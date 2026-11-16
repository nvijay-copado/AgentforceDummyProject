/**
 * Evaluates open Cases against their SLA policy, updates SLA status, and escalates Cases that
 * newly reach At Risk or Breached. One query per object and one DML per object per call.
 * Idempotent: an escalation level is never created twice for the same Case.
 */
public with sharing class EscalationService {
    public class Result {
        public Integer statusChanges = 0;
        public Integer escalationsCreated = 0;
        public Integer eventsPublished = 0;
    }

    public static Result process(List<Case> cases, Datetime now) {
        Result result = new Result();
        Map<Id, Case> originals = new Map<Id, Case>();
        Map<Id, Case> updates = new Map<Id, Case>();
        Map<Id, SLAPolicyService.Policy> policyByCase = new Map<Id, SLAPolicyService.Policy>();

        for (Case c : cases) {
            if (
                CaseSLATriggerHandler.isClosed(c.Status) ||
                c.SLA_Start_Date__c == null ||
                c.SLA_Due_Date__c == null ||
                c.SLA_Status__c == SLAPolicyService.STATUS_PAUSED
            ) {
                continue;
            }
            SLAPolicyService.Policy policy = SLAPolicyService.getPolicy(c.Priority);
            String newStatus = SLAPolicyService.evaluateStatus(
                c.SLA_Start_Date__c,
                c.SLA_Due_Date__c,
                now,
                policy.atRiskPct,
                false,
                c.SLA_Status__c
            );
            if (newStatus == c.SLA_Status__c) {
                continue;
            }
            originals.put(c.Id, c);
            policyByCase.put(c.Id, policy);
            updates.put(c.Id, new Case(Id = c.Id, SLA_Status__c = newStatus));
        }
        if (updates.isEmpty()) {
            return result;
        }
        result.statusChanges = updates.size();

        Set<String> existingLevels = loadExistingLevels(updates.keySet());
        Map<String, Id> queueIds = loadQueues(policyByCase.values());
        Map<Id, Id> managerByUser = loadManagers(originals.values());

        List<Escalation__c> escalations = new List<Escalation__c>();
        List<SLA_Breach_Event__e> events = new List<SLA_Breach_Event__e>();

        for (Id caseId : updates.keySet()) {
            Case original = originals.get(caseId);
            Case upd = updates.get(caseId);
            String status = upd.SLA_Status__c;
            if (status != SLAPolicyService.STATUS_AT_RISK && status != SLAPolicyService.STATUS_BREACHED) {
                continue;
            }
            SLAPolicyService.Policy policy = policyByCase.get(caseId);
            Integer current = original.Escalation_Level__c == null ? 0 : original.Escalation_Level__c.intValue();
            Integer nextLevel = current + 1;
            if (nextLevel > policy.maxLevel || existingLevels.contains(caseId + ':' + nextLevel)) {
                continue;
            }
            upd.Escalation_Level__c = nextLevel;
            if (policy.queueName != null && queueIds.containsKey(policy.queueName)) {
                upd.OwnerId = queueIds.get(policy.queueName);
            }
            escalations.add(
                new Escalation__c(
                    Case__c = caseId,
                    Level__c = nextLevel,
                    Reason__c = status,
                    Escalated_On__c = now,
                    Escalated_To__c = resolveRecipient(original.OwnerId, managerByUser)
                )
            );
            events.add(
                new SLA_Breach_Event__e(Case_Id__c = caseId, Escalation_Level__c = nextLevel, Breached_On__c = now)
            );
        }

        CaseSLATriggerHandler.bypassLevelCheck = true;
        try {
            update updates.values();
        } finally {
            CaseSLATriggerHandler.bypassLevelCheck = false;
        }
        if (!escalations.isEmpty()) {
            insert escalations;
            result.escalationsCreated = escalations.size();
            for (Database.SaveResult sr : EventBus.publish(events)) {
                if (sr.isSuccess()) {
                    result.eventsPublished++;
                }
            }
        }
        return result;
    }

    private static Set<String> loadExistingLevels(Set<Id> caseIds) {
        Set<String> keys = new Set<String>();
        for (Escalation__c e : [SELECT Case__c, Level__c FROM Escalation__c WHERE Case__c IN :caseIds]) {
            keys.add(e.Case__c + ':' + e.Level__c.intValue());
        }
        return keys;
    }

    private static Map<String, Id> loadQueues(List<SLAPolicyService.Policy> policies) {
        Set<String> names = new Set<String>();
        for (SLAPolicyService.Policy p : policies) {
            if (String.isNotBlank(p.queueName)) {
                names.add(p.queueName);
            }
        }
        Map<String, Id> result = new Map<String, Id>();
        if (names.isEmpty()) {
            return result;
        }
        for (QueueSobject qs : [
            SELECT QueueId, Queue.DeveloperName
            FROM QueueSobject
            WHERE SobjectType = 'Case' AND Queue.DeveloperName IN :names
        ]) {
            result.put(qs.Queue.DeveloperName, qs.QueueId);
        }
        return result;
    }

    private static Map<Id, Id> loadManagers(List<Case> cases) {
        Set<Id> userIds = new Set<Id>();
        for (Case c : cases) {
            if (isUser(c.OwnerId)) {
                userIds.add(c.OwnerId);
            }
        }
        Map<Id, Id> result = new Map<Id, Id>();
        if (userIds.isEmpty()) {
            return result;
        }
        for (User u : [SELECT Id, ManagerId FROM User WHERE Id IN :userIds AND ManagerId != NULL]) {
            result.put(u.Id, u.ManagerId);
        }
        return result;
    }

    /** Escalate to the owner's manager when one exists, otherwise to the owner. Queue owners have no recipient. */
    private static Id resolveRecipient(Id ownerId, Map<Id, Id> managerByUser) {
        if (!isUser(ownerId)) {
            return null;
        }
        return managerByUser.containsKey(ownerId) ? managerByUser.get(ownerId) : ownerId;
    }

    private static Boolean isUser(Id ownerId) {
        return ownerId != null && ownerId.getSobjectType() == User.SObjectType;
    }
}
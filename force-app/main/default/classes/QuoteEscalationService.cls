/**
 * Escalates Pending approval requests that exceed the configured SLA. Mirrors EscalationService:
 * one query per object, one DML per object, and an escalation level is never created twice.
 */
public with sharing class QuoteEscalationService {
    public static final Integer DEFAULT_SLA_HOURS = 24;
    public static final Integer DEFAULT_MAX_LEVEL = 2;

    public class Result {
        public Integer escalationsCreated = 0;
    }

    public static Result process(List<Quote_Approval_Request__c> requests, Datetime now) {
        Result result = new Result();
        Quote_Approval_Setting__mdt setting = Quote_Approval_Setting__mdt.getInstance('Default');
        Integer slaHours = setting == null || setting.SLA_Hours__c == null
            ? DEFAULT_SLA_HOURS
            : setting.SLA_Hours__c.intValue();
        Integer maxLevel = setting == null || setting.Max_Level__c == null
            ? DEFAULT_MAX_LEVEL
            : setting.Max_Level__c.intValue();

        List<Quote_Approval_Request__c> due = new List<Quote_Approval_Request__c>();
        for (Quote_Approval_Request__c req : requests) {
            if (req.Decision__c != QuoteApprovalOrchestrator.DECISION_PENDING) {
                continue;
            }
            Integer next = currentLevel(req) + 1;
            if (next <= maxLevel && now >= req.CreatedDate.addHours(slaHours * next)) {
                due.add(req);
            }
        }
        if (due.isEmpty()) {
            return result;
        }

        Set<Id> requestIds = new Map<Id, Quote_Approval_Request__c>(due).keySet();
        Set<String> existing = loadExistingKeys(requestIds);
        Map<Id, Id> managerByUser = loadManagers(due);

        List<Quote_Approval_Escalation__c> escalations = new List<Quote_Approval_Escalation__c>();
        List<Quote_Approval_Request__c> toUpdate = new List<Quote_Approval_Request__c>();
        for (Quote_Approval_Request__c req : due) {
            Integer next = currentLevel(req) + 1;
            String key = req.Id + ':' + next;
            if (existing.contains(key)) {
                continue;
            }
            escalations.add(
                new Quote_Approval_Escalation__c(
                    Request__c = req.Id,
                    Level__c = next,
                    Escalated_On__c = now,
                    Escalated_To__c = resolveRecipient(req.OwnerId, managerByUser),
                    Unique_Key__c = key
                )
            );
            toUpdate.add(new Quote_Approval_Request__c(Id = req.Id, Escalation_Level__c = next));
        }
        if (escalations.isEmpty()) {
            return result;
        }

        // Partial save keeps the run idempotent if a concurrent job already created the same level.
        List<Database.SaveResult> saved = Database.insert(escalations, false);
        List<Quote_Approval_Request__c> confirmed = new List<Quote_Approval_Request__c>();
        for (Integer i = 0; i < saved.size(); i++) {
            if (saved[i].isSuccess()) {
                result.escalationsCreated++;
                confirmed.add(toUpdate[i]);
            }
        }
        if (!confirmed.isEmpty()) {
            update confirmed;
        }
        return result;
    }

    private static Integer currentLevel(Quote_Approval_Request__c req) {
        return req.Escalation_Level__c == null ? 0 : req.Escalation_Level__c.intValue();
    }

    private static Set<String> loadExistingKeys(Set<Id> requestIds) {
        Set<String> keys = new Set<String>();
        for (Quote_Approval_Escalation__c e : [
            SELECT Unique_Key__c
            FROM Quote_Approval_Escalation__c
            WHERE Request__c IN :requestIds
        ]) {
            keys.add(e.Unique_Key__c);
        }
        return keys;
    }

    private static Map<Id, Id> loadManagers(List<Quote_Approval_Request__c> requests) {
        Set<Id> userIds = new Set<Id>();
        for (Quote_Approval_Request__c req : requests) {
            if (isUser(req.OwnerId)) {
                userIds.add(req.OwnerId);
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
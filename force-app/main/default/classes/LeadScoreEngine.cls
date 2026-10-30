public with sharing class LeadScoreEngine {
    @TestVisible static List<Lead_Scoring_Rule__mdt> rulesOverride;
    @TestVisible static List<Lead_Routing_Rule__mdt> routingOverride;

    public class Request {
        @InvocableVariable(label='Lead Id' required=true)
        public Id leadId;
    }

    @InvocableMethod(label='Score Leads' description='Calculates Lead_Score__c and routes leads to queues')
    public static void scoreLeads(List<Request> requests) {
        Set<Id> ids = new Set<Id>();
        for (Request r : requests) {
            if (r != null && r.leadId != null) { ids.add(r.leadId); }
        }
        scoreByIds(ids);
    }

    public static Integer scoreByIds(Set<Id> ids) {
        List<Lead> leads = [
            SELECT Id, OwnerId, Lead_Score__c, Company, Email, Phone, AnnualRevenue, NumberOfEmployees, LeadSource
            FROM Lead WHERE Id IN :ids
        ];
        return applyScores(leads);
    }

    public static Integer applyScores(List<Lead> leads) {
        List<Lead_Scoring_Rule__mdt> rules = rulesOverride != null ? rulesOverride :
            [SELECT Field_API_Name__c, Operator__c, Value__c, Points__c FROM Lead_Scoring_Rule__mdt WHERE Active__c = true];
        List<Lead_Routing_Rule__mdt> routing = routingOverride != null ? routingOverride :
            [SELECT Min_Score__c, Queue_Developer_Name__c FROM Lead_Routing_Rule__mdt ORDER BY Min_Score__c DESC];

        Set<String> queueNames = new Set<String>();
        for (Lead_Routing_Rule__mdt rr : routing) { queueNames.add(rr.Queue_Developer_Name__c); }
        Map<String, Id> queueIds = new Map<String, Id>();
        for (Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :queueNames]) {
            queueIds.put(g.DeveloperName, g.Id);
        }

        List<Lead> toUpdate = new List<Lead>();
        for (Lead l : leads) {
            Decimal score = calculate(l, rules);
            Id newOwner = route(score, l.OwnerId, routing, queueIds);
            if (l.Lead_Score__c != score || newOwner != l.OwnerId) {
                toUpdate.add(new Lead(Id = l.Id, Lead_Score__c = score, OwnerId = newOwner));
            }
        }
        if (!toUpdate.isEmpty()) { update toUpdate; }
        return toUpdate.size();
    }

    @TestVisible
    static Decimal calculate(Lead l, List<Lead_Scoring_Rule__mdt> rules) {
        Decimal score = 0;
        for (Lead_Scoring_Rule__mdt r : rules) {
            if (matches(l, r)) { score += r.Points__c == null ? 0 : r.Points__c; }
        }
        return score;
    }

    @TestVisible
    static Id route(Decimal score, Id currentOwner, List<Lead_Routing_Rule__mdt> routing, Map<String, Id> queueIds) {
        Id owner = currentOwner;
        Decimal best = null;
        for (Lead_Routing_Rule__mdt rr : routing) {
            if (score >= rr.Min_Score__c && queueIds.containsKey(rr.Queue_Developer_Name__c)
                    && (best == null || rr.Min_Score__c > best)) {
                best = rr.Min_Score__c;
                owner = queueIds.get(rr.Queue_Developer_Name__c);
            }
        }
        return owner;
    }

    @TestVisible
    static Boolean matches(Lead l, Lead_Scoring_Rule__mdt r) {
        Object raw = l.get(r.Field_API_Name__c);
        String op = r.Operator__c;
        if (op == 'NotBlank') { return raw != null && String.valueOf(raw) != ''; }
        if (raw == null) { return false; }
        if (op == 'Equals') { return String.valueOf(raw) == r.Value__c; }
        if (op == 'Contains') { return r.Value__c != null && String.valueOf(raw).containsIgnoreCase(r.Value__c); }
        if (op == 'GreaterOrEqual') { return Decimal.valueOf(String.valueOf(raw)) >= Decimal.valueOf(r.Value__c); }
        return false;
    }
}
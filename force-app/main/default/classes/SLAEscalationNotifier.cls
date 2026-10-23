/** Sends a custom notification to the escalation recipient when an SLA breach event is published. */
public with sharing class SLAEscalationNotifier {
    public static final String NOTIFICATION_TYPE = 'Case_SLA_Escalation';

    public static Integer notify(List<SLA_Breach_Event__e> events) {
        Set<Id> caseIds = new Set<Id>();
        for (SLA_Breach_Event__e e : events) {
            if (e.Case_Id__c != null) {
                caseIds.add(e.Case_Id__c);
            }
        }
        if (caseIds.isEmpty()) {
            return 0;
        }
        List<CustomNotificationType> types = [
            SELECT Id FROM CustomNotificationType WHERE DeveloperName = :NOTIFICATION_TYPE LIMIT 1
        ];
        if (types.isEmpty()) {
            return 0;
        }
        Map<Id, Case> cases = new Map<Id, Case>([SELECT Id, CaseNumber FROM Case WHERE Id IN :caseIds]);
        Map<String, Escalation__c> escalations = new Map<String, Escalation__c>();
        for (Escalation__c esc : [
            SELECT Case__c, Level__c, Escalated_To__c FROM Escalation__c
            WHERE Case__c IN :caseIds AND Escalated_To__c != null
        ]) {
            escalations.put(esc.Case__c + ':' + esc.Level__c.intValue(), esc);
        }
        Integer sent = 0;
        for (SLA_Breach_Event__e e : events) {
            Escalation__c esc = escalations.get(e.Case_Id__c + ':' + Integer.valueOf(e.Escalation_Level__c));
            Case c = cases.get(e.Case_Id__c);
            if (esc == null || c == null) {
                continue;
            }
            Messaging.CustomNotification n = new Messaging.CustomNotification();
            n.setNotificationTypeId(types[0].Id);
            n.setTargetId(c.Id);
            n.setTitle('Case ' + c.CaseNumber + ' escalated');
            n.setBody('SLA is at risk. Escalation level ' + Integer.valueOf(e.Escalation_Level__c) + '.');
            try {
                n.send(new Set<String>{ esc.Escalated_To__c });
                sent++;
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN, 'Notification failed: ' + ex.getMessage());
            }
        }
        return sent;
    }
}
/** Backend for the slaEscalationPanel and slaManagerDashboard LWCs. */
public with sharing class SLAEscalationController {
    private static final Integer DASHBOARD_LIMIT = 200;

    public class EscalationRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal level;
        @AuraEnabled public String reason;
        @AuraEnabled public Datetime escalatedOn;
        @AuraEnabled public String escalatedToName;
        @AuraEnabled public Boolean acknowledged;
        @AuraEnabled public Boolean canAcknowledge;
    }

    public class SlaSummary {
        @AuraEnabled public String slaStatus;
        @AuraEnabled public Datetime dueDate;
        @AuraEnabled public Decimal escalationLevel;
        @AuraEnabled public Boolean isClosed;
        @AuraEnabled public List<EscalationRow> escalations = new List<EscalationRow>();
    }

    private static AuraHandledException toAura(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }

    @AuraEnabled(cacheable=true)
    public static SlaSummary getSlaSummary(Id caseId) {
        try {
            List<Case> cases = [
                SELECT Id, SLA_Status__c, SLA_Due_Date__c, Escalation_Level__c, IsClosed
                FROM Case
                WHERE Id = :caseId
                WITH USER_MODE
            ];
            if (cases.isEmpty()) {
                throw toAura('Case not found or not accessible.');
            }
            Case c = cases[0];
            SlaSummary summary = new SlaSummary();
            summary.slaStatus = c.SLA_Status__c;
            summary.dueDate = c.SLA_Due_Date__c;
            summary.escalationLevel = c.Escalation_Level__c;
            summary.isClosed = c.IsClosed;
            Boolean manager = FeatureManagement.checkPermission('SLA_Manager');
            for (Escalation__c e : [
                SELECT
                    Id,
                    Name,
                    Level__c,
                    Reason__c,
                    Escalated_On__c,
                    Escalated_To__c,
                    Escalated_To__r.Name,
                    Acknowledged__c
                FROM Escalation__c
                WHERE Case__c = :caseId
                WITH USER_MODE
                ORDER BY Level__c DESC
            ]) {
                EscalationRow row = new EscalationRow();
                row.id = e.Id;
                row.name = e.Name;
                row.level = e.Level__c;
                row.reason = e.Reason__c;
                row.escalatedOn = e.Escalated_On__c;
                row.escalatedToName = e.Escalated_To__r?.Name;
                row.acknowledged = e.Acknowledged__c;
                row.canAcknowledge = !e.Acknowledged__c && (manager || e.Escalated_To__c == UserInfo.getUserId());
                summary.escalations.add(row);
            }
            return summary;
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw toAura(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void acknowledgeEscalation(Id escalationId) {
        try {
            List<Escalation__c> rows = [
                SELECT Id, Escalated_To__c, Acknowledged__c
                FROM Escalation__c
                WHERE Id = :escalationId
                WITH USER_MODE
            ];
            if (rows.isEmpty()) {
                throw toAura('Escalation not found or not accessible.');
            }
            Escalation__c esc = rows[0];
            if (esc.Acknowledged__c) {
                throw toAura('This escalation has already been acknowledged.');
            }
            if (!FeatureManagement.checkPermission('SLA_Manager') && esc.Escalated_To__c != UserInfo.getUserId()) {
                throw toAura('Only the assigned user or an SLA manager can acknowledge this escalation.');
            }
            update as user new Escalation__c(Id = esc.Id, Acknowledged__c = true, Acknowledged_On__c = System.now());
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw toAura(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getDashboardCases(String priority, Integer minLevel) {
        if (!FeatureManagement.checkPermission('SLA_Manager')) {
            throw toAura('The SLA Manager permission is required.');
        }
        try {
            String priorityFilter = String.isBlank(priority) ? null : priority;
            Integer levelFilter = minLevel == null ? 0 : minLevel;
            String soql =
                'SELECT Id, CaseNumber, Subject, Priority, SLA_Status__c, SLA_Due_Date__c, Escalation_Level__c, Owner.Name ' +
                'FROM Case WHERE IsClosed = FALSE AND SLA_Status__c IN (\'At Risk\', \'Breached\') ' +
                'AND Escalation_Level__c >= :levelFilter ' +
                (priorityFilter == null ? '' : 'AND Priority = :priorityFilter ') +
                'ORDER BY SLA_Due_Date__c ASC LIMIT :limitRows';
            Map<String, Object> binds = new Map<String, Object>{
                'levelFilter' => levelFilter,
                'priorityFilter' => priorityFilter,
                'limitRows' => DASHBOARD_LIMIT
            };
            return (List<Case>) Database.queryWithBinds(soql, binds, AccessLevel.USER_MODE);
        } catch (Exception ex) {
            throw toAura(ex.getMessage());
        }
    }
}
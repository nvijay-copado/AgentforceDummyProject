/**
 * Before insert/update logic for Case SLA fields. Contains no SOQL and no DML, so it is
 * bulk safe and cannot recurse. Legacy Cases without an SLA start date are left untouched.
 */
public with sharing class CaseSLATriggerHandler {
    public static final Set<String> CLOSED_STATUSES = new Set<String>{ 'Closed' };

    /** Set by EscalationService while it raises the escalation level as the system. */
    public static Boolean bypassLevelCheck = false;

    @TestVisible
    private static Boolean overridePermission;
    @TestVisible
    private static Datetime nowOverride;

    public static void beforeInsert(List<Case> cases) {
        Datetime now = currentTime();
        for (Case c : cases) {
            SLAPolicyService.Policy policy = SLAPolicyService.getPolicy(c.Priority);
            Boolean closed = isClosed(c.Status);
            if (closed && String.isBlank(c.Resolution_Summary__c)) {
                c.addError('A Resolution Summary is required to close a Case.');
                continue;
            }
            Decimal level = c.Escalation_Level__c == null ? 0 : c.Escalation_Level__c;
            c.Escalation_Level__c = level;
            checkLevelChange(c, 0);
            c.SLA_Start_Date__c = now;
            c.SLA_Paused_Hours__c = 0;
            c.SLA_Due_Date__c = SLAPolicyService.calculateDueDate(now, policy, 0);
            if (closed) {
                c.SLA_Status__c = SLAPolicyService.STATUS_MET;
            } else if (c.Status == policy.pauseStatus) {
                c.SLA_Status__c = SLAPolicyService.STATUS_PAUSED;
                c.SLA_Pause_Started__c = now;
            } else {
                c.SLA_Status__c = SLAPolicyService.STATUS_ON_TRACK;
            }
        }
    }

    public static void beforeUpdate(List<Case> cases, Map<Id, Case> oldCases) {
        Datetime now = currentTime();
        for (Case c : cases) {
            Case old = oldCases.get(c.Id);
            Boolean closedNow = isClosed(c.Status);
            Boolean closedBefore = isClosed(old.Status);
            if (closedNow && String.isBlank(c.Resolution_Summary__c)) {
                c.addError('A Resolution Summary is required to close a Case.');
                continue;
            }
            checkLevelChange(c, old.Escalation_Level__c);
            if (c.SLA_Start_Date__c == null || (closedBefore && closedNow)) {
                continue;
            }
            applySlaChanges(c, old, now, closedNow, closedBefore);
        }
    }

    private static void applySlaChanges(Case c, Case old, Datetime now, Boolean closedNow, Boolean closedBefore) {
        SLAPolicyService.Policy policy = SLAPolicyService.getPolicy(c.Priority);
        Boolean pausedNow = !closedNow && c.Status == policy.pauseStatus;
        Boolean pausedBefore = !closedBefore && old.Status == policy.pauseStatus;
        Boolean recalculate = c.Priority != old.Priority;

        if (pausedNow && !pausedBefore) {
            c.SLA_Status__c = SLAPolicyService.STATUS_PAUSED;
            c.SLA_Pause_Started__c = now;
        } else if (pausedBefore && !pausedNow) {
            if (old.SLA_Pause_Started__c != null) {
                Decimal hours = Decimal.valueOf(now.getTime() - old.SLA_Pause_Started__c.getTime()) / 3600000;
                c.SLA_Paused_Hours__c = (c.SLA_Paused_Hours__c == null ? 0 : c.SLA_Paused_Hours__c) + hours.setScale(2);
            }
            c.SLA_Pause_Started__c = null;
            c.SLA_Status__c = SLAPolicyService.STATUS_ON_TRACK;
            recalculate = true;
        }

        if (recalculate && !pausedNow) {
            c.SLA_Due_Date__c = SLAPolicyService.calculateDueDate(c.SLA_Start_Date__c, policy, c.SLA_Paused_Hours__c);
        }

        if (closedNow && !closedBefore) {
            c.SLA_Status__c = SLAPolicyService.evaluateStatus(
                c.SLA_Start_Date__c,
                c.SLA_Due_Date__c,
                now,
                policy.atRiskPct,
                true,
                old.SLA_Status__c
            );
            c.SLA_Pause_Started__c = null;
        }
    }

    private static void checkLevelChange(Case c, Decimal oldLevel) {
        Decimal before = oldLevel == null ? 0 : oldLevel;
        Decimal after = c.Escalation_Level__c == null ? 0 : c.Escalation_Level__c;
        if (before == after || bypassLevelCheck) {
            return;
        }
        if (!hasOverridePermission()) {
            c.addError('You do not have permission to change the Escalation Level.');
        } else if (String.isBlank(c.Escalation_Override_Reason__c)) {
            c.addError('An Escalation Override Reason is required when changing the Escalation Level.');
        }
    }

    public static Boolean isClosed(String status) {
        return status != null && CLOSED_STATUSES.contains(status);
    }

    private static Boolean hasOverridePermission() {
        if (overridePermission != null) {
            return overridePermission;
        }
        return FeatureManagement.checkPermission('SLA_Override_Escalation');
    }

    private static Datetime currentTime() {
        return nowOverride != null ? nowOverride : System.now();
    }
}
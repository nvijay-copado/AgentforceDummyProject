@IsTest
private class CaseSLATriggerTest {
    private static List<Case> makeCases(Integer n, String priority) {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < n; i++) {
            cases.add(new Case(Subject = 'SLA ' + i, Priority = priority, Status = 'New', Origin = 'Web'));
        }
        return cases;
    }

    private static Case reload(Id id) {
        return [
            SELECT Id, Status, Priority, SLA_Status__c, SLA_Start_Date__c, SLA_Due_Date__c, SLA_Paused_Hours__c,
                   SLA_Pause_Started__c, Escalation_Level__c
            FROM Case WHERE Id = :id
        ];
    }

    @IsTest
    static void insertSetsSlaFields() {
        Case c = makeCases(1, 'High')[0];
        insert c;
        Case r = reload(c.Id);
        System.assertEquals('On Track', r.SLA_Status__c);
        System.assertNotEquals(null, r.SLA_Start_Date__c);
        System.assertEquals(0, r.Escalation_Level__c);
        Decimal hours = (r.SLA_Due_Date__c.getTime() - r.SLA_Start_Date__c.getTime()) / 3600000.0;
        System.assertEquals(SLAPolicyService.getPolicy('High').resolutionHours, hours);
    }

    @IsTest
    static void bulkInsertTwoHundredCases() {
        List<Case> cases = makeCases(200, 'Medium');
        Test.startTest();
        insert cases;
        Test.stopTest();
        System.assertEquals(200, [SELECT COUNT() FROM Case WHERE SLA_Status__c = 'On Track' AND SLA_Due_Date__c != NULL]);
    }

    @IsTest
    static void priorityChangeRecalculatesDueDate() {
        Case c = makeCases(1, 'Low')[0];
        insert c;
        Datetime before = reload(c.Id).SLA_Due_Date__c;
        c.Priority = 'High';
        update c;
        Case r = reload(c.Id);
        System.assert(r.SLA_Due_Date__c < before, 'High priority has a shorter window');
    }

    @IsTest
    static void pauseAndResumeExtendsDueDate() {
        Case c = makeCases(1, 'High')[0];
        insert c;
        Datetime originalDue = reload(c.Id).SLA_Due_Date__c;
        c.Status = 'Waiting on Customer';
        update c;
        Case paused = reload(c.Id);
        System.assertEquals('Paused', paused.SLA_Status__c);
        System.assertNotEquals(null, paused.SLA_Pause_Started__c);
        c.Status = 'Working';
        update c;
        Case resumed = reload(c.Id);
        System.assertEquals('On Track', resumed.SLA_Status__c);
        System.assertEquals(null, resumed.SLA_Pause_Started__c);
        System.assert(resumed.SLA_Due_Date__c >= originalDue);
    }

    @IsTest
    static void closeRequiresResolutionSummary() {
        Case c = makeCases(1, 'Medium')[0];
        insert c;
        c.Status = 'Closed';
        Database.SaveResult sr = Database.update(c, false);
        System.assert(!sr.isSuccess());
        System.assert(sr.getErrors()[0].getMessage().contains('Resolution Summary'));
    }

    @IsTest
    static void closeWithinSlaIsMet() {
        Case c = makeCases(1, 'Medium')[0];
        insert c;
        c.Status = 'Closed';
        c.Resolution_Summary__c = 'Fixed';
        update c;
        System.assertEquals('Met', reload(c.Id).SLA_Status__c);
    }

    @IsTest
    static void lateCloseIsBreached() {
        Case c = makeCases(1, 'High')[0];
        insert c;
        CaseSLATriggerHandler.nowOverride = Datetime.now().addDays(30);
        c.Status = 'Closed';
        c.Resolution_Summary__c = 'Fixed late';
        update c;
        System.assertEquals('Breached', reload(c.Id).SLA_Status__c);
    }

    @IsTest
    static void escalationLevelChangeNeedsPermission() {
        CaseSLATriggerHandler.overridePermission = false;
        Case c = makeCases(1, 'Medium')[0];
        insert c;
        c.Escalation_Level__c = 2;
        c.Escalation_Override_Reason__c = 'Customer VIP';
        Database.SaveResult sr = Database.update(c, false);
        System.assert(!sr.isSuccess());
        System.assert(sr.getErrors()[0].getMessage().contains('permission'));
    }

    @IsTest
    static void overrideRequiresReason() {
        CaseSLATriggerHandler.overridePermission = true;
        Case c = makeCases(1, 'Medium')[0];
        insert c;
        c.Escalation_Level__c = 2;
        Database.SaveResult denied = Database.update(c, false);
        System.assert(!denied.isSuccess());
        System.assert(denied.getErrors()[0].getMessage().contains('Override Reason'));
        c.Escalation_Override_Reason__c = 'Customer VIP';
        Database.SaveResult ok = Database.update(c, false);
        System.assert(ok.isSuccess());
        System.assertEquals(2, reload(c.Id).Escalation_Level__c);
    }

    @IsTest
    static void legacyCaseWithoutStartDateIsUntouched() {
        Case c = makeCases(1, 'High')[0];
        insert c;
        Database.update(new Case(Id = c.Id, SLA_Start_Date__c = null, SLA_Due_Date__c = null, SLA_Status__c = null), false);
        Case legacy = reload(c.Id);
        legacy.Priority = 'Low';
        update legacy;
        System.assertEquals(null, reload(c.Id).SLA_Due_Date__c);
    }
}
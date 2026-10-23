@IsTest
private class QuoteEscalationTest {
    private static List<Quote_Approval_Request__c> load() {
        return [
            SELECT Id, CreatedDate, OwnerId, Decision__c, Escalation_Level__c
            FROM Quote_Approval_Request__c
        ];
    }

    @IsTest
    static void notEscalatedBeforeSla() {
        TestDataFactory.approvalRequest().create();
        System.assertEquals(0, QuoteEscalationService.process(load(), Datetime.now()).escalationsCreated);
    }

    @IsTest
    static void escalatesOncePerLevelAndStopsAtMax() {
        Quote_Approval_Request__c r = TestDataFactory.approvalRequest().create();
        System.assertEquals(1, QuoteEscalationService.process(load(), Datetime.now().addHours(30)).escalationsCreated);
        System.assertEquals(0, QuoteEscalationService.process(load(), Datetime.now().addHours(30)).escalationsCreated);
        System.assertEquals(1, QuoteEscalationService.process(load(), Datetime.now().addHours(60)).escalationsCreated);
        System.assertEquals(0, QuoteEscalationService.process(load(), Datetime.now().addHours(500)).escalationsCreated);
        System.assertEquals(2, [SELECT COUNT() FROM Quote_Approval_Escalation__c WHERE Request__c = :r.Id]);
        System.assertEquals(2, load()[0].Escalation_Level__c);
    }

    @IsTest
    static void decidedRequestsAreSkipped() {
        TestDataFactory.approvalRequest().withDecision('Approved').create();
        System.assertEquals(0, QuoteEscalationService.process(load(), Datetime.now().addHours(100)).escalationsCreated);
    }

    @IsTest
    static void escalatesToOwnerWhenNoManager() {
        Quote_Approval_Request__c r = TestDataFactory.approvalRequest().create();
        QuoteEscalationService.process(load(), Datetime.now().addHours(30));
        Quote_Approval_Escalation__c e = [SELECT Escalated_To__c FROM Quote_Approval_Escalation__c WHERE Request__c = :r.Id];
        System.assertNotEquals(null, e.Escalated_To__c);
    }

    @IsTest
    static void batchAndSchedulerRun() {
        TestDataFactory.approvalRequest().create();
        Test.startTest();
        Database.executeBatch(new QuoteEscalationBatch());
        String jobId = System.schedule('QuoteEscalationTest', '0 0 * * * ?', new QuoteEscalationScheduler());
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM CronTrigger WHERE Id = :jobId]);
    }
}
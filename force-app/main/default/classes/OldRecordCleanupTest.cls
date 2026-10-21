@IsTest
private class OldRecordCleanupTest {
    @IsTest
    static void batchRunsWithoutError() {
        Task t = new Task(Subject = 'Recent', Status = 'Completed');
        insert t;
        Test.startTest();
        Database.executeBatch(new OldRecordCleanupBatch(), 200);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE Id = :t.Id], 'Recent task must be kept');
    }

    @IsTest
    static void schedulerEnqueuesBatch() {
        Test.startTest();
        String jobId = System.schedule('OldRecordCleanupTestJob', OldRecordCleanupScheduler.CRON_NIGHTLY, new OldRecordCleanupScheduler());
        Test.stopTest();
        CronTrigger ct = [SELECT CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(OldRecordCleanupScheduler.CRON_NIGHTLY, ct.CronExpression);
    }
}
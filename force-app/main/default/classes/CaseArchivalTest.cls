@IsTest
private class CaseArchivalTest {
    @TestSetup
    static void setup() {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            cases.add(new Case(Subject = 'Old case ' + i, Status = 'Closed', Origin = 'Web'));
        }
        insert cases;
    }

    @IsTest
    static void batchArchivesAndCleanupDeletesClosedCases() {
        CaseArchivalBatch.cutoff = Datetime.now().addDays(1);
        CaseArchivalBatch.skipBigObjectWrite = true;
        Test.startTest();
        CaseArchivalBatch batch = new CaseArchivalBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Subject LIKE 'Old case%'], 'Archived cases should be deleted');
    }

    @IsTest
    static void recentCasesAreNotArchived() {
        CaseArchivalBatch.cutoff = Datetime.now().addYears(-3);
        CaseArchivalBatch.skipBigObjectWrite = true;
        Test.startTest();
        Database.executeBatch(new CaseArchivalBatch(), 200);
        Test.stopTest();
        System.assertEquals(5, [SELECT COUNT() FROM Case WHERE Subject LIKE 'Old case%'], 'Recent cases must be kept');
    }

    @IsTest
    static void queueableHandlesEmptyAndDeletes() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        System.enqueueJob(new CaseArchivalCleanupQueueable(new List<Id>()));
        System.enqueueJob(new CaseArchivalCleanupQueueable(new List<Id>{ c.Id }));
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Id = :c.Id]);
    }

    @IsTest
    static void schedulerSchedulesJob() {
        Test.startTest();
        Id jobId = CaseArchivalScheduler.schedule();
        Test.stopTest();
        System.assertNotEquals(null, jobId);
        System.assertEquals(1, [SELECT COUNT() FROM CronTrigger WHERE Id = :jobId]);
    }
}
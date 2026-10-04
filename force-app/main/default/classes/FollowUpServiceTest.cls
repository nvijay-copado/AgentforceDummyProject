@isTest
private class FollowUpServiceTest {

    private static Account createAccount() {
        Account acc = new Account(Name = 'Test Follow-Up Account');
        insert acc;
        return acc;
    }

    @isTest
    static void testGetMyFollowUpsReturnsOwnedRecordsOrderedByDueDate() {
        Account acc = createAccount();
        insert new List<Follow_Up__c>{
            new Follow_Up__c(Subject__c = 'Later Call', Due_Date__c = Date.today().addDays(10),
                              Priority__c = 'Low', Status__c = 'Not Started', Account__c = acc.Id),
            new Follow_Up__c(Subject__c = 'Sooner Call', Due_Date__c = Date.today().addDays(1),
                              Priority__c = 'High', Status__c = 'Not Started', Account__c = acc.Id)
        };

        Test.startTest();
        List<Follow_Up__c> results = FollowUpService.getMyFollowUps();
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Both follow-ups owned by the running user should be returned.');
        System.assertEquals('Sooner Call', results[0].Subject__c, 'Results should be ordered by Due Date ascending.');
    }

    @isTest
    static void testGetOverdueFollowUpsFlagsPastDueIncompleteRecords() {
        Account acc = createAccount();
        Follow_Up__c overdue = new Follow_Up__c(Subject__c = 'Overdue Item', Due_Date__c = Date.today().addDays(-5),
                                                 Priority__c = 'High', Status__c = 'Not Started', Account__c = acc.Id);
        Follow_Up__c notOverdueCompleted = new Follow_Up__c(Subject__c = 'Completed Past Item', Due_Date__c = Date.today().addDays(-5),
                                                 Priority__c = 'Medium', Status__c = 'Completed', Account__c = acc.Id);
        Follow_Up__c notOverdueFuture = new Follow_Up__c(Subject__c = 'Future Item', Due_Date__c = Date.today().addDays(5),
                                                 Priority__c = 'Medium', Status__c = 'Not Started', Account__c = acc.Id);
        insert new List<Follow_Up__c>{ overdue, notOverdueCompleted, notOverdueFuture };

        Test.startTest();
        List<Follow_Up__c> overdueResults = FollowUpService.getOverdueFollowUps();
        Test.stopTest();

        System.assertEquals(1, overdueResults.size(), 'Only the past-due, non-completed follow-up should be flagged as overdue.');
        System.assertEquals(overdue.Id, overdueResults[0].Id, 'The overdue record returned should be the one that is past due and not completed.');
    }

    @isTest
    static void testCompleteFollowUpsBulkUpdatesStatus() {
        Account acc = createAccount();
        List<Follow_Up__c> followUps = new List<Follow_Up__c>();
        for (Integer i = 0; i < 200; i++) {
            followUps.add(new Follow_Up__c(Subject__c = 'Bulk Item ' + i, Due_Date__c = Date.today().addDays(1),
                                            Priority__c = 'Medium', Status__c = 'Not Started', Account__c = acc.Id));
        }
        insert followUps;

        List<Id> idsToComplete = new List<Id>();
        for (Follow_Up__c fu : followUps) {
            idsToComplete.add(fu.Id);
        }

        Test.startTest();
        List<Follow_Up__c> updated = FollowUpService.completeFollowUps(idsToComplete);
        Test.stopTest();

        System.assertEquals(200, updated.size(), 'All 200 bulk follow-ups should be returned as updated.');
        List<Follow_Up__c> requeried = [SELECT Status__c FROM Follow_Up__c WHERE Id IN :idsToComplete];
        for (Follow_Up__c fu : requeried) {
            System.assertEquals('Completed', fu.Status__c, 'Every follow-up should now be Completed.');
        }
    }

    @isTest
    static void testCompleteFollowUpsHandlesEmptyAndNullInput() {
        Test.startTest();
        List<Follow_Up__c> emptyResult = FollowUpService.completeFollowUps(new List<Id>());
        List<Follow_Up__c> nullResult = FollowUpService.completeFollowUps(null);
        Test.stopTest();

        System.assertEquals(0, emptyResult.size(), 'Empty input should return an empty list without querying.');
        System.assertEquals(0, nullResult.size(), 'Null input should return an empty list without throwing.');
    }

    @isTest
    static void testGetTeamFollowUpsReturnsDirectReportsFollowUps() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User manager = new User(
            FirstName = 'Manager',
            LastName = 'Test' + System.currentTimeMillis(),
            Email = 'manager' + System.currentTimeMillis() + '@test.followup.com',
            Username = 'manager' + System.currentTimeMillis() + '@test.followup.com',
            Alias = 'mgrtst',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert manager;

        User teamMember = new User(
            FirstName = 'Report',
            LastName = 'Test' + System.currentTimeMillis(),
            Email = 'report' + System.currentTimeMillis() + '@test.followup.com',
            Username = 'report' + System.currentTimeMillis() + '@test.followup.com',
            Alias = 'rpttst',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id,
            ManagerId = manager.Id
        );
        insert teamMember;

        Account acc = createAccount();
        System.runAs(teamMember) {
            insert new Follow_Up__c(Subject__c = 'Team Member Call', Due_Date__c = Date.today().addDays(2),
                                     Priority__c = 'Medium', Status__c = 'Not Started', Account__c = acc.Id);
        }

        Test.startTest();
        List<Follow_Up__c> teamResults = FollowUpService.getTeamFollowUps(manager.Id);
        Test.stopTest();

        System.assertEquals(1, teamResults.size(), 'The manager should see the follow-up owned by their direct report.');
        System.assertEquals(teamMember.Id, teamResults[0].OwnerId, 'The returned follow-up should be owned by the team member.');
    }

    @isTest
    static void testGetTeamFollowUpsDefaultsToRunningUserWhenNoManagerIdProvided() {
        Test.startTest();
        List<Follow_Up__c> results = FollowUpService.getTeamFollowUps(null);
        Test.stopTest();

        System.assertNotEquals(null, results, 'A null manager Id should default to the running user without throwing.');
    }
}
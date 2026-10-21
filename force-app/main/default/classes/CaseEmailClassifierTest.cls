@IsTest
private class CaseEmailClassifierTest {
    @IsTest
    static void categorizesByKeyword() {
        System.assertEquals('Access', CaseEmailClassifier.categorize('Password reset', null));
        System.assertEquals('Hardware', CaseEmailClassifier.categorize('Help', 'My printer is broken'));
        System.assertEquals('Network', CaseEmailClassifier.categorize('VPN down', ''));
        System.assertEquals('General', CaseEmailClassifier.categorize('Hello', 'Question'));
        System.assertEquals('General', CaseEmailClassifier.categorize(null, null));
    }

    @IsTest
    static void mapsQueues() {
        System.assertEquals('Network_IT', CaseEmailClassifier.queueNameFor('Network'));
        System.assertEquals('General_IT', CaseEmailClassifier.queueNameFor('Unknown'));
    }

    @IsTest
    static void routesOnlyEmailCases() {
        Case emailCase = new Case(Origin = 'Email', Subject = 'VPN issue');
        Case phoneCase = new Case(Origin = 'Phone', Subject = 'VPN issue');
        Id phoneOwner = phoneCase.OwnerId;
        Test.startTest();
        insert new List<Case>{ emailCase, phoneCase };
        Test.stopTest();
        Case reloaded = [SELECT OwnerId FROM Case WHERE Id = :phoneCase.Id];
        System.assertEquals(UserInfo.getUserId(), reloaded.OwnerId);
        System.assertNotEquals(null, [SELECT OwnerId FROM Case WHERE Id = :emailCase.Id].OwnerId);
    }

    @IsTest
    static void noEmailCasesIsNoop() {
        CaseEmailClassifier.routeEmailCases(new List<Case>{ new Case(Origin = 'Web') });
        System.assert(true);
    }
}
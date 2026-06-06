@isTest
private class StrategicHealthServiceTest {
    @TestSetup
    static void setup() {
        insert new Account(Name = 'Strategic Deal Test Account');
    }

    @isTest
    static void isStrategicDeal_returnsTrueWhenFlagged() {
        Opportunity opp = createOpportunity('Flagged Deal', true);

        Test.startTest();
        Boolean result = StrategicHealthService.isStrategicDeal(opp);
        Test.stopTest();

        Assert.isTrue(result, 'Opportunity should be identified as a strategic deal');
    }

    @isTest
    static void isStrategicDeal_returnsFalseWhenNotFlagged() {
        Opportunity opp = createOpportunity('Standard Deal', false);

        Test.startTest();
        Boolean result = StrategicHealthService.isStrategicDeal(opp);
        Test.stopTest();

        Assert.isFalse(result, 'Opportunity should not be identified as a strategic deal');
    }

    @isTest
    static void countStrategicDeals_countsOnlyFlaggedOpportunities() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Opportunity> opportunities = new List<Opportunity>{
            buildOpportunity(acc.Id, 'Strategic One', true),
            buildOpportunity(acc.Id, 'Strategic Two', true),
            buildOpportunity(acc.Id, 'Standard One', false)
        };
        insert opportunities;

        Test.startTest();
        Integer count = StrategicHealthService.countStrategicDeals(opportunities);
        Test.stopTest();

        Assert.areEqual(2, count, 'Only flagged opportunities should be counted');
    }

    @isTest
    static void strategicDealFlag_persistsOnUpdate() {
        Opportunity opp = createOpportunity('Deal To Flag', false);

        Test.startTest();
        opp.Strategic_Deal__c = true;
        update opp;
        Test.stopTest();

        opp = [SELECT Strategic_Deal__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.isTrue(opp.Strategic_Deal__c, 'Strategic Deal flag should persist after update');
    }

    private static Opportunity createOpportunity(String name, Boolean isStrategic) {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = buildOpportunity(acc.Id, name, isStrategic);
        insert opp;
        return opp;
    }

    private static Opportunity buildOpportunity(
        Id accountId,
        String name,
        Boolean isStrategic
    ) {
        return new Opportunity(
            Name = name,
            AccountId = accountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Strategic_Deal__c = isStrategic
        );
    }
}

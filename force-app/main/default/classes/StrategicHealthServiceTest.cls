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

    @isTest
    static void resolveStrategicDealOwner_returnsOpportunityOwner() {
        Opportunity opp = createOpportunity('Owner Resolution Deal', true);

        Test.startTest();
        Id ownerId = StrategicHealthService.resolveStrategicDealOwner(opp);
        Test.stopTest();

        Assert.areEqual(opp.OwnerId, ownerId, 'Strategic Deal Owner should resolve to the Opportunity owner');
    }

    @isTest
    static void resolveStrategicDealOwner_returnsNullWhenOpportunityNull() {
        Test.startTest();
        Id ownerId = StrategicHealthService.resolveStrategicDealOwner(null);
        Test.stopTest();

        Assert.isNull(ownerId, 'Null opportunity should not resolve to an owner');
    }

    @isTest
    static void shouldAssignStrategicDealOwner_whenFlaggedAndOwnerBlank() {
        Opportunity opp = createOpportunity('Assignable Deal', true);
        opp = [SELECT Id, OwnerId, Strategic_Deal__c, Strategic_Deal_Owner__c FROM Opportunity WHERE Id = :opp.Id];
        opp.Strategic_Deal_Owner__c = null;

        Test.startTest();
        Boolean shouldAssign = StrategicHealthService.shouldAssignStrategicDealOwner(opp);
        Test.stopTest();

        Assert.isTrue(shouldAssign, 'Flagged deal with blank owner should be eligible for assignment');
    }

    @isTest
    static void shouldAssignStrategicDealOwner_whenNotFlagged() {
        Opportunity opp = createOpportunity('Non Strategic Deal', false);

        Test.startTest();
        Boolean shouldAssign = StrategicHealthService.shouldAssignStrategicDealOwner(opp);
        Test.stopTest();

        Assert.isFalse(shouldAssign, 'Non-strategic deal should not be eligible for owner assignment');
    }

    @isTest
    static void applyStrategicDealOwner_populatesOwnerField() {
        Opportunity opp = createOpportunity('Apply Owner Deal', true);
        opp = [SELECT Id, OwnerId, Strategic_Deal__c, Strategic_Deal_Owner__c FROM Opportunity WHERE Id = :opp.Id];
        opp.Strategic_Deal_Owner__c = null;

        Test.startTest();
        StrategicHealthService.applyStrategicDealOwner(opp);
        update opp;
        Test.stopTest();

        opp = [
            SELECT Strategic_Deal_Owner__c, OwnerId
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        Assert.areEqual(
            opp.OwnerId,
            opp.Strategic_Deal_Owner__c,
            'Strategic Deal Owner should be set to the Opportunity owner'
        );
    }

    @isTest
    static void strategicDealOwner_populatedWhenFlaggedViaFlow() {
        Opportunity opp = createOpportunity('Flow Owner Test', false);

        Test.startTest();
        opp.Strategic_Deal__c = true;
        update opp;
        Test.stopTest();

        opp = [
            SELECT Strategic_Deal_Owner__c, OwnerId
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        Assert.areEqual(
            opp.OwnerId,
            opp.Strategic_Deal_Owner__c,
            'Flow should assign Strategic Deal Owner when deal is flagged'
        );
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
@IsTest
private class OpportunityDiscountApprovalHandlerTest {
    private static Opportunity makeOpp(Decimal discount, Boolean approved) {
        Opportunity opp = new Opportunity(
            Name = 'Discount Test',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Discount_Percent__c = discount,
            Discount_Approved__c = approved
        );
        insert opp;
        return opp;
    }
    @IsTest
    static void blocksUnapprovedDiscount() {
        OpportunityDiscountApprovalHandler.testThresholds = new List<Decimal>{ 10, 20 };
        Opportunity opp = makeOpp(25, false);
        opp.StageName = 'Closed Won';
        Database.SaveResult result = Database.update(opp, false);
        System.assert(!result.isSuccess(), 'Unapproved discount must be blocked');
        System.assert(
            result.getErrors()[0].getMessage().contains('requires approval'),
            'Expected approval error message'
        );
    }
    @IsTest
    static void allowsApprovedDiscount() {
        OpportunityDiscountApprovalHandler.testThresholds = new List<Decimal>{ 10, 20 };
        Opportunity opp = makeOpp(25, true);
        opp.StageName = 'Closed Won';
        Database.SaveResult result = Database.update(opp, false);
        System.assert(result.isSuccess(), 'Approved discount should save');
    }
    @IsTest
    static void allowsDiscountBelowLowestTier() {
        OpportunityDiscountApprovalHandler.testThresholds = new List<Decimal>{ 10, 20 };
        Opportunity opp = makeOpp(5, false);
        opp.StageName = 'Closed Won';
        Database.SaveResult result = Database.update(opp, false);
        System.assert(result.isSuccess(), 'Small discount should save');
    }
    @IsTest
    static void noThresholdsMeansNoBlock() {
        OpportunityDiscountApprovalHandler.testThresholds = new List<Decimal>();
        Opportunity opp = makeOpp(90, false);
        opp.StageName = 'Closed Won';
        Database.SaveResult result = Database.update(opp, false);
        System.assert(result.isSuccess(), 'No tiers configured, no block');
    }
}
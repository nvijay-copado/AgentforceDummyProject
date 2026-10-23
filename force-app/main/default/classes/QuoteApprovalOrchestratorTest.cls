@IsTest
private class QuoteApprovalOrchestratorTest {
    private static Opportunity createOpp(Account a, Decimal discount, Decimal amount) {
        return TestDataFactory.opportunity().forAccount(a.Id).withDiscount(discount).withAmount(amount).create();
    }

    private static List<Quote_Approval_Request__c> requests() {
        return [
            SELECT Required_Level__c, Credit_Review_Required__c, Available_Credit__c, Open_Key__c,
                   Discount_Percent__c, Lifecycle__c, Decision__c
            FROM Quote_Approval_Request__c
        ];
    }

    @IsTest
    static void belowThresholdCreatesNothing() {
        Account a = TestDataFactory.createAccountWithCode('CUST001');
        createOpp(a, 5, 100000);
        System.assertEquals(0, requests().size());
    }

    @IsTest
    static void managerWhenCreditIsSufficient() {
        Account a = TestDataFactory.createAccountWithCode('CUST001');
        createOpp(a, 15, 100000);
        List<Quote_Approval_Request__c> rows = requests();
        System.assertEquals(1, rows.size());
        System.assertEquals('MANAGER', rows[0].Required_Level__c);
        System.assertEquals(false, rows[0].Credit_Review_Required__c);
        System.assertNotEquals(null, rows[0].Available_Credit__c);
    }

    @IsTest
    static void creditShortfallRaisesLevel() {
        Account a = TestDataFactory.createAccountWithCode('CUST002');
        createOpp(a, 15, 200000);
        System.assertEquals('DIRECTOR', requests()[0].Required_Level__c);
        System.assertEquals(false, requests()[0].Credit_Review_Required__c);
    }

    @IsTest
    static void shortfallAtDirectorRequiresCreditReview() {
        Account a = TestDataFactory.createAccountWithCode('CUST002');
        createOpp(a, 30, 200000);
        System.assertEquals('DIRECTOR', requests()[0].Required_Level__c);
        System.assertEquals(true, requests()[0].Credit_Review_Required__c);
    }

    @IsTest
    static void blankCustomerCodeRequiresCreditReview() {
        Account a = new Account(Name = 'No Code');
        insert a;
        createOpp(a, 15, 1000);
        List<Quote_Approval_Request__c> rows = requests();
        System.assertEquals(1, rows.size());
        System.assertEquals(true, rows[0].Credit_Review_Required__c);
        System.assertEquals(null, rows[0].Available_Credit__c);
        System.assertEquals('Pending', rows[0].Decision__c);
    }

    @IsTest
    static void unknownCustomerCodeRequiresCreditReview() {
        Account a = TestDataFactory.createAccountWithCode('ZZZ999');
        createOpp(a, 15, 1000);
        System.assertEquals(true, requests()[0].Credit_Review_Required__c);
    }

    @IsTest
    static void resubmissionUpdatesTheOpenRequest() {
        Account a = TestDataFactory.createAccountWithCode('CUST001');
        Opportunity o = createOpp(a, 15, 100000);
        o.Discount_Percent__c = 30;
        update o;
        o.Discount_Percent__c = 30;
        o.Amount = 120000;
        update o;
        List<Quote_Approval_Request__c> rows = requests();
        System.assertEquals(1, rows.size());
        System.assertEquals('DIRECTOR', rows[0].Required_Level__c);
        System.assertEquals(30, rows[0].Discount_Percent__c);
    }

    @IsTest
    static void droppingBelowThresholdWithdrawsTheRequest() {
        Account a = TestDataFactory.createAccountWithCode('CUST001');
        Opportunity o = createOpp(a, 15, 100000);
        o.Discount_Percent__c = 5;
        update o;
        List<Quote_Approval_Request__c> rows = requests();
        System.assertEquals(1, rows.size());
        System.assertEquals('Cancelled', rows[0].Lifecycle__c);
        System.assertEquals(null, rows[0].Open_Key__c);
    }

    @IsTest
    static void bulkInsertHandles200Opportunities() {
        Account a = TestDataFactory.createAccountWithCode('CUST001');
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            opps.add(TestDataFactory.opportunity().forAccount(a.Id).withDiscount(15).withAmount(1000).build());
        }
        Test.startTest();
        insert opps;
        Test.stopTest();
        System.assertEquals(200, requests().size());
    }
}
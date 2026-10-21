@IsTest
private class AccountRatingBackfillTest {
    @IsTest
    static void ratesByRevenue() {
        System.assertEquals('Hot', AccountRatingBackfill.rate(2000000));
        System.assertEquals('Warm', AccountRatingBackfill.rate(500000));
        System.assertEquals('Cold', AccountRatingBackfill.rate(10));
        System.assertEquals(null, AccountRatingBackfill.rate(null));
    }

    @IsTest
    static void backfillUpdatesAccounts() {
        List<Account> accs = new List<Account>{
            new Account(Name = 'A1', AnnualRevenue = 2000000),
            new Account(Name = 'A2', AnnualRevenue = 200000),
            new Account(Name = 'A3', AnnualRevenue = 5)
        };
        insert accs;
        Test.startTest();
        AccountRatingBackfill.run();
        Test.stopTest();
        Map<String, Account> m = new Map<String, Account>();
        for (Account a : [SELECT Name, Rating FROM Account WHERE Id IN :accs]) {
            m.put(a.Name, a);
        }
        System.assertEquals('Hot', m.get('A1').Rating);
        System.assertEquals('Warm', m.get('A2').Rating);
        System.assertEquals('Cold', m.get('A3').Rating);
    }
}
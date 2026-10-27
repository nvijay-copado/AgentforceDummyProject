@IsTest
private class AccountSearchControllerTest {
    @TestSetup
    static void setup() {
        List<Account> accs = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accs.add(new Account(Name = 'Acme ' + i, Industry = 'Technology', BillingCountry = 'United States', BillingState = 'California'));
        }
        accs.add(new Account(Name = 'Globex', Industry = 'Energy', BillingCountry = 'United States', BillingState = 'New York'));
        insert accs;
    }

    @IsTest
    static void filtersByName() {
        AccountSearchController.SearchResult r = AccountSearchController.search('Acme', null, null, 10, 1);
        System.assertEquals(5, r.totalCount);
        System.assertEquals(5, r.records.size());
    }

    @IsTest
    static void filtersCombined() {
        AccountSearchController.SearchResult r = AccountSearchController.search('Glo', 'Energy', 'New York', 10, 1);
        System.assertEquals(1, r.totalCount);
        System.assertEquals('Globex', r.records[0].Name);
    }

    @IsTest
    static void noResults() {
        AccountSearchController.SearchResult r = AccountSearchController.search('Nope', null, null, 10, 1);
        System.assertEquals(0, r.totalCount);
        System.assert(r.records.isEmpty());
    }

    @IsTest
    static void paginates() {
        AccountSearchController.SearchResult r = AccountSearchController.search(null, 'Technology', null, 2, 3);
        System.assertEquals(5, r.totalCount);
        System.assertEquals(1, r.records.size());
    }

    @IsTest
    static void defaultsPaging() {
        AccountSearchController.SearchResult r = AccountSearchController.search(null, null, null, null, null);
        System.assertEquals(6, r.records.size());
    }

    @IsTest
    static void rejectsDeepOffset() {
        try {
            AccountSearchController.search(null, null, null, 200, 50);
            System.assert(false, 'Expected exception');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
    }
}
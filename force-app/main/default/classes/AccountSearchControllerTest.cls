@IsTest
private class AccountSearchControllerTest {
    @TestSetup
    static void setup() {
        insert new List<Account>{
            new Account(Name = 'Acme Corp', Industry = 'Technology', BillingCountry = 'United States', BillingState = 'California'),
            new Account(Name = 'Acme Foods', Industry = 'Food', BillingCountry = 'United States', BillingState = 'New York'),
            new Account(Name = 'Globex', Industry = 'Technology', BillingCountry = 'United States', BillingState = 'New York')
        };
    }

    @IsTest
    static void filtersByName() {
        AccountSearchController.SearchResult r = AccountSearchController.searchAccounts('acme', null, null, 25, 1);
        System.assertEquals(2, r.totalCount);
        System.assertEquals(2, r.records.size());
    }

    @IsTest
    static void filtersCombined() {
        AccountSearchController.SearchResult r = AccountSearchController.searchAccounts('acme', 'Technology', 'California', 25, 1);
        System.assertEquals(1, r.records.size());
        System.assertEquals('Acme Corp', r.records[0].Name);
    }

    @IsTest
    static void noResults() {
        AccountSearchController.SearchResult r = AccountSearchController.searchAccounts('zzz', null, null, null, null);
        System.assertEquals(0, r.totalCount);
        System.assert(r.records.isEmpty());
    }

    @IsTest
    static void paginates() {
        AccountSearchController.SearchResult r = AccountSearchController.searchAccounts(null, null, null, 2, 2);
        System.assertEquals(3, r.totalCount);
        System.assertEquals(1, r.records.size());
    }

    @IsTest
    static void rejectsDeepOffset() {
        try {
            AccountSearchController.searchAccounts(null, null, null, 200, 50);
            System.assert(false, 'Expected exception');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
    }
}
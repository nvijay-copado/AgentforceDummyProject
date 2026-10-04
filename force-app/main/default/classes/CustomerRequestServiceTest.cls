@isTest
private class CustomerRequestServiceTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Acme Test Account');
        insert acc;
    }

    @isTest
    static void testCreateCustomerRequestsBulk() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Customer_Request__c> requests = new List<Customer_Request__c>();
        for (Integer i = 0; i < 200; i++) {
            requests.add(new Customer_Request__c(
                Name = 'Request ' + i,
                Account__c = acc.Id,
                Request_Type__c = 'Question',
                Priority__c = 'Medium',
                Requested_Date__c = Date.today()
            ));
        }

        Test.startTest();
        List<Customer_Request__c> inserted = CustomerRequestService.createCustomerRequests(requests);
        Test.stopTest();

        System.assertEquals(200, inserted.size(), 'All 200 records should be returned');
        List<Customer_Request__c> fromDb = [SELECT Id, Status__c FROM Customer_Request__c];
        System.assertEquals(200, fromDb.size(), 'All 200 records should be inserted');
        for (Customer_Request__c request : fromDb) {
            System.assertEquals('New', request.Status__c, 'Default status should be New when not provided');
        }
    }

    @isTest
    static void testCreateCustomerRequestsEmptyOrNullInput() {
        Test.startTest();
        List<Customer_Request__c> resultEmpty = CustomerRequestService.createCustomerRequests(new List<Customer_Request__c>());
        List<Customer_Request__c> resultNull = CustomerRequestService.createCustomerRequests(null);
        Test.stopTest();

        System.assertEquals(0, resultEmpty.size(), 'Empty input should return an empty list');
        System.assertEquals(0, resultNull.size(), 'Null input should return an empty list');
    }

    @isTest
    static void testSearchCustomerRequestsWithFilters() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        insert new List<Customer_Request__c>{
            new Customer_Request__c(Name = 'Req A', Account__c = acc.Id, Status__c = 'New', Priority__c = 'High', Requested_Date__c = Date.today()),
            new Customer_Request__c(Name = 'Req B', Account__c = acc.Id, Status__c = 'Completed', Priority__c = 'Low', Requested_Date__c = Date.today().addDays(-1)),
            new Customer_Request__c(Name = 'Req C', Account__c = acc.Id, Status__c = 'New', Priority__c = 'Low', Requested_Date__c = Date.today().addDays(-2))
        };

        Test.startTest();
        List<Customer_Request__c> allForAccount = CustomerRequestService.searchCustomerRequests(acc.Id, null, null);
        List<Customer_Request__c> newOnly = CustomerRequestService.searchCustomerRequests(acc.Id, 'New', null);
        List<Customer_Request__c> newHighPriority = CustomerRequestService.searchCustomerRequests(acc.Id, 'New', 'High');
        List<Customer_Request__c> noMatch = CustomerRequestService.searchCustomerRequests(acc.Id, 'Blocked', null);
        Test.stopTest();

        System.assertEquals(3, allForAccount.size(), 'All 3 records should be returned with no filters');
        System.assertEquals(2, newOnly.size(), 'Only the 2 New records should be returned');
        System.assertEquals(1, newHighPriority.size(), 'Only 1 record matches New + High priority');
        System.assertEquals(0, noMatch.size(), 'No records should match Blocked status');
    }

    @isTest
    static void testSearchCustomerRequestsWithoutAccountFilter() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        insert new List<Customer_Request__c>{
            new Customer_Request__c(Name = 'Req D', Account__c = acc.Id, Status__c = 'New', Priority__c = 'High', Requested_Date__c = Date.today()),
            new Customer_Request__c(Name = 'Req E', Account__c = acc.Id, Status__c = 'Blocked', Priority__c = 'Low', Requested_Date__c = Date.today().addDays(-1))
        };

        Test.startTest();
        List<Customer_Request__c> all = CustomerRequestService.searchCustomerRequests(null, null, null);
        List<Customer_Request__c> priorityOnly = CustomerRequestService.searchCustomerRequests(null, null, 'High');
        List<Customer_Request__c> priorityNoMatch = CustomerRequestService.searchCustomerRequests(null, 'New', 'Low');
        Test.stopTest();

        System.assertEquals(2, all.size(), 'Both records should be returned with no filters at all');
        System.assertEquals(1, priorityOnly.size(), 'Only 1 record matches High priority');
        System.assertEquals(0, priorityNoMatch.size(), 'No record matches New status with Low priority');
    }

    @isTest
    static void testUpdateStatusBulk() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Customer_Request__c> requests = new List<Customer_Request__c>();
        for (Integer i = 0; i < 50; i++) {
            requests.add(new Customer_Request__c(Name = 'Req ' + i, Account__c = acc.Id, Status__c = 'New'));
        }
        insert requests;
        Set<Id> ids = new Map<Id, Customer_Request__c>(requests).keySet();

        Test.startTest();
        List<Customer_Request__c> updated = CustomerRequestService.updateStatus(ids, 'In Progress');
        Test.stopTest();

        System.assertEquals(50, updated.size(), 'All 50 records should be updated');
        List<Customer_Request__c> fromDb = [SELECT Status__c FROM Customer_Request__c WHERE Id IN :ids];
        for (Customer_Request__c request : fromDb) {
            System.assertEquals('In Progress', request.Status__c, 'Status should be updated to In Progress');
        }
    }

    @isTest
    static void testUpdateStatusEmptyOrBlankInput() {
        Test.startTest();
        List<Customer_Request__c> resultEmptySet = CustomerRequestService.updateStatus(new Set<Id>(), 'New');
        List<Customer_Request__c> resultBlankStatus = CustomerRequestService.updateStatus(new Set<Id>{ '001000000000000AAA' }, '');
        Test.stopTest();

        System.assertEquals(0, resultEmptySet.size(), 'Empty Id set should return an empty list');
        System.assertEquals(0, resultBlankStatus.size(), 'Blank status should return an empty list');
    }
}
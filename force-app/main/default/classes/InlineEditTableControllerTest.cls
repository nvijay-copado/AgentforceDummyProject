@IsTest
private class InlineEditTableControllerTest {
    @TestSetup
    static void setup() {
        Account a = new Account(Name = 'Acme');
        insert a;
        insert new List<Contact>{
            new Contact(LastName = 'One', AccountId = a.Id),
            new Contact(LastName = 'Two', AccountId = a.Id)
        };
    }

    @IsTest
    static void fetchesContactsForAccount() {
        Account a = [SELECT Id FROM Account LIMIT 1];
        List<SObject> rows = InlineEditTableController.getRecords('Contact', new List<String>{ 'LastName' }, 'AccountId', a.Id, 10);
        System.assertEquals(2, rows.size());
    }

    @IsTest
    static void fetchesWithoutParentAndDefaultLimit() {
        List<SObject> rows = InlineEditTableController.getRecords('Account', new List<String>{ 'Name', 'Id' }, null, null, null);
        System.assertEquals(1, rows.size());
    }

    @IsTest
    static void rejectsInvalidInput() {
        try {
            InlineEditTableController.getRecords('NotAnObject__x', new List<String>{ 'Name' }, null, null, 5);
            System.assert(false, 'expected exception');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        try {
            InlineEditTableController.getRecords('Account', new List<String>{ 'Bogus__c' }, null, null, 5);
            System.assert(false, 'expected exception');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        try {
            InlineEditTableController.getRecords('Account', new List<String>{ 'Name' }, 'Bogus__c', UserInfo.getUserId(), 5);
            System.assert(false, 'expected exception');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
    }

    @IsTest
    static void savesRecords() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        c.LastName = 'Renamed';
        InlineEditTableController.SaveResult r = InlineEditTableController.saveRecords(new List<SObject>{ c });
        System.assert(r.success);
        System.assertEquals('Renamed', [SELECT LastName FROM Contact WHERE Id = :c.Id].LastName);
        System.assert(InlineEditTableController.saveRecords(null).success);
    }

    @IsTest
    static void reportsRowErrors() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        c.LastName = null;
        InlineEditTableController.SaveResult r = InlineEditTableController.saveRecords(new List<SObject>{ c });
        System.assert(!r.success);
        System.assert(r.rowErrors.containsKey(c.Id));
    }
}
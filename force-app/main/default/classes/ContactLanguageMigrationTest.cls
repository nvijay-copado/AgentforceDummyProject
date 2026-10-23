@IsTest
private class ContactLanguageMigrationTest {
    @TestSetup
    static void setup() {
        insert new List<Contact>{
            new Contact(LastName = 'A', Languages__c = 'English'),
            new Contact(LastName = 'B', Languages__c = 'French, English'),
            new Contact(LastName = 'C', Languages__c = 'Klingon'),
            new Contact(LastName = 'D')
        };
    }

    @IsTest
    static void snapshotCopiesLegacyValue() {
        Test.startTest();
        Database.executeBatch(new ContactLanguageSnapshot());
        Test.stopTest();
        Contact b = [SELECT Legacy_Languages_Snapshot__c FROM Contact WHERE LastName = 'B'];
        System.assertEquals('French, English', b.Legacy_Languages_Snapshot__c);
        Contact d = [SELECT Legacy_Languages_Snapshot__c FROM Contact WHERE LastName = 'D'];
        System.assertEquals(null, d.Legacy_Languages_Snapshot__c);
    }

    @IsTest
    static void migrationMapsAndReportsExceptions() {
        ContactLanguageMigrationBatch job = new ContactLanguageMigrationBatch(
            new Map<String, String>{ 'english' => 'English', 'french' => 'French' });
        job.execute(null, [SELECT Id, Languages__c FROM Contact WHERE Languages__c != null]);
        Map<String, Contact> byName = new Map<String, Contact>();
        for (Contact c : [SELECT LastName, Languages_Structured__c FROM Contact]) { byName.put(c.LastName, c); }
        System.assertEquals('English', byName.get('A').Languages_Structured__c);
        System.assertEquals(2, byName.get('B').Languages_Structured__c.split(';').size());
        System.assertEquals(null, byName.get('C').Languages_Structured__c);
        System.assertEquals(null, byName.get('D').Languages_Structured__c);
        System.assertEquals(2, job.migrated);
        System.assertEquals(1, job.exceptions.size());
    }
}
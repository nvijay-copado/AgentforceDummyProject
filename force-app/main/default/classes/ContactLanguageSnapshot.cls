public with sharing class ContactLanguageSnapshot implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Languages__c FROM Contact WHERE Languages__c != null');
    }
    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        for (Contact c : scope) {
            c.Legacy_Languages_Snapshot__c = c.Languages__c;
        }
        update scope;
    }
    public void finish(Database.BatchableContext bc) {}
}
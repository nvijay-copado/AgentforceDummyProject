public with sharing class ContactLanguageMigrationBatch implements Database.Batchable<SObject>, Database.Stateful {
    public List<String> exceptions = new List<String>();
    public Integer migrated = 0;
    private Map<String, String> mapping;

    public ContactLanguageMigrationBatch() {
        mapping = new Map<String, String>();
        for (Legacy_Value_Mapping__mdt m : Legacy_Value_Mapping__mdt.getAll().values()) {
            mapping.put(m.Legacy_Value__c.toLowerCase(), m.New_Value__c);
        }
    }

    @TestVisible
    private ContactLanguageMigrationBatch(Map<String, String> overrideMapping) {
        mapping = overrideMapping;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Languages__c FROM Contact WHERE Languages__c != null AND Languages_Structured__c = null');
    }

    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        List<Contact> toUpdate = new List<Contact>();
        for (Contact c : scope) {
            List<String> mapped = new List<String>();
            List<String> unmapped = new List<String>();
            for (String token : c.Languages__c.split('[,;/]')) {
                String t = token.trim();
                if (String.isBlank(t)) { continue; }
                String target = mapping.get(t.toLowerCase());
                if (target == null) { unmapped.add(t); } else if (!mapped.contains(target)) { mapped.add(target); }
            }
            if (!unmapped.isEmpty()) {
                exceptions.add(c.Id + ': unmapped value(s) ' + String.join(unmapped, ', '));
            }
            if (!mapped.isEmpty()) {
                c.Languages_Structured__c = String.join(mapped, ';');
                toUpdate.add(c);
            }
        }
        update toUpdate;
        migrated += toUpdate.size();
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'Migrated ' + migrated + ' contacts. Exceptions: ' + exceptions);
    }
}
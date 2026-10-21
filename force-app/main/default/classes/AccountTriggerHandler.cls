public with sharing class AccountTriggerHandler extends TriggerHandler {
    protected override void beforeInsert(List<SObject> newRecords) {
        trimNames((List<Account>) newRecords);
    }
    protected override void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        trimNames((List<Account>) newRecords);
    }
    private void trimNames(List<Account> accounts) {
        for (Account acc : accounts) {
            if (acc.Name != null) {
                acc.Name = acc.Name.trim();
            }
        }
    }
}
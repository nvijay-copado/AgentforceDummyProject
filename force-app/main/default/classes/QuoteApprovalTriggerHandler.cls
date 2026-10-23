public with sharing class QuoteApprovalTriggerHandler extends TriggerHandler {
    protected override void afterInsert(List<SObject> newRecords) {
        QuoteApprovalOrchestrator.evaluate((List<Opportunity>) newRecords, null);
    }

    protected override void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        QuoteApprovalOrchestrator.evaluate((List<Opportunity>) newRecords, (Map<Id, Opportunity>) oldMap);
    }
}
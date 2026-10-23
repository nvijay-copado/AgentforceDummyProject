public with sharing class QuoteEscalationBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id, CreatedDate, OwnerId, Decision__c, Escalation_Level__c
                FROM Quote_Approval_Request__c
                WHERE Decision__c = :QuoteApprovalOrchestrator.DECISION_PENDING
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<Quote_Approval_Request__c> scope) {
        QuoteEscalationService.process(scope, Datetime.now());
    }

    public void finish(Database.BatchableContext bc) {
    }
}
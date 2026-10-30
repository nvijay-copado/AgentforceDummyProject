public with sharing class LeadScoreBackfillBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, OwnerId, Lead_Score__c, Company, Email, Phone, AnnualRevenue, NumberOfEmployees, LeadSource FROM Lead WHERE IsConverted = false'
        );
    }
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        LeadScoreEngine.applyScores(scope);
    }
    public void finish(Database.BatchableContext bc) {}
}
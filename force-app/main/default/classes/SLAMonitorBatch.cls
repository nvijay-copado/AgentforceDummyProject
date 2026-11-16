/** Evaluates open, non-paused Cases against their SLA policy and escalates them. */
public with sharing class SLAMonitorBatch implements Database.Batchable<SObject> {
    @TestVisible
    private Datetime nowOverride;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id,
                    Priority,
                    Status,
                    OwnerId,
                    SLA_Start_Date__c,
                    SLA_Due_Date__c,
                    SLA_Status__c,
                    Escalation_Level__c
                FROM Case
                WHERE
                    IsClosed = FALSE
                    AND SLA_Status__c IN ('On Track', 'At Risk')
                    AND SLA_Due_Date__c != NULL
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<Case> scope) {
        EscalationService.process(scope, nowOverride != null ? nowOverride : System.now());
    }

    public void finish(Database.BatchableContext bc) {
    }
}
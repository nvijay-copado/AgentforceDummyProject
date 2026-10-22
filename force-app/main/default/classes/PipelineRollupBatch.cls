/**
 * Daily rollup of Opportunity pipeline metrics by region and stage into Pipeline_Rollup__c.
 * Region is derived from the parent Account billing state.
 */
public with sharing class PipelineRollupBatch implements Database.Batchable<AggregateResult>, Database.Stateful {
    private static final String UNASSIGNED = 'Unassigned';
    public Integer rowsWritten = 0;

    public Iterable<AggregateResult> start(Database.BatchableContext bc) {
        return [
            SELECT Account.BillingState region, StageName stage, COUNT(Id) cnt, SUM(Amount) total
            FROM Opportunity
            GROUP BY Account.BillingState, StageName
        ];
    }

    public void execute(Database.BatchableContext bc, List<AggregateResult> scope) {
        Date today = Date.today();
        List<Pipeline_Rollup__c> rows = new List<Pipeline_Rollup__c>();
        for (AggregateResult ar : scope) {
            String region = (String) ar.get('region');
            if (String.isBlank(region)) {
                region = UNASSIGNED;
            }
            String stage = (String) ar.get('stage');
            Decimal total = (Decimal) ar.get('total');
            rows.add(new Pipeline_Rollup__c(
                Name = region + ' - ' + stage,
                Region__c = region,
                Stage__c = stage,
                Rollup_Date__c = today,
                Opportunity_Count__c = (Integer) ar.get('cnt'),
                Total_Amount__c = total == null ? 0 : total,
                Rollup_Key__c = today.format() + '|' + region + '|' + stage
            ));
        }
        if (!rows.isEmpty() && Schema.sObjectType.Pipeline_Rollup__c.isCreateable()) {
            Database.upsert(rows, Pipeline_Rollup__c.Rollup_Key__c, true);
            rowsWritten += rows.size();
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'PipelineRollupBatch wrote ' + rowsWritten + ' rows');
    }
}
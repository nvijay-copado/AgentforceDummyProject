@IsTest
private class PipelineRollupBatchTest {
    @IsTest
    static void rollupMatchesSourceTotals() {
        Account a = new Account(Name = 'Acme', BillingCountryCode = 'US', BillingStateCode = 'CA');
        insert a;
        String regionName = [SELECT BillingState FROM Account WHERE Id = :a.Id].BillingState;
        insert new List<Opportunity>{
            new Opportunity(Name = 'O1', AccountId = a.Id, StageName = 'Prospecting', CloseDate = Date.today().addDays(5), Amount = 100),
            new Opportunity(Name = 'O2', AccountId = a.Id, StageName = 'Prospecting', CloseDate = Date.today().addDays(5), Amount = 50),
            new Opportunity(Name = 'O3', StageName = 'Qualification', CloseDate = Date.today().addDays(5), Amount = 10)
        };
        Test.startTest();
        Database.executeBatch(new PipelineRollupBatch(), 200);
        Test.stopTest();

        Decimal srcTotal = 0;
        Integer srcCount = 0;
        for (AggregateResult ar : [SELECT COUNT(Id) c, SUM(Amount) t FROM Opportunity]) {
            srcCount = (Integer) ar.get('c');
            srcTotal = (Decimal) ar.get('t');
        }
        Decimal rollTotal = 0;
        Decimal rollCount = 0;
        for (Pipeline_Rollup__c r : [SELECT Opportunity_Count__c, Total_Amount__c FROM Pipeline_Rollup__c]) {
            rollTotal += r.Total_Amount__c;
            rollCount += r.Opportunity_Count__c;
        }
        System.assertEquals(srcTotal, rollTotal, 'Rollup amount must match source');
        System.assertEquals(srcCount, rollCount, 'Rollup count must match source');
        List<Pipeline_Rollup__c> ca = [SELECT Opportunity_Count__c, Total_Amount__c FROM Pipeline_Rollup__c WHERE Region__c = :regionName AND Stage__c = 'Prospecting'];
        System.assertEquals(1, ca.size());
        System.assertEquals(150, ca[0].Total_Amount__c);
        System.assertEquals(1, [SELECT COUNT() FROM Pipeline_Rollup__c WHERE Region__c = 'Unassigned']);
    }

    @IsTest
    static void rerunIsIdempotent() {
        insert new Opportunity(Name = 'O1', StageName = 'Prospecting', CloseDate = Date.today().addDays(5), Amount = 5);
        Test.startTest();
        Database.executeBatch(new PipelineRollupBatch(), 200);
        Test.stopTest();
        Integer before = [SELECT COUNT() FROM Pipeline_Rollup__c];
        Database.executeBatch(new PipelineRollupBatch(), 200);
        System.assert(before > 0);
    }

    @IsTest
    static void schedulerRegistersJob() {
        Test.startTest();
        Id jobId = PipelineRollupScheduler.schedule();
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM CronTrigger WHERE Id = :jobId]);
    }
}
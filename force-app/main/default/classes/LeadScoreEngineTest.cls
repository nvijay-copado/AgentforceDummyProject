@IsTest
private class LeadScoreEngineTest {
    static List<Lead_Scoring_Rule__mdt> rules() {
        return new List<Lead_Scoring_Rule__mdt>{
            new Lead_Scoring_Rule__mdt(Field_API_Name__c = 'Email', Operator__c = 'NotBlank', Points__c = 10),
            new Lead_Scoring_Rule__mdt(Field_API_Name__c = 'AnnualRevenue', Operator__c = 'GreaterOrEqual', Value__c = '1000', Points__c = 20),
            new Lead_Scoring_Rule__mdt(Field_API_Name__c = 'LeadSource', Operator__c = 'Equals', Value__c = 'Web', Points__c = 10),
            new Lead_Scoring_Rule__mdt(Field_API_Name__c = 'Company', Operator__c = 'Contains', Value__c = 'zzz', Points__c = 5)
        };
    }

    static void useOverrides() {
        LeadScoreEngine.rulesOverride = rules();
        LeadScoreEngine.routingOverride = new List<Lead_Routing_Rule__mdt>{
            new Lead_Routing_Rule__mdt(Min_Score__c = 30, Queue_Developer_Name__c = 'No_Such_Queue')
        };
    }

    @IsTest
    static void calculatesScoreFromRules() {
        Lead full = new Lead(LastName = 'A', Company = 'Acme', Email = 'a@x.com', AnnualRevenue = 5000, LeadSource = 'Web');
        Lead empty = new Lead(LastName = 'B', Company = 'zzzCorp');
        System.assertEquals(40, LeadScoreEngine.calculate(full, rules()));
        System.assertEquals(5, LeadScoreEngine.calculate(empty, rules()));
    }

    @IsTest
    static void unknownOperatorDoesNotMatch() {
        Lead l = new Lead(LastName = 'B', Company = 'Co');
        Lead_Scoring_Rule__mdt bad = new Lead_Scoring_Rule__mdt(Field_API_Name__c = 'Company', Operator__c = 'Bogus', Value__c = 'x', Points__c = 1);
        System.assertEquals(false, LeadScoreEngine.matches(l, bad));
    }

    @IsTest
    static void routesToHighestQualifyingQueue() {
        Id owner = UserInfo.getUserId();
        Id hot = '00G000000000001AAA';
        Id warm = '00G000000000002AAA';
        List<Lead_Routing_Rule__mdt> routing = new List<Lead_Routing_Rule__mdt>{
            new Lead_Routing_Rule__mdt(Min_Score__c = 20, Queue_Developer_Name__c = 'Warm'),
            new Lead_Routing_Rule__mdt(Min_Score__c = 40, Queue_Developer_Name__c = 'Hot')
        };
        Map<String, Id> queues = new Map<String, Id>{ 'Hot' => hot, 'Warm' => warm };
        System.assertEquals(hot, LeadScoreEngine.route(45, owner, routing, queues));
        System.assertEquals(warm, LeadScoreEngine.route(25, owner, routing, queues));
        System.assertEquals(owner, LeadScoreEngine.route(5, owner, routing, queues));
        System.assertEquals(owner, LeadScoreEngine.route(45, owner, routing, new Map<String, Id>()));
    }

    @IsTest
    static void invocableScoresLeads() {
        useOverrides();
        Lead l = new Lead(LastName = 'A', Company = 'Acme', Email = 'a@x.com', AnnualRevenue = 5000, LeadSource = 'Web');
        insert l;
        LeadScoreEngine.Request r = new LeadScoreEngine.Request();
        r.leadId = l.Id;
        Test.startTest();
        LeadScoreEngine.scoreLeads(new List<LeadScoreEngine.Request>{ r });
        Test.stopTest();
        System.assertEquals(0, LeadScoreEngine.scoreByIds(new Set<Id>{ l.Id }), 'Second pass must be a no-op');
    }

    @IsTest
    static void backfillProcessesExistingLeads() {
        useOverrides();
        List<Lead> ls = new List<Lead>();
        for (Integer i = 0; i < 20; i++) {
            ls.add(new Lead(LastName = 'L' + i, Company = 'Co', Email = 'l' + i + '@x.com'));
        }
        insert ls;
        Test.startTest();
        Database.executeBatch(new LeadScoreBackfillBatch(), 200);
        Test.stopTest();
        System.assertEquals(0, LeadScoreEngine.scoreByIds(new Map<Id, Lead>(ls).keySet()), 'Backfill should have scored every lead');
    }
}
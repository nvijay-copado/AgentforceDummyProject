@isTest
private class LeadQualificationHandlerTest {
    @isTest
    static void qualifyLeads_hotLead_createsInteractionAndTask() {
        Lead ld = new Lead(
            LastName = 'HotLead',
            Company = 'Enterprise Co',
            Title = 'VP Sales',
            NumberOfEmployees = 1000,
            AnnualRevenue = 20000000,
            Requested_Demo__c = true
        );
        insert ld;

        LeadQualificationHandler.QualificationRequest request = new LeadQualificationHandler.QualificationRequest();
        request.leadId = ld.Id;

        Test.startTest();
        List<LeadQualificationHandler.QualificationResult> results = LeadQualificationHandler.qualifyLeads(
            new List<LeadQualificationHandler.QualificationRequest>{ request }
        );
        Test.stopTest();

        Assert.areEqual(1, results.size());
        Assert.areEqual(100, results[0].leadScore);
        Assert.areEqual('Hot', results[0].qualificationStatus);
        Assert.isTrue(results[0].isHotLead);

        Lead updatedLead = [
            SELECT Lead_Score__c, Qualification_Status__c, AI_Summary__c
            FROM Lead
            WHERE Id = :ld.Id
        ];
        Assert.areEqual(100, updatedLead.Lead_Score__c);
        Assert.areEqual('Hot', updatedLead.Qualification_Status__c);
        Assert.isNotNull(updatedLead.AI_Summary__c);

        List<Sales_Agent_Interaction__c> interactions = [
            SELECT Lead_Score__c, Status__c, Recommendation__c
            FROM Sales_Agent_Interaction__c
            WHERE Lead__c = :ld.Id
        ];
        Assert.areEqual(1, interactions.size());
        Assert.areEqual(100, interactions[0].Lead_Score__c);
        Assert.areEqual('Escalated', interactions[0].Status__c);
        Assert.areEqual(
            'Schedule Demo Immediately',
            interactions[0].Recommendation__c
        );

        List<Task> tasks = [SELECT Subject, Priority FROM Task WHERE WhoId = :ld.Id];
        Assert.areEqual(1, tasks.size());
        Assert.areEqual('High', tasks[0].Priority);
    }

    @isTest
    static void qualifyLeads_coldLead_createsInteractionWithoutTask() {
        Lead ld = new Lead(
            LastName = 'ColdLead',
            Company = 'Startup',
            Title = 'Intern',
            NumberOfEmployees = 10
        );
        insert ld;

        LeadQualificationHandler.QualificationRequest request = new LeadQualificationHandler.QualificationRequest();
        request.leadId = ld.Id;

        Test.startTest();
        List<LeadQualificationHandler.QualificationResult> results = LeadQualificationHandler.qualifyLeads(
            new List<LeadQualificationHandler.QualificationRequest>{ request }
        );
        Test.stopTest();

        Assert.areEqual(1, results.size());
        Assert.areEqual(0, results[0].leadScore);
        Assert.areEqual('Cold', results[0].qualificationStatus);
        Assert.isFalse(results[0].isHotLead);

        List<Sales_Agent_Interaction__c> interactions = [
            SELECT Status__c
            FROM Sales_Agent_Interaction__c
            WHERE Lead__c = :ld.Id
        ];
        Assert.areEqual(1, interactions.size());
        Assert.areEqual('New', interactions[0].Status__c);

        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId = :ld.Id];
        Assert.areEqual(0, tasks.size());
    }
}

@isTest
private class LeadScoringServiceTest {
    @isTest
    static void calculateScore_allCriteriaMet_returns100() {
        Lead ld = new Lead(
            LastName = 'Smith',
            Company = 'Acme Corp',
            Title = 'VP Sales',
            NumberOfEmployees = 1000,
            AnnualRevenue = 15000000,
            Requested_Demo__c = true
        );

        Integer score = LeadScoringService.calculateScore(ld);

        Assert.areEqual(100, score);
        Assert.areEqual('Hot', LeadScoringService.getQualificationStatus(score));
        Assert.areEqual(
            'Schedule Demo Immediately',
            LeadScoringService.getRecommendation(score)
        );
    }

    @isTest
    static void calculateScore_partialCriteria_returnsWarm() {
        Lead ld = new Lead(
            LastName = 'Jones',
            Company = 'Mid Corp',
            Title = 'Director of IT',
            NumberOfEmployees = 600,
            AnnualRevenue = 5000000
        );

        Integer score = LeadScoringService.calculateScore(ld);

        Assert.areEqual(55, score);
        Assert.areEqual('Warm', LeadScoringService.getQualificationStatus(score));
        Assert.areEqual(
            'Nurture with Product Content',
            LeadScoringService.getRecommendation(score)
        );
    }

    @isTest
    static void calculateScore_noCriteria_returnsCold() {
        Lead ld = new Lead(
            LastName = 'Brown',
            Company = 'Small Co',
            Title = 'Analyst',
            NumberOfEmployees = 50,
            AnnualRevenue = 100000
        );

        Integer score = LeadScoringService.calculateScore(ld);

        Assert.areEqual(0, score);
        Assert.areEqual('Cold', LeadScoringService.getQualificationStatus(score));
        Assert.areEqual(
            'Add to Marketing Campaign',
            LeadScoringService.getRecommendation(score)
        );
    }

    @isTest
    static void generateAiSummary_includesLeadDetails() {
        Lead ld = new Lead(
            FirstName = 'Jamie',
            LastName = 'Taylor',
            Company = 'Global Inc',
            Title = 'VP Engineering',
            NumberOfEmployees = 800,
            Requested_Demo__c = true
        );
        Integer score = LeadScoringService.calculateScore(ld);
        String status = LeadScoringService.getQualificationStatus(score);

        String summary = LeadScoringService.generateAiSummary(ld, score, status);

        Assert.isTrue(summary.contains('Taylor'));
        Assert.isTrue(summary.contains('Global Inc'));
        Assert.isTrue(summary.contains(String.valueOf(score)));
        Assert.isTrue(summary.contains(status));
    }
}

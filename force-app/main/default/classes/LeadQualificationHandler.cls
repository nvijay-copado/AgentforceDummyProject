public with sharing class LeadQualificationHandler {
    @InvocableMethod(
        label='Qualify Lead'
        description='Calculates lead score, updates qualification fields, creates interaction record, and escalates hot leads'
        category='Lead Qualification'
    )
    public static List<QualificationResult> qualifyLeads(
        List<QualificationRequest> requests
    ) {
        List<QualificationResult> results = new List<QualificationResult>();

        Set<Id> leadIds = new Set<Id>();
        for (QualificationRequest request : requests) {
            leadIds.add(request.leadId);
        }

        Map<Id, Lead> leadsById = new Map<Id, Lead>(
            [
                SELECT
                    Id,
                    Name,
                    Title,
                    Company,
                    AnnualRevenue,
                    NumberOfEmployees,
                    Requested_Demo__c,
                    OwnerId,
                    Lead_Score__c,
                    Qualification_Status__c,
                    AI_Summary__c
                FROM Lead
                WHERE Id IN :leadIds
            ]
        );

        List<Lead> leadsToUpdate = new List<Lead>();
        List<Sales_Agent_Interaction__c> interactions = new List<Sales_Agent_Interaction__c>();
        List<Task> followUpTasks = new List<Task>();

        for (QualificationRequest request : requests) {
            Lead ld = leadsById.get(request.leadId);
            if (ld == null) {
                continue;
            }

            Integer score = LeadScoringService.calculateScore(ld);
            String status = LeadScoringService.getQualificationStatus(score);
            String recommendation = LeadScoringService.getRecommendation(score);
            String summary = LeadScoringService.generateAiSummary(ld, score, status);

            ld.Lead_Score__c = score;
            ld.Qualification_Status__c = status;
            ld.AI_Summary__c = summary;
            leadsToUpdate.add(ld);

            String interactionStatus = score >= LeadScoringService.HOT_THRESHOLD
                ? 'Escalated'
                : 'New';

            interactions.add(
                new Sales_Agent_Interaction__c(
                    Lead__c = ld.Id,
                    Lead_Score__c = score,
                    Recommendation__c = recommendation,
                    Status__c = interactionStatus,
                    Interaction_Date__c = System.now(),
                    Agent_Response__c = summary
                )
            );

            if (score >= LeadScoringService.HOT_THRESHOLD) {
                followUpTasks.add(
                    new Task(
                        Subject = 'Hot Lead Follow-Up: ' + ld.Name,
                        Description = summary,
                        WhoId = ld.Id,
                        OwnerId = ld.OwnerId,
                        Priority = 'High',
                        Status = 'Not Started',
                        ActivityDate = Date.today()
                    )
                );
            }

            QualificationResult result = new QualificationResult();
            result.leadId = ld.Id;
            result.leadScore = score;
            result.qualificationStatus = status;
            result.recommendation = recommendation;
            result.aiSummary = summary;
            result.isHotLead = score >= LeadScoringService.HOT_THRESHOLD;
            results.add(result);
        }

        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
        if (!interactions.isEmpty()) {
            insert interactions;
        }
        if (!followUpTasks.isEmpty()) {
            insert followUpTasks;
        }

        return results;
    }

    public class QualificationRequest {
        @InvocableVariable(required=true label='Lead Id')
        public Id leadId;
    }

    public class QualificationResult {
        @InvocableVariable(label='Lead Id')
        public Id leadId;

        @InvocableVariable(label='Lead Score')
        public Integer leadScore;

        @InvocableVariable(label='Qualification Status')
        public String qualificationStatus;

        @InvocableVariable(label='Recommendation')
        public String recommendation;

        @InvocableVariable(label='AI Summary')
        public String aiSummary;

        @InvocableVariable(label='Is Hot Lead')
        public Boolean isHotLead;
    }
}

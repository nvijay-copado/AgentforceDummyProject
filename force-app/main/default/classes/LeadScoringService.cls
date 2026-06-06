public with sharing class LeadScoringService {
    public static final Integer HOT_THRESHOLD = 80;
    public static final Integer WARM_THRESHOLD = 50;

    public static Integer calculateScore(Lead ld) {
        Integer score = 0;

        if (ld.NumberOfEmployees != null && ld.NumberOfEmployees > 500) {
            score += 30;
        }

        if (
            ld.Title != null &&
            (ld.Title.containsIgnoreCase('Director') ||
            ld.Title.containsIgnoreCase('VP'))
        ) {
            score += 25;
        }

        if (ld.AnnualRevenue != null && ld.AnnualRevenue > 10000000) {
            score += 25;
        }

        if (ld.Requested_Demo__c == true) {
            score += 20;
        }

        return score;
    }

    public static String getQualificationStatus(Integer score) {
        if (score >= HOT_THRESHOLD) {
            return 'Hot';
        }
        if (score >= WARM_THRESHOLD) {
            return 'Warm';
        }
        return 'Cold';
    }

    public static String getRecommendation(Integer score) {
        if (score >= HOT_THRESHOLD) {
            return 'Schedule Demo Immediately';
        }
        if (score >= WARM_THRESHOLD) {
            return 'Nurture with Product Content';
        }
        return 'Add to Marketing Campaign';
    }

    public static String generateAiSummary(Lead ld, Integer score, String status) {
        List<String> factors = new List<String>();

        if (ld.NumberOfEmployees != null && ld.NumberOfEmployees > 500) {
            factors.add('large company size (' + ld.NumberOfEmployees + ' employees)');
        }
        if (
            ld.Title != null &&
            (ld.Title.containsIgnoreCase('Director') ||
            ld.Title.containsIgnoreCase('VP'))
        ) {
            factors.add('senior title (' + ld.Title + ')');
        }
        if (ld.AnnualRevenue != null && ld.AnnualRevenue > 10000000) {
            factors.add('high annual revenue');
        }
        if (ld.Requested_Demo__c == true) {
            factors.add('requested a demo');
        }

        String factorText = factors.isEmpty()
            ? 'limited qualifying signals'
            : String.join(factors, ', ');

        String leadName = ld.Name;
        if (String.isBlank(leadName)) {
            leadName = String.join(
                new List<String>{ ld.FirstName, ld.LastName },
                ' '
            ).trim();
        }
        if (String.isBlank(leadName)) {
            leadName = 'Unknown';
        }

        return String.format(
            'Lead {0} from {1} scored {2} points and is classified as {3}. Key factors: {4}. Recommended action: {5}.',
            new List<String>{
                leadName,
                ld.Company != null ? ld.Company : 'Unknown Company',
                String.valueOf(score),
                status,
                factorText,
                getRecommendation(score)
            }
        );
    }
}

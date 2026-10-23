public with sharing class OpportunityDiscountApprovalHandler {
    private static final String CLOSED_WON = 'Closed Won';
    @TestVisible
    private static final String MSG_UNAPPROVED =
        'Discount requires approval before the opportunity can be closed.';
    @TestVisible
    private static List<Decimal> testThresholds;
    public static void handleBeforeUpdate(
        List<Opportunity> newOpportunities,
        Map<Id, Opportunity> oldOpportunityMap
    ) {
        Decimal lowest = lowestThreshold();
        if (lowest == null) {
            return;
        }
        for (Opportunity opp : newOpportunities) {
            Opportunity oldOpp = oldOpportunityMap.get(opp.Id);
            if (
                opp.StageName == CLOSED_WON &&
                oldOpp.StageName != CLOSED_WON &&
                opp.Discount_Percent__c != null &&
                opp.Discount_Percent__c >= lowest &&
                opp.Discount_Approved__c != true
            ) {
                opp.addError(MSG_UNAPPROVED);
            }
        }
    }
    private static Decimal lowestThreshold() {
        List<Decimal> values = new List<Decimal>();
        if (Test.isRunningTest() && testThresholds != null) {
            values.addAll(testThresholds);
        } else {
            for (Discount_Threshold__mdt t : [
                SELECT Min_Percent__c
                FROM Discount_Threshold__mdt
                WHERE Min_Percent__c != NULL
            ]) {
                values.add(t.Min_Percent__c);
            }
        }
        values.sort();
        return values.isEmpty() ? null : values[0];
    }
}
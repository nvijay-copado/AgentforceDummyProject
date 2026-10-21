@IsTest
private class QuoteApprovalServiceTest {
    @IsTest
    static void noApprovalForLowOrNullDiscount() {
        System.assertEquals(QuoteApprovalService.ApproverLevel.NONE, QuoteApprovalService.getRequiredApprover(null));
        System.assertEquals(QuoteApprovalService.ApproverLevel.NONE, QuoteApprovalService.getRequiredApprover(10));
        System.assertEquals(false, QuoteApprovalService.isApprovalRequired(5));
    }

    @IsTest
    static void managerApproval() {
        System.assertEquals(QuoteApprovalService.ApproverLevel.MANAGER, QuoteApprovalService.getRequiredApprover(15));
        System.assertEquals(QuoteApprovalService.ApproverLevel.MANAGER, QuoteApprovalService.getRequiredApprover(25));
        System.assertEquals(true, QuoteApprovalService.isApprovalRequired(15));
    }

    @IsTest
    static void directorApproval() {
        System.assertEquals(QuoteApprovalService.ApproverLevel.DIRECTOR, QuoteApprovalService.getRequiredApprover(30));
    }

    @IsTest
    static void bulkMapping() {
        System.assertEquals(0, QuoteApprovalService.getRequiredApprovers(null).size());
        Map<Decimal, QuoteApprovalService.ApproverLevel> m =
            QuoteApprovalService.getRequiredApprovers(new List<Decimal>{5, 15, 40});
        System.assertEquals(3, m.size());
        System.assertEquals(QuoteApprovalService.ApproverLevel.DIRECTOR, m.get(40));
    }
}
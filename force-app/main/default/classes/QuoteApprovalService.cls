public with sharing class QuoteApprovalService {
    public static final Decimal MANAGER_THRESHOLD = 10;
    public static final Decimal DIRECTOR_THRESHOLD = 25;

    public enum ApproverLevel { NONE, MANAGER, DIRECTOR }

    public static ApproverLevel getRequiredApprover(Decimal discountPercent) {
        if (discountPercent == null || discountPercent <= MANAGER_THRESHOLD) {
            return ApproverLevel.NONE;
        }
        return discountPercent > DIRECTOR_THRESHOLD ? ApproverLevel.DIRECTOR : ApproverLevel.MANAGER;
    }

    public static Map<Decimal, ApproverLevel> getRequiredApprovers(List<Decimal> discounts) {
        Map<Decimal, ApproverLevel> result = new Map<Decimal, ApproverLevel>();
        if (discounts == null) {
            return result;
        }
        for (Decimal d : discounts) {
            result.put(d, getRequiredApprover(d));
        }
        return result;
    }

    public static Boolean isApprovalRequired(Decimal discountPercent) {
        return getRequiredApprover(discountPercent) != ApproverLevel.NONE;
    }
}
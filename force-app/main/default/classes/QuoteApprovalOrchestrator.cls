/**
 * Decides whether a discounted Opportunity needs approval and keeps exactly one open
 * Quote_Approval_Request__c per Opportunity. Reuses QuoteApprovalService for discount tiering and
 * CreditLimitService for the credit position. Bulk safe: one query per object, one upsert.
 */
public with sharing class QuoteApprovalOrchestrator {
    public static final String DECISION_PENDING = 'Pending';
    public static final String LIFECYCLE_CANCELLED = 'Cancelled';

    public static List<Quote_Approval_Request__c> evaluate(
        List<Opportunity> newOpportunities,
        Map<Id, Opportunity> oldMap
    ) {
        List<Opportunity> needsApproval = new List<Opportunity>();
        Set<Id> withdrawnOppIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        for (Opportunity opp : newOpportunities) {
            Opportunity old = oldMap == null ? null : oldMap.get(opp.Id);
            if (!hasRelevantChange(opp, old)) {
                continue;
            }
            if (QuoteApprovalService.isApprovalRequired(opp.Discount_Percent__c)) {
                needsApproval.add(opp);
                if (opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
            } else if (old != null) {
                withdrawnOppIds.add(opp.Id);
            }
        }

        withdrawOpenRequests(withdrawnOppIds);

        if (needsApproval.isEmpty()) {
            return new List<Quote_Approval_Request__c>();
        }

        Map<Id, Account> accounts = loadAccounts(accountIds);
        Map<String, CreditLimitService.CreditInfo> creditCache = new Map<String, CreditLimitService.CreditInfo>();
        List<Quote_Approval_Request__c> requests = new List<Quote_Approval_Request__c>();
        for (Opportunity opp : needsApproval) {
            requests.add(buildRequest(opp, accounts.get(opp.AccountId), creditCache));
        }
        // Open_Key__c is a unique external id, so a resubmission updates the open request instead of duplicating it.
        Database.upsert(requests, Quote_Approval_Request__c.Open_Key__c, true);
        return requests;
    }

    private static Boolean hasRelevantChange(Opportunity opp, Opportunity old) {
        if (old == null) {
            return opp.Discount_Percent__c != null;
        }
        return opp.Discount_Percent__c != old.Discount_Percent__c
            || opp.Amount != old.Amount
            || opp.AccountId != old.AccountId;
    }

    private static Quote_Approval_Request__c buildRequest(
        Opportunity opp,
        Account account,
        Map<String, CreditLimitService.CreditInfo> creditCache
    ) {
        QuoteApprovalService.ApproverLevel level = QuoteApprovalService.getRequiredApprover(opp.Discount_Percent__c);
        Quote_Approval_Request__c req = new Quote_Approval_Request__c(
            Opportunity__c = opp.Id,
            Account__c = opp.AccountId,
            Discount_Percent__c = opp.Discount_Percent__c,
            Decision__c = DECISION_PENDING,
            Credit_Review_Required__c = false,
            Open_Key__c = String.valueOf(opp.Id)
        );

        String code = account == null ? null : account.Customer_Code__c;
        CreditLimitService.CreditInfo info = String.isBlank(code) ? null : lookupCredit(code, creditCache);
        if (info == null) {
            req.Credit_Review_Required__c = true;
            req.Credit_Limit__c = null;
            req.Utilized_Credit__c = null;
            req.Available_Credit__c = null;
        } else {
            Decimal available = info.getAvailableCredit();
            req.Credit_Limit__c = info.creditLimit;
            req.Utilized_Credit__c = info.utilizedCredit;
            req.Available_Credit__c = available;
            if (opp.Amount != null && opp.Amount > available) {
                if (level == QuoteApprovalService.ApproverLevel.MANAGER) {
                    level = QuoteApprovalService.ApproverLevel.DIRECTOR;
                } else {
                    req.Credit_Review_Required__c = true;
                }
            }
        }
        req.Required_Level__c = level.name();
        return req;
    }

    private static CreditLimitService.CreditInfo lookupCredit(
        String code,
        Map<String, CreditLimitService.CreditInfo> creditCache
    ) {
        if (!creditCache.containsKey(code)) {
            creditCache.put(code, CreditLimitService.getCustomerCreditInfo(code));
        }
        return creditCache.get(code);
    }

    private static Map<Id, Account> loadAccounts(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return new Map<Id, Account>();
        }
        return new Map<Id, Account>([SELECT Id, Customer_Code__c FROM Account WHERE Id IN :accountIds]);
    }

    private static void withdrawOpenRequests(Set<Id> opportunityIds) {
        if (opportunityIds.isEmpty()) {
            return;
        }
        List<Quote_Approval_Request__c> open = [
            SELECT Id
            FROM Quote_Approval_Request__c
            WHERE Opportunity__c IN :opportunityIds AND Decision__c = :DECISION_PENDING
        ];
        for (Quote_Approval_Request__c req : open) {
            req.Lifecycle__c = LIFECYCLE_CANCELLED;
            req.Open_Key__c = null;
            req.Decision__c = 'Rejected';
        }
        if (!open.isEmpty()) {
            update open;
        }
    }
}
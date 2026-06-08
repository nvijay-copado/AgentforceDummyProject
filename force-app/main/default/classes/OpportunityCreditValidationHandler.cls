public with sharing class OpportunityCreditValidationHandler {
    private static final String APPROVAL_REQUESTED_STAGE = 'Approval Requested';
    private static final Decimal CREDIT_VALIDATION_THRESHOLD = 1000000;

    private static final String MSG_CUSTOMER_CODE_REQUIRED =
        'Customer Code is required before requesting approval.';
    private static final String MSG_UNABLE_TO_RETRIEVE_CREDIT =
        'Unable to retrieve customer credit information.';
    private static final String MSG_INSUFFICIENT_CREDIT =
        'Customer has insufficient available credit for approval.';

    @TestVisible
    private static Map<String, CreditLimitService.CreditInfo> testCreditOverrides;

    public static void handleBeforeUpdate(
        List<Opportunity> newOpportunities,
        Map<Id, Opportunity> oldOpportunityMap
    ) {
        List<Opportunity> opportunitiesToValidate = new List<Opportunity>();
        Set<Id> accountIds = new Set<Id>();

        for (Opportunity opportunity : newOpportunities) {
            Opportunity oldOpportunity = oldOpportunityMap.get(opportunity.Id);
            if (requiresCreditValidation(opportunity, oldOpportunity)) {
                opportunitiesToValidate.add(opportunity);
                if (opportunity.AccountId != null) {
                    accountIds.add(opportunity.AccountId);
                }
            }
        }

        if (opportunitiesToValidate.isEmpty()) {
            return;
        }

        Map<Id, Account> accountsById = queryAccounts(accountIds);
        Map<String, CreditLimitService.CreditInfo> creditInfoCache =
            new Map<String, CreditLimitService.CreditInfo>();

        for (Opportunity opportunity : opportunitiesToValidate) {
            validateOpportunity(
                opportunity,
                accountsById.get(opportunity.AccountId),
                creditInfoCache
            );
        }
    }

    private static Boolean requiresCreditValidation(
        Opportunity opportunity,
        Opportunity oldOpportunity
    ) {
        return opportunity.StageName == APPROVAL_REQUESTED_STAGE
            && oldOpportunity.StageName != APPROVAL_REQUESTED_STAGE
            && opportunity.Amount != null
            && opportunity.Amount > CREDIT_VALIDATION_THRESHOLD;
    }

    private static Map<Id, Account> queryAccounts(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return new Map<Id, Account>();
        }

        return new Map<Id, Account>(
            [
                SELECT Id, Customer_Code__c
                FROM Account
                WHERE Id IN :accountIds
            ]
        );
    }

    private static void validateOpportunity(
        Opportunity opportunity,
        Account account,
        Map<String, CreditLimitService.CreditInfo> creditInfoCache
    ) {
        String customerCode = account != null ? account.Customer_Code__c : null;
        if (String.isBlank(customerCode)) {
            opportunity.addError(MSG_CUSTOMER_CODE_REQUIRED);
            return;
        }

        CreditLimitService.CreditInfo creditInfo = getCachedCreditInfo(
            customerCode,
            creditInfoCache
        );
        if (creditInfo == null) {
            opportunity.addError(MSG_UNABLE_TO_RETRIEVE_CREDIT);
            return;
        }

        Decimal availableCredit =
            creditInfo.creditLimit - creditInfo.utilizedCredit;
        if (opportunity.Amount > availableCredit) {
            opportunity.addError(MSG_INSUFFICIENT_CREDIT);
        }
    }

    private static CreditLimitService.CreditInfo getCachedCreditInfo(
        String customerCode,
        Map<String, CreditLimitService.CreditInfo> creditInfoCache
    ) {
        if (!creditInfoCache.containsKey(customerCode)) {
            creditInfoCache.put(
                customerCode,
                resolveCreditInfo(customerCode)
            );
        }
        return creditInfoCache.get(customerCode);
    }

    private static CreditLimitService.CreditInfo resolveCreditInfo(
        String customerCode
    ) {
        if (Test.isRunningTest() && testCreditOverrides != null) {
            if (testCreditOverrides.containsKey(customerCode)) {
                return testCreditOverrides.get(customerCode);
            }
        }
        return CreditLimitService.getCustomerCreditInfo(customerCode);
    }
}
public with sharing class CreditLimitService implements ICreditLimitService {

    public class CreditInfo { // Created by peer developer, adding this comment to showcase in demo.
        @AuraEnabled
        public Decimal creditLimit;

        @AuraEnabled
        public Decimal utilizedCredit;

        public CreditInfo(Decimal creditLimit, Decimal utilizedCredit) {
            this.creditLimit = creditLimit;
            this.utilizedCredit = utilizedCredit;
        }

        public Decimal getAvailableCredit() {
            return creditLimit - utilizedCredit;
        }
    }

    /**
     * Returns credit information for a customer.
     *
     * @param customerCode Unique customer identifier stored on Account.Customer_Code__c
     * @return CreditInfo containing credit limit and utilized credit
     */
    public static CreditInfo getCustomerCreditInfo(String customerCode) {

        if (String.isBlank(customerCode)) {
            return null;
        }

        // Simulated ERP response
        Map<String, CreditInfo> creditData = new Map<String, CreditInfo>{
            'CUST001' => new CreditInfo(5000000, 1200000),
            'CUST002' => new CreditInfo(1000000, 950000),
            'CUST003' => new CreditInfo(7500000, 3000000)
        };

        return creditData.get(customerCode);
    }
}
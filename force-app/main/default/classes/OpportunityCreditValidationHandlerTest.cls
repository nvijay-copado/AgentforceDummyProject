@isTest
private class OpportunityCreditValidationHandlerTest {
    private static final String APPROVAL_REQUESTED_STAGE = 'Approval Requested';

    @isTest
    static void creditAvailable_savesSuccessfully() {
        Account account = createAccount('CUST-AC1');
        Opportunity opportunity = createOpportunity(account.Id, 1500000);

        OpportunityCreditValidationHandler.testCreditOverrides =
            new Map<String, CreditLimitService.CreditInfo>{
                'CUST-AC1' => new CreditLimitService.CreditInfo(
                    5000000,
                    2000000
                )
            };

        Test.startTest();
        opportunity.StageName = APPROVAL_REQUESTED_STAGE;
        update opportunity;
        Test.stopTest();

        Opportunity updatedOpportunity = [
            SELECT StageName
            FROM Opportunity
            WHERE Id = :opportunity.Id
        ];
        Assert.areEqual(
            APPROVAL_REQUESTED_STAGE,
            updatedOpportunity.StageName,
            'Opportunity should save when available credit is sufficient'
        );
    }

    @isTest
    static void insufficientCredit_blocksSave() {
        Account account = createAccount('CUST-AC2');
        Opportunity opportunity = createOpportunity(account.Id, 1500000);

        OpportunityCreditValidationHandler.testCreditOverrides =
            new Map<String, CreditLimitService.CreditInfo>{
                'CUST-AC2' => new CreditLimitService.CreditInfo(
                    5000000,
                    4500000
                )
            };

        Test.startTest();
        opportunity.StageName = APPROVAL_REQUESTED_STAGE;
        try {
            update opportunity;
            Assert.fail('Expected insufficient credit validation error');
        } catch (DmlException ex) {
            Assert.isTrue(
                ex.getMessage()
                    .contains(
                        'Customer has insufficient available credit for approval.'
                    ),
                'Unexpected error message: ' + ex.getMessage()
            );
        }
        Test.stopTest();
    }

    @isTest
    static void blankCustomerCode_blocksSave() {
        Account account = createAccount(null);
        Opportunity opportunity = createOpportunity(account.Id, 1500000);

        Test.startTest();
        opportunity.StageName = APPROVAL_REQUESTED_STAGE;
        try {
            update opportunity;
            Assert.fail('Expected customer code validation error');
        } catch (DmlException ex) {
            Assert.isTrue(
                ex.getMessage()
                    .contains(
                        'Customer Code is required before requesting approval.'
                    ),
                'Unexpected error message: ' + ex.getMessage()
            );
        }
        Test.stopTest();
    }

    @isTest
    static void nullCreditServiceResponse_blocksSave() {
        Account account = createAccount('CUST-AC4');
        Opportunity opportunity = createOpportunity(account.Id, 1500000);

        OpportunityCreditValidationHandler.testCreditOverrides =
            new Map<String, CreditLimitService.CreditInfo>{
                'CUST-AC4' => null
            };

        Test.startTest();
        opportunity.StageName = APPROVAL_REQUESTED_STAGE;
        try {
            update opportunity;
            Assert.fail('Expected unable to retrieve credit validation error');
        } catch (DmlException ex) {
            Assert.isTrue(
                ex.getMessage()
                    .contains(
                        'Unable to retrieve customer credit information.'
                    ),
                'Unexpected error message: ' + ex.getMessage()
            );
        }
        Test.stopTest();
    }

    @isTest
    static void amountAtThreshold_skipsValidation() {
        Account account = createAccount('CUST001');
        Opportunity opportunity = createOpportunity(account.Id, 1000000);

        Test.startTest();
        opportunity.StageName = APPROVAL_REQUESTED_STAGE;
        update opportunity;
        Test.stopTest();

        Opportunity updatedOpportunity = [
            SELECT StageName
            FROM Opportunity
            WHERE Id = :opportunity.Id
        ];
        Assert.areEqual(
            APPROVAL_REQUESTED_STAGE,
            updatedOpportunity.StageName,
            'Validation should not run when amount equals the threshold'
        );
    }

    private static Account createAccount(String customerCode) {
        Account account = new Account(Name = 'Test Account');
        if (customerCode != null) {
            account.Customer_Code__c = customerCode;
        }
        insert account;
        return account;
    }

    private static Opportunity createOpportunity(
        Id accountId,
        Decimal amount
    ) {
        Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = accountId,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Amount = amount
        );
        insert opportunity;
        return opportunity;
    }
}
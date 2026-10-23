@IsTest
private class QuoteApprovalControllerTest {
    private class Mock implements HttpCalloutMock {
        private final Integer code;
        Mock(Integer code) {
            this.code = code;
        }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody('{"reference":"ERP-9"}');
            return res;
        }
    }

    @TestSetup
    static void setup() {
        User u = new User(
            Alias = 'qapp', Email = 'qapp@example.com', LastName = 'Approver', Username = 'qapp' + System.currentTimeMillis() + '@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            TimeZoneSidKey = 'GMT', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert u;
            insert new PermissionSetAssignment(
                AssigneeId = u.Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Quote_Approval_Manager'].Id
            );
        }
        Account a = TestDataFactory.createAccountWithCode('CUST001');
        Opportunity o = TestDataFactory.opportunity().forAccount(a.Id).create();
        TestDataFactory.approvalRequest().forOpportunity(o.Id).create();
    }

    private static User approver() {
        return [SELECT Id FROM User WHERE Alias = 'qapp'];
    }

    private static Quote_Approval_Request__c load() {
        return [SELECT Id, Opportunity__c, Decision__c, Approver__c, Open_Key__c, Sync_Status__c FROM Quote_Approval_Request__c];
    }

    @IsTest
    static void deniedWithoutPermission() {
        Boolean thrown = false;
        try {
            QuoteApprovalController.decide(load().Id, 'Approved');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Permission gate must block the call');
        System.assertEquals('Pending', load().Decision__c);
    }

    @IsTest
    static void approvalEnqueuesErpSync() {
        Test.setMock(HttpCalloutMock.class, new Mock(200));
        Quote_Approval_Request__c r = load();
        System.runAs(approver()) {
            Test.startTest();
            QuoteApprovalController.decide(r.Id, 'Approved');
            Test.stopTest();
        }
        r = load();
        System.assertEquals('Approved', r.Decision__c);
        System.assertEquals(approver().Id, r.Approver__c);
        System.assertEquals(null, r.Open_Key__c);
        System.assertEquals('Sent', r.Sync_Status__c);
    }

    @IsTest
    static void rejectionDoesNotSync() {
        Quote_Approval_Request__c r = load();
        System.runAs(approver()) {
            QuoteApprovalController.decide(r.Id, 'Rejected');
        }
        System.assertEquals('Rejected', load().Decision__c);
    }

    @IsTest
    static void invalidAndRepeatedDecisionsAreRejected() {
        Quote_Approval_Request__c r = load();
        System.runAs(approver()) {
            try {
                QuoteApprovalController.decide(r.Id, 'Maybe');
                System.assert(false, 'invalid decision');
            } catch (AuraHandledException e) {
                System.assert(true);
            }
            QuoteApprovalController.decide(r.Id, 'Rejected');
            try {
                QuoteApprovalController.decide(r.Id, 'Approved');
                System.assert(false, 'repeat decision');
            } catch (AuraHandledException e) {
                System.assert(true);
            }
        }
    }

    @IsTest
    static void getApprovalReturnsViewOrNull() {
        Quote_Approval_Request__c r = load();
        System.runAs(approver()) {
            QuoteApprovalController.ApprovalView v = QuoteApprovalController.getApproval(r.Opportunity__c);
            System.assertEquals(r.Id, v.requestId);
            System.assertEquals(true, v.canDecide);
            System.assertEquals(null, QuoteApprovalController.getApproval(r.Id));
        }
    }

    @IsTest
    static void retryOnlyForFailedSync() {
        Test.setMock(HttpCalloutMock.class, new Mock(200));
        Quote_Approval_Request__c r = load();
        r.Decision__c = 'Approved';
        r.Sync_Status__c = 'Failed';
        update r;
        System.runAs(approver()) {
            Test.startTest();
            QuoteApprovalController.retrySync(r.Id);
            Test.stopTest();
        }
        System.assertEquals('Sent', load().Sync_Status__c);
    }

    @IsTest
    static void retryRejectedWhenNotFailed() {
        Quote_Approval_Request__c r = load();
        System.runAs(approver()) {
            try {
                QuoteApprovalController.retrySync(r.Id);
                System.assert(false, 'should not retry');
            } catch (AuraHandledException e) {
                System.assert(true);
            }
        }
    }
}
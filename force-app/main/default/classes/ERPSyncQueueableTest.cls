@IsTest
private class ERPSyncQueueableTest {
    private class Mock implements HttpCalloutMock {
        private final Integer code;
        private final String body;
        Mock(Integer code, String body) {
            this.code = code;
            this.body = body;
        }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody(body);
            return res;
        }
    }

    @TestSetup
    static void setup() {
        TestDataFactory.approvalRequest().withDecision('Approved').create();
    }

    private static Quote_Approval_Request__c load() {
        return [SELECT Id, Sync_Status__c, ERP_Reference__c, Last_Error__c, Decision__c FROM Quote_Approval_Request__c];
    }

    @IsTest
    static void successMarksSent() {
        Test.setMock(HttpCalloutMock.class, new Mock(200, '{"reference":"ERP-1"}'));
        Quote_Approval_Request__c r = load();
        Test.startTest();
        ERPSyncQueueable.sync(new Set<Id>{ r.Id });
        Test.stopTest();
        r = load();
        System.assertEquals('Sent', r.Sync_Status__c);
        System.assertEquals('ERP-1', r.ERP_Reference__c);
    }

    @IsTest
    static void serverErrorMarksFailedAndKeepsApproval() {
        Test.setMock(HttpCalloutMock.class, new Mock(500, 'boom'));
        Quote_Approval_Request__c r = load();
        Test.startTest();
        ERPSyncQueueable.sync(new Set<Id>{ r.Id });
        Test.stopTest();
        r = load();
        System.assertEquals('Failed', r.Sync_Status__c);
        System.assertEquals('Approved', r.Decision__c);
    }

    @IsTest
    static void queueableRunsAsync() {
        Test.setMock(HttpCalloutMock.class, new Mock(200, '{"reference":"ERP-2"}'));
        Quote_Approval_Request__c r = load();
        Test.startTest();
        ERPSyncQueueable.enqueue(new Set<Id>{ r.Id });
        Test.stopTest();
        System.assertEquals('Sent', load().Sync_Status__c);
    }

    @IsTest
    static void helpersHandleEdgeCases() {
        System.assertEquals(null, ERPSyncQueueable.enqueue(new Set<Id>()));
        System.assertEquals(null, ERPSyncQueueable.parseReference(''));
        System.assertEquals(null, ERPSyncQueueable.parseReference('{}'));
        System.assertNotEquals(null, ERPSyncQueueable.buildBody(new Quote_Approval_Request__c()));
    }
}
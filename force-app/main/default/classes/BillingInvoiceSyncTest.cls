@IsTest
private class BillingInvoiceSyncTest {
    private class Mock implements HttpCalloutMock {
        Integer code;
        String body;
        Mock(Integer code, String body) {
            this.code = code;
            this.body = body;
        }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse r = new HttpResponse();
            r.setStatusCode(code);
            r.setBody(body);
            return r;
        }
    }

    private static final String BODY = '[{"id":"X1","number":"INV-1","amount":10.5,"status":"Open"},{"id":"X2","number":"INV-2","amount":20,"status":"Paid"}]';

    @IsTest
    static void syncUpsertsIdempotently() {
        Test.setMock(HttpCalloutMock.class, new Mock(200, BODY));
        Test.startTest();
        Integer first = BillingInvoiceSyncService.sync();
        Integer second = BillingInvoiceSyncService.upsertInvoices(BODY);
        Test.stopTest();
        System.assertEquals(2, first);
        System.assertEquals(2, second);
        System.assertEquals(2, [SELECT COUNT() FROM Invoice__c]);
        Invoice__c i = [SELECT Amount__c, Status__c FROM Invoice__c WHERE External_Id__c = 'X1'];
        System.assertEquals(10.5, i.Amount__c);
        System.assertEquals('Open', i.Status__c);
    }

    @IsTest
    static void errorStatusThrows() {
        Test.setMock(HttpCalloutMock.class, new Mock(500, 'err'));
        try {
            BillingInvoiceSyncService.sync();
            System.assert(false, 'expected exception');
        } catch (BillingInvoiceSyncService.SyncException e) {
            System.assert(e.getMessage().contains('500'));
        }
    }

    @IsTest
    static void queueableSyncsOnSuccess() {
        Test.setMock(HttpCalloutMock.class, new Mock(200, BODY));
        Test.startTest();
        System.enqueueJob(new BillingInvoiceSyncQueueable());
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM Invoice__c]);
    }

    @IsTest
    static void queueableRetriesThreeTimes() {
        Test.setMock(HttpCalloutMock.class, new Mock(500, 'err'));
        BillingInvoiceSyncQueueable.chainedCount = 0;
        BillingInvoiceSyncQueueable.suppressEnqueue = true;
        // Run each attempt synchronously to count chained retries without test chaining limits.
        for (Integer a = 0; a <= BillingInvoiceSyncQueueable.MAX_RETRIES; a++) {
            new BillingInvoiceSyncQueueable(a).execute(null);
        }
        System.assertEquals(3, BillingInvoiceSyncQueueable.chainedCount);
        System.assertEquals(0, [SELECT COUNT() FROM Invoice__c]);
        Test.startTest();
        Test.stopTest();
    }

    @IsTest
    static void schedulerIsHourlyAndEnqueues() {
        Test.setMock(HttpCalloutMock.class, new Mock(200, BODY));
        Test.startTest();
        Id jobId = BillingInvoiceSyncScheduler.scheduleHourly();
        CronTrigger ct = [SELECT CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('0 0 * * * ?', ct.CronExpression);
        new BillingInvoiceSyncScheduler().execute(null);
        Test.stopTest();
    }
}
@IsTest
private class ERPCalloutServiceTest {
    private class Mock implements HttpCalloutMock {
        Integer code;
        Mock(Integer code) { this.code = code; }
        public HttpResponse respond(HttpRequest req) {
            System.assert(req.getEndpoint().startsWith('callout:ERP_Named_Credential'));
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody('{"ok":true}');
            return res;
        }
    }

    @IsTest
    static void getSucceeds() {
        Test.setMock(HttpCalloutMock.class, new Mock(200));
        Test.startTest();
        HttpResponse res = ERPCalloutService.get('/orders');
        Test.stopTest();
        System.assertEquals(200, res.getStatusCode());
    }

    @IsTest
    static void postSucceeds() {
        Test.setMock(HttpCalloutMock.class, new Mock(201));
        HttpResponse res = ERPCalloutService.post('/orders', '{}');
        System.assertEquals(201, res.getStatusCode());
    }

    @IsTest
    static void failureThrows() {
        Test.setMock(HttpCalloutMock.class, new Mock(500));
        try {
            ERPCalloutService.get('');
            System.assert(false, 'Expected exception');
        } catch (ERPCalloutService.ERPCalloutException e) {
            System.assert(e.getMessage().contains('500'));
        }
    }
}
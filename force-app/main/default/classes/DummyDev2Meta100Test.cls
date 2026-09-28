@isTest
private class DummyDev2Meta100Test {
    @isTest
    static void testPing() {
        Test.startTest();
        String result = DummyDev2Meta100.ping();
        Test.stopTest();
        System.assertEquals('dummy', result, 'ping() should return the literal dummy value');
    }
}
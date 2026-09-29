@isTest
private class DummyDev2Meta102Test {
    @isTest
    static void testGetMessage() {
        Test.startTest();
        String result = DummyDev2Meta102.getMessage();
        Test.stopTest();

        System.assertEquals('Dev2 Meta 10 dummy Apex commit.', result, 'Message should match expected value.');
    }
}
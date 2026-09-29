@isTest
private class DummyDev2Meta101Test {
    @isTest
    static void testGetMessage() {
        Test.startTest();
        String result = DummyDev2Meta101.getMessage();
        Test.stopTest();

        System.assertEquals('Dev2 Meta 10 dummy Apex commit.', result, 'Message should match expected value.');
    }
}
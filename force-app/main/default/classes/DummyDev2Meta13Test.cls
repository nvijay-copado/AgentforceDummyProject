/**
 * Unit test for DummyDev2Meta13.
 */
@isTest
private class DummyDev2Meta13Test {
    @isTest
    static void testGetMessage() {
        DummyDev2Meta13 instance = new DummyDev2Meta13();

        Test.startTest();
        String result = instance.getMessage();
        Test.stopTest();

        System.assertEquals('Hello from DummyDev2Meta13', result, 'Message should match expected value.');
    }
}
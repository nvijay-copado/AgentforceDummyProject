/**
 * Unit test for DummyDev2Meta15.
 */
@isTest
private class DummyDev2Meta15Test {
    @isTest
    static void testGetGreeting() {
        DummyDev2Meta15 instance = new DummyDev2Meta15();

        Test.startTest();
        String result = instance.getGreeting();
        Test.stopTest();

        System.assertEquals('Hello from DummyDev2Meta15', result, 'Greeting should match expected value.');
    }
}
/**
 * Unit tests for DummyDev2Meta1011 (US-0012431).
 */
@isTest
private class DummyDev2Meta1011Test {
    @isTest
    static void testGetMessage() {
        DummyDev2Meta1011 instance = new DummyDev2Meta1011();

        Test.startTest();
        String result = instance.getMessage();
        Test.stopTest();

        System.assertEquals(
            'DummyDev2Meta1011 is committed on the story.',
            result,
            'getMessage should return the expected commit confirmation text.'
        );
    }
}
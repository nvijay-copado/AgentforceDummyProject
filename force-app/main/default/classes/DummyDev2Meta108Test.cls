/**
 * Unit tests for DummyDev2Meta108, committed for US-0012427 (Agentia commit 8).
 */
@isTest
private class DummyDev2Meta108Test {
    @isTest
    static void testGetMessage() {
        DummyDev2Meta108 instance = new DummyDev2Meta108();

        Test.startTest();
        String result = instance.getMessage();
        Test.stopTest();

        System.assertEquals('DummyDev2Meta108', result, 'getMessage should return the class name literal.');
    }
}
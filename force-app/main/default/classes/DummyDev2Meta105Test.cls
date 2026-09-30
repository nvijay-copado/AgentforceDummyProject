/**
 * Unit tests for DummyDev2Meta105, committed for US-0012421 (Agentia commit 5).
 */
@isTest
private class DummyDev2Meta105Test {
    @isTest
    static void testGetMessage() {
        DummyDev2Meta105 instance = new DummyDev2Meta105();

        Test.startTest();
        String result = instance.getMessage();
        Test.stopTest();

        System.assertEquals('DummyDev2Meta105', result, 'getMessage should return the class name literal.');
    }
}
/**
 * Unit tests for DummyDev2Meta106, committed for US-0012422 (Agentia commit 6).
 */
@isTest
private class DummyDev2Meta106Test {
    @isTest
    static void testGetMessage() {
        DummyDev2Meta106 instance = new DummyDev2Meta106();

        Test.startTest();
        String result = instance.getMessage();
        Test.stopTest();

        System.assertEquals('DummyDev2Meta106', result, 'getMessage should return the class name literal.');
    }
}
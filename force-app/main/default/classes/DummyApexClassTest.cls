@IsTest
private class DummyApexClassTest {

    @IsTest
    static void testDummyApexClass() {

        DummyApexClass dummy = new DummyApexClass();

        System.assertEquals(
            'Hello from DummyApexClass third try!',
            dummy.message
        );

        System.assertEquals(
            'Hello, Salesforce!',
            dummy.getGreeting('Salesforce')
        );

        System.assertEquals(
            15,
            DummyApexClass.addNumbers(10, 5)
        );

        List<String> input = new List<String>{'one', 'two', 'three'};
        List<String> output = dummy.getUpperCaseValues(input);

        System.assertEquals(3, output.size());
        System.assertEquals('ONE', output[0]);
        System.assertEquals('TWO', output[1]);
        System.assertEquals('THREE', output[2]);
    }
}
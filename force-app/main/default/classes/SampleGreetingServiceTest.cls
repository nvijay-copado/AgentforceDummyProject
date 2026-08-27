@isTest
private class SampleGreetingServiceTest {

    @isTest
    static void testGetGreetingWithName() {
        String result = SampleGreetingService.getGreeting('Copado');
        System.assertEquals('Hello, Copado!', result, 'Greeting should include the provided name');
    }

    @isTest
    static void testGetGreetingWithBlankName() {
        String result = SampleGreetingService.getGreeting('');
        System.assertEquals('Hello, Guest!', result, 'Greeting should default to Guest when name is blank');
    }

    @isTest
    static void testAddNumbers() {
        Integer result = SampleGreetingService.addNumbers(2, 3);
        System.assertEquals(5, result, 'Sum of 2 and 3 should be 5');
    }
}
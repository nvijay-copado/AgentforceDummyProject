public with sharing class DummyApexClass {

    // Static variable
    public static final String APP_NAME = 'Dummy Application';

    // Instance variable
    public String message;

    // Constructor
    public DummyApexClass() {
        this.message = 'Hello from DummyApexClass!';
    }

    // Sample method
    public String getGreeting(String name) {
        return 'Hello, ' + name + '!';
    }

    // Sample static method
    public static Integer addNumbers(Integer a, Integer b) {
        return a + b;
    }

    // Sample method with list processing
    public List<String> getUpperCaseValues(List<String> values) {
        List<String> result = new List<String>();

        if (values != null) {
            for (String value : values) {
                result.add(value.toUpperCase());
            }
        }

        return result;
    }
}
public class SampleGreetingService {

    public static String getGreeting(String name) {
        if (String.isBlank(name)) {
            return 'Hello, Guest!';
        }
        return 'Hello, ' + name + '!';
    }

    public static Integer addNumbers(Integer a, Integer b) {
        return a + b;
    }

}
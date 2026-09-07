public with sharing class DummyStoryHelper {

    public static String formatGreeting(String name) {
        if (String.isBlank(name)) {
            return 'Hello, Guest!';
        }
        return 'Hello, ' + name.trim() + '!';
    }

    public static Integer sumIntegers(List<Integer> values) {
        Integer total = 0;
        if (values == null) {
            return total;
        }
        for (Integer value : values) {
            if (value != null) {
                total += value;
            }
        }
        return total;
    }

    public static Boolean isEven(Integer value) {
        return value != null && Math.mod(value, 2) == 0;
    }
}

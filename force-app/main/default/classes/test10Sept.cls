public class test10Sept {
    
    public static void method1() {
        Account acc = [Select id, name from Account Limit 1];
        acc.name = 'ac1234 - 29 aug - 10th sept';
        update acc;
    }

}
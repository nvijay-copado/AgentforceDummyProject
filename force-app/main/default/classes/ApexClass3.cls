public class ApexClass3 {
    
    public static void method1() {
        Account acc = [Select id, name from Account Limit 1];
        acc.name = 'ac1 - 25 nov';
        update acc;
    }

}
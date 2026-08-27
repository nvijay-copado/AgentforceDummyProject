public class ApexClass2 {
    
    public static void method1() {
        Account acc = [Select id, name from Account Limit 1];
        acc.name = 'ac1 - 12 May - try 21 aug';
        update acc;
    }

}
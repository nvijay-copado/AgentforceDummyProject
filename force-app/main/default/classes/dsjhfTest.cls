@IsTest
public class dsjhfTest {
    public static Account createTestAccount(String name) {
        Account acc = new Account(Name = name);
        insert acc;
        return acc;
    }
    
     public static Account createTestAccount2(String name) {
        Account acc = new Account(Name = name);
        insert acc;
        return acc;
    }
}
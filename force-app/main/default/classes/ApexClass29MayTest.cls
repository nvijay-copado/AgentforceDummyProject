@IsTest
public class ApexClass29MayTest {
    
    @IsTest
    static void testActiveMethod(){
        Test.startTest();
        Account ac = new Account(name = 'acc123 - 25Nov');
        insert ac;
         ApexClass29May.execute();
         Test.stopTest();
    }

}
public with sharing class backPromotionTest {
     public static void execute() {
        System.debug('back promoting this class - 7th jan. vlocity org 1 version');
        Account a = [Select id, name from Account limit 1];
        
        a.name = 'newAcc1111123';
        update a;
    }
}
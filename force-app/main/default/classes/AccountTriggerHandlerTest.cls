@IsTest
private class AccountTriggerHandlerTest {
    @IsTest
    static void trimsNameOnInsertAndUpdate() {
        List<Account> accts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accts.add(new Account(Name = '  Handler Test ' + i + '  '));
        }
        insert accts;
        for (Account a : [SELECT Name FROM Account WHERE Id IN :accts]) {
            System.assertEquals(a.Name.trim(), a.Name, 'Name should be trimmed on insert');
        }
        accts[0].Name = '  Renamed  ';
        update accts[0];
        System.assertEquals('Renamed', [SELECT Name FROM Account WHERE Id = :accts[0].Id].Name);
    }
    @IsTest
    static void otherContextsAreNoOps() {
        Account a = new Account(Name = 'Ctx');
        insert a;
        delete a;
        undelete a;
        System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Id = :a.Id]);
    }
}
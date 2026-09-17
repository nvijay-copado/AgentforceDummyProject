public with sharing class DummyUsb2child2 {
    public static List<Account> getAccounts() {
        return [
            SELECT Id, Name
            FROM Account
            LIMIT 10
        ];
    }
}
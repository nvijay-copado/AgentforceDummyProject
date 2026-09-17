public with sharing class DummyUsb2child1 {
    public static List<Account> getAccounts() {
        return [
            SELECT Id, Name
            FROM Account
            LIMIT 10
        ];
    }
}
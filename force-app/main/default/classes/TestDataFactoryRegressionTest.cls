@IsTest
private class TestDataFactoryRegressionTest {
    @IsTest
    static void accountBuilderCreatesRecord() {
        Account acc = TestDataFactory.account().withName('Acme').withIndustry('Energy').create();
        Account result = [SELECT Name, Industry FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Acme', result.Name, 'Name should match');
        System.assertEquals('Energy', result.Industry, 'Industry should match');
    }

    @IsTest
    static void contactBuilderLinksAccount() {
        Account acc = TestDataFactory.account().create();
        Contact c = TestDataFactory.contact().withLastName('Doe').forAccount(acc.Id).create();
        Contact result = [SELECT LastName, AccountId FROM Contact WHERE Id = :c.Id];
        System.assertEquals('Doe', result.LastName, 'Last name should match');
        System.assertEquals(acc.Id, result.AccountId, 'Contact should link to account');
    }

    @IsTest
    static void opportunityBuilderSetsFields() {
        Account acc = TestDataFactory.account().create();
        Opportunity o = TestDataFactory.opportunity().withName('Deal').withStage('Qualification')
            .withAmount(500).forAccount(acc.Id).create();
        Opportunity result = [SELECT Name, StageName, Amount, AccountId FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Deal', result.Name, 'Name should match');
        System.assertEquals('Qualification', result.StageName, 'Stage should match');
        System.assertEquals(500, result.Amount, 'Amount should match');
        System.assertEquals(acc.Id, result.AccountId, 'Opportunity should link to account');
    }

    @IsTest
    static void buildDoesNotInsert() {
        Account acc = TestDataFactory.account().build();
        System.assertEquals(null, acc.Id, 'build() must not insert');
    }

    @IsTest
    static void bulkCreationIsBulkified() {
        List<Account> accounts = TestDataFactory.createAccounts(20);
        TestDataFactory.createContacts(3, accounts);
        TestDataFactory.createOpportunities(2, accounts);
        System.assertEquals(20, [SELECT COUNT() FROM Account], 'Accounts');
        System.assertEquals(60, [SELECT COUNT() FROM Contact], 'Contacts');
        System.assertEquals(40, [SELECT COUNT() FROM Opportunity], 'Opportunities');
    }
}
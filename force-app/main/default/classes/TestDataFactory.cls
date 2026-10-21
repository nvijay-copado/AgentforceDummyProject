@IsTest
public with sharing class TestDataFactory {
    public class AccountBuilder {
        private Account record = new Account(Name = 'Test Account');
        public AccountBuilder withName(String name) { record.Name = name; return this; }
        public AccountBuilder withIndustry(String industry) { record.Industry = industry; return this; }
        public Account build() { return record; }
        public Account create() { insert record; return record; }
    }

    public class ContactBuilder {
        private Contact record = new Contact(FirstName = 'Test', LastName = 'Contact');
        public ContactBuilder withLastName(String lastName) { record.LastName = lastName; return this; }
        public ContactBuilder forAccount(Id accountId) { record.AccountId = accountId; return this; }
        public Contact build() { return record; }
        public Contact create() { insert record; return record; }
    }

    public class OpportunityBuilder {
        private Opportunity record = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        public OpportunityBuilder withName(String name) { record.Name = name; return this; }
        public OpportunityBuilder withStage(String stage) { record.StageName = stage; return this; }
        public OpportunityBuilder withAmount(Decimal amount) { record.Amount = amount; return this; }
        public OpportunityBuilder forAccount(Id accountId) { record.AccountId = accountId; return this; }
        public Opportunity build() { return record; }
        public Opportunity create() { insert record; return record; }
    }

    public static AccountBuilder account() { return new AccountBuilder(); }
    public static ContactBuilder contact() { return new ContactBuilder(); }
    public static OpportunityBuilder opportunity() { return new OpportunityBuilder(); }

    public static List<Account> createAccounts(Integer count) {
        List<Account> records = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            records.add(account().withName('Test Account ' + i).build());
        }
        insert records;
        return records;
    }

    public static List<Contact> createContacts(Integer perAccount, List<Account> accounts) {
        List<Contact> records = new List<Contact>();
        for (Account acc : accounts) {
            for (Integer i = 0; i < perAccount; i++) {
                records.add(contact().withLastName('Contact ' + i).forAccount(acc.Id).build());
            }
        }
        insert records;
        return records;
    }

    public static List<Opportunity> createOpportunities(Integer perAccount, List<Account> accounts) {
        List<Opportunity> records = new List<Opportunity>();
        for (Account acc : accounts) {
            for (Integer i = 0; i < perAccount; i++) {
                records.add(opportunity().withName('Opp ' + i).forAccount(acc.Id).build());
            }
        }
        insert records;
        return records;
    }
}
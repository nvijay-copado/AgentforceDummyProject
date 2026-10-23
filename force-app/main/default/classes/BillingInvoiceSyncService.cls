public with sharing class BillingInvoiceSyncService {
    public static final String ENDPOINT = 'callout:Billing_API/invoices';

    public class SyncException extends Exception {}

    public class InvoiceDto {
        public String id;
        public Decimal amount;
        public String status;
        public String number_x;
        public Id accountId;
    }

    /** Pulls invoices from the billing system and upserts them by external id. Returns rows processed. */
    public static Integer sync() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod('GET');
        req.setTimeout(60000);
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() < 200 || res.getStatusCode() > 299) {
            throw new SyncException('Billing API returned ' + res.getStatusCode());
        }
        return upsertInvoices(res.getBody());
    }

    @TestVisible
    private static Integer upsertInvoices(String body) {
        List<Object> rows = (List<Object>) JSON.deserializeUntyped(body);
        Map<String, Invoice__c> byExternalId = new Map<String, Invoice__c>();
        for (Object o : rows) {
            Map<String, Object> m = (Map<String, Object>) o;
            String extId = (String) m.get('id');
            if (String.isBlank(extId)) {
                continue;
            }
            Invoice__c inv = new Invoice__c(
                External_Id__c = extId,
                Name = (String) m.get('number'),
                Status__c = (String) m.get('status')
            );
            Object amt = m.get('amount');
            if (amt != null) {
                inv.Amount__c = Decimal.valueOf(String.valueOf(amt));
            }
            String acct = (String) m.get('accountId');
            if (String.isNotBlank(acct)) {
                inv.Account__c = (Id) acct;
            }
            byExternalId.put(extId, inv);
        }
        if (!byExternalId.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(byExternalId.values(), Invoice__c.External_Id__c, true);
            return results.size();
        }
        return 0;
    }
}
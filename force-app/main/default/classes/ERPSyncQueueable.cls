/**
 * Sends approved quote terms to the ERP through ERPCalloutService. Runs asynchronously because callouts are
 * not allowed in the trigger transaction. A failure marks the request Failed and never reverts the approval.
 */
public with sharing class ERPSyncQueueable implements Queueable, Database.AllowsCallouts {
    public static final String PATH = '/quote-approvals';
    public static final String STATUS_SENT = 'Sent';
    public static final String STATUS_FAILED = 'Failed';
    public static final Integer MAX_ERROR_LENGTH = 2000;

    private final Set<Id> requestIds;

    public ERPSyncQueueable(Set<Id> requestIds) {
        this.requestIds = requestIds;
    }

    public static Id enqueue(Set<Id> requestIds) {
        if (requestIds == null || requestIds.isEmpty()) {
            return null;
        }
        return System.enqueueJob(new ERPSyncQueueable(requestIds));
    }

    public void execute(QueueableContext context) {
        sync(requestIds);
    }

    public static void sync(Set<Id> requestIds) {
        List<Quote_Approval_Request__c> requests = [
            SELECT Id, Name, Opportunity__c, Account__c, Discount_Percent__c, Required_Level__c,
                   Available_Credit__c, Decision_Date__c
            FROM Quote_Approval_Request__c
            WHERE Id IN :requestIds AND Decision__c = 'Approved'
        ];
        for (Quote_Approval_Request__c req : requests) {
            try {
                HttpResponse res = ERPCalloutService.post(PATH, buildBody(req));
                req.ERP_Reference__c = parseReference(res.getBody());
                req.Sync_Status__c = STATUS_SENT;
                req.Last_Error__c = null;
            } catch (Exception ex) {
                req.Sync_Status__c = STATUS_FAILED;
                req.Last_Error__c = ex.getMessage().abbreviate(MAX_ERROR_LENGTH);
            }
        }
        if (!requests.isEmpty()) {
            update requests;
        }
    }

    @TestVisible
    private static String buildBody(Quote_Approval_Request__c req) {
        return JSON.serialize(
            new Map<String, Object>{
                'requestNumber' => req.Name,
                'opportunityId' => req.Opportunity__c,
                'accountId' => req.Account__c,
                'discountPercent' => req.Discount_Percent__c,
                'approverLevel' => req.Required_Level__c,
                'availableCredit' => req.Available_Credit__c,
                'approvedOn' => req.Decision_Date__c
            }
        );
    }

    @TestVisible
    private static String parseReference(String body) {
        if (String.isBlank(body)) {
            return null;
        }
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(body);
        Object ref = parsed.get('reference');
        return ref == null ? null : String.valueOf(ref);
    }
}
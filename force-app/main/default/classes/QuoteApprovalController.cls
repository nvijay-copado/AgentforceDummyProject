public with sharing class QuoteApprovalController {
    public static final String PERMISSION = 'Approve_Quote_Discounts';

    public class ApprovalView {
        @AuraEnabled public Id requestId;
        @AuraEnabled public String name;
        @AuraEnabled public String requiredLevel;
        @AuraEnabled public Decimal discountPercent;
        @AuraEnabled public String decision;
        @AuraEnabled public Decimal creditLimit;
        @AuraEnabled public Decimal utilizedCredit;
        @AuraEnabled public Decimal availableCredit;
        @AuraEnabled public Boolean creditReviewRequired;
        @AuraEnabled public String syncStatus;
        @AuraEnabled public String erpReference;
        @AuraEnabled public String lastError;
        @AuraEnabled public String lifecycle;
        @AuraEnabled public Decimal escalationLevel;
        @AuraEnabled public Boolean canDecide;
    }

    @AuraEnabled(cacheable=true)
    public static ApprovalView getApproval(Id opportunityId) {
        List<Quote_Approval_Request__c> rows = [
            SELECT Id, Name, Required_Level__c, Discount_Percent__c, Decision__c, Credit_Limit__c,
                   Utilized_Credit__c, Available_Credit__c, Credit_Review_Required__c, Sync_Status__c,
                   ERP_Reference__c, Last_Error__c, Lifecycle__c, Escalation_Level__c
            FROM Quote_Approval_Request__c
            WHERE Opportunity__c = :opportunityId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (rows.isEmpty()) {
            return null;
        }
        Quote_Approval_Request__c r = rows[0];
        ApprovalView v = new ApprovalView();
        v.requestId = r.Id;
        v.name = r.Name;
        v.requiredLevel = r.Required_Level__c;
        v.discountPercent = r.Discount_Percent__c;
        v.decision = r.Decision__c;
        v.creditLimit = r.Credit_Limit__c;
        v.utilizedCredit = r.Utilized_Credit__c;
        v.availableCredit = r.Available_Credit__c;
        v.creditReviewRequired = r.Credit_Review_Required__c;
        v.syncStatus = r.Sync_Status__c;
        v.erpReference = r.ERP_Reference__c;
        v.lastError = r.Last_Error__c;
        v.lifecycle = r.Lifecycle__c;
        v.escalationLevel = r.Escalation_Level__c;
        v.canDecide = FeatureManagement.checkPermission(PERMISSION);
        return v;
    }

    @AuraEnabled
    public static void decide(Id requestId, String decision) {
        requirePermission();
        if (decision != 'Approved' && decision != 'Rejected') {
            throw new AuraHandledException('Decision must be Approved or Rejected.');
        }
        Quote_Approval_Request__c req = loadForUpdate(requestId);
        if (req.Decision__c != QuoteApprovalOrchestrator.DECISION_PENDING) {
            throw new AuraHandledException('This request has already been decided.');
        }
        req.Decision__c = decision;
        req.Decision_Date__c = Datetime.now();
        req.Approver__c = UserInfo.getUserId();
        req.Open_Key__c = null;
        Database.update(req, AccessLevel.USER_MODE);
        if (decision == 'Approved') {
            ERPSyncQueueable.enqueue(new Set<Id>{ req.Id });
        }
    }

    @AuraEnabled
    public static void retrySync(Id requestId) {
        requirePermission();
        Quote_Approval_Request__c req = loadForUpdate(requestId);
        if (req.Decision__c != 'Approved' || req.Sync_Status__c != ERPSyncQueueable.STATUS_FAILED) {
            throw new AuraHandledException('Only approved requests with a failed sync can be retried.');
        }
        ERPSyncQueueable.enqueue(new Set<Id>{ req.Id });
    }

    private static Quote_Approval_Request__c loadForUpdate(Id requestId) {
        List<Quote_Approval_Request__c> rows = [
            SELECT Id, Decision__c, Sync_Status__c
            FROM Quote_Approval_Request__c
            WHERE Id = :requestId
            WITH USER_MODE
            FOR UPDATE
        ];
        if (rows.isEmpty()) {
            throw new AuraHandledException('Approval request not found.');
        }
        return rows[0];
    }

    private static void requirePermission() {
        if (!FeatureManagement.checkPermission(PERMISSION)) {
            throw new AuraHandledException('You do not have permission to manage quote approvals.');
        }
    }
}
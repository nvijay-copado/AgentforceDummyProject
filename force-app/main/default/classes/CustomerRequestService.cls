/**
 * Service class for managing Customer Request (Customer_Request__c) records.
 * Supports bulk creation and search/filter operations used by the
 * Customer Request Management feature (US-0012506).
 */
public with sharing class CustomerRequestService {

    /**
     * Bulk-creates Customer Request records.
     * @param requests List of Customer_Request__c records to insert.
     * @return The same list, populated with Ids after insert.
     */
    public static List<Customer_Request__c> createCustomerRequests(List<Customer_Request__c> requests) {
        if (requests == null || requests.isEmpty()) {
            return new List<Customer_Request__c>();
        }

        List<Customer_Request__c> toInsert = new List<Customer_Request__c>();
        for (Customer_Request__c request : requests) {
            if (String.isBlank(request.Status__c)) {
                request.Status__c = 'New';
            }
            toInsert.add(request);
        }

        if (Schema.sObjectType.Customer_Request__c.isCreateable()) {
            insert toInsert;
        }
        return toInsert;
    }

    /**
     * Searches and filters Customer Request records by Account, Status and Priority.
     * All filter parameters are optional; pass null to skip a filter.
     * @param accountId Account Id to filter by.
     * @param status Status__c value to filter by.
     * @param priority Priority__c value to filter by.
     * @return List of matching Customer_Request__c records, most recently requested first.
     */
    public static List<Customer_Request__c> searchCustomerRequests(Id accountId, String status, String priority) {
        if (!Schema.sObjectType.Customer_Request__c.isAccessible()) {
            return new List<Customer_Request__c>();
        }

        // Single static, bulk-safe query filtered by the only indexed/selective
        // criterion (Account), with the remaining optional filters applied in
        // memory. Keeps field references resolvable at compile time.
        List<Customer_Request__c> candidates = (accountId != null)
            ? [
                SELECT Id, Name, Account__c, Request_Type__c, Priority__c, Status__c,
                       Description__c, Requested_Date__c, Target_Completion_Date__c
                FROM Customer_Request__c
                WHERE Account__c = :accountId
                ORDER BY Requested_Date__c DESC NULLS LAST
                LIMIT 1000
              ]
            : [
                SELECT Id, Name, Account__c, Request_Type__c, Priority__c, Status__c,
                       Description__c, Requested_Date__c, Target_Completion_Date__c
                FROM Customer_Request__c
                ORDER BY Requested_Date__c DESC NULLS LAST
                LIMIT 1000
              ];

        if (String.isBlank(status) && String.isBlank(priority)) {
            return candidates;
        }

        List<Customer_Request__c> filtered = new List<Customer_Request__c>();
        for (Customer_Request__c request : candidates) {
            if (String.isNotBlank(status) && request.Status__c != status) {
                continue;
            }
            if (String.isNotBlank(priority) && request.Priority__c != priority) {
                continue;
            }
            filtered.add(request);
        }
        return filtered;
    }

    /**
     * Updates the status of a set of Customer Request records in bulk.
     * @param requestIds Ids of the Customer_Request__c records to update.
     * @param newStatus The new Status__c value to apply.
     * @return The updated Customer_Request__c records.
     */
    public static List<Customer_Request__c> updateStatus(Set<Id> requestIds, String newStatus) {
        if (requestIds == null || requestIds.isEmpty() || String.isBlank(newStatus)) {
            return new List<Customer_Request__c>();
        }

        List<Customer_Request__c> toUpdate = [
            SELECT Id, Status__c
            FROM Customer_Request__c
            WHERE Id IN :requestIds
        ];

        for (Customer_Request__c request : toUpdate) {
            request.Status__c = newStatus;
        }

        if (!toUpdate.isEmpty() && Schema.sObjectType.Customer_Request__c.isUpdateable()) {
            update toUpdate;
        }
        return toUpdate;
    }
}
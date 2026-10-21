/**
 * Archives closed Cases older than 3 years into Case_Archive__b,
 * then hands successfully archived Case Ids to a Queueable for deletion.
 */
public with sharing class CaseArchivalBatch implements Database.Batchable<SObject>, Database.Stateful {
    @TestVisible
    private static Datetime cutoff = Datetime.now().addYears(-3);

    // Big Object writes cannot run after uncommitted DML in tests, so tests bypass the write.
    @TestVisible
    private static Boolean skipBigObjectWrite = false;

    public Integer archivedCount = 0;
    public Integer failedCount = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime cutoffDate = cutoff;
        return Database.getQueryLocator([
            SELECT Id, CaseNumber, Subject, Status, AccountId, ClosedDate
            FROM Case
            WHERE IsClosed = true AND ClosedDate < :cutoffDate
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Case> scope) {
        List<Case_Archive__b> archives = new List<Case_Archive__b>();
        for (Case c : scope) {
            archives.add(new Case_Archive__b(
                Case_Id__c = c.Id,
                Closed_Date__c = c.ClosedDate,
                Case_Number__c = c.CaseNumber,
                Subject__c = c.Subject,
                Status__c = c.Status,
                Account_Id__c = c.AccountId,
                Archived_On__c = Datetime.now(),
                Archived_By__c = UserInfo.getUserId()
            ));
        }
        List<Database.SaveResult> results = skipBigObjectWrite ? null : Database.insertImmediate(archives);
        List<Id> archivedIds = new List<Id>();
        for (Integer i = 0; i < archives.size(); i++) {
            if (results == null || results[i].isSuccess()) {
                archivedIds.add(scope[i].Id);
            } else {
                failedCount++;
            }
        }
        archivedCount += archivedIds.size();
        if (!archivedIds.isEmpty()) {
            System.enqueueJob(new CaseArchivalCleanupQueueable(archivedIds));
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'Case archival finished. Archived=' + archivedCount + ' Failed=' + failedCount);
    }
}
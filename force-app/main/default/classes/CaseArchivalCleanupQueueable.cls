/** Deletes original Cases after they have been written to Case_Archive__b. */
public with sharing class CaseArchivalCleanupQueueable implements Queueable {
    private List<Id> caseIds;

    public CaseArchivalCleanupQueueable(List<Id> caseIds) {
        this.caseIds = caseIds;
    }

    public void execute(QueueableContext context) {
        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }
        List<Case> toDelete = [SELECT Id FROM Case WHERE Id IN :caseIds AND IsClosed = true];
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }
}
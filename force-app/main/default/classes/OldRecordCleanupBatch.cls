public with sharing class OldRecordCleanupBatch implements Database.Batchable<SObject> {
    public static final Integer RETENTION_YEARS = 2;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime cutoff = Datetime.now().addYears(-RETENTION_YEARS);
        return Database.getQueryLocator([
            SELECT Id FROM Task WHERE IsClosed = true AND CreatedDate < :cutoff
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        Database.delete(scope, false);
    }

    public void finish(Database.BatchableContext bc) {}
}
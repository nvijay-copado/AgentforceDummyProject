public with sharing class OldRecordCleanupScheduler implements Schedulable {
    public static final String CRON_NIGHTLY = '0 0 2 * * ?';

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new OldRecordCleanupBatch(), 200);
    }
}
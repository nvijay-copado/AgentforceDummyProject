/** Schedules the nightly Case archival batch. */
public with sharing class CaseArchivalScheduler implements Schedulable {
    public static final String CRON_NIGHTLY = '0 0 2 * * ?';

    public static Id schedule() {
        return System.schedule('Case Archival Nightly', CRON_NIGHTLY, new CaseArchivalScheduler());
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CaseArchivalBatch(), 200);
    }
}
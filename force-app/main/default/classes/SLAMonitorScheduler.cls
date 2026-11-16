/** Runs SLAMonitorBatch. Schedule with scheduleEvery15Minutes() to get four jobs per hour. */
public with sharing class SLAMonitorScheduler implements Schedulable {
    public static final Integer BATCH_SIZE = 200;
    private static final List<String> CRON_EXPRESSIONS = new List<String>{
        '0 0 * * * ?',
        '0 15 * * * ?',
        '0 30 * * * ?',
        '0 45 * * * ?'
    };

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new SLAMonitorBatch(), BATCH_SIZE);
    }

    public static List<Id> scheduleEvery15Minutes() {
        List<Id> jobIds = new List<Id>();
        for (String cron : CRON_EXPRESSIONS) {
            jobIds.add(System.schedule('SLA Monitor ' + cron, cron, new SLAMonitorScheduler()));
        }
        return jobIds;
    }
}
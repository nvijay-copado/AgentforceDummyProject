/** Schedules PipelineRollupBatch daily at 02:00. */
public with sharing class PipelineRollupScheduler implements Schedulable {
    public static final String CRON_DAILY_2AM = '0 0 2 * * ?';
    public static final String JOB_NAME = 'Pipeline Rollup Daily';

    public static Id schedule() {
        return System.schedule(JOB_NAME, CRON_DAILY_2AM, new PipelineRollupScheduler());
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new PipelineRollupBatch(), 200);
    }
}
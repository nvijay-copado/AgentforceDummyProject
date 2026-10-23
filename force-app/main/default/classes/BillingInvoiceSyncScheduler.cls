public with sharing class BillingInvoiceSyncScheduler implements Schedulable {
    public static final String HOURLY_CRON = '0 0 * * * ?';

    public static Id scheduleHourly() {
        return System.schedule('Billing Invoice Sync', HOURLY_CRON, new BillingInvoiceSyncScheduler());
    }

    public void execute(SchedulableContext sc) {
        System.enqueueJob(new BillingInvoiceSyncQueueable());
    }
}
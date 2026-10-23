public with sharing class BillingInvoiceSyncQueueable implements Queueable, Database.AllowsCallouts {
    public static final Integer MAX_RETRIES = 3;
    @TestVisible private static Integer chainedCount = 0;
    @TestVisible private static Boolean suppressEnqueue = false;

    private final Integer attempt;

    public BillingInvoiceSyncQueueable() {
        this(0);
    }

    public BillingInvoiceSyncQueueable(Integer attempt) {
        this.attempt = attempt;
    }

    public void execute(QueueableContext ctx) {
        try {
            BillingInvoiceSyncService.sync();
        } catch (Exception e) {
            if (attempt < MAX_RETRIES) {
                chainedCount++;
                if (!suppressEnqueue) {
                    System.enqueueJob(new BillingInvoiceSyncQueueable(attempt + 1));
                }
            } else {
                System.debug(LoggingLevel.ERROR, 'Billing sync failed after ' + MAX_RETRIES + ' retries: ' + e.getMessage());
            }
        }
    }
}
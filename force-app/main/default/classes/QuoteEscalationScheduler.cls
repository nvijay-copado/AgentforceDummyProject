public with sharing class QuoteEscalationScheduler implements Schedulable {
    public static final Integer BATCH_SIZE = 100;

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new QuoteEscalationBatch(), BATCH_SIZE);
    }
}
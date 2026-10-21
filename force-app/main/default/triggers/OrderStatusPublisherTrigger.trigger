trigger OrderStatusPublisherTrigger on Order (after update) {
    OrderStatusPublisher.publishChanges(Trigger.new, Trigger.oldMap);
}
trigger OrderStatusEventTrigger on Order_Status_Event__e (after insert) {
    OrderStatusEventSubscriber.handle(Trigger.new);
}
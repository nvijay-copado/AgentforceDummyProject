public with sharing class OrderStatusPublisher {
    public static List<Database.SaveResult> publishChanges(List<Order> newOrders, Map<Id, Order> oldMap) {
        List<Order_Status_Event__e> events = new List<Order_Status_Event__e>();
        for (Order o : newOrders) {
            Order old = oldMap == null ? null : oldMap.get(o.Id);
            if (old != null && old.Status != o.Status) {
                events.add(new Order_Status_Event__e(
                    Order_Id__c = o.Id, New_Status__c = o.Status, Old_Status__c = old.Status));
            }
        }
        if (events.isEmpty()) {
            return new List<Database.SaveResult>();
        }
        return EventBus.publish(events);
    }
}
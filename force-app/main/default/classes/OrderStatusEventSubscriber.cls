public with sharing class OrderStatusEventSubscriber {
    public static void handle(List<Order_Status_Event__e> events) {
        try {
            process(events);
            // Checkpoint after success so a retry resumes after the last processed event.
            EventBus.TriggerContext ctx = EventBus.TriggerContext.currentContext();
            if (ctx != null) {
                ctx.setResumeCheckpoint(events[events.size() - 1].ReplayId);
            }
        } catch (Exception ex) {
            EventBus.TriggerContext ctx = EventBus.TriggerContext.currentContext();
            if (ctx != null && ctx.retries < 4) {
                throw new EventBus.RetryableException(ex.getMessage());
            }
            System.debug(LoggingLevel.ERROR, 'Order status event failed: ' + ex.getMessage());
        }
    }

    public static Integer process(List<Order_Status_Event__e> events) {
        Set<Id> orderIds = new Set<Id>();
        for (Order_Status_Event__e e : events) {
            if (String.isNotBlank(e.Order_Id__c)) {
                orderIds.add((Id) e.Order_Id__c);
            }
        }
        Map<Id, Order> orders = new Map<Id, Order>(
            [SELECT Id, OrderNumber, OwnerId, Quote_Approval_Request__c FROM Order WHERE Id IN :orderIds]);
        List<Task> tasks = new List<Task>();
        for (Order_Status_Event__e e : events) {
            Order o = String.isBlank(e.Order_Id__c) ? null : orders.get((Id) e.Order_Id__c);
            if (o != null) {
                tasks.add(new Task(
                    WhoId = null, WhatId = o.Id, OwnerId = o.OwnerId,
                    Subject = 'Order ' + o.OrderNumber + ' status changed to ' + e.New_Status__c,
                    Description = 'Previous status: ' + e.Old_Status__c + '. Event ReplayId: ' + e.ReplayId,
                    ActivityDate = Date.today(), Status = 'Not Started'));
            }
        }
        if (!tasks.isEmpty()) {
            insert tasks;
        }
        syncApprovalLifecycle(events, orders);
        return tasks.size();
    }

    /** Activated orders fulfil their linked approval request, cancelled orders cancel it. Idempotent. */
    private static void syncApprovalLifecycle(List<Order_Status_Event__e> events, Map<Id, Order> orders) {
        Map<Id, String> target = new Map<Id, String>();
        for (Order_Status_Event__e e : events) {
            Order o = String.isBlank(e.Order_Id__c) ? null : orders.get((Id) e.Order_Id__c);
            if (o == null || o.Quote_Approval_Request__c == null) {
                continue;
            }
            if (e.New_Status__c == 'Activated') {
                target.put(o.Quote_Approval_Request__c, 'Fulfilled');
            } else if (e.New_Status__c == 'Cancelled' || e.New_Status__c == 'Canceled') {
                target.put(o.Quote_Approval_Request__c, 'Cancelled');
            }
        }
        if (target.isEmpty()) {
            return;
        }
        List<Quote_Approval_Request__c> updates = new List<Quote_Approval_Request__c>();
        for (Quote_Approval_Request__c r : [
            SELECT Id, Lifecycle__c FROM Quote_Approval_Request__c WHERE Id IN :target.keySet()
        ]) {
            if (r.Lifecycle__c != target.get(r.Id)) {
                updates.add(new Quote_Approval_Request__c(Id = r.Id, Lifecycle__c = target.get(r.Id)));
            }
        }
        if (!updates.isEmpty()) {
            update updates;
        }
    }
}
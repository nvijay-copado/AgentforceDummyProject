@IsTest
private class OrderStatusEventTest {
    @TestSetup
    static void setup() {
        Account a = new Account(Name = 'Test Acct');
        insert a;
        insert new Order(AccountId = a.Id, Status = 'Draft', EffectiveDate = Date.today());
    }

    @IsTest
    static void statusChangePublishesAndNotifies() {
        Order o = [SELECT Id, Status, OwnerId FROM Order LIMIT 1];
        Order changed = o.clone(true, true, true, true);
        changed.Status = 'Activated';
        Test.startTest();
        List<Database.SaveResult> res = OrderStatusPublisher.publishChanges(
            new List<Order>{ changed }, new Map<Id, Order>{ o.Id => o });
        Test.getEventBus().deliver();
        Test.stopTest();
        System.assertEquals(1, res.size());
        System.assert(res[0].isSuccess(), 'Event should publish');
        List<Task> tasks = [SELECT Subject FROM Task WHERE WhatId = :o.Id];
        System.assertEquals(1, tasks.size(), 'One notification task expected');
        System.assert(tasks[0].Subject.contains('Activated'), 'Subject should show new status');
    }

    @IsTest
    static void noChangePublishesNothing() {
        Order o = [SELECT Id, Description FROM Order LIMIT 1];
        Test.startTest();
        o.Description = 'edit';
        update o;
        Test.getEventBus().deliver();
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhatId = :o.Id]);
    }

    @IsTest
    static void publisherHandlesNullOldMap() {
        System.assertEquals(0, OrderStatusPublisher.publishChanges(new List<Order>(), null).size());
    }

    @IsTest
    static void subscriberSkipsBlankAndUnknownOrders() {
        Integer n = OrderStatusEventSubscriber.process(new List<Order_Status_Event__e>{
            new Order_Status_Event__e(Order_Id__c = null, New_Status__c = 'X')});
        System.assertEquals(0, n);
    }
}
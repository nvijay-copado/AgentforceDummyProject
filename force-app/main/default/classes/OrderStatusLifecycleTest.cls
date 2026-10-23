@IsTest
private class OrderStatusLifecycleTest {
    private static Order makeOrder(Id requestId) {
        Account a = new Account(Name = 'Lifecycle Acct');
        insert a;
        Order o = new Order(AccountId = a.Id, Status = 'Draft', EffectiveDate = Date.today(), Quote_Approval_Request__c = requestId);
        insert o;
        return o;
    }

    private static Order_Status_Event__e evt(Order o, String status) {
        return new Order_Status_Event__e(Order_Id__c = o.Id, New_Status__c = status, Old_Status__c = 'Draft');
    }

    @IsTest
    static void activatedFulfilsRequest() {
        Quote_Approval_Request__c r = TestDataFactory.approvalRequest().create();
        Order o = makeOrder(r.Id);
        OrderStatusEventSubscriber.process(new List<Order_Status_Event__e>{ evt(o, 'Activated') });
        OrderStatusEventSubscriber.process(new List<Order_Status_Event__e>{ evt(o, 'Activated') });
        System.assertEquals('Fulfilled', [SELECT Lifecycle__c FROM Quote_Approval_Request__c WHERE Id = :r.Id].Lifecycle__c);
    }

    @IsTest
    static void cancelledCancelsRequest() {
        Quote_Approval_Request__c r = TestDataFactory.approvalRequest().create();
        Order o = makeOrder(r.Id);
        OrderStatusEventSubscriber.process(new List<Order_Status_Event__e>{ evt(o, 'Canceled') });
        System.assertEquals('Cancelled', [SELECT Lifecycle__c FROM Quote_Approval_Request__c WHERE Id = :r.Id].Lifecycle__c);
    }

    @IsTest
    static void unlinkedOrderLeavesRequestsAlone() {
        Quote_Approval_Request__c r = TestDataFactory.approvalRequest().create();
        Order o = makeOrder(null);
        OrderStatusEventSubscriber.process(new List<Order_Status_Event__e>{ evt(o, 'Activated') });
        System.assertEquals('Open', [SELECT Lifecycle__c FROM Quote_Approval_Request__c WHERE Id = :r.Id].Lifecycle__c);
    }
}
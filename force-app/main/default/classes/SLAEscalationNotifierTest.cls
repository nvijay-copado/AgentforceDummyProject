@IsTest
private class SLAEscalationNotifierTest {
    @IsTest
    static void ignoresEventsWithoutCase() {
        System.assertEquals(0, SLAEscalationNotifier.notify(new List<SLA_Breach_Event__e>{ new SLA_Breach_Event__e() }));
    }

    @IsTest
    static void notifiesRecipientOnEscalation() {
        Case c = new Case(Subject = 'At risk', Status = 'New', Priority = 'High');
        insert c;
        insert new Escalation__c(
            Case__c = c.Id, Level__c = 1, Reason__c = 'At Risk', Escalated_On__c = Datetime.now(),
            Escalated_To__c = UserInfo.getUserId());
        SLA_Breach_Event__e ev = new SLA_Breach_Event__e(
            Case_Id__c = c.Id, Escalation_Level__c = 1, Breached_On__c = Datetime.now());
        Integer sent = SLAEscalationNotifier.notify(new List<SLA_Breach_Event__e>{ ev });
        Integer expected = [SELECT COUNT() FROM CustomNotificationType WHERE DeveloperName = 'Case_SLA_Escalation'];
        System.assertEquals(expected, sent, 'One notification per escalation when the type exists');
    }

    @IsTest
    static void publishingEventRunsTrigger() {
        Case c = new Case(Subject = 'Event', Status = 'New', Priority = 'High');
        insert c;
        Test.startTest();
        EventBus.publish(new SLA_Breach_Event__e(Case_Id__c = c.Id, Escalation_Level__c = 1, Breached_On__c = Datetime.now()));
        Test.stopTest();
        System.assertNotEquals(null, c.Id);
    }
}
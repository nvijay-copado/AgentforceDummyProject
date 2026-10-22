@IsTest
private class EscalationServiceTest {
    private static List<Case> createCases(Integer n, String priority) {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < n; i++) {
            cases.add(new Case(Subject = 'Esc ' + i, Priority = priority, Status = 'New', Origin = 'Web'));
        }
        insert cases;
        return cases;
    }

    private static List<Case> query(Set<Id> ids) {
        return [
            SELECT Id, Priority, Status, OwnerId, SLA_Start_Date__c, SLA_Due_Date__c, SLA_Status__c, Escalation_Level__c
            FROM Case WHERE Id IN :ids
        ];
    }

    @IsTest
    static void breachedCaseIsEscalatedOnce() {
        List<Case> cases = createCases(1, 'High');
        Datetime future = Datetime.now().addDays(60);
        Test.startTest();
        EscalationService.Result first = EscalationService.process(query(new Map<Id, Case>(cases).keySet()), future);
        Test.stopTest();
        System.assertEquals(1, first.escalationsCreated);
        System.assertEquals(1, first.eventsPublished);
        Case r = query(new Map<Id, Case>(cases).keySet())[0];
        System.assertEquals('Breached', r.SLA_Status__c);
        System.assertEquals(1, r.Escalation_Level__c);
        System.assertEquals(1, [SELECT COUNT() FROM Escalation__c WHERE Case__c = :r.Id AND Level__c = 1]);

        EscalationService.Result second = EscalationService.process(query(new Map<Id, Case>(cases).keySet()), future);
        System.assertEquals(0, second.escalationsCreated, 'No duplicate escalation for an already breached case');
    }

    @IsTest
    static void onTrackAndPausedAndClosedAreSkipped() {
        List<Case> cases = createCases(3, 'Medium');
        cases[1].Status = 'Waiting on Customer';
        cases[2].Status = 'Closed';
        cases[2].Resolution_Summary__c = 'Done';
        update cases;
        EscalationService.Result res = EscalationService.process(query(new Map<Id, Case>(cases).keySet()), Datetime.now());
        System.assertEquals(0, res.statusChanges);
        System.assertEquals(0, [SELECT COUNT() FROM Escalation__c]);
    }

    @IsTest
    static void atRiskThenBreachedProducesTwoLevels() {
        List<Case> cases = createCases(1, 'High');
        Set<Id> ids = new Map<Id, Case>(cases).keySet();
        Case c = query(ids)[0];
        Long window = c.SLA_Due_Date__c.getTime() - c.SLA_Start_Date__c.getTime();
        Datetime atRiskTime = c.SLA_Start_Date__c.addSeconds((Integer) (window * 0.85 / 1000));
        EscalationService.process(new List<Case>{ c }, atRiskTime);
        System.assertEquals('At Risk', query(ids)[0].SLA_Status__c);
        EscalationService.process(query(ids), c.SLA_Due_Date__c.addHours(1));
        Case r = query(ids)[0];
        System.assertEquals('Breached', r.SLA_Status__c);
        System.assertEquals(2, r.Escalation_Level__c);
        System.assertEquals(2, [SELECT COUNT() FROM Escalation__c WHERE Case__c = :r.Id]);
    }

    @IsTest
    static void bulkTwoHundredCasesStaysWithinLimits() {
        List<Case> cases = createCases(200, 'Low');
        Test.startTest();
        EscalationService.Result res = EscalationService.process(
            query(new Map<Id, Case>(cases).keySet()),
            Datetime.now().addDays(90)
        );
        Test.stopTest();
        System.assertEquals(200, res.escalationsCreated);
        System.assertEquals(200, [SELECT COUNT() FROM Escalation__c]);
    }

    @IsTest
    static void maxLevelIsRespected() {
        List<Case> cases = createCases(1, 'Low');
        Set<Id> ids = new Map<Id, Case>(cases).keySet();
        Integer max = SLAPolicyService.getPolicy('Low').maxLevel;
        Case c = query(ids)[0];
        CaseSLATriggerHandler.bypassLevelCheck = true;
        update new Case(Id = c.Id, Escalation_Level__c = max);
        CaseSLATriggerHandler.bypassLevelCheck = false;
        EscalationService.Result res = EscalationService.process(query(ids), Datetime.now().addDays(90));
        System.assertEquals(0, res.escalationsCreated);
    }

    @IsTest
    static void batchProcessesBreachedCases() {
        List<Case> cases = createCases(5, 'High');
        SLAMonitorBatch batch = new SLAMonitorBatch();
        batch.nowOverride = Datetime.now().addDays(60);
        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        System.assertEquals(5, [SELECT COUNT() FROM Escalation__c]);
    }

    @IsTest
    static void schedulerRegistersFourJobs() {
        Test.startTest();
        List<Id> jobs = SLAMonitorScheduler.scheduleEvery15Minutes();
        Test.stopTest();
        System.assertEquals(4, jobs.size());
        System.assertEquals(4, [SELECT COUNT() FROM CronTrigger WHERE Id IN :jobs]);
    }
}
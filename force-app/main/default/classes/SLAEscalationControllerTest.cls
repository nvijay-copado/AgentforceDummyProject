@IsTest
private class SLAEscalationControllerTest {
    private static User makeUser(String alias, String permSetName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = alias,
            Email = alias + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = alias,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = alias + System.currentTimeMillis() + '@example.com'
        );
        insert u;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :permSetName];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        return u;
    }

    private static Escalation__c makeEscalation(Id assignee) {
        Case c = new Case(Subject = 'Ctl', Priority = 'High', Status = 'New', Origin = 'Web');
        insert c;
        Escalation__c e = new Escalation__c(
            Case__c = c.Id,
            Level__c = 1,
            Reason__c = 'Breached',
            Escalated_On__c = System.now(),
            Escalated_To__c = assignee
        );
        insert e;
        return e;
    }

    @IsTest
    static void summaryReturnsEscalations() {
        User agent = makeUser('slaag1', 'SLA_Agent');
        Escalation__c e = makeEscalation(agent.Id);
        SLAEscalationController.SlaSummary s;
        System.runAs(agent) {
            s = SLAEscalationController.getSlaSummary(e.Case__c);
        }
        System.assertEquals(1, s.escalations.size());
        System.assertEquals('On Track', s.slaStatus);
        System.assert(s.escalations[0].canAcknowledge, 'Assigned user can acknowledge');
    }

    @IsTest
    static void acknowledgeSetsFlagAndRejectsRepeat() {
        User agent = makeUser('slaag2', 'SLA_Agent');
        Escalation__c e = makeEscalation(agent.Id);
        Boolean repeatRejected = false;
        System.runAs(agent) {
            SLAEscalationController.acknowledgeEscalation(e.Id);
            try {
                SLAEscalationController.acknowledgeEscalation(e.Id);
            } catch (AuraHandledException ex) {
                repeatRejected = true;
            }
        }
        Escalation__c r = [SELECT Acknowledged__c, Acknowledged_On__c FROM Escalation__c WHERE Id = :e.Id];
        System.assert(r.Acknowledged__c);
        System.assertNotEquals(null, r.Acknowledged_On__c);
        System.assert(repeatRejected);
    }

    @IsTest
    static void acknowledgeByUnrelatedUserIsRejected() {
        User assignee = makeUser('slaag3', 'SLA_Agent');
        User other = makeUser('slaag4', 'SLA_Agent');
        Escalation__c e = makeEscalation(assignee.Id);
        String message;
        System.runAs(other) {
            try {
                SLAEscalationController.acknowledgeEscalation(e.Id);
            } catch (AuraHandledException ex) {
                message = ex.getMessage();
            }
        }
        System.assertNotEquals(null, message, 'Expected rejection');
        System.assert(message.contains('Only the assigned user'), message);
        System.assertEquals(false, [SELECT Acknowledged__c FROM Escalation__c WHERE Id = :e.Id].Acknowledged__c);
    }

    @IsTest
    static void dashboardRequiresManagerPermission() {
        User agent = makeUser('slaag5', 'SLA_Agent');
        String message;
        System.runAs(agent) {
            try {
                SLAEscalationController.getDashboardCases(null, 0);
            } catch (AuraHandledException ex) {
                message = ex.getMessage();
            }
        }
        System.assert(message != null && message.contains('SLA Manager'), 'Agents are blocked: ' + message);
    }

    @IsTest
    static void dashboardReturnsAtRiskCasesForManager() {
        User mgr = makeUser('slamg1', 'SLA_Manager');
        Case c = new Case(Subject = 'Dash', Priority = 'High', Status = 'New', Origin = 'Web');
        insert c;
        EscalationService.process(
            [SELECT Id, Priority, Status, OwnerId, SLA_Start_Date__c, SLA_Due_Date__c, SLA_Status__c, Escalation_Level__c FROM Case WHERE Id = :c.Id],
            System.now().addDays(60)
        );
        List<Case> rows;
        System.runAs(mgr) {
            rows = SLAEscalationController.getDashboardCases('High', 1);
        }
        System.assertEquals(1, rows.size());
        System.assertEquals('Breached', rows[0].SLA_Status__c);
    }
}
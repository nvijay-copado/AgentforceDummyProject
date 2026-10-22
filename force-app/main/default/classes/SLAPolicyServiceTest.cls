@IsTest
private class SLAPolicyServiceTest {
    private static SLAPolicyService.Policy policy(Decimal hours) {
        SLAPolicyService.Policy p = new SLAPolicyService.Policy();
        p.resolutionHours = hours;
        p.atRiskPct = 80;
        p.maxLevel = 3;
        return p;
    }

    @IsTest
    static void dueDateAddsResolutionAndPausedHours() {
        Datetime start = Datetime.newInstanceGmt(2026, 1, 1, 0, 0, 0);
        System.assertEquals(start.addHours(4), SLAPolicyService.calculateDueDate(start, policy(4), 0));
        System.assertEquals(start.addHours(6), SLAPolicyService.calculateDueDate(start, policy(4), 2));
        System.assertEquals(start.addHours(4), SLAPolicyService.calculateDueDate(start, policy(4), null));
    }

    @IsTest
    static void statusBoundaries() {
        Datetime start = Datetime.newInstanceGmt(2026, 1, 1, 0, 0, 0);
        Datetime due = start.addHours(10);
        System.assertEquals('On Track', SLAPolicyService.evaluateStatus(start, due, start.addHours(7), 80, false, 'On Track'));
        System.assertEquals('At Risk', SLAPolicyService.evaluateStatus(start, due, start.addHours(8), 80, false, 'On Track'), 'Exactly 80% is At Risk');
        System.assertEquals('At Risk', SLAPolicyService.evaluateStatus(start, due, due, 80, false, 'At Risk'), 'Exactly due is not yet breached');
        System.assertEquals('Breached', SLAPolicyService.evaluateStatus(start, due, due.addMinutes(1), 80, false, 'At Risk'));
    }

    @IsTest
    static void closedAndPausedStatuses() {
        Datetime start = Datetime.newInstanceGmt(2026, 1, 1, 0, 0, 0);
        Datetime due = start.addHours(10);
        System.assertEquals('Met', SLAPolicyService.evaluateStatus(start, due, start.addHours(2), 80, true, 'On Track'));
        System.assertEquals('Breached', SLAPolicyService.evaluateStatus(start, due, due.addHours(1), 80, true, 'At Risk'));
        System.assertEquals('Breached', SLAPolicyService.evaluateStatus(start, due, start.addHours(2), 80, true, 'Breached'));
        System.assertEquals('Paused', SLAPolicyService.evaluateStatus(start, due, due.addHours(5), 80, false, 'Paused'));
    }

    @IsTest
    static void unknownPriorityFallsBackToLow() {
        SLAPolicyService.Policy low = SLAPolicyService.getPolicy('Low');
        System.assertEquals(low.resolutionHours, SLAPolicyService.getPolicy('Nonexistent').resolutionHours);
        System.assertEquals(low.resolutionHours, SLAPolicyService.getPolicy(null).resolutionHours);
    }

    @IsTest
    static void emptyPolicyMapUsesDefaults() {
        SLAPolicyService.policies = new Map<String, SLAPolicyService.Policy>();
        System.assertEquals(72, SLAPolicyService.getPolicy('High').resolutionHours);
    }
}
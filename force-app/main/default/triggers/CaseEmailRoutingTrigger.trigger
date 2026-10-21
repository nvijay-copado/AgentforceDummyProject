trigger CaseEmailRoutingTrigger on Case (before insert) {
    CaseEmailClassifier.routeEmailCases(Trigger.new);
}
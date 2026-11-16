trigger SLABreachEventTrigger on SLA_Breach_Event__e(after insert) {
    SLAEscalationNotifier.notify(Trigger.new);
}
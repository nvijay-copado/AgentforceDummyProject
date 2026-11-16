trigger CaseSLATrigger on Case(before insert, before update) {
    if (Trigger.isInsert) {
        CaseSLATriggerHandler.beforeInsert(Trigger.new);
    } else {
        CaseSLATriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }
}
public virtual with sharing class TriggerHandler {
    public void run() {
        switch on Trigger.operationType {
            when BEFORE_INSERT { beforeInsert(Trigger.new); }
            when BEFORE_UPDATE { beforeUpdate(Trigger.new, Trigger.oldMap); }
            when BEFORE_DELETE { beforeDelete(Trigger.old); }
            when AFTER_INSERT { afterInsert(Trigger.new); }
            when AFTER_UPDATE { afterUpdate(Trigger.new, Trigger.oldMap); }
            when AFTER_DELETE { afterDelete(Trigger.old); }
            when AFTER_UNDELETE { afterUndelete(Trigger.new); }
        }
    }
    protected virtual void beforeInsert(List<SObject> newRecords) {}
    protected virtual void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {}
    protected virtual void beforeDelete(List<SObject> oldRecords) {}
    protected virtual void afterInsert(List<SObject> newRecords) {}
    protected virtual void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {}
    protected virtual void afterDelete(List<SObject> oldRecords) {}
    protected virtual void afterUndelete(List<SObject> newRecords) {}
}
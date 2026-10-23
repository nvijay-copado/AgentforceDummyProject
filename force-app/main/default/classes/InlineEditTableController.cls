public with sharing class InlineEditTableController {
    public class SaveResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public List<String> errors = new List<String>();
        @AuraEnabled public Map<Id, String> rowErrors = new Map<Id, String>();
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String objectApiName, List<String> fields, String parentField, Id parentId, Integer maxRows) {
        Schema.SObjectType t = Schema.getGlobalDescribe().get(objectApiName);
        if (t == null || fields == null || fields.isEmpty()) {
            throw new AuraHandledException('Invalid object or fields.');
        }
        Map<String, Schema.SObjectField> fm = t.getDescribe().fields.getMap();
        if (!t.getDescribe().isAccessible()) {
            throw new AuraHandledException('No access to ' + objectApiName);
        }
        List<String> safe = new List<String>{ 'Id' };
        for (String f : fields) {
            Schema.SObjectField sf = fm.get(f);
            if (sf == null || !sf.getDescribe().isAccessible()) {
                throw new AuraHandledException('Field not accessible: ' + f);
            }
            if (f.toLowerCase() != 'id') { safe.add(f); }
        }
        String q = 'SELECT ' + String.join(safe, ',') + ' FROM ' + objectApiName;
        if (String.isNotBlank(parentField) && parentId != null) {
            if (!fm.containsKey(parentField)) {
                throw new AuraHandledException('Invalid parent field: ' + parentField);
            }
            q += ' WHERE ' + parentField + ' = :parentId';
        }
        Integer lim = (maxRows == null || maxRows < 1 || maxRows > 200) ? 50 : maxRows;
        q += ' WITH USER_MODE LIMIT ' + lim;
        return Database.query(q);
    }

    @AuraEnabled
    public static SaveResult saveRecords(List<SObject> records) {
        SaveResult res = new SaveResult();
        res.success = true;
        if (records == null || records.isEmpty()) { return res; }
        List<Database.SaveResult> srs = Database.update(records, false, AccessLevel.USER_MODE);
        for (Integer i = 0; i < srs.size(); i++) {
            if (!srs[i].isSuccess()) {
                res.success = false;
                String msg = srs[i].getErrors()[0].getMessage();
                res.rowErrors.put(records[i].Id, msg);
                res.errors.add(msg);
            }
        }
        return res;
    }
}
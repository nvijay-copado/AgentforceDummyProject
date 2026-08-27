global class test7march {
    
    

    global static void addRecords() {
        SObject test1 = new test7March__c();
        test7March__c test2 = new test7March__c();
        execute123(new List<test7March__c>{test2});
        execute(new List<SObject>{test1});
        insert test1;

    }

    public static void execute123(List<test7March__c> records) {
        System.debug('WITH CUSTOM OBJ');
        System.debug(records.get(0).getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getName());
        System.debug(records.get(0).getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getLocalName());
    }

    public static void execute(List<SObject> records) {
        System.debug('WITH S Records');
        System.debug(records.get(0).getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getName());
        System.debug(records.get(0).getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getLocalName());
    }


}
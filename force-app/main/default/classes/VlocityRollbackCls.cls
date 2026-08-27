public class VlocityRollbackCls {
     
    public static void execute() {
        Account ac = [Select name from Account LIMIT 1][0];
        ac.Active__c = 'false';
        
        System.debug('final UI test');
        
        update ac;
    }

}
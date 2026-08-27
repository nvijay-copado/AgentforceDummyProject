public class SFDXCategoryApex {
    
    public static void execute() {
        System.debug('Deploying this class with Vlocity enabled 1');
        Account a = [Select id, name from Account limit 1];
        
        a.name = 'newAcc1';
        update a;
    }

}
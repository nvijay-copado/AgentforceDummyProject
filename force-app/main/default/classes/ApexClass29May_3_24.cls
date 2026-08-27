public class ApexClass29May_3_24 {
	 public static void execute() {
        System.debug('Deploying this class with Vlocity enabled');
        Account a = [Select id, name from Account limit 1];
        
        a.name = 'newAcc1';
        update a;
    }
}
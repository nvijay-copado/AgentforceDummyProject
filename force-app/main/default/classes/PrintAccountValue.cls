Public Class PrintAccountValue{
    public static void printValue(){
        Account myAccount = [Select Id, Name, New_Test_Field_1__c From Account LIMIT 1];
        System.debug(myAccount.New_Test_Field_1__c);
    }
       
}
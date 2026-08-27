@IsTest(seeAllData=false)
private class Service2Test {
    @IsTest
    public static void testActiveMethod(){
        Account testAccount = dsjhfTest.createTestAccount('Test Account');
        Service2 test1Hello = new Service2();
    }
}
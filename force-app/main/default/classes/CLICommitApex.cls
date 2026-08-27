public with sharing class CLICommitApex {
  public static void execute() {
    Account a = [SELECT id, name FROM Account LIMIT 1];
    a.name = 'ds';

    update a;
  }
}
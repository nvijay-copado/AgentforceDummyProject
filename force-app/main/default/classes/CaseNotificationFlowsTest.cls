@IsTest
private class CaseNotificationFlowsTest {
    @IsTest
    static void flowsRunForOptedInAndOptedOutContacts() {
        Contact optedIn = new Contact(LastName = 'In', Email = 'in@example.com', Case_Email_Opt_Out__c = false);
        Contact optedOut = new Contact(LastName = 'Out', Email = 'out@example.com', Case_Email_Opt_Out__c = true);
        insert new List<Contact>{ optedIn, optedOut };

        Case c1 = new Case(Subject = 'Opted in', Status = 'New', ContactId = optedIn.Id);
        Case c2 = new Case(Subject = 'Opted out', Status = 'New', ContactId = optedOut.Id);
        insert new List<Case>{ c1, c2 };

        insert new List<CaseComment>{
            new CaseComment(ParentId = c1.Id, CommentBody = 'Public', IsPublished = true),
            new CaseComment(ParentId = c2.Id, CommentBody = 'Public', IsPublished = true)
        };

        c1.Status = 'Working';
        c2.Status = 'Working';
        update new List<Case>{ c1, c2 };

        System.assertEquals(2, [SELECT COUNT() FROM Case WHERE Status = 'Working']);
        System.assertEquals(2, [SELECT COUNT() FROM CaseComment WHERE IsPublished = true]);
    }
}
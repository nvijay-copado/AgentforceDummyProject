@isTest
private class ITTicketControllerTest {
    @isTest // Naman Test
    static void createTicket_createsRecordAndReturnsTicketId() {
        ITTicketController.TicketRequest request = buildValidRequest();

        Test.startTest();
        ITTicketController.TicketResponse response = ITTicketController.createTicket(
            request
        );
        Test.stopTest();

        Assert.isTrue(response.success, 'Ticket creation should succeed');
        Assert.isNotNull(response.ticketId, 'Ticket Id should be returned');
        Assert.isNotNull(response.ticketName, 'Ticket name should be returned');
        Assert.isNotNull(response.slaDueDate, 'SLA due date should be returned');
        Assert.isTrue(response.slaHours > 0, 'SLA hours should be returned');

        IT_Ticket__c ticket = [
            SELECT Name, Subject__c, Priority__c, Contact_Email__c, SLA_Due_Date__c
            FROM IT_Ticket__c
            WHERE Id = :response.ticketId
        ];
        Assert.areEqual('VPN not connecting', ticket.Subject__c);
        Assert.areEqual('Medium', ticket.Priority__c);
        Assert.areEqual('employee@example.com', ticket.Contact_Email__c);
        Assert.isNotNull(ticket.SLA_Due_Date__c);
    }

    @isTest
    static void createTicket_missingSubject_returnsError() {
        ITTicketController.TicketRequest request = buildValidRequest();
        request.subject = '';

        ITTicketController.TicketResponse response = ITTicketController.createTicket(
            request
        );

        Assert.isFalse(response.success);
        Assert.areEqual('Subject is required.', response.errorMessage);
    }

    @isTest
    static void createTicket_withAttachment_linksFileToTicket() {
        ContentVersion version = new ContentVersion(
            Title = 'Screenshot',
            PathOnClient = 'screenshot.png',
            VersionData = Blob.valueOf('test-file-content')
        );
        insert version;

        ContentVersion latestVersion = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :version.Id
        ];

        ITTicketController.TicketRequest request = buildValidRequest();
        request.contentDocumentIds = new List<String>{
            latestVersion.ContentDocumentId
        };

        ITTicketController.TicketResponse response = ITTicketController.createTicket(
            request
        );

        Assert.isTrue(response.success, 'Ticket with attachment should succeed');

        Integer linkCount = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :response.ticketId
        ];
        Assert.areEqual(1, linkCount, 'Attachment should be linked to the ticket');
    }

    @isTest
    static void resolveSlaHours_returnsPositiveValue() {
        Integer slaHours = ITTicketController.resolveSlaHours('Network', 'Medium');

        Assert.isTrue(slaHours > 0, 'SLA hours should be resolved');
    }

    @isTest
    static void validateRequest_blankCategory_returnsError() {
        ITTicketController.TicketRequest request = buildValidRequest();
        request.category = '';

        String errorMessage = ITTicketController.validateRequest(request);

        Assert.areEqual('Issue Category is required.', errorMessage);
    }

    @isTest
    static void validateRequest_nullRequest_returnsError() {
        String errorMessage = ITTicketController.validateRequest(null);

        Assert.areEqual('Ticket details are required.', errorMessage);
    }

    @isTest
    static void stripHtml_removesMarkup() {
        String plainText = ITTicketController.stripHtml('<p>Hello <strong>world</strong></p>');

        Assert.areEqual('Hello world', plainText);
    }

    private static ITTicketController.TicketRequest buildValidRequest() {
        ITTicketController.TicketRequest request = new ITTicketController.TicketRequest();
        request.category = 'Network';
        request.subCategory = 'VPN';
        request.subject = 'VPN not connecting';
        request.description = '<p>Unable to connect to VPN from home.</p>';
        request.priority = 'Medium';
        request.affectedSystem = 'Corporate VPN';
        request.urgency = 'Normal';
        request.employeeName = 'Test Employee';
        request.department = 'Engineering';
        request.contactEmail = 'employee@example.com';
        request.contentDocumentIds = new List<String>();
        return request;
    }
}
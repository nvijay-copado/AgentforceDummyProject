public with sharing class ITTicketController {
    private static final Integer DEFAULT_SLA_HOURS = 24;
    private static final Integer MAX_ATTACHMENT_BYTES = 10485760;
    private static final String EMAIL_TEMPLATE_DEVELOPER_NAME = 'IT_Ticket_Confirmation';

    public class TicketRequest {
        @AuraEnabled
        public String category { get; set; }
        @AuraEnabled
        public String subCategory { get; set; }
        @AuraEnabled
        public String subject { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String priority { get; set; }
        @AuraEnabled
        public String affectedSystem { get; set; }
        @AuraEnabled
        public String urgency { get; set; }
        @AuraEnabled
        public String employeeName { get; set; }
        @AuraEnabled
        public String department { get; set; }
        @AuraEnabled
        public String contactEmail { get; set; }
        @AuraEnabled
        public List<String> contentDocumentIds { get; set; }
    }

    public class TicketResponse {
        @AuraEnabled
        public String ticketId { get; set; }
        @AuraEnabled
        public String ticketName { get; set; }
        @AuraEnabled
        public Datetime slaDueDate { get; set; }
        @AuraEnabled
        public Integer slaHours { get; set; }
        @AuraEnabled
        public Boolean success { get; set; }
        @AuraEnabled
        public String errorMessage { get; set; }
    }

    @AuraEnabled
    public static TicketResponse createTicket(TicketRequest request) {
        TicketResponse response = new TicketResponse();
        response.success = false;

        try {
            String validationError = validateRequest(request);
            if (validationError != null) {
                response.errorMessage = validationError;
                return response;
            }

            String attachmentError = validateAttachments(request.contentDocumentIds);
            if (attachmentError != null) {
                response.errorMessage = attachmentError;
                return response;
            }

            Integer slaHours = resolveSlaHours(request.category, request.priority);
            Datetime slaDueDate = System.now().addHours(slaHours);

            IT_Ticket__c ticket = new IT_Ticket__c(
                Status__c = 'New',
                Category__c = request.category,
                Sub_Category__c = request.subCategory,
                Subject__c = request.subject.trim(),
                Description__c = request.description,
                Priority__c = request.priority,
                Affected_System__c = request.affectedSystem,
                Urgency__c = request.urgency,
                Employee_Name__c = request.employeeName,
                Department__c = request.department,
                Contact_Email__c = request.contactEmail,
                Submitted_By__c = UserInfo.getUserId(),
                SLA_Due_Date__c = slaDueDate
            );
            insert ticket;

            IT_Ticket__c createdTicket = [
                SELECT
                    Id,
                    Name,
                    Subject__c,
                    Priority__c,
                    Category__c,
                    Contact_Email__c,
                    Employee_Name__c,
                    SLA_Due_Date__c
                FROM IT_Ticket__c
                WHERE Id = :ticket.Id
                LIMIT 1
            ];

            linkAttachments(createdTicket.Id, request.contentDocumentIds);
            sendConfirmationEmail(createdTicket, slaHours);

            response.ticketId = createdTicket.Id;
            response.ticketName = createdTicket.Name;
            response.slaDueDate = slaDueDate;
            response.slaHours = slaHours;
            response.success = true;
        } catch (AuraHandledException ex) {
            response.errorMessage = ex.getMessage();
        } catch (Exception ex) {
            response.errorMessage = 'Unable to submit your ticket. Please try again or contact IT support.';
        }

        return response;
    }

    @TestVisible
    private static String validateRequest(TicketRequest request) {
        if (request == null) {
            return 'Ticket details are required.';
        }
        if (String.isBlank(request.category)) {
            return 'Issue Category is required.';
        }
        if (String.isBlank(request.subCategory)) {
            return 'Sub-category is required.';
        }
        if (String.isBlank(request.subject)) {
            return 'Subject is required.';
        }
        if (String.isBlank(stripHtml(request.description))) {
            return 'Description is required.';
        }
        if (String.isBlank(request.priority)) {
            return 'Priority is required.';
        }
        if (String.isBlank(request.urgency)) {
            return 'Urgency is required.';
        }
        if (String.isBlank(request.contactEmail)) {
            return 'Contact email is required.';
        }
        return null;
    }

    @TestVisible
    private static String validateAttachments(List<String> contentDocumentIds) {
        if (contentDocumentIds == null || contentDocumentIds.isEmpty()) {
            return null;
        }

        Set<Id> documentIds = new Set<Id>();
        for (String documentId : contentDocumentIds) {
            if (String.isNotBlank(documentId)) {
                documentIds.add((Id) documentId);
            }
        }

        if (documentIds.isEmpty()) {
            return null;
        }

        for (ContentVersion version : [
            SELECT ContentSize
            FROM ContentVersion
            WHERE ContentDocumentId IN :documentIds AND IsLatest = TRUE
        ]) {
            if (version.ContentSize > MAX_ATTACHMENT_BYTES) {
                return 'Each attachment must be 10MB or smaller.';
            }
        }

        return null;
    }

    @TestVisible
    private static Integer resolveSlaHours(String category, String priority) {
        List<IT_SLA_Config__mdt> configs = [
            SELECT SLA_Hours__c
            FROM IT_SLA_Config__mdt
            WHERE Category__c = :category AND Priority__c = :priority
            LIMIT 1
        ];

        if (!configs.isEmpty() && configs[0].SLA_Hours__c != null) {
            return Integer.valueOf(configs[0].SLA_Hours__c);
        }

        List<IT_SLA_Config__mdt> defaultConfigs = [
            SELECT SLA_Hours__c
            FROM IT_SLA_Config__mdt
            WHERE Category__c = 'Other' AND Priority__c = :priority
            LIMIT 1
        ];

        if (!defaultConfigs.isEmpty() && defaultConfigs[0].SLA_Hours__c != null) {
            return Integer.valueOf(defaultConfigs[0].SLA_Hours__c);
        }

        return DEFAULT_SLA_HOURS;
    }

    @TestVisible
    private static void linkAttachments(Id ticketId, List<String> contentDocumentIds) {
        if (contentDocumentIds == null || contentDocumentIds.isEmpty()) {
            return;
        }

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (String documentId : contentDocumentIds) {
            if (String.isNotBlank(documentId)) {
                links.add(
                    new ContentDocumentLink(
                        ContentDocumentId = (Id) documentId,
                        LinkedEntityId = ticketId,
                        ShareType = 'V',
                        Visibility = 'AllUsers'
                    )
                );
            }
        }

        if (!links.isEmpty()) {
            insert links;
        }
    }

    @TestVisible
    private static void sendConfirmationEmail(IT_Ticket__c ticket, Integer slaHours) {
        if (String.isBlank(ticket.Contact_Email__c)) {
            return;
        }

        try {
            List<EmailTemplate> templates = [
                SELECT Id
                FROM EmailTemplate
                WHERE DeveloperName = :EMAIL_TEMPLATE_DEVELOPER_NAME
                LIMIT 1
            ];

            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setTargetObjectId(UserInfo.getUserId());
            message.setTreatTargetObjectAsRecipient(false);
            message.setToAddresses(new List<String>{ ticket.Contact_Email__c });
            message.setSaveAsActivity(false);

            if (!templates.isEmpty()) {
                message.setTemplateId(templates[0].Id);
                message.setWhatId(ticket.Id);
            } else {
                message.setSubject('IT Ticket Confirmation: ' + ticket.Name);
                message.setPlainTextBody(
                    'Your IT request ' +
                        ticket.Name +
                        ' has been submitted.\n\nSubject: ' +
                        ticket.Subject__c +
                        '\nPriority: ' +
                        ticket.Priority__c +
                        '\nExpected response within ' +
                        slaHours +
                        ' hours.\n\nThank you,\nIT Help Desk'
                );
            }

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Unable to send IT ticket confirmation email: ' + ex.getMessage());
        }
    }

    @TestVisible
    private static String stripHtml(String value) {
        if (String.isBlank(value)) {
            return value;
        }
        return value.replaceAll('<[^>]+>', '').trim();
    }
}

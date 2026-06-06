trigger ITTicketTrigger on IT_Ticket__c (after insert) {
    ITTicketAssignmentHandler.handleAfterInsert(Trigger.new);
}

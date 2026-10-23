trigger OpportunityTrigger on Opportunity (before update, after insert, after update) {
    if (Trigger.isBefore) {
        OpportunityCreditValidationHandler.handleBeforeUpdate(
            Trigger.new,
            Trigger.oldMap
        );
    } else {
        new QuoteApprovalTriggerHandler().run();
    }
}
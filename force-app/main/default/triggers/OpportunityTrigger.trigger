trigger OpportunityTrigger on Opportunity (before update) {
    OpportunityCreditValidationHandler.handleBeforeUpdate(
        Trigger.new,
        Trigger.oldMap
    );
}
/**
 * Service class supporting the customer Follow-Up tracking feature (US-0012479).
 * Provides bulkified query and update operations used by UI components and
 * automation to list, complete, and surface overdue/team follow-ups.
 */
public with sharing class FollowUpService {

    /**
     * Returns the open and completed follow-ups owned by the running user,
     * ordered by due date.
     */
    public static List<Follow_Up__c> getMyFollowUps() {
        return [
            SELECT Id, Name, Subject__c, Due_Date__c, Priority__c, Status__c,
                   Is_Overdue__c, Account__c, Contact__c, Opportunity__c, OwnerId
            FROM Follow_Up__c
            WHERE OwnerId = :UserInfo.getUserId()
            ORDER BY Due_Date__c ASC NULLS LAST
        ];
    }

    /**
     * Returns the follow-ups owned by the direct reports of the given manager
     * (defaults to the running user), satisfying AC5 (manager visibility).
     * Relies on Apex "with sharing" so row-level access still applies.
     */
    public static List<Follow_Up__c> getTeamFollowUps(Id managerId) {
        Id effectiveManagerId = (managerId != null) ? managerId : UserInfo.getUserId();

        Set<Id> teamUserIds = new Set<Id>();
        for (User teamMember : [
            SELECT Id
            FROM User
            WHERE ManagerId = :effectiveManagerId
        ]) {
            teamUserIds.add(teamMember.Id);
        }

        if (teamUserIds.isEmpty()) {
            return new List<Follow_Up__c>();
        }

        return [
            SELECT Id, Name, Subject__c, Due_Date__c, Priority__c, Status__c,
                   Is_Overdue__c, Account__c, Contact__c, Opportunity__c, OwnerId
            FROM Follow_Up__c
            WHERE OwnerId IN :teamUserIds
            ORDER BY Due_Date__c ASC NULLS LAST
        ];
    }

    /**
     * Returns every follow-up currently flagged as overdue that the running
     * user can see (AC4).
     */
    public static List<Follow_Up__c> getOverdueFollowUps() {
        return [
            SELECT Id, Name, Subject__c, Due_Date__c, Priority__c, Status__c, OwnerId
            FROM Follow_Up__c
            WHERE Is_Overdue__c = true
            ORDER BY Due_Date__c ASC NULLS LAST
        ];
    }

    /**
     * Bulk-marks the given follow-up Ids as Completed (AC3). Bulkified:
     * a single SOQL query and a single DML statement regardless of list size.
     */
    public static List<Follow_Up__c> completeFollowUps(List<Id> followUpIds) {
        if (followUpIds == null || followUpIds.isEmpty()) {
            return new List<Follow_Up__c>();
        }

        List<Follow_Up__c> followUpsToUpdate = [
            SELECT Id, Status__c
            FROM Follow_Up__c
            WHERE Id IN :followUpIds
        ];

        for (Follow_Up__c followUp : followUpsToUpdate) {
            followUp.Status__c = 'Completed';
        }

        if (!followUpsToUpdate.isEmpty()) {
            update followUpsToUpdate;
        }

        return followUpsToUpdate;
    }
}
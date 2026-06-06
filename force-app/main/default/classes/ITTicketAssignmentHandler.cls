public with sharing class ITTicketAssignmentHandler {
  private static final String DEFAULT_QUEUE_DEVELOPER_NAME = 'General_IT';
  private static final String EMAIL_TEMPLATE_DEVELOPER_NAME = 'IT_Ticket_Agent_Assignment';
  private static final String NOTIFICATION_TYPE_DEVELOPER_NAME = 'IT_Ticket_Assignment';

  @TestVisible
  private static String defaultQueueDeveloperNameOverride;

  public static void handleAfterInsert(List<IT_Ticket__c> newTickets) {
    if (newTickets == null || newTickets.isEmpty()) {
      return;
    }

    Map<String, String> categoryToQueueRef = loadCategoryRouting();
    Id defaultQueueId = resolveQueueId(
      defaultQueueDeveloperNameOverride != null
        ? defaultQueueDeveloperNameOverride
        : DEFAULT_QUEUE_DEVELOPER_NAME
    );

    Set<String> queueRefs = new Set<String>();
    if (defaultQueueId == null) {
      queueRefs.add(
        defaultQueueDeveloperNameOverride != null
          ? defaultQueueDeveloperNameOverride
          : DEFAULT_QUEUE_DEVELOPER_NAME
      );
    }
    for (IT_Ticket__c ticket : newTickets) {
      String queueRef = categoryToQueueRef.get(ticket.Category__c);
      if (String.isNotBlank(queueRef)) {
        queueRefs.add(queueRef);
      }
    }

    Map<String, Id> queueIdsByRef = resolveQueueIds(queueRefs);
    if (defaultQueueId == null) {
      defaultQueueId = queueIdsByRef.get(
        defaultQueueDeveloperNameOverride != null
          ? defaultQueueDeveloperNameOverride
          : DEFAULT_QUEUE_DEVELOPER_NAME
      );
    }

    List<IT_Ticket__c> ticketsToUpdate = new List<IT_Ticket__c>();
    Map<Id, Id> ticketToQueueId = new Map<Id, Id>();

    for (IT_Ticket__c ticket : newTickets) {
      String queueRef = categoryToQueueRef.get(ticket.Category__c);
      Id queueId = queueRef != null ? queueIdsByRef.get(queueRef) : null;
      if (queueId == null) {
        queueId = defaultQueueId;
      }
      if (queueId == null) {
        continue;
      }

      ticketsToUpdate.add(new IT_Ticket__c(Id = ticket.Id, OwnerId = queueId));
      ticketToQueueId.put(ticket.Id, queueId);
    }

    if (ticketsToUpdate.isEmpty()) {
      return;
    }

    update ticketsToUpdate;
    notifyQueueMembers(newTickets, ticketToQueueId);
  }

  @TestVisible
  private static Map<String, String> loadCategoryRouting() {
    Map<String, String> categoryToQueueRef = new Map<String, String>();
    for (IT_Category_Routing__mdt routing : [
      SELECT Category__c, Assigned_Queue_Id__c
      FROM IT_Category_Routing__mdt
    ]) {
      if (
        String.isNotBlank(routing.Category__c) &&
        String.isNotBlank(routing.Assigned_Queue_Id__c)
      ) {
        categoryToQueueRef.put(
          routing.Category__c,
          routing.Assigned_Queue_Id__c.trim()
        );
      }
    }
    return categoryToQueueRef;
  }

  @TestVisible
  private static Id resolveQueueId(String queueRef) {
    if (String.isBlank(queueRef)) {
      return null;
    }
    return resolveQueueIds(new Set<String>{ queueRef }).get(queueRef.trim());
  }

  @TestVisible
  private static Map<String, Id> resolveQueueIds(Set<String> queueRefs) {
    Map<String, Id> queueIdsByRef = new Map<String, Id>();
    if (queueRefs == null || queueRefs.isEmpty()) {
      return queueIdsByRef;
    }

    Set<String> developerNames = new Set<String>();
    Set<Id> queueIds = new Set<Id>();

    for (String queueRef : queueRefs) {
      if (String.isBlank(queueRef)) {
        continue;
      }
      String trimmedRef = queueRef.trim();
      if (isSalesforceId(trimmedRef)) {
        queueIds.add((Id) trimmedRef);
        queueIdsByRef.put(trimmedRef, (Id) trimmedRef);
      } else {
        developerNames.add(trimmedRef);
      }
    }

    if (developerNames.isEmpty() && queueIds.isEmpty()) {
      return queueIdsByRef;
    }

    List<Group> queues = [
      SELECT Id, DeveloperName
      FROM Group
      WHERE
        Type = 'Queue'
        AND (DeveloperName IN :developerNames
        OR Id IN :queueIds)
    ];

    for (Group queue : queues) {
      queueIdsByRef.put(queue.DeveloperName, queue.Id);
      queueIdsByRef.put(String.valueOf(queue.Id), queue.Id);
    }

    return queueIdsByRef;
  }

  @TestVisible
  private static Boolean isSalesforceId(String value) {
    return (value.length() == 15 || value.length() == 18) &&
      Pattern.matches('^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$', value);
  }

  @TestVisible
  private static void notifyQueueMembers(
    List<IT_Ticket__c> sourceTickets,
    Map<Id, Id> ticketToQueueId
  ) {
    if (sourceTickets.isEmpty() || ticketToQueueId.isEmpty()) {
      return;
    }

    Map<Id, IT_Ticket__c> ticketsById = new Map<Id, IT_Ticket__c>(
      [
        SELECT
          Id,
          Name,
          Subject__c,
          Priority__c,
          Category__c,
          Description__c,
          SLA_Due_Date__c
        FROM IT_Ticket__c
        WHERE Id IN :ticketToQueueId.keySet()
      ]
    );

    Set<Id> queueIds = new Set<Id>(ticketToQueueId.values());
    Map<Id, List<Id>> queueToMemberUserIds = loadQueueMemberUserIds(queueIds);
    EmailTemplate agentTemplate = findAgentEmailTemplate();
    CustomNotificationType notificationType = findNotificationType();

    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    for (Id ticketId : ticketToQueueId.keySet()) {
      IT_Ticket__c ticket = ticketsById.get(ticketId);
      Id queueId = ticketToQueueId.get(ticketId);
      List<Id> memberUserIds = queueToMemberUserIds.get(queueId);
      if (ticket == null || memberUserIds == null || memberUserIds.isEmpty()) {
        continue;
      }

      emails.addAll(buildAgentEmails(ticket, memberUserIds, agentTemplate));
      sendCustomNotification(ticket, memberUserIds, notificationType);
    }

    if (!emails.isEmpty()) {
      try {
        Messaging.sendEmail(emails);
      } catch (Exception ex) {
        System.debug(
          LoggingLevel.WARN,
          'Unable to send IT ticket assignment emails: ' + ex.getMessage()
        );
      }
    }
  }

  @TestVisible
  private static void sendCustomNotification(
    IT_Ticket__c ticket,
    List<Id> memberUserIds,
    CustomNotificationType notificationType
  ) {
    Messaging.CustomNotification notification = buildCustomNotification(
      ticket,
      notificationType
    );
    if (notification == null) {
      return;
    }

    Set<String> recipientIds = new Set<String>();
    for (Id memberUserId : memberUserIds) {
      recipientIds.add(String.valueOf(memberUserId));
    }

    try {
      notification.send(recipientIds);
    } catch (Exception ex) {
      System.debug(
        LoggingLevel.WARN,
        'Unable to send IT ticket assignment notification: ' + ex.getMessage()
      );
    }
  }

  @TestVisible
  private static Map<Id, List<Id>> loadQueueMemberUserIds(Set<Id> queueIds) {
    Map<Id, List<Id>> queueToMemberUserIds = new Map<Id, List<Id>>();
    for (GroupMember member : [
      SELECT GroupId, UserOrGroupId
      FROM GroupMember
      WHERE GroupId IN :queueIds AND UserOrGroupId IN (SELECT Id FROM User)
    ]) {
      if (!queueToMemberUserIds.containsKey(member.GroupId)) {
        queueToMemberUserIds.put(member.GroupId, new List<Id>());
      }
      queueToMemberUserIds.get(member.GroupId).add(member.UserOrGroupId);
    }
    return queueToMemberUserIds;
  }

  @TestVisible
  private static List<Messaging.SingleEmailMessage> buildAgentEmails(
    IT_Ticket__c ticket,
    List<Id> memberUserIds,
    EmailTemplate agentTemplate
  ) {
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    Map<Id, User> membersById = new Map<Id, User>(
      [
        SELECT Id, Email
        FROM User
        WHERE Id IN :memberUserIds AND IsActive = TRUE
      ]
    );

    for (Id memberUserId : memberUserIds) {
      User member = membersById.get(memberUserId);
      if (member == null || String.isBlank(member.Email)) {
        continue;
      }

      Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
      message.setTargetObjectId(member.Id);
      message.setTreatTargetObjectAsRecipient(false);
      message.setToAddresses(new List<String>{ member.Email });
      message.setSaveAsActivity(false);

      if (agentTemplate != null) {
        message.setTemplateId(agentTemplate.Id);
        message.setWhatId(ticket.Id);
      } else {
        message.setSubject('New IT Ticket Assigned: ' + ticket.Name);
        message.setPlainTextBody(
          'A new IT ticket has been assigned to your queue.\n\n' +
            'Ticket: ' +
            ticket.Name +
            '\nSubject: ' +
            ticket.Subject__c +
            '\nCategory: ' +
            ticket.Category__c +
            '\nPriority: ' +
            ticket.Priority__c +
            '\n\nPlease review the ticket in Salesforce.'
        );
      }

      emails.add(message);
    }

    return emails;
  }

  @TestVisible
  private static Messaging.CustomNotification buildCustomNotification(
    IT_Ticket__c ticket,
    CustomNotificationType notificationType
  ) {
    if (notificationType == null) {
      return null;
    }

    Messaging.CustomNotification notification = new Messaging.CustomNotification();
    notification.setTitle('New IT Ticket Assigned');
    notification.setBody(
      ticket.Name +
        ': ' +
        ticket.Subject__c +
        ' (' +
        ticket.Category__c +
        ')'
    );
    notification.setNotificationTypeId(notificationType.Id);
    notification.setTargetId(ticket.Id);
    notification.setSenderId(UserInfo.getUserId());
    return notification;
  }

  @TestVisible
  private static EmailTemplate findAgentEmailTemplate() {
    List<EmailTemplate> templates = [
      SELECT Id
      FROM EmailTemplate
      WHERE DeveloperName = :EMAIL_TEMPLATE_DEVELOPER_NAME
      LIMIT 1
    ];
    return templates.isEmpty() ? null : templates[0];
  }

  @TestVisible
  private static CustomNotificationType findNotificationType() {
    List<CustomNotificationType> notificationTypes = [
      SELECT Id
      FROM CustomNotificationType
      WHERE DeveloperName = :NOTIFICATION_TYPE_DEVELOPER_NAME
      LIMIT 1
    ];
    return notificationTypes.isEmpty() ? null : notificationTypes[0];
  }
}

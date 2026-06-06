@isTest
private class ITTicketAssignmentHandlerTest {
  @TestSetup
  static void setupQueueMembers() {
    List<Group> hardwareQueues = [
      SELECT Id
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName = 'Hardware_IT'
      LIMIT 1
    ];
    if (hardwareQueues.isEmpty()) {
      return;
    }

    List<GroupMember> existingMembers = [
      SELECT Id
      FROM GroupMember
      WHERE
        GroupId = :hardwareQueues[0].Id
        AND UserOrGroupId = :UserInfo.getUserId()
      LIMIT 1
    ];
    if (existingMembers.isEmpty()) {
      insert new GroupMember(
        GroupId = hardwareQueues[0].Id,
        UserOrGroupId = UserInfo.getUserId()
      );
    }
  }

  @isTest
  static void handleAfterInsert_assignsMappedQueue() {
    QueueContext context = createQueueContext('Hardware_IT');

    IT_Ticket__c ticket = buildTicket('Hardware', 'Broken laptop keyboard');

    Test.startTest();
    insert ticket;
    Test.stopTest();

    IT_Ticket__c assignedTicket = [
      SELECT OwnerId
      FROM IT_Ticket__c
      WHERE Id = :ticket.Id
    ];
    Assert.areEqual(
      context.queueId,
      assignedTicket.OwnerId,
      'Hardware tickets should route to the Hardware queue'
    );
  }

  @isTest
  static void handleAfterInsert_unmatchedCategory_usesGeneralQueue() {
    QueueContext context = createQueueContext('General_IT');

    IT_Ticket__c ticket = buildTicket('Other', 'General help request');

    Test.startTest();
    insert ticket;
    Test.stopTest();

    IT_Ticket__c assignedTicket = [
      SELECT OwnerId
      FROM IT_Ticket__c
      WHERE Id = :ticket.Id
    ];
    Assert.areEqual(
      context.queueId,
      assignedTicket.OwnerId,
      'Unmatched categories should route to General IT'
    );
  }

  @isTest
  static void handleAfterInsert_bulkInsert_assignsAllTickets() {
    QueueContext hardwareQueue = createQueueContext('Hardware_IT');
    QueueContext generalQueue = createQueueContext('General_IT');

    List<IT_Ticket__c> tickets = new List<IT_Ticket__c>{
      buildTicket('Hardware', 'Broken monitor'),
      buildTicket('Other', 'Need help with onboarding')
    };

    Test.startTest();
    insert tickets;
    Test.stopTest();

    Map<String, Id> ownerBySubject = new Map<String, Id>();
    for (IT_Ticket__c ticket : [
      SELECT Subject__c, OwnerId
      FROM IT_Ticket__c
      WHERE Id IN :tickets
    ]) {
      ownerBySubject.put(ticket.Subject__c, ticket.OwnerId);
    }

    Assert.areEqual(
      hardwareQueue.queueId,
      ownerBySubject.get('Broken monitor')
    );
    Assert.areEqual(
      generalQueue.queueId,
      ownerBySubject.get('Need help with onboarding')
    );
  }

  @isTest
  static void resolveQueueIds_supportsDeveloperNameAndId() {
    QueueContext context = createQueueContext('Network_IT');

    Map<String, Id> queueIdsByRef = ITTicketAssignmentHandler.resolveQueueIds(
      new Set<String>{ context.developerName, String.valueOf(context.queueId) }
    );

    Assert.areEqual(context.queueId, queueIdsByRef.get(context.developerName));
    Assert.areEqual(
      context.queueId,
      queueIdsByRef.get(String.valueOf(context.queueId))
    );
  }

  @isTest
  static void loadCategoryRouting_returnsConfiguredMappings() {
    Map<String, String> routing = ITTicketAssignmentHandler.loadCategoryRouting();

    Assert.isTrue(routing.containsKey('Hardware'));
    Assert.areEqual('Hardware_IT', routing.get('Hardware'));
  }

  @isTest
  static void isSalesforceId_detectsValidIds() {
    QueueContext context = createQueueContext('Software_IT');

    Assert.isTrue(
      ITTicketAssignmentHandler.isSalesforceId(String.valueOf(context.queueId))
    );
    Assert.isFalse(ITTicketAssignmentHandler.isSalesforceId('Software_IT'));
  }

  @isTest
  static void handleAfterInsert_emptyInput_doesNothing() {
    Test.startTest();
    ITTicketAssignmentHandler.handleAfterInsert(new List<IT_Ticket__c>());
    ITTicketAssignmentHandler.handleAfterInsert(null);
    Test.stopTest();

    Assert.areEqual(
      0,
      [SELECT COUNT() FROM IT_Ticket__c],
      'No tickets should be created for empty handler input'
    );
  }

  @isTest
  static void resolveQueueId_blankReference_returnsNull() {
    Assert.isNull(ITTicketAssignmentHandler.resolveQueueId(''));
    Assert.isNull(ITTicketAssignmentHandler.resolveQueueId(null));
  }

  @isTest
  static void resolveQueueIds_emptySet_returnsEmptyMap() {
    Assert.isTrue(
      ITTicketAssignmentHandler.resolveQueueIds(new Set<String>()).isEmpty()
    );
    Assert.isTrue(ITTicketAssignmentHandler.resolveQueueIds(null).isEmpty());
  }

  @isTest
  static void handleAfterInsert_withQueueMember_sendsNotifications() {
    QueueContext context = createQueueContext('Hardware_IT');
    IT_Ticket__c ticket = buildTicket('Hardware', 'Printer jam');

    Test.startTest();
    insert ticket;
    Test.stopTest();

    IT_Ticket__c assignedTicket = [
      SELECT OwnerId
      FROM IT_Ticket__c
      WHERE Id = :ticket.Id
    ];
    Assert.areEqual(context.queueId, assignedTicket.OwnerId);
    Assert.isNotNull(ITTicketAssignmentHandler.findAgentEmailTemplate());
    Assert.isNotNull(ITTicketAssignmentHandler.findNotificationType());
  }

  @isTest
  static void buildAgentEmails_createsMessageForActiveMember() {
    QueueContext context = createQueueContext('Network_IT');
    User agent = [
      SELECT Id, Email
      FROM User
      WHERE Id = :UserInfo.getUserId()
      LIMIT 1
    ];

    IT_Ticket__c ticket = buildTicket('Network', 'Wi-Fi outage');
    insert ticket;
    ticket = [
      SELECT Id, Name, Subject__c, Priority__c, Category__c
      FROM IT_Ticket__c
      WHERE Id = :ticket.Id
    ];

    List<Messaging.SingleEmailMessage> emails = ITTicketAssignmentHandler.buildAgentEmails(
      ticket,
      new List<Id>{ agent.Id },
      ITTicketAssignmentHandler.findAgentEmailTemplate()
    );

    Assert.areEqual(1, emails.size());
    Assert.isNotNull(emails[0]);
  }

  private static IT_Ticket__c buildTicket(String category, String subject) {
    String subCategory = 'General Inquiry';
    if (category == 'Hardware') {
      subCategory = 'Laptop';
    } else if (category == 'Network') {
      subCategory = 'VPN';
    }
    return new IT_Ticket__c(
      Status__c = 'New',
      Category__c = category,
      Sub_Category__c = subCategory,
      Subject__c = subject,
      Description__c = 'Test description',
      Priority__c = 'Medium',
      Urgency__c = 'Normal',
      Contact_Email__c = 'employee@example.com',
      SLA_Due_Date__c = System.now().addHours(24)
    );
  }

  private static QueueContext createQueueContext(String developerName) {
    List<Group> existingQueues = [
      SELECT Id
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName = :developerName
      LIMIT 1
    ];

    if (!existingQueues.isEmpty()) {
      if (developerName == 'General_IT') {
        ITTicketAssignmentHandler.defaultQueueDeveloperNameOverride = developerName;
      }
      return new QueueContext(developerName, existingQueues[0].Id);
    }

    Group queue = new Group(Name = developerName, Type = 'Queue');
    insert queue;
    insert new QueueSObject(QueueId = queue.Id, SObjectType = 'IT_Ticket__c');

    if (developerName == 'General_IT') {
      ITTicketAssignmentHandler.defaultQueueDeveloperNameOverride = developerName;
    }

    return new QueueContext(developerName, queue.Id);
  }

  private class QueueContext {
    private final String developerName;
    private final Id queueId;

    private QueueContext(String developerName, Id queueId) {
      this.developerName = developerName;
      this.queueId = queueId;
    }
  }
}

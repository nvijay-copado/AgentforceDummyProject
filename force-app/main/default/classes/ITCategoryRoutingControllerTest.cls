@isTest
private class ITCategoryRoutingControllerTest {
  @isTest
  static void getRoutingRules_returnsConfiguredRules() {
    Test.startTest();
    List<ITCategoryRoutingController.RoutingRule> rules = ITCategoryRoutingController.getRoutingRules();
    Test.stopTest();

    Assert.isFalse(rules.isEmpty(), 'Routing rules should be returned');
    Assert.isNotNull(rules[0].category);
    Assert.isNotNull(rules[0].queueReference);
  }

  @isTest
  static void getAvailableQueues_returnsQueueOptions() {
    createQueueIfMissing('General_IT');

    Test.startTest();
    List<ITCategoryRoutingController.QueueOption> queues = ITCategoryRoutingController.getAvailableQueues();
    Test.stopTest();

    Assert.isFalse(queues.isEmpty(), 'Queue options should be returned');
    Assert.isNotNull(queues[0].developerName);
  }

  @isTest
  static void getDefaultQueueName_returnsGeneralItLabel() {
    createQueueIfMissing('General_IT');

    Test.startTest();
    String queueName = ITCategoryRoutingController.getDefaultQueueName();
    Test.stopTest();

    Assert.isFalse(String.isBlank(queueName), 'Default queue name should be returned');
  }

  private static void createQueueIfMissing(String developerName) {
    List<Group> existingQueues = [
      SELECT Id
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName = :developerName
      LIMIT 1
    ];
    if (!existingQueues.isEmpty()) {
      return;
    }

    String queueLabel = developerName == 'General_IT' ? 'General IT' : developerName;
    Group queue = new Group(Name = queueLabel, Type = 'Queue');
    insert queue;
    insert new QueueSObject(QueueId = queue.Id, SObjectType = 'IT_Ticket__c');
  }
}

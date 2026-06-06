public with sharing class ITCategoryRoutingController {
  public class RoutingRule {
    @AuraEnabled
    public String category { get; set; }
    @AuraEnabled
    public String queueReference { get; set; }
    @AuraEnabled
    public String queueName { get; set; }
    @AuraEnabled
    public String queueDeveloperName { get; set; }
  }

  public class QueueOption {
    @AuraEnabled
    public String id { get; set; }
    @AuraEnabled
    public String name { get; set; }
    @AuraEnabled
    public String developerName { get; set; }
  }

  @AuraEnabled(cacheable=true)
  public static List<RoutingRule> getRoutingRules() {
    Map<String, Group> queuesByDeveloperName = new Map<String, Group>();
    for (Group queue : [
      SELECT Id, Name, DeveloperName
      FROM Group
      WHERE Type = 'Queue'
    ]) {
      queuesByDeveloperName.put(queue.DeveloperName, queue);
    }

    List<RoutingRule> rules = new List<RoutingRule>();
    for (IT_Category_Routing__mdt routing : [
      SELECT Category__c, Assigned_Queue_Id__c
      FROM IT_Category_Routing__mdt
      ORDER BY Category__c
    ]) {
      RoutingRule rule = new RoutingRule();
      rule.category = routing.Category__c;
      rule.queueReference = routing.Assigned_Queue_Id__c;

      Group queue = queuesByDeveloperName.get(routing.Assigned_Queue_Id__c);
      if (queue != null) {
        rule.queueName = queue.Name;
        rule.queueDeveloperName = queue.DeveloperName;
      } else {
        rule.queueName = routing.Assigned_Queue_Id__c;
        rule.queueDeveloperName = routing.Assigned_Queue_Id__c;
      }

      rules.add(rule);
    }

    return rules;
  }

  @AuraEnabled(cacheable=true)
  public static List<QueueOption> getAvailableQueues() {
    List<QueueOption> options = new List<QueueOption>();
    for (Group queue : [
      SELECT Id, Name, DeveloperName
      FROM Group
      WHERE Type = 'Queue'
      ORDER BY Name
    ]) {
      QueueOption option = new QueueOption();
      option.id = queue.Id;
      option.name = queue.Name;
      option.developerName = queue.DeveloperName;
      options.add(option);
    }
    return options;
  }

  @AuraEnabled(cacheable=true)
  public static String getDefaultQueueName() {
    List<Group> queues = [
      SELECT Name
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName = 'General_IT'
      LIMIT 1
    ];
    return queues.isEmpty() ? 'General IT' : queues[0].Name;
  }
}

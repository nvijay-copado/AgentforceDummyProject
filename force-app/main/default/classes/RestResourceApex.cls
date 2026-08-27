@RestResource(urlMapping='/Opportunities/*')
global with sharing class RestResourceApex {
    
    @HttpGet
    global static List<Opportunity> doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        List<Opportunity> opps = [SELECT Id, Name, StageName ,Type, TrackingNumber__c  FROM Opportunity WHERE AccountId =:accountId];
        return opps;
    }

}
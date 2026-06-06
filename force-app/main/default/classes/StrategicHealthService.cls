public with sharing class StrategicHealthService {
    public static Boolean isStrategicDeal(Opportunity opp) {
        return opp != null && opp.Strategic_Deal__c == true;
    }

    public static Integer countStrategicDeals(List<Opportunity> opportunities) {
        Integer count = 0;
        for (Opportunity opp : opportunities) {
            if (isStrategicDeal(opp)) {
                count++;
            }
        }
        return count;
    }
}

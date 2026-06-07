public with sharing class StrategicHealthService {
    public static Boolean isStrategicDeal(Opportunity opp) {
        return opp != null && opp.Strategic_Deal__c == true;
    }

    public static Id resolveStrategicDealOwner(Opportunity opp) {
        if (opp == null || opp.OwnerId == null) {
            return null;
        }
        return opp.OwnerId;
    }

    public static Boolean shouldAssignStrategicDealOwner(Opportunity opp) {
        return isStrategicDeal(opp)
            && opp.Strategic_Deal_Owner__c == null
            && resolveStrategicDealOwner(opp) != null;
    }

    public static void applyStrategicDealOwner(Opportunity opp) {
        if (shouldAssignStrategicDealOwner(opp)) {
            opp.Strategic_Deal_Owner__c = resolveStrategicDealOwner(opp);
        }
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
public with sharing class AccountRatingBackfill {
    public static String rate(Decimal revenue) {
        if (revenue == null) {
            return null;
        }
        if (revenue >= 1000000) {
            return 'Hot';
        }
        if (revenue >= 100000) {
            return 'Warm';
        }
        return 'Cold';
    }

    public static Integer run() {
        List<Account> toUpdate = new List<Account>();
        for (Account a : [SELECT Id, AnnualRevenue, Rating FROM Account WHERE AnnualRevenue != null]) {
            String r = rate(a.AnnualRevenue);
            if (a.Rating != r) {
                a.Rating = r;
                toUpdate.add(a);
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
        return toUpdate.size();
    }
}
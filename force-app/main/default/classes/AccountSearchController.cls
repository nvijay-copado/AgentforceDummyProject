public with sharing class AccountSearchController {
    public class SearchResult {
        @AuraEnabled public List<Account> records;
        @AuraEnabled public Integer totalCount;
    }

    @AuraEnabled(cacheable=true)
    public static SearchResult searchAccounts(String name, String industry, String region, Integer pageSize, Integer pageNumber) {
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new AuraHandledException('You do not have access to Account records.');
        }
        Integer size = (pageSize == null || pageSize < 1) ? 25 : Math.min(pageSize, 200);
        Integer page = (pageNumber == null || pageNumber < 1) ? 1 : pageNumber;
        Integer offsetVal = Math.min((page - 1) * size, 2000);

        List<String> clauses = new List<String>();
        if (String.isNotBlank(name)) {
            clauses.add('Name LIKE :namePattern');
        }
        if (String.isNotBlank(industry)) {
            clauses.add('Industry = :industry');
        }
        if (String.isNotBlank(region)) {
            clauses.add('BillingState = :region');
        }
        String namePattern = '%' + String.escapeSingleQuotes(String.valueOf(name == null ? '' : name).trim()) + '%';
        String whereClause = clauses.isEmpty() ? '' : ' WHERE ' + String.join(clauses, ' AND ');

        SearchResult result = new SearchResult();
        try {
            String countQuery = 'SELECT COUNT() FROM Account' + whereClause;
            result.totalCount = Database.countQueryWithBinds(countQuery,
                new Map<String, Object>{ 'namePattern' => namePattern, 'industry' => industry, 'region' => region },
                AccessLevel.USER_MODE);
            String q = 'SELECT Id, Name, Industry, BillingState, Phone FROM Account' + whereClause
                + ' ORDER BY Name LIMIT :size OFFSET :offsetVal';
            result.records = Database.queryWithBinds(q,
                new Map<String, Object>{ 'namePattern' => namePattern, 'industry' => industry, 'region' => region, 'size' => size, 'offsetVal' => offsetVal },
                AccessLevel.USER_MODE);
        } catch (Exception e) {
            throw new AuraHandledException('Account search failed: ' + e.getMessage());
        }
        return result;
    }
}
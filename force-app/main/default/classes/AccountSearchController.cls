public with sharing class AccountSearchController {
    public class SearchResult {
        @AuraEnabled public List<Account> records;
        @AuraEnabled public Integer totalCount;
    }

    @AuraEnabled(cacheable=true)
    public static SearchResult search(String name, String industry, String region, Integer pageSize, Integer pageNumber) {
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new AuraHandledException('You do not have access to Account records.');
        }
        Integer size = (pageSize == null || pageSize < 1) ? 20 : Math.min(pageSize, 200);
        Integer page = (pageNumber == null || pageNumber < 1) ? 1 : pageNumber;
        Integer offset = (page - 1) * size;
        if (offset > 2000) {
            throw new AuraHandledException('Please refine your search criteria.');
        }

        List<String> conditions = new List<String>();
        if (String.isNotBlank(name)) {
            conditions.add('Name LIKE :namePattern');
        }
        if (String.isNotBlank(industry)) {
            conditions.add('Industry = :industry');
        }
        if (String.isNotBlank(region)) {
            conditions.add('BillingState = :region');
        }
        String namePattern = '%' + (String.isNotBlank(name) ? String.escapeSingleQuotes(name.trim()) : '') + '%';
        String whereClause = conditions.isEmpty() ? '' : ' WHERE ' + String.join(conditions, ' AND ');

        SearchResult result = new SearchResult();
        try {
            result.totalCount = Database.countQueryWithBinds(
                'SELECT COUNT() FROM Account' + whereClause,
                new Map<String, Object>{ 'namePattern' => namePattern, 'industry' => industry, 'region' => region },
                AccessLevel.USER_MODE
            );
            result.records = Database.queryWithBinds(
                'SELECT Id, Name, Industry, BillingState, Phone FROM Account' + whereClause +
                ' ORDER BY Name LIMIT :size OFFSET :offset',
                new Map<String, Object>{
                    'namePattern' => namePattern, 'industry' => industry, 'region' => region,
                    'size' => size, 'offset' => offset
                },
                AccessLevel.USER_MODE
            );
        } catch (Exception e) {
            throw new AuraHandledException('Account search failed: ' + e.getMessage());
        }
        return result;
    }
}
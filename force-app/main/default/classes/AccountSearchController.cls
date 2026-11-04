public with sharing class AccountSearchController {
    public class SearchResult {
        @AuraEnabled public List<Account> records;
        @AuraEnabled public Integer totalCount;
    }

    @AuraEnabled(cacheable=true)
    public static SearchResult searchAccounts(String name, String industry, String region, Integer pageSize, Integer pageNumber) {
        if (!Schema.sObjectType.Account.isAccessible()
            || !Schema.sObjectType.Account.fields.Name.isAccessible()
            || !Schema.sObjectType.Account.fields.Industry.isAccessible()
            || !Schema.sObjectType.Account.fields.BillingState.isAccessible()) {
            throw new AuraHandledException('You do not have access to search accounts.');
        }
        Integer size = (pageSize == null || pageSize < 1 || pageSize > 200) ? 25 : pageSize;
        Integer page = (pageNumber == null || pageNumber < 1) ? 1 : pageNumber;
        Integer offset = (page - 1) * size;
        if (offset > 2000) {
            throw new AuraHandledException('Please refine your filters to see more results.');
        }
        String nameLike = String.isBlank(name) ? null : '%' + String.escapeSingleQuotes(name.trim()) + '%';
        String ind = String.isBlank(industry) ? null : industry.trim();
        String reg = String.isBlank(region) ? null : region.trim();

        List<String> clauses = new List<String>();
        Map<String, Object> binds = new Map<String, Object>{ 'nameLike' => nameLike, 'ind' => ind, 'reg' => reg, 'lim' => size, 'off' => offset };
        if (nameLike != null) { clauses.add('Name LIKE :nameLike'); }
        if (ind != null) { clauses.add('Industry = :ind'); }
        if (reg != null) { clauses.add('BillingState = :reg'); }
        String whereClause = clauses.isEmpty() ? '' : ' WHERE ' + String.join(clauses, ' AND ');

        SearchResult result = new SearchResult();
        result.totalCount = Database.countQueryWithBinds('SELECT COUNT() FROM Account' + whereClause, binds, AccessLevel.USER_MODE);
        result.records = Database.queryWithBinds(
            'SELECT Id, Name, Industry, BillingState FROM Account' + whereClause + ' ORDER BY Name ASC LIMIT :lim OFFSET :off',
            binds, AccessLevel.USER_MODE);
        return result;
    }
}
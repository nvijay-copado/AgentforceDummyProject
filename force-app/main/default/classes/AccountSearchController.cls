/**
 * Apex controller backing the accountSearch Lightning Web Component.
 * Searches Account records by name, industry and region (Billing State)
 * with server-side pagination. Runs with sharing and in user mode so the
 * running user's record access, CRUD and FLS are always enforced.
 */
public with sharing class AccountSearchController {
    /** Wrapper returned to the LWC: one page of records plus the total match count. */
    public class SearchResult {
        /** Accounts on the requested page. */
        @AuraEnabled public List<Account> records;
        /** Total number of Accounts matching the filters, used to render paging. */
        @AuraEnabled public Integer totalCount;
    }

    /**
     * Searches Accounts using optional filters, combined with AND.
     * @param name       Partial, case-insensitive match on Account Name (LIKE). Ignored if blank.
     * @param industry   Exact match on Industry. Ignored if blank.
     * @param region     Exact match on BillingState. Ignored if blank.
     * @param pageSize   Records per page. Defaults to 25 and is capped at 200.
     * @param pageNumber 1-based page number. Defaults to 1.
     * @return SearchResult with the page of records and the total count.
     * @throws AuraHandledException if the user cannot read Account or the query fails.
     */
    @AuraEnabled(cacheable=true)
    public static SearchResult searchAccounts(String name, String industry, String region, Integer pageSize, Integer pageNumber) {
        // Fail fast with a friendly message when the user has no read access to Account.
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new AuraHandledException('You do not have access to Account records.');
        }
        // Normalize paging inputs. The offset is capped at 2000 (SOQL OFFSET limit).
        Integer size = (pageSize == null || pageSize < 1) ? 25 : Math.min(pageSize, 200);
        Integer page = (pageNumber == null || pageNumber < 1) ? 1 : pageNumber;
        Integer offsetVal = Math.min((page - 1) * size, 2000);

        // Build the WHERE clause only from the filters supplied. Values are passed as
        // bind variables, never concatenated, which prevents SOQL injection.
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
        // Wildcard pattern for the partial name match.
        String namePattern = '%' + String.escapeSingleQuotes(String.valueOf(name == null ? '' : name).trim()) + '%';
        String whereClause = clauses.isEmpty() ? '' : ' WHERE ' + String.join(clauses, ' AND ');

        SearchResult result = new SearchResult();
        try {
            // Total count first so the UI can show "Page X of Y".
            String countQuery = 'SELECT COUNT() FROM Account' + whereClause;
            result.totalCount = Database.countQueryWithBinds(countQuery,
                new Map<String, Object>{ 'namePattern' => namePattern, 'industry' => industry, 'region' => region },
                AccessLevel.USER_MODE);
            // Fetch the requested page, sorted by Name for stable paging.
            String q = 'SELECT Id, Name, Industry, BillingState, Phone FROM Account' + whereClause
                + ' ORDER BY Name LIMIT :size OFFSET :offsetVal';
            result.records = Database.queryWithBinds(q,
                new Map<String, Object>{ 'namePattern' => namePattern, 'industry' => industry, 'region' => region, 'size' => size, 'offsetVal' => offsetVal },
                AccessLevel.USER_MODE);
        } catch (Exception e) {
            // Surface a readable message to the LWC instead of a raw platform error.
            throw new AuraHandledException('Account search failed: ' + e.getMessage());
        }
        return result;
    }
}
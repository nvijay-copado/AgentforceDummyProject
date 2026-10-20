import { LightningElement } from 'lwc';
import searchAccounts from '@salesforce/apex/AccountSearchController.searchAccounts';

const PAGE_SIZE = 25;
const DEBOUNCE_MS = 300;

export default class AccountSearch extends LightningElement {
    name = '';
    industry = '';
    region = '';
    pageNumber = 1;
    totalCount = 0;
    records = [];
    error;
    isLoading = false;
    sortedBy = 'Name';
    sortedDirection = 'asc';
    searched = false;
    timer;

    columns = [
        { label: 'Name', fieldName: 'Name', sortable: true },
        { label: 'Industry', fieldName: 'Industry', sortable: true },
        { label: 'Billing State', fieldName: 'BillingState', sortable: true },
        { label: 'Phone', fieldName: 'Phone', type: 'phone' }
    ];

    connectedCallback() {
        this.runSearch();
    }

    get hasRecords() { return this.records.length > 0; }
    get showEmpty() { return this.searched && !this.isLoading && !this.error && !this.hasRecords; }
    get totalPages() { return Math.max(1, Math.ceil(this.totalCount / PAGE_SIZE)); }
    get isFirstPage() { return this.pageNumber <= 1; }
    get isLastPage() { return this.pageNumber >= this.totalPages; }

    handleName(e) { this.name = e.target.value; this.scheduleSearch(); }
    handleIndustry(e) { this.industry = e.target.value; this.scheduleSearch(); }
    handleRegion(e) { this.region = e.target.value; this.scheduleSearch(); }
    handlePrev() { this.pageNumber -= 1; this.runSearch(); }
    handleNext() { this.pageNumber += 1; this.runSearch(); }

    handleSort(e) {
        this.sortedBy = e.detail.fieldName;
        this.sortedDirection = e.detail.sortDirection;
        const dir = this.sortedDirection === 'asc' ? 1 : -1;
        const key = this.sortedBy;
        this.records = [...this.records].sort((a, b) =>
            dir * String(a[key] ?? '').localeCompare(String(b[key] ?? '')));
    }

    scheduleSearch() {
        clearTimeout(this.timer);
        this.timer = setTimeout(() => {
            this.pageNumber = 1;
            this.runSearch();
        }, DEBOUNCE_MS);
    }

    async runSearch() {
        this.isLoading = true;
        this.error = undefined;
        try {
            const res = await searchAccounts({
                name: this.name, industry: this.industry, region: this.region,
                pageSize: PAGE_SIZE, pageNumber: this.pageNumber
            });
            this.records = res.records;
            this.totalCount = res.totalCount;
        } catch (err) {
            this.records = [];
            this.totalCount = 0;
            this.error = err?.body?.message || 'Search failed. Please try again.';
        } finally {
            this.isLoading = false;
            this.searched = true;
        }
    }
}
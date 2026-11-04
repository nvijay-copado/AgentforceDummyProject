import { LightningElement } from 'lwc';
import searchAccounts from '@salesforce/apex/AccountSearchController.searchAccounts';

const PAGE_SIZE = 25;
const DEBOUNCE_MS = 300;

export default class AccountSearch extends LightningElement {
    name = '';
    industry = '';
    region = '';
    records = [];
    totalCount = 0;
    pageNumber = 1;
    isLoading = false;
    error;
    searched = false;
    sortedBy = 'Name';
    sortedDirection = 'asc';
    timer;

    columns = [
        { label: 'Name', fieldName: 'Name', sortable: true },
        { label: 'Industry', fieldName: 'Industry', sortable: true },
        { label: 'Region', fieldName: 'BillingState', sortable: true }
    ];

    connectedCallback() {
        this.load();
    }

    get hasRecords() {
        return this.records.length > 0;
    }
    get showEmpty() {
        return this.searched && !this.isLoading && !this.error && this.records.length === 0;
    }
    get totalPages() {
        return Math.max(1, Math.ceil(this.totalCount / PAGE_SIZE));
    }
    get isFirstPage() {
        return this.pageNumber <= 1;
    }
    get isLastPage() {
        return this.pageNumber >= this.totalPages;
    }

    handleName(e) { this.name = e.target.value; this.debounce(); }
    handleIndustry(e) { this.industry = e.target.value; this.debounce(); }
    handleRegion(e) { this.region = e.target.value; this.debounce(); }

    debounce() {
        clearTimeout(this.timer);
        this.timer = setTimeout(() => {
            this.pageNumber = 1;
            this.load();
        }, DEBOUNCE_MS);
    }

    handlePrev() { this.pageNumber -= 1; this.load(); }
    handleNext() { this.pageNumber += 1; this.load(); }

    handleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        const dir = this.sortedDirection === 'asc' ? 1 : -1;
        const key = this.sortedBy;
        this.records = [...this.records].sort((a, b) =>
            dir * String(a[key] ?? '').localeCompare(String(b[key] ?? '')));
    }

    async load() {
        this.isLoading = true;
        this.error = undefined;
        try {
            const res = await searchAccounts({
                name: this.name,
                industry: this.industry,
                region: this.region,
                pageSize: PAGE_SIZE,
                pageNumber: this.pageNumber
            });
            this.records = res.records;
            this.totalCount = res.totalCount;
        } catch (e) {
            this.records = [];
            this.totalCount = 0;
            this.error = (e && e.body && e.body.message) || 'Unable to search accounts. Please try again.';
        } finally {
            this.searched = true;
            this.isLoading = false;
        }
    }
}
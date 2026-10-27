import { LightningElement } from 'lwc';
import search from '@salesforce/apex/AccountSearchController.search';

const PAGE_SIZE = 20;

export default class AccountSearch extends LightningElement {
    name = '';
    industry = '';
    region = '';
    records = [];
    totalCount = 0;
    pageNumber = 1;
    isLoading = false;
    searched = false;
    error;
    sortedBy = 'Name';
    sortedDirection = 'asc';
    cache = new Map();

    columns = [
        { label: 'Name', fieldName: 'Name', sortable: true },
        { label: 'Industry', fieldName: 'Industry', sortable: true },
        { label: 'State', fieldName: 'BillingState', sortable: true },
        { label: 'Phone', fieldName: 'Phone', type: 'phone' }
    ];

    get hasResults() {
        return this.records.length > 0;
    }
    get showEmpty() {
        return this.searched && !this.isLoading && !this.error && this.records.length === 0;
    }
    get totalPages() {
        return Math.max(1, Math.ceil(this.totalCount / PAGE_SIZE));
    }
    get disablePrev() {
        return this.pageNumber <= 1;
    }
    get disableNext() {
        return this.pageNumber >= this.totalPages;
    }

    handleName(e) {
        this.name = e.target.value;
    }
    handleIndustry(e) {
        this.industry = e.target.value;
    }
    handleRegion(e) {
        this.region = e.target.value;
    }

    handleSearch() {
        this.pageNumber = 1;
        this.load();
    }
    handlePrev() {
        this.pageNumber -= 1;
        this.load();
    }
    handleNext() {
        this.pageNumber += 1;
        this.load();
    }

    handleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        const dir = this.sortedDirection === 'asc' ? 1 : -1;
        const field = this.sortedBy;
        this.records = [...this.records].sort((a, b) => {
            const x = (a[field] || '').toString().toLowerCase();
            const y = (b[field] || '').toString().toLowerCase();
            return x > y ? dir : x < y ? -dir : 0;
        });
    }

    async load() {
        const key = JSON.stringify([this.name, this.industry, this.region, this.pageNumber]);
        this.error = undefined;
        this.searched = true;
        if (this.cache.has(key)) {
            this.apply(this.cache.get(key));
            return;
        }
        this.isLoading = true;
        try {
            const result = await search({
                name: this.name,
                industry: this.industry,
                region: this.region,
                pageSize: PAGE_SIZE,
                pageNumber: this.pageNumber
            });
            this.cache.set(key, result);
            this.apply(result);
        } catch (err) {
            this.records = [];
            this.totalCount = 0;
            this.error = (err && err.body && err.body.message) || 'Unable to search accounts.';
        } finally {
            this.isLoading = false;
        }
    }

    apply(result) {
        this.records = result.records || [];
        this.totalCount = result.totalCount || 0;
    }
}
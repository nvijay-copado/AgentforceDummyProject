import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRecords from '@salesforce/apex/InlineEditTableController.getRecords';
import saveRecords from '@salesforce/apex/InlineEditTableController.saveRecords';

export default class InlineEditTable extends LightningElement {
    @api title = 'Related Records';
    @api objectApiName = 'Contact';
    @api fieldNames = 'FirstName,LastName,Email,Phone';
    @api parentField = 'AccountId';
    @api maxRows = 50;
    @api recordId;
    @api readOnly = false;

    rows = [];
    draftValues = [];
    tableErrors = {};
    errorMessage;
    sortedBy;
    sortedDirection = 'asc';
    wiredResult;

    get fields() {
        return (this.fieldNames || '').split(',').map((f) => f.trim()).filter(Boolean);
    }

    get columns() {
        return this.fields.map((f) => ({
            label: f.replace(/__c$/, '').replace(/([a-z])([A-Z])/g, '$1 $2').replace(/_/g, ' '),
            fieldName: f,
            sortable: true,
            editable: !this.readOnly
        }));
    }

    @wire(getRecords, {
        objectApiName: '$objectApiName',
        fields: '$fields',
        parentField: '$parentField',
        parentId: '$recordId',
        maxRows: '$maxRows'
    })
    wiredRecords(result) {
        this.wiredResult = result;
        if (result.data) {
            this.rows = [...result.data];
            this.errorMessage = undefined;
            if (this.sortedBy) {
                this.sortRows();
            }
        } else if (result.error) {
            this.rows = [];
            this.errorMessage = this.reduceError(result.error);
        }
    }

    handleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.sortRows();
    }

    sortRows() {
        const dir = this.sortedDirection === 'asc' ? 1 : -1;
        const key = this.sortedBy;
        this.rows = [...this.rows].sort((a, b) => {
            const x = a[key] === undefined || a[key] === null ? '' : a[key];
            const y = b[key] === undefined || b[key] === null ? '' : b[key];
            if (x === y) return 0;
            return x > y ? dir : -dir;
        });
    }

    async handleSave(event) {
        const records = event.detail.draftValues.map((d) => ({ ...d }));
        try {
            const res = await saveRecords({ records });
            if (res.success) {
                this.dispatchEvent(new ShowToastEvent({ title: 'Saved', message: 'Records updated', variant: 'success' }));
                this.draftValues = [];
                this.tableErrors = {};
                await refreshApex(this.wiredResult);
            } else {
                const rowsErr = {};
                Object.keys(res.rowErrors || {}).forEach((id) => {
                    rowsErr[id] = { title: 'Could not save', messages: [res.rowErrors[id]], fieldNames: [] };
                });
                this.tableErrors = { rows: rowsErr, table: { title: 'Some records failed', messages: res.errors } };
            }
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error saving', message: this.reduceError(e), variant: 'error' }));
        }
    }

    handleCancel() {
        this.draftValues = [];
        this.tableErrors = {};
    }

    reduceError(error) {
        if (error && error.body && error.body.message) return error.body.message;
        return (error && error.message) || 'Unknown error';
    }
}
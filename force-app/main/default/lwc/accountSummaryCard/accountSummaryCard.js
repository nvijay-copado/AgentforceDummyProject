import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME from '@salesforce/schema/Account.Name';
import INDUSTRY from '@salesforce/schema/Account.Industry';
import TYPE from '@salesforce/schema/Account.Type';
import PHONE from '@salesforce/schema/Account.Phone';
import WEBSITE from '@salesforce/schema/Account.Website';
import OWNER from '@salesforce/schema/Account.Owner.Name';

const FIELDS = [NAME, INDUSTRY, TYPE, PHONE, WEBSITE, OWNER];

export default class AccountSummaryCard extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    account;

    get isLoaded() {
        return !!this.account?.data;
    }
    get hasError() {
        return !!this.account?.error;
    }
    get name() {
        return getFieldValue(this.account.data, NAME);
    }
    get industry() {
        return getFieldValue(this.account.data, INDUSTRY);
    }
    get type() {
        return getFieldValue(this.account.data, TYPE);
    }
    get phone() {
        return getFieldValue(this.account.data, PHONE);
    }
    get website() {
        return getFieldValue(this.account.data, WEBSITE);
    }
    get owner() {
        return getFieldValue(this.account.data, OWNER);
    }
}
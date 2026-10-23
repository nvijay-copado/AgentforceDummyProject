import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getApproval from '@salesforce/apex/QuoteApprovalController.getApproval';
import decide from '@salesforce/apex/QuoteApprovalController.decide';
import retrySync from '@salesforce/apex/QuoteApprovalController.retrySync';

export default class QuoteApprovalPanel extends LightningElement {
    @api recordId;
    error;
    wired;

    @wire(getApproval, { opportunityId: '$recordId' })
    wiredApproval(result) {
        this.wired = result;
    }

    get view() {
        return this.wired && this.wired.data ? this.wired.data : null;
    }

    get showDecisionButtons() {
        return this.view && this.view.canDecide && this.view.decision === 'Pending';
    }

    get showRetry() {
        return this.view && this.view.canDecide && this.view.syncStatus === 'Failed';
    }

    async handleDecision(event) {
        await this.run(() => decide({ requestId: this.view.requestId, decision: event.target.dataset.decision }));
    }

    async handleRetry() {
        await this.run(() => retrySync({ requestId: this.view.requestId }));
    }

    async run(action) {
        this.error = undefined;
        try {
            await action();
            await refreshApex(this.wired);
        } catch (e) {
            this.error = e && e.body ? e.body.message : 'Unexpected error';
        }
    }
}
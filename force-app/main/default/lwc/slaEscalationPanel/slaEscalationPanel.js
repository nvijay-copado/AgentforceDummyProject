import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSlaSummary from '@salesforce/apex/SLAEscalationController.getSlaSummary';
import acknowledgeEscalation from '@salesforce/apex/SLAEscalationController.acknowledgeEscalation';

export default class SlaEscalationPanel extends LightningElement {
    @api recordId;
    summary;
    error;
    wiredResult;

    @wire(getSlaSummary, { caseId: '$recordId' })
    wiredSummary(result) {
        this.wiredResult = result;
        if (result.data) {
            this.summary = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.summary = undefined;
            this.error = result.error.body ? result.error.body.message : 'Unable to load SLA data.';
        }
    }

    get rows() {
        return this.summary ? this.summary.escalations : [];
    }

    get noEscalations() {
        return this.rows.length === 0;
    }

    get badgeClass() {
        const map = { Breached: 'slds-theme_error', 'At Risk': 'slds-theme_warning', Met: 'slds-theme_success' };
        return map[this.summary.slaStatus] || '';
    }

    async handleAcknowledge(event) {
        try {
            await acknowledgeEscalation({ escalationId: event.target.dataset.id });
            this.dispatchEvent(new ShowToastEvent({ title: 'Escalation acknowledged', variant: 'success' }));
            await refreshApex(this.wiredResult);
        } catch (e) {
            this.dispatchEvent(
                new ShowToastEvent({ title: 'Error', message: e.body ? e.body.message : 'Failed', variant: 'error' })
            );
        }
    }
}
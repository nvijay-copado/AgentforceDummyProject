import { LightningElement, wire } from 'lwc';
import getDashboardCases from '@salesforce/apex/SLAEscalationController.getDashboardCases';

const COLUMNS = [
    { label: 'Case', fieldName: 'CaseNumber' },
    { label: 'Subject', fieldName: 'Subject' },
    { label: 'Priority', fieldName: 'Priority' },
    { label: 'SLA Status', fieldName: 'SLA_Status__c' },
    { label: 'Due', fieldName: 'SLA_Due_Date__c', type: 'date', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit' } },
    { label: 'Level', fieldName: 'Escalation_Level__c', type: 'number' },
    { label: 'Owner', fieldName: 'ownerName' }
];

export default class SlaManagerDashboard extends LightningElement {
    columns = COLUMNS;
    priority = '';
    minLevel = '0';
    cases;
    error;
    priorityOptions = [
        { label: 'All', value: '' },
        { label: 'High', value: 'High' },
        { label: 'Medium', value: 'Medium' },
        { label: 'Low', value: 'Low' }
    ];
    levelOptions = [0, 1, 2, 3].map((n) => ({ label: String(n), value: String(n) }));

    @wire(getDashboardCases, { priority: '$priority', minLevel: '$levelNumber' })
    wiredCases({ data, error }) {
        if (data) {
            this.cases = data.map((c) => ({ ...c, ownerName: c.Owner ? c.Owner.Name : '' }));
            this.error = undefined;
        } else if (error) {
            this.cases = undefined;
            this.error = error.body ? error.body.message : 'Unable to load cases.';
        }
    }

    get levelNumber() {
        return parseInt(this.minLevel, 10);
    }

    get isEmpty() {
        return this.cases && this.cases.length === 0;
    }

    handlePriority(e) {
        this.priority = e.detail.value;
    }

    handleLevel(e) {
        this.minLevel = e.detail.value;
    }
}
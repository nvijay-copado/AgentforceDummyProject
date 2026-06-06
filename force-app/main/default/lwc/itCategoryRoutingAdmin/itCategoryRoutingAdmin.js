import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRoutingRules from '@salesforce/apex/ITCategoryRoutingController.getRoutingRules';
import getAvailableQueues from '@salesforce/apex/ITCategoryRoutingController.getAvailableQueues';
import getDefaultQueueName from '@salesforce/apex/ITCategoryRoutingController.getDefaultQueueName';

const COLUMNS = [
    { label: 'Category', fieldName: 'category', type: 'text' },
    { label: 'Assigned Queue', fieldName: 'queueName', type: 'text' },
    { label: 'Queue Developer Name', fieldName: 'queueDeveloperName', type: 'text' }
];

export default class ItCategoryRoutingAdmin extends NavigationMixin(
    LightningElement
) {
    columns = COLUMNS;
    routingRules = [];
    queueOptions = [];
    defaultQueueName = 'General IT';
    isLoading = true;

    @wire(getRoutingRules)
    wiredRoutingRules({ data, error }) {
        if (data) {
            this.routingRules = data;
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
        }
    }

    @wire(getAvailableQueues)
    wiredQueues({ data }) {
        if (data) {
            this.queueOptions = data;
        }
    }

    @wire(getDefaultQueueName)
    wiredDefaultQueue({ data }) {
        if (data) {
            this.defaultQueueName = data;
        }
    }

    get hasRules() {
        return this.routingRules.length > 0;
    }

    get hasQueues() {
        return this.queueOptions.length > 0;
    }

    handleManageInSetup() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/lightning/setup/CustomMetadata/home'
            }
        });
    }
}

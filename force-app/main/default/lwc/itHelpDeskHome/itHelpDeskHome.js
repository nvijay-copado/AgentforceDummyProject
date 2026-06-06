import { LightningElement } from 'lwc';

const VIEW_HOME = 'home';
const VIEW_FORM = 'form';
const VIEW_CONFIRMATION = 'confirmation';

export default class ItHelpDeskHome extends LightningElement {
    currentView = VIEW_HOME;
    confirmationDetails = {};

    get showHome() {
        return this.currentView === VIEW_HOME;
    }

    get showForm() {
        return this.currentView === VIEW_FORM;
    }

    get showConfirmation() {
        return this.currentView === VIEW_CONFIRMATION;
    }

    get formattedSlaDueDate() {
        if (!this.confirmationDetails.slaDueDate) {
            return '';
        }
        return new Date(this.confirmationDetails.slaDueDate).toLocaleString();
    }

    handleOpenForm() {
        this.currentView = VIEW_FORM;
    }

    handleTicketSubmitted(event) {
        this.confirmationDetails = event.detail;
        this.currentView = VIEW_CONFIRMATION;
    }

    handleSubmitAnother() {
        this.confirmationDetails = {};
        this.currentView = VIEW_FORM;
    }

    handleBackToHome() {
        this.confirmationDetails = {};
        this.currentView = VIEW_HOME;
    }
}

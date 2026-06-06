import { LightningElement, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import createTicket from '@salesforce/apex/ITTicketController.createTicket';

const USER_FIELDS = ['User.Name', 'User.Department', 'User.Email'];
const MAX_FILE_SIZE = 10485760;

const CATEGORY_OPTIONS = [
    { label: 'Hardware', value: 'Hardware' },
    { label: 'Software', value: 'Software' },
    { label: 'Network', value: 'Network' },
    { label: 'Access', value: 'Access' },
    { label: 'Other', value: 'Other' }
];

const SUB_CATEGORY_MAP = {
    Hardware: [
        { label: 'Laptop', value: 'Laptop' },
        { label: 'Monitor', value: 'Monitor' },
        { label: 'Peripherals', value: 'Peripherals' },
        { label: 'Mobile Device', value: 'Mobile Device' }
    ],
    Software: [
        { label: 'Application Error', value: 'Application Error' },
        { label: 'Installation', value: 'Installation' },
        { label: 'License', value: 'License' },
        { label: 'Performance', value: 'Performance' }
    ],
    Network: [
        { label: 'VPN', value: 'VPN' },
        { label: 'Wi-Fi', value: 'Wi-Fi' },
        { label: 'Email', value: 'Email' }
    ],
    Access: [
        { label: 'Account Lockout', value: 'Account Lockout' },
        { label: 'Password Reset', value: 'Password Reset' },
        { label: 'Permissions', value: 'Permissions' }
    ],
    Other: [{ label: 'General Inquiry', value: 'General Inquiry' }]
};

const PRIORITY_OPTIONS = [
    { label: 'Low', value: 'Low' },
    { label: 'Medium', value: 'Medium' },
    { label: 'High', value: 'High' }
];

const URGENCY_OPTIONS = [
    { label: 'Low', value: 'Low' },
    { label: 'Normal', value: 'Normal' },
    { label: 'High', value: 'High' },
    { label: 'Critical', value: 'Critical' }
];

export default class ItTicketSubmissionForm extends LightningElement {
    userId = USER_ID;
    acceptedFormats = [
        '.pdf',
        '.png',
        '.jpg',
        '.jpeg',
        '.doc',
        '.docx',
        '.txt',
        '.xlsx'
    ];

    category = '';
    subCategory = '';
    subject = '';
    description = '';
    priority = 'Medium';
    affectedSystem = '';
    urgency = 'Normal';
    employeeName = '';
    department = '';
    contactEmail = '';
    isSubmitting = false;
    uploadedDocumentIds = [];

    fieldErrors = {};

    categoryOptions = CATEGORY_OPTIONS;
    priorityOptions = PRIORITY_OPTIONS;
    urgencyOptions = URGENCY_OPTIONS;

    @wire(getRecord, { recordId: USER_ID, fields: USER_FIELDS })
    wiredUser({ data }) {
        if (data) {
            this.employeeName = data.fields.Name.value;
            this.department = data.fields.Department.value || '';
            this.contactEmail = data.fields.Email.value;
        }
    }

    get subCategoryOptions() {
        return SUB_CATEGORY_MAP[this.category] || [];
    }

    get isSubCategoryDisabled() {
        return !this.category;
    }

    handleCategoryChange(event) {
        this.category = event.detail.value;
        this.subCategory = '';
        this.clearFieldError('category');
        this.clearFieldError('subCategory');
    }

    handleSubCategoryChange(event) {
        this.subCategory = event.detail.value;
        this.clearFieldError('subCategory');
    }

    handleSubjectChange(event) {
        this.subject = event.detail.value;
        this.clearFieldError('subject');
    }

    handleDescriptionChange(event) {
        this.description = event.detail.value;
        this.clearFieldError('description');
    }

    handlePriorityChange(event) {
        this.priority = event.detail.value;
        this.clearFieldError('priority');
    }

    handleAffectedSystemChange(event) {
        this.affectedSystem = event.detail.value;
    }

    handleUrgencyChange(event) {
        this.urgency = event.detail.value;
        this.clearFieldError('urgency');
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files || [];
        uploadedFiles.forEach((file) => {
            if (file.size > MAX_FILE_SIZE) {
                this.setFieldError(
                    'attachment',
                    'Each attachment must be 10MB or smaller.'
                );
                return;
            }
            this.uploadedDocumentIds = [
                ...this.uploadedDocumentIds,
                file.documentId
            ];
        });
        this.clearFieldError('attachment');
    }

    handleSubmit() {
        if (!this.validateForm()) {
            return;
        }

        this.isSubmitting = true;

        createTicket({
            request: {
                category: this.category,
                subCategory: this.subCategory,
                subject: this.subject,
                description: this.description,
                priority: this.priority,
                affectedSystem: this.affectedSystem,
                urgency: this.urgency,
                employeeName: this.employeeName,
                department: this.department,
                contactEmail: this.contactEmail,
                contentDocumentIds: this.uploadedDocumentIds
            }
        })
            .then((response) => {
                if (response.success) {
                    this.dispatchEvent(
                        new CustomEvent('ticketsubmitted', {
                            detail: {
                                ticketId: response.ticketId,
                                ticketName: response.ticketName,
                                slaDueDate: response.slaDueDate,
                                slaHours: response.slaHours
                            }
                        })
                    );
                } else {
                    this.setFieldError('form', response.errorMessage);
                }
            })
            .catch(() => {
                this.setFieldError(
                    'form',
                    'Unable to submit your ticket. Please try again.'
                );
            })
            .finally(() => {
                this.isSubmitting = false;
            });
    }

    validateForm() {
        this.fieldErrors = {};
        let isValid = true;

        if (!this.category) {
            this.setFieldError('category', 'Issue Category is required.');
            isValid = false;
        }
        if (!this.subCategory) {
            this.setFieldError('subCategory', 'Sub-category is required.');
            isValid = false;
        }
        if (!this.subject || !this.subject.trim()) {
            this.setFieldError('subject', 'Subject is required.');
            isValid = false;
        }
        if (!this.stripHtml(this.description)) {
            this.setFieldError('description', 'Description is required.');
            isValid = false;
        }
        if (!this.priority) {
            this.setFieldError('priority', 'Priority is required.');
            isValid = false;
        }
        if (!this.urgency) {
            this.setFieldError('urgency', 'Urgency is required.');
            isValid = false;
        }
        if (!this.contactEmail) {
            this.setFieldError('contactEmail', 'Contact email is required.');
            isValid = false;
        }

        return isValid;
    }

    stripHtml(value) {
        if (!value) {
            return '';
        }
        return value.replace(/<[^>]+>/g, '').trim();
    }

    setFieldError(field, message) {
        this.fieldErrors = { ...this.fieldErrors, [field]: message };
    }

    clearFieldError(field) {
        if (this.fieldErrors[field]) {
            const updatedErrors = { ...this.fieldErrors };
            delete updatedErrors[field];
            this.fieldErrors = updatedErrors;
        }
    }

    get categoryError() {
        return this.fieldErrors.category;
    }

    get subCategoryError() {
        return this.fieldErrors.subCategory;
    }

    get subjectError() {
        return this.fieldErrors.subject;
    }

    get descriptionError() {
        return this.fieldErrors.description;
    }

    get priorityError() {
        return this.fieldErrors.priority;
    }

    get urgencyError() {
        return this.fieldErrors.urgency;
    }

    get contactEmailError() {
        return this.fieldErrors.contactEmail;
    }

    get attachmentError() {
        return this.fieldErrors.attachment;
    }

    get formError() {
        return this.fieldErrors.form;
    }
}

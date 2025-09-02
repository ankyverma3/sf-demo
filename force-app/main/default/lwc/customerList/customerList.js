import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCustomers from '@salesforce/apex/CustomerController.getCustomers';
import createCustomer from '@salesforce/apex/CustomerController.createCustomer';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
    { label: 'Customer Number', fieldName: 'Name', type: 'text' },
    { label: 'Customer Type', fieldName: 'Customer_Type__c', type: 'text' },
    { label: 'Email', fieldName: 'Email__c', type: 'email' },
    { label: 'Phone', fieldName: 'Phone__c', type: 'phone' },
    { label: 'Total Orders', fieldName: 'Total_Orders__c', type: 'number' },
    { label: 'Total Revenue', fieldName: 'Total_Revenue__c', type: 'currency', typeAttributes: { currencyCode: 'USD' } }
];

export default class CustomerList extends LightningElement {
    @track customers = [];
    @track columns = COLUMNS;
    @track showModal = false;
    @track isLoading = false;
    @track customerData = {
        Customer_Type__c: 'Individual',
        Email__c: '',
        Phone__c: ''
    };

    wiredCustomersResult;

    @wire(getCustomers)
    wiredCustomers(result) {
        this.wiredCustomersResult = result;
        if (result.data) {
            this.customers = result.data;
        } else if (result.error) {
            this.showToast('Error', 'Failed to load customers', 'error');
        }
    }

    get customerTypeOptions() {
        return [
            { label: 'Individual', value: 'Individual' },
            { label: 'Business', value: 'Business' },
            { label: 'Enterprise', value: 'Enterprise' }
        ];
    }

    handleNewCustomer() {
        this.showModal = true;
        this.customerData = {
            Customer_Type__c: 'Individual',
            Email__c: '',
            Phone__c: ''
        };
    }

    handleCloseModal() {
        this.showModal = false;
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this.customerData[field] = event.target.value;
    }

    async handleSave() {
        this.isLoading = true;
        
        try {
            await createCustomer({ customerData: this.customerData });
            this.showToast('Success', 'Customer created successfully', 'success');
            this.showModal = false;
            
            // Refresh the data
            await refreshApex(this.wiredCustomersResult);
            
        } catch (error) {
            this.showToast('Error', 'Failed to create customer: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}

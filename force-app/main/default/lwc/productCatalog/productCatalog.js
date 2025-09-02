import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProducts from '@salesforce/apex/ProductController.getProducts';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
    { label: 'Product Name', fieldName: 'Name', type: 'text' },
    { label: 'SKU', fieldName: 'SKU__c', type: 'text' },
    { label: 'Category', fieldName: 'Category__c', type: 'text' },
    { label: 'Price', fieldName: 'Price__c', type: 'currency', typeAttributes: { currencyCode: 'USD' } },
    { label: 'Stock', fieldName: 'Stock_Quantity__c', type: 'number' },
    { label: 'Description', fieldName: 'Description__c', type: 'text' }
];

export default class ProductCatalog extends LightningElement {
    @track products = [];
    @track columns = COLUMNS;
    @track searchTerm = '';
    @track selectedCategory = '';
    @track isLoading = false;

    wiredProductsResult;

    @wire(getProducts, { searchTerm: '$searchTerm', category: '$selectedCategory' })
    wiredProducts(result) {
        this.wiredProductsResult = result;
        if (result.data) {
            this.products = result.data;
        } else if (result.error) {
            this.showToast('Error', 'Failed to load products', 'error');
        }
    }

    get categoryOptions() {
        return [
            { label: 'All Categories', value: '' },
            { label: 'Electronics', value: 'Electronics' },
            { label: 'Clothing', value: 'Clothing' },
            { label: 'Books', value: 'Books' },
            { label: 'Home & Garden', value: 'Home & Garden' }
        ];
    }

    get hasProducts() {
        return this.products && this.products.length > 0;
    }

    get productCount() {
        return this.products ? this.products.length : 0;
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    handleCategoryChange(event) {
        this.selectedCategory = event.target.value;
    }

    async handleRefresh() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredProductsResult);
            this.showToast('Success', 'Product catalog refreshed', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to refresh products', 'error');
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

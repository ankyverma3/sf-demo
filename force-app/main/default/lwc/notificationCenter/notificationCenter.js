import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getNotifications from '@salesforce/apex/NotificationController.getNotifications';
import markNotificationAsRead from '@salesforce/apex/NotificationController.markNotificationAsRead';
import markAllAsRead from '@salesforce/apex/NotificationController.markAllAsRead';

const COLUMNS = [
    { label: 'Title', fieldName: 'Title__c', type: 'text' },
    { label: 'Message', fieldName: 'Message__c', type: 'text' },
    { label: 'Type', fieldName: 'Type__c', type: 'text' },
    { label: 'Read', fieldName: 'Is_Read__c', type: 'boolean' },
    { label: 'Date', fieldName: 'CreatedDate', type: 'date' }
];

const ROW_ACTIONS = [
    { label: 'Mark as Read', name: 'markAsRead' },
    { label: 'View Details', name: 'viewDetails' }
];

export default class NotificationCenter extends LightningElement {
    @track notifications = [];
    @track columns = COLUMNS;
    @track rowActions = ROW_ACTIONS;
    @track isLoading = false;
    @track showUnreadOnly = false;
    @track selectedNotificationId = null;

    // Junior dev mistake: Not using proper wire result handling
    wiredNotificationsResult;

    @wire(getNotifications, { showUnreadOnly: '$showUnreadOnly' })
    wiredNotifications(result) {
        this.wiredNotificationsResult = result;
        if (result.data) {
            this.notifications = result.data;
        } else if (result.error) {
            this.showToast('Error', 'Failed to load notifications', 'error');
        }
    }

    get hasNotifications() {
        return this.notifications && this.notifications.length > 0;
    }

    get unreadCount() {
        // Junior dev mistake: Not handling null/undefined properly
        return this.notifications.filter(notification => !notification.Is_Read__c).length;
    }

    get notificationCount() {
        return this.notifications ? this.notifications.length : 0;
    }

    get showMarkAllButton() {
        return this.unreadCount > 0;
    }

    // Junior dev mistake: Not using proper event handling
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'markAsRead') {
            this.markAsRead(row.Id);
        } else if (action.name === 'viewDetails') {
            this.viewDetails(row);
        }
    }

    async markAsRead(notificationId) {
        this.isLoading = true;
        
        try {
            await markNotificationAsRead({ notificationId: notificationId });
            this.showToast('Success', 'Notification marked as read', 'success');
            
            // Refresh the data
            await refreshApex(this.wiredNotificationsResult);
            
        } catch (error) {
            // Junior dev mistake: Not handling different error types
            this.showToast('Error', 'Failed to mark notification as read: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleMarkAllAsRead() {
        this.isLoading = true;
        
        try {
            await markAllAsRead();
            this.showToast('Success', 'All notifications marked as read', 'success');
            
            // Refresh the data
            await refreshApex(this.wiredNotificationsResult);
            
        } catch (error) {
            this.showToast('Error', 'Failed to mark all notifications as read: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleToggleUnreadOnly() {
        this.showUnreadOnly = !this.showUnreadOnly;
    }

    async handleRefresh() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredNotificationsResult);
            this.showToast('Success', 'Notifications refreshed', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to refresh notifications', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    viewDetails(notification) {
        // Junior dev mistake: Not implementing proper navigation
        this.selectedNotificationId = notification.Id;
        // In a real app, this would navigate to the related record
        this.showToast('Info', 'View details functionality not implemented yet', 'info');
    }

    // Junior dev mistake: Not using proper error handling
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Junior dev mistake: Not implementing proper cleanup
    disconnectedCallback() {
        // Should clean up any event listeners or timers here
    }
}

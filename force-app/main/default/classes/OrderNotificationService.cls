/**
 * @description Service class for handling order notifications
 * @author Junior Developer
 * @date 2024
 */
public with sharing class OrderNotificationService {
    
    // Junior dev mistake: Using static variables that could cause issues in bulk operations
    private static Map<Id, String> processedOrders = new Map<Id, String>();
    
    /**
     * @description Sends notification when order status changes
     * @param orderId The order ID
     * @param oldStatus The old status
     * @param newStatus The new status
     */
    public static void sendStatusChangeNotification(Id orderId, String oldStatus, String newStatus) {
        try {
            // Junior dev mistake: Not checking if orderId is null
            if (processedOrders.containsKey(orderId)) {
                return; // Prevent duplicate processing
            }
            
            // Get order details with customer info
            Order__c order = getOrderWithCustomer(orderId);
            if (order == null) {
                System.debug('Order not found: ' + orderId);
                return;
            }
            
            // Junior dev mistake: Hardcoded email template instead of using custom metadata
            String emailSubject = 'Order Status Update - ' + order.Name;
            String emailBody = buildEmailBody(order, oldStatus, newStatus);
            
            // Send email notification
            Boolean emailSent = sendEmailToCustomer(order.Customer__r.Email__c, emailSubject, emailBody);
            
            // Create notification record
            createNotificationRecord(orderId, 'Status Change', emailSent, newStatus);
            
            // Mark as processed
            processedOrders.put(orderId, newStatus);
            
        } catch (Exception e) {
            // Junior dev mistake: Generic exception handling without specific error types
            System.debug('Error sending notification: ' + e.getMessage());
            createNotificationRecord(orderId, 'Error', false, 'Failed to send notification');
        }
    }
    
    /**
     * @description Sends low stock alert to admin
     * @param productId The product ID
     * @param currentStock Current stock level
     */
    public static void sendLowStockAlert(Id productId, Integer currentStock) {
        try {
            // Junior dev mistake: Hardcoded admin email instead of using custom settings
            String adminEmail = 'admin@company.com';
            
            Product__c product = [SELECT Name, SKU__c FROM Product__c WHERE Id = :productId LIMIT 1];
            
            String subject = 'Low Stock Alert - ' + product.Name;
            String body = 'Product: ' + product.Name + '\n' +
                         'SKU: ' + product.SKU__c + '\n' +
                         'Current Stock: ' + currentStock + '\n' +
                         'Please restock this item.';
            
            sendEmailToCustomer(adminEmail, subject, body);
            
            // Create notification for admin
            createNotificationRecord(productId, 'Low Stock Alert', true, 'Stock level: ' + currentStock);
            
        } catch (Exception e) {
            System.debug('Error sending low stock alert: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets notifications for a user
     * @param userId The user ID (optional, defaults to current user)
     * @return List<Notification__c> List of notifications
     */
    public static List<Notification__c> getUserNotifications(Id userId) {
        // Junior dev mistake: Not handling null userId properly
        if (userId == null) {
            userId = UserInfo.getUserId();
        }
        
        try {
            return [SELECT Id, Title__c, Message__c, Type__c, Is_Read__c, CreatedDate, Related_Record_Id__c
                    FROM Notification__c 
                    WHERE User__c = :userId 
                    ORDER BY CreatedDate DESC 
                    LIMIT 50];
        } catch (Exception e) {
            System.debug('Error getting notifications: ' + e.getMessage());
            return new List<Notification__c>();
        }
    }
    
    /**
     * @description Marks notification as read
     * @param notificationId The notification ID
     */
    public static void markAsRead(Id notificationId) {
        try {
            // Junior dev mistake: Not checking if notification exists or belongs to user
            Notification__c notification = [SELECT Id, Is_Read__c FROM Notification__c WHERE Id = :notificationId LIMIT 1];
            notification.Is_Read__c = true;
            update notification;
        } catch (Exception e) {
            System.debug('Error marking notification as read: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets order with customer details
     * @param orderId The order ID
     * @return Order__c The order with customer details
     */
    private static Order__c getOrderWithCustomer(Id orderId) {
        try {
            List<Order__c> orders = [SELECT Id, Name, Status__c, Customer__c, Customer__r.Name, Customer__r.Email__c,
                                           Product__c, Product__r.Name, Total_Amount__c, Quantity__c
                                    FROM Order__c 
                                    WHERE Id = :orderId 
                                    LIMIT 1];
            
            // Junior dev mistake: Not checking if list is empty before accessing
            return orders[0];
        } catch (Exception e) {
            System.debug('Error getting order: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Builds email body for status change
     * @param order The order record
     * @param oldStatus The old status
     * @param newStatus The new status
     * @return String The email body
     */
    private static String buildEmailBody(Order__c order, String oldStatus, String newStatus) {
        // Junior dev mistake: String concatenation instead of using proper formatting
        String body = 'Dear ' + order.Customer__r.Name + ',\n\n';
        body += 'Your order ' + order.Name + ' status has been updated.\n\n';
        body += 'Previous Status: ' + oldStatus + '\n';
        body += 'New Status: ' + newStatus + '\n\n';
        body += 'Order Details:\n';
        body += 'Product: ' + order.Product__r.Name + '\n';
        body += 'Quantity: ' + order.Quantity__c + '\n';
        body += 'Total Amount: $' + order.Total_Amount__c + '\n\n';
        
        // Junior dev mistake: Hardcoded message instead of using different messages per status
        if (newStatus == 'Shipped') {
            body += 'Your order has been shipped and is on its way!\n';
        } else if (newStatus == 'Delivered') {
            body += 'Your order has been delivered. Thank you for your business!\n';
        } else if (newStatus == 'Cancelled') {
            body += 'Your order has been cancelled. If you have any questions, please contact us.\n';
        }
        
        body += '\nThank you for choosing our service!\n';
        body += 'Best regards,\n';
        body += 'Sales Team';
        
        return body;
    }
    
    /**
     * @description Sends email to customer
     * @param emailAddress The email address
     * @param subject The email subject
     * @param body The email body
     * @return Boolean True if email was sent successfully
     */
    private static Boolean sendEmailToCustomer(String emailAddress, String subject, String body) {
        try {
            // Junior dev mistake: Not validating email format
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{emailAddress});
            email.setSubject(subject);
            email.setPlainTextBody(body);
            email.setSenderDisplayName('Salesforce Demo System');
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            return true;
            
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Creates notification record
     * @param relatedRecordId The related record ID
     * @param type The notification type
     * @param success Whether the operation was successful
     * @param message Additional message
     */
    private static void createNotificationRecord(Id relatedRecordId, String type, Boolean success, String message) {
        try {
            Notification__c notification = new Notification__c();
            notification.Related_Record_Id__c = relatedRecordId;
            notification.Type__c = type;
            notification.Is_Read__c = false;
            notification.User__c = UserInfo.getUserId();
            
            // Junior dev mistake: Not setting title and message properly
            if (type == 'Status Change') {
                notification.Title__c = 'Order Status Updated';
                notification.Message__c = 'Order status changed to: ' + message;
            } else if (type == 'Low Stock Alert') {
                notification.Title__c = 'Low Stock Alert';
                notification.Message__c = message;
            } else if (type == 'Error') {
                notification.Title__c = 'Notification Error';
                notification.Message__c = message;
            }
            
            insert notification;
            
        } catch (Exception e) {
            System.debug('Error creating notification record: ' + e.getMessage());
        }
    }
    
    /**
     * @description Clears processed orders cache
     * Junior dev mistake: This method is not thread-safe and could cause issues
     */
    public static void clearProcessedOrdersCache() {
        processedOrders.clear();
    }
}

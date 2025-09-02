/**
 * @description Test class for OrderNotificationService
 * @author Junior Developer
 * @date 2024
 */
@isTest
public class OrderNotificationServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test customers
        List<Customer__c> customers = TestDataFactory.createCustomers(2);
        
        // Create test products
        List<Product__c> products = TestDataFactory.createProducts(3);
        
        // Create test orders
        List<Order__c> orders = TestDataFactory.createOrders(customers, products, 5);
    }
    
    @isTest
    static void testSendStatusChangeNotification_Success() {
        // Get test data
        Order__c order = [SELECT Id, Status__c FROM Order__c LIMIT 1];
        
        Test.startTest();
        
        // Send status change notification
        OrderNotificationService.sendStatusChangeNotification(order.Id, 'Pending', 'Confirmed');
        
        Test.stopTest();
        
        // Verify notification was created
        List<Notification__c> notifications = [SELECT Id, Title__c, Type__c, Is_Read__c FROM Notification__c WHERE Related_Record_Id__c = :order.Id];
        System.assertEquals(1, notifications.size(), 'Notification should be created');
        System.assertEquals('Order Status Updated', notifications[0].Title__c, 'Title should be correct');
        System.assertEquals('Status Change', notifications[0].Type__c, 'Type should be correct');
        System.assertEquals(false, notifications[0].Is_Read__c, 'Notification should be unread');
    }
    
    @isTest
    static void testSendStatusChangeNotification_InvalidOrder() {
        Test.startTest();
        
        // Try to send notification for invalid order ID
        try {
            OrderNotificationService.sendStatusChangeNotification('001000000000000', 'Pending', 'Confirmed');
            // Should not throw exception but should handle gracefully
        } catch (Exception e) {
            System.assert(false, 'Should handle invalid order ID gracefully');
        }
        
        Test.stopTest();
        
        // Verify no notification was created
        List<Notification__c> notifications = [SELECT Id FROM Notification__c];
        System.assertEquals(0, notifications.size(), 'No notification should be created for invalid order');
    }
    
    @isTest
    static void testSendLowStockAlert_Success() {
        // Get test product
        Product__c product = [SELECT Id FROM Product__c LIMIT 1];
        
        Test.startTest();
        
        // Send low stock alert
        OrderNotificationService.sendLowStockAlert(product.Id, 5);
        
        Test.stopTest();
        
        // Verify notification was created
        List<Notification__c> notifications = [SELECT Id, Title__c, Type__c FROM Notification__c WHERE Related_Record_Id__c = :product.Id];
        System.assertEquals(1, notifications.size(), 'Low stock notification should be created');
        System.assertEquals('Low Stock Alert', notifications[0].Title__c, 'Title should be correct');
        System.assertEquals('Low Stock Alert', notifications[0].Type__c, 'Type should be correct');
    }
    
    @isTest
    static void testGetUserNotifications_Success() {
        // Create a test notification
        Notification__c notification = new Notification__c();
        notification.Title__c = 'Test Notification';
        notification.Message__c = 'Test message';
        notification.Type__c = 'Info';
        notification.User__c = UserInfo.getUserId();
        notification.Is_Read__c = false;
        insert notification;
        
        Test.startTest();
        
        // Get user notifications
        List<Notification__c> notifications = OrderNotificationService.getUserNotifications(UserInfo.getUserId());
        
        Test.stopTest();
        
        // Verify notifications
        System.assertNotEquals(null, notifications, 'Notifications should not be null');
        System.assert(notifications.size() > 0, 'Should have at least one notification');
        
        Boolean foundTestNotification = false;
        for (Notification__c notif : notifications) {
            if (notif.Title__c == 'Test Notification') {
                foundTestNotification = true;
                break;
            }
        }
        System.assert(foundTestNotification, 'Test notification should be found');
    }
    
    @isTest
    static void testMarkAsRead_Success() {
        // Create a test notification
        Notification__c notification = new Notification__c();
        notification.Title__c = 'Test Notification';
        notification.Message__c = 'Test message';
        notification.Type__c = 'Info';
        notification.User__c = UserInfo.getUserId();
        notification.Is_Read__c = false;
        insert notification;
        
        Test.startTest();
        
        // Mark as read
        OrderNotificationService.markAsRead(notification.Id);
        
        Test.stopTest();
        
        // Verify notification was marked as read
        Notification__c updatedNotification = [SELECT Is_Read__c FROM Notification__c WHERE Id = :notification.Id];
        System.assertEquals(true, updatedNotification.Is_Read__c, 'Notification should be marked as read');
    }
    
    @isTest
    static void testMarkAsRead_InvalidId() {
        Test.startTest();
        
        // Try to mark invalid notification as read
        try {
            OrderNotificationService.markAsRead('001000000000000');
            System.assert(false, 'Should throw exception for invalid notification ID');
        } catch (Exception e) {
            // Expected behavior
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testClearProcessedOrdersCache() {
        Test.startTest();
        
        // Clear cache
        OrderNotificationService.clearProcessedOrdersCache();
        
        Test.stopTest();
        
        // No assertions needed as this is just testing that no exception is thrown
    }
    
    @isTest
    static void testDuplicateNotificationPrevention() {
        // Get test data
        Order__c order = [SELECT Id FROM Order__c LIMIT 1];
        
        Test.startTest();
        
        // Send same notification twice
        OrderNotificationService.sendStatusChangeNotification(order.Id, 'Pending', 'Confirmed');
        OrderNotificationService.sendStatusChangeNotification(order.Id, 'Pending', 'Confirmed');
        
        Test.stopTest();
        
        // Verify only one notification was created (due to duplicate prevention)
        List<Notification__c> notifications = [SELECT Id FROM Notification__c WHERE Related_Record_Id__c = :order.Id];
        System.assertEquals(1, notifications.size(), 'Only one notification should be created due to duplicate prevention');
    }
}

/**
 * @description Test class for NotificationController
 * @author Junior Developer
 * @date 2024
 */
@isTest
public class NotificationControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test notifications
        List<Notification__c> notifications = new List<Notification__c>();
        
        for (Integer i = 0; i < 5; i++) {
            Notification__c notification = new Notification__c();
            notification.Title__c = 'Test Notification ' + i;
            notification.Message__c = 'Test message ' + i;
            notification.Type__c = 'Info';
            notification.User__c = UserInfo.getUserId();
            notification.Is_Read__c = (i % 2 == 0); // Half read, half unread
            notifications.add(notification);
        }
        
        insert notifications;
    }
    
    @isTest
    static void testGetNotifications_All() {
        Test.startTest();
        
        List<Notification__c> notifications = NotificationController.getNotifications(false);
        
        Test.stopTest();
        
        System.assertNotEquals(null, notifications, 'Notifications should not be null');
        System.assertEquals(5, notifications.size(), 'Should return all 5 notifications');
    }
    
    @isTest
    static void testGetNotifications_UnreadOnly() {
        Test.startTest();
        
        List<Notification__c> notifications = NotificationController.getNotifications(true);
        
        Test.stopTest();
        
        System.assertNotEquals(null, notifications, 'Notifications should not be null');
        System.assert(notifications.size() > 0, 'Should have unread notifications');
        
        // Verify all returned notifications are unread
        for (Notification__c notification : notifications) {
            System.assertEquals(false, notification.Is_Read__c, 'All notifications should be unread');
        }
    }
    
    @isTest
    static void testMarkNotificationAsRead_Success() {
        // Get an unread notification
        Notification__c notification = [SELECT Id FROM Notification__c WHERE Is_Read__c = false LIMIT 1];
        
        Test.startTest();
        
        NotificationController.markNotificationAsRead(notification.Id);
        
        Test.stopTest();
        
        // Verify notification was marked as read
        Notification__c updatedNotification = [SELECT Is_Read__c FROM Notification__c WHERE Id = :notification.Id];
        System.assertEquals(true, updatedNotification.Is_Read__c, 'Notification should be marked as read');
    }
    
    @isTest
    static void testMarkNotificationAsRead_InvalidId() {
        Test.startTest();
        
        try {
            NotificationController.markNotificationAsRead(null);
            System.assert(false, 'Should throw exception for null notification ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Notification ID is required'), 'Error message should mention required ID');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testMarkAllAsRead_Success() {
        Test.startTest();
        
        NotificationController.markAllAsRead();
        
        Test.stopTest();
        
        // Verify all notifications are marked as read
        List<Notification__c> notifications = [SELECT Is_Read__c FROM Notification__c WHERE User__c = :UserInfo.getUserId()];
        for (Notification__c notification : notifications) {
            System.assertEquals(true, notification.Is_Read__c, 'All notifications should be marked as read');
        }
    }
    
    @isTest
    static void testGetNotificationStats() {
        Test.startTest();
        
        Map<String, Object> stats = NotificationController.getNotificationStats();
        
        Test.stopTest();
        
        System.assertNotEquals(null, stats, 'Stats should not be null');
        System.assert(stats.containsKey('totalCount'), 'Should contain total count');
        System.assert(stats.containsKey('unreadCount'), 'Should contain unread count');
        System.assertEquals(5, stats.get('totalCount'), 'Total count should be 5');
    }
    
    @isTest
    static void testCreateNotification_Success() {
        Test.startTest();
        
        Notification__c notification = NotificationController.createNotification(
            'Test Title', 
            'Test Message', 
            'Info', 
            null
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, notification.Id, 'Notification should be created');
        System.assertEquals('Test Title', notification.Title__c, 'Title should be set correctly');
        System.assertEquals('Test Message', notification.Message__c, 'Message should be set correctly');
        System.assertEquals('Info', notification.Type__c, 'Type should be set correctly');
        System.assertEquals(false, notification.Is_Read__c, 'Should be unread by default');
    }
    
    @isTest
    static void testCreateNotification_InvalidTitle() {
        Test.startTest();
        
        try {
            NotificationController.createNotification(null, 'Test Message', 'Info', null);
            System.assert(false, 'Should throw exception for null title');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Title is required'), 'Error message should mention required title');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteOldNotifications() {
        // Create an old notification
        Notification__c oldNotification = new Notification__c();
        oldNotification.Title__c = 'Old Notification';
        oldNotification.Message__c = 'Old message';
        oldNotification.Type__c = 'Info';
        oldNotification.User__c = UserInfo.getUserId();
        oldNotification.Is_Read__c = false;
        insert oldNotification;
        
        // Update created date to be old (this is a test scenario)
        Test.setCreatedDate(oldNotification.Id, Date.today().addDays(-30));
        
        Test.startTest();
        
        Integer deletedCount = NotificationController.deleteOldNotifications(7);
        
        Test.stopTest();
        
        System.assertEquals(1, deletedCount, 'Should delete 1 old notification');
        
        // Verify old notification was deleted
        List<Notification__c> remainingNotifications = [SELECT Id FROM Notification__c WHERE Id = :oldNotification.Id];
        System.assertEquals(0, remainingNotifications.size(), 'Old notification should be deleted');
    }
    
    @isTest
    static void testDeleteOldNotifications_NoOldNotifications() {
        Test.startTest();
        
        Integer deletedCount = NotificationController.deleteOldNotifications(365);
        
        Test.stopTest();
        
        System.assertEquals(0, deletedCount, 'Should delete 0 notifications');
    }
}

/**
 * @description Controller class for Notification Lightning Web Components
 * @author Junior Developer
 * @date 2024
 */
public with sharing class NotificationController {
    
    /**
     * @description Gets notifications for the current user
     * @param showUnreadOnly Whether to show only unread notifications
     * @return List<Notification__c> List of notifications
     */
    @AuraEnabled(cacheable=true)
    public static List<Notification__c> getNotifications(Boolean showUnreadOnly) {
        try {
            // Junior dev mistake: Not handling null parameter properly
            String query = 'SELECT Id, Title__c, Message__c, Type__c, Is_Read__c, CreatedDate, Related_Record_Id__c FROM Notification__c WHERE User__c = :userId';
            
            if (showUnreadOnly) {
                query += ' AND Is_Read__c = false';
            }
            
            query += ' ORDER BY CreatedDate DESC LIMIT 100';
            
            Id userId = UserInfo.getUserId();
            
            // Junior dev mistake: Using dynamic query instead of proper SOQL
            return Database.query(query);
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve notifications: ' + e.getMessage());
        }
    }
    
    /**
     * @description Marks a notification as read
     * @param notificationId The ID of the notification
     */
    @AuraEnabled
    public static void markNotificationAsRead(Id notificationId) {
        try {
            if (notificationId == null) {
                throw new AuraHandledException('Notification ID is required');
            }
            
            // Junior dev mistake: Not checking if notification belongs to current user
            Notification__c notification = [SELECT Id, Is_Read__c FROM Notification__c WHERE Id = :notificationId LIMIT 1];
            notification.Is_Read__c = true;
            update notification;
            
        } catch (DmlException e) {
            throw new AuraHandledException('Database error: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Failed to mark notification as read: ' + e.getMessage());
        }
    }
    
    /**
     * @description Marks all notifications as read for the current user
     */
    @AuraEnabled
    public static void markAllAsRead() {
        try {
            Id userId = UserInfo.getUserId();
            
            // Junior dev mistake: Not using bulk operations properly
            List<Notification__c> notifications = [SELECT Id FROM Notification__c WHERE User__c = :userId AND Is_Read__c = false];
            
            for (Notification__c notification : notifications) {
                notification.Is_Read__c = true;
            }
            
            if (!notifications.isEmpty()) {
                update notifications;
            }
            
        } catch (DmlException e) {
            throw new AuraHandledException('Database error: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Failed to mark all notifications as read: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets notification statistics for the current user
     * @return Map<String, Object> Notification statistics
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getNotificationStats() {
        try {
            Id userId = UserInfo.getUserId();
            
            // Junior dev mistake: Not using aggregate queries efficiently
            List<AggregateResult> results = [
                SELECT COUNT(Id) totalCount, 
                       SUM(CASE WHEN Is_Read__c = false THEN 1 ELSE 0 END) unreadCount
                FROM Notification__c 
                WHERE User__c = :userId
            ];
            
            Map<String, Object> stats = new Map<String, Object>();
            
            if (!results.isEmpty()) {
                AggregateResult result = results[0];
                stats.put('totalCount', result.get('totalCount'));
                stats.put('unreadCount', result.get('unreadCount'));
            } else {
                stats.put('totalCount', 0);
                stats.put('unreadCount', 0);
            }
            
            return stats;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve notification statistics: ' + e.getMessage());
        }
    }
    
    /**
     * @description Creates a new notification
     * @param title The notification title
     * @param message The notification message
     * @param type The notification type
     * @param relatedRecordId The related record ID
     * @return Notification__c The created notification
     */
    @AuraEnabled
    public static Notification__c createNotification(String title, String message, String type, Id relatedRecordId) {
        try {
            // Junior dev mistake: Not validating input parameters properly
            if (String.isBlank(title)) {
                throw new AuraHandledException('Title is required');
            }
            
            Notification__c notification = new Notification__c();
            notification.Title__c = title;
            notification.Message__c = message;
            notification.Type__c = type;
            notification.Related_Record_Id__c = relatedRecordId;
            notification.User__c = UserInfo.getUserId();
            notification.Is_Read__c = false;
            
            insert notification;
            return notification;
            
        } catch (DmlException e) {
            throw new AuraHandledException('Database error: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Failed to create notification: ' + e.getMessage());
        }
    }
    
    /**
     * @description Deletes old notifications (cleanup method)
     * @param daysOld Number of days old to delete
     * @return Integer Number of notifications deleted
     */
    @AuraEnabled
    public static Integer deleteOldNotifications(Integer daysOld) {
        try {
            // Junior dev mistake: Not validating input parameter
            Date cutoffDate = Date.today().addDays(-daysOld);
            
            List<Notification__c> oldNotifications = [
                SELECT Id FROM Notification__c 
                WHERE User__c = :UserInfo.getUserId() 
                AND CreatedDate < :cutoffDate
            ];
            
            Integer deletedCount = oldNotifications.size();
            
            if (!oldNotifications.isEmpty()) {
                delete oldNotifications;
            }
            
            return deletedCount;
            
        } catch (DmlException e) {
            throw new AuraHandledException('Database error: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Failed to delete old notifications: ' + e.getMessage());
        }
    }
}

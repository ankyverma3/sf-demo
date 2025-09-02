/**
 * @description Utility class with common helper methods
 * @author Salesforce Demo
 * @date 2024
 */
public with sharing class Utility {
    
    /**
     * @description Formats currency values for display
     * @param amount The amount to format
     * @return String Formatted currency string
     */
    public static String formatCurrency(Decimal amount) {
        if (amount == null) {
            return '$0.00';
        }
        return '$' + String.valueOf(amount.setScale(2));
    }
    
    /**
     * @description Validates email format
     * @param email The email to validate
     * @return Boolean True if email is valid
     */
    public static Boolean isValidEmail(String email) {
        if (String.isBlank(email)) {
            return false;
        }
        
        String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        Pattern emailPattern = Pattern.compile(emailRegex);
        return emailPattern.matcher(email).matches();
    }
    
    /**
     * @description Generates a random string of specified length
     * @param length The length of the string to generate
     * @return String Random string
     */
    public static String generateRandomString(Integer length) {
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String result = '';
        
        for (Integer i = 0; i < length; i++) {
            Integer index = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            result += chars.substring(index, index + 1);
        }
        
        return result;
    }
    
    /**
     * @description Sends email notification
     * @param toAddresses List of recipient email addresses
     * @param subject Email subject
     * @param body Email body
     * @return Boolean True if email was sent successfully
     */
    public static Boolean sendEmailNotification(List<String> toAddresses, String subject, String body) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(toAddresses);
            email.setSubject(subject);
            email.setPlainTextBody(body);
            email.setSenderDisplayName('Salesforce Demo System');
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            return true;
            
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Logs debug information with timestamp
     * @param message The message to log
     * @param level The log level (DEBUG, INFO, WARN, ERROR)
     */
    public static void log(String message, String level) {
        String timestamp = DateTime.now().format('yyyy-MM-dd HH:mm:ss');
        String logMessage = '[' + timestamp + '] [' + level + '] ' + message;
        
        switch on level {
            when 'ERROR' {
                System.debug(LoggingLevel.ERROR, logMessage);
            }
            when 'WARN' {
                System.debug(LoggingLevel.WARN, logMessage);
            }
            when 'INFO' {
                System.debug(LoggingLevel.INFO, logMessage);
            }
            when else {
                System.debug(logMessage);
            }
        }
    }
    
    /**
     * @description Checks if user has permission to access a record
     * @param recordId The ID of the record to check
     * @param operation The operation (READ, EDIT, DELETE)
     * @return Boolean True if user has permission
     */
    public static Boolean hasRecordAccess(Id recordId, String operation) {
        try {
            String objectType = recordId.getSObjectType().getDescribe().getName();
            DescribeSObjectResult objectDescribe = recordId.getSObjectType().getDescribe();
            
            switch on operation {
                when 'READ' {
                    return objectDescribe.isAccessible();
                }
                when 'EDIT' {
                    return objectDescribe.isUpdateable();
                }
                when 'DELETE' {
                    return objectDescribe.isDeletable();
                }
                when else {
                    return false;
                }
            }
        } catch (Exception e) {
            System.debug('Error checking record access: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Converts a list of IDs to a comma-separated string
     * @param idList List of IDs to convert
     * @return String Comma-separated string of IDs
     */
    public static String convertIdListToString(List<Id> idList) {
        if (idList == null || idList.isEmpty()) {
            return '';
        }
        
        List<String> stringList = new List<String>();
        for (Id recordId : idList) {
            stringList.add(String.valueOf(recordId));
        }
        
        return String.join(stringList, ',');
    }
    
    /**
     * @description Gets the current user's profile name
     * @return String The profile name
     */
    public static String getCurrentUserProfile() {
        try {
            User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            return currentUser.Profile.Name;
        } catch (Exception e) {
            System.debug('Error getting user profile: ' + e.getMessage());
            return 'Unknown';
        }
    }
    
    /**
     * @description Checks if the current user is a system administrator
     * @return Boolean True if user is system admin
     */
    public static Boolean isSystemAdmin() {
        return getCurrentUserProfile() == 'System Administrator';
    }
}

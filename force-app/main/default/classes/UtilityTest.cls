/**
 * @description Test class for Utility
 * @author Salesforce Demo
 * @date 2024
 */
@isTest
public class UtilityTest {
    
    @isTest
    static void testFormatCurrency() {
        Test.startTest();
        
        // Test with valid amount
        String formatted = Utility.formatCurrency(123.45);
        System.assertEquals('$123.45', formatted, 'Currency should be formatted correctly');
        
        // Test with null amount
        String nullFormatted = Utility.formatCurrency(null);
        System.assertEquals('$0.00', nullFormatted, 'Null amount should return $0.00');
        
        // Test with zero
        String zeroFormatted = Utility.formatCurrency(0);
        System.assertEquals('$0.00', zeroFormatted, 'Zero should be formatted as $0.00');
        
        // Test with large amount
        String largeFormatted = Utility.formatCurrency(1234567.89);
        System.assertEquals('$1234567.89', largeFormatted, 'Large amount should be formatted correctly');
        
        Test.stopTest();
    }
    
    @isTest
    static void testIsValidEmail() {
        Test.startTest();
        
        // Test valid emails
        System.assert(Utility.isValidEmail('test@example.com'), 'Valid email should return true');
        System.assert(Utility.isValidEmail('user.name@domain.co.uk'), 'Valid email with dots should return true');
        System.assert(Utility.isValidEmail('user+tag@example.org'), 'Valid email with plus should return true');
        
        // Test invalid emails
        System.assert(!Utility.isValidEmail(''), 'Empty string should return false');
        System.assert(!Utility.isValidEmail(null), 'Null should return false');
        System.assert(!Utility.isValidEmail('invalid-email'), 'Invalid email format should return false');
        System.assert(!Utility.isValidEmail('test@'), 'Incomplete email should return false');
        System.assert(!Utility.isValidEmail('@example.com'), 'Email without local part should return false');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGenerateRandomString() {
        Test.startTest();
        
        // Test different lengths
        String shortString = Utility.generateRandomString(5);
        System.assertEquals(5, shortString.length(), 'String should have correct length');
        
        String longString = Utility.generateRandomString(20);
        System.assertEquals(20, longString.length(), 'String should have correct length');
        
        // Test that strings are different
        String string1 = Utility.generateRandomString(10);
        String string2 = Utility.generateRandomString(10);
        // Note: There's a small chance they could be the same, but it's very unlikely
        System.assertNotEquals(string1, string2, 'Random strings should be different');
        
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailNotification() {
        Test.startTest();
        
        // Test with valid parameters
        List<String> toAddresses = new List<String>{'test@example.com'};
        String subject = 'Test Subject';
        String body = 'Test Body';
        
        Boolean result = Utility.sendEmailNotification(toAddresses, subject, body);
        // Note: In a test context, email sending might be disabled, so we just verify no exception is thrown
        System.assertNotEquals(null, result, 'Result should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testLog() {
        Test.startTest();
        
        // Test different log levels
        Utility.log('Test message', 'DEBUG');
        Utility.log('Test message', 'INFO');
        Utility.log('Test message', 'WARN');
        Utility.log('Test message', 'ERROR');
        Utility.log('Test message', 'UNKNOWN');
        
        // No assertions needed as this is just testing that no exceptions are thrown
        Test.stopTest();
    }
    
    @isTest
    static void testHasRecordAccess() {
        Test.startTest();
        
        // Create a test record
        Customer__c customer = TestDataFactory.createSingleCustomer('Individual', 'test@example.com', '1234567890');
        
        // Test record access
        Boolean hasReadAccess = Utility.hasRecordAccess(customer.Id, 'READ');
        System.assert(hasReadAccess, 'Should have read access to created record');
        
        Boolean hasEditAccess = Utility.hasRecordAccess(customer.Id, 'EDIT');
        System.assert(hasEditAccess, 'Should have edit access to created record');
        
        Boolean hasDeleteAccess = Utility.hasRecordAccess(customer.Id, 'DELETE');
        System.assert(hasDeleteAccess, 'Should have delete access to created record');
        
        // Test invalid operation
        Boolean invalidAccess = Utility.hasRecordAccess(customer.Id, 'INVALID');
        System.assert(!invalidAccess, 'Should not have access for invalid operation');
        
        Test.stopTest();
    }
    
    @isTest
    static void testConvertIdListToString() {
        Test.startTest();
        
        // Create test records
        List<Customer__c> customers = TestDataFactory.createCustomers(3);
        List<Id> customerIds = new List<Id>();
        for (Customer__c customer : customers) {
            customerIds.add(customer.Id);
        }
        
        // Test conversion
        String idString = Utility.convertIdListToString(customerIds);
        System.assertNotEquals('', idString, 'ID string should not be empty');
        System.assert(idString.contains(','), 'ID string should contain commas for multiple IDs');
        
        // Test with null list
        String nullString = Utility.convertIdListToString(null);
        System.assertEquals('', nullString, 'Null list should return empty string');
        
        // Test with empty list
        String emptyString = Utility.convertIdListToString(new List<Id>());
        System.assertEquals('', emptyString, 'Empty list should return empty string');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetCurrentUserProfile() {
        Test.startTest();
        
        String profile = Utility.getCurrentUserProfile();
        System.assertNotEquals(null, profile, 'Profile should not be null');
        System.assertNotEquals('Unknown', profile, 'Profile should be retrieved successfully');
        
        Test.stopTest();
    }
    
    @isTest
    static void testIsSystemAdmin() {
        Test.startTest();
        
        Boolean isAdmin = Utility.isSystemAdmin();
        // In test context, this might be true or false depending on the running user
        System.assertNotEquals(null, isAdmin, 'isSystemAdmin should return a boolean value');
        
        Test.stopTest();
    }
}

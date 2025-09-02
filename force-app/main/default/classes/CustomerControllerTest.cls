/**
 * @description Test class for CustomerController
 * @author Salesforce Demo
 * @date 2024
 */
@isTest
public class CustomerControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test customers
        List<Customer__c> customers = TestDataFactory.createCustomers(5);
        
        // Create test products
        List<Product__c> products = TestDataFactory.createProducts(3);
        
        // Create test orders
        List<Order__c> orders = TestDataFactory.createOrders(customers, products, 10);
    }
    
    @isTest
    static void testGetCustomers() {
        Test.startTest();
        
        List<Customer__c> customers = CustomerController.getCustomers();
        
        Test.stopTest();
        
        System.assertNotEquals(null, customers, 'Customers list should not be null');
        System.assertEquals(5, customers.size(), 'Should return 5 customers');
        
        for (Customer__c customer : customers) {
            System.assertNotEquals(null, customer.Id, 'Customer should have an ID');
            System.assertNotEquals(null, customer.Name, 'Customer should have a name');
        }
    }
    
    @isTest
    static void testCreateCustomer_Success() {
        Test.startTest();
        
        Map<String, Object> customerData = new Map<String, Object>{
            'Customer_Type__c' => 'Business',
            'Email__c' => 'newcustomer@example.com',
            'Phone__c' => '9876543210'
        };
        
        Customer__c customer = CustomerController.createCustomer(customerData);
        
        Test.stopTest();
        
        System.assertNotEquals(null, customer.Id, 'Customer should be created');
        System.assertEquals('Business', customer.Customer_Type__c, 'Customer type should be set correctly');
        System.assertEquals('newcustomer@example.com', customer.Email__c, 'Email should be set correctly');
        System.assertEquals('9876543210', customer.Phone__c, 'Phone should be set correctly');
    }
    
    @isTest
    static void testCreateCustomer_InvalidData() {
        Test.startTest();
        
        // Test with null data
        try {
            CustomerController.createCustomer(null);
            System.assert(false, 'Exception should have been thrown for null data');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Customer data is required'), 'Error message should mention required data');
        }
        
        // Test with empty data
        try {
            CustomerController.createCustomer(new Map<String, Object>());
            System.assert(false, 'Exception should have been thrown for empty data');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Customer type is required'), 'Error message should mention required customer type');
        }
        
        // Test with invalid email
        Map<String, Object> invalidEmailData = new Map<String, Object>{
            'Customer_Type__c' => 'Individual',
            'Email__c' => 'invalid-email',
            'Phone__c' => '1234567890'
        };
        
        try {
            CustomerController.createCustomer(invalidEmailData);
            System.assert(false, 'Exception should have been thrown for invalid email');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('valid email address'), 'Error message should mention valid email');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetCustomerById_Success() {
        // Get test customer
        Customer__c testCustomer = [SELECT Id FROM Customer__c LIMIT 1];
        
        Test.startTest();
        
        Customer__c customer = CustomerController.getCustomerById(testCustomer.Id);
        
        Test.stopTest();
        
        System.assertNotEquals(null, customer, 'Customer should be returned');
        System.assertEquals(testCustomer.Id, customer.Id, 'Customer ID should match');
    }
    
    @isTest
    static void testGetCustomerById_InvalidId() {
        Test.startTest();
        
        try {
            CustomerController.getCustomerById(null);
            System.assert(false, 'Exception should have been thrown for null ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Customer ID is required'), 'Error message should mention required ID');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateCustomer_Success() {
        // Get test customer
        Customer__c testCustomer = [SELECT Id FROM Customer__c LIMIT 1];
        
        Test.startTest();
        
        Map<String, Object> updateData = new Map<String, Object>{
            'Customer_Type__c' => 'Enterprise',
            'Email__c' => 'updated@example.com',
            'Phone__c' => '5555555555'
        };
        
        Customer__c updatedCustomer = CustomerController.updateCustomer(testCustomer.Id, updateData);
        
        Test.stopTest();
        
        System.assertEquals('Enterprise', updatedCustomer.Customer_Type__c, 'Customer type should be updated');
        System.assertEquals('updated@example.com', updatedCustomer.Email__c, 'Email should be updated');
        System.assertEquals('5555555555', updatedCustomer.Phone__c, 'Phone should be updated');
    }
    
    @isTest
    static void testGetCustomerOrders() {
        // Get test customer
        Customer__c testCustomer = [SELECT Id FROM Customer__c LIMIT 1];
        
        Test.startTest();
        
        List<Order__c> orders = CustomerController.getCustomerOrders(testCustomer.Id);
        
        Test.stopTest();
        
        System.assertNotEquals(null, orders, 'Orders list should not be null');
        
        for (Order__c order : orders) {
            System.assertEquals(testCustomer.Id, order.Customer__c, 'All orders should belong to the customer');
        }
    }
    
    @isTest
    static void testSearchCustomers() {
        Test.startTest();
        
        // Search with empty term
        List<Customer__c> allCustomers = CustomerController.searchCustomers('');
        System.assertEquals(5, allCustomers.size(), 'Should return all customers for empty search');
        
        // Search with null term
        List<Customer__c> nullSearchCustomers = CustomerController.searchCustomers(null);
        System.assertEquals(5, nullSearchCustomers.size(), 'Should return all customers for null search');
        
        // Search with specific term
        List<Customer__c> searchResults = CustomerController.searchCustomers('testcustomer');
        System.assert(searchResults.size() > 0, 'Should return results for valid search term');
        
        Test.stopTest();
    }
}

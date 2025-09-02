/**
 * @description Controller class for Customer Lightning Web Components
 * @author Salesforce Demo
 * @date 2024
 */
public with sharing class CustomerController {
    
    /**
     * @description Gets all customers with their order statistics
     * @return List<Customer__c> List of customers
     */
    @AuraEnabled(cacheable=true)
    public static List<Customer__c> getCustomers() {
        try {
            return [
                SELECT Id, Name, Customer_Type__c, Email__c, Phone__c, 
                       Total_Orders__c, Total_Revenue__c, CreatedDate
                FROM Customer__c 
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve customers: ' + e.getMessage());
        }
    }
    
    /**
     * @description Creates a new customer
     * @param customerData Map containing customer data
     * @return Customer__c The created customer
     */
    @AuraEnabled
    public static Customer__c createCustomer(Map<String, Object> customerData) {
        try {
            // Validate input data
            if (customerData == null || customerData.isEmpty()) {
                throw new AuraHandledException('Customer data is required');
            }
            
            // Create customer record
            Customer__c customer = new Customer__c();
            customer.Customer_Type__c = (String)customerData.get('Customer_Type__c');
            customer.Email__c = (String)customerData.get('Email__c');
            customer.Phone__c = (String)customerData.get('Phone__c');
            
            // Validate required fields
            if (String.isBlank(customer.Customer_Type__c)) {
                throw new AuraHandledException('Customer type is required');
            }
            if (String.isBlank(customer.Email__c)) {
                throw new AuraHandledException('Email is required');
            }
            
            // Validate email format
            if (!Utility.isValidEmail(customer.Email__c)) {
                throw new AuraHandledException('Please enter a valid email address');
            }
            
            insert customer;
            return customer;
            
        } catch (DmlException e) {
            throw new AuraHandledException('Database error: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Failed to create customer: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets customer details by ID
     * @param customerId The ID of the customer
     * @return Customer__c The customer record
     */
    @AuraEnabled(cacheable=true)
    public static Customer__c getCustomerById(Id customerId) {
        try {
            if (customerId == null) {
                throw new AuraHandledException('Customer ID is required');
            }
            
            List<Customer__c> customers = [
                SELECT Id, Name, Customer_Type__c, Email__c, Phone__c, 
                       Total_Orders__c, Total_Revenue__c, CreatedDate
                FROM Customer__c 
                WHERE Id = :customerId 
                LIMIT 1
            ];
            
            if (customers.isEmpty()) {
                throw new AuraHandledException('Customer not found');
            }
            
            return customers[0];
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve customer: ' + e.getMessage());
        }
    }
    
    /**
     * @description Updates customer information
     * @param customerId The ID of the customer to update
     * @param customerData Map containing updated customer data
     * @return Customer__c The updated customer
     */
    @AuraEnabled
    public static Customer__c updateCustomer(Id customerId, Map<String, Object> customerData) {
        try {
            if (customerId == null) {
                throw new AuraHandledException('Customer ID is required');
            }
            
            if (customerData == null || customerData.isEmpty()) {
                throw new AuraHandledException('Customer data is required');
            }
            
            // Get existing customer
            Customer__c customer = getCustomerById(customerId);
            
            // Update fields
            if (customerData.containsKey('Customer_Type__c')) {
                customer.Customer_Type__c = (String)customerData.get('Customer_Type__c');
            }
            if (customerData.containsKey('Email__c')) {
                String email = (String)customerData.get('Email__c');
                if (!Utility.isValidEmail(email)) {
                    throw new AuraHandledException('Please enter a valid email address');
                }
                customer.Email__c = email;
            }
            if (customerData.containsKey('Phone__c')) {
                customer.Phone__c = (String)customerData.get('Phone__c');
            }
            
            update customer;
            return customer;
            
        } catch (DmlException e) {
            throw new AuraHandledException('Database error: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Failed to update customer: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets customer orders
     * @param customerId The ID of the customer
     * @return List<Order__c> List of customer orders
     */
    @AuraEnabled(cacheable=true)
    public static List<Order__c> getCustomerOrders(Id customerId) {
        try {
            if (customerId == null) {
                throw new AuraHandledException('Customer ID is required');
            }
            
            return [
                SELECT Id, Name, Product__c, Product__r.Name, Product__r.SKU__c,
                       Quantity__c, Unit_Price__c, Total_Amount__c, Status__c, CreatedDate
                FROM Order__c 
                WHERE Customer__c = :customerId 
                ORDER BY CreatedDate DESC
            ];
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve customer orders: ' + e.getMessage());
        }
    }
    
    /**
     * @description Searches customers by name or email
     * @param searchTerm The search term
     * @return List<Customer__c> List of matching customers
     */
    @AuraEnabled(cacheable=true)
    public static List<Customer__c> searchCustomers(String searchTerm) {
        try {
            if (String.isBlank(searchTerm)) {
                return getCustomers();
            }
            
            String searchPattern = '%' + searchTerm + '%';
            
            return [
                SELECT Id, Name, Customer_Type__c, Email__c, Phone__c, 
                       Total_Orders__c, Total_Revenue__c, CreatedDate
                FROM Customer__c 
                WHERE Name LIKE :searchPattern 
                   OR Email__c LIKE :searchPattern
                ORDER BY CreatedDate DESC
                LIMIT 50
            ];
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to search customers: ' + e.getMessage());
        }
    }
}

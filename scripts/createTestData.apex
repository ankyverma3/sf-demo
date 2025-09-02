// Create Test Data for Salesforce Demo Project
// This script creates sample data for demonstration purposes

System.debug('Creating test data for Salesforce Demo Project...');

try {
    // Create customers
    List<Customer__c> customers = new List<Customer__c>();
    
    customers.add(new Customer__c(
        Customer_Type__c = 'Individual',
        Email__c = 'john.doe@example.com',
        Phone__c = '+1-555-0101'
    ));
    
    customers.add(new Customer__c(
        Customer_Type__c = 'Business',
        Email__c = 'contact@acmecorp.com',
        Phone__c = '+1-555-0102'
    ));
    
    customers.add(new Customer__c(
        Customer_Type__c = 'Enterprise',
        Email__c = 'enterprise@bigcorp.com',
        Phone__c = '+1-555-0103'
    ));
    
    insert customers;
    System.debug('Created ' + customers.size() + ' customers');
    
    // Create products
    List<Product__c> products = new List<Product__c>();
    
    products.add(new Product__c(
        Name = 'Wireless Headphones',
        Category__c = 'Electronics',
        Price__c = 199.99,
        Stock_Quantity__c = 50,
        SKU__c = 'WH-001',
        Description__c = 'High-quality wireless headphones with noise cancellation'
    ));
    
    products.add(new Product__c(
        Name = 'Cotton T-Shirt',
        Category__c = 'Clothing',
        Price__c = 24.99,
        Stock_Quantity__c = 100,
        SKU__c = 'CT-001',
        Description__c = 'Comfortable cotton t-shirt in various colors'
    ));
    
    products.add(new Product__c(
        Name = 'Programming Book',
        Category__c = 'Books',
        Price__c = 49.99,
        Stock_Quantity__c = 25,
        SKU__c = 'PB-001',
        Description__c = 'Comprehensive guide to modern programming practices'
    ));
    
    products.add(new Product__c(
        Name = 'Garden Tools Set',
        Category__c = 'Home & Garden',
        Price__c = 79.99,
        Stock_Quantity__c = 15,
        SKU__c = 'GT-001',
        Description__c = 'Complete set of essential garden tools'
    ));
    
    products.add(new Product__c(
        Name = 'Smartphone',
        Category__c = 'Electronics',
        Price__c = 699.99,
        Stock_Quantity__c = 30,
        SKU__c = 'SP-001',
        Description__c = 'Latest generation smartphone with advanced features'
    ));
    
    insert products;
    System.debug('Created ' + products.size() + ' products');
    
    // Create some sample orders
    List<Order__c> orders = new List<Order__c>();
    
    orders.add(new Order__c(
        Customer__c = customers[0].Id,
        Product__c = products[0].Id,
        Quantity__c = 1,
        Unit_Price__c = products[0].Price__c,
        Total_Amount__c = products[0].Price__c,
        Status__c = 'Delivered'
    ));
    
    orders.add(new Order__c(
        Customer__c = customers[1].Id,
        Product__c = products[1].Id,
        Quantity__c = 5,
        Unit_Price__c = products[1].Price__c,
        Total_Amount__c = products[1].Price__c * 5,
        Status__c = 'Shipped'
    ));
    
    orders.add(new Order__c(
        Customer__c = customers[2].Id,
        Product__c = products[4].Id,
        Quantity__c = 2,
        Unit_Price__c = products[4].Price__c,
        Total_Amount__c = products[4].Price__c * 2,
        Status__c = 'Confirmed'
    ));
    
    insert orders;
    System.debug('Created ' + orders.size() + ' orders');
    
    // Create some test notifications
    List<Notification__c> notifications = new List<Notification__c>();
    
    notifications.add(new Notification__c(
        Title__c = 'Welcome to Salesforce Demo',
        Message__c = 'Welcome to the Salesforce Demo application! Explore the features and functionality.',
        Type__c = 'Info',
        User__c = UserInfo.getUserId(),
        Is_Read__c = false
    ));
    
    notifications.add(new Notification__c(
        Title__c = 'System Maintenance',
        Message__c = 'Scheduled system maintenance will occur tonight from 2 AM to 4 AM EST.',
        Type__c = 'Info',
        User__c = UserInfo.getUserId(),
        Is_Read__c = true
    ));
    
    insert notifications;
    System.debug('Created ' + notifications.size() + ' notifications');
    
    System.debug('✅ Test data creation completed successfully!');
    System.debug('📊 Summary:');
    System.debug('- Customers: ' + customers.size());
    System.debug('- Products: ' + products.size());
    System.debug('- Orders: ' + orders.size());
    System.debug('- Notifications: ' + notifications.size());
    
} catch (Exception e) {
    System.debug('❌ Error creating test data: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

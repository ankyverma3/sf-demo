/**
 * @description Factory class for creating test data
 * @author Salesforce Demo
 * @date 2024
 */
@isTest
public class TestDataFactory {
    
    /**
     * @description Creates test customers
     * @param count Number of customers to create
     * @return List<Customer__c> List of created customers
     */
    public static List<Customer__c> createCustomers(Integer count) {
        List<Customer__c> customers = new List<Customer__c>();
        
        for (Integer i = 0; i < count; i++) {
            Customer__c customer = new Customer__c();
            customer.Customer_Type__c = getRandomCustomerType();
            customer.Email__c = 'testcustomer' + i + '@example.com';
            customer.Phone__c = '+123456789' + String.valueOf(i).leftPad(2, '0');
            customers.add(customer);
        }
        
        insert customers;
        return customers;
    }
    
    /**
     * @description Creates test products
     * @param count Number of products to create
     * @return List<Product__c> List of created products
     */
    public static List<Product__c> createProducts(Integer count) {
        List<Product__c> products = new List<Product__c>();
        
        for (Integer i = 0; i < count; i++) {
            Product__c product = new Product__c();
            product.Name = 'Test Product ' + i;
            product.Category__c = getRandomCategory();
            product.Price__c = Math.random() * 1000 + 10; // Random price between 10 and 1010
            product.Stock_Quantity__c = Math.mod(i, 100) + 1; // Stock between 1 and 100
            product.SKU__c = 'SKU-' + String.valueOf(i).leftPad(5, '0');
            product.Description__c = 'Test product description for product ' + i;
            products.add(product);
        }
        
        insert products;
        return products;
    }
    
    /**
     * @description Creates test orders
     * @param customers List of customers
     * @param products List of products
     * @param count Number of orders to create
     * @return List<Order__c> List of created orders
     */
    public static List<Order__c> createOrders(List<Customer__c> customers, List<Product__c> products, Integer count) {
        List<Order__c> orders = new List<Order__c>();
        
        for (Integer i = 0; i < count; i++) {
            Order__c order = new Order__c();
            order.Customer__c = customers[Math.mod(i, customers.size())].Id;
            order.Product__c = products[Math.mod(i, products.size())].Id;
            order.Quantity__c = Math.mod(i, 10) + 1; // Quantity between 1 and 10
            order.Unit_Price__c = products[Math.mod(i, products.size())].Price__c;
            order.Total_Amount__c = order.Quantity__c * order.Unit_Price__c;
            order.Status__c = getRandomOrderStatus();
            orders.add(order);
        }
        
        insert orders;
        return orders;
    }
    
    /**
     * @description Creates a complete test scenario with customers, products, and orders
     * @return Map<String, List<SObject>> Map containing all created test data
     */
    public static Map<String, List<SObject>> createCompleteTestScenario() {
        Map<String, List<SObject>> testData = new Map<String, List<SObject>>();
        
        // Create test data
        List<Customer__c> customers = createCustomers(5);
        List<Product__c> products = createProducts(10);
        List<Order__c> orders = createOrders(customers, products, 15);
        
        // Add to map
        testData.put('customers', customers);
        testData.put('products', products);
        testData.put('orders', orders);
        
        return testData;
    }
    
    /**
     * @description Creates a single customer with specific data
     * @param customerType The type of customer
     * @param email The email address
     * @param phone The phone number
     * @return Customer__c The created customer
     */
    public static Customer__c createSingleCustomer(String customerType, String email, String phone) {
        Customer__c customer = new Customer__c();
        customer.Customer_Type__c = customerType;
        customer.Email__c = email;
        customer.Phone__c = phone;
        
        insert customer;
        return customer;
    }
    
    /**
     * @description Creates a single product with specific data
     * @param name The product name
     * @param category The product category
     * @param price The product price
     * @param stock The stock quantity
     * @return Product__c The created product
     */
    public static Product__c createSingleProduct(String name, String category, Decimal price, Integer stock) {
        Product__c product = new Product__c();
        product.Name = name;
        product.Category__c = category;
        product.Price__c = price;
        product.Stock_Quantity__c = stock;
        product.SKU__c = 'SKU-' + Utility.generateRandomString(8);
        product.Description__c = 'Test product: ' + name;
        
        insert product;
        return product;
    }
    
    /**
     * @description Creates a single order with specific data
     * @param customerId The customer ID
     * @param productId The product ID
     * @param quantity The quantity
     * @param status The order status
     * @return Order__c The created order
     */
    public static Order__c createSingleOrder(Id customerId, Id productId, Integer quantity, String status) {
        Product__c product = [SELECT Price__c FROM Product__c WHERE Id = :productId LIMIT 1];
        
        Order__c order = new Order__c();
        order.Customer__c = customerId;
        order.Product__c = productId;
        order.Quantity__c = quantity;
        order.Unit_Price__c = product.Price__c;
        order.Total_Amount__c = product.Price__c * quantity;
        order.Status__c = status;
        
        insert order;
        return order;
    }
    
    /**
     * @description Private method to get random customer type
     * @return String Random customer type
     */
    private static String getRandomCustomerType() {
        List<String> types = new List<String>{'Individual', 'Business', 'Enterprise'};
        return types[Math.mod(Math.abs(Crypto.getRandomInteger()), types.size())];
    }
    
    /**
     * @description Private method to get random product category
     * @return String Random product category
     */
    private static String getRandomCategory() {
        List<String> categories = new List<String>{'Electronics', 'Clothing', 'Books', 'Home & Garden'};
        return categories[Math.mod(Math.abs(Crypto.getRandomInteger()), categories.size())];
    }
    
    /**
     * @description Private method to get random order status
     * @return String Random order status
     */
    private static String getRandomOrderStatus() {
        List<String> statuses = new List<String>{'Pending', 'Confirmed', 'Shipped', 'Delivered'};
        return statuses[Math.mod(Math.abs(Crypto.getRandomInteger()), statuses.size())];
    }
}

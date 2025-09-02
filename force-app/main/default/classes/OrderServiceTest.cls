/**
 * @description Test class for OrderService
 * @author Salesforce Demo
 * @date 2024
 */
@isTest
public class OrderServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test customers
        List<Customer__c> customers = TestDataFactory.createCustomers(3);
        
        // Create test products
        List<Product__c> products = TestDataFactory.createProducts(5);
        
        // Create test orders
        List<Order__c> orders = TestDataFactory.createOrders(customers, products, 10);
    }
    
    @isTest
    static void testCreateOrder_Success() {
        // Get test data
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        Product__c product = [SELECT Id, Price__c, Stock_Quantity__c FROM Product__c LIMIT 1];
        
        Test.startTest();
        
        // Create order
        Order__c order = OrderService.createOrder(customer.Id, product.Id, 2);
        
        Test.stopTest();
        
        // Verify order was created
        System.assertNotEquals(null, order.Id, 'Order should be created');
        System.assertEquals(customer.Id, order.Customer__c, 'Customer should be set correctly');
        System.assertEquals(product.Id, order.Product__c, 'Product should be set correctly');
        System.assertEquals(2, order.Quantity__c, 'Quantity should be set correctly');
        System.assertEquals(product.Price__c, order.Unit_Price__c, 'Unit price should match product price');
        System.assertEquals(product.Price__c * 2, order.Total_Amount__c, 'Total amount should be calculated correctly');
        System.assertEquals('Pending', order.Status__c, 'Status should be Pending');
        
        // Verify stock was updated
        Product__c updatedProduct = [SELECT Stock_Quantity__c FROM Product__c WHERE Id = :product.Id];
        System.assertEquals(product.Stock_Quantity__c - 2, updatedProduct.Stock_Quantity__c, 'Stock should be reduced');
        
        // Verify customer totals were updated
        Customer__c updatedCustomer = [SELECT Total_Orders__c, Total_Revenue__c FROM Customer__c WHERE Id = :customer.Id];
        System.assertEquals(1, updatedCustomer.Total_Orders__c, 'Total orders should be 1');
        System.assertEquals(product.Price__c * 2, updatedCustomer.Total_Revenue__c, 'Total revenue should be calculated correctly');
    }
    
    @isTest
    static void testCreateOrder_InsufficientStock() {
        // Get test data
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        Product__c product = [SELECT Id, Stock_Quantity__c FROM Product__c LIMIT 1];
        
        Test.startTest();
        
        // Try to create order with quantity exceeding stock
        try {
            OrderService.createOrder(customer.Id, product.Id, (Integer)product.Stock_Quantity__c + 10);
            System.assert(false, 'Exception should have been thrown for insufficient stock');
        } catch (OrderService.OrderServiceException e) {
            System.assert(e.getMessage().contains('Insufficient stock'), 'Error message should mention insufficient stock');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testCreateOrder_InvalidInputs() {
        // Get test data
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        Product__c product = [SELECT Id FROM Product__c LIMIT 1];
        
        Test.startTest();
        
        // Test null customer ID
        try {
            OrderService.createOrder(null, product.Id, 1);
            System.assert(false, 'Exception should have been thrown for null customer ID');
        } catch (OrderService.OrderServiceException e) {
            System.assert(e.getMessage().contains('Invalid input parameters'), 'Error message should mention invalid parameters');
        }
        
        // Test null product ID
        try {
            OrderService.createOrder(customer.Id, null, 1);
            System.assert(false, 'Exception should have been thrown for null product ID');
        } catch (OrderService.OrderServiceException e) {
            System.assert(e.getMessage().contains('Invalid input parameters'), 'Error message should mention invalid parameters');
        }
        
        // Test zero quantity
        try {
            OrderService.createOrder(customer.Id, product.Id, 0);
            System.assert(false, 'Exception should have been thrown for zero quantity');
        } catch (OrderService.OrderServiceException e) {
            System.assert(e.getMessage().contains('Invalid input parameters'), 'Error message should mention invalid parameters');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateOrderStatus_Success() {
        // Get test data
        Order__c order = [SELECT Id, Status__c FROM Order__c LIMIT 1];
        
        Test.startTest();
        
        // Update order status
        OrderService.updateOrderStatus(order.Id, 'Confirmed');
        
        Test.stopTest();
        
        // Verify status was updated
        Order__c updatedOrder = [SELECT Status__c FROM Order__c WHERE Id = :order.Id];
        System.assertEquals('Confirmed', updatedOrder.Status__c, 'Status should be updated to Confirmed');
    }
    
    @isTest
    static void testUpdateOrderStatus_Cancelled() {
        // Get test data
        Order__c order = [SELECT Id, Product__c, Quantity__c FROM Order__c LIMIT 1];
        Product__c product = [SELECT Id, Stock_Quantity__c FROM Product__c WHERE Id = :order.Product__c];
        Decimal originalStock = product.Stock_Quantity__c;
        
        Test.startTest();
        
        // Cancel order
        OrderService.updateOrderStatus(order.Id, 'Cancelled');
        
        Test.stopTest();
        
        // Verify stock was restored
        Product__c updatedProduct = [SELECT Stock_Quantity__c FROM Product__c WHERE Id = :product.Id];
        System.assertEquals(originalStock + order.Quantity__c, updatedProduct.Stock_Quantity__c, 'Stock should be restored when order is cancelled');
    }
    
    @isTest
    static void testGetOrderDetails_Success() {
        // Get test data
        Order__c order = [SELECT Id FROM Order__c LIMIT 1];
        
        Test.startTest();
        
        // Get order details
        Order__c orderDetails = OrderService.getOrderDetails(order.Id);
        
        Test.stopTest();
        
        // Verify order details
        System.assertNotEquals(null, orderDetails, 'Order details should be returned');
        System.assertEquals(order.Id, orderDetails.Id, 'Order ID should match');
        System.assertNotEquals(null, orderDetails.Customer__c, 'Customer should be populated');
        System.assertNotEquals(null, orderDetails.Product__c, 'Product should be populated');
    }
    
    @isTest
    static void testGetCustomerOrders_Success() {
        // Get test data
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        
        Test.startTest();
        
        // Get customer orders
        List<Order__c> orders = OrderService.getCustomerOrders(customer.Id);
        
        Test.stopTest();
        
        // Verify orders
        System.assertNotEquals(null, orders, 'Orders list should not be null');
        System.assert(orders.size() > 0, 'Should have at least one order');
        
        for (Order__c order : orders) {
            System.assertEquals(customer.Id, order.Customer__c, 'All orders should belong to the customer');
        }
    }
    
    @isTest
    static void testGetOrderDetails_InvalidId() {
        Test.startTest();
        
        // Try to get order with invalid ID
        try {
            OrderService.getOrderDetails('001000000000000');
            System.assert(false, 'Exception should have been thrown for invalid order ID');
        } catch (OrderService.OrderServiceException e) {
            System.assert(e.getMessage().contains('Failed to get order details'), 'Error message should mention failure to get order details');
        }
        
        Test.stopTest();
    }
}

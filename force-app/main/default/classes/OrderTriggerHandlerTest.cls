/**
 * @description Test class for OrderTriggerHandler
 * @author Salesforce Demo
 * @date 2024
 */
@isTest
public class OrderTriggerHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test customers
        List<Customer__c> customers = TestDataFactory.createCustomers(3);
        
        // Create test products
        List<Product__c> products = TestDataFactory.createProducts(5);
    }
    
    @isTest
    static void testOrderInsert_Success() {
        // Get test data
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        Product__c product = [SELECT Id, Price__c, Stock_Quantity__c FROM Product__c LIMIT 1];
        
        Test.startTest();
        
        // Create order
        Order__c order = new Order__c();
        order.Customer__c = customer.Id;
        order.Product__c = product.Id;
        order.Quantity__c = 2;
        order.Unit_Price__c = product.Price__c;
        order.Total_Amount__c = product.Price__c * 2;
        order.Status__c = 'Pending';
        
        insert order;
        
        Test.stopTest();
        
        // Verify order was created
        Order__c insertedOrder = [SELECT Id, Total_Amount__c FROM Order__c WHERE Id = :order.Id];
        System.assertNotEquals(null, insertedOrder.Id, 'Order should be created');
        
        // Verify stock was updated
        Product__c updatedProduct = [SELECT Stock_Quantity__c FROM Product__c WHERE Id = :product.Id];
        System.assertEquals(product.Stock_Quantity__c - 2, updatedProduct.Stock_Quantity__c, 'Stock should be reduced');
    }
    
    @isTest
    static void testOrderInsert_InsufficientStock() {
        // Get test data
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        Product__c product = [SELECT Id, Price__c, Stock_Quantity__c FROM Product__c LIMIT 1];
        
        Test.startTest();
        
        // Try to create order with quantity exceeding stock
        Order__c order = new Order__c();
        order.Customer__c = customer.Id;
        order.Product__c = product.Id;
        order.Quantity__c = (Integer)product.Stock_Quantity__c + 10;
        order.Unit_Price__c = product.Price__c;
        order.Total_Amount__c = product.Price__c * order.Quantity__c;
        order.Status__c = 'Pending';
        
        try {
            insert order;
            System.assert(false, 'Exception should have been thrown for insufficient stock');
        } catch (DmlException e) {
            System.assert(e.getDmlMessage(0).contains('Insufficient stock'), 'Error message should mention insufficient stock');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testOrderUpdate_StatusChange() {
        // Get test data
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        Product__c product = [SELECT Id, Price__c, Stock_Quantity__c FROM Product__c LIMIT 1];
        
        // Create order
        Order__c order = new Order__c();
        order.Customer__c = customer.Id;
        order.Product__c = product.Id;
        order.Quantity__c = 1;
        order.Unit_Price__c = product.Price__c;
        order.Total_Amount__c = product.Price__c;
        order.Status__c = 'Pending';
        insert order;
        
        Test.startTest();
        
        // Update order status
        order.Status__c = 'Confirmed';
        update order;
        
        Test.stopTest();
        
        // Verify status was updated
        Order__c updatedOrder = [SELECT Status__c FROM Order__c WHERE Id = :order.Id];
        System.assertEquals('Confirmed', updatedOrder.Status__c, 'Status should be updated');
    }
    
    @isTest
    static void testOrderUpdate_Cancelled() {
        // Get test data
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        Product__c product = [SELECT Id, Price__c, Stock_Quantity__c FROM Product__c LIMIT 1];
        Decimal originalStock = product.Stock_Quantity__c;
        
        // Create order
        Order__c order = new Order__c();
        order.Customer__c = customer.Id;
        order.Product__c = product.Id;
        order.Quantity__c = 2;
        order.Unit_Price__c = product.Price__c;
        order.Total_Amount__c = product.Price__c * 2;
        order.Status__c = 'Pending';
        insert order;
        
        Test.startTest();
        
        // Cancel order
        order.Status__c = 'Cancelled';
        update order;
        
        Test.stopTest();
        
        // Verify stock was restored
        Product__c updatedProduct = [SELECT Stock_Quantity__c FROM Product__c WHERE Id = :product.Id];
        System.assertEquals(originalStock, updatedProduct.Stock_Quantity__c, 'Stock should be restored when order is cancelled');
    }
    
    @isTest
    static void testOrderDelete() {
        // Get test data
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        Product__c product = [SELECT Id, Price__c, Stock_Quantity__c FROM Product__c LIMIT 1];
        Decimal originalStock = product.Stock_Quantity__c;
        
        // Create order
        Order__c order = new Order__c();
        order.Customer__c = customer.Id;
        order.Product__c = product.Id;
        order.Quantity__c = 1;
        order.Unit_Price__c = product.Price__c;
        order.Total_Amount__c = product.Price__c;
        order.Status__c = 'Pending';
        insert order;
        
        Test.startTest();
        
        // Delete order
        delete order;
        
        Test.stopTest();
        
        // Verify stock was restored
        Product__c updatedProduct = [SELECT Stock_Quantity__c FROM Product__c WHERE Id = :product.Id];
        System.assertEquals(originalStock, updatedProduct.Stock_Quantity__c, 'Stock should be restored when order is deleted');
    }
    
    @isTest
    static void testOrderValidation_RequiredFields() {
        Test.startTest();
        
        // Try to create order without required fields
        Order__c order = new Order__c();
        order.Status__c = 'Pending';
        
        try {
            insert order;
            System.assert(false, 'Exception should have been thrown for missing required fields');
        } catch (DmlException e) {
            System.assert(e.getDmlMessage(0).contains('required'), 'Error message should mention required fields');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testOrderValidation_PositiveQuantity() {
        // Get test data
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        Product__c product = [SELECT Id, Price__c FROM Product__c LIMIT 1];
        
        Test.startTest();
        
        // Try to create order with zero quantity
        Order__c order = new Order__c();
        order.Customer__c = customer.Id;
        order.Product__c = product.Id;
        order.Quantity__c = 0;
        order.Unit_Price__c = product.Price__c;
        order.Total_Amount__c = 0;
        order.Status__c = 'Pending';
        
        try {
            insert order;
            System.assert(false, 'Exception should have been thrown for zero quantity');
        } catch (DmlException e) {
            System.assert(e.getDmlMessage(0).contains('greater than 0'), 'Error message should mention quantity must be greater than 0');
        }
        
        Test.stopTest();
    }
}

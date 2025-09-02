/**
 * @description Service class for Order management operations
 * @author Salesforce Demo
 * @date 2024
 */
public with sharing class OrderService {
    
    /**
     * @description Creates a new order and updates customer totals
     * @param customerId The ID of the customer placing the order
     * @param productId The ID of the product being ordered
     * @param quantity The quantity being ordered
     * @return Order__c The created order record
     */
    public static Order__c createOrder(Id customerId, Id productId, Integer quantity) {
        try {
            // Validate inputs
            if (customerId == null || productId == null || quantity <= 0) {
                throw new OrderServiceException('Invalid input parameters for order creation');
            }
            
            // Get product details
            Product__c product = getProductById(productId);
            if (product == null) {
                throw new OrderServiceException('Product not found');
            }
            
            // Check stock availability
            if (product.Stock_Quantity__c < quantity) {
                throw new OrderServiceException('Insufficient stock. Available: ' + product.Stock_Quantity__c);
            }
            
            // Create order
            Order__c order = new Order__c();
            order.Customer__c = customerId;
            order.Product__c = productId;
            order.Quantity__c = quantity;
            order.Unit_Price__c = product.Price__c;
            order.Total_Amount__c = product.Price__c * quantity;
            order.Status__c = 'Pending';
            
            insert order;
            
            // Update stock quantity
            updateProductStock(productId, quantity);
            
            // Update customer totals
            updateCustomerTotals(customerId);
            
            return order;
            
        } catch (Exception e) {
            System.debug('Error creating order: ' + e.getMessage());
            throw new OrderServiceException('Failed to create order: ' + e.getMessage());
        }
    }
    
    /**
     * @description Updates order status
     * @param orderId The ID of the order to update
     * @param newStatus The new status for the order
     */
    public static void updateOrderStatus(Id orderId, String newStatus) {
        try {
            Order__c order = [SELECT Id, Status__c FROM Order__c WHERE Id = :orderId LIMIT 1];
            order.Status__c = newStatus;
            update order;
            
            // If order is cancelled, restore stock
            if (newStatus == 'Cancelled') {
                restoreProductStock(orderId);
            }
            
        } catch (Exception e) {
            System.debug('Error updating order status: ' + e.getMessage());
            throw new OrderServiceException('Failed to update order status: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets order details with related records
     * @param orderId The ID of the order
     * @return Order__c The order with related customer and product details
     */
    public static Order__c getOrderDetails(Id orderId) {
        try {
            return [
                SELECT Id, Name, Customer__c, Customer__r.Name, Customer__r.Email__c,
                       Product__c, Product__r.Name, Product__r.SKU__c, Product__r.Category__c,
                       Quantity__c, Unit_Price__c, Total_Amount__c, Status__c, CreatedDate
                FROM Order__c 
                WHERE Id = :orderId 
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('Error getting order details: ' + e.getMessage());
            throw new OrderServiceException('Failed to get order details: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets orders for a specific customer
     * @param customerId The ID of the customer
     * @return List<Order__c> List of orders for the customer
     */
    public static List<Order__c> getCustomerOrders(Id customerId) {
        try {
            return [
                SELECT Id, Name, Product__c, Product__r.Name, Product__r.SKU__c,
                       Quantity__c, Unit_Price__c, Total_Amount__c, Status__c, CreatedDate
                FROM Order__c 
                WHERE Customer__c = :customerId 
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            System.debug('Error getting customer orders: ' + e.getMessage());
            throw new OrderServiceException('Failed to get customer orders: ' + e.getMessage());
        }
    }
    
    /**
     * @description Private method to get product by ID
     * @param productId The ID of the product
     * @return Product__c The product record
     */
    private static Product__c getProductById(Id productId) {
        try {
            return [SELECT Id, Name, Price__c, Stock_Quantity__c FROM Product__c WHERE Id = :productId LIMIT 1];
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * @description Private method to update product stock
     * @param productId The ID of the product
     * @param quantity The quantity to reduce from stock
     */
    private static void updateProductStock(Id productId, Integer quantity) {
        Product__c product = getProductById(productId);
        if (product != null) {
            product.Stock_Quantity__c -= quantity;
            update product;
        }
    }
    
    /**
     * @description Private method to restore product stock when order is cancelled
     * @param orderId The ID of the cancelled order
     */
    private static void restoreProductStock(Id orderId) {
        try {
            Order__c order = [SELECT Product__c, Quantity__c FROM Order__c WHERE Id = :orderId LIMIT 1];
            Product__c product = getProductById(order.Product__c);
            if (product != null) {
                product.Stock_Quantity__c += (Integer)order.Quantity__c;
                update product;
            }
        } catch (Exception e) {
            System.debug('Error restoring product stock: ' + e.getMessage());
        }
    }
    
    /**
     * @description Private method to update customer totals
     * @param customerId The ID of the customer
     */
    private static void updateCustomerTotals(Id customerId) {
        try {
            // Get customer with current totals
            Customer__c customer = [SELECT Id, Total_Orders__c, Total_Revenue__c FROM Customer__c WHERE Id = :customerId LIMIT 1];
            
            // Calculate new totals
            List<AggregateResult> orderStats = [
                SELECT COUNT(Id) orderCount, SUM(Total_Amount__c) totalRevenue
                FROM Order__c 
                WHERE Customer__c = :customerId AND Status__c != 'Cancelled'
            ];
            
            if (!orderStats.isEmpty()) {
                AggregateResult stats = orderStats[0];
                customer.Total_Orders__c = (Decimal)stats.get('orderCount');
                customer.Total_Revenue__c = (Decimal)stats.get('totalRevenue');
                update customer;
            }
        } catch (Exception e) {
            System.debug('Error updating customer totals: ' + e.getMessage());
        }
    }
    
    /**
     * @description Custom exception class for OrderService
     */
    public class OrderServiceException extends Exception {}
}

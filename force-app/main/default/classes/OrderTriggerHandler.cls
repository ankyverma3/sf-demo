/**
 * @description Handler class for Order__c trigger
 * @author Salesforce Demo
 * @date 2024
 */
public with sharing class OrderTriggerHandler {
    
    private static Boolean isExecuting = false;
    
    /**
     * @description Handles before insert operations
     * @param newOrders List of new orders being inserted
     */
    public static void handleBeforeInsert(List<Order__c> newOrders) {
        if (isExecuting) return;
        isExecuting = true;
        
        try {
            // Validate order data
            validateOrders(newOrders);
            
            // Calculate total amount if not provided
            calculateTotalAmount(newOrders);
            
            // Check stock availability
            checkStockAvailability(newOrders);
            
        } finally {
            isExecuting = false;
        }
    }
    
    /**
     * @description Handles before update operations
     * @param newOrders List of orders being updated
     * @param oldOrdersMap Map of old order values
     */
    public static void handleBeforeUpdate(List<Order__c> newOrders, Map<Id, Order__c> oldOrdersMap) {
        if (isExecuting) return;
        isExecuting = true;
        
        try {
            // Validate order data
            validateOrders(newOrders);
            
            // Recalculate total amount if quantity or unit price changed
            recalculateTotalAmount(newOrders, oldOrdersMap);
            
            // Check stock availability for quantity changes
            checkStockAvailabilityForUpdates(newOrders, oldOrdersMap);
            
        } finally {
            isExecuting = false;
        }
    }
    
    /**
     * @description Handles after insert operations
     * @param newOrders List of newly inserted orders
     */
    public static void handleAfterInsert(List<Order__c> newOrders) {
        if (isExecuting) return;
        isExecuting = true;
        
        try {
            // Update product stock
            updateProductStock(newOrders, 'insert');
            
            // Update customer totals
            updateCustomerTotals(newOrders);
            
            // Send order confirmation email
            sendOrderConfirmationEmails(newOrders);
            
        } finally {
            isExecuting = false;
        }
    }
    
    /**
     * @description Handles after update operations
     * @param newOrders List of updated orders
     * @param oldOrdersMap Map of old order values
     */
    public static void handleAfterUpdate(List<Order__c> newOrders, Map<Id, Order__c> oldOrdersMap) {
        if (isExecuting) return;
        isExecuting = true;
        
        try {
            // Handle status changes
            handleStatusChanges(newOrders, oldOrdersMap);
            
            // Update customer totals
            updateCustomerTotals(newOrders);
            
        } finally {
            isExecuting = false;
        }
    }
    
    /**
     * @description Handles after delete operations
     * @param oldOrders List of deleted orders
     */
    public static void handleAfterDelete(List<Order__c> oldOrders) {
        if (isExecuting) return;
        isExecuting = true;
        
        try {
            // Restore product stock
            updateProductStock(oldOrders, 'delete');
            
            // Update customer totals
            updateCustomerTotals(oldOrders);
            
        } finally {
            isExecuting = false;
        }
    }
    
    /**
     * @description Validates order data
     * @param orders List of orders to validate
     */
    private static void validateOrders(List<Order__c> orders) {
        for (Order__c order : orders) {
            // Validate required fields
            if (order.Customer__c == null) {
                order.addError('Customer is required');
            }
            if (order.Product__c == null) {
                order.addError('Product is required');
            }
            if (order.Quantity__c == null || order.Quantity__c <= 0) {
                order.addError('Quantity must be greater than 0');
            }
            if (order.Unit_Price__c == null || order.Unit_Price__c <= 0) {
                order.addError('Unit price must be greater than 0');
            }
        }
    }
    
    /**
     * @description Calculates total amount for new orders
     * @param orders List of orders
     */
    private static void calculateTotalAmount(List<Order__c> orders) {
        for (Order__c order : orders) {
            if (order.Total_Amount__c == null && order.Quantity__c != null && order.Unit_Price__c != null) {
                order.Total_Amount__c = order.Quantity__c * order.Unit_Price__c;
            }
        }
    }
    
    /**
     * @description Recalculates total amount for updated orders
     * @param newOrders List of updated orders
     * @param oldOrdersMap Map of old order values
     */
    private static void recalculateTotalAmount(List<Order__c> newOrders, Map<Id, Order__c> oldOrdersMap) {
        for (Order__c order : newOrders) {
            Order__c oldOrder = oldOrdersMap.get(order.Id);
            
            if (order.Quantity__c != oldOrder.Quantity__c || order.Unit_Price__c != oldOrder.Unit_Price__c) {
                order.Total_Amount__c = order.Quantity__c * order.Unit_Price__c;
            }
        }
    }
    
    /**
     * @description Checks stock availability for new orders
     * @param orders List of orders
     */
    private static void checkStockAvailability(List<Order__c> orders) {
        Set<Id> productIds = new Set<Id>();
        for (Order__c order : orders) {
            if (order.Product__c != null) {
                productIds.add(order.Product__c);
            }
        }
        
        Map<Id, Product__c> products = new Map<Id, Product__c>([
            SELECT Id, Stock_Quantity__c FROM Product__c WHERE Id IN :productIds
        ]);
        
        for (Order__c order : orders) {
            if (order.Product__c != null && products.containsKey(order.Product__c)) {
                Product__c product = products.get(order.Product__c);
                if (product.Stock_Quantity__c < order.Quantity__c) {
                    order.addError('Insufficient stock. Available: ' + product.Stock_Quantity__c);
                }
            }
        }
    }
    
    /**
     * @description Checks stock availability for order updates
     * @param newOrders List of updated orders
     * @param oldOrdersMap Map of old order values
     */
    private static void checkStockAvailabilityForUpdates(List<Order__c> newOrders, Map<Id, Order__c> oldOrdersMap) {
        Set<Id> productIds = new Set<Id>();
        for (Order__c order : newOrders) {
            if (order.Product__c != null) {
                productIds.add(order.Product__c);
            }
        }
        
        Map<Id, Product__c> products = new Map<Id, Product__c>([
            SELECT Id, Stock_Quantity__c FROM Product__c WHERE Id IN :productIds
        ]);
        
        for (Order__c order : newOrders) {
            Order__c oldOrder = oldOrdersMap.get(order.Id);
            
            if (order.Quantity__c != oldOrder.Quantity__c && order.Product__c != null && products.containsKey(order.Product__c)) {
                Product__c product = products.get(order.Product__c);
                Decimal quantityChange = order.Quantity__c - oldOrder.Quantity__c;
                
                if (product.Stock_Quantity__c < quantityChange) {
                    order.addError('Insufficient stock for quantity increase. Available: ' + product.Stock_Quantity__c);
                }
            }
        }
    }
    
    /**
     * @description Updates product stock based on order operations
     * @param orders List of orders
     * @param operation Type of operation (insert, update, delete)
     */
    private static void updateProductStock(List<Order__c> orders, String operation) {
        Map<Id, Decimal> stockChanges = new Map<Id, Decimal>();
        
        for (Order__c order : orders) {
            if (order.Product__c != null && order.Quantity__c != null) {
                Decimal change = order.Quantity__c;
                
                if (operation == 'delete') {
                    change = -change; // Restore stock
                }
                
                if (stockChanges.containsKey(order.Product__c)) {
                    stockChanges.put(order.Product__c, stockChanges.get(order.Product__c) + change);
                } else {
                    stockChanges.put(order.Product__c, change);
                }
            }
        }
        
        // Update product stock and check for low stock alerts
        List<Product__c> productsToUpdate = new List<Product__c>();
        for (Id productId : stockChanges.keySet()) {
            Product__c product = new Product__c(Id = productId);
            product.Stock_Quantity__c = stockChanges.get(productId);
            productsToUpdate.add(product);
            
            // Junior dev mistake: Checking low stock in trigger instead of using async processing
            if (product.Stock_Quantity__c < 10) {
                OrderNotificationService.sendLowStockAlert(productId, (Integer)product.Stock_Quantity__c);
            }
        }
        
        if (!productsToUpdate.isEmpty()) {
            update productsToUpdate;
        }
    }
    
    /**
     * @description Updates customer totals
     * @param orders List of orders
     */
    private static void updateCustomerTotals(List<Order__c> orders) {
        Set<Id> customerIds = new Set<Id>();
        for (Order__c order : orders) {
            if (order.Customer__c != null) {
                customerIds.add(order.Customer__c);
            }
        }
        
        if (!customerIds.isEmpty()) {
            // Update customer totals asynchronously to avoid governor limits
            System.enqueueJob(new UpdateCustomerTotalsJob(customerIds));
        }
    }
    
    /**
     * @description Handles order status changes
     * @param newOrders List of updated orders
     * @param oldOrdersMap Map of old order values
     */
    private static void handleStatusChanges(List<Order__c> newOrders, Map<Id, Order__c> oldOrdersMap) {
        List<Order__c> statusChangedOrders = new List<Order__c>();
        
        for (Order__c order : newOrders) {
            Order__c oldOrder = oldOrdersMap.get(order.Id);
            if (order.Status__c != oldOrder.Status__c) {
                statusChangedOrders.add(order);
                // Junior dev mistake: Calling service method in loop instead of bulk processing
                OrderNotificationService.sendStatusChangeNotification(order.Id, oldOrder.Status__c, order.Status__c);
            }
        }
        
        if (!statusChangedOrders.isEmpty()) {
            sendStatusChangeNotifications(statusChangedOrders);
        }
    }
    
    /**
     * @description Sends order confirmation emails
     * @param orders List of orders
     */
    private static void sendOrderConfirmationEmails(List<Order__c> orders) {
        // This would typically be implemented as a queueable job for better performance
        // For demo purposes, we'll just log the action
        for (Order__c order : orders) {
            Utility.log('Order confirmation email would be sent for order: ' + order.Name, 'INFO');
        }
    }
    
    /**
     * @description Sends status change notifications
     * @param orders List of orders with status changes
     */
    private static void sendStatusChangeNotifications(List<Order__c> orders) {
        // This would typically be implemented as a queueable job for better performance
        // For demo purposes, we'll just log the action
        for (Order__c order : orders) {
            Utility.log('Status change notification would be sent for order: ' + order.Name, 'INFO');
        }
    }
    
    /**
     * @description Queueable job to update customer totals
     */
    public class UpdateCustomerTotalsJob implements Queueable {
        private Set<Id> customerIds;
        
        public UpdateCustomerTotalsJob(Set<Id> customerIds) {
            this.customerIds = customerIds;
        }
        
        public void execute(QueueableContext context) {
            List<Customer__c> customersToUpdate = new List<Customer__c>();
            
            for (Id customerId : customerIds) {
                List<AggregateResult> orderStats = [
                    SELECT COUNT(Id) orderCount, SUM(Total_Amount__c) totalRevenue
                    FROM Order__c 
                    WHERE Customer__c = :customerId AND Status__c != 'Cancelled'
                ];
                
                Customer__c customer = new Customer__c(Id = customerId);
                
                if (!orderStats.isEmpty()) {
                    AggregateResult stats = orderStats[0];
                    customer.Total_Orders__c = (Decimal)stats.get('orderCount');
                    customer.Total_Revenue__c = (Decimal)stats.get('totalRevenue');
                } else {
                    customer.Total_Orders__c = 0;
                    customer.Total_Revenue__c = 0;
                }
                
                customersToUpdate.add(customer);
            }
            
            if (!customersToUpdate.isEmpty()) {
                update customersToUpdate;
            }
        }
    }
}

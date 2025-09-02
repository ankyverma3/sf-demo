/**
 * @description Controller class for Product Lightning Web Components
 * @author Salesforce Demo
 * @date 2024
 */
public with sharing class ProductController {
    
    /**
     * @description Gets products with optional search and category filtering
     * @param searchTerm Search term for product name or SKU
     * @param category Category filter
     * @return List<Product__c> List of products
     */
    @AuraEnabled(cacheable=true)
    public static List<Product__c> getProducts(String searchTerm, String category) {
        try {
            String query = 'SELECT Id, Name, SKU__c, Category__c, Price__c, Stock_Quantity__c, Description__c FROM Product__c';
            List<String> conditions = new List<String>();
            List<String> parameters = new List<String>();
            
            // Add search condition
            if (!String.isBlank(searchTerm)) {
                conditions.add('(Name LIKE :searchPattern OR SKU__c LIKE :searchPattern)');
                parameters.add('%' + searchTerm + '%');
            }
            
            // Add category condition
            if (!String.isBlank(category)) {
                conditions.add('Category__c = :category');
                parameters.add(category);
            }
            
            // Build final query
            if (!conditions.isEmpty()) {
                query += ' WHERE ' + String.join(conditions, ' AND ');
            }
            
            query += ' ORDER BY Name ASC LIMIT 100';
            
            // Execute query with parameters
            if (!String.isBlank(searchTerm) && !String.isBlank(category)) {
                return Database.queryWithBinds(query, new Map<String, Object>{
                    'searchPattern' => '%' + searchTerm + '%',
                    'category' => category
                }, AccessLevel.USER_MODE);
            } else if (!String.isBlank(searchTerm)) {
                return Database.queryWithBinds(query, new Map<String, Object>{
                    'searchPattern' => '%' + searchTerm + '%'
                }, AccessLevel.USER_MODE);
            } else if (!String.isBlank(category)) {
                return Database.queryWithBinds(query, new Map<String, Object>{
                    'category' => category
                }, AccessLevel.USER_MODE);
            } else {
                return Database.query(query);
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve products: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets product details by ID
     * @param productId The ID of the product
     * @return Product__c The product record
     */
    @AuraEnabled(cacheable=true)
    public static Product__c getProductById(Id productId) {
        try {
            if (productId == null) {
                throw new AuraHandledException('Product ID is required');
            }
            
            List<Product__c> products = [
                SELECT Id, Name, SKU__c, Category__c, Price__c, Stock_Quantity__c, Description__c
                FROM Product__c 
                WHERE Id = :productId 
                LIMIT 1
            ];
            
            if (products.isEmpty()) {
                throw new AuraHandledException('Product not found');
            }
            
            return products[0];
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve product: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets products by category
     * @param category The product category
     * @return List<Product__c> List of products in the category
     */
    @AuraEnabled(cacheable=true)
    public static List<Product__c> getProductsByCategory(String category) {
        try {
            if (String.isBlank(category)) {
                throw new AuraHandledException('Category is required');
            }
            
            return [
                SELECT Id, Name, SKU__c, Category__c, Price__c, Stock_Quantity__c, Description__c
                FROM Product__c 
                WHERE Category__c = :category 
                ORDER BY Name ASC
            ];
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve products by category: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets low stock products (stock < 10)
     * @return List<Product__c> List of low stock products
     */
    @AuraEnabled(cacheable=true)
    public static List<Product__c> getLowStockProducts() {
        try {
            return [
                SELECT Id, Name, SKU__c, Category__c, Price__c, Stock_Quantity__c, Description__c
                FROM Product__c 
                WHERE Stock_Quantity__c < 10 
                ORDER BY Stock_Quantity__c ASC
            ];
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve low stock products: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets product categories
     * @return List<String> List of available categories
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getProductCategories() {
        try {
            List<AggregateResult> results = [
                SELECT Category__c 
                FROM Product__c 
                WHERE Category__c != null 
                GROUP BY Category__c 
                ORDER BY Category__c
            ];
            
            List<String> categories = new List<String>();
            for (AggregateResult result : results) {
                categories.add((String)result.get('Category__c'));
            }
            
            return categories;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve product categories: ' + e.getMessage());
        }
    }
    
    /**
     * @description Updates product stock quantity
     * @param productId The ID of the product
     * @param newStockQuantity The new stock quantity
     * @return Product__c The updated product
     */
    @AuraEnabled
    public static Product__c updateProductStock(Id productId, Integer newStockQuantity) {
        try {
            if (productId == null) {
                throw new AuraHandledException('Product ID is required');
            }
            
            if (newStockQuantity == null || newStockQuantity < 0) {
                throw new AuraHandledException('Stock quantity must be a non-negative number');
            }
            
            Product__c product = getProductById(productId);
            product.Stock_Quantity__c = newStockQuantity;
            
            update product;
            return product;
            
        } catch (DmlException e) {
            throw new AuraHandledException('Database error: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Failed to update product stock: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets product statistics
     * @return Map<String, Object> Product statistics
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getProductStatistics() {
        try {
            List<AggregateResult> results = [
                SELECT COUNT(Id) totalProducts,
                       SUM(Stock_Quantity__c) totalStock,
                       AVG(Price__c) averagePrice,
                       MIN(Price__c) minPrice,
                       MAX(Price__c) maxPrice
                FROM Product__c
            ];
            
            Map<String, Object> stats = new Map<String, Object>();
            
            if (!results.isEmpty()) {
                AggregateResult result = results[0];
                stats.put('totalProducts', result.get('totalProducts'));
                stats.put('totalStock', result.get('totalStock'));
                stats.put('averagePrice', result.get('averagePrice'));
                stats.put('minPrice', result.get('minPrice'));
                stats.put('maxPrice', result.get('maxPrice'));
            }
            
            return stats;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve product statistics: ' + e.getMessage());
        }
    }
}

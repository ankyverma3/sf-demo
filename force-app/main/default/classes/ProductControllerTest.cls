/**
 * @description Test class for ProductController
 * @author Salesforce Demo
 * @date 2024
 */
@isTest
public class ProductControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test products
        List<Product__c> products = TestDataFactory.createProducts(10);
    }
    
    @isTest
    static void testGetProducts_All() {
        Test.startTest();
        
        List<Product__c> products = ProductController.getProducts('', '');
        
        Test.stopTest();
        
        System.assertNotEquals(null, products, 'Products list should not be null');
        System.assertEquals(10, products.size(), 'Should return 10 products');
        
        for (Product__c product : products) {
            System.assertNotEquals(null, product.Id, 'Product should have an ID');
            System.assertNotEquals(null, product.Name, 'Product should have a name');
        }
    }
    
    @isTest
    static void testGetProducts_WithSearch() {
        Test.startTest();
        
        List<Product__c> products = ProductController.getProducts('Test Product 1', '');
        
        Test.stopTest();
        
        System.assertNotEquals(null, products, 'Products list should not be null');
        System.assert(products.size() > 0, 'Should return at least one product for search');
        
        for (Product__c product : products) {
            System.assert(product.Name.contains('Test Product 1'), 'All products should match search term');
        }
    }
    
    @isTest
    static void testGetProducts_WithCategory() {
        Test.startTest();
        
        // Get a product to find its category
        Product__c testProduct = [SELECT Category__c FROM Product__c LIMIT 1];
        
        List<Product__c> products = ProductController.getProducts('', testProduct.Category__c);
        
        Test.stopTest();
        
        System.assertNotEquals(null, products, 'Products list should not be null');
        System.assert(products.size() > 0, 'Should return at least one product for category');
        
        for (Product__c product : products) {
            System.assertEquals(testProduct.Category__c, product.Category__c, 'All products should match category');
        }
    }
    
    @isTest
    static void testGetProductById_Success() {
        // Get test product
        Product__c testProduct = [SELECT Id FROM Product__c LIMIT 1];
        
        Test.startTest();
        
        Product__c product = ProductController.getProductById(testProduct.Id);
        
        Test.stopTest();
        
        System.assertNotEquals(null, product, 'Product should be returned');
        System.assertEquals(testProduct.Id, product.Id, 'Product ID should match');
    }
    
    @isTest
    static void testGetProductById_InvalidId() {
        Test.startTest();
        
        try {
            ProductController.getProductById(null);
            System.assert(false, 'Exception should have been thrown for null ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Product ID is required'), 'Error message should mention required ID');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetProductsByCategory() {
        // Get a product to find its category
        Product__c testProduct = [SELECT Category__c FROM Product__c LIMIT 1];
        
        Test.startTest();
        
        List<Product__c> products = ProductController.getProductsByCategory(testProduct.Category__c);
        
        Test.stopTest();
        
        System.assertNotEquals(null, products, 'Products list should not be null');
        System.assert(products.size() > 0, 'Should return at least one product for category');
        
        for (Product__c product : products) {
            System.assertEquals(testProduct.Category__c, product.Category__c, 'All products should match category');
        }
    }
    
    @isTest
    static void testGetProductsByCategory_InvalidCategory() {
        Test.startTest();
        
        try {
            ProductController.getProductsByCategory('');
            System.assert(false, 'Exception should have been thrown for empty category');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Category is required'), 'Error message should mention required category');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetLowStockProducts() {
        Test.startTest();
        
        List<Product__c> lowStockProducts = ProductController.getLowStockProducts();
        
        Test.stopTest();
        
        System.assertNotEquals(null, lowStockProducts, 'Low stock products list should not be null');
        
        for (Product__c product : lowStockProducts) {
            System.assert(product.Stock_Quantity__c < 10, 'All products should have stock less than 10');
        }
    }
    
    @isTest
    static void testGetProductCategories() {
        Test.startTest();
        
        List<String> categories = ProductController.getProductCategories();
        
        Test.stopTest();
        
        System.assertNotEquals(null, categories, 'Categories list should not be null');
        System.assert(categories.size() > 0, 'Should return at least one category');
    }
    
    @isTest
    static void testUpdateProductStock_Success() {
        // Get test product
        Product__c testProduct = [SELECT Id, Stock_Quantity__c FROM Product__c LIMIT 1];
        
        Test.startTest();
        
        Product__c updatedProduct = ProductController.updateProductStock(testProduct.Id, 50);
        
        Test.stopTest();
        
        System.assertEquals(50, updatedProduct.Stock_Quantity__c, 'Stock quantity should be updated');
    }
    
    @isTest
    static void testUpdateProductStock_InvalidInputs() {
        // Get test product
        Product__c testProduct = [SELECT Id FROM Product__c LIMIT 1];
        
        Test.startTest();
        
        // Test null product ID
        try {
            ProductController.updateProductStock(null, 50);
            System.assert(false, 'Exception should have been thrown for null product ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Product ID is required'), 'Error message should mention required product ID');
        }
        
        // Test negative stock quantity
        try {
            ProductController.updateProductStock(testProduct.Id, -1);
            System.assert(false, 'Exception should have been thrown for negative stock quantity');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('non-negative number'), 'Error message should mention non-negative number');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetProductStatistics() {
        Test.startTest();
        
        Map<String, Object> stats = ProductController.getProductStatistics();
        
        Test.stopTest();
        
        System.assertNotEquals(null, stats, 'Statistics should not be null');
        System.assert(stats.containsKey('totalProducts'), 'Should contain total products');
        System.assert(stats.containsKey('totalStock'), 'Should contain total stock');
        System.assert(stats.containsKey('averagePrice'), 'Should contain average price');
        System.assert(stats.containsKey('minPrice'), 'Should contain minimum price');
        System.assert(stats.containsKey('maxPrice'), 'Should contain maximum price');
    }
}

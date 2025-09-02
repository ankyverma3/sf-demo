# Salesforce Demo Project

A comprehensive Salesforce demo project showcasing real-world functionality including custom objects, Apex classes, Lightning Web Components, triggers, validation rules, and test classes.

## 🚀 Features

### Custom Objects
- **Customer__c**: Manages customer information with types (Individual, Business, Enterprise)
- **Product__c**: Product catalog with categories, pricing, and inventory management
- **Order__c**: Order management with customer and product relationships

### Business Logic
- **OrderService**: Service class for order creation, status updates, and business rules
- **Utility**: Common utility methods for email validation, currency formatting, and more
- **TestDataFactory**: Factory class for creating test data

### User Interface
- **CustomerList**: Lightning Web Component for customer management
- **ProductCatalog**: Lightning Web Component for product browsing and search
- **Responsive Design**: Modern UI with Salesforce Lightning Design System

### Data Integrity
- **Validation Rules**: Ensure data quality and business rules
- **Triggers**: Automate business processes and maintain data consistency
- **Stock Management**: Automatic inventory tracking and low-stock alerts

## 📋 Prerequisites

- Salesforce CLI (sf CLI)
- Node.js (for Lightning Web Components)
- Git

## 🛠️ Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sf-demo
   ```

2. **Authenticate with Salesforce**
   ```bash
   sf org login web --set-default
   ```

3. **Deploy to scratch org**
   ```bash
   ./scripts/deploy.sh
   ```

## 🏗️ Project Structure

```
sf-demo/
├── force-app/main/default/
│   ├── classes/                 # Apex classes
│   │   ├── OrderService.cls     # Order business logic
│   │   ├── Utility.cls          # Utility methods
│   │   ├── CustomerController.cls # Customer LWC controller
│   │   ├── ProductController.cls  # Product LWC controller
│   │   ├── OrderTriggerHandler.cls # Trigger handler
│   │   ├── TestDataFactory.cls  # Test data factory
│   │   └── *Test.cls            # Test classes
│   ├── triggers/                # Apex triggers
│   │   └── OrderTrigger.trigger # Order trigger
│   ├── lwc/                     # Lightning Web Components
│   │   ├── customerList/        # Customer management component
│   │   └── productCatalog/      # Product catalog component
│   ├── objects/                 # Custom objects
│   │   ├── Customer__c/         # Customer object
│   │   ├── Product__c/          # Product object
│   │   └── Order__c/            # Order object
│   └── flows/                   # Process Builder flows
├── config/                      # Configuration files
│   └── project-scratch-def.json # Scratch org definition
├── scripts/                     # Deployment scripts
│   ├── deploy.sh               # Deployment script
│   └── createTestData.apex     # Test data creation
└── manifest/                   # Package manifest
    └── package.xml             # Metadata manifest
```

## 🎯 Usage

### Creating Customers
1. Navigate to the Customer Management component
2. Click "New Customer"
3. Fill in customer details (Type, Email, Phone)
4. Save to create the customer

### Managing Products
1. Use the Product Catalog component
2. Search products by name or SKU
3. Filter by category
4. View stock levels and pricing

### Processing Orders
1. Orders are created through the OrderService class
2. Stock is automatically updated when orders are placed
3. Customer totals are recalculated automatically
4. Order status changes trigger notifications

## 🧪 Testing

Run the test suite to ensure code quality:

```bash
sf apex run test --target-org demo-org
```

### Test Coverage
- **OrderService**: 95%+ coverage
- **Utility**: 100% coverage
- **Controllers**: 90%+ coverage
- **Trigger Handler**: 95%+ coverage

## 🔧 Development

### Adding New Features
1. Create feature branch
2. Implement changes with tests
3. Ensure test coverage > 90%
4. Submit pull request

### Code Standards
- Follow Salesforce coding conventions
- Include comprehensive test coverage
- Document public methods
- Use meaningful variable names

## 📊 Business Rules

### Order Processing
- Orders require valid customer and product
- Stock is checked before order creation
- Total amount is calculated automatically
- Status changes trigger business logic

### Data Validation
- Email addresses must be valid format
- Prices and quantities must be positive
- Stock quantities cannot be negative
- Required fields are enforced

### Customer Management
- Customer types: Individual, Business, Enterprise
- Email addresses must be unique
- Total orders and revenue are calculated automatically

## 🚀 Deployment

### To Production
1. Create deployment package
2. Run validation tests
3. Deploy to production org
4. Verify functionality

### To Sandbox
```bash
sf project deploy start --target-org sandbox-org
```

## 📈 Monitoring

### Key Metrics
- Order processing time
- Stock level accuracy
- Customer satisfaction
- System performance

### Logging
- All business operations are logged
- Error handling with detailed messages
- Performance monitoring

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes with tests
4. Submit pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## 🔄 Version History

- **v1.0.0**: Initial release with core functionality
- **v1.1.0**: Added Lightning Web Components
- **v1.2.0**: Enhanced business logic and validation
- **v1.3.0**: Improved test coverage and documentation

---

**Built with ❤️ using Salesforce DX and Lightning Web Components**

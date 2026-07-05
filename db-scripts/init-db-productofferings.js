print("Importation de la base de donnée initiale du catalogue")
db = db.getSiblingDB('cantelcox');
db.createCollection('productofferings')
db.productofferings.insertMany([
  { "_id": "yHzk18y9AsTrb5crwWSV0vaO", name: "SMGA54", description: "Samsung A54", productOfferingPrice: 299.99, version: "1.0", validFor: '', lifecycleStatus: 'RUNNING', stock: 100, characteristics: {isService: false, billingCycle: 'once'} },
  { "_id": "WbpFMSt2nHOggHCRnnz9whyK", name: "IPH008", description: "Apple iPhone 8 - Promo", productOfferingPrice: 499.99, version: "1.0", validFor: '', lifecycleStatus: 'RUNNING', stock: 20, characteristics: {isService: false, billingCycle: 'once'} },
  { "_id": "EeeTAgEAFlmSeMXJ1iAFb2i5", name: "MOTXYZ", description: "Motorola XYZ", productOfferingPrice: 350.99, version: "1.0", validFor: '', lifecycleStatus: 'RUNNING', stock: 75, characteristics: {isService: false, billingCycle: 'once'} },
  { "_id": "7XlRCHmgajT7QAgQImKRcX7g", name: "MOB001", description: "Ligne Mobile - Accès mensuel", productOfferingPrice: 45.99, version: "1.0", validFor: '', lifecycleStatus: 'RUNNING', stock: 1500, characteristics: {isService: true, billingCycle: 'monthly'} }
]);
print("Database seeding completed successfully!");

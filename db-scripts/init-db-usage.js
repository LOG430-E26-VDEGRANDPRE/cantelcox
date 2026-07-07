print("Importation de la base de donnée initiale des usages")
db = db.getSiblingDB('usages');
db.createCollection('usages')
/*
db.productofferings.insertMany([
]);
*/
print("Database seeding completed successfully!");

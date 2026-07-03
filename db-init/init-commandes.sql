-- Create database
CREATE DATABASE IF NOT EXISTS bd_commandes;
USE bd_commandes;

GRANT ALL PRIVILEGES ON bd_commandes.* TO 'cantelcox'@'%';

-- Order table
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    partyRef VARCHAR(150) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    payment_link VARCHAR(100),
    is_paid BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    productOfferingRef VARCHAR(150),
    price DECIMAL(10,2) NOT NULL,
    serviceRef VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order items
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
);

INSERT INTO products (name, productOfferingRef, serviceRef, price) VALUES
('Samsung A54', 'SMGA54', NULL, 299.99),
('Apple iPhone 8 - Promo', 'IPH008', NULL, 499.99),
('Motorola XYZ', 'MOTXYZ', NULL, 20.99),
('Ligne Mobile - Accès mensuel', 'MOB001', 'CanTelcoX-L1', 45.99);
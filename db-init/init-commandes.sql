-- Importation de caractères accentués
SET NAMES 'utf8mb4';

-- Create database
CREATE DATABASE IF NOT EXISTS productorders CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE productorders;

GRANT ALL PRIVILEGES ON productorders.* TO 'cantelcox'@'%';

-- Order table
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    partyRef INT NOT NULL,
    orderTotalPrice DECIMAL(12,2) NOT NULL,
    cancellationDate DATETIME,
    category VARCHAR(25),
    payment_link VARCHAR(100),
    is_paid BOOLEAN,
    creationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completionDate DATETIME,
    description VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Products table
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    productOfferingRef VARCHAR(150),
    price DECIMAL(10,2) NOT NULL,
    serviceRef VARCHAR(150),
    type ENUM('produit','service'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_billed BIT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Order items
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    itemPrice DECIMAL(10,2) NOT NULL,
    itemTotalPrice DECIMAL(10,2) NOT NULL,
    description VARCHAR(255),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Patron d'idempotence
DROP TABLE IF EXISTS idempotency_keys;
CREATE TABLE idempotency_keys (
    idempotency_key VARCHAR(255) NOT NULL,
    request_hash VARCHAR(64) NOT NULL,
    status ENUM('PENDING', 'COMPLETED', 'FAILED') NOT NULL DEFAULT 'PENDING',
    response_code INT NULL,
    response_body TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (idempotency_key),
    UNIQUE(idempotency_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO products (name, productOfferingRef, serviceRef, price, type) VALUES
('Samsung A54', 'SMGA54', NULL, 299.99, 'produit'),
('Apple iPhone 8 - Promo', 'IPH008', NULL, 499.99, 'produit'),
('Motorola XYZ', 'MOTXYZ', NULL, 20.99, 'produit'),
('Ligne Mobile - Accès mensuel', 'MOB001', 'CanTelcoX-L1', 45.99, 'service');
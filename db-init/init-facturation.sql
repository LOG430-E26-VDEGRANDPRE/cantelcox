-- Importation de caractères accentués
SET NAMES 'utf8mb4';

-- Create database
CREATE DATABASE IF NOT EXISTS customerbills CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE customerbills;

GRANT ALL PRIVILEGES ON customerbills.* TO 'cantelcox'@'%';

-- BillCycle table
DROP TABLE IF EXISTS billcycles;
CREATE TABLE billcycles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description VARCHAR(255),
    billing_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    billing_period_start DATE,
    billing_period_end DATE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- CustomerBill table
DROP TABLE IF EXISTS customerbills;
CREATE TABLE customerbills (
    id INT UNIQUE AUTO_INCREMENT,
    partyRef INT NOT NULL,
    billcycle_id INT NOT NULL,
    bill_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    next_bill_date DATETIME,
    remaining_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    bill_status ENUM ('DUE','PAID','CANCELED') NOT NULL DEFAULT 'DUE',
    payment_link VARCHAR(150),
    FOREIGN KEY (billcycle_id) REFERENCES billcycles(id),
    PRIMARY KEY (id, partyRef, billcycle_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- BillLine table
DROP TABLE IF EXISTS billlines;
CREATE TABLE billlines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customerbill_id INT NOT NULL,
    productRef INT,
    usageRef VARCHAR(32),
    amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (customerbill_id) REFERENCES customerbills(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Payments table
DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    customerbill_id INT NOT NULL,
    is_processed BIT,
    FOREIGN KEY (customerbill_id) REFERENCES customerbills(id) ON DELETE CASCADE
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

INSERT INTO billcycles (name, description) VALUES ('202607', 'Cycle de facturation initial');
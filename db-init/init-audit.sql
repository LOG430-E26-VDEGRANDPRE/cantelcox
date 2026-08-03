-- Importation de caractères accentués
SET NAMES 'utf8mb4';

-- Create database
CREATE DATABASE IF NOT EXISTS audit CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE audit;

GRANT ALL PRIVILEGES ON audit.* TO 'cantelcox'@'%';

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

DROP TABLE IF EXISTS outbox;
CREATE TABLE outbox (
    id INT AUTO_INCREMENT PRIMARY KEY,
    topic VARCHAR(100) NOT NULL,
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id BIGINT NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    published BOOLEAN DEFAULT FALSE
);

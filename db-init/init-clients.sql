-- Importation de caractères accentués
SET NAMES 'utf8mb4';

-- Create database
CREATE DATABASE IF NOT EXISTS bd_clients CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bd_clients;

GRANT ALL PRIVILEGES ON bd_clients.* TO 'cantelcox'@'%';

-- Party table
DROP TABLE IF EXISTS party;
CREATE TABLE party (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(150) NOT NULL,
    firstName VARCHAR(100) NOT NULL,
    lastName VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phoneNumber VARCHAR(15),
    city VARCHAR(75),
    country VARCHAR(75),
    postalCode VARCHAR(15),
    stateOrProvince VARCHAR(25),
    street1 VARCHAR(50),
    street2 VARCHAR(50),
    isOrganization BIT,
    username VARCHAR(75),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    partyStatus VARCHAR(25) DEFAULT 'ACTIVE'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO party (firstName, lastName, uuid, email, username) VALUES
('Vincent', 'de Grandpré', '2dd68aef-1868-46a9-ac0b-2c1f21a2c53d', 'vincent.de-grandpre.1@ens.etsmtl.ca','operateur'),
('Abonné', 'CanTelcoX', '5e4e94c4-81c9-41f6-9935-782f6f88829c', 'test-cantelcox@de-grandpre.quebec','abonne');
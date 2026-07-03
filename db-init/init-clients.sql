-- Create database
CREATE DATABASE IF NOT EXISTS bd_clients;
USE bd_clients;

GRANT ALL PRIVILEGES ON bd_clients.* TO 'cantelcox'@'%';

-- Party table
DROP TABLE IF EXISTS party;
CREATE TABLE party (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(150) NOT NULL,
    name VARCHAR(100) NOT NULL,
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO party (name, uuid, email, username) VALUES
('Vincent de Grandpré', UUID(), 'vincent.de-grandpre.1@ens.etsmtl.ca','operateur'),
('Abonné', UUID(), 'test-cantelcox@de-grandpre.quebec','abonne');
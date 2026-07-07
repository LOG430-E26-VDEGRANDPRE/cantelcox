# CanTelcoX - Système de Gestion pour Opérateur Mobile Canadien

**École de technologie supérieure (ÉTS) - LOG430 - Été 2026**
**Auteur : Vincent de Grandpré, DEGV03078209**

## Aperçu du Projet

CanTelcoX est une architecture de microservices conçue pour un opérateur mobile canadien, implémentant un système complet de gestion des clients, des commandes, de la facturation et des services mobiles. Le système suit les principes de l'architecture hexagonale et utilise des technologies modernes pour assurer la scalabilité, la résilience et l'observabilité.

## Architecture Globale

Le système est composé de 7 microservices principaux, chacun responsable d'un domaine métier spécifique :

1. **svc-catalogue** - Gestion des offres produits et du catalogue
2. **svc-clients** - Gestion des clients et de l'authentification
3. **svc-commandes** - Gestion des commandes et des produits
4. **svc-facturation** - Facturation et gestion des paiements
5. **svc-lignes** - Gestion des lignes mobiles et services (intègre free5GC)
6. **svc-audit** - Conformité et audit (en développement)
7. **svc-orchestration** - Orchestration des sagas de commandes

## Diagrammes Clés

### Diagramme de Contexte

Le système CanTelcoX interagit avec plusieurs acteurs externes :

- **Abonnés** : Clients finaux via HTTPS/JSON
- **Opérations** : Équipe interne pour la gestion des factures
- **Conformité** : Notification des anomalies (PUB/SUB)
- **Régulateur** : Audit d'usage et facturation (GraphQL)
- **Processeur de paiement** : Exécution des paiements
- **Réseau (HLR/HSS)** : Provisionnement des services mobiles
- **ANC** : Bassin de numéros de téléphone (SOAP/XML)

### Cartographie des Contextes

Les bounded contexts identifiés sont :

- **Clients et identités** : Gestion des parties (Party)
- **Catalogue et offres** : Gestion des produits et offres (ProductCatalog, ProductOffering)
- **Commandes et activations** : Gestion des commandes (ProductOrder, Product)
- **Lignes et services** : Gestion des services mobiles
- **Usage, tarification et facturation** : Facturation client (CustomerBill, Usage)
- **Conformité et audit** : Détection d'anomalies et anti-fraude

### Cas d'Utilisation Principaux

1. **UC-01** : Inscription et vérification d'identité
2. **UC-02** : Authentification et MFA
3. **UC-03** : Activation d'une ligne mobile
4. **UC-04** : Consultation de l'usage et des factures
5. **UC-05** : Prise de commande / souscription à un forfait
6. **UC-06** : Paiement de facture mobile
7. **UC-07** : Détection de fraude
8. **UC-08** : Cycle de facturation mensuel

## Services en Détail

### 1. svc-catalogue

**Responsabilité** : Gestion du catalogue des offres produits

**Fonctionnalités** :
- Création, lecture, mise à jour et suppression des offres produits
- Gestion des stocks
- Validation des offres disponibles

**Endpoints principaux** :
- `GET /v1/productoffering/<offering_ids>` - Récupérer une offre spécifique
- `GET /v1/productofferings` - Lister toutes les offres
- `POST /v1/productoffering` - Créer une nouvelle offre
- `PUT /v1/stocks` - Définir le stock
- `PATCH /v1/stocks` - Mettre à jour le stock

**Technologies** : Flask, MongoDB, OpenTelemetry

### 2. svc-clients

**Responsabilité** : Gestion des clients et authentification

**Fonctionnalités** :
- Création et gestion des utilisateurs (Party)
- Authentification avec JWT
- Vérification d'identité
- Support MFA (Multi-Factor Authentication)

**Endpoints principaux** :
- `GET /v1/party/<user_id>` - Récupérer un client
- `POST /v1/party` - Créer un nouveau client
- `POST /v1/auth` - Authentification
- `DELETE /v1/party/<user_id>` - Supprimer un client

**Technologies** : Flask, PostgreSQL, JWT, OpenTelemetry

### 3. svc-commandes

**Responsabilité** : Gestion des commandes et des produits

**Fonctionnalités** :
- Création et suivi des commandes
- Gestion des produits associés aux commandes
- Intégration avec le catalogue pour validation
- Idempotence des commandes
- Support des sagas pour les transactions distribuées

**Endpoints principaux** :
- `GET /v1/orders/<order_id>` - Récupérer une commande
- `POST /v1/orders` - Créer une commande
- `GET /v1/products/<product_id>` - Récupérer un produit
- `POST /v1/products` - Créer un produit
- `PUT /v1/orders` - Mettre à jour une commande

**Technologies** : Flask, PostgreSQL, Architecture Hexagonale, OpenTelemetry

### 4. svc-facturation

**Responsabilité** : Facturation et gestion des paiements

**Fonctionnalités** :
- Création et gestion des factures client (CustomerBill)
- Suivi de l'usage des services (CDR - Call Detail Records)
- Processing des paiements par carte de crédit
- Gestion des cycles de facturation
- Calcul des montants dus

**Endpoints principaux** :
- `GET /v1/customerbills/<customerbill_id>` - Récupérer une facture
- `POST /v1/customerbills` - Créer une facture
- `POST /v1/usage` - Enregistrer de l'usage
- `POST /v1/payments` - Créer un paiement
- `PATCH /v1/payments/process/<payment_id>` - Traiter un paiement

**Technologies** : Flask, PostgreSQL, OpenTelemetry

### 5. svc-lignes

**Responsabilité** : Gestion des lignes mobiles et services

**Fonctionnalités** :
- Intégration avec free5GC (UDM/UDR)
- Provisionnement des abonnés mobiles
- Simulation de réseau HLR/HSS
- Gestion des services mobiles
- Enregistrement et consultation des CDR (Call Detail Records)

**Composants** :
- **WebConsole** : Interface de provisionnement (port 5050)
- **MongoDB** : Stockage des données d'usage et d'abonnés
- **UDM** : Unified Data Management (port 8000)
- **usage-api** : Façade REST pour la gestion des CDR (port 8090)

**Technologies** : free5GC v4.1.0, MongoDB, Docker, REST API

### 6. svc-audit

**Responsabilité** : Conformité et audit (en développement)

**Fonctionnalités prévues** :
- Détection des anomalies
- Notification des événements de conformité
- Audit des usages et facturations
- Anti-fraude

### 7. svc-orchestration

**Responsabilité** : Orchestration des sagas de commandes

**Fonctionnalités** :
- Coordination des transactions distribuées
- Implémentation du pattern Saga
- Gestion des étapes de commande :
  - Vérification de l'offre
  - Vérification de l'acheteur
  - Création de la commande
  - Réduction du stock
  - Activation du service
  - Création de la facture client
  - Création du paiement
- Gestion des échecs et compensation

**Endpoints principaux** :
- `POST /v1/saga/order` - Démarrer une saga de commande

**Technologies** : Flask, OpenTelemetry, OAuth2/Keycloak

## Flux Principaux

### 1. Souscription à un Forfait (UC-05)

1. Le client sélectionne une offre dans le catalogue (svc-catalogue)
2. Le système vérifie la disponibilité et le stock
3. Une commande est créée (svc-commandes)
4. La saga d'orchestration coordonne :
   - Validation de l'offre
   - Validation du client
   - Création de la commande
   - Réduction du stock
   - Activation de la ligne mobile (svc-lignes)
   - Création de la facture (svc-facturation)
5. Le client reçoit confirmation et accès au service

### 2. Cycle de Facturation Mensuel (UC-08)

1. Le service de facturation récupère l'usage depuis svc-lignes
2. Calcul des montants dus basé sur les tarifs
3. Génération des factures pour chaque client
4. Notification des clients
5. Processing des paiements

### 3. Authentification et MFA (UC-02)

1. Le client soumet ses identifiants (svc-clients)
2. Vérification initiale des informations
3. Génération d'un jeton JWT
4. Si MFA activé, vérification du code OTP
5. Accès accordé aux services

## Technologies et Outils

### Langages et Frameworks

- **Python** : Langage principal pour tous les microservices
- **Flask** : Framework web pour les API REST
- **SQLAlchemy** : ORM pour les bases de données relationnelles
- **Pydantic** : Validation des données

### Bases de Données

- **PostgreSQL** : Utilisé par svc-clients, svc-commandes, svc-facturation
- **MongoDB** : Utilisé par svc-lignes pour le stockage des CDR

### Observabilité

- **OpenTelemetry** : Tracing distribué
- **Jaeger** : Visualisation des traces
- **Prometheus** : Métriques et monitoring
- **Grafana** : Tableaux de bord (non montré dans les diagrammes)

### Infrastructure

- **Docker** : Conteneurisation des services
- **Docker Compose** : Orchestration locale
- **free5GC** : Cœur 5G pour la simulation réseau

### Sécurité

- **JWT** : Authentification des utilisateurs
- **OAuth2** : Intégration avec Keycloak
- **MFA** : Authentification multi-facteurs
- **HTTPS** : Communication sécurisée

## Déploiement

Chaque microservice possède son propre fichier `docker-compose.yml` pour le déploiement local. Le système est conçu pour être déployé dans un environnement Kubernetes en production.

### Prérequis

- Docker et Docker Compose
- Python 3.9+
- Accès à un registre Docker (pour les images personnalisées)

### Démarrage Local

1. Cloner le dépôt
2. Naviguer vers chaque service et exécuter :
   ```bash
   docker compose up -d
   ```
3. Le service svc-lignes nécessite un démarrage préalable en raison de ses dépendances free5GC

## Architecture Hexagonale

Les microservices suivent les principes de l'architecture hexagonale (ports and adapters) :

- **Ports** : Interfaces définissant les capacités du domaine
- **Adapters** : Implémentations concrètes pour les bases de données, API externes, etc.
- **Domain** : Logique métier pure, indépendante des détails techniques

Cette séparation permet :
- Une meilleure testabilité
- Une indépendance vis-à-vis des technologies
- Une évolution plus aisée du système

## Pattern Saga

Le service d'orchestration implémente le pattern Saga pour gérer les transactions distribuées :

1. **Saga Orchestrator** : Coordonne les étapes
2. **Handlers** : Chaque étape est un handler spécifique
3. **Compensation** : Mécanismes de rollback en cas d'échec
4. **État** : Suivi de l'état de la saga

Les étapes typiques d'une saga de commande :
1. Vérification de l'offre (VerifyOfferingHandler)
2. Vérification de l'acheteur (VerifyBuyerHandler)
3. Création de la commande (CreateOrderHandler)
4. Réduction du stock (DecreaseStockHandler)
5. Activation du service (ActivateServiceHandler)
6. Création de la facture (CreateCustomerBillHandler)
7. Création du paiement (CreatePaymentHandler)

## Intégration avec free5GC

Le service svc-lignes intègre free5GC pour simuler un réseau mobile :

- **UDM** (Unified Data Management) : Gestion des données d'abonnés
- **UDR** (Unified Data Repository) : Stockage des données
- **WebConsole** : Interface de provisionnement
- **usage-api** : Façade REST pour la gestion des CDR

Cette intégration permet :
- Le provisionnement réel des abonnés mobiles
- La simulation d'usage (appels, données, SMS)
- La récupération des CDR pour la facturation

## Observabilité et Monitoring

Chaque service est instrumenté avec :

- **OpenTelemetry** : Pour le tracing distribué
- **Prometheus** : Pour les métriques
- **Jaeger** : Pour la visualisation des traces

Exemple de métriques exposées :
- Nombre d'appels par endpoint
- Temps de réponse
- Taux d'erreur
- Métriques spécifiques au domaine (ex: commandes créées, paiements traités)

## Sécurité

### Authentification

- **JWT** : Jetons pour l'authentification des utilisateurs
- **OAuth2** : Intégration avec Keycloak pour l'orchestration
- **MFA** : Authentification multi-facteurs optionnelle

### Autorisation

- Basée sur les rôles (RBAC)
- Contrôle d'accès aux endpoints sensibles
- Validation des jetons pour chaque requête

### Protection des Données

- Chiffrement des données sensibles
- Communication HTTPS entre services
- Masquage des informations sensibles dans les logs

## Tests

Chaque microservice devrait inclure :

- Tests unitaires pour la logique métier
- Tests d'intégration pour les adapters
- Tests end-to-end pour les flux principaux
- Tests de performance pour les endpoints critiques

(Note : Les tests ne sont pas visibles dans la structure actuelle mais devraient être présents dans une implémentation complète)

## Documentation Complémentaire

La documentation détaillée inclut :

- Diagrammes PlantUML dans `./docs/diagrammes/`
- Spécifications des API (OpenAPI/Swagger)
- Collections Postman pour les tests d'API
- Documentation d'architecture dans chaque service

## Contribution

Ce projet suit les bonnes pratiques de développement :

- Conventions de nommage cohérentes
- Documentation du code
- Validation des données en entrée
- Gestion des erreurs appropriée
- Journalisation structurée
- Tests automatisés

## Licence

Le projet est développé dans un cadre académique à l'ÉTS Montréal. Les composants tiers (comme free5GC) sont sous leurs licences respectives (ex: Apache 2.0 pour free5GC).

## Contact

Pour toute question concernant ce projet, contacter :
- Vincent de Grandpré (DEGV03078209)
- École de technologie supérieure (ÉTS), Montréal
- Cours LOG430 - Architecture logicielle

## Remerciements

Ce projet s'appuie sur plusieurs technologies open-source et frameworks académiques. Nous remercions particulièrement les contributeurs de free5GC, OpenTelemetry et Flask pour leurs excellents outils.

## Infrastructure Conteneurisée

Ce référentiel principal fournit les services d'infrastructure suivants :

- **Prometheus** : Collecte et stockage des métriques
- **Grafana** : Visualisation des métriques
- **KrakenD** : API Gateway
- **MySQL** : Base de données relationnelle
- **MongoDB** : Base de données NoSQL
- **PostgreSQL** : Base de données relationnelle
- **Redis** : Cache et gestion de session
- **Jaeger** : Tracing distribué

## Dépendances

Tous les services doivent être présents dans l'arborescence (les dossiers svc-* sont dans .gitignore) afin que le docker-compose de ce référentiel puisse les inclure.
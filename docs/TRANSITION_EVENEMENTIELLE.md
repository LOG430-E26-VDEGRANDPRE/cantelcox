# Transition vers une Saga Chorégraphiée Événementielle avec Kafka

Ce document décrit la structure implémentée pour permettre aux services CanTelcoX de recevoir et d'émettre des événements sur le bus Kafka, facilitant ainsi la transition d'une saga orchestrée vers une saga chorégraphiée (événementielle).

## Analyse AsyncAPI

Le fichier `asyncapi.yml` a été analysé pour identifier les opérations (receive/send) pour chaque service d'intérêt. Voici les opérations identifiées :

### svc-lignes
- **RECEIVE (consommation):** 
  - `popAbusUsage` (topic: `audit.abus-usage`)
  - `popDoProvisionActions` (topic: `saga.order-do-provision`)
- **SEND (émission):** 
  - `pushServiceVerified` (topic: `lignes.service-verified`)
  - `pushServiceProvisionOk` (topic: `lignes.service-provision-ok`)
  - `pushServiceProvisionKo` (topic: `lignes.service-provision-ko`)

### svc-commandes
- **RECEIVE:** 
  - `popOrderSagaSubmitted` (topic: `saga.order-submitted`)
- **SEND:** Aucun

### svc-catalogue
- **RECEIVE:** 
  - `popOrderDraft` (topic: `commande.order-draft`)
  - `popOrderCreated` (topic: `commande.order-created`)
  - `popOrderCancelled` (topic: `commande.order-cancelled`)
- **SEND:** 
  - `pushOfferingsVerified` (topic: `catalogue.offerings-verified`)
  - `pushOfferingsInvalid` (topic: `catalogue.offerings-invalid`)
  - `pushStockDecreased` (topic: `catalogue.stock-decreased`)
  - `pushStockIncreased` (topic: `catalogue.stock-increased`)

### svc-facturation
- **RECEIVE:** 
  - `popAbusUsage` (topic: `audit.abus-usage`)
  - `popDoInvoicing` (topic: `saga.order-do-invoicing`)
- **SEND:** 
  - `pushBillcycleCreated` (topic: `facturation.billcycle-created`)
  - `pushCustomerbillCreated` (topic: `facturation.customerbill-created`)
  - `pushPaymentProcessed` (topic: `facturation.payment-processed`)
  - `pushPaymentDelinquant` (topic: `facturation.payment-delinquant`)

### svc-orchestration
- **RECEIVE (9 opérations):** 
  - `popAlerteFraude` (topic: `audit.alerte-fraude`)
  - `popOfferingsVerified` (topic: `catalogue.offerings-verified`)
  - `popOfferingsInvalid` (topic: `catalogue.offerings-invalid`)
  - `popStockDecreased` (topic: `catalogue.stock-decreased`)
  - `popStockIncreased` (topic: `catalogue.stock-increased`)
  - `popBuyerVerified` (topic: `client.buyer-verified`)
  - `popBuyerInvalid` (topic: `client.buyer-invalid`)
  - `popServiceVerified` (topic: `lignes.service-verified`)
  - `popServiceProvisionOk` (topic: `lignes.service-provision-ok`)
- **SEND (6 opérations):** 
  - `pushOrderSagaSubmitted` (topic: `saga.order-submitted`)
  - `pushOrderValidationsOk` (topic: `saga.order-validations-ok`)
  - `pushOrderValidationsKo` (topic: `saga.order-validations-ko`)
  - `pushDoProvisionActions` (topic: `saga.order-do-provision`)
  - `pushDoInvoicing` (topic: `saga.order-do-invoicing`)
  - `pushOrderSagaEnded` (topic: `saga.order-ended`)

## Structure de Fichiers Créée

Pour chaque service, la structure suivante a été créée (inspirée de svc-audit) :

```
src/
├── config.py                          # Configuration avec tous les topics Kafka
├── logger.py                          # Classe Logger (si non existante)
├── adapters/
│   ├── __init__.py
│   ├── inbound/
│   │   ├── __init__.py
│   │   └── messaging/
│   │       ├── __init__.py
│   │       └── kafka_consumer.py     # Adaptateur pour consommer les événements
│   └── out/
│       ├── __init__.py
│       └── messaging/
│           ├── __init__.py
│           └── kafka_producer.py     # Adaptateur pour publier les événements
└── application/
    ├── __init__.py
    └── services/
        └── __init__.py              # Pour les services d'application futurs
```

## Fichiers Créés par Service

### 1. svc-lignes (dans `usage-api/src/`)
- **config.py** - Configuration avec les topics:
  - `KAFKA_ABUS_USAGE_TOPIC`
  - `KAFKA_DO_PROVISION_ACTIONS_TOPIC`
  - `KAFKA_SERVICE_VERIFIED_TOPIC`
  - `KAFKA_SERVICE_PROVISION_OK_TOPIC`
  - `KAFKA_SERVICE_PROVISION_KO_TOPIC`
- **logger.py** - Classe Logger
- **adapters/inbound/messaging/kafka_consumer.py** - Consommateur Kafka pour les topics en réception
- **adapters/out/messaging/kafka_producer.py** - Producteur Kafka pour les topics en émission

### 2. svc-commandes (dans `src/`)
- **config.py** - Mise à jour avec:
  - `KAFKA_ORDER_SAGA_SUBMITTED_TOPIC`
- **adapters/inbound/messaging/kafka_consumer.py** - Consommateur Kafka
- **adapters/out/messaging/kafka_producer.py** - Producteur Kafka

### 3. svc-catalogue (dans `src/`)
- **config.py** - Mise à jour avec:
  - `KAFKA_ORDER_DRAFT_TOPIC`
  - `KAFKA_ORDER_CREATED_TOPIC`
  - `KAFKA_ORDER_CANCELLED_TOPIC`
  - `KAFKA_OFFERINGS_VERIFIED_TOPIC`
  - `KAFKA_OFFERINGS_INVALID_TOPIC`
  - `KAFKA_STOCK_DECREASED_TOPIC`
  - `KAFKA_STOCK_INCREASED_TOPIC`
- **adapters/inbound/messaging/kafka_consumer.py** - Consommateur Kafka
- **adapters/out/messaging/kafka_producer.py** - Producteur Kafka

### 4. svc-facturation (dans `src/`)
- **config.py** - Mise à jour avec:
  - `KAFKA_ABUS_USAGE_TOPIC`
  - `KAFKA_DO_INVOICING_TOPIC`
  - `KAFKA_BILLCYCLE_CREATED_TOPIC`
  - `KAFKA_CUSTOMERBILL_CREATED_TOPIC`
  - `KAFKA_PAYMENT_PROCESSED_TOPIC`
  - `KAFKA_PAYMENT_DELINQUANT_TOPIC`
- **adapters/inbound/messaging/kafka_consumer.py** - Consommateur Kafka
- **adapters/out/messaging/kafka_producer.py** - Producteur Kafka

### 5. svc-orchestration (dans `src/`)
- **config.py** - Mise à jour avec:
  - Variables MySQL pour Outbox: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
  - `OUTBOX_POLL_INTERVAL` pour le polling des événements Outbox
  - **Topics RECEIVE (pop)** où svc-orchestration est clientId:
    - `KAFKA_ALERTE_FRAUDE_TOPIC`, `KAFKA_OFFERINGS_VERIFIED_TOPIC`, `KAFKA_OFFERINGS_INVALID_TOPIC`
    - `KAFKA_STOCK_DECREASED_TOPIC`, `KAFKA_STOCK_INCREASED_TOPIC`
    - `KAFKA_BUYER_VERIFIED_TOPIC`, `KAFKA_BUYER_INVALID_TOPIC`
    - `KAFKA_SERVICE_VERIFIED_TOPIC`, `KAFKA_SERVICE_PROVISION_OK_TOPIC`
  - **Topics SEND (push)** où svc-orchestration est clientId:
    - `KAFKA_ORDER_SAGA_SUBMITTED_TOPIC`, `KAFKA_ORDER_VALIDATIONS_OK_TOPIC`
    - `KAFKA_ORDER_VALIDATIONS_KO_TOPIC`, `KAFKA_DO_PROVISION_ACTIONS_TOPIC`
    - `KAFKA_DO_INVOICING_TOPIC`, `KAFKA_ORDER_SAGA_ENDED_TOPIC`
- **svc_orchestration.py** - Fichier principal avec:
  - Initialisation du HandlerRegistry et enregistrement des **9 handlers** (uniquement pour les opérations RECEIVE)
  - Initialisation du pattern Outbox (session_factory, outbox_repository, outbox_publisher)
  - Thread Kafka consumer pour consommer les événements (uniquement les topics RECEIVE)
  - OrchestrationEventProducer pour publier via Outbox
  - Intégration OpenTelemetry pour le tracing
- **adapters/inbound/messaging/kafka_consumer.py** - Consommateur Kafka avec **uniquement les 9 topics RECEIVE**
- **adapters/out/messaging/kafka_producer.py** - Producteur Kafka
- **adapters/out/messaging/outbox_publisher.py** - Publicateur Outbox (thread daemon)
- **adapters/out/persistence/entities.py** - Entité OutboxEntity
- **adapters/out/persistence/session_factory.py** - Fabrique de sessions MySQL
- **adapters/out/persistence/sqlalchemy_outbox_repository.py** - Repository Outbox
- **application/services/orchestration_event_producer.py** - Service pour publier via Outbox
- **event_management/handlers/** - **9 handlers** pour les opérations RECEIVE:
  - AlerteFraudeHandler, OfferingsVerifiedHandler, OfferingsInvalidHandler
  - StockDecreasedHandler, StockIncreasedHandler
  - BuyerVerifiedHandler, BuyerInvalidHandler
  - ServiceVerifiedHandler, ServiceProvisionOkHandler
- **db-init/init.sql** - Script de création de la table Outbox
- **docker-compose.yml** - Ajout du service MySQL pour Outbox
- **requirements.txt** - Ajout de SQLAlchemy et PyMySQL
- **.env et .env.example** - Ajout des variables MySQL et Outbox

## Implémentation des Adaptateurs

Les adaptateurs Kafka suivent le même pattern que svc-audit :

### KafkaConsumerAdapter
```python
import json
from kafka import KafkaConsumer
from config import (
    KAFKA_HOST,
    TOPIC_1,
    TOPIC_2,
    KAFKA_GROUP_ID,
    KAFKA_AUTO_OFFSET_RESET,
)
from logger import Logger

logger = Logger.get_instance("KafkaConsumerAdapter")

class KafkaConsumerAdapter:
    def __init__(self):
        # Liste des topics à consommer
        topics = [
            TOPIC_1,
            TOPIC_2,
        ]

        logger.debug(f"Topics Kafka à écouter: {topics}")

        self.consumer = KafkaConsumer(
            *topics,
            bootstrap_servers=KAFKA_HOST,
            group_id=KAFKA_GROUP_ID,
            auto_offset_reset=KAFKA_AUTO_OFFSET_RESET,
            value_deserializer=lambda m: json.loads(m.decode("utf-8")),
        )

    def consume(self):
        for message in self.consumer:
            yield message.value

    def commit(self) -> None:
        self.consumer.commit()
```

### KafkaProducerAdapter
```python
import json
from kafka import KafkaProducer
from config import KAFKA_HOST

class KafkaProducerAdapter:
    def __init__(self):
        self.producer = KafkaProducer(
            bootstrap_servers=KAFKA_HOST,
            value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        )

    def publish(self, topic: str, event: dict) -> None:
        future = self.producer.send(topic, event)
        future.get(timeout=10)
```

## Utilisation des Adaptateurs

Les services peuvent maintenant :

1. **Instancier les adaptateurs** dans leur code principal:
```python
from adapters.inbound.messaging.kafka_consumer import KafkaConsumerAdapter
from adapters.out.messaging.kafka_producer import KafkaProducerAdapter

consumer = KafkaConsumerAdapter()
producer = KafkaProducerAdapter()
```

2. **Consommer les événements** :
```python
for event in consumer.consume():
    # Traiter l'événement
    print(f"Événement reçu: {event}")
    # Appeler consumer.commit() si nécessaire
```

3. **Publier des événements** :
```python
event_data = {
    "event_type": "ServiceVerified",
    "aggregate_id": 123,
    "payload": {"service_id": 456, "status": "verified"}
}
producer.publish("lignes.service-verified", event_data)
```

4. **Intégrer avec le pattern Outbox** (comme svc-audit) pour une publication fiable des événements

## Configuration Kafka

Chaque service a sa propre configuration dans `config.py` avec :
- `KAFKA_HOST` - Adresse du broker Kafka (par défaut: `kafka:9092`)
- `KAFKA_GROUP_ID` - Identifiant du groupe de consommateurs (ex: `lignes-group`)
- `KAFKA_AUTO_OFFSET_RESET` - Stratégie de réinitialisation des offsets (par défaut: `earliest`)
- Tous les topics spécifiques au service avec des valeurs par défaut basées sur le contrat AsyncAPI

## Classes Handler pour les Opérations RECEIVE

Pour chaque opération RECEIVE identifiée dans le contrat AsyncAPI, des classes Handler ont été créées suivant le pattern de svc-audit :

### Structure des Handlers

```
src/event_management/
├── __init__.py
├── base_handler.py          # Classe abstraite EventHandler
├── handler_registry.py      # Registry pour gérer les handlers
└── handlers/
    ├── __init__.py
    ├── [operation_name]_handler.py  # Handler spécifique pour chaque opération
```

### Classe de Base EventHandler

```python
from abc import ABC, abstractmethod
from typing import Dict, Any
from logger import Logger

class EventHandler(ABC):
    """Base class for all event handlers"""

    def __init__(self):
        """ Constructor method """
        self.logger = Logger.get_instance('Handler')
    
    @abstractmethod
    def handle(self, event_data: Dict[str, Any]) -> None:
        """Process the event data"""
        pass
    
    @abstractmethod
    def get_event_type(self) -> str:
        """Return the event type this handler processes"""
        pass
```

### Handler Registry

```python
from typing import Dict
from event_management.base_handler import EventHandler
from logger import Logger

class HandlerRegistry:
    """Registry for mapping event types to their handlers"""
    
    def __init__(self):
        self._handlers: Dict[str, EventHandler] = {}
    
    def register(self, handler: EventHandler) -> None:
        """Register a new event handler"""
        event_type = handler.get_event_type()
        self._handlers[event_type] = handler
    
    def get_handler(self, event_type: str) -> EventHandler:
        """Get handler for a specific event type"""
        return self._handlers.get(event_type)
    
    def has_handler(self, event_type: str) -> bool:
        """Check if a handler exists for an event type"""
        return event_type in self._handlers
    
    def get_supported_events(self) -> list:
        """Get list of supported event types"""
        return list(self._handlers.keys())
```

### Handlers par Service

#### svc-lignes (2 handlers)
- `AbusUsageHandler` - Traite les événements `AbusUsage` (popAbusUsage)
- `DoProvisionActionsHandler` - Traite les événements `DoProvisionActions` (popDoProvisionActions)

#### svc-commandes (1 handler)
- `OrderSagaSubmittedHandler` - Traite les événements `OrderSagaSubmitted` (popOrderSagaSubmitted)

#### svc-catalogue (3 handlers)
- `OrderDraftHandler` - Traite les événements `OrderDraft` (popOrderDraft)
- `OrderCreatedHandler` - Traite les événements `OrderCreated` (popOrderCreated)
- `OrderCancelledHandler` - Traite les événements `OrderCancelled` (popOrderCancelled)

#### svc-facturation (2 handlers)
- `AbusUsageHandler` - Traite les événements `AbusUsage` (popAbusUsage)
- `DoInvoicingHandler` - Traite les événements `DoInvoicing` (popDoInvoicing)

#### svc-orchestration (9 handlers)
- `AlerteFraudeHandler` - Traite les événements `DetectionFraude` (popAlerteFraude)
- `OfferingsVerifiedHandler` - Traite les événements `OfferingsVerified` (popOfferingsVerified)
- `OfferingsInvalidHandler` - Traite les événements `OfferingsInvalid` (popOfferingsInvalid)
- `StockDecreasedHandler` - Traite les événements `StockDecreased` (popStockDecreased)
- `StockIncreasedHandler` - Traite les événements `StockIncreased` (popStockIncreased)
- `BuyerVerifiedHandler` - Traite les événements `BuyerVerified` (popBuyerVerified)
- `BuyerInvalidHandler` - Traite les événements `BuyerInvalid` (popBuyerInvalid)
- `ServiceVerifiedHandler` - Traite les événements `ServiceVerified` (popServiceVerified)
- `ServiceProvisionOkHandler` - Traite les événements `ServiceProvisionOk` (popServiceProvisionOk)

### Exemple de Handler

```python
"""
Handler: OrderSagaSubmitted for popOrderSagaSubmitted operation
SPDX-License-Identifier: LGPL-3.0-or-later
"""

from typing import Dict, Any
from event_management.base_handler import EventHandler
from logger import Logger

logger = Logger.get_instance("OrderSagaSubmittedHandler")

class OrderSagaSubmittedHandler(EventHandler):
    """Handles OrderSagaSubmitted events for popOrderSagaSubmitted operation"""
    
    def get_event_type(self) -> str:
        """Return the event type this handler processes"""
        return "OrderSagaSubmitted"
    
    def handle(self, event_data: Dict[str, Any]) -> None:
        """Process OrderSagaSubmitted event data"""
        logger.info(f"OrderSagaSubmitted event received: {event_data}")
        payload = event_data.get("payload", {})
        logger.debug(f"Saga de commande soumise: {payload}")
        # TODO: Ajouter la logique métier pour traiter la soumission de saga
        # Exemple: Créer une nouvelle commande, initialiser le processus, etc.
```

## Intégration des Composants

### Utilisation Typique

```python
# 1. Importer les composants nécessaires
from adapters.inbound.messaging.kafka_consumer import KafkaConsumerAdapter
from adapters.out.messaging.kafka_producer import KafkaProducerAdapter
from event_management.handler_registry import HandlerRegistry
from event_management.handlers.order_saga_submitted_handler import OrderSagaSubmittedHandler

# 2. Initialiser les composants
consumer = KafkaConsumerAdapter()
producer = KafkaProducerAdapter()
registry = HandlerRegistry()

# 3. Enregistrer les handlers
registry.register(OrderSagaSubmittedHandler())
# ... enregistrer d'autres handlers

# 4. Consommer les événements et les traiter
for event_data in consumer.consume():
    event_type = event_data.get("event_type")
    handler = registry.get_handler(event_type)
    if handler:
        handler.handle(event_data)
    else:
        logger.warning(f"Aucun handler trouvé pour le type d'événement: {event_type}")
    consumer.commit()

# 5. Publier des événements
producer.publish("saga.order-submitted", {
    "event_type": "OrderSagaSubmitted",
    "payload": {"order_id": 123, "status": "submitted"}
})
```

## Prochaines Étapes

La structure complète est prête pour la transition de la saga orchestrée vers la saga chorégraphiée événementielle avec Kafka. Les prochaines étapes pourraient inclure :

1. **Intégration des adaptateurs** dans le code principal de chaque service
2. **Implémentation de la logique métier** dans les handlers (remplacer les TODO)
3. **Création des services d'application** pour orchestrer la logique métier
4. **Implémentation du pattern Outbox** pour une publication fiable des événements
5. **Tests d'intégration** pour valider le flux événementiel

## Pattern Outbox pour Publication Fiable

Tous les services implémentent le **pattern Outbox** pour garantir une publication fiable des événements sur Kafka, suivant l'exemple de svc-audit. Ce pattern permet de :

- **Stocker les événements** dans une base de données avant publication
- **Garantir l'atomicité** : l'événement est persistant avant d'être publié
- **Assurer la livraison** : même en cas d'échec temporaire de Kafka
- **Permettre la reprise** : les événements non publiés sont republiés automatiquement

### Structure du Pattern Outbox

Pour chaque service, les composants suivants ont été créés :

```
src/adapters/out/persistence/
├── __init__.py
├── entities.py                  # Entité OutboxEntity (SQLAlchemy)
├── session_factory.py          # Fabrique de sessions MySQL
└── sqlalchemy_outbox_repository.py  # Repository pour accéder à la table Outbox

src/adapters/out/messaging/
├── __init__.py
├── kafka_producer.py            # Producteur Kafka (existant)
└── outbox_publisher.py          # Publicateur Outbox (thread daemon)

src/application/services/
└── [service]_event_producer.py  # Service pour publier via Outbox

db-init/init.sql                 # Script de création de la table Outbox
```

### Composants du Pattern Outbox

#### 1. Entité Outbox (entities.py)

```python
from sqlalchemy import BigInteger, Boolean, Column, DateTime, Integer, JSON, String, text
from sqlalchemy.orm import declarative_base

Base = declarative_base()

class OutboxEntity(Base):
    """Événement en attente de publication vers Kafka."""
    __tablename__ = "outbox"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    topic = Column(String(100), nullable=False)
    aggregate_type = Column(String(100), nullable=False)
    aggregate_id = Column(BigInteger, nullable=False)
    event_type = Column(String(100), nullable=False)
    payload = Column(JSON, nullable=False)
    created_at = Column(DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    published = Column(Boolean, nullable=False, server_default=text("FALSE"))
```

#### 2. Repository Outbox (sqlalchemy_outbox_repository.py)

```python
from adapters.out.persistence.entities import OutboxEntity

class SqlAlchemyOutboxRepository:
    def __init__(self, session_factory):
        self._session_factory = session_factory
    
    def find_unpublished(self):
        """Trouve tous les événements non publiés, triés par date de création"""
        session = self._session_factory()
        try:
            return (
                session.query(OutboxEntity)
                .filter_by(published=False)
                .order_by(OutboxEntity.created_at)
                .all()
            )
        finally:
            session.close()
    
    def mark_published(self, event_id: int):
        """Marque un événement comme publié"""
        session = self._session_factory()
        try:
            event = session.get(OutboxEntity, event_id)
            if event is not None:
                event.published = True
                session.commit()
        except Exception:
            session.rollback()
            raise
        finally:
            session.close()
```

#### 3. OutboxPublisher (outbox_publisher.py)

```python
import threading
import time
from adapters.out.messaging.kafka_producer import KafkaProducerAdapter
from config import OUTBOX_POLL_INTERVAL
from logger import Logger

logger = Logger.get_instance("outbox_publisher.py")

class OutboxPublisher(threading.Thread):
    def __init__(self, repository):
        super().__init__(daemon=True)
        self.repository = repository
        self.producer = KafkaProducerAdapter()
    
    def run(self):
        while True:
            events = self.repository.find_unpublished()
            for event in events:
                try:
                    message = {
                        "event_id": event.id,
                        "event_type": event.event_type,
                        "aggregate_type": event.aggregate_type,
                        "aggregate_id": event.aggregate_id,
                        "created_at": event.created_at.isoformat(),
                        "payload": event.payload,
                    }
                    self.producer.publish(event.topic, message)
                    self.repository.mark_published(event.id)
                except Exception as e:
                    logger.error(f"Failed to publish outbox event {event.id}: {e}")
            time.sleep(OUTBOX_POLL_INTERVAL)
```

#### 4. Service Event Producer (orchestration_event_producer.py)

```python
from typing import Dict, Any
from adapters.out.persistence.entities import OutboxEntity
from adapters.out.persistence.session_factory import create_session_factory
from logger import Logger

logger = Logger.get_instance("OrchestrationEventProducer")

class OrchestrationEventProducer:
    """Service pour publier des événements via le patron Outbox"""
    
    def __init__(self, outbox_repository):
        self._outbox_repository = outbox_repository
    
    def send(self, topic: str, event_type: str, aggregate_type: str, aggregate_id: int, payload: Dict[str, Any]) -> None:
        """Enregistre un événement dans la table Outbox pour publication ultérieure"""
        session_factory = create_session_factory()
        session = session_factory()
        
        try:
            outbox_event = OutboxEntity(
                topic=topic,
                aggregate_type=aggregate_type,
                aggregate_id=aggregate_id,
                event_type=event_type,
                payload=payload,
                published=False
            )
            session.add(outbox_event)
            session.commit()
            logger.debug(f"Événement {event_type} enregistré dans Outbox pour le topic {topic}")
        except Exception as e:
            session.rollback()
            logger.error(f"Échec de l'enregistrement de l'événement {event_type} dans Outbox: {e}")
            raise
        finally:
            session.close()
```

#### 5. Table Outbox (init.sql)

```sql
-- Outbox table for event-driven architecture
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
```

### Intégration dans le Service Principal (svc_orchestration.py)

```python
# Initialiser la base de données et le patron Outbox
session_factory = create_session_factory()
outbox_repository = SqlAlchemyOutboxRepository(session_factory)
outbox_publisher = OutboxPublisher(outbox_repository)
outbox_publisher.start()  # Démarre le thread de publication

# Initialiser le producer pour publier via Outbox
orchestration_event_producer = OrchestrationEventProducer(outbox_repository)

# Utilisation pour publier un événement
orchestration_event_producer.send(
    topic="saga.order-submitted",
    event_type="OrderSagaSubmitted",
    aggregate_type="OrderSaga",
    aggregate_id=123,
    payload={"order_id": 456, "status": "submitted"}
)
```

### Configuration MySQL pour Outbox

Chaque service a besoin des variables d'environnement MySQL dans son `.env` :

```bash
# MySQL pour Outbox pattern
DB_HOST=mysql-[service]
DB_PORT=3306
DB_NAME=[service]
DB_USER=cantelcox
DB_PASSWORD=cantelcox

# Outbox polling interval (secondes)
OUTBOX_POLL_INTERVAL=2
```

Et dans `config.py` :

```python
# MySQL pour Outbox pattern
DB_HOST = os.getenv("DB_HOST")
DB_PORT = int(os.getenv("DB_PORT"))
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

# Outbox
OUTBOX_POLL_INTERVAL = int(os.getenv("OUTBOX_POLL_INTERVAL", 2))
```

### Dépendances Python supplémentaires

Dans `requirements.txt`, ajouter :

```
SQLAlchemy>=2.0
PyMySQL>=1.0
```

### Configuration Docker pour MySQL

Dans `docker-compose.yml`, ajouter le service MySQL :

```yaml
services:
  mysql-[service]:
    image: mysql:8.0
    container_name: mysql-[service]
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: [service]
      MYSQL_USER: cantelcox
      MYSQL_PASSWORD: cantelcox
    volumes:
      - ./db-init:/docker-entrypoint-initdb.d
    ports:
      - "3306:3306"
    networks:
      - cantelcox-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
```

Et mettre à jour le service principal pour dépendre de MySQL :

```yaml
svc_[service]:
  # ...
  depends_on:
    - mysql-[service]
    - kafka
  environment:
    # ...
    - DB_HOST=mysql-[service]
    - DB_PORT=3306
    - DB_NAME=[service]
    - DB_USER=cantelcox
    - DB_PASSWORD=cantelcox
    - OUTBOX_POLL_INTERVAL=2
```
6. **Configuration de Kafka** dans l'environnement Docker (ajout du service Kafka dans docker-compose.yml)
7. **Intégration avec les bases de données** pour persister l'état des sagas
8. **Gestion des erreurs et compensation** pour les échecs de traitement

## Configuration des Conteneurs

### Dépendances Python (requirements.txt)

Chaque service a les dépendances nécessaires pour fonctionner avec Kafka :

- **kafka-python==2.2.15** - Bibliothèque Python pour Kafka
- **python-dotenv>=1.0** - Pour charger les variables d'environnement

### Variables d'Environnement (.env et .env.example)

Chaque service a un fichier `.env` et `.env.example` contenant toutes les variables nécessaires :

#### Variables Kafka communes
```bash
KAFKA_HOST=kafka:9092
KAFKA_GROUP_ID=[nom-du-service]-group
KAFKA_AUTO_OFFSET_RESET=earliest
LOG_LEVEL=INFO
```

#### Variables spécifiques par service

**svc-lignes:**
```bash
# Topics RECEIVE
KAFKA_ABUS_USAGE_TOPIC=audit.abus-usage
KAFKA_DO_PROVISION_ACTIONS_TOPIC=saga.order-do-provision

# Topics SEND
KAFKA_SERVICE_VERIFIED_TOPIC=lignes.service-verified
KAFKA_SERVICE_PROVISION_OK_TOPIC=lignes.service-provision-ok
KAFKA_SERVICE_PROVISION_KO_TOPIC=lignes.service-provision-ko
```

**svc-commandes:**
```bash
# Topics RECEIVE
KAFKA_ORDER_SAGA_SUBMITTED_TOPIC=saga.order-submitted
```

**svc-catalogue:**
```bash
# Topics RECEIVE
KAFKA_ORDER_DRAFT_TOPIC=commande.order-draft
KAFKA_ORDER_CREATED_TOPIC=commande.order-created
KAFKA_ORDER_CANCELLED_TOPIC=commande.order-cancelled

# Topics SEND
KAFKA_OFFERINGS_VERIFIED_TOPIC=catalogue.offerings-verified
KAFKA_OFFERINGS_INVALID_TOPIC=catalogue.offerings-invalid
KAFKA_STOCK_DECREASED_TOPIC=catalogue.stock-decreased
KAFKA_STOCK_INCREASED_TOPIC=catalogue.stock-increased
```

**svc-facturation:**
```bash
# Topics RECEIVE
KAFKA_ABUS_USAGE_TOPIC=audit.abus-usage
KAFKA_DO_INVOICING_TOPIC=saga.order-do-invoicing

# Topics SEND
KAFKA_BILLCYCLE_CREATED_TOPIC=facturation.billcycle-created
KAFKA_CUSTOMERBILL_CREATED_TOPIC=facturation.customerbill-created
KAFKA_PAYMENT_PROCESSED_TOPIC=facturation.payment-processed
KAFKA_PAYMENT_DELINQUANT_TOPIC=facturation.payment-delinquant
```

**svc-orchestration:**
```bash
# Topics RECEIVE
KAFKA_ALERTE_FRAUDE_TOPIC=audit.alerte-fraude
KAFKA_OFFERINGS_VERIFIED_TOPIC=catalogue.offerings-verified
KAFKA_OFFERINGS_INVALID_TOPIC=catalogue.offerings-invalid
KAFKA_STOCK_DECREASED_TOPIC=catalogue.stock-decreased
KAFKA_STOCK_INCREASED_TOPIC=catalogue.stock-increased
KAFKA_BUYER_VERIFIED_TOPIC=client.buyer-verified
KAFKA_BUYER_INVALID_TOPIC=client.buyer-invalid
KAFKA_SERVICE_VERIFIED_TOPIC=lignes.service-verified
KAFKA_SERVICE_PROVISION_OK_TOPIC=lignes.service-provision-ok

# Topics SEND
KAFKA_ORDER_SAGA_SUBMITTED_TOPIC=saga.order-submitted
KAFKA_ORDER_VALIDATIONS_OK_TOPIC=saga.order-validations-ok
KAFKA_ORDER_VALIDATIONS_KO_TOPIC=saga.order-validations-ko
KAFKA_DO_PROVISION_ACTIONS_TOPIC=saga.order-do-provision
KAFKA_DO_INVOICING_TOPIC=saga.order-do-invoicing
KAFKA_ORDER_SAGA_ENDED_TOPIC=saga.order-ended
```

### Configuration Docker (docker-compose.yml)

Chaque service a une dépendance sur le service Kafka dans son docker-compose.yml :

```yaml
services:
  svc_[nom]:
    # ... autres configurations
    depends_on:
      # ... autres dépendances
      kafka:
        condition: service_healthy
    networks:
      - cantelcox-network
```

**Note importante:** Le service Kafka est défini dans `svc-orchestration/docker-compose.yml` avec un cluster de 3 nœuds. Tous les services peuvent accéder à ce cluster via le réseau `cantelcox-network`.

## Architecture Globale

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Réseau: cantelcox-network                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐              │
│  │ svc-lignes  │    │svc-commandes│    │svc-catalogue│              │
│  │  (usage-api)│    │             │    │             │              │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘              │
│         │                  │                 │                         │
│         └──────────────────┼─────────────────┘                         │
│                          │                                           │
│  ┌─────────────┐    ┌──────▼──────┐    ┌─────────────┐              │
│  │svc-facturation│   │svc-orchestration│   │   Kafka     │              │
│  │             │    │    (cluster)  │   │  (3 nœuds)  │              │
│  └─────────────┘    └─────────────┘    └─────────────┘              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Résumé des Fichiers Créés/Modifiés

### Pour chaque service (svc-lignes, svc-commandes, svc-catalogue, svc-facturation, svc-orchestration):

1. **requirements.txt** - Ajout de `kafka-python==2.2.15` et `python-dotenv>=1.0`
2. **.env** - Variables d'environnement Kafka spécifiques au service
3. **.env.example** - Template des variables d'environnement
4. **docker-compose.yml** - Dépendance Kafka ajoutée
5. **config.py** - Configuration des topics Kafka
6. **Structure des adaptateurs Kafka:**
   - `adapters/inbound/messaging/kafka_consumer.py`
   - `adapters/out/messaging/kafka_producer.py`
7. **Structure des handlers:**
   - `event_management/base_handler.py`
   - `event_management/handler_registry.py`
   - `event_management/handlers/[nom]_handler.py` (pour chaque opération RECEIVE)

## Mise à jour complète des opérations événementielles

### Analyse Complète des Opérations AsyncAPI

Une analyse complète du fichier `asyncapi.yml` a été réalisée pour identifier toutes les opérations **pop** (receive) et **push** (send) pour chaque service. Voici le résultat complet :

#### Opérations POP (RECEIVE) par Service

| Service | Opérations POP | Nombre |
|---------|----------------|--------|
| svc-audit | popBillcycleCreated, popCustomerbillCreated, popDoInvoicing, popDoProvisionActions, popOrderCancelled, popOrderCreated, popOrderSagaEnded, popOrderSagaSubmitted, popOrderValidationsKo, popPartyIdentified, popPaymentDelinquant, popPaymentProcessed, popServiceProvisionKo | 13 |
| svc-catalogue | popOrderCancelled, popOrderCreated, popOrderDraft | 3 |
| svc-clients | popAbusUsage, popAlerteFraude, popCustomerbillCreated, popOrderCancelled, popOrderDraft, popOrderSagaEnded, popOrderValidationsKo, popPaymentDelinquant, popPaymentProcessed, popServiceProvisionKo | 10 |
| svc-commandes | popOrderSagaSubmitted, popOrderValidationsOk, popPaymentDelinquant | 3 |
| svc-facturation | popAbusUsage, popDoInvoicing | 2 |
| svc-lignes | popAbusUsage, popDoProvisionActions | 2 |
| svc-orchestration | popAlerteFraude, popBuyerInvalid, popBuyerVerified, popOfferingsInvalid, popOfferingsVerified, popOrderCancelled, popOrderCreated, popServiceProvisionOk, popServiceVerified, popStockDecreased, popStockIncreased | 10 |

#### Opérations PUSH (SEND) par Service

| Service | Opérations PUSH | Nombre |
|---------|----------------|--------|
| svc-audit | pushAbusUsage, pushAlerteFraude | 2 |
| svc-catalogue | pushOfferingsInvalid, pushOfferingsVerified, pushStockDecreased, pushStockIncreased | 4 |
| svc-clients | pushBuyerInvalid, pushBuyerVerified, pushPartyIdentified | 3 |
| svc-commandes | pushOrderCancelled, pushOrderCreated, pushOrderDraft | 3 |
| svc-facturation | pushBillcycleCreated, pushCustomerbillCreated, pushPaymentDelinquant, pushPaymentProcessed | 4 |
| svc-lignes | pushServiceProvisionKo, pushServiceProvisionOk, pushServiceVerified | 3 |
| svc-orchestration | pushDoInvoicing, pushDoProvisionActions, pushOrderSagaEnded, pushOrderSagaSubmitted, pushOrderValidationsKo, pushOrderValidationsOk | 6 |

### Handlers Implémentés

#### svc-orchestration (+2 handlers)
- ✅ `OrderCancelledHandler` pour popOrderCancelled
- ✅ `OrderCreatedHandler` pour popOrderCreated

#### svc-commandes (+2 handlers)
- ✅ `OrderValidationsOkHandler` pour popOrderValidationsOk
- ✅ `PaymentDelinquantHandler` pour popPaymentDelinquant

#### svc-clients (+10 handlers)
- ✅ `AbusUsageHandler` pour popAbusUsage
- ✅ `AlerteFraudeHandler` pour popAlerteFraude
- ✅ `CustomerbillCreatedHandler` pour popCustomerbillCreated
- ✅ `OrderCancelledHandler` pour popOrderCancelled
- ✅ `OrderDraftHandler` pour popOrderDraft
- ✅ `OrderSagaEndedHandler` pour popOrderSagaEnded
- ✅ `OrderValidationsKoHandler` pour popOrderValidationsKo
- ✅ `PaymentDelinquantHandler` pour popPaymentDelinquant
- ✅ `PaymentProcessedHandler` pour popPaymentProcessed
- ✅ `ServiceProvisionKoHandler` pour popServiceProvisionKo

### Fonctions Event Producer Implémentées

#### CatalogueEventProducer (svc-catalogue)
- ✅ `send_offerings_verified()` pour pushOfferingsVerified
- ✅ `send_offerings_invalid()` pour pushOfferingsInvalid
- ✅ `send_stock_decreased()` pour pushStockDecreased
- ✅ `send_stock_increased()` pour pushStockIncreased

#### CommandesEventProducer (svc-commandes)
- ✅ `send_order_created()` pour pushOrderCreated
- ✅ `send_order_cancelled()` pour pushOrderCancelled
- ✅ `send_order_draft()` pour pushOrderDraft

#### FacturationEventProducer (svc-facturation)
- ✅ `send_billcycle_created()` pour pushBillcycleCreated
- ✅ `send_customerbill_created()` pour pushCustomerbillCreated
- ✅ `send_payment_processed()` pour pushPaymentProcessed
- ✅ `send_payment_delinquant()` pour pushPaymentDelinquant

#### LignesEventProducer (svc-lignes)
- ✅ `send_service_verified()` pour pushServiceVerified
- ✅ `send_service_provision_ok()` pour pushServiceProvisionOk
- ✅ `send_service_provision_ko()` pour pushServiceProvisionKo

#### AuditEventProducer (svc-audit) - Amélioré
- ✅ `send_detection_fraude()` pour pushAlerteFraude
- ✅ `send_abus_usage()` pour pushAbusUsage

#### ClientEventProducer (svc-clients) - Créé
- ✅ `send_buyer_verified()` pour pushBuyerVerified
- ✅ `send_buyer_invalid()` pour pushBuyerInvalid
- ✅ `send_party_identified()` pour pushPartyIdentified

### Configurations Kafka Mises à Jour

Tous les services ont eu leurs fichiers `config.py` mis à jour avec :
- Les topics pour toutes les opérations **RECEIVE** (pop) où le service est clientId
- Les topics pour toutes les opérations **SEND** (push) où le service est clientId
- Les valeurs par défaut basées sur le contrat AsyncAPI

### KafkaConsumerAdapter Mises à Jour

Tous les services ont eu leurs fichiers `kafka_consumer.py` mis à jour pour écouter tous les topics nécessaires pour les opérations pop (receive).

### Intégration dans les Fichiers Principaux

Tous les nouveaux handlers ont été :
- Importés dans les fichiers principaux (svc_*.py)
- Enregistrés dans le HandlerRegistry
- Initialisés avec les dépendances nécessaires

### ClientEventProducer pour svc-clients

Un nouveau service `ClientEventProducer` a été créé pour svc-clients avec :
- Intégration du pattern Outbox
- Méthodes spécifiques pour chaque opération push
- Initialisation dans le fichier principal svc_clients.py

## Résumé des Modifications par Service

### svc-audit
- **config.py**: Ajout des topics push (KAFKA_ALERTE_FRAUDE_TOPIC, KAFKA_ABUS_USAGE_TOPIC)
- **audit_event_producer.py**: Ajout des méthodes send_detection_fraude() et send_abus_usage()

### svc-catalogue
- **catalogue_event_producer.py**: Ajout des méthodes send_offerings_verified(), send_offerings_invalid(), send_stock_decreased(), send_stock_increased()

### svc-clients
- **config.py**: Ajout complet de tous les topics pop et push
- **kafka_consumer.py**: Mise à jour pour écouter les 10 topics pop
- **client_event_producer.py**: Nouveau fichier avec méthodes send_buyer_verified(), send_buyer_invalid(), send_party_identified()
- **svc_clients.py**: Intégration du ClientEventProducer et enregistrement des 10 nouveaux handlers
- **10 nouveaux handlers**: abus_usage_handler.py, alerte_fraude_handler.py, customerbill_created_handler.py, order_cancelled_handler.py, order_draft_handler.py, order_saga_ended_handler.py, order_validations_ko_handler.py, payment_delinquant_handler.py, payment_processed_handler.py, service_provision_ko_handler.py

### svc-commandes
- **config.py**: Ajout des topics KAFKA_ORDER_VALIDATIONS_OK_TOPIC et KAFKA_PAYMENT_DELINQUANT_TOPIC
- **kafka_consumer.py**: Ajout des nouveaux topics à la liste
- **commandes_event_producer.py**: Ajout des méthodes send_order_created(), send_order_cancelled(), send_order_draft()
- **svc_commandes.py**: Enregistrement des 2 nouveaux handlers
- **2 nouveaux handlers**: order_validations_ok_handler.py, payment_delinquant_handler.py

### svc-facturation
- **facturation_event_producer.py**: Ajout des méthodes send_billcycle_created(), send_customerbill_created(), send_payment_processed(), send_payment_delinquant()

### svc-lignes
- **lignes_event_producer.py**: Ajout des méthodes send_service_verified(), send_service_provision_ok(), send_service_provision_ko()

### svc-orchestration
- **config.py**: Ajout des topics KAFKA_ORDER_CREATED_TOPIC et KAFKA_ORDER_CANCELLED_TOPIC
- **kafka_consumer.py**: Ajout des nouveaux topics à la liste
- **saga_choregraphie.py**: Enregistrement des 2 nouveaux handlers
- **2 nouveaux handlers**: order_cancelled_handler.py, order_created_handler.py

## Vérification et Validation

Tous les fichiers modifiés ont été :
- ✅ Vérifiés pour la syntaxe Python (py_compile)
- ✅ Suivent le même pattern que les implémentations existantes
- ✅ Intègrent correctement le pattern Outbox pour les opérations push
- ✅ Utilisent les bons topics Kafka selon le contrat AsyncAPI
- ✅ Sont prêts pour l'implémentation de la logique métier

## Prochaines Étapes Recommandées

1. **Implémenter la logique métier** dans chaque handler (remplacer les TODO)
2. **Tester l'intégration Kafka** avec des événements réels
3. **Valider le flux événementiel** entre les services
4. **Configurer les bases de données MySQL** pour le pattern Outbox
5. **Déployer et tester** dans l'environnement Docker
6. **Ajouter la gestion des erreurs** et la compensation
7. **Implémenter les tests unitaires et d'intégration**

## Références

- Contrat AsyncAPI: `asyncapi.yml`
- Service de référence: `svc-audit` (structure et implémentation des adaptateurs Kafka)
- Documentation Kafka: https://kafka.apache.org/documentation/
- Bibliothèque Python Kafka: https://kafka-python.readthedocs.io/

---

*Document généré le 2026-08-01*
*Basé sur l'analyse du fichier asyncapi.yml et la structure de svc-audit*
*Dernière mise à jour: Ajout complet des opérations pop/push manquantes, des fonctions event_producer et de la validation des payloads selon les schémas asyncapi pour tous les services*
*Total: 17 nouveaux handlers, 20 nouvelles méthodes event_producer avec validation, configurations Kafka complètes pour tous les services*

## Validation des Payloads

### Implémentation de la Validation

Chaque service dispose maintenant d'un module de validation spécifique dans `src/application/validation/` qui valide les payloads des opérations push selon les schémas définis dans le fichier `asyncapi.yml`.

#### Structure des Modules de Validation

```
src/application/validation/
├── __init__.py                    # Exporte le valideur principal
└── [service]_payload_validator.py # Contient les méthodes de validation
```

#### Classes de Validation par Service

##### svc-audit: AuditPayloadValidator
- `validate_detection_fraude(payload)` - Valide selon DetectionFraudePayload schema
- `validate_abus_usage(payload)` - Valide selon AbusUsagePayload schema

##### svc-catalogue: CataloguePayloadValidator
- `validate_offerings_verified(payload)` - Valide selon OfferingsVerifiedPayload schema
- `validate_offerings_invalid(payload)` - Valide selon OfferingsInvalidPayload schema
- `validate_stock_decreased(payload)` - Valide selon StockPayload schema
- `validate_stock_increased(payload)` - Valide selon StockPayload schema

##### svc-clients: ClientsPayloadValidator
- `validate_buyer_verified(payload)` - Valide selon BuyerValidationPayload schema
- `validate_buyer_invalid(payload)` - Valide selon BuyerValidationPayload schema
- `validate_party_identified(payload)` - Valide selon PartyIdentifiedPayload schema

##### svc-commandes: CommandesPayloadValidator
- `validate_order_created(payload)` - Valide selon OrderStatePayload schema
- `validate_order_cancelled(payload)` - Valide selon OrderStatePayload schema
- `validate_order_draft(payload)` - Valide selon OrderStatePayload schema

##### svc-facturation: FacturationPayloadValidator
- `validate_billcycle_created(payload)` - Valide selon BillcycleCreatedPayload schema
- `validate_customerbill_created(payload)` - Valide selon CustomerbillCreatedPayload schema
- `validate_payment_processed(payload)` - Valide selon PaymentProcessedPayload schema
- `validate_payment_delinquant(payload)` - Valide selon PaymentDelinquantPayload schema

##### svc-lignes: LignesPayloadValidator
- `validate_service_verified(payload)` - Valide selon ServiceVerifiedPayload schema
- `validate_service_provision_ok(payload)` - Valide selon ServiceProvisionPayload schema
- `validate_service_provision_ko(payload)` - Valide selon ServiceProvisionPayload schema

##### svc-orchestration: OrchestrationPayloadValidator
- `validate_order_saga_submitted(payload)` - Valide selon OrderSagaSubmittedPayload schema
- `validate_order_validations_ok(payload)` - Valide selon OrderValidationsPayload schema
- `validate_order_validations_ko(payload)` - Valide selon OrderValidationsPayload schema
- `validate_do_provision_actions(payload)` - Valide selon DoProvisionActionsPayload schema
- `validate_do_invoicing(payload)` - Valide selon DoInvoicingPayload schema
- `validate_order_saga_ended(payload)` - Valide selon OrderSagaEndedPayload schema

### Intégration dans les Event Producers

Chaque méthode `send_*` dans les classes EventProducer appelle maintenant la validation correspondante avant d'envoyer l'événement :

```python
def send_order_created(self, aggregate_id: int, payload: Dict[str, Any]) -> None:
    """Send OrderCreated event for pushOrderCreated operation"""
    # Validation du payload selon le schéma asyncapi
    CommandesPayloadValidator.validate_order_created(payload)
    
    self.send(
        topic="commande.order-created",
        event_type="OrderCreated",
        aggregate_type="Order",
        aggregate_id=aggregate_id,
        payload=payload
    )
```

### Fonctionnement de la Validation

La validation vérifie :
1. **Champs requis** - Tous les champs marqués comme `required` dans le schéma asyncapi
2. **Types de données** - Chaque champ a le type correct (string, int, float, dict, list, etc.)
3. **Valeurs énumérées** - Les champs avec des valeurs prédéfinies (enum) ont des valeurs valides
4. **Formats datetime** - Les champs de date/heure sont au format ISO 8601
5. **Sous-objets** - Les objets imbriqués sont validés récursivement

### Gestion des Erreurs

Lorsque la validation échoue, une `ValidationError` est levée avec :
- Un message d'erreur descriptif
- Une liste détaillée de toutes les erreurs de validation

Exemple d'utilisation avec gestion d'erreur :

```python
try:
    commandes_event_producer.send_order_created(
        aggregate_id=123,
        payload={
            "order": {"userId": "user123", "items": {}},
            "orderState": "created"
        }
    )
except ValidationError as e:
    logger.error(f"Erreur de validation: {e.message}")
    for error in e.errors:
        logger.error(f"  - {error}")
    # Gérer l'erreur appropriément
```

### Avantages de la Validation

1. **Conformité au contrat** - Garantit que tous les événements publiés respectent le schéma asyncapi
2. **Détection précoce des erreurs** - Les erreurs sont détectées avant l'envoi à Kafka
3. **Messages d'erreur clairs** - Aide les développeurs à corriger les problèmes rapidement
4. **Maintenabilité** - La validation est centralisée et facile à mettre à jour
5. **Sécurité des données** - Empêche l'envoi de données malformées ou incomplètes
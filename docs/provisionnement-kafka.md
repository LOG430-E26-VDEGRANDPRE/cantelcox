# Provisionnement des lignes par Kafka

## Décision

Le provisionnement utilise un événement par ligne. L'orchestrateur publie
`DoProvisionActions`; `svc-lignes` répond par `ServiceProvisionOk` ou
`ServiceProvisionKo`. `ServiceVerified` reste disponible pour un éventuel flux
de vérification distinct, mais n'est pas émis artificiellement pendant cette
activation.

## Séquence nominale

```text
OrderSagaController
  -> Outbox MySQL orchestration
  -> saga.order-do-provision (DoProvisionActions)
  -> DoProvisionActionsHandler dans svc-lignes
  -> ActivateLines
  -> Free5GCWebUIAdapter
  -> Outbox MongoDB svc-lignes
  -> lignes.service-provision-ok (ServiceProvisionOk)
  -> ProvisioningMessagingRuntime dans svc-orchestration
  -> provisioning_results MySQL
  -> ActivateServiceHandler reprend la saga
  -> SERVICE_ACTIVE
```

Chaque commande possède un `provisioningId` UUID. Cet identifiant corrèle une
réponse précise lorsque la commande contient plusieurs lignes et rend
l'enregistrement des réponses idempotent entre les réplicas d'orchestration.

## Commande

```json
{
  "event_type": "DoProvisionActions",
  "aggregate_type": "OrderSaga",
  "aggregate_id": 42,
  "payload": {
    "provisioningId": "d24aeccf-79b8-4893-baf7-82263897f8a1",
    "orderId": 42,
    "userId": 7,
    "productOfferingRef": "PLN873",
    "MSISDN": "15145550124"
  }
}
```

## Réponse positive

```json
{
  "event_type": "ServiceProvisionOk",
  "aggregate_type": "Service",
  "aggregate_id": 42,
  "payload": {
    "provisioningId": "d24aeccf-79b8-4893-baf7-82263897f8a1",
    "productOfferingRef": "PLN873",
    "orderId": 42,
    "validation": "OK",
    "service": {
      "userId": 7,
      "orderId": 42,
      "MSISDN": "15145550124",
      "supi": "imsi-208935145550124",
      "serviceStatus": "active"
    }
  }
}
```

## Réponse négative et compensation

Une erreur métier connue de `ActivateLines` produit `ServiceProvisionKo` avec
`validation: KO`, `serviceStatus: error` et `failureReason`. L'orchestrateur
restaure ensuite le stock et poursuit sa compensation existante en supprimant
la commande.

Si l'Outbox de `svc-lignes` est indisponible, le handler lève une exception et
ne confirme pas l'offset de `DoProvisionActions`. Kafka pourra donc remettre la
commande. L'activation est idempotente : une ligne déjà créée avec le même
MSISDN est reconnue comme active.

## Persistance et réplicas

- Les commandes sont insérées atomiquement dans l'Outbox MySQL de
  `svc-orchestration`.
- Les réponses sont insérées dans l'Outbox MongoDB de `svc-lignes`.
- Les deux réplicas d'orchestration partagent la table MySQL
  `provisioning_results`; une réponse consommée par n'importe quel réplica est
  donc visible par la requête HTTP ayant lancé la saga.
- Le délai d'attente est contrôlé par `PROVISIONING_TIMEOUT_SECONDS` et
  l'intervalle de lecture par `PROVISIONING_POLL_INTERVAL_SECONDS`.
- La route KrakenD `/orchestration/v1/commande` dispose d'un délai de 60
  secondes. Il reste donc une marge autour des 45 secondes maximales consacrées
  au provisionnement Kafka.

## Base existante

Le script `svc-orchestration/db-init/init.sql` crée la table
`provisioning_results` sur une nouvelle base. Les scripts Docker d'initialisation
MySQL ne sont exécutés automatiquement que lors de la création initiale du
volume. Sur une base déjà existante, appliquer la migration réexécutable avant
de tester le flux, depuis la racine du projet :

```powershell
Get-Content .\svc-orchestration\db-init\migrations\001_create_orchestration_messaging_tables.sql | docker compose exec -T mysql mysql -uroot -proot
```

Cette migration crée la base `orchestration`, l'Outbox et la table de
corrélation avec `IF NOT EXISTS`; elle ne supprime aucune donnée existante.

## Exécuter les tests automatisés sous PowerShell

Les environnements virtuels ne se partagent pas dans Git. La première fois,
créer chaque environnement et installer ses dépendances :

```powershell
Set-Location .\svc-lignes\usage-api
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m pytest -q -p no:cacheprovider

Set-Location ..\..\svc-orchestration
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m pytest -q
```

Lors des exécutions suivantes, seules les deux commandes `pytest` sont
nécessaires. Le premier groupe teste le handler Kafka de `svc-lignes`, son
Outbox et ses adaptateurs; le second teste la corrélation `OK`/`KO`, plusieurs
lignes, l'idempotence MySQL, l'acquittement Kafka et le publisher Outbox.

## Test bout en bout

Depuis la racine du projet :

```powershell
docker network inspect cantelcox-network
docker compose up -d --build
docker compose ps
```

Si la première commande indique que le réseau n'existe pas, le créer une seule
fois avec `docker network create cantelcox-network`, puis relancer
`docker compose up -d --build`. Attendre que MySQL, Kafka et les services soient
prêts. Sur un ancien volume, appliquer aussi la migration de la section
précédente.

Importer ensuite la collection Postman
`docs/CanTelcoX - E26 -Vincent de Grandpré.postman_collection.json`, renseigner
`base_url` et `api_token`, puis exécuter la requête
`Test bout-en-bout - commande, facturation et paiement, activation`.

Pendant le test, ces commandes permettent de suivre le trajet :

```powershell
docker compose logs -f svc_orchestration1 svc_orchestration2 usage-api kafka
docker compose exec mysql mysql -uroot -proot -D orchestration -e "SELECT provisioning_id, order_id, status, received_at FROM provisioning_results ORDER BY received_at DESC LIMIT 10;"
docker compose exec db mongosh free5gc --quiet --eval 'db.cantelcox_outbox.find({}, {event_type:1, topic:1, published:1}).sort({created_at:-1}).limit(10).pretty()'
```

Le résultat attendu est une réponse HTTP avec `status: OK` et une section
`activation.lines`. Dans MySQL, le `provisioning_id` correspondant doit être
`OK`; dans MongoDB, l'événement `ServiceProvisionOk` doit être marqué publié.

# README – Projet exploratoire d’analyse SOC (MISP + Suricata + ELK + TheHive)

> Objectif : monter un mini‑SOC labo, pratiquer la Threat Intelligence avec **MISP**, générer des détections **Suricata**, visualiser dans **ELK**, et orchestrer des enquêtes avec **TheHive/Cortex**. 
Le tout versionner chaque étape de la Roadmap + relever et analyser chaque observation. [ Faire relire mon rapport par un analyste, relever mes erreurs, les lister pour rappel et corriger mon rapport en conséquence ]
Développer mon sens critique et organiser mon travail de prise de notes et d'analyse en situation réaliste.

SOC1 :
Scope: What is the scope of the engagement?
Responsibilities: What are the responsibilities of the organization?
Design: What is the design of the controls?
Description: What is the description management provided regarding the controls?
Type: What is the type of report being used?
Opinion: What was the auditor’s opinion after conducting all the testing and examination?

[source : https://secureframe.com/blog/soc-1-vs-soc-2]



---

## 0) Résultats attendus

* **environnement Docker** prêt à l’emploi : MISP, Suricata, Elasticsearch/Kibana (ELK), TheHive, Cortex.
* **jeu de données d’IOC** importé dans MISP (+ corrélations, TLP, tags ATT&CK).
* **pipeline de détection** : export MISP → règles IDS → alertes Suricata → remontée dans Kibana.
* **Playbooks** SOC (L1/L2), KPI de détection et rapport de synthèse.

---

## 1) Structure du dépôt

```
SOC-Lab/
├─ README.md
├─ .env.example
├─ docker/
│  ├─ docker-compose.yml
│  ├─ profiles/              
│  └─ configs/
│     ├─ misp/                
│     ├─ suricata/
│     │  ├─ suricata.yaml
│     │  └─ rules/
│     ├─ elastic/
│     ├─ thehive/
│     └─ cortex/
├─ scripts/
│  ├─ misp_ingest_sample.sh
│  ├─ misp_export_suricata.sh
│  ├─ seed_traffic.sh         # génère du trafic de test
│  └─ healthcheck.sh
├─ seed/
│  ├─ misp-events/
│  │  └─ phishing-2025.json   # événement prêt à importer
│  └─ pcaps/
│     └─ phishing-example.pcap
├─ docs/
│  ├─ architecture.png
│  ├─ playbooks/
│  │  ├─ L1_enrichissement.md
│  │  └─ L2_conteniment.md
│  ├─ runbooks/
│  │  └─ export_misp_to_suricata.md 
│  ├─ kpis.md
│  └─ rapport_template.md  # rédactionnel
└─ Makefile
```

---

## 2) Pré‑requis

* OS : macOS / Linux
* **Docker** & **Docker Compose**
* **Git**, **curl**, **jq**
* Accès Internet (feeds MISP, images Docker)

> API MISP Scripting **Python 3.11+**.
---

## 3) Sécurité, éthique et cadre légal [recherche en cours = à développer]

* Toujours **anonymiser** les données sensibles (emails internes, IP privées).
* Utiliser les marquages **TLP** (ex. `tlp:green`) et restreindre le partage.
* Ne jamais attaquer des cibles réelles. **simulation** de trafic malveillant (pcap / domaines sinkhole).
* Journaliser les accès admin et **changer tous les mots de passe** par défaut.

---

[ Documenter absolument toutes les étapes dans un rapport de mise en œuvre et détailler le protocol de test ]

## 4) Mise en route 

### 4.1 Cloner et préparer l’environnement

```bash
git clone <ton_repo> SOC-Lab && cd SOC-Lab
cp .env.example .env
# Édite .env : mots de passe, ports, clés API…
```

### 4.2 Lancer la stack

```bash
# Profil minimal : MISP + Suricata + Elasticsearch + Kibana
docker compose -f docker/docker-compose.yml --profile minimal up -d
```

### 4.3 Accès par défaut ( contrôler les ports )

* **MISP** : [https://localhost:8443](https://localhost:8443)  ([admin@admin.test](mailto:anthony-fds@pm.me)
* **Kibana** : [http://localhost:5601](http://localhost:5601)
* **TheHive** : [http://localhost:9000](http://localhost:9000)
* **Cortex** : [http://localhost:9001](http://localhost:9001)

> !! !! !! première connexion, *Administration → Server settings* (MISP) et correction des avertissements.

---

## 5) Première donnée : créercet charger un événement MISP

### 5.1 Via l’UI (rapide)

1. **Event Actions → Add Event**
2. `Info` : *Phishing Banque – Sept. 2025*
   `Threat level` : 3 (Low)  ·  `Analysis` : 0 (Initial)  ·  `Distribution` : *Your organisation only* (puis élargir)
3. **Ajouter des attributs** :

   * `domain` → `login-secure-banque[.]fr`
   * `url` → `hxxp://login-secure-banque[.]fr/auth`
   * `ip-dst` → `203.0.113.42`
   * `sha256` (pièce jointe) → *hash fictif*
4. **Tagguer** : `tlp:green`, `misp-galaxy:attack-pattern="T1566 Phishing"`

### 5.2 Via l’API (exemple de script à adapter)

`scripts/misp_ingest_sample.sh` :

```bash
#!/usr/bin/env bash
set -euo pipefail
MISP_URL="https://localhost:8443"
MISP_KEY="<API_KEY>"     # MISP → Auth keys
PAYLOAD='{
  "info": "Phishing Banque – Sept. 2025",
  "threat_level_id": 3,
  "analysis": 0,
  "distribution": 0,
  "Attribute": [
    {"type":"domain","category":"Network activity","to_ids":true,"value":"login-secure-banque.fr"},
    {"type":"url","category":"Network activity","to_ids":true,"value":"http://login-secure-banque.fr/auth"},
    {"type":"ip-dst","category":"Network activity","to_ids":true,"value":"203.0.113.42"},
    {"type":"sha256","category":"Payload delivery","to_ids":true,"value":"aaaaaaaa...ffffffff"}
  ],
  "Tag":[{"name":"tlp:green"},{"name":"misp-galaxy:attack-pattern=Phishing (T1566)"}]
}'

curl -sk -H "Authorization: $MISP_KEY" -H "Content-Type: application/json" \
  -X POST "$MISP_URL/events" -d "$PAYLOAD" | jq .
```

---

[ Documenter le pourquois, le comment et chaque choix technique ]

## 6) Du renseignement à la détection : exporter vers Suricata

### 6.1 Exporter les règles IDS depuis MISP

Script `scripts/misp_export_suricata.sh` (exemple de script à adapter) :

```bash
#!/usr/bin/env bash
set -euo pipefail
MISP_URL="https://localhost:8443"
MISP_KEY="<API_KEY>"
RULES_OUT="docker/configs/suricata/rules/misp.rules"

curl -sk -H "Authorization: $MISP_KEY" \
  "$MISP_URL/attributes/nids/suricata/download" > "$RULES_OUT"

echo "Règles écrites dans $RULES_OUT"
```

### 6.2 Recharger Suricata

```bash
docker exec -it suricata suricatasc -c reload-rules || docker restart suricata
```

> Vérifie que `misp.rules` est bien référencé dans `suricata.yaml`.

---

## 7) Simuler du trafic et vérifier les alertes

### 7.1 Générer un trafic de test minimal

```bash
# Exemple à adapter : résolution DNS et HTTP vers le domaine malveillant
nslookup login-secure-banque.fr || true
curl -v http://login-secure-banque.fr/auth || true
```

### 7.2 (Option) Rejouer un PCAP

```bash
# nécessite tcpreplay et une interface de test
sudo tcpreplay --intf1=lo seed/pcaps/phishing-example.pcap
```

### 7.3 Observer dans Kibana

* Index Suricata (EVE JSON) → créer **Data View** `suricata-*`
* Visualisations : *Top alerts by signature*, *Src/Dst IP*, *Timeline*.

---

## 8) Intégrer TheHive & Cortex (profil *full*)

1. Dans **TheHive**, configurer l’intégration **MISP** (URL + clé API).
2. Depuis un événement MISP, **Create case in TheHive**.
3. Dans **Cortex**, configuration des analyzers --> **VirusTotal** en clé publique, et lancer des **jobs** sur les hash/URL.
4. Récupèrer les **sightings** côté MISP pour enrichir l’intelligence.


> [ !!! But pédagogique : relier TI → Détection → Enquête → Contre‑mesures. !!! Justifier tous ses choix et développer la logique d'analyse ]

---

## 9) Playbooks & Runbooks

* **Playbook L1 (tri/qualification)**

  * Vérifier TLP / org / source
  * Enrichir IOC (WHOIS, Passive DNS)
  * Chercher correspondances dans Suricata/ELK
  * Escalader si impact avéré
* **Playbook L2 (confinement/éradication)**

  * Bloquer domaines/IP sur le pare‑feu/EDR
  * Notifier les utilisateurs ciblés (campagnes phishing)
  * Créer règles YARA / EDR si binaire identifié
* **Runbook** : *Export MISP → Suricata* (voir `docs/runbooks/export_misp_to_suricata.md`).

---

## 10) KPIs (dans `docs/kpis.md`)

* **MTTD** (Mean Time To Detect) : temps entre IOC dispo et première alerte.
* **Faux positifs** / 24h et **taux de précision** par règle.
* **Couverture ATT&CK** (techniques affiliées aux événements taggés).
* **Délai de propagation** IOC → IDS (MISP → Suricata reload).

---

## 11) Bonnes pratiques MISP

* Utiliser des **taxonomies** (TLP, Confidence, ATT&CK) de façon cohérente.
* Définir des **communities/circles** même en local (simulateur) pour pratiquer le partage contrôlé.
* Documenter chaque événement : **Contexte, Source, Confiance, Recommandations**.

---

## 12) Fichiers clés à adapter

* `.env` : mots de passe, ports, clés API (MISP, TheHive, Cortex).
* `docker/docker-compose.yml` : versions d’images, volumes, réseaux.
* `docker/configs/suricata/suricata.yaml` : interface d’écoute, EVE JSON, règles.
* `scripts/*` : URLs/chemins.

---

## 13) Makefile (exemple de script à adapter)

```Makefile
.PHONY: up down logs seed rules test clean
up:
	docker compose -f docker/docker-compose.yml --profile minimal up -d
full:
	docker compose -f docker/docker-compose.yml --profile full up -d
logs:
	docker compose -f docker/docker-compose.yml logs -f --tail=200
seed:
	bash scripts/misp_ingest_sample.sh
rules:
	bash scripts/misp_export_suricata.sh && docker exec -it suricata suricatasc -c reload-rules || true
test:
	bash scripts/seed_traffic.sh
down:
	docker compose -f docker/docker-compose.yml down
clean:
	docker compose -f docker/docker-compose.yml down -v --remove-orphans
```

---

## 14) Modèle d’événement MISP (JSON)

`seed/misp-events/phishing-2025.json` (extrait minimal) :

```json
{
  "Event": {
    "info": "Phishing Banque – Sept. 2025",
    "threat_level_id": 3,
    "analysis": 0,
    "distribution": 0,
    "Attribute": [
      {"type":"domain","category":"Network activity","to_ids":true,"value":"login-secure-banque.fr"},
      {"type":"url","category":"Network activity","to_ids":true,"value":"http://login-secure-banque.fr/auth"},
      {"type":"ip-dst","category":"Network activity","to_ids":true,"value":"203.0.113.42"},
      {"type":"sha256","category":"Payload delivery","to_ids":true,"value":"aaaaaaaa...ffffffff"}
    ],
    "Tag": [
      {"name":"tlp:green"},
      {"name":"misp-galaxy:attack-pattern=Phishing (T1566)"}
    ]
  }
}
```

---

# ROADMAP

## 15) Roadmap d’étude (estimation sur 2 ou 3 semaines selon études)

* **1** : installation, durcissement basique, import d’un premier événement.
* **2* : export IDS + alertes Suricata → dashboard Kibana.
* **3** : intégration TheHive/Cortex + premiers cas.
* **4** : feeds publics, tagging avancé, KPIs, rapport final.

---

## 16) Rapport final – plan type (`docs/rapport_template.md`)

1. Contexte & objectifs
2. Architecture & périmètre
3. Méthodologie (MISP → IDS → SIEM → IR)
4. Jeux de données & hypothèses
5. Résultats (détections, corrélations, tableaux Kibana)
6. KPIs & analyse (MTTD, FPs)
7. Recommandations (techniques & orga)
8. Limites & travaux futurs

---

## 17) Dépannage rapide

* **Pas d’alertes Suricata** : vérifier interface d’écoute, chargement `misp.rules`, EVE JSON activé.
* **MISP export vide** : vérifier `to_ids=true` sur les attributs, droits de distribution, filtre d’export.
* **Kibana ne voit rien** : vérifier Filebeat/ingest pipeline et index `suricata-*`.
* **Certificat MISP** : en dev, utiliser `-k` (curl) ou générer un cert local.

---

## 18) Prochaines étapes

* Ajouter **YARA** (fichiers) et **Sigma** (SIEM) aux exports MISP.
* Instrumenter un **SOAR** (n8n/StackStorm) pour auto‑blocage sur IOC.
* Fournir un 2ᵉ dataset (malvertising, C2) et comparer la couverture ATT&CK.

---

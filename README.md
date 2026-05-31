# Projet Final DevOps

Infrastructure cloud automatisée sur AWS provisionnée par Terraform et configurée par Ansible. L'application Node.js (runtime Bun) est déployée sur deux instances EC2 privées, exposées via un Application Load Balancer, avec une base de données PostgreSQL managée (RDS) et des sauvegardes automatiques vers S3.

---

## Table des matières

1. [Prérequis](#prérequis)
2. [Architecture](#architecture)
3. [Structure du dépôt](#structure-du-dépôt)
4. [Déploiement de zéro](#déploiement-de-zéro)
5. [Ansible Vault](#ansible-vault)
6. [Stratégie de backup](#stratégie-de-backup)
7. [Restauration depuis S3](#restauration-depuis-s3)
8. [Usine logicielle (CI/CD)](#usine-logicielle-cicd)
9. [Tests Molecule](#tests-molecule)

---

## Prérequis

### Outils à installer

| Outil | Version minimale | Installation |
|---|---|---|
| Terraform | >= 1.6.0 | https://developer.hashicorp.com/terraform/install |
| Ansible | >= 2.14 | `pip install ansible` |
| Python | >= 3.9 | Fourni par le système |
| AWS CLI | >= 2.0 | https://aws.amazon.com/cli/ |
| Docker | >= 24.0 | Requis pour les tests Molecule |

```bash
# Installer les dépendances Python (Ansible + Molecule)
pip install ansible molecule molecule-docker ansible-lint
```

### Credentials AWS

```bash
aws configure
# AWS Access Key ID     : <votre access key>
# AWS Secret Access Key : <votre secret key>
# Default region        : eu-west-3
# Default output format : json
```

---

## Architecture

### Schéma réseau

```
                        INTERNET
                           │
                    ┌──────▼──────┐
                    │     ALB     │  ports entrants : 80 (HTTP), 443 (HTTPS)
                    │  (public)   │  port sortant   : 3000 → instances app
                    └──────┬──────┘
                           │  VPC 10.0.0.0/16
          ┌────────────────┴────────────────┐
          │                                 │
   ┌──────▼──────┐                   ┌──────▼──────┐
   │   app-1     │  subnet privé     │   app-2     │  subnet privé
   │ 10.0.2.0/24 │  eu-west-3a       │ 10.0.3.0/24 │  eu-west-3b
   │             │                   │             │
   │ Nginx :443  │                   │ Nginx :443  │
   │ App   :3000 │                   │ App   :3000 │
   └──────┬──────┘                   └──────┬──────┘
          │                                 │
          └────────────┬────────────────────┘
                       │  port 5432 (PostgreSQL)
                ┌──────▼──────┐
                │  RDS Postgres│  subnet privé isolé
                │ 10.0.4.0/24  │  eu-west-3a + 3b
                │  db.t3.micro  │  accessible uniquement depuis sg-app
                └─────────────┘
                       │
                ┌──────▼──────┐
                │  NAT Gateway │  subnet public — accès sortant internet
                │  (10.0.1.0) │  pour mises à jour, dépendances
                └─────────────┘
                       │
                ┌──────▼──────┐
                │  S3 Backups  │  chiffré AES-256, versioning activé
                └─────────────┘
```

### Flux réseau et ports

| Source | Destination | Port | Protocole | Règle |
|---|---|---|---|---|
| Internet | ALB | 80 | TCP | HTTP (redirection HTTPS) |
| Internet | ALB | 443 | TCP | HTTPS entrant |
| ALB | app-1, app-2 | 3000 | TCP | Forward vers l'application |
| app-1, app-2 | RDS | 5432 | TCP | PostgreSQL (sg-app → sg-db uniquement) |
| app-1, app-2 | Internet | * | TCP | Sortant via NAT Gateway (packages, S3) |
| RDS | VPC | * | TCP | Sortant limité au VPC (10.0.0.0/16) |

### Machines et rôles

| Machine | Type | Subnet | IP privée | Rôles Ansible |
|---|---|---|---|---|
| app-1 | t3.small | privé eu-west-3a | 10.0.2.x | application, load_balancer, database, backup |
| app-2 | t3.small | privé eu-west-3b | 10.0.3.x | application, load_balancer |
| RDS | db.t3.micro | privé isolé | (endpoint RDS) | — (managé AWS) |

### Groupes Ansible (inventaire)

```ini
[app]           → app-1, app-2   (déploiement application Node.js)
[load_balancer] → app-1, app-2   (Nginx reverse proxy + SSL)
[database]      → app-1          (connexion et init schéma RDS)
[backup]        → app-1          (backup quotidien PostgreSQL → S3)
```

---

## Structure du dépôt

```
.
├── terraform/
│   ├── main.tf                   # Provider AWS, backend
│   ├── variables.tf              # Déclaration des variables
│   ├── vpc.tf                    # VPC, subnets, NAT Gateway, route tables
│   ├── ec2.tf                    # Instances app (Amazon Linux 2023)
│   ├── rds.tf                    # Base de données PostgreSQL 15
│   ├── alb.tf                    # Application Load Balancer
│   ├── s3.tf                     # Bucket backups (lifecycle 90j, AES-256)
│   ├── iam.tf                    # IAM role EC2 (SSM + S3)
│   ├── security_groups.tf        # Règles réseau (alb, app, db)
│   ├── outputs.tf                # Outputs : ALB DNS, IPs, endpoint RDS
│   ├── terraform.tfvars.example  # Template de configuration
│   └── user_data/
│       └── app.sh                # Script init EC2 (Node.js, PM2, appuser)
│
├── ansible/
│   ├── ansible.cfg               # Config Ansible (vault_password_file, etc.)
│   ├── site.yml                  # Playbook principal
│   ├── inventory/
│   │   ├── hosts.ini             # Inventaire statique avec groupes
│   │   └── group_vars/
│   │       └── all/
│   │           ├── vars.yml      # Variables générales
│   │           ├── app.yml       # Config application
│   │           ├── database.yml  # Config DB (références vault)
│   │           ├── backup.yml    # Config S3 backup
│   │           ├── aws.yml       # Config AWS (références vault)
│   │           └── vault.yml     # Secrets chiffrés AES-256
│   └── roles/
│       ├── application/          # Bun, sources app, service systemd
│       │   └── molecule/         # Tests d'intégration
│       ├── load_balancer/        # Nginx, SSL auto-signé, reverse proxy
│       │   └── molecule/
│       ├── database/             # Client psql, connectivité RDS, schéma SQL
│       │   └── molecule/
│       └── backup/               # pg_dump, upload S3, cron
│           └── molecule/
│
├── api/                          # Code source de l'application
├── .gitignore
└── README.md
```

---

## Déploiement de zéro

### Étape 1 — Provisionner l'infrastructure avec Terraform

```bash
cd terraform

# 1. Copier et remplir le fichier de variables
cp terraform.tfvars.example terraform.tfvars
```

Éditer `terraform.tfvars` :

```hcl
db_password    = "MotDePasseSecurisé123!"
ssh_public_key = "ssh-rsa AAAA..."   # votre clé publique SSH
```

```bash
# 2. Initialiser Terraform
terraform init

# 3. Prévisualiser les ressources à créer
terraform plan

# 4. Appliquer (crée VPC, EC2, RDS, ALB, S3, IAM...)
terraform apply
```

> Notez les outputs affichés : `alb_dns_name`, `app_instance_ids`, `db_endpoint`.

### Étape 2 — Configurer l'inventaire Ansible

Mettre à jour `ansible/inventory/hosts.ini` avec les IPs privées des instances (disponibles dans les outputs Terraform ou via `aws ec2 describe-instances`).

### Étape 3 — Configurer le Vault Ansible

```bash
# Créer le fichier de mot de passe vault
echo "projet-devops" > ansible/.vault_pass
chmod 600 ansible/.vault_pass

# Vérifier le contenu du vault
ansible-vault view ansible/inventory/group_vars/all/vault.yml
```

### Étape 4 — Déployer avec Ansible

```bash
cd ansible

# Tester la connectivité SSH vers les instances
ansible all -m ping

# Déployer l'infrastructure complète
ansible-playbook site.yml
```

### Étape 5 — Vérifier le déploiement

```bash
# L'application doit répondre sur l'ALB
curl http://<alb_dns_name>

# Connexion aux instances via SSM (pas besoin de port 22 ouvert)
aws ssm start-session --target <instance-id> --region eu-west-3
```

---

## Ansible Vault

Les secrets sont chiffrés avec Ansible Vault (AES-256). Le fichier `vault.yml` est versionné dans git en état chiffré — seul le fichier `.vault_pass` ne doit jamais être commité.

**Mot de passe vault : `projet-devops`**

```bash
# Configurer le mot de passe (une seule fois)
echo "projet-devops" > ansible/.vault_pass
chmod 600 ansible/.vault_pass

# Voir les secrets déchiffrés
ansible-vault view ansible/inventory/group_vars/all/vault.yml

# Modifier un secret
ansible-vault edit ansible/inventory/group_vars/all/vault.yml
```

Secrets stockés dans le vault :

| Variable | Description |
|---|---|
| `vault_db_password` | Mot de passe PostgreSQL |
| `vault_db_host` | Endpoint RDS (extrait du tfstate, marqué sensitive) |
| `vault_app_instance_ids` | IDs EC2 (extraits du tfstate) |
| `vault_aws_access_key` | AWS Access Key ID |
| `vault_aws_secret_key` | AWS Secret Access Key |
| `vault_ssh_private_key` | Clé privée SSH EC2 |
| `vault_github_token` | Token CI/CD GitHub |

---

## Stratégie de backup

### Vue d'ensemble

| Paramètre | Valeur |
|---|---|
| Fréquence | Quotidienne à **02h00** |
| Méthode | `pg_dump` compressé (gzip) |
| Rétention locale | **7 jours** (`/var/backups/devops-final/`) |
| Rétention S3 | **90 jours** (lifecycle Terraform automatique) |
| Localisation S3 | `s3://devops-final-backups-095713296107/backups/db/` |
| Chiffrement | AES-256 côté serveur (SSE-S3) |
| Versioning | Activé (restauration de version antérieure possible) |

### Planification cron

```
# Backup quotidien à 2h00 (toutes les nuits)
0 2 * * *   appuser   /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1

# Nettoyage local des fichiers > 7 jours (dimanche 3h30)
30 3 * * 0  root      find /var/backups/devops-final -name '*.sql.gz' -mtime +7 -delete
```

### Restauration

```bash
# 1. Lister les backups disponibles dans S3
aws s3 ls s3://devops-final-backups-095713296107/backups/db/ --region eu-west-3

# 2. Télécharger un backup
aws s3 cp s3://devops-final-backups-095713296107/backups/db/db_20240115_020001.sql.gz /tmp/

# 3. Restaurer la base de données
gunzip -c /tmp/db_20240115_020001.sql.gz | psql postgresql://appuser:<password>@<rds-endpoint>:5432/appdb
```

---

## Restauration depuis S3

Le playbook `restore.yml` est **indépendant** du playbook principal. Il restaure le backup le plus récent (ou un backup spécifique) depuis le bucket S3.

### Restaurer le backup le plus récent

```bash
cd ansible
ansible-playbook restore.yml
```

### Restaurer un backup spécifique

```bash
# Lister les backups disponibles
aws s3 ls s3://devops-final-backups-095713296107/backups/db/ --region eu-west-3

# Restaurer un backup précis
ansible-playbook restore.yml -e "backup_file=db_20240115_020001.sql.gz"
```

### Ce que fait le playbook

1. Liste les backups S3 et identifie le plus récent (ou utilise le fichier passé en paramètre)
2. Télécharge le fichier `.sql.gz` depuis S3
3. Décompresse le dump
4. **Stoppe l'application** sur toutes les instances `[app]` pour éviter des écritures concurrentes
5. Exécute `psql` pour restaurer le dump sur RDS
6. **Redémarre l'application**
7. Supprime les fichiers temporaires

### Prérequis

- AWS CLI configuré avec les permissions S3 (déjà en place via IAM role EC2)
- `postgresql15` installé sur l'hôte (géré par le rôle `backup`)
- Variables vault disponibles (`db_password`, `db_host`)

---

## Usine logicielle (CI/CD)

Instance dédiée, isolée du réseau applicatif (subnet 10.0.30.0/24, security group distinct).

### Architecture CI tools

```
Internet
   │
  :443 (HTTPS via Nginx reverse proxy)
   │
  ┌──────────────────────────────────────┐
  │         citools-1 (t3.medium)         │
  │         subnet 10.0.30.0/24           │
  │                                       │
  │  Nginx :443 → Jenkins    :8080        │
  │  Nginx :443 → SonarQube  :9000        │
  │  Nginx :443 → Nexus      :8081        │
  └──────────────────────────────────────┘
```

### Flux réseau et ports

| Port | Service | Accès |
|---|---|---|
| 80 | HTTP → redirect HTTPS | Internet |
| 443 | HTTPS (Nginx proxy) | Internet |
| 8080 | Jenkins (direct) | Internet |
| 9000 | SonarQube (direct) | Internet |
| 8081 | Nexus (direct) | Internet |

> Le security group `sg-citools` est indépendant de `sg-app` — aucune règle croisée entre les deux.

### Déployer l'usine logicielle

```bash
# 1. Récupérer l'IP publique depuis les outputs Terraform
terraform output citools_public_ip

# 2. Mettre à jour l'inventaire
# Remplacer CITOOLS_PUBLIC_IP dans ansible/inventory/hosts.ini

# 3. Déployer uniquement les outils CI
cd ansible
ansible-playbook site.yml --limit citools

# Ou déployer tout en une fois
ansible-playbook site.yml
```

### Accès aux interfaces web

| Outil | URL directe | URL via Nginx (HTTPS) |
|---|---|---|
| Jenkins | `http://<IP>:8080` | `https://jenkins.citools.local` |
| SonarQube | `http://<IP>:9000` | `https://sonarqube.citools.local` |
| Nexus | `http://<IP>:8081` | `https://nexus.citools.local` |

Pour utiliser les URLs avec domaine, ajouter dans `/etc/hosts` :
```
<CITOOLS_IP>  jenkins.citools.local sonarqube.citools.local nexus.citools.local
```

### Credentials initiaux

| Outil | Login | Mot de passe |
|---|---|---|
| Jenkins | — | Affiché à la fin du playbook (aussi dans `/var/lib/jenkins/secrets/initialAdminPassword`) |
| SonarQube | `admin` | `admin` (à changer à la première connexion) |
| Nexus | `admin` | Dans `/opt/sonatype-work/nexus3/admin.password` |

### Rôles Ansible citools

| Rôle | Description |
|---|---|
| `jenkins` | Java 17, dépôt LTS, service systemd, mot de passe initial affiché |
| `sonarqube` | Java 17, tuning kernel, installation /opt, service systemd |
| `nexus` | Java 11, utilisateur nexus, installation /opt, service systemd |
| `citools_proxy` | Nginx, SSL auto-signé, virtual hosts HTTPS pour chaque outil |

---

## Tests Molecule

Les tests vérifient chaque rôle Ansible en isolation dans un conteneur Docker Amazon Linux 2023, avec systemd actif.

### Prérequis

Docker doit être installé et en cours d'exécution :

```bash
docker info
```

### Construire l'image Docker (une seule fois par rôle)

Les scénarios Molecule utilisent une image personnalisée basée sur Amazon Linux 2023 avec systemd. Elle est construite automatiquement lors du premier `molecule test`.

### Lancer les tests

```bash
# Tester un rôle spécifique
cd ansible/roles/load_balancer
molecule test

# Étapes disponibles séparément
molecule create    # Créer le conteneur
molecule converge  # Appliquer le rôle
molecule verify    # Vérifier le résultat
molecule destroy   # Supprimer le conteneur

# Tester tous les rôles en séquence
for role in ansible/roles/*/; do
  echo "==============================="
  echo "Testing: $(basename $role)"
  echo "==============================="
  cd "$role"
  molecule test
  cd -
done
```

### Ce que testent les scénarios

| Rôle | Tests vérifiés |
|---|---|
| `load_balancer` | Nginx installé, service actif, port 443 en écoute, certificat SSL présent |
| `application` | Bun installé, utilisateur appuser créé, service systemd actif, port 3000 en écoute |
| `database` | Client postgresql15 installé, connectivité RDS vérifiée |
| `backup` | Script backup présent, cron configuré, répertoire backup créé |
| `jenkins` | Java installé, Jenkins installé (rpm), service actif, port 8080 en écoute |
| `sonarqube` | Java installé, utilisateur sonarqube créé, /opt/sonarqube/bin présent, service systemd configuré, vm.max_map_count >= 524288 |
| `nexus` | Java installé, utilisateur nexus créé, /opt/nexus/bin/nexus présent, service systemd configuré, /opt/sonatype-work présent |

### Dépannage Molecule

```bash
# Voir les logs détaillés
molecule test --debug

# Si le conteneur est bloqué
molecule destroy --force

# Vérifier que l'image a bien été construite
docker images | grep molecule-amazonlinux2023
```

Voici la transformation complète de ton sujet de projet DevOps au format Markdown, structurée de manière claire et lisible pour ton repository ou tes notes d'étude.

---

PROJET DEVOPS

Mise en situation - Infrastructure & Déploiement

- **Durée :** 2 séances de 3h30 (7h au total)

- **Groupes :** 2 à 3 étudiants

- **Technos :** Libres dans le cadre des exigences décrites ci-dessous

- **Rendu :** URL du repository Git envoyée par mail avant la deadline à `thomas.lanquetin@intervenants.efrei.net`

---

## 1. Contexte

Vous avez pratiqué Terraform, Ansible, Jenkins et SonarQube lors des TPs précédents. Ce projet a pour objectif de les assembler pour produire une infrastructure multi-machines, automatisée et documentée, telle que vous pourriez en déployer une en entreprise.

Le choix du fournisseur cloud, des technologies applicatives et de la base de données est libre. Seules les exigences fonctionnelles et de qualité décrites ci-dessous sont imposées.

---

## 2. Architecture cible

L'infrastructure à déployer doit respecter le schéma suivant:

```
     Internet
        │
        ▼
[ Load Balancer ]      <── point d'entrée unique, HTTPS terminé ici
        │
   ┌────┴──────────────┐
   ▼                   ▼
[ VM App 1 ]     [ VM App N ]  <── N ≥ 2 (back + front)
   │                   │
   └────┬──────────────┘
        ▼
[ VM Base de données ] <── instance dédiée, non exposée
        │
        ▼
  [ Bucket S3 ]        <── stockage des backups (BDD et/ou fichiers)

```

---

## 3. Exigences

3.1 Infrastructure - Terraform

L'ensemble des ressources cloud doit être provisionné exclusivement via Terraform:

- Au moins 2 instances applicatives identiques (back-end + front-end).

- 1 instance dédiée à la base de données, non exposée directement sur Internet.

- 1 load balancer (natif du provider ou logiciel sur VM dédiée).

- 1 bucket S3 (ou équivalent : GCS, OVH Object Storage...) pour le stockage des backups.

- Règles réseau et firewall adaptées à chaque type de machine.

- **Aucune ressource créée manuellement**, tout doit être en Infra as Code.

  3.2 Configuration & Déploiement - Ansible

La configuration de toutes les machines et le déploiement sont gérés via Ansible, organisé en rôles, avec un inventaire reflétant les différents groupes de machines:

- **Rôle load balancer :** reverse proxy (Nginx, HAProxy, Caddy...) avec HTTPS.

- **Rôle application :** déploiement du back-end et du front-end sur chaque VM applicative.

- **Rôle base de données :** installation, configuration, accès restreint aux VMs applicatives.

- **Rôle backup :** sauvegarde automatisée de la BDD et/ou des fichiers applicatifs.

- Fréquence et rétention au choix, mais justifiées dans la documentation.

- Les dumps/archives sont envoyés automatiquement vers le bucket S3.

- Le bucket S3 est provisionné via Terraform et configuré via Ansible (credentials, destination).

> 💡 **Conseil DNS :** `sslip.io` et `nip.io` permettent d'obtenir un nom de domaine résolvable gratuitement à partir d'une IP (ex. `1-2-3-4.sslip.io`), compatible Let's Encrypt.

3.3 Tests - Molecule

Chaque rôle Ansible doit être couvert par un scénario Molecule:

- Driver au choix (Docker, Vagrant, instance cloud éphémère...).

- Les tests vérifient a minima que le service est actif et que les ports attendus répondent.

- La commande `molecule test` doit passer sans erreur sur l'ensemble des rôles.

  3.4 Documentation

Le repository doit permettre à n'importe qui de reproduire l'environnement de zéro:

- `README.md` : description du projet, pré-requis, étapes de déploiement, etc.

- Schéma ou description de l'architecture : machines, rôles, flux réseau, ports.

- Stratégie de backup : fréquence, rétention, localisation des sauvegardes.

- Instructions pour lancer les tests Molecule.

  3.5 Structure du repository

Aucune structure n'est imposée, mais elle doit être lisible et cohérente.

---

4. Livrables

Un seul livrable : **l'URL de votre repository Git** (GitHub, GitLab, Gitea...), envoyée avant la deadline.

Le repository doit contenir:

- Le code Terraform complet

- Les rôles Ansible avec leurs scénarios Molecule

- L'inventaire Ansible avec les groupes de machines

- Un `README.md` complet

- Un `.gitignore` adapté

> ⚠️ **Sécurité :** Toute credential (clé API, mot de passe, token, tfstate) commitée en clair entraîne une **pénalité automatique**. Utilisez Ansible Vault, des variables d'environnement, ou des fichiers exclus via `.gitignore`.

---

5. Pour aller plus loin - Usine logicielle (Bonus)

Si vous avez terminé le projet principal, vous pouvez étendre l'infrastructure avec une machine dédiée à l'usine logicielle, provisionnée et configurée avec les mêmes outils.

5.1 Infrastructure supplémentaire - Terraform

- 1 instance dédiée à l'usine logicielle, isolée du réseau applicatif.

- Ports ouverts uniquement pour Jenkins (8080), SonarQube (9000) et Nexus (8081).

- Configurer un nom de domaine spécifique pour chacun d'eux en HTTPS.

  5.2 Configuration - Ansible

Un rôle dédié par outil, intégré à l'inventaire existant (nouveau groupe `citools`):

- **Rôle jenkins :** installation, démarrage du service, accès initial sécurisé.

- **Rôle sonarqube :** installation, configuration de base, connectivité vérifiée.

- **Rôle nexus :** installation, démarrage, repository par défaut accessible.

- Tests Molecule présents pour chaque rôle bonus.

| Critère                                                 | Points     |
| ------------------------------------------------------- | ---------- |
| **Bonus - Usine logicielle**                            | **+3 pts** |
| VM provisionnée via Terraform, règles réseau cohérentes | +1 pt      |
| Jenkins + SonarQube + Nexus installés et accessibles    | +1 pt      |
| Tests Molecule pour les rôles bonus                     | +1 pt      |

5.3 Restauration depuis le S3

Fournir un playbook Ansible dédié `restore.yml` capable de récupérer le dernier backup depuis le bucket S3 et de le restaurer sur la VM base de données.

- Le playbook doit être exécutable indépendamment du playbook principal.

- La procédure de restauration doit être documentée dans le README.

| Critère                                 | Points     |
| --------------------------------------- | ---------- |
| **Bonus - Restauration depuis S3**      | **+2 pts** |
| Playbook `restore.yml` fonctionnel      | +1 pt      |
| Procédure documentée et jouable de zéro | +1 pt      |

---

6. Conseils

- **Commencez par Terraform :** validez que toutes vos machines sont up avant de toucher à Ansible.

- Générez l'inventaire Ansible dynamiquement depuis les outputs Terraform (fichier ou script).

- Molecule peut tourner en local avec Docker/Vagrant pendant que le cloud est provisionné.

- Le load balancer ne doit pas connaître la BDD – **vérifiez vos règles firewall**.

- _Un projet propre et documenté qui ne tourne pas vaut plus qu'un projet qui tourne mais incompréhensible_.

- Pensez au `.gitignore` avant le premier commit, et ayez un historique clair.

**Bonne chance à tous !**

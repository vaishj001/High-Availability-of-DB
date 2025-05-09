# 🐘 PostgreSQL High Availability Cluster on Azure  
  ⛓️ Streaming Replication | ⚡️ Automatic Failover | ♻️ Cron-Based Backup & Restore

## 📌 Project Overview

This project simulates a production-ready PostgreSQL High Availability (HA) environment built entirely on Microsoft Azure. Using four Ubuntu virtual machines, we implemented replication, automatic failover, and scheduled backups using open-source tools: PostgreSQL 14, Patroni, pg_basebackup, etcd, and cron.

The cluster supports:
- Real-time streaming replication across multiple nodes
- Automatic failover and leader re-election using Patroni
- Scheduled, timestamped full backups via cron
- Manual and isolated full-database restores (cluster-aware and standalone)

🗃️ We created a sample expense-tracking database to test replication accuracy and restore fidelity under realistic fault and recovery conditions. The database consisted of personal expenses, with tables for Expenses, Categories, Income, and Users.


---

## 🏗️ Architecture


                ┌────────────┐
                │   etcd VM  │
                │  (Monitor) │
                └─────┬──────┘
                      │
          ┌───────────┴────────────┐
          │                        │
    ┌────────────┐          ┌──────────────┐
    │   node1     │          │ secondary-1  │
    │ (Primary)   │          │  (Replica)   │
    └────────────┘          └──────────────┘
          │                        │
          └──────────┬─────────────┘
                     │
            ┌──────────────┐
            │ secondary-2  │
            │  (Replica)   │
            └──────────────┘


---

## 🎯 Key Features

### ✅ PostgreSQL Streaming Replication
- pg_basebackup used to clone primary to replicas
- WAL archiving, standby.signal, and replication slots enabled
- Consistent real-time data replication validated across all nodes

### ✅ Automatic Failover (via Patroni + etcd)
- Primary node failure triggers automatic promotion of a replica
- Recovered nodes rejoin as secondaries without manual intervention
- Cluster state managed via etcd and Patroni REST API

### ✅ Backup Automation
- Custom cron job triggers pg_basebackup every 30 minutes
- Leader validation via Patroni REST API before backup
- Backups archived as .tar.gz and old ones cleaned after 3 generations

### ✅ Full Restore
- Validated both cluster-aware and standalone restore workflows
- Safely restored full backups on isolated nodes to avoid replication overwrite
- Verified schema and row consistency post-restore using psql and pgAdmin

---

## 🔧 Tech Stack

| Layer              | Tools Used                                 |
|-------------------|---------------------------------------------|
| Database Engine    | PostgreSQL 14                              |
| HA & Failover      | Patroni, etcd                               |
| Replication        | Streaming Replication (async)              |
| Infrastructure     | Azure Virtual Machines (Ubuntu 22.04)      |
| Backup             | pg_basebackup, cron, Bash scripts          |
| Monitoring & Control | Patroni REST API, pgAdmin                 |

---

## 🧪 Implementation Highlights

### 🔄 Failover Testing
- Simulated node failures using kill -9 and systemctl stop
- Patroni logs and REST status confirmed role transitions
- Write attempts on replicas correctly rejected

### 💾 Backup Logic

#### Cron Job: To automate backups every 30 minutes

```
Path: /var/backups/pg_backup.sh
*/30 * * * * /var/backups/pg_backup.sh
```

#### Backup Script logic:
- Verifies leadership via Patroni REST API
- Triggers compressed pg_basebackup
- Archives it with a timestamped name
- Removes backup folders after tarring
- Keeps only the 3 latest archives


### 🔁 Restore Logic (Standalone Node)

#### 1. Stop PostgreSQL
```
sudo pkill postgres
```

#### 2. Clean old data
```
sudo rm -rf /var/lib/postgresql/14/main
```

#### 3. Extract backup
```
sudo tar -xzf /var/backups/postgres/basebackup_<timestamp>.tar.gz -C /var/lib/postgresql/14/main
```

#### 4. Restore config files (pg_basebackup does not include them)
```
sudo cp /etc/postgresql/14/main/postgresql.conf /var/lib/postgresql/14/main/
sudo cp /etc/postgresql/14/main/pg_hba.conf /var/lib/postgresql/14/main/
sudo chown postgres:postgres /var/lib/postgresql/14/main/*.conf
```

#### 5. Set ownership and permissions
```
sudo chown -R postgres:postgres /var/lib/postgresql/14/main
sudo chmod 700 /var/lib/postgresql/14/main
```

#### 6. Start PostgreSQL manually
```
sudo -u postgres /usr/lib/postgresql/14/bin/postgres -D /var/lib/postgresql/14/main
```
---

## ✅ Final Takeaways

##### ✓ Streaming replication works across 3 nodes
##### ✓ Failover from primary to secondary-1, auto-promotion confirmed in logs
##### ✓ pg_basebackup ran only on the leader and created timestamped tar.gz files
##### ✓ Restore tested with only one node running to avoid overwrite by cluster
##### ✓ Standalone node restored from .tar.gz backup using manual process
##### ✓ pgAdmin confirmed data match post-restore
##### ✓ Non-leader nodes rejected writes as expected (read-only mode enforced)

---

## 🧠 Lessons Learned

##### 🧩 Patroni is far more stable and customizable than pg_auto_failover
##### 📁 Backup files don’t include postgresql.conf or pg_hba.conf — back them up manually
##### ⚙️ Cron-based automation can break silently — always check logs
##### 🔄 Restores in HA clusters must coordinate with etcd and leader elections
##### 🧪 Verification is critical — use pgAdmin or psql to confirm rows and schema match

---

## 📂 Repo Structure
```
├── backups.sh/                 # Backup script
├── Final_Project_report.pdf/   # Final project report
├── final_slides.pdf/           # Presentation deck
├── README.md/                  # Project overview (this file)
```

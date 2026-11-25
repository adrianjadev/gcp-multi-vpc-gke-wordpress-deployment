# Multi-VPC Enterprise Network & Containerized WordPress on Google Cloud (GKE + Cloud SQL + Terraform)

A hands-on Google Cloud Platform (GCP) architecture project demonstrating **custom multi-VPC network segmentation**, a **dual-homed (multi-NIC) Bastion Host**, **Google Kubernetes Engine (GKE)** stateful workloads, **Cloud SQL Auth Proxy sidecar** database connectivity, **Cloud Monitoring** synthetic uptime checks, **least-privilege IAM**, and **Infrastructure as Code (Terraform)**.

> Built as part of the **Associate Cloud Engineer** learning path (*Develop Your Google Cloud Network*), extended with **Terraform IaC** to automate core cloud infrastructure provisioning.

---

## Architecture Diagram

```mermaid
graph TB
    classDef external fill:#f3e8fd,stroke:#9334e6,stroke-width:2px,color:#4a148c
    classDef devvpc fill:#e8f0fe,stroke:#1a73e8,stroke-width:2px,color:#0d47a1
    classDef prodvpc fill:#e6f4ea,stroke:#1e8e3e,stroke-width:2px,color:#0d652d
    classDef k8s fill:#fef7e0,stroke:#f9ab00,stroke-width:2px,color:#b06000
    classDef sql fill:#fce8e6,stroke:#d93025,stroke-width:2px,color:#a50e0e
    classDef ops fill:#e0f2f1,stroke:#00796b,stroke-width:2px,color:#004d40

    Users["End Users / Browser"]:::external
    Admin["Cloud Admin (SSH)"]:::external
    Eng2["Monitoring Engineer<br/>(roles/monitoring.editor)"]:::ops
    Uptime["Cloud Monitoring<br/>HTTP Uptime Check"]:::ops

    subgraph DevVPC ["Development VPC: griffin-dev-vpc (Custom Mode)"]
        subgraph DevMgmt ["Subnet: griffin-dev-mgmt (192.168.32.0/20)"]
            Bastion["Bastion Host (e2-medium)<br/>nic0: Dev Mgmt | nic1: Prod Mgmt<br/>Firewall: TCP:22 (tag: ssh)"]:::devvpc
        end

        subgraph DevWP ["Subnet: griffin-dev-wp (192.168.16.0/20)"]
            LB["External LoadBalancer Service<br/>(wp-service.yaml :80)"]:::k8s
            subgraph GKE ["GKE Cluster: griffin-dev (2x e2-standard-4 | us-central1-c)"]
                subgraph Pod ["WordPress Pod (wp-deployment.yaml)"]
                    WP["WordPress Container"]:::k8s
                    Proxy["Cloud SQL Auth Proxy<br/>(Sidecar Container)"]:::k8s
                    WP -->|"127.0.0.1:3306"| Proxy
                end
                Secrets["K8s Secrets<br/>(wordpress + cloudsql-instance-credentials)"]:::k8s
                PVC["PersistentVolumeClaim<br/>(wordpress-volumeclaim / 200Gi)"]:::k8s
                Secrets -.-> Pod
                PVC -.-> WP
            end
            LB --> WP
        end
    end

    subgraph ProdVPC ["Production VPC: griffin-prod-vpc (Custom Mode)"]
        ProdMgmt["Subnet: griffin-prod-mgmt<br/>(192.168.64.0/20)"]:::prodvpc
        ProdWP["Subnet: griffin-prod-wp<br/>(192.168.48.0/20)"]:::prodvpc
    end

    CloudSQL[("Cloud SQL for MySQL<br/>griffin-dev-db (us-central1)<br/>DB: wordpress | User: wp_user")]:::sql

    Users -->|"HTTP :80"| LB
    Uptime -->|"Synthetic HTTP Probes"| LB
    Eng2 -.->|"Monitors Uptime & Alerts"| Uptime
    Admin -->|"SSH :22"| Bastion
    Bastion <-->|"nic1 (Private)"| ProdMgmt
    Proxy ==>|"Encrypted IAM Tunnel<br/>(cloud-sql-proxy SA)"| CloudSQL
```

---

## Repository Structure

```text
gcp-multi-vpc-gke-wordpress/
├── .gitignore
├── README.md
├── terraform/                     # IaC automation for Tasks 1–5, Task 9 & Proxy SA
│   ├── providers.tf
│   ├── variables.tf
│   ├── terraform.tfvars.example
│   ├── network.tf                 # Tasks 1 & 2: Dev & Prod custom VPCs + 4 subnets
│   ├── bastion.tf                 # Task 3: Dual-NIC Bastion VM + SSH firewalls
│   ├── sql.tf                     # Task 4: Cloud SQL MySQL 8.0 + DB + user
│   ├── gke.tf                     # Task 5: GKE cluster + managed node pool
│   ├── iam.tf                     # Task 9: Engineer IAM + cloud-sql-proxy SA
│   └── outputs.tf
├── sql/
│   └── init-wordpress.sql         # SQL reference script for manual CLI setup
└── k8s/
    ├── wp-env.yaml.example        # PVC + MySQL credentials secret template
    ├── wp-deployment.yaml         # WordPress + Cloud SQL Auth Proxy sidecar
    └── wp-service.yaml            # External LoadBalancer service (:80)
```

---

## Network & CIDR Plan

| Environment | VPC Name | Mode | Subnet Name | Region | CIDR Block | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Development** | `griffin-dev-vpc` | Custom | `griffin-dev-wp` | `us-central1` | `192.168.16.0/20` | GKE cluster & WordPress workloads |
| **Development** | `griffin-dev-vpc` | Custom | `griffin-dev-mgmt` | `us-central1` | `192.168.32.0/20` | Bastion host primary interface (`nic0`) |
| **Production** | `griffin-prod-vpc` | Custom | `griffin-prod-wp` | `us-central1` | `192.168.48.0/20` | Isolated production application subnet |
| **Production** | `griffin-prod-vpc` | Custom | `griffin-prod-mgmt` | `us-central1` | `192.168.64.0/20` | Bastion host secondary interface (`nic1`) |

*(All CIDR blocks are strictly non-overlapping to support multi-NIC appliances and future VPC peering.)*

---

## Key Cloud & Security Engineering Concepts Demonstrated

- **Dual Provisioning Paths (IaC + CLI):** Supports automated, repeatable provisioning via **Terraform** (`terraform/`) as well as step-by-step **`gcloud` CLI** commands.
- **Custom VPC Segmentation:** Separates Development and Production environments and isolates workload traffic (`-wp`) from administrative traffic (`-mgmt`).
- **Dual-Homed Multi-NIC Bastion Host:** Bridges `griffin-dev-mgmt` and `griffin-prod-mgmt` on a single cost-effective `e2-medium` VM protected by tag-scoped ingress firewall rules (`tcp:22`).
- **Sidecar Database Security Pattern:** WordPress connects locally (`127.0.0.1:3306`) to a **Cloud SQL Auth Proxy** sidecar container inside the Pod, which opens an encrypted, IAM-authenticated tunnel to Cloud SQL (`griffin-dev-db`).
- **Stateful Kubernetes on GKE:** Uses a `PersistentVolumeClaim` so WordPress media/uploads persist across Pod restarts and isolates credentials in Kubernetes `Secrets`.
- **Observability & Least-Privilege IAM:** Implements Cloud Monitoring synthetic HTTP uptime checks and assigns non-authoritative, least-privilege IAM bindings (`roles/monitoring.editor` and `roles/cloudsql.client`).

---

## Prerequisites

- A Google Cloud Project with billing enabled
- [Google Cloud CLI (`gcloud`)](https://cloud.google.com/sdk/docs/install) and `kubectl` (or **Google Cloud Shell**)
- [Terraform `>= 1.5.7`](https://developer.hashicorp.com/terraform/install) *(required for Option A)*

---

## Phase 1: Provision Cloud Infrastructure (Tasks 1–5 & Task 9)

Choose **either Option A (Terraform - Recommended)** or **Option B (`gcloud` CLI)** to build the VPCs, Bastion Host, Cloud SQL database, GKE cluster, and IAM bindings, then proceed to **Phase 2 (Kubernetes Deployment & Monitoring)**.

---

### Option A: Automated Provisioning with Terraform (Recommended)

The `terraform/` directory automatically enables the required GCP APIs and provisions **Tasks 1–5** (Dev/Prod VPCs, Dual-NIC Bastion + Firewalls, Cloud SQL MySQL 8.0 + `wordpress` database + `wp_user`, GKE cluster + dedicated node pool), **Task 9** (additional engineer IAM binding), and the **`cloud-sql-proxy` Service Account**.

1. **Authenticate Application Default Credentials** *(skip if running inside Cloud Shell)*:
   ```bash
   gcloud auth application-default login
   ```

2. **Configure your local variables file** *(gitignored so credentials never leak)*:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your project_id, wp_db_password, and additional_engineer_email
   ```

3. **Initialize, validate, plan, and apply:**
   ```bash
   terraform init
   terraform fmt -check
   terraform validate
   terraform plan
   terraform apply
   ```

4. **Configure `kubectl` and capture Terraform outputs for Phase 2:**
   ```bash
   eval "$(terraform output -raw gke_get_credentials_command)"
   export SQL_CONNECTION=$(terraform output -raw sql_connection_name)
   export PROXY_SA_EMAIL=$(terraform output -raw cloud_sql_proxy_sa_email)
   export PROJECT_ID=$(gcloud config get-value project)
   export WP_DB_PASSWORD="<SAME_PASSWORD_SET_IN_TFVARS>"
   cd ..
   ```

> ✅ **Done with Phase 1!** Jump straight to **[Phase 2: Deploy WordPress on GKE & Enable Monitoring](#phase-2-deploy-wordpress-on-gke--enable-monitoring-steps-68)** (skipping Step 6.1 since Terraform already created the `cloud-sql-proxy` service account).

---

### Option B: Manual Provisioning with `gcloud` CLI

<details>
<summary>Click to expand full step-by-step gcloud CLI commands (Tasks 1–5 & Task 9)</summary>

#### Enable APIs & Set Environment Variables
```bash
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  sqladmin.googleapis.com \
  iam.googleapis.com \
  monitoring.googleapis.com

export PROJECT_ID=$(gcloud config get-value project)
export REGION="us-central1"
export ZONE="us-central1-c"
export DB_ROOT_PASSWORD="ChangeMeRoot!123"
export WP_DB_PASSWORD="ChangeMeWpUser!123"
export ADDITIONAL_ENGINEER_EMAIL="engineer@example.com"
```

#### Step 1: Create the Custom Development VPC (`griffin-dev-vpc`)
```bash
gcloud compute networks create griffin-dev-vpc \
  --subnet-mode=custom

gcloud compute networks subnets create griffin-dev-wp \
  --network=griffin-dev-vpc \
  --region=$REGION \
  --range=192.168.16.0/20

gcloud compute networks subnets create griffin-dev-mgmt \
  --network=griffin-dev-vpc \
  --region=$REGION \
  --range=192.168.32.0/20
```

#### Step 2: Create the Custom Production VPC (`griffin-prod-vpc`)
```bash
gcloud compute networks create griffin-prod-vpc \
  --subnet-mode=custom

gcloud compute networks subnets create griffin-prod-wp \
  --network=griffin-prod-vpc \
  --region=$REGION \
  --range=192.168.48.0/20

gcloud compute networks subnets create griffin-prod-mgmt \
  --network=griffin-prod-vpc \
  --region=$REGION \
  --range=192.168.64.0/20
```

#### Step 3: Deploy the Multi-NIC Bastion Host & SSH Firewall Rules
```bash
gcloud compute instances create griffin-dev-bastion \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --tags=ssh \
  --network-interface=subnet=griffin-dev-mgmt \
  --network-interface=subnet=griffin-prod-mgmt,no-address

gcloud compute firewall-rules create allow-dev-bastion-ssh \
  --network=griffin-dev-vpc \
  --allow=tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=ssh

gcloud compute firewall-rules create allow-prod-bastion-ssh \
  --network=griffin-prod-vpc \
  --allow=tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=ssh
```

#### Step 4: Provision & Initialize the Cloud SQL (MySQL) Instance
```bash
gcloud sql instances create griffin-dev-db \
  --database-version=MYSQL_8_0 \
  --region=$REGION \
  --zone=$ZONE \
  --tier=db-n1-standard-1 \
  --edition=ENTERPRISE \
  --root-password="$DB_ROOT_PASSWORD"

gcloud sql connect griffin-dev-db --user=root --quiet
```
Inside `mysql>`, run (replacing `<WP_DB_PASSWORD>`):
```sql
CREATE DATABASE wordpress;
CREATE USER 'wp_user'@'%' IDENTIFIED BY '<WP_DB_PASSWORD>';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'%';
FLUSH PRIVILEGES;
EXIT;
```

#### Step 5: Create the GKE Cluster (`griffin-dev`)
```bash
gcloud container clusters create griffin-dev \
  --zone=$ZONE \
  --machine-type=e2-standard-4 \
  --num-nodes=2 \
  --network=griffin-dev-vpc \
  --subnetwork=griffin-dev-wp

gcloud container clusters get-credentials griffin-dev --zone=$ZONE
export SQL_CONNECTION=$(gcloud sql instances describe griffin-dev-db --format="value(connectionName)")
export PROXY_SA_EMAIL="cloud-sql-proxy@${PROJECT_ID}.iam.gserviceaccount.com"
```

#### Step 9: Grant Least-Privilege Monitoring Access to an Additional Engineer
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="user:${ADDITIONAL_ENGINEER_EMAIL}" \
  --role="roles/monitoring.editor" \
  --condition=None
```

</details>

---

## Phase 2: Deploy WordPress on GKE & Enable Monitoring (Steps 6–8)

### Step 6: Prepare Kubernetes Secrets, Storage & Cloud SQL Proxy Credentials

1. **Create the `cloud-sql-proxy` Service Account** *(skip this sub-step if you used Option A: Terraform)*:
   ```bash
   gcloud iam service-accounts create cloud-sql-proxy \
     --display-name="Cloud SQL Proxy Service Account"

   gcloud projects add-iam-policy-binding $PROJECT_ID \
     --member="serviceAccount:${PROXY_SA_EMAIL}" \
     --role="roles/cloudsql.client" \
     --condition=None
   ```

2. **Create the local `k8s/wp-env.yaml` from the template** (ignored by `.gitignore`) and apply it:
   ```bash
   cp k8s/wp-env.yaml.example k8s/wp-env.yaml
   sed -i.bak "s/<REPLACE_WITH_DB_PASSWORD>/${WP_DB_PASSWORD}/g" k8s/wp-env.yaml && rm -f k8s/wp-env.yaml.bak
   kubectl apply -f k8s/wp-env.yaml
   ```

3. **Create the service account key secret** for the sidecar container (and delete the local JSON file immediately afterward):
   ```bash
   gcloud iam service-accounts keys create key.json \
     --iam-account="${PROXY_SA_EMAIL}"

   kubectl create secret generic cloudsql-instance-credentials \
     --from-file=key.json

   rm -f key.json
   ```

---

### Step 7: Deploy WordPress & Expose via External LoadBalancer

```bash
# Inject the Cloud SQL Instance Connection Name into the deployment manifest
sed -i.bak "s/YOUR_SQL_INSTANCE/${SQL_CONNECTION}/g" k8s/wp-deployment.yaml && rm -f k8s/wp-deployment.yaml.bak

# Apply Deployment and LoadBalancer Service
kubectl apply -f k8s/wp-deployment.yaml
kubectl apply -f k8s/wp-service.yaml

# Wait until EXTERNAL-IP is assigned
kubectl get svc wordpress --watch
```

Once an `EXTERNAL-IP` appears, visit `http://<EXTERNAL-IP>` in your browser to confirm the WordPress installer loads.

---

### Step 8: Enable Cloud Monitoring (HTTP Uptime Check)

```bash
WP_IP=$(kubectl get svc wordpress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

gcloud monitoring uptime create wordpress-uptime \
  --resource-type=uptime-url \
  --resource-labels="host=<span class="katex"><span class="katex-html" aria-hidden="true"><span class="katex-base"><span class="katex-strut" style="height:0.8889em;vertical-align:-0.1944em;"></span><span class="mord"><span class="mord mathnormal" style="margin-right:0.1389em;">W</span><span class="mord"><span class="mord mathnormal" style="margin-right:0.1389em;">P</span><span class="msupsub"><span class="vlist-t vlist-t2"><span class="vlist-r"><span class="vlist" style="height:0.3283em;"><span style="top:-2.55em;margin-left:-0.1389em;margin-right:0.05em;"><span class="pstrut" style="height:2.7em;"></span><span class="katex-sizing reset-size6 size3 mtight"><span class="mord mathnormal mtight" style="margin-right:0.0785em;">I</span></span></span></span><span class="vlist-s">​</span></span><span class="vlist-r"><span class="vlist" style="height:0.15em;"><span></span></span></span></span></span></span><span class="mord mathnormal" style="margin-right:0.1389em;">P</span></span><span class="mpunct">,</span><span class="mspace" style="margin-right:0.1667em;"></span><span class="mord mathnormal">p</span><span class="mord mathnormal" style="margin-right:0.0278em;">r</span><span class="mord mathnormal">o</span><span class="mord mathnormal" style="margin-right:0.0572em;">j</span><span class="mord mathnormal">ec</span><span class="mord"><span class="mord mathnormal">t</span><span class="msupsub"><span class="vlist-t vlist-t2"><span class="vlist-r"><span class="vlist" style="height:0.3117em;"><span style="top:-2.55em;margin-left:0em;margin-right:0.05em;"><span class="pstrut" style="height:2.7em;"></span><span class="katex-sizing reset-size6 size3 mtight"><span class="mord mathnormal mtight">i</span></span></span></span><span class="vlist-s">​</span></span><span class="vlist-r"><span class="vlist" style="height:0.15em;"><span></span></span></span></span></span></span><span class="mord mathnormal">d</span><span class="mspace" style="margin-right:0.2778em;"></span><span class="mrel">=</span></span></span></span>{PROJECT_ID}" \
  --protocol=http \
  --path="/"
```

---

## Production Security Hardening (Next-Step Upgrades)

To promote this architecture from a development portfolio project to enterprise production:

1. **Workload Identity Federation for GKE (Eliminate Static JSON Keys):** Replace the downloadable `key.json` Kubernetes Secret in Step 6 with **GKE Workload Identity Federation** so the Cloud SQL Auth Proxy sidecar authenticates using short-lived IAM tokens with zero static keys.
2. **Identity-Aware Proxy (IAP) for SSH:** Set `bastion_ssh_source_ranges = ["35.235.240.0/20"]` in `terraform.tfvars` and remove the `access_config {}` block from `terraform/bastion.tf` so the Bastion Host has no public IP.
3. **Private IP for Cloud SQL & HTTPS + Cloud Armor WAF:** Move Cloud SQL to Private Services Access inside `griffin-dev-vpc`, terminate HTTPS (`443`) using a managed SSL certificate on an Application Load Balancer (Ingress/Gateway API), and attach a **Google Cloud Armor** WAF security policy to block OWASP Top 10 exploits.
4. **Remote Terraform State & CI/CD:** Uncomment the `backend "gcs"` block in `terraform/providers.tf` (pointing to a versioned, private GCS bucket) and run `terraform plan`/`apply` via GitHub Actions with OIDC Workload Identity Federation.

---

## Clean Up (Avoid Ongoing GCP Charges)

### 1. Delete Kubernetes Workloads & Uptime Check First
*(Always delete the Kubernetes `LoadBalancer` Service before destroying the VPC/GKE cluster so GCP cleanly releases the forwarding rule and firewall rules.)*

```bash
kubectl delete -f k8s/wp-service.yaml --ignore-not-found
kubectl delete -f k8s/wp-deployment.yaml --ignore-not-found
kubectl delete -f k8s/wp-env.yaml --ignore-not-found
kubectl delete secret cloudsql-instance-credentials --ignore-not-found
```

### 2. Destroy Cloud Infrastructure

- **If provisioned with Option A (Terraform):**
  ```bash
  cd terraform
  terraform destroy
  ```

- **If provisioned with Option B (`gcloud` CLI):**
  ```bash
  gcloud container clusters delete griffin-dev --zone=$ZONE --quiet
  gcloud sql instances delete griffin-dev-db --quiet
  gcloud compute instances delete griffin-dev-bastion --zone=$ZONE --quiet
  gcloud compute firewall-rules delete allow-dev-bastion-ssh allow-prod-bastion-ssh --quiet
  gcloud compute networks subnets delete griffin-dev-wp griffin-dev-mgmt griffin-prod-wp griffin-prod-mgmt --region=$REGION --quiet
  gcloud compute networks delete griffin-dev-vpc griffin-prod-vpc --quiet
  ```

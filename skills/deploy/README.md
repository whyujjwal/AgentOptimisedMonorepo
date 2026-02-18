# Deploy Skill

Manually deploy API or Web to **Google Cloud Run**.

> **Prefer CI/CD**: Normal deployments happen automatically when you push to `main`
> via the `.github/workflows/deploy.yml` workflow. Use this skill only for emergency
> hotfixes or the initial service setup.

## Usage

```bash
bash skills/deploy/run.sh api     # Deploy FastAPI backend
bash skills/deploy/run.sh web     # Deploy Next.js frontend
bash skills/deploy/run.sh all     # Deploy API then Web
```

Or via Make:

```bash
make deploy-api
make deploy-web
```

## Environment Variables

Override defaults by setting these before running:

| Variable | Default | Description |
|---|---|---|
| `GCP_PROJECT` | `gcloud config get-value project` | GCP project ID |
| `GCP_REGION` | `us-central1` | Cloud Run region |
| `GAR_LOCATION` | `us-central1` | Artifact Registry location |
| `GAR_REPO` | `monorepo` | Artifact Registry repository name |
| `IMAGE_TAG` | short git SHA | Docker image tag |
| `PROD_API_URL` | auto-detected from Cloud Run | API URL baked into web image at build time |

## Prerequisites

### 1. Authenticate gcloud

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### 2. One-time GCP Setup

Run these once to set up the GCP infrastructure. Replace `$PROJECT` and `$ORG/REPO`:

```bash
PROJECT="your-gcp-project-id"
PROJECT_NUMBER="$(gcloud projects describe $PROJECT --format='value(projectNumber)')"
GITHUB_REPO="your-org/your-repo"   # e.g. acme/monorepo

# Create Artifact Registry repository
gcloud artifacts repositories create monorepo \
  --repository-format=docker \
  --location=us-central1 \
  --project="$PROJECT"

# Create Workload Identity Pool (for GitHub Actions — no JSON keys needed)
gcloud iam workload-identity-pools create github-pool \
  --project="$PROJECT" \
  --location=global \
  --display-name="GitHub Actions Pool"

gcloud iam workload-identity-pools providers create-oidc github-provider \
  --project="$PROJECT" \
  --location=global \
  --workload-identity-pool=github-pool \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Create Service Account for CI/CD
gcloud iam service-accounts create github-actions-sa \
  --project="$PROJECT" \
  --display-name="GitHub Actions SA"

SA="github-actions-sa@${PROJECT}.iam.gserviceaccount.com"

# Grant required roles
for ROLE in roles/run.admin roles/artifactregistry.writer \
            roles/secretmanager.secretAccessor roles/iam.serviceAccountUser; do
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member="serviceAccount:$SA" \
    --role="$ROLE"
done

# Allow GitHub Actions to impersonate the SA via WIF
gcloud iam service-accounts add-iam-policy-binding "$SA" \
  --project="$PROJECT" \
  --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool/attribute.repository/${GITHUB_REPO}"

# Output the values needed for GitHub Secrets
echo "WIF_PROVIDER: projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool/providers/github-provider"
echo "WIF_SERVICE_ACCOUNT: $SA"
```

### 3. Add Secrets to GCP Secret Manager

```bash
# Database URL (PostgreSQL connection string for production)
echo -n "postgresql+psycopg2://user:pass@host/dbname" | \
  gcloud secrets create DATABASE_URL --data-file=- --project="$PROJECT"

# App secret key
openssl rand -hex 32 | \
  gcloud secrets create SECRET_KEY --data-file=- --project="$PROJECT"
```

### 4. Add GitHub Secrets and Variables

In your GitHub repo → Settings → Secrets and variables → Actions:

**Secrets** (sensitive):
- `WIF_PROVIDER` — from step 2 output
- `WIF_SERVICE_ACCOUNT` — from step 2 output
- `PROD_API_URL` — your Cloud Run API URL (set after first API deploy)

**Variables** (non-sensitive):
- `GCP_PROJECT_ID` — your GCP project ID
- `GCP_REGION` — e.g. `us-central1`
- `GAR_LOCATION` — e.g. `us-central1`
- `GAR_REPO` — `monorepo`

## Cloud Run Service Configuration

| Setting | API | Web |
|---|---|---|
| Min instances | 1 (avoids ChromaDB cold-start) | 0 (scale to zero) |
| Max instances | 10 | 5 |
| Memory | 1 GiB | 512 MiB |
| CPU | 1 | 1 |
| Timeout | 300s | 60s |
| Auth | Private (no unauthenticated) | Public |

## ChromaDB Note

Cloud Run is stateless. ChromaDB is configured with `MEMORY_DB_PATH=/tmp/chromadb`,
meaning the vector store is ephemeral per container instance. This is acceptable for
agent memory that can be re-indexed. For persistent vector storage, consider:
- [GCS FUSE mount](https://cloud.google.com/run/docs/tutorials/network-filesystems-fuse)
- Migrating to a managed vector DB (Vertex AI Vector Search, Pinecone, etc.)

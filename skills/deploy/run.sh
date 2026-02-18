#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

TARGET="${1:-help}"

# ── Configuration (override via environment variables) ────────────────────────
GCP_PROJECT="${GCP_PROJECT:-$(gcloud config get-value project 2>/dev/null || true)}"
GCP_REGION="${GCP_REGION:-us-central1}"
GAR_LOCATION="${GAR_LOCATION:-us-central1}"
GAR_REPO="${GAR_REPO:-monorepo}"
API_SERVICE="${API_SERVICE:-api}"
WEB_SERVICE="${WEB_SERVICE:-web}"
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD)}"

GAR_BASE="${GAR_LOCATION}-docker.pkg.dev/${GCP_PROJECT}/${GAR_REPO}"

function check_prereqs() {
    if ! command -v docker &> /dev/null; then
        echo "ERROR: docker not found. Install Docker Desktop or Docker CLI."
        exit 1
    fi
    if ! command -v gcloud &> /dev/null; then
        echo "ERROR: gcloud not found. Install Google Cloud SDK."
        exit 1
    fi
    if [[ -z "$GCP_PROJECT" ]]; then
        echo "ERROR: GCP_PROJECT not set and gcloud config has no project."
        echo "  Run: gcloud config set project YOUR_PROJECT_ID"
        echo "  Or:  GCP_PROJECT=my-project bash skills/deploy/run.sh api"
        exit 1
    fi
}

function show_help() {
    cat << EOF
=== Deploy Skill ===

Deploy API or Web service to Google Cloud Run.

Usage:
  bash skills/deploy/run.sh api                  # Deploy API
  bash skills/deploy/run.sh web                  # Deploy Web (auto-detects API URL)
  bash skills/deploy/run.sh all                  # Deploy API then Web

Environment overrides:
  GCP_PROJECT     GCP project ID (default: gcloud config)
  GCP_REGION      Cloud Run region (default: us-central1)
  GAR_LOCATION    Artifact Registry location (default: us-central1)
  GAR_REPO        Artifact Registry repo name (default: monorepo)
  IMAGE_TAG       Docker image tag (default: git SHA short)
  PROD_API_URL    API URL baked into web image (default: auto-detect from Cloud Run)

Prerequisites:
  gcloud auth login
  gcloud auth configure-docker ${GAR_LOCATION}-docker.pkg.dev
  gcloud config set project YOUR_PROJECT_ID

WARNING: For production, prefer pushing to main to trigger the GitHub Actions
         deploy workflow. Use this skill for emergency deploys only.
EOF
}

function deploy_api() {
    local api_image="${GAR_BASE}/${API_SERVICE}:${IMAGE_TAG}"
    local api_latest="${GAR_BASE}/${API_SERVICE}:latest"

    echo ""
    echo "=== deploy/api: Building image ==="
    echo "  Image: $api_image"
    docker build \
        -f apps/api/Dockerfile \
        -t "$api_image" \
        -t "$api_latest" \
        .

    echo ""
    echo "=== deploy/api: Pushing image ==="
    docker push "$api_image"
    docker push "$api_latest"

    echo ""
    echo "=== deploy/api: Deploying to Cloud Run ==="
    gcloud run deploy "$API_SERVICE" \
        --image "$api_image" \
        --region "$GCP_REGION" \
        --project "$GCP_PROJECT" \
        --platform managed \
        --set-secrets "DATABASE_URL=DATABASE_URL:latest" \
        --set-env-vars "LOG_JSON=true,LOG_LEVEL=INFO,DEBUG=false,MEMORY_DB_PATH=/tmp/chromadb" \
        --min-instances 1 \
        --max-instances 10 \
        --memory 1Gi \
        --cpu 1 \
        --timeout 300 \
        --concurrency 40

    echo ""
    echo "=== deploy/api: Done ==="
    local url
    url="$(gcloud run services describe "$API_SERVICE" \
        --region "$GCP_REGION" \
        --project "$GCP_PROJECT" \
        --format "value(status.url)")"
    echo "  URL: $url"
}

function deploy_web() {
    # NEXT_PUBLIC_API_URL must be baked into the image at build time.
    # Auto-detect from the deployed API service if not provided.
    local prod_api_url="${PROD_API_URL:-}"
    if [[ -z "$prod_api_url" ]]; then
        echo "=== deploy/web: Auto-detecting API URL from Cloud Run ==="
        prod_api_url="$(gcloud run services describe "$API_SERVICE" \
            --region "$GCP_REGION" \
            --project "$GCP_PROJECT" \
            --format "value(status.url)" 2>/dev/null || true)"
        if [[ -z "$prod_api_url" ]]; then
            echo "ERROR: Could not detect API URL. Deploy the API first, or set PROD_API_URL."
            exit 1
        fi
        echo "  Detected: $prod_api_url"
    fi

    local web_image="${GAR_BASE}/${WEB_SERVICE}:${IMAGE_TAG}"
    local web_latest="${GAR_BASE}/${WEB_SERVICE}:latest"

    echo ""
    echo "=== deploy/web: Building image ==="
    echo "  Image: $web_image"
    echo "  NEXT_PUBLIC_API_URL: $prod_api_url"
    docker build \
        -f apps/web/Dockerfile \
        --build-arg "NEXT_PUBLIC_API_URL=${prod_api_url}" \
        -t "$web_image" \
        -t "$web_latest" \
        .

    echo ""
    echo "=== deploy/web: Pushing image ==="
    docker push "$web_image"
    docker push "$web_latest"

    echo ""
    echo "=== deploy/web: Deploying to Cloud Run ==="
    gcloud run deploy "$WEB_SERVICE" \
        --image "$web_image" \
        --region "$GCP_REGION" \
        --project "$GCP_PROJECT" \
        --platform managed \
        --allow-unauthenticated \
        --min-instances 0 \
        --max-instances 5 \
        --memory 512Mi \
        --cpu 1 \
        --timeout 60 \
        --concurrency 80

    echo ""
    echo "=== deploy/web: Done ==="
    local url
    url="$(gcloud run services describe "$WEB_SERVICE" \
        --region "$GCP_REGION" \
        --project "$GCP_PROJECT" \
        --format "value(status.url)")"
    echo "  URL: $url"
}

case "$TARGET" in
    api)
        check_prereqs
        deploy_api
        ;;
    web)
        check_prereqs
        deploy_web
        ;;
    all)
        check_prereqs
        deploy_api
        deploy_web
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Error: Unknown target '$TARGET'"
        echo ""
        show_help
        exit 1
        ;;
esac

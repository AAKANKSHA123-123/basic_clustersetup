#!/bin/bash

# Quick Start Deployment Script
# This script automates the deployment process

set -e

echo "=========================================="
echo "🚀 Kubernetes Demo App - Quick Deploy"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Error: docker is not installed${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}Error: kubectl is not installed${NC}"; exit 1; }
echo -e "${GREEN}✓ Prerequisites OK${NC}"
echo ""

# Get current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Step 1: Build images
echo -e "${BLUE}Step 1: Building Docker images...${NC}"
echo "Building backend..."
cd backend
docker build -t backend:latest . > /dev/null 2>&1
echo -e "${GREEN}✓ Backend image built${NC}"

echo "Building frontend..."
cd ../frontend
docker build -t frontend:latest . > /dev/null 2>&1
echo -e "${GREEN}✓ Frontend image built${NC}"
cd ..
echo ""

# Step 2: Load images (detect environment)
echo -e "${BLUE}Step 2: Making images available to cluster...${NC}"
if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
    echo "Detected minikube, loading images..."
    minikube image load backend:latest > /dev/null 2>&1
    minikube image load frontend:latest > /dev/null 2>&1
    echo -e "${GREEN}✓ Images loaded into minikube${NC}"
elif command -v kind >/dev/null 2>&1; then
    echo "Detected kind, loading images..."
    kind load docker-image backend:latest > /dev/null 2>&1
    kind load docker-image frontend:latest > /dev/null 2>&1
    echo -e "${GREEN}✓ Images loaded into kind${NC}"
else
    echo -e "${YELLOW}⚠ Not using minikube/kind. Make sure images are in your cluster's registry.${NC}"
fi
echo ""

# Step 3: Create namespace
echo -e "${BLUE}Step 3: Creating namespace...${NC}"
kubectl apply -f k8s/namespace.yaml > /dev/null 2>&1
echo -e "${GREEN}✓ Namespace created${NC}"
echo ""

# Step 4: Deploy backend
echo -e "${BLUE}Step 4: Deploying backend...${NC}"
kubectl apply -f k8s/backend-deployment.yaml -n demo-app > /dev/null 2>&1
echo -e "${GREEN}✓ Backend deployed${NC}"
echo ""

# Step 5: Deploy frontend
echo -e "${BLUE}Step 5: Deploying frontend...${NC}"
kubectl apply -f k8s/frontend-deployment.yaml -n demo-app > /dev/null 2>&1
echo -e "${GREEN}✓ Frontend deployed${NC}"
echo ""

# Step 6: Wait for pods
echo -e "${BLUE}Step 6: Waiting for pods to be ready...${NC}"
echo "This may take a minute..."
kubectl wait --for=condition=ready pod -l app=backend -n demo-app --timeout=120s > /dev/null 2>&1 || true
kubectl wait --for=condition=ready pod -l app=frontend -n demo-app --timeout=120s > /dev/null 2>&1 || true
echo ""

# Step 7: Show status
echo -e "${BLUE}Step 7: Deployment Status${NC}"
echo ""
kubectl get pods -n demo-app
echo ""
kubectl get svc -n demo-app
echo ""

# Step 8: Access instructions
echo -e "${GREEN}=========================================="
echo "✅ Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo "To access the application:"
echo ""
echo -e "${YELLOW}Option 1: Port Forwarding (Recommended)${NC}"
echo "  kubectl port-forward svc/frontend-service 8080:80 -n demo-app"
echo "  Then open: http://localhost:8080"
echo ""
if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
    echo -e "${YELLOW}Option 2: Minikube Service${NC}"
    echo "  minikube service frontend-service -n demo-app"
    echo ""
fi
echo -e "${YELLOW}Useful Commands:${NC}"
echo "  View logs:    kubectl logs -f -l app=backend -n demo-app"
echo "  Check pods:   kubectl get pods -n demo-app"
echo "  Delete all:   kubectl delete namespace demo-app"
echo ""
echo -e "${BLUE}For detailed instructions, see DEPLOYMENT_GUIDE.md${NC}"

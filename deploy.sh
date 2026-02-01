#!/bin/bash

# Simple deployment script for Kubernetes Demo App

set -e

echo "🚀 Deploying Kubernetes Demo Application"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed or not in PATH"
    exit 1
fi

echo -e "${BLUE}Step 1: Building Docker images...${NC}"
cd backend
docker build -t backend:latest . || exit 1
echo -e "${GREEN}✓ Backend image built${NC}"

cd ../frontend
docker build -t frontend:latest . || exit 1
echo -e "${GREEN}✓ Frontend image built${NC}"

cd ..

# Check if using minikube
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo -e "${BLUE}Step 2: Loading images into minikube...${NC}"
    minikube image load backend:latest
    minikube image load frontend:latest
    echo -e "${GREEN}✓ Images loaded into minikube${NC}"
elif command -v kind &> /dev/null; then
    echo -e "${BLUE}Step 2: Loading images into kind...${NC}"
    kind load docker-image backend:latest
    kind load docker-image frontend:latest
    echo -e "${GREEN}✓ Images loaded into kind${NC}"
else
    echo -e "${BLUE}Step 2: Skipping image load (not using minikube/kind)${NC}"
    echo "   Make sure your images are available in your cluster's registry"
fi

echo -e "${BLUE}Step 3: Creating namespace...${NC}"
kubectl apply -f k8s/namespace.yaml
echo -e "${GREEN}✓ Namespace created${NC}"

echo -e "${BLUE}Step 4: Deploying backend...${NC}"
kubectl apply -f k8s/backend-deployment.yaml -n demo-app
echo -e "${GREEN}✓ Backend deployed${NC}"

echo -e "${BLUE}Step 5: Deploying frontend...${NC}"
kubectl apply -f k8s/frontend-deployment.yaml -n demo-app
echo -e "${GREEN}✓ Frontend deployed${NC}"

echo ""
echo -e "${GREEN}=========================================="
echo "Deployment complete! 🎉"
echo "==========================================${NC}"
echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n demo-app --timeout=60s || true
kubectl wait --for=condition=ready pod -l app=frontend -n demo-app --timeout=60s || true

echo ""
echo "Pod status:"
kubectl get pods -n demo-app

echo ""
echo "To access the application:"
echo "  - For minikube: minikube service frontend-service -n demo-app"
echo "  - For port-forward: kubectl port-forward svc/frontend-service 8080:80 -n demo-app"
echo "  - Check LoadBalancer IP: kubectl get svc frontend-service -n demo-app"

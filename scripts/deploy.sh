#!/bin/bash
set -e
cd /home/adhidhi/kubedeploymentsetup
echo "🔄 Pulling latest code..."
git pull origin main
echo "📦 Deploying to Kubernetes..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/backend-deployment.yaml -n demo-app
kubectl apply -f k8s/frontend-deployment.yaml -n demo-app
echo "🔄 Restarting deployments..."
kubectl rollout restart deployment/backend-deployment -n demo-app
kubectl rollout restart deployment/frontend-deployment -n demo-app
echo "⏳ Waiting for rollout..."
kubectl rollout status deployment/backend-deployment -n demo-app --timeout=5m
kubectl rollout status deployment/frontend-deployment -n demo-app --timeout=5m
echo "✅ Deployment complete!"
kubectl get pods -n demo-app
kubectl get svc -n demo-app

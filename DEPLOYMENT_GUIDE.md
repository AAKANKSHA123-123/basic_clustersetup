# Step-by-Step Deployment Guide

This guide will walk you through deploying the application on Kubernetes pods.

## Prerequisites Check

First, verify you have the required tools installed:

```bash
# Check Docker
docker --version

# Check Kubernetes/kubectl
kubectl version --client

# Check if you have a Kubernetes cluster running
kubectl cluster-info
```

If any of these fail, install them first.

---

## Step 1: Navigate to Project Directory

```bash
cd /home/adhidhi/kubedeploymentsetup
```

---

## Step 2: Build Docker Images

### Build Backend Image

```bash
cd backend
docker build -t backend:latest .
```

**Expected output:** You should see Docker building the image with steps like:
```
Step 1/5 : FROM python:3.11-slim
...
Successfully built abc123def456
Successfully tagged backend:latest
```

### Build Frontend Image

```bash
cd ../frontend
docker build -t frontend:latest .
```

**Expected output:** Similar build output confirming the frontend image was created.

### Verify Images

```bash
docker images | grep -E "backend|frontend"
```

You should see both `backend:latest` and `frontend:latest` in the list.

---

## Step 3: Make Images Available to Kubernetes

**Choose the method based on your Kubernetes setup:**

### Option A: Using Minikube

```bash
# Load images into minikube
minikube image load backend:latest
minikube image load frontend:latest

# Verify images are loaded
minikube image ls | grep -E "backend|frontend"
```

### Option B: Using Kind (Kubernetes in Docker)

```bash
# Load images into kind
kind load docker-image backend:latest
kind load docker-image frontend:latest
```

### Option C: Using a Cloud Cluster (GKE, EKS, AKS)

You'll need to push images to a container registry:

```bash
# Tag images (replace with your registry)
docker tag backend:latest your-registry/backend:latest
docker tag frontend:latest your-registry/frontend:latest

# Push images
docker push your-registry/backend:latest
docker push your-registry/frontend:latest

# Then update k8s/*.yaml files to use: your-registry/backend:latest
```

### Option D: Using Docker Desktop Kubernetes

If using Docker Desktop's built-in Kubernetes, images are already available.

---

## Step 4: Create Kubernetes Namespace

```bash
cd /home/adhidhi/kubedeploymentsetup
kubectl apply -f k8s/namespace.yaml
```

**Expected output:**
```
namespace/demo-app created
```

Verify:
```bash
kubectl get namespace demo-app
```

---

## Step 5: Deploy Backend

```bash
kubectl apply -f k8s/backend-deployment.yaml -n demo-app
```

**Expected output:**
```
deployment.apps/backend-deployment created
service/backend-service created
```

### Check Backend Pods Status

```bash
kubectl get pods -n demo-app -l app=backend
```

**Wait for pods to be ready** (status should show `Running`):
```bash
# Watch pods until they're ready
kubectl get pods -n demo-app -l app=backend -w
```

Press `Ctrl+C` once pods show `Running` status.

### Verify Backend is Working

```bash
# Check pod logs
kubectl logs -n demo-app -l app=backend --tail=20

# Test backend service (from within cluster)
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -n demo-app -- curl http://backend-service:5000/api/health
```

---

## Step 6: Deploy Frontend

```bash
kubectl apply -f k8s/frontend-deployment.yaml -n demo-app
```

**Expected output:**
```
deployment.apps/frontend-deployment created
service/frontend-service created
```

### Check Frontend Pods Status

```bash
kubectl get pods -n demo-app -l app=frontend
```

Wait for pods to be ready (same as backend).

---

## Step 7: Verify All Resources

```bash
# Check all pods
kubectl get pods -n demo-app

# Check all services
kubectl get svc -n demo-app

# Check deployments
kubectl get deployments -n demo-app
```

**Expected output:**
```
NAME                                  READY   STATUS    RESTARTS   AGE
backend-deployment-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
backend-deployment-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
frontend-deployment-xxxxxxxxxx-xxxxx  1/1     Running   0          1m
frontend-deployment-xxxxxxxxxx-xxxxx  1/1     Running   0          1m

NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
backend-service      ClusterIP      10.96.x.x       <none>        5000/TCP       2m
frontend-service     LoadBalancer   10.96.x.x       <pending>     80:xxxxx/TCP   1m
```

---

## Step 8: Access the Application

### Method 1: Port Forwarding (Works Everywhere)

```bash
# Forward frontend service to local port 8080
kubectl port-forward svc/frontend-service 8080:80 -n demo-app
```

**Then open your browser:** http://localhost:8080

Keep the terminal open while using the app. Press `Ctrl+C` to stop.

### Method 2: Minikube Service

```bash
minikube service frontend-service -n demo-app
```

This will automatically open your browser.

### Method 3: LoadBalancer (Cloud Providers)

```bash
# Get the external IP
kubectl get svc frontend-service -n demo-app

# Wait for EXTERNAL-IP to be assigned (may take a few minutes)
# Then access: http://<EXTERNAL-IP>
```

### Method 4: NodePort (Alternative)

If LoadBalancer doesn't work, you can change the service type:

```bash
kubectl patch svc frontend-service -n demo-app -p '{"spec":{"type":"NodePort"}}'
kubectl get svc frontend-service -n demo-app
# Access via: http://<node-ip>:<node-port>
```

---

## Step 9: Test the Application

1. **Open the frontend** in your browser (from Step 8)
2. **Check connection status** - Should show "✓ Connected to backend"
3. **Add an item:**
   - Enter a name (e.g., "Test Item")
   - Optionally add a description
   - Click "Add Item"
4. **Verify item appears** in the items list
5. **Delete an item** by clicking the "Delete" button

### Test Backend API Directly

```bash
# Health check
curl http://localhost:8080/api/health

# Get items
curl http://localhost:8080/api/items

# Add item (if port-forwarding)
curl -X POST http://localhost:8080/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"API Test","description":"Testing via curl"}'
```

---

## Step 10: View Logs (Optional)

### Backend Logs

```bash
# View logs from all backend pods
kubectl logs -f -l app=backend -n demo-app

# View logs from a specific pod
kubectl logs -f <pod-name> -n demo-app
```

### Frontend Logs

```bash
kubectl logs -f -l app=frontend -n demo-app
```

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n demo-app

# Describe pod to see errors
kubectl describe pod <pod-name> -n demo-app

# Check events
kubectl get events -n demo-app --sort-by='.lastTimestamp'
```

**Common issues:**
- **ImagePullBackOff**: Image not found - verify images are loaded/pushed
- **CrashLoopBackOff**: Check logs for application errors
- **Pending**: Check resource availability

### Can't Access Frontend

```bash
# Verify frontend pods are running
kubectl get pods -n demo-app -l app=frontend

# Check frontend service
kubectl get svc frontend-service -n demo-app

# Test backend connectivity from frontend pod
kubectl exec -it <frontend-pod-name> -n demo-app -- wget -O- http://backend-service:5000/api/health
```

### Backend Connection Errors

```bash
# Verify backend pods are running
kubectl get pods -n demo-app -l app=backend

# Check backend service
kubectl get svc backend-service -n demo-app

# Test backend directly
kubectl port-forward svc/backend-service 5000:5000 -n demo-app
# Then: curl http://localhost:5000/api/health
```

---

## Clean Up (When Done)

To remove everything:

```bash
# Delete entire namespace (removes all resources)
kubectl delete namespace demo-app

# Or delete individually
kubectl delete -f k8s/frontend-deployment.yaml -n demo-app
kubectl delete -f k8s/backend-deployment.yaml -n demo-app
kubectl delete -f k8s/namespace.yaml
```

---

## Quick Reference Commands

```bash
# Check everything
kubectl get all -n demo-app

# Scale backend
kubectl scale deployment backend-deployment --replicas=3 -n demo-app

# Restart deployments
kubectl rollout restart deployment/backend-deployment -n demo-app
kubectl rollout restart deployment/frontend-deployment -n demo-app

# View deployment history
kubectl rollout history deployment/backend-deployment -n demo-app

# Access FastAPI docs (if port-forwarding backend)
kubectl port-forward svc/backend-service 5000:5000 -n demo-app
# Then visit: http://localhost:5000/docs
```

---

## Next Steps

- **Add persistent storage** for data persistence
- **Configure ingress** for proper domain routing
- **Add secrets** for sensitive configuration
- **Set up monitoring** with Prometheus/Grafana
- **Configure autoscaling** based on load

Happy deploying! 🚀

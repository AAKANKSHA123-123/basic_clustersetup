# Kubernetes Demo Application

A simple full-stack application with Python Flask backend and HTML/CSS/JS frontend, ready to deploy on Kubernetes.

## Project Structure

```
.
├── backend/
│   ├── app.py              # FastAPI backend application
│   ├── requirements.txt    # Python dependencies
│   └── Dockerfile          # Backend container image
├── frontend/
│   ├── index.html          # Frontend HTML
│   ├── styles.css          # Frontend styles
│   ├── app.js              # Frontend JavaScript
│   └── Dockerfile          # Frontend container image
└── k8s/
    ├── namespace.yaml           # Kubernetes namespace
    ├── backend-deployment.yaml  # Backend deployment & service
    └── frontend-deployment.yaml # Frontend deployment & service
```

## Features

- **Backend**: RESTful API with FastAPI
  - Health check endpoint
  - CRUD operations for items
  - CORS enabled for frontend communication
  - Automatic API documentation at `/docs` and `/redoc`

- **Frontend**: Modern responsive UI
  - Add/delete items
  - Real-time status monitoring
  - Clean, modern design

## Prerequisites

- Docker installed and running
- Kubernetes cluster (minikube, kind, or cloud cluster)
- kubectl configured to access your cluster

## Quick Start

### 1. Build Docker Images

```bash
# Build backend image
cd backend
docker build -t backend:latest .

# Build frontend image
cd ../frontend
docker build -t frontend:latest .
```

**Note**: If using minikube, load images into minikube:
```bash
minikube image load backend:latest
minikube image load frontend:latest
```

**Or** if using kind:
```bash
kind load docker-image backend:latest
kind load docker-image frontend:latest
```

### 2. Deploy to Kubernetes

```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy backend
kubectl apply -f k8s/backend-deployment.yaml -n demo-app

# Deploy frontend
kubectl apply -f k8s/frontend-deployment.yaml -n demo-app
```

### 3. Access the Application

**For LoadBalancer (cloud providers):**
```bash
kubectl get svc frontend-service -n demo-app
# Use the EXTERNAL-IP from the output
```

**For minikube:**
```bash
minikube service frontend-service -n demo-app
```

**For port-forwarding (any cluster):**
```bash
kubectl port-forward svc/frontend-service 8080:80 -n demo-app
# Access at http://localhost:8080
```

## API Endpoints

- `GET /api/health` - Health check
- `GET /api/items` - Get all items
- `POST /api/items` - Create new item (body: `{"name": "string", "description": "string"}`)
- `DELETE /api/items/<id>` - Delete item

## Useful Commands

```bash
# Check pod status
kubectl get pods -n demo-app

# View logs
kubectl logs -f deployment/backend-deployment -n demo-app
kubectl logs -f deployment/frontend-deployment -n demo-app

# Scale deployments
kubectl scale deployment backend-deployment --replicas=3 -n demo-app

# Delete everything
kubectl delete namespace demo-app
```

## Customization

### Update API URL in Frontend

If you need to change the backend URL, update the `API_URL` environment variable in `k8s/frontend-deployment.yaml` or modify `frontend/app.js`.

### Using Container Registry

Instead of building locally, push images to a registry:

```bash
# Tag images
docker tag backend:latest your-registry/backend:latest
docker tag frontend:latest your-registry/frontend:latest

# Push images
docker push your-registry/backend:latest
docker push your-registry/frontend:latest

# Update image names in deployment YAMLs
# Change: image: backend:latest
# To: image: your-registry/backend:latest
```

## Troubleshooting

- **Pods not starting**: Check image pull policy and ensure images are available
- **Connection errors**: Verify services are running and check service selectors match pod labels
- **502 errors**: Ensure backend pods are healthy and service is routing correctly

## License

MIT

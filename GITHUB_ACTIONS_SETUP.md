# GitHub Actions CI/CD Setup Guide

This guide will help you set up automated build and deployment using GitHub Actions.

## Prerequisites

1. GitHub account and repository
2. Docker Hub account (aakanksha0511)
3. Kubernetes cluster access (kubectl configured)
4. kubeconfig file for your cluster

## Step 1: Create GitHub Repository

```bash
cd /home/adhidhi/kubedeploymentsetup

# Initialize git if not already done
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit with GitHub Actions CI/CD"

# Add remote (replace with your GitHub repo URL)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# Push to GitHub
git push -u origin main
```

## Step 2: Set Up GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these secrets:

### 1. DOCKER_USERNAME
- **Name**: `DOCKER_USERNAME`
- **Value**: `aakanksha0511`

### 2. DOCKER_PASSWORD
- **Name**: `DOCKER_PASSWORD`
- **Value**: Your Docker Hub password or access token
  - To create access token: Docker Hub → Account Settings → Security → New Access Token
  - Recommended: Use access token instead of password

### 3. KUBECONFIG
- **Name**: `KUBECONFIG`
- **Value**: Base64 encoded kubeconfig file

To get your kubeconfig:
```bash
# On genai02, get your kubeconfig
cat ~/.kube/config | base64 -w 0

# Or if you have a specific kubeconfig file:
cat /path/to/kubeconfig | base64 -w 0

# Copy the output and paste as the secret value
```

## Step 3: Verify Workflow File

The workflow file is already created at `.github/workflows/deploy.yml`. It will:

1. **Build and Push** (on push to main/master):
   - Build backend Docker image
   - Build frontend Docker image
   - Push both to Docker Hub

2. **Deploy** (after build completes):
   - Apply Kubernetes manifests
   - Wait for rollout to complete
   - Show deployment status

## Step 4: Test the Workflow

### Option 1: Push to trigger automatically
```bash
# Make a small change
echo "# Test" >> README.md
git add README.md
git commit -m "Test GitHub Actions workflow"
git push origin main
```

### Option 2: Manual trigger
1. Go to GitHub repository → **Actions** tab
2. Select **Build and Deploy to Kubernetes** workflow
3. Click **Run workflow** → **Run workflow**

## Step 5: Monitor Workflow Execution

1. Go to your GitHub repository
2. Click **Actions** tab
3. Click on the latest workflow run
4. Watch the build and deployment progress

## Workflow Details

### Build Job
- Runs on: `ubuntu-latest`
- Builds both backend and frontend images
- Tags images with `latest` and commit SHA
- Pushes to Docker Hub

### Deploy Job
- Runs after build completes
- Sets up kubectl
- Applies Kubernetes manifests
- Waits for rollout completion
- Shows final status

## Troubleshooting

### Build fails with "denied: requested access to the resource is denied"
- Check Docker Hub credentials in secrets
- Verify `DOCKER_USERNAME` matches your Docker Hub username
- Ensure `DOCKER_PASSWORD` is correct

### Deploy fails with "Unable to connect to the server"
- Verify `KUBECONFIG` secret is correctly base64 encoded
- Check if kubeconfig has valid cluster credentials
- Ensure cluster is accessible from GitHub Actions runners

### Images not updating in Kubernetes
- Verify `imagePullPolicy: Always` in deployment YAMLs
- Check if pods are restarting: `kubectl get pods -n demo-app -w`
- Force rollout restart: `kubectl rollout restart deployment/backend-deployment -n demo-app`

### Workflow not triggering
- Ensure you're pushing to `main` or `master` branch
- Check if workflow file is in `.github/workflows/` directory
- Verify YAML syntax is correct

## Customization

### Change Docker Hub username
Edit `.github/workflows/deploy.yml`:
```yaml
env:
  DOCKER_USERNAME: your-username
```

### Change branch trigger
Edit `.github/workflows/deploy.yml`:
```yaml
on:
  push:
    branches: [ main, develop ]  # Add your branches
```

### Add environment-specific deployments
You can add multiple deploy jobs for different environments:
```yaml
deploy-staging:
  # ... staging config

deploy-production:
  # ... production config
```

## Security Best Practices

1. **Use Access Tokens**: Use Docker Hub access tokens instead of passwords
2. **Rotate Secrets**: Regularly rotate your secrets
3. **Limit Access**: Use repository secrets (not organization secrets) when possible
4. **Review Logs**: Regularly review GitHub Actions logs for any issues

## Next Steps

After setup:
1. Make changes to your code
2. Commit and push to GitHub
3. Watch GitHub Actions build and deploy automatically
4. Verify deployment: `kubectl get pods -n demo-app`

## Useful Commands

```bash
# Check workflow runs
gh run list  # If you have GitHub CLI

# View workflow logs
gh run view <run-id>  # If you have GitHub CLI

# Check Kubernetes deployment
kubectl get pods -n demo-app
kubectl get svc -n demo-app
kubectl logs -f -l app=backend -n demo-app
```

## Support

If you encounter issues:
1. Check GitHub Actions logs for detailed error messages
2. Verify all secrets are set correctly
3. Test kubectl access manually: `kubectl get nodes`
4. Test Docker Hub login: `docker login -u aakanksha0511`

Happy automating! 🚀

# SSH Setup Guide for GitHub Actions Deployment

Since your Kubernetes cluster is on a private network (10.9.110.148), GitHub Actions cannot access it directly. We'll use SSH to deploy from your genai02 server.

## Step 1: Generate SSH Key Pair

On genai02 server, run:

```bash
# Generate SSH key pair
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions -N ""

# Add public key to authorized_keys
cat ~/.ssh/github_actions.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh

# Display the private key (copy this for GitHub secret)
echo "=== PRIVATE KEY (copy this) ==="
cat ~/.ssh/github_actions
```

## Step 2: Add GitHub Secrets

Go to your GitHub repository:
1. **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**

Add these 3 secrets:

### Secret 1: SSH_HOST
- **Name**: `SSH_HOST`
- **Value**: `genai02` (or your server IP/hostname)
- Click **Add secret**

### Secret 2: SSH_USER
- **Name**: `SSH_USER`
- **Value**: `adhidhi` (your username)
- Click **Add secret**

### Secret 3: SSH_PRIVATE_KEY
- **Name**: `SSH_PRIVATE_KEY`
- **Value**: Paste the entire private key from Step 1 (including `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----`)
- Click **Add secret**

## Step 3: Verify SSH Access

Test SSH connection manually:

```bash
# From genai02, test SSH to itself
ssh -i ~/.ssh/github_actions adhidhi@genai02 "echo 'SSH test successful'"
```

## Step 4: Ensure Git Repository is Cloned

Make sure the repository exists on genai02:

```bash
cd /home/adhidhi/kubedeploymentsetup

# If not cloned, clone it:
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git /home/adhidhi/kubedeploymentsetup
```

## Step 5: Test the Workflow

1. Push the updated workflow file:
```bash
git add .github/workflows/deploy.yml
git commit -m "Update workflow to use SSH deployment"
git push origin main
```

2. Go to GitHub → **Actions** tab
3. Watch the workflow run
4. The deploy job should now connect via SSH and deploy successfully

## Troubleshooting

### SSH Connection Failed
- Verify `SSH_HOST` is correct (try IP address instead of hostname)
- Check if SSH port 22 is open
- Verify `SSH_USER` matches your username
- Test SSH manually: `ssh adhidhi@genai02`

### Permission Denied
- Verify private key is correctly copied (include BEGIN/END lines)
- Check `~/.ssh/authorized_keys` has the public key
- Verify file permissions: `chmod 600 ~/.ssh/authorized_keys`

### Git Pull Failed
- Ensure repository is cloned on genai02
- Check git remote URL is correct
- Verify you have read access to the repository

### Kubectl Commands Failed
- Verify kubectl is installed on genai02
- Check kubeconfig is configured: `kubectl get nodes`
- Ensure you have permissions to deploy to `demo-app` namespace

## Security Notes

1. **SSH Key**: Keep the private key secure - never commit it to git
2. **Access**: The SSH key only needs access to genai02, not the entire network
3. **Rotation**: Consider rotating SSH keys periodically
4. **Permissions**: The SSH user only needs access to deploy scripts and kubectl

## Alternative: Use Existing SSH Key

If you already have an SSH key set up:

```bash
# Use existing private key
cat ~/.ssh/id_rsa  # or id_ed25519, etc.

# Add to GitHub secret SSH_PRIVATE_KEY
```

Make sure the corresponding public key is in `~/.ssh/authorized_keys`.

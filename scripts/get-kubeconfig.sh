#!/bin/bash
# Script to generate base64 encoded kubeconfig for GitHub Secrets

echo "Generating base64 encoded kubeconfig..."
echo ""

# Check if kubeconfig exists
if [ -f "$HOME/.kube/config" ]; then
    KUBECONFIG_PATH="$HOME/.kube/config"
elif [ -n "$KUBECONFIG" ]; then
    KUBECONFIG_PATH="$KUBECONFIG"
else
    echo "Error: kubeconfig not found"
    echo "Please specify path: $0 /path/to/kubeconfig"
    exit 1
fi

# If argument provided, use it
if [ -n "$1" ]; then
    KUBECONFIG_PATH="$1"
fi

if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "Error: File not found: $KUBECONFIG_PATH"
    exit 1
fi

echo "Using kubeconfig: $KUBECONFIG_PATH"
echo ""
echo "Base64 encoded kubeconfig (copy this for GitHub Secret KUBECONFIG):"
echo "=========================================="
cat "$KUBECONFIG_PATH" | base64 -w 0
echo ""
echo "=========================================="
echo ""
echo "To set this as a GitHub secret:"
echo "1. Go to your GitHub repo → Settings → Secrets → Actions"
echo "2. Click 'New repository secret'"
echo "3. Name: KUBECONFIG"
echo "4. Value: (paste the base64 string above)"
echo "5. Click 'Add secret'"

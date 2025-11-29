#!/bin/bash
# Deploy modified TAK Server scripts to OpenWrt device
# Usage: ./deploy_scripts.sh [device-ip] [device-password]
# If .env file exists in the project root, it will be used for defaults

# Get the project root directory (parent of this script's directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load .env file from project root if it exists (for default values)
if [ -f "${PROJECT_ROOT}/.env" ]; then
    set -a
    source "${PROJECT_ROOT}/.env"
    set +a
fi

# Use command-line arguments or fall back to .env defaults
DEVICE_IP="${1:-${DEVICE_IP}}"
DEVICE_USER="${DEVICE_USER:-root}"
DEVICE_PASS="${2:-${DEVICE_PASS}}"

# Check if required parameters are provided
if [ -z "$DEVICE_IP" ] || [ -z "$DEVICE_PASS" ]; then
    echo "Usage: $0 [device-ip] [device-password]"
    echo ""
    echo "You can either:"
    echo "  1. Provide IP and password as arguments: $0 192.168.1.1 mypassword"
    echo "  2. Create a .env file in the project root with DEVICE_IP and DEVICE_PASS"
    echo "  3. Copy .env.example to .env in the project root and update the values"
    exit 1
fi
SCRIPTS_DIR="scripts"
TARGET_DIR="~/tak-server/scripts"

echo "=== Deploying TAK Server scripts to device ==="
echo "Device: ${DEVICE_USER}@${DEVICE_IP}"
echo ""

# Check if scripts directory exists locally
if [ ! -d "$SCRIPTS_DIR" ]; then
    echo "ERROR: $SCRIPTS_DIR directory not found in current directory"
    exit 1
fi

# Check if required scripts exist
REQUIRED_SCRIPTS=("setup.sh" "certDP.sh" "shareCerts.sh")
for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -f "$SCRIPTS_DIR/$script" ]; then
        echo "ERROR: Required script $SCRIPTS_DIR/$script not found"
        exit 1
    fi
done

# Copy scripts to device
echo "Step 1: Copying scripts to device..."
for script in "${REQUIRED_SCRIPTS[@]}"; do
    echo "  - Copying $script..."
    sshpass -p "$DEVICE_PASS" scp -o StrictHostKeyChecking=no "$SCRIPTS_DIR/$script" "${DEVICE_USER}@${DEVICE_IP}:${TARGET_DIR}/" || {
        echo "ERROR: Failed to copy $script"
        exit 1
    }
done
echo "✓ All scripts copied to ${TARGET_DIR}"

# Make scripts executable
echo ""
echo "Step 2: Making scripts executable..."
for script in "${REQUIRED_SCRIPTS[@]}"; do
    sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" "chmod +x ${TARGET_DIR}/${script}" || {
        echo "ERROR: Failed to make $script executable"
        exit 1
    }
done
echo "✓ All scripts are now executable"

# Verify scripts on device
echo ""
echo "Step 3: Verifying scripts on device..."
sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" << 'REMOTE_EOF'
cd ~/tak-server/scripts
echo "Scripts in ~/tak-server/scripts:"
ls -lh *.sh 2>/dev/null || echo "No .sh files found"
REMOTE_EOF

echo ""
echo "=== Deployment complete ==="
echo ""
echo "The modified TAK Server scripts are now installed on the device."
echo ""
echo "To run setup:"
echo "  ssh ${DEVICE_USER}@${DEVICE_IP}"
echo "  cd ~/tak-server"
echo "  ./scripts/setup.sh"
echo ""

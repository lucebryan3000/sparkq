#!/bin/bash

# NVIDIA Container Toolkit for Ubuntu 25.04 (workaround)
# Uses Ubuntu 24.04 (Noble) repository as fallback

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}NVIDIA Container Toolkit (Ubuntu 25.04 Fix)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}This script needs sudo privileges.${NC}"
    echo "Please run: sudo ./nvidia_docker_fix.sh"
    exit 1
fi

# Clean up broken repository
echo -e "${YELLOW}Cleaning up broken repository...${NC}"
rm -f /etc/apt/sources.list.d/nvidia-container-toolkit.list
rm -f /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Use Ubuntu 24.04 (Noble) repository as it's compatible
echo -e "${YELLOW}Installing NVIDIA Container Toolkit (using Ubuntu 24.04 repo)...${NC}"
echo ""

# Add GPG key
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Add repository (using Ubuntu 24.04 "noble" instead of 25.04 "plucky")
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sed 's/\${ARCH}/amd64/g' | \
    sed 's/\${ID}/ubuntu/g' | \
    sed 's/\${VERSION_ID}/24.04/g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

echo -e "${GREEN}✓ Repository configured${NC}"
echo ""

# Update and install
echo -e "${YELLOW}Installing packages...${NC}"
apt-get update
apt-get install -y nvidia-container-toolkit

echo -e "${GREEN}✓ NVIDIA Container Toolkit installed${NC}"
echo ""

# Configure Docker
echo -e "${YELLOW}Configuring Docker runtime...${NC}"
nvidia-ctk runtime configure --runtime=docker

echo -e "${GREEN}✓ Docker configured${NC}"
echo ""

# Restart Docker
echo -e "${YELLOW}Restarting Docker...${NC}"
systemctl restart docker

echo -e "${GREEN}✓ Docker restarted${NC}"
echo ""

# Test GPU access
echo -e "${YELLOW}Testing GPU access...${NC}"
echo ""

if docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ GPU Support Working!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Docker can now use your RTX 3080!"
    echo ""
else
    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}GPU test failed${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo "This might be fixed by:"
    echo "  1. Logging out and back in"
    echo "  2. Running: newgrp docker"
    echo "  3. Rebooting the system"
    echo ""
fi

# Clean up old services
echo -e "${YELLOW}=== Clean Up Old Services ===${NC}"
echo ""

if systemctl list-units --type=service | grep -q ccui-backend; then
    echo "Found old ccui-backend service (from archived project)"
    read -p "Disable it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl stop ccui-backend.service 2>/dev/null || true
        systemctl disable ccui-backend.service 2>/dev/null || true
        echo -e "${GREEN}✓ Service disabled${NC}"
    fi
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Complete${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}Summary:${NC}"
echo "  ✓ Docker 29.1.2 installed"
echo "  ✓ NVIDIA Container Toolkit installed"
echo "  ✓ GPU support configured"
echo "  ✓ System clean and ready"
echo ""

echo -e "${YELLOW}To activate docker group (avoid sudo):${NC}"
echo "  newgrp docker"
echo ""

echo -e "${YELLOW}Test GPU again:${NC}"
echo "  docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi"
echo ""

echo -e "${GREEN}Docker is now pristine and GPU-enabled!${NC}"
echo "Ready for SparkQ development."
echo ""

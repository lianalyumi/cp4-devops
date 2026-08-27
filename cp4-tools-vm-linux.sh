#!/bin/bash

# Execute este script no Azure Cloud Shell

# Variáveis
RESOURCE_GROUP="rg-linux-free"
VM_NAME="vm-linux-free"

echo "Iniciando a instalação de Ferramentas..."

# 1. Instalar os softwares
echo "Instalar tree"
az vm run-command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --command-id RunShellScript \
  --scripts "
    sudo yum install -y tree
  "

echo "Instalar Git e nano"
az vm run-command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --command-id RunShellScript \
  --scripts "
    sudo yum update -y
    sudo yum install -y git nano yum-utils
  "

echo "Instalar Azure CLI"
az vm run-command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --command-id RunShellScript \
  --scripts "
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo dnf install -y https://packages.microsoft.com/config/rhel/10/packages-microsoft-prod.rpm
    sudo dnf install -y azure-cli
  "

echo "Instalar Docker"
az vm run-command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --command-id RunShellScript \
  --scripts "
    sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  "

echo "Configurar Docker"
az vm run-command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --command-id RunShellScript \
  --scripts "
    sudo systemctl start docker
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    sudo usermod -aG docker admlnx
  "

# 2. Obter IP público
echo "Obtendo IP público da VM..."
PUBLIC_IP=$(az network public-ip show \
    --resource-group $RESOURCE_GROUP \
    --name ip-linux-free \
    --query ipAddress \
    --output tsv)

echo ""
echo "============================="
echo "VM CONFIGURADA COM SUCESSO!"
echo "============================="
echo ""
echo "Softwares instalados:"
echo "Git"
echo "nano"
echo "Azure CLI"
echo "Docker (configurado)"
echo ""
echo "Para conectar via SSH execute:"
echo "ssh $USERNAME@$PUBLIC_IP"
echo ""
echo "Senha: $PASSWORD"
echo ""
echo "============================================"

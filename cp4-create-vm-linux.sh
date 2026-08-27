#!/bin/bash

# Execute este script no Azure Cloud Shell

# Variáveis
RESOURCE_GROUP="rg-linux-free"
VM_NAME="vm-linux-free"
LOCATION="canadacentral"
IMAGE="almalinux:almalinux-x86_64:10-gen2:10.1.202512150"
SIZE="Standard_B2ats_v2"
USERNAME="admlnx"
PASSWORD="Fiap@2tdsvms"

echo "Iniciando criação da infraestrutura Azure..."

# 1. Criar Resource Group
echo "Criando Resource Group: $RESOURCE_GROUP"
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION


# 2. Criar VM com recursos de rede automáticos + NSG
echo "Criando VM com toda infraestrutura de rede..."
az vm create \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --location $LOCATION \
    --image $IMAGE \
    --size $SIZE \
    --admin-username $USERNAME \
    --admin-password $PASSWORD \
    --vnet-name vnet-linux-free \
    --vnet-address-prefix 10.0.0.0/16 \
    --subnet subnet-linux-free \
    --subnet-address-prefix 10.0.1.0/24 \
    --nsg nsg-linux-free \
    --nsg-rule SSH \
    --public-ip-sku Standard \
    --public-ip-address ip-linux-free \
    --public-ip-sku Standard \
    --nic-delete-option Delete \
    --os-disk-delete-option Delete \
    --storage-sku Premium_LRS \
    --os-disk-size-gb 64

# 3. Adicionar todas as regras NSG
echo "Adicionando regras de firewall para portas..."
az network nsg rule create \
    --resource-group $RESOURCE_GROUP \
    --nsg-name nsg-linux-free \
    --name Common_Ports \
    --protocol tcp \
    --priority 1111 \
    --destination-port-ranges 80 8080 3000 5000 5001 \
    --access allow \
    --source-address-prefixes "*"

# 3. Obter IP público
echo "Obtendo IP público da VM..."
PUBLIC_IP=$(az network public-ip show \
    --resource-group $RESOURCE_GROUP \
    --name ip-linux-free \
    --query ipAddress \
    --output tsv)

echo ""
echo "======================="
echo "VM CRIADA COM SUCESSO!"
echo "======================="
echo "Resource Group: $RESOURCE_GROUP"
echo "VM Name: $VM_NAME"
echo "Location: $LOCATION"
echo "Username: $USERNAME"
echo "Public IP: $PUBLIC_IP"
echo ""
echo "Portas abertas no firewall:"
echo "SSH (22)"
echo "HTTP (80, 8080, 3000, 5000, 5001)"
echo ""
echo "Para conectar via SSH execute:"
echo "ssh $USERNAME@$PUBLIC_IP"
echo ""
echo "Senha: $PASSWORD"
echo ""
echo "============================================"

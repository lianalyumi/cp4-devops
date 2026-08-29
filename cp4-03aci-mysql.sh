# Variaveis
# ALTERE PARA SEU RM
rm=rm565698
location="canadacentral"
resourceGroup="rg-cp4-$rm"
acrName="cp4$rm"
aciName="$rm-db"
imageName="$rm-db"
tag="v1"
storageAccountName="volumecp4$rm"
file_share_name="db-cp4-volume"
storage_key=$(az storage account keys list --resource-group $resourceGroup --account-name $storageAccountName --query "[0].value" --output tsv)
keyVaultName="keyvault-cp4-$rm"

# Registra o Serviço de ACI na Assinatura
az provider register --namespace Microsoft.ContainerInstance

# Deploy do Container MySQL (Banco de Dados)
az container create \
  --resource-group $resourceGroup \
  --name $aciName \
  --location $location \
  --image $acrName.azurecr.io/$imageName:$tag \
  --cpu 1 \
  --memory 1 \
  --os-type Linux \
  --dns-name-label $rm-db \
  --ports 3306 \
  --registry-login-server $acrName.azurecr.io \
  --registry-username $(az keyvault secret show --vault-name $keyVaultName --name acr-username --query value -o tsv) \
  --registry-password $(az keyvault secret show --vault-name $keyVaultName --name acr-password --query value -o tsv) \
  --azure-file-volume-account-name $storageAccountName \
  --azure-file-volume-account-key $storage_key \
  --azure-file-volume-share-name $file_share_name \
  --azure-file-volume-mount-path /var/lib/mysql \
  --environment-variables \
    MYSQL_ROOT_PASSWORD=$(az keyvault secret show --vault-name $keyVaultName --name mysql-root-password --query value -o tsv) \
    MYSQL_DATABASE=$(az keyvault secret show --vault-name $keyVaultName --name mysql-database --query value -o tsv) \
    MYSQL_USER=$(az keyvault secret show --vault-name $keyVaultName --name mysql-user --query value -o tsv) \
    MYSQL_PASSWORD=$(az keyvault secret show --vault-name $keyVaultName --name mysql-password --query value -o tsv) \
  --restart-policy Always

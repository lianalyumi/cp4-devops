# Variaveis
# ALTERE PARA SEU RM
rm=rm565698
resourceGroup="rg-cp4-$rm"
location="canadacentral"
MYSQL_ROOT_PASSWORD=senha-root-cp4$rm
MYSQL_DATABASE=cp4db
MYSQL_USER=user-cp4$rm
MYSQL_PASSWORD=senha-cp4$rm
SPRING_DATASOURCE_URL=jdbc:mysql://$rm-db:3306/cp4db
SPRING_DATASOURCE_USERNAME=user-cp4$rm
SPRING_DATASOURCE_PASSWORD=senha-cp4$rm

acrName="cp4$rm"
ACRUSERNAME=$(az acr credential show --name $acrName --resource-group $resourceGroup --query username --output tsv)
ACRPASSWORD=$(az acr credential show --name $acrName --resource-group $resourceGroup --query passwords[0].value --output tsv)
keyVaultName="keyvault-cp4-$rm"

# Registra o Serviço do Key Vault na Assinatura
az provider register --namespace Microsoft.KeyVault

# Criar o Key Vault
if ! az keyvault show --name "$keyVaultName" --resource-group "$resourceGroup" &> /dev/null; then
  az keyvault create --name "$keyVaultName" --resource-group "$resourceGroup" --location "$location"
else
  echo "Key Vault '$keyVaultName' já existe no Grupo de Recurso '$resourceGroup'."
fi

# Conceder acesso de ADM no Key Vault para nossa Assinatura
az role assignment create \
  --assignee $(az account show --query user.name -o tsv) \
  --role "Key Vault Administrator" \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroup/providers/Microsoft.KeyVault/vaults/$keyVaultName

sleep 15

# Armazenar os dados sensíveis
az keyvault secret set --vault-name $keyVaultName --name mysql-root-password --value "$MYSQL_ROOT_PASSWORD"
az keyvault secret set --vault-name $keyVaultName --name mysql-database --value "$MYSQL_DATABASE"
az keyvault secret set --vault-name $keyVaultName --name mysql-user --value "$MYSQL_USER"
az keyvault secret set --vault-name $keyVaultName --name mysql-password --value "$MYSQL_PASSWORD"
az keyvault secret set --vault-name $keyVaultName --name spring-datasource-url --value "$SPRING_DATASOURCE_URL"
az keyvault secret set --vault-name $keyVaultName --name spring-datasource-username --value "$SPRING_DATASOURCE_USERNAME"
az keyvault secret set --vault-name $keyVaultName --name spring-datasource-password --value "$SPRING_DATASOURCE_PASSWORD"
az keyvault secret set --vault-name $keyVaultName --name acr-username --value "$ACRUSERNAME"
az keyvault secret set --vault-name $keyVaultName --name acr-password --value "$ACRPASSWORD"

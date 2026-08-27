# Variáveis
# ALTERE PARA SEU RM
rm=rm565698
location="canadacentral"
resourceGroup="rg-cp4-$rm"
acrName="cp4$rm"
aciName="$rm-app"
aciNameDb="$rm-db"
imageName="$rm-app"
tag="v1"
keyVaultName="keyvault-cp4-$rm"
dbURL=$(az container show --resource-group $resourceGroup --name $aciNameDb --query ipAddress.fqdn --output tsv)

# Registra o Serviço de ACI na Assintaura
az provider register --namespace Microsoft.ContainerInstance

# Deploy do Container Api (Aplicação)
az container create \
  --resource-group $resourceGroup \
  --name $aciName \
  --location $location \
  --image $acrName.azurecr.io/$imageName:$tag \
  --cpu 1 \
  --memory 1 \
  --os-type Linux \
  --dns-name-label $rm-app \
  --ports 8080 \
  --registry-login-server $acrName.azurecr.io \
  --registry-username $(az keyvault secret show --vault-name $keyVaultName --name acr-username --query value -o tsv) \
  --registry-password $(az keyvault secret show --vault-name $keyVaultName --name acr-password --query value -o tsv) \
  --environment-variables \
    SPRING_DATASOURCE_URL=$(az keyvault secret show --name spring-datasource-url --vault-name $keyVaultName --query value -o tsv | sed "s/$rm-db/$dbURL/") \
    SPRING_DATASOURCE_USERNAME=$(az keyvault secret show --name spring-datasource-username --vault-name $keyVaultName --query value -o tsv) \
    SPRING_DATASOURCE_PASSWORD=$(az keyvault secret show --name spring-datasource-password --vault-name $keyVaultName --query value -o tsv) \
  --restart-policy Always

# O comando sed troca o hostname <RM>-db pelo FQDN do ACI em runtime (Somente Linux)
#
# Outro exemplo do comando sed:
# echo "My name is Bond, James Bond" | sed "s/Bond/Stuart/g"
#
# Em Power Shell
# 'My name is Bond, James Bond' -replace 'Bond', 'Stuart'
#

# Testes após a criação
#
#fqdnApp=$(az container show --resource-group rg-cp4-rm565698 --name rm565698-app --query ipAddress.fqdn --output tsv)

#curl -X GET http://$fqdnApp:8080/api/<endpoint>

#curl -X POST http://$fqdnApp:8080/api/<endpoint> \
#  -H "Content-Type: application/json" \
#  -d '{
#    "campo1": "valor",
#    "campo2": 123
#  }'

#curl -X PUT http://$fqdnApp:8080/api/<endpoint>/<id> \
#  -H "Content-Type: application/json" \
#  -d '{
#    "campo1": "valor alterado"
#  }'

#curl -X DELETE http://$fqdnApp:8080/api/<endpoint>/<id>

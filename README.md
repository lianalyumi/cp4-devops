# Checkpoint 4: Containers em Nuvem (ACR/ACI)

> Sistema de gestão veterinária centralizada para acompanhamento contínuo da saúde de animais, com API REST em Java Spring Boot e banco de dados MySQL, containerizado na Azure.

---

## Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Arquitetura](#arquitetura)
- [Repositórios do Projeto](#repositórios-do-projeto)
- [Pré-requisitos](#pré-requisitos)
- [Instalação (How-To)](#instalação-how-to)
- [Testes do CRUD](#13-testes-do-crud)
- [Segurança](#segurança)
- [Equipe](#equipe)

---

## Sobre o Projeto
O objetivo da Clyvo é acompanhar a jornada contínua de saúde de animais, centralizando em um único lugar tudo o que um veterinário e uma clínica precisam no dia a dia: consultas, histórico, carteira de vacinação, responsável e localização.

Nesta entrega do Checkpoint 4, a aplicação API Java/Spring Boot e o banco de dados MySQL foram totalmente containerizados e implantados na nuvem Azure, utilizando **Azure Container Registry (ACR)** para armazenar as imagens Docker, **Azure Container Instance (ACI)** para executar os containers, **Azure File Storage** para persistência dos dados e **Azure Key Vault** para a segurança das credenciais.

## Arquitetura

- **Opção escolhida:** ACR + ACI
- **Banco de dados:** MySQL 8.0 (`mysql:8.0`)
- **API:** Java / Spring Boot
- **Armazenamento persistente:** Azure Files (montado no container do banco)
- **Segurança:** Credenciais armazenadas no Azure Key Vault (nenhuma senha exposta no código-fonte)

## Repositórios do Projeto

| Repositório | Conteúdo |
|---|---|
| [`cp4-devops-banco`](https://github.com/lianalyumi/cp4-devops-banco.git) | Dockerfile e scripts de inicialização do banco MySQL (DDL + dados) |
| [`cp4-devops-java`](https://github.com/lianalyumi/cp4-devops-java.git) | Código-fonte da API Java/Spring Boot + Dockerfile |
| [`cp4-devops`](https://github.com/lianalyumi/cp4-devops.git) | Scripts de criação da VM e deploy dos recursos na Azure |

## Pré-requisitos

- Conta ativa no Microsoft Azure
- Acesso ao Azure Cloud Shell

---

## Instalação (How-To)

### Por que criar uma VM?

O Azure Cloud Shell (usado no passo 1) não tem o Docker instalado — só tem o Azure CLI. Como o CRUD depende de **construir as imagens Docker**
(passos 6 a 9), é preciso um ambiente com Docker disponível. Por isso, os passos 2 a 9 criam e usam uma VM temporária só para clonar os
repositórios, montar (`docker build`) e enviar (`docker push`) as imagens ao ACR. Depois disso, a VM deixa de ser necessária (apagar no passo
9.6) e os testes seguem direto pelo Cloud Shell.

> **Caso já tenha o Docker e Azure CLI instalados na máquina (ou em outro ambiente próprio)?** Pode pular os passos 2 a 5 (criação e
> configuração da VM) e ir direto para o **passo 6**, clonando os repositórios e rodando os `docker build`/`docker push` na própria
> máquina. O restante do roteiro (passo 8 em diante) continua igual, seja rodando no Cloud Shell ou localmente.

### 1. Clonar o repositório de scripts (no Cloud Shell)

`git clone` — baixa o repositório `cp4-devops.git` para o Cloud Shell, trazendo `./cp4-create-vm-linux.sh`, `cp4-tools-vm-linux.sh` e os 4 scripts de deploy (`01` a `04`)
```bash
git clone https://github.com/lianalyumi/cp4-devops.git
```

`cd` — entra na pasta recém-clonada, de onde os próximos comandos serão executados
```bash
cd cp4-devops
```

### 2. Criar a VM de trabalho (no Cloud Shell)

`chmod +x` — concede permissão de execução ao script `cp4-create-vm-linux.sh`
```bash
chmod +x cp4-create-vm-linux.sh
```

`./cp4-create-vm-linux.sh` — executa o script, que cria o Resource Group, a VM Linux (AlmaLinux), a rede virtual, o IP público e as regras de firewall necessárias
```bash
./cp4-create-vm-linux.sh
```

### 3. Instalar as ferramentas na VM (no Cloud Shell)

`chmod +x` — concede permissão de execução ao script `cp4-tools-vm-linux.sh`
```bash
chmod +x cp4-tools-vm-linux.sh
```

`./cp4-tools-vm-linux.sh` — executa o script, que instala Git, nano, Azure CLI e Docker dentro da VM criada no passo anterior
```bash
./cp4-tools-vm-linux.sh
```

### 4. Conectar na VM via SSH - usando IP público da VM

```bash
ssh admlnx@<ip-publico>
```
Senha: `<senha>`

### 5. Instalar dependências dentro da VM

`sudo yum install` — instala Git, nano e utilitários adicionais necessários para clonar os repositórios e editar arquivos dentro da VM
```bash
sudo yum install -y git nano yum-utils
```

### 6. Clonar os repositórios do projeto (dentro da VM)

`git clone` do repositório MySQL — baixa o Dockerfile e os scripts de inicialização (DDL + dados) do banco
```bash
git clone https://github.com/lianalyumi/cp4-devops-banco.git
```

`git clone` do repositório Java — baixa o código-fonte da API Spring Boot e seu Dockerfile
```bash
git clone https://github.com/lianalyumi/cp4-devops-java.git
```

`git clone` do repositório de DEVOPS baixa novamente os scripts de deploy, desta vez dentro da VM
```bash
git clone https://github.com/lianalyumi/cp4-devops.git
```

### 7. Build das imagens Docker (dentro da VM)

`cd` — entra na pasta do repositório MySQL
```bash
cd cp4-devops-banco
```

`docker build` — constrói a imagem `rm565698-db` a partir do `Dockerfile.mysql`, empacotando o banco MySQL com os scripts de inicialização das tabelas
```bash
docker build -f Dockerfile.mysql -t rm565698-db .
```

`cd` — sai da pasta do banco e entra na pasta do repositório Java
```bash
cd ../cp4-devops-java
```

`docker build` — constrói a imagem `rm565698-app` a partir do `Dockerfile.api`, compilando a aplicação Spring Boot em uma imagem enxuta rodando com usuário não-root
```bash
docker build -f Dockerfile.api -t rm565698-app .
```

**7.1. Testar as imagens localmente (antes do push)**

Antes de enviar as imagens pro ACR, vale confirmar que elas funcionam
juntas — evita gastar tempo subindo pra nuvem uma imagem quebrada.

`docker network create` — cria uma rede Docker isolada só para esse
teste, permitindo que os dois containers se enxerguem pelo nome
```bash
docker network create teste-local
```

`docker run` — sobe o container do banco localmente, na rede criada
acima, com credenciais temporárias só para esse teste
```bash
docker run -d --name teste-db --network teste-local \
  -e MYSQL_ROOT_PASSWORD=senha-teste \
  -e MYSQL_DATABASE=cp4db \
  -e MYSQL_USER=user-teste \
  -e MYSQL_PASSWORD=senha-teste \
  rm565698-db
```

`docker run` — sobe o container da API localmente, na mesma rede,
apontando a `SPRING_DATASOURCE_URL` para o container do banco pelo nome
(`teste-db`)
```bash
docker run -d --name teste-app --network teste-local -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://teste-db:3306/cp4db \
  -e SPRING_DATASOURCE_USERNAME=user-teste \
  -e SPRING_DATASOURCE_PASSWORD=senha-teste \
  rm565698-app
```

`curl` — testa se a API local está respondendo e conseguindo consultar
o banco (confirma que as duas imagens funcionam juntas)
```bash
curl http://localhost:8080/api/animal
```

`docker rm` / `docker network rm` — encerra e remove os containers e a
rede de teste, já que eles cumpriram sua função e não são usados no
deploy real na Azure
```bash
docker rm -f teste-db teste-app
docker network rm teste-local
```

### 8. Login no Azure e criação do Resource Group + ACR (dentro da VM)

**8.1. Autenticar na conta Azure**
`az login` — autentica a sessão da VM na sua conta Azure (abre um link/código para confirmar o login no navegador)
```bash
az login
```

**8.2. Confirmar a assinatura ativa**
`az account show` — exibe a assinatura (subscription) atualmente ativa, para confirmar que é a correta antes de criar recursos
```bash
az account show
```

**8.3. Criar o Resource Group**
`az group create` — cria o Resource Group `rg-cp4-rm565698`, que vai agrupar todos os recursos do projeto (ACR, Storage, Key Vault, containers) em `canadacentral`
```bash
az group create --name rg-cp4-rm565698 --location canadacentral
```

**8.4. Habilitar o serviço de Container Registry**
`az provider register --namespace Microsoft.ContainerRegistry` — habilita o serviço de Container Registry na assinatura (necessário na primeira vez que se usa ACR nela)
```bash
az provider register --namespace Microsoft.ContainerRegistry
```

**8.5. Criar o Azure Container Registry (ACR)**
`az acr create` — cria o registry (`cp4rm565698`), onde as imagens Docker (MySQL e API Java) serão armazenadas antes do deploy:
- `--resource-group` — em qual Resource Group o ACR será criado
- `--name` — nome único do registry (vira parte da URL, ex: `cp4rm565698.azurecr.io`)
- `--sku Standard` — nível de serviço do registry (Standard oferece mais armazenamento e throughput que o Basic)
- `--location` — região onde o ACR fica hospedado
- `--public-network-enabled true` — permite acesso ao registry pela rede pública (necessário para o push/pull das imagens)
- `--admin-enabled true` — habilita o usuário administrador do registry, usado para autenticação via usuário/senha nos próximos passos
```bash
az acr create \
    --resource-group rg-cp4-rm565698 \
    --name cp4rm565698 \
    --sku Standard \
    --location canadacentral \
    --public-network-enabled true \
    --admin-enabled true
```

### 9. Login no ACR e push das imagens (dentro da VM)

**9.1. Login no registry**
`az acr login` — autentica o Docker local no Azure Container Registry cp4rm565698, permitindo realizar o push das imagens.
```bash
az acr login --name cp4rm565698
```

**9.2. Enviar a imagem do MySQL**
`docker tag` — renomeia a imagem local `rm565698-db` com o endereço completo do registry
```bash
docker tag rm565698-db cp4rm565698.azurecr.io/rm565698-db:v1
```
`docker push` — envia a imagem tageada para o ACR, ficando disponível para o deploy no ACI
```bash
docker push cp4rm565698.azurecr.io/rm565698-db:v1
```

**9.3. Enviar a imagem da API Java**
`docker tag` — mesma lógica do passo anterior, agora para a imagem da API
```bash
docker tag rm565698-app cp4rm565698.azurecr.io/rm565698-app:v1
```
`docker push` — envia a imagem da API para o ACR
```bash
docker push cp4rm565698.azurecr.io/rm565698-app:v1
```

**9.4. Conferir as imagens no registry**
`az acr repository list` — lista os repositórios (imagens) já enviados ao ACR, confirmando que o push das duas imagens funcionou
```bash
az acr repository list --name cp4rm565698 --output table
```

`az acr repository show-tags` — Eles permitem verificar que a versão v1 das imagens do banco e da API está registrada no ACR.
```bash
az acr repository show-tags \
  --name cp4rm565698 \
  --repository rm565698-db
```
```bash
az acr repository show-tags \
  --name cp4rm565698 \
  --repository rm565698-app
```

### 9.5. Limpeza das imagens locais (opcional)
`docker rmi` — remove as imagens tageadas do armazenamento local da VM, liberando espaço em disco após garantir que o envio (*push*) para o ACR foi concluído com sucesso
```bash
docker rmi cp4rm565698.azurecr.io/rm565698-db:v1
docker rmi cp4rm565698.azurecr.io/rm565698-app:v1
```

### 9.6. A VM já pode ser apagada

A partir deste ponto, a VM **não é mais necessária**. Ela serviu apenas para clonar os repositórios e construir/enviar as imagens Docker
(passos 6 a 9) — algo que o Azure Cloud Shell não consegue fazer sozinho, por não ter o Docker instalado.

Agora que as imagens já estão salvas no **ACR** (Azure Container Registry), os containers vão ser criados a partir delas diretamente
pela Azure — sem depender da VM em nenhum momento. Por isso, os próximos passos (10 em diante) podem ser executados **direto no Azure
Cloud Shell**, no mesmo lugar onde o passo 1 já clonou o repositório `cp4-devops`.

`az group delete` — remove o Resource Group `rg-linux-free`, onde ficou a VM de trabalho, já que ela cumpriu sua função
```bash
az group delete --name rg-linux-free --yes --no-wait
```

### 10. Executar os scripts de deploy (no Cloud Shell)

A partir deste ponto, os comandos voltam a ser executados diretamente no Azure Cloud Shell.

O repositório cp4-devops já foi clonado no Cloud Shell no passo 1.

**10.1. Entrar na pasta e liberar execução dos scripts**
`cd` — entra na pasta do repositório de scripts
```bash
cd cp4-devops
```
`chmod +x` — concede permissão de execução aos 4 scripts de deploy de uma vez só
```bash
chmod +x cp4-01store-account.sh cp4-02key-vault.sh cp4-03aci-mysql.sh cp4-04aci-api-java.sh
```

**10.2. Criar o volume persistente**
`./cp4-01store-account.sh` — cria a Storage Account e o File Share que servirão como volume persistente do banco MySQL (ele garante que os dados persistam caso o container reinicie)
```bash
./cp4-01store-account.sh
```

**10.3. Criar o Key Vault e armazenar as credenciais**
`./cp4-02key-vault.sh` — cria o Azure Key Vault e armazena nele as credenciais do banco e do ACR como secrets, para que nenhuma senha fique exposta no código
```bash
./cp4-02key-vault.sh
```

**10.4. Subir o container do banco MySQL**
`./cp4-03aci-mysql.sh` — cria o container ACI do MySQL, puxando a imagem do ACR, montando o volume persistente e colocando as credenciais lidas do Key Vault
```bash
./cp4-03aci-mysql.sh
```

**10.5. Subir o container da API Java**
`./cp4-04aci-api-java.sh` — cria o container ACI da API, obtém automaticamente o endereço do container do banco e coloca a string de conexão via variável de ambiente
```bash
./cp4-04aci-api-java.sh
```

**10.6. Verifica execução da aplicação sem privilégios administrativos**
`az container exec` - executa o comando `whoami` dentro do container da aplicação para verificar qual usuário está executando o processo.

```bash
az container exec \
  --resource-group rg-cp4-rm565698 \
  --name rm565698-app \
  --exec-command "whoami"
```

**10.7. Recursos criados na Azure**
`az resource list` - visualiza os recursos do Resource Group.
```bash
az resource list \
  --resource-group rg-cp4-rm565698 \
  --output table
```

`az container list` - visualiza containers criados.
```bash
az container list \
  --resource-group rg-cp4-rm565698 \
  --output table
```

`az storage account list` - visualiza Storage Account.
```bash
az storage account list \
  --resource-group rg-cp4-rm565698 \
  --output table
```

`az keyvault list` - visualiza o Key Vault.
```bash
az keyvault list \
  --resource-group rg-cp4-rm565698 \
  --output table
```

`az acr show` — exibe os detalhes do Azure Container Registry criado para o projeto.
```bash
az acr show \
  --name cp4rm565698 \
  --resource-group rg-cp4-rm565698 \
  --output table
```


### 11. Conferir os logs (no Cloud Shell)
`az container logs` do MySQL — exibe a saída do container do banco, útil para confirmar que ele terminou de inicializar
```bash
az container logs --resource-group rg-cp4-rm565698 --name rm565698-db
```

`az container logs` da API — exibe a saída do container da API, confirmando que a aplicação Spring Boot subiu e conectou no banco
```bash
az container logs --resource-group rg-cp4-rm565698 --name rm565698-app
```

### 12. Obter o endereço da API (no Cloud Shell)

`az container show` — consulta o FQDN (endereço público) do container da API, guardando na variável `fqdnApp` para uso nos testes de CRUD a seguir
```bash
fqdnApp=$(az container show --resource-group rg-cp4-rm565698 --name rm565698-app --query ipAddress.fqdn --output tsv)
```

### 13. TESTES DO CRUD

### CRUD - ANIMAL
### CREATE (POST) - Inserir um Animal

`curl -X GET` — consulta (**Read**) todos os registros existentes de **ANIMAIS**.
```bash
curl -X GET http://$fqdnApp:8080/api/animal
```

`curl -X POST` — cria (**Create**) um novo registro de **ANIMAL** na tabela via endpoint da API
```bash
curl -X POST http://$fqdnApp:8080/api/animal \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Hércules",
    "especie": "cachorro",
    "raca": "Pitbull",
    "peso": 28.5,
    "dataNascimento": "2023-05-10",
    "microchip": "13250",
    "rg": "12442546",
    "responsavel": {
      "id": 1
    }
  }'
```

`curl -X GET` — consulta (**Read**) todos os registros existentes, confirmando a inclusão feita acima
```bash
curl -X GET http://$fqdnApp:8080/api/animal
```

`curl -X GET` — consulta (**Read**) o registro `<id>`, confirmando a inclusão feita acima
```bash
curl -X GET http://$fqdnApp:8080/api/animal/<id>
```

`az container logs` - mostra os logs da API, confirmando as requisições batendo na nuvem
```bash
az container logs --resource-group rg-cp4-rm565698 --name rm565698-app
```

Cada operação pode ser confirmada diretamente no banco via SELECT.

`az container exec` — abre uma sessão `mysql` dentro do container do banco, permitindo rodar `SELECT * FROM <tabela>;` para conferir cada operação (INSERT, UPDATE, DELETE) diretamente no banco
```bash
az container exec --resource-group rg-cp4-rm565698 --name rm565698-db \
  --exec-command "mysql -u user-cp4rm565698 -psenha-cp4rm565698 cp4db"
```

```sql
SELECT id, nome, peso FROM animal WHERE id = <id>;

SELECT * FROM animal;

exit
```

### UPDATE (PUT) - Atualizar um Animal

`curl -X GET` — consulta (**Read**) todos os registros existentes de **ANIMAIS**.
```bash
curl -X GET http://$fqdnApp:8080/api/animal
```

`curl -X PUT` — atualiza (**Update**) o registro criado, identificado pelo `<id>` retornado no POST
```bash
curl -X PUT http://$fqdnApp:8080/api/animal/<id> \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Hércules da Silva",
    "especie": "cachorro",
    "raca": "Poodle",
    "peso": 10.0,
    "dataNascimento": "2020-03-08",
    "microchip": "20563",
    "rg": "89654123",
    "responsavel": {
      "id": 1
    }
  }'
```

`curl -X GET` — consulta (**Read**) todos os registros existentes, confirmando a atualização feita acima
```bash
curl -X GET http://$fqdnApp:8080/api/animal
```

`curl -X GET` — consulta (**Read**) o registro de `<id>`, confirmando a modificação feita acima
```bash
curl -X GET http://$fqdnApp:8080/api/animal/<id>
```

`az container logs` - mostra os logs da API, confirmando as requisições batendo na nuvem
```bash
az container logs --resource-group rg-cp4-rm565698 --name rm565698-app
```

Cada operação pode ser confirmada diretamente no banco via SELECT.

`az container exec` — abre uma sessão `mysql` dentro do container do banco, permitindo rodar `SELECT * FROM <tabela>;` para conferir cada operação (INSERT, UPDATE, DELETE) diretamente no banco
```bash
az container exec --resource-group rg-cp4-rm565698 --name rm565698-db \
  --exec-command "mysql -u user-cp4rm565698 -psenha-cp4rm565698 cp4db"
```

```sql
SELECT id, nome, peso FROM animal WHERE id = <id>;

SELECT * FROM animal;

exit
```

### DELETE (DELETE) - Deletar um Animal

`curl -X GET` — consulta (**Read**) todos os registros existentes de **ANIMAIS**.
```bash
curl -X GET http://$fqdnApp:8080/api/animal
```

`curl -X DELETE` — exclui (**Delete**) o registro, identificado pelo mesmo `<id>`
```bash
curl -X DELETE http://$fqdnApp:8080/api/animal/<id>
```

`curl -X GET` — consulta (**Read**) todos os registros existentes, confirmando a exclusão feita acima
```bash
curl -X GET http://$fqdnApp:8080/api/animal
```

`curl -X GET` — consulta (**Read**) o registro de `<id>`, confirmando a deleção feita acima
```bash
curl -X GET http://$fqdnApp:8080/api/animal/<id>
```

`az container logs` - mostra os logs da API, confirmando as requisições batendo na nuvem
```bash
az container logs --resource-group rg-cp4-rm565698 --name rm565698-app
```

Cada operação pode ser confirmada diretamente no banco via SELECT.

`az container exec` — abre uma sessão `mysql` dentro do container do banco, permitindo rodar `SELECT * FROM <tabela>;` para conferir cada operação (INSERT, UPDATE, DELETE) diretamente no banco
```bash
az container exec --resource-group rg-cp4-rm565698 --name rm565698-db \
  --exec-command "mysql -u user-cp4rm565698 -psenha-cp4rm565698 cp4db"
```

```sql
SELECT id, nome, peso FROM animal WHERE id = <id>;

SELECT * FROM animal;

exit
```

### CRUD - RESPONSÁVEL
### CREATE (POST) - Inserir um Responsável

`curl -X GET` — consulta (**Read**) todos os registros existentes de **RESPONSÁVEIS**.
```bash
curl -X GET http://$fqdnApp:8080/api/responsavel
```

`curl -X POST` — cria (**Create**) um novo registro de **RESPONSÁVEL** na tabela via endpoint da API
```bash
curl -X POST http://$fqdnApp:8080/api/responsavel \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Roberto",
    "cpf": "12345678901",
    "telefone": "11988887777"
  }'
```

`curl -X GET` — consulta (**Read**) todos os registros existentes, confirmando a inclusão feita acima
```bash
curl -X GET http://$fqdnApp:8080/api/responsavel
```

`curl -X GET` — consulta (**Read**) o registro de `<id>`, confirmando a inclusão feita acima
```bash
curl -X GET http://$fqdnApp:8080/api/responsavel/<id>
```

`az container logs` - mostra os logs da API, confirmando as requisições batendo na nuvem
```bash
az container logs --resource-group rg-cp4-rm565698 --name rm565698-app
```

Cada operação pode ser confirmada diretamente no banco via SELECT.

`az container exec` — abre uma sessão `mysql` dentro do container do banco, permitindo rodar `SELECT * FROM <tabela>;` para conferir cada operação (INSERT, UPDATE, DELETE) diretamente no banco
```bash
az container exec --resource-group rg-cp4-rm565698 --name rm565698-db \
  --exec-command "mysql -u user-cp4rm565698 -psenha-cp4rm565698 cp4db"
```

```sql
SELECT id, nome, telefone FROM responsavel WHERE id = <id>;

SELECT * FROM responsavel;

exit
```

### UPDATE (PUT) - Atualizar um Responsável

`curl -X GET` — consulta (**Read**) todos os registros existentes de **RESPONSÁVEIS**.
```bash
curl -X GET http://$fqdnApp:8080/api/responsavel
```

`curl -X PUT` — atualiza (**Update**) o registro criado, identificado pelo `<id>` retornado no POST
```bash
curl -X PUT http://$fqdnApp:8080/api/responsavel/<id> \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Roberto Carlos da Silva",
    "cpf": "12587965478",
    "telefone": "11999998888"
  }'
```

`curl -X GET` — consulta (**Read**) todos os registros existentes, confirmando a atualização feita acima
```bash
curl -X GET http://$fqdnApp:8080/api/responsavel
```

`curl -X GET` — consulta (**Read**) o registro de `<id>`, confirmando a modificação feita acima
```bash
curl -X GET http://$fqdnApp:8080/api/responsavel/<id>
```

`az container logs` - mostra os logs da API, confirmando as requisições batendo na nuvem
```bash
az container logs --resource-group rg-cp4-rm565698 --name rm565698-app
```

Cada operação pode ser confirmada diretamente no banco via SELECT.

`az container exec` — abre uma sessão `mysql` dentro do container do banco, permitindo rodar `SELECT * FROM <tabela>;` para conferir cada operação (INSERT, UPDATE, DELETE) diretamente no banco
```bash
az container exec --resource-group rg-cp4-rm565698 --name rm565698-db \
  --exec-command "mysql -u user-cp4rm565698 -psenha-cp4rm565698 cp4db"
```

```sql
SELECT id, nome, telefone FROM responsavel WHERE id = <id>;

SELECT * FROM responsavel;

exit
```

### DELETE (DELETE) - Excluir um Responsável

`curl -X GET` — consulta (**Read**) todos os registros existentes de **RESPONSÁVEIS**.
```bash
curl -X GET http://$fqdnApp:8080/api/responsavel
```

`curl -X DELETE` — exclui (**Delete**) o registro, identificado pelo mesmo `<id>`
```bash
curl -X DELETE http://$fqdnApp:8080/api/responsavel/<id>
```

`curl -X GET` — consulta (**Read**) todos os registros existentes, confirmando a exclusão feita acima
```bash
curl -X GET http://$fqdnApp:8080/api/responsavel
```

`curl -X GET` — consulta (**Read**) o registro de `<id>`, confirmando a deleção feita acima
```bash
curl -X GET http://$fqdnApp:8080/api/responsavel/<id>
```

`az container logs` - mostra os logs da API, confirmando as requisições batendo na nuvem
```bash
az container logs --resource-group rg-cp4-rm565698 --name rm565698-app
```

Cada operação pode ser confirmada diretamente no banco via SELECT.

`az container exec` — abre uma sessão `mysql` dentro do container do banco, permitindo rodar `SELECT * FROM <tabela>;` para conferir cada operação (INSERT, UPDATE, DELETE) diretamente no banco
```bash
az container exec --resource-group rg-cp4-rm565698 --name rm565698-db \
  --exec-command "mysql -u user-cp4rm565698 -psenha-cp4rm565698 cp4db"
```

```sql
SELECT id, nome, telefone FROM responsavel WHERE id = <id>;

SELECT * FROM responsavel;

exit
```

### 14. Limpeza final (depois de gravar o vídeo)

`az group delete` — remove o Resource Group `rg-cp4-rm565698` inteiro (ACR, Key Vault, Storage, containers do banco e da API), evitando custos desnecessários após a gravação. O Resource Group `rg-linux-free` (VM) já foi removido antes, no passo 9.6.
```bash
az group delete --name rg-cp4-rm565698 --yes --no-wait
```
`rm -rf` — remove de maneira forçada `cp4-devops` e todos os arquivos contidos nela.
```bash
rm -rf cp4-devops
```

## Segurança

Todas as credenciais (usuário/senha do banco, usuário/senha do ACR) são
armazenadas no **Azure Key Vault** e colocadas nos containers via
variáveis de ambiente em tempo de execução, nenhuma credencial fica
exposta no código-fonte ou nos scripts versionados no GitHub.

## Equipe

| RM | Nome | Turma |
|---|---|---|
| RM561713 | Eduardo Batista Locaspi | 2TDSPI |
| RM565698 | Liana Lyumi Morisita Fujisima | 2TDSPI |
| RM561833 | Victor Alves Lopes | 2TDSPI |

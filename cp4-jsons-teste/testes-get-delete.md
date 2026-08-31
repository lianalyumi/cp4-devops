# Testes GET e DELETE — API CP4

Requisições GET e DELETE não enviam corpo (payload) — o identificador do registro é passado direto na URL. Por isso, não existe um "JSON de requisição" real para essas duas operações; abaixo estão os comandos
`curl` exatamente como usados no vídeo de demonstração.

## Tabela: animal

**GET (listar todos)**
```bash
curl -X GET http://$fqdnApp:8080/api/animal
```

**GET (por ID)**
```bash
curl -X GET http://$fqdnApp:8080/api/animal/3
```

**DELETE**
```bash
curl -X DELETE http://$fqdnApp:8080/api/animal/3
```

## Tabela: responsavel

**GET (listar todos)**
```bash
curl -X GET http://$fqdnApp:8080/api/responsavel
```

**GET (por ID)**
```bash
curl -X GET http://$fqdnApp:8080/api/responsavel/3
```

**DELETE**
```bash
curl -X DELETE http://$fqdnApp:8080/api/responsavel/3
```

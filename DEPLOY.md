# Guia de Deploy - geminicli2api

Este guia explica como fazer deploy da aplicação geminicli2api usando Docker e Coolify.

## Arquivos Criados

### 1. `build-and-push.sh`
Script para fazer build da imagem Docker e enviar para o Docker Hub.

**Uso:**
```bash
# Build e push com tag 'latest'
./build-and-push.sh

# Build e push com tag personalizada
./build-and-push.sh v1.0.0
```

**Pré-requisitos:**
- Docker instalado e funcionando
- Login no Docker Hub: `docker login`
- Acesso ao repositório `drnit29/geminicli2api`

### 2. `docker-compose.local.yml`
Configuração para desenvolvimento local usando a imagem do Docker Hub.

**Uso:**
```bash
# Executar localmente
docker-compose -f docker-compose.local.yml up -d

# Parar
docker-compose -f docker-compose.local.yml down
```

### 3. `docker-compose.yml`
Configuração otimizada para deploy no Coolify.

## Processo de Deploy

### 1. Build e Push da Imagem

```bash
# Fazer login no Docker Hub
docker login

# Build e push da imagem
./build-and-push.sh

# Verificar se foi enviada
docker pull drnit29/geminicli2api:latest
```

### 2. Deploy Local para Testes

```bash
# Método 1: Usando script start.sh (Recomendado)
./start.sh

# Método 2: Usando docker-compose diretamente
# Configurar variáveis de ambiente
cp .env.example .env
# Editar .env com suas configurações

# Executar localmente
docker-compose -f docker-compose.local.yml up -d

# Verificar logs
docker-compose -f docker-compose.local.yml logs -f

# Testar API
curl -X POST "http://localhost:8888/v1/chat/completions" \
  -H "Authorization: Bearer sua_senha" \
  -H "Content-Type: application/json" \
  -d '{"model": "gemini-2.5-pro", "messages": [{"role": "user", "content": "Olá!"}]}'
```

#### Script start.sh

O script `start.sh` facilita o gerenciamento local:

```bash
# Iniciar serviços
./start.sh

# Ver logs
./start.sh logs

# Verificar status
./start.sh status

# Testar API
./start.sh test

# Parar serviços
./start.sh stop

# Reiniciar serviços
./start.sh restart

# Atualizar imagem
./start.sh pull

# Ver ajuda
./start.sh help
```

### 3. Deploy no Coolify

#### Configuração no Coolify:

1. **Criar Nova Aplicação**:
   - Tipo: Docker Compose
   - Repositório: Link para seu repositório Git
   - Branch: main

2. **Configurar Variáveis de Ambiente**:
   ```
   GEMINI_AUTH_PASSWORD=sua_senha_forte_aqui
   GEMINI_CREDENTIALS=suas_credenciais_google_json
   GOOGLE_CLOUD_PROJECT=seu_projeto_google
   FQDN=seudominio.com
   ```

3. **Configurar Domínio**:
   - Adicionar domínio personalizado
   - Coolify irá configurar SSL automaticamente

4. **Deploy**:
   - Coolify irá detectar o `docker-compose.yml`
   - Configurar rede e volumes automaticamente
   - Gerar certificados SSL

#### Recursos do Coolify:

- ✅ **SSL Automático**: Certificados Let's Encrypt
- ✅ **Reverse Proxy**: Traefik configurado automaticamente
- ✅ **Health Checks**: Monitoramento integrado
- ✅ **Logs**: Acesso via interface web
- ✅ **Rollback**: Reversão automática em caso de falha
- ✅ **Backups**: Configuração de backup automático

## Variáveis de Ambiente

### Obrigatórias:
- `GEMINI_AUTH_PASSWORD`: Senha para autenticação da API
- `GEMINI_CREDENTIALS`: Credenciais Google (JSON) ou arquivo de credenciais

### Opcionais:
- `GOOGLE_CLOUD_PROJECT`: ID do projeto Google Cloud
- `LOG_LEVEL`: Nível de log (DEBUG, INFO, WARNING, ERROR)
- `WORKERS`: Número de workers (padrão: 1)
- `FQDN`: Domínio completo (para Coolify)

## Monitoramento

### Health Checks:
- Endpoint: `http://localhost:8888/health`
- Intervalo: 30s
- Timeout: 10s
- Retries: 3

### Logs:
```bash
# Local
docker-compose -f docker-compose.local.yml logs -f

# Coolify
# Via interface web do Coolify
```

## Troubleshooting

### Problemas Comuns:

1. **Erro de Autenticação**:
   - Verificar se `GEMINI_AUTH_PASSWORD` está definida
   - Verificar credenciais Google

2. **Container não inicia**:
   - Verificar logs: `docker-compose logs geminicli2api`
   - Verificar health check: `curl http://localhost:8888/health`

3. **Coolify não consegue acessar**:
   - Verificar configuração de domínio
   - Verificar se a porta 8888 está exposta
   - Verificar labels do Traefik

### Comandos Úteis:

```bash
# Verificar imagem
docker images | grep geminicli2api

# Verificar containers
docker ps | grep geminicli2api

# Logs detalhados
docker logs geminicli2api-local

# Reiniciar serviço
docker-compose -f docker-compose.local.yml restart

# Remover tudo
docker-compose -f docker-compose.local.yml down --volumes
```

## Atualizações

### Para atualizar a aplicação:

1. **Fazer alterações no código**
2. **Build nova imagem**:
   ```bash
   ./build-and-push.sh v1.1.0
   ```

3. **Atualizar docker-compose.yml**:
   ```yaml
   image: drnit29/geminicli2api:v1.1.0
   ```

4. **Deploy no Coolify**:
   - Coolify detectará mudanças automaticamente
   - Ou trigger manual via interface

## Segurança

### Práticas implementadas:
- ✅ Usuário não-root no container
- ✅ Health checks configurados
- ✅ SSL/TLS via Coolify
- ✅ Variáveis de ambiente para secrets
- ✅ Recursos limitados
- ✅ Rede isolada

### Recomendações:
- Use senhas fortes para `GEMINI_AUTH_PASSWORD`
- Mantenha credenciais Google seguras
- Configure backup regular no Coolify
- Monitore logs regularmente
# Configuração do CodeBuild para Beanstalk

## Variáveis de Ambiente Necessárias

O CodeBuild precisa ter acesso às seguintes variáveis através do AWS Secrets Manager:

### Variáveis do Banco de Dados
- `DB_HOST` - Endpoint do banco de dados
- `DB_USER` - Usuário do banco
- `DB_PWD` - Senha do banco
- `DB_PORT` - Porta do banco (geralmente 3306 para MySQL)
- `DB_NAME` - Nome do banco de dados (opcional, padrão: bia_production)

### Configuração no CodeBuild

1. **Service Role**: O CodeBuild precisa ter permissões para:
   - ECR (push/pull de imagens)
   - Secrets Manager (leitura dos secrets)
   - Elastic Beanstalk (deploy)

2. **Environment Variables**: Configure no CodeBuild:
   ```
   Type: Parameter Store ou Secrets Manager
   Name: /bia/database/host -> DB_HOST
   Name: /bia/database/user -> DB_USER  
   Name: /bia/database/password -> DB_PWD
   Name: /bia/database/port -> DB_PORT
   Name: /bia/database/name -> DB_NAME
   ```

3. **IAM Policy para o Service Role**:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "secretsmanager:GetSecretValue",
           "secretsmanager:DescribeSecret"
         ],
         "Resource": "arn:aws:secretsmanager:us-east-1:397234361193:secret:bia/*"
       }
     ]
   }
   ```

## Fluxo da Pipeline

1. **Build Stage**: 
   - Constrói a imagem Docker
   - Faz push para ECR
   - Executa testes
   - Executa migrações do banco
   - Gera Dockerrun.aws.json com variáveis do Secrets Manager

2. **Deploy Stage**:
   - Usa o Dockerrun.aws.json gerado
   - Deploy no Elastic Beanstalk
   - Variáveis são injetadas no container

## Endpoints para Teste

Após o deploy, teste estes endpoints:

- `https://seu-beanstalk-url/health` - Health check
- `https://seu-beanstalk-url/debug` - Informações de debug
- `https://seu-beanstalk-url/api/ping` - Teste da API
- `https://seu-beanstalk-url/api/versao` - Versão da aplicação
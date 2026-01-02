#!/bin/bash

echo "🧪 Simulando pipeline localmente..."

# Simular variáveis de ambiente que viriam do Secrets Manager
export DB_HOST="localhost"
export DB_USER="test_user"
export DB_PWD="test_password"
export DB_PORT="3306"
export DB_NAME="bia_test"
export NODE_ENV="production"

# Simular variáveis do CodeBuild
export CODEBUILD_RESOLVED_SOURCE_VERSION="abc123def456"
export AWS_DEFAULT_REGION="us-east-1"

echo "📋 Variáveis de ambiente configuradas:"
echo "DB_HOST=$DB_HOST"
echo "DB_USER=$DB_USER"
echo "DB_PORT=$DB_PORT"
echo "DB_NAME=$DB_NAME"

# Simular o buildspec
REPOSITORY_URI="397234361193.dkr.ecr.us-east-1.amazonaws.com/repository-ci/cd"
COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
IMAGE_TAG=${COMMIT_HASH:=latest}

echo "🏷️  IMAGE_TAG: $IMAGE_TAG"

# Gerar Dockerrun.aws.json como na pipeline
echo "📝 Gerando Dockerrun.aws.json..."
cat > Dockerrun.aws.json << EOF
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "$REPOSITORY_URI:$IMAGE_TAG",
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": 8080,
      "HostPort": 80
    }
  ],
  "Environment": [
    {
      "Name": "NODE_ENV",
      "Value": "production"
    },
    {
      "Name": "PORT",
      "Value": "8080"
    },
    {
      "Name": "DB_HOST",
      "Value": "$DB_HOST"
    },
    {
      "Name": "DB_USER",
      "Value": "$DB_USER"
    },
    {
      "Name": "DB_PWD",
      "Value": "$DB_PWD"
    },
    {
      "Name": "DB_PORT",
      "Value": "$DB_PORT"
    },
    {
      "Name": "DB_NAME",
      "Value": "$DB_NAME"
    }
  ],
  "Logging": "/var/log/nginx"
}
EOF

echo "📄 Dockerrun.aws.json gerado:"
cat Dockerrun.aws.json

echo "✅ Simulação da pipeline concluída com sucesso!"
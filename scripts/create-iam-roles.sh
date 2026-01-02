#!/bin/bash

# Script para criar as roles IAM necessárias para os projetos CodeBuild

set -e

echo "=== CRIANDO ROLES IAM PARA CODEBUILD ==="

# Trust policy para CodeBuild
cat > /tmp/codebuild-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Policy para projeto de teste
cat > /tmp/codebuild-test-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::bia-artifacts/*"
    }
  ]
}
EOF

# Policy para projeto de build
cat > /tmp/codebuild-build-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::bia-artifacts/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:GetAuthorizationToken",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Policy para projeto de migração
cat > /tmp/codebuild-migrate-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::bia-artifacts/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:397234361193:secret:rds!db-f32b3e54-e56b-48a1-b5d0-8ab0fe23865d*"
    }
  ]
}
EOF

# Função para criar role
create_role() {
    local role_name=$1
    local policy_file=$2
    
    echo "Criando role: $role_name"
    
    # Criar role se não existir
    if ! aws iam get-role --role-name $role_name > /dev/null 2>&1; then
        aws iam create-role \
            --role-name $role_name \
            --assume-role-policy-document file:///tmp/codebuild-trust-policy.json \
            --path "/service-role/"
        echo "✅ Role $role_name criada"
    else
        echo "✅ Role $role_name já existe"
    fi
    
    # Criar policy inline
    aws iam put-role-policy \
        --role-name $role_name \
        --policy-name "${role_name}-policy" \
        --policy-document file://$policy_file
    
    echo "✅ Policy aplicada à role $role_name"
}

# Criar as roles
create_role "bia-test" "/tmp/codebuild-test-policy.json"
create_role "bia-build" "/tmp/codebuild-build-policy.json"
create_role "bia-migrate" "/tmp/codebuild-migrate-policy.json"

# Limpar arquivos temporários
rm -f /tmp/codebuild-*.json

echo "✅ Todas as roles IAM foram criadas com sucesso!"
echo ""
echo "Roles criadas:"
echo "- bia-test: Para execução de testes"
echo "- bia-build: Para build Docker e push para ECR"
echo "- bia-migrate: Para migrações de banco com acesso ao Secrets Manager"
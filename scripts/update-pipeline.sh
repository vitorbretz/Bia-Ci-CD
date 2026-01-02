#!/bin/bash

# Script para atualizar a pipeline CI/CD com a nova arquitetura
# Este script cria os projetos CodeBuild e atualiza a pipeline

set -e

echo "=== ATUALIZANDO PIPELINE CI/CD BIA ==="

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI não está configurado ou sem permissões"
    exit 1
fi

echo "✅ AWS CLI configurado"

# Verificar roles existentes
echo "=== VERIFICANDO ROLES IAM ==="
echo "Verificando roles existentes..."

EXISTING_ROLES=$(aws iam list-roles --path-prefix "/service-role/" --query 'Roles[?contains(RoleName, `bia`)].RoleName' --output text)
echo "Roles encontradas: $EXISTING_ROLES"

# Verificar se as roles necessárias existem
for role in "bia-test" "bia-build" "bia-migrate"; do
    if echo "$EXISTING_ROLES" | grep -q "$role"; then
        echo "✅ Role $role existe"
    else
        echo "❌ Role $role não encontrada"
        echo "Execute: aws iam create-role --role-name $role --assume-role-policy-document file://trust-policy.json --path '/service-role/'"
        exit 1
    fi
done

# Função para criar ou atualizar projeto CodeBuild
create_or_update_codebuild_project() {
    local config_file=$1
    local project_name=$(jq -r '.name' $config_file)
    
    echo "Verificando se projeto $project_name existe..."
    
    if aws codebuild batch-get-projects --names $project_name > /dev/null 2>&1; then
        echo "Atualizando projeto existente: $project_name"
        aws codebuild update-project --cli-input-json file://$config_file
    else
        echo "Criando novo projeto: $project_name"
        aws codebuild create-project --cli-input-json file://$config_file
    fi
    
    echo "✅ Projeto $project_name configurado"
}

# Criar/atualizar projetos CodeBuild
echo "=== CONFIGURANDO PROJETOS CODEBUILD ==="

create_or_update_codebuild_project "codebuild-test-config.json"
create_or_update_codebuild_project "codebuild-build-config.json" 
create_or_update_codebuild_project "codebuild-config.json"  # bia-migrate

# Atualizar pipeline
echo "=== ATUALIZANDO PIPELINE ==="
echo "Atualizando pipeline bia-hom..."

aws codepipeline update-pipeline --cli-input-json file://pipeline-updated.json

echo "✅ Pipeline atualizada com sucesso!"

echo "=== RESUMO DAS ALTERAÇÕES ==="
echo "✅ Projeto bia-test criado/atualizado (buildspec-test.yml)"
echo "✅ Projeto bia-build criado/atualizado (buildspec-build.yml)"
echo "✅ Projeto bia-migrate atualizado (buildspec-migrate.yml)"
echo "✅ Pipeline bia-hom atualizada com 5 etapas:"
echo "   1. Source (GitHub)"
echo "   2. Test (bia-test)"
echo "   3. Build (bia-build)"
echo "   4. Migration (bia-migrate)"
echo "   5. Deploy (Elastic Beanstalk)"

echo ""
echo "🎉 PIPELINE CORRIGIDA COM SUCESSO!"
echo ""
echo "A pipeline agora tem separação adequada de responsabilidades:"
echo "- Testes executam primeiro e param a pipeline se falharem"
echo "- Build Docker só executa se testes passarem"
echo "- Migrações só executam se build for bem-sucedido"
echo "- Deploy só acontece se todas as etapas anteriores passarem"
echo ""
echo "Para testar, faça um commit na branch pr-ci/cd"
# Design Document

## Overview

Esta solução redesenha a pipeline CI/CD da aplicação Bia para implementar uma arquitetura adequada com separação de responsabilidades. A nova arquitetura terá 4 etapas distintas: Source, Test, Build, Migration e Deploy, cada uma com seu próprio projeto CodeBuild e buildspec otimizado.

## Architecture

### Current State Problems
- Pipeline com apenas 1 ação de Build sobrecarregada
- Buildspec principal executando testes, build, migrações e deploy em uma única etapa
- Falhas mascaradas por comandos com `|| echo`
- Falta de isolamento entre responsabilidades

### Target Architecture
```
Source → Test → Build → Migration → Deploy
   ↓       ↓       ↓        ↓         ↓
GitHub  Jest/   Docker   Sequelize  Elastic
        Vite    Build    Migrate    Beanstalk
```

### Pipeline Stages
1. **Source**: Código do GitHub via CodeStar Connection
2. **Test**: Execução de testes unitários e build do frontend
3. **Build**: Criação e push da imagem Docker para ECR
4. **Migration**: Execução de migrações do banco de dados
5. **Deploy**: Deploy para Elastic Beanstalk

## Components and Interfaces

### CodeBuild Projects
1. **bia-test**: Projeto dedicado para execução de testes
2. **bia-build**: Projeto dedicado para build da imagem Docker
3. **bia-migrate**: Projeto dedicado para migrações de banco

### Buildspec Files
1. **buildspec-test.yml**: Configuração otimizada para testes
2. **buildspec-build.yml**: Configuração otimizada para build Docker
3. **buildspec-migrate.yml**: Configuração otimizada para migrações

### Environment Variables
- Variáveis de banco de dados via Secrets Manager
- Configurações específicas por ambiente (dev/prod)
- Credenciais ECR para push de imagens

## Data Models

### Pipeline Configuration
```json
{
  "stages": [
    {
      "name": "Source",
      "actions": ["GitHub Source"]
    },
    {
      "name": "Test", 
      "actions": ["Unit Tests", "Frontend Build"]
    },
    {
      "name": "Build",
      "actions": ["Docker Build & Push"]
    },
    {
      "name": "Migration",
      "actions": ["Database Migration"]
    },
    {
      "name": "Deploy",
      "actions": ["Beanstalk Deploy"]
    }
  ]
}
```

### Artifact Flow
- **SourceArtifact**: Código fonte do GitHub
- **TestArtifact**: Resultados dos testes e build do frontend
- **BuildArtifact**: Definições de imagem Docker (imagedefinitions.json, Dockerrun.aws.json)
- **MigrationArtifact**: Logs de migração e status

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*
Property 1:
 Pipeline stage execution order
*For any* pipeline execution, the Test stage should always execute before the Build stage, and Build should execute before Migration
**Validates: Requirements 1.1, 5.2**

Property 2: Test failure stops pipeline
*For any* test execution that fails, the pipeline should stop and not proceed to Build or subsequent stages
**Validates: Requirements 1.2, 5.3**

Property 3: Build success triggers migration
*For any* successful Build stage completion, the Migration stage should be triggered automatically
**Validates: Requirements 1.4**

Property 4: Migration failure stops pipeline
*For any* migration execution that fails, the pipeline should stop and not proceed to Deploy stage
**Validates: Requirements 1.5, 4.4, 5.3**

Property 5: Buildspec error handling
*For any* buildspec execution that encounters an error, the system should provide clear error messages and stop execution
**Validates: Requirements 2.4**

Property 6: Resource allocation consistency
*For any* buildspec execution, appropriate timeouts and compute resources should be allocated based on the stage requirements
**Validates: Requirements 2.5**

Property 7: Test report generation
*For any* test execution that completes, test reports and coverage information should be generated and preserved
**Validates: Requirements 3.3**

Property 8: Test failure log preservation
*For any* test execution that fails, detailed logs should be preserved for debugging purposes
**Validates: Requirements 3.5**

Property 9: Artifact flow integrity
*For any* pipeline execution, artifacts should be correctly passed between stages without corruption or loss
**Validates: Requirements 5.4**

Property 10: Deployment safety
*For any* pipeline execution, deployment should only occur if all previous stages (Source, Test, Build, Migration) have succeeded
**Validates: Requirements 5.5**

## Error Handling

### Test Stage Failures
- Jest test failures stop pipeline execution
- Vite build failures prevent Docker image creation
- Clear error messages with test output preserved

### Build Stage Failures
- Docker build failures prevent image push to ECR
- ECR authentication failures stop pipeline
- Build logs preserved for debugging

### Migration Stage Failures
- Database connectivity issues prevent migration execution
- Sequelize migration failures stop pipeline before deploy
- Database rollback procedures documented

### Pipeline-Level Error Handling
- Each stage validates prerequisites before execution
- Failed stages prevent subsequent stage execution
- Comprehensive logging and monitoring

## Testing Strategy

### Unit Testing Approach
- Test individual buildspec configurations
- Validate environment variable configurations
- Test artifact generation and consumption
- Verify error handling scenarios

### Property-Based Testing Approach
- Use AWS CLI and CloudFormation for infrastructure testing
- Property-based tests will use the AWS SDK to verify pipeline configurations
- Each correctness property will be implemented as an automated test
- Tests will run a minimum of 100 iterations to verify consistency
- Property-based testing library: AWS SDK with custom test framework

### Integration Testing
- End-to-end pipeline execution tests
- Cross-stage artifact validation
- Database migration rollback testing
- Multi-environment deployment validation

### Testing Requirements
- Each property-based test must be tagged with: **Feature: pipeline-ci-cd-fix, Property {number}: {property_text}**
- Each correctness property must be implemented by a single property-based test
- Tests must validate real AWS infrastructure, not mocked services
- Test execution must be isolated and repeatable
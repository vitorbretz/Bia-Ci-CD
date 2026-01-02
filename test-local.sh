#!/bin/bash

echo "🚀 Testando aplicação localmente..."

# Build da aplicação
echo "📦 Fazendo build do cliente..."
cd client && npm run build
cd ..

# Verificar se o build foi criado
if [ ! -d "client/build" ]; then
    echo "❌ Erro: Diretório client/build não foi criado"
    exit 1
fi

if [ ! -f "client/build/index.html" ]; then
    echo "❌ Erro: index.html não encontrado no build"
    exit 1
fi

echo "✅ Build do cliente criado com sucesso"

# Iniciar servidor
echo "🌐 Iniciando servidor..."
npm start &
SERVER_PID=$!

# Aguardar servidor iniciar
sleep 5

# Testar endpoints
echo "🔍 Testando endpoints..."

echo "Testing /health..."
curl -f http://localhost:8080/health || echo "❌ Health check falhou"

echo "Testing /api/ping..."
curl -f http://localhost:8080/api/ping || echo "❌ Ping falhou"

echo "Testing /debug..."
curl -f http://localhost:8080/debug || echo "❌ Debug falhou"

echo "Testing root..."
curl -f http://localhost:8080/ || echo "❌ Root falhou"

# Parar servidor
kill $SERVER_PID

echo "✅ Testes concluídos"
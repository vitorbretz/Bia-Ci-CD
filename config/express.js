const express = require("express");
var cors = require("cors");
var path = require("path");
const config = require("config");
var bodyParser = require("body-parser");

module.exports = () => {
  const app = express();

  // SETANDO VARIÁVEIS DA APLICAÇÃO
  app.set("port", process.env.PORT || config.get("server.port"));

  //Setando react
  app.use(express.static(path.join(__dirname, "../", "client", "build")));

  // parse request bodies (req.body)
  app.use(express.urlencoded({ extended: true }));
  app.use(bodyParser.json());

  app.use(cors());

  require("../api/routes/tarefas")(app);
  require("../api/routes/versao")(app);
  require("../api/routes/ping")(app);

  // Health check route
  app.get('/health', (req, res) => {
    res.status(200).json({ 
      status: 'OK', 
      timestamp: new Date().toISOString(),
      version: require('../package.json').version 
    });
  });

  // Debug route to check static files
  app.get('/debug', (req, res) => {
    const fs = require('fs');
    const buildPath = path.join(__dirname, "../", "client", "build");
    const buildExists = fs.existsSync(buildPath);
    const buildContents = buildExists ? fs.readdirSync(buildPath) : [];
    
    res.json({
      buildPath,
      buildExists,
      buildContents,
      port: app.get("port"),
      env: process.env.NODE_ENV || 'development'
    });
  });

  // Fallback para React Router - serve index.html para todas as rotas não-API
  app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, "../", "client", "build", "index.html"));
  });

  return app;
};

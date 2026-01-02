// Para sequelize-cli, precisamos de uma configuração síncrona
const config = {
  development: {
    username: process.env.DB_USER || "postgres",
    password: process.env.DB_PWD || "postgres", 
    database: process.env.DB_NAME || "bia",
    host: process.env.DB_HOST || "127.0.0.1",
    port: process.env.DB_PORT || 5433,
    dialect: "postgres",
    dialectOptions: {
      ssl: {
        require: true,
        rejectUnauthorized: false
      }
    }
  },
  test: {
    username: process.env.DB_USER || "postgres",
    password: process.env.DB_PWD || "postgres",
    database: process.env.DB_NAME || "bia_test", 
    host: process.env.DB_HOST || "127.0.0.1",
    port: process.env.DB_PORT || 5433,
    dialect: "postgres"
  },
  production: {
    username: process.env.DB_USER || "postgres",
    password: process.env.DB_PWD || "postgres",
    database: process.env.DB_NAME || "bia",
    host: process.env.DB_HOST || "127.0.0.1", 
    port: process.env.DB_PORT || 5432,
    dialect: "postgres",
    dialectOptions: {
      ssl: {
        require: true,
        rejectUnauthorized: false
      }
    }
  }
};

module.exports = config;


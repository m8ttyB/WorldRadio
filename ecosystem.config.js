module.exports = {
  apps: [
    {
      name: 'global-radio-backend',
      script: 'uvicorn',
      args: 'server:app --host 0.0.0.0 --port 8001',
      cwd: './backend',
      instances: 1,
      exec_mode: 'fork',
      watch: false,
      env: {
        NODE_ENV: 'production',
        MONGO_URL: 'mongodb://localhost:27017',
        DB_NAME: 'global_radio_prod'
      },
      error_file: './logs/backend-err.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend-combined.log',
      time: true
    }
  ]
};
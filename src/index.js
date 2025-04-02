const express = require('express');
const path = require('path');
const config = require('config');
const bodyParser = require('body-parser');
const basicAuth = require('express-basic-auth');
const logger = require('./utils/logger');
const { router: streamController } = require('./controllers/streamController');

// Initialize Express app
const app = express();
const port = config.get('dashboardSettings.port') || 3000;

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, '../public')));

// Basic authentication
app.use(basicAuth({
  users: { 
    [config.get('dashboardSettings.username')]: config.get('dashboardSettings.password') 
  },
  challenge: true
}));

// Routes
app.use('/api/stream', streamController);

// Start server
app.listen(port, () => {
  logger.info(`Dashboard server started on port ${port}`);
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  logger.info('Shutting down gracefully...');
  process.exit(0);
});

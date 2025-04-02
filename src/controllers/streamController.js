const express = require('express');
const router = express.Router();
const { exec } = require('child_process');
const config = require('config');
const logger = require('../utils/logger');

// Function to start the stream
const startStream = (stationId = config.get('defaultStationId')) => {
  // Normalize URL by removing trailing slashes and ensuring stationId is properly appended
  const baseUrl = config.get('streamBaseUrl').replace(/\/+$/, '');
  const streamUrl = `${baseUrl}/${stationId}`.replace(/\/\//g, '/');
  
  // Set reasonable timeout for connection attempts
  const timeoutSec = config.has('networkSettings.streamTimeout') ? 
    config.get('networkSettings.streamTimeout') : 15;
  
  return new Promise((resolve, reject) => {
    // First kill any existing mpv processes to avoid conflicts
    exec('pkill mpv', () => {
      // Start mpv with timeout and capture error output
      exec(`timeout ${timeoutSec}s mpv --no-video --msg-level=all=error ${streamUrl} 2>&1`, 
        (error, stdout, stderr) => {
          if (error) {
            // Check for specific error types
            if (error.code === 124) {
              logger.error(`Stream connection timed out after ${timeoutSec}s: ${streamUrl}`);
              return reject(new Error('Connection timeout'));
            }
            
            const output = stdout || stderr;
            // Log detailed error for better debugging
            logger.error(`Error starting stream: ${error.message}`);
            logger.error(`Stream output: ${output}`);
            
            // Provide more specific error messages based on output
            if (output.includes('404')) {
              return reject(new Error('Stream not found (404)'));
            } else if (output.includes('403')) {
              return reject(new Error('Access denied (403)'));
            } else if (output.includes('Failed to resolve')) {
              return reject(new Error('Failed to resolve hostname'));
            }
            
            return reject(error);
          }
          
          logger.info(`Stream started: ${streamUrl}`);
          resolve({ success: true, message: 'Stream started' });
        }
      );
    });
  });
};

// Get stream status
router.get('/status', (req, res) => {
  exec('pgrep mpv', (error, stdout, stderr) => {
    const isPlaying = stdout ? true : false;
    res.json({ playing: isPlaying });
  });
});

// Start stream
router.post('/start', (req, res) => {
  const stationId = req.body.stationId || config.get('defaultStationId');
  
  startStream(stationId)
    .then(result => res.json(result))
    .catch(error => res.status(500).json({ 
      error: 'Failed to start stream', 
      message: error.message,
      details: error.toString()
    }));
});

// Stop stream
router.post('/stop', (req, res) => {
  exec('pkill mpv', (error, stdout, stderr) => {
    if (error && error.code !== 1) {
      logger.error(`Error stopping stream: ${error.message}`);
      return res.status(500).json({ error: 'Failed to stop stream' });
    }
    
    logger.info('Stream stopped');
    res.json({ success: true, message: 'Stream stopped' });
  });
});

// Set volume
router.post('/volume', (req, res) => {
  const volume = req.body.volume;
  if (typeof volume !== 'number' || volume < 0 || volume > 100) {
    return res.status(400).json({ error: 'Volume must be a number between 0 and 100' });
  }
  
  exec(`amixer sset Master ${volume}%`, (error, stdout, stderr) => {
    if (error) {
      logger.error(`Error setting volume: ${error.message}`);
      return res.status(500).json({ error: 'Failed to set volume' });
    }
    
    logger.info(`Volume set to ${volume}%`);
    res.json({ success: true, message: `Volume set to ${volume}%` });
  });
});

// Auto-start stream on boot with retry logic
const autoStartEnabled = config.has('autoStart') ? config.get('autoStart') : true;

if (autoStartEnabled) {
  // Check if already playing
  exec('pgrep mpv', (error, stdout, stderr) => {
    const isPlaying = stdout ? true : false;
    
    if (!isPlaying) {
      logger.info('Auto-starting stream on boot');
      
      // Get retry settings from config
      const maxRetries = config.has('networkSettings.maxRetries') ? 
        config.get('networkSettings.maxRetries') : 5;
      const retryInterval = config.has('networkSettings.retryInterval') ? 
        config.get('networkSettings.retryInterval') : 10000;
      
      // Define recursive retry function
      const attemptStart = (retriesLeft) => {
        startStream()
          .then(() => {
            logger.info('Auto-start successful');
          })
          .catch(err => {
            logger.error(`Auto-start failed: ${err.message}`);
            
            if (retriesLeft > 0) {
              logger.info(`Retrying in ${retryInterval/1000} seconds... (${retriesLeft} attempts remaining)`);
              setTimeout(() => attemptStart(retriesLeft - 1), retryInterval);
            } else {
              logger.error('Auto-start failed after all retry attempts');
            }
          });
      };
      
      // Start the retry process
      attemptStart(maxRetries);
    } else {
      logger.info('Stream already playing, skipping auto-start');
    }
  });
}

module.exports = { router, startStream };

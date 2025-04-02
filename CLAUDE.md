# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Run Commands
- Start server: `node src/index.js`
- Run in development mode: `NODE_ENV=development node src/index.js`
- No tests implemented yet

## Code Style Guidelines
- **Imports**: CommonJS requires (not ES modules)
- **Error Handling**: Use try/catch blocks for async operations, log errors with Winston logger
- **Logging**: Use the custom logger from utils/logger.js
- **Naming**: camelCase for variables/functions, PascalCase for classes
- **Shell Commands**: Use child_process.exec for system commands
- **Authentication**: Express-basic-auth for dashboard access
- **Config**: Use config package with JSON files in config/ directory
- **Frontend**: Vanilla JavaScript with fetch API for backend communication
- **API Structure**: RESTful API endpoints under /api/stream/

## Project Structure
- Configuration in /config
- Frontend in /public
- Backend in /src
- Logs in /logs (gitignored)
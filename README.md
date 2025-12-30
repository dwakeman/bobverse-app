# Bobverse - Agentic Lab Demo Application

A full-stack application demonstrating Bob AI capabilities with a FastAPI backend and React frontend.

## 🎯 Quick Start

Clone the repository and run these three commands:

```bash
make setup      # Install dependencies and configure environment
make init-db    # Initialize database with seed data
make start      # Start both backend and frontend
```

Then open your browser to:
- **Frontend**: http://localhost:30402
- **Backend API**: http://localhost:8000

## 📋 Requirements

### Python
- **Supported versions**: Python 3.10, 3.11, 3.12, or 3.13
- **Recommended**: Python 3.12 (as specified in `.python-version`)

The setup script will:
1. Try to use the Python version from `.python-version` (3.12)
2. Fall back to `python3` if the specific version isn't available
3. Verify the version is within the supported range (3.10-3.13)

### Node.js
- Node.js 14+ and npm

### System Dependencies
- `make` (usually pre-installed on macOS/Linux)
- `bc` calculator (for version comparison, usually pre-installed)

## 🚀 Setup Instructions

### 1. Install Python (if needed)

**macOS (using Homebrew):**
```bash
brew install python@3.12
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install python3.12 python3.12-venv
```

**Windows:**
Download from [python.org](https://www.python.org/downloads/)

### 2. Install Node.js (if needed)

**macOS:**
```bash
brew install node
```

**Ubuntu/Debian:**
```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Windows:**
Download from [nodejs.org](https://nodejs.org/)

### 3. Run Setup

```bash
make setup
```

This command will:
- Create a Python virtual environment (`.ve`)
- Install all Python dependencies
- Create environment configuration files (`.env`, `.env.dev`, `frontend/.env.development`)
- Install frontend npm dependencies

### 4. Initialize Database

```bash
make init-db
```

This creates a SQLite database with:
- 2 test users (AskBob and demo)
- 18 sample articles
- Tags and metadata

### 5. Start the Application

```bash
make start
```

This starts both services:
- **Backend**: http://localhost:8000 (FastAPI with Swagger docs)
- **Frontend**: http://localhost:30402 (React application)

## 🧪 Test Credentials

- **Email**: `demo@example.com`
- **Email**: `AskBob@example.com`

## 📚 Available Make Commands

```bash
make setup          # Initial setup (install dependencies, create config files)
make init-db        # Initialize/reset database with seed data
make start          # Start both backend and frontend
make backend        # Start backend only
make frontend       # Start frontend only
make test-backend   # Run backend tests
make clean          # Remove database and cache files
```

## 🏗️ Project Structure

```
.
├── bobverse/              # Backend Python application
│   ├── api/              # API routes and schemas
│   ├── core/             # Core configuration and utilities
│   ├── domain/           # Business logic and services
│   └── infrastructure/   # Database models and repositories
├── frontend/             # React frontend application
│   ├── src/
│   │   ├── app/         # Application setup
│   │   ├── pages/       # Page components
│   │   ├── features/    # Feature modules
│   │   ├── entities/    # Domain entities
│   │   └── shared/      # Shared utilities
│   └── public/          # Static assets
├── articles/            # Markdown articles for seeding
├── tests/              # Backend tests
└── Makefile           # Build and run commands
```

## 🔧 Configuration

### Environment Variables

The setup creates these configuration files:

**`.env` and `.env.dev`** (Backend):
```env
APP_ENV=dev
JWT_SECRET_KEY=dev-jwt-secret-key-change-in-production
SECRET_KEY=dev-secret-key-change-in-production
```

**`frontend/.env.development`** (Frontend):
```env
PORT=30402
API_URL=http://localhost:8000/api
```

### Python Version

The project uses the version specified in `.python-version` (3.12.0) but supports Python 3.10-3.13.

To use a different Python version:
1. Update `.python-version` file
2. Ensure the version is between 3.10 and 3.13
3. Run `make setup` again

## 🐛 Troubleshooting

### Python Version Issues

If you see errors about Python version compatibility:

```bash
# Check your Python version
python3 --version

# If it's not 3.10-3.13, install a supported version
# macOS:
brew install python@3.12

# Then re-run setup
rm -rf .ve
make setup
```

### Port Already in Use

If ports 8000 or 30402 are already in use:

```bash
# Find and kill the process using the port
lsof -ti:8000 | xargs kill -9
lsof -ti:30402 | xargs kill -9

# Then restart
make start
```

### Database Issues

To reset the database:

```bash
make clean
make init-db
```

## 🧪 Running Tests

```bash
# Backend tests
make test-backend

# Frontend tests (from frontend directory)
cd frontend
npm test
```

## 📖 API Documentation

Once the backend is running, visit:
- **Swagger UI**: http://localhost:8000
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

## 🤝 Contributing

This is a demo application for showcasing Bob AI capabilities. Feel free to explore and modify!

## 📝 License

See LICENSE file for details.

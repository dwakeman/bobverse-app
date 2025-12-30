# Environment setup
setup:
	@echo "Setting up Python virtual environment..."
	@if [ -f .python-version ]; then \
		PYTHON_VERSION=$$(cat .python-version | cut -d. -f1,2); \
		if command -v python$$PYTHON_VERSION >/dev/null 2>&1; then \
			echo "Using python$$PYTHON_VERSION from .python-version"; \
			python$$PYTHON_VERSION -m venv .ve; \
		elif command -v python3 >/dev/null 2>&1; then \
			INSTALLED_VERSION=$$(python3 --version 2>&1 | awk '{print $$2}' | cut -d. -f1,2); \
			echo "python$$PYTHON_VERSION not found, using python3 (version $$INSTALLED_VERSION)"; \
			if [ "$$(echo "$$INSTALLED_VERSION >= 3.10" | bc -l)" -eq 1 ] && [ "$$(echo "$$INSTALLED_VERSION <= 3.13" | bc -l)" -eq 1 ]; then \
				python3 -m venv .ve; \
			else \
				echo "Error: Python version $$INSTALLED_VERSION is not supported. Please install Python 3.10-3.13"; \
				exit 1; \
			fi; \
		else \
			echo "Error: Python 3 not found. Please install Python 3.10-3.13"; \
			exit 1; \
		fi; \
	else \
		echo "No .python-version file found, using python3"; \
		python3 -m venv .ve; \
	fi
	@echo "Installing Python dependencies..."
	. .ve/bin/activate && pip install -r requirements.txt
	@if [ ! -f .env ]; then \
		if [ -f .env.example ]; then \
			echo "Creating .env from .env.example..."; \
			cp .env.example .env; \
		else \
			echo "Creating .env file..."; \
			echo "APP_ENV=dev" > .env; \
			echo "JWT_SECRET_KEY=dev-jwt-secret-key-change-in-production" >> .env; \
			echo "SECRET_KEY=dev-secret-key-change-in-production" >> .env; \
		fi; \
	else \
		echo ".env file already exists, skipping..."; \
	fi
	@if [ ! -f .env.dev ]; then \
		echo "Creating .env.dev file..."; \
		cp .env .env.dev; \
	fi
	@if [ ! -f frontend/.env.development ]; then \
		echo "Creating frontend/.env.development file..."; \
		echo "PORT=30402" > frontend/.env.development; \
		echo "API_URL=http://localhost:8000/api" >> frontend/.env.development; \
	fi
	@echo "Installing frontend dependencies..."
	cd frontend && npm install
	@echo ""
	@echo "✅ Setup complete! Next steps:"
	@echo "   1. Run 'make init-db' to initialize the database"
	@echo "   2. Run 'make start' to start the application"
	

# Database initialization
init-db:
	. .ve/bin/activate && [ ! -f bobverse.db ] || mv -f bobverse.db bobverse.db.bak && python3 init_sqlite_db.py --auto-login

# Run backend tests
test-backend:
	. .ve/bin/activate && export APP_ENV=test && \
	export JWT_SECRET_KEY=test-jwt-secret-key && \
	export SECRET_KEY=test-secret-key && \
	python -m pytest -v ./tests

# Run backend only
backend:
	. .ve/bin/activate && uvicorn bobverse.app:app --host 0.0.0.0 --port 8000 --reload

# Run frontend only
frontend:
	PORT=30402 && cd frontend && npm start

# Run both backend and frontend
start:
	@echo "Starting backend and frontend..."
	@trap 'kill 0' INT; \
	. .ve/bin/activate && uvicorn bobverse.app:app --host 0.0.0.0 --port 8000 --reload & \
	PORT=30402 && cd frontend && npm start & \
	wait

# Clean the project (remove database and other generated files)
clean:
	@echo "Cleaning project..."
	rm -f bobverse.db
	rm -f test_bobverse.db
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type d -name .pytest_cache -exec rm -rf {} +

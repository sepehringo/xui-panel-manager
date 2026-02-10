# Makefile for XUI Panel Manager

.PHONY: help install run test clean dev deploy backup restore uninstall

# Default target
help:
	@echo "XUI Panel Manager - Available Commands"
	@echo "======================================"
	@echo "  make install       - Install XUI Panel Manager"
	@echo "  make run           - Run web panel"
	@echo "  make dev           - Run in development mode"
	@echo "  make test          - Run tests"
	@echo "  make clean         - Clean temporary files"
	@echo "  make deploy        - Deploy to production"
	@echo "  make backup        - Backup configuration"
	@echo "  make restore       - Restore configuration"
	@echo "  make uninstall     - Remove XUI Panel Manager"
	@echo "  make status        - Check service status"
	@echo "  make logs          - View logs"
	@echo "  make restart       - Restart services"
	@echo "  make sync          - Run manual sync"

# Installation
install:
	@echo "Installing XUI Panel Manager..."
	@chmod +x xui-panel-manager-installer.sh
	@sudo ./xui-panel-manager-installer.sh

# Run web panel
run:
	@echo "Starting web panel..."
	@python3 web_app.py

# Development mode
dev:
	@echo "Starting in development mode..."
	@FLASK_APP=web_app.py FLASK_ENV=development FLASK_DEBUG=1 python3 web_app.py

# Run tests
test:
	@echo "Running tests..."
	@pytest tests/ -v --cov=web_app

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -delete
	@find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	@rm -rf .pytest_cache/
	@rm -rf htmlcov/
	@rm -rf dist/
	@rm -rf build/
	@echo "Clean complete"

# Deploy to production
deploy:
	@echo "Deploying to production..."
	@sudo systemctl stop xui-panel-manager-web || true
	@sudo systemctl stop xui-panel-manager-sync.timer || true
	@sudo cp web_app.py /opt/xui-panel-manager/
	@sudo cp -r templates/* /opt/xui-panel-manager/templates/
	@sudo systemctl start xui-panel-manager-web
	@sudo systemctl start xui-panel-manager-sync.timer
	@echo "Deployment complete"

# Backup configuration
backup:
	@echo "Creating backup..."
	@mkdir -p backups
	@sudo tar -czf backups/xui-panel-manager-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz \
		/etc/xui-panel-manager \
		/var/lib/xui-panel-manager
	@echo "Backup created in backups/"

# Restore configuration
restore:
	@echo "Restoring from backup..."
	@echo "Available backups:"
	@ls -lh backups/*.tar.gz
	@echo "To restore, run: sudo tar -xzf backups/BACKUP_FILE.tar.gz -C /"

# Uninstall
uninstall:
	@echo "Uninstalling XUI Panel Manager..."
	@sudo systemctl stop xui-panel-manager-web || true
	@sudo systemctl stop xui-panel-manager-sync.timer || true
	@sudo systemctl disable xui-panel-manager-web || true
	@sudo systemctl disable xui-panel-manager-sync.timer || true
	@sudo rm -f /etc/systemd/system/xui-panel-manager-*
	@sudo systemctl daemon-reload
	@sudo rm -rf /opt/xui-panel-manager
	@sudo rm -rf /var/lib/xui-panel-manager
	@sudo rm -f /usr/local/bin/xui-panel-manager
	@echo "Note: Config files in /etc/xui-panel-manager NOT removed"
	@echo "To remove config: sudo rm -rf /etc/xui-panel-manager"

# Service status
status:
	@echo "=== Web Service Status ==="
	@sudo systemctl status xui-panel-manager-web --no-pager || true
	@echo ""
	@echo "=== Sync Timer Status ==="
	@sudo systemctl status xui-panel-manager-sync.timer --no-pager || true
	@echo ""
	@echo "=== Next Sync ==="
	@systemctl list-timers | grep xui || true

# View logs
logs:
	@echo "=== Application Logs ==="
	@sudo tail -n 50 /var/log/xui-panel-manager.log
	@echo ""
	@echo "=== Systemd Logs ==="
	@sudo journalctl -u xui-panel-manager-web -n 20 --no-pager

# Restart services
restart:
	@echo "Restarting services..."
	@sudo systemctl restart xui-panel-manager-web
	@sudo systemctl restart xui-panel-manager-sync.timer
	@echo "Services restarted"

# Manual sync
sync:
	@echo "Running manual sync..."
	@sudo python3 /opt/xui-panel-manager/sync.py

# Development setup
dev-setup:
	@echo "Setting up development environment..."
	@python3 -m venv venv
	@. venv/bin/activate && pip install -r requirements.txt
	@. venv/bin/activate && pip install pytest pytest-cov flake8 black mypy
	@echo "Development environment ready"
	@echo "Activate with: source venv/bin/activate"

# Code quality checks
lint:
	@echo "Running linter..."
	@flake8 web_app.py --max-line-length=100

format:
	@echo "Formatting code..."
	@black web_app.py

typecheck:
	@echo "Type checking..."
	@mypy web_app.py

# Build release
build:
	@echo "Building release package..."
	@mkdir -p release
	@tar -czf release/xui-panel-manager-$(shell date +%Y%m%d).tar.gz \
		xui-panel-manager-installer.sh \
		web_app.py \
		requirements.txt \
		templates/ \
		docs/ \
		README.md \
		LICENSE \
		CHANGELOG.md
	@echo "Release package created in release/"

# Quick commands
up: restart
down: 
	@sudo systemctl stop xui-panel-manager-web
	@sudo systemctl stop xui-panel-manager-sync.timer

ps:
	@ps aux | grep -E "web_app|sync.py" | grep -v grep

# Database operations
db-backup:
	@echo "Backing up local database..."
	@sudo cp /etc/x-ui/x-ui.db /var/lib/xui-panel-manager/backups/x-ui-manual-backup-$(shell date +%Y%m%d-%H%M%S).db

db-restore:
	@echo "Available database backups:"
	@ls -lh /var/lib/xui-panel-manager/backups/*.db

# SSH key management
ssh-key:
	@echo "=== SSH Public Key ==="
	@sudo cat /etc/xui-panel-manager/id_ed25519.pub
	@echo ""
	@echo "Copy this key to remote servers:"
	@echo "ssh root@REMOTE_SERVER"
	@echo "echo 'KEY_HERE' >> ~/.ssh/authorized_keys"

# Quick access to web panel
open:
	@echo "Opening web panel..."
	@xdg-open http://localhost:8080 2>/dev/null || open http://localhost:8080 2>/dev/null || echo "Visit: http://localhost:8080"

# Version info
version:
	@echo "XUI Panel Manager v1.0.0"
	@echo "Python: $(shell python3 --version)"
	@echo "Flask: $(shell pip show flask 2>/dev/null | grep Version)"

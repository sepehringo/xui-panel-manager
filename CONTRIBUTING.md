# Contributing to XUI Panel Manager

First off, thank you for considering contributing to XUI Panel Manager! 🎉

Following these guidelines helps to communicate that you respect the time of the developers managing and developing this open source project. In return, they should reciprocate that respect in addressing your issue, assessing changes, and helping you finalize your pull requests.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [What We're Looking For](#what-were-looking-for)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Community](#community)

---

## Code of Conduct

This project and everyone participating in it is governed by basic principles:

- **Be Respectful**: Treat everyone with respect and kindness
- **Be Collaborative**: Work together towards common goals
- **Be Professional**: Keep discussions focused and constructive
- **Be Inclusive**: Welcome diverse perspectives and backgrounds

---

## What We're Looking For

XUI Panel Manager welcomes contributions in many forms:

### 🐛 Bug Reports
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- System information (OS, Python version, etc.)
- Relevant logs or screenshots

### ✨ Feature Requests
- Clear use case and motivation
- Detailed description of proposed feature
- Mockups or examples (if applicable)
- Willingness to help implement

### 🔧 Code Contributions
- Bug fixes
- New features
- Performance improvements
- Code refactoring
- Test coverage improvements

### 📚 Documentation
- Fixing typos or unclear sections
- Adding examples
- Translating documentation
- Creating tutorials or guides

### 🌍 Translations
- Adding new language support
- Improving existing translations
- Localizing documentation

---

## How to Contribute

### Reporting Bugs

Before creating a bug report:
1. **Check existing issues** to avoid duplicates
2. **Test with latest version** to ensure bug still exists
3. **Gather debug information** (logs, config, etc.)

When creating a bug report, include:
- **Clear title** describing the issue
- **Detailed description** of the problem
- **Steps to reproduce**:
  1. Go to '...'
  2. Click on '...'
  3. See error
- **Expected behavior**
- **Actual behavior**
- **Screenshots** (if applicable)
- **Environment details**:
  - OS: Ubuntu 22.04
  - Python: 3.10.0
  - XUI Panel Manager: v1.0.0
  - Browser: Chrome 120.0
- **Logs**:
  ```
  [paste relevant logs here]
  ```

### Suggesting Enhancements

Before creating an enhancement suggestion:
1. **Check if it already exists** in issues or roadmap
2. **Consider if it fits project scope**
3. **Think about implementation complexity**

When suggesting enhancements, include:
- **Clear title** and description
- **Problem statement**: What problem does this solve?
- **Proposed solution**: How should it work?
- **Alternatives considered**: Other approaches you thought about
- **Additional context**: Mockups, examples, related features

---

## Development Setup

### Prerequisites

- Ubuntu 20.04+ (or similar Linux distribution)
- Python 3.8+
- Git
- Text editor or IDE (VS Code, PyCharm, etc.)

### Fork and Clone

```bash
# Fork on GitHub first, then:
git clone https://github.com/sepehringo/xui-panel-manager.git
cd xui-panel-manager

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/xui-panel-manager.git
```

### Install Dependencies

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Install development dependencies (if you create this file)
pip install -r requirements-dev.txt
```

### Run Locally

```bash
# Set environment variables
export FLASK_APP=web_app.py
export FLASK_ENV=development
export FLASK_DEBUG=1

# Run web app
python3 web_app.py

# Access at http://localhost:8080
```

### Project Structure

```
xui-panel-manager/
├── xui-panel-manager-installer.sh  # Installation script
├── web_app.py                      # Flask application
├── requirements.txt                # Python dependencies
├── templates/                      # HTML templates
│   ├── base.html
│   ├── login.html
│   ├── dashboard.html
│   ├── clients.html
│   ├── packages.html
│   ├── servers.html
│   └── settings.html
├── docs/                           # Documentation
│   ├── README-panel-manager.md
│   ├── QUICKSTART.md
│   ├── INSTALLATION.md
│   ├── PROJECT_SUMMARY.md
│   └── FILE_LIST.md
├── tests/                          # Test files (future)
├── examples/                       # Example configs
├── LICENSE
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
└── .gitignore
```

---

## Coding Standards

### Python Style Guide

Follow [PEP 8](https://pep8.org/) with these specifics:

#### Indentation
```python
# Use 4 spaces (not tabs)
def my_function():
    if condition:
        do_something()
```

#### Line Length
```python
# Maximum 100 characters per line
# Break long lines logically
result = some_function(
    parameter1,
    parameter2,
    parameter3
)
```

#### Naming Conventions
```python
# Classes: PascalCase
class ClientManager:
    pass

# Functions/Variables: snake_case
def get_client_list():
    client_count = 0
    pass

# Constants: UPPER_SNAKE_CASE
MAX_RETRY_ATTEMPTS = 8
DEFAULT_SYNC_INTERVAL = 60
```

#### Imports
```python
# Standard library first
import os
import sys
import json

# Third-party libraries
from flask import Flask, render_template
import requests

# Local modules
from utils import helper_function
```

#### Docstrings
```python
def sync_clients(servers, config):
    """
    Synchronize client data across multiple servers.
    
    Args:
        servers (list): List of server configurations
        config (dict): Global configuration settings
        
    Returns:
        dict: Sync results with success/failure counts
        
    Raises:
        ConnectionError: If unable to connect to server
        DatabaseError: If database operation fails
    """
    pass
```

### Bash Style Guide

```bash
# Use #!/bin/bash shebang
#!/bin/bash

# Use lowercase for variables
local_var="value"

# Use readonly for constants
readonly INSTALL_DIR="/opt/xui-panel-manager"

# Quote variables
echo "${local_var}"

# Use functions
function install_dependencies() {
    apt-get update
    apt-get install -y python3
}

# Check command success
if ! command -v python3 &> /dev/null; then
    echo "Python3 not found"
    exit 1
fi
```

### HTML/CSS/JavaScript

```html
<!-- Use semantic HTML -->
<nav class="navbar">
    <ul class="nav-list">
        <li><a href="/dashboard">Dashboard</a></li>
    </ul>
</nav>

<!-- Use CSS classes, not inline styles -->
<div class="stat-card success">
    <h3>Active Clients</h3>
    <p class="stat-value">42</p>
</div>
```

```css
/* Use kebab-case for classes */
.stat-card {
    padding: 20px;
    border-radius: 8px;
}

/* Use CSS variables for colors */
:root {
    --primary-color: #3498db;
    --success-color: #2ecc71;
}
```

```javascript
// Use camelCase for variables
const clientCount = 42;

// Use async/await for promises
async function fetchClients() {
    const response = await fetch('/api/clients');
    const data = await response.json();
    return data;
}

// Add JSDoc comments
/**
 * Update client traffic data
 * @param {string} email - Client email
 * @param {Object} data - Updated data
 * @returns {Promise<Object>} API response
 */
async function updateClient(email, data) {
    // ...
}
```

---

## Testing Guidelines

### Running Tests

```bash
# Run all tests
pytest

# Run specific test file
pytest tests/test_sync.py

# Run with coverage
pytest --cov=web_app tests/
```

### Writing Tests

```python
import pytest
from web_app import app, get_local_clients

def test_get_clients():
    """Test fetching clients from database"""
    clients = get_local_clients()
    assert isinstance(clients, list)
    
def test_sync_max_traffic():
    """Test MAX traffic algorithm"""
    data = [
        {"email": "test@example.com", "up": 100, "down": 200},
        {"email": "test@example.com", "up": 150, "down": 250}
    ]
    result = merge_traffic(data)
    assert result["up"] == 150
    assert result["down"] == 250
```

### Test Coverage

- Aim for **80%+ code coverage**
- **100% coverage** for critical functions (sync, backup, auth)
- Test edge cases and error conditions
- Mock external dependencies (SSH, databases)

---

## Commit Messages

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style (formatting, semicolons, etc.)
- **refactor**: Code refactoring
- **perf**: Performance improvement
- **test**: Adding or updating tests
- **chore**: Build process, dependencies, etc.

### Examples

```
feat(sync): add parallel server synchronization

Implement concurrent sync for multiple servers to reduce
total sync time from O(n) to O(1) with configurable
max parallel connections.

Closes #42
```

```
fix(web): resolve client search case sensitivity

Search now works case-insensitively for client emails
and names, improving user experience.

Fixes #55
```

```
docs(readme): update installation instructions

Add troubleshooting section for common SSH key issues
and firewall configuration.
```

### Commit Message Rules

1. **Use imperative mood** ("add" not "added")
2. **First line < 50 characters**
3. **Body lines < 72 characters**
4. **Reference issues/PRs** in footer
5. **Explain WHY, not just WHAT**

---

## Pull Request Process

### Before Submitting

1. **Create feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

2. **Make changes** following coding standards

3. **Test thoroughly**
   - Run existing tests: `pytest`
   - Add new tests if needed
   - Test manually in browser

4. **Update documentation**
   - Update README if needed
   - Add/update docstrings
   - Update CHANGELOG.md

5. **Commit changes**
   ```bash
   git add .
   git commit -m "feat: add amazing feature"
   ```

6. **Sync with upstream**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

7. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```

### Creating Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Select base: `main`, compare: `feature/amazing-feature`
4. Fill out PR template:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed code
- [ ] Commented complex code
- [ ] Updated documentation
- [ ] Added tests
- [ ] All tests pass
- [ ] No new warnings

## Testing
Describe how you tested your changes

## Screenshots
If applicable, add screenshots

## Related Issues
Closes #123
```

### Review Process

1. **Maintainer reviews** within 1-3 days
2. **Address feedback** by pushing new commits
3. **Once approved**, maintainer will merge
4. **Celebrate!** 🎉 Your contribution is live!

### After Merge

1. **Delete branch** (optional)
   ```bash
   git branch -d feature/amazing-feature
   git push origin --delete feature/amazing-feature
   ```

2. **Update local main**
   ```bash
   git checkout main
   git pull upstream main
   ```

---

## Community

### Getting Help

- **Documentation**: Start with [docs/](docs/)
- **GitHub Issues**: Search existing issues first
- **GitHub Discussions**: For questions and ideas
- **Telegram**: [@YOUR_TELEGRAM_CHANNEL] for chat

### Maintainers

- **Response time**: Usually within 1-3 days
- **Review time**: PRs reviewed within 1 week
- **Be patient**: Maintainers are volunteers

### Recognition

Contributors will be:
- Listed in README.md
- Mentioned in release notes
- Credited in CHANGELOG.md

---

## Development Tips

### Quick Development Cycle

```bash
# Watch for file changes and auto-reload
FLASK_DEBUG=1 python3 web_app.py

# Run linter
flake8 web_app.py

# Format code
black web_app.py

# Check types
mypy web_app.py
```

### Debugging

```python
# Add debug logging
import logging
logging.basicConfig(level=logging.DEBUG)

# Use Flask debug toolbar (add to requirements-dev.txt)
from flask_debugtoolbar import DebugToolbarExtension
toolbar = DebugToolbarExtension(app)

# Use pdb for breakpoints
import pdb; pdb.set_trace()
```

### Common Tasks

```bash
# Add new HTML template
cp templates/base.html templates/new_page.html
# Edit and add route in web_app.py

# Add new API endpoint
# In web_app.py:
@app.route('/api/new-endpoint', methods=['POST'])
def new_endpoint():
    # Implementation
    pass

# Add new package to requirements
echo "new-package==1.0.0" >> requirements.txt
pip install -r requirements.txt
```

---

## Questions?

If you have questions not covered here:

1. Check [documentation](docs/)
2. Search [existing issues](https://github.com/sepehringo/xui-panel-manager/issues)
3. Ask in [Discussions](https://github.com/sepehringo/xui-panel-manager/discussions)
4. Email maintainers (if really stuck)

---

Thank you for contributing to XUI Panel Manager! 🚀

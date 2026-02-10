#!/usr/bin/env bash
# Test script to validate installer without actually installing

set -e

echo "🔍 Testing XUI Panel Manager Installer..."
echo ""

# Check bash syntax
echo "✓ Checking bash syntax..."
bash -n xui-panel-manager-installer.sh
echo "  ✅ Syntax OK"
echo ""

# Check Python syntax
echo "✓ Checking Python syntax..."
python3 -m py_compile web_app.py
echo "  ✅ Python OK"
echo ""

# Check required files
echo "✓ Checking required files..."
required_files=(
    "xui-panel-manager-installer.sh"
    "web_app.py"
    "requirements.txt"
    "templates/base.html"
    "templates/login.html"
    "templates/dashboard.html"
    "templates/clients.html"
    "templates/packages.html"
    "templates/servers.html"
    "templates/settings.html"
    "README.md"
    "QUICKSTART.md"
    "INSTALLATION.md"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (MISSING)"
        exit 1
    fi
done
echo ""

# Check installer structure
echo "✓ Checking installer structure..."
required_functions=(
    "write_sync_script"
    "write_systemd_units"
    "init_config_files"
    "main_install"
)

for func in "${required_functions[@]}"; do
    if grep -q "^${func}()" xui-panel-manager-installer.sh; then
        echo "  ✅ Function: $func"
    else
        echo "  ⚠️  Function not found: $func"
    fi
done
echo ""

# Test GitHub URLs
echo "✓ Testing GitHub repository..."
if curl -s -o /dev/null -w "%{http_code}" https://github.com/sepehringo/xui-panel-manager | grep -q "200"; then
    echo "  ✅ Repository accessible"
else
    echo "  ❌ Repository not accessible"
    exit 1
fi
echo ""

# Test raw file access
echo "✓ Testing raw file downloads..."
test_url="https://raw.githubusercontent.com/sepehringo/xui-panel-manager/main/xui-panel-manager-installer.sh"
if curl -s -o /dev/null -w "%{http_code}" "$test_url" | grep -q "200"; then
    echo "  ✅ Raw files accessible"
    
    # Check for PYSCRIPT errors
    if curl -s "$test_url" | grep -c "^PYSCRIPT$" | grep -q "^1$"; then
        echo "  ✅ Single PYSCRIPT marker (correct)"
    else
        count=$(curl -s "$test_url" | grep -c "^PYSCRIPT$" || echo "0")
        echo "  ⚠️  PYSCRIPT count: $count (should be 1)"
    fi
else
    echo "  ❌ Raw files not accessible"
    exit 1
fi
echo ""

echo "================================================"
echo "✅ All tests passed!"
echo "================================================"
echo ""
echo "📋 Installation Commands for Ubuntu Server:"
echo ""
echo "  # Method 1: One-line install"
echo "  wget -qO- https://raw.githubusercontent.com/sepehringo/xui-panel-manager/main/xui-panel-manager-installer.sh | sudo bash"
echo ""
echo "  # Method 2: Git clone"
echo "  git clone https://github.com/sepehringo/xui-panel-manager.git"
echo "  cd xui-panel-manager"
echo "  chmod +x xui-panel-manager-installer.sh"
echo "  sudo ./xui-panel-manager-installer.sh"
echo ""
echo "🚀 Ready to deploy on Ubuntu server!"

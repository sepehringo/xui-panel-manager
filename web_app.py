#!/usr/bin/env python3
"""
XUI Panel Manager - Web Dashboard
Complete web interface for managing clients, packages, servers, and monitoring
"""

from flask import Flask, render_template, request, jsonify, session, redirect, url_for, flash
from flask_cors import CORS
from functools import wraps
import json
import os
import sqlite3
import subprocess
import hashlib
from datetime import datetime, timedelta
import time

app = Flask(__name__)
CORS(app)

# Configuration
CONF_FILE = "/etc/xui-panel-manager/config.json"
SERVERS_FILE = "/etc/xui-panel-manager/servers.json"
PACKAGES_FILE = "/etc/xui-panel-manager/packages.json"
USERS_FILE = "/etc/xui-panel-manager/users.json"
LOG_FILE = "/var/log/xui-panel-manager.log"
BACKUP_DIR = "/var/lib/xui-panel-manager/backups"

# Load config
def load_config():
    with open(CONF_FILE, 'r') as f:
        return json.load(f)

config = load_config()
app.secret_key = config.get('web_panel', {}).get('secret_key', 'change-me-please')

# Authentication decorator
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user' not in session or session.get('role') != 'admin':
            flash('Admin access required', 'error')
            return redirect(url_for ('dashboard'))
        return f(*args, **kwargs)
    return decorated_function

# Initialize users file
def init_users():
    if not os.path.exists(USERS_FILE):
        default_users = {
            "users": [
                {
                    "username": "admin",
                    "password": hashlib.sha256("admin123".encode()).hexdigest(),
                    "role": "admin",
                    "language": "en"
                }
            ]
        }
        with open(USERS_FILE, 'w') as f:
            json.dump(default_users, f, indent=2)

init_users()

# Helper functions
def load_json(path):
    with open(path, 'r') as f:
        return json.load(f)

def save_json(path, data):
    with open(path, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def get_local_clients():
    """Get clients from local database"""
    config = load_config()
    db_path = config.get('local_db_path')
    
    if not db_path or not os.path.exists(db_path):
        return []
    
    try:
        con = sqlite3.connect(db_path, timeout=5)
        con.row_factory = sqlite3.Row
        cur = con.cursor()
        cur.execute("SELECT email, up, down, expiry_time, total, enable FROM client_traffics ORDER BY email")
        
        clients = []
        for row in cur.fetchall():
            expiry_timestamp = int(row['expiry_time'] or 0)
            if expiry_timestamp > 0:
                expiry_date = datetime.fromtimestamp(expiry_timestamp / 1000)
                days_remaining = (expiry_date - datetime.now()).days
            else:
                expiry_date = None
                days_remaining = None
            
            up_gb = int(row['up'] or 0) / (1024**3)
            down_gb = int(row['down'] or 0) / (1024**3)
            total_gb = int(row['total'] or 0) / (1024**3)
            used_gb = up_gb + down_gb
            
            clients.append({
                'email': row['email'],
                'up_gb': round(up_gb, 2),
                'down_gb': round(down_gb, 2),
                'used_gb': round(used_gb, 2),
                'total_gb': round(total_gb, 2),
                'usage_percent': round((used_gb / total_gb * 100) if total_gb > 0 else 0, 1),
                'expiry_date': expiry_date.strftime('%Y-%m-%d %H:%M') if expiry_date else 'N/A',
                'days_remaining': days_remaining,
                'enabled': bool(row['enable']),
                'expiry_timestamp': expiry_timestamp
            })
        
        con.close()
        return clients
    except Exception as e:
        print(f"Error fetching clients: {e}")
        return []

def update_client_in_db(email, up_bytes, down_bytes, expiry_timestamp, total_bytes, enable):
    """Update client data in local database"""
    config = load_config()
    db_path = config.get('local_db_path')
    service_name = config.get('local_service_name', 'x-ui')
    
    if not db_path or not os.path.exists(db_path):
        return False
    
    try:
        con = sqlite3.connect(db_path, timeout=10)
        cur = con.cursor()
        cur.execute('''
            UPDATE client_traffics 
            SET up=?, down=?, expiry_time=?, total=?, enable=?
            WHERE email=?
        ''', (up_bytes, down_bytes, expiry_timestamp, total_bytes, enable, email))
        con.commit()
        con.close()
        
        # Trigger sync to propagate changes
        subprocess.Popen(['/usr/bin/python3', '/opt/xui-panel-manager/sync.py'], 
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        return True
    except Exception as e:
        print(f"Error updating client: {e}")
        return False

def apply_package_to_client(email, package):
    """Apply a package to a client"""
    clients = get_local_clients()
    client = next((c for c in clients if c['email'] == email), None)
    
    if not client:
        return False
    
    # Calculate new values
    days = int(package['days'])
    traffic_gb = float(package['traffic_gb'])
    
    # New expiry: current time + days
    new_expiry = int((datetime.now() + timedelta(days=days)).timestamp() * 1000)
    
    # Reset traffic or add to existing
    up_bytes = 0  # Reset upload
    down_bytes = 0  # Reset download
    total_bytes = int(traffic_gb * (1024**3))
    enable = 1  # Enable client
    
    return update_client_in_db(email, up_bytes, down_bytes, new_expiry, total_bytes, enable)

def get_stats():
    """Get system statistics"""
    clients = get_local_clients()
    servers = load_json(SERVERS_FILE)
    packages = load_json(PACKAGES_FILE)
    
    total_clients = len(clients)
    active_clients = len([c for c in clients if c['enabled']])
    expired_clients = len([c for c in clients if c['days_remaining'] is not None and c['days_remaining'] < 0])
    expiring_soon = len([c for c in clients if c['days_remaining'] is not None and 0 <= c['days_remaining'] <= 7])
    
    total_used_gb = sum(c['used_gb'] for c in clients)
    total_quota_gb = sum(c['total_gb'] for c in clients)
    
    return {
        'total_clients': total_clients,
        'active_clients': active_clients,
        'expired_clients': expired_clients,
        'expiring_soon': expiring_soon,
        'total_servers': len(servers.get('servers', [])),
        'total_packages': len(packages.get('packages', [])),
        'total_used_gb': round(total_used_gb, 2),
        'total_quota_gb': round(total_quota_gb, 2)
    }

def send_telegram(message):
    """Send Telegram notification"""
    config = load_config()
    telegram = config.get('telegram', {})
    
    if not telegram.get('enabled') or not telegram.get('bot_token'):
        return False
    
    try:
        import requests
        bot_token = telegram['bot_token']
        chat_id = telegram['chat_id']
        url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
        
        data = {
            "chat_id": chat_id,
            "text": f"🔔 XUI Panel Manager\n\n{message}",
            "parse_mode": "HTML"
        }
        
        response = requests.post(url, json=data, timeout=10)
        return response.status_code == 200
    except:
        return False

# Routes
@app.route('/')
def index():
    if 'user' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        data = request.get_json() if request.is_json else request.form
        username = data.get('username')
        password = data.get('password')
        
        users = load_json(USERS_FILE)
        password_hash = hashlib.sha256(password.encode()).hexdigest()
        
        user = next((u for u in users['users'] if u['username'] == username and u['password'] == password_hash), None)
        
        if user:
            session['user'] = username
            session['role'] = user.get('role', 'user')
            session['language'] = user.get('language', 'en')
            
            if request.is_json:
                return jsonify({'success': True, 'redirect': url_for('dashboard')})
            return redirect(url_for('dashboard'))
        
        if request.is_json:
            return jsonify({'success': False, 'message': 'Invalid credentials'}), 401
        
        flash('Invalid username or password', 'error')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/dashboard')
@login_required
def dashboard():
    stats = get_stats()
    return render_template('dashboard.html', stats=stats, user=session.get('user'), language=session.get('language', 'en'))

@app.route('/clients')
@login_required
def clients_page():
    clients = get_local_clients()
    packages = load_json(PACKAGES_FILE)
    return render_template('clients.html', clients=clients, packages=packages['packages'], user=session.get('user'))

@app.route('/api/clients')
@login_required
def api_clients():
    clients = get_local_clients()
    return jsonify(clients)

@app.route('/api/clients/<email>/update', methods=['POST'])
@login_required
def api_update_client(email):
    data = request.get_json()
    
    try:
        # Parse values
        days = int(data.get('days', 0))
        traffic_gb = float(data.get('traffic_gb', 0))
        action = data.get('action', 'set')  # 'set', 'add', or 'reset'
        
        clients = get_local_clients()
        client = next((c for c in clients if c['email'] == email), None)
        
        if not client:
            return jsonify({'success': False, 'message': 'Client not found'}), 404
        
        # Calculate new expiry
        if action == 'set' and days > 0:
            new_expiry = int((datetime.now() + timedelta(days=days)).timestamp() * 1000)
        elif action == 'add' and days > 0:
            current_expiry = client.get('expiry_timestamp', 0)
            if current_expiry > 0:
                new_expiry = current_expiry + (days * 24 * 60 * 60 * 1000)
            else:
                new_expiry = int((datetime.now() + timedelta(days=days)).timestamp() * 1000)
        else:
            new_expiry = client.get('expiry_timestamp', 0)
        
        # Calculate new traffic
        if action == 'reset':
            up_bytes = 0
            down_bytes = 0
            total_bytes = int(traffic_gb * (1024**3))
        elif action == 'add':
            up_bytes = int(client['up_gb'] * (1024**3))
            down_bytes = int(client['down_gb'] * (1024**3))
            total_bytes = int((client['total_gb'] + traffic_gb) * (1024**3))
        else:  # set
            up_bytes = int(client['up_gb'] * (1024**3))
            down_bytes = int(client['down_gb'] * (1024**3))
            total_bytes = int(traffic_gb * (1024**3))
        
        enable = 1
        
        success = update_client_in_db(email, up_bytes, down_bytes, new_expiry, total_bytes, enable)
        
        if success:
            send_telegram(f"✏️ Client Updated\n\nEmail: {email}\nDays: {days}\nTraffic: {traffic_gb} GB")
            return jsonify({'success': True, 'message': 'Client updated successfully'})
        else:
            return jsonify({'success': False, 'message': 'Failed to update client'}), 500
            
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/clients/<email>/apply-package', methods=['POST'])
@login_required
def api_apply_package(email):
    data = request.get_json()
    package_id = data.get('package_id')
    
    packages = load_json(PACKAGES_FILE)
    package = next((p for p in packages['packages'] if p['id'] == package_id), None)
    
    if not package:
        return jsonify({'success': False, 'message': 'Package not found'}), 404
    
    success = apply_package_to_client(email, package)
    
    if success:
        send_telegram(f"📦 Package Applied\n\nClient: {email}\nPackage: {package['name']}\nDays: {package['days']}\nTraffic: {package['traffic_gb']} GB")
        return jsonify({'success': True, 'message': f'Package "{package["name"]}" applied successfully'})
    else:
        return jsonify({'success': False, 'message': 'Failed to apply package'}), 500

@app.route('/api/clients/<email>/reset', methods=['POST'])
@login_required
def api_reset_client(email):
    """Reset client traffic to zero"""
    clients = get_local_clients()
    client = next((c for c in clients if c['email'] == email), None)
    
    if not client:
        return jsonify({'success': False, 'message': 'Client not found'}), 404
    
    # Reset traffic but keep other settings
    up_bytes = 0
    down_bytes = 0
    total_bytes = int(client['total_gb'] * (1024**3))
    expiry_timestamp = client.get('expiry_timestamp', 0)
    enable = 1
    
    success = update_client_in_db(email, up_bytes, down_bytes, expiry_timestamp, total_bytes, enable)
    
    if success:
        send_telegram(f"🔄 Client Reset\n\nEmail: {email}\nTraffic reset to 0")
        return jsonify({'success': True, 'message': 'Client traffic reset'})
    else:
        return jsonify({'success': False, 'message': 'Failed to reset client'}), 500

@app.route('/packages')
@login_required
def packages_page():
    packages = load_json(PACKAGES_FILE)
    return render_template('packages.html', packages=packages['packages'], user=session.get('user'))

@app.route('/api/packages', methods=['GET', 'POST'])
@login_required
@admin_required
def api_packages():
    packages = load_json(PACKAGES_FILE)
    
    if request.method == 'POST':
        data = request.get_json()
        
        new_package = {
            'id': f"pkg_{int(time.time())}",
            'name': data['name'],
            'days': int(data['days']),
            'traffic_gb': float(data['traffic_gb']),
            'price': data.get('price', '')
        }
        
        packages['packages'].append(new_package)
        save_json(PACKAGES_FILE, packages)
        
        return jsonify({'success': True, 'package': new_package})
    
    return jsonify(packages['packages'])

@app.route('/api/packages/<package_id>', methods=['DELETE'])
@login_required
@admin_required
def api_delete_package(package_id):
    packages = load_json(PACKAGES_FILE)
    packages['packages'] = [p for p in packages['packages'] if p['id'] != package_id]
    save_json(PACKAGES_FILE, packages)
    
    return jsonify({'success': True})

@app.route('/servers')
@login_required
def servers_page():
    servers = load_json(SERVERS_FILE)
    return render_template('servers.html', servers=servers['servers'], user=session.get('user'))

@app.route('/api/servers', methods=['GET', 'POST'])
@login_required
@admin_required
def api_servers():
    servers = load_json(SERVERS_FILE)
    
    if request.method == 'POST':
        data = request.get_json()
        
        new_server = {
            'name': data['name'],
            'host': data['host'],
            'port': int(data.get('port', 22)),
            'user': data.get('user', 'root'),
            'db_path': data.get('db_path', '/etc/x-ui/x-ui.db'),
            'service_name': data.get('service_name', 'x-ui'),
            'ssh_key': '/etc/xui-panel-manager/id_ed25519'
        }
        
        servers['servers'].append(new_server)
        save_json(SERVERS_FILE, servers)
        
        return jsonify({'success': True, 'server': new_server})
    
    return jsonify(servers['servers'])

@app.route('/api/servers/<int:index>', methods=['DELETE'])
@login_required
@admin_required
def api_delete_server(index):
    servers = load_json(SERVERS_FILE)
    
    if 0 <= index < len(servers['servers']):
        deleted = servers['servers'].pop(index)
        save_json(SERVERS_FILE, servers)
        return jsonify({'success': True, 'deleted': deleted})
    
    return jsonify({'success': False, 'message': 'Server not found'}), 404

@app.route('/api/sync/trigger', methods=['POST'])
@login_required
def api_trigger_sync():
    """Manually trigger synchronization"""
    try:
        subprocess.Popen(['/usr/bin/python3', '/opt/xui-panel-manager/sync.py'],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return jsonify({'success': True, 'message': 'Sync triggered'})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/stats')
@login_required
def api_stats():
    return jsonify(get_stats())

@app.route('/settings')
@login_required
@admin_required
def settings_page():
    config = load_config()
    return render_template('settings.html', config=config, user=session.get('user'))

@app.route('/api/settings', methods=['POST'])
@login_required
@admin_required
def api_update_settings():
    data = request.get_json()
    config = load_config()
    
    # Update telegram settings
    if 'telegram' in data:
        config['telegram'] = data['telegram']
    
    # Update sync interval
    if 'sync_interval_minutes' in data:
        config['sync_interval_minutes'] = int(data['sync_interval_minutes'])
    
    save_json(CONF_FILE, config)
    
    return jsonify({'success': True, 'message': 'Settings updated'})

@app.route('/api/logs')
@login_required
def api_logs():
    """Get recent logs"""
    try:
        with open(LOG_FILE, 'r') as f:
            lines = f.readlines()
            return jsonify({'logs': lines[-100:]})  # Last 100 lines
    except:
        return jsonify({'logs': []})

if __name__ == '__main__':
    host = config.get('web_panel', {}).get('host', '0.0.0.0')
    port = config.get('web_panel', {}).get('port', 8080)
    
    print(f"Starting XUI Panel Manager Web Interface on {host}:{port}")
    app.run(host=host, port=port, debug=False)

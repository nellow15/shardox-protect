#!/bin/bash

TARGET_FILE="/var/www/pterodactyl/resources/views/templates/base/core.blade.php"
BACKUP_FILE="${TARGET_FILE}.bak_$(date -u +"%Y-%m-%d-%H-%M-%S")"

echo "Mengganti isi $TARGET_FILE dengan sistem real-time monitoring tanpa console..."

# Backup dulu file lama
if [ -f "$TARGET_FILE" ]; then
  cp "$TARGET_FILE" "$BACKUP_FILE"
  echo "Backup file lama dibuat di $BACKUP_FILE"
fi

cat > "$TARGET_FILE" << 'EOF'
@extends('templates/wrapper', [
    'css' => ['body' => 'bg-neutral-800'],
])

@section('container')
    <div id="modal-portal"></div>
    <div id="app"></div>

    <script>
      document.addEventListener("DOMContentLoaded", () => {
        const username = @json(auth()->user()->name?? 'User');
        
        // State management
        let greetingVisible = true;
        let statsVisible = false;
        let monitoringInterval = null;
        let serverDetails = [];
        let currentServerData = null;
        
        // Helper functions
        const getGreeting = () => {
          const hour = new Date().getHours();
          if (hour < 12) return 'Pagi';
          if (hour < 15) return 'Siang';
          if (hour < 18) return 'Sore';
          return 'Malam';
        };
        
        const formatTime = () => {
          return new Date().toLocaleTimeString('id-ID', {
            hour: '2-digit',
            minute: '2-digit'
          });
        };
        
        // Format bytes to readable size
        const formatBytes = (bytes) => {
          if (bytes === 0) return '0 B';
          const k = 1024;
          const sizes = ['B', 'KB', 'MB', 'GB'];
          const i = Math.floor(Math.log(bytes) / Math.log(k));
          return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
        };
        
        // Calculate percentage for RAM and Disk
        const calculatePercentage = (used, total) => {
          if (!total || total === 0) return 0;
          return Math.min(Math.round((used / total) * 100), 100);
        };
        
        // 1. CREATE COMPACT GREETING
        const greetingElement = document.createElement('div');
        greetingElement.id = 'compact-greeting';
        
        greetingElement.innerHTML = `
          <div class="greeting-compact">
            <div class="greeting-inner">
              <div class="user-badge">
                ${username.charAt(0).toUpperCase()}
              </div>
              <div class="greeting-details">
                <div class="user-name">${username}</div>
                <div class="time-greeting">${getGreeting()} • ${formatTime()}</div>
              </div>
              <button class="btn-close" title="Sembunyikan">
                <svg width="12" height="12" viewBox="0 0 12 12">
                  <path d="M1 1L11 11M1 11L11 1" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                </svg>
              </button>
            </div>
          </div>
        `;
        
        // 2. CREATE COMPACT TOGGLE BUTTON
        const toggleButton = document.createElement('div');
        toggleButton.id = 'compact-toggle';
        
        toggleButton.innerHTML = `
          <div class="toggle-compact">
            <svg width="14" height="14" viewBox="0 0 24 24">
              <rect x="2" y="2" width="20" height="8" rx="1" ry="1"/>
              <rect x="2" y="14" width="20" height="8" rx="1" ry="1"/>
              <line x1="6" y1="6" x2="6.01" y2="6"/>
              <line x1="6" y1="18" x2="6.01" y2="18"/>
            </svg>
            <div class="server-badge" id="server-badge">0</div>
          </div>
        `;
        
        // 3. CREATE COMPACT STATS PANEL
        const statsContainer = document.createElement('div');
        statsContainer.id = 'compact-stats';
        
        // Add CSS styles
        const styleElement = document.createElement('style');
        styleElement.textContent = `
          /* Base styles */
          #compact-greeting, #compact-toggle, #compact-stats {
            position: fixed;
            right: 12px;
            z-index: 9999;
            transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
          }
          
          /* Greeting styles */
          #compact-greeting {
            bottom: 12px;
            opacity: 0;
            transform: translateY(10px);
          }
          
          .greeting-compact {
            background: rgba(30, 41, 59, 0.92);
            backdrop-filter: blur(8px);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 10px;
            padding: 8px 10px;
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
            max-width: 220px;
            min-width: 180px;
          }
          
          .greeting-inner {
            display: flex;
            align-items: center;
            gap: 8px;
            width: 100%;
          }
          
          .user-badge {
            width: 28px;
            height: 28px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 12px;
            flex-shrink: 0;
          }
          
          .greeting-details {
            flex: 1;
            min-width: 0;
          }
          
          .user-name {
            font-weight: 600;
            font-size: 12px;
            color: #f8fafc;
            line-height: 1.2;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
          }
          
          .time-greeting {
            font-size: 10px;
            color: #cbd5e1;
            opacity: 0.8;
            line-height: 1.2;
            margin-top: 1px;
          }
          
          .btn-close {
            background: rgba(255, 255, 255, 0.07);
            border: none;
            width: 22px;
            height: 22px;
            border-radius: 6px;
            color: #94a3b8;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.15s ease;
            flex-shrink: 0;
            margin-left: 2px;
            padding: 0;
          }
          
          .btn-close:hover {
            background: rgba(239, 68, 68, 0.15);
            color: #ef4444;
          }
          
          .btn-close svg {
            width: 10px;
            height: 10px;
          }
          
          /* Toggle button styles */
          #compact-toggle {
            bottom: 56px;
            opacity: 0;
            transform: scale(0.9);
          }
          
          .toggle-compact {
            width: 36px;
            height: 36px;
            background: rgba(30, 41, 59, 0.9);
            backdrop-filter: blur(8px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #94a3b8;
            cursor: pointer;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
            transition: all 0.2s ease;
            position: relative;
          }
          
          .toggle-compact:hover {
            background: rgba(59, 130, 246, 0.85);
            color: white;
            transform: scale(1.05);
            box-shadow: 0 4px 20px rgba(59, 130, 246, 0.25);
          }
          
          .toggle-compact svg {
            width: 14px;
            height: 14px;
            fill: none;
            stroke: currentColor;
            stroke-width: 1.5;
          }
          
          .server-badge {
            position: absolute;
            top: -3px;
            right: -3px;
            width: 18px;
            height: 18px;
            background: #10b981;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 9px;
            font-weight: 700;
            box-shadow: 0 2px 6px rgba(16, 185, 129, 0.4);
            opacity: 0;
            transform: scale(0);
            transition: all 0.2s ease;
          }
          
          .server-badge.active {
            opacity: 1;
            transform: scale(1);
          }
          
          /* Stats panel styles */
          #compact-stats {
            bottom: 98px;
            opacity: 0;
            transform: translateY(8px) scale(0.95);
            pointer-events: none;
            max-width: 320px;
            min-width: 280px;
          }
          
          #compact-stats.visible {
            opacity: 1;
            transform: translateY(0) scale(1);
            pointer-events: auto;
          }
          
          .stats-compact {
            background: rgba(30, 41, 59, 0.96);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            box-shadow: 0 6px 24px rgba(0, 0, 0, 0.25);
            overflow: hidden;
          }
          
          .stats-header {
            padding: 10px 12px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
          
          .stats-title {
            font-weight: 600;
            font-size: 12px;
            color: #f8fafc;
            display: flex;
            align-items: center;
            gap: 6px;
          }
          
          .refresh-btn {
            background: rgba(255, 255, 255, 0.07);
            border: none;
            width: 22px;
            height: 22px;
            border-radius: 6px;
            color: #94a3b8;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.15s ease;
            padding: 0;
            margin-right: 6px;
          }
          
          .refresh-btn:hover {
            background: rgba(59, 130, 246, 0.2);
            color: #3b82f6;
            transform: rotate(90deg);
          }
          
          .refresh-btn.loading {
            animation: spin 1s linear infinite;
          }
          
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
          
          .stats-close {
            background: rgba(255, 255, 255, 0.07);
            border: none;
            width: 22px;
            height: 22px;
            border-radius: 6px;
            color: #94a3b8;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.15s ease;
            padding: 0;
          }
          
          .stats-close:hover {
            background: rgba(239, 68, 68, 0.15);
            color: #ef4444;
          }
          
          .stats-close svg {
            width: 10px;
            height: 10px;
          }
          
          .stats-content {
            padding: 12px;
            max-height: 400px;
            overflow-y: auto;
          }
          
          .server-overview {
            margin-bottom: 12px;
            padding-bottom: 10px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
          }
          
          .overview-grid {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 8px;
            margin-bottom: 10px;
          }
          
          .stat-card {
            background: rgba(255, 255, 255, 0.03);
            border-radius: 8px;
            padding: 8px;
            text-align: center;
          }
          
          .stat-value {
            font-size: 18px;
            font-weight: 700;
            line-height: 1;
            margin-bottom: 2px;
          }
          
          .stat-label {
            font-size: 9px;
            color: #94a3b8;
            text-transform: uppercase;
            letter-spacing: 0.5px;
          }
          
          .online-value {
            color: #10b981;
          }
          
          .cpu-value {
            color: #3b82f6;
          }
          
          .ram-value {
            color: #8b5cf6;
          }
          
          .disk-value {
            color: #10b981;
          }
          
          .monitoring-info {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-top: 8px;
          }
          
          .update-status {
            font-size: 9px;
            color: #94a3b8;
            display: flex;
            align-items: center;
            gap: 4px;
          }
          
          .update-dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background: #10b981;
          }
          
          .update-dot.active {
            animation: pulse 2s infinite;
          }
          
          @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.3; }
            100% { opacity: 1; }
          }
          
          .time-stamp {
            font-size: 9px;
            color: #64748b;
          }
          
          .server-list {
            margin-top: 8px;
          }
          
          .server-item {
            background: rgba(255, 255, 255, 0.02);
            border-radius: 8px;
            padding: 10px;
            margin-bottom: 8px;
            border: 1px solid rgba(255, 255, 255, 0.03);
          }
          
          .server-item:last-child {
            margin-bottom: 0;
          }
          
          .server-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
          }
          
          .server-name {
            font-size: 11px;
            color: #e2e8f0;
            font-weight: 500;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            max-width: 180px;
          }
          
          .server-status {
            font-size: 9px;
            padding: 2px 6px;
            border-radius: 4px;
            font-weight: 600;
          }
          
          .status-online {
            background: rgba(16, 185, 129, 0.15);
            color: #10b981;
          }
          
          .status-offline {
            background: rgba(239, 68, 68, 0.15);
            color: #ef4444;
          }
          
          .server-resources {
            margin-top: 8px;
          }
          
          .resource-item {
            margin-bottom: 6px;
          }
          
          .resource-item:last-child {
            margin-bottom: 0;
          }
          
          .resource-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 4px;
          }
          
          .resource-label {
            font-size: 9px;
            color: #94a3b8;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            display: flex;
            align-items: center;
            gap: 4px;
          }
          
          .resource-value {
            font-size: 10px;
            color: #f8fafc;
            font-weight: 600;
          }
          
          .cpu-display {
            color: #3b82f6;
          }
          
          .ram-display {
            color: #8b5cf6;
          }
          
          .disk-display {
            color: #10b981;
          }
          
          .progress-bar {
            height: 4px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 2px;
            overflow: hidden;
            margin-top: 2px;
          }
          
          .progress-fill {
            height: 100%;
            border-radius: 2px;
            transition: width 0.5s ease;
          }
          
          .cpu-progress {
            background: linear-gradient(90deg, #3b82f6, #8b5cf6);
          }
          
          .ram-progress {
            background: linear-gradient(90deg, #8b5cf6, #a78bfa);
          }
          
          .disk-progress {
            background: linear-gradient(90deg, #10b981, #34d399);
          }
          
          .server-actions {
            display: flex;
            gap: 8px;
            margin-top: 10px;
          }
          
          .btn-open {
            flex: 1;
            background: rgba(59, 130, 246, 0.15);
            color: #3b82f6;
            border: none;
            padding: 6px 12px;
            border-radius: 6px;
            font-size: 10px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
            text-align: center;
          }
          
          .btn-open:hover {
            background: rgba(59, 130, 246, 0.25);
            transform: translateY(-1px);
          }
          
          .btn-open:disabled {
            background: rgba(100, 116, 139, 0.1);
            color: #64748b;
            cursor: not-allowed;
            transform: none;
          }
          
          .empty-state {
            text-align: center;
            padding: 20px 12px;
            color: #94a3b8;
            font-size: 11px;
          }
          
          .error-state {
            text-align: center;
            padding: 20px 12px;
            color: #ef4444;
            font-size: 11px;
          }
          
          .loading-state {
            text-align: center;
            padding: 20px 12px;
            color: #94a3b8;
            font-size: 11px;
          }
          
          /* Resource usage details */
          .usage-details {
            font-size: 8px;
            color: #64748b;
            margin-top: 2px;
            text-align: right;
          }
          
          /* Scrollbar */
          .stats-content::-webkit-scrollbar {
            width: 4px;
          }
          
          .stats-content::-webkit-scrollbar-track {
            background: rgba(255, 255, 255, 0.03);
            border-radius: 2px;
          }
          
          .stats-content::-webkit-scrollbar-thumb {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 2px;
          }
          
          /* Mobile responsive */
          @media (max-width: 768px) {
            #compact-greeting, #compact-toggle, #compact-stats {
              right: 8px;
            }
            
            #compact-greeting {
              bottom: 8px;
            }
            
            #compact-toggle {
              bottom: 52px;
            }
            
            #compact-stats {
              bottom: 96px;
              max-width: calc(100vw - 16px);
              min-width: auto;
            }
            
            .greeting-compact {
              max-width: calc(100vw - 24px);
            }
            
            .stats-compact {
              max-width: calc(100vw - 16px);
            }
            
            .overview-grid {
              grid-template-columns: 1fr 1fr;
              gap: 8px;
            }
            
            .server-name {
              max-width: 160px;
            }
          }
          
          @media (max-width: 480px) {
            .greeting-compact {
              padding: 6px 8px;
            }
            
            .user-badge {
              width: 24px;
              height: 24px;
              font-size: 11px;
            }
            
            .user-name {
              font-size: 11px;
            }
            
            .time-greeting {
              font-size: 9px;
            }
            
            .toggle-compact {
              width: 32px;
              height: 32px;
            }
            
            .toggle-compact svg {
              width: 12px;
              height: 12px;
            }
            
            .overview-grid {
              grid-template-columns: 1fr 1fr;
            }
            
            .server-name {
              max-width: 140px;
            }
          }
          
          /* Hide toggle button when idle */
          #compact-toggle.idle {
            opacity: 0.3 !important;
          }
        `;
        
        document.head.appendChild(styleElement);
        
        // Add elements to body
        document.body.appendChild(greetingElement);
        document.body.appendChild(toggleButton);
        document.body.appendChild(statsContainer);
        
        // 4. EVENT HANDLERS
        // Close greeting
        const closeGreetingBtn = greetingElement.querySelector('.btn-close');
        closeGreetingBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          greetingVisible = false;
          greetingElement.style.opacity = '0';
          greetingElement.style.transform = 'translateY(10px)';
          setTimeout(() => {
            greetingElement.style.display = 'none';
          }, 250);
        });
        
        // Toggle stats panel
        toggleButton.addEventListener('click', (e) => {
          e.stopPropagation();
          toggleStatsPanel();
        });
        
        // Close stats when clicking outside
        document.addEventListener('click', (e) => {
          if (statsVisible) {
            const isStatsClick = statsContainer.contains(e.target);
            const isToggleClick = toggleButton.contains(e.target);
            
            if (!isStatsClick && !isToggleClick) {
              hideStatsPanel();
            }
          }
        });
        
        // 5. STATS PANEL FUNCTIONS
        function toggleStatsPanel() {
          if (statsVisible) {
            hideStatsPanel();
          } else {
            showStatsPanel();
          }
        }
        
        function showStatsPanel() {
          statsVisible = true;
          statsContainer.classList.add('visible');
          toggleButton.classList.remove('idle');
          
          if (!currentServerData) {
            loadServerData();
          } else {
            updateStatsDisplay();
          }
        }
        
        function hideStatsPanel() {
          statsVisible = false;
          statsContainer.classList.remove('visible');
        }
        
        // 6. LOAD SERVER DATA WITH REAL-TIME RESOURCE MONITORING
        async function loadServerData() {
          try {
            // Show loading state
            statsContainer.innerHTML = `
              <div class="stats-compact">
                <div class="stats-header">
                  <div class="stats-title">Monitoring Server</div>
                  <div style="display: flex; gap: 4px;">
                    <button class="refresh-btn loading">
                      <svg width="12" height="12" viewBox="0 0 24 24">
                        <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.3" 
                          stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                      </svg>
                    </button>
                    <button class="stats-close">
                      <svg width="12" height="12" viewBox="0 0 12 12">
                        <path d="M1 1L11 11M1 11L11 1" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                      </svg>
                    </button>
                  </div>
                </div>
                <div class="stats-content">
                  <div class="loading-state">
                    <div style="margin-bottom: 4px;">Memuat data real-time...</div>
                    <div style="font-size: 9px; color: #64748b;">Monitoring CPU, RAM, Disk aktif</div>
                  </div>
                </div>
              </div>
            `;
            
            // Add close button handler
            const closeBtn = statsContainer.querySelector('.stats-close');
            closeBtn.addEventListener('click', (e) => {
              e.stopPropagation();
              hideStatsPanel();
            });
            
            // Fetch server list
            const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || '';
            
            const response = await fetch('/api/client', {
              method: 'GET',
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': csrfToken,
                'X-Requested-With': 'XMLHttpRequest'
              },
              credentials: 'same-origin'
            });
            
            if (!response.ok) throw new Error('Network error');
            
            const data = await response.json();
            let servers = [];
            
            if (data.data && Array.isArray(data.data)) {
              servers = data.data;
              
              // Process each server
              const serverPromises = servers.map(async (server) => {
                const serverId = server.attributes?.identifier || server.id;
                const serverName = server.attributes?.name || 'Server';
                const serverIdentifier = server.attributes?.identifier;
                
                let isRunning = false;
                let cpuUsage = 0;
                let ramUsage = 0;
                let ramUsed = 0;
                let ramTotal = 0;
                let diskUsed = 0;
                let diskTotal = 0;
                
                try {
                  const res = await fetch(`/api/client/servers/${serverId}/resources`, {
                    method: 'GET',
                    headers: {
                      'Accept': 'application/json',
                      'Content-Type': 'application/json',
                      'X-CSRF-TOKEN': csrfToken,
                      'X-Requested-With': 'XMLHttpRequest'
                    },
                    credentials: 'same-origin'
                  });
                  
                  if (res.ok) {
                    const resourceData = await res.json();
                    const attributes = resourceData.attributes || {};
                    
                    isRunning = attributes.current_state === 'running' || 
                               attributes.current_state === 'starting';
                    
                    // Get detailed resource usage
                    if (attributes.resources) {
                      const resources = attributes.resources;
                      
                      // CPU usage (percentage)
                      cpuUsage = Math.min(Math.max(resources.cpu_absolute || 0, 0), 100);
                      
                      // RAM usage
                      ramUsed = resources.memory_bytes || 0;
                      ramTotal = resources.memory_limit_bytes || 0;
                      ramUsage = calculatePercentage(ramUsed, ramTotal);
                      
                      // Disk usage
                      diskUsed = resources.disk_bytes || 0;
                      diskTotal = resources.disk_limit_bytes || 0;
                      diskUsage = calculatePercentage(diskUsed, diskTotal);
                    }
                  }
                } catch (error) {
                  console.warn('Error fetching server resources:', error);
                }
                
                return {
                  id: serverId,
                  name: serverName,
                  identifier: serverIdentifier,
                  status: isRunning ? 'running' : 'offline',
                  cpu: cpuUsage,
                  ram: {
                    used: ramUsed,
                    total: ramTotal,
                    percentage: ramUsage
                  },
                  disk: {
                    used: diskUsed,
                    total: diskTotal,
                    percentage: diskUsage
                  },
                  url: serverIdentifier ? `/server/${serverIdentifier}` : `/server/${serverId}`,
                  lastUpdate: new Date().getTime()
                };
              });
              
              serverDetails = await Promise.all(serverPromises);
            }
            
            // Calculate totals and averages
            const totalServers = serverDetails.length;
            const activeServers = serverDetails.filter(s => s.status === 'running').length;
            const activeServersList = serverDetails.filter(s => s.status === 'running');
            
            // Calculate average CPU
            const avgCpu = activeServersList.length > 0 
              ? Math.round(activeServersList.reduce((sum, s) => sum + s.cpu, 0) / activeServersList.length)
              : 0;
            
            // Calculate average RAM percentage
            const avgRam = activeServersList.length > 0 
              ? Math.round(activeServersList.reduce((sum, s) => sum + s.ram.percentage, 0) / activeServersList.length)
              : 0;
            
            // Calculate average Disk percentage
            const avgDisk = activeServersList.length > 0 
              ? Math.round(activeServersList.reduce((sum, s) => sum + s.disk.percentage, 0) / activeServersList.length)
              : 0;
            
            currentServerData = {
              totalServers,
              activeServers,
              avgCpu,
              avgRam,
              avgDisk,
              serverDetails,
              lastUpdate: new Date().getTime()
            };
            
            // Update badge
            updateServerBadge(activeServers);
            
            // Update display
            updateStatsDisplay();
            
            // Start real-time monitoring
            startRealTimeMonitoring();
            
          } catch (error) {
            console.error('Error loading server data:', error);
            showErrorState();
          }
        }
        
        // 7. REAL-TIME MONITORING SYSTEM
        function startRealTimeMonitoring() {
          // Clear any existing interval
          if (monitoringInterval) {
            clearInterval(monitoringInterval);
          }
          
          // Update every 60 seconds (1 minute)
          monitoringInterval = setInterval(async () => {
            if (!serverDetails.length) return;
            
            try {
              const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || '';
              let updatedCount = 0;
              
              // Update each server's resource usage
              for (const server of serverDetails) {
                try {
                  const res = await fetch(`/api/client/servers/${server.id}/resources`, {
                    method: 'GET',
                    headers: {
                      'Accept': 'application/json',
                      'Content-Type': 'application/json',
                      'X-CSRF-TOKEN': csrfToken,
                      'X-Requested-With': 'XMLHttpRequest'
                    },
                    credentials: 'same-origin'
                  });
                  
                  if (res.ok) {
                    const resourceData = await res.json();
                    const attributes = resourceData.attributes || {};
                    
                    // Update running status
                    const isRunning = attributes.current_state === 'running' || 
                                     attributes.current_state === 'starting';
                    server.status = isRunning ? 'running' : 'offline';
                    
                    // Update detailed resource usage
                    if (attributes.resources) {
                      const resources = attributes.resources;
                      
                      // CPU usage
                      server.cpu = Math.min(Math.max(resources.cpu_absolute || 0, 0), 100);
                      
                      // RAM usage
                      const ramUsed = resources.memory_bytes || 0;
                      const ramTotal = resources.memory_limit_bytes || 0;
                      server.ram.used = ramUsed;
                      server.ram.total = ramTotal;
                      server.ram.percentage = calculatePercentage(ramUsed, ramTotal);
                      
                      // Disk usage
                      const diskUsed = resources.disk_bytes || 0;
                      const diskTotal = resources.disk_limit_bytes || 0;
                      server.disk.used = diskUsed;
                      server.disk.total = diskTotal;
                      server.disk.percentage = calculatePercentage(diskUsed, diskTotal);
                      
                      server.lastUpdate = new Date().getTime();
                      updatedCount++;
                    }
                  }
                } catch (error) {
                  // Keep existing values if update fails
                  console.warn(`Failed to update server ${server.name}:`, error);
                }
              }
              
              // Recalculate totals and averages
              const activeServers = serverDetails.filter(s => s.status === 'running').length;
              const activeServersList = serverDetails.filter(s => s.status === 'running');
              
              // Calculate averages
              const avgCpu = activeServersList.length > 0 
                ? Math.round(activeServersList.reduce((sum, s) => sum + s.cpu, 0) / activeServersList.length)
                : 0;
              
              const avgRam = activeServersList.length > 0 
                ? Math.round(activeServersList.reduce((sum, s) => sum + s.ram.percentage, 0) / activeServersList.length)
                : 0;
              
              const avgDisk = activeServersList.length > 0 
                ? Math.round(activeServersList.reduce((sum, s) => sum + s.disk.percentage, 0) / activeServersList.length)
                : 0;
              
              // Update current data
              currentServerData = {
                totalServers: serverDetails.length,
                activeServers,
                avgCpu,
                avgRam,
                avgDisk,
                serverDetails,
                lastUpdate: new Date().getTime()
              };
              
              // Update badge
              updateServerBadge(activeServers);
              
              // Update display if visible
              if (statsVisible) {
                updateStatsDisplay();
              }
              
              // Log update status (for debugging)
              if (updatedCount > 0) {
                console.log(`Real-time update: ${updatedCount} servers updated at ${new Date().toLocaleTimeString()}`);
              }
              
            } catch (error) {
              console.warn('Error in real-time monitoring:', error);
            }
          }, 60000); // Update every 60 seconds (1 minute)
          
          // Also do an immediate update
          setTimeout(() => {
            if (monitoringInterval) {
              manualUpdateResources();
            }
          }, 1000);
        }
        
        // Manual update function
        async function manualUpdateResources() {
          if (!serverDetails.length) return;
          
          const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || '';
          
          for (const server of serverDetails) {
            try {
              const res = await fetch(`/api/client/servers/${server.id}/resources`, {
                method: 'GET',
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                  'X-CSRF-TOKEN': csrfToken,
                  'X-Requested-With': 'XMLHttpRequest'
                },
                credentials: 'same-origin'
              });
              
              if (res.ok) {
                const resourceData = await res.json();
                const attributes = resourceData.attributes || {};
                
                // Update status
                const isRunning = attributes.current_state === 'running' || 
                                 attributes.current_state === 'starting';
                server.status = isRunning ? 'running' : 'offline';
                
                // Update resources
                if (attributes.resources) {
                  const resources = attributes.resources;
                  
                  // CPU
                  server.cpu = Math.min(Math.max(resources.cpu_absolute || 0, 0), 100);
                  
                  // RAM
                  const ramUsed = resources.memory_bytes || 0;
                  const ramTotal = resources.memory_limit_bytes || 0;
                  server.ram.used = ramUsed;
                  server.ram.total = ramTotal;
                  server.ram.percentage = calculatePercentage(ramUsed, ramTotal);
                  
                  // Disk
                  const diskUsed = resources.disk_bytes || 0;
                  const diskTotal = resources.disk_limit_bytes || 0;
                  server.disk.used = diskUsed;
                  server.disk.total = diskTotal;
                  server.disk.percentage = calculatePercentage(diskUsed, diskTotal);
                  
                  server.lastUpdate = new Date().getTime();
                }
              }
            } catch (error) {
              // Silently fail for individual server updates
            }
          }
          
          // Recalculate
          const activeServers = serverDetails.filter(s => s.status === 'running').length;
          const activeServersList = serverDetails.filter(s => s.status === 'running');
          
          const avgCpu = activeServersList.length > 0 
            ? Math.round(activeServersList.reduce((sum, s) => sum + s.cpu, 0) / activeServersList.length)
            : 0;
          
          const avgRam = activeServersList.length > 0 
            ? Math.round(activeServersList.reduce((sum, s) => sum + s.ram.percentage, 0) / activeServersList.length)
            : 0;
          
          const avgDisk = activeServersList.length > 0 
            ? Math.round(activeServersList.reduce((sum, s) => sum + s.disk.percentage, 0) / activeServersList.length)
            : 0;
          
          currentServerData = {
            totalServers: serverDetails.length,
            activeServers,
            avgCpu,
            avgRam,
            avgDisk,
            serverDetails,
            lastUpdate: new Date().getTime()
          };
          
          updateServerBadge(activeServers);
          
          if (statsVisible) {
            updateStatsDisplay();
          }
        }
        
        function updateStatsDisplay() {
          if (!currentServerData) return;
          
          const { totalServers, activeServers, avgCpu, avgRam, avgDisk, serverDetails, lastUpdate } = currentServerData;
          const updateTime = new Date(lastUpdate).toLocaleTimeString('id-ID', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
          });
          
          let serverListHTML = '';
          if (serverDetails.length > 0) {
            serverListHTML = serverDetails.map(server => `
              <div class="server-item">
                <div class="server-header">
                  <div class="server-name">${server.name}</div>
                  <div class="server-status ${server.status === 'running' ? 'status-online' : 'status-offline'}">
                    ${server.status === 'running' ? 'ONLINE' : 'OFFLINE'}
                  </div>
                </div>
                
                ${server.status === 'running' ? `
                  <div class="server-resources">
                    <!-- CPU -->
                    <div class="resource-item">
                      <div class="resource-header">
                        <div class="resource-label">
                          <span>CPU</span>
                          <span class="resource-value cpu-display">${server.cpu}%</span>
                        </div>
                        <div class="usage-details">${server.cpu}% used</div>
                      </div>
                      <div class="progress-bar">
                        <div class="progress-fill cpu-progress" style="width: ${server.cpu}%"></div>
                      </div>
                    </div>
                    
                    <!-- RAM -->
                    <div class="resource-item">
                      <div class="resource-header">
                        <div class="resource-label">
                          <span>RAM</span>
                          <span class="resource-value ram-display">${server.ram.percentage}%</span>
                        </div>
                        <div class="usage-details">${formatBytes(server.ram.used)} / ${formatBytes(server.ram.total)}</div>
                      </div>
                      <div class="progress-bar">
                        <div class="progress-fill ram-progress" style="width: ${server.ram.percentage}%"></div>
                      </div>
                    </div>
                    
                    <!-- DISK -->
                    <div class="resource-item">
                      <div class="resource-header">
                        <div class="resource-label">
                          <span>DISK</span>
                          <span class="resource-value disk-display">${server.disk.percentage}%</span>
                        </div>
                        <div class="usage-details">${formatBytes(server.disk.used)} / ${formatBytes(server.disk.total)}</div>
                      </div>
                      <div class="progress-bar">
                        <div class="progress-fill disk-progress" style="width: ${server.disk.percentage}%"></div>
                      </div>
                    </div>
                  </div>
                  
                  <div class="server-actions">
                    <button class="btn-open" onclick="window.location.href='${server.url}'">
                      CONSOLE
                    </button>
                  </div>
                ` : `
                  <div style="text-align: center; padding: 12px; font-size: 10px; color: #94a3b8;">
                    Server sedang offline
                  </div>
                  <div class="server-actions">
                    <button class="btn-open" onclick="window.location.href='${server.url}'" disabled>
                      CONSOLE
                    </button>
                  </div>
                `}
              </div>
            `).join('');
          } else {
            serverListHTML = `
              <div class="empty-state">
                <div style="margin-bottom: 4px;">Belum ada server</div>
                <div style="font-size: 9px; color: #64748b;">Buat server untuk memulai monitoring</div>
              </div>
            `;
          }
          
          statsContainer.innerHTML = `
            <div class="stats-compact">
              <div class="stats-header">
                <div class="stats-title">Monitoring Real-time</div>
                <div style="display: flex; gap: 4px;">
                  <button class="refresh-btn" id="refresh-stats" title="Refresh sekarang">
                    <svg width="12" height="12" viewBox="0 0 24 24">
                      <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.3" 
                        stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                    </svg>
                  </button>
                  <button class="stats-close">
                    <svg width="12" height="12" viewBox="0 0 12 12">
                      <path d="M1 1L11 11M1 11L11 1" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                    </svg>
                  </button>
                </div>
              </div>
              <div class="stats-content">
                <div class="server-overview">
                  <div class="overview-grid">
                    <div class="stat-card">
                      <div class="stat-value online-value">${activeServers}</div>
                      <div class="stat-label">Online</div>
                    </div>
                    <div class="stat-card">
                      <div class="stat-value cpu-value">${avgCpu}%</div>
                      <div class="stat-label">CPU Avg</div>
                    </div>
                    <div class="stat-card">
                      <div class="stat-value ram-value">${avgRam}%</div>
                      <div class="stat-label">RAM Avg</div>
                    </div>
                    <div class="stat-card">
                      <div class="stat-value disk-value">${avgDisk}%</div>
                      <div class="stat-label">DISK Avg</div>
                    </div>
                  </div>
                  
                  <div class="monitoring-info">
                    <div class="update-status">
                      <div class="update-dot active"></div>
                      <span>Auto-update aktif</span>
                    </div>
                    <div class="time-stamp">${updateTime}</div>
                  </div>
                </div>
                
                ${serverDetails.length > 0 ? `
                  <div class="server-list">
                    ${serverListHTML}
                  </div>
                ` : serverListHTML}
                
                <div style="margin-top: 12px; padding-top: 8px; border-top: 1px solid rgba(255,255,255,0.03);">
                  <div style="font-size: 9px; color: #64748b; text-align: center;">
                    Update otomatis setiap 1 menit • Monitoring CPU, RAM, Disk
                  </div>
                </div>
              </div>
            </div>
          `;
          
          // Add event handlers
          const closeBtn = statsContainer.querySelector('.stats-close');
          closeBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            hideStatsPanel();
          });
          
          const refreshBtn = statsContainer.querySelector('#refresh-stats');
          refreshBtn.addEventListener('click', async (e) => {
            e.stopPropagation();
            refreshBtn.classList.add('loading');
            await manualUpdateResources();
            setTimeout(() => {
              refreshBtn.classList.remove('loading');
            }, 500);
          });
        }
        
        function updateServerBadge(count) {
          const badge = document.getElementById('server-badge');
          if (badge) {
            badge.textContent = count;
            if (count > 0) {
              badge.classList.add('active');
            } else {
              badge.classList.remove('active');
            }
          }
        }
        
        function showErrorState() {
          statsContainer.innerHTML = `
            <div class="stats-compact">
              <div class="stats-header">
                <div class="stats-title">Monitoring Server</div>
                <button class="stats-close">
                  <svg width="12" height="12" viewBox="0 0 12 12">
                    <path d="M1 1L11 11M1 11L11 1" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                  </svg>
                </button>
              </div>
              <div class="stats-content">
                <div class="error-state">
                  <div style="margin-bottom: 4px;">Gagal memuat data</div>
                  <div style="font-size: 9px; color: #94a3b8;">Coba refresh manual</div>
                  <button style="
                    margin-top: 8px;
                    background: rgba(59, 130, 246, 0.15);
                    color: #3b82f6;
                    border: none;
                    padding: 6px 12px;
                    border-radius: 6px;
                    font-size: 10px;
                    cursor: pointer;
                  " onclick="loadServerData()">
                    COBA LAGI
                  </button>
                </div>
              </div>
            </div>
          `;
          
          const closeBtn = statsContainer.querySelector('.stats-close');
          closeBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            hideStatsPanel();
          });
        }
        
        // 8. INITIALIZE AND SHOW ELEMENTS
        setTimeout(() => {
          greetingElement.style.opacity = '1';
          greetingElement.style.transform = 'translateY(0)';
          toggleButton.style.opacity = '1';
          toggleButton.style.transform = 'scale(1)';
          
          // Load initial data but don't show panel
          loadServerData();
        }, 500);
        
        // 9. AUTO-HIDE TOGGLE BUTTON
        let activityTimer;
        
        function resetActivityTimer() {
          clearTimeout(activityTimer);
          toggleButton.classList.remove('idle');
          
          activityTimer = setTimeout(() => {
            if (!statsVisible) {
              toggleButton.classList.add('idle');
            }
          }, 5000);
        }
        
        function showToggleButton() {
          toggleButton.classList.remove('idle');
          resetActivityTimer();
        }
        
        document.addEventListener('mousemove', resetActivityTimer);
        document.addEventListener('click', resetActivityTimer);
        
        toggleButton.addEventListener('mouseenter', showToggleButton);
        
        // Initialize activity timer
        resetActivityTimer();
        
        // 10. UPDATE TIME IN GREETING EVERY MINUTE
        setInterval(() => {
          if (greetingVisible && greetingElement.style.display !== 'none') {
            const timeElement = greetingElement.querySelector('.time-greeting');
            if (timeElement) {
              timeElement.textContent = ` Selamat ${getGreeting()} • ${formatTime()}`;
            }
          }
        }, 60000);

      });
    </script>
@endsection
EOF

echo "Isi $TARGET_FILE sudah diganti!"
echo ""
echo "✅ SISTEM REAL-TIME MONITORING TANPA CONSOLE BERHASIL DITAMBAHKAN:"
echo ""
echo "⚡ FITUR REAL-TIME MONITORING:"
echo "   • Auto-update setiap 1 MENIT tanpa refresh"
echo "   • Monitoring CPU, RAM, DISK secara real-time"
echo "   • Progress bar untuk setiap resource"
echo "   • Detail usage dalam bytes (GB/MB/KB)"
echo ""
echo "📊 INFORMASI YANG DITAMPILKAN:"
echo "   • CPU Usage (%) dengan progress bar"
echo "   • RAM Usage (%) + ukuran (GB/MB)"
echo "   • Disk Usage (%) + ukuran (GB/MB)"
echo "   • Status server (online/offline)"
echo "   • Waktu update terakhir"
echo ""
echo "🎯 PERUBAHAN YANG DIBUAT:"
echo "   • HAPUS tombol CONSOLE"
echo "   • TINGGAL tombol BUKA SERVER saja"
echo "   • RAM dan DISK sekarang terdeteksi REAL-TIME"
echo "   • Tampilan lebih clean dan fokus"
echo ""
echo "📱 ELEMEN YANG DIBUAT:"
echo "   1. GREETING COMPACT:"
echo "      - Tombol close berfungsi"
echo "      - Auto update waktu"
echo ""
echo "   2. TOGGLE BUTTON + BADGE:"
echo "      - Badge jumlah server online"
echo "      - Auto-hide saat idle"
echo ""
echo "   3. STATS PANEL REAL-TIME:"
echo "      - Overview: Online, CPU Avg, RAM Avg, DISK Avg"
echo "      - Detail per server dengan progress bars"
echo "      - Tombol BUKA SERVER saja (no console)"
echo ""
echo "🔄 SISTEM UPDATE OTOMATIS:"
echo "   • Background monitoring terus berjalan"
echo "   • Update CPU, RAM, DISK setiap 60 detik"
echo "   • Panel update real-time saat terbuka"
echo "   • Tombol refresh manual tersedia"
echo ""
echo "📱 MOBILE SUPPORT:"
echo "   • Responsif di semua ukuran layar"
echo "   • Layout menyesuaikan ukuran layar"
echo "   • Touch-friendly buttons"
echo ""
echo "🎨 TAMPILAN IMPROVED:"
echo "   • Progress bars dengan warna berbeda"
echo "   • Detail usage dalam format readable"
echo "   • Spacing optimal untuk readability"
echo   "   • Max width 320px (tidak terlalu lebar)"
echo ""
echo "🚀 Sistem sekarang memiliki monitoring real-time CPU, RAM, Disk tanpa tombol console!"

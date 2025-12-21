#!/bin/bash

TARGET_FILE="/var/www/pterodactyl/resources/views/templates/base/core.blade.php"
BACKUP_FILE="${TARGET_FILE}.bak_$(date -u +"%Y-%m-%d-%H-%M-%S")"

echo "Mengganti isi $TARGET_FILE dengan sistem compact responsive..."

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
        let cpuInterval = null;
        
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
          
          /* Stats panel styles */
          #compact-stats {
            bottom: 98px;
            opacity: 0;
            transform: translateY(8px) scale(0.95);
            pointer-events: none;
            max-width: 280px;
            min-width: 240px;
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
            max-height: 300px;
            overflow-y: auto;
          }
          
          .server-overview {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 12px;
            padding-bottom: 10px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
          }
          
          .server-icon {
            width: 36px;
            height: 36px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 11px;
            flex-shrink: 0;
          }
          
          .server-numbers {
            flex: 1;
          }
          
          .online-total {
            display: flex;
            align-items: baseline;
            gap: 4px;
            margin-bottom: 2px;
          }
          
          .online-count {
            font-size: 18px;
            font-weight: 700;
            color: #10b981;
            line-height: 1;
          }
          
          .total-count {
            font-size: 12px;
            color: #94a3b8;
            font-weight: 500;
          }
          
          .server-status {
            font-size: 10px;
            color: #cbd5e1;
            display: flex;
            align-items: center;
            gap: 6px;
          }
          
          .cpu-monitor {
            margin-top: 4px;
          }
          
          .cpu-label {
            font-size: 9px;
            color: #94a3b8;
            margin-bottom: 2px;
            display: flex;
            justify-content: space-between;
          }
          
          .cpu-bar {
            height: 4px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 2px;
            overflow: hidden;
          }
          
          .cpu-fill {
            height: 100%;
            background: linear-gradient(90deg, #3b82f6, #8b5cf6);
            border-radius: 2px;
            transition: width 0.3s ease;
          }
          
          .cpu-value {
            font-size: 9px;
            color: #cbd5e1;
            font-weight: 500;
          }
          
          .server-list {
            margin-top: 8px;
          }
          
          .server-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 8px 0;
            border-bottom: 1px solid rgba(255, 255, 255, 0.03);
          }
          
          .server-item:last-child {
            border-bottom: none;
          }
          
          .server-info {
            flex: 1;
            min-width: 0;
            padding-right: 8px;
          }
          
          .server-name {
            font-size: 11px;
            color: #e2e8f0;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
          }
          
          .server-meta {
            display: flex;
            align-items: center;
            gap: 6px;
            margin-top: 2px;
          }
          
          .server-state {
            font-size: 9px;
            padding: 1px 6px;
            border-radius: 4px;
            font-weight: 500;
          }
          
          .state-online {
            background: rgba(16, 185, 129, 0.15);
            color: #10b981;
          }
          
          .state-offline {
            background: rgba(239, 68, 68, 0.15);
            color: #ef4444;
          }
          
          .server-cpu {
            font-size: 9px;
            color: #94a3b8;
            display: flex;
            align-items: center;
            gap: 3px;
          }
          
          .btn-open {
            background: rgba(59, 130, 246, 0.15);
            color: #3b82f6;
            border: none;
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 10px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
            white-space: nowrap;
            flex-shrink: 0;
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
            padding: 16px 12px;
            color: #94a3b8;
            font-size: 11px;
          }
          
          .error-state {
            text-align: center;
            padding: 16px 12px;
            color: #ef4444;
            font-size: 11px;
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
          loadServerData();
        }
        
        function hideStatsPanel() {
          statsVisible = false;
          statsContainer.classList.remove('visible');
          // Stop CPU monitoring when panel is closed
          if (cpuInterval) {
            clearInterval(cpuInterval);
            cpuInterval = null;
          }
        }
        
        // 6. LOAD SERVER DATA WITH REAL-TIME CPU
        async function loadServerData() {
          try {
            // Show loading state
            statsContainer.innerHTML = `
              <div class="stats-compact">
                <div class="stats-header">
                  <div class="stats-title">Status Server</div>
                  <button class="stats-close">
                    <svg width="12" height="12" viewBox="0 0 12 12">
                      <path d="M1 1L11 11M1 11L11 1" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                    </svg>
                  </button>
                </div>
                <div class="stats-content">
                  <div class="empty-state">
                    <div style="margin-bottom: 4px;">Memuat data...</div>
                    <div style="font-size: 9px; color: #64748b;">Mohon tunggu</div>
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
            let totalServers = 0;
            let activeServers = 0;
            let serverDetails = [];
            
            if (data.data && Array.isArray(data.data)) {
              servers = data.data;
              totalServers = servers.length;
              
              // Process each server
              const serverPromises = servers.map(async (server) => {
                const serverId = server.attributes?.identifier || server.id;
                const serverName = server.attributes?.name || 'Server';
                const serverIdentifier = server.attributes?.identifier;
                
                let isRunning = false;
                let cpuUsage = 0;
                
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
                    
                    // Get CPU usage from resources
                    if (attributes.resources) {
                      const cpuPercent = attributes.resources.cpu_absolute || 0;
                      cpuUsage = Math.min(Math.max(cpuPercent, 0), 100);
                    }
                  }
                } catch (error) {
                  console.warn('Error fetching server resources:', error);
                }
                
                if (isRunning) activeServers++;
                
                return {
                  id: serverId,
                  name: serverName,
                  identifier: serverIdentifier,
                  status: isRunning ? 'running' : 'offline',
                  cpu: cpuUsage,
                  url: serverIdentifier ? `/server/${serverIdentifier}` : `/server/${serverId}`
                };
              });
              
              serverDetails = await Promise.all(serverPromises);
            }
            
            // Update display
            updateStatsDisplay(totalServers, activeServers, serverDetails);
            
            // Start CPU monitoring
            startCpuMonitoring(serverDetails);
            
          } catch (error) {
            console.error('Error loading server data:', error);
            showErrorState();
          }
        }
        
        function updateStatsDisplay(totalServers, activeServers, serverDetails) {
          const statusPercentage = totalServers > 0 ? Math.round((activeServers / totalServers) * 100) : 0;
          
          // Determine color based on status
          let iconColor = 'linear-gradient(135deg, #10b981 0%, #059669 100%)';
          if (totalServers === 0) {
            iconColor = 'linear-gradient(135deg, #94a3b8 0%, #64748b 100%)';
          } else if (statusPercentage < 50) {
            iconColor = 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)';
          } else if (statusPercentage < 80) {
            iconColor = 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)';
          }
          
          // Calculate average CPU usage for active servers
          const activeServersList = serverDetails.filter(s => s.status === 'running');
          const avgCpu = activeServersList.length > 0 
            ? Math.round(activeServersList.reduce((sum, s) => sum + s.cpu, 0) / activeServersList.length)
            : 0;
          
          let serverListHTML = '';
          if (serverDetails.length > 0) {
            serverListHTML = serverDetails.map(server => `
              <div class="server-item">
                <div class="server-info">
                  <div class="server-name">${server.name}</div>
                  <div class="server-meta">
                    <span class="server-state ${server.status === 'running' ? 'state-online' : 'state-offline'}">
                      ${server.status === 'running' ? 'ONLINE' : 'OFFLINE'}
                    </span>
                    ${server.status === 'running' ? `
                      <span class="server-cpu">
                        <span>CPU:</span>
                        <span class="cpu-value">${server.cpu}%</span>
                      </span>
                    ` : ''}
                  </div>
                </div>
                <button class="btn-open" 
                  onclick="window.location.href='${server.url}'"
                  ${server.status !== 'running' ? 'disabled' : ''}>
                  BUKA
                </button>
              </div>
            `).join('');
          } else {
            serverListHTML = `
              <div class="empty-state">
                <div style="margin-bottom: 4px;">Belum ada server</div>
                <div style="font-size: 9px; color: #64748b;">Buat server untuk memulai</div>
              </div>
            `;
          }
          
          statsContainer.innerHTML = `
            <div class="stats-compact">
              <div class="stats-header">
                <div class="stats-title">Status Server</div>
                <button class="stats-close">
                  <svg width="12" height="12" viewBox="0 0 12 12">
                    <path d="M1 1L11 11M1 11L11 1" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                  </svg>
                </button>
              </div>
              <div class="stats-content">
                <div class="server-overview">
                  <div class="server-icon" style="background: ${iconColor};">
                    ${totalServers === 0 ? '0' : statusPercentage}
                  </div>
                  <div class="server-numbers">
                    <div class="online-total">
                      <span class="online-count">${activeServers}</span>
                      <span class="total-count">/${totalServers}</span>
                    </div>
                    <div class="server-status">
                      <span>${totalServers === 0 ? 'Tidak ada server' : `${activeServers} aktif`}</span>
                      <span style="color: #64748b; font-size: 9px;">${formatTime()}</span>
                    </div>
                    ${activeServers > 0 ? `
                      <div class="cpu-monitor">
                        <div class="cpu-label">
                          <span>CPU Rata-rata:</span>
                          <span class="cpu-value">${avgCpu}%</span>
                        </div>
                        <div class="cpu-bar">
                          <div class="cpu-fill" style="width: ${avgCpu}%"></div>
                        </div>
                      </div>
                    ` : ''}
                  </div>
                </div>
                
                ${serverDetails.length > 0 ? `
                  <div class="server-list">
                    ${serverListHTML}
                  </div>
                ` : serverListHTML}
              </div>
            </div>
          `;
          
          // Add close button handler
          const closeBtn = statsContainer.querySelector('.stats-close');
          closeBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            hideStatsPanel();
          });
        }
        
        function startCpuMonitoring(serverDetails) {
          // Clear any existing interval
          if (cpuInterval) {
            clearInterval(cpuInterval);
          }
          
          // Update CPU usage every 10 seconds
          cpuInterval = setInterval(async () => {
            if (!statsVisible) return;
            
            try {
              const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || '';
              const activeServers = serverDetails.filter(s => s.status === 'running');
              
              // Update CPU for each active server
              for (const server of activeServers) {
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
                    
                    if (attributes.resources) {
                      const cpuPercent = attributes.resources.cpu_absolute || 0;
                      server.cpu = Math.min(Math.max(cpuPercent, 0), 100);
                    }
                  }
                } catch (error) {
                  // Keep existing CPU value if update fails
                }
              }
              
              // Update display with new CPU values
              const totalServers = serverDetails.length;
              const activeCount = activeServers.length;
              const avgCpu = activeCount > 0 
                ? Math.round(activeServers.reduce((sum, s) => sum + s.cpu, 0) / activeCount)
                : 0;
              
              // Update CPU bar and value in display
              const cpuFill = statsContainer.querySelector('.cpu-fill');
              const cpuValue = statsContainer.querySelectorAll('.cpu-value');
              
              if (cpuFill) {
                cpuFill.style.width = `${avgCpu}%`;
              }
              
              if (cpuValue.length > 1) {
                cpuValue[0].textContent = `${avgCpu}%`;
              }
              
              // Update individual server CPU values
              const serverCpuElements = statsContainer.querySelectorAll('.server-cpu .cpu-value');
              serverCpuElements.forEach((element, index) => {
                if (activeServers[index]) {
                  element.textContent = `${activeServers[index].cpu}%`;
                }
              });
              
            } catch (error) {
              console.warn('Error updating CPU data:', error);
            }
          }, 10000); // Update every 10 seconds
        }
        
        function showErrorState() {
          statsContainer.innerHTML = `
            <div class="stats-compact">
              <div class="stats-header">
                <div class="stats-title">Status Server</div>
                <button class="stats-close">
                  <svg width="12" height="12" viewBox="0 0 12 12">
                    <path d="M1 1L11 11M1 11L11 1" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                  </svg>
                </button>
              </div>
              <div class="stats-content">
                <div class="error-state">
                  <div style="margin-bottom: 4px;">Gagal memuat data</div>
                  <div style="font-size: 9px; color: #94a3b8;">Coba refresh halaman</div>
                  <button style="
                    margin-top: 8px;
                    background: rgba(59, 130, 246, 0.15);
                    color: #3b82f6;
                    border: none;
                    padding: 6px 12px;
                    border-radius: 6px;
                    font-size: 10px;
                    cursor: pointer;
                  " onclick="location.reload()">
                    REFRESH
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
        
        // 7. INITIALIZE AND SHOW ELEMENTS
        setTimeout(() => {
          greetingElement.style.opacity = '1';
          greetingElement.style.transform = 'translateY(0)';
          toggleButton.style.opacity = '1';
          toggleButton.style.transform = 'scale(1)';
        }, 500);
        
        // 8. AUTO-HIDE TOGGLE BUTTON
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
        
        // 9. UPDATE TIME IN GREETING EVERY MINUTE
        setInterval(() => {
          if (greetingVisible && greetingElement.style.display !== 'none') {
            const timeElement = greetingElement.querySelector('.time-greeting');
            if (timeElement) {
              timeElement.textContent = `${getGreeting()} • ${formatTime()}`;
            }
          }
        }, 60000);
        
      });
    </script>
@endsection
EOF

echo "Isi $TARGET_FILE sudah diganti!"
echo ""
echo "✅ SISTEM COMPACT RESPONSIVE BERHASIL DITAMBAHKAN:"
echo ""
echo "🎯 FITUR UTAMA:"
echo "   • Ukuran sangat compact (tidak memakan tempat)"
echo "   • Tanpa emoji (clean dan profesional)"
echo "   • Real-time CPU monitoring"
echo "   • Support mobile responsive"
echo ""
echo "📱 ELEMEN YANG DIBUAT:"
echo "   1. GREETING COMPACT:"
echo "      - Ukuran kecil: 220px max"
echo "      - Tombol close berfungsi"
echo "      - Waktu update otomatis"
echo ""
echo "   2. TOGGLE BUTTON:"
echo "      - 36px diameter (sangat kecil)"
echo "      - Auto-hide setelah 5 detik idle"
echo "      - Muncul saat mouse hover"
echo ""
echo "   3. STATS PANEL:"
echo "      - Real-time CPU usage (update setiap 10 detik)"
echo "      - CPU bar visual dengan persentase"
echo "      - Tampilan sangat compact"
echo "      - Tombol close berfungsi"
echo ""
echo "⚡ REAL-TIME CPU FEATURES:"
echo "   • CPU rata-rata semua server aktif"
echo "   • CPU per server (ditampilkan di list)"
echo "   • Visual bar untuk CPU usage"
echo "   • Update otomatis setiap 10 detik"
echo ""
echo "📱 MOBILE SUPPORT:"
echo "   • Responsif di semua ukuran layar"
echo "   • Di mobile: elemen menyesuaikan ukuran layar"
echo "   • Padding dan spacing optimal untuk mobile"
echo ""
echo "🎨 UKURAN KOMPAK:"
echo "   • Greeting: max 220px (mobile: 100vw - 24px)"
echo "   • Stats panel: max 280px (mobile: 100vw - 16px)"
echo "   • Tombol: 36px (mobile: 32px)"
echo ""
echo "🖱️ INTERAKSI:"
echo "   • Klik ✕ greeting → greeting hilang"
echo "   • Klik toggle button → show/hide stats"
echo "   • Klik ✕ stats → stats hilang"
echo "   • Klik di luar stats → stats hilang"
echo "   • Klik BUKA → buka server"
echo ""
echo "🚀 Sistem sekarang sangat compact, responsive, dan berfungsi penuh!"

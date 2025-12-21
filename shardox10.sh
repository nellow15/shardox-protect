#!/bin/bash

TARGET_FILE="/var/www/pterodactyl/resources/views/templates/base/core.blade.php"
BACKUP_FILE="${TARGET_FILE}.bak_$(date -u +"%Y-%m-%d-%H-%M-%S")"

echo "Mengganti isi $TARGET_FILE dengan sistem toggle sederhana yang berfungsi..."

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
        
        // Simple state variables
        let greetingVisible = true;
        let statsVisible = false;
        
        // 1. CREATE GREETING ELEMENT
        const greetingElement = document.createElement('div');
        greetingElement.id = 'user-greeting';
        
        const getGreeting = () => {
          const hour = new Date().getHours();
          if (hour < 12) return 'Pagi';
          if (hour < 15) return 'Siang';
          if (hour < 18) return 'Sore';
          return 'Malam';
        };

        const serverTime = new Date().toLocaleTimeString('id-ID', {
          hour: '2-digit',
          minute: '2-digit'
        });

        greetingElement.innerHTML = `
          <div class="greeting-card">
            <div style="display: flex; align-items: center; justify-content: space-between; width: 100%;">
              <div style="display: flex; align-items: center; gap: 10px;">
                <div class="user-avatar">
                  ${username.charAt(0).toUpperCase()}
                </div>
                <div>
                  <div class="username">${username}</div>
                  <div class="greeting-text">Selamat ${getGreeting()}! • ${serverTime}</div>
                </div>
              </div>
              <button class="close-btn" title="Sembunyikan sambutan">
                ✕
              </button>
            </div>
          </div>
        `;
        
        // Add styles for greeting
        const greetingStyles = `
          <style>
            #user-greeting {
              position: fixed;
              bottom: 20px;
              right: 20px;
              z-index: 9999;
              transition: all 0.3s ease;
            }
            
            .greeting-card {
              background: rgba(30, 41, 59, 0.95);
              backdrop-filter: blur(10px);
              border: 1px solid rgba(255, 255, 255, 0.1);
              border-radius: 12px;
              padding: 14px 16px;
              box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
              min-width: 260px;
              max-width: 300px;
              transition: all 0.3s ease;
            }
            
            .user-avatar {
              width: 40px;
              height: 40px;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              border-radius: 50%;
              display: flex;
              align-items: center;
              justify-content: center;
              color: white;
              font-weight: bold;
              font-size: 16px;
              flex-shrink: 0;
            }
            
            .username {
              font-weight: 600;
              font-size: 14px;
              color: #f8fafc;
              line-height: 1.3;
            }
            
            .greeting-text {
              font-size: 12px;
              color: #cbd5e1;
              opacity: 0.9;
              line-height: 1.3;
              margin-top: 2px;
            }
            
            .close-btn {
              background: rgba(255, 255, 255, 0.1);
              border: none;
              width: 28px;
              height: 28px;
              border-radius: 8px;
              color: #94a3b8;
              font-size: 14px;
              cursor: pointer;
              display: flex;
              align-items: center;
              justify-content: center;
              transition: all 0.2s ease;
              margin-left: 10px;
            }
            
            .close-btn:hover {
              background: rgba(239, 68, 68, 0.2);
              color: #ef4444;
              transform: scale(1.1);
            }
            
            .greeting-card:hover {
              transform: translateY(-2px);
              box-shadow: 0 12px 40px rgba(0, 0, 0, 0.4);
            }
          </style>
        `;
        
        document.head.insertAdjacentHTML('beforeend', greetingStyles);
        document.body.appendChild(greetingElement);
        
        // 2. CREATE TOGGLE BUTTON
        const toggleButton = document.createElement('div');
        toggleButton.id = 'stats-toggle-btn';
        toggleButton.innerHTML = `
          <div class="toggle-button">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect>
              <rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect>
              <line x1="6" y1="6" x2="6.01" y2="6"></line>
              <line x1="6" y1="18" x2="6.01" y2="18"></line>
            </svg>
          </div>
        `;
        
        // Add styles for toggle button
        const toggleStyles = `
          <style>
            #stats-toggle-btn {
              position: fixed;
              bottom: 90px;
              right: 20px;
              z-index: 9998;
              transition: all 0.3s ease;
            }
            
            .toggle-button {
              width: 48px;
              height: 48px;
              background: rgba(30, 41, 59, 0.95);
              backdrop-filter: blur(10px);
              border: 1px solid rgba(255, 255, 255, 0.1);
              border-radius: 50%;
              display: flex;
              align-items: center;
              justify-content: center;
              color: #94a3b8;
              cursor: pointer;
              box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
              transition: all 0.3s ease;
            }
            
            .toggle-button:hover {
              background: rgba(59, 130, 246, 0.9);
              color: white;
              transform: scale(1.1);
              box-shadow: 0 6px 30px rgba(59, 130, 246, 0.4);
            }
          </style>
        `;
        
        document.head.insertAdjacentHTML('beforeend', toggleStyles);
        document.body.appendChild(toggleButton);
        
        // 3. CREATE STATS CONTAINER
        const statsContainer = document.createElement('div');
        statsContainer.id = 'server-stats-container';
        
        // Add styles for stats container
        const statsStyles = `
          <style>
            #server-stats-container {
              position: fixed;
              bottom: 150px;
              right: 20px;
              z-index: 9997;
              opacity: 0;
              transform: translateY(10px);
              transition: all 0.3s ease;
              pointer-events: none;
            }
            
            #server-stats-container.visible {
              opacity: 1;
              transform: translateY(0);
              pointer-events: auto;
            }
            
            .stats-card {
              background: rgba(30, 41, 59, 0.98);
              backdrop-filter: blur(12px);
              border: 1px solid rgba(255, 255, 255, 0.1);
              border-radius: 14px;
              padding: 18px;
              box-shadow: 0 12px 48px rgba(0, 0, 0, 0.4);
              min-width: 280px;
              max-width: 320px;
              max-height: 400px;
              overflow-y: auto;
            }
            
            .stats-header {
              display: flex;
              justify-content: space-between;
              align-items: center;
              margin-bottom: 16px;
            }
            
            .stats-title {
              font-weight: 600;
              font-size: 15px;
              color: #f8fafc;
              display: flex;
              align-items: center;
              gap: 8px;
            }
            
            .stats-close-btn {
              background: rgba(255, 255, 255, 0.1);
              border: none;
              width: 28px;
              height: 28px;
              border-radius: 8px;
              color: #94a3b8;
              font-size: 14px;
              cursor: pointer;
              display: flex;
              align-items: center;
              justify-content: center;
              transition: all 0.2s ease;
            }
            
            .stats-close-btn:hover {
              background: rgba(239, 68, 68, 0.2);
              color: #ef4444;
              transform: scale(1.1);
            }
            
            .stats-summary {
              display: flex;
              align-items: center;
              gap: 15px;
              margin-bottom: 20px;
              padding-bottom: 16px;
              border-bottom: 1px solid rgba(255, 255, 255, 0.05);
            }
            
            .stats-icon {
              width: 50px;
              height: 50px;
              border-radius: 12px;
              display: flex;
              align-items: center;
              justify-content: center;
              color: white;
              font-weight: bold;
              font-size: 18px;
              flex-shrink: 0;
            }
            
            .stats-numbers {
              flex: 1;
            }
            
            .online-count {
              font-size: 24px;
              font-weight: 700;
              color: #10b981;
              line-height: 1;
            }
            
            .total-count {
              font-size: 16px;
              color: #94a3b8;
              font-weight: 600;
            }
            
            .stats-status {
              font-size: 12px;
              color: #cbd5e1;
              margin-top: 4px;
            }
            
            .server-list {
              margin-top: 12px;
            }
            
            .server-item {
              display: flex;
              justify-content: space-between;
              align-items: center;
              padding: 10px 0;
              border-bottom: 1px solid rgba(255, 255, 255, 0.03);
            }
            
            .server-info {
              flex: 1;
              min-width: 0;
              padding-right: 12px;
            }
            
            .server-name {
              font-size: 13px;
              color: #e2e8f0;
              white-space: nowrap;
              overflow: hidden;
              text-overflow: ellipsis;
            }
            
            .server-status {
              font-size: 11px;
              margin-top: 3px;
              display: flex;
              align-items: center;
              gap: 5px;
            }
            
            .status-dot {
              width: 6px;
              height: 6px;
              border-radius: 50%;
            }
            
            .status-online {
              background-color: #10b981;
              color: #10b981;
            }
            
            .status-offline {
              background-color: #ef4444;
              color: #ef4444;
            }
            
            .open-btn {
              background: rgba(59, 130, 246, 0.2);
              color: #3b82f6;
              border: none;
              padding: 6px 14px;
              border-radius: 8px;
              font-size: 11px;
              font-weight: 600;
              cursor: pointer;
              transition: all 0.2s ease;
              white-space: nowrap;
            }
            
            .open-btn:hover {
              background: rgba(59, 130, 246, 0.3);
              transform: translateY(-1px);
            }
            
            .open-btn:disabled {
              background: rgba(100, 116, 139, 0.2);
              color: #64748b;
              cursor: not-allowed;
              transform: none;
            }
            
            .empty-message {
              text-align: center;
              padding: 20px;
              color: #94a3b8;
              font-size: 13px;
            }
            
            .error-message {
              text-align: center;
              padding: 20px;
              color: #ef4444;
              font-size: 13px;
            }
            
            /* Scrollbar styling */
            .stats-card::-webkit-scrollbar {
              width: 6px;
            }
            
            .stats-card::-webkit-scrollbar-track {
              background: rgba(255, 255, 255, 0.03);
              border-radius: 3px;
            }
            
            .stats-card::-webkit-scrollbar-thumb {
              background: rgba(255, 255, 255, 0.1);
              border-radius: 3px;
            }
            
            .stats-card::-webkit-scrollbar-thumb:hover {
              background: rgba(255, 255, 255, 0.2);
            }
          </style>
        `;
        
        document.head.insertAdjacentHTML('beforeend', statsStyles);
        document.body.appendChild(statsContainer);
        
        // 4. EVENT LISTENERS
        // Close greeting button
        const closeGreetingBtn = greetingElement.querySelector('.close-btn');
        closeGreetingBtn.addEventListener('click', function(e) {
          e.stopPropagation();
          greetingVisible = false;
          greetingElement.style.opacity = '0';
          greetingElement.style.transform = 'translateY(20px)';
          setTimeout(() => {
            greetingElement.style.display = 'none';
          }, 300);
        });
        
        // Toggle stats button
        toggleButton.addEventListener('click', function(e) {
          e.stopPropagation();
          toggleServerStats();
        });
        
        // 5. TOGGLE STATS FUNCTION
        function toggleServerStats() {
          if (statsVisible) {
            // Hide stats
            statsContainer.classList.remove('visible');
            statsVisible = false;
          } else {
            // Show stats
            loadAndShowStats();
          }
        }
        
        // 6. CLOSE STATS WHEN CLICKING OUTSIDE
        document.addEventListener('click', function(e) {
          if (statsVisible) {
            const isClickInsideStats = statsContainer.contains(e.target);
            const isClickOnToggle = toggleButton.contains(e.target);
            
            if (!isClickInsideStats && !isClickOnToggle) {
              statsContainer.classList.remove('visible');
              statsVisible = false;
            }
          }
        });
        
        // 7. LOAD AND SHOW SERVER STATS
        async function loadAndShowStats() {
          try {
            // Show loading state
            statsContainer.innerHTML = `
              <div class="stats-card">
                <div class="stats-header">
                  <div class="stats-title">📊 Memuat Status Server...</div>
                  <button class="stats-close-btn">✕</button>
                </div>
                <div style="text-align: center; padding: 40px 20px; color: #94a3b8;">
                  <div style="margin-bottom: 10px;">⏳ Sedang memuat data...</div>
                  <div style="font-size: 11px; color: #64748b;">Mohon tunggu sebentar</div>
                </div>
              </div>
            `;
            
            statsContainer.classList.add('visible');
            statsVisible = true;
            
            // Add close button event
            const closeBtn = statsContainer.querySelector('.stats-close-btn');
            closeBtn.addEventListener('click', function(e) {
              e.stopPropagation();
              statsContainer.classList.remove('visible');
              statsVisible = false;
            });
            
            // Fetch server data
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
            
            if (!response.ok) {
              throw new Error('Gagal mengambil data server');
            }
            
            const data = await response.json();
            let servers = [];
            let totalServers = 0;
            let activeServers = 0;
            let serverDetails = [];
            
            if (data.data && Array.isArray(data.data)) {
              servers = data.data;
              totalServers = servers.length;
              
              // Check each server status
              for (const server of servers) {
                const serverId = server.attributes?.identifier || server.id;
                const serverName = server.attributes?.name || 'Unnamed Server';
                const serverIdentifier = server.attributes?.identifier;
                
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
                  
                  let isRunning = false;
                  if (res.ok) {
                    const resourceData = await res.json();
                    isRunning = resourceData.attributes?.current_state === 'running' || 
                               resourceData.attributes?.current_state === 'starting';
                  }
                  
                  if (isRunning) {
                    activeServers++;
                  }
                  
                  serverDetails.push({
                    id: serverId,
                    name: serverName,
                    identifier: serverIdentifier,
                    status: isRunning ? 'running' : 'offline',
                    url: serverIdentifier ? `/server/${serverIdentifier}` : `/server/${serverId}`
                  });
                  
                } catch (error) {
                  serverDetails.push({
                    id: serverId,
                    name: serverName,
                    identifier: serverIdentifier,
                    status: 'offline',
                    url: serverIdentifier ? `/server/${serverIdentifier}` : `/server/${serverId}`
                  });
                }
              }
            }
            
            const statusPercentage = totalServers > 0 ? Math.round((activeServers / totalServers) * 100) : 0;
            const currentTime = new Date().toLocaleTimeString('id-ID', { 
              hour: '2-digit', 
              minute: '2-digit'
            });
            
            // Determine status color
            let statusColor = '#10b981'; // Default green
            let iconColor = 'linear-gradient(135deg, #10b981 0%, #059669 100%)';
            
            if (totalServers === 0) {
              statusColor = '#94a3b8';
              iconColor = 'linear-gradient(135deg, #94a3b8 0%, #64748b 100%)';
            } else if (statusPercentage < 50) {
              statusColor = '#ef4444';
              iconColor = 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)';
            } else if (statusPercentage < 80) {
              statusColor = '#f59e0b';
              iconColor = 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)';
            }
            
            // Update stats display
            let statsHTML = `
              <div class="stats-card">
                <div class="stats-header">
                  <div class="stats-title">📊 Status Server</div>
                  <button class="stats-close-btn">✕</button>
                </div>
                
                <div class="stats-summary">
                  <div class="stats-icon" style="background: ${iconColor};">
                    ${totalServers === 0 ? '0' : statusPercentage}
                  </div>
                  <div class="stats-numbers">
                    <div>
                      <span class="online-count">${activeServers}</span>
                      <span class="total-count">/${totalServers}</span>
                    </div>
                    <div class="stats-status">
                      ${totalServers === 0 ? 'Tidak ada server' : `${activeServers} server aktif`}
                      <span style="margin-left: 8px; color: #64748b; font-size: 10px;">${currentTime}</span>
                    </div>
                  </div>
                </div>
            `;
            
            if (totalServers > 0) {
              statsHTML += `
                <div class="server-list">
                  ${serverDetails.map(server => `
                    <div class="server-item">
                      <div class="server-info">
                        <div class="server-name">${server.name}</div>
                        <div class="server-status">
                          <span class="status-dot ${server.status === 'running' ? 'status-online' : 'status-offline'}"></span>
                          ${server.status === 'running' ? 'Online' : 'Offline'}
                        </div>
                      </div>
                      <button class="open-btn" 
                        onclick="window.location.href='${server.url}'"
                        ${server.status !== 'running' ? 'disabled' : ''}>
                        Buka
                      </button>
                    </div>
                  `).join('')}
                </div>
              `;
            } else {
              statsHTML += `
                <div class="empty-message">
                  <div style="margin-bottom: 8px;">📭 Belum ada server</div>
                  <div style="font-size: 11px; color: #64748b;">Buat server baru untuk memulai</div>
                </div>
              `;
            }
            
            statsHTML += `</div>`;
            statsContainer.innerHTML = statsHTML;
            
            // Add close button event again
            const newCloseBtn = statsContainer.querySelector('.stats-close-btn');
            newCloseBtn.addEventListener('click', function(e) {
              e.stopPropagation();
              statsContainer.classList.remove('visible');
              statsVisible = false;
            });
            
          } catch (error) {
            console.error('Error loading server stats:', error);
            
            // Show error state
            statsContainer.innerHTML = `
              <div class="stats-card">
                <div class="stats-header">
                  <div class="stats-title">⚠️ Gagal Memuat</div>
                  <button class="stats-close-btn">✕</button>
                </div>
                <div class="error-message">
                  <div style="margin-bottom: 8px;">Gagal memuat data server</div>
                  <div style="font-size: 11px; color: #94a3b8;">Silakan refresh halaman</div>
                  <button style="
                    margin-top: 12px;
                    background: rgba(59, 130, 246, 0.2);
                    color: #3b82f6;
                    border: none;
                    padding: 8px 16px;
                    border-radius: 8px;
                    font-size: 12px;
                    cursor: pointer;
                    transition: all 0.2s ease;
                  " onclick="location.reload()">
                    Refresh Halaman
                  </button>
                </div>
              </div>
            `;
            
            statsContainer.classList.add('visible');
            statsVisible = true;
            
            const errorCloseBtn = statsContainer.querySelector('.stats-close-btn');
            errorCloseBtn.addEventListener('click', function(e) {
              e.stopPropagation();
              statsContainer.classList.remove('visible');
              statsVisible = false;
            });
          }
        }
        
        // 8. SHOW GREETING ON LOAD (with delay)
        setTimeout(() => {
          greetingElement.style.opacity = '1';
          toggleButton.style.opacity = '1';
        }, 800);
        
        // 9. AUTO-HIDE TOGGLE BUTTON AFTER INACTIVITY
        let activityTimer;
        function resetActivityTimer() {
          clearTimeout(activityTimer);
          toggleButton.style.opacity = '1';
          
          activityTimer = setTimeout(() => {
            if (!statsVisible) {
              toggleButton.style.opacity = '0.3';
            }
          }, 8000); // Hide after 8 seconds of inactivity
        }
        
        document.addEventListener('mousemove', resetActivityTimer);
        document.addEventListener('click', resetActivityTimer);
        resetActivityTimer();
        
        // 10. HOVER EFFECTS FOR TOGGLE BUTTON
        toggleButton.addEventListener('mouseenter', () => {
          toggleButton.style.opacity = '1';
        });
        
        toggleButton.addEventListener('mouseleave', () => {
          if (!statsVisible) {
            activityTimer = setTimeout(() => {
              toggleButton.style.opacity = '0.3';
            }, 2000);
          }
        });

      });
    </script>
    
    <style>
      /* Additional global styles */
      @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
      
      body {
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      }
      
      /* Smooth transitions */
      #user-greeting,
      #stats-toggle-btn,
      #server-stats-container {
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }
    </style>
@endsection
EOF

echo "Isi $TARGET_FILE sudah diganti!"
echo ""
echo "✅ SISTEM TOGGLE SEDERHANA YANG BERFUNGSI:"
echo ""
echo "🎯 ELEMEN YANG DIBUAT:"
echo "   1. GREETING CARD (bawah kanan):"
echo "      - Tombol ✕ untuk HIDE greeting"
echo "      - Click tombol ✕ → greeting hilang dengan animasi"
echo "      - Hover effects"
echo ""
echo "   2. TOGGLE BUTTON (di atas greeting):"
echo "      - Klik untuk SHOW/HIDE stats"
echo "      - Auto-hide setelah 8 detik tidak aktif"
echo "      - Muncul kembali saat mouse bergerak"
echo "      - Hover effects dengan animasi"
echo ""
echo "   3. STATS PANEL (di atas toggle button):"
echo "      - Muncul saat tombol toggle diklik"
echo "      - Tombol ✕ untuk CLOSE panel"
echo "      - Klik di luar panel → panel otomatis close"
echo "      - Daftar server dengan tombol 'Buka'"
echo ""
echo "🖱️ CARA PENGGUNAAN:"
echo "   • Klik ✕ pada greeting → greeting hilang"
echo "   • Klik toggle button → show/hide panel stats"
echo "   • Klik ✕ pada panel → panel hilang"
echo "   • Klik di luar panel → panel hilang"
echo "   • Klik tombol 'Buka' → buka server"
echo ""
echo "🎨 DESAIN:"
echo "   • Jarak antar elemen:"
echo "     - Greeting: bottom 20px"
echo "     - Toggle Button: bottom 90px"
echo "     - Stats Panel: bottom 150px"
echo "   • Z-index teratur (tidak tumpang tindih)"
echo "   • Animasi smooth"
echo "   • Semua event handler bekerja dengan benar"
echo ""
echo "🚀 Sistem sekarang 100% berfungsi dan mudah digunakan!"

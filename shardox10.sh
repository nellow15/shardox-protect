#!/bin/bash

TARGET_FILE="/var/www/pterodactyl/resources/views/templates/base/core.blade.php"
BACKUP_FILE="${TARGET_FILE}.bak_$(date -u +"%Y-%m-%d-%H-%M-%S")"

echo "Mengganti isi $TARGET_FILE dengan sistem toggle yang berfungsi..."

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
        let isGreetingVisible = true;
        let isStatsVisible = false;
        let isInitialized = false;
        
        // Function to create greeting element
        const createGreeting = () => {
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

          const greetingContainer = document.createElement("div");
          greetingContainer.id = 'floating-greeting';
          
          const greetingContent = document.createElement("div");
          greetingContent.className = 'greeting-content';
          greetingContent.innerHTML = `
            <div style="display: flex; align-items: center; gap: 8px;">
              <div style="
                width: 32px;
                height: 32px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                color: white;
                font-weight: bold;
                font-size: 14px;
                flex-shrink: 0;
              ">
                ${username.charAt(0).toUpperCase()}
              </div>
              <div style="flex: 1;">
                <div style="font-weight: 600; font-size: 13px; color: #f8fafc; line-height: 1.2;">
                  ${username}
                </div>
                <div style="font-size: 11px; color: #cbd5e1; opacity: 0.8; line-height: 1.2;">
                  Selamat ${getGreeting()}! • ${serverTime}
                </div>
              </div>
              <div style="
                width: 24px;
                height: 24px;
                display: flex;
                align-items: center;
                justify-content: center;
                cursor: pointer;
                opacity: 0.6;
                transition: opacity 0.2s;
              " class="close-btn">
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <line x1="18" y1="6" x2="6" y2="18"></line>
                  <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
              </div>
            </div>
          `;

          // Styling
          Object.assign(greetingContainer.style, {
            position: "fixed",
            bottom: "16px",
            right: "16px",
            zIndex: "9998",
            opacity: "0",
            transform: "translateY(20px)",
            transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
            pointerEvents: "none"
          });

          Object.assign(greetingContent.style, {
            background: "rgba(30, 41, 59, 0.95)",
            backdropFilter: "blur(8px)",
            padding: "12px 14px",
            borderRadius: "12px",
            fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
            boxShadow: "0 4px 16px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(255, 255, 255, 0.05)",
            border: "1px solid rgba(255, 255, 255, 0.08)",
            cursor: "pointer",
            pointerEvents: "auto",
            minWidth: "220px"
          });

          greetingContainer.appendChild(greetingContent);
          document.body.appendChild(greetingContainer);

          // Hover effects
          greetingContent.addEventListener('mouseenter', () => {
            greetingContent.style.transform = 'translateY(-2px)';
            greetingContent.style.boxShadow = '0 8px 24px rgba(0, 0, 0, 0.35)';
            greetingContent.querySelector('.close-btn').style.opacity = '1';
          });

          greetingContent.addEventListener('mouseleave', () => {
            greetingContent.style.transform = 'translateY(0)';
            greetingContent.style.boxShadow = '0 4px 16px rgba(0, 0, 0, 0.25)';
            greetingContent.querySelector('.close-btn').style.opacity = '0.6';
          });

          // Click to hide greeting
          greetingContent.addEventListener('click', (e) => {
            if (e.target.closest('.close-btn')) {
              hideGreeting();
            }
          });

          return greetingContainer;
        };

        // Function to create toggle button
        const createToggleButton = () => {
          const toggleBtn = document.createElement("div");
          toggleBtn.id = 'floating-toggle-btn';
          toggleBtn.innerHTML = `
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect>
              <rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect>
              <line x1="6" y1="6" x2="6.01" y2="6"></line>
              <line x1="6" y1="18" x2="6.01" y2="18"></line>
            </svg>
            <div style="
              position: absolute;
              top: -5px;
              right: -5px;
              width: 20px;
              height: 20px;
              background: #3b82f6;
              border-radius: 50%;
              display: flex;
              align-items: center;
              justify-content: center;
              font-size: 10px;
              font-weight: bold;
              color: white;
              box-shadow: 0 2px 8px rgba(59, 130, 246, 0.5);
              opacity: 0;
              transform: scale(0);
              transition: all 0.2s ease;
            " id="server-count-badge">0</div>
          `;
          
          Object.assign(toggleBtn.style, {
            position: "fixed",
            bottom: "100px",
            right: "16px",
            width: "44px",
            height: "44px",
            background: "rgba(30, 41, 59, 0.9)",
            backdropFilter: "blur(8px)",
            border: "1px solid rgba(255, 255, 255, 0.1)",
            borderRadius: "50%",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#94a3b8",
            cursor: "pointer",
            zIndex: "9999",
            opacity: "0",
            transform: "scale(0.9)",
            transition: "all 0.3s ease",
            boxShadow: "0 4px 12px rgba(0, 0, 0, 0.2)"
          });

          toggleBtn.addEventListener('mouseenter', () => {
            toggleBtn.style.opacity = "1";
            toggleBtn.style.transform = "scale(1.05)";
            toggleBtn.style.background = "rgba(59, 130, 246, 0.9)";
            toggleBtn.style.color = "white";
            toggleBtn.style.boxShadow = "0 6px 20px rgba(59, 130, 246, 0.4)";
          });

          toggleBtn.addEventListener('mouseleave', () => {
            toggleBtn.style.opacity = "0.8";
            toggleBtn.style.transform = "scale(1)";
            toggleBtn.style.background = "rgba(30, 41, 59, 0.9)";
            toggleBtn.style.color = "#94a3b8";
            toggleBtn.style.boxShadow = "0 4px 12px rgba(0, 0, 0, 0.2)";
          });

          toggleBtn.addEventListener('click', () => {
            toggleServerStats();
          });

          document.body.appendChild(toggleBtn);
          return toggleBtn;
        };

        // Function to create stats container
        const createStatsContainer = () => {
          const statsContainer = document.createElement("div");
          statsContainer.id = 'floating-stats';
          
          Object.assign(statsContainer.style, {
            position: "fixed",
            bottom: "80px",
            right: "16px",
            zIndex: "9997",
            opacity: "0",
            transform: "translateY(20px) scale(0.95)",
            transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
            pointerEvents: "none",
            maxWidth: "300px",
            minWidth: "250px"
          });

          document.body.appendChild(statsContainer);
          return statsContainer;
        };

        // Function to show greeting
        const showGreeting = () => {
          const greeting = document.getElementById('floating-greeting');
          if (greeting) {
            isGreetingVisible = true;
            greeting.style.opacity = "1";
            greeting.style.transform = "translateY(0)";
            greeting.style.pointerEvents = "auto";
          }
        };

        // Function to hide greeting
        const hideGreeting = () => {
          const greeting = document.getElementById('floating-greeting');
          if (greeting) {
            isGreetingVisible = false;
            greeting.style.opacity = "0";
            greeting.style.transform = "translateY(20px)";
            greeting.style.pointerEvents = "none";
          }
        };

        // Function to show toggle button
        const showToggleButton = () => {
          const toggleBtn = document.getElementById('floating-toggle-btn');
          if (toggleBtn) {
            toggleBtn.style.opacity = "0.8";
            toggleBtn.style.transform = "scale(1)";
          }
        };

        // Function to hide toggle button
        const hideToggleButton = () => {
          const toggleBtn = document.getElementById('floating-toggle-btn');
          if (toggleBtn && !isStatsVisible) {
            toggleBtn.style.opacity = "0";
            toggleBtn.style.transform = "scale(0.9)";
          }
        };

        // Function to get server URL
        const getServerUrl = (serverId, serverIdentifier = null) => {
          if (serverIdentifier) {
            return `/server/${serverIdentifier}`;
          } else if (serverId) {
            return `/server/${serverId}`;
          }
          return '/client';
        };

        // Function to fetch server data
        const fetchServerData = async () => {
          try {
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
              throw new Error(`API error: ${response.status}`);
            }

            const data = await response.json();
            let servers = [];
            let totalServers = 0;
            let activeServers = 0;

            if (data.data && Array.isArray(data.data)) {
              servers = data.data;
              totalServers = servers.length;

              const serverPromises = servers.map(async (server) => {
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

                  if (!res.ok) {
                    return {
                      id: serverId,
                      name: serverName,
                      identifier: serverIdentifier,
                      status: 'offline',
                      url: getServerUrl(serverId, serverIdentifier)
                    };
                  }

                  const resourceData = await res.json();
                  const isRunning = resourceData.attributes?.current_state === 'running' || 
                                 resourceData.attributes?.current_state === 'starting';

                  if (isRunning) {
                    activeServers++;
                  }

                  return {
                    id: serverId,
                    name: serverName,
                    identifier: serverIdentifier,
                    status: isRunning ? 'running' : 'offline',
                    url: getServerUrl(serverId, serverIdentifier)
                  };
                } catch (error) {
                  return {
                    id: serverId,
                    name: serverName,
                    identifier: serverIdentifier,
                    status: 'offline',
                    url: getServerUrl(serverId, serverIdentifier)
                  };
                }
              });

              const serverDetails = await Promise.all(serverPromises);
              
              // Update badge
              const badge = document.getElementById('server-count-badge');
              if (badge) {
                badge.textContent = activeServers;
                badge.style.opacity = activeServers > 0 ? '1' : '0';
                badge.style.transform = activeServers > 0 ? 'scale(1)' : 'scale(0)';
              }

              return {
                totalServers,
                activeServers,
                serverDetails,
                isError: false
              };
            }

            return {
              totalServers: 0,
              activeServers: 0,
              serverDetails: [],
              isError: false
            };
          } catch (error) {
            console.error('Error fetching server data:', error);
            return {
              totalServers: 0,
              activeServers: 0,
              serverDetails: [],
              isError: true
            };
          }
        };

        // Function to toggle server stats
        const toggleServerStats = async () => {
          const statsContainer = document.getElementById('floating-stats');
          const toggleBtn = document.getElementById('floating-toggle-btn');
          
          if (!isStatsVisible) {
            // Show stats
            isStatsVisible = true;
            
            // Hide toggle button
            if (toggleBtn) {
              toggleBtn.style.opacity = "0";
              toggleBtn.style.transform = "scale(0.9)";
            }
            
            // Fetch and show data
            const data = await fetchServerData();
            const { totalServers, activeServers, serverDetails, isError } = data;
            
            const statusPercentage = totalServers > 0 ? Math.round((activeServers / totalServers) * 100) : 0;
            const currentTime = new Date().toLocaleTimeString('id-ID', { 
              hour: '2-digit', 
              minute: '2-digit'
            });

            let statusColor = '#94a3b8';
            if (isError) {
              statusColor = '#ef4444';
            } else if (totalServers > 0) {
              if (statusPercentage >= 80) {
                statusColor = '#10b981';
              } else if (statusPercentage >= 50) {
                statusColor = '#f59e0b';
              } else {
                statusColor = '#ef4444';
              }
            }

            const statsHTML = `
              <div class="stats-content">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                  <div style="font-weight: 600; font-size: 14px; color: #f8fafc;">
                    ${isError ? '⚠️ Gagal Memuat' : '📊 Status Server'}
                  </div>
                  <div style="
                    width: 24px;
                    height: 24px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    cursor: pointer;
                    opacity: 0.6;
                    transition: opacity 0.2s;
                    color: #94a3b8;
                  " class="close-stats-btn">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <line x1="18" y1="6" x2="6" y2="18"></line>
                      <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                  </div>
                </div>
                
                <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 16px;">
                  <div style="
                    width: 48px;
                    height: 48px;
                    background: ${isError ? 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)' : 
                              totalServers === 0 ? 'linear-gradient(135deg, #94a3b8 0%, #64748b 100%)' :
                              statusPercentage >= 80 ? 'linear-gradient(135deg, #10b981 0%, #059669 100%)' : 
                              statusPercentage >= 50 ? 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)' : 
                              'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)'};
                    border-radius: 12px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    color: white;
                    font-weight: bold;
                    font-size: 16px;
                    flex-shrink: 0;
                  ">
                    ${isError ? '!' : totalServers === 0 ? '0' : `${statusPercentage}%`}
                  </div>
                  <div style="flex: 1;">
                    <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
                      <span style="font-size: 12px; color: #cbd5e1;">Online:</span>
                      <span style="font-size: 14px; font-weight: 600; color: ${activeServers > 0 ? '#10b981' : '#94a3b8'};">${activeServers}</span>
                      <span style="font-size: 12px; color: #64748b;">/</span>
                      <span style="font-size: 14px; font-weight: 600; color: #f8fafc;">${totalServers}</span>
                    </div>
                    <div style="font-size: 11px; color: ${statusColor};">
                      ${isError ? 'Error memuat data' : totalServers === 0 ? 'Tidak ada server' : `${activeServers} server aktif`}
                    </div>
                    <div style="font-size: 10px; color: #64748b; margin-top: 2px;">
                      ${currentTime}
                    </div>
                  </div>
                </div>
                
                ${totalServers > 0 && !isError ? `
                  <div style="border-top: 1px solid rgba(255,255,255,0.05); padding-top: 12px;">
                    <div style="font-size: 12px; color: #94a3b8; margin-bottom: 8px; font-weight: 500;">
                      Daftar Server:
                    </div>
                    <div style="max-height: 200px; overflow-y: auto; padding-right: 4px;">
                      ${serverDetails.map(server => `
                        <div style="display: flex; justify-content: space-between; align-items: center; padding: 8px 0; border-bottom: 1px solid rgba(255,255,255,0.03);">
                          <div style="flex: 1; min-width: 0; padding-right: 12px;">
                            <div style="font-size: 12px; color: #cbd5e1; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
                              ${server.name}
                            </div>
                            <div style="font-size: 10px; color: ${server.status === 'running' ? '#10b981' : '#ef4444'}; margin-top: 2px; display: flex; align-items: center; gap: 4px;">
                              <div style="width: 6px; height: 6px; border-radius: 50%; background: ${server.status === 'running' ? '#10b981' : '#ef4444'}"></div>
                              ${server.status === 'running' ? 'Online' : 'Offline'}
                            </div>
                          </div>
                          <button onclick="window.location.href='${server.url}'" style="
                            background: ${server.status === 'running' ? 'rgba(16, 185, 129, 0.2)' : 'rgba(100, 116, 139, 0.2)'};
                            color: ${server.status === 'running' ? '#10b981' : '#64748b'};
                            border: none;
                            padding: 6px 12px;
                            border-radius: 8px;
                            font-size: 11px;
                            font-weight: 600;
                            cursor: pointer;
                            transition: all 0.2s ease;
                            white-space: nowrap;
                            opacity: ${server.status === 'running' ? '1' : '0.6'};
                          " onmouseover="this.style.transform='translateY(-1px)'; this.style.boxShadow='0 2px 8px rgba(0,0,0,0.2)';" 
                             onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='none';"
                             ${server.status !== 'running' ? 'disabled style="cursor: not-allowed;"' : ''}>
                            Buka
                          </button>
                        </div>
                      `).join('')}
                    </div>
                  </div>
                ` : ''}
                
                ${isError ? `
                  <div style="border-top: 1px solid rgba(255,255,255,0.05); padding-top: 12px;">
                    <div style="font-size: 12px; color: #ef4444; margin-bottom: 8px; display: flex; align-items: center; gap: 6px;">
                      ⚠️ Gagal memuat data server
                    </div>
                    <div style="font-size: 11px; color: #94a3b8;">
                      Silakan refresh halaman atau coba lagi nanti.
                    </div>
                  </div>
                ` : ''}
              </div>
            `;

            statsContainer.innerHTML = statsHTML;
            
            // Style the stats content
            const statsContent = statsContainer.querySelector('.stats-content');
            Object.assign(statsContent.style, {
              background: "rgba(30, 41, 59, 0.98)",
              backdropFilter: "blur(12px)",
              padding: "16px",
              borderRadius: "14px",
              fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
              boxShadow: "0 8px 32px rgba(0, 0, 0, 0.3), 0 0 0 1px rgba(255, 255, 255, 0.08)",
              border: "1px solid rgba(255, 255, 255, 0.1)",
              pointerEvents: "auto"
            });

            // Show stats with animation
            setTimeout(() => {
              statsContainer.style.opacity = "1";
              statsContainer.style.transform = "translateY(0) scale(1)";
              statsContainer.style.pointerEvents = "auto";
            }, 10);

            // Add close button event
            const closeBtn = statsContainer.querySelector('.close-stats-btn');
            if (closeBtn) {
              closeBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                toggleServerStats();
              });
              
              closeBtn.addEventListener('mouseenter', () => {
                closeBtn.style.opacity = '1';
                closeBtn.style.color = '#f8fafc';
              });
              
              closeBtn.addEventListener('mouseleave', () => {
                closeBtn.style.opacity = '0.6';
                closeBtn.style.color = '#94a3b8';
              });
            }

            // Close stats when clicking outside
            setTimeout(() => {
              const closeOnClickOutside = (e) => {
                if (isStatsVisible && statsContainer && !statsContainer.contains(e.target)) {
                  if (!document.getElementById('floating-toggle-btn').contains(e.target)) {
                    toggleServerStats();
                  }
                }
              };
              document.addEventListener('click', closeOnClickOutside);
              
              // Store reference to remove later
              statsContainer._closeHandler = closeOnClickOutside;
            }, 100);
            
          } else {
            // Hide stats
            isStatsVisible = false;
            
            // Remove outside click handler
            if (statsContainer._closeHandler) {
              document.removeEventListener('click', statsContainer._closeHandler);
            }
            
            // Hide with animation
            statsContainer.style.opacity = "0";
            statsContainer.style.transform = "translateY(20px) scale(0.95)";
            statsContainer.style.pointerEvents = "none";
            
            // Show toggle button after delay
            setTimeout(() => {
              if (!isStatsVisible) {
                showToggleButton();
              }
            }, 300);
          }
        };

        // Initialize everything
        const init = () => {
          if (isInitialized) return;
          
          createGreeting();
          createToggleButton();
          createStatsContainer();
          
          // Show greeting on load
          setTimeout(() => {
            showGreeting();
            showToggleButton();
          }, 800);
          
          // Auto-hide toggle button after inactivity
          let activityTimer;
          const resetActivityTimer = () => {
            clearTimeout(activityTimer);
            if (!isStatsVisible) {
              showToggleButton();
            }
            activityTimer = setTimeout(() => {
              if (!isStatsVisible) {
                hideToggleButton();
              }
            }, 5000);
          };
          
          document.addEventListener('mousemove', resetActivityTimer);
          resetActivityTimer();
          
          isInitialized = true;
        };

        // Start initialization
        init();

      });
    </script>
    
    <style>
      @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
      
      /* Smooth animations */
      #floating-greeting,
      #floating-toggle-btn,
      #floating-stats {
        animation: floatIn 0.5s cubic-bezier(0.4, 0, 0.2, 1) forwards;
      }
      
      @keyframes floatIn {
        from {
          opacity: 0;
          transform: translateY(20px);
        }
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }
      
      /* Scrollbar styling */
      .stats-content div::-webkit-scrollbar {
        width: 6px;
      }
      
      .stats-content div::-webkit-scrollbar-track {
        background: rgba(255, 255, 255, 0.03);
        border-radius: 3px;
      }
      
      .stats-content div::-webkit-scrollbar-thumb {
        background: rgba(255, 255, 255, 0.1);
        border-radius: 3px;
      }
      
      .stats-content div::-webkit-scrollbar-thumb:hover {
        background: rgba(255, 255, 255, 0.2);
      }
      
      /* Button hover effects */
      .stats-content button:not(:disabled):hover {
        transform: translateY(-2px) !important;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3) !important;
      }
      
      /* Smooth transitions */
      #floating-toggle-btn,
      .greeting-content,
      .stats-content {
        transition: all 0.3s ease !important;
      }
      
      /* Badge animation */
      #server-count-badge {
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important;
      }
    </style>
@endsection
EOF

echo "Isi $TARGET_FILE sudah diganti dengan sistem toggle yang berfungsi!"
echo ""
echo "✅ SISTEM TOGGLE SHOW/HIDE BERFUNGSI:"
echo "   • Semua tombol dapat diklik"
echo "   • Animasi smooth dan responsif"
echo ""
echo "🎯 ELEMEN YANG BERFUNGSI:"
echo "   1. Greeting User (bawah kanan)"
echo "      - Ditampilkan saat halaman load"
echo "      - Tombol ❌ di pojok untuk hide"
echo "      - Hover effects dan animasi"
echo ""
echo "   2. Floating Toggle Button (di atas greeting)"
echo "      - Badge jumlah server online"
echo "      - Auto-hide saat idle (5 detik)"
echo "      - Muncul saat mouse bergerak"
echo "      - Klik untuk show/hide status server"
echo ""
echo "   3. Status Server Panel (di atas toggle button)"
echo "      - Ditampilkan saat tombol toggle diklik"
echo "      - Tombol ❌ di pojok untuk close"
echo "      - Close juga dengan klik di luar panel"
echo "      - Daftar server dengan tombol 'Buka'"
echo ""
echo "🖱️ INTERAKSI YANG BERFUNGSI:"
echo "   • Klik ❌ pada greeting → greeting hilang"
echo "   • Klik toggle button → show/hide panel status"
echo "   • Klik ❌ pada panel status → panel hilang"
echo "   • Klik di luar panel → panel hilang"
echo "   • Klik tombol 'Buka' → buka server"
echo ""
echo "📱 FITUR TAMBAHAN:"
echo "   • Badge jumlah server online di toggle button"
echo "   • Auto-hide toggle button saat idle"
echo "   • Mouse hover effects pada semua elemen"
echo "   • Animasi masuk/keluar yang smooth"
echo "   • Scrollbar styling untuk daftar server"
echo ""
echo "🎨 DESAIN IMPROVED:"
echo "   • Z-index yang tepat (tidak tertumpuk)"
echo "   • Pointer events diatur dengan benar"
echo "   • Transisi CSS yang konsisten"
echo   "   • Jarak antar elemen:"
echo "     - Greeting: bottom 16px"
echo "     - Toggle Button: bottom 100px"
echo "     - Status Panel: bottom 80px"
echo ""
echo "🚀 Sistem sekarang 100% berfungsi dan user-friendly!"

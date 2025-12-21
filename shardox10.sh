#!/bin/bash

TARGET_FILE="/var/www/pterodactyl/resources/views/templates/base/core.blade.php"
BACKUP_FILE="${TARGET_FILE}.bak_$(date -u +"%Y-%m-%d-%H-%M-%S")"

echo "Mengganti isi $TARGET_FILE dengan sistem toggle show/hide..."

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
        
        // Data untuk penyimpanan state
        let serverStatsVisible = false;
        let greetingVisible = false;
        let floatingButtonVisible = false;
        
        // Function to create compact greeting
        const createCompactGreeting = () => {
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
          greetingContainer.className = 'floating-greeting-container';
          
          // Container untuk konten greeting
          const content = document.createElement("div");
          content.className = 'greeting-content';
          content.innerHTML = `
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
            </div>
          `;

          Object.assign(content.style, {
            background: "rgba(30, 41, 59, 0.95)",
            backdropFilter: "blur(8px)",
            padding: "10px 14px",
            borderRadius: "12px",
            fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
            fontSize: "12px",
            boxShadow: "0 4px 16px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(255, 255, 255, 0.05)",
            border: "1px solid rgba(255, 255, 255, 0.08)",
            cursor: "pointer",
            transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)"
          });

          greetingContainer.appendChild(content);
          
          Object.assign(greetingContainer.style, {
            position: "fixed",
            bottom: "16px",
            right: "16px",
            zIndex: "9998",
            opacity: "0",
            transform: "translateY(20px)",
            transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)"
          });

          document.body.appendChild(greetingContainer);

          // Hover effects
          content.addEventListener('mouseenter', () => {
            content.style.transform = 'translateY(-2px)';
            content.style.boxShadow = '0 8px 24px rgba(0, 0, 0, 0.35)';
          });

          content.addEventListener('mouseleave', () => {
            content.style.transform = 'translateY(0)';
            content.style.boxShadow = '0 4px 16px rgba(0, 0, 0, 0.25)';
          });

          // Toggle greeting visibility
          content.addEventListener('click', () => {
            greetingVisible = !greetingVisible;
            if (!greetingVisible) {
              greetingContainer.style.opacity = "0";
              greetingContainer.style.transform = "translateY(20px)";
            }
            // Jika greeting disembunyikan, sembunyikan juga stats jika visible
            if (!greetingVisible && serverStatsVisible) {
              toggleServerStats();
            }
          });

          return greetingContainer;
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

        // Function to check server status
        const checkServerStatus = () => {
          const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || '';
          
          fetch('/api/client', {
            method: 'GET',
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'X-CSRF-TOKEN': csrfToken,
              'X-Requested-With': 'XMLHttpRequest'
            },
            credentials: 'same-origin'
          })
          .then(response => {
            if (!response.ok) {
              throw new Error(`API error: ${response.status}`);
            }
            return response.json();
          })
          .then(data => {
            let servers = [];
            let totalServers = 0;
            let activeServers = 0;
            
            if (data.data && Array.isArray(data.data)) {
              servers = data.data;
              totalServers = servers.length;
              
              const checkPromises = servers.map(server => {
                const serverId = server.attributes?.identifier || server.id;
                const serverUUID = server.attributes?.uuid || serverId;
                const serverName = server.attributes?.name || 'Unnamed Server';
                const serverIdentifier = server.attributes?.identifier;
                
                return fetch(`/api/client/servers/${serverId}/resources`, {
                  method: 'GET',
                  headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': csrfToken,
                    'X-Requested-With': 'XMLHttpRequest'
                  },
                  credentials: 'same-origin'
                })
                .then(res => {
                  if (!res.ok) {
                    return { status: 'offline' };
                  }
                  return res.json();
                })
                .then(resourceData => {
                  const isRunning = resourceData.attributes?.current_state === 'running' || 
                                   resourceData.attributes?.current_state === 'starting';
                  
                  if (isRunning) {
                    activeServers++;
                    return {
                      id: serverId,
                      uuid: serverUUID,
                      name: serverName,
                      identifier: serverIdentifier,
                      status: 'running',
                      url: getServerUrl(serverId, serverIdentifier)
                    };
                  }
                  
                  return {
                    id: serverId,
                    uuid: serverUUID,
                    name: serverName,
                    identifier: serverIdentifier,
                    status: 'offline',
                    url: getServerUrl(serverId, serverIdentifier)
                  };
                })
                .catch(() => {
                  return {
                    id: serverId,
                    uuid: serverUUID,
                    name: serverName,
                    identifier: serverIdentifier,
                    status: 'offline',
                    url: getServerUrl(serverId, serverIdentifier)
                  };
                });
              });
              
              return Promise.allSettled(checkPromises)
                .then(results => {
                  const serverDetails = results
                    .filter(result => result.status === 'fulfilled')
                    .map(result => result.value);
                  
                  activeServers = serverDetails.filter(server => server.status === 'running').length;
                  
                  return {
                    totalServers,
                    activeServers,
                    serverDetails
                  };
                });
            } else {
              return {
                totalServers: 0,
                activeServers: 0,
                serverDetails: []
              };
            }
          })
          .catch(error => {
            console.error('Error fetching server status:', error);
            
            const cachedData = localStorage.getItem('pterodactyl_server_cache');
            if (cachedData) {
              try {
                const parsedData = JSON.parse(cachedData);
                const now = new Date().getTime();
                const cacheAge = now - (parsedData.timestamp || 0);
                
                if (cacheAge < 300000) {
                  return {
                    totalServers: parsedData.totalServers || 0,
                    activeServers: parsedData.activeServers || 0,
                    serverDetails: parsedData.serverDetails || [],
                    isCached: true
                  };
                }
              } catch (e) {
                // Cache corrupted
              }
            }
            
            return {
              totalServers: 0,
              activeServers: 0,
              serverDetails: [],
              isError: true
            };
          });
        };

        // Function to create server stats container
        const createServerStatsContainer = () => {
          const statsContainer = document.createElement("div");
          statsContainer.className = 'floating-server-stats-container';
          
          Object.assign(statsContainer.style, {
            position: "fixed",
            bottom: "80px", // Jarak dari greeting
            right: "16px",
            zIndex: "9997",
            opacity: "0",
            transform: "translateY(20px)",
            transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
            maxWidth: "280px"
          });

          document.body.appendChild(statsContainer);
          return statsContainer;
        };

        // Function to show/hide server stats
        const toggleServerStats = async () => {
          const greetingEl = document.querySelector('.floating-greeting-container');
          const statsEl = document.querySelector('.floating-server-stats-container');
          
          if (!statsEl) return;
          
          if (!serverStatsVisible) {
            // Show server stats
            serverStatsVisible = true;
            
            // Load server data
            const data = await checkServerStatus();
            
            // Create stats content
            const { totalServers, activeServers, serverDetails, isCached = false, isError = false } = data;
            const offlineServers = totalServers - activeServers;
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
            
            const statsContent = document.createElement("div");
            statsContent.className = 'server-stats-content';
            
            statsContent.innerHTML = `
              <div style="display: flex; align-items: center; gap: 10px;">
                <div style="
                  width: 32px;
                  height: 32px;
                  background: ${isError ? 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)' : 
                            totalServers === 0 ? 'linear-gradient(135deg, #94a3b8 0%, #64748b 100%)' :
                            statusPercentage >= 80 ? 'linear-gradient(135deg, #10b981 0%, #059669 100%)' : 
                            statusPercentage >= 50 ? 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)' : 
                            'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)'};
                  border-radius: 10px;
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  color: white;
                  flex-shrink: 0;
                ">
                  ${isError ? '!' : 
                    totalServers === 0 ? '0' : 
                    `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect>
                      <rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect>
                      <line x1="6" y1="6" x2="6.01" y2="6"></line>
                      <line x1="6" y1="18" x2="6.01" y2="18"></line>
                    </svg>`}
                </div>
                <div style="flex: 1;">
                  <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
                    <div style="font-weight: 600; font-size: 13px; color: #f8fafc;">
                      ${isError ? 'Gagal Memuat' : 'Status Server'}
                    </div>
                    ${isCached ? `<div style="font-size: 9px; color: #f59e0b; font-weight: 500;">CACHE</div>` : ''}
                  </div>
                  <div style="display: flex; align-items: center; gap: 12px; font-size: 11px;">
                    <span style="color: #cbd5e1; background: rgba(255,255,255,0.05); padding: 2px 8px; border-radius: 10px;">
                      <span style="color: ${activeServers > 0 ? '#10b981' : '#94a3b8'};">${activeServers}</span>/
                      <span>${totalServers}</span>
                    </span>
                    <span style="color: ${statusColor};">${isError ? 'Error' : totalServers === 0 ? 'Tidak ada server' : `${statusPercentage}% online`}</span>
                  </div>
                  <div style="font-size: 9px; color: #64748b; margin-top: 4px;">
                    ${currentTime}${isCached ? ' • Cached' : ''}
                  </div>
                </div>
              </div>
              
              ${isError ? `
                <div style="margin-top: 10px; padding-top: 10px; border-top: 1px solid rgba(255,255,255,0.05);">
                  <div style="font-size: 11px; color: #ef4444; margin-bottom: 8px; display: flex; align-items: center; gap: 6px;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <circle cx="12" cy="12" r="10"></circle>
                      <line x1="12" y1="8" x2="12" y2="12"></line>
                      <line x1="12" y1="16" x2="12.01" y2="16"></line>
                    </svg>
                    Gagal memuat data server
                  </div>
                  <div style="font-size: 10px; color: #94a3b8;">
                    Coba refresh halaman atau periksa koneksi Anda.
                  </div>
                </div>
              ` : totalServers === 0 ? `
                <div style="margin-top: 10px; padding-top: 10px; border-top: 1px solid rgba(255,255,255,0.05);">
                  <div style="font-size: 11px; color: #94a3b8; margin-bottom: 8px;">
                    Anda belum memiliki server
                  </div>
                  <div style="font-size: 10px; color: #64748b;">
                    Buat server baru untuk memulai.
                  </div>
                </div>
              ` : `
                <div style="margin-top: 10px; padding-top: 10px; border-top: 1px solid rgba(255,255,255,0.05);">
                  <div style="font-size: 11px; color: #94a3b8; margin-bottom: 8px; font-weight: 500;">
                    Server Anda (${serverDetails.length}):
                  </div>
                  <div style="max-height: 150px; overflow-y: auto; padding-right: 4px;">
                    ${serverDetails.map(server => {
                      return `
                        <div style="display: flex; justify-content: space-between; align-items: center; padding: 6px 0; border-bottom: 1px solid rgba(255,255,255,0.03);">
                          <div style="flex: 1; min-width: 0; padding-right: 8px;">
                            <div style="font-size: 11px; color: #cbd5e1; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
                              ${server.name}
                            </div>
                            <div style="font-size: 9px; color: ${server.status === 'running' ? '#10b981' : '#ef4444'}; margin-top: 2px;">
                              ${server.status === 'running' ? '● Online' : '○ Offline'}
                            </div>
                          </div>
                          <div style="display: flex; align-items: center; gap: 6px;">
                            <button onclick="window.location.href='${server.url || getServerUrl(server.id, server.identifier)}'" style="
                              background: rgba(59, 130, 246, 0.2);
                              color: #3b82f6;
                              border: none;
                              padding: 5px 10px;
                              border-radius: 8px;
                              font-size: 10px;
                              font-weight: 600;
                              cursor: pointer;
                              transition: all 0.2s ease;
                              white-space: nowrap;
                              min-width: 50px;
                            " onmouseover="this.style.background='rgba(59, 130, 246, 0.3)'; this.style.transform='translateY(-1px)';" 
                               onmouseout="this.style.background='rgba(59, 130, 246, 0.2)'; this.style.transform='translateY(0)';">
                              Buka
                            </button>
                          </div>
                        </div>
                      `;
                    }).join('')}
                  </div>
                  
                  ${isCached ? `
                    <div style="font-size: 9px; color: #f59e0b; text-align: center; margin-top: 8px; padding: 4px; background: rgba(245, 158, 11, 0.1); border-radius: 6px;">
                      Data dari cache • Klik untuk refresh
                    </div>
                  ` : ''}
                </div>
              `}
            `;

            Object.assign(statsContent.style, {
              background: "rgba(30, 41, 59, 0.95)",
              backdropFilter: "blur(8px)",
              padding: "12px",
              borderRadius: "12px",
              fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
              fontSize: "12px",
              boxShadow: "0 4px 16px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(255, 255, 255, 0.05)",
              border: "1px solid rgba(255, 255, 255, 0.08)",
              cursor: "pointer",
              transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)"
            });

            // Hover effects
            statsContent.addEventListener('mouseenter', () => {
              statsContent.style.transform = 'translateY(-2px)';
              statsContent.style.boxShadow = '0 8px 24px rgba(0, 0, 0, 0.35)';
            });

            statsContent.addEventListener('mouseleave', () => {
              statsContent.style.transform = 'translateY(0)';
              statsContent.style.boxShadow = '0 4px 16px rgba(0, 0, 0, 0.25)';
            });

            // Click to close
            statsContent.addEventListener('click', (e) => {
              if (e.target.tagName === 'BUTTON' || e.target.closest('button')) {
                return;
              }
              toggleServerStats();
            });

            // Clear previous content and add new
            statsEl.innerHTML = '';
            statsEl.appendChild(statsContent);
            
            // Show with animation
            setTimeout(() => {
              statsEl.style.opacity = "1";
              statsEl.style.transform = "translateY(0)";
            }, 10);
            
            // Cache the data
            if (!isCached && !isError) {
              localStorage.setItem('pterodactyl_server_cache', JSON.stringify({
                totalServers,
                activeServers,
                serverDetails,
                timestamp: new Date().getTime()
              }));
            }
            
          } else {
            // Hide server stats
            serverStatsVisible = false;
            statsEl.style.opacity = "0";
            statsEl.style.transform = "translateY(20px)";
            setTimeout(() => {
              statsEl.innerHTML = '';
            }, 300);
          }
        };

        // Function to create floating toggle button
        const createFloatingToggleButton = () => {
          const toggleBtn = document.createElement("div");
          toggleBtn.className = 'floating-toggle-button';
          toggleBtn.innerHTML = `
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect>
              <rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect>
              <line x1="6" y1="6" x2="6.01" y2="6"></line>
              <line x1="6" y1="18" x2="6.01" y2="18"></line>
            </svg>
          `;
          
          Object.assign(toggleBtn.style, {
            position: "fixed",
            bottom: "140px", // Posisi lebih tinggi
            right: "16px",
            width: "40px",
            height: "40px",
            background: "rgba(30, 41, 59, 0.9)",
            backdropFilter: "blur(8px)",
            border: "1px solid rgba(255, 255, 255, 0.1)",
            borderRadius: "50%",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#94a3b8",
            cursor: "pointer",
            zIndex: "9996",
            opacity: "0.7",
            transition: "all 0.3s ease",
            boxShadow: "0 2px 8px rgba(0, 0, 0, 0.2)"
          });

          toggleBtn.addEventListener('mouseenter', () => {
            toggleBtn.style.opacity = "1";
            toggleBtn.style.transform = "scale(1.1)";
            toggleBtn.style.background = "rgba(59, 130, 246, 0.9)";
            toggleBtn.style.color = "white";
          });

          toggleBtn.addEventListener('mouseleave', () => {
            toggleBtn.style.opacity = "0.7";
            toggleBtn.style.transform = "scale(1)";
            toggleBtn.style.background = "rgba(30, 41, 59, 0.9)";
            toggleBtn.style.color = "#94a3b8";
          });

          toggleBtn.addEventListener('click', () => {
            toggleServerStats();
          });

          document.body.appendChild(toggleBtn);
          return toggleBtn;
        };

        // Initialize all components
        const greetingContainer = createCompactGreeting();
        const statsContainer = createServerStatsContainer();
        const toggleButton = createFloatingToggleButton();

        // Show greeting on load
        greetingVisible = true;
        setTimeout(() => {
          greetingContainer.style.opacity = "1";
          greetingContainer.style.transform = "translateY(0)";
        }, 500);

        // Toggle greeting visibility when clicking anywhere on greeting
        greetingContainer.addEventListener('click', (e) => {
          if (e.target.closest('.greeting-content')) {
            greetingVisible = !greetingVisible;
            if (greetingVisible) {
              greetingContainer.style.opacity = "1";
              greetingContainer.style.transform = "translateY(0)";
            } else {
              greetingContainer.style.opacity = "0";
              greetingContainer.style.transform = "translateY(20px)";
              // Also hide server stats if visible
              if (serverStatsVisible) {
                toggleServerStats();
              }
            }
          }
        });

        // Show toggle button on load
        floatingButtonVisible = true;
        setTimeout(() => {
          toggleButton.style.opacity = "0.7";
        }, 1000);

        // Hide toggle button when mouse is idle
        let mouseTimeout;
        document.addEventListener('mousemove', () => {
          toggleButton.style.opacity = "0.7";
          clearTimeout(mouseTimeout);
          mouseTimeout = setTimeout(() => {
            if (!serverStatsVisible) {
              toggleButton.style.opacity = "0";
            }
          }, 3000);
        });

      });
    </script>
    
    <style>
      @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
      
      /* Smooth transitions */
      .floating-greeting-container,
      .floating-server-stats-container,
      .floating-toggle-button {
        animation: fadeInUp 0.3s ease-out;
      }
      
      @keyframes fadeInUp {
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
      div::-webkit-scrollbar {
        width: 4px;
      }
      
      div::-webkit-scrollbar-track {
        background: rgba(255, 255, 255, 0.03);
        border-radius: 2px;
      }
      
      div::-webkit-scrollbar-thumb {
        background: rgba(255, 255, 255, 0.1);
        border-radius: 2px;
      }
      
      div::-webkit-scrollbar-thumb:hover {
        background: rgba(255, 255, 255, 0.2);
      }
      
      /* Button hover effects */
      .server-stats-content button:hover {
        transform: translateY(-1px) !important;
      }
    </style>
@endsection
EOF

echo "Isi $TARGET_FILE sudah diganti dengan sistem toggle!"
echo ""
echo "🔄 SISTEM TOGGLE SHOW/HIDE:"
echo "   • Tidak ada notifikasi otomatis"
echo "   • Semua elemen dapat dikontrol pengguna"
echo ""
echo "🎯 ELEMEN YANG TERSEDIA:"
echo "   1. Greeting User"
echo "      - Ditampilkan di pojok kanan bawah"
echo "      - Dapat diklik untuk show/hide"
echo "      - Memiliki jarak dengan status server"
echo ""
echo "   2. Floating Toggle Button"
echo "      - Ikon server di atas greeting"
echo "      - Diklik untuk show/hide status server"
echo "      - Auto-hide saat idle (muncul saat mouse bergerak)"
echo ""
echo "   3. Status Server Panel"
echo "      - Muncul di atas greeting (jarak: 80px)"
echo "      - Diklik untuk menutup (kecuali tombol 'Buka')"
echo "      - Menampilkan detail server dengan tombol 'Buka'"
echo ""
echo "📱 INTERAKSI PENGguna:"
echo "   • Klik greeting → toggle greeting visibility"
echo "   • Klik toggle button → show/hide status server"
echo "   • Klik panel status → close panel"
echo "   • Klik tombol 'Buka' → buka server"
echo ""
echo "🎨 JARAK ANTAR ELEMEN:"
echo "   • Toggle Button: bottom 140px"
echo "   • Status Server: bottom 80px"
echo "   • Greeting: bottom 16px"
echo ""
echo "✅ Sistem sekarang bersifat interaktif dan tidak mengganggu!"

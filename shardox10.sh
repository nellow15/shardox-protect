#!/bin/bash

TARGET_FILE="/var/www/pterodactyl/resources/views/templates/base/core.blade.php"
BACKUP_FILE="${TARGET_FILE}.bak_$(date -u +"%Y-%m-%d-%H-%M-%S")"

echo "Mengganti isi $TARGET_FILE dengan sistem real-time monitoring + welcome notify baru..."

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
        // Bersihkan username
        const username = String(@json(auth()->user()->name?? 'User')).trim();
        
        // State management
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
        
        // Fungsi untuk mendapatkan inisial
        const getInitials = (name) => {
          const cleanName = String(name || '').trim();
          if (!cleanName) return 'U';
          
          const nameWithoutExtraSpaces = cleanName.replace(/\s+/g, ' ');
          const words = nameWithoutExtraSpaces.split(' ');
          
          if (words.length === 1) {
            const word = words[0];
            if (word.length >= 2) {
              return word.substring(0, 2).toUpperCase();
            }
            return word.charAt(0).toUpperCase();
          }
          
          const firstWord = words[0];
          const secondWord = words[1];
          
          if (firstWord && secondWord) {
            return (firstWord.charAt(0) + secondWord.charAt(0)).toUpperCase();
          }
          
          return firstWord.charAt(0).toUpperCase();
        };
        
        // ============ WELCOME NOTIFY BARU - TENGAH ATAS ============
        // 1. CREATE TOP CENTER WELCOME NOTIFY
        const welcomeElement = document.createElement('div');
        welcomeElement.id = 'welcome-top-notify';
        let welcomeVisible = true;
        let welcomeTimeout = null;
        
        welcomeElement.innerHTML = `
          <div class="welcome-top">
            <div class="welcome-top-content">
              <div class="welcome-avatar">
                <div class="avatar-top-circle">
                  ${getInitials(username)}
                </div>
                <div class="online-top-dot"></div>
              </div>
              <div class="welcome-top-text">
                <div class="welcome-top-title">Selamat ${getGreeting()}!</div>
                <div class="welcome-top-subtitle">Halo, <span class="username-highlight">${username || 'User'}</span></div>
              </div>
              <button class="welcome-top-close" title="Tutup">
                <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
                  <path d="M10.5 3.5L3.5 10.5M3.5 3.5L10.5 10.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              </button>
            </div>
            <div class="welcome-top-progress"></div>
          </div>
        `;
        
        // ============ COMPACT TOGGLE BUTTON ============
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
          /* ============ WELCOME TOP NOTIFY STYLES ============ */
          #welcome-top-notify {
            position: fixed;
            top: 20px;
            left: 50%;
            transform: translateX(-50%) translateY(-20px);
            z-index: 99999;
            opacity: 0;
            transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            pointer-events: none;
            max-width: 400px;
            width: 90%;
          }
          
          #welcome-top-notify.visible {
            opacity: 1;
            transform: translateX(-50%) translateY(0);
            pointer-events: auto;
          }
          
          .welcome-top {
            background: rgba(30, 41, 59, 0.95);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 12px;
            box-shadow: 
              0 8px 32px rgba(0, 0, 0, 0.25),
              0 0 0 1px rgba(255, 255, 255, 0.05),
              inset 0 1px 0 rgba(255, 255, 255, 0.08);
            overflow: hidden;
          }
          
          .welcome-top-content {
            padding: 14px 16px;
            display: flex;
            align-items: center;
            gap: 12px;
            position: relative;
          }
          
          .welcome-avatar {
            position: relative;
            flex-shrink: 0;
          }
          
          .avatar-top-circle {
            width: 40px;
            height: 40px;
            background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 14px;
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
            position: relative;
            overflow: hidden;
          }
          
          .avatar-top-circle::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(45deg, transparent, rgba(255, 255, 255, 0.1), transparent);
            animation: shimmer 3s infinite;
          }
          
          @keyframes shimmer {
            0% { transform: translateX(-100%); }
            100% { transform: translateX(100%); }
          }
          
          .online-top-dot {
            position: absolute;
            bottom: 2px;
            right: 2px;
            width: 10px;
            height: 10px;
            background: linear-gradient(135deg, #10b981, #34d399);
            border-radius: 50%;
            border: 2px solid rgba(30, 41, 59, 0.95);
            box-shadow: 0 2px 4px rgba(16, 185, 129, 0.4);
          }
          
          .welcome-top-text {
            flex: 1;
            min-width: 0;
          }
          
          .welcome-top-title {
            font-size: 13px;
            color: #cbd5e1;
            font-weight: 500;
            margin-bottom: 2px;
            letter-spacing: 0.3px;
          }
          
          .welcome-top-subtitle {
            font-size: 15px;
            color: #f8fafc;
            font-weight: 600;
            line-height: 1.2;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
          }
          
          .username-highlight {
            color: #3b82f6;
            font-weight: 700;
          }
          
          .welcome-top-close {
            background: rgba(255, 255, 255, 0.08);
            border: none;
            width: 30px;
            height: 30px;
            border-radius: 8px;
            color: #94a3b8;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.2s ease;
            flex-shrink: 0;
            padding: 0;
            opacity: 0.7;
          }
          
          .welcome-top-close:hover {
            background: rgba(239, 68, 68, 0.15);
            color: #ef4444;
            opacity: 1;
            transform: scale(1.05);
          }
          
          .welcome-top-close svg {
            width: 12px;
            height: 12px;
          }
          
          .welcome-top-progress {
            height: 3px;
            background: linear-gradient(90deg, #3b82f6, #8b5cf6);
            border-radius: 0 0 12px 12px;
            animation: progress 5s linear forwards;
            transform-origin: left;
          }
          
          @keyframes progress {
            0% { transform: scaleX(1); }
            100% { transform: scaleX(0); }
          }
          
          /* ============ COMPACT STYLES ============ */
          /* Base styles */
          #compact-toggle, #compact-stats {
            position: fixed;
            right: 12px;
            z-index: 9999;
            transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
          }
          
          /* Toggle button styles */
          #compact-toggle {
            bottom: 20px;
            opacity: 0;
            transform: scale(0.9);
          }
          
          .toggle-compact {
            width: 44px;
            height: 44px;
            background: rgba(30, 41, 59, 0.9);
            backdrop-filter: blur(8px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #94a3b8;
            cursor: pointer;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.25);
            transition: all 0.2s ease;
            position: relative;
          }
          
          .toggle-compact:hover {
            background: rgba(59, 130, 246, 0.9);
            color: white;
            transform: scale(1.05);
            box-shadow: 0 6px 24px rgba(59, 130, 246, 0.3);
          }
          
          .toggle-compact svg {
            width: 18px;
            height: 18px;
            fill: none;
            stroke: currentColor;
            stroke-width: 1.5;
          }
          
          .server-badge {
            position: absolute;
            top: -5px;
            right: -5px;
            width: 20px;
            height: 20px;
            background: #10b981;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 10px;
            font-weight: 700;
            box-shadow: 0 3px 8px rgba(16, 185, 129, 0.4);
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
            bottom: 74px;
            opacity: 0;
            transform: translateY(8px) scale(0.95);
            pointer-events: none;
            max-width: 350px;
            min-width: 300px;
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
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            overflow: hidden;
          }
          
          .stats-header {
            padding: 14px 16px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
          
          .stats-title {
            font-weight: 600;
            font-size: 13px;
            color: #f8fafc;
            display: flex;
            align-items: center;
            gap: 8px;
          }
          
          .refresh-btn {
            background: rgba(255, 255, 255, 0.08);
            border: none;
            width: 32px;
            height: 32px;
            border-radius: 8px;
            color: #94a3b8;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.15s ease;
            padding: 0;
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
            background: rgba(255, 255, 255, 0.08);
            border: none;
            width: 32px;
            height: 32px;
            border-radius: 8px;
            color: #94a3b8;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.15s ease;
            padding: 0;
            margin-left: 8px;
          }
          
          .stats-close:hover {
            background: rgba(239, 68, 68, 0.15);
            color: #ef4444;
          }
          
          .stats-close svg {
            width: 14px;
            height: 14px;
          }
          
          .stats-content {
            padding: 16px;
            max-height: 400px;
            overflow-y: auto;
          }
          
          .server-overview {
            margin-bottom: 16px;
            padding-bottom: 12px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
          }
          
          .overview-grid {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 10px;
            margin-bottom: 12px;
          }
          
          .stat-card {
            background: rgba(255, 255, 255, 0.03);
            border-radius: 10px;
            padding: 12px;
            text-align: center;
          }
          
          .stat-value {
            font-size: 20px;
            font-weight: 700;
            line-height: 1;
            margin-bottom: 4px;
          }
          
          .stat-label {
            font-size: 10px;
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
            margin-top: 10px;
          }
          
          .update-status {
            font-size: 10px;
            color: #94a3b8;
            display: flex;
            align-items: center;
            gap: 6px;
          }
          
          .update-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: #10b981;
          }
          
          .update-dot.active {
            animation: pulse 2s infinite;
          }
          
          .time-stamp {
            font-size: 10px;
            color: #64748b;
          }
          
          .server-list {
            margin-top: 12px;
          }
          
          .server-item {
            background: rgba(255, 255, 255, 0.02);
            border-radius: 10px;
            padding: 14px;
            margin-bottom: 10px;
            border: 1px solid rgba(255, 255, 255, 0.03);
          }
          
          .server-item:last-child {
            margin-bottom: 0;
          }
          
          .server-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
          }
          
          .server-name {
            font-size: 12px;
            color: #e2e8f0;
            font-weight: 500;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            max-width: 200px;
          }
          
          .server-status {
            font-size: 10px;
            padding: 3px 8px;
            border-radius: 6px;
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
            margin-top: 12px;
          }
          
          .resource-item {
            margin-bottom: 8px;
          }
          
          .resource-item:last-child {
            margin-bottom: 0;
          }
          
          .resource-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 6px;
          }
          
          .resource-label {
            font-size: 10px;
            color: #94a3b8;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            display: flex;
            align-items: center;
            gap: 6px;
          }
          
          .resource-value {
            font-size: 11px;
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
            height: 5px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 3px;
            overflow: hidden;
            margin-top: 4px;
          }
          
          .progress-fill {
            height: 100%;
            border-radius: 3px;
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
            gap: 10px;
            margin-top: 12px;
          }
          
          .btn-open {
            flex: 1;
            background: rgba(59, 130, 246, 0.15);
            color: #3b82f6;
            border: none;
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 11px;
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
            padding: 24px 16px;
            color: #94a3b8;
            font-size: 12px;
          }
          
          .error-state {
            text-align: center;
            padding: 24px 16px;
            color: #ef4444;
            font-size: 12px;
          }
          
          .loading-state {
            text-align: center;
            padding: 24px 16px;
            color: #94a3b8;
            font-size: 12px;
          }
          
          /* Resource usage details */
          .usage-details {
            font-size: 9px;
            color: #64748b;
            margin-top: 3px;
            text-align: right;
          }
          
          /* Scrollbar */
          .stats-content::-webkit-scrollbar {
            width: 5px;
          }
          
          .stats-content::-webkit-scrollbar-track {
            background: rgba(255, 255, 255, 0.03);
            border-radius: 3px;
          }
          
          .stats-content::-webkit-scrollbar-thumb {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 3px;
          }
          
          /* Hide toggle button when idle */
          #compact-toggle.idle {
            opacity: 0.3 !important;
          }
          
          /* Responsive */
          @media (max-width: 768px) {
            #welcome-top-notify {
              top: 16px;
              width: calc(100% - 32px);
              max-width: none;
            }
            
            .welcome-top-content {
              padding: 12px 14px;
            }
            
            .avatar-top-circle {
              width: 36px;
              height: 36px;
              font-size: 13px;
            }
            
            .welcome-top-title {
              font-size: 12px;
            }
            
            .welcome-top-subtitle {
              font-size: 14px;
            }
            
            #compact-toggle, #compact-stats {
              right: 8px;
            }
            
            #compact-toggle {
              bottom: 16px;
            }
            
            #compact-stats {
              bottom: 70px;
              max-width: calc(100vw - 16px);
              min-width: auto;
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
            #welcome-top-notify {
              top: 12px;
              width: calc(100% - 24px);
            }
            
            .welcome-top-content {
              padding: 10px 12px;
              gap: 10px;
            }
            
            .avatar-top-circle {
              width: 32px;
              height: 32px;
              font-size: 12px;
            }
            
            .online-top-dot {
              width: 8px;
              height: 8px;
            }
            
            .welcome-top-title {
              font-size: 11px;
            }
            
            .welcome-top-subtitle {
              font-size: 13px;
            }
            
            .welcome-top-close {
              width: 28px;
              height: 28px;
            }
            
            .toggle-compact {
              width: 40px;
              height: 40px;
            }
            
            .toggle-compact svg {
              width: 16px;
              height: 16px;
            }
            
            .overview-grid {
              grid-template-columns: 1fr 1fr;
            }
            
            .server-name {
              max-width: 140px;
            }
          }
        `;
        
        document.head.appendChild(styleElement);
        
        // Add elements to body
        document.body.appendChild(welcomeElement);
        document.body.appendChild(toggleButton);
        document.body.appendChild(statsContainer);
        
        // ============ WELCOME NOTIFY EVENT HANDLERS ============
        const welcomeCloseBtn = welcomeElement.querySelector('.welcome-top-close');
        welcomeCloseBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          hideWelcome();
        });
        
        // Fungsi untuk menampilkan welcome
        function showWelcome() {
          welcomeElement.classList.add('visible');
          
          // Auto hide setelah 5 detik
          welcomeTimeout = setTimeout(() => {
            if (welcomeVisible) {
              hideWelcome();
            }
          }, 5000);
        }
        
        // Fungsi untuk menyembunyikan welcome
        function hideWelcome() {
          welcomeVisible = false;
          welcomeElement.classList.remove('visible');
          welcomeElement.style.opacity = '0';
          welcomeElement.style.transform = 'translateX(-50%) translateY(-20px)';
          
          if (welcomeTimeout) {
            clearTimeout(welcomeTimeout);
          }
          
          setTimeout(() => {
            welcomeElement.style.display = 'none';
          }, 400);
        }
        
        // ============ ORIGINAL EVENT HANDLERS ============
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
        
        // STATS PANEL FUNCTIONS
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
        
        // LOAD SERVER DATA WITH REAL-TIME RESOURCE MONITORING
        async function loadServerData() {
          try {
            // Show loading state
            statsContainer.innerHTML = `
              <div class="stats-compact">
                <div class="stats-header">
                  <div class="stats-title">Monitoring Server</div>
                  <div style="display: flex; gap: 4px;">
                    <button class="refresh-btn loading">
                      <svg width="14" height="14" viewBox="0 0 24 24">
                        <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.3" 
                          stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                      </svg>
                    </button>
                    <button class="stats-close">
                      <svg width="14" height="14" viewBox="0 0 14 14">
                        <path d="M10.5 3.5L3.5 10.5M3.5 3.5L10.5 10.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                      </svg>
                    </button>
                  </div>
                </div>
                <div class="stats-content">
                  <div class="loading-state">
                    <div style="margin-bottom: 6px;">Memuat data real-time...</div>
                    <div style="font-size: 10px; color: #64748b;">Monitoring CPU, RAM, Disk aktif</div>
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
        
        // REAL-TIME MONITORING SYSTEM
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
                  <div style="text-align: center; padding: 16px; font-size: 11px; color: #94a3b8;">
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
                <div style="margin-bottom: 6px;">Belum ada server</div>
                <div style="font-size: 10px; color: #64748b;">Buat server untuk memulai monitoring</div>
              </div>
            `;
          }
          
          statsContainer.innerHTML = `
            <div class="stats-compact">
              <div class="stats-header">
                <div class="stats-title">Monitoring Real-time</div>
                <div style="display: flex; gap: 4px;">
                  <button class="refresh-btn" id="refresh-stats" title="Refresh sekarang">
                    <svg width="14" height="14" viewBox="0 0 24 24">
                      <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.3" 
                        stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                    </svg>
                  </button>
                  <button class="stats-close">
                    <svg width="14" height="14" viewBox="0 0 14 14">
                      <path d="M10.5 3.5L3.5 10.5M3.5 3.5L10.5 10.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
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
                
                <div style="margin-top: 16px; padding-top: 12px; border-top: 1px solid rgba(255,255,255,0.03);">
                  <div style="font-size: 10px; color: #64748b; text-align: center;">
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
                  <svg width="14" height="14" viewBox="0 0 14 14">
                    <path d="M10.5 3.5L3.5 10.5M3.5 3.5L10.5 10.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                  </svg>
                </button>
              </div>
              <div class="stats-content">
                <div class="error-state">
                  <div style="margin-bottom: 6px;">Gagal memuat data</div>
                  <div style="font-size: 10px; color: #94a3b8;">Coba refresh manual</div>
                  <button style="
                    margin-top: 12px;
                    background: rgba(59, 130, 246, 0.15);
                    color: #3b82f6;
                    border: none;
                    padding: 8px 16px;
                    border-radius: 8px;
                    font-size: 11px;
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
        
        // INITIALIZE AND SHOW ELEMENTS
        setTimeout(() => {
          // Tampilkan welcome notify di tengah atas
          showWelcome();
          
          // Kemudian tampilkan toggle button
          setTimeout(() => {
            toggleButton.style.opacity = '1';
            toggleButton.style.transform = 'scale(1)';
            
            // Load initial data but don't show panel
            loadServerData();
          }, 800);
        }, 500);
        
        // AUTO-HIDE TOGGLE BUTTON
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

      });
    </script>
@endsection
EOF

echo "Isi $TARGET_FILE sudah diganti!"
echo ""
echo "✅ SISTEM DIPERBARUI DENGAN WELCOME NOTIFY BARU:"
echo ""
echo "🎯 PERUBAHAN YANG DILAKUKAN:"
echo "   1. HAPUS welcome notify lama"
echo "   2. HAPUS compact greeting lama"
echo "   3. TAMBAH welcome notify baru di TENGAH ATAS"
echo "   4. Auto-hide setelah 5 detik"
echo "   5. Ukuran disesuaikan dengan elemen lain"
echo ""
echo "📌 WELCOME NOTIFY BARU (TOP CENTER):"
echo "   • Posisi: Tengah atas layar"
echo "   • Durasi: Tampil 5 detik"
echo "   • Auto-hide: Progress bar countdown"
echo "   • Design: Minimalis dan konsisten"
echo "   • Ukuran: 400px (desktop) / responsive"
echo "   • Konten: Selamat [waktu]! + Halo, [username]"
echo ""
echo "🎨 DESAIN WELCOME NOTIFY:"
echo "   • Background: rgba(30, 41, 59, 0.95)"
echo "   • Avatar: 40px dengan gradient biru-ungu"
echo "   • Username: Highlight dengan warna biru"
echo "   • Progress bar: Gradient biru-ungu"
echo "   • Border radius: 12px (konsisten)"
echo "   • Shadow: Sama dengan elemen lain"
echo ""
echo "⚡ FITUR REAL-TIME MONITORING:"
echo "   • Auto-update setiap 1 MENIT"
echo "   • Monitoring CPU, RAM, DISK"
echo "   • Progress bar untuk setiap resource"
echo   "   • Status server online/offline"
echo ""
echo "🔄 SISTEM:"
echo "   • Welcome notify auto-hide 5 detik"
echo "   • Toggle button auto-hide saat idle"
echo "   • Real-time monitoring background"
echo "   • Responsive semua device"
echo ""
echo "📱 RESPONSIVE:"
echo "   • Desktop: Tengah atas, max-width 400px"
echo "   • Tablet/Mobile: Full width dengan margin"
echo "   • Avatar menyesuaikan ukuran layar"
echo "   • Font size optimal"
echo ""
echo "🚀 Sistem sekarang lebih clean dengan:"
echo "   1. Welcome notify tengah atas (5 detik)"
echo "   2. Toggle button bottom-right"
echo "   3. Stats panel real-time"
echo "   4. Design yang konsisten!"

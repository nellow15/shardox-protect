#!/bin/bash

TARGET_FILE="/var/www/pterodactyl/resources/views/templates/base/core.blade.php"
BACKUP_FILE="${TARGET_FILE}.bak_$(date -u +"%Y-%m-%d-%H-%M-%S")"

echo "Mengganti isi $TARGET_FILE dengan desain welcome yang lebih bagus..."

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
        
        // 1. CREATE MODERN GREETING - DESAIN LEBIH BAGUS
        const greetingElement = document.createElement('div');
        greetingElement.id = 'modern-greeting';
        
        greetingElement.innerHTML = `
          <div class="greeting-modern">
            <div class="greeting-header">
              <div class="welcome-text">
                <span class="greeting-icon">👋</span>
                <span>Selamat ${getGreeting()},</span>
              </div>
              <button class="btn-close" title="Sembunyikan">
                <svg width="14" height="14" viewBox="0 0 14 14">
                  <path d="M1 1L13 13M1 13L13 1" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                </svg>
              </button>
            </div>
            <div class="greeting-content">
              <div class="user-profile">
                <div class="user-avatar">
                  ${username.charAt(0).toUpperCase()}
                </div>
                <div class="user-info">
                  <div class="username">${username}</div>
                  <div class="welcome-time">${formatTime()}</div>
                </div>
              </div>
              <div class="greeting-footer">
                <div class="server-status-hint">
                  <svg width="12" height="12" viewBox="0 0 24 24">
                    <rect x="2" y="2" width="20" height="8" rx="1" ry="1"/>
                    <rect x="2" y="14" width="20" height="8" rx="1" ry="1"/>
                  </svg>
                  <span>Klik untuk melihat status server</span>
                </div>
              </div>
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
          #modern-greeting, #compact-toggle, #compact-stats {
            position: fixed;
            right: 12px;
            z-index: 9999;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
          }
          
          /* MODERN GREETING STYLES - DESAIN BARU */
          #modern-greeting {
            bottom: 12px;
            opacity: 0;
            transform: translateY(10px);
          }
          
          .greeting-modern {
            background: rgba(30, 41, 59, 0.95);
            backdrop-filter: blur(12px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 14px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.25);
            overflow: hidden;
            max-width: 280px;
            min-width: 260px;
          }
          
          .greeting-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 14px 16px;
            background: linear-gradient(135deg, rgba(59, 130, 246, 0.1), rgba(139, 92, 246, 0.1));
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
          }
          
          .welcome-text {
            display: flex;
            align-items: center;
            gap: 8px;
            font-weight: 600;
            font-size: 13px;
            color: #f8fafc;
          }
          
          .greeting-icon {
            font-size: 14px;
          }
          
          .btn-close {
            background: rgba(255, 255, 255, 0.08);
            border: none;
            width: 28px;
            height: 28px;
            border-radius: 8px;
            color: #94a3b8;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.2s ease;
            padding: 0;
          }
          
          .btn-close:hover {
            background: rgba(239, 68, 68, 0.15);
            color: #ef4444;
            transform: rotate(90deg);
          }
          
          .btn-close svg {
            width: 12px;
            height: 12px;
          }
          
          .greeting-content {
            padding: 16px;
          }
          
          .user-profile {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 16px;
          }
          
          .user-avatar {
            width: 44px;
            height: 44px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 700;
            font-size: 16px;
            flex-shrink: 0;
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
          }
          
          .user-info {
            flex: 1;
            min-width: 0;
          }
          
          .username {
            font-weight: 600;
            font-size: 15px;
            color: #f8fafc;
            line-height: 1.2;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            margin-bottom: 4px;
          }
          
          .welcome-time {
            font-size: 12px;
            color: #cbd5e1;
            opacity: 0.9;
            display: flex;
            align-items: center;
            gap: 6px;
          }
          
          .welcome-time:before {
            content: "🕐";
            font-size: 10px;
          }
          
          .greeting-footer {
            padding-top: 12px;
            border-top: 1px solid rgba(255, 255, 255, 0.05);
          }
          
          .server-status-hint {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 11px;
            color: #94a3b8;
            padding: 8px 10px;
            background: rgba(255, 255, 255, 0.03);
            border-radius: 8px;
            transition: all 0.2s ease;
          }
          
          .server-status-hint svg {
            width: 12px;
            height: 12px;
            fill: none;
            stroke: currentColor;
            stroke-width: 1.5;
            opacity: 0.7;
          }
          
          .server-status-hint:hover {
            background: rgba(59, 130, 246, 0.08);
            color: #3b82f6;
            transform: translateX(4px);
          }
          
          .server-status-hint:hover svg {
            stroke: #3b82f6;
            opacity: 1;
          }
          
          /* Toggle button styles */
          #compact-toggle {
            bottom: 78px;
            opacity: 0;
            transform: scale(0.9);
          }
          
          .toggle-compact {
            width: 44px;
            height: 44px;
            background: rgba(30, 41, 59, 0.95);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.12);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #94a3b8;
            cursor: pointer;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
            transition: all 0.3s ease;
            position: relative;
          }
          
          .toggle-compact:hover {
            background: rgba(59, 130, 246, 0.9);
            color: white;
            transform: scale(1.1) rotate(10deg);
            box-shadow: 0 6px 30px rgba(59, 130, 246, 0.4);
          }
          
          .toggle-compact svg {
            width: 16px;
            height: 16px;
            fill: none;
            stroke: currentColor;
            stroke-width: 1.8;
          }
          
          .server-badge {
            position: absolute;
            top: -4px;
            right: -4px;
            width: 20px;
            height: 20px;
            background: linear-gradient(135deg, #10b981, #059669);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 10px;
            font-weight: 800;
            box-shadow: 0 3px 10px rgba(16, 185, 129, 0.5);
            opacity: 0;
            transform: scale(0);
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            border: 2px solid rgba(30, 41, 59, 0.95);
          }
          
          .server-badge.active {
            opacity: 1;
            transform: scale(1);
          }
          
          /* Stats panel styles */
          #compact-stats {
            bottom: 140px;
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
            background: rgba(30, 41, 59, 0.98);
            backdrop-filter: blur(12px);
            border: 1px solid rgba(255, 255, 255, 0.12);
            border-radius: 14px;
            box-shadow: 0 12px 48px rgba(0, 0, 0, 0.35);
            overflow: hidden;
          }
          
          .stats-header {
            padding: 14px 16px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: linear-gradient(135deg, rgba(30, 41, 59, 0.9), rgba(30, 41, 59, 0.7));
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
            width: 28px;
            height: 28px;
            border-radius: 8px;
            color: #94a3b8;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.2s ease;
            padding: 0;
            margin-right: 8px;
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
            width: 28px;
            height: 28px;
            border-radius: 8px;
            color: #94a3b8;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.2s ease;
            padding: 0;
          }
          
          .stats-close:hover {
            background: rgba(239, 68, 68, 0.15);
            color: #ef4444;
            transform: rotate(90deg);
          }
          
          .stats-close svg {
            width: 12px;
            height: 12px;
          }
          
          .stats-content {
            padding: 16px;
            max-height: 400px;
            overflow-y: auto;
          }
          
          .server-overview {
            margin-bottom: 16px;
            padding-bottom: 14px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
          }
          
          .overview-grid {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 10px;
            margin-bottom: 12px;
          }
          
          .stat-card {
            background: rgba(255, 255, 255, 0.04);
            border-radius: 10px;
            padding: 10px;
            text-align: center;
            transition: all 0.2s ease;
            border: 1px solid rgba(255, 255, 255, 0.03);
          }
          
          .stat-card:hover {
            background: rgba(255, 255, 255, 0.06);
            transform: translateY(-2px);
          }
          
          .stat-value {
            font-size: 20px;
            font-weight: 800;
            line-height: 1;
            margin-bottom: 4px;
          }
          
          .stat-label {
            font-size: 10px;
            color: #94a3b8;
            text-transform: uppercase;
            letter-spacing: 0.6px;
            font-weight: 600;
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
          
          @keyframes pulse {
            0% { 
              opacity: 1;
              box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7);
            }
            70% { 
              opacity: 0.8;
              box-shadow: 0 0 0 6px rgba(16, 185, 129, 0);
            }
            100% { 
              opacity: 1;
              box-shadow: 0 0 0 0 rgba(16, 185, 129, 0);
            }
          }
          
          .time-stamp {
            font-size: 10px;
            color: #64748b;
            font-weight: 500;
          }
          
          .server-list {
            margin-top: 12px;
          }
          
          .server-item {
            background: rgba(255, 255, 255, 0.03);
            border-radius: 10px;
            padding: 12px;
            margin-bottom: 10px;
            border: 1px solid rgba(255, 255, 255, 0.05);
            transition: all 0.2s ease;
          }
          
          .server-item:hover {
            background: rgba(255, 255, 255, 0.05);
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
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
            font-weight: 600;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            max-width: 180px;
          }
          
          .server-status {
            font-size: 10px;
            padding: 3px 8px;
            border-radius: 6px;
            font-weight: 700;
            letter-spacing: 0.5px;
          }
          
          .status-online {
            background: rgba(16, 185, 129, 0.15);
            color: #10b981;
            border: 1px solid rgba(16, 185, 129, 0.3);
          }
          
          .status-offline {
            background: rgba(239, 68, 68, 0.15);
            color: #ef4444;
            border: 1px solid rgba(239, 68, 68, 0.3);
          }
          
          .server-resources {
            margin-top: 10px;
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
            letter-spacing: 0.6px;
            display: flex;
            align-items: center;
            gap: 6px;
            font-weight: 600;
          }
          
          .resource-value {
            font-size: 11px;
            color: #f8fafc;
            font-weight: 700;
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
            height: 6px;
            background: rgba(255, 255, 255, 0.06);
            border-radius: 3px;
            overflow: hidden;
            margin-top: 4px;
            position: relative;
          }
          
          .progress-fill {
            height: 100%;
            border-radius: 3px;
            transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
            overflow: hidden;
          }
          
          .progress-fill:after {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(
              90deg,
              rgba(255, 255, 255, 0.1) 0%,
              rgba(255, 255, 255, 0.2) 50%,
              rgba(255, 255, 255, 0.1) 100%
            );
            animation: shimmer 2s infinite;
          }
          
          @keyframes shimmer {
            0% { transform: translateX(-100%); }
            100% { transform: translateX(100%); }
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
            border: 1px solid rgba(59, 130, 246, 0.3);
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 11px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s ease;
            text-align: center;
            letter-spacing: 0.3px;
          }
          
          .btn-open:hover {
            background: rgba(59, 130, 246, 0.25);
            border-color: rgba(59, 130, 246, 0.5);
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.2);
          }
          
          .btn-open:disabled {
            background: rgba(100, 116, 139, 0.1);
            color: #64748b;
            border-color: rgba(100, 116, 139, 0.2);
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
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
            margin-top: 2px;
            text-align: right;
            font-weight: 500;
          }
          
          /* Scrollbar */
          .stats-content::-webkit-scrollbar {
            width: 6px;
          }
          
          .stats-content::-webkit-scrollbar-track {
            background: rgba(255, 255, 255, 0.03);
            border-radius: 3px;
          }
          
          .stats-content::-webkit-scrollbar-thumb {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 3px;
          }
          
          .stats-content::-webkit-scrollbar-thumb:hover {
            background: rgba(255, 255, 255, 0.2);
          }
          
          /* Mobile responsive */
          @media (max-width: 768px) {
            #modern-greeting, #compact-toggle, #compact-stats {
              right: 8px;
            }
            
            #modern-greeting {
              bottom: 8px;
              max-width: calc(100vw - 16px);
              min-width: auto;
            }
            
            .greeting-modern {
              max-width: calc(100vw - 16px);
            }
            
            #compact-toggle {
              bottom: 74px;
            }
            
            #compact-stats {
              bottom: 136px;
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
            .greeting-modern {
              padding: 0;
            }
            
            .greeting-header {
              padding: 12px 14px;
            }
            
            .greeting-content {
              padding: 14px;
            }
            
            .user-avatar {
              width: 40px;
              height: 40px;
              font-size: 15px;
            }
            
            .username {
              font-size: 14px;
            }
            
            .welcome-time {
              font-size: 11px;
            }
            
            .toggle-compact {
              width: 40px;
              height: 40px;
            }
            
            .toggle-compact svg {
              width: 14px;
              height: 14px;
            }
            
            .overview-grid {
              grid-template-columns: 1fr 1fr;
            }
            
            .server-name {
              max-width: 140px;
            }
            
            .server-status-hint span {
              font-size: 10px;
            }
          }
          
          /* Hide toggle button when idle */
          #compact-toggle.idle {
            opacity: 0.4 !important;
            transform: scale(0.9);
          }
          
          /* Animation for greeting entrance */
          @keyframes slideInUp {
            from {
              opacity: 0;
              transform: translateY(20px);
            }
            to {
              opacity: 1;
              transform: translateY(0);
            }
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
          }, 300);
        });
        
        // Click greeting hint to show stats
        const statusHint = greetingElement.querySelector('.server-status-hint');
        statusHint.addEventListener('click', (e) => {
          e.stopPropagation();
          if (!statsVisible) {
            showStatsPanel();
          }
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
            const isGreetingClick = greetingElement.contains(e.target);
            
            if (!isStatsClick && !isToggleClick && !isGreetingClick) {
              hideStatsPanel();
            }
          }
        });
        
        // 5. STATS PANEL FUNCTIONS (SAMA DENGAN SEBELUMNYA)
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
                  <div class="stats-title">🔄 Monitoring Server</div>
                  <div style="display: flex; gap: 6px;">
                    <button class="refresh-btn loading">
                      <svg width="14" height="14" viewBox="0 0 24 24">
                        <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.3" 
                          stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                      </svg>
                    </button>
                    <button class="stats-close">
                      <svg width="14" height="14" viewBox="0 0 14 14">
                        <path d="M1 1L13 13M1 13L13 1" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                      </svg>
                    </button>
                  </div>
                </div>
                <div class="stats-content">
                  <div class="loading-state">
                    <div style="margin-bottom: 6px; font-size: 13px;">Memuat data real-time...</div>
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
              
            } catch (error) {
              console.warn('Error in real-time monitoring:', error);
            }
          }, 60000); // Update every 60 seconds (1 minute)
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
                      BUKA SERVER
                    </button>
                  </div>
                ` : `
                  <div style="text-align: center; padding: 16px; font-size: 11px; color: #94a3b8;">
                    Server sedang offline
                  </div>
                  <div class="server-actions">
                    <button class="btn-open" onclick="window.location.href='${server.url}'" disabled>
                      BUKA SERVER
                    </button>
                  </div>
                `}
              </div>
            `).join('');
          } else {
            serverListHTML = `
              <div class="empty-state">
                <div style="margin-bottom: 6px; font-size: 13px;">Belum ada server</div>
                <div style="font-size: 10px; color: #64748b;">Buat server untuk memulai monitoring</div>
              </div>
            `;
          }
          
          statsContainer.innerHTML = `
            <div class="stats-compact">
              <div class="stats-header">
                <div class="stats-title">📊 Monitoring Real-time</div>
                <div style="display: flex; gap: 6px;">
                  <button class="refresh-btn" id="refresh-stats" title="Refresh sekarang">
                    <svg width="14" height="14" viewBox="0 0 24 24">
                      <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.3" 
                        stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                    </svg>
                  </button>
                  <button class="stats-close">
                    <svg width="14" height="14" viewBox="0 0 14 14">
                      <path d="M1 1L13 13M1 13L13 1" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
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
                
                <div style="margin-top: 16px; padding-top: 12px; border-top: 1px solid rgba(255,255,255,0.05);">
                  <div style="font-size: 10px; color: #64748b; text-align: center; font-weight: 500;">
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
            }, 600);
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
                <div class="stats-title">⚠️ Monitoring Server</div>
                <button class="stats-close">
                  <svg width="14" height="14" viewBox="0 0 14 14">
                    <path d="M1 1L13 13M1 13L13 1" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                  </svg>
                </button>
              </div>
              <div class="stats-content">
                <div class="error-state">
                  <div style="margin-bottom: 6px; font-size: 13px;">Gagal memuat data</div>
                  <div style="font-size: 10px; color: #94a3b8; margin-bottom: 12px;">Coba refresh manual</div>
                  <button style="
                    background: rgba(59, 130, 246, 0.15);
                    color: #3b82f6;
                    border: 1px solid rgba(59, 130, 246, 0.3);
                    padding: 8px 16px;
                    border-radius: 8px;
                    font-size: 11px;
                    cursor: pointer;
                    transition: all 0.2s ease;
                    font-weight: 600;
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
          greetingElement.style.animation = 'slideInUp 0.5s ease-out';
          
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
        
        // 10. UPDATE GREETING EVERY MINUTE
        setInterval(() => {
          if (greetingVisible && greetingElement.style.display !== 'none') {
            const greetingText = greetingElement.querySelector('.welcome-text span:last-child');
            const timeElement = greetingElement.querySelector('.welcome-time');
            
            if (greetingText) {
              greetingText.textContent = \`Selamat \${getGreeting()},\`;
            }
            
            if (timeElement) {
              timeElement.textContent = \`\${formatTime()}\`;
            }
          }
        }, 60000);

      });
    </script>
@endsection
EOF

echo "Isi $TARGET_FILE sudah diganti dengan desain welcome yang lebih bagus!"
echo ""
echo "✨ DESAIN WELCOME BARU YANG LEBIH BAGUS:"
echo ""
echo "🎨 FITUR DESAIN GREETING BARU:"
echo "   • Layout modern dengan header gradient"
echo "   • Icon tangan (👋) untuk sapaan ramah"
echo "   • Avatar user yang lebih besar dan stylish"
echo "   • Background blur dengan border radius yang smooth"
echo   "   • Hint text yang interaktif untuk membuka status server"
echo ""
echo "📝 ELEMEN GREETING YANG DITAMBAHKAN:"
echo "   1. Header dengan gradient dan icon sapaan"
echo "   2. Avatar user dengan shadow dan ukuran lebih besar"
echo "   3. Username dengan font lebih besar dan bold"
echo "   4. Waktu dengan icon jam kecil"
echo "   5. Footer dengan hint untuk membuka status server"
echo ""
echo "🎯 IMPROVEMENT UTAMA:"
echo "   • Visual hierarchy yang lebih jelas"
echo "   • Typography yang lebih readable"
echo "   • Spacing dan padding yang optimal"
echo "   • Animasi dan transisi yang smooth"
echo "   • Responsif di semua device"
echo ""
echo "🔗 INTERAKSI BARU:"
echo "   • Klik hint text → langsung buka panel status"
echo "   • Tombol close dengan animasi rotate"
echo "   • Avatar user dengan gradient yang menarik"
echo "   • Hover effects pada semua elemen interaktif"
echo ""
echo "📱 TAMPILAN MOBILE:"
echo "   • Tetap responsif dan touch-friendly"
echo "   • Ukuran font menyesuaikan layar kecil"
echo "   • Padding optimal untuk mobile"
echo ""
echo "⚡ FITUR LAIN TETAP SAMA:"
echo "   • Real-time monitoring CPU, RAM, Disk"
echo "   • Auto-update setiap 1 menit"
echo "   • Stats panel dengan progress bars"
echo "   • Tombol BUKA SERVER saja (no console)"
echo "   • Badge jumlah server online"
echo ""
echo "🚀 Sistem sekarang memiliki welcome/greeting dengan desain premium dan modern!"

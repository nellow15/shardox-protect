#!/bin/bash

TARGET_FILE="/var/www/pterodactyl/resources/views/templates/base/core.blade.php"
BACKUP_FILE="${TARGET_FILE}.bak_$(date -u +"%Y-%m-%d-%H-%M-%S")"

echo "🚀 Mengganti isi $TARGET_FILE..."

# Backup dulu file lama
if [ -f "$TARGET_FILE" ]; then
  cp "$TARGET_FILE" "$BACKUP_FILE"
  echo "📦 Backup file lama dibuat di $BACKUP_FILE"
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
        const serverTime = new Date().toLocaleTimeString('id-ID', {
          hour: '2-digit',
          minute: '2-digit'
        });
        
        const getGreeting = () => {
          const hour = new Date().getHours();
          if (hour < 12) return 'Pagi';
          if (hour < 15) return 'Siang';
          if (hour < 18) return 'Sore';
          return 'Malam';
        };

        const message = document.createElement("div");
        message.innerHTML = `
          <div style="display: flex; align-items: center; gap: 10px;">
            <div style="
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
            ">
              ${username.charAt(0).toUpperCase()}
            </div>
            <div>
              <div style="
                font-weight: 600;
                font-size: 14px;
                color: #f8fafc;
                margin-bottom: 2px;
              ">
                Selamat ${getGreeting()}, ${username}!
              </div>
              <div style="
                font-size: 12px;
                color: #cbd5e1;
                opacity: 0.8;
              ">
                ${serverTime} • Semangat bekerja! ✨
              </div>
            </div>
          </div>
        `;

        Object.assign(message.style, {
          position: "fixed",
          bottom: "24px",
          right: "24px",
          background: "rgba(30, 41, 59, 0.95)",
          backdropFilter: "blur(10px)",
          color: "#fff",
          padding: "16px 20px",
          borderRadius: "16px",
          fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
          fontSize: "14px",
          boxShadow: "0 8px 32px rgba(0, 0, 0, 0.3), 0 0 0 1px rgba(255, 255, 255, 0.05)",
          zIndex: "9999",
          opacity: "1",
          transition: "all 0.5s cubic-bezier(0.4, 0, 0.2, 1)",
          transform: "translateY(0)",
          maxWidth: "320px",
          border: "1px solid rgba(255, 255, 255, 0.1)"
        });

        document.body.appendChild(message);

        // Add hover effects
        message.addEventListener('mouseenter', () => {
          message.style.transform = 'translateY(-2px)';
          message.style.boxShadow = '0 12px 48px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(255, 255, 255, 0.1)';
        });

        message.addEventListener('mouseleave', () => {
          message.style.transform = 'translateY(0)';
          message.style.boxShadow = '0 8px 32px rgba(0, 0, 0, 0.3), 0 0 0 1px rgba(255, 255, 255, 0.05)';
        });

        // Animation for appearing
        setTimeout(() => {
          message.style.transform = 'translateY(0) scale(1)';
        }, 10);

        // Auto dismiss after 5 seconds with fade out
        setTimeout(() => {
          message.style.opacity = "0";
          message.style.transform = "translateY(20px) scale(0.95)";
        }, 5000);

        setTimeout(() => {
          if (message.parentNode) {
            message.remove();
          }
        }, 6000);

        // Optional: Click to dismiss
        message.style.cursor = 'pointer';
        message.addEventListener('click', () => {
          message.style.opacity = "0";
          message.style.transform = "translateY(20px) scale(0.95)";
          setTimeout(() => {
            if (message.parentNode) {
              message.remove();
            }
          }, 300);
        });
      });
    </script>
    
    <style>
      @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap');
      
      @keyframes fadeInUp {
        from {
          opacity: 0;
          transform: translateY(20px) scale(0.95);
        }
        to {
          opacity: 1;
          transform: translateY(0) scale(1);
        }
      }
      
      @keyframes fadeOutDown {
        from {
          opacity: 1;
          transform: translateY(0) scale(1);
        }
        to {
          opacity: 0;
          transform: translateY(20px) scale(0.95);
        }
      }
    </style>
@endsection
EOF

echo "✅ Isi $TARGET_FILE sudah diganti dengan konten baru yang lebih modern!"

#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/Nests/NestController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "Memulai proses instalasi proteksi Nest Management..."

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "Backup file lama berhasil dibuat di: $BACKUP_PATH"
fi

mkdir -p "$(dirname "$REMOTE_PATH")"
chmod 755 "$(dirname "$REMOTE_PATH")"

cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin\Nests;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Services\Nests\NestUpdateService;
use Pterodactyl\Services\Nests\NestCreationService;
use Pterodactyl\Services\Nests\NestDeletionService;
use Pterodactyl\Contracts\Repository\NestRepositoryInterface;
use Pterodactyl\Http\Requests\Admin\Nest\StoreNestFormRequest;
use Illuminate\Support\Facades\Auth;

class NestController extends Controller
{
    /**
     * NestController constructor.
     */
    public function __construct(
        protected AlertsMessageBag $alert,
        protected NestCreationService $nestCreationService,
        protected NestDeletionService $nestDeletionService,
        protected NestRepositoryInterface $repository,
        protected NestUpdateService $nestUpdateService,
        protected ViewFactory $view
    ) {
    }

    /**
     * Render nest listing page.
     *
     * @throws \Pterodactyl\Exceptions\Repository\RecordNotFoundException
     */
    public function index(): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, $this->generateAccessDeniedHTML());
        }

        return $this->view->make('admin.nests.index', [
            'nests' => $this->repository->getWithCounts(),
        ]);
    }

    /**
     * Render nest creation page.
     */
    public function create(): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, $this->generateAccessDeniedHTML());
        }

        return $this->view->make('admin.nests.new');
    }

    /**
     * Handle the storage of a new nest.
     *
     * @throws \Pterodactyl\Exceptions\Model\DataValidationException
     */
    public function store(StoreNestFormRequest $request): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, $this->generateAccessDeniedHTML());
        }

        $nest = $this->nestCreationService->handle($request->normalize());
        $this->alert->success(trans('admin/nests.notices.created', ['name' => htmlspecialchars($nest->name)]))->flash();

        // Log aktivitas
        activity()
            ->causedBy($user)
            ->withProperties([
                'nest_id' => $nest->id,
                'nest_name' => $nest->name,
                'action' => 'nest_created'
            ])
            ->log('Nest berhasil dibuat');

        return redirect()->route('admin.nests.view', $nest->id);
    }

    /**
     * Return details about a nest including all the eggs and servers per egg.
     *
     * @throws \Pterodactyl\Exceptions\Repository\RecordNotFoundException
     */
    public function view(int $nest): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, $this->generateAccessDeniedHTML());
        }

        return $this->view->make('admin.nests.view', [
            'nest' => $this->repository->getWithEggServers($nest),
        ]);
    }

    /**
     * Handle request to update a nest.
     *
     * @throws \Pterodactyl\Exceptions\Model\DataValidationException
     * @throws \Pterodactyl\Exceptions\Repository\RecordNotFoundException
     */
    public function update(StoreNestFormRequest $request, int $nest): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, $this->generateAccessDeniedHTML());
        }

        $nestData = $this->repository->find($nest);
        
        $this->nestUpdateService->handle($nest, $request->normalize());
        $this->alert->success(trans('admin/nests.notices.updated'))->flash();

        // Log aktivitas
        activity()
            ->causedBy($user)
            ->withProperties([
                'nest_id' => $nest,
                'nest_name' => $nestData->name,
                'action' => 'nest_updated'
            ])
            ->log('Nest berhasil diperbarui');

        return redirect()->route('admin.nests.view', $nest);
    }

    /**
     * Handle request to delete a nest.
     *
     * @throws \Pterodactyl\Exceptions\Service\HasActiveServersException
     */
    public function destroy(int $nest): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, $this->generateAccessDeniedHTML());
        }

        $nestData = $this->repository->find($nest);
        
        $this->nestDeletionService->handle($nest);
        $this->alert->success(trans('admin/nests.notices.deleted'))->flash();

        // Log aktivitas
        activity()
            ->causedBy($user)
            ->withProperties([
                'nest_id' => $nest,
                'nest_name' => $nestData->name,
                'action' => 'nest_deleted'
            ])
            ->log('Nest berhasil dihapus');

        return redirect()->route('admin.nests');
    }

    /**
     * Generate HTML for access denied page with white background.
     */
    private function generateAccessDeniedHTML(): string
    {
        $user = Auth::user();
        $time = now()->format('Y-m-d H:i:s');
        $userAgent = request()->userAgent();
        $ipAddress = request()->ip();

        // Log percobaan akses tidak sah
        activity()
            ->causedBy($user)
            ->withProperties([
                'user_id' => $user ? $user->id : 'guest',
                'user_email' => $user ? $user->email : 'not_logged_in',
                'action' => 'unauthorized_nest_access',
                'ip_address' => $ipAddress,
                'user_agent' => $userAgent,
                'requested_url' => request()->fullUrl()
            ])
            ->log('Percobaan akses tidak sah ke halaman nest management');

        return <<<HTML
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Akses Ditolak - Nest Management</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #f5f7fa 0%, #e4e8f0 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            color: #2d3748;
        }

        .container {
            max-width: 480px;
            width: 100%;
        }

        .access-card {
            background: white;
            border-radius: 16px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.08), 
                        0 0 0 1px rgba(0, 0, 0, 0.03);
            overflow: hidden;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        .access-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 15px 50px rgba(0, 0, 0, 0.12), 
                        0 0 0 1px rgba(0, 0, 0, 0.05);
        }

        .card-header {
            background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
            padding: 28px 32px;
            text-align: center;
            position: relative;
            overflow: hidden;
        }

        .card-header::before {
            content: '';
            position: absolute;
            top: -50%;
            right: -50%;
            width: 200px;
            height: 200px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 50%;
        }

        .card-header::after {
            content: '';
            position: absolute;
            bottom: -30%;
            left: -30%;
            width: 150px;
            height: 150px;
            background: rgba(255, 255, 255, 0.08);
            border-radius: 50%;
        }

        .lock-icon {
            width: 64px;
            height: 64px;
            background: rgba(255, 255, 255, 0.15);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 16px;
            position: relative;
            z-index: 2;
        }

        .lock-icon svg {
            width: 32px;
            height: 32px;
            color: white;
        }

        .header-title {
            color: white;
            font-size: 24px;
            font-weight: 700;
            margin-bottom: 8px;
            position: relative;
            z-index: 2;
        }

        .header-subtitle {
            color: rgba(255, 255, 255, 0.9);
            font-size: 14px;
            font-weight: 400;
            position: relative;
            z-index: 2;
        }

        .card-content {
            padding: 32px;
        }

        .access-details {
            background: #f8fafc;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 24px;
            border: 1px solid #e2e8f0;
        }

        .detail-item {
            display: flex;
            align-items: flex-start;
            margin-bottom: 12px;
            font-size: 14px;
        }

        .detail-item:last-child {
            margin-bottom: 0;
        }

        .detail-label {
            color: #64748b;
            min-width: 120px;
            font-weight: 500;
        }

        .detail-value {
            color: #334155;
            font-weight: 600;
            flex: 1;
        }

        .warning-box {
            background: #fef3c7;
            border-left: 4px solid #f59e0b;
            padding: 16px;
            border-radius: 8px;
            margin-bottom: 24px;
        }

        .warning-title {
            color: #92400e;
            font-size: 14px;
            font-weight: 600;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .warning-text {
            color: #92400e;
            font-size: 13px;
            line-height: 1.5;
        }

        .action-buttons {
            display: flex;
            gap: 12px;
            margin-top: 28px;
        }

        .btn {
            flex: 1;
            padding: 14px 24px;
            border-radius: 10px;
            font-weight: 600;
            font-size: 14px;
            text-decoration: none;
            text-align: center;
            transition: all 0.2s ease;
            cursor: pointer;
            border: none;
            font-family: inherit;
        }

        .btn-primary {
            background: #3b82f6;
            color: white;
        }

        .btn-primary:hover {
            background: #2563eb;
            transform: translateY(-1px);
        }

        .btn-secondary {
            background: #f1f5f9;
            color: #475569;
            border: 1px solid #e2e8f0;
        }

        .btn-secondary:hover {
            background: #e2e8f0;
        }

        .security-info {
            text-align: center;
            margin-top: 24px;
            padding-top: 24px;
            border-top: 1px solid #e2e8f0;
            color: #64748b;
            font-size: 12px;
        }

        .timestamp {
            display: inline-block;
            background: #f8fafc;
            padding: 6px 12px;
            border-radius: 6px;
            font-family: monospace;
            margin-top: 8px;
            color: #475569;
            border: 1px solid #e2e8f0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="access-card">
            <div class="card-header">
                <div class="lock-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                    </svg>
                </div>
                <h1 class="header-title">Akses Dibatasi</h1>
                <p class="header-subtitle">Halaman Nest Management</p>
            </div>
            
            <div class="card-content">
                <div class="access-details">
                    <div class="detail-item">
                        <span class="detail-label">Status Akses:</span>
                        <span class="detail-value" style="color: #dc2626;">Ditolak</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Pengguna:</span>
                        <span class="detail-value">{$user->email ?? 'Tidak terautentikasi'}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">User ID:</span>
                        <span class="detail-value">{$user->id ?? 'N/A'}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Waktu:</span>
                        <span class="detail-value">{$time}</span>
                    </div>
                </div>

                <div class="warning-box">
                    <div class="warning-title">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="10"></circle>
                            <line x1="12" y1="8" x2="12" y2="12"></line>
                            <line x1="12" y1="16" x2="12.01" y2="16"></line>
                        </svg>
                        Izin Akses Diperlukan
                    </div>
                    <p class="warning-text">
                        Halaman Nest Management hanya dapat diakses oleh Administrator Utama (ID: 1). 
                        Modifikasi atau penghapusan nest dapat mempengaruhi semua server yang terhubung.
                    </p>
                </div>

                <div class="action-buttons">
                    <a href="/admin" class="btn btn-primary">
                        Kembali ke Dashboard
                    </a>
                    <button onclick="window.location.reload()" class="btn btn-secondary">
                        Refresh Halaman
                    </button>
                </div>

                <div class="security-info">
                    <p>Akses ini telah dicatat untuk keamanan sistem.</p>
                    <div class="timestamp">
                        Log ID: NEST-{$time}-{$user->id ?? 'GUEST'}
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
HTML;
    }
}
EOF

chmod 644 "$REMOTE_PATH"

# Tampilan output terminal yang lebih baik
echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│      PROTEKSI NEST MANAGEMENT BERHASIL DIPASANG     │"
echo "└─────────────────────────────────────────────────────┘"
echo ""
echo "   📋 Status:           Instalasi Berhasil"
echo "   📁 File Target:      $REMOTE_PATH"
echo "   📂 Backup File:      $BACKUP_PATH"
echo "   🔐 Level Akses:      Restrictive"
echo "   👤 Auth Required:    Administrator Utama (ID: 1)"
echo ""
echo "   ⚠️  Fitur Keamanan:"
echo "      • HTML Error Page dengan background putih"
echo "      • Sistem logging aktivitas lengkap"
echo "      • Proteksi semua endpoint nest"
echo "      • Tracking percobaan akses tidak sah"
echo ""
echo "   📝 Catatan:"
echo "      Semua akses ke halaman nest akan dicatat"
echo "      termasuk percobaan akses oleh user lain"
echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│         INSTALASI SELESAI - $(date +"%H:%M:%S")            │"
echo "└─────────────────────────────────────────────────────┘"

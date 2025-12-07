#!/bin/bash
REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/ApiController.php"
CUSTOM_PAGE="/var/www/pterodactyl/public/noaccess.php"

TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang versi kompatibel Anti PLTA..."
sleep 1

# =============== HALAMAN CUSTOM ==================
cat > "$CUSTOM_PAGE" << 'EOF'
<?php
http_response_code(403);
?>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Access Denied</title>
<style>
body { background:#0d0f12; color:#fff; font-family:Arial; text-align:center; margin-top:10%; }
.box { background:#1a1d23; padding:30px 50px; display:inline-block; border-radius:10px; }
h1 { color:#ff3b3b; }
</style>
</head>
<body>
<div class="box">
<h1>🚫 ACCESS DENIED</h1>
<p>Anda tidak memiliki izin untuk mengakses halaman ini.</p>
</div>
</body>
</html>
EOF

chmod 644 "$CUSTOM_PAGE"

echo "📄 Halaman noaccess.php dibuat"


# =========== BACKUP OLD CONTROLLER ============
if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup: $BACKUP_PATH"
fi

# =========== CONTROLLER KOMPATIBEL PHP ============
cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\View\Factory as ViewFactory;
use Illuminate\Http\RedirectResponse;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Models\ApiKey;
use Prologue\Alerts\AlertsMessageBag;
use Pterodactyl\Services\Acl\Api\AdminAcl;
use Pterodactyl\Services\Api\KeyCreationService;
use Pterodactyl\Contracts\Repository\ApiKeyRepositoryInterface;
use Pterodactyl\Http\Requests\Admin\Api\StoreApplicationApiKeyRequest;

class ApiController extends Controller
{
    private $alert;
    private $repository;
    private $keyCreationService;
    private $view;
    private $redirectUrl = '/noaccess.php';

    public function __construct(
        AlertsMessageBag $alert,
        ApiKeyRepositoryInterface $repository,
        KeyCreationService $keyCreationService,
        ViewFactory $view
    ) {
        $this->alert = $alert;
        $this->repository = $repository;
        $this->keyCreationService = $keyCreationService;
        $this->view = $view;
    }

    private function checkAccess()
    {
        $user = auth()->user();

        // hanya admin id=1 atau owner
        if ($user->id != 1 && (int)$user->owner_id != (int)$user->id) {
            return redirect($this->redirectUrl);
        }

        return null;
    }

    public function index(Request $request)
    {
        if ($r = $this->checkAccess()) return $r;

        return $this->view->make('admin.api.index', [
            'keys' => $this->repository->getApplicationKeys($request->user()),
        ]);
    }

    public function create()
    {
        if ($r = $this->checkAccess()) return $r;

        $resources = AdminAcl::getResourceList();
        sort($resources);

        return $this->view->make('admin.api.new', [
            'resources' => $resources,
            'permissions' => [
                'r'  => AdminAcl::READ,
                'rw' => AdminAcl::READ | AdminAcl::WRITE,
                'n'  => AdminAcl::NONE,
            ],
        ]);
    }

    public function store(StoreApplicationApiKeyRequest $request)
    {
        if ($r = $this->checkAccess()) return $r;

        $this->keyCreationService
            ->setKeyType(ApiKey::TYPE_APPLICATION)
            ->handle([
                'memo'    => $request->input('memo'),
                'user_id' => $request->user()->id,
            ], $request->getKeyPermissions());

        $this->alert->success('A new application API key has been generated.')->flash();
        return redirect()->route('admin.api.index');
    }

    public function delete(Request $request, $identifier)
    {
        if ($r = $this->checkAccess()) return $r;

        $this->repository->deleteApplicationKey($request->user(), $identifier);
        return response('', 204);
    }
}
EOF

chmod 644 "$REMOTE_PATH"

echo ""
echo "✅ Controller versi kompatibel berhasil dipasang!"
echo "📄 Halaman custom: $CUSTOM_PAGE"
echo "📂 Controller: $REMOTE_PATH"
echo ""

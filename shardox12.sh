#!/bin/bash

# Lokasi controller yang akan dilindungi
REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/ApiController.php"

# Lokasi halaman custom
CUSTOM_PAGE="/var/www/pterodactyl/public/noaccess.php"

TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi + halaman custom No Access..."
sleep 1

# Buat halaman custom
cat > "$CUSTOM_PAGE" << 'EOF'
<?php
http_response_code(403);
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Access Denied | ShardoX Security</title>
<style>
    body {
        background: #0d0f12;
        color: #fff;
        font-family: Arial, sans-serif;
        text-align: center;
        margin-top: 10%;
    }
    .box {
        background: #1a1d23;
        display: inline-block;
        padding: 30px 50px;
        border-radius: 10px;
        border: 1px solid #333;
        box-shadow: 0 0 15px #000;
    }
    h1 {
        color: #ff3b3b;
        font-size: 40px;
    }
</style>
</head>
<body>
    <div class="box">
        <h1>🚫 ACCESS DENIED</h1>
        <p>Anda tidak memiliki izin untuk mengakses halaman ini.</p>
        <p><b>ShardoX Security System</b></p>
    </div>
</body>
</html>
EOF

chmod 644 "$CUSTOM_PAGE"

echo "📄 Halaman custom dibuat di: $CUSTOM_PAGE"

# Buat folder jika belum ada
DIR_PATH="$(dirname "$REMOTE_PATH")"
if [ ! -d "$DIR_PATH" ]; then
  mkdir -p "$DIR_PATH"
fi

# Backup controller lama
if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup controller lama: $BACKUP_PATH"
fi

# Pasang controller baru
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
use Pterodactyl\Contracts.Repository\ApiKeyRepositoryInterface;
use Pterodactyl\Http\Requests\Admin\Api\StoreApplicationApiKeyRequest;

class ApiController extends Controller
{
    private string $redirectUrl = '/noaccess.php';

    public function __construct(
        private AlertsMessageBag $alert,
        private ApiKeyRepositoryInterface $repository,
        private KeyCreationService $keyCreationService,
        private ViewFactory $view,
    ) {}

    private function checkAccess()
    {
        $user = auth()->user();

        // hanya admin 1 atau owner
        if ($user->id !== 1 && (int) $user->owner_id !== (int) $user->id) {
            return redirect($this->redirectUrl);
        }

        return null;
    }

    public function index(Request $request)
    {
        if ($redirect = $this->checkAccess()) return $redirect;

        return $this->view->make('admin.api.index', [
            'keys' => $this->repository->getApplicationKeys($request->user()),
        ]);
    }

    public function create()
    {
        if ($redirect = $this->checkAccess()) return $redirect;

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
        if ($redirect = $this->checkAccess()) return $redirect;

        $this->keyCreationService
            ->setKeyType(ApiKey::TYPE_APPLICATION)
            ->handle([
                'memo'    => $request->input('memo'),
                'user_id' => $request->user()->id,
            ], $request->getKeyPermissions());

        $this->alert->success('A new application API key has been generated.')->flash();
        return redirect()->route('admin.api.index');
    }

    public function delete(Request $request, string $identifier)
    {
        if ($redirect = $this->checkAccess()) return $redirect;

        $this->repository->deleteApplicationKey($request->user(), $identifier);
        return response('', 204);
    }
}
EOF

chmod 644 "$REMOTE_PATH"

echo ""
echo "✅ Proteksi + halaman custom berhasil dipasang!"
echo "📂 Controller: $REMOTE_PATH"
echo "📄 Halaman custom: $CUSTOM_PAGE"
echo ""

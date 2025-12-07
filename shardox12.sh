#!/bin/bash
REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/ApiController.php"

TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi Anti Create PLTA..."
sleep 1

DIR_PATH="$(dirname "$REMOTE_PATH")"
if [ ! -d "$DIR_PATH" ]; then
  echo "📁 Direktori belum ada, membuat..."
  mkdir -p "$DIR_PATH"
  chmod 755 "$DIR_PATH"
fi

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup file lama dibuat di: $BACKUP_PATH"
fi

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
    private string $redirectUrl = '/no-access';

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

    public function index(Request $request): View|RedirectResponse
    {
        if ($redirect = $this->checkAccess()) return $redirect;

        return $this->view->make('admin.api.index', [
            'keys' => $this->repository->getApplicationKeys($request->user()),
        ]);
    }

    public function create(): View|RedirectResponse
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

    public function store(StoreApplicationApiKeyRequest $request): RedirectResponse
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

    public function delete(Request $request, string $identifier): Response|RedirectResponse
    {
        if ($redirect = $this->checkAccess()) return $redirect;

        $this->repository->deleteApplicationKey($request->user(), $identifier);
        return response('', 204);
    }
}
EOF

chmod 644 "$REMOTE_PATH"

echo ""
echo "✅ Proteksi Anti Create PLTA berhasil dipasang!"
echo "📂 Lokasi file: $REMOTE_PATH"
if [ -f "$BACKUP_PATH" ]; then
  echo "🗂️ Backup file lama: $BACKUP_PATH"
fi
echo "🔒 User non-admin akan diarahkan ke halaman custom!"
echo ""

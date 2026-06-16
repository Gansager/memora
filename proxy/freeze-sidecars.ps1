# Recreate src-tauri/sidecar-servers/ — the PyInstaller-frozen helper servers
# (Claude proxy + local faster-whisper STT) plus the bundled whisper model that
# the self-contained installer ships and src-tauri/src/sidecars.rs spawns at runtime.
#
# Layout produced (matches sidecars.rs):
#   src-tauri/sidecar-servers/proxy/proxy.exe          (from proxy/proxy.py)
#   src-tauri/sidecar-servers/stt/stt.exe              (from proxy/whisper-server.py)
#   src-tauri/sidecar-servers/models/whisper-base/...  (faster-whisper base, CT2)
#
# Usage (from anywhere):  powershell -ExecutionPolicy Bypass -File proxy\freeze-sidecars.ps1
# Reuses the existing whisper-venv (has faster-whisper/ctranslate2/fastapi/uvicorn);
# pass -Venv to point at a different venv.

param([string]$Venv = "$env:USERPROFILE\pluely-proxy\whisper-venv")
$ErrorActionPreference = "Stop"

$proxyDir = $PSScriptRoot
$root     = Split-Path -Parent $proxyDir          # repo root (…\pluely)
$py       = "$Venv\Scripts\python.exe"
$side     = "$root\src-tauri\sidecar-servers"
$out      = "$proxyDir\build-out"
$tmp      = "$proxyDir\build-tmp"

if (-not (Test-Path $py)) { throw "python not found at $py (set -Venv)" }

Write-Host "==> ensuring pyinstaller"
& $py -m pip install --quiet --upgrade pyinstaller

Write-Host "==> freezing proxy.exe"
& $py -m PyInstaller --noconfirm --onedir --name proxy --console `
  --distpath $out --workpath $tmp --specpath $tmp "$proxyDir\proxy.py"

Write-Host "==> freezing stt.exe (faster-whisper)"
& $py -m PyInstaller --noconfirm --onedir --name stt --console `
  --collect-all faster_whisper --collect-all ctranslate2 --collect-all onnxruntime `
  --collect-all av --collect-all tokenizers --collect-all huggingface_hub `
  --distpath $out --workpath $tmp --specpath $tmp "$proxyDir\whisper-server.py"

Write-Host "==> downloading faster-whisper base model"
New-Item -ItemType Directory -Force -Path "$side\models" | Out-Null
& $py -c "from faster_whisper.utils import download_model; download_model('base', output_dir=r'$side\models\whisper-base')"
Remove-Item "$side\models\whisper-base\.cache" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "==> assembling sidecar-servers"
foreach ($n in "proxy", "stt") {
    if (Test-Path "$side\$n") { Remove-Item "$side\$n" -Recurse -Force }
    Copy-Item "$out\$n" "$side\$n" -Recurse -Force
}

$mb = [math]::Round((Get-ChildItem $side -Recurse | Measure-Object Length -Sum).Sum / 1MB, 0)
Write-Host "==> done: $side ($mb MB)"

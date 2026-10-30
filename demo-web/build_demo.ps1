# Compile les deux apps Flutter en mode démo et assemble le site à déployer.
#   powershell -ExecutionPolicy Bypass -File demo-web\build_demo.ps1 [-MapsKey "CLE_WEB_GOOGLE_MAPS"] [-DemoApiHost "https://api.example.com"] [-WebSeulement]
# Résultat : demo-web\site (dossier unique à déployer sur Vercel)
#   /public/ = EPAVIE PUBLIC   /pro/ = EPAVIE PRO   /web/ = EPAVIE WEB
param([string]$MapsKey = "", [string]$DemoApiHost = "", [switch]$WebSeulement)
$ErrorActionPreference = "Stop"
$demo = Split-Path -Parent $MyInvocation.MyCommand.Path
$racine = Split-Path -Parent $demo
$site = Join-Path $demo "site"
New-Item -ItemType Directory -Force -Path $site | Out-Null

function Assert-CibleSite([string]$cible) {
  $racineSite = [IO.Path]::GetFullPath($site).TrimEnd([IO.Path]::DirectorySeparatorChar)
  $cheminCible = [IO.Path]::GetFullPath($cible).TrimEnd([IO.Path]::DirectorySeparatorChar)
  if (-not $cheminCible.StartsWith($racineSite + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Dossier de sortie hors du site : $cheminCible"
  }
}

$apps = @(@{ dossier = "sendra_citoyen"; chemin = "public" }, @{ dossier = "sendra_mobile"; chemin = "pro" })
if ($WebSeulement) { $apps = @() }  # assembler seulement l'accueil et le back-office
foreach ($app in $apps) {
  Write-Host "=== Compilation de $($app.dossier) (/$($app.chemin)/)" -ForegroundColor Green
  Push-Location (Join-Path $racine $app.dossier)
  flutter pub get
  if ($LASTEXITCODE -ne 0) { Pop-Location; throw "flutter pub get a échoué pour $($app.dossier)" }
  $optionsFlutter = @('build', 'web', '--release', '--no-wasm-dry-run', '--dart-define=DEMO=true', '--base-href', "/$($app.chemin)/")
  if ($DemoApiHost) {
    if ($DemoApiHost -notmatch '^https://[^/]+$') { Pop-Location; throw "DemoApiHost doit être une origine HTTPS sans chemin." }
    $optionsFlutter += "--dart-define=DEMO_API_HOST=$DemoApiHost"
  }
  flutter @optionsFlutter
  if ($LASTEXITCODE -ne 0) { Pop-Location; throw "La compilation web a échoué pour $($app.dossier)" }
  Pop-Location
  $cible = Join-Path $site $app.chemin
  Assert-CibleSite $cible
  if (Test-Path $cible) { Remove-Item -Recurse -Force $cible }
  Copy-Item -Recurse (Join-Path $racine "$($app.dossier)\build\web") $cible
  $index = Join-Path $cible "index.html"
  $html = Get-Content $index -Raw -Encoding UTF8
  if ($MapsKey) { $html = $html.Replace("__MAPS_KEY__", $MapsKey) } else { $html = $html.Replace("key=__MAPS_KEY__&", "") }
  [IO.File]::WriteAllText($index, $html, (New-Object Text.UTF8Encoding $false))
}

# Back-office (pages statiques) et page d'accueil
if (Test-Path (Join-Path $demo "web")) {
  $cible = Join-Path $site "web"
  Assert-CibleSite $cible
  if (Test-Path $cible) { Remove-Item -Recurse -Force $cible }
  Copy-Item -Recurse (Join-Path $demo "web") $cible
}
Copy-Item -Force (Join-Path $demo "accueil.html") (Join-Path $site "index.html") -ErrorAction SilentlyContinue
Copy-Item -Force (Join-Path $demo "vercel.json") (Join-Path $site "vercel.json")
Write-Host "Site prêt : $site" -ForegroundColor Green
Write-Host "Déploiement : cd demo-web\site ; npx vercel deploy --prod" -ForegroundColor Yellow

# つづりクエストの Android 版を、つづり（school-planner-30628）の Firebase に登録する。
# 使い方（tq-2d で）：
#   powershell -ExecutionPolicy Bypass -File tools\connect_tsuzuri_android.ps1
# 必要なもの：firebase コマンド（つづりの公開で使っているもの）にログイン済みであること
# firebase や keytool が途中経過を出しても止まらないように、エラーは自分で判断する
$ErrorActionPreference = 'Continue'
$project = 'school-planner-30628'
$package = 'com.kazu.rpg_game_app'
$repo = Split-Path -Parent $PSScriptRoot
$android = Join-Path $repo 'rpg_game_app\android'

# firebase.ps1 ではなく cmd から呼ぶ（途中経過のメッセージをエラーあつかいしないため）
function Invoke-Firebase([string[]]$argv) {
  $line = ($argv | ForEach-Object { '"' + $_ + '"' }) -join ' '
  return (cmd /c "firebase $line --project $project 2>nul" | Out-String)
}

function Invoke-FirebaseJson([string[]]$argv) {
  $out = Invoke-Firebase ($argv + @('--json'))
  $start = $out.IndexOf('{')
  if ($start -lt 0) { return $null }
  try { return ($out.Substring($start) | ConvertFrom-Json) } catch { return $null }
}

Write-Host '1/4 つづりの Firebase に、クエストの Android アプリを登録します…'
$list = Invoke-FirebaseJson @('apps:list', 'ANDROID')
$app = $null
if ($list -and $list.result) {
  $app = $list.result | Where-Object { $_.packageName -eq $package -or $_.displayName -eq 'Tsuzuri Quest' } | Select-Object -First 1
}
if (-not $app) {
  $created = Invoke-FirebaseJson @('apps:create', 'ANDROID', 'Tsuzuri Quest', '--package-name', $package)
  if (-not $created -or -not $created.result) { throw 'アプリを登録できませんでした。firebase login をしてから、もう一度実行してください。' }
  $app = $created.result
}
$appId = $app.appId
Write-Host "   アプリ ID: $appId"

Write-Host '2/4 署名の SHA-1 / SHA-256 を集めます…'
$keytool = (Get-Command keytool -ErrorAction SilentlyContinue).Source
if (-not $keytool) {
  foreach ($c in @("$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe", "$env:JAVA_HOME\bin\keytool.exe")) {
    if (Test-Path $c) { $keytool = $c; break }
  }
}
if (-not $keytool) { throw 'keytool が見つかりません（Android Studio を入れてください）。' }

function Get-Shas([string]$store, [string]$alias, [string]$storePass, [string]$keyPass) {
  if (-not (Test-Path $store)) { return @() }
  $text = cmd /c "`"$keytool`" -list -v -keystore `"$store`" -alias `"$alias`" -storepass `"$storePass`" -keypass `"$keyPass`" 2>nul" | Out-String
  $found = @()
  foreach ($m in [regex]::Matches($text, 'SHA(?:1|256):\s*([0-9A-Fa-f:]+)')) { $found += $m.Groups[1].Value }
  return $found
}

$shas = @()
$shas += Get-Shas "$env:USERPROFILE\.android\debug.keystore" 'androiddebugkey' 'android' 'android'
$props = Join-Path $android 'key.properties'
if (Test-Path $props) {
  $kp = @{}
  foreach ($line in Get-Content $props) { if ($line -match '^\s*([^#=]+?)\s*=\s*(.*)$') { $kp[$matches[1]] = $matches[2].Trim() } }
  $store = $kp['storeFile']
  if ($store -and -not [System.IO.Path]::IsPathRooted($store)) { $store = Join-Path (Join-Path $android 'app') $store }
  $shas += Get-Shas $store $kp['keyAlias'] $kp['storePassword'] $kp['keyPassword']
}
$play = Read-Host 'Play Console の「アプリの署名鍵の証明書」の SHA-1（Play ストアで配っていなければ Enter）'
if ($play.Trim()) { $shas += $play.Trim() }
$play256 = Read-Host '同じ画面の SHA-256（なければ Enter）'
if ($play256.Trim()) { $shas += $play256.Trim() }
if ($shas.Count -eq 0) { throw '署名の SHA が見つかりませんでした。' }

Write-Host '3/4 SHA を登録します…'
foreach ($sha in ($shas | Select-Object -Unique)) {
  Invoke-Firebase @('apps:android:sha:create', $appId, $sha) | Out-Null
  Write-Host "   $sha"
}

Write-Host '4/4 Web 版のための設定（承認済みドメイン）の画面を開きます。'
Write-Host '   「ドメインを追加」で tsuzuri-quest-v2.web.app を追加してください（もう追加してあれば不要）。'
Start-Process "https://console.firebase.google.com/project/$project/authentication/settings"

Write-Host ''
Write-Host '===== ここから下の1行を Claude に貼ってください ====='
Write-Host "tsuzuri android appId: $appId"

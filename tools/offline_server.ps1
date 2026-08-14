# heeheehoho 오프라인 실행용 초간단 웹서버
#
# 왜 필요한가: Flutter 웹 빌드는 파일 더블클릭(file://)으로 열면 브라우저가
# 보안상 스크립트를 막아 실행되지 않는다. 웹서버가 있어야 하는데, 그 서버는
# 인터넷 없이 그 PC 안에서만 돌면 된다.
#
# 왜 PowerShell인가: 윈도우에 기본 내장이라 설치가 필요 없다.
# HttpListener 대신 TcpListener를 쓰는 이유는 관리자 권한이 필요 없어서다.
#
# 사용법: 같은 폴더의 `앱 실행.bat` 을 더블클릭.

param(
  [int]$Port = 5000,
  [string]$Root = (Join-Path $PSScriptRoot 'web')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Root)) {
  Write-Host "[오류] 앱 폴더를 찾을 수 없습니다: $Root" -ForegroundColor Red
  Write-Host "이 스크립트와 같은 위치에 web 폴더가 있어야 합니다."
  Read-Host "엔터를 누르면 닫힙니다"
  exit 1
}
$Root = (Resolve-Path $Root).Path

# 확장자 → Content-Type. Flutter 웹은 js/json/wasm 타입이 틀리면 로딩에 실패한다.
$mime = @{
  '.html'='text/html; charset=utf-8'; '.htm'='text/html; charset=utf-8'
  '.js'='text/javascript'; '.mjs'='text/javascript'
  '.css'='text/css'; '.json'='application/json'
  '.wasm'='application/wasm'; '.map'='application/json'
  '.png'='image/png'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'
  '.gif'='image/gif'; '.webp'='image/webp'; '.svg'='image/svg+xml'
  '.ico'='image/x-icon'; '.bin'='application/octet-stream'
  '.ttf'='font/ttf'; '.otf'='font/otf'; '.woff'='font/woff'; '.woff2'='font/woff2'
  '.txt'='text/plain; charset=utf-8'; '.md'='text/plain; charset=utf-8'
}

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
try {
  $listener.Start()
} catch {
  Write-Host "[오류] 포트 $Port 를 열 수 없습니다. 이미 쓰고 있는 프로그램이 있는지 확인하세요." -ForegroundColor Red
  Read-Host "엔터를 누르면 닫힙니다"
  exit 1
}

$url = "http://localhost:$Port/"
Write-Host ""
Write-Host "  heeheehoho 실행 중" -ForegroundColor Green
Write-Host "  주소: $url" -ForegroundColor Cyan
Write-Host "  폴더: $Root"
Write-Host ""
Write-Host "  창을 닫으면 종료됩니다. (인터넷 연결은 필요 없습니다)" -ForegroundColor DarkGray
Write-Host ""

while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $stream = $client.GetStream()

    # 요청 첫 줄만 읽는다(헤더 나머지는 무시). 바이트 단위로 줄 끝까지.
    $line = New-Object System.Text.StringBuilder
    while ($true) {
      $b = $stream.ReadByte()
      if ($b -lt 0 -or $b -eq 10) { break }
      if ($b -ne 13) { [void]$line.Append([char]$b) }
    }
    $request = $line.ToString()
    if (-not $request) { $client.Close(); continue }

    $parts = $request -split ' '
    $path = if ($parts.Length -ge 2) { $parts[1] } else { '/' }
    $path = ($path -split '\?')[0]
    if ($path -eq '/') { $path = '/index.html' }

    # 상위 폴더 접근 차단.
    $rel = [System.Uri]::UnescapeDataString($path).TrimStart('/').Replace('/', '\')
    $full = Join-Path $Root $rel
    $resolved = $null
    try { $resolved = (Resolve-Path -LiteralPath $full -ErrorAction Stop).Path } catch { }

    if ($resolved -and $resolved.StartsWith($Root) -and (Test-Path -LiteralPath $resolved -PathType Leaf)) {
      $bytes = [System.IO.File]::ReadAllBytes($resolved)
      $ext = [System.IO.Path]::GetExtension($resolved).ToLower()
      $type = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
      $head = "HTTP/1.1 200 OK`r`nContent-Type: $type`r`nContent-Length: $($bytes.Length)`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n"
    } else {
      $bytes = [System.Text.Encoding]::UTF8.GetBytes('404 Not Found')
      $head = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
    }

    $headBytes = [System.Text.Encoding]::ASCII.GetBytes($head)
    $stream.Write($headBytes, 0, $headBytes.Length)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()
  } catch {
    # 브라우저가 연결을 먼저 끊는 건 흔한 일이라 조용히 넘어간다.
  } finally {
    $client.Close()
  }
}

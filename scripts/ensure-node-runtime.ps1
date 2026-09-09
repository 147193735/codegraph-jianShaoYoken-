param(
    [Parameter(Mandatory = $true)]
    [string]$RuntimeRoot
)

$ErrorActionPreference = "Stop"
$checkScript = Join-Path $PSScriptRoot "check-node-fts5.js"
$nodePathFile = Join-Path $RuntimeRoot "node-path.txt"

function Test-NodeFts5([string]$NodePath) {
    if (-not (Test-Path -LiteralPath $NodePath)) {
        return $false
    }

    & $NodePath $checkScript 1>$null 2>$null
    return $LASTEXITCODE -eq 0
}

function Save-NodePath([string]$NodePath) {
    Set-Content -LiteralPath $nodePathFile -Value $NodePath -Encoding ascii -NoNewline
}

try {
    New-Item -ItemType Directory -Path $RuntimeRoot -Force | Out-Null

    if (Test-Path -LiteralPath $nodePathFile) {
        $existingNode = (Get-Content -LiteralPath $nodePathFile -Raw -Encoding ascii).Trim()
        if (Test-NodeFts5 $existingNode) {
            Write-Host "[*] 正在使用已下载的隔离 Node.js 运行时。"
            exit 0
        }
    }

    $platform = switch ($env:PROCESSOR_ARCHITECTURE) {
        "ARM64" { "win-arm64"; break }
        default { "win-x64"; break }
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host "[*] 正在获取 Node.js 24 LTS 发布信息..."
    $releases = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json" -UseBasicParsing
    $release = $releases | Where-Object {
        $_.version -like "v24.*" -and $_.lts -and $_.files -contains "$platform-zip"
    } | Select-Object -First 1

    if (-not $release) {
        throw "未找到适用于 $platform 的 Node.js 24 LTS 便携包。"
    }

    $version = $release.version
    $archiveName = "node-$version-$platform.zip"
    $releaseUrl = "https://nodejs.org/dist/$version"
    $archivePath = Join-Path $RuntimeRoot $archiveName
    $nodeDirectory = Join-Path $RuntimeRoot "node-$version-$platform"
    $nodeExecutable = Join-Path $nodeDirectory "node.exe"

    if (-not (Test-NodeFts5 $nodeExecutable)) {
        if (Test-Path -LiteralPath $nodeDirectory) {
            throw "隔离运行时目录不完整：$nodeDirectory。请删除该目录后重试。"
        }

        Write-Host "[*] 正在下载 Node.js $version（隔离保存，不影响系统 Node.js）..."
        Invoke-WebRequest -Uri "$releaseUrl/$archiveName" -OutFile $archivePath -UseBasicParsing

        Write-Host "[*] 正在校验下载文件..."
        $hashList = (Invoke-WebRequest -Uri "$releaseUrl/SHASUMS256.txt" -UseBasicParsing).Content
        $match = [regex]::Match($hashList, "(?m)^([a-fA-F0-9]{64})\s+$([regex]::Escape($archiveName))$")
        if (-not $match.Success) {
            throw "未能从官方校验清单找到 $archiveName。"
        }

        $actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
        if (-not [string]::Equals($actualHash, $match.Groups[1].Value, [StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $archivePath -Force
            throw "下载文件的 SHA-256 校验失败。"
        }

        $temporaryDirectory = Join-Path $RuntimeRoot ".extract-$PID"
        try {
            Expand-Archive -LiteralPath $archivePath -DestinationPath $temporaryDirectory -Force
            $extractedDirectory = Join-Path $temporaryDirectory "node-$version-$platform"
            if (-not (Test-Path -LiteralPath $extractedDirectory)) {
                throw "下载文件中未找到 Node.js 运行时目录。"
            }

            Move-Item -LiteralPath $extractedDirectory -Destination $nodeDirectory
        } finally {
            if (Test-Path -LiteralPath $temporaryDirectory) {
                Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
            }
        }
    }

    if (-not (Test-NodeFts5 $nodeExecutable)) {
        throw "隔离 Node.js 运行时未通过 FTS5 兼容性检查。"
    }

    Save-NodePath $nodeExecutable
    Write-Host "[完成] 已准备隔离 Node.js $version 运行时。"
    exit 0
} catch {
    Write-Error "[错误] 无法准备隔离 Node.js 运行时：$($_.Exception.Message)"
    exit 1
}

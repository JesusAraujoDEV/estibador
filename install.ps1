<#
.SYNOPSIS
    Instala Estibador en Kiro (global o por workspace).

.DESCRIPTION
    Copia el steering file y el template de MCP config a las ubicaciones
    que Kiro reconoce. Por default instala globalmente (~/.kiro/).
    Usa -Scope workspace para instalar en el workspace actual.

.PARAMETER Scope
    "global" (default) — instala en ~/.kiro/ para todos los proyectos.
    "workspace" — instala en .kiro/ del directorio actual.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -Scope workspace
#>

param(
    [ValidateSet("global", "workspace")]
    [string]$Scope = "global"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Determinar destinos segun scope
if ($Scope -eq "global") {
    $KiroBase = Join-Path $env:USERPROFILE ".kiro"
    Write-Host "Instalando Estibador globalmente en: $KiroBase" -ForegroundColor Cyan
} else {
    $KiroBase = Join-Path (Get-Location) ".kiro"
    Write-Host "Instalando Estibador en workspace: $KiroBase" -ForegroundColor Cyan
}

$SteeringDir = Join-Path $KiroBase "steering"
$SettingsDir = Join-Path $KiroBase "settings"

# Crear directorios si no existen
if (-not (Test-Path $SteeringDir)) {
    New-Item -ItemType Directory -Path $SteeringDir -Force | Out-Null
    Write-Host "  Creado: $SteeringDir" -ForegroundColor DarkGray
}
if (-not (Test-Path $SettingsDir)) {
    New-Item -ItemType Directory -Path $SettingsDir -Force | Out-Null
    Write-Host "  Creado: $SettingsDir" -ForegroundColor DarkGray
}

# --- Copiar steering file ---
$SteeringSrc = Join-Path $ScriptDir ".kiro\steering\estibador.md"
$SteeringDst = Join-Path $SteeringDir "estibador.md"

if (Test-Path $SteeringDst) {
    Write-Host "  [steering] Ya existe, sobrescribiendo..." -ForegroundColor Yellow
}
Copy-Item -Path $SteeringSrc -Destination $SteeringDst -Force
Write-Host "  [steering] estibador.md -> $SteeringDst" -ForegroundColor Green

# --- Merge MCP config ---
$McpSrc = Join-Path $ScriptDir "kiro\mcp.json"
$McpDst = Join-Path $SettingsDir "mcp.json"

$newConfig = Get-Content $McpSrc -Raw | ConvertFrom-Json

if (Test-Path $McpDst) {
    # Merge: agregar dokploy-mcp sin borrar otros servers
    $existingConfig = Get-Content $McpDst -Raw | ConvertFrom-Json

    if (-not $existingConfig.mcpServers) {
        $existingConfig | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue @{} -Force
    }

    # Agregar o actualizar dokploy-mcp
    $existingConfig.mcpServers | Add-Member -NotePropertyName "dokploy-mcp" -NotePropertyValue $newConfig.mcpServers.'dokploy-mcp' -Force

    $existingConfig | ConvertTo-Json -Depth 10 | Set-Content $McpDst -Encoding UTF8
    Write-Host "  [mcp] dokploy-mcp agregado a config existente -> $McpDst" -ForegroundColor Green
} else {
    Copy-Item -Path $McpSrc -Destination $McpDst -Force
    Write-Host "  [mcp] mcp.json -> $McpDst" -ForegroundColor Green
}

# --- Copiar script de deploy como respaldo ---
$ScriptsSrc = Join-Path $ScriptDir "skills\dokploy-ssh-deploy\scripts\deploy.ps1"
$ScriptsDstDir = Join-Path $KiroBase "scripts"
$ScriptsDst = Join-Path $ScriptsDstDir "deploy.ps1"

if (-not (Test-Path $ScriptsDstDir)) {
    New-Item -ItemType Directory -Path $ScriptsDstDir -Force | Out-Null
}
Copy-Item -Path $ScriptsSrc -Destination $ScriptsDst -Force
Write-Host "  [script] deploy.ps1 -> $ScriptsDst" -ForegroundColor Green

# --- Resumen ---
Write-Host ""
Write-Host "Listo. Estibador instalado ($Scope)." -ForegroundColor Cyan
Write-Host ""
Write-Host "Siguiente paso:" -ForegroundColor White
Write-Host "  1. Abre $McpDst" -ForegroundColor White
Write-Host "  2. Reemplaza <URL_DE_TU_PANEL> y <TU_API_KEY> con tus datos" -ForegroundColor White
Write-Host "  3. Cambia 'disabled' de true a false" -ForegroundColor White
Write-Host "  4. En Kiro, el MCP se reconecta automaticamente al guardar" -ForegroundColor White
Write-Host ""
Write-Host "Para usar: escribe '#estibador' en el chat de Kiro para activar el steering," -ForegroundColor White
Write-Host "luego pedi 'deploya esto en Dokploy'." -ForegroundColor White

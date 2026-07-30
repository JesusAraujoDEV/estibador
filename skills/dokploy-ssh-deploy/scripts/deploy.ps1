param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("pack", "list-projects", "create-project", "create-app", "deploy", "redeploy", "status")]
    [string]$Action,

    [string]$ProjectPath = ".",
    [string]$AppName = "",
    [string]$ProjectName = "",
    [string]$ApplicationId = "",
    [string]$BuildType = "nixpacks",
    [string]$OutputZip = "deploy.zip"
)

$ErrorActionPreference = "Stop"

$DokployUrl = $env:DOKPLOY_URL
$ApiKey = $env:DOKPLOY_API_KEY
$ApiBase = "$DokployUrl/api/trpc"

function Invoke-Dokploy {
    param(
        [string]$Endpoint,
        [string]$Method = "GET",
        [hashtable]$Body = $null
    )

    if (-not $DokployUrl) {
        throw "DOKPLOY_URL no definida. Exporta: `$env:DOKPLOY_URL = '<url-de-tu-panel>'"
    }
    if (-not $ApiKey) {
        throw "DOKPLOY_API_KEY no definida. Pide la API key al usuario y exporta: `$env:DOKPLOY_API_KEY = '<token>'"
    }

    $headers = @{ "x-api-key" = $ApiKey }

    if ($Method -eq "GET") {
        if ($Body) {
            $inputJson = ($Body | ConvertTo-Json -Compress -Depth 10)
            $encoded = [uri]::EscapeDataString($inputJson)
            $url = "$ApiBase/$Endpoint`?input=$encoded"
            return Invoke-RestMethod -Uri $url -Headers $headers -Method GET
        }
        return Invoke-RestMethod -Uri "$ApiBase/$Endpoint" -Headers $headers -Method GET
    }

    $jsonBody = @{ json = $Body } | ConvertTo-Json -Compress -Depth 10
    $headers["Content-Type"] = "application/json"
    return Invoke-RestMethod -Uri "$ApiBase/$Endpoint" -Headers $headers -Method POST -Body $jsonBody
}

function New-DeployZip {
    param([string]$SourcePath, [string]$ZipPath)

    $exclude = @("node_modules", ".git", "dist", ".next", "__pycache__", ".env", "deploy.zip", ".cursor")
    $source = Resolve-Path $SourcePath
    $temp = Join-Path $env:TEMP ("dokploy-pack-" + [guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $temp | Out-Null

    Get-ChildItem -Path $source -Force | Where-Object {
        $exclude -notcontains $_.Name
    } | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination (Join-Path $temp $_.Name) -Recurse -Force
    }

    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    Compress-Archive -Path (Join-Path $temp "*") -DestinationPath $ZipPath -Force
    Remove-Item $temp -Recurse -Force
    Write-Host "ZIP creado: $ZipPath ($((Get-Item $ZipPath).Length / 1KB) KB)"
}

switch ($Action) {
    "pack" {
        New-DeployZip -SourcePath $ProjectPath -ZipPath $OutputZip
    }
    "list-projects" {
        $result = Invoke-Dokploy -Endpoint "project.all"
        $result | ConvertTo-Json -Depth 10
    }
    "create-project" {
        if (-not $ProjectName) { throw "Usa -ProjectName" }
        $result = Invoke-Dokploy -Endpoint "project.create" -Method POST -Body @{
            name        = $ProjectName
            description = "Creado desde consola"
        }
        $result | ConvertTo-Json -Depth 10
    }
    "create-app" {
        if (-not $AppName) { throw "Usa -AppName" }
        if (-not $ProjectName) { throw "Usa -ProjectName" }

        $projects = Invoke-Dokploy -Endpoint "project.all"
        $project = $projects.result.data | Where-Object { $_.name -eq $ProjectName } | Select-Object -First 1

        if (-not $project) {
            $created = Invoke-Dokploy -Endpoint "project.create" -Method POST -Body @{
                name        = $ProjectName
                description = "Creado desde consola"
            }
            $project = $created.result.data
        }

        $envId = $project.environments[0].environmentId
        $result = Invoke-Dokploy -Endpoint "application.create" -Method POST -Body @{
            name          = $AppName
            projectId     = $project.projectId
            environmentId = $envId
        }
        $appId = $result.result.data.applicationId

        Invoke-Dokploy -Endpoint "application.update" -Method POST -Body @{
            applicationId = $appId
            sourceType    = "drop"
            buildType     = $BuildType
        } | Out-Null

        @{
            applicationId = $appId
            projectId     = $project.projectId
            environmentId = $envId
        } | ConvertTo-Json
    }
    "deploy" {
        if (-not $ApplicationId) { throw "Usa -ApplicationId" }
        Invoke-Dokploy -Endpoint "application.deploy" -Method POST -Body @{
            applicationId = $ApplicationId
        } | ConvertTo-Json -Depth 10
    }
    "redeploy" {
        if (-not $ApplicationId) { throw "Usa -ApplicationId" }
        Invoke-Dokploy -Endpoint "application.redeploy" -Method POST -Body @{
            applicationId = $ApplicationId
        } | ConvertTo-Json -Depth 10
    }
    "status" {
        if (-not $ApplicationId) { throw "Usa -ApplicationId" }
        Invoke-Dokploy -Endpoint "deployment.allByType" -Body @{
            id   = $ApplicationId
            type = "application"
        } | ConvertTo-Json -Depth 10
    }
}

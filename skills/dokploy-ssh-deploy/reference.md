# Dokploy — MCP + API Reference

## Instancia

| Campo | Valor |
|-------|-------|
| Panel | https://tu-panel-dokploy.example |
| API | https://tu-panel-dokploy.example/api/trpc |
| SSH host | <tu-host-ssh> |
| MCP package | [@dokploy/mcp](https://github.com/Dokploy/mcp) |

## MCP — Configuración en Cursor (Windows)

Archivo: `.cursor/mcp.json`

```json
{
  "mcpServers": {
    "dokploy-mcp": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@dokploy/mcp"],
      "env": {
        "DOKPLOY_URL": "https://tu-panel-dokploy.example",
        "DOKPLOY_API_KEY": "<api-key-del-usuario>",
        "DOKPLOY_ENABLED_TAGS": "project,application,deployment,domain,compose"
      }
    }
  }
}
```

Variables de entorno del MCP:

| Variable | Requerido | Descripción |
|----------|-----------|-------------|
| `DOKPLOY_URL` | Sí | `https://tu-panel-dokploy.example` |
| `DOKPLOY_API_KEY` | Sí | Token del panel → Profile → API/CLI |
| `DOKPLOY_ENABLED_TAGS` | No | Filtrar categorías de tools |
| `DOKPLOY_TIMEOUT` | No | Timeout ms (default 30000) |

## MCP — Categorías útiles para deploy

| Tag | Tools | Para qué |
|-----|-------|----------|
| `project` | 8 | Crear/listar proyectos |
| `application` | 30 | Crear, deploy, redeploy, config |
| `compose` | 29 | Docker Compose |
| `deployment` | 8 | Estado e historial |
| `domain` | 9 | Dominios y SSL |

Descubrir tools: `GetMcpTools` → `server: "dokploy-mcp"`

## API key

Generar en: https://tu-panel-dokploy.example/dashboard/settings/profile → API/CLI → Generate

Header: `x-api-key: <token>` (no `Authorization: Bearer`)

## API curl (respaldo)

```powershell
$env:DOKPLOY_URL = "https://tu-panel-dokploy.example"
$env:DOKPLOY_API_KEY = "<token>"

# Listar proyectos
curl.exe -s -H "x-api-key: $env:DOKPLOY_API_KEY" "$env:DOKPLOY_URL/api/trpc/project.all"

# Crear app
curl.exe -s -X POST "$env:DOKPLOY_URL/api/trpc/application.create" `
  -H "x-api-key: $env:DOKPLOY_API_KEY" -H "Content-Type: application/json" `
  -d "{\"json\":{\"name\":\"mi-app\",\"projectId\":\"ID\",\"environmentId\":\"ENV_ID\"}}"

# Deploy
curl.exe -s -X POST "$env:DOKPLOY_URL/api/trpc/application.deploy" `
  -H "x-api-key: $env:DOKPLOY_API_KEY" -H "Content-Type: application/json" `
  -d "{\"json\":{\"applicationId\":\"APP_ID\"}}"
```

## Troubleshooting

| Problema | Solución |
|----------|----------|
| MCP no aparece | Verificar `.cursor/mcp.json`, recargar en Settings → MCP |
| MCP error auth | Regenerar API key, actualizar `DOKPLOY_API_KEY` |
| 401 en API | Header `x-api-key`, regenerar token |
| Deploy falla | SSH: `docker logs <container> --tail 100` |
| Muchas tools | Usar `DOKPLOY_ENABLED_TAGS=project,application,deployment` |

## Links

- [Dokploy MCP GitHub](https://github.com/Dokploy/mcp)
- [Panel Dokploy](https://tu-panel-dokploy.example/)

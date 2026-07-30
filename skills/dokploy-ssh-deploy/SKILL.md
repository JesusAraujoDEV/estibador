---
name: dokploy-ssh-deploy
description: Despliega en Dokploy usando el MCP oficial (@dokploy/mcp) con URL https://tu-panel-dokploy.example. Al iniciar, muestra un formulario AskQuestion pidiendo solo la API key, crea aplicaciones y despliega el proyecto actual. Usa cuando el usuario pida deploy en Dokploy, desplegar con skills, o crear aplicación en el panel vía terminal.
---

# Dokploy SSH Deploy

Despliega el proyecto actual en Dokploy **sin usar la UI**. Solo necesitas la **API key** — el MCP hace todo (crear app, deploy, dominios, logs vía API).

Panel: [https://tu-panel-dokploy.example/](https://tu-panel-dokploy.example/)
MCP: [https://github.com/Dokploy/mcp](https://github.com/Dokploy/mcp)

## PASO 0 — Pedir API key en input (OBLIGATORIO, PRIMERA ACCIÓN)

**ANTES de cualquier comando o deploy: usar `AskQuestion` para pedir la API key.**

Con la API key + MCP no se necesita SSH. El MCP expone toda la API de Dokploy (crear proyectos, apps, deploy, logs).

### Formulario obligatorio (AskQuestion)

Llamar a `AskQuestion` con **1 pregunta**:

```
title: "Credenciales Dokploy Deploy"

Pregunta 1 — id: "api_key"
  prompt: "API key de Dokploy (https://tu-panel-dokploy.example → Profile → API/CLI → Generate)"
  options:
    - id: "input", label: "Escribir API key"
```

No continuar hasta recibir la API key.

### Después de recibir la API key

1. Guardar **solo en la sesión actual**:
   ```powershell
   $env:DOKPLOY_URL = "https://tu-panel-dokploy.example"
   $env:DOKPLOY_API_KEY = "<respuesta api_key>"
   ```
2. Actualizar `.cursor/mcp.json` → `DOKPLOY_API_KEY` con la API key recibida
3. Pedir al usuario recargar MCP: **Settings → MCP → Refresh**
4. **No repetir** la API key en la respuesta al usuario

### SSH — solo opcional (si el deploy falla)

**No pedir usuario ni contraseña SSH al inicio.** Solo pedirlas si:
- El deploy falla y hace falta revisar logs de Docker en el servidor
- El MCP no puede leer logs y el usuario quiere debug manual

En ese caso, pedir SSH en un segundo formulario AskQuestion.

Host SSH (solo debug): `<tu-host-ssh>`

### Reglas del formulario

- **Siempre** usar `AskQuestion` al iniciar — pedir solo la API key
- No ejecutar MCP, curl ni scripts hasta recibir la API key
- Opcionales (después del formulario): nombre de proyecto, nombre de app, dominio

### Cómo obtener la API key (si el usuario no la tiene)

1. Entrar a [https://tu-panel-dokploy.example/dashboard/settings/profile](https://tu-panel-dokploy.example/dashboard/settings/profile)
2. Sección **API / CLI** → **Generate**
3. Copiar el token (solo se muestra una vez) y pegarlo en el input del formulario

### Seguridad

- **Nunca** guardar credenciales en archivos, skills, commits o `.env`
- **Nunca** repetir API key ni contraseña en la respuesta
- Si el usuario pegó secretos en el chat antes, avisarle que los regenere

## PASO 1 — Usar MCP de Dokploy (MÉTODO PRINCIPAL)

El MCP expone **508 herramientas** de la API de Dokploy. Usar siempre que esté disponible.

### Descubrir herramientas

```
GetMcpTools → server: "dokploy-mcp"
```

Si el servidor no aparece o está en `needsAuth`/`error`, pedir al usuario configurar MCP y recargar.

### Herramientas clave para deploy

| Categoría | Acciones MCP |
|-----------|--------------|
| `project` | listar, crear, buscar |
| `application` | create, update, deploy, redeploy, start, stop |
| `compose` | create, deploy, update |
| `deployment` | historial, estado |
| `domain` | crear dominio |

Filtrar solo lo necesario (opcional en mcp.json):

```
DOKPLOY_ENABLED_TAGS=project,application,deployment,domain,compose
```

### Flujo con MCP

```
Task Progress:
- [ ] 0. AskQuestion → API key (único input obligatorio)
- [ ] 1. Configurar mcp.json + recargar MCP
- [ ] 2. GetMcpTools → dokploy-mcp
- [ ] 3. Listar proyectos (project.*)
- [ ] 4. Crear proyecto si no existe (project.create)
- [ ] 5. Crear aplicación (application.create) → visible en panel
- [ ] 6. Configurar source/build (application.update)
- [ ] 7. Desplegar (application.deploy)
- [ ] 8. Verificar estado (deployment.*)
- [ ] 9. SSH solo si falla y el usuario quiere debug manual
```

### Ejemplo de llamadas MCP

1. `GetMcpTools` con `server: "dokploy-mcp"` para ver schemas
2. `CallMcpTool` → listar proyectos
3. `CallMcpTool` → `application.create` con name, projectId, environmentId
4. `CallMcpTool` → `application.update` con sourceType, buildType
5. `CallMcpTool` → `application.deploy` con applicationId

**Preferir MCP sobre curl** para crear apps, deploy y consultar estado.

## PASO 2 — SSH (opcional, solo debug)

Solo si el deploy falla y el MCP no da suficiente info. Pedir usuario/contraseña SSH en ese momento, no al inicio.

| Campo | Valor |
|-------|-------|
| Host SSH | `<tu-host-ssh>` |
| Panel | `https://tu-panel-dokploy.example` |

```powershell
ssh <usuario>@<tu-host-ssh> "docker logs <container-id> --tail 80"
```

## PASO 3 — Respaldo con curl/script (si MCP no funciona)

```powershell
$env:DOKPLOY_URL = "https://tu-panel-dokploy.example"
$env:DOKPLOY_API_KEY = "<api-key-del-usuario>"

curl.exe -s -H "x-api-key: $env:DOKPLOY_API_KEY" "$env:DOKPLOY_URL/api/trpc/project.all"
```

### Analizar proyecto local

| Archivo | buildType |
|---------|-----------|
| `docker-compose.yml` | Compose (usar compose.* del MCP) |
| `Dockerfile` | `dockerfile` |
| `package.json` | `nixpacks` |
| Solo estáticos | `static` |

### Empaquetar y subir (drop)

```powershell
.cursor/skills/dokploy-ssh-deploy/scripts/deploy.ps1 -Action pack -ProjectPath "."

curl.exe -s -X POST "$env:DOKPLOY_URL/api/trpc/application.dropDeployment" `
  -H "x-api-key: $env:DOKPLOY_API_KEY" `
  -F "zip=@deploy.zip" `
  -F "json={\"applicationId\":\"<APP_ID>\",\"dropBuildPath\":\"/\"}"
```

## Reglas

1. **MCP + API key es suficiente** — no pedir SSH al inicio
2. API key: pedir con AskQuestion, poner en `.cursor/mcp.json`, nunca en commits
3. URL fija: `https://tu-panel-dokploy.example`
4. SSH solo si falla el deploy y hace falta debug en el servidor
5. Si la app existe, listar con MCP y redeploy en vez de duplicar
6. Reportar: `applicationId`, URL del panel, estado del deployment

## Referencia

- MCP tools: [reference.md](reference.md)
- Repo oficial: [github.com/Dokploy/mcp](https://github.com/Dokploy/mcp)

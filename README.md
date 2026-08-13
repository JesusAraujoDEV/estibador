# Estibador

Agente que despliega proyectos en [Dokploy](https://dokploy.com) sin tocar la UI — usa el MCP oficial (`@dokploy/mcp`) o `curl` de respaldo. Vos le das la API key, él crea la app, empaqueta el proyecto y hace el deploy.

Compatible con **Claude Code** y **Kiro**.

## Requisitos

- Node.js (para correr `npx @dokploy/mcp`).
- Una instancia de Dokploy corriendo y su API key (Panel -> Profile -> API/CLI -> Generate).

---

## Instalacion en Kiro

### Opcion 1: Script automatico (recomendado)

Clona el repo y ejecuta el instalador:

```powershell
git clone https://github.com/JesusAraujoDEV/estibador.git
cd estibador

# Instalacion global (disponible en todos tus proyectos)
.\install.ps1

# O solo para el workspace actual
.\install.ps1 -Scope workspace
```

El script:
- Copia el steering file a `~/.kiro/steering/estibador.md` (o `.kiro/steering/`)
- Agrega `dokploy-mcp` a tu `mcp.json` sin borrar otros servers
- Copia `deploy.ps1` como script de respaldo

Despues de instalar:
1. Abri `~/.kiro/settings/mcp.json` (o `.kiro/settings/mcp.json` si usaste workspace)
2. Reemplaza `<URL_DE_TU_PANEL>` y `<TU_API_KEY>` con tus datos
3. Cambia `"disabled": true` a `"disabled": false`
4. Kiro reconecta el MCP automaticamente al guardar

### Opcion 2: Manual

1. Copia `.kiro/steering/estibador.md` a `~/.kiro/steering/estibador.md` (global) o a `.kiro/steering/` de tu proyecto.

2. Agrega esto a tu `~/.kiro/settings/mcp.json` (o `.kiro/settings/mcp.json`):

```json
{
  "mcpServers": {
    "dokploy-mcp": {
      "command": "npx",
      "args": ["-y", "@dokploy/mcp"],
      "env": {
        "DOKPLOY_URL": "https://tu-panel.com",
        "DOKPLOY_API_KEY": "tu-api-key",
        "DOKPLOY_ENABLED_TAGS": "project,application,deployment,domain,compose"
      }
    }
  }
}
```

### Uso en Kiro

En el chat de Kiro, activa el steering con `#estibador` y pedi:

> "Deploya esto en Dokploy"

O simplemente:

> "Crea una app en Dokploy y desplegala"

El agente te va a pedir la URL del panel y la API key si no estan configuradas en el MCP, y despues ejecuta todo el flujo: detecta el tipo de build, crea proyecto/app, despliega y verifica.

---

## Instalacion en Claude Code

```bash
claude plugin marketplace add https://github.com/JesusAraujoDEV/estibador
claude plugin install estibador@estibador
```

Queda disponible en **cualquier proyecto** sin repetir el paso. Usa `/estibador:deploy` o pedi en el chat "deploya esto en Dokploy".

Para actualizar:

```bash
claude plugin marketplace update estibador
claude plugin update estibador@estibador
```

---

## Como funciona

1. Te pide la **URL de tu panel de Dokploy** y la **API key** (no hay instancia por default, cada quien apunta a la suya).
2. Configura el MCP con tu URL y key.
3. Detecta el tipo de build (`Dockerfile`, `docker-compose.yml`, `package.json`, o estaticos).
4. Crea el proyecto/app en Dokploy si no existe (o hace redeploy si ya existe).
5. Dispara el deploy y confirma el estado — `applicationId`, URL del panel, resultado real.

Si el deploy falla, ahi si te pide datos SSH para revisar logs — nunca antes.

## Seguridad

- Nunca pega tu API key ni contrasenas en texto plano fuera del flujo que te pide el agente.
- El agente no persiste secretos en commits, `.env` ni archivos versionados.
- Si alguna vez pegaste una API key en un chat, regenerala en el panel de Dokploy.

## Estructura del repo

```
estibador/
  .claude-plugin/                  -> manifiesto del plugin (Claude Code)
  .kiro/steering/estibador.md      -> steering file (Kiro)
  kiro/mcp.json                    -> template MCP config (Kiro)
  agents/estibador.md              -> definicion del agente (Claude Code)
  commands/deploy.md               -> comando /estibador:deploy (Claude Code)
  skills/dokploy-ssh-deploy/       -> runbook tecnico + script de deploy
  install.ps1                      -> instalador para Kiro (PowerShell)
```

## Licencia

MIT

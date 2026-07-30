# Estibador

Agente de Claude Code que despliega proyectos en [Dokploy](https://dokploy.com) sin tocar la UI — usa el MCP oficial (`@dokploy/mcp`) o `curl` de respaldo. Vos le das la API key, él crea la app, empaqueta el proyecto y hace el deploy.

Es **autónomo**: no depende de ningún otro plugin para funcionar. Si tenés instalado el [crew-plugin](https://github.com/jircdev/crew-plugin), Estibador consulta algunos de sus roles (`atlas-deploy`, `security-compliance`) para decisiones de topología o seguridad — pero funciona perfecto sin él.

## Requisitos

- [Claude Code](https://docs.claude.com/claude-code) instalado (CLI).
- Node.js (para correr `npx @dokploy/mcp`).
- Una instancia de Dokploy corriendo y su API key (Panel → Profile → API/CLI → Generate).

## Instalación

1. Cloná el repo donde quieras tenerlo:

```bash
git clone git@github.com:JesusAraujoDEV/estibador.git
```

2. Agregalo como marketplace/plugin local de Claude Code:

```bash
claude plugin marketplace add /ruta/a/estibador
```

3. Instalá el plugin:

```bash
claude plugin install estibador
```

4. Listo. Ya tenés disponible el agente `estibador` y el comando `/estibador:deploy`.

## Uso

Desde una sesión de Claude Code, en la carpeta del proyecto que querés desplegar:

```
/estibador:deploy
```

O simplemente pedile en el chat: *"desplegá esto en Dokploy"*.

Lo primero que va a hacer es **pedirte la API key de Dokploy** por un formulario — no la escribas directo en el chat, dejá que te la pida así queda solo en la sesión y nunca se guarda en archivos versionados.

A partir de ahí él solo:
1. Configura el MCP con tu key.
2. Detecta el tipo de build (`Dockerfile`, `docker-compose.yml`, `package.json`, o estáticos).
3. Crea el proyecto/app en Dokploy si no existe (o hace redeploy si ya existe).
4. Dispara el deploy y te confirma el estado — `applicationId`, URL del panel, resultado real.

Si el deploy falla, ahí sí te va a pedir usuario/contraseña SSH para revisar logs — nunca antes.

## Seguridad

- Nunca pega tu API key ni contraseñas en texto plano fuera del formulario que te pide el agente.
- El agente no persiste secretos en commits, `.env` ni archivos versionados.
- Si alguna vez pegaste una API key en un chat, regenerala en el panel de Dokploy.

## Estructura del repo

```
estibador/
  .claude-plugin/plugin.json     → manifiesto del plugin
  agents/estibador.md            → definición del agente
  commands/deploy.md             → comando /estibador:deploy
  skills/dokploy-ssh-deploy/     → runbook técnico + script de deploy (PowerShell)
```

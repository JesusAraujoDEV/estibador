# Estibador

Agente de Claude Code que despliega proyectos en [Dokploy](https://dokploy.com) sin tocar la UI — usa el MCP oficial (`@dokploy/mcp`) o `curl` de respaldo. Vos le das la API key, él crea la app, empaqueta el proyecto y hace el deploy.

Es **autónomo**: no depende de ningún otro plugin para funcionar. Si tenés instalado el [crew-plugin](https://github.com/jircdev/crew-plugin), Estibador consulta algunos de sus roles (`atlas-deploy`, `security-compliance`) para decisiones de topología o seguridad — pero funciona perfecto sin él.

## Requisitos

- [Claude Code](https://docs.claude.com/claude-code) instalado (CLI).
- Node.js (para correr `npx @dokploy/mcp`).
- Una instancia de Dokploy corriendo y su API key (Panel → Profile → API/CLI → Generate).

## Instalación

Dos comandos, directo desde el repo de GitHub (no hace falta clonar nada a mano):

```bash
claude plugin marketplace add https://github.com/JesusAraujoDEV/estibador
claude plugin install estibador@estibador
```

Esto lo instala a nivel de usuario (`scope: user`), o sea que queda disponible en **cualquier proyecto** sin repetir el paso. Listo. Ya tenés el agente `estibador` y el comando `/estibador:deploy`.

> Si preferís tenerlo clonado localmente en vez de apuntar a GitHub:
> ```bash
> git clone https://github.com/JesusAraujoDEV/estibador.git
> claude plugin marketplace add /ruta/a/estibador
> claude plugin install estibador@estibador
> ```

Para actualizarlo cuando salga una versión nueva:

```bash
claude plugin marketplace update estibador
claude plugin update estibador@estibador
```

## Uso

Desde una sesión de Claude Code, en la carpeta del proyecto que querés desplegar:

```
/estibador:deploy
```

O simplemente pedile en el chat: *"desplegá esto en Dokploy"*.

Lo primero que va a hacer es pedirte, por un formulario, **la URL de tu panel de Dokploy y la API key** — no hay ninguna instancia asumida por default, cada quien apunta a la suya. No las escribas directo en el chat, dejá que te las pida así quedan solo en la sesión y nunca se guardan en archivos versionados.

A partir de ahí él solo:
1. Configura el MCP con tu URL y tu key.
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
  .claude-plugin/plugin.json       → manifiesto del plugin
  .claude-plugin/marketplace.json  → declara el repo como marketplace instalable
  agents/estibador.md              → definición del agente
  commands/deploy.md               → comando /estibador:deploy
  skills/dokploy-ssh-deploy/       → runbook técnico + script de deploy (PowerShell)
```

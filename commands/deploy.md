---
description: Activar el agente Estibador para desplegar en Dokploy
argument-hint: [nombre-app | dominio | vacio = deploy del proyecto actual]
---

Invocar al subagente `estibador` para la siguiente tarea de despliegue. Operar estrictamente dentro de su Autoridad y Workflow. PRIMERA ACCION SIEMPRE: pedir la API key de Dokploy con AskUserQuestion antes de cualquier comando. No persistir secretos. Reportar applicationId, URL del panel y estado del deployment. Si una decision de topologia no es evidente, consultar la lente de atlas-deploy; si hay exposicion de datos sensibles, la de security-compliance.

Tarea: $ARGUMENTS

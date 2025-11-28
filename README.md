# 🚀 WinCho – Instalador de Apps para Windows

Instalador interactivo en PowerShell para configurar rápidamente un equipo Windows usando **Chocolatey** o **winget**, con soporte incluso para **PowerShell 2.0**, detección automática de versión, barra de progreso, y actualización fácil a **PowerShell 7**.

---

## 🔗 Menú

- [Descripción](#-descripción)
- [Instalación rápida](#-instalación-rápida)
- [Ejecutar desde archivo](#-ejecutar-desde-archivo)
- [Uso del menú interactivo](#-uso-del-menú-interactivo)
- [Catálogo incluido](#-catálogo-incluido)
- [Requisitos](#-requisitos)
- [Notas de seguridad](#-notas-de-seguridad)
- [Personalización](#-personalización)
- [Roadmap](#-roadmap)

---

## 📌 Descripción

**WinCho** es un script avanzado en PowerShell diseñado para automatizar:

- Instalación de aplicaciones esenciales.
- Actualización de software existente.
- Configuración automática de **PowerShell 7** como predeterminado en Windows Terminal.
- Funcionamiento incluso en **PowerShell 2.0**.
- Soporte para **Chocolatey** y **winget**.
- Menú visual con panel de progreso dinámico.

---

## 🚀 Instalación rápida

Ejecuta este comando en **PowerShell como Administrador**:

powershell
irm bit.ly/WinCho | iex


Descargará y ejecutará la última versión del instalador.

📂 Ejecutar desde archivo

Descarga WinCho.ps1 desde el repositorio.

Abre PowerShell como Administrador.

Ejecuta:

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\WinCho.ps1

🕹 Uso del menú interactivo

Al iniciar WinCho verás algo como:

============== r02 ====================
  Instalador de Aplicaciones (PS2.0)
======================================

Elige el gestor de paquetes:
  1) Chocolatey
  2) winget
  0) Salir


Luego aparece el menú de acciones:

1) Listar catálogo
2) Instalar TODO el catálogo
3) Instalar apps seleccionadas
4) Actualizar TODO (apps instaladas)
5) Actualizar PowerShell (7 recomendado)
9) Cambiar de gestor
0) Salir


El script incluye un panel visual de progreso que muestra logs en tiempo real.

📦 Catálogo incluido

El arreglo $Apps incluye aplicaciones listas para instalar:

🌐 Web / Nube

Google Chrome

Google Drive

💬 Comunicación / Productividad

Discord

TeamViewer

TeamSpeak

Thunderbird

🎮 Gaming / Monitoreo

Steam

EA App

MSI Afterburner

RivaTuner Statistics Server

🎥 Multimedia / Edición / Streaming

VLC

HandBrake

OBS Studio

REAPER

ImageMagick

FFmpeg

yt-dlp

💻 Desarrollo / Virtualización

Node.js LTS

Python 3.12

PowerShell 7

VirtualBox

Tesseract OCR

🧩 Sistema / Runtimes

7-Zip

.NET Framework 4.8

.NET Desktop Runtime 9

.NET Desktop Runtime 8

🧱 Requisitos

Windows 10/11

PowerShell ejecutado como Administrador

Conexión a Internet

Para winget:

App Installer instalado vía Microsoft Store

Para configurar Windows Terminal:

Windows Terminal instalado

🔐 Notas de seguridad

El script usa Chocolatey y winget, ambos gestionan firmas y seguridad.

Se crea un respaldo de settings.json antes de modificar Windows Terminal.

No se envían datos del usuario.

🛠 Personalización

Puedes editar fácilmente:

El catálogo $Apps

El texto de los menús

La lógica del panel de progreso

Métodos de instalación (por ejemplo, añadir Scoop)

🗺 Roadmap

 Modo silencioso

 Exportar logs a archivo

 Verificación de versiones

 Reinstalación / desinstalación automática

 Categorías personalizadas

❤️ Créditos

Creado con PowerShell, paciencia y muchas reinstalaciones 😄
Si te ayudó… ¡dale estrella ⭐!

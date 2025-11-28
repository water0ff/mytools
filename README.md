# Instalador de Apps para Windows (WinCho)

Pequeño instalador en PowerShell para configurar rápidamente un entorno de Windows con Chocolatey/winget y apps esenciales.

## 🔗 Menú

- [Descripción](#-descripción)
- [Instalación rápida](#-instalación-rápida)
- [Uso](#-uso)
- [Requisitos](#-requisitos)
- [Catálogo de aplicaciones](#-catálogo-de-aplicaciones)
- [Notas de seguridad](#-notas-de-seguridad)

## 🚀 Instalación rápida

En PowerShell **como administrador**, ejecuta:
🚀 WinCho – Instalador de Aplicaciones para Windows

Instalador interactivo en PowerShell para configurar rápidamente un equipo Windows usando Chocolatey o winget, con soporte incluso para PowerShell 2.0, detección automática de versión, barra de progreso, y actualización fácil a PowerShell 7.

🔗 Menú

Descripción

Instalación rápida

Ejecutar desde archivo

Uso del menú interactivo

Catálogo incluido

Requisitos

Notas de seguridad

Personalización

Roadmap

📌 Descripción

WinCho es un script avanzado en PowerShell diseñado para automatizar:

Instalación de aplicaciones esenciales.

Actualización de software existente.

Configuración automática de PowerShell 7 como predeterminado en Windows Terminal.

Soporte dual:

Chocolatey

winget

Funcionamiento incluso en PowerShell 2.0 (ideal para equipos viejos o recién formateados).

Menú interactivo con instalador visual y panel de progreso dinámico.

🚀 Instalación rápida

Ejecuta este comando en PowerShell como Administrador:

irm bit.ly/WinCho | iex


Esto descargará y ejecutará la última versión del script directamente.

📂 Ejecutar desde archivo

Descarga WinCho.ps1 desde este repositorio.

Abre PowerShell como Administrador.

Ejecútalo:

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\WinCho.ps1

🕹 Uso del menú interactivo

Al ejecutar WinCho tendrás algo como:

============== r02 ====================
  Instalador de Aplicaciones (PS2.0)
======================================

Elige el gestor de paquetes:
  1) Chocolatey
  2) winget
  0) Salir


Luego podrás:

1) Listar catálogo
2) Instalar TODO el catálogo
3) Instalar apps seleccionadas
4) Actualizar TODO (apps ya instaladas)
5) Actualizar PowerShell (7 recomendado)
9) Cambiar de gestor
0) Salir


El script muestra un panel visual de progreso con logs en vivo mientras instala.

📦 Catálogo incluido

El catálogo $Apps trae software organizado por categorías:

🌐 Web / Nube

Google Chrome

Google Drive

💬 Comunicación / Productividad

Discord

TeamViewer

TeamSpeak

Thunderbird (ESR/estable según canal)

🎮 Gaming / Monitoreo

Steam

EA App

MSI Afterburner

RivaTuner Statistics Server

🎥 Multimedia / Edición / Streaming

VLC media player

HandBrake

OBS Studio

REAPER (x64)

ImageMagick

FFmpeg

yt-dlp

💻 Desarrollo / Virtualización

Node.js LTS

Python 3.12

PowerShell 7 (x64)

VirtualBox

Tesseract OCR

🧩 Sistema / Runtimes

7-Zip

.NET Framework 4.8

.NET Desktop Runtime 9

.NET Desktop Runtime 8

Puedes añadir o quitar apps modificando el arreglo $Apps.

🧱 Requisitos

Windows 10/11 (ideal).

PowerShell como administrador.

Conexión a Internet.

Para winget:

App Installer (Microsoft Store).

Para configuración automática de Windows Terminal:

Windows Terminal instalado.

🔐 Notas de seguridad

El script no instala archivos externos directamente:
usa Chocolatey o winget, que manejan su propia seguridad y firmas.

Se crea un respaldo de settings.json de Windows Terminal antes de modificarlo.

No se almacena ni envía información del usuario.

🛠 Personalización

Puedes modificar fácilmente:

El catálogo $Apps.

Los textos del menú.

La apariencia del panel de progreso.

Los instaladores disponibles (por ejemplo, añadir Scoop).

🗺 Roadmap

 Exportar logs a archivo.

 Añadir verificación de versiones antes de instalar.

 Modo silencioso (sin menú).

 Añadir reinstalación y desinstalación automática.

 Añadir categorías personalizadas por usuario.

❤️ Créditos

Creado con PowerShell, paciencia y muchas reinstalaciones de Windows 😄
Si te fue útil, ¡dale una estrella ⭐ al repositorio!

 Integrar comprobaciones de versión antes de intentar instalar.

 Modo “silencioso” sin preguntas, para automatizar despliegues.

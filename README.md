# KDZi

Un proyecto comprehensivo de Roblox que incluye sistemas avanzados de UI, clanes, música, emotes y más.

## 📁 Estructura del Proyecto

### ReplicatedStorage
Sistema de configuración y componentes compartidos entre cliente y servidor.
- **Config/**: Configuraciones centralizadas (Admin, Clanes, Música, Temas)
- **Core/**: Sistema de UI base
- **Modal/**: Sistema de modales (Confirmación, Manager)
- **Systems/**: Sistemas globales (Clanes, DataStore, Notificaciones)
- **UIComponents/**: Componentes UI reutilizables (Scrollbar, NavTabs, Búsqueda, tarjetas)

### ServerScriptService
Scripts del lado del servidor.
- **Systems/**: 
  - Clan System: Sistema completo de clanes
  - Combat System: Sistema de combate
  - Music System: Sistema de música
  - Lighting: Control de iluminación
  - VR System: Sistema de realidad virtual
  - HD Commands: Comandos avanzados
  - Likes System: Sistema de likes
  - Gamepass Gifting: Sistema de regalos de gamepasses

### StarterGui
Interfaz gráfica del cliente.
- **ClanSystem/**: Sistema completo de UI de clanes
- **GamepassShop/**: Tienda de gamepasses
- **Settings/**: Configuración de usuario
- **SystemMusic/**: Dashboard de DJ
- **SelectedPlayer/**: Panel de usuario

### StarterPlayer
Scripts de inicio del jugador.
- **StarterPlayerScripts/**: Scripts de inicialización
  - Chat Tags
  - Effects (Brillo, Disco, Terremoto)
  - Camera System (FreeCam, Giro)
  - Music & Visual Effects
  - Speed Boost
- **StarterCharacterScripts/**: Scripts por personaje

### ServerStorage
Configuración centralizada del servidor.
- Configuración de Admin Central
- Sistemas base

## 🎮 Características Principales

- ✨ **Sistema de Clanes**: Crear, gestionar y participar en clanes
- 🎵 **Sistema de Música**: DJ Dashboard, visualización de música
- 🎭 **Sistema de Emotes**: Emotes sincronizados entre jugadores
- 💎 **Gamepasses**: Shop de gamepasses y sistema de regalos
- 🎨 **Sistema de Temas**: Temas personalizables
- 👥 **Panel de Usuario**: Información de jugadores seleccionados
- ⚡ **Sistema de Combate**: Punching system con efectos
- 🏆 **Leaderboards**: Sistema de clasificación
- 🎯 **Effects**: Efectos visuales variados (brillo, disco, terremoto)
- 🎮 **VR Support**: Sistema de realidad virtual

## 🛠️ Requisitos

- Roblox Studio
- Lua 5.1+

## 📝 Instalación

1. Abre Roblox Studio
2. Abre o crea un juego
3. Importa los archivos de este repositorio en sus respectivas carpetas
4. Configura los valores en cada archivo `Config.lua`

## 🔧 Configuración

Cada sistema tiene su archivo de configuración:
- `AdminConfig.lua`
- `ClanSystemConfig.lua`
- `MusicSystemConfig.lua`
- `ThemeConfig.lua`
- `TitleConfig.lua`

Edita estos archivos según tus necesidades.

## 📧 Soporte

Para reportar bugs o sugerir features, abre un issue en el repositorio.

## 📄 Licencia

Este proyecto es privado. Todos los derechos reservados.

---

**Última actualización**: 6 de marzo de 2026

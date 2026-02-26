# NextField Mobile

NextField es una aplicación móvil desarrollada en Flutter diseñada para la gestión de trabajos de campo, seguimiento de suministros y recolección de evidencia fotográfica por parte de técnicos.

## 🚀 Características Principales

- **Gestión Offline-First**: Permite trabajar sin conexión a internet. Los datos se guardan en una base de datos local (SQLite) y se sincronizan automáticamente cuando se detecta conexión.
- **Evidencia Fotográfica con GPS**: Captura fotos probatorias con registro automático de coordenadas de latitud y longitud.
- **Sincronización Inteligente**: Sistema de colas para subida de imágenes y actualización de estados en segundo plano.
- **Interfaz Premium**: Diseño visual moderno con soporte para Modo Oscuro y Modo Claro.
- **Seguridad**: Autenticación integrada con Supabase Auth y manejo de roles de usuario.
- **Monitoreo de Red**: Verificación activa de conectividad real a internet para prevenir errores de sincronización.

## 🛠️ Stack Tecnológico

- **Framework**: [Flutter](https://flutter.dev/)
- **Backend**: [Supabase](https://supabase.com/) (Auth, Database, Storage)
- **Base de Datos Local**: [SQLite](https://sqlite.org/) (sqflite)
- **Gestión de Estado**: StatefulWidget con sincronización reactiva a cambios de conexión.

## 📦 Instalación y Configuración

1. **Prerrequisitos**:
   - Flutter SDK (v3.11.0 o superior)
   - Dart SDK
   - Android Studio / Xcode

2. **Clonar el repositorio**:

   ```bash
   git clone <url-del-repositorio>
   cd protoflutter
   ```

3. **Instalar dependencias**:

   ```bash
   flutter pub get
   ```

4. **Configurar Supabase**:
   Asegúrate de configurar las credenciales de Supabase en `lib/main.dart`:

   ```dart
   await Supabase.initialize(
     url: 'TU_SUPABASE_URL',
     anonKey: 'TU_ANON_KEY',
   );
   ```

5. **Ejecutar la aplicación**:
   ```bash
   flutter run
   ```

## 📂 Estructura del Proyecto

- `lib/pages/`: Pantallas principales (Login, Home, Detalles, Revisión).
- `lib/services/`: Lógica de negocio, base de datos y servicios de sincronización.
- `lib/widgets/`: Componentes de UI reutilizables (Overlays, Diálogos).
- `assets/`: Recursos gráficos de la aplicación.

## 👨‍💻 Contribución

NextField es un proyecto enfocado en la eficiencia operativa en campo. Si deseas contribuir, por favor abre un Issue o un Pull Request.

---

© 2026 NextField - Gestión Eficiente de Suministros.

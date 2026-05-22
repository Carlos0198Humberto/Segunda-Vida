# Pulse of Life — Instrucciones de Instalación
**Versión:** 1.0.0  
**Slogan:** *Track what matters. Live with purpose.*

---

## Contenido
1. [Descripción de la app](#1-descripción)
2. [Requisitos previos](#2-requisitos-previos)
3. [Configurar la base de datos](#3-base-de-datos-postgresql)
4. [Iniciar el backend](#4-backend-fastapi)
5. [Instalar en Android](#5-android)
6. [Instalar en iPhone (iOS)](#6-iphone--ios)
7. [Solución de errores comunes](#7-solución-de-errores)

---

## 1. Descripción

**Pulse of Life** es una app personal all-in-one que centraliza:

| Módulo | Descripción |
|--------|-------------|
| 📊 Dashboard | Resumen diario de vida |
| 💰 Finanzas | Control de ingresos y gastos |
| 💵 Ahorros | Metas y alcancías digitales |
| ✅ Hábitos | Rastreador con rachas y heatmap |
| 🏃 Salud | Gym, sueño, hidratación |
| 🍎 Nutrición | Control calórico semanal (Lun-Dom) |
| 📖 Diario | Entradas privadas con estado emocional |
| 📚 Aprendizaje | Cursos y horas de práctica |
| 🧠 Habilidades | Progreso por áreas |
| 🗓️ Planificación | Proyectos y tareas |
| ⏱️ Tiempo | Seguimiento de horas productivas |
| 🏆 Logros | Sistema de recompensas |
| 📈 Analíticas | Histórico multi-año |
| 🔐 Life Vault | Módulo secreto para recuerdos privados |

---

## 2. Requisitos Previos

### Software necesario

| Herramienta | Versión mínima | Descarga |
|-------------|---------------|---------|
| Flutter SDK | 3.19+ | https://docs.flutter.dev/get-started/install |
| Dart SDK | 3.3+ | (incluido con Flutter) |
| Python | 3.11+ | https://python.org |
| Docker Desktop | 24+ | https://docker.com/products/docker-desktop |
| Git | 2.40+ | https://git-scm.com |

### Para iOS además necesitas:
- macOS con Xcode 15+
- Cuenta de Apple Developer (gratuita sirve para pruebas en dispositivo)
- CocoaPods: `sudo gem install cocoapods`

### Para Android:
- Android Studio / Android SDK
- `flutter doctor` debe mostrar todo en verde

---

## 3. Base de datos PostgreSQL

### Opción A — Docker (recomendada)

```bash
# Instalar y arrancar Docker Desktop, luego:
docker run --name pulsador-pg \
  -e POSTGRES_USER=segunda_vida \
  -e POSTGRES_PASSWORD=segunda_vida_secret \
  -e POSTGRES_DB=segunda_vida \
  -p 5432:5432 \
  -d postgres:15
```

### Opción B — Ya tienes el contenedor

```bash
docker start pulsador-pg
```

### Verificar conexión
```bash
docker exec -it pulsador-pg psql -U segunda_vida -d segunda_vida -c "\dt"
```

---

## 4. Backend (FastAPI)

### Instalar dependencias

```bash
cd backend
pip install -r requirements.txt
```

### Configurar variables de entorno
Crear `backend/.env`:
```env
DATABASE_URL=postgresql://segunda_vida:segunda_vida_secret@localhost:5432/segunda_vida
SECRET_KEY=tu_clave_secreta_muy_larga_y_segura_aqui
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
```

### Aplicar migraciones

```bash
cd backend
alembic upgrade head
```

### Iniciar el servidor

```bash
uvicorn main:app --reload --port 8000
```

### Acceso rápido (Windows)
Doble clic en `iniciar-backend.bat` (en la raíz del proyecto).  
⚠️ **Docker Desktop debe estar abierto primero.**

### Verificar que funciona
Abrir en el navegador: http://localhost:8000/docs

---

## 5. Android

### Paso 1 — Preparar Flutter para Android

```bash
flutter doctor
# Si falta Android toolchain, seguir las instrucciones
flutter doctor --android-licenses
```

### Paso 2 — Compilar APK de debug (para pruebas)

```bash
cd frontend
flutter build apk --debug
# APK generada en: frontend/build/app/outputs/flutter-apk/app-debug.apk
```

### Paso 3 — Compilar APK de release

```bash
# Primero crear el keystore (solo una vez):
keytool -genkey -v -keystore ~/pulse-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias pulse

# Crear frontend/android/key.properties:
echo "storePassword=TU_PASSWORD
keyPassword=TU_PASSWORD
keyAlias=pulse
storeFile=/Users/TU_USUARIO/pulse-release.jks" > frontend/android/key.properties

# Compilar:
cd frontend
flutter build apk --release
# APK en: build/app/outputs/flutter-apk/app-release.apk
```

### Paso 4 — Instalar en el teléfono

**Método A (cable USB):**
```bash
# Habilitar "Depuración USB" en tu teléfono Android
# Ajustes → Acerca del teléfono → tocar "Número de compilación" 7 veces
# Ajustes → Opciones de desarrollador → Depuración USB = ON

flutter devices          # verificar que el teléfono aparece
flutter run --release    # instala y ejecuta directamente
```

**Método B (APK por archivo):**
1. Copiar `app-release.apk` al teléfono (por cable o Google Drive)
2. Abrir el archivo en el teléfono
3. Permitir "Instalar apps desconocidas" si se solicita
4. Instalar

### Paso 5 — Play Store (opcional, futuro)
```bash
flutter build appbundle --release
# Sube el .aab en https://play.google.com/console
```

---

## 6. iPhone / iOS

> **Requisito:** Necesitas una Mac con Xcode instalado.

### Paso 1 — Instalar dependencias iOS

```bash
cd frontend/ios
pod install
cd ../..
```

### Paso 2 — Abrir en Xcode

```bash
open frontend/ios/Runner.xcworkspace
```

En Xcode:
- Seleccionar **Runner** en el panel izquierdo
- **Signing & Capabilities** → seleccionar tu Team (Apple ID)
- Cambiar el **Bundle Identifier** a algo único: `com.TU_NOMBRE.pulseoflife`

### Paso 3 — Instalar en iPhone (cable USB)

```bash
# Conectar iPhone por cable
# Confiar en el computador cuando el iPhone lo pida

flutter devices   # el iPhone debe aparecer
flutter run -d [device-id] --release
```

O desde Xcode: seleccionar tu iPhone en la barra superior → ▶ Play.

**Primera vez:** en el iPhone ir a:
**Ajustes → General → VPN y gestión de dispositivos → confiar en [tu nombre]**

### Paso 4 — TestFlight (para compartir con otros)

1. Registrarse en https://developer.apple.com (gratis para pruebas personales, $99/año para distribuir)
2. Compilar para distribución:
```bash
cd frontend
flutter build ipa --release
# Archivo .ipa en build/ios/ipa/
```
3. Abrir Xcode → **Product → Archive**
4. **Distribute App → App Store Connect → Upload**
5. En App Store Connect: añadir testers en TestFlight

### Paso 5 — Alternativa sin Mac: AltStore (sin jailbreak)

Si no tienes Mac, puedes usar **AltStore** para instalar sin cuenta de desarrollador:
1. Instalar AltStore en Windows: https://altstore.io
2. Instalar AltServer en el PC
3. Conectar iPhone por cable
4. Instalar AltStore en el iPhone desde AltServer
5. Abrir AltStore y cargar el `.ipa` de la app

> ⚠️ Las apps instaladas con AltStore se revocan cada 7 días y deben reinstalarse.

---

## 7. Solución de Errores

### Error: ERR_CONNECTION_REFUSED al hacer login
**Causa:** El backend no está corriendo.  
**Solución:**
1. Verificar que Docker Desktop está abierto
2. Correr `iniciar-backend.bat` (Windows) o:
   ```bash
   docker start pulsador-pg
   cd backend && uvicorn main:app --reload --port 8000
   ```

### Error: No pubspec.yaml found
**Causa:** Estás ejecutando `flutter run` desde la carpeta equivocada.  
**Solución:**
```bash
cd frontend   # ← SIEMPRE desde aquí
flutter run -d chrome
```

### Error: Migration failed / alembic
```bash
cd backend
alembic downgrade base
alembic upgrade head
```

### Error de CORS en el navegador
El backend ya tiene CORS configurado correctamente.  
Si persiste, verificar que `main.py` tiene `allow_credentials=False`.

### Flutter: dependencias faltantes
```bash
cd frontend
flutter pub get
flutter clean && flutter pub get
```

### iOS: Pod install falla
```bash
cd frontend/ios
sudo gem install cocoapods
pod repo update
pod install --repo-update
```

### Android: Gradle build falla
```bash
cd frontend
flutter clean
cd android && ./gradlew clean
cd ..
flutter build apk --debug
```

---

## Módulo Secreto — Life Vault 🔐

El **Life Vault** es un espacio privado protegido con PIN para guardar recuerdos de seres queridos (ideal para registrar el crecimiento de un sobrino, hijo, etc.)

### ¿Cómo acceder?

1. En la pantalla de **Ajustes** (Settings), tocar el **avatar/foto de perfil** **5 veces seguidas** en menos de 3 segundos
2. La app pedirá el **PIN master**: `2024`
3. Una vez adentro, crear perfiles para cada persona

### ¿Qué se puede guardar?

| Tipo | Descripción |
|------|-------------|
| ⭐ Milestone | Primeros pasos, primera palabra, etc. |
| 🏥 Salud | Visitas médicas, vacunas |
| 📏 Medida | Peso y talla en el tiempo |
| ❤️ Recuerdo | Momentos especiales |
| 🎓 Escuela | Logros académicos |
| ✨ Primera vez | Primera vez que... |
| ✈️ Viaje | Trips familiares |
| 🏆 Logro | Premios y reconocimientos |

### PIN del perfil
Cada perfil puede tener su propio PIN adicional para mayor privacidad.

---

## Información de la App

```
Nombre:    Pulse of Life
Versión:   1.0.0
Slogan:    Track what matters. Live with purpose.
Backend:   FastAPI + PostgreSQL
Frontend:  Flutter (iOS, Android, Web)
Authn:     JWT Bearer tokens
Database:  PostgreSQL 15 (Docker local / Railway cloud)
```

---

*Documentación generada para Pulse of Life v1.0.0*

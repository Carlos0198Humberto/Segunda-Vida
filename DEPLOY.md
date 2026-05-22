# Despliegue en la Nube — Pulsador de Vida

## Paso 1: Base de datos — Supabase (gratis)

1. Ve a [supabase.com](https://supabase.com) → New project
2. Crea el proyecto (elige región más cercana)
3. Ve a **Settings → Database → Connection string → URI**
4. Copia la URL — se ve así:
   `postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres`
5. Pon esa URL en `backend/.env` como `DATABASE_URL`

## Paso 2: Backend — Railway (gratis $5 créditos/mes)

1. Ve a [railway.app](https://railway.app) → New Project → Deploy from GitHub
2. Conecta este repo / sube el código del backend
3. En Railway: **Variables** → agrega todas las del `.env.production`
4. Railway auto-detecta el `Procfile` y hace el deploy
5. Copia la URL que te da Railway (ej: `https://pulsador.up.railway.app`)

## Paso 3: Flutter — apuntar al backend cloud

En `frontend/lib/core/constants/app_constants.dart`:
```dart
static const String _prodUrl = 'https://pulsador.up.railway.app/api/v1';
```

Para build de producción:
```bash
flutter build ios --dart-define=PRODUCTION=true
flutter build apk --dart-define=PRODUCTION=true
```

## Paso 4: iOS — instalar en iPhone

### Opción A: Codemagic (sin Mac)
1. [codemagic.io](https://codemagic.io) → conecta repo
2. Configura iOS workflow
3. Te manda el `.ipa` por email para instalar via TestFlight

### Opción B: Mac con Xcode
```bash
cd frontend
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
```
Luego abre `ios/Runner.xcworkspace` en Xcode → Archive → Distribute

### Opción C: TestFlight directo
1. Genera build con Codemagic
2. Sube a App Store Connect
3. Instala vía TestFlight en tu iPhone

## Para probar desde iPhone en red WiFi local (sin deploy)

1. Encuentra la IP de tu PC: `ipconfig` → busca `IPv4 Address`
2. En `app_constants.dart` cambia:
   ```dart
   return 'http://192.168.1.X:8000/api/v1'; // tu IP local
   ```
3. Asegúrate que el backend esté corriendo
4. Conecta el iPhone a la misma WiFi
5. Corre `flutter run -d [device-id]`

@echo off
echo ==========================================
echo   Pulsador de Vida — Iniciando Backend
echo ==========================================

REM 1. Verificar que Docker está corriendo
echo [1/4] Verificando Docker...
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker Desktop no está corriendo.
    echo Abre Docker Desktop y espera que cargue, luego vuelve a correr este script.
    pause
    exit /b 1
)
echo       Docker OK

REM 2. Iniciar PostgreSQL si no existe
echo [2/4] Iniciando base de datos...
docker ps -a --format "{{.Names}}" | findstr /i "pulsador-pg" >nul 2>&1
if %errorlevel% equ 0 (
    docker start pulsador-pg >nul 2>&1
    echo       PostgreSQL ya existia, iniciado.
) else (
    docker run --name pulsador-pg -e POSTGRES_USER=segunda_vida -e POSTGRES_PASSWORD=segunda_vida_secret -e POSTGRES_DB=segunda_vida -p 5432:5432 -d postgres:15 >nul 2>&1
    echo       PostgreSQL creado e iniciado.
)

REM 3. Esperar a que Postgres esté listo
echo       Esperando que PostgreSQL esté listo...
timeout /t 4 /nobreak >nul

REM 4. Ir a la carpeta del backend
cd /d "%~dp0backend"

REM 5. Correr migraciones
echo [3/4] Aplicando migraciones...
alembic upgrade head
if %errorlevel% neq 0 (
    echo ERROR en migraciones. Revisa la conexion a la DB.
    pause
    exit /b 1
)

REM 6. Iniciar el servidor
echo [4/4] Iniciando servidor en http://localhost:8000
echo.
echo      Presiona Ctrl+C para detener
echo ==========================================
uvicorn main:app --reload --port 8000

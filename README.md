# P41

Repo aislado para el programa nuevo `P41`.

## Estructura

- `app/`: app Flutter principal
- `launcher/`: launcher/updater desktop
- `scripts/`: scripts de build y empaquetado para Windows
- `.github/workflows/`: CI propia del repo

## Build Windows local

### App

```powershell
./scripts/build_pos.ps1 -RunCodegen Auto
```

### Launcher

```powershell
./scripts/build_launcher.ps1
```

### Instalador

Primero compilar app y launcher, después:

```powershell
./scripts/create_launcher_installer.ps1
```

## CI

El workflow del repo:

- analiza la app y el launcher
- compila la app Windows
- compila el launcher Windows
- arma el instalador con la app incluida
- sube ZIP del launcher e instalador como artifacts

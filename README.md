# P41

Repo aislado para el programa nuevo `P41`.

## Estructura

- `app/`: app Flutter principal
- `launcher/`: bootstrap desktop propio de `P41`
- `scripts/`: scripts de build y empaquetado para Windows
- `.github/workflows/`: CI propia del repo

## Build Windows local

### App

```powershell
./scripts/build_pos.ps1 -RunCodegen Auto
```

Build por defecto contra `http://31.97.166.250`.

### Launcher

```powershell
./scripts/build_launcher.ps1
```

El launcher queda apuntando al VPS para `version.json`, catálogo global e imágenes bootstrap.

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

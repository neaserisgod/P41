# HorsePos Flutter Stock V2

Nuevo proyecto aislado para rediseñar el dominio de inventario alrededor de:

- ubicaciones fisicas (`heladeras`, `gondolas`, `estantes`, `depositos`)
- stock por ubicacion
- stock por proveedor cuando aplique
- movimientos y auditoria de inventario

## Objetivo

Construir un modulo y una app nueva sin arrastrar las limitaciones del modelo actual de stock plano.

## Mantener afuera de esta carpeta

- la app Flutter actual
- migraciones improvisadas sobre pantallas viejas
- dependencias directas con screens legacy

## Reusar desde el proyecto actual

- autenticacion y sesiones
- sucursales y staff
- sincronizacion, si demuestra ser reutilizable
- servicios transversales que no dependan del inventario viejo

## Alcance inicial

1. definir modelo de datos nuevo
2. definir reglas de negocio
3. definir flujos operativos
4. crear base tecnica del nuevo proyecto
5. migrar modulos puntuales de forma controlada

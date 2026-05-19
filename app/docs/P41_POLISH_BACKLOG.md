# P41 Polish Backlog

## Objetivo

Este backlog define el pulido necesario para que `P41` pase de "ya funciona" a "se siente firme, claro y comercialmente usable" en operacion diaria.

No apunta a migracion ni a features teoricas. Apunta a:

- consistencia operativa
- claridad de uso
- estabilidad de UI/estado
- performance local
- criterio comercial real

La prioridad se clasifica asi:

- `Critico`: hoy genera confusion, fragilidad o malas decisiones operativas.
- `Importante`: mejora fuerte la calidad del producto y reduce friccion diaria.
- `Deseable`: suma calidad percibida, velocidad o profesionalismo, pero no bloquea uso.

## Critico

### 1. Corregir side effects dentro de `build` en mercaderia

Hallazgo:

- En [products_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/catalog_products/screens/products_screen.dart:71) se llama `_inventoryViewModel.updateLocations(locations)` dentro de `build`.

Riesgo:

- rebuilds innecesarios
- estado dificil de razonar
- comportamiento inconsistente al crecer el modulo

Mejora:

- mover esa derivacion a listener/controlador
- separar render de sincronizacion de estado derivado

Archivos:

- [products_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/catalog_products/screens/products_screen.dart:55)
- [inventory_view_model.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/inventory/view_models/inventory_view_model.dart:1)

Criterio de cierre:

- `build` no muta view models
- la pantalla sigue reaccionando a cambios de productos/espacios sin side effects en render

### 2. Separar mensajes de error vs mensajes de exito en caja

Hallazgo:

- En [cash_management_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/cash_management/screens/cash_management_screen.dart:61) se muestra `cashController.errorMessage` siempre con color de error.
- En el controller se usan mensajes como `Caja abierta.` y `Caja cerrada.` como si fueran error.

Riesgo:

- feedback visual incorrecto
- sensacion de sistema inestable aunque la accion salga bien

Mejora:

- separar `errorMessage`, `successMessage` y opcionalmente `infoMessage`
- normalizar el feedback visual en caja y en otros modulos

Archivos:

- [cash_management_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/cash_management/screens/cash_management_screen.dart:61)
- [cash_controller.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/cash_management/state/cash_controller.dart:1)

Criterio de cierre:

- abrir/cerrar caja no se ve como error
- solo los fallos reales se pintan en rojo

### 3. Hacer responsive real la pantalla de configuracion

Hallazgo:

- En [settings_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/settings/screens/settings_screen.dart:74) la estructura principal es un `Row` fijo con sidebar de `260`.
- No tiene `LayoutBuilder` ni modo compacto como otros modulos.

Riesgo:

- peor UX que el resto de la app
- quiebre prematuro en tamaños medianos
- inconsistencia visual y operativa

Mejora:

- agregar layout responsive con lista arriba/panel abajo en modo compacto
- alinear breakpoints con `desktop_viewport.dart`

Archivos:

- [settings_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/settings/screens/settings_screen.dart:43)
- [desktop_viewport.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/app/widgets/desktop_viewport.dart:1)

Criterio de cierre:

- settings se comporta igual de bien que POS, caja y reportes en desktop chico

### 4. Replantear la absorcion automatica de ventas a borradores de proveedor

Hallazgo:

- En [providers_controller.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/providers/state/providers_controller.dart:190) `absorbSaleItems()` agrega items vendidos al borrador del proveedor.

Riesgo:

- el usuario no entiende por que aparecio un pedido sugerido
- mezcla reposicion sugerida con borrador confirmado
- puede ensuciar ordenes reales

Mejora:

- mover esa logica a una bandeja de `reposicion sugerida`
- dejar que el usuario confirme que quiere pasar sugerencias a pedido

Archivos:

- [providers_controller.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/providers/state/providers_controller.dart:190)
- [providers_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/providers/screens/providers_screen.dart:1)

Criterio de cierre:

- vender no modifica silenciosamente un pedido en curso
- la reposicion sugerida existe, pero como sugerencia visible

## Importante

### 5. Hacer persistente y accionable el onboarding

Hallazgo:

- El onboarding actual en [onboarding_home_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/auth/screens/onboarding_home_screen.dart:7) funciona como home operativo, pero todavia es mas informativo que ejecutable.

Mejora:

- persistir progreso por cuenta/sucursal
- marcar pasos reales completados
- agregar CTA directos:
  - crear usuario
  - cargar primer producto
  - abrir caja
  - ir a vender

Archivos:

- [onboarding_home_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/auth/screens/onboarding_home_screen.dart:7)
- [app.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/app/app.dart:544)
- [local_store_service.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/app/services/local_store_service.dart:1)

### 6. Mejorar velocidad operativa del POS

Hallazgo:

- El POS ya opera, pero sigue muy dependiente de mouse/UI.

Mejora:

- foco automatico en busqueda
- atajos de teclado para cobrar, borrar, cambiar cantidad
- enter para primer resultado
- feedback mas claro al agregar item
- vacios/errores menos genericos

Archivos:

- [pos_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/pos/screens/pos_screen.dart:1)
- [sales_controller.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/pos/state/sales_controller.dart:1)
- [pos_cart_panel.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/pos/widgets/pos_cart_panel.dart:1)

### 7. Desacoplar calculos pesados de reportes del render

Hallazgo:

- En [reports_view_model.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/reports/view_models/reports_view_model.dart:31) `summary`, `supplierReports`, `transactions` y `topProducts` recalculan desde cero en getters.

Riesgo:

- escala mal con mas ventas/productos/pedidos
- repite trabajo en cada rebuild

Mejora:

- cachear snapshots derivados
- recomputar por eventos relevantes
- tener invalidacion clara por periodo, anulacion o recepcion

Archivos:

- [reports_view_model.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/reports/view_models/reports_view_model.dart:1)
- [reports_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/reports/screens/reports_screen.dart:1)

### 8. Corregir invalidacion incompleta de reportes frente a caja

Hallazgo:

- `ReportsViewModel` escucha catalogo, proveedores y ventas, pero no `cashController`.

Riesgo:

- reportes parcialmente desactualizados cuando cambia caja o se revierte una venta relacionada

Mejora:

- agregar listener de `cashController`
- revisar si resumen/reportes financieros deben leer mas estado de caja

Archivos:

- [reports_view_model.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/reports/view_models/reports_view_model.dart:19)

### 9. Reordenar configuracion por mentalidad operativa

Hallazgo:

- `Configuracion` hoy mezcla ajustes del local, equipo, venta y sistema, pero todavia no separa bien lo diario de lo excepcional.

Mejora:

- separar:
  - `Operacion diaria`
  - `Negocio y sucursales`
  - `Equipo y permisos`
  - `Cuenta y respaldo`
- hacer mas visible que backup pertenece a la cuenta activa

Archivos:

- [settings_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/settings/screens/settings_screen.dart:1)

### 10. Aclarar mejor el modelo de caja separada para cigarrillos

Hallazgo:

- La logica ya esta mas cerca de la operacion real, pero el modelo sigue necesitando mas claridad visual y conceptual.

Mejora:

- indicador fijo de si la sucursal usa caja separada
- motivo de diferencia por caja
- resumen final con esperado / contado / diferencia por caja
- mejorar historial con filtro por tipo de caja

Archivos:

- [cash_controller.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/cash_management/state/cash_controller.dart:1)
- [cash_shift_dialog.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/cash_management/widgets/cash_shift_dialog.dart:1)
- [cash_management_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/cash_management/screens/cash_management_screen.dart:1)

## Deseable

### 11. Mejorar vacios y microcopy en todos los modulos

Hallazgo:

- Hay mensajes utiles pero todavia bastante tecnicos o genéricos: `No hay proveedores.`, `Todavía no hay productos guardados.`, `No se pudo registrar la venta.`

Mejora:

- convertir vacios en mensajes accionables
- indicar que hacer despues
- unificar tono comercial y operativo

Archivos:

- multiples pantallas en `features/`

### 12. Agregar mas pruebas de flujos criticos

Hallazgo:

- Ya existen tests basicos de auth, pero sigue faltando cobertura de operaciones clave.

Mejora:

- tests para:
  - login nuevo -> onboarding
  - login con cuenta guardada
  - apertura/cierre de caja
  - venta con cigarrillos
  - anulacion con reversa de stock/caja

Archivos:

- [widget_test.dart](/Users/brunofuentes/Developer/p41/P41/app/test/widget_test.dart:1)
- nuevos tests por modulo en `app/test/`

### 13. Normalizar feedback de acciones

Hallazgo:

- Algunos modulos usan texto inline, otros `SnackBar`, otros estado persistente en controller.

Mejora:

- definir un patron claro:
  - accion exitosa corta -> `SnackBar`
  - error bloqueante -> inline + CTA
  - estado persistente del modulo -> banner o badge, no `errorMessage` ambiguo

Archivos:

- [session_controller.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/app/state/session_controller.dart:1)
- [settings_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/settings/screens/settings_screen.dart:1)
- [pos_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/pos/screens/pos_screen.dart:1)
- [cash_management_screen.dart](/Users/brunofuentes/Developer/p41/P41/app/lib/features/cash_management/screens/cash_management_screen.dart:1)

## Orden recomendado de ejecucion

### Fase 1. Estabilidad y semantica

- side effects fuera de `build`
- mensajes de error/exito bien separados
- invalidacion correcta de reportes

### Fase 2. UX operativa central

- onboarding accionable
- POS mas rapido
- caja mas clara

### Fase 3. Criterio comercial

- sugerencias de reposicion en vez de borradores contaminados
- configuracion orientada a negocio
- vacios y textos mas claros

### Fase 4. Calidad sostenida

- tests de flujos clave
- normalizacion de feedback
- mejoras de performance derivada

## Definicion de “P41 pulido”

Se considera que `P41` esta pulido cuando:

- entrar por primera vez no confunde
- vender es mas rapido que pensar
- caja no deja dudas sobre esperado vs contado
- proveedores ayudan a reponer sin generar ruido
- reportes responden rapido y con consistencia
- configuracion no se siente como panel tecnico
- el sistema mantiene el mismo criterio visual y operativo en todos los modulos

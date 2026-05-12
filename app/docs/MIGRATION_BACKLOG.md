# Migration Backlog

## Objetivo

Este backlog define que falta para que `HorsePos_Flutter_StockV2` deje de ser una base visual y pase a cubrir la operacion central que hoy resuelve `HorsePos_Flutter_Universal`.

La clasificacion es:

- `Imprescindible`: sin esto el sistema no puede operar bien.
- `Importante`: da completitud operativa fuerte, pero puede entrar despues.
- `Postergable`: conviene hacerlo, pero no bloquea una primera salida usable.

Tambien se explicita la estrategia de migracion:

- `Se copia`: se puede rescatar casi directo desde Universal.
- `Se adapta`: conviene reutilizar parte de la logica pero rediseñar la capa de presentacion o integracion.
- `Se rehace`: no conviene heredar la implementacion actual.

## Imprescindible

### 1. Auth y sesion

- Login real
- Persistencia y recuperacion de sesion
- Logout real
- Contexto de cuenta activa
- Contexto de usuario activo
- Contexto de sucursal activa
- Gate de acceso por sesion valida

Estrategia:

- `Se adapta`: [login_screen.dart](/Users/brunofuentes/Developer/HorsePosPro/Apps_Moviles/HorsePos_Flutter_Universal/lib/features/auth/presentation/screens/login_screen.dart:1)
- `Se adapta`: [profile_selection_screen.dart](/Users/brunofuentes/Developer/HorsePosPro/Apps_Moviles/HorsePos_Flutter_Universal/lib/features/auth/presentation/screens/profile_selection_screen.dart:1)
- `Se adapta`: [branch_selection_screen.dart](/Users/brunofuentes/Developer/HorsePosPro/Apps_Moviles/HorsePos_Flutter_Universal/lib/features/auth/presentation/screens/branch_selection_screen.dart:1)
- `Se adapta`: [user_switcher_screen.dart](/Users/brunofuentes/Developer/HorsePosPro/Apps_Moviles/HorsePos_Flutter_Universal/lib/features/auth/presentation/screens/user_switcher_screen.dart:1)

### 2. Usuarios

- Listado de usuarios
- Creacion de usuario
- Editor de usuario
- Activacion/desactivacion
- PIN o credencial
- Rol
- Permisos
- Sucursales asignadas
- Restricciones operativas por rol

Estrategia:

- `Se adapta`: modelos y logica de staff/perfiles desde Universal
- `Se rehace`: pantalla nueva de escritorio orientada a HorsePos

### 3. Sucursales

- Listado de sucursales
- Creacion de sucursal
- Editor de sucursal
- Estado activa/inactiva
- Datos operativos de sucursal
- Relacion con usuarios
- Relacion con caja
- Relacion con stock y reportes

Estrategia:

- `Se adapta`: logica de seleccion y negocio desde Universal
- `Se rehace`: UX de administracion de sucursales

### 4. Productos

- Alta de producto
- Editor de producto
- Precio de venta
- Costo
- SKU/codigo
- Categoria
- Proveedor principal o proveedores habilitados
- Estado activo/inactivo
- Ubicacion fisica
- Historial basico
- Validaciones de formulario

Estrategia:

- `Se adapta`: [product_form_provider.dart](/Users/brunofuentes/Developer/HorsePosPro/Apps_Moviles/HorsePos_Flutter_Universal/lib/features/inventory/presentation/providers/product_form_provider.dart:1)
- `Se adapta`: [product_editor_dialog.dart](/Users/brunofuentes/Developer/HorsePosPro/Apps_Moviles/HorsePos_Flutter_Universal/lib/features/inventory/presentation/widgets/product_editor_dialog.dart:1)
- `Se adapta`: tabs de producto en [general_tab.dart](/Users/brunofuentes/Developer/HorsePosPro/Apps_Moviles/HorsePos_Flutter_Universal/lib/features/inventory/presentation/widgets/product_editor/general_tab.dart:1), [price_stock_tab.dart](/Users/brunofuentes/Developer/HorsePosPro/Apps_Moviles/HorsePos_Flutter_Universal/lib/features/inventory/presentation/widgets/product_editor/price_stock_tab.dart:1), [advanced_tab.dart](/Users/brunofuentes/Developer/HorsePosPro/Apps_Moviles/HorsePos_Flutter_Universal/lib/features/inventory/presentation/widgets/product_editor/advanced_tab.dart:1), [history_tab.dart](/Users/brunofuentes/Developer/HorsePosPro/Apps_Moviles/HorsePos_Flutter_Universal/lib/features/inventory/presentation/widgets/product_editor/history_tab.dart:1)
- `Se rehace`: modelo final de producto segun ubicacion/proveedor

### 5. Capa de datos real

- Modelos persistentes
- Repositorios
- DB local
- Mapeo de entidades
- Estado offline
- Sync base
- Manejo de errores
- Carga inicial

Estrategia:

- `Se adapta`: repositorios y acceso a datos que no dependan del inventario legacy
- `Se rehace`: todo lo que asuma `producto -> stock total`

### 6. Permisos y reglas operativas

- Permisos por rol
- Permisos por accion
- Restriccion de anulacion
- Restriccion de cierre de caja
- Restriccion de edicion de producto
- Restriccion de administracion de usuarios/sucursales

Estrategia:

- `Se adapta`: reglas ya existentes en Universal
- `Se rehace`: integracion con el shell y la UX nueva

## Importante

### 7. Caja y turnos

- Persistencia de apertura/cierre
- Historial de cajas
- Arqueo
- Diferencias
- Caja por sucursal
- Caja por usuario activo
- Reglas de caja abierta para operar

Estrategia:

- `Se adapta`: logica operativa de Universal
- `Se adapta`: base de UX ya montada en StockV2

### 8. POS real

- Carrito real
- Busqueda real de productos
- Descuentos
- Medios de pago
- Suspender/recuperar venta
- Confirmacion de venta
- Integracion con caja
- Integracion con stock
- Integracion con historial

Estrategia:

- `Se adapta`: negocio base desde Universal
- `Se rehace`: UX y composicion final del POS

### 9. Inventario real

- CRUD de ubicaciones
- CRUD de productos dentro del nuevo modelo
- Stock por ubicacion
- Stock por proveedor
- Ajustes
- Movimientos
- Conteos
- Reposicion
- Historial de movimientos

Estrategia:

- `Se rehace`: dominio completo

### 10. Proveedores y pedidos reales

- Alta y edicion de proveedores
- Catalogo persistido
- Pedidos persistidos
- Recepcion de pedidos
- Impacto en stock
- Pagos/facturas
- Historial por proveedor

Estrategia:

- `Se adapta`: negocio y estructuras parciales de Universal
- `Se rehace`: UX final del modulo

### 11. Reportes reales

- Ingresos reales
- Compras reales
- Margen calculado con costo real
- Historial de transacciones real
- Anulacion persistida
- Top productos real
- Filtros reales por sucursal y periodo

Estrategia:

- `Se adapta`: consultas y reglas de Universal donde sirvan
- `Se adapta`: UI base ya creada en StockV2

## Postergable

### 12. Settings completos

- Configuracion general
- Preferencias de venta
- Datos del negocio
- Configuracion fiscal
- Mantenimiento
- Diagnostico

Estrategia:

- `Se adapta`: [settings_screen.dart](/Users/brunofuentes/Developer/HorsePosPro/Apps_Moviles/HorsePos_Flutter_Universal/lib/features/settings/presentation/screens/settings_screen.dart:1)
- `Se rehace`: organizacion modular de configuraciones

### 13. Historial y auditoria extendida

- Historial de ventas
- Historial de pedidos
- Historial de cambios de producto
- Historial de cambios de stock
- Historial de cierres de caja
- Auditoria de anulaciones

Estrategia:

- `Se adapta`: negocio
- `Se rehace`: presentacion y navegacion

### 14. Importacion/exportacion

- Importacion de productos
- Exportacion de reportes
- Herramientas de carga masiva

Estrategia:

- `Se adapta`: [excel_import_dialog.dart](/Users/brunofuentes/Developer/HorsePosPro/Apps_Moviles/HorsePos_Flutter_Universal/lib/features/inventory/presentation/widgets/excel_import_dialog.dart:1)

### 15. Setup y bootstrap administrativo

- Creacion inicial de admin
- Configuracion inicial de negocio
- Flujo de primer arranque

Estrategia:

- `Se adapta`: [setup_admin_screen.dart](/Users/brunofuentes/Developer/HorsePosPro/Apps_Moviles/HorsePos_Flutter_Universal/lib/features/auth/presentation/screens/setup_admin_screen.dart:1)

## Dependencias invisibles que no conviene olvidar

- Un usuario debe pertenecer a una cuenta
- Un usuario puede tener una o varias sucursales asignadas
- Una sucursal puede tener una o varias cajas
- Un producto debe tener reglas claras de costo y precio
- Un producto debe poder vivir en una o varias ubicaciones
- Una venta debe quedar ligada a usuario, sucursal y caja
- Un pedido debe quedar ligado a proveedor, sucursal y recepcion
- Una anulacion debe guardar quien la hizo y por que

## Orden recomendado de implementacion

1. Auth y sesion
2. Contexto de usuario y sucursal
3. CRUD de usuarios
4. CRUD de sucursales
5. Capa de datos real
6. CRUD de productos
7. Caja y turnos persistidos
8. POS real
9. Proveedores y pedidos reales
10. Inventario real
11. Reportes reales
12. Settings, historial y auditoria extendida

## Decision fuerte

Todo lo administrativo nuevo debe montarse en este proyecto con UI nueva, pero no hace falta reescribir toda la logica de negocio de Universal si ya existe y no depende del modelo legacy de stock plano.

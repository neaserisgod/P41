# Implementation Roadmap

## Objetivo

Este roadmap traduce el backlog de migracion a fases ejecutables para llevar `HorsePos_Flutter_StockV2` desde base visual y prototipo operativo hacia una adaptacion real de `HorsePos_Flutter_Universal`, sin volver a caer en la arquitectura vieja.

Cada fase tiene:

- objetivo
- alcance
- entregables
- criterio de cierre

## Fase 1. Acceso y Contexto

### Objetivo

Resolver el arranque real del sistema y dejar establecido el contexto operativo base:

- cuenta
- usuario
- sucursal
- caja

### Alcance

- login real
- recuperacion de sesion
- logout real
- bootstrap de cuenta
- selector de sucursal
- selector de usuario
- setup inicial de admin si no existe cuenta configurada
- estado global de sesion
- estado global de contexto operativo

### Entregables

- pantalla de login
- pantalla de setup inicial
- flujo de seleccion de sucursal
- flujo de seleccion de usuario
- integracion del shell con sesion real
- bloqueo de modulos si no hay contexto valido

### Criterio de cierre

- la app no entra al shell sin sesion valida
- el usuario no puede operar sin sucursal activa
- el POS no puede operar sin usuario y caja definidos
- el cambio de usuario y sucursal ya no depende de mocks

## Fase 2. Administracion Base

### Objetivo

Cubrir el anillo administrativo minimo para que el negocio pueda configurarse sin depender de la app vieja.

### Alcance

- CRUD de usuarios
- editor de usuarios
- asignacion de roles
- asignacion de sucursales
- activacion/desactivacion
- PIN o credencial
- CRUD de sucursales
- editor de sucursales
- configuracion basica de cajas por sucursal
- permisos por rol

### Entregables

- modulo de usuarios
- modulo de sucursales
- editor de usuario
- editor de sucursal
- validaciones administrativas
- reglas de permisos

### Criterio de cierre

- se pueden crear usuarios nuevos desde StockV2
- se pueden crear sucursales nuevas desde StockV2
- se puede editar usuario y sucursal sin tocar Universal
- las acciones sensibles responden a permisos reales

## Fase 3. Catalogo y Productos

### Objetivo

Dar de alta y mantener el catalogo de productos dentro del modelo nuevo, preparado para inventario por ubicacion y proveedor.

### Alcance

- CRUD de productos
- categorias
- SKU/codigo
- costo
- precio de venta
- estado activo/inactivo
- relacion con proveedor
- relacion con ubicaciones
- historial basico de cambios

### Entregables

- listado de productos
- alta de producto
- editor de producto
- validacion de campos obligatorios
- persistencia real

### Criterio de cierre

- un producto creado puede verse en inventario, proveedores y POS
- el producto tiene costo y precio validos
- el producto puede asociarse a proveedor y ubicacion
- la edicion de productos ya no depende de formularios mock

## Fase 4. Caja y Turnos

### Objetivo

Convertir el flujo visual actual de apertura y cierre de caja en una operacion real persistida.

### Alcance

- apertura real de caja
- cierre real de caja
- arqueo
- diferencia esperada vs contada
- caja por sucursal
- caja por usuario
- historial de aperturas y cierres
- reglas de bloqueo operativo

### Entregables

- persistencia de caja
- historial de cajas
- acciones reales desde sidebar y POS
- reglas de validacion para operar

### Criterio de cierre

- la caja abierta queda registrada
- el cierre registra monto contado y diferencia
- el POS responde al estado real de caja
- existe historial minimo de aperturas y cierres

## Fase 5. POS Operativo

### Objetivo

Convertir el POS actual en flujo real de venta.

### Alcance

- carrito real
- busqueda de productos
- agregar/quitar items
- cantidades
- descuentos
- cliente opcional
- medios de pago
- suspender/recuperar venta
- confirmacion de venta
- generacion de transaccion
- impacto en caja e historial

### Entregables

- view model real de venta
- persistencia de ventas
- integracion con caja
- integracion con productos
- primer flujo end-to-end de venta

### Criterio de cierre

- una venta puede iniciarse, cobrarse y persistirse
- la venta queda asociada a usuario, sucursal y caja
- la transaccion aparece en historial/reportes

## Fase 6. Proveedores y Compras

### Objetivo

Hacer real el modulo de proveedores y su flujo de pedidos.

### Alcance

- CRUD de proveedores
- editor de proveedor
- catalogo por proveedor
- pedido multi-item persistido
- recepcion de pedido
- impacto en stock
- pagos/facturas basicos
- historial por proveedor

### Entregables

- alta y edicion de proveedores
- pedidos persistidos
- recepcion de compras
- relacion compras -> productos -> stock

### Criterio de cierre

- un proveedor puede crearse y editarse
- un pedido puede emitirse y recibirse
- la recepcion actualiza stock en el modelo nuevo

## Fase 7. Inventario Real

### Objetivo

Implementar el dominio central del producto nuevo: inventario por ubicacion y proveedor.

### Alcance

- CRUD de ubicaciones
- jerarquia fisica
- stock por ubicacion
- stock por proveedor
- movimientos
- ajustes
- conteos
- reposicion
- historial de stock

### Entregables

- dominio de inventario 2.0
- pantallas reales de ubicaciones, proveedores y productos
- operaciones de movimiento y ajuste

### Criterio de cierre

- el stock ya no depende del modelo legacy de stock plano
- una venta y una compra pueden reflejarse en el inventario nuevo
- existe trazabilidad basica por ubicacion y proveedor

## Fase 8. Reportes Reales

### Objetivo

Conectar el modulo de reportes actual a datos reales.

### Alcance

- resumen real
- compras y margen real
- transacciones reales
- anulacion persistida
- top productos real
- filtros por periodo y sucursal

### Entregables

- reportes conectados a ventas, compras y stock
- reglas de margen basadas en costo real
- anulacion de transacciones con auditoria minima

### Criterio de cierre

- el modulo de reportes deja de depender de mocks
- los filtros reflejan datos reales del negocio
- las anulaciones impactan historial y estados

## Fase 9. Settings, Historial y Auditoria

### Objetivo

Cerrar el anillo de administracion extendida y soporte operativo.

### Alcance

- settings generales
- preferencias POS
- datos del negocio
- configuracion fiscal si aplica
- historial de ventas
- historial de pedidos
- historial de cambios de stock
- auditoria de anulaciones y acciones sensibles

### Entregables

- modulo de settings modular
- historial consolidado
- auditoria minima

### Criterio de cierre

- la operacion administrativa ya no depende de Universal
- existe trazabilidad basica de acciones sensibles

## Estrategia de migracion por fase

### Se adapta primero

- auth
- seleccion de usuario
- seleccion de sucursal
- setup inicial
- reglas de caja y permisos
- parte de productos
- parte de proveedores
- parte de reportes

### Se rehace primero

- shell y navegacion
- inventario por ubicacion/proveedor
- UX de POS
- UX de reportes
- UX de proveedores
- administracion modular nueva

### Se posterga si no bloquea

- importacion/exportacion
- settings avanzados
- subscripciones
- herramientas de mantenimiento no criticas

## Hitos sugeridos

1. `Milestone A`
   Acceso real + usuario + sucursal + caja

2. `Milestone B`
   Administracion base + productos

3. `Milestone C`
   POS operativo + proveedores/compras

4. `Milestone D`
   Inventario 2.0 funcionando

5. `Milestone E`
   Reportes reales + auditoria minima

## Regla de decision

Si una pieza de Universal ya resuelve negocio reusable y no depende de `producto -> stock total`, se adapta.

Si la pieza esta demasiado mezclada con UI vieja, shell viejo o supuestos de inventario legacy, se rehace.

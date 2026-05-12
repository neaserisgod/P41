# Backend Migration Matrix

Fecha de revision: 2026-05-09

## Estado general

La app nueva ya consume backend real para autenticacion, negocio y sucursales.

Todavia no consume backend real para catalogo, ventas, caja, proveedores, inventario ni reportes. Esos modulos siguen apoyados en controladores locales o datos mock.

## Negocio local verificado

Usuario probado:

- `laplazoleta25@gmail.com`
- `business_id = 14`

Datos reales encontrados en Postgres local para `business_id = 14`:

- sucursales: 1
- productos: 115
- ventas: 31
- proveedores: 11
- pedidos: 11
- turnos: 10
- staff: 2

## Matriz por modulo

| Modulo app nueva | Estado actual en app | Backend disponible | Datos reales para business 14 | Viabilidad de migracion | Observaciones |
| --- | --- | --- | --- | --- | --- |
| Login / setup | Integrado | Si | Si | Alta | Ya usa `/public/system-status`, `/api/auth/login`, `/api/auth/me`, `/api/branches`, `/api/staff` |
| Sucursales | Integrado para lectura | Si | Si | Alta | CRUD disponible en `/api/branches` |
| Usuarios | Parcial | Si | Si | Alta | La app hoy hidrata login desde `user_profiles` y fallback a `staff`; falta conectar pantallas admin |
| Staff operativo | Parcial | Si | Si | Alta | CRUD en `/api/staff`; la app todavia no usa ese backend en la gestion interna |
| Catalogo / productos | Local mock | Si | Si | Alta | CRUD en `/api/products`; hoy la app usa `CatalogController` hardcodeado |
| Ventas POS | Local en memoria | Si | Si | Alta | Alta y listado en `/api/sales`; el backend ya descuenta stock |
| Caja / turnos | Local en memoria | Si | Si | Alta | `/api/shifts` y `cash_movements` cubren apertura, cierre y resumen |
| Proveedores | Local en memoria | Parcial directa, completa via sync | Si | Media-Alta | Hay modelo `suppliers` real, pero no hay router REST dedicado; hoy entra por `/api/sync` |
| Pedidos a proveedores | Local en memoria | Si | Si | Alta | `/api/orders` existe y al recibir ajusta stock |
| Inventario / stock por sucursal | Vista local derivada | Si | Parcialmente verificable | Media-Alta | El backend tiene `branch_stocks`, pero la UI actual modela ubicaciones fisicas que no existen como entidad backend |
| Reportes | Mock | Parcial | Si | Media | El backend tiene ventas, caja y pedidos, pero la pantalla actual usa snapshots mock y no un agregado real |

## Diferencias de modelo que importan

### 1. Productos

La UI nueva hoy modela:

- `supplierName`
- `locationId`
- `locationName`
- `locationType`

El backend real de `products` hoy modela:

- `supplier_id`
- `branch_id`
- `stock`
- `min_stock`
- sin entidad nativa de `locationName` o `locationType`

Conclusion:

- la migracion de productos es viable
- pero la parte de "ubicaciones fisicas" no tiene correspondencia directa hoy
- hay que decidir si se elimina de la UI, se deriva visualmente, o se agrega al backend

### 2. Proveedores

El backend tiene tabla y schema de `suppliers`, pero no expone un router REST dedicado como `/api/suppliers`.

Conclusion:

- los datos existen y se sincronizan por `/api/sync`
- si la app macOS nueva quiere CRUD simple de proveedores, conviene agregar `GET/POST/PUT/DELETE /api/suppliers`

### 3. Inventario

El backend soporta:

- `products.stock`
- `branch_stocks`
- ajustes por ventas
- ajuste al recibir pedidos

La UI nueva hoy muestra inventario navegando:

- ubicaciones
- proveedores dentro de ubicaciones
- productos dentro del proveedor

Conclusion:

- el stock real existe
- la estructura visual de ubicaciones no existe en backend como entidad persistida

### 4. Reportes

La app usa datos mock en `ReportsViewModel`.

El backend ya tiene base real para construir:

- ventas por periodo
- ticket promedio
- ventas por medio de pago
- pedidos a proveedores
- caja por turno

Conclusion:

- la migracion es viable
- pero requiere armar un adaptador o endpoints de agregacion
- no alcanza con "conectar una lista"

## Conclusión operativa

Si la pregunta es:

`podemos migrar todos los datos actuales a como se muestran en la app nueva?`

La respuesta correcta es:

- `si`, el backend actual ya contiene casi todo el dominio de negocio necesario
- `no`, la app nueva todavia no esta conectada a esos datos fuera de auth/sucursales
- `no`, algunas pantallas no matchean 1:1 con el modelo persistido actual, sobre todo inventario por ubicacion y reportes

## Orden recomendado de migracion

1. Catalogo y productos
2. Proveedores y pedidos
3. Caja y turnos
4. POS y ventas
5. Inventario real por sucursal
6. Reportes agregados
7. CRUD admin de usuarios y staff

## Decisiones tecnicas pendientes

1. Definir si la app nueva va a consumir CRUD directo por modulo o `/api/sync`
2. Definir si "ubicaciones" se agregan al backend o se eliminan de la UI actual
3. Definir si usuarios operativos salen de `staff_members`, `user_profiles`, o una combinacion
4. Definir si reportes se calculan en backend o en cliente sobre datos crudos

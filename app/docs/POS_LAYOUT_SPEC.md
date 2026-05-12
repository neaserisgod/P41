# POS Layout Spec

## Objetivo

Definir un POS puro.

La pantalla de POS debe servir solo para vender.
No debe convertirse en una extension de inventario, proveedores, reposicion o auditoria.

## Regla principal

El POS:

- consume informacion minima del inventario
- no administra inventario
- no administra ubicaciones
- no administra proveedores
- no muestra vistas operativas secundarias

## Que resuelve el POS

- buscar productos
- escanear productos
- agregar items al carrito
- editar cantidad
- editar precio si el rol lo permite
- aplicar descuentos
- asociar cliente si aplica
- cobrar
- suspender venta
- recuperar venta

## Que no resuelve el POS

- conteos de stock
- transferencias
- reposicion
- ajustes manuales
- alta o edicion de ubicaciones
- alta o edicion de proveedores
- analisis de inventario
- auditoria de movimientos

Todo eso vive en tabs separadas.

## Distribucion recomendada

El POS debe tener una estructura simple de tres bloques:

1. barra superior de contexto
2. superficie principal de productos
3. columna fija de carrito y cobro

## 1. Barra superior de contexto

Ubicada debajo de la navbar global.

Debe mostrar solo contexto util para la venta:

- nombre de caja o terminal
- cajero activo
- sucursal activa
- turno activo
- estado de sincronizacion
- acciones rapidas

Acciones rapidas sugeridas:

- nueva venta
- suspender venta
- recuperar venta
- buscar cliente
- abrir teclado o scanner si hace falta

No debe incluir accesos a:

- inventario
- proveedores
- reportes
- reposicion

## 2. Superficie principal de productos

Es el foco principal del POS.

Debe incluir:

- buscador grande
- ingreso por scanner
- filtros rapidos
- lista o grid de productos
- acceso a recientes o favoritos

### Reglas

- el foco inicial va al buscador
- el scanner no debe pelear con inputs secundarios
- los filtros deben ser pocos y rapidos
- la seleccion de producto debe ser inmediata

### Informacion de stock permitida

Solo la minima para vender bien:

- disponible
- sin stock
- stock bajo

Si se muestra algo extra, debe ser extremadamente resumido.

No mostrar dentro del POS:

- detalle por heladera
- detalle por gondola
- detalle por proveedor
- movimientos del producto

## 3. Columna fija de carrito y cobro

Ubicada a la derecha en desktop.
Debe permanecer visible toda la operacion.

Debe incluir:

- cliente actual si aplica
- items cargados
- cantidad por item
- precio por item
- descuento por item o total
- subtotal
- impuestos
- total final
- acciones de cobro

### Reglas

- no esconder el carrito
- no abrir modales para cambiar cantidad simple
- no abrir modales para borrar item
- la accion de cobro debe estar siempre clara

## Layout recomendado para desktop

Proporcion sugerida:

- `productos`: 65%
- `carrito y cobro`: 35%

No agregar una tercera columna para inventario.

## Layout recomendado para tablet

- productos como superficie principal
- carrito como panel lateral estable o expandible

## Layout recomendado para mobile

No es la prioridad principal.
Si existe:

- busqueda
- productos
- carrito
- cobro

en flujo simplificado.

## Modales permitidos

Se justifican solo para acciones puntuales:

- seleccionar cliente
- confirmar cancelacion
- cobro complejo
- producto pesable
- venta a cuenta
- observaciones de venta

## Modales no permitidos

No deberian usarse para:

- editar cantidad simple
- eliminar item
- ver stock detallado
- navegar inventario
- administrar proveedor

## Relacion con inventario

El POS puede consultar stock de forma silenciosa para validar venta.

Pero:

- no expone flujos de gestion
- no cambia estructuras de ubicacion
- no cambia reglas de proveedor

Si falta stock o hay conflicto:

- el POS informa
- el modulo de inventario resuelve

## Tabs relacionadas pero separadas

El sistema nuevo puede tener tabs vecinas:

- `Ventas`
- `Inventario`
- `Ubicaciones`
- `Reposicion`
- `Movimientos`
- `Proveedores`

Pero cada una con responsabilidad propia.

La tab `Ventas` no debe absorber tareas de las otras.

## Atajos sugeridos

- `F1`: foco a buscador
- `F2`: foco a carrito
- `F3`: buscar cliente
- `F4`: suspender venta
- `Enter`: agregar producto seleccionado
- `Cmd/Ctrl + Backspace`: cancelar venta con confirmacion

## Errores a evitar

- mezclar venta con control de inventario
- mostrar demasiada informacion en pantalla
- ocultar el carrito
- depender de modales para acciones basicas
- hacer que el cajero piense en proveedores o ubicaciones al cobrar

## Decision actual

La pantalla de POS del proyecto nuevo queda definida como:

- `barra superior de contexto`
- `superficie principal de productos`
- `columna fija de carrito y cobro`

Y queda explicitamente excluido de esta pantalla:

- inventario
- ubicaciones
- proveedores
- reposicion
- auditoria

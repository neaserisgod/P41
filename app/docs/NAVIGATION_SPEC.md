# Navigation Spec

## Objetivo

Definir una navegacion superior tipo tabs de navegador para el proyecto nuevo, evitando mezclar navegacion, layout y logica de negocio.

La barra superior debe permitir:

- abrir tabs
- cerrar tabs
- anclar tabs
- reordenar tabs
- restaurar tabs al reiniciar
- marcar tabs con cambios sin guardar

## Principios

- la navbar no contiene logica de negocio
- el router no es la fuente de verdad de las tabs
- las screens no administran tabs por su cuenta
- toda accion sobre tabs pasa por un `TabManager`
- una tab representa un espacio de trabajo, no solo una vista visual

## Componentes

### AppShell

Contenedor general de la app nueva.

Responsabilidades:

- renderizar top bar
- renderizar contenido activo
- alojar acciones globales
- mantener el layout estable

No debe:

- decidir reglas de negocio
- mutar tabs sin pasar por el manager

### TopTabBar

Barra superior estilo Chrome.

Responsabilidades:

- mostrar tabs abiertas
- mostrar estado visual de activa, anclada y dirty
- exponer acciones de abrir, cerrar, reordenar y anclar

### TabManager

Fuente de verdad del estado de tabs.

Responsabilidades:

- crear tabs
- activar tabs
- cerrar tabs
- anclar tabs
- reordenar tabs
- persistir sesiones
- restaurar sesion previa
- validar cierre de tabs dirty

### WorkspaceRouter

Traduce la tab activa al contenido real.

Responsabilidades:

- resolver el tipo de workspace
- renderizar la screen correcta
- hidratar parametros de la tab activa

No debe:

- decidir orden de tabs
- persistir estado de tabs

## Modelo de tab

Cada tab debe soportar como minimo:

- `id`
- `kind`
- `title`
- `icon`
- `route`
- `params`
- `pinned`
- `closable`
- `dirty`
- `restorable`
- `createdAt`
- `updatedAt`

## Tipos de tabs

### Tabs fijas

Son tabs estructurales del sistema. Pueden venir preancladas.

Tabs sugeridas:

- `Inicio`
- `Ventas`
- `Inventario`
- `Ubicaciones`
- `Reposicion`
- `Proveedores`
- `Movimientos`
- `Reportes`
- `Configuracion`

Reglas:

- pueden estar ancladas por defecto
- no deberian duplicarse
- pueden ocultarse en futuras versiones, pero no en V1

### Tabs dinamicas

Se abren desde acciones de usuario sobre entidades o contextos.

Ejemplos:

- `Producto: Coca Cola 500ml`
- `Heladera 1`
- `Gondola Bebidas`
- `Estante A3`
- `Proveedor: Pepsi`
- `Movimiento #1842`
- `Conteo de Stock 07/05`

Reglas:

- pueden duplicarse si el contexto cambia
- deben poder cerrarse
- deben poder anclarse
- deben restaurarse si `restorable = true`

## Reglas de apertura

### Abrir tab fija

Si ya existe, se activa.
Si no existe, se crea y se activa.

### Abrir tab dinamica

Si ya existe una tab del mismo `kind` y mismo identificador de entidad, se activa esa tab.
Si no existe, se crea una nueva.

### Abrir en segundo plano

Permitido para acciones como:

- abrir producto desde lista
- abrir ubicacion desde reporte
- abrir proveedor relacionado

## Reglas de cierre

### Cierre simple

Si la tab no esta anclada ni dirty, se cierra sin confirmacion.

### Tab anclada

No se cierra con accion accidental.
Debe requerir:

- desanclar primero, o
- confirmar cierre si la UX final lo admite

### Tab dirty

Debe pedir confirmacion antes de cerrar.

Opciones:

- guardar y cerrar
- descartar y cerrar
- cancelar

### Cierre multiple

Acciones requeridas para menu contextual:

- cerrar
- cerrar otras
- cerrar tabs a la derecha
- cerrar todas las no ancladas
- anclar o desanclar
- duplicar

## Reglas de orden

- drag and drop horizontal
- tabs ancladas siempre primero
- dentro del grupo anclado se pueden reordenar
- dentro del grupo no anclado se pueden reordenar
- no mezclar ancladas y no ancladas durante drag en V1

## Estado visual de tab

Cada tab debe comunicar:

- activa
- hover
- anclada
- dirty
- bloqueada si no es cerrable

Indicadores recomendados:

- `x` para cerrar
- icono de pin para anclada
- punto o marca para dirty

## Persistencia

Persistir como minimo:

- orden
- tab activa
- tabs ancladas
- tabs restorable
- parametros de tabs dinamicas

No persistir:

- modales abiertos
- menus contextuales
- estados efimeros de hover o focus

## Navegacion y router

La URL o ruta interna debe reflejar la tab activa, pero no gobernar el sistema de tabs por si sola.

Regla:

- `TabManager` decide que tab esta abierta
- `WorkspaceRouter` decide que contenido renderizar
- el router sincroniza el contenido visible, no la existencia de tabs

## Que abre en tab y que no

### Abren tab

- modulos principales
- detalle de producto
- detalle de proveedor
- detalle de ubicacion
- reportes
- movimientos auditables

### No abren tab

- confirmaciones
- selectores cortos
- filtros temporales
- formularios de una sola accion
- alertas

Estos deben ir como:

- modal
- drawer
- popover
- panel lateral

## Interacciones clave

### Click izquierdo

- activa tab

### Click medio o atajo equivalente

- cierra tab si es cerrable y no anclada

### Doble click

- opcion reservada
- sugerencia V1: anclar o desanclar

### Click derecho

- abre menu contextual

## Atajos sugeridos

- `Cmd/Ctrl + T`: nueva tab
- `Cmd/Ctrl + W`: cerrar tab actual
- `Cmd/Ctrl + Shift + T`: restaurar ultima tab cerrada
- `Cmd/Ctrl + 1..9`: ir a tab por posicion
- `Cmd/Ctrl + Tab`: siguiente tab
- `Cmd/Ctrl + Shift + Tab`: tab anterior

## V1 recomendada

Implementar en la primera version:

- top bar tipo Chrome
- tabs fijas
- tabs dinamicas
- tabs cerrables
- tabs anclables
- drag and drop
- dirty state
- persistencia de sesion
- menu contextual basico

## V2 posible

- grupos de tabs
- split view
- tabs por rol
- tabs compartidas por sucursal
- restauracion de sesion por usuario

## Decision actual

La navegacion del nuevo proyecto queda definida como:

- `top navbar` persistente
- estilo `browser tabs`
- tabs fijas para modulos
- tabs dinamicas para entidades y contextos operativos
- `TabManager` como fuente de verdad
- router subordinado al sistema de tabs

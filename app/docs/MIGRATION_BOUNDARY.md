# Migration Boundary

## Se reutiliza

- auth
- business profile
- branches
- staff y permisos
- servicios compartidos no acoplados a inventario legacy

## Se adapta

- proveedores
- dashboard
- reportes
- POS, si necesita descontar por ubicacion

## Se reconstruye

- inventario
- ubicaciones fisicas
- stock por ubicacion
- stock por proveedor
- movimientos de stock
- reposicion
- conteos y auditoria

## Regla principal

Nada nuevo dentro de este proyecto debe depender de la premisa `producto -> stock total` como fuente unica de verdad.

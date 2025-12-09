# La Mansión Velasco - Cliente CLI

Cliente de línea de comandos interactivo para jugar la API de La Mansión Velasco.

## Ejecución

### Con Docker (recomendado)

```bash
# Desde la raíz del proyecto, primero levanta el servidor
docker-compose up -d

# Luego ejecuta el cliente
docker-compose --profile play run --rm cli
```

### Sin Docker

```bash
cd client
bundle install
ruby bin/play http://localhost:3000
```

## Comandos del Juego

| Comando | Descripción |
|---------|-------------|
| `mirar` | Ver la habitación actual |
| `examinar <objeto>` | Examinar un objeto |
| `usar <item> <objetivo>` | Usar un item en un objetivo |
| `ir <dirección>` | Moverse (norte/sur/este/oeste) |
| `inventario` | Ver inventario y pistas |
| `estado` | Ver estado del juego |
| `terminal <contraseña>` | Ingresar contraseña en terminal |
| `vault` | Abrir caja fuerte (necesita token) |
| `pistas` | Ver pistas recolectadas |
| `ayuda` | Mostrar ayuda |
| `salir` | Salir del juego |

## Atajos

- Direcciones: `n`, `s`, `e`, `o` (norte, sur, este, oeste)
- Inventario: `i` o `inv`
- Examinar: `ex`

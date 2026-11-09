# README – Sistema de consulta de reportes sísmicos

**Autores:** Isabel Cristina Guerra Guzmán y Jhonatan Mosquera Correa  
**Fecha:** Noviembre de 2026  
**Licencia:** GNU GPL v3

## Requisitos previos

- Tener instalado Elixir y Erlang/OTP.
- Ejecutar los comandos desde la carpeta indicada en cada punto, ya que las rutas de los archivos son relativas.
- Compilar el módulo `Util` con `elixirc util.ex` desde cada carpeta donde se ejecute un programa. Esto solo es necesario una vez por carpeta.

---

## Punto 1 – Reporte local

### Ejecución del programa

Para ejecutar el programa y generar el reporte sísmico, primero se debe abrir una terminal y ubicarse en la carpeta `punto-1`.

```bash
cd parcial-2-elixir/punto-1
```

Después, compilar el módulo `Util` y ejecutar el archivo principal:

```bash
elixirc util.ex
elixir observatorio.exs
```

### Archivos de entrada

El programa utiliza dos archivos para obtener la información de las ciudades y sus movimientos sísmicos:

```text
punto-1/resources/ciudades.txt
punto-1/resources/movimientos.txt
```

Estos archivos se leen cada vez que se ejecuta el programa, por lo que cualquier cambio en sus datos se verá reflejado en el siguiente reporte.

### Archivo de salida

El reporte generado se muestra en consola y también se guarda en:

```text
punto-1/resources/reporte_sismos.txt
```

Cada vez que se genera un nuevo reporte, se reemplaza el contenido del anterior. Si ocurre algún problema al leer los archivos de entrada, el programa muestra el error correspondiente y conserva el reporte anterior.

### Resultado esperado

Al ejecutar el programa con los datos de prueba, se obtiene el siguiente resumen:

| Ciudad | Movimientos | Mayor magnitud | Profundidad promedio |
|---|---:|---|---|
| Armenia | 2 | S001 · 3.4 | 14.00 km |
| Calarcá | 1 | S002 · 4.1 | 25.00 km |
| Circasia | 0 | No aplica | No aplica |

También se incluyen registros inválidos en los archivos de prueba para verificar su validación. El resultado indica:

- `ciudades.txt`: 3 registros rechazados.
- `movimientos.txt`: 6 registros rechazados.
- Total: 9 registros rechazados.

Las líneas vacías se ignoran y no se cuentan como registros rechazados.

---

## Punto 2 – Consulta entre nodos

Para ejecutar este punto se necesitan dos terminales abiertas al mismo tiempo: una para iniciar el servidor y otra para ejecutar el cliente.

Primero se debe iniciar el servidor y después el cliente. Ambos utilizan la misma cookie de Erlang para poder comunicarse entre sí.

### 1. Iniciar el servidor

En la primera terminal, ubicarse en la carpeta `nodo-servidor`:

```bash
cd parcial-2-elixir/punto-2/nodo-servidor
```

Compilar `Util` y ejecutar el servidor:

```bash
elixirc util.ex
elixir --sname nodoservidor@localhost --cookie parcial2 nodo-servidor.exs
```

El servidor queda esperando las solicitudes del cliente. Para atenderlas, consulta los archivos `resources/ciudades.txt` y `resources/movimientos.txt` de su propia carpeta cada vez que recibe una solicitud.

**Importante:** No se debe cerrar esta terminal mientras se realizan las consultas.

### 2. Iniciar el cliente

En una segunda terminal, ubicarse en la carpeta `nodo-cliente`:

```bash
cd parcial-2-elixir/punto-2/nodo-cliente
```

Compilar `Util` y ejecutar el cliente:

```bash
elixirc util.ex
elixir --sname nodocliente@localhost --cookie parcial2 nodo-cliente.exs
```

El cliente se conecta al servidor y envía las solicitudes en el orden establecido. Luego muestra las respuestas recibidas hasta encontrar el mensaje `:fin`.

Si no logra establecer la conexión, muestra el error en consola y finaliza su ejecución.

### 3. Configuración de los nodos

Para que la comunicación funcione correctamente, se deben tener en cuenta los siguientes aspectos:

- Cada nodo debe tener un nombre diferente.
- Los dos deben utilizar la misma cookie de Erlang.
- El servidor debe iniciarse con el nombre `nodoservidor@localhost`, ya que es el nombre al que intenta conectarse el cliente.

La configuración utilizada en el proyecto es:

| Elemento | Valor |
|---|---|
| Nodo servidor | `nodoservidor@localhost` |
| Nodo cliente | `nodocliente@localhost` |
| Cookie compartida | `parcial2` |

---

## Verificación del punto 2

Para comprobar que las consultas funcionan correctamente, el cliente realiza automáticamente varias solicitudes al servidor.

Estas pruebas permiten verificar qué sucede cuando se consulta una ciudad con movimientos sísmicos, una sin movimientos y otra que no se encuentra registrada.

### Prueba 1 – Ciudad con movimientos sísmicos

**Identificador de la ciudad:**

```text
C01
```

**Resultado esperado:**

El servidor devuelve el reporte de Armenia, donde se encuentran 2 movimientos sísmicos (S001 y S003), una magnitud máxima de `3.4` correspondiente al movimiento S001 y una profundidad promedio de `14.00 km`.

### Prueba 2 – Ciudad sin movimientos sísmicos

**Identificador de la ciudad:**

```text
C03
```

**Resultado esperado:**

El servidor devuelve el reporte de Circasia, indicando que no tiene movimientos registrados. El total es 0 y tanto la magnitud máxima como la profundidad promedio aparecen como «No aplica».

### Prueba 3 – Ciudad inexistente

**Identificador de la ciudad:**

```text
C99
```

**Resultado esperado:**

El servidor responde con el mensaje:

```text
La ciudad no está registrada
```

### Verificar que el servidor siga funcionando

Para comprobar que el servidor puede seguir atendiendo solicitudes sin necesidad de reiniciarse, se debe realizar lo siguiente:

1. Dejar abierta la primera terminal donde se está ejecutando el servidor.
2. Esperar a que el cliente termine de enviar las solicitudes y reciba el mensaje `:fin`.
3. Desde la segunda terminal, volver a ejecutar el cliente con el mismo comando:

```bash
cd parcial-2-elixir/punto-2/nodo-cliente
elixir --sname nodocliente@localhost --cookie parcial2 nodo-cliente.exs
```

**Resultado esperado:**

El cliente vuelve a realizar las consultas y muestra las respuestas correspondientes. Al finalizar, recibe nuevamente el mensaje `:fin`.

Con esto se comprueba que el servidor continúa activo y puede atender nuevas solicitudes sin tener que ejecutarlo otra vez.

**Brayan Alpizar Elizondo**
**Arquitectura de Computadores I**  
**Ingeniería en Computadores - 2026**  
  
**Proyecto:** Integración de Ensamblador RISC-V y C: ChaCha20 Stream Cipher  

##  Descripción del proyecto

  

Este proyecto consiste en la implementación del algoritmo de cifrado de flujo **ChaCha20** utilizando **ensamblador RISC-V**, siguiendo la especificación oficial definida en el **RFC 8439**. El objetivo es demostrar el dominio de las convenciones de llamada de RISC-V, el manejo eficiente de registros y la capacidad de implementar algoritmos criptográficos modernos directamente a partir de su especificación formal.

  

ChaCha20 es un cifrador de flujo diseñado por Daniel J. Bernstein y ampliamente utilizado en sistemas actuales como **TLS 1.3, WireGuard, OpenSSH y la pila de seguridad de Android**. Su diseño se basa únicamente en operaciones aritméticas simples —sumas de 32 bits, rotaciones de bits y operaciones XOR— lo que lo hace altamente eficiente para implementaciones en software y hardware.

  

El algoritmo opera sobre un estado interno de **16 palabras de 32 bits (512 bits)** y utiliza como operación fundamental el **quarter round**, una transformación que mezcla cuatro palabras del estado mediante sumas, XOR y rotaciones. Este diseño se adapta naturalmente a arquitecturas RISC como RISC-V, permitiendo una implementación directa utilizando registros del procesador.

  

En este proyecto se implementan en ensamblador las funciones principales del algoritmo:

  

-  `chacha20_quarter_round`: aplica la operación fundamental del algoritmo sobre cuatro palabras del estado.

-  `chacha20_block`: genera un bloque de **64 bytes de keystream** a partir del estado inicial.

-  `chacha20_encrypt`: cifra mensajes de longitud arbitraria generando bloques de keystream e incrementando el contador.

  

El programa principal, escrito en **C**, se encarga de inicializar la clave, el nonce y el contador, invocar las funciones en ensamblador y verificar la implementación utilizando **vectores de prueba oficiales del RFC 8439**.

  

##  Estructura del repositorio

  

El repositorio está organizado de la siguiente manera:

  ```bash

├── Dockerfile # Define el entorno Docker con las herramientas necesarias (toolchain RISC-V y QEMU)

├── README.md # Documentación principal del proyecto

├── run.sh # Script para ejecutar el entorno del proyecto

├── exec_guide.txt # Archivo con ejemplos de ejecución o salida del programa

│

├── chacha20/ # Directorio que contiene la implementación del algoritmo ChaCha20

│ ├── build/ # Directorio donde se generan archivos durante la compilación

│ ├── build.sh # Script para compilar el proyecto

│ ├── linker.ld # Script de enlace utilizado para generar el ejecutable RISC-V

│ ├── run-qemu.sh # Script para ejecutar el programa usando QEMU

│ ├── debug_test.gdb # Script para iniciar una sesión de depuración con GDB

│ │

│ ├── chacha_program.c # Programa principal en C que invoca las funciones en ensamblador

│ │

│ ├── quarter_round.s # Implementación en ensamblador de la operación Quarter Round

│ ├── inner_block.s # Implementación de la función Inner Block del algoritmo

│ ├── chacha20_block.s # Implementación de la generación de un bloque de keystream

│ ├── chacha20_encrypt.s # Implementación de la función de cifrado ChaCha20

│ ├── startup.s # Código de inicialización del programa

│ │

│ ├── *.o # Archivos objeto generados durante la compilación

│ └── chacha_program.elf # Ejecutable final para arquitectura RISC-V

  ```
  

##  Requisitos previos

Para compilar, ejecutar y depurar el proyecto es necesario contar con los siguientes componentes instalados:

  

1.  **Docker**

-  Permite crear un entorno reproducible con todas las herramientas necesarias para compilar y ejecutar el proyecto.

-  Recomendado instalar la versión más reciente disponible para tu sistema operativo.

-  [Guía oficial de instalación de Docker](https://docs.docker.com/get-docker/)

  

2.  **Toolchain RISC-V**

-  Compilador cruzado para generar ejecutables para la arquitectura RISC-V.

-  Este proyecto utiliza `riscv64-unknown-elf-gcc`.

-  Incluye herramientas como `as`, `ld` y `objdump`.

-  Se puede instalar dentro del contenedor Docker o localmente siguiendo las instrucciones del repositorio oficial de RISC-V.

  

3.  **QEMU**

-  Emulador que permite ejecutar binarios RISC-V en sistemas x86_64.

-  Este proyecto requiere `qemu-system-riscv64`.

-  Se recomienda la versión más reciente compatible con RISC-V 64 bits.

-  Permite simular el hardware y ejecutar el programa ensamblador sin necesidad de una placa física.

  

>  **Recomendación adicional:** Para usuarios de Windows, se recomienda usar **WSL (Windows Subsystem for Linux)** con una distribución de Linux, preferiblemente **Ubuntu**, e instalar **Visual Studio Code (VSC)** para editar y depurar el código. Esto proporciona un entorno más cercano a Linux y facilita la integración con Docker, QEMU y las herramientas de RISC-V.

  
  

#  Construcción y ejecución dentro del entorno Docker

  

Para compilar y ejecutar el proyecto en un entorno reproducible con Docker, sigue estos pasos:

  

##  1. Copiar el repositorio a tu máquina local

Clona el repositorio en tu sistema de archivos local:

  

```bash

git  clone  <URL_DEL_REPOSITORIO>

cd  <NOMBRE_DEL_REPOSITORIO>

  ```

## 2.  Ejecutar  el  ensamblador  y  compilar  el  programa  C

  

Desde  la  terminal,  otorga  permisos  de  ejecución  al  script  y  ejecútalo:

```bash

chmod  +x  run.sh

./run.sh

   ```

## 3.  Construir  el  proyecto

  

Accede  al  directorio  del  proyecto  dentro  del  contenedor  Docker  y  compila:

 ```bash

cd  /home/rvqemu-dev/workspace/chacha20

./build.sh

```

4.  Ejecutar  el  programa  en  QEMU

  

Dentro  del  mismo  directorio,  ejecuta  el  script  que  lanza  el  binario  en  el  emulador:

  
 ```bash
 
./run-qemu.sh

  ```

Nota:  Estos  pasos  configuran  y  ejecutan  el  proyecto  completo  dentro  del  contenedor  Docker,  garantizando  que  se  utilicen  las  versiones  correctas  de  las  herramientas  y  la  arquitectura  RISC-V  emulada  con  QEMU.

## Ejecución de casos de prueba y verificación de vectores del RFC  
  
Los casos de prueba para verificar la correcta implementación del algoritmo ChaCha20 están **predefinidos en el programa principal en C** (`chacha_program.c`). Esto incluye los vectores oficiales del RFC 8439, tanto para **quarter round**, **bloques de 64 bytes** y ejemplos completos de cifrado/descifrado.  
  
Para ejecutar los casos de prueba y verificar los vectores:  
  
1. Asegúrate de haber compilado el proyecto siguiendo las instrucciones anteriores dentro del contenedor Docker.  
2. Ejecuta el programa principal:  
  
```bash  
cd /home/rvqemu-dev/workspace/chacha20  
./run-qemu.sh'
```
El programa imprimirá automáticamente:

-   El resultado de cada quarter round usando los vectores de prueba del RFC.
    
-   Bloques completos de 64 bytes (keystream).
    
-   Texto cifrado y descifrado para verificar que el algoritmo es simétrico.
    
-   Cualquier diferencia con los vectores oficiales será visible inmediatamente en la salida.
    

> Nota: No se requiere ninguna acción adicional, ya que todos los vectores de prueba están incorporados en `main()` y se ejecutan en cada corrida del programa.

## Instrucciones para abrir una sesión de depuración con GDB  
  
Para depurar el programa principal `chacha_program.elf` y analizar la ejecución de ChaCha20, sigue estos pasos:  
  
### 1. Preparar el entorno (Terminal 1)  
Corre el ensamblador y compila el archivo C:  
  
```bash  
chmod +x run.sh  
./run.sh  
cd /home/rvqemu-dev/workspace/chacha20  
./build.sh  
./run-qemu.sh
```
### 2. Abrir una sesión de GDB (Terminal 2)

Dentro de otra terminal, ingresa al contenedor Docker y lanza GDB:
```bash 
docker exec -it rvqemu /bin/bash  
cd /home/rvqemu-dev/workspace/chacha20  
gdb-multiarch chacha_program.elf
```

### Nota adicional

-   Otros comandos útiles para depuración, puntos de ruptura y revisión de registros se encuentran en el archivo `exec_guide.txt`.
    
-   Esto permite inspeccionar el estado interno del algoritmo, verificar vectores de prueba y seguir la ejecución paso a paso dentro de QEMU.
**Autor:** Brayan Alpizar Elizondo  
**Asignatura:** Arquitectura de Computadores 1  
**Carrera:** Ingeniería en Computadores - 2026
  
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

  ```C
├── DOCUMENTACION.md // Documento técnico con explicación del algoritmo, debugging y resultados
├── Dockerfile // Define el entorno Docker para compilar y ejecutar el proyecto en RISC-V
├── README.md // Descripción general del proyecto y guía de ejecución
├── bug_images // Capturas utilizadas para documentar el bug encontrado y su corrección con GDB
│   ├── program_freezed.png 
│   ├── step_1_bugged.png 
│   ├── step_1_fixed.png 
│   ├── step_2_bugged.png 
│   └── step_2_fixed.png 
├── chacha20 // Implementación del algoritmo ChaCha20 en ensamblador RISC-V
│   ├── build // Directorio de archivos generados durante la compilación
│   ├── build.sh // Script de compilación del proyecto
│   ├── chacha20_block.s // Implementación del bloque ChaCha20
│   ├── chacha20_encrypt.s // Implementación del proceso de cifrado
│   ├── chacha_program.c // Programa principal en C (interfaz y pruebas)
│   ├── chacha_program.elf // Ejecutable final para QEMU
│   ├── debug_test.gdb // Script de debugging con GDB
│   ├── inner_block.s // Implementación del inner block del algoritmo
│   ├── linker.ld // Script de linker para organización de memoria
│   ├── quarter_round.s // Implementación de la operación quarter round
│   ├── run-qemu.sh // Script para ejecutar el programa en QEMU
│   └── startup.s // Punto de entrada e inicialización del programa
├── exec.txt // Programa con informacion relevante para la ejecucion
├── result_images // Capturas de resultados intermedios del algoritmo
│   ├── step_1.png
│   ├── step_2.png
│   ├── step_3.png
│   └── step_4.png 
├── run.sh // Script que inicializa el entorno Docker
└── test_images // Capturas usadas para validar el algoritmo con la especificación
    ├── resultado_final_especificacion.png 
    ├── state_after_inner_block.png
    ├── state_before_inner_block.png
    ├── state_especificacion.png
    └── state_plus_working_state.png

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
### 3. Conectarse a QEMU (Terminal 2)

Se debe ejecutar el siguiente comando para empezar a debuggear
```bash 
target remote :1234
```


### Nota adicional

-   Otros comandos útiles para depuración, puntos de ruptura y revisión de registros se encuentran en el archivo `exec_guide.txt`.
    
-   Esto permite inspeccionar el estado interno del algoritmo, verificar vectores de prueba y seguir la ejecución paso a paso dentro de QEMU.
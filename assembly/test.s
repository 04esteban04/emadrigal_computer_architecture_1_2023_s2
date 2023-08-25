.section .data
filename:    .asciz "sekiroGris.bmp"
file_mode:   .asciz "r"

.section .bss
fd:          .space 4          @ Descriptor de archivo

.section .text
.globl _start

_start:
    @ Abrir el archivo
    mov r0, #5                @ Número de llamada al sistema para abrir (5 en Linux)
    ldr r1, =filename         @ Dirección de la cadena de nombre de archivo
    ldr r2, =file_mode        @ Dirección de la cadena de modo de archivo
    svc 0x00                   @ Llamada al sistema

    @ Comprobar errores al abrir el archivo (verificar el valor de retorno en r0)

    @ Leer el archivo aquí usando llamadas al sistema (como read)
    
    @ Cerrar el archivo cuando hayas terminado (usando llamadas al sistema close)

    @ Salir del programa
    mov r0, #1                @ Número de llamada al sistema para salir (1 en Linux)
    svc 0x00                   @ Llamada al sistema

.macro nullwrite outstr
    @ Buscar la longitud de la cadena
    ldr r0, =\outstr         @ Cargar la dirección de outstr
    mov r1, r0               @ Copiar la dirección para el cálculo de la longitud más tarde
1:
    ldrb r2, [r1]            @ Cargar el primer carácter
    cmp r2, #0               @ Comprobar si tenemos un carácter nulo
    beq 2f
    add r1, #1               @ Incrementar la dirección de búsqueda
    b 1b                     @ Volver al principio del bucle
2:
    sub r3, r1, r0           @ Calcular la longitud de la cadena
    
    @ Configurar la llamada al sistema de escritura
    mov r7, #4               @ 4 = write
    mov r0, #1               @ 1 = stdout
    ldr r1, =\outstr         @ Dirección de outstr
    mov r2, r3               @ Cargar la longitud
    svc 0
.endm
@ target remote localhost:1233
.global _start

.section .data
file_path:  .asciz "INPUT.txt"     @ Ruta del archivo a abrir
fd:         .space 4           @ Descriptor de archivo
buffer:     .space 1           @ Buffer para leer un carácter
newline:    .asciz "\n"        @ Carácter de nueva línea
rowBuffer: .space 256         @ Búfer para almacenar una fila completa (ajusta el tamaño según tus necesidades)
bufferTOTALW: .space 1228800   @  1.17 MB Búfer para almacenar una fila completa (ajusta el tamaño según tus necesidades)
filas: .int 480
columnas: .int 640

frecuencia: .float 0.083775

cero: .float 0
aumentoUNO: .float 1
aumentoCINCO: .float 5
aumentoDOS: .float 2
aumentoMedio: .float 0.5

doce: .float 12
trece: .float 13
catorce: .float 14
quince: .float 15

tres: .float 6
cinco: .float 120
siete: .float 5040
nueve: .float 362880
once: .float 39916800

pi: .float 3.141592
dosPi: .float 6.283184
.section .text
_start:

    @ Abre el archivo
    ldr r0, =file_path
    mov r1, #0      @ O_RDONLY (Modo de lectura)
    mov r7, #5      @ Código de llamada al sistema para abrir el archivo
    svc 0

    @ Verifica si hubo un error al abrir el archivo (r0 contiene el descriptor de archivo o el código de error)
    cmp r0, #-1
    beq error

    @ Almacena el descriptor de archivo en r9
    mov r9, r0

    @ Puntero de rowBuffer
    ldr r8, =rowBuffer
    ldr r11, =bufferTOTALW
    @ Contador temp de rowBuffer
    mov r10, #0
    @ Contador total de bufferTotalW
    mov r12, #0
@ Loop para ir leyendo valores del txt y guardarlos en el buffer
loop:
    @ Lee un carácter del archivo
    mov r0, r9
    ldr r1, =buffer
    mov r2, #1        @ Lee un solo carácter a la vez
    mov r7, #3        @ Código de llamada al sistema para leer desde el archivo
    svc 0

    @ Verifica si se llegó al final del archivo (EOF)
    cmp r0, #0
    ble preCalculo

    @ Lee el carácter de buffer
    ldrb r3, [r1]

    @ Si el carácter leído es un salto de línea, imprime la fila completa
    cmp r3, #10
    beq preCarga

    strb r3, [r8, r10]
    add r10, r10, #4

    b loop
@ Guardamos y preparamos los registros que necesitaremos para aplicar el filtro rippling
preCalculo:
    push {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10}
    ldr r2, =filas    @ Cargar la dirección de la etiqueta 'filas' en r0
    ldr r3, =columnas @ Cargar la dirección de la etiqueta 'columnas' en r1
    ldr r7, =frecuencia @ Cargar la dirección de la etiqueta 'columnas' en r1

    ldr r0, [r2]      @ Fila 480
    ldr r1, [r3]      @ Columna 640
    
    mov r2, #0         @ Fila actual (Y)
    mov r3, #0         @ Columna actual (X)
    @ Ax
    ldr r8, =aumentoDOS
    vldr s6, [r8]
    @ Ay
    ldr r8, =aumentoDOS
    vldr s29, [r8]

    b columna_loop
@ Reseteamos la columna
resetColumna:
    mov r3, #0         @ Columna actual (X)
    b columna_loop
@ El loop para ir recorriendo 640x480
columna_loop:
    @ Calcular indice
    mul r5, r3, r0   @ Multiplica X(r3) por 480(ancho r9) y almacena en r5
    add r4, r5, r2   @ Suma el resultado de r5 con Y(r2) y almacena en r4
    mov r5, #4
    mul r4, r4, r5   @ Índice en espacio de memoria

    cmp r4, #1228800
    beq valorNoPermitido

    ldr r10, [r11, r4] @ El valor de la lista (pixel a mover)
    @ Ponemos en cero r4 y r5
    eor r4, r4, r4
    eor r5, r5, r5
    
    @ frecuencia en s10
    vldr s15, [r7]
    
    @ X(S10) y Y(S11) a flotante
    vmov s11, r2
    vmov s10, r3
    vcvt.f32.s32 s10, s10
    vcvt.f32.s32 s11, s11

    @ Lo de S10 S11 lo multiplicamos por la periodo
    vmul.f32 s10, s10, s15 
    vmul.f32 s11, s11, s15

    @Se les cambian las coordenadas a S10 S11
    bl analisisCoordenas 
@@@@@@@@@@@@@@@@@@@@@@@@@@
    @ Y' = y + s6 * sen (0.3 * x)
    @ En s3 tiene el valor de X y en s15 tenemos el acumulado
    vmov s3, s10
    bl sen
    @ s6 * sen (0.3 * x)
    vmul.f32 s15, s15, s29
    @ s6 * sen (0.3 * x) a entero
    vcvt.s32.f32 s18, s15 
    vmov r4, s18
    @ Y' = y + s6 * sen (0.3 * x)
    add r4, r2, r4

    @ Para los valores negativos o rango no permitido
    cmp r4, #0
    blt valorNoPermitido
    cmp r4, #480
    bge valorNoPermitido
@@@@@@@@@@@@@@@@@@@@@@@@@@
    @ X' = x + s6 * sen (0.3 * y)
    @ En s3 tiene el valor de X y en s15 tenemos el acumulado
    vmov s3, s11
    bl sen
    @ s6 * sen (0.3 * y)
    vmul.f32 s15, s15, s6
    @ s6 * sen (0.3 * y) a entero
    vcvt.s32.f32 s19, s15 
    vmov r5, s19
    @ X' = x + s6 * sen (0.3 * x)
    add r5, r3, r5

    @ Para los valores negativos rango no permitido
    cmp r5, #0
    blt valorNoPermitido
    cmp r5, #640
    bge valorNoPermitido
@@@@@@@@@@@@@@@@@@@@@@@@@@
    @ Calcular indice
    mul r5, r5, r0   @ Multiplica X(r3) por 480(ancho r9) y almacena en r5
    add r4, r5, r4   @ Suma el resultado de r5 con Y(r2) y almacena en r4
    mov r5, #4
    mul r4, r4, r5   @ Índice en espacio de memoria
    
    cmp r4, #1228800
    bge valorNoPermitido

    str r10, [r11, r4] @ El valor de la lista (NUEVO INDICE)

    @ Pasamos la amplitud a int para compararala con el valor maximo, que esta puede tener
    @vcvt.s32.f32 s6, s6 
    @vmov r10, s6
    @cmp r10, #2
    @bge resetContadorAx
    @vmov s6, r10
    @vcvt.f32.s32 s6, s6 
    @ Para Ay
    @vcvt.s32.f32 s29, s29 
    @vmov r10, s29
    @cmp r10, #5
    @bge resetContadorAy
    @vmov s29, r10
    @vcvt.f32.s32 s29, s29 

    @vadd.f32 s6, s6, s7
    @vadd.f32 s29, s29, s7

    @ Contadores de fila y columna
    add r3, r3, #1    @ Incrementar el contador de columna
    cmp r3, r1         @ Comparar contador de columna con número de columnas
    blt columna_loop   @ Saltar de nuevo al bucle de columna si r5 < r3

    add r2, r2, #1    @ Incrementar el contador de fila
    cmp r2, r0         @ Comparar contador de fila con número de filas
    blt resetColumna @ Saltar de nuevo al bucle interno de fila si r4 < r2

    pop {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9,r10}
    b preSend
@ Reseteamos la amplitud de Ay
resetContadorAy:
    ldr r8, =aumentoUNO
    vldr s29, [r8]
    vadd.f32 s6, s6, s7
    @ Contadores de fila y columna
    add r3, r3, #1    @ Incrementar el contador de columna
    cmp r3, r1         @ Comparar contador de columna con número de columnas
    blt columna_loop   @ Saltar de nuevo al bucle de columna si r5 < r3

    add r2, r2, #1    @ Incrementar el contador de fila
    cmp r2, r0         @ Comparar contador de fila con número de filas
    blt resetColumna @ Saltar de nuevo al bucle interno de fila si r4 < r2

    pop {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9,r10}
    b preSend    
@ Reseteamos la amplitud de Ax
resetContadorAx:
    ldr r8, =aumentoUNO
    vldr s6, [r8]
    vadd.f32 s29, s29, s7
    @ Contadores de fila y columna
    add r3, r3, #1    @ Incrementar el contador de columna
    cmp r3, r1         @ Comparar contador de columna con número de columnas
    blt columna_loop   @ Saltar de nuevo al bucle de columna si r5 < r3

    add r2, r2, #1    @ Incrementar el contador de fila
    cmp r2, r0         @ Comparar contador de fila con número de filas
    blt resetColumna @ Saltar de nuevo al bucle interno de fila si r4 < r2

    pop {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9,r10}
    b preSend
@ Trasladamos las coordenadas de X y Y a su equivalente de 0 a 2pi
analisisCoordenas:
    push {r4}
    @ Cargar la dirección de la etiqueta 'dosPi' en r4

    ldr r4, =dosPi
    vldr s8, [r4]

    @ r9 lo pasamos a float s3 y s4
    vmov s3, S10
    vmov s4, s11

    @ s3 lo dividimos por s8(2pi)
    vdiv.f32 s3, s3, s8

    @ s3 sacamos la parte entera de s0
    vcvt.s32.f32 s3, s3

    @ s3 lo pasamos a float
    vcvt.f32.s32 s3, s3

    @ s3 lo multiplicamos por s8(2pi)
    vmul.f32 s3, s3, s8
    
    @ s10 lo restamos por s3
    vsub.f32 s10, s10, s3
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
    @ s4 lo dividimos por s8(2pi)
    vdiv.f32 s4, s4, s8

    @ s4 sacamos la parte entera de s0
    vcvt.s32.f32 s4, s4

    @ s4 lo pasamos a float
    vcvt.f32.s32 s4, s4

    @ s4 lo multiplicamos por s8(2pi)
    vmul.f32 s4, s4, s8
    
    @ s11 lo restamos por s4
    vsub.f32 s11, s11, s4
    
    pop {r4}
    bx lr
@ Casos cuando el X o Y, dan negativo o se salen del rango
valorNoPermitido:
    @vadd.f32 s6, s6, s7 
    @ Contadores de fila y columna
    add r3, r3, #1    @ Incrementar el contador de columna
    cmp r3, r1         @ Comparar contador de columna con número de columnas
    blt columna_loop   @ Saltar de nuevo al bucle de columna si r5 < r3

    add r2, r2, #1    @ Incrementar el contador de fila
    cmp r2, r0         @ Comparar contador de fila con número de filas
    blt resetColumna @ Saltar de nuevo al bucle interno de fila si r4 < r2

    pop {r0, r1, r2, r3, r4, r5, r6}
    b preSend
@ Pasamos los valores de ascii a int
preCarga:
    @ Valores de rowBuffer
    ldr r7, [r8, #0]  
    ldr r6, [r8, #4]  
    ldr r5, [r8, #8]
    @ Valores de rowBuffer en decimal
    sub r7, r7, #48
    sub r6, r6, #48
    sub r5, r5, #48
    @ Casos de la cantidad de digitos
    cmp r10, #4
    beq unDigito

    cmp r10, #8
    beq dosDigito

    cmp r10, #12
    beq tresDigito
@ Caso de lectura para solo un digito
unDigito:
    @ Guardamos el primero digito en el bufferTOTAL
    strb r7, [r11, r12]
    add r12, r12, #4
    b resetRow
@ Caso de lectura para solo dos digito
dosDigito:
    mov r4, #10
    mul r7, r7, r4

    add r7, r7, r6
    @ Guardamos los dos digito en el bufferTOTAL
    strb r7, [r11, r12]
    add r12, r12, #4
    b resetRow
@ Caso de lectura para solo tres digito
tresDigito:
    @ 301
    mov r4, #100
    mul r7, r7, r4
    
    mov r4, #10
    mul r6, r6, r4 
    
    add r7, r7, r6  
    add r7, r7, r5 
    @ Guardamos los tres digito en el bufferTOTAL
    strb r7, [r11, r12]
    add r12, r12, #4
    b resetRow

@ Caso para resetear la fila
resetRow:
    @ Limpiamos los registros
    eor r7, r7
    eor r6, r6
    eor r5, r5
    eor r4, r4

    @ Reinicia el puntero de row_buffer al comienzo
    mov r10, #0
    ldr r8, =rowBuffer
    b loop
@ Preparar el buffer para imprimir los valores
preSend:
    @ Contador total de bufferTotalW
    mov r12, #4
    ldr r11, =bufferTOTALW
    b send
@ Caso de lectura para solo un digito
send:
    @ Ver si llegamos al final de la lista
    cmp r12, #1228800
    beq end_program
    
    ldr r7, [r11] @El valor de la lista

    mov     r0, r7          @ move total to r4
    ldr     r1, =outstr     @ move buffer to r1 for write
    @ zero out output 
    mov     r2, #0          @ store null byte to use 
    str     r2, [r1]        @ bytes 0-3 
    str     r2, [r1, #4]    @ bytes 4-7 
    str     r2, [r1, #8]    @ bytes 8-11  
    bl      itoa            
    
    @ setup nullwrite 
    nullwrite   outstr
    
    add r12, r12, #4
    add r11, r11, #4
    b send
@ Serie del 6 termino de Taylor para sen 
sen:
    push {r0}
    @ En s3 viene el valor de X o Y y en s15 tenemos el acumulado
    @ X^3

    vmul.f32 s15, s3, s3
    vmul.f32 s15, s3, s15

    ldr r0, =tres
    vldr s20, [r0]
    vdiv.f32 s15, s15, s20
    
    @ X - X^3
    vsub.f32 s15, s3, s15
    
    @ X^5
    vmul.f32 s16, s3, s3
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16

    ldr r0, =cinco
    vldr s20, [r0]
    vdiv.f32 s16, s16, s20

    @ (X - X^3) + X^5
    vadd.f32 s15, s16, s15

    @ X^7
    vmul.f32 s16, s3, s3
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    
    ldr r0, =siete
    vldr s20, [r0]
    vdiv.f32 s16, s16, s20

    @ ((X - X^3) + X^5) - X^7
    vsub.f32 s15, s15, s16

    @ X^9
    vmul.f32 s16, s3, s3
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16

    ldr r0, =nueve
    vldr s20, [r0]
    vdiv.f32 s16, s16, s20

    @ (((X - X^3) + X^5) - X^7) + X^9
    vadd.f32 s15, s16, s15
    
    @ X^11
    vmul.f32 s16, s3, s3
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    
    ldr r0, =once
    vldr s20, [r0]
    vdiv.f32 s16, s16, s20
    
    @ ((((X - X^3) + X^5) - X^7) + X^9) - X^11
    vsub.f32 s15, s15, s16

    @ X^13
    vmul.f32 s16, s3, s3
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16

    ldr r0, =once
    vldr s20, [r0]
    ldr r0, =doce
    vldr s21, [r0]
    ldr r0, =trece
    vldr s22, [r0]

    vmul.f32 s20, s21, s20
    vmul.f32 s20, s22, s20
    vdiv.f32 s16, s16, s20
    
    @ (((((X - X^3) + X^5) - X^7) + X^9) - X^11) + X^13 
    vadd.f32 s15, s15, s16

    @ X^15
    vmul.f32 s16, s3, s3
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16

    ldr r0, =catorce
    vldr s23, [r0]
    ldr r0, =quince
    vldr s24, [r0]

    vmul.f32 s20, s23, s20
    vmul.f32 s20, s24, s20
    vdiv.f32 s16, s16, s20
    
    @ ((((((X - X^3) + X^5) - X^7) + X^9) - X^11) + X^13) - X^15 
    vsub.f32 s15, s15, s16

    pop {r0}
    bx lr
@ Caso final para cerrar el archivo y terminar el programa
end_program:
    @ Cierra el archivo
    mov r0, r9
    mov r7, #6         @ Código de llamada al sistema para cerrar el archivo
    svc 0
    
    ldr r11, =bufferTOTALW
    ldr r7, [r11] @El valor de la lista
    
    mov     r0, r7          @ move total to r4
    ldr     r1, =outstr     @ move buffer to r1 for write
    @ zero out output 
    mov     r2, #0          @ store null byte to use 
    str     r2, [r1]        @ bytes 0-3 
    str     r2, [r1, #4]    @ bytes 4-7 
    str     r2, [r1, #8]    @ bytes 8-11  
    bl      itoa            
    
    @ setup nullwrite 
    nullwrite   outstr

    @ Salida del programa
    mov r0, #0         @ Código de retorno
    mov r7, #1         @ Código de llamada al sistema para salir
    svc 0
@ Caso para manejar un error a la hora de abrir el archivo txt
error:
    @ Manejo de errores (puedes personalizarlo según tus necesidades)
    mov r0, #1         @ Descriptor de archivo estándar (salida estándar)
    ldr r1, =newline
    mov r2, #1         @ Longitud del buffer (1 byte)
    mov r7, #4          @ Código de llamada al sistema para escribir en el archivo
    svc 0

    @ Salida del programa con código de error
    mov r0, #-1
    mov r7, #1
    svc 0

.data
outstr:     .fill 12        @ Digitos maximos son 10 
                            @ 11 para el /n

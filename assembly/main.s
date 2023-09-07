.macro      nullwrite       outstr
    @ Find length of string 
    ldr     r0, =\outstr        @ load outstring address
    mov     r1, r0              @ copy address for len calc later 
1:
    ldrb    r2, [r1]            @ load first char 
    cmp     r2, #0              @ check to see if we have a null char 
    beq     2f  
    add     r1, #1              @ Increment search address 
    b       1b                  @ go back to beginning of loop     
2:
    sub     r3, r1, r0          @ calculate string length 
    
    @ Setup write syscall 
    mov     r7, #4              @ 4 = write 
    mov     r0, #1              @ 1 = stdout 
    ldr     r1, =\outstr        @ outstr address 
    mov     r2, r3              @ load length 
    svc     0 
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

frecuencia: .float 1
cero: .float 0
aumentoCinco: .float 1
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

preCalculo:
    push {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9}
    ldr r2, =filas    @ Cargar la dirección de la etiqueta 'filas' en r0
    ldr r3, =columnas @ Cargar la dirección de la etiqueta 'columnas' en r1
    ldr r7, =frecuencia @ Cargar la dirección de la etiqueta 'columnas' en r1

    ldr r0, [r2]      @ Fila 480
    ldr r1, [r3]      @ Columna 640
    
    mov r2, #0         @ Fila actual (Y)
    mov r3, #0         @ Columna actual (X)
    
    ldr r8, =cero
    vldr s6, [r8]
    
    ldr r8, =aumentoCinco
    vldr s7, [r8] 

    b columna_loop

fila_loop:
    mov r2, #0         @ Fila actual (Y)
    ldr r8, =cero
    vldr s6, [r8]
    
    b columna_loop

fila_inner_loop:
    mov r3, #0         @ Columna actual (X)
    b columna_loop

columna_loop:
    @ Calcular indice
    mul r5, r3, r0   @ Multiplica X(r3) por 480(ancho r9) y almacena en r5
    add r4, r5, r2   @ Suma el resultado de r5 con Y(r2) y almacena en r4
    mov r5, #4
    mul r4, r4, r5   @ Índice en espacio de memoria

    @ El lx y ly, tiene que ser (20 pi)/3 sen(0.3 * x)

    cmp r4, #1228800
    beq casoFinal

    ldr r10, [r11, r4] @ El valor de la lista (pixel a mover)
    
    eor r4, r4, r4
    eor r5, r5, r5
    
    @ frecuencia en s10
    vldr s15, [r7]
    
    @ X(S10) y Y(S11) a flotante
    vmov s11, r2
    vmov s10, r3
    vcvt.f32.s32 s10, s10
    vcvt.f32.s32 s11, s11

    @ Lo de S10 S11 lo multiplicamos por la frecuencia
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
    @vmul.f32 s17, s15, s6
    @ s6 * sen (0.3 * x) a entero
    vcvt.s32.f32 s18, s15 
    vmov r4, s18
    @ Y' = y + s6 * sen (0.3 * x)
    add r4, r2, r4

    @ Para los valores negativos
    cmp r4, #0
    blt casoNegativo
@@@@@@@@@@@@@@@@@@@@@@@@@@
    @ X' = x + s6 * sen (0.3 * y)
    @ En s3 tiene el valor de X y en s15 tenemos el acumulado
    vmov s3, s11
    bl sen
    @ s6 * sen (0.3 * x)
    @vmul.f32 s19, s15, s6
    @ s6 * sen (0.3 * x) a entero
    vcvt.s32.f32 s19, s15 
    vmov r5, s19
    @ X' = x + s6 * sen (0.3 * x)
    add r5, r3, r5

    @ Para los valores negativos
    cmp r5, #0
    blt casoNegativo

    @ Calcular indice
    mul r5, r5, r0   @ Multiplica X(r3) por 480(ancho r9) y almacena en r5
    add r4, r5, r4   @ Suma el resultado de r5 con Y(r2) y almacena en r4
    mov r5, #4
    mul r4, r4, r5   @ Índice en espacio de memoria
    
    cmp r4, #1228800
    bge casoFinal

    str r10, [r11, r4] @ El valor de la lista (NUEVO INDICE)
    
    vadd.f32 s6, s6, s7
    @add r2, r2, #1
    @ Contadores de fila y columna
    add r3, r3, #1    @ Incrementar el contador de columna
    cmp r3, r1         @ Comparar contador de columna con número de columnas
    blt columna_loop   @ Saltar de nuevo al bucle de columna si r5 < r3

    add r2, r2, #1    @ Incrementar el contador de fila
    cmp r2, r0         @ Comparar contador de fila con número de filas
    blt fila_inner_loop @ Saltar de nuevo al bucle interno de fila si r4 < r2

    pop {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9}
    b preSend


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

casoNegativo:
    @ Calcular indice
    mul r5, r3, r0   @ Multiplica X por 480(ancho r9) y almacena en r5
    add r4, r5, r2   @ Suma el resultado de r5 con Y y almacena en r4
    mov r5, #4
    mul r4, r4, r5   @ Índice en espacio de memoria
    
    vadd.f32 s6, s6, s7
    @ El pixel se pone como cero
    mov r9, #1
    str r9, [r11, r4] @ El valor de la lista (NUEVO INDICE)
    
    @ Contadores de fila y columna
    add r3, r3, #1    @ Incrementar el contador de columna
    cmp r3, r1         @ Comparar contador de columna con número de columnas
    blt columna_loop   @ Saltar de nuevo al bucle de columna si r5 < r3

    add r2, r2, #1    @ Incrementar el contador de fila
    cmp r2, r0         @ Comparar contador de fila con número de filas
    blt fila_inner_loop @ Saltar de nuevo al bucle interno de fila si r4 < r2

    pop {r0, r1, r2, r3, r4, r5, r6}
    b preSend

casoFinal:
    vadd.f32 s6, s6, s7
    @ Contadores de fila y columna
    add r3, r3, #1    @ Incrementar el contador de columna
    cmp r3, r1         @ Comparar contador de columna con número de columnas
    blt columna_loop   @ Saltar de nuevo al bucle de columna si r5 < r3

    add r2, r2, #1    @ Incrementar el contador de fila
    cmp r2, r0         @ Comparar contador de fila con número de filas
    blt fila_inner_loop @ Saltar de nuevo al bucle interno de fila si r4 < r2

    pop {r0, r1, r2, r3, r4, r5, r6}
    b preSend

preCarga:
    @ Valores de rowBuffer
    ldr r7, [r8, #0]  
    ldr r6, [r8, #4]  
    ldr r5, [r8, #8]
    @ Valores de rowBuffer en decimal
    sub r7, r7, #48
    sub r6, r6, #48
    sub r5, r5, #48

    cmp r10, #4
    beq unDigito

    cmp r10, #8
    beq dosDigito

    cmp r10, #12
    beq tresDigito
unDigito:
    @ Guardamos el primero digito en el bufferTOTAL
    strb r7, [r11, r12]
    add r12, r12, #4
    b resetRow

dosDigito:
    mov r4, #10
    mul r7, r7, r4

    add r7, r7, r6
    @ Guardamos los dos digito en el bufferTOTAL
    strb r7, [r11, r12]
    add r12, r12, #4
    b resetRow
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

preSend:
    @ Contador total de bufferTotalW
    mov r12, #4
    ldr r11, =bufferTOTALW
    b send
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
outstr:     .fill 12        @ the max output size is 10 digits 
                            @ 11 for line ending 

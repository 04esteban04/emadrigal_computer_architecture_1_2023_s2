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

f: .float 480
c: .float 640
frecuencia: .float 0.3

tres: .float 6
cinco: .float 120
siete: .float 5040
nueve: .float 362880
once: .float 39916800
pi: .float 3.141592

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
    push {r0, r1, r2, r3, r4, r5, r6, r7}
    ldr r2, =filas    @ Cargar la dirección de la etiqueta 'filas' en r0
    ldr r3, =columnas @ Cargar la dirección de la etiqueta 'columnas' en r1
    ldr r7, =frecuencia @ Cargar la dirección de la etiqueta 'columnas' en r1
    
    ldr r0, [r2]      @ Fila 480
    ldr r1, [r3]      @ Columna 640
    
    mov r2, #0         @ Fila actual (Y)
    mov r3, #0         @ Columna actual (X)
    mov r6, #0

    b columna_loop

fila_loop:
    mov r2, #0         @ Fila actual (Y)
    mov r6, #0
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
    
    @ Trasformamos las coordenadas X (s0) y Y (s1)
    @ para poder hacer la funcion seno
    bl analisisCoordenas
    
    @ X' = x + 1*sen (0.3*y)
    vmov s3, s1
    @ frecuencia en s10
    vldr s10, [r7]
    
    @ Lo de s3 lo multiplicamos por la frecuencia
    vmul.f32 s3, s3, s10
    @ En s3 tiene el valor de X y en s15 tenemos el acumulado
    bl sen
    vmov s18, s15
    @ En r4 = sen(0.3*y)
    vcvt.s32.f32 s15, s15 
    vmov r4, s15
  
    @ En r4 = r6 * sen(0.3*y)
    mul r4, r4, r6
    @ En r4 = X' = x + r6 * sen(0.3*y)
    add r4, r4, r3

    cmp r4, #0              @ Comprobar si X' es negativo
    blt casoNegativo
    
     @ Y' = y + sen (0.3*x)
    vmov s3, s0
    vldr s10, [r7]
    
    @ En s3 lo multiplicamos por la frecuencia
    vmul.f32 s3, s3, s10
    @ En s3 viene el valor de X y en s15 tenemos el acumulado
    bl sen
    
    @ En r5 = sen(0.3*x)
    vcvt.s32.f32 s15, s15 
    vmov r5, s15

    @ En r4 = r6 * sen(0.3*x)
    mul r5, r5, r6
   
    @ En r5 = Y' = y + sen(0.3*x)
    add r5, r5, r2
    
    cmp r5, #0              @ Comprobar si Y' es negativo
    blt casoNegativo
    

    @ Tenemos en r4 (X') y r5 (Y')

    
    mul r9, r4, r0   @ Multiplica X(r3) por 480(ancho r9) y almacena en r5
    add r9, r9, r5   @ Suma el resultado de r5 con Y(r2) y almacena en r4
    mov r4, #4
    mul r9, r4, r9   @ Índice en espacio de memoria

    strb r10, [r11, r9] @ El valor de la lista (NUEVO INDICE)

    add r6, r6, #1
    @ Contadores de fila y columna
    add r3, r3, #1    @ Incrementar el contador de columna
    cmp r3, r1         @ Comparar contador de columna con número de columnas
    blt columna_loop   @ Saltar de nuevo al bucle de columna si r5 < r3

    add r2, r2, #1    @ Incrementar el contador de fila
    cmp r2, r0         @ Comparar contador de fila con número de filas
    blt fila_inner_loop @ Saltar de nuevo al bucle interno de fila si r4 < r2

    pop {r0, r1, r2, r3, r4, r5, r6, r7}
    b preSend

analisisCoordenas:
    @ (640 x 480) rango maximo
    @ r3 (X) y r2 (Y)
    @ X (s0)
    @ Dividir r3/640
    @ (r3/640) * 2 * pi = r4
    @ sen(r4)
    @ Y
    @ Dividir (r2/480)
    @ Multiplicarlo (r2/480) * 2
    @ Resta ((r2/480) * 2) - 1 = r5
    @ sen(r5)
    push {r0, r4, r5}
    
    ldr r4, =f    @ Cargar la dirección de la etiqueta 'filas' en r4
    ldr r5, =c    @ Cargar la dirección de la etiqueta 'columnas' en r5

    @ r3 lo pasamos a float
    vmov s0, r3
    vcvt.f32.s32 s0, s0

    @ s0 lo dividimos por 640
    vldr s10, [r5]
    vdiv.f32 s0, s0, s10

    @ s0 lo multiplicamos por 2
    vmov s10, #2
    vmul.f32 s0, s0, s10

    @ s0 lo multiplicamos por pi
    ldr r0, =pi
    vldr s10, [r0]
    vmul.f32 s0, s0, s10
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    
    @ r2 lo pasamos a float
    vmov s1, r2
    vcvt.f32.s32 s1, s1

    @ s1 lo dividimos por 480
    vldr s10, [r4]
    vdiv.f32 s1, s1, s10

    @ s1 lo multiplicamos por 2
    vmov s10, #2
    vmul.f32 s1, s1, s10

    @ s1 le restamos 1
    vmov s10, #1
    vsub.f32 s1, s1, s10

    pop {r0, r4, r5}
    bx lr

casoNegativo:
    @ Calcular indice
    mul r5, r3, r0   @ Multiplica X por 480(ancho r9) y almacena en r5
    add r4, r5, r2   @ Suma el resultado de r5 con Y y almacena en r4
    mov r5, #4
    mul r4, r4, r5   @ Índice en espacio de memoria
    
    @ El pixel se pone como cero
    mov r9, #0
    strb r9, [r11, r4] @ El valor de la lista (NUEVO INDICE)
    
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

sen:
    push {r0}
    @ En s3 viene el valor de X o Y y en s15 tenemos el acumulado
    @ X^3

    vmul.f32 s15, s3, s3
    vmul.f32 s15, s3, s15

    ldr r0, =tres
    vldr s10, [r0]
    vdiv.f32 s15, s15, s10
    
    @ X - X^3
    vsub.f32 s15, s3, s15
    
    @ X^5
    vmul.f32 s16, s3, s3
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16
    vmul.f32 s16, s3, s16

    ldr r0, =cinco
    vldr s10, [r0]
    vdiv.f32 s16, s16, s10

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
    vldr s10, [r0]
    vdiv.f32 s16, s16, s10

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
    vldr s10, [r0]
    vdiv.f32 s16, s16, s10

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
    vldr s10, [r0]
    vdiv.f32 s16, s16, s10

    @ ((((X - X^3) + X^5) - X^7) + X^9) - X^11
    vsub.f32 s15, s15, s16

    pop {r0}
    bx lr

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

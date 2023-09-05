@ target remote localhost:1233
.section .data
filas: .int 480
columnas: .int 640

.section .text
.global _start

_start:
    ldr r2, =filas    @ Cargar la dirección de la etiqueta 'filas' en r0
    ldr r3, =columnas @ Cargar la dirección de la etiqueta 'columnas' en r1

    ldr r0, [r2]      @ Fila 480
    ldr r1, [r3]      @ Columna 640

fila_loop:
    mov r2, #0         @ Fila actual (Y)

fila_inner_loop:
    mov r3, #0         @ Columna actual (X)

columna_loop:
    @ Calcular indice
    mul r5, r3, r0   @ Multiplica X por 480(ancho r9) y almacena en r5
    add r4, r5, r2   @ Suma el resultado de r5 con Y y almacena en r4
    mul r4, r4, #4   @ Índice en espacio de memoria
    
    cmp r4, #1228800
    beq casoFinal

    ldr r7, [r11, r4] @ El valor de la lista (pixel a mover)

    b xy        @ X' esta en s6 y Y' está en s7

    vcvt.s32.f32 s6, s6
    vmov r4, s6

    vcvt.s32.f32 s7, s7
    vmov r5, s7

    cmp r4, #0              @ Comprobar si X' es negativo
    blt casoFinal

    cmp r5, #0              @ Comprobar si Y' es negativo
    blt casoFinal


    @ Calcular NUEVO indice
    mul r6, r4, r0   @ Multiplica X' por 480(ancho r9) y almacena en r5
    add r4, r6, r5   @ Suma el resultado de r6 con Y y almacena en r4
    mul r4, r4, #4   @ Índice en espacio de memoria
    
    cmp r4, #1228800
    beq casoFinal


    strb r7, [r11, r4] @ El valor de la lista (NUEVO INDICE)


    @ Contadores de fila y columna
    add r3, r3, #1    @ Incrementar el contador de columna
    cmp r3, r1         @ Comparar contador de columna con número de columnas
    blt columna_loop   @ Saltar de nuevo al bucle de columna si r5 < r3

    add r2, r2, #1    @ Incrementar el contador de fila
    cmp r2, r0         @ Comparar contador de fila con número de filas
    blt fila_inner_loop @ Saltar de nuevo al bucle interno de fila si r4 < r2



casoFinal:
    @ Contadores de fila y columna
    add r3, r3, #1    @ Incrementar el contador de columna
    cmp r3, r1         @ Comparar contador de columna con número de columnas
    blt columna_loop   @ Saltar de nuevo al bucle de columna si r5 < r3

    add r2, r2, #1    @ Incrementar el contador de fila
    cmp r2, r0         @ Comparar contador de fila con número de filas
    blt fila_inner_loop @ Saltar de nuevo al bucle interno de fila si r4 < r2
















_start:
    mov r3, #0      @ X actual (columna)
    mov r2, #0      @ Y actual (fila)

    ldr r6, =ancho 
    ldr r9, [r6]    @ Constante ancho

    b recorrerFila
    


calcularxy:
    mul r3, r3, r9   @ Multiplica X por 480(ancho r9) y almacena en r3
    add r1, r3, r2   @ Suma el resultado de r3 con Y y almacena en r1
    mul r1, r1, #4   @ Índice en espacio de memoria

    b xy


calcularIndice:

    vcvt.f32.s32 s6, s6
    vmov r3, s6

    vcvt.f32.s32 s7, s7
    vmov r4, s7

    mul r3, r3, r9   @ Multiplica X por 480(ancho r9) y almacena en r3
    add r0, r3, r4   @ Suma el resultado de r3 con Y y almacena en r0









recorrerFila:
    cmp r2, #480
    beq exit

    cmp r3, #640
    beq recorrerColumna

    add r2, r2, #1      @ Se aumenta contador en 1
    mov r3, #0          @ Se resetea X


recorrerColumna:
    cmp r7, #639
    beq recorrerFila

    cmp r4, #3              @ Compara Ax con el valor máximo
    bge reset_Ax            @ Salta a reset_Ax si es mayor o igual

    cmp r5, #3              @ Compara Ay con el valor máximo
    bge reset_Ay            @ Salta a reset_Ay si es mayor o igual

    ldr r7, [r11, r0] @El valor de la lista

    b newx                 @ Se obtiene el x' en s6
    add r0, r0, #0          @ Intrucción de control

    b newy                 @ Se obtiene el y' en s7
    add r0, r0, #0          @ Intrucción de control 


    @ Indice = (x*ancho) + y    
    @ Ultimo pixel desaparece (369,479)

    @mov r1, #639       @ Carga el valor 4 en r1
    @mov r2, #480     @ Carga el valor 480 en r2
    
    vcvt.f32.s32 s6, s6
    vmov r1, s6

    vcvt.f32.s32 s7, s7
    vmov r4, s7

    mul r3, r1, r9   @ Multiplica 4 por 480 y almacena en r3
    add r0, r3, r4   @ Suma el resultado de la multiplicación con 5 y almacena en r0

    mov r1, #4       @ Carga el valor 4 en r1
    mul r0, r0, r1

    cmp r1, #0              @ Valores negativos
    blt recorrerColumna

    cmp r4, #0              @ Valores negativos
    blt recorrerColumna


    ldr r7, [r11, r0] @El valor de la lista


    add r7, r7, #1
    b recorrerColumna


reset_Ax:
    mov r4, #0              @ Reinicia Ax a su valor mínimo
    b xy_loop               @ Vuelve al inicio del bucle

reset_Ay:
    mov r5, #0              @ Reinicia Ay a su valor mínimo
    b xy_loop               @ Vuelve al inicio del bucle



exit:
    @ setup exit
    mov     r7, #1          @ 1 = exit
    mov     r0, #0          @ 0 = no error
    svc     0

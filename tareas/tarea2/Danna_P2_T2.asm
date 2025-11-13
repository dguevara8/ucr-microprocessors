;*******************************************************************************
;                        PROGRAMA SELECTOR
;*******************************************************************************
;        V1.0
;        AUTOR: Danna Guevara Quesada. C23562
; Descripción:  Programa que ejecuta una XOR entre el primer número de una tabla
;               Mascaras con el último número de una tabla Datos y así
;               sucecivamente hasta llegar a los indicadores de fin de cada
;               tabla, $80 para Datos y $FE para las Mascaras. Si el resultado
;               de las XORs es negativo, el resultado se guarda en el arreglo
;               de resultados cuya direccion esta en la variable Puntero.
;               Las máscaras son de 1 byte sin signo y los números son de
;               1 byte con signo.
;*******************************************************************************
;                        DECLARACIÓN DE ESTRUCTURAS DE DATOS
;*******************************************************************************
                ORG $1000
Puntero:        ds 2

                ORG $1050
Datos:          dB $15, $25, $55, $80

                ORG $1150
Mascaras:       dB $81, $04, $82, $FE
;*******************************************************************************
;                       PROGRAMA PRINCIPAL
;*******************************************************************************
                ORG $2000

                Ldx #Mascaras
                Ldy #Datos
                LdD #$1300
                Std Puntero
                Clrb

Loop            Ldaa B,Y
                Cmpa #$80
                Beq Contador
                Incb
                Bra Loop

Contador        Cmpb #$00
                Beq Fin
                Decb
                Ldaa 0,X
                Cmpa #$FE
                Beq Fin
                Eora B,Y
                Inx
                Bmi Negativo
                Bra Contador

Negativo        Ldy Puntero
                Staa 0,Y
                Iny
                Sty Puntero
                Ldy #Datos
                Bra Contador

Fin             Bra *                           ;Fin del programa
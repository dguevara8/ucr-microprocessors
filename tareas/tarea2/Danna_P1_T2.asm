;*******************************************************************************
;                        PROGRAMA DIVISOR
;*******************************************************************************
;        V1.0
;        AUTOR: Danna Guevara Quesada. C23562

; Descripción:   Programa que recorre el arreglo DATOS de tamaño variable Long con
;                números de 1 byte con signo y copia los números divisibles
;                entre 4 en el arreglo Div_4, además la cantidad de números en
;                Div_4 se guarda en la variable Cant_4.
;*******************************************************************************
;                        DECLARACIÓN DE ESTRUCTURAS DE DATOS
;*******************************************************************************
                ORG $1000
Long:           dB 5
                ORG $1001
Cant_4:         ds 1

                ORG $1100
Datos:          dB $04,$08,$07,$FC,$01

                ORG $1200
Div_4:          ds 1
;*******************************************************************************

;*******************************************************************************
;                       PROGRAMA PRINCIPAL
;*******************************************************************************

                ORG $2000

                Ldx #Datos
                Ldy #Div_4
                Clr Cant_4
                Clrb
                
Loop            Ldaa 0,X
                Anda #$03
                Bne Divisible
                Ldaa 0,X
                Staa B,Y
                Incb
                
Divisible       Ldaa 1,+X
                Dec Long
                Bne Loop
                Stab Cant_4

Fin             Bra *

 
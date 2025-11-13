;*******************************************************************************
;                        PROGRAMA CONVERSIONES
;*******************************************************************************
;        V1.0
;        AUTOR: Danna Guevara Quesada. C23562

; Descripción:  a. Programa que convierte un número binario a BCD y lo guarda
;               en NUM_BCD.
;               b. Programa que convierte un número en BCD a binario y lo guarda
;               en NUM_BIN.
;*******************************************************************************
;                        DECLARACIÓN DE ESTRUCTURAS DE DATOS
;*******************************************************************************
                ORG $1000
BIN:            dw   $0A37
CONT:           ds   1
TEMP:           ds   2
LOW:            ds   1
BCD:            ds   2
BCD_L:          ds   1
BCD_H:          ds   1

                ORG $1010
NUM_BCD:        ds   2

                ORG $1020
NUM_BIN:        ds   2
;*******************************************************************************
;                       PROGRAMA PRINCIPAL A
;*******************************************************************************
                ORG $2000

                Ldd BIN
                Ldaa #12
                Staa CONT
                Clr BCD_L
                Clr BCD_H

Loop:           Lsld
                Rol   BCD_L
                Rol   BCD_H
                Std   TEMP
                
		Ldaa BCD_L
                Anda #$0F
                Cmpa #5
                Bhs Suma1
                Bra Siga1
Suma1:          Adda #3
Siga1:          Staa LOW

                Ldaa BCD_L
                Anda #$F0
                Cmpa #$50
                Bhs Suma2
                Bra Siga2
Suma2:          Adda #$30
Siga2:          Adda LOW
                Staa BCD_L

                Ldab BCD_H
                Andb #$0F
                Cmpb #5
                Bhs Suma3
                Bra Siga3
Suma3:          Addb #3
Siga3:          Ldaa BCD_H
                Anda #$F0
                Aba
                Staa BCD_H

                Ldaa CONT
                Deca
                Staa CONT
                Beq FinLoop
                Bra Loop

FinLoop:
                Lsld
                Rol BCD_L
                Rol BCD_H
                Ldaa BCD_H
                Ldab BCD_L
                Std NUM_BCD

;*******************************************************************************
;                       PROGRAMA PRINCIPAL B
;*******************************************************************************
                Ldd NUM_BCD
                Andb #$0F
                Stab NUM_BIN+1

                Ldd NUM_BCD
                Ldx #16
                Idiv
                Xgdx
                Andb #$0F
                Ldaa #10
                Mul
                Addd NUM_BIN
                Std NUM_BIN
                
                Ldd NUM_BCD
                Ldx #256
                Idiv
                Xgdx
                Andb #$0F
                Ldy #100
                Emul
                Addd NUM_BIN
                Std NUM_BIN

                Ldd NUM_BCD
                Ldx #4096
                Idiv
                Xgdx
                Andb #$0F
                Ldy #1000
                Emul
                Addd NUM_BIN
                Std NUM_BIN
                
Fin             Bra *                   ;Fin del programa

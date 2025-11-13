;*******************************************************************************
;                        PROGRAMA EXAMEN
;*******************************************************************************
;        V1.0
;        AUTOR: Danna Guevara Quesada. C23562

; Descripción:
;*******************************************************************************
;                        DECLARACIÓN DE ESTRUCTURAS DE DATOS
;*******************************************************************************

                ORG $1000
Banderas:       ds 1
Offset:         ds 1

Par: EQU $01

                ORG $1010
Datos_BCD:      dB $78, $96, $67, $55, $23, $31, $25, $46, $18, $50, $15, $FF

                ORG $1020
Ordenados:

;*******************************************************************************
;                       PROGRAMA PRINCIPAL
;*******************************************************************************

                ORG $2000

                Lds #$4000
                Ldy #Ordenados
                Ldx #Datos_BCD
                Clrb
                Bset Banderas,Par
                
Inicio          Ldaa B,X
                Incb
                Stab Offset

                Cmpa #$FF
                Beq Pares
                Jsr BCDaBIN
                Brset Banderas,Par,Siga
                Bita #$01
                Beq Off
                Cmpa #50
                Bhs Off

Guardar         Staa 1,Y+
                Bra Off
                
Siga            Bita #$01
                Bne Off
                Cmpa #50
                Blo Off
                Bra Guardar
                
Off             Ldab Offset
                Bra Inicio
                
Pares           Brset Banderas,Par,Siga2
                Bra *

Siga2           Bclr Banderas,Par
                Clrb
                Bra Inicio


                
;*******************************************************************************
;                       SUBRUTINA BCDaBIN
;*******************************************************************************

BCDaBIN         Psha
                Anda #$F0
                Lsra
                Tab
                Lsrb
                Lsrb
                Aba
                
                Pulb
                Andb #$0F
                Aba
                Rts
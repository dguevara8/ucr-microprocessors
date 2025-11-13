;*******************************************************************************
;                        PROGRAMA IoT
;*******************************************************************************
;        V1.6.16
;        AUTOR: Danna Guevara Quesada. C23562

; Descripción:   Este programa se encarga de implementar 4 subrutinas
;                en general, se encarga de tomar datos en ASCII de una tabla
;                generada en tiempo de ensamblado, y los convierte a datos
;                binario para separarlos en tres grupos de nibbles, para
;                imprimirlos en tres tablas distintas: Nibble_Up, Nibble_Med
;                y Nibble_Low
;
;*******************************************************************************
;                        DECLARACIÓN DE ESTRUCTURAS DE DATOS
;*******************************************************************************

SP:             EQU $3BFF
NULL:           EQU $00
CR:             EQU $0D
LF:             EQU $0A
PrintF:         EQU $EE88
GetChar:        EQU $EE84
PutChar:        EQU $EE86
Datos_Bin       EQU $1600

                ORG $1000
Cant:           ds 1
Cont:           ds 1
Offset:         ds 1
Acc:            ds 2

                ORG $1010
Nibble_UP:      ds 2
Nibble_MED:     ds 2
Nibble_LOW:     ds 2

                ORG $1030
MSG1    FCC "Ingrese el valor de cant (entre 1 y 50):"
        dB LF, NULL
MSG2    dB CR, LF, CR, LF, CR, LF
        FCC "Cantidad de valores procesados: %u"
        dB CR, LF, CR, LF, CR, LF, NULL
MSG3    FCC "Nibble_UP:"
        dB NULL
MSG4    FCC "Nibble_MED:"
        dB NULL
MSG5    FCC "Nibble_LOW:"
        dB NULL
MSG6    FCC "0%X, "
        dB NULL
MSG7    FCC "0%X "
        dB CR, LF, CR, LF, CR, LF, NULL

                ORG $1500
Datos_IoT       FCC "0129"
                FCC "0729"
                FCC "3954"
                FCC "1875"
                FCC "0075"

                FCC "1536"
                FCC "0534"
                FCC "2755"
                FCC "2021"
                FCC "0389"

                FCC "0000"
                FCC "1329"
                FCC "1783"
                FCC "0009"
                FCC "2804"

                FCC "0064"
                FCC "0128"
                FCC "0256"
                FCC "0512"
                FCC "4095"

;*******************************************************************************
;                       PROGRAMA PRINCIPAL
;*******************************************************************************

                ORG $2000

                Lds #SP
                Jsr GetCant
                Ldx #Datos_IoT
                Ldy #Datos_Bin
                Pshy
                Pshx
                Jsr AsciiBIN
                Ldx #Datos_Bin
                Jsr Mover
                Movw #$1630,Nibble_UP
                Movw #$1660,Nibble_MED
                Movw #$1690,Nibble_LOW
                Jsr Imprimir
                Bra *

;*******************************************************************************
;                       SUBRUTINA GET_CANT
;*******************************************************************************

GetCant         Clr Cant
                Ldd #MSG1
                Ldy #$0
                Jsr [PrintF,y]

Primertecla     Ldy #$0
                Jsr [GetChar,y]
                Cmpb #$30
                Blo Primertecla
                Cmpb #$35
                Bhi Primertecla
                Ldy #$0
                Jsr [PutChar,y]
                Subb #$30
                Ldaa #$0A
                Mul
                Stab Cant

Segundatecla    Ldy #$0
                Jsr [GetChar,y]
                Cmpb #$30
                Blo Segundatecla
                Cmpb #$39
                Bhi Segundatecla
                Ldaa Cant
                Beq Es0
                Cmpa #50
                Beq Es50
                Bra Valor

Es0             Cmpb #$30
                Beq Segundatecla
                Bra Valor

Es50            Cmpb #$30
                Beq Valor
                Bra Segundatecla

Valor           Ldy #$0
                Clra
                Jsr [PutChar,y]
                Subb #$30
                Addb Cant
                Stab Cant
                Rts

;*******************************************************************************
;                       SUBRUTINA ASCII_BIN
;*******************************************************************************

AsciiBIN        Leas 2,SP
                Pulx
                Puly
                Clr Cont
                Clr Offset

Inicio          Ldaa Offset
                Ldab A,X
                Inca
                Staa Offset
                Subb #$30
                Ldaa #$FA
                Mul
                Lsld
                Lsld
                Std Acc

                Ldaa Offset
                Ldab A,X
                Inca
                Staa Offset
                Subb #$30
                Ldaa #$64
                Mul
                Addd Acc
                Std Acc

                Ldaa Offset
                Ldab A,X
                Inca
                Staa Offset
                Subb #$30
                Ldaa #$0A
                Mul
                Addd Acc
                Std Acc

                Ldaa Offset
                Ldab A,X
                Inca
                Staa Offset
                Subb #$30
                Ldaa #$0
                Addd Acc
                Std Acc

                Ldaa Cont
                Movw Acc,A,Y
                Inc Cont
                Inc Cont
                Ldaa Cont
                Lsra
                Cmpa Cant
                Bne Inicio
                Lsr Cont
                Leas -6,SP
                Rts

;*******************************************************************************
;                       SUBRUTINA MOVER
;*******************************************************************************

Mover           Clra
                Clrb

Loop            Ldaa 0,X
                Ldy Nibble_UP
                Staa B,Y

                Ldaa 1,X
                Anda #$F0
                Lsra
        	Lsra
                Lsra
                Lsra
                Ldy Nibble_MED
                Staa B,Y

                Ldaa 1,X
                Anda #$0F
                Ldy Nibble_LOW
                Staa B,Y

                Leax 2,X
                Incb
                Cmpb Cant
                Bne Loop

                Rts

;*******************************************************************************
;                       SUBRUTINA IMPRIMIR
;*******************************************************************************

IMPRIMIR 	Ldx #0
		Ldd #0
                Ldab Cont
                Pshd
                Ldd #MSG2
                Jsr [PrintF,X]
                Puld

                Ldab #0
                Pshb
                Ldaa #0
                Psha

                Ldy Nibble_UP
                Pshy
                Ldx #0
                Ldd #MSG3
                Jsr [PrintF,X]

Lazo            Ldd #0
		Puly
                Ldab 1,Y+
                Pshy
                Pshd
                Ldx #0
                Ldd #MSG6
                Jsr [PrintF,X]
                Puld

                Puly
                Pula
                Inca
                Psha
                Pshy
                Dec Cant
                Cmpa Cant
                Beq Last
                Inc Cant
                Bra Lazo

Last            Inc Cant
		Puly
                Pula
                Ldd #0
                Ldab 1,Y+
                Pshd
                Ldx #0
                Ldd #MSG7
                Jsr [PrintF,X]
                Puld

                Pulb
                Incb
                Pshb
                Ldaa #0
                Psha
                Cmpb #3
                Beq Final
                Cmpb #2
                Beq Valorbajo
                Bra Valormed

Valormed        Ldy Nibble_MED
                Pshy
                Ldx #0
                Ldd #MSG4
                Jsr [PrintF,X]
                Bra Lazo


Valorbajo       Ldy Nibble_LOW
                Pshy
                Ldx #0
                Ldd #MSG5
                Jsr [PrintF,X]
                Bra Lazo

Final           Pula
                Pulb
                Rts



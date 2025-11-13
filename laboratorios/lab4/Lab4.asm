;*******************************************************************************
;                        PROGRAMA INTERRUPCIONES KEY WAKEUPS
;*******************************************************************************
;        V1.0
;        AUTOR: Danna Guevara Quesada. C23562

; Descripción:   Programa de GPIO por polling en la Dragon 12+.
;*******************************************************************************
;                 RELOCALIZACIION DE VECTOR DE INTERRUPCIONES
;*******************************************************************************
#include registers.inc

                ORG $3E70
		ORG $3E4C
                
                dW PTH_ISR
                
                ORG $1000
LEDS:           ds 1
                
CONT_RTI:       ds 1
                
;*******************************************************************************
;                       PROGRAMA PRINCIPAL
;*******************************************************************************

                ORG $2000

                Movb #$FF, DDRB
                Bset DDRJ, $02
                Bclr PTJ, $02

                Movb #$0F, DDRP
                Movb #$0F, PTP
                
                Bset PIEH, $01
                Bset PPSH, $01
                
                Lds #$3BFF
                CLI
                Movb #$01, LEDS
                
                Bra *
                
;*******************************************************************************
;                       SUBRUTINA PTH_ISR
;*******************************************************************************

PTH_ISR         Bset PIFH, $01

                Movb LEDS, PORTB
                
                Ldab LEDS
                Cmpb #$80
                
                Beq Denuevo
                Lsl LEDS
                Bra Retornar
                
Denuevo         Movb #$01, LEDS
                
Retornar        Rti
                
                
                
                
                
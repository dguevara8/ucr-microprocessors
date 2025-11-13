;*******************************************************************************
;                        PROGRAMA INTERRUPCIONES RTI
;*******************************************************************************
;        V1.0
;        AUTOR: Danna Guevara Quesada. C23562

; Descripción:   Programa de GPIO por polling en la Dragon 12+.
;*******************************************************************************
;                 RELOCALIZACIION DE VECTOR DE INTERRUPCIONES
;*******************************************************************************
#include registers.inc

                ORG $3E70
                
                dW RTI_ISR
                
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
                
                Bset CRGINT, $80
                Movb #$17, RTICTL
                
                Lds #$3BFF
                CLI
                Movb #$01, LEDS
                Movb #100, CONT_RTI
                
                Bra *
                
;*******************************************************************************
;                       SUBRUTINA RTI_ISR
;*******************************************************************************

RTI_ISR         Bset CRGFLG, $80
                Dec CONT_RTI
                Bne Retornar
                
                Movb #100, CONT_RTI
                Movb LEDS, PORTB
                Ldab LEDS
                Cmpb #$80
                Beq Denuevo
                Lsl LEDS
                Bra Retornar
                
Denuevo         Movb #$01, LEDS
                
Retornar        Rti
                
                
                
                
                
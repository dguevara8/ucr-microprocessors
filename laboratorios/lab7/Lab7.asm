;*******************************************************************************
;                        PROGRAMA CONTADOR DE TIEMPO
;*******************************************************************************
;        V1.0
;        AUTOR: Danna Guevara Quesada. C23562

; Descripción:   Programa de GPIO por polling en la Dragon 12+.
;*******************************************************************************
;                 RELOCALIZACIION DE VECTOR DE INTERRUPCIONES
;*******************************************************************************
#include registers.inc

                ORG $3E5E

                dW TOI_ISR

                ORG $1000
LEDS:           ds 1

CONT_TOI:       ds 1

;*******************************************************************************
;                       PROGRAMA PRINCIPAL
;*******************************************************************************

                ORG $2000

                Movb #$FF, DDRB
                Bset DDRJ, $02
                Bclr PTJ, $02

                Movb #$0F, DDRP
                Movb #$0F, PTP
                
                Movb #$80, TSCR1
               ;Movb #$90, TSCR1
                Movb #$82, TSCR2

                Lds #$3BFF
                CLI
                Movb #$01, LEDS
                Movb #25, CONT_TOI

                Bra *

;*******************************************************************************
;                       SUBRUTINA TOI_ISR
;*******************************************************************************

TOI_ISR         Bset TFLG2, $80
               ;Ldd TCNT
                Dec CONT_TOI

                Bne Retornar

                Movb #25, CONT_TOI
                Movb LEDS, PORTB

                Ldab LEDS
                Cmpb #$80

                Beq Denuevo
                Lsl LEDS
                Bra Retornar

Denuevo         Movb #$01, LEDS

Retornar        Rti
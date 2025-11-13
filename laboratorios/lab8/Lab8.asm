;*******************************************************************************
;                        PROGRAMA SALIDA POR COMPARACION
;*******************************************************************************
;        V1.0
;        AUTOR: Danna Guevara Quesada. C23562

; Descripción:   Programa de GPIO por polling en la Dragon 12+.
;*******************************************************************************
;                 RELOCALIZACIION DE VECTOR DE INTERRUPCIONES
;*******************************************************************************
#include registers.inc

                ORG $3E64

                dW OC5_ISR

                ORG $1000
LEDS:           ds 1

CONT_OC:        ds 1

;*******************************************************************************
;                       PROGRAMA PRINCIPAL
;*******************************************************************************

                ORG $2000

                Movb #$FF, DDRB
                Bset DDRJ, $02
                Bclr PTJ, $02

                Movb #$0F, DDRP
                Movb #$0F, PTP

                Movb #$90, TSCR1
                Movb #$04, TSCR2
                Movb #$20, TIOS
                Movb #$20, TIE
                
                Ldd TCNT
                Addd #15000
                Std TC5

                Lds #$3BFF
                CLI
                Movb #$01, LEDS
                Movb #25, CONT_OC

                Bra *

;*******************************************************************************
;                       SUBRUTINA TOI_ISR
;*******************************************************************************

OC5_ISR         Dec CONT_OC

                Bne No

                Movb #25, CONT_OC
                Movb LEDS, PORTB

                Ldab LEDS
                Cmpb #$80

                Beq Denuevo
                Lsl LEDS
                Bra No

Denuevo         Movb #$01, LEDS

No              Ldd TCNT
                Addd #15000
                Std TC5

Retornar        Rti
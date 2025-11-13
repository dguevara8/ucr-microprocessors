;*******************************************************************************
;                        PROGRAMA GPIO
;*******************************************************************************
;        V1.0
;        AUTOR: Danna Guevara Quesada. C23562

; Descripción:   Programa de GPIO por polling en la Dragon 12+.
;*******************************************************************************
;                       PROGRAMA PRINCIPAL
;*******************************************************************************
#include registers.inc

                ORG $2000
                
                Movb #$00, DDRH
                Movb #$FF, DDRB
                Bset DDRJ, $02
                Bclr PTJ, $02
                
Loop            Ldaa PTIH
                Staa PORTB
                Bra Loop
                
                
                
                

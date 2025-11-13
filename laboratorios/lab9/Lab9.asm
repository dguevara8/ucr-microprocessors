;*******************************************************************************
;                        PROGRAMA CONVERSIONES MULTIPLEXADAS
;*******************************************************************************
;        V1.0
;        AUTOR: Danna Guevara Quesada. C23562

; Descripción:
;*******************************************************************************
;                 RELOCALIZACIION DE VECTOR DE INTERRUPCIONES
;*******************************************************************************
#include registers.inc

                ORG $FFD2

                dW ATD0_ISR

                ORG $1000
RESULT:         ds 1

;*******************************************************************************
;                       PROGRAMA PRINCIPAL
;*******************************************************************************

                ORG $2000

                Movb #$C2, ATD0CTL2
                Ldaa #160

                Dbne A,Lazo
                
Lazo		Movb #$20, ATD0CTL3
                Movb #$B7, ATD0CTL4
                Movb #$93, ATD0CTL5

                Lds #$4000
                CLI
                
                Bra *

;*******************************************************************************
;                       SUBRUTINA ATD0_ISR
;*******************************************************************************

ATD0_ISR        Ldd ADR00H
                Addd ADR01H
                Addd ADR02H
                Addd ADR03H
                
                Lsrd
                Lsrd
                Stab RESULT
                
                Movb #$93, ATD0CTl5

Retornar        Rti
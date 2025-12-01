
#include registers.inc
;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************
                                org $1000
Puntero        ds 2
EOM            EQU $FF

MSG            FCC " ESCUELA DE ING. ELECTRICA "
               dB EOM

                	ORG $3E54
                        dw  SCI_ISR

;*******************************************************************************
;                     Configuracion del Hardware
;*******************************************************************************
                              ORG $2000
                              
                Movw #39,SC1BDH
                Clr SC1CR1
                Movb #$88,SC1CR2

                Ldaa SC1SR1
                Clr SC1DRL

;*******************************************************************************
;                      Programa Principal
;*******************************************************************************

                Lds #$3BFF  ; Inicializar la pila
                Cli         ; Habilitar las interrupciones mascarables
                Movw #MSG,Puntero

                Ldaa SC1SR1
                Movb #$0C,SC1DRL

                Bra *
                       
;*******************************************************************************
;                     INTERRUPCION SCI
;*******************************************************************************

SCI_ISR
                Ldaa SC1SR1
                Ldx Puntero
                Ldaa 1,X+

                Cmpa #EOM
                Beq SIGUE
                Staa SC1DRL
                Stx Puntero
                Bra FIN
                
SIGUE           Bclr SC1CR2,$08

FIN             Rti
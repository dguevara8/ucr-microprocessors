;*******************************************************************************
;                             Laboratorio SPI
;*******************************************************************************
#include registers.inc

			ORG $3E70
                        dw  RTI_ISR

                        ORG $3E52
                        dw  ATD0_ISR
;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************
                                org $1000
CONT_DA        ds 2
LEDS           ds 1
Comparador     ds 1

;*******************************************************************************
;                     Configuracion del Hardware
;*******************************************************************************
                              ORG $2000

                Movb #$49,RTICTL
                Movb #$80,CRGINT
                
                Movb #$FF,DDRB
                Clr PORTB
                Bset DDRJ,$02
                Bclr PTJ,$02
                Movb #$0F,DDRP
                Movb #$0F,PTP

                Movb #$C2,ATD0CTL2
                Ldaa #160

Lazo            Dbne A,Lazo

                Movb #$08,ATD0CTL3
                Movb #$97,ATD0CTL4
                
                Movb #$50,SPI0CR1
                Clr SPI0CR2
                Movb #$45,SPI0BR
                
                Bset DDRM,$40
                Bset PTM,$40

;*******************************************************************************
;                      Programa Principal
;*******************************************************************************

                Lds #$3BFF  ; Inicializar la pila
                Cli         ; Habilitar las interrupciones mascarables
                Movb #32,Comparador
                Movb #$01,LEDS
                Movw #$00,CONT_DA

                Bra *
                       
;*******************************************************************************
;                     INTERRUPCION RTI
;*******************************************************************************

RTI_ISR         Ldx CONT_DA
                Inx
                Stx CONT_DA
                Cpx #1024
                Bne LOOP

                Movw #$00,CONT_DA
LOOP            Bclr PTM,$40
                
ESPERE          Brclr SPI0SR,$20,ESPERE

                Ldd CONT_DA
                Lsld
                Lsld
                
                Anda #$0F
                Adda #$90
                Staa SPI0DR
                
ESPERE2         Brclr SPI0SR,$20,ESPERE2
                
                Stab SPI0DR

ESPERE3         Brclr SPI0SR,$20,ESPERE3
                
                Bset PTM,$40
                Bset CRGFLG,$80
                Movb #$86,ATD0CTL5

FIN             Rti

;*******************************************************************************
;                       SUBRUTINA ATD0_ISR
;*******************************************************************************

ATD0_ISR
                Ldd ADR00H
                Cmpb #31
                Blo SIGUE2
                Cmpb Comparador
                Blo FIN2
                Movb LEDS,PORTB
                Ldaa Comparador
                Adda #31
                Staa Comparador
                Ldaa LEDS
                Lsla
                Oraa LEDS
                Staa LEDS
                Bra FIN2
                
SIGUE2          Clr PORTB
                Movb #31,Comparador
                Movb #$01,LEDS

FIN2            Rti
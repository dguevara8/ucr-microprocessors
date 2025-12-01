;*******************************************************************************
;                                  EXAMEN 2
;*******************************************************************************
; Autora: Danna Guevara Quesada
; Carne: C23562
; Descripcion: Este programa se comprueba su funcionamiento por medio de que el
; LED PB0 conmute lento y que el LED PB7 tenga un apagado corto y encendido
; rapido, cuando se presione PH0, el LED PB0 conmutara rapido y que el LED PB7
; tenga un apagado largo y encendido corto.

#include registers.inc
;*******************************************************************************
;                 RELOCALIZACION DE VECTORES DE INTERRUPCION
;*******************************************************************************

                ; Vector de RTI
                    	ORG $3E70
                dW RTI_ISR
                ; Vector de OC7
                	ORG $3E60
                dW ECT_ISR
                ; Vector de Port H.0
			ORG $3E4C
                dW PORTH_ISR
                
;*******************************************************************************
;                      DECLARACION DE LAS ESTRUCTURAS DE DATOS
;*******************************************************************************

WFLG1             EQU $01       ; Variable tipo bit
WFLG2             EQU $02       ; Variable tipo bit

tCONT_7           EQU 12        ; 12 para el contador RTI
tCONT_2           EQU 42        ; 42 para el contador RTI

tTC7H             EQU 56250     ; Periodo alto
tTC7L             EQU 7812      ; Periodo bajo

                        ORG $1000
BANDERAS          dS 1


CONT_RTI          dS 1

;===============================================================================
;                            PROGRAMA ONDAS
;===============================================================================
                                      org $2000

		Bclr CLKSEL,$80

          	; Configurar Puerto H
		Bset PIEH,$01
		Bclr PPSH,$01
          	;Habilitar LED
		Movb #$FF,DDRB    ; Poner el puerto del LED como salida
          	Clr PORTB
          	Bset DDRJ,$02     ; Habilitar LED
         	Bclr PTJ,$02
          	;Apagar Displays  de 7 Segmentos
          	Movb #$0F,DDRP
          	Movb #$0F,PTP
          
          	;Configurar MODULO
          	Movb #$80,TIOS
          	Movb #$90,TSCR1
          	Movb #$0F,TSCR2
          	Movb #$80,TIE
          	Movw #tTC7L,TC7

          	; Habilitar RTI
          	Movb #$80,CRGINT
          	Movb #$63,RTICTL

          	Lds #$3BFF               ; Definir pila
          	Cli                      ; Habilitar interrupciones
          	Bclr BANDERAS,WFLG1
          	Bclr BANDERAS,WFLG2
          	Movb #tCONT_7,CONT_RTI
          
          	Bra *
          
;*******************************************************************************
;             SUBRUTINA DE ATENCION A PUERTO H KEY WAKE UP
;*******************************************************************************

PORTH_ISR     	; Suprimir Rebotes
		Ldd #13000
              
Sup_rebotes
		Dbne D,Sup_rebotes

		Ldaa BANDERAS       ; Toggle a WFLG1
		Eora #WFLG1
		Staa BANDERAS

Fin_PORTH_ISR
		Bset PIFH,$01       ; Borrar Bandera
		Rti

;*******************************************************************************
;                   SUBRUTINA DE ATENCION A ECT
;*******************************************************************************

ECT_ISR
         	Bset TFLG1,$80      ; Borrar Bandera
         
         	Brclr BANDERAS,WFLG2, SI
         	Bclr PORTB,$80      ; Apaga el LED 8 y desactiva WFLG2
         	Bclr BANDERAS,WFLG2
         	Brclr BANDERAS,WFLG1, SI3
         	Movw #tTC7H,TC7
         	Bra FIN_ECT_ISR
         
SI3      	Movw #tTC7L,TC7
         	Bra FIN_ECT_ISR
         
SI       	Bset PORTB,$80      ; Enciende el LED 8 y activa WFLG2
         	Bset BANDERAS,WFLG2
         	Brset BANDERAS,WFLG1, SI2
         	Movw #tTC7H,TC7
         	Bra FIN_ECT_ISR
         
SI2      	Movw #tTC7L,TC7
         	Bra FIN_ECT_ISR

FIN_ECT_ISR
         	Rti
         
;*******************************************************************************
;                    SUBRUTINA DE ATENCION A RTI
;*******************************************************************************

RTI_ISR
        	Dec CONT_RTI     ; Decrementa cont
        	Bne FIN_RTI_ISR
        
        	Brclr BANDERAS,WFLG1, SI4
        	Movb #tCONT_7,CONT_RTI
        	Bra TOGGLE
        
SI4     	Movb #tCONT_2,CONT_RTI

TOGGLE  	Ldaa PORTB       ; Toggle al Led
        	Eora #$01
        	Staa PORTB

FIN_RTI_ISR
        	Bset CRGFLG,$80 ; Borrar Bandera
        	Rti
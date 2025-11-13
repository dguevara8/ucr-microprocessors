 ;******************************************************************************
 ;                              MAQUINA DE TIEMPOS
 ;                                     (RTI)
 ;******************************************************************************
#include registers.inc
 ;******************************************************************************
 ;                 RELOCALIZACION DE VECTOR DE INTERRUPCION
 ;******************************************************************************
                                Org $3E70
                                dw Maquina_Tiempos
;******************************************************************************
;                       DECLARACION DE LAS ESTRUCTURAS DE DATOS
;******************************************************************************

;--- Aqui se colocan los valores de carga para los timers baseT  ----

tTimer1mS:        EQU 2     ;Base de tiempo de 1 mS (0.5 ms x 2)
tTimer10mS:       EQU 20    ;Base de tiempo de 10 mS (0.5 mS x 20)
tTimer100mS:      EQU 200    ;Base de tiempo de 100 mS (0.5 mS x 200)
tTimer1S:         EQU 2000    ;Base de tiempo de 1 segundo (0.5 mS x 2000)

;--- Aqui se colocan los valores de carga para los timers de la aplicacion  ----


tTimerLDTst       EQU 1     ;Tiempo de parpadeo de LED testigo en segundos


                                Org $1000

;Aqui se colocan las estructuras de datos de la aplicacion

;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1040
Tabla_Timers_BaseT:

Timer1mS        ds 2       ;Timer 1 ms con base a tiempo de interrupcion
Timer10mS:      ds 2       ;Timer para generar la base de tiempo 10 mS
Timer100mS:     ds 2       ;Timer para generar la base de tiempo de 100 mS
Timer1S:        ds 2       ;Timer para generar la base de tiempo de 1 Seg.

Fin_BaseT       dW $FFFF

Tabla_Timers_Base1mS

Timer1_Base1:   ds 1       ;Ejemplos de timers de aplicacion con BaseT
Timer2_Base1:   ds 1

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Timer1_Base10:  ds 1       ;Ejemplos de timers de aplicacion con base 10 mS
Timer2_Base10:  ds 1

Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS

Timer1_Base100  ds 1       ;Ejemplos de timers de aplicacpon con base 100 mS
Timer2_Base100  ds 1

Fin_Base100mS   dB $FF

Tabla_Timers_Base1S

Timer_LED_Testigo ds 1   ;Timer para parpadeo de led testigo
Timer1_Base1S:    ds 1   ;Ejemplos de timers de aplicacion con base 1 seg.
Timer2_Base1S:    ds 1

Fin_Base1S        dB $FF

;===============================================================================
;                              CONFIGURACION DE HARDWARE
;===============================================================================
                              Org $2000

        Bset DDRB,$80     ;Habilitacion del LED Testigo
        Bset DDRJ,$02     ;como comprobacion del timer de 1 segundo
        BClr PTJ,$02      ;haciendo toogle

        Movb #$0F,DDRP    ;bloquea los display de 7 Segmentos
        Movb #$0F,PTP

        Movb #$13,RTICTL   ;Se configura RTI con un periodo de 0.5 mS
        Bset CRGINT,$80
;===============================================================================
;                           PROGRAMA PRINCIPAL
;===============================================================================
        Movw #tTimer1mS,Timer1mS
        Movw #tTimer10mS,Timer10mS         ;Inicia los timers de bases de tiempo
        Movw #tTimer100mS,Timer100mS
        Movw #tTimer1S,Timer1S

        Movb #tTimerLDTst,Timer_LED_Testigo  ;inicia timer parpadeo led testigo
        Lds #$3BFF
        Cli
Despachador_Tareas
        Jsr Decre_TablaTimers
        Jsr Tarea_Led_Testigo
       ; Aqui se colocan todas las tareas del programa de aplicacion
        Bra Despachador_Tareas

;******************************************************************************
;                               TAREA LED TESTIGO
;******************************************************************************

Tarea_Led_Testigo
                Tst Timer_LED_Testigo
                Bne FinLedTest
                Movb #tTimerLDTst,Timer_LED_Testigo
                Ldaa PORTB
                Eora #$80
                Staa PORTB
FinLedTest
      Rts

;******************************************************************************
;                       SUBRUTINA DECRE_TABLATIMERS
;******************************************************************************

Decre_TablaTimers
                Ldd Timer1mS
                Bne Loop
                Movw #tTimer1mS,Timer1mS
                Ldx #Tabla_Timers_Base1mS
                Jsr Decre_Timers
Loop            Ldd Timer10mS
                Bne Loop2
                Movw #tTimer10mS,Timer10mS
                Ldx #Tabla_Timers_Base10mS
                Jsr Decre_Timers
Loop2           Ldd Timer100mS
                Bne Loop3
                Movw #tTimer100mS,Timer100mS
                Ldx #Tabla_Timers_Base100mS
                Jsr Decre_Timers
Loop3           Ldd Timer1S
                Bne Retornar
                Movw #tTimer1S,Timer1S
                Ldx #Tabla_Timers_Base1S
                Jsr Decre_Timers
                Bra Retornar
                
Retornar        Rts

;******************************************************************************
;                       SUBRUTINA DECRE_TIMERS
;******************************************************************************

Decre_Timers:
                tst 0,X
                Beq Incremento
                Ldaa 0,X
                Cmpa #$FF
                Beq Retorno
                Dec 0,X
                
Incremento      Inx
                Bra Decre_Timers

Retorno         Rts

;******************************************************************************
;                       SUBRUTINA DE ATENCION A RTI
;******************************************************************************

Maquina_Tiempos:
               Ldx #Tabla_Timers_BaseT
               Jsr Decre_Timers_BaseT
               Bset CRGFLG, $80
               RTI
               
;******************************************************************************
;                       SUBRUTINA DECRE_TIMERS_BASET
;******************************************************************************

Decre_Timers_BaseT:
               Ldy 2,X+
               Cpy #0
               Beq Decre_Timers_BaseT
               Cpy #$FFFF
               Bne Siga
               Bra Retorne
               
Siga           Dey
               Sty -2,X
               Bra Decre_Timers_BaseT
               
Retorne        RTS
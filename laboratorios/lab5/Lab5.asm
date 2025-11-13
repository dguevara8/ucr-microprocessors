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

tSupRebPB         EQU 10
tShortP           EQU 25
tLongP            EQU 3
tTimerLDTst       EQU 1     ;Tiempo de parpadeo de LED testigo en segundos

PortPB            EQU PTIH
MaskPB            EQU $01

                                Org $1000

;Aqui se colocan las estructuras de datos de la aplicacion
Est_Pres_LeerPB   ds 2
Banderas_PB       ds 1

ShortP            EQU $01
LongP             EQU $02

;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1010
Tabla_Timers_BaseT:

Timer1mS        ds 2       ;Timer 1 ms con base a tiempo de interrupcion
Timer10mS:      ds 2       ;Timer para generar la base de tiempo 10 mS
Timer100mS:     ds 2       ;Timer para generar la base de tiempo de 100 mS
Timer1S:        ds 2       ;Timer para generar la base de tiempo de 1 Seg.

Fin_BaseT       dW $FFFF

Tabla_Timers_Base1mS

Timer_RebPB     ds 1

Timer1_Base1:   ds 1       ;Ejemplos de timers de aplicacion con BaseT
Timer2_Base1:   ds 1

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Timer_SHP       ds 1

Timer1_Base10:  ds 1       ;Ejemplos de timers de aplicacion con base 10 mS
Timer2_Base10:  ds 1

Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS

Timer1_100mS    ds 1
Timer1_Base100  ds 1       ;Ejemplos de timers de aplicacpon con base 100 mS
Timer2_Base100  ds 1

Fin_Base100mS   dB $FF

Tabla_Timers_Base1S

Timer_LP          ds 1
Timer_LED_Testigo ds 1   ;Timer para parpadeo de led testigo
Timer1_Base1S:    ds 1   ;Ejemplos de timers de aplicacion con base 1 seg.
Timer2_Base1S:    ds 1

Fin_Base1S        dB $FF

;===============================================================================
;                              CONFIGURACION DE HARDWARE
;===============================================================================
                              Org $2000

        Bset DDRB,$81     ;Habilitacion del LED Testigo
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
        Movb #0, Timer_LP
        
        Lds #$3BFF
        Cli
        Clr Banderas_PB
        Movw #LeerPB_Est1,Est_Pres_LeerPB
;===============================================================================
;                           DESPACHADOR DE TAREAS
;===============================================================================
Despachador_Tareas

        Jsr Tarea_Led_Testigo
        Jsr Tarea_Led_PB
        Jsr Tarea_LeerPB
        Jsr Decre_TablaTimers
        Bra Despachador_Tareas

;******************************************************************************
;                               TAREA LED_PB
;******************************************************************************

Tarea_LED_PB
                Brset Banderas_PB,ShortP,ON
                Brset Banderas_PB,LongP,OFF
                Bra FIN_Led
ON              Bclr Banderas_PB,ShortP
                Bset PORTB,$01
                Bra FIN_Led
OFF             Bclr Banderas_PB,LongP
                Bclr PORTB,$01

FIN_Led                Rts

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
FinLedTest        Rts

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
                Tst 0,X
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

;******************************************************************************
;                       TAREA LEER PB
;******************************************************************************

Tarea_LeerPB
              Ldx Est_Pres_LeerPB
              Jsr 0,X
              
FinTareaPB    Rts
;======================= LEER PB ESTADO 1 ======================================

LeerPB_Est1
              Brclr PortPB,MaskPB,Continue
              Bra FinEst1
              
Continue      Movb #tSupRebPB,Timer_RebPB
              Movb #tShortP,Timer_SHP
              Movb #tLongP,Timer_LP
              
              Movw #LeerPB_Est2,Est_Pres_LeerPB
              
FinEst1       Rts

;======================= LEER PB ESTADO 2 ======================================

LeerPB_Est2
              Tst Timer_RebPB
              Bne FinEst2

              Brclr PortPB,MaskPB,Continue2
              Movw #LeerPB_Est1,Est_Pres_LeerPB
              Bra FinEst2
              
Continue2     Movw #LeerPB_Est3,Est_Pres_LeerPB
              
FinEst2       Rts

;======================= LEER PB ESTADO 3 ======================================

LeerPB_Est3
              Tst Timer_SHP
              Bne FinEst3
              
              Brclr PortPB,MaskPB,Continue3
              Bset Banderas_PB,ShortP
              Movw #LeerPB_Est1,Est_Pres_LeerPB
              Bra FinEst3
              
Continue3     Movw #LeerPB_Est4,Est_Pres_LeerPB

FinEst3       Rts

;======================= LEER PB ESTADO 4 ======================================

LeerPB_Est4
              Tst Timer_LP
              Beq Continue5
              Brclr PortPB,MaskPB,FinEst4
              Bset Banderas_PB,ShortP
              Bra LOL

Continue5     Brclr PortPB,MaskPB,FinEst4
              Bset Banderas_PB,LongP
LOL           Movw #LeerPB_Est1,Est_Pres_LeerPB

FinEst4       Rts

;******************************************************************************
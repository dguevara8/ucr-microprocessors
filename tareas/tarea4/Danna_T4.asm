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
tTimerLDTst       EQU 1
tSupRebTCL        EQU 20

PortPB            EQU PTIH
MaskPB            EQU $01

                                Org $1000

MAX_TCL           dB $04
Tecla             ds 1
Tecla_In          ds 1
Cont_TCL          ds 1
Patron            ds 1
Funcion           ds 1

Est_Pres_TCL      ds 2

                                Org $1010

Num_Array         ds 1

                                Org $100C
Banderas          ds 1

                                Org $100D
Est_Pres_LeerPB   ds 2

                                Org $1020

Teclas            dB $01
                  dB $02
                  dB $03
                  dB $04
                  dB $05
                  dB $06
                  dB $07
                  dB $08
                  dB $09
                  dB $0B
                  dB $00
                  dB $0E

ShortP            EQU $01
LongP             EQU $02
ArrayOK           EQU $04

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

Timer_RebPB     ds 1
Timer_RebTCL:   ds 1

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Timer_SHP       ds 1

Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS

Timer1_100mS    ds 1

Fin_Base100mS   dB $FF

Tabla_Timers_Base1S

Timer_LP          ds 1
Timer_LED_Testigo ds 1   ;Timer para parpadeo de led testigo

Fin_Base1S        dB $FF

;===============================================================================
;                              CONFIGURACION DE HARDWARE
;===============================================================================
                              Org $2000

        Bset DDRB,$CF     ;Habilitacion del LED Testigo
        Bset DDRJ,$02     ;como comprobacion del timer de 1 segundo
        BClr PTJ,$02      ;haciendo toogle

        Movb #$0F,DDRP    ;bloquea los display de 7 Segmentos
        Movb #$0F,PTP

        Movb #$13,RTICTL   ;Se configura RTI con un periodo de 0.5 mS
        Bset CRGINT,$80

        Movb #$F0,DDRA
        Bset PUCR,$01
;===============================================================================
;                           PROGRAMA PRINCIPAL
;===============================================================================
        Movw #tTimer1mS,Timer1mS
        Movw #tTimer10mS,Timer10mS         ;Inicia los timers de bases de tiempo
        Movw #tTimer100mS,Timer100mS
        Movw #tTimer1S,Timer1S
        Movw #tSupRebTCL,Timer_RebTCL

        Movb #$FF,Tecla    ; Borrar los contenidos en Tecla y Tecla_IN
        Movb #$FF,Tecla_In
        Movb #$FF,Funcion
        Clr Cont_TCL
        Clr Banderas

        Movb #tTimerLDTst,Timer_LED_Testigo  ;inicia timer parpadeo led testigo
        Movb #0, Timer_LP

        Lds #$3BFF
        Cli

        Movw #LeerPB_Est1,Est_Pres_LeerPB
        Movw #Teclado_Est1,Est_Pres_TCL
;===============================================================================
;                           DESPACHADOR DE TAREAS
;===============================================================================
Despachador_Tareas

        Jsr Decre_TablaTimers
        Jsr Tarea_Led_Testigo
        Jsr Tarea_LeerPB
        Jsr Tarea_Teclado
        Jsr Tarea_Leds
        Bra Despachador_Tareas

;******************************************************************************
;                               TAREA LED_PB
;******************************************************************************

Tarea_Leds
            Brset Banderas,ShortP,ON
            Brset Banderas,LongP,OFF
            Bra Check_Funcion

ON
            Bclr Banderas,ShortP
            Bset PORTB,$40
            Bra Check_Funcion

OFF
            Bclr Banderas,LongP
            Bclr PORTB,$40
            Bclr Banderas,ArrayOK
            Jsr Borrar_Num_Array

Check_Funcion
            Bclr PORTB,$0F
            Ldaa Funcion

            Brset Funcion,$10,No_F1
            Bset PORTB,$01

No_F1
            Brset Funcion,$20,No_F2
            Bset PORTB,$02

No_F2
            Brset Funcion,$40,No_F3
            Bset PORTB,$04

No_F3
            Brset Funcion,$80,No_F4
            Bset PORTB,$08

No_F4

FIN_Led
            Rts
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
              Bset Banderas,ShortP
              Movw #LeerPB_Est1,Est_Pres_LeerPB
              Bra FinEst3

Continue3     Movw #LeerPB_Est4,Est_Pres_LeerPB

FinEst3       Rts

;======================= LEER PB ESTADO 4 ======================================

LeerPB_Est4
              Tst Timer_LP
              Beq Continue5
              Brclr PortPB,MaskPB,FinEst4
              Bset Banderas,ShortP
              Bra LOL

Continue5     Brclr PortPB,MaskPB,FinEst4
              Bset Banderas,LongP
LOL           Movw #LeerPB_Est1,Est_Pres_LeerPB

FinEst4       Rts

;*******************************************************************************
;                            TAREA LEER TECLADO
;*******************************************************************************

Tarea_LeerTeclado
              Movb #$EF,Patron
              Ldx #Teclas
              Ldab Tecla
              Clra

InicioT       Movb Patron,PORTA
              Brclr PORTA,$01,Cargar
              Inca
              Brclr PORTA,$02,Cargar
              Inca
              Brclr PORTA,$04,Cargar
              Inca
              Brclr PORTA,$08,Cargar2
              Cmpa #12
              Beq Cargar3
              Rol Patron
              Bra InicioT

Cargar        Movb A,X,Tecla
              Bra FinLeerTeclado

Cargar2       Movb Patron,Tecla
              Bra FinLeerTeclado

Cargar3       Movb #$FF,Tecla

FinLeerTeclado
              Rts

;*******************************************************************************
;                       Subrutina Borrar_Num_Array
;*******************************************************************************

Borrar_Num_Array
              Ldy #Num_Array
              Ldaa #0

BorrandoNumArray
              Cmpa MAX_TCL                    ;Se verifica si ya se recorrió todo el arreglo
              Beq FIN_Borrar_Num_Array        ;Si ya se recorrió todo retorna

              Movb #$FF,1,Y+                  ;sino, se borra la posición actual de Num_Array poniendo un $FF
              Inca
              Bra BorrandoNumArray

FIN_Borrar_Num_Array
              Rts

;*******************************************************************************
;                              TAREA TECLADO
;*******************************************************************************

Tarea_Teclado
              Ldx Est_Pres_TCL
              Jsr 0,X

FinTeclado    Rts

;============================ TECLADO ESTADO 1 =================================

Teclado_Est1
              Jsr Tarea_LeerTeclado
              Ldaa Tecla
              Cmpa #$FF
              Beq FinTecladoEst1

TeclaPresionada
              Movb Tecla,Tecla_In
              Movb #tSupRebTCL,Timer_RebTCL
              Movw #Teclado_Est2,Est_Pres_TCL

FinTecladoEst1
              Rts

;============================ TECLADO ESTADO 2 =================================

Teclado_Est2
              Tst Timer_RebTCL
              Bne FinTecladoEst2

              Jsr Tarea_LeerTeclado
              Ldaa Tecla

              Cmpa Tecla_In
              Beq MantieneTeclaPres
              Movw #Teclado_Est1,Est_Pres_TCL
              Bra FinTecladoEst2

MantieneTeclaPres
              Movw #Teclado_Est3,Est_Pres_TCL

FinTecladoEst2
              Rts

;============================ TECLADO ESTADO 3 =================================

Teclado_Est3
              Jsr Tarea_LeerTeclado
              Ldaa Tecla
              Cmpa #$FF
              Bne FinTecladoEst3
              Ldaa Tecla_In
              Cmpa #15
              Bhi TeclaMayor
              Movw #Teclado_Est4,Est_Pres_TCL
              Bra FinTecladoEst3

TeclaMayor
              Movb Tecla_In,Funcion
              Movw #Teclado_Est1,Est_Pres_TCL

FinTecladoEst3
              Rts

;============================ TECLADO ESTADO 4 =================================

Teclado_Est4    Ldaa Cont_TCL
                Ldab Tecla_In
                Ldx #Num_Array
                Cmpa Max_TCL
                Beq FullArray
                Tsta
                Beq Primertecla
                Cmpb #$0B
                Beq Borrar
                Cmpb #$0E
                Beq Enter
                Bra Noenter

Primertecla     Cmpb #$0B
                Beq FinTecladoEst4
                Cmpb #$0E
                Beq FinTecladoEst4

Noenter         Stab A,X
                Inc Cont_TCL
                Bra FinTecladoEst4

FullArray       Cmpb #$0B
                Beq Borrar
                Cmpb #$0E
                Beq Enter
                Bra FinTecladoEst4

Borrar          Dec Cont_TCL
                Ldaa Cont_TCL
                Movb #$FF,A,X
                Bra FinTecladoEst4

Enter           Clr Cont_TCL
                Bset Banderas,ArrayOK

FinTecladoEst4
                Movb #$FF,Tecla_In
                Movw #Teclado_Est1,Est_Pres_TCL
                Rts

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
FinLedTest      Rts

;*******************************************************************************
;                       SUBRUTINA DECRE_TABLATIMERS
;*******************************************************************************

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

;*******************************************************************************
;                       SUBRUTINA DECRE_TIMERS
;*******************************************************************************

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

;*******************************************************************************
;                       SUBRUTINA DE ATENCION A RTI
;*******************************************************************************

Maquina_Tiempos:
               Ldx #Tabla_Timers_BaseT
               Jsr Decre_Timers_BaseT
               Bset CRGFLG, $80
               RTI

;*******************************************************************************
;                       SUBRUTINA DECRE_TIMERS_BASET
;*******************************************************************************

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
*******************************************************************************
 ;                             Manejo de Pantallas
 ; Autor: Danna Guevara Quesada
 ; Descripcion: Implementa el manejo de los displays y la pantalla LCD de la
 ; Dragon 12, se muestra un mensaje de inicio en el LCD y al presinar PH.3 se
 ; cambia el mensaje y el contador empieza a descontar.
;*******************************************************************************
#include registers.inc

;******************************************************************************
;                 RELOCALIZACION DE VECTOR DE INTERRUPCION
;******************************************************************************
                                Org $3E4A
                                dw Maquina_Tiempos
;******************************************************************************
;                       DECLARACION DE LAS ESTRUCTURAS DE DATOS
;******************************************************************************

;--- Aqui se colocan los valores de carga para los timers baseT  ----
tTimer1mS:        EQU 50
tTimer10mS:       EQU 500
tTimer100mS:      EQU 5000
tTimer1S:         EQU 50000

tSupRebTCL        EQU 20

tTimerDigito      EQU 2
MaxCountTicks     EQU 100
DIG1              EQU $01
DIG2              EQU $02
DIG3              EQU $04
DIG4              EQU $08

tTimer2mS         EQU 2
tTimer260uS:      EQU 13
tTimer40uS:       EQU 2
EOB               EQU $FF
Clear_LCD         EQU $01
ADD_L1            EQU $80
ADD_L2            EQU $C0

tSupRebPB0        EQU 10
tShortP0          EQU 25
tLongP0           EQU 3
tSupRebPB1        EQU 10
tShortP1          EQU 25
tLongP1           EQU 3

tMinutosTCM       EQU 1
tSegundosTCM      EQU 15

tTimerLDTst       EQU 5

Recarga_TC        EQU 30
InicioLD          EQU $AA
TemporalLD        EQU $55

;--- Aqui se colocan los valores de carga para los timers de la aplicacion  ----

PortPB            EQU PTIH
MaskPB0           EQU $01
MaskPB1           EQU $08

ShortP0           EQU $01
LongP0            EQU $02
ShortP1           EQU $04
LongP1            EQU $08
ArrayOK           EQU $10
RS                EQU $01
LCD_OK            EQU $02
FinSendLCD        EQU $04
Second_Line       EQU $08

                                Org $1000

MAX_TCL           ds 1
Tecla             ds 1
Tecla_In          ds 1
Cont_TCL          ds 1
Patron            ds 1
Funcion           ds 1
Est_Pres_TCL      ds 2

                                Org $1010
Num_Array         ds 1

                                Org $100D
Est_Pres_LeerPB0  ds 2

                                Org $1020
EstPres_PantallaMUX ds 2
Dsp1              ds 1
Dsp2              ds 1
Dsp3              ds 1
Dsp4              ds 1
LEDS              ds 1
Cont_Dig          ds 1
Brillo            ds 1
BIN1              ds 1
BIN2              ds 1
BCD               ds 1
Cont_BCD          ds 1
BCD1              ds 1
BCD2              ds 1

IniDsp            dB $28,$06,$0C,$FF
Punt_LCD          ds 2
CharLCD           ds 1
Msg_L1            ds 2
Msg_L2            ds 2
EstPres_SendLCD   ds 2
EstPres_TareaLCD  ds 2

Est_Pres_LeerPB1  ds 2

Est_Pres_TCM      ds 2
MinutosTCM        ds 1

                                Org $1070
Banderas_1        ds 1
Banderas_2        ds 1

                                Org $1080
Est_Pres_LDTst    ds 2

                                Org $1100
Segment           dB $3F        ;'0' en 7 segmentos
                  dB $06        ;'1' en 7 segmentos
                  dB $5B        ;'2' en 7 segmentos
                  dB $4F        ;'3' en 7 segmentos
                  dB $66        ;'4' en 7 segmentos
                  dB $6D        ;'5' en 7 segmentos
                  dB $7D        ;'6' en 7 segmentos
                  dB $07        ;'7' en 7 segmentos
                  dB $7F        ;'8' en 7 segmentos
                  dB $6F        ;'9' en 7 segmentos

                                Org $1110
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

                                  Org $1200
MSG1:             FCC "   ESCUELA DE   "
                  dB EOB
MSG2:             FCC " ING. ELECTRICA "
                  dB EOB
MSG3:             FCC " uPROCESADORES "
                  dB EOB
MSG4:             FCC "    TAREA #5   "
                  dB EOB

;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1500
Tabla_Timers_BaseT:

Counter_Ticks:  ds 2
Timer260uS:     ds 2
Timer40uS:      ds 2
Timer1mS        ds 2       ;Timer 1 ms con base a tiempo de interrupcion
Timer10mS:      ds 2       ;Timer para generar la base de tiempo 10 mS
Timer100mS:     ds 2       ;Timer para generar la base de tiempo de 100 mS
Timer1S:        ds 2       ;Timer para generar la base de tiempo de 1 Seg.

Fin_BaseT       dW $FFFF

Tabla_Timers_Base1mS

TimerDigito:    ds 1
Timer2mS:       ds 1
Timer_RebPB0:   ds 1
Timer_RebPB1:   ds 1
Timer_RebTCL:   ds 1

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Timer_SHP0:     ds 1
Timer_SHP1:     ds 1

Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS

Timer1_100mS:    ds 1
Timer_LED_Testigo: ds 1   ;Timer para parpadeo de led testigo

Fin_Base100mS   dB $FF

Tabla_Timers_Base1S

Timer_LP0:       ds 1
Timer_LP1:       ds 1
SegundosTCM:     ds 1

Fin_Base1S      dB $FF

;===============================================================================
;                              CONFIGURACION DE HARDWARE
;===============================================================================
                              Org $2000

        ; Leds
        Movb #$FF,DDRB
        Bset DDRJ,$02
        Bclr PTJ,$02

        ; Display 7 segmentos
        Movb #$7F,DDRP    ;bloquea los display de 7 Segmentos
        Movb #$0F,PTP
        
        ; Pantalla LCD
        Movb #$FF,DDRK

        ; Count Down
        Bset MCCTL,$C7
        Movw #Recarga_TC,MCCNT

        ; Teclado
        Movb #$F0,DDRA
        Bset PUCR,$01
;===============================================================================
;                           PROGRAMA PRINCIPAL
;===============================================================================
        Movw #tTimer1mS,Timer1mS
        Movw #tTimer10mS,Timer10mS      ;Inicia los timers de bases de tiempo
        Movw #tTimer100mS,Timer100mS
        Movw #tTimer1S,Timer1S

        Movb #$FF,Tecla                 ; Borra los contenidos en Tecla y Tecla_IN
        Movb #$FF,Tecla_In
        Movb #$FF,Funcion
        Clr Cont_TCL
        Clr Banderas_1
        Movb #$05,MAX_TCL

        Movb #1,Cont_Dig
        Movb #90,Brillo
        Movb #InicioLD,LEDS
        Movb #tTimerDigito,TimerDigito
        Movb #tMinutosTCM,BIN2
        Movb #tSegundosTCM,BIN1

        Movb #tTimerLDTst,Timer_LED_Testigo ;Inicia timer parpadeo led testigo

        Movw #MSG1,Msg_L1
        Movw #MSG2,Msg_L2

        Lds #$3BFF
        Cli

        Movw #LeerPB0_Est1,Est_Pres_LeerPB0
        Movw #LeerPB1_Est1,Est_Pres_LeerPB1
        Movw #Teclado_Est1,Est_Pres_TCL
        Movw #Led_Testigo_Est1,Est_Pres_LDTst
        Movw #SendLCD_Est1,EstPres_SendLCD
        Movw #TareaLCD_Est1,EstPres_TareaLCD
        Movw #PantallaMUX_Est1,EstPres_PantallaMUX
        Movw #Tarea_TCM_Est1,Est_Pres_TCM
        
;===============================================================================
;                      Inicializacion de la pantalla LCD
;===============================================================================

        Clr Banderas_2
        Movw #IniDsp,Punt_LCD

Cargardato
        Ldx Punt_LCD
        Movb 1,X+,CharLCD
        Stx Punt_LCD
        Ldaa CharLCD
        Cmpa #EOB
        Beq Clear

Mandardato
	Jsr Decre_TablaTimers
        Jsr Tarea_SendLCD
        Brclr Banderas_2,FinSendLCD,Mandardato

        Bclr Banderas_2,FinSendLCD
        Bra Cargardato

Clear   Movb #Clear_LCD,CharLCD

Mandarclear
	Jsr Decre_TablaTimers
        Jsr Tarea_SendLCD
        Brclr Banderas_2,FinSendLCD,Mandarclear
        Movb tTimer2mS,Timer2mS
        
Espera
        Jsr Decre_TablaTimers
        Tst Timer2mS
        Bne Espera

;===============================================================================
;                           DESPACHADOR DE TAREAS
;===============================================================================

Despachador_Tareas
        Brset Banderas_2,LCD_OK,Siguientes
        Jsr TareaLCD
        
Siguientes
        Jsr Decre_TablaTimers
        Jsr Tarea_Led_Testigo
        Jsr Tarea_Teclado
        Jsr Tarea_LeerPB0
        Jsr Tarea_LeerPB1
        ;Jsr Tarea_Leds
        Jsr Tarea_TCM
        Jsr Tarea_Conversion
        Jsr Tarea_MUX_Pantalla
        Bra Despachador_Tareas

;******************************************************************************
;                               TAREA LEDS
;******************************************************************************

Tarea_Leds
            Brset Banderas_1,ShortP0,ON
            Brset Banderas_1,LongP0,OFF
            Bra Check_Funcion

ON
            Bclr Banderas_1,ShortP0
            Bset PORTB,$40
            Bra Check_Funcion

OFF
            Bclr Banderas_1,LongP0
            Bclr PORTB,$40
            Bclr Banderas_1,ArrayOK
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
;                       TAREA LEER PB0
;******************************************************************************

Tarea_LeerPB0
              Ldx Est_Pres_LeerPB0
              Jsr 0,X

FinTareaPB0   Rts

;======================= LEER PB0 ESTADO 1 ======================================

LeerPB0_Est1
              Brclr PortPB,MaskPB0,ContinuePB0
              Bra FinPB0Est1

ContinuePB0   Movb #tSupRebPB0,Timer_RebPB0
              Movb #tShortP0,Timer_SHP0
              Movb #tLongP0,Timer_LP0

              Movw #LeerPB0_Est2,Est_Pres_LeerPB0

FinPB0Est1    Rts

;======================= LEER PB0 ESTADO 2 ======================================

LeerPB0_Est2
              Tst Timer_RebPB0
              Bne FinPB0Est2

              Brclr PortPB,MaskPB0,ContinuePB02
              Movw #LeerPB0_Est1,Est_Pres_LeerPB0
              Bra FinPB0Est2

ContinuePB02  Movw #LeerPB0_Est3,Est_Pres_LeerPB0

FinPB0Est2    Rts

;======================= LEER PB0 ESTADO 3 ======================================

LeerPB0_Est3
              Tst Timer_SHP0
              Bne FinPB0Est3

              Brclr PortPB,MaskPB0,ContinuePB03
              Bset Banderas_1,ShortP0
              Movw #LeerPB0_Est1,Est_Pres_LeerPB0
              Bra FinPB0Est3

ContinuePB03  Movw #LeerPB0_Est4,Est_Pres_LeerPB0

FinPB0Est3    Rts

;======================= LEER PB0 ESTADO 4 ======================================

LeerPB0_Est4
              Tst Timer_LP0
              Beq ContinuePB05
              Brclr PortPB,MaskPB0,FinPB0Est4
              Bset Banderas_1,ShortP0
              Bra LOLPB0

ContinuePB05  Brclr PortPB,MaskPB0,FinPB0Est4
              Bset Banderas_1,LongP0
LOLPB0        Movw #LeerPB0_Est1,Est_Pres_LeerPB0

FinPB0Est4    Rts

;******************************************************************************
;                       TAREA LEER PB1
;******************************************************************************

Tarea_LeerPB1
              Ldx Est_Pres_LeerPB1
              Jsr 0,X

FinTareaPB1   Rts

;======================= LEER PB1 ESTADO 1 ======================================

LeerPB1_Est1
              Brclr PortPB,MaskPB1,ContinuePB1
              Bra FinPB1Est1

ContinuePB1   Movb #tSupRebPB1,Timer_RebPB1
              Movb #tShortP1,Timer_SHP1
              Movb #tLongP1,Timer_LP1

              Movw #LeerPB1_Est2,Est_Pres_LeerPB1

FinPB1Est1    Rts

;======================= LEER PB1 ESTADO 2 ======================================

LeerPB1_Est2
              Tst Timer_RebPB1
              Bne FinPB1Est2

              Brclr PortPB,MaskPB1,ContinuePB12
              Movw #LeerPB1_Est1,Est_Pres_LeerPB1
              Bra FinPB1Est2

ContinuePB12  Movw #LeerPB1_Est3,Est_Pres_LeerPB1

FinPB1Est2    Rts

;======================= LEER PB1 ESTADO 3 ======================================

LeerPB1_Est3
              Tst Timer_SHP1
              Bne FinPB1Est3

              Brclr PortPB,MaskPB1,ContinuePB13
              Bset Banderas_1,ShortP1
              Movw #LeerPB1_Est1,Est_Pres_LeerPB1
              Bra FinPB1Est3

ContinuePB13  Movw #LeerPB1_Est4,Est_Pres_LeerPB1

FinPB1Est3    Rts

;======================= LEER PB1 ESTADO 4 ======================================

LeerPB1_Est4
              Tst Timer_LP1
              Beq ContinuePB15
              Brclr PortPB,MaskPB1,FinPB1Est4
              Bset Banderas_1,ShortP1
              Bra LOLPB1

ContinuePB15  Brclr PortPB,MaskPB1,FinPB1Est4
              Bset Banderas_1,LongP1
LOLPB1        Movw #LeerPB1_Est1,Est_Pres_LeerPB1

FinPB1Est4    Rts

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
              Cmpa MAX_TCL
              Beq FIN_Borrar_Num_Array

              Movb #$FF,1,Y+
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
                Bset Banderas_1,ArrayOK

FinTecladoEst4
                Movb #$FF,Tecla_In
                Movw #Teclado_Est1,Est_Pres_TCL
                Rts

;******************************************************************************
;                               TAREA LED TESTIGO
;******************************************************************************

Tarea_Led_Testigo
                Ldx Est_Pres_LDTst
                Jsr 0,X

FinLedTest      Rts

;========================== LED TESTIGO ESTADO 1 ===============================

Led_Testigo_Est1
                Tst Timer_LED_Testigo
                Bne FinLed_TestigoEst1

                Bclr PTP,$20
                Bset PTP,$10
                Movb #tTimerLDTst,Timer_LED_Testigo
                Movw #Led_Testigo_Est2,Est_Pres_LDTst

FinLed_TestigoEst1    Rts

;========================== LED TESTIGO ESTADO 2 ===============================

Led_Testigo_Est2
                Tst Timer_LED_Testigo
                Bne FinLed_TestigoEst2

                Bclr PTP,$10
                Bset PTP,$40
                Movb #tTimerLDTst,Timer_LED_Testigo
                Movw #Led_Testigo_Est3,Est_Pres_LDTst

FinLed_TestigoEst2    Rts

;========================== LED TESTIGO ESTADO 3 ===============================

Led_Testigo_Est3
                Tst Timer_LED_Testigo
                Bne FinLed_TestigoEst3

                Bclr PTP,$40
                Bset PTP,$20
                Movb #tTimerLDTst,Timer_LED_Testigo
                Movw #Led_Testigo_Est1,Est_Pres_LDTst

FinLed_TestigoEst3    Rts

;*******************************************************************************
;                            TAREA SEND LCD
;*******************************************************************************

Tarea_SendLCD
                Ldx EstPres_SendLCD
                Jsr 0,X

FinTarea_SendLCD      Rts

;============================ SEND LCD ESTADO 1 ================================

SendLCD_Est1
                Ldaa CharLCD
                Anda #$F0
                Lsra
                Lsra
                Staa PORTK

                Brset Banderas_2,RS,Deshabilitar
                Bclr PORTK,RS
                Bra Sigue

Deshabilitar    Bset PORTK,RS

Sigue           Bset PORTK,$02
                Movw #tTimer260uS,Timer260uS
                Movw #SendLCD_Est2,EstPres_SendLCD

FinSendLCDEst1  Rts

;============================ SEND LCD ESTADO 2 ================================

SendLCD_Est2
                Tst Timer260uS
                Bne FinSendLCDEst2

                Bclr PORTK,$02

                Ldaa CharLCD
                Anda #$0F
                Lsla
                Lsla
                Staa PORTK

                Brset Banderas_2,RS,Deshabilitar2
                Bclr PORTK,RS
                Bra Sigue2

Deshabilitar2   Bset PORTK,RS

Sigue2          Bset PORTK,$02
                Movw #tTimer260uS,Timer260uS
                Movw #SendLCD_Est3,EstPres_SendLCD

FinSendLCDEst2    Rts

;============================ SEND LCD ESTADO 3 ================================

SendLCD_Est3
                Tst Timer260uS
                Bne FinSendLCDEst3

                Bclr PORTK,$02
                Movw #tTimer40uS,Timer40uS
                Movw #SendLCD_Est4,EstPres_SendLCD

FinSendLCDEst3  Rts

;============================ SEND LCD ESTADO 4 ================================

SendLCD_Est4
                Tst Timer40uS
                Bne FinSendLCDEst4
                Bset Banderas_2,FinSendLCD
                Movw #SendLCD_Est1,EstPres_SendLCD

FinSendLCDEst4  Rts

;******************************************************************************
;                                TAREA LCD
;******************************************************************************

TareaLCD
            Ldx EstPres_TareaLCD
            Jsr 0,X
            
FinTareaLCD      Rts
            
;========================= TAREA LCD ESTADO 1 ==================================

TareaLCD_Est1
            Bclr Banderas_2,FinSendLCD
            Bclr Banderas_2,RS
            
            Brset Banderas_2,Second_line,Cargar_L2
            Movb #ADD_L1,CharLCD
            Movw Msg_L1,Punt_LCD
            Bra Comando
            
Cargar_L2   Movb #ADD_L2,CharLCD
            Movw Msg_L2,Punt_LCD
            
Comando     Jsr Tarea_SendLCD
	    Movw #TareaLCD_Est2,EstPres_TareaLCD
	    
Fin_TareaLCD_Est1   Rts
            
;========================= TAREA LCD ESTADO 2 ==================================

TareaLCD_Est2
            Brclr Banderas_2,FinSendLCD,Noenviado
            Bclr Banderas_2,FinSendLCD
            Bset Banderas_2,RS
            Ldx Punt_LCD
            Movb 1,X+,CharLCD
            Stx Punt_LCD
            Ldaa CharLCD
            
            Cmpa #$FF
            Bne Noenviado
            
            Brset Banderas_2,Second_Line,Terminar
            Bset Banderas_2,Second_Line
            Bra Sedevuelve
            
Terminar    Bclr Banderas_2,Second_Line
            Bset Banderas_2,LCD_OK
            
Sedevuelve  Movw #TareaLCD_Est1,EstPres_TareaLCD
            Bra Fin_TareaLCD_Est2
            
Noenviado   Jsr Tarea_SendLCD

Fin_TareaLCD_Est2  Rts

;******************************************************************************
;                               TAREA TCM
;******************************************************************************

Tarea_TCM
                Ldx Est_Pres_TCM
                Jsr 0,X

FinTCM          Rts

;============================== TCM ESTADO 1 ==================================

Tarea_TCM_Est1
                Brclr Banderas_1,ShortP1,FinTarea_TCMEst1
                Bclr Banderas_1,ShortP1
                Movb #tMinutosTCM,MinutosTCM
                Movb #tSegundosTCM,SegundosTCM

                Movw #MSG3,Msg_L1
                Movw #MSG4,Msg_L2
                Movb #TemporalLD,LEDS
                Bclr Banderas_2,LCD_OK

                Movw #Tarea_TCM_Est2,Est_Pres_TCM

FinTarea_TCMEst1  Rts

;============================== TCM ESTADO 2 ==================================

Tarea_TCM_Est2
                Movb MinutosTCM,BIN2
                Movb SegundosTCM,BIN1
                Movb #TemporalLD,LEDS

                Tst SegundosTCM
                Bne FinTarea_TCMEst2

                Tst MinutosTCM
                Bne DecMinutos

                Movb #tMinutosTCM,BIN2
                Movb #tSegundosTCM,BIN1
                Movw #MSG1,Msg_L1
                Movw #MSG2,Msg_L2
                Bclr Banderas_2,LCD_OK
		Movb #InicioLD,LEDS
                Bclr Banderas_1,ShortP1
                Movw #Tarea_TCM_Est1,Est_Pres_TCM
                Bra FinTarea_TCMEst2

DecMinutos      Dec MinutosTCM
                Movb #60,SegundosTCM

FinTarea_TCMEst2    Rts

;*******************************************************************************
;                             TAREA CONVERSION
;*******************************************************************************

Tarea_Conversion
                Ldaa BIN1
                Jsr BINBCD_PantallaMUX
                Movb BCD,BCD1

                Ldaa BIN2
                Jsr BINBCD_PantallaMUX
                Movb BCD,BCD2

                Jsr BCD_7SEG

FinTarea_Conversion     Rts

;*******************************************************************************
;                      Subrutina BINBCD_PantallaMUX
;*******************************************************************************

BINBCD_PantallaMUX
                Staa BCD
                Movb #7,Cont_BCD
                Ldd #0

LoopBINBCD      Lsl BCD
                Rolb
                Tfr B,A
                Andb #$0F

                Cmpb #5
                Bhs Mayor1
                Bra Menor1

Mayor1          Addb #3

Menor1          Anda #$F0

                Cmpa #$50
                Bhs Mayor2
                Bra Menor2

Mayor2          Adda #$30

Menor2          Aba
                Tfr A,B
                Dec Cont_BCD

                Beq LastBCD
                Bra LoopBINBCD

LastBCD         Lsl BCD
                Rolb
                Stab BCD

FinBINBCD_PantallaMUX Rts


;*******************************************************************************
;                       Subrutina BCD_7SEG
;*******************************************************************************

BCD_7SEG        Ldx #Segment
                Ldaa BCD1
                Anda #$0F
                Ldab A,X
                Stab Dsp4

                Ldaa BCD1
                Lsra
                Lsra
                Lsra
                Lsra
                Ldab A,X
                Stab Dsp3

                Ldaa BCD2
                Anda #$0F
                Ldab A,X
                Stab Dsp2

                Ldaa BCD2
                Lsra
                Lsra
                Lsra
                Lsra
                Ldab A,X
                Stab Dsp1

FinBCD_7SEG     Rts

;******************************************************************************
;                               TAREA MUX PANTALLA
;******************************************************************************

Tarea_MUX_Pantalla
                Ldx EstPres_PantallaMUX
                Jsr 0,X

FinPantallaMUX  Rts

;========================= PANTALLA MUX ESTADO 1 ===============================

PantallaMUX_Est1
              Tst TimerDigito
              Bne FinPantallaMUXEst1
              Movb #tTimerDigito,TimerDigito
              Ldaa Cont_Dig

              Cmpa #1
              Beq Display1
              Cmpa #2
              Beq Display2
              Cmpa #3
              Beq Display3
              Cmpa #4
              Beq Display4
              Bclr PTJ,$02
              Movb LEDS,PORTB
              Movb #$01,Cont_Dig
              Bra Contador

Display1      Bclr PTP,$01
              Movb Dsp1,PORTB
              Inc Cont_Dig
              Bra Contador

Display2      Bclr PTP,$02
              Movb Dsp2,PORTB
              Inc Cont_Dig
              Bra Contador

Display3      Bclr PTP,$04
              Movb Dsp3,PORTB
              Inc Cont_Dig
              Bra Contador

Display4      Bclr PTP,$08
              Movb Dsp4,PORTB
              Inc Cont_Dig

Contador      Movw #MaxCountTicks,Counter_Ticks
              Movw #PantallaMUX_Est2,EstPres_PantallaMUX

FinPantallaMUXEst1    Rts

;========================= PANTALLA MUX ESTADO 2 ===============================

PantallaMUX_Est2
              Ldd #MaxCountTicks
              Subd Counter_Ticks
              Cmpb Brillo
              Blo FinPantallaMUXEst2

              Bset PTP,$0F
              Bset PTJ,$02

              Movw #PantallaMUX_Est1,EstPres_PantallaMUX

FinPantallaMUXEst2    Rts

;*******************************************************************************
;                       SUBRUTINA DE ATENCION A RTI
;*******************************************************************************

Maquina_Tiempos:
               Ldx #Tabla_Timers_BaseT
               Jsr Decre_Timers_BaseT
               Bset MCFLG, $80
               RTI

;*******************************************************************************
;                       SUBRUTINA DECRE_TABLATIMERS
;*******************************************************************************

Decre_TablaTimers:
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

Retorne        Rts
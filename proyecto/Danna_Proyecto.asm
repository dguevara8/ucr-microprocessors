*******************************************************************************
;                            Proyecto Velodromo
; Autor: Danna Guevara Quesada
; Descripcion: Este sistema está diseñado para un velódromo de entrenamiento
; ciclista. Utiliza dos sensores (S1 y S2) para detectar el paso
; del ciclista y calcular su velocidad promedio. La información se muestra en
; una pantalla LCD 2x16 y un display de 7 segmentos de 4 dígitos.
;
; El sistema opera en cuatro modos:
; 1. ESPERA: Sistema inactivo, muestra mensaje en LCD.
; 2. CONFIGURAR: Permite programar el número de vueltas del entrenamiento.
; 3. CORRER: Ejecuta el ciclo de entrenamiento, calcula velocidad y muestra datos.
; 4. RESUMEN: Muestra la velocidad promedio y vueltas realizadas.

#include registers.inc

;******************************************************************************
;                 RELOCALIZACION DE VECTOR DE INTERRUPCION
;******************************************************************************
                                Org $3E4A
                                dw Maquina_Tiempos
;******************************************************************************
;                  DECLARACION DE LAS ESTRUCTURAS DE DATOS
;******************************************************************************

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

PortPB            EQU PTIH
MaskPB1           EQU $08
MaskPB2           EQU $01
tSupRebPB1        EQU 10
tShortP1          EQU 25
tLongP1           EQU 3
tSupRebPB2        EQU 10
tShortP2          EQU 25
tLongP2           EQU 3

LDConfig          EQU $02
MinNumVueltas     EQU 3
MaxNumVueltas     EQU 20

LDEspera          EQU $01

LDCorrer          EQU $04
tTimerCal         EQU 100
tTimerError       EQU 2
DeltaS            EQU 50
DeltaM            EQU 150
DeltaP            EQU 250
PortRele          EQU PORTE
Rele              EQU $04
VMin              EQU 35
VMax              EQU 90

LDResumen         EQU $08

tTimerBrillo      EQU 4
MaskSCF           EQU $80


ShortP1           EQU $01
LongP1            EQU $02
ShortP2           EQU $04
LongP2            EQU $08
ArrayOK           EQU $10

RS                EQU $01
LCD_OK            EQU $02
FinSendLCD        EQU $04
Second_Line       EQU $08

tTimerLDTst       EQU 5
Recarga_TC        EQU 30

InicioLD          EQU $AA
TemporalLD        EQU $55

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

                                Org $1020
EstPres_PantallaMUX ds 2
Dsp1              ds 1
Dsp2              ds 1
Dsp3              ds 1
Dsp4              ds 1
LEDS              ds 1
Cont_Dig          ds 1
Brillo            ds 1

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
Est_Pres_LeerPB2  ds 2

Est_Pres_TConfig  ds 2
ValorNumVueltas   ds 1
NumVueltas        ds 1

Est_Pres_TCorrer  ds 2
DeltaT            ds 1
Velocidad         ds 1
AcumVelocidad     ds 2
Vueltas           ds 1

Est_Pres_TBrillo  ds 2

Est_Pres_TLedTestigo ds 2

                                Org $1070
Banderas_1        ds 1
Banderas_2        ds 1

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
                  dB $40        ;'-' en 7 segmentos
                  dB $00        ;' ' en 7 segmentos


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
                  dB $0B ; Borrar
                  dB $00
                  dB $0E ; Enter

                                  Org $1200
Msg_Espera1:             FCC "*VELODROMO  623*"
                  dB EOB
Msg_Espera2:             FCC "**MODO  ESPERA**"
                  dB EOB
Msg_Configurar1:         FCC "MODO  CONFIGURAR"
                  dB EOB
Msg_Configurar2:         FCC "*  NUM VUELTAS *"
                  dB EOB
Msg_Correr1:             FCC "**MODO  CORRER**"
                  dB EOB
Msg_Correr2:             FCC "ESPERANDO INICIO"
                  dB EOB
Msg_Correr3:             FCC "ESPERANDO S1... "
                  dB EOB
Msg_Correr4:             FCC "ESPERANDO S2... "
                  dB EOB
Msg_Correr5:             FCC "TIniP      TFinP"
                  dB EOB
Msg_Correr6:             FCC "VELOC.   VUELTAS"
                  dB EOB
Msg_Correr7:             FCC "**  VELOCIDAD **"
                  dB EOB
Msg_Correr8:             FCC "*FUERA DE RANGO*"
                  dB EOB
Msg_Correr9:             FCC "**FIN DE CICLO**"
                  dB EOB
Msg_Resumen1:            FCC "  MODO RESUMEN  "
                  dB EOB
Msg_Resumen2:            FCC " VUELTAS   VELOC"
                  dB EOB

;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1500

tTimer1mS:      EQU 50
tTimer10mS:     EQU 500
tTimer100mS:    EQU 5000
tTimer1S:       EQU 50000

Tabla_Timers_BaseT:

Timer1mS        ds 2       ;Timer 1 ms con base a tiempo de interrupcion
Timer10mS:      ds 2       ;Timer para generar la base de tiempo 10 mS
Timer100mS:     ds 2       ;Timer para generar la base de tiempo de 100 mS
Timer1S:        ds 2       ;Timer para generar la base de tiempo de 1 Seg.
Counter_Ticks:  ds 2
Timer260uS:     ds 2
Timer40uS:      ds 2

Fin_BaseT       dW $FFFF

Tabla_Timers_Base1mS

Timer_RebPB1:   ds 1
Timer_RebPB2:   ds 1
Timer_RebTCL:   ds 1
TimerDigito:    ds 1
Timer2mS:       ds 1

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Timer_SHP1:     ds 1
Timer_SHP2:     ds 1

Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS

TimerCal:       ds 1
TimerIniPant:   ds 1
TimerFinPant:   ds 1
Timer_Brillo:   ds 1
Timer_LED_Testigo: ds 1   ;Timer para parpadeo de led testigo

Fin_Base100mS   dB $FF

Tabla_Timers_Base1S

Timer_LP1:      ds 1
Timer_LP2:      ds 1
TimerError:     ds 1

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
        Movb #$7F,DDRP
        Movb #$0F,PTP

        ; Pantalla LCD
        Movb #$FF,DDRK

        ; Count Down
        Bset MCCTL,$C7
        Movw #Recarga_TC,MCCNT

        ; Teclado
        Movb #$F0,DDRA
        Bset PUCR,$01

        ; Rele
        Bset DDRE,Rele
        Bclr PortRele,Rele

        ; ATD0
        Movb #$C0,ATD0CTL2
        Ldaa #160

LazoATD Dbne A,LazoATD

        Movb #$20,ATD0CTL3
        Movb #$90,ATD0CTL4
;===============================================================================
;                           PROGRAMA PRINCIPAL
;===============================================================================
        ; === TIMERS ===
        Movw #tTimer1mS,Timer1mS
        Movw #tTimer10mS,Timer10mS
        Movw #tTimer100mS,Timer100mS
        Movw #tTimer1S,Timer1S

        ; === TECLADO ===
        Movb #$FF,Tecla
        Movb #$FF,Tecla_In
        Clr Cont_TCL
        Movb #2,MAX_TCL

        ; === MODO ESPERA (VALOR POR DEFECTO) ===
        Movb #LDEspera,Leds         ; LED de Espera encendido
        Movb #$EF,Funcion

        ; === DISPLAYS Y PANTALLAS ===
        Movb #$01,Cont_Dig
        Clr TimerDigito
        Movb #$BB,BCD1              ; Displays apagados inicialmente
        Movb #$BB,BCD2
        Jsr BCD_7SEG

        ; === BANDERAS ===
        Clr Banderas_1
        Clr Banderas_2

        ; === CONFIGURACION ===
        Movb #10,NumVueltas         ; Valor por defecto

        Clr TimerIniPant
        Clr TimerFinPant

        Movb #tTimerLDTst,Timer_LED_Testigo ;Inicia timer parpadeo led testigo

        Lds #$3BFF
        Cli

        Movw #LeerPB1_Est1,Est_Pres_LeerPB1
        Movw #LeerPB2_Est1,Est_Pres_LeerPB2
        Movw #Teclado_Est1,Est_Pres_TCL
        Movw #Led_Testigo_Est1,Est_Pres_TLedTestigo
        Movw #SendLCD_Est1,EstPres_SendLCD
        Movw #TareaLCD_Est1,EstPres_TareaLCD
        Movw #Tarea_Brillo_Est1,Est_Pres_TBrillo
        Movw #Tarea_Configurar_Est1,Est_Pres_TConfig
        Movw #Tarea_Correr_Est1,Est_Pres_TCorrer
        Movw #PantallaMUX_Est1,EstPres_PantallaMUX

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
        Jsr Tarea_LeerPB1
        Jsr Tarea_LeerPB2
        Jsr Tarea_Brillo
        Jsr Tarea_MUX_Pantalla
        Jsr Tarea_Espera
        Jsr Tarea_Configurar
        Jsr Tarea_Correr
        Jsr Tarea_Resumen
        Bra Despachador_Tareas

;*******************************************************************************
;                           TAREA MODO ESPERA
;*******************************************************************************

Tarea_Espera
        Brset Funcion,$10,Fin_Tarea_Espera
        Movb #LDEspera,LEDS
        Movw #Msg_Espera1,Msg_L1
        Movw #Msg_Espera2,Msg_L2
        Bclr Banderas_2,LCD_OK

        Movb #$BB,BCD1
        Movb #$BB,BCD2
        Jsr BCD_7SEG

Fin_Tarea_Espera
        Rts

;*******************************************************************************
;                            TAREA CONFIGURAR
;*******************************************************************************

Tarea_Configurar
        Brclr Funcion,$20,Configurar
        Movw #Tarea_Configurar_Est1,Est_Pres_TConfig
        Bra FinTarea_Configurar

Configurar
        Movb #LDConfig,LEDS
        Ldx Est_Pres_TConfig
        Jsr 0,X

FinTarea_Configurar
        Rts

;========================== CONFIGURAR ESTADO 1 ================================

Tarea_Configurar_Est1
        Brclr Banderas_2,LCD_OK,FinTarea_Configurar_Est1
        ; Configurar mensajes LCD
        Movw #Msg_Configurar1,Msg_L1
        Movw #Msg_Configurar2,Msg_L2
        Bclr Banderas_2,LCD_OK

        ; Mostrar valor actual de vueltas
        Ldaa NumVueltas
        Jsr BINBCD_PantallaMUX
        Movb BCD,BCD1
        Movb #$BB,BCD2
        Jsr BCD_7SEG

        Jsr Borrar_Num_Array

        Movw #Tarea_Configurar_Est2,Est_Pres_TConfig

FinTarea_Configurar_Est1
        Rts

;========================== CONFIGURAR ESTADO 2 ================================

Tarea_Configurar_Est2
        ; Esperar entrada de teclado
        Brclr Banderas_1,ArrayOK,FinTarea_Configurar_Est2
        Bclr Banderas_1,ArrayOK

        ; Construir valor BCD desde array
        Ldx #Num_Array
        Ldaa 0,X              ; Decenas
        Cmpa #$FF
        Beq RechazarValor
        Lsla                  ; Mover a nibble alto
        Lsla
        Lsla
        Lsla
        Ldab 1,X              ; Unidades
        Cmpb #$FF
        Beq RechazarValor
        Aba                   ; Combinar

        ; Convertir BCD a binario
        Jsr BCD_BIN
        Movb BCD,ValorNumVueltas

        ; Validar límites (3 <= valor <= 20)
        Ldaa ValorNumVueltas
        Cmpa #MaxNumVueltas
        Bhi RechazarValor
        Cmpa #MinNumVueltas
        Blo RechazarValor

        ; Valor válido - guardar y mostrar
        Movb ValorNumVueltas,NumVueltas
        Ldaa NumVueltas
        Jsr BINBCD_PantallaMUX
        Movb BCD,BCD1
        Movb #$BB,BCD2
        Jsr BCD_7SEG

RechazarValor:
        Jsr Borrar_Num_Array

FinTarea_Configurar_Est2:
        Rts

;*******************************************************************************
;                           TAREA MODO CORRER
;*******************************************************************************

Tarea_Correr
        Brclr Funcion,$40,Correr
        Movw #Tarea_Correr_Est1,Est_Pres_TCorrer
        Bra FinTarea_Correr

Correr
        Movb #LDCorrer,LEDS
        Ldx Est_Pres_TCorrer
        Jsr 0,X

FinTarea_Correr
        Rts

;=============================== CORRER ESTADO 1 ===============================

Tarea_Correr_Est1
        ;Bclr Banderas_1,LongP2
        Brclr Banderas_2,LCD_OK,FinTarea_CorrerEst1
        ; Mensaje inicial
        Movw #Msg_Correr1,Msg_L1
        Movw #Msg_Correr2,Msg_L2
        Bclr Banderas_2,LCD_OK

        Movb #$BB,BCD1
        Movb #$BB,BCD2
        Jsr BCD_7SEG

FinTarea_CorrerEst1
        Movw #Tarea_Correr_Est2,Est_Pres_TCorrer
        Rts

;=============================== CORRER ESTADO 2 ===============================

Tarea_Correr_Est2
        ; Esperar presión larga PB2 para iniciar
        Brclr Banderas_1,LongP2,FinTarea_CorrerEst2

        ; Apagar relé
        Bclr PortRele,Rele

        ; Reiniciar variables del ciclo
        Clr DeltaT
        Clr Velocidad
        Clr AcumVelocidad
        Clr AcumVelocidad+1
        Clr Vueltas

        Bclr Banderas_1,ShortP2
        Bclr Banderas_1,LongP2

        Movw #Tarea_Correr_Est3,Est_Pres_TCorrer

FinTarea_CorrerEst2     Rts

;=============================== CORRER ESTADO 3 ===============================

Tarea_Correr_Est3
        Brclr Banderas_2,LCD_OK,FinTarea_CorrerEst3
        ; Mensaje esperando S1
        Movw #Msg_Correr1,Msg_L1
        Movw #Msg_Correr3,Msg_L2
        Bclr Banderas_2,LCD_OK

        Movb #$BB,BCD1
        Movb #$BB,BCD2
        Jsr BCD_7SEG

        Movw #Tarea_Correr_Est4,Est_Pres_TCorrer

FinTarea_CorrerEst3     Rts

;=============================== CORRER ESTADO 4 ===============================

Tarea_Correr_Est4
        ; Esperar ShortP1 (sensor S1)
        Brclr Banderas_1,ShortP1,FinTarea_CorrerEst4

        ; Iniciar timer de cálculo
        Movb #tTimerCal,TimerCal
        Bclr Banderas_1,ShortP1

        Brclr Banderas_2,LCD_OK,FinTarea_CorrerEst4
        ; Mensaje esperando S2
        Movw #Msg_Correr1,Msg_L1
        Movw #Msg_Correr4,Msg_L2
        Bclr Banderas_2,LCD_OK

        Movw #Tarea_Correr_Est5,Est_Pres_TCorrer

FinTarea_CorrerEst4     Rts

;========================== CORRER ESTADO 5 ===================================

Tarea_Correr_Est5
        ; Esperar ShortP2 (sensor S2)
        Brset Banderas_1,ShortP2,ShortP2_Detectado
        Jmp FinTarea_CorrerEst5

ShortP2_Detectado:
        Bclr Banderas_1,ShortP2

        ; Calcular velocidad y timers
        Jsr Calcula

        ; Verificar si velocidad es válida (35-90 km/h)
        Ldaa Velocidad
        Cmpa #VMin
        Blo Velocidad_Invalida_Est5
        Cmpa #VMax
        Bhi Velocidad_Invalida_Est5

        ; === VELOCIDAD VÁLIDA ===
        ; Mensaje TimerPant
        Movw #Msg_Correr1,Msg_L1
        Movw #Msg_Correr5,Msg_L2
        Bclr Banderas_2,LCD_OK

        ; Mostrar TimerFinPant en display izquierdo
        Ldab TimerFinPant
        Clra
        Ldx #10               ; Convertir 100ms a segundos
        Idiv
        Tfr X,D
        Tba
        Jsr BINBCD_PantallaMUX
        Movb BCD,BCD1

        ; Mostrar TimerIniPant en display derecho
        Ldab TimerIniPant
        Clra
        Ldx #10
        Idiv
        Tfr X,D
        Tba
        Jsr BINBCD_PantallaMUX
        Movb BCD,BCD2

        Jsr BCD_7SEG

        Movw #Tarea_Correr_Est6,Est_Pres_TCorrer
        Jmp FinTarea_CorrerEst5

        ; === VELOCIDAD INVÁLIDA ===
Velocidad_Invalida_Est5:
        ; Mensaje de alerta
        Movw #Msg_Correr7,Msg_L1
        Movw #Msg_Correr8,Msg_L2
        Bclr Banderas_2,LCD_OK

        ; Mostrar velocidad en display
        Ldaa Velocidad
        Cmpa #99
        Bhi Mostrar_Guiones_Vel_Est5

        Jsr BINBCD_PantallaMUX
        Movb BCD,BCD1
        Movb #$BB,BCD2
        Jsr BCD_7SEG
        Bra Cargar_Error_Est5

Mostrar_Guiones_Vel_Est5:
        Movb #$AA,BCD1
        Movb #$AA,BCD2
        Jsr BCD_7SEG

Cargar_Error_Est5:
        Clr TimerIniPant
        Clr TimerFinPant
        Movb #tTimerError,TimerError

        Movw #Tarea_Correr_Est7,Est_Pres_TCorrer

FinTarea_CorrerEst5:
        Rts

;========================== CORRER ESTADO 6 ===================================

Tarea_Correr_Est6
        ; Esperar que termine TimerIniPant
        Tst TimerIniPant
        Bne FinTarea_CorrerEst6

        ; Incrementar vueltas y acumular velocidad
        Inc Vueltas
        Ldd AcumVelocidad
        Addb Velocidad
        Adca #0
        Std AcumVelocidad

        ; Mostrar velocidad y vueltas en displays
        Ldaa Velocidad
        Jsr BINBCD_PantallaMUX
        Movb BCD,BCD2
        Ldaa Vueltas
        Jsr BINBCD_PantallaMUX
        Movb BCD,BCD1
        Jsr BCD_7SEG

        ; Mensaje de resultados
        Movw #Msg_Correr1,Msg_L1
        Movw #Msg_Correr6,Msg_L2
        Bclr Banderas_2,LCD_OK

        Movw #Tarea_Correr_Est8,Est_Pres_TCorrer

FinTarea_CorrerEst6        Rts

;========================== CORRER ESTADO 7 ===================================

Tarea_Correr_Est7:
        ; Esperar que termine TimerError (2 seg)
        Tst TimerError
        Bne FinTarea_CorrerEst7

        ; Volver a estado 3 (siguiente vuelta)
        Movw #Tarea_Correr_Est3,Est_Pres_TCorrer

FinTarea_CorrerEst7        Rts

;========================== CORRER ESTADO 8 ===================================

Tarea_Correr_Est8:
        ; Esperar que termine TimerFinPant
        Tst TimerFinPant
        Bne FinTarea_CorrerEst8

        ; Verificar si se completaron las vueltas
        Ldaa Vueltas
        Cmpa NumVueltas
        Beq No_Alcanzado_Completado

        ; Continuar con siguiente vuelta
        Movw #Tarea_Correr_Est3,Est_Pres_TCorrer
        Bra FinTarea_CorrerEst8

No_Alcanzado_Completado:
        ; Vueltas completadas - activar relé
        Bset PortRele,Rele
        Bclr Banderas_1,LongP2
        ; Mensaje fin de ciclo
        Movw #Msg_Correr1,Msg_L1
        Movw #Msg_Correr9,Msg_L2
        Bclr Banderas_2,LCD_OK
        Movw #Tarea_Correr_Est2,Est_Pres_TCorrer

FinTarea_CorrerEst8:
        Rts

;*******************************************************************************
;                             TAREA RESUMEN
;*******************************************************************************

Tarea_Resumen
        ; Verificar si NO estamos en modo Resumen (invertir lógica)
        Brclr Funcion,$80,FinTarea_Resumen  ; ? Si ya procesamos, salir

        ; Verificar que LCD esté listo
        Brclr Banderas_2,LCD_OK,FinTarea_Resumen

        Movb #LDResumen,LEDS
        Movw #Msg_Resumen1,Msg_L1
        Movw #Msg_Resumen2,Msg_L2
        Bclr Banderas_2,LCD_OK

        ; === CALCULAR VELOCIDAD PROMEDIO (CORREGIDO) ===
        Ldaa Vueltas
        Beq Resumen_Sin_Vueltas           ; ? Prevenir división por 0

        ; Preparar división: AcumVelocidad / Vueltas
        Ldd AcumVelocidad                 ; D = acumulado
        Clra                              ; A = 0
        Ldab Vueltas                      ; B = divisor
        Tfr D,X                           ; X = divisor (16 bits)
        Ldd AcumVelocidad                 ; D = dividendo
        Idiv                              ; X = cociente (VelPromedio)

        ; Mostrar velocidad promedio
        Tfr X,D
        Tba
        Jsr BINBCD_PantallaMUX
        Movb BCD,BCD1

        ; Mostrar vueltas
        Ldaa Vueltas
        Jsr BINBCD_PantallaMUX
        Movb BCD,BCD2

        Bra Resumen_Actualizar

Resumen_Sin_Vueltas:
        Movb #$00,BCD1
        Movb #$00,BCD2

Resumen_Actualizar:
        Jsr BCD_7SEG
        Movb #$FF,Funcion                 ; ? Marcar como procesado

FinTarea_Resumen:
        Rts

;*******************************************************************************
;                             TAREA BRILLO
;*******************************************************************************

Tarea_Brillo
        Ldx Est_Pres_TBrillo
        Jsr 0,X

FinTarea_Brillo   Rts

;=========================== BRILLO ESTADO 1 ===================================

Tarea_Brillo_Est1
        ; Cargar timer de muestreo
        Movb #tTimerBrillo,Timer_Brillo
        Movw #Tarea_Brillo_Est2,Est_Pres_TBrillo

FinTarea_BrilloEst1    Rts

;=========================== BRILLO ESTADO 2 ===================================

Tarea_Brillo_Est2
        ; Esperar tiempo de muestreo
        Tst Timer_Brillo
        Bne FinTarea_BrilloEst2

        ; Iniciar conversión ATD
        Movb #$87,ATD0CTL5
        Movw #Tarea_Brillo_Est3,Est_Pres_TBrillo

FinTarea_BrilloEst2    Rts

;==============================Brillo Estado 3=================================

Tarea_Brillo_Est3:
        ; Esperar fin de conversión
        Brclr ATD0STAT0,MaskSCF,FinTarea_BrilloEst3

        ; Promediar las 4 conversiones
        Ldd ADR00H
        Addd ADR01H
        Addd ADR02H
        Addd ADR03H
        Lsrd        ; /2
        Lsrd        ; /4 -> promedio en B (0-255)

        ; Convertir de 0-255 a 0-100
        Tfr B,A
        Ldy #100
        Mul         ; D = valor * 100
        Ldx #255
        Idiv        ; X = (valor * 100) / 255
        Tfr X,D
        Tba

        ; Limitar a rango 0-100
        Cmpa #100
        Bls BrilloOK
        Ldaa #100

BrilloOK
        Staa Brillo
        Movw #Tarea_Brillo_Est1,Est_Pres_TBrillo

FinTarea_BrilloEst3 Rts

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
;                               TAREA LED TESTIGO
;*******************************************************************************

Tarea_Led_Testigo
                Ldx Est_Pres_TLedTestigo
                Jsr 0,X

FinLedTest      Rts

;========================== LED TESTIGO ESTADO 1 ===============================

Led_Testigo_Est1
                Tst Timer_LED_Testigo
                Bne FinLed_TestigoEst1

                Movb #tTimerLDTst,Timer_LED_Testigo
                Bclr PTP,$20
                Bset PTP,$10
                Movw #Led_Testigo_Est2,Est_Pres_TLedTestigo

FinLed_TestigoEst1    Rts

;========================== LED TESTIGO ESTADO 2 ===============================

Led_Testigo_Est2
                Tst Timer_LED_Testigo
                Bne FinLed_TestigoEst2

                Movb #tTimerLDTst,Timer_LED_Testigo
                Bclr PTP,$10
                Bset PTP,$40
                Movw #Led_Testigo_Est3,Est_Pres_TLedTestigo

FinLed_TestigoEst2    Rts

;========================== LED TESTIGO ESTADO 3 ===============================

Led_Testigo_Est3
                Tst Timer_LED_Testigo
                Bne FinLed_TestigoEst3

                Movb #tTimerLDTst,Timer_LED_Testigo
                Bclr PTP,$40
                Bset PTP,$20
                Movw #Led_Testigo_Est1,Est_Pres_TLedTestigo

FinLed_TestigoEst3    Rts

;*******************************************************************************
;                             TAREA LEER PB1
;*******************************************************************************

Tarea_LeerPB1
              Ldx Est_Pres_LeerPB1
              Jsr 0,X

FinTareaPB1   Rts

;========================== LEER PB1 ESTADO 1 ==================================

LeerPB1_Est1
              Brclr PortPB,MaskPB1,ContinuePB1
              Bra FinPB1Est1

ContinuePB1   Movb #tSupRebPB1,Timer_RebPB1
              Movb #tShortP1,Timer_SHP1
              Movb #tLongP1,Timer_LP1

              Movw #LeerPB1_Est2,Est_Pres_LeerPB1

FinPB1Est1    Rts

;========================== LEER PB1 ESTADO 2 ==================================

LeerPB1_Est2
              Tst Timer_RebPB1
              Bne FinPB1Est2

              Brclr PortPB,MaskPB1,ContinuePB12
              Movw #LeerPB1_Est1,Est_Pres_LeerPB1
              Bra FinPB1Est2

ContinuePB12  Movw #LeerPB1_Est3,Est_Pres_LeerPB1

FinPB1Est2    Rts

;========================== LEER PB1 ESTADO 3 ==================================

LeerPB1_Est3
              Tst Timer_SHP1
              Bne FinPB1Est3

              Brclr PortPB,MaskPB1,ContinuePB13
              Bset Banderas_1,ShortP1
              Movw #LeerPB1_Est1,Est_Pres_LeerPB1
              Bra FinPB1Est3

ContinuePB13  Movw #LeerPB1_Est4,Est_Pres_LeerPB1

FinPB1Est3    Rts

;=========================== LEER PB1 ESTADO 4 =================================

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
;                             TAREA LEER PB2
;*******************************************************************************

Tarea_LeerPB2
              Ldx Est_Pres_LeerPB2
              Jsr 0,X

FinTareaPB2   Rts

;=========================== LEER PB2 ESTADO 1 =================================

LeerPB2_Est1
              Brclr PortPB,MaskPB2,ContinuePB2
              Bra FinPB2Est1

ContinuePB2   Movb #tSupRebPB2,Timer_RebPB2
              Movb #tShortP2,Timer_SHP2
              Movb #tLongP2,Timer_LP2

              Movw #LeerPB2_Est2,Est_Pres_LeerPB2

FinPB2Est1    Rts

;=========================== LEER PB1 ESTADO 2 =================================

LeerPB2_Est2
              Tst Timer_RebPB2
              Bne FinPB2Est2

              Brclr PortPB,MaskPB2,ContinuePB22
              Movw #LeerPB2_Est1,Est_Pres_LeerPB2
              Bra FinPB2Est2

ContinuePB22  Movw #LeerPB2_Est3,Est_Pres_LeerPB2

FinPB2Est2    Rts

;=========================== LEER PB1 ESTADO 3 =================================

LeerPB2_Est3
              Tst Timer_SHP2
              Bne FinPB2Est3

              Brclr PortPB,MaskPB2,ContinuePB23
              Bset Banderas_1,ShortP2
              Movw #LeerPB2_Est1,Est_Pres_LeerPB2
              Bra FinPB2Est3

ContinuePB23  Movw #LeerPB2_Est4,Est_Pres_LeerPB2

FinPB2Est3    Rts

;=========================== LEER PB1 ESTADO 4 =================================

LeerPB2_Est4
              Tst Timer_LP2
              Beq ContinuePB25
              Brclr PortPB,MaskPB2,FinPB2Est4
              Bset Banderas_1,ShortP2
              Bra LOLPB2

ContinuePB25  Brclr PortPB,MaskPB2,FinPB2Est4
              Bset Banderas_1,LongP2
LOLPB2        Movw #LeerPB2_Est1,Est_Pres_LeerPB2

FinPB2Est4    Rts

;*******************************************************************************
;                               TAREA MUX PANTALLA
;*******************************************************************************

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
              Bset DDRJ,$02
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
;                                TAREA LCD
;*******************************************************************************

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

;*******************************************************************************
;                         TAREA CONVERSION BCD BIN
;*******************************************************************************

BCD_BIN         Tfr A,B                 ;Se copia el valor BCD en el acumulador B

                Anda #$0F               ;Se obtiene el n mero de las unidades
                Staa BCD                ;Se carga el n mero de las unidades en BCD

                Lsrb                    ;Se desplaza 4 posiciones el valor de las decenas
                Lsrb
                Lsrb
                Lsrb

                Ldaa #10                ;Se multiplica por 10
                Mul

                Addb BCD                ;Se le suma a las unidades, el valor de las decenas multiplicado por 10
                Stab BCD                ;Se guarda el resultado en BCD
                Rts

;*******************************************************************************
;                               SUBRUTINA CALCULA
;*******************************************************************************
; Descripción: Calcula velocidad y timers basados en tiempo entre sensores
; Entradas: TimerCal (debe estar corriendo desde S1)
; Salidas: DeltaT, Velocidad, TimerIniPant, TimerFinPant
; Fórmulas:
;   DeltaT = tTimerCal - TimerCal (en unidades de 100ms)
;   Velocidad = (DeltaS * 36) / DeltaT (en km/h)
;   TimerIniPant = (DeltaT * DeltaM) / DeltaS (en 100ms)
;   TimerFinPant = (DeltaT * DeltaP) / DeltaS (en 100ms)
;*******************************************************************************

Calcula:
        ; ===== CALCULAR DeltaT =====
        Ldaa #tTimerCal       ; A = 100
        Suba TimerCal         ; A = 100 - TimerCal
        Staa DeltaT
        Tsta
        Beq DeltaT_Cero       ; Si DeltaT = 0, caso especial

        ; ===== CALCULAR VELOCIDAD =====
        ; Velocidad = (DeltaS * 36) / DeltaT
        Ldaa DeltaT
        Tfr A,B               ; B = DeltaT
        Clra                  ; D = 00:DeltaT
        Tfr D,X               ; X = DeltaT (divisor)

        Ldaa #DeltaS          ; A = 50
        Ldab #36              ; B = 36
        Mul                   ; D = 50 * 36 = 1800
        Idiv                  ; X = 1800 / DeltaT (cociente)
        XGDX                  ; INTERCAMBIO: D = cociente (velocidad)

        ; Limitar velocidad a 99
        Cmpb #99
        Bls Velocidad_OK
        Ldab #99

Velocidad_OK:
        Stab Velocidad

        ; ===== CALCULAR TimerIniPant =====
        ; TimerIniPant = (DeltaT * 150) / 50 = DeltaT * 3
        Ldaa DeltaT
        Ldab #DeltaM         ; B = 150
        Mul                  ; D = DeltaT * 150
        Ldx #DeltaS          ; X = 50
        Idiv                 ; X = (DeltaT * 150) / 50
        XGDX                 ; INTERCAMBIO: D = TimerIniPant
        Stab TimerIniPant    ; Guardar resultado

        ; ===== CALCULAR TimerFinPant =====
        ; TimerFinPant = (DeltaT * 250) / 50 = DeltaT * 5
        Ldaa DeltaT
        Ldab #DeltaP         ; B = 250
        Mul                  ; D = DeltaT * 250
        Ldx #DeltaS          ; X = 50
        Idiv                 ; X = (DeltaT * 250) / 50
        XGDX                 ; INTERCAMBIO: D = TimerFinPant

        ; Limitar a 254 (evitar $FF = -1)
        Cmpb #$FF
        Bne TimerFin_OK
        Ldab #$FE            ; Usar 254 si es 255

TimerFin_OK:
        Stab TimerFinPant
        Bra Fin_Calcula

        ; ===== CASO DeltaT = 0 =====
DeltaT_Cero:
        Movb #99,Velocidad
        Movb #99,TimerIniPant
        Movb #99,TimerFinPant

Fin_Calcula:
        Rts
;*******************************************************************************
;                        SUBRUTINA BIN BCD PANTALLA MUX
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
;                            SUBRUTINA BCD 7SEG
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

;*******************************************************************************
;                       SUBRUTINA BORRAR NUM ARRAY
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
;                     SUBRUTINA DE ATENCION MOD COUNT DOWN
;*******************************************************************************

Maquina_Tiempos:
               Ldx #Tabla_Timers_BaseT
               Jsr Decre_Timers_BaseT
               Bset MCFLG, $80
               RTI

;*******************************************************************************
;                       SUBRUTINA DECRE TABLATIMERS
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
;                       SUBRUTINA DECRE TIMERS
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
;                       SUBRUTINA DECRE TIMERS BASET
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
;*******************************************************************************
;                          Control de Nivel
; Autora: Danna Guevara Quesada C23562
;*******************************************************************************
#include registers.inc

;******************************************************************************
;                 RELOCALIZACION DE VECTOR DE INTERRUPCION
;******************************************************************************
                        Org $3E4A
                        dw Maquina_Tiempos
;******************************************************************************
;                 DECLARACION DE LAS ESTRUCTURAS DE DATOS
;******************************************************************************

CR:             EQU $0D
LF:             EQU $0A
EOM:            EQU $FF

Recarga_TC      EQU 30

MaskRele        EQU $04
PortRele        EQU PORTE

tTimer1mS:      EQU 50
tTimer10mS:     EQU 500
tTimer100mS:    EQU 5000
tTimer1S:       EQU 50000

tTimerATD       EQU 5
tTimerTerminal  EQU 1
tTimer5s        EQU 5

SCF             EQU $80

                Org $1000
Puntero_Serial  ds 2
Puntero_Aux     ds 2
Estado_Pres_ATD ds 2
NivelProm       ds 2
datoTemp        ds 2
Volumen         ds 1
Nivel           ds 1
Estado_Terminal ds 2
BCD_Result      ds 1
Contador        ds 1
ASCII_Output    ds 2
Flags           ds 1
Flag_Alarma     EQU $01
Flag_Vaciado    EQU $02

                Org $1200

MSG1:
             dB $0C
             FCC "     Universidad de Costa Rica"
             dB CR, LF, CR, LF
             FCC "   Escuela De Ingeneria Electrica"
             dB CR, LF, CR, LF
             FCC "        Microprocesadores"
             dB CR, LF, CR, LF
             FCC "              IE0623"
             dB CR, LF, CR, LF
MSG2:
             FCC "Volumen Calculado: "
             dB EOM

MSG3:
             dB CR, LF, CR, LF
             FCC "Alarma: El Nivel esta Bajo"
             dB EOM

MSG4:
             dB CR, LF, CR, LF
             FCC "Vaciando Tanque, Bomba Apagada"
             dB EOM

;===============================================================================
;                              TABLA DE TIMERS
;===============================================================================
                                Org $1500
Tabla_Timers_BaseT:

Timer1mS:   ds 2
Timer10mS:  ds 2
Timer100mS: ds 2
Timer1S:    ds 2

Fin_BaseT       dW $FFFF

Tabla_Timers_Base1mS

Fin_Base1mS:    dB $FF

Tabla_Timers_Base10mS

Fin_Base10ms    dB $FF

Tabla_Timers_Base100mS

TimerATD        ds 1

Fin_Base100mS   dB $FF

Tabla_Timers_Base1S

TimerTerminal   ds 1
Timer5s         ds 1

Fin_Base1S      dB $FF

;===============================================================================
;                              CONFIGURACION DE HARDWARE
;===============================================================================
                Org $2000
; Configuracion del SCI
                Movw #39,SC1BDH
                Movb #$00,SC1CR1
                Movb #$0C,SC1CR2

                Ldaa SC1SR1
                Movb #$00,SC1DRL

; Configuracion del ATD
                Movb #$C0,ATD0CTL2
                Ldaa #160
Espere_ATD:     Dbne a,Espere_ATD
                Movb #$20,ATD0CTL3
                Movb #$10,ATD0CTL4

; Configuracion de puertos
                Bset DDRE,$04
                Bset DDRT,$20
                Bclr PORTE,$04
                Bclr PTT,$20

; Configuracion del Modulo de Contador
                Bset MCCTL,$C7
                Movw #Recarga_TC,MCCNT

; Inicializacion de timers
                Movw #tTimer1mS,Timer1mS
                Movw #tTimer10mS,Timer10mS
                Movw #tTimer100mS,Timer100mS
                Movw #tTimer1S,Timer1S

; Envio mensaje inicial
                Movb #MSG1,Puntero_Serial
                Bset SC1CR2,$08

Transmitir_Inicio:
                Brclr SC1SR1,$80,Transmitir_Inicio
                Ldaa SC1SR1
                Ldx Puntero_Serial
                Ldaa 1,x+
                Cmpa #EOM
                Beq Finalizar_Transmision
                Staa SC1DRL
                Stx Puntero_Serial
                Bra Transmitir_Inicio

Finalizar_Transmision:
                Movw #Terminal_Estado1,Estado_Terminal

;*******************************************************************************
;                          Programa Principal
;*******************************************************************************
                Lds #$3BFF
                Cli
                Clr Flags
                Movw #ATD_Estado1,Estado_Pres_ATD

;******************************************************************************
;                          DESPACHADOR DE TAREAS
;******************************************************************************
Despachador_Tareas:
                Jsr Decre_TablaTimers
                Jsr Tarea_ATD
                Jsr Tarea_Terminal
                Bra Despachador_Tareas

;******************************************************************************
;                               TAREA ATD
;******************************************************************************
Tarea_ATD:
                Ldx Estado_Pres_ATD
                Jsr 0,x
                Rts

;=========================== TAREA ATD ESTADO 1 ================================
ATD_Estado1:
                Movb #tTimerATD,TimerATD
                Movw #ATD_Estado2,Estado_Pres_ATD
                Rts

;=========================== TAREA ATD ESTADO 2 ================================
ATD_Estado2:
                Tst TimerATD
                Bne Fin_ATD_Estado2
                Movb #$87,ATD0CTL5
                Movw #ATD_Estado3,Estado_Pres_ATD
Fin_ATD_Estado2:
                Rts

;=========================== TAREA ATD ESTADO 3 ================================
ATD_Estado3:
                Brclr ATD0STAT0,SCF,Fin_ATD_Estado3
                Jsr Calcula

                Ldaa Volumen
                Cmpa #14
                Bhi Verificar_Alarma_Off
                Bset Flags,Flag_Alarma
                Bset PortRele,MaskRele
                Bra Reiniciar_ATD

Verificar_Alarma_Off:
                Cmpa #28
                Bls Verificar_Vaciado
                Bclr Flags,Flag_Alarma

Verificar_Vaciado:
                Cmpa #83
                Bls Reiniciar_ATD
                Bset Flags,Flag_Vaciado
                Bclr PortRele,MaskRele

Reiniciar_ATD:
                Movw #ATD_Estado1,Estado_Pres_ATD

Fin_ATD_Estado3:
                Rts

;******************************************************************************
;                               TAREA TERMINAL
;******************************************************************************
Tarea_Terminal:
                Ldx Estado_Terminal
                Jsr 0,x
                Rts

;========================= TAREA TERMINAL ESTADO 1 =============================
Terminal_Estado1:
                Movb #tTimerTerminal,TimerTerminal
                Movw #Terminal_Estado2,Estado_Terminal
                Movw #MSG1,Puntero_Serial
                Rts

;========================= TAREA TERMINAL ESTADO 2 =============================
Terminal_Estado2:
                Tst TimerTerminal
                Bne Fin_Terminal_Estado2
                Brclr SC1SR1,$80,Fin_Terminal_Estado2
                Ldaa SC1SR1
                Ldx Puntero_Serial
                Ldaa 1,x+
                Cmpa #EOM
                Beq Mostrar_Volumen
                Staa SC1DRL
                Stx Puntero_Serial
                Bra Fin_Terminal_Estado2

Mostrar_Volumen:
                Jsr BIN_ASCII
                Ldaa ASCII_Output
                Staa SC1DRL
Esperar_TX1:    Brclr SC1SR1,$80,Esperar_TX1
                Ldaa ASCII_Output+1
                Staa SC1DRL
Esperar_TX2:    Brclr SC1SR1,$80,Esperar_TX2
                Movw #Terminal_Estado3,Estado_Terminal
                Movw #MSG3,Puntero_Serial
                Movw #MSG4,Puntero_Aux
Fin_Terminal_Estado2:
                Rts

;========================= TAREA TERMINAL ESTADO 3 =============================
Terminal_Estado3:
                Brclr Flags,Flag_Alarma,Verificar_Vacio
                Brclr SC1SR1,$80,Fin_Terminal_Estado3
                Ldaa SC1SR1
                Ldx Puntero_Serial
                Ldaa 1,x+
                Cmpa #EOM
                Beq Volver_Estado1
                Staa SC1DRL
                Stx Puntero_Serial
                Bra Fin_Terminal_Estado3

Verificar_Vacio:
                Brclr Flags,Flag_Vaciado,Volver_Estado1
                Brclr SC1SR1,$80,Fin_Terminal_Estado3
                Ldaa SC1SR1
                Ldx Puntero_Aux
                Ldaa 1,x+
                Cmpa #EOM
                Beq Mensaje_Vaciado_Completo
                Staa SC1DRL
                Stx Puntero_Aux
                Bra Fin_Terminal_Estado3

Mensaje_Vaciado_Completo:
                Movb #tTimer5s,Timer5s
                Movw #MSG1,Puntero_Serial
                Movw #Terminal_Estado4,Estado_Terminal
                Bra Fin_Terminal_Estado3

Volver_Estado1:
                Movw #Terminal_Estado1,Estado_Terminal
Fin_Terminal_Estado3:
                Rts

;========================= TAREA TERMINAL ESTADO 4 =============================
Terminal_Estado4:
                Tst Timer5s
                Bne Fin_Terminal_Estado4
                Bclr Flags,Flag_Vaciado
                Movw #Terminal_Estado1,Estado_Terminal
Fin_Terminal_Estado4:
                Rts

;******************************************************************************
;                       SUBRUTINA BIN_ASCII
;******************************************************************************

BIN_ASCII:
                Ldaa Volumen
                Clrb
                Ldx #10
                Idiv
                Addb #$30
                Stab ASCII_Output+1
                Tfr X,D
                Adda #$30
                Staa ASCII_Output
                Rts

;******************************************************************************
;                       SUBRUTINA CALCULA
;******************************************************************************
Calcula:
                Ldd ADR00H
                Addd ADR01H
                Addd ADR02H
                Addd ADR03H
                Lsrd
                Lsrd
                Std NivelProm

                Ldd NivelProm
                Ldy #13
                Emul
                Ldx #1023
                Ediv
                Sty datoTemp
                Ldd datoTemp
                Stab Nivel

                Ldd #7065
                Ldy datoTemp
                Emul
                Ldx #1000
                Ediv
                Sty datoTemp
                Ldd datoTemp
                Stab Volumen
                Rts

;*******************************************************************************
;                       SUBRUTINA DE ATENCION A MCCNT
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
Loop:           Ldd Timer10mS
                Bne Loop2
                Movw #tTimer10mS,Timer10mS
                Ldx #Tabla_Timers_Base10mS
                Jsr Decre_Timers
Loop2:          Ldd Timer100mS
                Bne Loop3
                Movw #tTimer100mS,Timer100mS
                Ldx #Tabla_Timers_Base100mS
                Jsr Decre_Timers
Loop3:          Ldd Timer1S
                Bne Retornar
                Movw #tTimer1S,Timer1S
                Ldx #Tabla_Timers_Base1S
                Jsr Decre_Timers

Retornar:       Rts

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

Incremento:     Inx
                Bra Decre_Timers

Retorno:        Rts

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

Siga:          Dey
               Sty -2,X
               Bra Decre_Timers_BaseT

Retorne:       Rts
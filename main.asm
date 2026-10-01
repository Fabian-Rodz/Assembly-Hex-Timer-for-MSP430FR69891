            .cdecls C,LIST,"msp430.h"
            .def RESET
            .text
            .retain
            .retainrefs

;-------------------------------------------------------------------------------
; VARIABLES
;-------------------------------------------------------------------------------
chars			.byte  " ", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",0x00
charsHigh		.byte 0x00,0xEF,0xF1,0x9C,0x0C,0x9F,0x8F,0xBD,0x6F,0x90,0x78,0x0E,0x1C,0x6C,0x6C,0xFC,0xCF,0xFC,0xCF,0xB7,0x80,0x7C,0x0C,0x6C,0x00,0x00,0x90,0xFC,0x60,0xDB,0xF3,0x67,0xB7,0xBF,0xE0,0xFF,0xF7
charsLow		.byte 0x00,0x00,0x50,0x00,0x88,0x00,0x00,0x00,0x00,0x50,0x00,0x22,0x00,0xA0,0x82,0x00,0x00,0x02,0x02,0x00,0x50,0x00,0x28,0x0A,0xAA,0xB0,0x28,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
LCDPositions	.byte 0,9,5,3,18,14,7,0

TEAM14String	.byte	"TEAM14",0
NAME01String	.byte	"NAME01",0
NAME02String	.byte	"NAME02",0
NAME03String	.byte	"NAME03",0
NAME04String	.byte	"NAME04",0
ATBASEString	.byte	"ATBASE",0
HEXString		.byte	"HEX",0
OCTALString		.byte	"OCTAL",0
STTIMEString	.byte	"STTIME",0
FREQString		.byte	"FREQ",0
OneHZString		.byte	"1 HZ",0
TenHZString		.byte	"10HZ",0



;-------------------------------------------------------------------------------
; RESET
;-------------------------------------------------------------------------------

RESET:
            mov.w   #__STACK_END,SP
            mov.w   #WDTPW|WDTHOLD,&WDTCTL

;-------------------------------------------------------------------------------
; CONFIGURACION LCD
;-------------------------------------------------------------------------------

            mov.w   #0xFFFF,&LCDCPCTL0
            mov.w   #0xFC3F,&LCDCPCTL1
            mov.w   #0x0FFF,&LCDCPCTL2

            bic.w   #LOCKLPM5,&PM5CTL0

            mov.w   #0x041E,&LCDCCTL0
            mov.w   #0x0208,&LCDCVCTL
            mov.w   #0x8000,&LCDCCPCTL
            mov.w   #LCDCLRM,&LCDCMEMCTL
            bis.w   #LCDON,&LCDCCTL0


;-------------------------------------------------------------------------------
; CONFIGURACIO BOTONES
;-------------------------------------------------------------------------------

            bic.b   #BIT1+BIT2,&P1DIR
            bis.b   #BIT1+BIT2,&P1REN
            bis.b   #BIT1+BIT2,&P1OUT
            bis.b   #BIT1+BIT2,&P1IES
            bic.b   #BIT1+BIT2,&P1IFG

			;<<<< Enable Port 1 Interrupts >>>>
            bis.b   #BIT1+BIT2,&P1IE

			;<<<< Enable General Interrupts >>>>
			nop
            bis.w   #GIE,SR
            nop


;-------------------------------------------------------------------------------
; CONFIGURACION TEMPORIZADOR
;-------------------------------------------------------------------------------
			bic		#CCIE, &TA0CCTL0
			mov     #TASSEL_1+MC_1+ID_0, &TA0CTL
			nop
;-------------------------------------------------------------------------------
; ESTADOS
;-------------------------------------------------------------------------------
team14			.equ	0
teamNames		.equ	1
atBase			.equ	2
hexOctal		.equ	3
stTime			.equ	4
chooseDigits	.equ	5
frequency		.equ	6
hzSelect		.equ	7
countdown		.equ	8

			mov		#team14,R13				;R13 representa el estado del programa
											;0 -> TEAM14
											;1 -> Team Names
											;2 -> ATBASE
											;3 -> HEX/OCTAL
											;4 -> STTIME
											;5 -> Choose Decimal Digits
											;6 -> FREQ
											;7 -> 1Hz/10Hz
											;8 -> Countdown


;-------------------------------------------------------------------------------
; MAIN
;-------------------------------------------------------------------------------
MainLoop:
			cmp		#team14,R13
			jz		GoToTeamNames

			cmp		#teamNames,R13
			jz		GoToTeamNamesLoop

			cmp		#atBase,R13
			jz		GoToATBASE

			cmp		#hexOctal,R13
			jz		GoToHexOctal

			cmp		#stTime,R13
			jz		GoToSTTIME

			cmp		#chooseDigits,R13
			jz		GoToChooseDecimalDigits

			cmp		#frequency,R13
			jz		GoToFREQ

			cmp		#hzSelect,R13
			jz		GoToHzSelect

			cmp		#countdown,R13
			jz		GoToCountdown

			jmp     MainLoop


GoToTeamNames:
			call	#TeamNames
			jmp		MainLoop

GoToTeamNamesLoop:
			call	#TeamNamesLoop
			jmp		MainLoop

GoToATBASE:
			call	#ATBASE
			jmp		MainLoop

GoToHexOctal:
			call	#HexOctal
			jmp		MainLoop

GoToSTTIME:
			call	#STTIME
			jmp		MainLoop

GoToChooseDecimalDigits:
			call	#ChooseDecimalDigits
			mov		R8,R14
			jmp		MainLoop

GoToFREQ:
			call	#FREQ
			jmp		MainLoop

GoToHzSelect:
			call	#HzSelect
			jmp		MainLoop

GoToCountdown:
			call	#Countdown
			jmp		MainLoop


;-------------------------------------------------------------------------------
; Nombre: TeamNames
; Objetivo: Confirmar si el estado de R13 se mantiene en team14(0), teamNames(1) o si ha cambiado y reflejarlo en el LCD
; Precondiciones:
;	- El programa acaba de empezar o viene de atBase(2)
;	- El estado de R13 está en team14(0)
;	- El string siempre comienza en "TEAM14"
; Postcondiciones:
;	- El estado de R13 cambiará a teamNames(1) o atBase(2)
; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
TeamNames:
			mov		#TEAM14String,R5			; Empieza en TEAM14
			mov		#0,R15						; Orden (TEAM14,NAME01,NAME02,NAME03,NAME04)
			call	#DisplayString

TeamNamesLoop:
			nop
			;<<<< Enable General Interrupts >>>>
			;<<<< Enable Low Power Mode >>>>
			mov		#LPM0+GIE,SR
			nop
			cmp		#2,R13
			jz		SwitchState					; Va hacia ATBASE
			jmp		TeamNamesLoop


;-------------------------------------------------------------------------------
; Nombre: TeamNamesPort1Pressed
; Objetivo: Procesar la lectura del botón presionado en el estado de R13 team14(0) y teamNames(1)
; Precondiciones:
;	- El estado de R13 corresponde a team14(0) 0 teamNames(1)
;	- S1 o S2 fueron presionados durante este estado
; Postcondiciones:
;	- Se llamará la función que corresponda al botón presionado durante este estado
; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
TeamNamesPort1Pressed:


			bit		#BIT1,&P1IN
			jnz		CheckTeamNamesS2Press
            call    #TeamNamesS1
            jmp		ReturnFromTeamNamesPort1Pressed

CheckTeamNamesS2Press:
            bit.b   #BIT2,&P1IN
            jnz     ReturnFromTeamNamesPort1Pressed
            call    #TeamNamesS2


ReturnFromTeamNamesPort1Pressed:
            ret



;-------------------------------------------------------------------------------
; Nombre: TeamNamesS1
; Objetivo: Mostrar el nombre en el LCD correspondiente al orden en R15 (0:TEAM14 -> 1:NAME01 -> 2:NAME02 -> 3:NAME03 -> 4:NAME04)
; Precondiciones:
;	- S1 fue presionado en el estado de R13 que corresponde a team14(0) 0 teamNames(1)
;	- LCD inicializado.
; Postcondiciones:
;	- El LCD mostrara el nombre correspondiente al orden de R15
; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
TeamNamesS1:
			inc.b	R15

            cmp.b   #5,R15
            jl      SelectNextName

            mov.b   #0,R15


SelectNextName:
			cmp		#0,R15
			jz		SelectTEAM14

			mov		#1,R13					; Poner estado en teamNames(1)

			cmp		#1,R15
			jz		SelectNAME01
			cmp		#2,R15
			jz		SelectNAME02
			cmp		#3,R15
			jz		SelectNAME03
			cmp		#4,R15
			jz		SelectNAME04

			mov		#0,R15					; Prevención por si el orden tiene un valor invalido

SelectTEAM14:
			mov		#TEAM14String,R5
			mov		#0,R13					; Poner estaod en team14(0)
			jmp		DisplayNextName

SelectNAME01:
			mov		#NAME01String,R5
			jmp		DisplayNextName

SelectNAME02:
			mov		#NAME02String,R5
			jmp		DisplayNextName

SelectNAME03:
			mov		#NAME03String,R5
			jmp		DisplayNextName

SelectNAME04:
			mov		#NAME04String,R5

DisplayNextName:
            call    #DisplayString
            ret

;-------------------------------------------------------------------------------
; Nombre: TeamNamesS2
; Objetivo: Cambiar el estado de R13 a atBase(2) si actualmente se está en el estado team14(0)
; Precondiciones:
;	- S2 fue presionado en el estado de R13 que corresponde a team14(0) 0 teamNames(1)
;	- LCD inicializado.
; Postcondiciones:
;	- El estado de R13 cambiará a atBase(2) si actualmente se está en el estado team14(0)
;	- Si el estado actual de R13 es teamNames(1), se mantendrá en teamNames(1)

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
TeamNamesS2:
			cmp		#team14,R13
			jz		SwitchToATBASEState
			jmp		ReturnFromTeamNamesS2

SwitchToATBASEState:
			mov		#atBase,R13

ReturnFromTeamNamesS2:
			ret

;-------------------------------------------------------------------------------
; Nombre: ATBASE
; Objetivo: Confirmar si el estado de R13 se mantiene en atBase(2) o si ha cambiado y reflejarlo en el LCD
; Precondiciones:
;	- El estado anterior fue team14(0) o countdown(8)
; Postcondiciones:
;	- El estado de R13 cambiará a team14(0) o a hexOctal(3)

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
ATBASE:
			mov		#ATBASEString,R5
			call	#DisplayString
			nop
			;<<<< Enable General Interrupts >>>>
			;<<<< Enable Low Power Mode >>>>
			mov		#LPM0+GIE,SR
			nop
			cmp		#team14,R13						; Va hacia team14(0)
			jz		SwitchState
			cmp		#hexOctal,R13					; Va hacia hexOctal(3)
			jz		SwitchState
			jmp		ATBASE


;-------------------------------------------------------------------------------
; Nombre: ATBASEPort1Pressed
; Objetivo: Procesar la lectura del botón presionado en el estado de R13 atBase(2)
; Precondiciones:
;	- El estado de R13 corresponde a atBase(2)
;	- S1 o S2 fueron presionados durante este estado
; Postcondiciones:
;	- El estado de R13 cambiará a team14(0) o a hexOctal(3)

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
ATBASEPort1Pressed:
			bit		#BIT1,&P1IN
			jnz		CheckATBASES2Press
            call    #ATBASES1
            jmp		ReturnFromATBASEPort1Pressed

CheckATBASES2Press:
            bit.b   #BIT2,&P1IN
            jnz     ReturnFromATBASEPort1Pressed
            call    #ATBASES2
            jmp		ReturnFromATBASEPort1Pressed


;-------------------------------------------------------------------------------
; Nombre: ATBASES1
; Objetivo: Cambiar R13 al estado de hexOctal(3)
; Precondiciones:
;	- S1 fue presionado en el estado de R13 que corresponde a atBase(2)
; Postcondiciones:
;	- El programa cambiará a trabajar con el estado de elegir entre HEX y OCTAL

; Fecha: 29-mayo-2026
;------------------------------------------------------------------------------
ATBASES1:
			mov		#hexOctal,R13
			jmp		ReturnFromATBASEPort1Pressed

;-------------------------------------------------------------------------------
; Nombre: ATBASES2
; Objetivo: Cambiar R13 al estado de team14(0)
; Precondiciones:
;	- S2 fue presionado en el estado de R13 que corresponde a atBase(2)
; Postcondiciones:
;	- El programa cambiará a trabajar con el estado presentar los nombres, comenzando con "TEAM14"

; Fecha: 29-mayo-2026
;------------------------------------------------------------------------------
ATBASES2:
			mov		#team14,R13

ReturnFromATBASEPort1Pressed:
			ret

;-------------------------------------------------------------------------------
; Nombre: HexOctal
; Objetivo: Confirmar si el estado de R13 se mantiene en hexOctal(3) o si ha cambiado y reflejarlo en el LCD
; Precondiciones:
;	- El programa viene de atBase(2)
;	- El estado de R13 está en hexOctal(3)
; Postcondiciones:
;	- El estado de R13 cambiará a stTime(4)

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
HexOctal:
			mov		#HEXString,R5
			call	#DisplayString
			mov		#0,R14							; 0 representa hexadecimal; 1 representa octal
HexOctalLoop:
			nop
			;<<<< Enable General Interrupts >>>>
			;<<<< Enable Low Power Mode >>>>
			mov		#LPM0+GIE,SR
			nop
			cmp		#stTime,R13						; Va hacia STTIME(4)
			jz		SwitchState
			jmp		HexOctalLoop

;-------------------------------------------------------------------------------
; Nombre: HexOctalPort1Pressed
; Objetivo: Procesar la lectura del botón presionado en el estado de R13 hexOctal(3)
; Precondiciones:
;	- El estado de R13 corresponde a hexOctal(3)
;	- S1 o S2 fueron presionados durante este estado
; Postcondiciones:
;	- Se llamará la función que corresponda al botón presionado durante este estado

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
HexOctalPort1Pressed:
			bit		#BIT1,&P1IN
			jnz		CheckHexOctalS2Press
            call    #HexOctalS1
            jmp		ReturnFromHexOctalPort1Pressed

CheckHexOctalS2Press:
            bit.b   #BIT2,&P1IN
            jnz     ReturnFromHexOctalPort1Pressed
            call    #HexOctalS2

;-------------------------------------------------------------------------------
; Nombre: HexOctalS1
; Objetivo: Alternar entre la base hexadecimal o la octal y reflejarla en la pantalla
; Precondiciones:
;	- S1 fue presionado en el estado de R13 que corresponde a hexOctal(3)
; Postcondiciones:
;	- El LCD mostrara la base que se ha escogido entre hexadecimal y octal

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
HexOctalS1:
			xor.b	#BIT0,R14
			cmp.b	#0,R14
			jz		DisplayHex
			jmp		DisplayOctal

DisplayHex:
			mov		#HEXString,R5
			call	#DisplayString
			jmp		ReturnFromHexOctalPort1Pressed

DisplayOctal:
			mov		#OCTALString,R5
			call	#DisplayString
			jmp		ReturnFromHexOctalPort1Pressed

;-------------------------------------------------------------------------------
; Nombre: HexOctalS2
; Objetivo: Cambiar el estado de R13 a stTime(4)
; Precondiciones:
;	- S2 fue presionado en el estado de R13 que corresponde a stTime(4)
; Postcondiciones:
;	- El estado de R13 cambiará a stTime(4)

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
HexOctalS2:
			mov		#stTime,R13

ReturnFromHexOctalPort1Pressed:
			ret


;-------------------------------------------------------------------------------
; Nombre: STTIME
; Objetivo: Confirmar si el estado de R13 se mantiene en stTime(4) y reflejarlo en el LCD
; Precondiciones:
;	- El programa viene de hexOctal(3)
;	- El estado de R13 está en stTime(4)
; Postcondiciones:
;	- El estado de R13 cambiará a chooseDigits(5)

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
STTIME:

			mov		#STTIMEString,R5
			call	#DisplayString
			nop
			nop
			;<<<< Enable General Interrupts >>>>
			;<<<< Enable Low Power Mode >>>>
			mov		#LPM0+GIE,SR
			nop
			cmp		#chooseDigits,R13			; Va hacia chooseDigits(5)
			jz		SwitchState
			jmp		STTIME

;-------------------------------------------------------------------------------
; Nombre: STTIMEPort1Pressed
; Objetivo: Procesar la lectura del botón presionado en el estado de R13 stTime(4)
; Precondiciones:
;	- El estado de R13 corresponde a stTime(4)
;	- S1 o S2 fueron presionados durante este estado
; Postcondiciones:
;	- Se llamará la función que corresponda al botón presionado durante este estado

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
STTIMEPort1Pressed:
			bit		#BIT1,&P1IN
			jnz		CheckSTTIMES2Press
            call    #STTIMES1
            jmp		ReturnFromSTTIMEPort1Pressed

CheckSTTIMES2Press:
            bit.b   #BIT2,&P1IN
            jnz     ReturnFromSTTIMEPort1Pressed
            call    #STTIMES2
            jmp		ReturnFromSTTIMEPort1Pressed


;-------------------------------------------------------------------------------
; Nombre: STTIMES1
; Objetivo: Cambiar el estado de R13 a chooseDigits(5)
; Precondiciones:
;	- S1 fue presionado en el estado de R13 que corresponde a stTime(4)
; Postcondiciones:
;	- El estado de R13 cambiará a chooseDigits(5)

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
STTIMES1:
			mov		#chooseDigits,R13
			jmp		ReturnFromSTTIMEPort1Pressed

;-------------------------------------------------------------------------------
; Nombre: STTIMES2
; Objetivo: Cambiar el estado de R13 a chooseDigits(5)
; Precondiciones:
;	- S2 fue presionado en el estado de R13 que corresponde a stTime(4)
; Postcondiciones:
;	- El estado de R13 cambiará a chooseDigits(5)

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
STTIMES2:
			mov		#chooseDigits,R13

ReturnFromSTTIMEPort1Pressed:
			ret

;-------------------------------------------------------------------------------
; Nombre: ChooseDecimalDigits
; Objetivo: Confirmar si el estado de R13 se mantiene en chooseDigits(5) o si ha cambiado y reflejarlo en el LCD
; Precondiciones:
;	- El programa viene de stTime(4)
;	- El estado de R13 está en chooseDigits(5)
; Postcondiciones:
;	- El estado de R13 cambiará a frequency (6)
;	- R8 tendrá el valor del tiempo ingresado por el usuario y se copiará a R14

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
ChooseDecimalDigits:
			mov.w   #2,&LCDCMEMCTL			;LCD Clear
			clr.w   R5                      ; R5 = centenas
            clr.w   R6                      ; R6 = decenas
            clr.w   R7                      ; R7 = unidades
            clr.w   R8                      ; R8 = valor decimal total
            clr.w   R9                      ; R9 = dígito actual
            mov.w   #1,R11                  ; R11 = dígitos visibles
            call    #UpdateDecimalDisplay   ; Muestra primer 0
ChooseDecimalDigitsLoop:
			cmp		#5,R13
			jz		ChooseDecimalDigitsLoop
			ret

;-------------------------------------------------------------------------------
; Nombre: ChooseDecimalDigitsPort1Pressed
; Objetivo: Atender interrupciones generadas por S1 y S2.
; Precondiciones:
; 	- Las interrupciones del Puerto 1 están habilitadas y P1IFG contiene el flag del botón que generó la interrupción.
; Postcondiciones:
; 	- Se procesa S1 o S2 según corresponda, se hace debounce por loop y se restauran los registros utilizados.

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------
ChooseDecimalDigitsPort1Pressed:
			push.w  R10                     ; Guarda registros usados
            push.w  R12
			bit		#BIT1,&P1IN				;if P1.1 still being pressed, handleS1
			jnz		CheckS2
            call    #HandleS1               ; Procesa S1
            jmp		ReturnToLoop

CheckS2:
            bit.b   #BIT2,&P1IN				; Verifica S2
            jnz     ReturnToLoop			; Si no fue S2, iniciar vuelve a loop
            call    #HandleS2               ; Procesa S2


ReturnToLoop:
            pop.w   R12
            pop.w   R10
            ;<<<< Enable Port 1 Interrupts >>>>
            bis.b   #BIT1+BIT2, &P1IE
            ret

;-------------------------------------------------------------------------------
; Nombre: HandleS1
; Objetivo: Incrementar circularmente el dígito decimal actualmente seleccionado.
; Precondiciones:
; 	- R9 contiene el dígito actualmente seleccionado:
; 	- 0 = centenas, 1 = decenas, 2 = unidades.
; 	- R5, R6 y R7 contienen valores entre 0 y 9.
; Postcondiciones:
; 	- El dígito seleccionado aumenta en 1. Si llega a 10, regresa a 0.
; 	- Luego se actualiza el valor decimal total y el LCD.

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------
HandleS1:
            cmp.w   #0,R9                   ; ¿Dígito actual = centenas?
            jeq     IncHundreds

            cmp.w   #1,R9                   ; ¿Dígito actual = decenas?
            jeq     IncTens

            jmp     IncOnes                 ; Si no, son unidades

IncHundreds:
            inc.w   R5                      ; Incrementa centenas
            cmp.w   #10,R5                  ; Si llega a 10,
            jne     UpdateAfterS1
            clr.w   R5                      ; vuelve a 0
            jmp     UpdateAfterS1

IncTens:
            inc.w   R6                      ; Incrementa decenas
            cmp.w   #10,R6
            jne     UpdateAfterS1
            clr.w   R6                      ; vuelve a 0
            jmp     UpdateAfterS1

IncOnes:
            inc.w   R7                      ; Incrementa unidades
            cmp.w   #10,R7
            jne     UpdateAfterS1
            clr.w   R7                      ; vuelve a 0

UpdateAfterS1:
            call    #UpdateDecimalDisplay   ; Actualiza valor y LCD
            ret

;-------------------------------------------------------------------------------
; Nombre: HandleS2
; Objetivo: Confirmar el dígito actual y avanzar al próximo dígito decimal.
; Precondiciones:
; 	- R9 contiene el dígito actualmente seleccionado.
; 	- R11 contiene la cantidad de dígitos visibles en el LCD.
; Postcondiciones:
; 	- Si R9 es menor que 2, se avanza al próximo dígito y se muestra un dígito adicional.
;			Si R9 es 2, R8 queda con el valor decimal final.

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------
HandleS2:
            cmp.w   #2,R9                   ; Ya esta en unidades?
            jeq     SwitchToFREQState      	; Si si, termina seleccion

            inc.w   R9                      ; Pasa al proximo digito
            inc.w   R11                     ; Muestra otro digito

            call    #UpdateDecimalDisplay   ; Actualiza LCD
            jmp		ReturnToChooseDecimalDigitsPort1Pressed

SwitchToFREQState:
			mov		#frequency,R13

ReturnToChooseDecimalDigitsPort1Pressed:
            ret


;-------------------------------------------------------------------------------
; Nombre: UpdateDecimalDisplay
; Objetivo: Actualizar el valor decimal total y presentar los dígitos visibles.
; Precondiciones:
; 	- R5, R6 y R7 contienen los dígitos decimales.
; 	- R11 indica cuántos dígitos deben mostrarse.
; Postcondiciones:
; 	- R8 contiene el valor decimal equivalente y el LCD muestra los dígitos correspondientes.

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------
UpdateDecimalDisplay:
            call    #DecimalToValue         ; Calcula R8
            call    #ShowDecimalDigits      ; Muestra digitos visibles
            ret

;-------------------------------------------------------------------------------
; Nombre: DecimalToValue
; Objetivo: Convertir tres dígitos decimales individuales en un valor decimal total.
;
; Precondiciones:
; 	- R5 contiene centenas, R6 contiene decenas y R7 contiene unidades.
; 	- Cada registro contiene un valor entre 0 y 9.
;
; Postcondiciones:
; 	- R8 contiene el valor decimal equivalente a R5:R6:R7.
;

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------

DecimalToValue:
            clr.w   R8                      ; Limpia resultado

            mov.w   R5,R10                  ; Copia centenas

CentLoop:
            cmp.w   #0,R10                  ; Quedan centenas?
            jeq     TensStart
            add.w   #100,R8                 ; Suma 100
            dec.w   R10                     ; Baja contador
            jmp     CentLoop

TensStart:
            mov.w   R6,R10                  ; Copia decenas

TensLoop:
            cmp.w   #0,R10                  ; Quedan decenas?
            jeq     OnesStart
            add.w   #10,R8                  ; Suma 10
            dec.w   R10                     ; Baja contador
            jmp     TensLoop

OnesStart:
            add.w   R7,R8                   ; Suma unidades
            ret

;-------------------------------------------------------------------------------
; Nombre: ShowDecimalDigits
; Objetivo: Mostrar en el LCD los dígitos decimales que ya deben estar visibles.
; Precondiciones:
; 	- R5 contiene centenas, R6 contiene decenas, R7 contiene unidades y R11 contiene la cantidad de dígitos visibles.
; Postcondiciones:
; 	- LCD muestra:
; 			R11 = 1 -> centenas solamente
; 			R11 = 2 -> centenas y decenas
; 			R11 = 3 -> centenas, decenas y unidades

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------
ShowDecimalDigits:
            mov.w   R5,R12                  ; R12 = centenas
            call    #DigitToPattern         ; R12 = patron LCD
            mov.b   R12,LCDMEM+9            ; Muestra centenas

            cmp.w   #2,R11                  ; Mostrar decenas?
            jlo     OnlyHundreds

            mov.w   R6,R12                  ; R12 = decenas
            call    #DigitToPattern
            mov.b   R12,LCDMEM+5            ; Muestra decenas

            cmp.w   #3,R11                  ; Mostrar unidades?
            jlo     OnlyHundredsTens

            mov.w   R7,R12                  ; R12 = unidades
            call    #DigitToPattern
            mov.b   R12,LCDMEM+3            ; Muestra unidades
            ret

OnlyHundreds:
            mov.b   #0x00,LCDMEM+5          ; Borra decenas
            mov.b   #0x00,LCDMEM+3          ; Borra unidades
            ret

OnlyHundredsTens:
            mov.b   #0x00,LCDMEM+3          ; Borra unidades
            ret
;-------------------------------------------------------------------------------
; Nombre: DigitToPattern
; Objetivo: Convertir un dígito decimal al patrón hexadecimal correspondiente para presentarlo en el LCD.
; Precondiciones:
; 	- R12 contiene un dígito decimal entre 0 y 9.
; Postcondiciones:
; 	- R12 contiene el patrón hexadecimal del LCD correspondiente al dígito.

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------
DigitToPattern:
            cmp.w   #0,R12                  ; Compara con 0
            jeq     Pattern0
            cmp.w   #1,R12                  ; Compara con 1
            jeq     Pattern1
            cmp.w   #2,R12
            jeq     Pattern2
            cmp.w   #3,R12
            jeq     Pattern3
            cmp.w   #4,R12
            jeq     Pattern4
            cmp.w   #5,R12
            jeq     Pattern5
            cmp.w   #6,R12
            jeq     Pattern6
            cmp.w   #7,R12
            jeq     Pattern7
            cmp.w   #8,R12
            jeq     Pattern8

Pattern9:
            mov.w   #0x00F7,R12             ; Patron 9
            ret

Pattern0:
            mov.w   #0x00FC,R12             ; Patron 0
            ret

Pattern1:
            mov.w   #0x0060,R12             ; Patron 1
            ret

Pattern2:
            mov.w   #0x00DB,R12             ; Patron 2
            ret

Pattern3:
            mov.w   #0x00F3,R12             ; Patron 3
            ret

Pattern4:
            mov.w   #0x0067,R12             ; Patron 4
            ret

Pattern5:
            mov.w   #0x00B7,R12             ; Patron 5
            ret

Pattern6:
            mov.w   #0x00BF,R12             ; Patron 6
            ret

Pattern7:
            mov.w   #0x00E0,R12             ; Patron 7
            ret

Pattern8:
            mov.w   #0x00FF,R12             ; Patron 8
            ret

;-------------------------------------------------------------------------------
; Nombre: FREQ
; Objetivo: Confirmar si el estado de R13 se mantiene en frequency (6) o si ha cambiado y reflejarlo en el LCD
; Precondiciones:
;	- El programa viene de chooseDigits(5)
;	- El estado de R13 está en frequency (6)
; Postcondiciones:
;	- El estado de R13 cambiará a hzSelect(7)

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
FREQ:
			mov		#FREQString,R5
			call	#DisplayString
FREQLoop:
			nop
			;<<<< Enable General Interrupts >>>>
			;<<<< Enable Low Power Mode >>>>
			mov		#LPM0+GIE,SR
			nop
			cmp		#hzSelect,R13
			jz		SwitchState
			jmp		FREQLoop


;-------------------------------------------------------------------------------
; Nombre: FREQPort1Pressed
; Objetivo: Identificar si la interrupcion fue generada por S1 o S2.
; Precondiciones:
;	-Las interrupciones de P1.1 y P1.2 deben estar habilitadas.
; Postcondiciones:
;	- Se ejecuta la subrutina de S1o S2 segun el boton presionado.

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------
FREQPort1Pressed:
			bit		#BIT1,&P1IN
			jnz		CheckFREQS2Press
            call    #FREQS1
            jmp		ReturnFromFREQPort1Pressed

CheckFREQS2Press:
            bit.b   #BIT2,&P1IN
            jnz     ReturnFromFREQPort1Pressed
            call    #FREQS2
            jmp		ReturnFromFREQPort1Pressed


;-------------------------------------------------------------------------------
; Nombre: FREQS1
; Objetivo: Cambiar el estado de R13 a hzSelect(7)
; Precondiciones:
; 	- S1 fue presionado en el estado de R13 que corresponde a frequency(6)
; Postcondiciones:
;	- 	El estado de R13 cambiará a hzSelect(7)

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
FREQS1:
			mov		#hzSelect,R13
			jmp		ReturnFromFREQPort1Pressed

;-------------------------------------------------------------------------------
; Nombre: FREQS2
; Objetivo: Cambiar el estado de R13 a hzSelect(7)
; Precondiciones:
; 	- S2 fue presionado en el estado de R13 que corresponde a frequency(6)
; Postcondiciones:
;	- 	El estado de R13 cambiará a hzSelect(7)

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
FREQS2:
			mov		#hzSelect,R13

ReturnFromFREQPort1Pressed:
			ret

;-------------------------------------------------------------------------------
; Nombre: HzSelect
; Objetivo: Confirmar si el estado de R13 se mantiene en hzSelect(7) o si ha cambiado y reflejarlo en el LCD
; Precondiciones:
;	- El programa viene de frequency(6)
;	- El estado de R13 está en hzSelect(7)
; Postcondiciones:
;	- El estado de R13 cambiará a countdown(8)

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
HzSelect:
			mov		#OneHZString,R5
			call	#DisplayString
			mov.w   #32767,&TA0CCR0
			mov		#0,R4					; Mantiene referencia a estado entre 1Hz y 10Hz
HzSelectLoop:
			nop
			;<<<< Enable General Interrupts >>>>
			;<<<< Enable Low Power Mode >>>>
			mov		#LPM0+GIE,SR
			nop
			cmp		#countdown,R13			; Va hacia countdown(8)
			jz		SwitchState
			jmp		HzSelectLoop

;-------------------------------------------------------------------------------
; Nombre: HzSelectPort1Pressed
; Objetivo: Procesar la lectura del botón presionado en el estado de R13 hzSelect(7)
; Precondiciones:
;	- El estado de R13 corresponde a hzSelect(7)
;	- S1 o S2 fueron presionados durante este estado
; Postcondiciones:
;	- Se llamará la función que corresponda al botón presionado durante este estado

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
HzSelectPort1Pressed:
			bit		#BIT1,&P1IN
			jnz		CheckHzSelectS2Press
            call    #HzSelectS1
            jmp		ReturnFromHzSelectPort1Pressed

CheckHzSelectS2Press:
            bit.b   #BIT2,&P1IN
            jnz     ReturnFromHzSelectPort1Pressed
            call    #HzSelectS2
            jmp		ReturnFromHzSelectPort1Pressed


;-------------------------------------------------------------------------------
; Nombre: HzSelectS1
; Objetivo: Llamar la función ToggleFrequency para alternar entre las frecuencias
; Precondiciones:
;	- S1 fue presionado en el estado de R13 que corresponde a hzSelect(7)
; Postcondiciones:
;	- Se alternó entre la frecuencia escogida y la próxima opción

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
HzSelectS1:
			call	#ToggleFrequency
			jmp		ReturnFromHzSelectPort1Pressed

;-------------------------------------------------------------------------------
; Nombre: HzSelectS2
; Objetivo: Cambiar el estado de R13 a countdown(8)
; Precondiciones:
;	- S2 fue presionado en el estado de R13 que corresponde a hzSelect(7)
; Postcondiciones:
;	- El estado de R13 cambiará a countdown(8)

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
HzSelectS2:

			mov		#countdown,R13

ReturnFromHzSelectPort1Pressed:
			ret

;-------------------------------------------------------------------------------
; Nombre: ToggleFrequency
; Objetivo: Cambiar la frecuencia del conteoentre 1Hz y 10Hz.
; Precondiciones:
;	- S1 debe haber generado una interrupcion y Timer_A0 debe estar configurado.
; Postcondiciones:
;	- TA0CCR0 queda configurado para 1Hz o 10Hz y el LCD refleja la frecuencia.

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------
ToggleFrequency:
            xor.b   #1,R4

            tst.b   R4
            jnz     SelectTenHz

SelectOneHz:
            mov.w   #32767,&TA0CCR0
            mov		#OneHZString,R5
            call    #DisplayString
            jmp		ReturnFromToggleFrequency

SelectTenHz:
            mov.w   #3276,&TA0CCR0
            mov		#TenHZString,R5
            call    #DisplayString

ReturnFromToggleFrequency:
			ret

;-------------------------------------------------------------------------------
; Nombre: Countdown
; Objetivo: Confirmar si el estado de R13 se mantiene en countdown(8) o si ha cambiado y reflejarlo en el LCD
; Precondiciones:
;	- El programa viene de hzSelect(7)
;	- El estado de R13 está en countdown(8)
;	- El tiempo ingresado por el usuario está guardado en R14
;	- La frecuencia del temporizador fue registrada previamente
; Postcondiciones:
;	- El contador descenderá desde el valor en R14 hasta 0

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------

Countdown:
			;<<<< Enable Timer Interrupts >>>>
			mov.w   #CCIE, &TA0CCTL0
			mov.w   #TASSEL_1+MC_1+ID_0, &TA0CTL
			nop
			mov.w	R14,R5
CountdownLoop:
			nop
			;<<<< Enable General Interrupts >>>>
			;<<<< Enable Low Power Mode >>>>
			mov		#LPM0+GIE,SR
			nop
			cmp		#atBase,R13				; Va hacia atBase(2)
			jz		SwitchState
			jmp		CountdownLoop


;-------------------------------------------------------------------------------
; Nombre: CountdownTrigger
; Objetivo: Conseguir un dígito del valor actual del contador a través de una división
; Precondiciones:
;	- R5 almacena el valor actual del contador
;	- El TIMER0_A0 está habilitado
; Postcondiciones:
;	- El contador descenderá desde el valor en R14 hasta 0
;	- R5 contiene el dígito actual
;	- R6 contiene el próximo valor a dividir
;	- R7 contiene la posición en el LCD que corresponde al dígito actual

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------
CountdownTrigger:
			mov.w   #2,&LCDCMEMCTL
			push	R5
			mov.w	#0,R6
			mov.w	#LCDPositions+3,R7

divideCurrentDividend:
			cmp		#10,R5
			jn		callDisplayDecimalDigit
			inc		R6
			sub		#10,R5
			jmp		divideCurrentDividend

callDisplayDecimalDigit:
			call	#displayDecimalDigit
			pop		R5
			ret

;-------------------------------------------------------------------------------
; Nombre: displayDecimalDigit
; Objetivo: Validar si se puede demostrar el dígito actual conseguido en CountdownTrigger en el LCD
; Precondiciones:
;	- R5 contiene el dígito actual
;	- R7 contiene la posición actual
; Postcondiciones:
;	- R5 se convertirá en su valor ASCII
;	- R8 almacenará la dirección en memoria de los caracteres
;	- R9 almacenará la dirección en memoria de los high bytes
;	- R10 almacenará la dirección en memoria de los low bytes
;	-

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------
displayDecimalDigit:
			mov.b	@R7,R11
			tst		R11
			jz		countdownFin
			mov		#chars+1ah,R8
			mov		#charsHigh+1ah,R9
			mov		#charsLow+1ah,R10
			add		#0x30,R5
			jmp		searchDecimalDigitASCII

countdownFin:
			ret

;-------------------------------------------------------------------------------
; Nombre: searchDecimalDigitASCII
; Objetivo: Verificar si el valor ASCII de R5 es válido y demostrarlo en el LCD
; Precondiciones:
;	- R5 almacena el ASCII del dígito actual
;	- R8 almacena la dirección en memoria de los caracteres
;	- R9 almacena la dirección en memoria de los high bytes
;	- R10 almacená la dirección en memoria de los low bytes
; Postcondiciones:
;	- Se demostrará el valor del dígito actual en el LCD

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------
searchDecimalDigitASCII:
			mov.b	@R8,R11
			tst		R11
			jz		callReturnToDivision
			inc		R8
			inc		R9
			inc		R10
			cmp.b	R5,R11
			jnz		searchDecimalDigitASCII
			dec		R9
			dec		R10
			mov.b	@R7,R11
			mov.b	@R9,0x0a20(R11)
			mov.b	@R10,0x0a20+1(R11)
			dec		R7

callReturnToDivision:
			call	#returnToDivision
			ret

;-------------------------------------------------------------------------------
; Nombre: returnToDivision
; Objetivo: Volver a la división con el cociente anterior
; Precondiciones:
;	- R6 almacena el cociente anterior
; Postcondiciones:
;	- R5 almacenará el nuevo valor a dividir

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------
returnToDivision:
			mov		R6,R5
			mov		#0,R6
			call	#divideCurrentDividend
			ret


;-------------------------------------------------------------------------------
; Nombre: CountdownPort1Pressed
; Objetivo: Procesar la lectura del botón presionado en el estado de R13 countdown(R8)
; Precondiciones:
;	- El estado de R13 corresponde a countdown(R8)
;	- S1 o S2 fueron presionados durante este estado
; Postcondiciones:
;	- Se llamará la función que corresponda al botón presionado durante este estado

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
CountdownPort1Pressed:
			bit		#BIT1,&P1IN
			jnz		CheckCountdownS2Press
            call    #CountdownS1
            jmp		ReturnFromCountdownPort1Pressed

CheckCountdownS2Press:
            bit.b   #BIT2,&P1IN
            jnz     ReturnFromCountdownPort1Pressed
            call    #CountdownS2
            jmp		ReturnFromCountdownPort1Pressed

;-------------------------------------------------------------------------------
; Nombre: CountdownS1
; Objetivo: Alternar entre activar y desactivar las interrupciones del TIMER0_A0
; Precondiciones:
;	- S1 fue presionado en el estado de R13 que corresponde a countdown(8)
; Postcondiciones:
;	- El alternará la habilitación de las interrupciones del TIMER0_A0 entre el actual y el próximo

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
CountdownS1:
			;<<<< Enable Timer Interrupts >>>>
			xor		#CCIE,&TA0CCTL0
			jmp		ReturnFromCountdownPort1Pressed

;-------------------------------------------------------------------------------
; Nombre: HexOctalS2
; Objetivo: Cambiar el estado de R13 a atBase(2)
; Precondiciones:
;	- S2 fue presionado en el estado de R13 que corresponde a countdown(8)
; Postcondiciones:
;	- Si el contador terminó, el estado cambiará a atBase(2)

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
CountdownS2:
			tst		R5
			jz		NewStateATBASE
			jmp		ReturnFromCountdownPort1Pressed

NewStateATBASE:
			mov		#atBase,R13

ReturnFromCountdownPort1Pressed:
			ret


;-------------------------------------------------------------------------------
; SwitchState
;-------------------------------------------------------------------------------
SwitchState:
			ret
;-------------------------------------------------------------------------------
; Nombre: DisplayString
; Objetivo: Demostrar en el LCD el string entrado
; Precondiciones:
;	- R5 contiene el string por presentar
; Postcondiciones:
;	- Los primeros 6 caracteres del string serán presentado en el LCD si se encuentran todos sus caracteres

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------
DisplayString:
			mov.w   #2,&LCDCMEMCTL
			mov		#chars,R6
			mov		#charsHigh,R7
			mov		#charsLow,R8
			mov		#LCDPositions+1,R9
			mov		#0,R10					;0 representa no return, 1 represent return
displayStringSetup:
			push	R6
			push	R7
			push	R8

stringLoop:
			mov.b	@R6,R11
			tst		R11
			jz		ReturnFromLoop
			inc		R6
			inc		R7
			inc		R8
			cmp.b	@R5,R11
			jnz		stringLoop

			dec		R7
			dec		R8
			mov.b	@R9,R11
			mov.b	@R7,0x0a20(R11)
			mov.b	@R8,0x0a20+1(R11)
			call	#verifyPos
ReturnFromLoop:
			pop		R8
			pop		R7
			pop		R6
			cmp		#1,R10
			jnz		displayStringSetup
			ret
verifyPos:
			mov.b	@R9,R11
			cmp.b	#0x07, R11
			jz		EndPrint
			inc		R9
			inc		R5
			mov.b	@R5,R11
			tst		R11
			jz		EndPrint
			jmp		ReturnFromVerifyPos
EndPrint:
			mov		#1,R10
ReturnFromVerifyPos:
			ret

;-------------------------------------------------------------------------------
; Nombre: PORT1_ISR
; Objetivo: Recibe las interrupciones generadas por S1 y S2
; Precondiciones:
;	- P1IE está habilitado
;	- GIE está habilitado
;	- S1 y S2 están habilitados y en pull-up
; Postcondiciones:
;	- Se procesará la interrupción correspondiente a S1 o S2

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
PORT1_ISR:
			bit.b   #BIT1+BIT2, &P1IFG
            jz		InterruptFin

            bic.b   #BIT1+BIT2, &P1IE
            bic.b   #BIT1+BIT2, &P1IFG

			call	#Debouncing
			bit.b   #BIT1+BIT2,&P1IN
           	jz		EnablePort1Interrupt
            call	#CheckState
            jmp		InterruptFin

EnablePort1Interrupt:
			;<<<< Enable Port 1 Interrupts >>>>
			bis.b   #BIT1+BIT2, &P1IE
			jmp		InterruptFin


;-------------------------------------------------------------------------------
; Nombre: CheckState
; Objetivo: Verificar el estado actual y dirigirse a la operación correspondiente
; Precondiciones:
;	- R13 contiene el estado actual
; Postcondiciones:
;	- Se dirigirá a la operación que corresponda al estado actual

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
CheckState:
			cmp		#0,R13
			jz		ActionTeamNamesPort1Pressed
			cmp		#1,R13
			jz		ActionTeamNamesPort1Pressed
			cmp		#2,R13
			jz		ActionATBASEPort1Pressed
			cmp		#3,R13
			jz		ActionHexOctalPort1Pressed
			cmp		#4,R13
			jz		ActionSTTIMEPort1Pressed
			cmp		#5,R13
			jz		ActionChooseDecimalDigitsPort1Pressed
			cmp		#6,R13
			jz		ActionFREQPort1Pressed
			cmp		#7,R13
			jz		ActionHzSelectPort1Pressed
			cmp		#8,R13
			jz		ActionCountdownPort1Pressed
			; En caso que R13 no contenga un estado válido
			mov		#0,R13
			;<<<< Enable Port 1 Interrupts >>>>
			bis.b   #BIT1+BIT2, &P1IE
			jmp		ReturnFromCheckState

ActionTeamNamesPort1Pressed:
			call	#TeamNamesPort1Pressed
			jmp		ReturnFromCheckState

ActionATBASEPort1Pressed:
			call	#ATBASEPort1Pressed
			jmp		ReturnFromCheckState

ActionHexOctalPort1Pressed:
			call	#HexOctalPort1Pressed
			jmp		ReturnFromCheckState

ActionSTTIMEPort1Pressed:
			call	#STTIMEPort1Pressed
			jmp		ReturnFromCheckState
ActionChooseDecimalDigitsPort1Pressed:
			call	#ChooseDecimalDigitsPort1Pressed
			jmp		ReturnFromCheckState

ActionFREQPort1Pressed:
			call	#FREQPort1Pressed
			jmp		ReturnFromCheckState

ActionHzSelectPort1Pressed:
			call	#HzSelectPort1Pressed
			jmp		ReturnFromCheckState

ActionCountdownPort1Pressed:
			call	#CountdownPort1Pressed
            jmp		ReturnFromCheckState

ReturnFromCheckState:
			;<<<< Enable Port 1 Interrupts >>>>
			bis.b   #BIT1+BIT2, &P1IE
			ret

;-------------------------------------------------------------------------------
; Nombre: Debouncing
; Objetivo: Eliminar rebotes mecanicos del boton.
; Precondiciones:
;	- S1 u S2 fueron presionados
; Postcondiciones:
; - Delay generado.
; - R15 termina en cero.

; Fecha: 29-mayo-2026
;-------------------------------------------------------------------------------
Debouncing:
			push	R15
			mov		#25000,R15
DebounceLoop:
			dec		R15
			jnz		DebounceLoop
			pop		R15
			ret

;-------------------------------------------------------------------------------
; Nombre: TIMER0_A0_ISR
; Objetivo: Procesar interrupciones del TIMER0_A0
; Precondiciones:
;	- El timer está habilitado para realizar interrupciones
; Postcondiciones:
; 	- Si el estado está en countdown(8), el R5 y el contador decrementarán
;	- Si R5 es 0, el temporizador se deshabilitará

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------

TIMER0_A0_ISR:
			bic     #CCIFG,&TA0CCTL0

checkCountdownTrigger:
			cmp		#8,R13
			jnz		InterruptFin
			call	#CountdownTrigger
			tst		R5
			jz		callDisableTimerInterrupt
			dec		R5
			jmp		InterruptFin

callDisableTimerInterrupt:
			call	#disableTimerInterrupt

InterruptFin:
			bic.w   #CPUOFF,0(SP)
            reti

;-------------------------------------------------------------------------------
; Nombre: disableTimerInterrupt
; Objetivo: Procesar interrupciones del TIMER0_A0
; Precondiciones:
;	- R5 es 0
; Postcondiciones:
;	- El temporizador se deshabilitará

; Fecha: 28-mayo-2026
;-------------------------------------------------------------------------------
disableTimerInterrupt:
			mov     #0, &TA0CCTL0
			ret




;-------------------------------------------------------------------------------
; STACK
;-------------------------------------------------------------------------------

            .global __STACK_END
            .sect   .stack

;-------------------------------------------------------------------------------
; INTERRUPT VECTORS
;-------------------------------------------------------------------------------

            .sect   ".int37"
            .short  PORT1_ISR

            .sect   ".int44"
            .short  TIMER0_A0_ISR

            .sect   ".reset"
            .short  RESET

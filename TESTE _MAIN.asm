;Sistemas Microprocessados 
;23/10/2020
;Autores: Leonardo Machado e Michelle Teles
;	
;MAPEAMENTO UNIDIMENSIONAL POR ULTRASSONS
;
;------SERVO MOTOR(PWM) e LCD --------
	D7	equ	p1.7
	D6	equ	p1.6
	D5	equ	p1.5
	D4	equ	p1.4
	RS	equ	P1.3
	RW	equ	P1.2
	E	equ	P1.1
	
	Echo 	equ 	p3.2
	Trig	equ	p2.7	
	P_Pulso equ	p2.0	
	ledWAR	equ	p2.1
	
;-----------Reset-----------
	ORG 	000h
	jmp 	inicio
	
inicio:
	SETB 	ECHO
	
	mov	P1,#000h
	acall	lcd_init
	mov 	P2,#000h 	  
	mov	TMOD,#00001001B   
	setb	TR0		  		; TR0 + gate =  1 -> controle pelo int0 

	MOV 	R7,#01H
	MOV 	R6,#01H
	MOV 	R5,#12H

	jmp 	PulsoPWM


;--------rotinas pwm ----------- 
;(pulso de 50Hz confome o controle do servo controle do servo)

pulsoPWM:	
	Clr	ledWar					
positivo:
	setb	P_Pulso
	MOV	r0,#0f9h	;0.5MS natural ativo
 	DJNZ	r0,$		;
 	
	MOV	B,R7
QUEBRADOS:
	CALL	delay0_056Ms		
	DJNZ	B,QUEBRADOS	

negativo:
	CLR	P_PULSO
	MOV	R0,#0FFH	;
	DJNZ	R0,$		;512US
	MOV	R0,#056H	;
	DJNZ	R0,$		;88US

	MOV	B,#11H		;
AUXn:
	CALL	DELAY1MS	;
	DJNZ	b,AUXn	;17MS

	MOV	b,R6
QUEBRADOS2:
	CALL	delay0_056Ms		
	DJNZ	b,QUEBRADOS2	

Verifica_pulso:
	inc 	R5
	CJNE	R5,#13H,auxPWM	
	SETB 	LEDWAR			;DESLIGA LED DO PWM
	call	encontraNovoNumero
	mov	R5,#00h
	jmp	pulsoPWM
auxPWM:					
	cjne	r5,#12h,POSITIVO
	clr	c
	mov	a,r6			;	
	subb	a,#04h			;tira 2ms aproximadamente
	jc	auxPWM1			;tem tempos em que não vai poder fazer uma subtração
	cjne	a,#00h,soPassa	
	inc	acc
soPassa:	
	mov	R6,acc			;compensa o find
auxPWM1:
	jmp	POSITIVO


;--------------------------------------					
encontraNovoNumero:
	call	POSITION
	call	StartPlay
	call 	MostraLCD
	mov 	acc,R7
	
configPWM:
	mov	b,#05h			
	div	ab			

	mov	r7,#05h				;POSIÇÕES INICIAIS (-65GRAUS)
	mov	r6,#1Dh
	mov	R0,#00h
Define_angulo:
	cjne   a,#00h,loop_pegaOgrau
	jmp	fimNV
loop_pegaOgrau:
	inc 	R7
	DEC	R6
	inc	R0
	cjne	R0,#019h,continua		;Pode ter 25 variações de grau
	jmp 	fimnv
continua:
	DJNZ	ACC,LOOP_PEGAOGRAU
fimNV:		
	ret	
	
;--------------------------------------										
StartPlay:
	mov 	th0,#00h
	mov	Tl0,#00h			;prepara timer para contagem
	
	setb 	trig 
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	clr	trig
	
	jnb	echo,$			;
	jb	echo,$			;espera todo o pulso do echo
	
	mov	r7,#00h			;fica com um total momentaneo 
	mov	r5,#00h			;fica com o resto momentaneo
operando:
	mov	B,#3Ah			
	mov	a,tl0			;pega o byte inferior do timer
	div	ab			;divide por 58, a recebe a parte inteira e b o resto
	add 	a,r7			;a = a + r7(parte inteira ja divida)
	mov	r7,a			;adiciona o valor de divisão a r7(acumula todo a parte inteira no r7)
	mov	a,b
	add	a,r5
	mov	r5,a			;acumula o resto em r5
	mov	r6,th0
	CJNE	r6,#00h,recarrega	;Se th nao for 0 ele vai para recarrega
	mov	b,#3Ah			;B = 58 decimal 
	mov	a,r5			;a pega o byte resto total
	div	ab			;divide por 58, a recebe a parte inteira e b o resto
	add 	a,r7			;a = a + r7(parte inteira ja divida)
	CJNE	a,#00h,verifica_dois
	jmp	retoma
verifica_dois:
	CJNE	a,#01h,reforma
	jmp	retoma
reforma:
	subb	a,#01h			;ajusta ao erro do sensor de 1 cm 
	MOV 	R7,ACC	
retoma:
	
	ret
recarrega:
	mov	tl0,#0ffh		;Recarrega
	djnz	TH0,operando		
	jmp	operando		;Para o caso de o valor de th0 ter o valor 1 ira decrementar e passa do "djnz"


;---------------------------------------
lcd_init:
	acall	delay15ms
	acall	delay15ms
	setb	D4	
	setb	D5
	clr	D6
	clr	D7	;0011
	setb	E
	nop	

	clr	E

	acall	delay15ms
	setb	D4	
	setb	D5
	clr	D6
	clr	D7	;0011
	setb	E
	nop	

	clr	E

	acall	delay15ms
	setb	D4	
	setb	D5
	clr	D6
	clr	D7	;0011
	setb	E
	nop	

	clr	E

	acall	delay15ms
	clr	D4	
	setb	D5
	clr	D6
	clr	D7	;0010
	setb	E
	nop	

	clr	E
	;----------------------
	
	mov	a,#28h			;funcion					
	acall	Send_Inst

	mov	a,#06h			;entrymode
	acall	Send_inst

	acall	DisplayON

	acall	clear

	CALL	ESCREVETABELA
	MOV	A,#'0'
	ACALL 	SEND_DATA
	MOV	A,#'0'
	ACALL 	SEND_DATA
	MOV	A,#'0'
	ACALL 	SEND_DATA
	RET
;---------------------------------------
Send_Data:
	PUSH	ACC
	push	B
	CALL	busy_check
	pop	B
	POP	ACC
	clr	RW
	setb	RS
	call	swapBitsEnvio
	ret
;---------------------------------------
Send_Inst:
	PUSH	ACC
	push	B
	CALL	busy_check
	pop	B
	POP	ACC
	clr	RW
	clr	RS
	call	swapBitsEnvio
	ret
;---------------------------------------
Busy_Check:
	setb	RW
	clr	RS
	acall	aux
	RLC	A
	MOV	B.7,c
	RLC	A
	MOV	B.6,c
	RLC	A
	MOV	B.5,c
	RLC	A
	MOV	B.4,c
	acall	aux
	RLC	A
	MOV	B.3,c
	RLC	A
	MOV	B.2,c
	RLC	A
	MOV	B.1,c
	RLC	A
	MOV	B.0,c
	MOV 	A,B
	jb	ACC.7,Busy_Check	
	RET
aux:
	setb	D7
	setb	D6
	setb	D5
	setb	D4
	setb	E
	nop
	mov	A,P1
	clr	E	
	ret
;---------------------------------------	
swapBitsEnvio:
	CALL	AUXSWAP
	CALL	AUXSWAP	
	RET
AUXSWAP:
	RLC	A
	mov 	D7,C
	RLC  	A
	mov 	D6,C
	RLC  	A
	mov 	D5,C
	RLC  	A
	mov 	D4,C
	setb	E
	nop
	clr	E
	ret
;---------------------------------------
displayON:
	mov	a,#0Fh		
	acall	SEND_INST
	RET
;---------------------------------------
clear:
	mov	a,#01h		
	acall	SEND_INST
	ret
;---------------------------------------
MostraLCD:
	mov	b,#64h		;100decimal
	div 	ab
	add 	a,#30h
	call 	SEND_DATA	
	
	mov	a,b
	mov 	b,#0Ah		;10dec
	div	ab
	add 	a,#30h
	call    SEND_DATA
	
	mov	a,b
	add 	a,#30h
	call  	SEND_DATA

	ret
;-----------------------------------------------
Position:	
	MOV	B,#00001100B	
	push	acc
	mov	a,b
	jnb	a.7,Line1
Line2:
	clr	acc.7
	add	a,#3fh		;soma o valor da coluna com o ultimo valor da linha 1
	setb	acc.7
	ajmp	column
Line1:
	subb	a,#00000001b
	setb	a.7
Column:
	acall	Send_Inst
	pop	acc
	ret
;-----------------------------------------------
escreveTabela:
	PUSH	ACC
	mov 	dptr,#WORDS
auxt:
	MOV	A,#00H
	MOVC	A,@A+dptr
	Cjne	A,#00h,envia
	jmp 	fimET
envia:
	acall	send_data
	inc	dptr
	MOV	A,#00H
	jmp	auxt
fimET:	
	pop	ACC
	ret
;-----------------------------------------------	
delay0_056Ms:					;subtrai dois alem do total por causa do jmp no complemente
	mov	R0,#18h
	djnz	R0,$
	ret
;-----------------------------------------------
delay1ms:		;2
	mov	R0,#0F8h	;2
	djnz	R0,$	;248*2
	mov	R0,#0F8h ;2
	djnz	R0,$	;248*2	
	ret		;2
			;1000 us = 1 ms
;-----------------------------------------------
delay15ms:		;2
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	ret
;-----------------------------------------------
WORDS:
	db 'DISTANCIA: ',00H
;-----------------------------------------------
	end



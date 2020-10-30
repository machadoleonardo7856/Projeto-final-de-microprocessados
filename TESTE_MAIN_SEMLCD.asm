;a cada 0.111MS tempo de pulso ativo a mais ou a menos variamos 10 graos 
;a cada 0.056Ms	tempo de pulso ativo a mais ou a menos variamos 5 graos 	

;------SERVO MOTOR(PWM) e sensor --------
	
	Echo 	equ 	p3.2
	Trig	equ	p2.7	;saidas
	P_Pulso equ	p2.0	
	ledWAR	equ	p2.1
	
;-----------Reset-----------
	ORG 	000h
	jmp 	inicio
	
inicio:
	setb 	echo
	mov	P1,#000h
	mov 	P2,#000h 	  ;define como saida de dados
	mov	TMOD,#00001001B   ; configura o TIMER0 pra contar enquanto o int0 for a 1(timer 16 bit contado com a freq. do uc)
	setb	TR0		  ; TR0 + gate =  1 -> controle pelo int0 

	MOV 	R7,#01H
	MOV 	R6,#01H
	MOV 	R5,#12H
	jmp 	PulsoPWM


;--------rotinas pwm ----------- (pulso de 50Hz confome o controle do servo controle do servo)
;tempo de Ms (IMPORTANTE :O comando djnz decrementa e depois faz o teste, então se coloca o numero de vezes de ciclo mais 1) 
 
pulsoPWM:	
	Clr	ledWar		;inicio do pulso			
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
	SETB 	LEDWAR		;DESLIGA LED DO PWM
	call	encontraNovoNumero
	mov	R5,#00h
	jmp	pulsoPWM
auxPWM:					;compensa o tempo de find
	cjne	r5,#12h,POSITIVO
	clr	c
	mov	a,r6			;	
	subb	a,#04h			;tira 2ms aproximadamente
	jc	auxPWM1			; tem tempos em que não vai poder fazer uma subtração
	cjne	a,#00h,soPassa	
	inc	acc
soPassa:	
	mov	R6,acc			;compensa o find
auxPWM1:
	jmp	POSITIVO


;O reigistrador recebe (1+ a quantidade de vezes desejada)
encontraNovoNumero:
	call	StartPlay
	mov 	acc,R7
	
configPWM:
	mov	b,#05h				;Qual a variação de cm altera/90 graus/5?= 18/ 1ms ativo varia 90graus o grau zero
	div	ab									       ;começa em 0.5 ms ativo, div 1 por 18 

	mov	r7,#05h				;POSIÇÕES INICIAIS (25GRAUS)
	mov	r6,#1Dh
	mov	R0,#00h
Define_angulo:
	cjne   a,#00h,loop_pegaOgrau
	jmp	fimNV
loop_pegaOgrau:
	inc 	R7
	DEC	R6
	inc	R0
	cjne	R0,#019h,continua		;pode ter 26 variações de grau
	jmp 	fimnv
continua:
	DJNZ	ACC,LOOP_PEGAOGRAU
fimNV:		
	ret				;|880uc fixos mais valor variavel(1858ucStart play max + espera de 400uc) de 2258uc
					;| valor ser a descontado = fixo mais a media do variavel 2ms
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
	mov	B,#3Ah			;B = 58 decimal 
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
	subb	a,#02h			;ajusta ao erro do sensor de 2 cm 
	MOV 	R7,ACC	
retoma:
	mov	c,acc.2
	mov	p3.7,c
	mov	c,acc.1
	mov	p3.6,c
	mov	c,acc.0
	mov	p3.5,c
	ret
recarrega:
	mov	tl0,#0ffh		;recarrega
	djnz	TH0,operando		;decrementa th0 
	jmp	operando		; para o caso de o valor de th0 ter o valor 1 ira decrementar e passa do "djnz"


;---------------------------------------
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




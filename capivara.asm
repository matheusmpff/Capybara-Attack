; ------- TABELA DE CORES -------
; adicione ao caracter para Selecionar a cor correspondente

; 0 branco							0000 0000
; 256 marrom						0001 0000
; 512 verde							0010 0000
; 768 oliva							0011 0000
; 1024 azul marinho						0100 0000
; 1280 roxo							0101 0000
; 1536 teal							0110 0000
; 1792 prata						0111 0000
; 2048 cinza						1000 0000
; 2304 vermelho						1001 0000
; 2560 lima							1010 0000
; 2816 amarelo						1011 0000
; 3072 azul							1100 0000
; 3328 rosa							1101 0000
; 3584 aqua							1110 0000
; 3840 branco						1111 0000

jmp main


numCharLine: var #1
	static numCharLine + #0, #40

numCharColumn: var #1
	static numCharColumn + #0, #30

startMsg: string "Aperte ENTER para comecar"

msgErr: string "Ocorreu um erro"

playerPosX: var #1
	static playerPosX + #0, #20
playerPosY: var #1
	static playerPosY + #0, #15

; PARA TODOS OS PERSONAGENS: dir -> left = 1 ; right = 0 ;

playerDir: var #1


; quando a posicao eh 100, capivara nao esta viva ainda
capivarasPosX: var #5
	static capivarasPosX + #0, #100
	static capivarasPosX + #1, #100
	static capivarasPosX + #2, #100
	static capivarasPosX + #3, #100
	static capivarasPosX + #4, #100
capivarasPosY: var #5
	static capivarasPosY + #0, #100
	static capivarasPosY + #1, #100
	static capivarasPosY + #2, #100
	static capivarasPosY + #3, #100
	static capivarasPosY + #4, #100

capivarasDir: var #5


main:
	call apagaTela
	call waitUserStart

	call apagaTela
	call movePlayerPrint

resetTimer:
	loadn r7, #0 ; timer global

	playerControlLoop:


		; apenas move o jogador a cada 50 loops
		loadn r0, #100
		mod r0, r7, r0
		cmp r7, r0
		jne skipPlayer

		call movePlayer

		load r0, playerPosX
		loadn r1, #0
		cmp r0, r1
		jeq endGame

	skipPlayer:

	; capivara spawn

	loadn r0, #49999
	cmp r7, r0
	jne skipCapivaraSpawn

	call capivaraSpawn

	skipCapivaraSpawn:

	; reseta o timer global
	inc r7
	loadn r0, #50000
	cmp r7, r0
	jeq resetTimer

	jmp playerControlLoop



	endGame:
	halt

;--


apagaTela:
	push r0
	push r1
	push r2

	loadn r0, #0
	loadn r1, #1200
	loadn r2, #' '
	apagaTelaLoop:
		outchar r2, r0
		inc r0
		cmp r0, r1
		jne apagaTelaLoop

	pop r2
	pop r1
	pop r0
	rts


;--


waitUserStart:
	push r0
	push r1

	loadn r1, #startMsg	; mensagem
	loadn r0, #968		; posicao da tela
	loadn r2, #0
	call printStr

	loadn r1, #13 ; tecla ENTER
	waitUserStartLoop:
		call nextInputKey ; r0 recebe a proxima tecla do usuario
		cmp r0, r1
		jne waitUserStartLoop

	pop r1
	pop r0
	rts


;--


printStr: ; r0 = posicao na tela ; r1 = ponteiro pra string ; r2 = cor
	push r0
	push r1
	push r2
	push r3
	push r4

	loadn r3, #0 ; parada
	printStrLoop:
		loadi r4, r1 ; agora r4 eh o caracter para imprimir
		cmp r4, r3
		jeq printStrEnd
		add r4, r4, r2 ; r4 = caracter mais cor
		outchar r4, r0
		inc r0
		inc r1
		jmp printStrLoop

	printStrEnd:
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts


;--


nextInputKey: ; retorna a tecla em r0
	push r1

	loadn r1, #255 ; oque entra no buffer do teclado quando nada eh apertado
	nextInputKeyLoop:
		inchar r0
		cmp r0, r1
		jeq nextInputKeyLoop

	pop r1
	rts


;--


movePlayer: ;recebe o input do jogador e move o personagem
	push r0
	push r1
	push r2
	push r3
	push r4
	push r5

	
	inchar r0 ; r0 = input

	; os playerMove<Dir> nao devem usar r4 e r5
	load r4, playerPosX
	load r5, playerPosY

	; switch entre w a s d
	loadn r1, #'a'
	cmp r0, r1
	jeq playerMoveLeft
	loadn r1, #'s'
	cmp r0, r1
	jeq playerMoveDown
	loadn r1, #'d'
	cmp r0, r1
	jeq playerMoveRight
	loadn r1, #'w'
	cmp r0, r1
	jeq playerMoveUp
	; se nao apertou nenhum, fica parado
	jmp playerMoveNoMove

	movePlayerBreak: ; se entrou em alguma funcao do switch, sai aqui

	mov r0, r4
	mov r1, r5
	; apagaQuadrado r0->Y e r1->Y
	call apagaQuadrado
	call movePlayerPrint

playerMoveNoMove:
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts
	

	playerMoveUp:
		load r2, playerPosY
		loadn r0, #0
		cmp r2, r0
		jeq movePlayerBreak

		dec r2
		store playerPosY, r2
		jmp movePlayerBreak

	playerMoveDown:
		load r2, playerPosY
		inc r2
		load r0, numCharColumn
		dec r0
		cmp r2, r0
		jeq movePlayerBreak

		store playerPosY, r2
		jmp movePlayerBreak

	playerMoveLeft:
		load r2, playerPosX
		loadn r0, #0
		cmp r2, r0
		jeq movePlayerBreak

		dec r2
		store playerPosX, r2
		loadn r2, #0 ; dir right = 0
		store playerDir, r2
		jmp movePlayerBreak

	playerMoveRight:
		load r2, playerPosX
		inc r2
		load r0, numCharLine
		dec r0
		cmp r2, r0
		jeq movePlayerBreak

		store playerPosX, r2
		loadn r2, #1 ; dir left = 1
		store playerDir, r2
		jmp movePlayerBreak


movePlayerPrint: 
	load r0, playerPosX
	load r1, playerPosY
	load r2, playerDir

	load r3, numCharLine
	mul r1, r1, r3 ; num de pixels para mover na vertical
	add r0, r0, r1 ; posicao absoluta do jogador

	loadn r1, #257 ; capivara + marrom

	loadn r4, #4
	; se a direcao for right (0), nao muda
	; se a direcao for left (1), soma 4 ao char
	mul r4, r4, r2
	add r1, r1, r4

	outchar r1, r0

	; imprime superior direito
	inc r0
	inc r1
	outchar r1, r0

	; imprime inferior direito
	add r0, r0, r3
	inc r1
	inc r1
	outchar r1, r0

	; imprime inferior esquerdo
	dec r0
	dec r1
	outchar r1, r0

	rts
;--


; recebe em r0 e r1 as coordenadas x e y do primeiro
; char (superior esquerdo) e apaga os quatro chars do bloco
apagaQuadrado:
	push r0
	push r1
	push r2

	load r2, numCharLine
	mul r1, r1, r2 ; num de pixels para mover na vertical
	add r0, r0, r1 ; posicao absoluta do char

	; apaga superior esquerdo
	loadn r1, #' '
	outchar r1, r0

	; apaga superior direito
	inc r0
	outchar r1, r0

	; apaga inferior direito
	add r0, r0, r2
	outchar r1, r0

	; apaga inferior esquerdo
	dec r0
	outchar r1, r0

	pop r2
	pop r1
	pop r0
	rts
;--


printErrHalt: ; Printa uma msg de erro no meio da tela e para o programa
	loadn r1, #590
	load r0, msgErr
	loadn r2, #0
	call printStr
	halt

;--


capivaraSpawn:
	push r0
	push r1
	push r2
	push r3
	push r4
	push r5

	loadn r0, #0 ; int i do for lop
	loadn r2, #capivarasPosX ; array das capivaras
	loadn r5, #100 ; capivara para spawnar (100 == nenhuma)

capivaraSpawnTryNext:
	add r3, r2, r0 ; capivara[i]
	loadi r3, r3 ; r3 = capivara[i]

	cmp r3, r5
	jne capiSpawnTnElse
	; se capivara[i] eh 100, ela deve spawnar
	mov r5, r0
	jmp capiSpawnTnexit


capiSpawnTnElse:
	loadn r1, #4
	cmp r0, r1
	inc r0
	jle capivaraSpawnTryNext

capiSpawnTnExit:

	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts

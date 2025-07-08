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

morteMsg: string "Voce morreu. Aperte ENTER para recomecar"

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

iniciarJogo:
	call initializeVariables
	call apagaTela
	call movePlayerPrint

resetTimer:
	loadn r7, #0 ; timer global

controlLoop:

	; apenas move o jogador a cada 100 loops

	loadn r0, #100
	mod r0, r7, r0
	loadn r1, #0
	cmp r1, r0
	jne skipPlayer

	call movePlayer

	call colisaoMorte

skipPlayer:


	; capivara move a cada 400 loops

	loadn r0, #1000
	mod r0, r7, r0
	loadn r1, #0
	cmp r1, r0
	jne skipCapivara

	call moveCapivaras
	
	call colisaoMorte

skipCapivara:

	; capivara spawn

	loadn r0, #20000
	cmp r7, r0
	jne skipCapivaraSpawn

	call capivaraSpawn

	skipCapivaraSpawn:

	; reseta o timer global
	inc r7
	loadn r0, #50000
	cmp r7, r0
	jeq resetTimer

	; pausa para deixar o programa mais lento
	loadn r0, #0
	loadn r1, #5000
	slowDownLoop:
		inc r0
		cmp r0, r1
		jne slowDownLoop


	jmp controlLoop



	endGame:

	call waitUserStart ; recebe em r0 o input

	loadn r1, #'e' ; exit
	cmp r0, r1
	jne iniciarJogo

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


;; reinicializa as posições de memória com os valores iniciais delas
initializeVariables:
	loadn r0, #20
	store playerPosX, r0
	loadn r0, #15
	store playerPosY, r0

	loadn r0, #0 ; i - iterador
	loadn r1, #5
	loadn r2, #capivarasPosX
	loadn r3, #capivarasPosY
	loadn r6, #100 ; valor inicial das posições das capivaras

	capivaraInitializeLoop:
		cmp r0, r1 ; while i < 5
		jeq initializeExit

		add r4, r2, r0 ; capivarasPosX[i]
		add r5, r3, r0 ; capivarasPosY[i]
		storei r4, r6 ; capiPosX[i] = 100
		storei r5, r6 ; capiPosY[i] = 100

		inc r0 ; i++
		jmp capivaraInitializeLoop
	initializeExit:
	rts
;--


;; espera o usuario digitar ENTER ou 'e' para iniciar ou parar o jogo
;; retorna em r0 o input
waitUserStart:
	push r1
	push r2

	loadn r1, #startMsg	; mensagem
	loadn r0, #968		; posicao da tela
	loadn r2, #0
	call printStr

	loadn r1, #13 ; tecla ENTER
	loadn r2, #'e' ; exit
	waitUserStartLoop:
		call nextInputKey ; r0 recebe a proxima tecla do usuario
		cmp r0, r1
		jeq waitUserStartExit
		cmp r0, r2
		jne waitUserStartLoop

	waitUserStartExit:
	pop r2
	pop r1
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
		loadn r2, #1 ; dir right = 1
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
		loadn r2, #0 ; dir left = 0
		store playerDir, r2
		jmp movePlayerBreak


movePlayerPrint: 
	load r0, playerPosX
	load r1, playerPosY
	load r2, playerDir
	loadn r3, #3081 ; cacador + azul

	call printPersonagem
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
	loadn r1, #4
	loadn r2, #capivarasPosX ; array das capivaras
	loadn r3, #capivarasPosY
	loadn r4, #100 ; capivara para spawnar (100 == nenhuma)

	capivaraSpawnTryNext:
		add r5, r2, r0 ; capivara[i]
		loadi r5, r5 ; r5 = capivara[i]

		cmp r5, r4
		jne capiSpawnTnElse
		; se capivara[i] eh 100, ela deve spawnar
		jmp capiSpawnTnExit


	capiSpawnTnElse:
		cmp r0, r1 ; compara i com 4
		inc r0
		jle capivaraSpawnTryNext

		jmp capiSpawnExit

	capiSpawnTnExit:

		; endereco para guardar a pos da capivara a ser spawnada
		add r2, r2, r0 ; capivarasPosX[i]
		add r3, r3, r0 ; capivarasPosY[i]
		loadn r5, #capivarasDir
		add r5, r5, r0

		; switch da capivara
		cmp r0, r1
		jeq spawn4
		loadn r1, #3
		cmp r0, r1
		jeq spawn3
		loadn r1, #2
		cmp r0, r1
		jeq spawn2
		loadn r1, #1
		cmp r0, r1
		jeq spawn1
		loadn r1, #0
		cmp r0, r1
		jeq spawn0

		; execucao nao deve chegar aqui
		call printErrHalt

	spawn4:
		loadn r0, #12
		load r1, numCharColumn
		dec r1
		dec r1
		storei r2, r0
		storei r3, r1
		loadn r2, #0 ; direção
		storei r2, r5
		jmp capiSpawnBreak

	spawn3:
		loadn r0, #28
		load r1, numCharColumn
		dec r1
		dec r1
		storei r2, r0
		storei r3, r1
		loadn r2, #1 ; direção
		storei r2, r5
		jmp capiSpawnBreak

	spawn2:
		load r0, numCharLine
		dec r0
		dec r0
		loadn r1, #15
		storei r2, r0
		storei r3, r1
		loadn r2, #1 ; direção
		storei r2, r5
		jmp capiSpawnBreak

	spawn1:
		loadn r0, #20
		loadn r1, #0
		storei r2, r0
		storei r3, r1
		loadn r2, #0 ; direção
		storei r2, r5
		jmp capiSpawnBreak

	spawn0:
		loadn r0, #0
		loadn r1, #15
		dec r1
		storei r2, r0
		storei r3, r1
		loadn r2, #0 ; direção
		storei r2, r5
		jmp capiSpawnBreak

	capiSpawnBreak:
		loadn r3, #257 ; capivara marrom
		call printPersonagem

capiSpawnExit:
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts



; printa um quadrado de caracteres
; são quatro caracteres seguidos em que o primeiro é o superior esquerdo
; o segundo é o superior direito, terceiro é inferior esq. e 4rto é inf. dir.
; além disso, há mais quatro char após eles para a outra direção
; r0 = posX ; r1 = posY ; r2 = dir ; r3 = primeiro caracter
printPersonagem: 
	push r0
	push r1
	push r2
	push r3
	push r4

	load r4, numCharLine
	mul r1, r1, r4 ; num de pixels para mover na vertical
	add r0, r0, r1 ; posicao absoluta do jogador


	loadn r1, #4
	; se a direcao for right (0), nao muda
	; se a direcao for left (1), soma 4 ao char
	mul r1, r1, r2
	add r3, r3, r1

	outchar r3, r0

	; imprime superior direito
	inc r0
	inc r3
	outchar r3, r0

	; imprime inferior direito
	add r0, r0, r4
	inc r3
	inc r3
	outchar r3, r0

	; imprime inferior esquerdo
	dec r0
	dec r3
	outchar r3, r0

	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts
;--


colisaoMorte:
	push r0
	push r1
	push r2
	push r3
	push r4
	push r5

	loadn r0, #0 ; i - iterador
	loadn r1, #5 ; numero de capivaras
	load r2, playerPosX
	load r3, playerPosY

	loopColisaoMorte:
		cmp r0, r1 ; while i < 5
		jeq exitColisaoMorte

		loadn r4, #capivarasPosX
		loadn r5, #capivarasPosY
		add r4, r4, r0
		add r5, r5, r0
		loadi r4, r4 ; r4 = capivarasPosX[i]
		loadi r5, r5 ; r5 = capivarasPosY[i]

		; teste das colisoes
		; testando se um dos Ys é igual
		inc r5
		cmp r3, r5 ; lado de baixo da capivara com de cima do homem
		dec r5
		jeq colisaoMorteTestaX
		cmp r3, r5 ; um no meio do outro na coordenada Y
		jeq colisaoMorteTestaX
		inc r3
		cmp r3, r5 ; lado de cima da capivara com de baixo do homem
		dec r3
		jeq colisaoMorteTestaX

		jmp continueLoopColisaoMorte

	colisaoMorteTestaX:
		cmp r2, r4 ; um no meio do outro na coordenada X
		jeq colisaoMatar
		inc r2
		cmp r2, r4 ; lado esquerdo da capivara com direito do homem
		dec r2
		jeq colisaoMatar
		inc r4
		cmp r2, r4 ; lado direito da capivara com esquerdo do homem
		dec r4
		jeq colisaoMatar


	continueLoopColisaoMorte:
		inc r0 ; i++
		jmp loopColisaoMorte

	exitColisaoMorte:

	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts

colisaoMatar:
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	
	call apagaTela
	loadn r0, #968 ; posicao na tela
	loadn r1, #morteMsg ; string
	loadn r2, #2304 ; cor
	call printStr
	jmp endGame

;--


moveCapivaras:
	push r0
	push r1
	push r2
	push r3
	push r4

	loadn r0, #0 ; i
	loadn r1, #4 ; numero de capivaras - 1
	loadn r2, #100 ; valor nulo da capivara
	loadn r3, #capivarasPosX

	; para todas as capivaras, se ela existir, move ela
	moveCapiLoop:
		add r4, r3, r0 ; capivarasPosX[i]
		loadi r4, r4 ; r4 =
		cmp r4, r2 ; if capi == 100 ; pula
		jeq moveCapiLoopContinue

		; passo para a função r0 = i, o número da capivara
		call moveSingleCapi

	moveCapiLoopContinue:
		cmp r0, r1 ; while i < 5
		inc r0
		jne moveCapiLoop

	
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts

; r0 = número da capivara
moveSingleCapi:
	push r0
	push r1
	push r2
	push r3
	push r4
	push r5

	mov r5, r0
	loadn r0, #capivarasPosX
	add r0, r0, r5
	loadi r0, r0; r0 = posX
	loadn r1, #capivarasPosY
	add r1, r1, r5
	loadi r1, r1 ; r1 = posY
	call apagaQuadrado
	mov r0, r5

	loadn r1, #capivarasPosX
	loadn r4, #capivarasDir

	add r1, r0, r1 ; r1 = &capiPosX[i]
	loadi r2, r1 ; r2 = capivarasPosX[i]

	add r4, r4, r0 ; r4 = &capiDir[i]
	loadi r5, r4 ; r5 = capiDir[i]
	
	load r3, playerPosX
	
	cmp r2, r3
	jle capiMoverDireita ; se capiPosX < playerPosX
	jeq capiXParado ; se capiPosX == playerPosX

	; se capi PosX > playerPosX, mover esquerda
	dec r2
	storei r1, r2 ; capiPosX[i]--

	loadn r1, #1
	storei r4, r1 ; dir esquerda
	jmp capiXParado

capiMoverDireita:
	inc r2
	storei r1, r2 ; capiPosX[i]++

	loadn r1, #0
	storei r4, r1

capiXParado:
	
	; mover em Y
	loadn r1, #capivarasPosY
	add r1, r0, r1 ; &capivarasPosY[i]
	loadi r2, r1 ; capiPosY[i]

	load r3, playerPosY

	cmp r2, r3
	jle capiMoverBaixo
	jeq capiYParado

	;mover cima
	dec r2
	storei r1, r2
	jmp capiYParado

capiMoverBaixo:
	inc r2
	storei r1, r2

capiYParado:
	
	mov r1, r2 ; r1 = posY
	loadn r2, #capivarasDir
	add r2, r2, r0
	loadi r2, r2 ; r2 = dir
	loadn r3, #capivarasPosX
	add r3, r3, r0
	loadi r0, r3; r0 = posX
	loadn r3, #257 ; r3 = primeiro caractere = capivara marrom

	call printPersonagem

	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts	
;--

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

teclaApertada: var #1
	
tiroPosX: var #1
	static tiroPosX + #0, #100

tiroPosY: var #1
	static tiroPosY + #0, #100

tiroDir: var #1

posicaoMaca: var #1
	static posicaoMaca + #0, #0

pontuacao: var #1

velocidadeLoop: var #1
	static velocidadeLoop + #0, #2000

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
	call printtelaComecoScreen
	call waitUserStart

iniciarJogo:
	call apagaTela
	call movePlayerPrint

resetTimer:
	loadn r7, #0 ; timer global

controlLoop:

	; lidar com o movimento do tiro
	loadn r0, #20
	mod r0, r7, r0
	loadn r1, #0
	cmp r1, r0
	jne skipTiro

	call moveTiro

skipTiro:

	; apenas move o jogador a cada 100 loops

	loadn r0, #40
	mod r0, r7, r0
	loadn r1, #0
	cmp r1, r0
	jne skipPlayer

	call inputFPGA ; retorna em r0 o input
	store teclaApertada, r0

	; aumentar ou diminuir a velocidade do jogo
	loadn r1, #'+'
	cmp r0, r1
	jeq velocidadePlus
	loadn r1, #'-'
	cmp r0, r1
	jeq velocidadeMinus

	; testa se realiza tiro ou movimento do personagem
	loadn r1, #32
	cmp r0, r1
	jne movimentoMonstruoso

		; se a tecla é espaço, da o tiro
		call gerarTiro
		jmp skipPlayer

	movimentoMonstruoso:

		call movePlayer
		call colisaoMorte

		jmp skipPlayer

	velocidadePlus:
		; diminui a variável velocidadeLoop por 500
		load r2, velocidadeLoop
		loadn r3, #500

		cmp r2, r3 ; se velocidade já é 500, não diminui mais
		jeq skipPlayer
		sub r2, r2, r3
		store velocidadeLoop, r2

		jmp skipPlayer

	velocidadeMinus:
		; aumenta a variável velocidadeLoop por 500
		load r2, velocidadeLoop
		loadn r3, #500
		add r2, r2, r3
		store velocidadeLoop, r2


skipPlayer:

	; capivara move a cada 608 loops

	loadn r0, #608
	mod r0, r7, r0
	loadn r1, #0
	cmp r1, r0
	jne skipCapivara

	call moveCapivaras
	
	call colisaoMorte

skipCapivara:

	; capivara spawn

	loadn r0, #4100
	mod r0, r7, r0
	loadn r1, #0
	cmp r1, r0
	jne skipCapivaraSpawn

	call capivaraSpawn

skipCapivaraSpawn:

	call gerarMaca
	call pegarMaca


	; pausa para deixar o programa mais lento
	loadn r0, #0
	load r1, velocidadeLoop
	slowDownLoop:
		inc r0
		cmp r0, r1
		jne slowDownLoop

	; reseta o timer global
	inc r7
	loadn r0, #50000
	cmp r7, r0
	jeq resetTimer

	jmp controlLoop



endGame:
	call printTelaFinalScreen
	call mostrarPontuacao
	call initializeVariables
	call waitUserStart ; recebe em r0 o input

	loadn r1, #'e' ; exit
	cmp r0, r1
	jne iniciarJogo

	halt
;--


inputFPGA:
	push r1
	push r2

	inchar r1
	mov r0, r1

	loadn r2, #255
inputFPGALoop:
	inchar r1
	cmp r1, r2
	jne inputFPGALoop

	pop r2
	pop r1
	rts
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

	
	load r0, teclaApertada ; r0 = input
	loadn r1, #255
	store teclaApertada, r1 ; da clear no input da memoria

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
	nop
	nop
	nop
	nop
	nop
	nop

	; apaga superior direito
	inc r0
	outchar r1, r0
	nop
	nop
	nop
	nop
	nop
	nop

	; apaga inferior direito
	add r0, r0, r2
	outchar r1, r0
	nop
	nop
	nop
	nop
	nop
	nop

	; apaga inferior esquerdo
	dec r0
	outchar r1, r0
	nop
	nop

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
	nop
	nop
	nop
	nop
	nop
	nop

	; imprime superior direito
	inc r0
	inc r3
	outchar r3, r0
	nop
	nop
	nop
	nop
	nop
	nop

	; imprime inferior direito
	add r0, r0, r4
	inc r3
	inc r3
	outchar r3, r0
	nop
	nop
	nop
	nop
	nop
	nop

	; imprime inferior esquerdo
	dec r0
	dec r3
	outchar r3, r0
	nop
	nop

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
		cmp r3, r5
		jeq colisaoMorteTestaX
		inc r3
		cmp r3, r5 ; lado de cima da capivara com de baixo do homem
		dec r3
		jeq colisaoMorteTestaX

		jmp continueLoopColisaoMorte

	colisaoMorteTestaX:
		inc r2
		cmp r2, r4 ; lado esquerdo da capivara com direito do homem
		dec r2
		jeq colisaoMatar
		cmp r2, r4
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
	push r6
	push r7


	loadn r1, #capivarasPosX ; const
	loadn r2, #capivarasPosY ; const

	add r3, r1, r0
	add r4, r2, r0

	loadi r3, r3; r3 = capivarasPosX[i]
	loadi r4, r4 ; r4 = capivarasPosY[i]

	mov r6, r0
	mov r7, r1
	mov r0, r3 ; r0 = posX
	mov r1, r4 ; r1 = posY

	call apagaQuadrado
	mov r0, r6
	mov r1, r7

	; novo x previsto
	loadn r6, #capivarasDir
	add r6, r6, r0 ; r6 = &capiDir[i]

	load r5, playerPosX
	cmp r3, r5
	jle moveSCapiDireita
	jeq moveSCapiXParado

	; tenta mover esquerda
	dec r3
	loadn r7, #1 ; direcao esquerda
	storei r6, r7
	jmp moveSCapiXParado

moveSCapiDireita:

	; tenta mover direita
	inc r3
	loadn r7, #0 ; direcao direita
	storei r6, r7

moveSCapiXParado:

	; testando colisao em X
	; r3 = novo capiPosX[i]
	; r4 = capiPosY[i]

	; só pode colidir se já estiver no mesmo Y
	loadn r5, #0 ; r5 = j
	loadn r6, #5
	colisaoXCapi:
		cmp r5, r0 ; nao pode analisar a capivara consigo mesma
		jeq colisaoXCapiContinue

		add r7, r2, r5
		loadi r7, r7 ; capiPosY[j]
		
		inc r7
		cmp r4, r7
		dec r7
		jeq podeColidirNoX
		cmp r4, r7
		jeq podeColidirNoX
		inc r4
		cmp r4, r7
		dec r4
		jne colisaoXCapiContinue

	podeColidirNoX:
		add r7, r1, r5
		loadi r7, r7 ; capiPosX[j]

		inc r3
		cmp r3, r7
		dec r3
		jeq colideNoX
		inc r7
		cmp r3, r7
		dec r7
		jne colisaoXCapiContinue

	colideNoX:
		add r3, r1, r0
		loadi r3, r3 ; r3 = posX original
		loadn r5, #4 ; break para sair do loop
		

	colisaoXCapiContinue:
		inc r5
		cmp r5, r6 ; while r5 != 5
		jne colisaoXCapi

	;saiu do loop

	; novo y previsto

	load r5, playerPosY
	cmp r4, r5
	jle moveSCapiBaixo
	jeq moveSCapiYParado

	; tenta mover cima
	dec r4
	jmp moveSCapiYParado

moveSCapiBaixo:

	;tenta mover baixo
	inc r4

moveSCapiYParado:

	; testando colisao em Y
	; r3 = capiPosX[i]
	; r4 = novo capiPosY[i]

	; só pode colidir se já estiver no mesmo X
	loadn r5, #0 ; r5 = j
	loadn r6, #5
	colisaoYCapi:
		cmp r5, r0 ; nao pode analisar a capivara consigo mesma
		jeq colisaoYCapiContinue

		add r7, r1, r5
		loadi r7, r7 ; capiPosX[j]
		
		inc r7
		cmp r3, r7
		dec r7
		jeq podeColidirNoY
		cmp r3, r7
		jeq podeColidirNoY
		inc r3
		cmp r3, r7
		dec r3
		jne colisaoYCapiContinue

	podeColidirNoY:
		add r7, r2, r5
		loadi r7, r7 ; capiPosY[j]

		inc r4
		cmp r4, r7
		dec r4
		jeq colideNoY
		inc r7
		cmp r4, r7
		dec r7
		jne colisaoYCapiContinue

	colideNoY:
		add r4, r2, r0
		loadi r4, r4 ; r4 = posY original
		loadn r5, #4 ; break para sair do loop

	colisaoYCapiContinue:
		inc r5
		cmp r5, r6 ; while r5 != 5
		jne colisaoYCapi

	;saiu do loop

	; atualiza as posições
	add r1, r1, r0 ; &posX[i]
	add r2, r2, r0 ; &posY[i]
	storei r1, r3
	storei r2, r4

	loadn r7, #capivarasDir
	add r7, r7, r0
	loadi r7, r7

	mov r0, r3 ; r0 = posX
	mov r1, r4 ; r1 = posY
	mov r2, r7 ; r2 = dir
	loadn r3, #257 ; r3 = capivara marrom
	call printPersonagem


	pop r7
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts
;--

gerarTiro:
	push r0
	push r1
	push r2
	push r3
	
	load r0, playerPosX
	load r1, playerPosY
	load r2, playerDir

	loadn r3, #1
	cmp r2, r3
	jeq gerarTiroDireita

		dec r0
		loadn r2, #1
		jmp gerarTiroEsquerda
	
	gerarTiroDireita:
		inc r0 ; aparecer o tiro a esquerda
		inc r0
		loadn r2, #0
	
gerarTiroEsquerda:

	; guardar na memoria a pos do tiro
	store tiroPosX, r0
	store tiroPosY, r1
	store tiroDir, r2
	
	; calcular posicao absoluta do tiro
	load r3, numCharLine
	mul r1, r1, r3 ; num de pixels para mover na vertical
	add r0, r0, r1 ; posicao absoluta do tiro

	; printar bala
	loadn r1, #2073 ; tiro cinza
	outchar r1, r0

	pop r3
	pop r2
	pop r1
	pop r0
	rts
;--


moveTiro:
	push r0
	push r1
	push r2
	push r3
	push r4

	load r0, tiroPosX
	load r1, tiroPosY
	load r2, tiroDir

	; se tiro nao exite, n faz nada
	loadn r4, #100
	cmp r0, r4
	jeq moveTiroExit

	load r3, numCharLine
	mul r3, r1, r3
	add r3, r0, r3 ; r3 = posicao absoluta da bala

	loadn r4, #0
	outchar r4, r3 ; apagar a bala

	; r4 = direcao direita
	cmp r2, r4
	jeq moveBulletRight


	; mover a bala para a esquerda

	cmp r0, r4 ; r4 == 0
	jne moveBulletLeft

	; se a bala já esta na esquerda, apaga ela
	loadn r0, #100
	jmp moveBulletRightSkip

moveBulletLeft:

	dec r0 ; muda posicao para a esquerda
	dec r3 ; posicao absoluta

	jmp moveBulletRightSkip

moveBulletRight:

	load r4, numCharLine
	dec r4
	cmp r0, r4
	jne tiroMoveDireita

	; se o tiro ja esta na direita, apaga ela
	loadn r0, #100
	jmp moveBulletRightSkip

tiroMoveDireita:

	inc r0 ; muda posicao para a direita
	inc r3 ; posicao absoluta

moveBulletRightSkip:

	store tiroPosX, r0

	loadn r4, #100
	cmp r0, r4
	jeq moveTiroExit

	; logica para matar as capivaras
	call morteCapivara

	loadn r4, #100
	load r0, tiroPosX
	cmp r0, r4
	jeq moveTiroExit

	; se o tiro ainda existe, printa ele
	loadn r1, #2073 ; tiro cinza
	outchar r1, r3

moveTiroExit:
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts
;--



gerarMaca:
	push r1
	push r2
	push r3
	push r4
	
	
	; logica para aparecer a maca
	loadn r3, #0
	loadn r1, #2011
	mod r1, r7, r1
	
	cmp r1,r3
	jne gerarMacaFim
	;apaga a maca 
	load r2, posicaoMaca
	loadn r4, #2000
	cmp r2, r4
	jeq semApagar
	outchar r3,r2;

semApagar:

	; logica de mostrar a maca 
	loadn r3,#1200;numero de bytes para achar a posicao de gerar a maca
	mod r4,r7,r3
	
	store posicaoMaca, r4; atualiza a posicao da maca
	
	loadn r3,#2328 ;char da maca	
	outchar r3,r4

gerarMacaFim:

	pop r4
	pop r3
	pop r2 
	pop r1
	
	rts


pegarMaca:
	push r1
	push r2
	push r3
	push r4
		
	load r1, pontuacao
	;posicao absoluta do player que sera em r2
	load r2, playerPosX
	load r3, playerPosY
	loadn r4, #40
	mul r3,r3,r4
	add r2,r2,r3
	;comparacao com a posicao da maca
	load r4, posicaoMaca
	cmp r2, r4
	jeq pegarMacaSim
	load r3, numCharLine
	add r2,r2,r3
	cmp r2, r4
	jeq pegarMacaSim
	inc r2
	cmp r2, r4
	jeq pegarMacaSim
	sub r2,r2,r3
	cmp r2, r4
	jeq pegarMacaSim
	pegarMacaFim:
	pop r4
	pop r3
	pop r2
	pop r1
	rts
	
	pegarMacaSim:
	;logica de aumentar a pontuacao
	loadn r4, #10
	add r1,r1,r4
	store pontuacao, r1
	;Logica para apagar a maca daquela posicao
	outchar r1,r4
	loadn r4, #2000
	store posicaoMaca,r4
	jmp pegarMacaFim

;--


morteCapivara:
	push r0
	push r1
	push r2
	push r3
	push r4
	push r5
	push r6
	push r7

	load r0, tiroPosX
	load r1, tiroPosY

	loadn r2, #capivarasPosX
	loadn r3, #capivarasPosY

	loadn r4, #0 ; i - iterador

morteCapiLoop:
	add r5, r2, r4
	loadi r5, r5 ; r5 = capPosX[i]

	cmp r0, r5
	jeq talvezAcertarCapivara

	inc r5
	cmp r0, r5 ; x do tiro com lado direito da capi
	jne morteCapiContinue

talvezAcertarCapivara:
	add r5, r3, r4
	loadi r5, r5 ; r5 = capPosY[i]

	cmp r1, r5
	jeq matarCapivara
	
	inc r5
	cmp r1, r5
	jne morteCapiContinue

matarCapivara:

	; matar capivara
	loadn r5, #100
	store tiroPosX, r5
	
	load r6, numCharLine
	mul r6, r1, r6
	add r6, r6, r0 ; r6 = posicao absoluta do tiro
	loadn r7, #0
	outchar r7, r6 ; apaga tiro

	add r2, r2, r4 ; &capPosX[i]
	add r3, r3, r4 ; &capPosY[i]
	loadi r0, r2 ; r0 = posX
	loadi r1, r3 ; r1 = posY

	call apagaQuadrado

	loadn r5, #100
	storei r2, r5
	storei r3, r5

	jmp morteCapiBreak

morteCapiContinue:
	inc r4
	loadn r5, #5
	cmp r4, r5
	jne morteCapiLoop

morteCapiBreak:

	pop r7
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts
;--


mostrarPontuacao:
	push r1
	push r2
	push r3 
	push r4
	push r5
	push r6
	
	loadn r6,#741
	loadn r5,#745
	load r1, pontuacao
	loadn r4, #'0'
	loadn r2, #10
	
	mod r3,r1,r2
	Mostrarnumero:
	add	r3,r3,r4
	outchar r3,r5
	dec r5
	
	div r1, r1, r2
	mod r3,r1,r2	
	cmp r5,r6
	jne Mostrarnumero
	
	pop r6
	pop r5
	pop r4 
	pop r3
	pop r2
	pop r1
	rts
	
TelaFinal : var #1200
  ;Linha 0
  static TelaFinal + #0, #3967
  static TelaFinal + #1, #3967
  static TelaFinal + #2, #3967
  static TelaFinal + #3, #3967
  static TelaFinal + #4, #3967
  static TelaFinal + #5, #3967
  static TelaFinal + #6, #3967
  static TelaFinal + #7, #3967
  static TelaFinal + #8, #3967
  static TelaFinal + #9, #3967
  static TelaFinal + #10, #3967
  static TelaFinal + #11, #3967
  static TelaFinal + #12, #3967
  static TelaFinal + #13, #3967
  static TelaFinal + #14, #3967
  static TelaFinal + #15, #3967
  static TelaFinal + #16, #3967
  static TelaFinal + #17, #3967
  static TelaFinal + #18, #3967
  static TelaFinal + #19, #3967
  static TelaFinal + #20, #3967
  static TelaFinal + #21, #3967
  static TelaFinal + #22, #3967
  static TelaFinal + #23, #3967
  static TelaFinal + #24, #3967
  static TelaFinal + #25, #3967
  static TelaFinal + #26, #3967
  static TelaFinal + #27, #3967
  static TelaFinal + #28, #3967
  static TelaFinal + #29, #3967
  static TelaFinal + #30, #3967
  static TelaFinal + #31, #3967
  static TelaFinal + #32, #3967
  static TelaFinal + #33, #3967
  static TelaFinal + #34, #3967
  static TelaFinal + #35, #3967
  static TelaFinal + #36, #3967
  static TelaFinal + #37, #3967
  static TelaFinal + #38, #3967
  static TelaFinal + #39, #3967

  ;Linha 1
  static TelaFinal + #40, #3967
  static TelaFinal + #41, #3967
  static TelaFinal + #42, #3967
  static TelaFinal + #43, #3967
  static TelaFinal + #44, #3967
  static TelaFinal + #45, #3967
  static TelaFinal + #46, #3967
  static TelaFinal + #47, #3967
  static TelaFinal + #48, #3967
  static TelaFinal + #49, #3967
  static TelaFinal + #50, #3967
  static TelaFinal + #51, #3967
  static TelaFinal + #52, #3967
  static TelaFinal + #53, #3967
  static TelaFinal + #54, #3967
  static TelaFinal + #55, #3967
  static TelaFinal + #56, #3967
  static TelaFinal + #57, #3967
  static TelaFinal + #58, #3967
  static TelaFinal + #59, #3967
  static TelaFinal + #60, #3967
  static TelaFinal + #61, #3967
  static TelaFinal + #62, #3967
  static TelaFinal + #63, #3967
  static TelaFinal + #64, #3967
  static TelaFinal + #65, #3967
  static TelaFinal + #66, #3967
  static TelaFinal + #67, #3967
  static TelaFinal + #68, #3967
  static TelaFinal + #69, #3967
  static TelaFinal + #70, #3967
  static TelaFinal + #71, #3967
  static TelaFinal + #72, #3967
  static TelaFinal + #73, #3967
  static TelaFinal + #74, #3967
  static TelaFinal + #75, #3967
  static TelaFinal + #76, #3967
  static TelaFinal + #77, #3967
  static TelaFinal + #78, #3967
  static TelaFinal + #79, #3967

  ;Linha 2
  static TelaFinal + #80, #3967
  static TelaFinal + #81, #3967
  static TelaFinal + #82, #3967
  static TelaFinal + #83, #3967
  static TelaFinal + #84, #3967
  static TelaFinal + #85, #3967
  static TelaFinal + #86, #3967
  static TelaFinal + #87, #3967
  static TelaFinal + #88, #3967
  static TelaFinal + #89, #3967
  static TelaFinal + #90, #3967
  static TelaFinal + #91, #3967
  static TelaFinal + #92, #3967
  static TelaFinal + #93, #3967
  static TelaFinal + #94, #3967
  static TelaFinal + #95, #3967
  static TelaFinal + #96, #3967
  static TelaFinal + #97, #3967
  static TelaFinal + #98, #3967
  static TelaFinal + #99, #3967
  static TelaFinal + #100, #3967
  static TelaFinal + #101, #3967
  static TelaFinal + #102, #3967
  static TelaFinal + #103, #3967
  static TelaFinal + #104, #3967
  static TelaFinal + #105, #3967
  static TelaFinal + #106, #3967
  static TelaFinal + #107, #3967
  static TelaFinal + #108, #3967
  static TelaFinal + #109, #3967
  static TelaFinal + #110, #3967
  static TelaFinal + #111, #3967
  static TelaFinal + #112, #3967
  static TelaFinal + #113, #3967
  static TelaFinal + #114, #3967
  static TelaFinal + #115, #3967
  static TelaFinal + #116, #3967
  static TelaFinal + #117, #3967
  static TelaFinal + #118, #3967
  static TelaFinal + #119, #3967

  ;Linha 3
  static TelaFinal + #120, #3967
  static TelaFinal + #121, #3967
  static TelaFinal + #122, #3967
  static TelaFinal + #123, #3967
  static TelaFinal + #124, #3967
  static TelaFinal + #125, #3967
  static TelaFinal + #126, #3967
  static TelaFinal + #127, #3967
  static TelaFinal + #128, #3967
  static TelaFinal + #129, #3967
  static TelaFinal + #130, #3967
  static TelaFinal + #131, #3967
  static TelaFinal + #132, #3967
  static TelaFinal + #133, #3967
  static TelaFinal + #134, #3967
  static TelaFinal + #135, #3967
  static TelaFinal + #136, #3967
  static TelaFinal + #137, #3967
  static TelaFinal + #138, #3967
  static TelaFinal + #139, #3967
  static TelaFinal + #140, #3967
  static TelaFinal + #141, #3967
  static TelaFinal + #142, #3967
  static TelaFinal + #143, #3967
  static TelaFinal + #144, #3967
  static TelaFinal + #145, #3967
  static TelaFinal + #146, #3967
  static TelaFinal + #147, #3967
  static TelaFinal + #148, #3967
  static TelaFinal + #149, #3967
  static TelaFinal + #150, #3967
  static TelaFinal + #151, #3967
  static TelaFinal + #152, #3967
  static TelaFinal + #153, #3967
  static TelaFinal + #154, #3967
  static TelaFinal + #155, #3967
  static TelaFinal + #156, #3967
  static TelaFinal + #157, #3967
  static TelaFinal + #158, #3967
  static TelaFinal + #159, #3967

  ;Linha 4
  static TelaFinal + #160, #3967
  static TelaFinal + #161, #3967
  static TelaFinal + #162, #3967
  static TelaFinal + #163, #3967
  static TelaFinal + #164, #3967
  static TelaFinal + #165, #3967
  static TelaFinal + #166, #3967
  static TelaFinal + #167, #3967
  static TelaFinal + #168, #3967
  static TelaFinal + #169, #3967
  static TelaFinal + #170, #3967
  static TelaFinal + #171, #3967
  static TelaFinal + #172, #3967
  static TelaFinal + #173, #3967
  static TelaFinal + #174, #3967
  static TelaFinal + #175, #3967
  static TelaFinal + #176, #3967
  static TelaFinal + #177, #3967
  static TelaFinal + #178, #3967
  static TelaFinal + #179, #3967
  static TelaFinal + #180, #3967
  static TelaFinal + #181, #3967
  static TelaFinal + #182, #3967
  static TelaFinal + #183, #3967
  static TelaFinal + #184, #3967
  static TelaFinal + #185, #3967
  static TelaFinal + #186, #3967
  static TelaFinal + #187, #3967
  static TelaFinal + #188, #3967
  static TelaFinal + #189, #3967
  static TelaFinal + #190, #3967
  static TelaFinal + #191, #3967
  static TelaFinal + #192, #3967
  static TelaFinal + #193, #3967
  static TelaFinal + #194, #3967
  static TelaFinal + #195, #3967
  static TelaFinal + #196, #3967
  static TelaFinal + #197, #3967
  static TelaFinal + #198, #3967
  static TelaFinal + #199, #3967

  ;Linha 5
  static TelaFinal + #200, #3967
  static TelaFinal + #201, #3967
  static TelaFinal + #202, #3967
  static TelaFinal + #203, #3967
  static TelaFinal + #204, #3967
  static TelaFinal + #205, #3967
  static TelaFinal + #206, #3967
  static TelaFinal + #207, #3967
  static TelaFinal + #208, #3967
  static TelaFinal + #209, #3967
  static TelaFinal + #210, #3967
  static TelaFinal + #211, #3967
  static TelaFinal + #212, #3967
  static TelaFinal + #213, #3967
  static TelaFinal + #214, #3967
  static TelaFinal + #215, #3967
  static TelaFinal + #216, #3967
  static TelaFinal + #217, #3967
  static TelaFinal + #218, #3967
  static TelaFinal + #219, #3967
  static TelaFinal + #220, #3967
  static TelaFinal + #221, #3967
  static TelaFinal + #222, #3967
  static TelaFinal + #223, #3967
  static TelaFinal + #224, #3967
  static TelaFinal + #225, #3967
  static TelaFinal + #226, #3967
  static TelaFinal + #227, #3967
  static TelaFinal + #228, #3967
  static TelaFinal + #229, #3967
  static TelaFinal + #230, #3967
  static TelaFinal + #231, #3967
  static TelaFinal + #232, #3967
  static TelaFinal + #233, #3967
  static TelaFinal + #234, #3967
  static TelaFinal + #235, #3967
  static TelaFinal + #236, #3967
  static TelaFinal + #237, #3967
  static TelaFinal + #238, #3967
  static TelaFinal + #239, #3967

  ;Linha 6
  static TelaFinal + #240, #3967
  static TelaFinal + #241, #3967
  static TelaFinal + #242, #3967
  static TelaFinal + #243, #3967
  static TelaFinal + #244, #3967
  static TelaFinal + #245, #3967
  static TelaFinal + #246, #3967
  static TelaFinal + #247, #3967
  static TelaFinal + #248, #3967
  static TelaFinal + #249, #3085
  static TelaFinal + #250, #3086
  static TelaFinal + #251, #3967
  static TelaFinal + #252, #3967
  static TelaFinal + #253, #3967
  static TelaFinal + #254, #3967
  static TelaFinal + #255, #3967
  static TelaFinal + #256, #3967
  static TelaFinal + #257, #261
  static TelaFinal + #258, #262
  static TelaFinal + #259, #257
  static TelaFinal + #260, #258
  static TelaFinal + #261, #3967
  static TelaFinal + #262, #3967
  static TelaFinal + #263, #3967
  static TelaFinal + #264, #3967
  static TelaFinal + #265, #3967
  static TelaFinal + #266, #3967
  static TelaFinal + #267, #3967
  static TelaFinal + #268, #3081
  static TelaFinal + #269, #3082
  static TelaFinal + #270, #3967
  static TelaFinal + #271, #3967
  static TelaFinal + #272, #3967
  static TelaFinal + #273, #3967
  static TelaFinal + #274, #3967
  static TelaFinal + #275, #3967
  static TelaFinal + #276, #3967
  static TelaFinal + #277, #3967
  static TelaFinal + #278, #3967
  static TelaFinal + #279, #3967

  ;Linha 7
  static TelaFinal + #280, #3967
  static TelaFinal + #281, #3967
  static TelaFinal + #282, #3967
  static TelaFinal + #283, #3967
  static TelaFinal + #284, #3967
  static TelaFinal + #285, #3967
  static TelaFinal + #286, #3967
  static TelaFinal + #287, #3967
  static TelaFinal + #288, #3967
  static TelaFinal + #289, #3087
  static TelaFinal + #290, #3088
  static TelaFinal + #291, #3967
  static TelaFinal + #292, #3967
  static TelaFinal + #293, #3967
  static TelaFinal + #294, #3967
  static TelaFinal + #295, #3967
  static TelaFinal + #296, #3967
  static TelaFinal + #297, #263
  static TelaFinal + #298, #264
  static TelaFinal + #299, #259
  static TelaFinal + #300, #260
  static TelaFinal + #301, #3967
  static TelaFinal + #302, #3967
  static TelaFinal + #303, #3967
  static TelaFinal + #304, #3967
  static TelaFinal + #305, #3967
  static TelaFinal + #306, #3967
  static TelaFinal + #307, #3967
  static TelaFinal + #308, #3083
  static TelaFinal + #309, #3084
  static TelaFinal + #310, #3967
  static TelaFinal + #311, #3967
  static TelaFinal + #312, #3967
  static TelaFinal + #313, #3967
  static TelaFinal + #314, #3967
  static TelaFinal + #315, #3967
  static TelaFinal + #316, #3967
  static TelaFinal + #317, #3967
  static TelaFinal + #318, #3967
  static TelaFinal + #319, #3967

  ;Linha 8
  static TelaFinal + #320, #3967
  static TelaFinal + #321, #3967
  static TelaFinal + #322, #3967
  static TelaFinal + #323, #3967
  static TelaFinal + #324, #3967
  static TelaFinal + #325, #3967
  static TelaFinal + #326, #3967
  static TelaFinal + #327, #3967
  static TelaFinal + #328, #3967
  static TelaFinal + #329, #273
  static TelaFinal + #330, #273
  static TelaFinal + #331, #273
  static TelaFinal + #332, #273
  static TelaFinal + #333, #273
  static TelaFinal + #334, #273
  static TelaFinal + #335, #3967
  static TelaFinal + #336, #3967
  static TelaFinal + #337, #273
  static TelaFinal + #338, #273
  static TelaFinal + #339, #273
  static TelaFinal + #340, #273
  static TelaFinal + #341, #3967
  static TelaFinal + #342, #3967
  static TelaFinal + #343, #273
  static TelaFinal + #344, #273
  static TelaFinal + #345, #3967
  static TelaFinal + #346, #3967
  static TelaFinal + #347, #3967
  static TelaFinal + #348, #273
  static TelaFinal + #349, #273
  static TelaFinal + #350, #3967
  static TelaFinal + #351, #3967
  static TelaFinal + #352, #3967
  static TelaFinal + #353, #3967
  static TelaFinal + #354, #3967
  static TelaFinal + #355, #3967
  static TelaFinal + #356, #3967
  static TelaFinal + #357, #3967
  static TelaFinal + #358, #3967
  static TelaFinal + #359, #3967

  ;Linha 9
  static TelaFinal + #360, #3967
  static TelaFinal + #361, #3967
  static TelaFinal + #362, #3967
  static TelaFinal + #363, #3967
  static TelaFinal + #364, #3967
  static TelaFinal + #365, #3967
  static TelaFinal + #366, #3967
  static TelaFinal + #367, #3967
  static TelaFinal + #368, #3967
  static TelaFinal + #369, #273
  static TelaFinal + #370, #273
  static TelaFinal + #371, #3967
  static TelaFinal + #372, #3967
  static TelaFinal + #373, #3967
  static TelaFinal + #374, #3967
  static TelaFinal + #375, #3967
  static TelaFinal + #376, #3967
  static TelaFinal + #377, #3967
  static TelaFinal + #378, #273
  static TelaFinal + #379, #273
  static TelaFinal + #380, #3967
  static TelaFinal + #381, #3967
  static TelaFinal + #382, #3967
  static TelaFinal + #383, #273
  static TelaFinal + #384, #273
  static TelaFinal + #385, #273
  static TelaFinal + #386, #3967
  static TelaFinal + #387, #273
  static TelaFinal + #388, #273
  static TelaFinal + #389, #273
  static TelaFinal + #390, #3967
  static TelaFinal + #391, #3967
  static TelaFinal + #392, #3967
  static TelaFinal + #393, #3967
  static TelaFinal + #394, #3967
  static TelaFinal + #395, #3967
  static TelaFinal + #396, #3967
  static TelaFinal + #397, #3967
  static TelaFinal + #398, #3967
  static TelaFinal + #399, #3967

  ;Linha 10
  static TelaFinal + #400, #3967
  static TelaFinal + #401, #3967
  static TelaFinal + #402, #3967
  static TelaFinal + #403, #3967
  static TelaFinal + #404, #3967
  static TelaFinal + #405, #3967
  static TelaFinal + #406, #3967
  static TelaFinal + #407, #3967
  static TelaFinal + #408, #3967
  static TelaFinal + #409, #273
  static TelaFinal + #410, #273
  static TelaFinal + #411, #3967
  static TelaFinal + #412, #3967
  static TelaFinal + #413, #3967
  static TelaFinal + #414, #3967
  static TelaFinal + #415, #3967
  static TelaFinal + #416, #3967
  static TelaFinal + #417, #3967
  static TelaFinal + #418, #273
  static TelaFinal + #419, #273
  static TelaFinal + #420, #3967
  static TelaFinal + #421, #3967
  static TelaFinal + #422, #3967
  static TelaFinal + #423, #273
  static TelaFinal + #424, #273
  static TelaFinal + #425, #273
  static TelaFinal + #426, #273
  static TelaFinal + #427, #273
  static TelaFinal + #428, #273
  static TelaFinal + #429, #273
  static TelaFinal + #430, #3967
  static TelaFinal + #431, #3967
  static TelaFinal + #432, #3967
  static TelaFinal + #433, #3967
  static TelaFinal + #434, #3967
  static TelaFinal + #435, #3967
  static TelaFinal + #436, #3967
  static TelaFinal + #437, #3967
  static TelaFinal + #438, #3967
  static TelaFinal + #439, #3967

  ;Linha 11
  static TelaFinal + #440, #3967
  static TelaFinal + #441, #3967
  static TelaFinal + #442, #3967
  static TelaFinal + #443, #3967
  static TelaFinal + #444, #3967
  static TelaFinal + #445, #3967
  static TelaFinal + #446, #3967
  static TelaFinal + #447, #3967
  static TelaFinal + #448, #3967
  static TelaFinal + #449, #273
  static TelaFinal + #450, #273
  static TelaFinal + #451, #273
  static TelaFinal + #452, #273
  static TelaFinal + #453, #273
  static TelaFinal + #454, #3967
  static TelaFinal + #455, #3967
  static TelaFinal + #456, #3967
  static TelaFinal + #457, #3967
  static TelaFinal + #458, #273
  static TelaFinal + #459, #273
  static TelaFinal + #460, #3967
  static TelaFinal + #461, #3967
  static TelaFinal + #462, #3967
  static TelaFinal + #463, #273
  static TelaFinal + #464, #273
  static TelaFinal + #465, #3967
  static TelaFinal + #466, #273
  static TelaFinal + #467, #3967
  static TelaFinal + #468, #273
  static TelaFinal + #469, #273
  static TelaFinal + #470, #3967
  static TelaFinal + #471, #3967
  static TelaFinal + #472, #3967
  static TelaFinal + #473, #3967
  static TelaFinal + #474, #3967
  static TelaFinal + #475, #3967
  static TelaFinal + #476, #3967
  static TelaFinal + #477, #3967
  static TelaFinal + #478, #3967
  static TelaFinal + #479, #3967

  ;Linha 12
  static TelaFinal + #480, #3967
  static TelaFinal + #481, #3967
  static TelaFinal + #482, #3967
  static TelaFinal + #483, #3967
  static TelaFinal + #484, #3967
  static TelaFinal + #485, #3967
  static TelaFinal + #486, #3967
  static TelaFinal + #487, #3967
  static TelaFinal + #488, #3967
  static TelaFinal + #489, #273
  static TelaFinal + #490, #273
  static TelaFinal + #491, #3967
  static TelaFinal + #492, #3967
  static TelaFinal + #493, #3967
  static TelaFinal + #494, #3967
  static TelaFinal + #495, #3967
  static TelaFinal + #496, #3967
  static TelaFinal + #497, #3967
  static TelaFinal + #498, #273
  static TelaFinal + #499, #273
  static TelaFinal + #500, #3967
  static TelaFinal + #501, #3967
  static TelaFinal + #502, #3967
  static TelaFinal + #503, #273
  static TelaFinal + #504, #273
  static TelaFinal + #505, #3967
  static TelaFinal + #506, #3967
  static TelaFinal + #507, #3967
  static TelaFinal + #508, #273
  static TelaFinal + #509, #273
  static TelaFinal + #510, #3967
  static TelaFinal + #511, #3967
  static TelaFinal + #512, #3967
  static TelaFinal + #513, #3967
  static TelaFinal + #514, #3967
  static TelaFinal + #515, #3967
  static TelaFinal + #516, #3967
  static TelaFinal + #517, #3967
  static TelaFinal + #518, #3967
  static TelaFinal + #519, #3967

  ;Linha 13
  static TelaFinal + #520, #3967
  static TelaFinal + #521, #3967
  static TelaFinal + #522, #3967
  static TelaFinal + #523, #3967
  static TelaFinal + #524, #3967
  static TelaFinal + #525, #3967
  static TelaFinal + #526, #3967
  static TelaFinal + #527, #3967
  static TelaFinal + #528, #3967
  static TelaFinal + #529, #273
  static TelaFinal + #530, #273
  static TelaFinal + #531, #3967
  static TelaFinal + #532, #3967
  static TelaFinal + #533, #3967
  static TelaFinal + #534, #3967
  static TelaFinal + #535, #3967
  static TelaFinal + #536, #3967
  static TelaFinal + #537, #3967
  static TelaFinal + #538, #273
  static TelaFinal + #539, #273
  static TelaFinal + #540, #3072
  static TelaFinal + #541, #3967
  static TelaFinal + #542, #3967
  static TelaFinal + #543, #273
  static TelaFinal + #544, #273
  static TelaFinal + #545, #3967
  static TelaFinal + #546, #3967
  static TelaFinal + #547, #3967
  static TelaFinal + #548, #273
  static TelaFinal + #549, #273
  static TelaFinal + #550, #3967
  static TelaFinal + #551, #3967
  static TelaFinal + #552, #3967
  static TelaFinal + #553, #3967
  static TelaFinal + #554, #3967
  static TelaFinal + #555, #3967
  static TelaFinal + #556, #3967
  static TelaFinal + #557, #3967
  static TelaFinal + #558, #3967
  static TelaFinal + #559, #3967

  ;Linha 14
  static TelaFinal + #560, #3967
  static TelaFinal + #561, #3967
  static TelaFinal + #562, #3967
  static TelaFinal + #563, #3967
  static TelaFinal + #564, #3967
  static TelaFinal + #565, #3967
  static TelaFinal + #566, #3967
  static TelaFinal + #567, #3967
  static TelaFinal + #568, #3967
  static TelaFinal + #569, #273
  static TelaFinal + #570, #273
  static TelaFinal + #571, #3967
  static TelaFinal + #572, #3967
  static TelaFinal + #573, #3967
  static TelaFinal + #574, #3967
  static TelaFinal + #575, #3967
  static TelaFinal + #576, #3967
  static TelaFinal + #577, #273
  static TelaFinal + #578, #273
  static TelaFinal + #579, #273
  static TelaFinal + #580, #273
  static TelaFinal + #581, #3967
  static TelaFinal + #582, #3967
  static TelaFinal + #583, #273
  static TelaFinal + #584, #273
  static TelaFinal + #585, #3967
  static TelaFinal + #586, #3967
  static TelaFinal + #587, #3967
  static TelaFinal + #588, #273
  static TelaFinal + #589, #273
  static TelaFinal + #590, #3967
  static TelaFinal + #591, #3967
  static TelaFinal + #592, #3967
  static TelaFinal + #593, #3967
  static TelaFinal + #594, #3967
  static TelaFinal + #595, #3967
  static TelaFinal + #596, #3967
  static TelaFinal + #597, #3967
  static TelaFinal + #598, #3967
  static TelaFinal + #599, #3967

  ;Linha 15
  static TelaFinal + #600, #3967
  static TelaFinal + #601, #3967
  static TelaFinal + #602, #3967
  static TelaFinal + #603, #3967
  static TelaFinal + #604, #3967
  static TelaFinal + #605, #3967
  static TelaFinal + #606, #3967
  static TelaFinal + #607, #3967
  static TelaFinal + #608, #3967
  static TelaFinal + #609, #3967
  static TelaFinal + #610, #3967
  static TelaFinal + #611, #3967
  static TelaFinal + #612, #3967
  static TelaFinal + #613, #3967
  static TelaFinal + #614, #3967
  static TelaFinal + #615, #3967
  static TelaFinal + #616, #3967
  static TelaFinal + #617, #3967
  static TelaFinal + #618, #3967
  static TelaFinal + #619, #3967
  static TelaFinal + #620, #3967
  static TelaFinal + #621, #3967
  static TelaFinal + #622, #3967
  static TelaFinal + #623, #3967
  static TelaFinal + #624, #3967
  static TelaFinal + #625, #3967
  static TelaFinal + #626, #3967
  static TelaFinal + #627, #3967
  static TelaFinal + #628, #3967
  static TelaFinal + #629, #3967
  static TelaFinal + #630, #3967
  static TelaFinal + #631, #3967
  static TelaFinal + #632, #3967
  static TelaFinal + #633, #3967
  static TelaFinal + #634, #3967
  static TelaFinal + #635, #3967
  static TelaFinal + #636, #3967
  static TelaFinal + #637, #3967
  static TelaFinal + #638, #3967
  static TelaFinal + #639, #3967

  ;Linha 16
  static TelaFinal + #640, #3967
  static TelaFinal + #641, #3967
  static TelaFinal + #642, #3967
  static TelaFinal + #643, #3967
  static TelaFinal + #644, #3967
  static TelaFinal + #645, #3967
  static TelaFinal + #646, #3967
  static TelaFinal + #647, #3967
  static TelaFinal + #648, #3967
  static TelaFinal + #649, #3967
  static TelaFinal + #650, #3967
  static TelaFinal + #651, #3967
  static TelaFinal + #652, #3967
  static TelaFinal + #653, #3967
  static TelaFinal + #654, #3967
  static TelaFinal + #655, #3967
  static TelaFinal + #656, #3967
  static TelaFinal + #657, #3967
  static TelaFinal + #658, #3967
  static TelaFinal + #659, #3967
  static TelaFinal + #660, #3967
  static TelaFinal + #661, #3967
  static TelaFinal + #662, #3967
  static TelaFinal + #663, #3967
  static TelaFinal + #664, #3967
  static TelaFinal + #665, #3967
  static TelaFinal + #666, #3967
  static TelaFinal + #667, #3967
  static TelaFinal + #668, #3967
  static TelaFinal + #669, #3967
  static TelaFinal + #670, #3967
  static TelaFinal + #671, #3967
  static TelaFinal + #672, #3967
  static TelaFinal + #673, #3967
  static TelaFinal + #674, #3967
  static TelaFinal + #675, #3967
  static TelaFinal + #676, #3967
  static TelaFinal + #677, #3967
  static TelaFinal + #678, #3967
  static TelaFinal + #679, #3967

  ;Linha 17
  static TelaFinal + #680, #3967
  static TelaFinal + #681, #3967
  static TelaFinal + #682, #3967
  static TelaFinal + #683, #3967
  static TelaFinal + #684, #3967
  static TelaFinal + #685, #3967
  static TelaFinal + #686, #3967
  static TelaFinal + #687, #3967
  static TelaFinal + #688, #3967
  static TelaFinal + #689, #3967
  static TelaFinal + #690, #3967
  static TelaFinal + #691, #3967
  static TelaFinal + #692, #3967
  static TelaFinal + #693, #3967
  static TelaFinal + #694, #3967
  static TelaFinal + #695, #3967
  static TelaFinal + #696, #3967
  static TelaFinal + #697, #3967
  static TelaFinal + #698, #3967
  static TelaFinal + #699, #3967
  static TelaFinal + #700, #3967
  static TelaFinal + #701, #3967
  static TelaFinal + #702, #3967
  static TelaFinal + #703, #3967
  static TelaFinal + #704, #3967
  static TelaFinal + #705, #3967
  static TelaFinal + #706, #3967
  static TelaFinal + #707, #3967
  static TelaFinal + #708, #3967
  static TelaFinal + #709, #3967
  static TelaFinal + #710, #3967
  static TelaFinal + #711, #3967
  static TelaFinal + #712, #3967
  static TelaFinal + #713, #3967
  static TelaFinal + #714, #3967
  static TelaFinal + #715, #3967
  static TelaFinal + #716, #3967
  static TelaFinal + #717, #3967
  static TelaFinal + #718, #3967
  static TelaFinal + #719, #3967

  ;Linha 18
  static TelaFinal + #720, #3967
  static TelaFinal + #721, #3967
  static TelaFinal + #722, #3967
  static TelaFinal + #723, #3967
  static TelaFinal + #724, #3967
  static TelaFinal + #725, #3967
  static TelaFinal + #726, #3967
  static TelaFinal + #727, #3967
  static TelaFinal + #728, #3967
  static TelaFinal + #729, #3967
  static TelaFinal + #730, #3967
  static TelaFinal + #731, #3967
  static TelaFinal + #732, #0
  static TelaFinal + #733, #0
  static TelaFinal + #734, #83
  static TelaFinal + #735, #67
  static TelaFinal + #736, #79
  static TelaFinal + #737, #82
  static TelaFinal + #738, #69
  static TelaFinal + #739, #58
  static TelaFinal + #740, #3967
  static TelaFinal + #741, #3967
  static TelaFinal + #742, #3967
  static TelaFinal + #743, #3967
  static TelaFinal + #744, #3967
  static TelaFinal + #745, #3967
  static TelaFinal + #746, #3967
  static TelaFinal + #747, #3967
  static TelaFinal + #748, #3967
  static TelaFinal + #749, #3967
  static TelaFinal + #750, #3967
  static TelaFinal + #751, #3967
  static TelaFinal + #752, #3967
  static TelaFinal + #753, #3967
  static TelaFinal + #754, #3967
  static TelaFinal + #755, #3967
  static TelaFinal + #756, #3967
  static TelaFinal + #757, #3967
  static TelaFinal + #758, #3967
  static TelaFinal + #759, #3967

  ;Linha 19
  static TelaFinal + #760, #3967
  static TelaFinal + #761, #3967
  static TelaFinal + #762, #3967
  static TelaFinal + #763, #3967
  static TelaFinal + #764, #3967
  static TelaFinal + #765, #3967
  static TelaFinal + #766, #3967
  static TelaFinal + #767, #3967
  static TelaFinal + #768, #3967
  static TelaFinal + #769, #3967
  static TelaFinal + #770, #3967
  static TelaFinal + #771, #3967
  static TelaFinal + #772, #3967
  static TelaFinal + #773, #3967
  static TelaFinal + #774, #3967
  static TelaFinal + #775, #3967
  static TelaFinal + #776, #3967
  static TelaFinal + #777, #3967
  static TelaFinal + #778, #3967
  static TelaFinal + #779, #3967
  static TelaFinal + #780, #3967
  static TelaFinal + #781, #3967
  static TelaFinal + #782, #3967
  static TelaFinal + #783, #3967
  static TelaFinal + #784, #3967
  static TelaFinal + #785, #3967
  static TelaFinal + #786, #3967
  static TelaFinal + #787, #3967
  static TelaFinal + #788, #3967
  static TelaFinal + #789, #3967
  static TelaFinal + #790, #3967
  static TelaFinal + #791, #3967
  static TelaFinal + #792, #3967
  static TelaFinal + #793, #3967
  static TelaFinal + #794, #3967
  static TelaFinal + #795, #3967
  static TelaFinal + #796, #3967
  static TelaFinal + #797, #3967
  static TelaFinal + #798, #3967
  static TelaFinal + #799, #3967

  ;Linha 20
  static TelaFinal + #800, #3967
  static TelaFinal + #801, #3967
  static TelaFinal + #802, #3967
  static TelaFinal + #803, #3967
  static TelaFinal + #804, #3967
  static TelaFinal + #805, #3967
  static TelaFinal + #806, #3967
  static TelaFinal + #807, #3967
  static TelaFinal + #808, #3967
  static TelaFinal + #809, #3967
  static TelaFinal + #810, #3967
  static TelaFinal + #811, #3967
  static TelaFinal + #812, #3967
  static TelaFinal + #813, #3967
  static TelaFinal + #814, #3967
  static TelaFinal + #815, #3967
  static TelaFinal + #816, #3967
  static TelaFinal + #817, #3967
  static TelaFinal + #818, #3967
  static TelaFinal + #819, #3967
  static TelaFinal + #820, #3967
  static TelaFinal + #821, #3967
  static TelaFinal + #822, #3967
  static TelaFinal + #823, #3967
  static TelaFinal + #824, #3967
  static TelaFinal + #825, #3967
  static TelaFinal + #826, #3967
  static TelaFinal + #827, #3967
  static TelaFinal + #828, #3967
  static TelaFinal + #829, #3967
  static TelaFinal + #830, #3967
  static TelaFinal + #831, #3967
  static TelaFinal + #832, #3967
  static TelaFinal + #833, #3967
  static TelaFinal + #834, #3967
  static TelaFinal + #835, #3967
  static TelaFinal + #836, #3967
  static TelaFinal + #837, #3967
  static TelaFinal + #838, #3967
  static TelaFinal + #839, #3967

  ;Linha 21
  static TelaFinal + #840, #3967
  static TelaFinal + #841, #3967
  static TelaFinal + #842, #3967
  static TelaFinal + #843, #3967
  static TelaFinal + #844, #3967
  static TelaFinal + #845, #3967
  static TelaFinal + #846, #3967
  static TelaFinal + #847, #3967
  static TelaFinal + #848, #3967
  static TelaFinal + #849, #3967
  static TelaFinal + #850, #3967
  static TelaFinal + #851, #3967
  static TelaFinal + #852, #3967
  static TelaFinal + #853, #3967
  static TelaFinal + #854, #3967
  static TelaFinal + #855, #3967
  static TelaFinal + #856, #3967
  static TelaFinal + #857, #3967
  static TelaFinal + #858, #3967
  static TelaFinal + #859, #3967
  static TelaFinal + #860, #3967
  static TelaFinal + #861, #3967
  static TelaFinal + #862, #3967
  static TelaFinal + #863, #3967
  static TelaFinal + #864, #3967
  static TelaFinal + #865, #3967
  static TelaFinal + #866, #3967
  static TelaFinal + #867, #3967
  static TelaFinal + #868, #3967
  static TelaFinal + #869, #3967
  static TelaFinal + #870, #3967
  static TelaFinal + #871, #3967
  static TelaFinal + #872, #3967
  static TelaFinal + #873, #3967
  static TelaFinal + #874, #3967
  static TelaFinal + #875, #3967
  static TelaFinal + #876, #3967
  static TelaFinal + #877, #3967
  static TelaFinal + #878, #3967
  static TelaFinal + #879, #3967

  ;Linha 22
  static TelaFinal + #880, #3967
  static TelaFinal + #881, #3967
  static TelaFinal + #882, #3967
  static TelaFinal + #883, #3967
  static TelaFinal + #884, #3967
  static TelaFinal + #885, #3967
  static TelaFinal + #886, #3967
  static TelaFinal + #887, #3967
  static TelaFinal + #888, #3967
  static TelaFinal + #889, #3967
  static TelaFinal + #890, #3967
  static TelaFinal + #891, #3967
  static TelaFinal + #892, #3967
  static TelaFinal + #893, #3967
  static TelaFinal + #894, #3967
  static TelaFinal + #895, #3967
  static TelaFinal + #896, #3967
  static TelaFinal + #897, #3967
  static TelaFinal + #898, #3967
  static TelaFinal + #899, #3967
  static TelaFinal + #900, #3967
  static TelaFinal + #901, #3967
  static TelaFinal + #902, #3967
  static TelaFinal + #903, #3967
  static TelaFinal + #904, #3967
  static TelaFinal + #905, #3967
  static TelaFinal + #906, #3967
  static TelaFinal + #907, #3967
  static TelaFinal + #908, #3967
  static TelaFinal + #909, #3967
  static TelaFinal + #910, #3967
  static TelaFinal + #911, #3967
  static TelaFinal + #912, #3967
  static TelaFinal + #913, #3967
  static TelaFinal + #914, #3967
  static TelaFinal + #915, #3967
  static TelaFinal + #916, #3967
  static TelaFinal + #917, #3967
  static TelaFinal + #918, #3967
  static TelaFinal + #919, #3967

  ;Linha 23
  static TelaFinal + #920, #3967
  static TelaFinal + #921, #3967
  static TelaFinal + #922, #3967
  static TelaFinal + #923, #3967
  static TelaFinal + #924, #3967
  static TelaFinal + #925, #3967
  static TelaFinal + #926, #3967
  static TelaFinal + #927, #3967
  static TelaFinal + #928, #3967
  static TelaFinal + #929, #3967
  static TelaFinal + #930, #3967
  static TelaFinal + #931, #3967
  static TelaFinal + #932, #3967
  static TelaFinal + #933, #3967
  static TelaFinal + #934, #3967
  static TelaFinal + #935, #3967
  static TelaFinal + #936, #3967
  static TelaFinal + #937, #3967
  static TelaFinal + #938, #3967
  static TelaFinal + #939, #3967
  static TelaFinal + #940, #3967
  static TelaFinal + #941, #3967
  static TelaFinal + #942, #3967
  static TelaFinal + #943, #3967
  static TelaFinal + #944, #3967
  static TelaFinal + #945, #3967
  static TelaFinal + #946, #3967
  static TelaFinal + #947, #3967
  static TelaFinal + #948, #3967
  static TelaFinal + #949, #3967
  static TelaFinal + #950, #3967
  static TelaFinal + #951, #3967
  static TelaFinal + #952, #3967
  static TelaFinal + #953, #3967
  static TelaFinal + #954, #3967
  static TelaFinal + #955, #3967
  static TelaFinal + #956, #3967
  static TelaFinal + #957, #3967
  static TelaFinal + #958, #3967
  static TelaFinal + #959, #3967

  ;Linha 24
  static TelaFinal + #960, #3967
  static TelaFinal + #961, #3967
  static TelaFinal + #962, #3967
  static TelaFinal + #963, #3967
  static TelaFinal + #964, #3967
  static TelaFinal + #965, #3967
  static TelaFinal + #966, #3967
  static TelaFinal + #967, #3967
  static TelaFinal + #968, #3967
  static TelaFinal + #969, #3967
  static TelaFinal + #970, #3967
  static TelaFinal + #971, #3967
  static TelaFinal + #972, #3967
  static TelaFinal + #973, #3967
  static TelaFinal + #974, #3967
  static TelaFinal + #975, #3967
  static TelaFinal + #976, #3967
  static TelaFinal + #977, #3967
  static TelaFinal + #978, #3967
  static TelaFinal + #979, #3967
  static TelaFinal + #980, #3967
  static TelaFinal + #981, #3967
  static TelaFinal + #982, #3967
  static TelaFinal + #983, #3967
  static TelaFinal + #984, #3967
  static TelaFinal + #985, #3967
  static TelaFinal + #986, #3967
  static TelaFinal + #987, #3967
  static TelaFinal + #988, #3967
  static TelaFinal + #989, #3967
  static TelaFinal + #990, #3967
  static TelaFinal + #991, #3967
  static TelaFinal + #992, #3967
  static TelaFinal + #993, #3967
  static TelaFinal + #994, #3967
  static TelaFinal + #995, #3967
  static TelaFinal + #996, #3967
  static TelaFinal + #997, #3967
  static TelaFinal + #998, #3967
  static TelaFinal + #999, #3967

  ;Linha 25
  static TelaFinal + #1000, #3967
  static TelaFinal + #1001, #3967
  static TelaFinal + #1002, #3967
  static TelaFinal + #1003, #3967
  static TelaFinal + #1004, #3967
  static TelaFinal + #1005, #3967
  static TelaFinal + #1006, #3967
  static TelaFinal + #1007, #3967
  static TelaFinal + #1008, #3967
  static TelaFinal + #1009, #3967
  static TelaFinal + #1010, #3967
  static TelaFinal + #1011, #3967
  static TelaFinal + #1012, #3967
  static TelaFinal + #1013, #3967
  static TelaFinal + #1014, #3967
  static TelaFinal + #1015, #3967
  static TelaFinal + #1016, #3967
  static TelaFinal + #1017, #3967
  static TelaFinal + #1018, #3967
  static TelaFinal + #1019, #3967
  static TelaFinal + #1020, #3967
  static TelaFinal + #1021, #3967
  static TelaFinal + #1022, #3967
  static TelaFinal + #1023, #3967
  static TelaFinal + #1024, #3967
  static TelaFinal + #1025, #3967
  static TelaFinal + #1026, #3967
  static TelaFinal + #1027, #3967
  static TelaFinal + #1028, #3967
  static TelaFinal + #1029, #3967
  static TelaFinal + #1030, #3967
  static TelaFinal + #1031, #3967
  static TelaFinal + #1032, #3967
  static TelaFinal + #1033, #3967
  static TelaFinal + #1034, #3967
  static TelaFinal + #1035, #3967
  static TelaFinal + #1036, #3967
  static TelaFinal + #1037, #3967
  static TelaFinal + #1038, #3967
  static TelaFinal + #1039, #3967

  ;Linha 26
  static TelaFinal + #1040, #3967
  static TelaFinal + #1041, #3967
  static TelaFinal + #1042, #3967
  static TelaFinal + #1043, #3967
  static TelaFinal + #1044, #3967
  static TelaFinal + #1045, #3967
  static TelaFinal + #1046, #3967
  static TelaFinal + #1047, #3967
  static TelaFinal + #1048, #3967
  static TelaFinal + #1049, #3967
  static TelaFinal + #1050, #3967
  static TelaFinal + #1051, #3967
  static TelaFinal + #1052, #3967
  static TelaFinal + #1053, #3967
  static TelaFinal + #1054, #3967
  static TelaFinal + #1055, #3967
  static TelaFinal + #1056, #3967
  static TelaFinal + #1057, #3967
  static TelaFinal + #1058, #3967
  static TelaFinal + #1059, #3967
  static TelaFinal + #1060, #3967
  static TelaFinal + #1061, #3967
  static TelaFinal + #1062, #3967
  static TelaFinal + #1063, #3967
  static TelaFinal + #1064, #3967
  static TelaFinal + #1065, #3967
  static TelaFinal + #1066, #3967
  static TelaFinal + #1067, #3967
  static TelaFinal + #1068, #3967
  static TelaFinal + #1069, #3967
  static TelaFinal + #1070, #3967
  static TelaFinal + #1071, #3967
  static TelaFinal + #1072, #3967
  static TelaFinal + #1073, #3967
  static TelaFinal + #1074, #3967
  static TelaFinal + #1075, #3967
  static TelaFinal + #1076, #3967
  static TelaFinal + #1077, #3967
  static TelaFinal + #1078, #3967
  static TelaFinal + #1079, #3967

  ;Linha 27
  static TelaFinal + #1080, #3967
  static TelaFinal + #1081, #3967
  static TelaFinal + #1082, #3967
  static TelaFinal + #1083, #3967
  static TelaFinal + #1084, #3967
  static TelaFinal + #1085, #3967
  static TelaFinal + #1086, #3967
  static TelaFinal + #1087, #3967
  static TelaFinal + #1088, #3967
  static TelaFinal + #1089, #3967
  static TelaFinal + #1090, #3967
  static TelaFinal + #1091, #3967
  static TelaFinal + #1092, #3967
  static TelaFinal + #1093, #3967
  static TelaFinal + #1094, #3967
  static TelaFinal + #1095, #3967
  static TelaFinal + #1096, #3967
  static TelaFinal + #1097, #3967
  static TelaFinal + #1098, #3967
  static TelaFinal + #1099, #3967
  static TelaFinal + #1100, #3967
  static TelaFinal + #1101, #3967
  static TelaFinal + #1102, #3967
  static TelaFinal + #1103, #3967
  static TelaFinal + #1104, #3967
  static TelaFinal + #1105, #3967
  static TelaFinal + #1106, #3967
  static TelaFinal + #1107, #3967
  static TelaFinal + #1108, #3967
  static TelaFinal + #1109, #3967
  static TelaFinal + #1110, #3967
  static TelaFinal + #1111, #3967
  static TelaFinal + #1112, #3967
  static TelaFinal + #1113, #3967
  static TelaFinal + #1114, #3967
  static TelaFinal + #1115, #3967
  static TelaFinal + #1116, #3967
  static TelaFinal + #1117, #3967
  static TelaFinal + #1118, #3967
  static TelaFinal + #1119, #3967

  ;Linha 28
  static TelaFinal + #1120, #3967
  static TelaFinal + #1121, #3967
  static TelaFinal + #1122, #3967
  static TelaFinal + #1123, #3967
  static TelaFinal + #1124, #3967
  static TelaFinal + #1125, #3967
  static TelaFinal + #1126, #3967
  static TelaFinal + #1127, #3967
  static TelaFinal + #1128, #3967
  static TelaFinal + #1129, #3967
  static TelaFinal + #1130, #3967
  static TelaFinal + #1131, #3967
  static TelaFinal + #1132, #3967
  static TelaFinal + #1133, #3967
  static TelaFinal + #1134, #3967
  static TelaFinal + #1135, #3967
  static TelaFinal + #1136, #3967
  static TelaFinal + #1137, #3967
  static TelaFinal + #1138, #3967
  static TelaFinal + #1139, #3967
  static TelaFinal + #1140, #3967
  static TelaFinal + #1141, #3967
  static TelaFinal + #1142, #3967
  static TelaFinal + #1143, #3967
  static TelaFinal + #1144, #3967
  static TelaFinal + #1145, #3967
  static TelaFinal + #1146, #3967
  static TelaFinal + #1147, #3967
  static TelaFinal + #1148, #3967
  static TelaFinal + #1149, #3967
  static TelaFinal + #1150, #3967
  static TelaFinal + #1151, #3967
  static TelaFinal + #1152, #3967
  static TelaFinal + #1153, #3967
  static TelaFinal + #1154, #3967
  static TelaFinal + #1155, #3967
  static TelaFinal + #1156, #3967
  static TelaFinal + #1157, #3967
  static TelaFinal + #1158, #3967
  static TelaFinal + #1159, #3967

  ;Linha 29
  static TelaFinal + #1160, #3967
  static TelaFinal + #1161, #3967
  static TelaFinal + #1162, #3967
  static TelaFinal + #1163, #3967
  static TelaFinal + #1164, #3967
  static TelaFinal + #1165, #3967
  static TelaFinal + #1166, #3967
  static TelaFinal + #1167, #3967
  static TelaFinal + #1168, #3967
  static TelaFinal + #1169, #3967
  static TelaFinal + #1170, #3967
  static TelaFinal + #1171, #3967
  static TelaFinal + #1172, #3967
  static TelaFinal + #1173, #3967
  static TelaFinal + #1174, #3967
  static TelaFinal + #1175, #3967
  static TelaFinal + #1176, #3967
  static TelaFinal + #1177, #3967
  static TelaFinal + #1178, #3967
  static TelaFinal + #1179, #3967
  static TelaFinal + #1180, #3967
  static TelaFinal + #1181, #3967
  static TelaFinal + #1182, #3967
  static TelaFinal + #1183, #3967
  static TelaFinal + #1184, #3967
  static TelaFinal + #1185, #3967
  static TelaFinal + #1186, #3967
  static TelaFinal + #1187, #3967
  static TelaFinal + #1188, #3967
  static TelaFinal + #1189, #3967
  static TelaFinal + #1190, #3967
  static TelaFinal + #1191, #3967
  static TelaFinal + #1192, #3967
  static TelaFinal + #1193, #3967
  static TelaFinal + #1194, #3967
  static TelaFinal + #1195, #3967
  static TelaFinal + #1196, #3967
  static TelaFinal + #1197, #3967
  static TelaFinal + #1198, #3967
  static TelaFinal + #1199, #3967

printTelaFinalScreen:
  push R0
  push R1
  push R2
  push R3

  loadn R0, #TelaFinal
  loadn R1, #0
  loadn R2, #1200

  printTelaFinalScreenLoop:

    add R3,R0,R1
    loadi R3, R3
    outchar R3, R1
    inc R1
    cmp R1, R2

    jne printTelaFinalScreenLoop

  pop R3
  pop R2
  pop R1
  pop R0
  rts

telaComeco : var #1200
  ;Linha 0
  static telaComeco + #0, #17
  static telaComeco + #1, #17
  static telaComeco + #2, #17
  static telaComeco + #3, #0
  static telaComeco + #4, #17
  static telaComeco + #5, #17
  static telaComeco + #6, #17
  static telaComeco + #7, #0
  static telaComeco + #8, #17
  static telaComeco + #9, #17
  static telaComeco + #10, #17
  static telaComeco + #11, #0
  static telaComeco + #12, #17
  static telaComeco + #13, #0
  static telaComeco + #14, #17
  static telaComeco + #15, #0
  static telaComeco + #16, #17
  static telaComeco + #17, #17
  static telaComeco + #18, #17
  static telaComeco + #19, #0
  static telaComeco + #20, #17
  static telaComeco + #21, #17
  static telaComeco + #22, #17
  static telaComeco + #23, #0
  static telaComeco + #24, #17
  static telaComeco + #25, #17
  static telaComeco + #26, #17
  static telaComeco + #27, #0
  static telaComeco + #28, #17
  static telaComeco + #29, #17
  static telaComeco + #30, #17
  static telaComeco + #31, #0
  static telaComeco + #32, #17
  static telaComeco + #33, #17
  static telaComeco + #34, #17
  static telaComeco + #35, #0
  static telaComeco + #36, #17
  static telaComeco + #37, #0
  static telaComeco + #38, #17
  static telaComeco + #39, #0

  ;Linha 1
  static telaComeco + #40, #17
  static telaComeco + #41, #0
  static telaComeco + #42, #127
  static telaComeco + #43, #0
  static telaComeco + #44, #17
  static telaComeco + #45, #0
  static telaComeco + #46, #17
  static telaComeco + #47, #0
  static telaComeco + #48, #17
  static telaComeco + #49, #0
  static telaComeco + #50, #17
  static telaComeco + #51, #0
  static telaComeco + #52, #17
  static telaComeco + #53, #0
  static telaComeco + #54, #17
  static telaComeco + #55, #0
  static telaComeco + #56, #17
  static telaComeco + #57, #0
  static telaComeco + #58, #17
  static telaComeco + #59, #0
  static telaComeco + #60, #0
  static telaComeco + #61, #17
  static telaComeco + #62, #0
  static telaComeco + #63, #0
  static telaComeco + #64, #0
  static telaComeco + #65, #17
  static telaComeco + #66, #0
  static telaComeco + #67, #0
  static telaComeco + #68, #17
  static telaComeco + #69, #0
  static telaComeco + #70, #17
  static telaComeco + #71, #0
  static telaComeco + #72, #17
  static telaComeco + #73, #0
  static telaComeco + #74, #0
  static telaComeco + #75, #0
  static telaComeco + #76, #17
  static telaComeco + #77, #17
  static telaComeco + #78, #0
  static telaComeco + #79, #0

  ;Linha 2
  static telaComeco + #80, #17
  static telaComeco + #81, #0
  static telaComeco + #82, #127
  static telaComeco + #83, #0
  static telaComeco + #84, #17
  static telaComeco + #85, #17
  static telaComeco + #86, #17
  static telaComeco + #87, #0
  static telaComeco + #88, #17
  static telaComeco + #89, #17
  static telaComeco + #90, #17
  static telaComeco + #91, #0
  static telaComeco + #92, #17
  static telaComeco + #93, #17
  static telaComeco + #94, #17
  static telaComeco + #95, #127
  static telaComeco + #96, #17
  static telaComeco + #97, #17
  static telaComeco + #98, #17
  static telaComeco + #99, #0
  static telaComeco + #100, #0
  static telaComeco + #101, #17
  static telaComeco + #102, #0
  static telaComeco + #103, #0
  static telaComeco + #104, #127
  static telaComeco + #105, #17
  static telaComeco + #106, #0
  static telaComeco + #107, #0
  static telaComeco + #108, #17
  static telaComeco + #109, #17
  static telaComeco + #110, #17
  static telaComeco + #111, #0
  static telaComeco + #112, #17
  static telaComeco + #113, #0
  static telaComeco + #114, #0
  static telaComeco + #115, #0
  static telaComeco + #116, #17
  static telaComeco + #117, #0
  static telaComeco + #118, #17
  static telaComeco + #119, #0

  ;Linha 3
  static telaComeco + #120, #17
  static telaComeco + #121, #17
  static telaComeco + #122, #17
  static telaComeco + #123, #0
  static telaComeco + #124, #17
  static telaComeco + #125, #0
  static telaComeco + #126, #17
  static telaComeco + #127, #0
  static telaComeco + #128, #17
  static telaComeco + #129, #0
  static telaComeco + #130, #127
  static telaComeco + #131, #127
  static telaComeco + #132, #127
  static telaComeco + #133, #17
  static telaComeco + #134, #0
  static telaComeco + #135, #0
  static telaComeco + #136, #17
  static telaComeco + #137, #0
  static telaComeco + #138, #17
  static telaComeco + #139, #0
  static telaComeco + #140, #0
  static telaComeco + #141, #17
  static telaComeco + #142, #0
  static telaComeco + #143, #0
  static telaComeco + #144, #0
  static telaComeco + #145, #17
  static telaComeco + #146, #0
  static telaComeco + #147, #0
  static telaComeco + #148, #17
  static telaComeco + #149, #0
  static telaComeco + #150, #17
  static telaComeco + #151, #0
  static telaComeco + #152, #17
  static telaComeco + #153, #17
  static telaComeco + #154, #17
  static telaComeco + #155, #0
  static telaComeco + #156, #17
  static telaComeco + #157, #0
  static telaComeco + #158, #0
  static telaComeco + #159, #17

  ;Linha 4
  static telaComeco + #160, #127
  static telaComeco + #161, #127
  static telaComeco + #162, #127
  static telaComeco + #163, #127
  static telaComeco + #164, #127
  static telaComeco + #165, #127
  static telaComeco + #166, #127
  static telaComeco + #167, #127
  static telaComeco + #168, #127
  static telaComeco + #169, #127
  static telaComeco + #170, #127
  static telaComeco + #171, #127
  static telaComeco + #172, #127
  static telaComeco + #173, #127
  static telaComeco + #174, #127
  static telaComeco + #175, #127
  static telaComeco + #176, #127
  static telaComeco + #177, #127
  static telaComeco + #178, #127
  static telaComeco + #179, #127
  static telaComeco + #180, #127
  static telaComeco + #181, #127
  static telaComeco + #182, #127
  static telaComeco + #183, #127
  static telaComeco + #184, #127
  static telaComeco + #185, #127
  static telaComeco + #186, #127
  static telaComeco + #187, #127
  static telaComeco + #188, #127
  static telaComeco + #189, #0
  static telaComeco + #190, #0
  static telaComeco + #191, #127
  static telaComeco + #192, #127
  static telaComeco + #193, #127
  static telaComeco + #194, #127
  static telaComeco + #195, #127
  static telaComeco + #196, #127
  static telaComeco + #197, #127
  static telaComeco + #198, #127
  static telaComeco + #199, #127

  ;Linha 5
  static telaComeco + #200, #127
  static telaComeco + #201, #127
  static telaComeco + #202, #127
  static telaComeco + #203, #127
  static telaComeco + #204, #127
  static telaComeco + #205, #127
  static telaComeco + #206, #127
  static telaComeco + #207, #127
  static telaComeco + #208, #127
  static telaComeco + #209, #127
  static telaComeco + #210, #127
  static telaComeco + #211, #127
  static telaComeco + #212, #127
  static telaComeco + #213, #127
  static telaComeco + #214, #127
  static telaComeco + #215, #127
  static telaComeco + #216, #127
  static telaComeco + #217, #127
  static telaComeco + #218, #127
  static telaComeco + #219, #127
  static telaComeco + #220, #127
  static telaComeco + #221, #127
  static telaComeco + #222, #127
  static telaComeco + #223, #127
  static telaComeco + #224, #127
  static telaComeco + #225, #127
  static telaComeco + #226, #127
  static telaComeco + #227, #127
  static telaComeco + #228, #127
  static telaComeco + #229, #127
  static telaComeco + #230, #127
  static telaComeco + #231, #127
  static telaComeco + #232, #127
  static telaComeco + #233, #127
  static telaComeco + #234, #127
  static telaComeco + #235, #127
  static telaComeco + #236, #127
  static telaComeco + #237, #127
  static telaComeco + #238, #127
  static telaComeco + #239, #127

  ;Linha 6
  static telaComeco + #240, #127
  static telaComeco + #241, #127
  static telaComeco + #242, #127
  static telaComeco + #243, #127
  static telaComeco + #244, #127
  static telaComeco + #245, #2321
  static telaComeco + #246, #2321
  static telaComeco + #247, #2321
  static telaComeco + #248, #127
  static telaComeco + #249, #127
  static telaComeco + #250, #127
  static telaComeco + #251, #127
  static telaComeco + #252, #127
  static telaComeco + #253, #127
  static telaComeco + #254, #127
  static telaComeco + #255, #127
  static telaComeco + #256, #2321
  static telaComeco + #257, #127
  static telaComeco + #258, #2321
  static telaComeco + #259, #127
  static telaComeco + #260, #127
  static telaComeco + #261, #127
  static telaComeco + #262, #127
  static telaComeco + #263, #127
  static telaComeco + #264, #127
  static telaComeco + #265, #127
  static telaComeco + #266, #127
  static telaComeco + #267, #127
  static telaComeco + #268, #127
  static telaComeco + #269, #127
  static telaComeco + #270, #127
  static telaComeco + #271, #127
  static telaComeco + #272, #127
  static telaComeco + #273, #127
  static telaComeco + #274, #127
  static telaComeco + #275, #127
  static telaComeco + #276, #127
  static telaComeco + #277, #127
  static telaComeco + #278, #127
  static telaComeco + #279, #127

  ;Linha 7
  static telaComeco + #280, #127
  static telaComeco + #281, #127
  static telaComeco + #282, #127
  static telaComeco + #283, #127
  static telaComeco + #284, #2321
  static telaComeco + #285, #2321
  static telaComeco + #286, #273
  static telaComeco + #287, #273
  static telaComeco + #288, #2321
  static telaComeco + #289, #127
  static telaComeco + #290, #127
  static telaComeco + #291, #127
  static telaComeco + #292, #127
  static telaComeco + #293, #2321
  static telaComeco + #294, #2321
  static telaComeco + #295, #2321
  static telaComeco + #296, #2321
  static telaComeco + #297, #2321
  static telaComeco + #298, #2321
  static telaComeco + #299, #2321
  static telaComeco + #300, #2321
  static telaComeco + #301, #2321
  static telaComeco + #302, #2321
  static telaComeco + #303, #127
  static telaComeco + #304, #127
  static telaComeco + #305, #127
  static telaComeco + #306, #127
  static telaComeco + #307, #2321
  static telaComeco + #308, #2321
  static telaComeco + #309, #2321
  static telaComeco + #310, #2321
  static telaComeco + #311, #127
  static telaComeco + #312, #127
  static telaComeco + #313, #127
  static telaComeco + #314, #127
  static telaComeco + #315, #127
  static telaComeco + #316, #127
  static telaComeco + #317, #127
  static telaComeco + #318, #127
  static telaComeco + #319, #127

  ;Linha 8
  static telaComeco + #320, #127
  static telaComeco + #321, #127
  static telaComeco + #322, #127
  static telaComeco + #323, #2321
  static telaComeco + #324, #2321
  static telaComeco + #325, #273
  static telaComeco + #326, #273
  static telaComeco + #327, #273
  static telaComeco + #328, #2321
  static telaComeco + #329, #127
  static telaComeco + #330, #127
  static telaComeco + #331, #2321
  static telaComeco + #332, #2321
  static telaComeco + #333, #2321
  static telaComeco + #334, #2321
  static telaComeco + #335, #2321
  static telaComeco + #336, #2321
  static telaComeco + #337, #2321
  static telaComeco + #338, #2321
  static telaComeco + #339, #2321
  static telaComeco + #340, #2321
  static telaComeco + #341, #2321
  static telaComeco + #342, #2321
  static telaComeco + #343, #2321
  static telaComeco + #344, #2321
  static telaComeco + #345, #127
  static telaComeco + #346, #2321
  static telaComeco + #347, #273
  static telaComeco + #348, #273
  static telaComeco + #349, #273
  static telaComeco + #350, #2321
  static telaComeco + #351, #2321
  static telaComeco + #352, #127
  static telaComeco + #353, #127
  static telaComeco + #354, #127
  static telaComeco + #355, #127
  static telaComeco + #356, #127
  static telaComeco + #357, #127
  static telaComeco + #358, #127
  static telaComeco + #359, #127

  ;Linha 9
  static telaComeco + #360, #127
  static telaComeco + #361, #127
  static telaComeco + #362, #127
  static telaComeco + #363, #2321
  static telaComeco + #364, #273
  static telaComeco + #365, #273
  static telaComeco + #366, #256
  static telaComeco + #367, #273
  static telaComeco + #368, #273
  static telaComeco + #369, #2321
  static telaComeco + #370, #2321
  static telaComeco + #371, #2321
  static telaComeco + #372, #2321
  static telaComeco + #373, #2321
  static telaComeco + #374, #2321
  static telaComeco + #375, #2321
  static telaComeco + #376, #2321
  static telaComeco + #377, #2321
  static telaComeco + #378, #2321
  static telaComeco + #379, #2321
  static telaComeco + #380, #2321
  static telaComeco + #381, #2321
  static telaComeco + #382, #2321
  static telaComeco + #383, #2321
  static telaComeco + #384, #2321
  static telaComeco + #385, #2321
  static telaComeco + #386, #2321
  static telaComeco + #387, #273
  static telaComeco + #388, #273
  static telaComeco + #389, #273
  static telaComeco + #390, #273
  static telaComeco + #391, #2321
  static telaComeco + #392, #127
  static telaComeco + #393, #127
  static telaComeco + #394, #127
  static telaComeco + #395, #127
  static telaComeco + #396, #127
  static telaComeco + #397, #127
  static telaComeco + #398, #127
  static telaComeco + #399, #127

  ;Linha 10
  static telaComeco + #400, #127
  static telaComeco + #401, #127
  static telaComeco + #402, #127
  static telaComeco + #403, #2321
  static telaComeco + #404, #273
  static telaComeco + #405, #273
  static telaComeco + #406, #273
  static telaComeco + #407, #256
  static telaComeco + #408, #273
  static telaComeco + #409, #2321
  static telaComeco + #410, #2321
  static telaComeco + #411, #2321
  static telaComeco + #412, #2321
  static telaComeco + #413, #2321
  static telaComeco + #414, #2321
  static telaComeco + #415, #2321
  static telaComeco + #416, #2321
  static telaComeco + #417, #2321
  static telaComeco + #418, #2321
  static telaComeco + #419, #2321
  static telaComeco + #420, #2321
  static telaComeco + #421, #2321
  static telaComeco + #422, #2321
  static telaComeco + #423, #2321
  static telaComeco + #424, #2321
  static telaComeco + #425, #2321
  static telaComeco + #426, #2321
  static telaComeco + #427, #273
  static telaComeco + #428, #256
  static telaComeco + #429, #256
  static telaComeco + #430, #273
  static telaComeco + #431, #2321
  static telaComeco + #432, #127
  static telaComeco + #433, #127
  static telaComeco + #434, #127
  static telaComeco + #435, #127
  static telaComeco + #436, #127
  static telaComeco + #437, #127
  static telaComeco + #438, #127
  static telaComeco + #439, #127

  ;Linha 11
  static telaComeco + #440, #127
  static telaComeco + #441, #127
  static telaComeco + #442, #127
  static telaComeco + #443, #127
  static telaComeco + #444, #2321
  static telaComeco + #445, #2321
  static telaComeco + #446, #273
  static telaComeco + #447, #2321
  static telaComeco + #448, #2321
  static telaComeco + #449, #2321
  static telaComeco + #450, #2321
  static telaComeco + #451, #2321
  static telaComeco + #452, #2321
  static telaComeco + #453, #2321
  static telaComeco + #454, #2321
  static telaComeco + #455, #2321
  static telaComeco + #456, #2321
  static telaComeco + #457, #2321
  static telaComeco + #458, #2321
  static telaComeco + #459, #2321
  static telaComeco + #460, #2321
  static telaComeco + #461, #2321
  static telaComeco + #462, #2321
  static telaComeco + #463, #2321
  static telaComeco + #464, #2321
  static telaComeco + #465, #2321
  static telaComeco + #466, #2321
  static telaComeco + #467, #273
  static telaComeco + #468, #273
  static telaComeco + #469, #273
  static telaComeco + #470, #273
  static telaComeco + #471, #2321
  static telaComeco + #472, #127
  static telaComeco + #473, #127
  static telaComeco + #474, #127
  static telaComeco + #475, #127
  static telaComeco + #476, #127
  static telaComeco + #477, #127
  static telaComeco + #478, #127
  static telaComeco + #479, #127

  ;Linha 12
  static telaComeco + #480, #127
  static telaComeco + #481, #127
  static telaComeco + #482, #127
  static telaComeco + #483, #127
  static telaComeco + #484, #127
  static telaComeco + #485, #127
  static telaComeco + #486, #2321
  static telaComeco + #487, #2321
  static telaComeco + #488, #2321
  static telaComeco + #489, #2321
  static telaComeco + #490, #2321
  static telaComeco + #491, #2321
  static telaComeco + #492, #2321
  static telaComeco + #493, #2321
  static telaComeco + #494, #2321
  static telaComeco + #495, #2321
  static telaComeco + #496, #2321
  static telaComeco + #497, #2321
  static telaComeco + #498, #2321
  static telaComeco + #499, #2321
  static telaComeco + #500, #2321
  static telaComeco + #501, #2321
  static telaComeco + #502, #2321
  static telaComeco + #503, #2321
  static telaComeco + #504, #2321
  static telaComeco + #505, #2321
  static telaComeco + #506, #2321
  static telaComeco + #507, #2321
  static telaComeco + #508, #2321
  static telaComeco + #509, #2321
  static telaComeco + #510, #2321
  static telaComeco + #511, #127
  static telaComeco + #512, #127
  static telaComeco + #513, #127
  static telaComeco + #514, #127
  static telaComeco + #515, #127
  static telaComeco + #516, #127
  static telaComeco + #517, #127
  static telaComeco + #518, #127
  static telaComeco + #519, #127

  ;Linha 13
  static telaComeco + #520, #127
  static telaComeco + #521, #127
  static telaComeco + #522, #127
  static telaComeco + #523, #127
  static telaComeco + #524, #127
  static telaComeco + #525, #2321
  static telaComeco + #526, #2321
  static telaComeco + #527, #2321
  static telaComeco + #528, #2321
  static telaComeco + #529, #2321
  static telaComeco + #530, #2321
  static telaComeco + #531, #2321
  static telaComeco + #532, #2321
  static telaComeco + #533, #2321
  static telaComeco + #534, #2321
  static telaComeco + #535, #2321
  static telaComeco + #536, #2321
  static telaComeco + #537, #2321
  static telaComeco + #538, #2321
  static telaComeco + #539, #2321
  static telaComeco + #540, #2321
  static telaComeco + #541, #2321
  static telaComeco + #542, #2321
  static telaComeco + #543, #2321
  static telaComeco + #544, #2321
  static telaComeco + #545, #2321
  static telaComeco + #546, #2321
  static telaComeco + #547, #2321
  static telaComeco + #548, #2321
  static telaComeco + #549, #127
  static telaComeco + #550, #127
  static telaComeco + #551, #127
  static telaComeco + #552, #127
  static telaComeco + #553, #127
  static telaComeco + #554, #127
  static telaComeco + #555, #127
  static telaComeco + #556, #127
  static telaComeco + #557, #127
  static telaComeco + #558, #127
  static telaComeco + #559, #127

  ;Linha 14
  static telaComeco + #560, #127
  static telaComeco + #561, #127
  static telaComeco + #562, #127
  static telaComeco + #563, #127
  static telaComeco + #564, #127
  static telaComeco + #565, #2321
  static telaComeco + #566, #2321
  static telaComeco + #567, #2321
  static telaComeco + #568, #2321
  static telaComeco + #569, #2321
  static telaComeco + #570, #2321
  static telaComeco + #571, #2321
  static telaComeco + #572, #2321
  static telaComeco + #573, #2321
  static telaComeco + #574, #2321
  static telaComeco + #575, #2321
  static telaComeco + #576, #2321
  static telaComeco + #577, #2321
  static telaComeco + #578, #2321
  static telaComeco + #579, #2321
  static telaComeco + #580, #2321
  static telaComeco + #581, #2321
  static telaComeco + #582, #2321
  static telaComeco + #583, #2321
  static telaComeco + #584, #2321
  static telaComeco + #585, #2321
  static telaComeco + #586, #2321
  static telaComeco + #587, #2321
  static telaComeco + #588, #2321
  static telaComeco + #589, #2321
  static telaComeco + #590, #127
  static telaComeco + #591, #127
  static telaComeco + #592, #127
  static telaComeco + #593, #127
  static telaComeco + #594, #127
  static telaComeco + #595, #127
  static telaComeco + #596, #127
  static telaComeco + #597, #127
  static telaComeco + #598, #127
  static telaComeco + #599, #127

  ;Linha 15
  static telaComeco + #600, #127
  static telaComeco + #601, #127
  static telaComeco + #602, #127
  static telaComeco + #603, #127
  static telaComeco + #604, #2321
  static telaComeco + #605, #2321
  static telaComeco + #606, #2321
  static telaComeco + #607, #2321
  static telaComeco + #608, #2321
  static telaComeco + #609, #2321
  static telaComeco + #610, #2321
  static telaComeco + #611, #2321
  static telaComeco + #612, #2321
  static telaComeco + #613, #2321
  static telaComeco + #614, #2321
  static telaComeco + #615, #2321
  static telaComeco + #616, #2321
  static telaComeco + #617, #2321
  static telaComeco + #618, #2321
  static telaComeco + #619, #2321
  static telaComeco + #620, #2321
  static telaComeco + #621, #2321
  static telaComeco + #622, #2321
  static telaComeco + #623, #2321
  static telaComeco + #624, #2321
  static telaComeco + #625, #2321
  static telaComeco + #626, #2321
  static telaComeco + #627, #2321
  static telaComeco + #628, #2321
  static telaComeco + #629, #2321
  static telaComeco + #630, #127
  static telaComeco + #631, #127
  static telaComeco + #632, #127
  static telaComeco + #633, #127
  static telaComeco + #634, #127
  static telaComeco + #635, #127
  static telaComeco + #636, #127
  static telaComeco + #637, #127
  static telaComeco + #638, #127
  static telaComeco + #639, #127

  ;Linha 16
  static telaComeco + #640, #127
  static telaComeco + #641, #127
  static telaComeco + #642, #127
  static telaComeco + #643, #127
  static telaComeco + #644, #2321
  static telaComeco + #645, #2321
  static telaComeco + #646, #2321
  static telaComeco + #647, #2321
  static telaComeco + #648, #2321
  static telaComeco + #649, #2321
  static telaComeco + #650, #2321
  static telaComeco + #651, #2304
  static telaComeco + #652, #256
  static telaComeco + #653, #2321
  static telaComeco + #654, #2321
  static telaComeco + #655, #273
  static telaComeco + #656, #273
  static telaComeco + #657, #273
  static telaComeco + #658, #273
  static telaComeco + #659, #273
  static telaComeco + #660, #2321
  static telaComeco + #661, #2321
  static telaComeco + #662, #256
  static telaComeco + #663, #256
  static telaComeco + #664, #2321
  static telaComeco + #665, #2321
  static telaComeco + #666, #2321
  static telaComeco + #667, #2321
  static telaComeco + #668, #2321
  static telaComeco + #669, #2321
  static telaComeco + #670, #2321
  static telaComeco + #671, #127
  static telaComeco + #672, #127
  static telaComeco + #673, #127
  static telaComeco + #674, #127
  static telaComeco + #675, #127
  static telaComeco + #676, #127
  static telaComeco + #677, #127
  static telaComeco + #678, #127
  static telaComeco + #679, #127

  ;Linha 17
  static telaComeco + #680, #127
  static telaComeco + #681, #127
  static telaComeco + #682, #127
  static telaComeco + #683, #2321
  static telaComeco + #684, #2321
  static telaComeco + #685, #2321
  static telaComeco + #686, #2321
  static telaComeco + #687, #2321
  static telaComeco + #688, #2321
  static telaComeco + #689, #2321
  static telaComeco + #690, #2321
  static telaComeco + #691, #2321
  static telaComeco + #692, #2321
  static telaComeco + #693, #2321
  static telaComeco + #694, #273
  static telaComeco + #695, #273
  static telaComeco + #696, #2304
  static telaComeco + #697, #273
  static telaComeco + #698, #2304
  static telaComeco + #699, #273
  static telaComeco + #700, #273
  static telaComeco + #701, #2321
  static telaComeco + #702, #2321
  static telaComeco + #703, #2321
  static telaComeco + #704, #2321
  static telaComeco + #705, #2321
  static telaComeco + #706, #2321
  static telaComeco + #707, #2321
  static telaComeco + #708, #2321
  static telaComeco + #709, #2321
  static telaComeco + #710, #2321
  static telaComeco + #711, #2321
  static telaComeco + #712, #127
  static telaComeco + #713, #127
  static telaComeco + #714, #127
  static telaComeco + #715, #127
  static telaComeco + #716, #127
  static telaComeco + #717, #127
  static telaComeco + #718, #127
  static telaComeco + #719, #127

  ;Linha 18
  static telaComeco + #720, #127
  static telaComeco + #721, #127
  static telaComeco + #722, #2321
  static telaComeco + #723, #2321
  static telaComeco + #724, #2321
  static telaComeco + #725, #2321
  static telaComeco + #726, #2321
  static telaComeco + #727, #2321
  static telaComeco + #728, #2321
  static telaComeco + #729, #2321
  static telaComeco + #730, #2321
  static telaComeco + #731, #2321
  static telaComeco + #732, #2321
  static telaComeco + #733, #273
  static telaComeco + #734, #273
  static telaComeco + #735, #273
  static telaComeco + #736, #273
  static telaComeco + #737, #273
  static telaComeco + #738, #273
  static telaComeco + #739, #273
  static telaComeco + #740, #273
  static telaComeco + #741, #273
  static telaComeco + #742, #2321
  static telaComeco + #743, #2321
  static telaComeco + #744, #2321
  static telaComeco + #745, #2321
  static telaComeco + #746, #2321
  static telaComeco + #747, #2321
  static telaComeco + #748, #2321
  static telaComeco + #749, #2321
  static telaComeco + #750, #2321
  static telaComeco + #751, #2321
  static telaComeco + #752, #127
  static telaComeco + #753, #127
  static telaComeco + #754, #127
  static telaComeco + #755, #127
  static telaComeco + #756, #127
  static telaComeco + #757, #127
  static telaComeco + #758, #127
  static telaComeco + #759, #127

  ;Linha 19
  static telaComeco + #760, #127
  static telaComeco + #761, #127
  static telaComeco + #762, #2321
  static telaComeco + #763, #2321
  static telaComeco + #764, #2321
  static telaComeco + #765, #2321
  static telaComeco + #766, #2321
  static telaComeco + #767, #2321
  static telaComeco + #768, #2321
  static telaComeco + #769, #2321
  static telaComeco + #770, #2321
  static telaComeco + #771, #2321
  static telaComeco + #772, #273
  static telaComeco + #773, #273
  static telaComeco + #774, #273
  static telaComeco + #775, #273
  static telaComeco + #776, #273
  static telaComeco + #777, #2304
  static telaComeco + #778, #273
  static telaComeco + #779, #273
  static telaComeco + #780, #273
  static telaComeco + #781, #273
  static telaComeco + #782, #273
  static telaComeco + #783, #2321
  static telaComeco + #784, #2321
  static telaComeco + #785, #2321
  static telaComeco + #786, #2321
  static telaComeco + #787, #2321
  static telaComeco + #788, #2321
  static telaComeco + #789, #2321
  static telaComeco + #790, #2321
  static telaComeco + #791, #2321
  static telaComeco + #792, #2321
  static telaComeco + #793, #127
  static telaComeco + #794, #127
  static telaComeco + #795, #127
  static telaComeco + #796, #127
  static telaComeco + #797, #127
  static telaComeco + #798, #127
  static telaComeco + #799, #127

  ;Linha 20
  static telaComeco + #800, #127
  static telaComeco + #801, #2321
  static telaComeco + #802, #2321
  static telaComeco + #803, #2321
  static telaComeco + #804, #2321
  static telaComeco + #805, #2321
  static telaComeco + #806, #2321
  static telaComeco + #807, #2321
  static telaComeco + #808, #2321
  static telaComeco + #809, #2321
  static telaComeco + #810, #2321
  static telaComeco + #811, #2321
  static telaComeco + #812, #273
  static telaComeco + #813, #273
  static telaComeco + #814, #273
  static telaComeco + #815, #273
  static telaComeco + #816, #273
  static telaComeco + #817, #2304
  static telaComeco + #818, #273
  static telaComeco + #819, #273
  static telaComeco + #820, #273
  static telaComeco + #821, #273
  static telaComeco + #822, #273
  static telaComeco + #823, #2321
  static telaComeco + #824, #2321
  static telaComeco + #825, #2321
  static telaComeco + #826, #2321
  static telaComeco + #827, #2321
  static telaComeco + #828, #2321
  static telaComeco + #829, #2321
  static telaComeco + #830, #2321
  static telaComeco + #831, #2321
  static telaComeco + #832, #2321
  static telaComeco + #833, #2321
  static telaComeco + #834, #127
  static telaComeco + #835, #127
  static telaComeco + #836, #127
  static telaComeco + #837, #127
  static telaComeco + #838, #127
  static telaComeco + #839, #127

  ;Linha 21
  static telaComeco + #840, #127
  static telaComeco + #841, #2321
  static telaComeco + #842, #2321
  static telaComeco + #843, #2321
  static telaComeco + #844, #2321
  static telaComeco + #845, #2321
  static telaComeco + #846, #2321
  static telaComeco + #847, #2321
  static telaComeco + #848, #2321
  static telaComeco + #849, #2321
  static telaComeco + #850, #2321
  static telaComeco + #851, #2321
  static telaComeco + #852, #273
  static telaComeco + #853, #273
  static telaComeco + #854, #273
  static telaComeco + #855, #273
  static telaComeco + #856, #273
  static telaComeco + #857, #2304
  static telaComeco + #858, #273
  static telaComeco + #859, #273
  static telaComeco + #860, #273
  static telaComeco + #861, #273
  static telaComeco + #862, #273
  static telaComeco + #863, #2321
  static telaComeco + #864, #2321
  static telaComeco + #865, #2321
  static telaComeco + #866, #2321
  static telaComeco + #867, #2321
  static telaComeco + #868, #2321
  static telaComeco + #869, #2321
  static telaComeco + #870, #2321
  static telaComeco + #871, #2321
  static telaComeco + #872, #2321
  static telaComeco + #873, #2321
  static telaComeco + #874, #127
  static telaComeco + #875, #127
  static telaComeco + #876, #127
  static telaComeco + #877, #127
  static telaComeco + #878, #127
  static telaComeco + #879, #127

  ;Linha 22
  static telaComeco + #880, #127
  static telaComeco + #881, #2321
  static telaComeco + #882, #2321
  static telaComeco + #883, #2321
  static telaComeco + #884, #2321
  static telaComeco + #885, #2321
  static telaComeco + #886, #2321
  static telaComeco + #887, #2321
  static telaComeco + #888, #2321
  static telaComeco + #889, #2321
  static telaComeco + #890, #2321
  static telaComeco + #891, #2321
  static telaComeco + #892, #2321
  static telaComeco + #893, #273
  static telaComeco + #894, #273
  static telaComeco + #895, #273
  static telaComeco + #896, #273
  static telaComeco + #897, #2304
  static telaComeco + #898, #273
  static telaComeco + #899, #273
  static telaComeco + #900, #273
  static telaComeco + #901, #273
  static telaComeco + #902, #2321
  static telaComeco + #903, #2321
  static telaComeco + #904, #2321
  static telaComeco + #905, #2321
  static telaComeco + #906, #2321
  static telaComeco + #907, #2321
  static telaComeco + #908, #2321
  static telaComeco + #909, #2321
  static telaComeco + #910, #2321
  static telaComeco + #911, #2321
  static telaComeco + #912, #2321
  static telaComeco + #913, #2321
  static telaComeco + #914, #127
  static telaComeco + #915, #127
  static telaComeco + #916, #127
  static telaComeco + #917, #127
  static telaComeco + #918, #127
  static telaComeco + #919, #127

  ;Linha 23
  static telaComeco + #920, #127
  static telaComeco + #921, #2321
  static telaComeco + #922, #2321
  static telaComeco + #923, #2321
  static telaComeco + #924, #2321
  static telaComeco + #925, #2321
  static telaComeco + #926, #2321
  static telaComeco + #927, #2321
  static telaComeco + #928, #2321
  static telaComeco + #929, #2321
  static telaComeco + #930, #2321
  static telaComeco + #931, #2321
  static telaComeco + #932, #2321
  static telaComeco + #933, #273
  static telaComeco + #934, #273
  static telaComeco + #935, #273
  static telaComeco + #936, #273
  static telaComeco + #937, #273
  static telaComeco + #938, #273
  static telaComeco + #939, #273
  static telaComeco + #940, #273
  static telaComeco + #941, #273
  static telaComeco + #942, #2321
  static telaComeco + #943, #2321
  static telaComeco + #944, #2321
  static telaComeco + #945, #2321
  static telaComeco + #946, #2321
  static telaComeco + #947, #2321
  static telaComeco + #948, #2321
  static telaComeco + #949, #2321
  static telaComeco + #950, #2321
  static telaComeco + #951, #2321
  static telaComeco + #952, #2321
  static telaComeco + #953, #2321
  static telaComeco + #954, #127
  static telaComeco + #955, #127
  static telaComeco + #956, #127
  static telaComeco + #957, #127
  static telaComeco + #958, #127
  static telaComeco + #959, #127

  ;Linha 24
  static telaComeco + #960, #127
  static telaComeco + #961, #2321
  static telaComeco + #962, #2321
  static telaComeco + #963, #2321
  static telaComeco + #964, #2321
  static telaComeco + #965, #2321
  static telaComeco + #966, #2321
  static telaComeco + #967, #2321
  static telaComeco + #968, #2321
  static telaComeco + #969, #2321
  static telaComeco + #970, #2321
  static telaComeco + #971, #2321
  static telaComeco + #972, #2321
  static telaComeco + #973, #273
  static telaComeco + #974, #273
  static telaComeco + #975, #273
  static telaComeco + #976, #2304
  static telaComeco + #977, #2304
  static telaComeco + #978, #2304
  static telaComeco + #979, #273
  static telaComeco + #980, #273
  static telaComeco + #981, #273
  static telaComeco + #982, #2321
  static telaComeco + #983, #2321
  static telaComeco + #984, #2321
  static telaComeco + #985, #2321
  static telaComeco + #986, #2321
  static telaComeco + #987, #2321
  static telaComeco + #988, #2321
  static telaComeco + #989, #2321
  static telaComeco + #990, #2321
  static telaComeco + #991, #2321
  static telaComeco + #992, #2321
  static telaComeco + #993, #127
  static telaComeco + #994, #127
  static telaComeco + #995, #127
  static telaComeco + #996, #127
  static telaComeco + #997, #127
  static telaComeco + #998, #127
  static telaComeco + #999, #127

  ;Linha 25
  static telaComeco + #1000, #127
  static telaComeco + #1001, #127
  static telaComeco + #1002, #2321
  static telaComeco + #1003, #2321
  static telaComeco + #1004, #2321
  static telaComeco + #1005, #2321
  static telaComeco + #1006, #2321
  static telaComeco + #1007, #2321
  static telaComeco + #1008, #2321
  static telaComeco + #1009, #2321
  static telaComeco + #1010, #2321
  static telaComeco + #1011, #2321
  static telaComeco + #1012, #273
  static telaComeco + #1013, #273
  static telaComeco + #1014, #273
  static telaComeco + #1015, #273
  static telaComeco + #1016, #273
  static telaComeco + #1017, #273
  static telaComeco + #1018, #273
  static telaComeco + #1019, #273
  static telaComeco + #1020, #273
  static telaComeco + #1021, #273
  static telaComeco + #1022, #273
  static telaComeco + #1023, #2321
  static telaComeco + #1024, #2321
  static telaComeco + #1025, #2321
  static telaComeco + #1026, #2321
  static telaComeco + #1027, #2321
  static telaComeco + #1028, #2321
  static telaComeco + #1029, #2321
  static telaComeco + #1030, #2321
  static telaComeco + #1031, #2321
  static telaComeco + #1032, #127
  static telaComeco + #1033, #127
  static telaComeco + #1034, #127
  static telaComeco + #1035, #127
  static telaComeco + #1036, #127
  static telaComeco + #1037, #127
  static telaComeco + #1038, #127
  static telaComeco + #1039, #127

  ;Linha 26
  static telaComeco + #1040, #127
  static telaComeco + #1041, #2321
  static telaComeco + #1042, #2321
  static telaComeco + #1043, #2321
  static telaComeco + #1044, #2321
  static telaComeco + #1045, #2321
  static telaComeco + #1046, #2321
  static telaComeco + #1047, #2321
  static telaComeco + #1048, #2321
  static telaComeco + #1049, #2321
  static telaComeco + #1050, #2321
  static telaComeco + #1051, #2321
  static telaComeco + #1052, #273
  static telaComeco + #1053, #273
  static telaComeco + #1054, #273
  static telaComeco + #1055, #273
  static telaComeco + #1056, #273
  static telaComeco + #1057, #273
  static telaComeco + #1058, #273
  static telaComeco + #1059, #273
  static telaComeco + #1060, #273
  static telaComeco + #1061, #273
  static telaComeco + #1062, #273
  static telaComeco + #1063, #2321
  static telaComeco + #1064, #2321
  static telaComeco + #1065, #2321
  static telaComeco + #1066, #2321
  static telaComeco + #1067, #2321
  static telaComeco + #1068, #2321
  static telaComeco + #1069, #2321
  static telaComeco + #1070, #2321
  static telaComeco + #1071, #2321
  static telaComeco + #1072, #2321
  static telaComeco + #1073, #127
  static telaComeco + #1074, #127
  static telaComeco + #1075, #127
  static telaComeco + #1076, #127
  static telaComeco + #1077, #127
  static telaComeco + #1078, #127
  static telaComeco + #1079, #127

  ;Linha 27
  static telaComeco + #1080, #127
  static telaComeco + #1081, #2321
  static telaComeco + #1082, #2321
  static telaComeco + #1083, #2321
  static telaComeco + #1084, #2321
  static telaComeco + #1085, #2321
  static telaComeco + #1086, #2321
  static telaComeco + #1087, #2321
  static telaComeco + #1088, #2321
  static telaComeco + #1089, #2321
  static telaComeco + #1090, #2321
  static telaComeco + #1091, #2321
  static telaComeco + #1092, #2321
  static telaComeco + #1093, #273
  static telaComeco + #1094, #273
  static telaComeco + #1095, #273
  static telaComeco + #1096, #273
  static telaComeco + #1097, #273
  static telaComeco + #1098, #273
  static telaComeco + #1099, #273
  static telaComeco + #1100, #273
  static telaComeco + #1101, #273
  static telaComeco + #1102, #2321
  static telaComeco + #1103, #2321
  static telaComeco + #1104, #2321
  static telaComeco + #1105, #2321
  static telaComeco + #1106, #2321
  static telaComeco + #1107, #2321
  static telaComeco + #1108, #2321
  static telaComeco + #1109, #2321
  static telaComeco + #1110, #2321
  static telaComeco + #1111, #2321
  static telaComeco + #1112, #2321
  static telaComeco + #1113, #2321
  static telaComeco + #1114, #127
  static telaComeco + #1115, #127
  static telaComeco + #1116, #127
  static telaComeco + #1117, #127
  static telaComeco + #1118, #127
  static telaComeco + #1119, #127

  ;Linha 28
  static telaComeco + #1120, #2321
  static telaComeco + #1121, #2321
  static telaComeco + #1122, #2321
  static telaComeco + #1123, #2321
  static telaComeco + #1124, #2321
  static telaComeco + #1125, #2321
  static telaComeco + #1126, #2321
  static telaComeco + #1127, #2321
  static telaComeco + #1128, #2321
  static telaComeco + #1129, #2321
  static telaComeco + #1130, #2321
  static telaComeco + #1131, #2321
  static telaComeco + #1132, #2321
  static telaComeco + #1133, #2321
  static telaComeco + #1134, #2321
  static telaComeco + #1135, #273
  static telaComeco + #1136, #273
  static telaComeco + #1137, #273
  static telaComeco + #1138, #273
  static telaComeco + #1139, #273
  static telaComeco + #1140, #2321
  static telaComeco + #1141, #2321
  static telaComeco + #1142, #2321
  static telaComeco + #1143, #2321
  static telaComeco + #1144, #2321
  static telaComeco + #1145, #2321
  static telaComeco + #1146, #2321
  static telaComeco + #1147, #2321
  static telaComeco + #1148, #2321
  static telaComeco + #1149, #2321
  static telaComeco + #1150, #2321
  static telaComeco + #1151, #2321
  static telaComeco + #1152, #2321
  static telaComeco + #1153, #2321
  static telaComeco + #1154, #127
  static telaComeco + #1155, #127
  static telaComeco + #1156, #127
  static telaComeco + #1157, #127
  static telaComeco + #1158, #127
  static telaComeco + #1159, #127

  ;Linha 29
  static telaComeco + #1160, #2321
  static telaComeco + #1161, #2321
  static telaComeco + #1162, #2321
  static telaComeco + #1163, #2321
  static telaComeco + #1164, #2321
  static telaComeco + #1165, #2321
  static telaComeco + #1166, #2321
  static telaComeco + #1167, #2321
  static telaComeco + #1168, #2321
  static telaComeco + #1169, #2321
  static telaComeco + #1170, #2321
  static telaComeco + #1171, #2321
  static telaComeco + #1172, #2321
  static telaComeco + #1173, #2321
  static telaComeco + #1174, #2321
  static telaComeco + #1175, #2321
  static telaComeco + #1176, #2321
  static telaComeco + #1177, #2321
  static telaComeco + #1178, #2321
  static telaComeco + #1179, #2321
  static telaComeco + #1180, #2321
  static telaComeco + #1181, #2321
  static telaComeco + #1182, #2321
  static telaComeco + #1183, #2321
  static telaComeco + #1184, #2321
  static telaComeco + #1185, #2321
  static telaComeco + #1186, #2321
  static telaComeco + #1187, #2321
  static telaComeco + #1188, #2321
  static telaComeco + #1189, #2321
  static telaComeco + #1190, #2321
  static telaComeco + #1191, #2321
  static telaComeco + #1192, #2321
  static telaComeco + #1193, #2321
  static telaComeco + #1194, #2321
  static telaComeco + #1195, #127
  static telaComeco + #1196, #127
  static telaComeco + #1197, #127
  static telaComeco + #1198, #127
  static telaComeco + #1199, #127

printtelaComecoScreen:
  push R0
  push R1
  push R2
  push R3

  loadn R0, #telaComeco
  loadn R1, #0
  loadn R2, #1200

  printtelaComecoScreenLoop:

    add R3,R0,R1
    loadi R3, R3
    outchar R3, R1
    inc R1
    cmp R1, R2

    jne printtelaComecoScreenLoop

  pop R3
  pop R2
  pop R1
  pop R0
  rts


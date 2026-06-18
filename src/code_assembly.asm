.NOLIST
.INCLUDE "m328Pdef.inc"
.LIST

; atribuição de nome de hardware e pinos

.equ INTERRUPTOR = PD2     ; D2 (Entrada c/ pull-up, ativo LOW)
.equ SENSOR      = PD3     ; D3 (Entrada c/ pull-up, ativo LOW)
.equ LED         = PD4     ; D4 (Saída, ativo HIGH)
.equ SEG_G       = PD5     ; D5 (Saída, Segmento G do display)

.equ ContDez     = PC0     ; C0 (Base do Transistor da Dezena)
.equ ContUni     = PC1     ; C1 (Base do Transistor da Unidade)

.equ DISPLAY     = PORTB   ; PB0-PB5 = Segmentos A-F
.equ CONTROLE    = PORTC   ; Porta dos transistores

.equ FLAG_OVERRIDE = 0

; Regs
.def AUX      = R16
.def UNIDADE  = R20
.def DEZENA   = R21
.def FLAG_REG = R22

; interromper 

.ORG 0x0000
    RJMP Inicializacoes

.ORG INT0addr            ; Interrupção do Botão (PD2)
    RJMP ISR_Botao

.ORG INT1addr            ; Interrupção do Sensor (PD3)
    RJMP ISR_Sensor

.ORG OC1Aaddr
    RJMP ISR_Timer1

; inicio
.ORG 0x0034
Inicializacoes:
    ; Configuração da Pilha
    LDI AUX, HIGH(RAMEND) ; Carrega o byte mais significativo do fim da memória RAM no AUX
    OUT SPH, AUX          ; Move para o SPH
    LDI AUX, LOW(RAMEND)  ; Carrega o byte menos significativo do fim da memória RAM no AUX
    OUT SPL, AUX          ; Move para o SPL

    ; PORTB - Display
    
    LDI AUX, 0b00111111        
    OUT DDRB, AUX         ; Define os pinos PB0 a PB5 como saída
    CLR AUX               ; Zera o AUX                  
    OUT PORTB, AUX        ; Zera as saídas da Porta B
    
    ; PORTD
    
    LDI AUX, (1<<LED)|(1<<SEG_G) ; Seta os bits para LED
    OUT DDRD, AUX         ; Define LED e SEG_G como saída            
    LDI AUX, (1<<INTERRUPTOR) ; Seta o bit do botão como 1
    OUT PORTD, AUX        ; Pull-up no pino PD2           

    ; PORTC
    ; C0 - Dezena C1 - Unidade
    LDI AUX, (1<<ContDez)|(1<<ContUni) ; Prepara os bits PC0 e PC1 como 1
    OUT DDRC, AUX         ; Define PC0 e PC1 como saída
    OUT PORTC, AUX        ; Coloca PC0 e PC1 em high            
    LDI UNIDADE, 0        ; Inicia o tempo com 0 nas unidades
    LDI DEZENA, 0         ; Inicia o tempo com 0 nas dezenas
    CLR FLAG_REG          ; Zera todas as flags

    

    CLR AUX               ; Zera o AUX
    STS TCCR1A, AUX       ; Zera o controle A do Timer 1
    LDI AUX, (1<<WGM12)|(1<<CS12)|(1<<CS10) ; Modo CTC e Prescaler de 1024
    STS TCCR1B, AUX       ; Salva no controle B do Timer 1
    LDI AUX, HIGH(15624)  ; Carrega a parte alta do valor 15624
    STS OCR1AH, AUX       ; Salva no registrador de comparação High
    LDI AUX, LOW(15624)   ; Carrega a parte baixa do valor 15624
    STS OCR1AL, AUX       ; Salva no registrador de comparação Low
    LDI AUX, (1<<OCIE1A)  ; Prepara a ativação da interrupção por comparação A do Timer 1
    STS TIMSK1, AUX       ; Habilita a interrupção no registrador de máscara de timer

    LDI AUX, (1<<ISC11)|(1<<ISC10)|(1<<ISC01)|(0<<ISC00) ; INT1 borda de subida, INT0 borda de descida 
    STS EICRA, AUX        ; Configura os gatilhos no registrador de controle de interrupção externa

    LDI AUX, (1<<INT1)|(1<<INT0) ; Prepara ativação de INT1 e INT0
    OUT EIMSK, AUX        ; Habilita as interrupções externas no registrador de máscara 

    SEI                   ; Set Global Interrupt Flag                   

; main

Principal:
    SBIS PIND, SENSOR ; Verificamos o pino do sensor, caso esteja baixa (detectando presença) limpa a flag de override, iniciando novamente o sistema         
    CBR FLAG_REG, (1<<FLAG_OVERRIDE)

    CPI DEZENA, 0 ; Comparação da dezena com 0
    BRNE Verifica_Flag_LED ; Se não for igual, verificar a flag do LED com a sub-rotina
    CPI UNIDADE, 0 ; Comparação da unidade com 0
    BRNE Verifica_Flag_LED ; Se não for igual, verificar a flag do LED com a sub-rotina

    CBI PORTD, LED ; (Clear Bit in I/O Register), se ambos Unidade e Dezena forem 0, desligar o LED
    RJMP Atualiza_E_Repete ; Pulo direto para a atualização do display

Verifica_Flag_LED:
    SBRS FLAG_REG, FLAG_OVERRIDE ; Pula para a próxima instrução caso o bit FLAG_OVERRIDE setado
    SBI PORTD, LED ; Se a flag estiver em 0, ligar o LED
    SBRC FLAG_REG, FLAG_OVERRIDE ; Pula para a próxima instrução caso o bit FLAG_OVERRIDE esteja zerado
    CBI PORTD, LED ; Se a flag estiver e m1, desligar o LED

Atualiza_E_Repete:
    RCALL AtualizaDisplay ; Chama a sub-rotina de atualização do display
    RJMP Principal ; Retorna ao início do loop principal

ISR_Botao:
    PUSH AUX              ; Salva o AUX atual na pilha
    IN AUX, SREG          ; Lê SREG no AUX
    PUSH AUX              ; Salva o AUX (com SREG) na pilha

    SBR FLAG_REG, (1<<FLAG_OVERRIDE) ; Coloca o bit de Override no FLAG_REG
    LDI DEZENA, 0         ; Zera a contagem de Dezena
    LDI UNIDADE, 0        ; Zera a contagem de Unidade

    POP AUX               ; Restaura o registrador de status da pilha
    OUT SREG, AUX         ; Escreve no registrador de status
    POP AUX               ; Restaura o valor original do AUX na pilha
    RETI                  ; Retorno da interrupção

ISR_Sensor:
    PUSH AUX              ; Salva o AUX na pilha
    IN AUX, SREG          ; Lê SREG no AUX
    PUSH AUX              ; Salva o AUX (com SREG) na pilha

    SBRC FLAG_REG, FLAG_OVERRIDE ; Se a flag de Override estiver em 0, pula para a próxima instrução
    RJMP Fim_ISR_Sensor   ; Se estiver em 1, vai para o fim (não acender)

    LDI DEZENA, 1         ; Reinicia o tempo para 15 segundos caso o Override seja 0
    LDI UNIDADE, 5        ; Reinicia as unidades pra 5
    CLR AUX               ; Zera o AUX
    STS TCNT1H, AUX       ; Zera a parte alta do contador do Timer 1
    STS TCNT1L, AUX       ; Zera a parte baixa do contador do Timer 1

Fim_ISR_Sensor:
    POP AUX               ; Restaura o registrador de status da pilha
    OUT SREG, AUX         ; Escreve no registrador de status
    POP AUX               ; Restaura o valor original do AUX na pilha
    RETI                  ; Retorno da interrupção

AtualizaDisplay:

    CBI CONTROLE, ContDez ; Desliga o controle do display das dezenas
    CBI CONTROLE, ContUni ; Desliga o controle do display das unidades


    MOV AUX, UNIDADE      ; Coloca o valor da unidade no AUX
    RCALL Decodifica      ; Chama a rotina de decodificação

    MOV AUX, R0           ; Colocando o padrão da rotina para o AUX
    ANDI AUX, 0x3F        ; Máscara para pegar apenas os bits 0 a 5          
    OUT PORTB, AUX        ; Envia os bits dos segmentos para a porta B

    SBRC R0, 6            ; Pula a instrução se o bit 6 for 0                   
    SBI PORTD, SEG_G      ; Se o bit 6 for 1, liga o pino PD5            
    SBRS R0, 6            ; Pula a instrução se o bit 6 for 1                  
    CBI PORTD, SEG_G      ; Se o bit 6 for 0, desliga o pino PD5         

   
    SBI CONTROLE, ContUni ; Liga o transistor que ativa o display para as unidades
    RCALL AtrasoMultiplex ; Chama o delay para a luz ser perceptível para o olho humano

    
    CBI CONTROLE, ContUni ; Desliga o transistor das unidades antes de efetuar a troca do número


    MOV AUX, DEZENA       ; Copia o valor da dezena para AUX
    RCALL Decodifica      ; Chama a rotina de decodificação

   






    MOV AUX, R0           ; Colocando o padrão da rotina para o AUX
    ANDI AUX, 0x3F        ; Máscara para pegar apenas os bits 0 a 5  
    OUT PORTB, AUX        ; Envia os bits dos segmentos para a porta B


    SBRC R0, 6            ; Pula a instrução se o bit 6 for 0
    SBI PORTD, SEG_G      ; Se o bit 6 for 1, liga o pino PD5  
    SBRS R0, 6            ; Pula a instrução se o bit 6 for 1
    CBI PORTD, SEG_G      ; Se o bit 6 for 0, desliga o pino PD5

    
    SBI CONTROLE, ContDez ; Liga o transistor que ativa o display para as dezenas
    RCALL AtrasoMultiplex ; Chama o delay para a luz ser perceptível para o olho humano

 
    CBI CONTROLE, ContDez ; Desliga o transistor das unidades antes de efetuar a troca do número

    RET                   ; Retorna para o loop principal


AtrasoMultiplex:
    LDI R18, 50          ; Carrega o valor 50 no registrador
L_AM1:
    LDI R19, 200         ; Carrega o valor 200 no registrador
L_AM2:
    NOP                  ; Gasto de 1 ciclo de clock
    DEC R19              ; Decremento em R19
    BRNE L_AM2           ; Volta para L_AM2 caso R19 não seja 0
    DEC R18              ; Decremento em R18
    BRNE L_AM1           ; Volta para L_AM1 caso R18 não seja 0
    RET                  ; Retorno sub-rotina


Decodifica:
    LDI ZH, HIGH(Tabela<<1) ; Carrega na memória flash o endereço alto da tabela
    LDI ZL, LOW(Tabela<<1)  ; Carrega na memória flash o endereço baixo da tabela
    ADD ZL, AUX          ; Soma o valor do dígito ao endereço base
    BRCC le_tab          ; Se não houver carry, pula para ler a tabela
    INC ZH               ; Se houver carry. incrementa o endereço alto
le_tab:
    LPM R0, Z            ; Lê o byte da memória Flash apontado por Z e salva o valor em R0
    RET                  ; Retorno da sub-rotina


ISR_Timer1:
    PUSH AUX             ; Insere AUX na pilha
    IN AUX, SREG         ; Lê SREG
    PUSH AUX             ; Insere SREG na pilha

    SBRC FLAG_REG, FLAG_OVERRIDE ; Se não houver desligamento forçado, pula a próxima instrução
    RJMP Avalia_Zero     ; Se o botão foi apertado, não renova o tempo e avalia a subtração

    SBIS PIND, SENSOR    ; Caso esteja detectando movimento ativamente, pula para a próxima
    RJMP Avalia_Zero     ; Se estiver inativo, avalia a subtraçao do tempo  

    LDI DEZENA, 1        ; Se estiver detectando movimento, trava o tempo em 15
    LDI UNIDADE, 5       ;
    RJMP Fim_ISR         ; Pula a subtração e vai para o fim         

Avalia_Zero:
    CPI DEZENA, 0        ; Verifica se a dezena é 0
    BRNE Decrementa_Tempo ; Se a dezena não for 0, ainda tem tempo, vai decrementar
    CPI UNIDADE, 0       ; Verifica se a unidade é 0
    BREQ Fim_ISR         ; Se dezena for 0 e unidade for 0, o tempo acabou. Pula pro fim sem decrementar

Decrementa_Tempo:
    CPI UNIDADE, 0       ; Verifica se a unidade é 0
    BRNE Sub_Unidade     ; Subtrai a unidade caso não seja
    DEC DEZENA           ; Decrementa a dezena caso a unidade seja 0
    LDI UNIDADE, 9       ; A unidade vira 9
    RJMP Fim_ISR         ; Pula para o fim

Sub_Unidade:
    DEC UNIDADE          ; Decremento da unidade

Fim_ISR:
    POP AUX              ; Restaura o registrador de status da pilha
    OUT SREG, AUX        ; Escreve no registrador de status
    POP AUX              ; Restaura o valor original do AUX na pilha
    RETI                 ; Retorno da interrupção

Tabela:
    .DB 0x3F, 0x06 ; 0, 1
    .DB 0x5B, 0x4F ; 2, 3
    .DB 0x66, 0x6D ; 4, 5
    .DB 0x7D, 0x07 ; 6, 7
    .DB 0x7F, 0x6F ; 8, 9

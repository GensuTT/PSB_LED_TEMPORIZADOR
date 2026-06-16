# Sistema de Iluminação Inteligente com Temporizador

#### Universidade Federal da Bahia  
#### **Disciplina:** Programação de Software Básico  
#### **Professor(a):** Euclerio Barbosa
#### **Disciplina-Ano:** MATA49 - 2026.1  

---

##  Descrição do Projeto

Este projeto consiste em um Sistema de Iluminação Inteligente com controle de tempo e detecção de presença. O sistema foi desenvolvido para gerenciar o acionamento de um LED com base na movimentação do ambiente e intervenção manual, operando da seguinte maneira:

* **Acionamento Automático:** Um sensor de movimento detecta a presença no ambiente e acende a iluminação (representada por um LED).
* **Temporizador Visual:** Simultaneamente ao acionamento, um display duplo de 7 segmentos inicia uma contagem regressiva utilizando a técnica de multiplexação.
* **Reinicialização por Movimento:** Caso o sensor detecte um novo movimento enquanto a luz estiver acesa, o temporizador é automaticamente reiniciado, mantendo o ambiente iluminado.
* **Controle Manual (Desligamento Forçado):** O sistema possui um botão que, ao ser pressionado, interrompe a contagem e força o desligamento imediato do LED a qualquer momento. 

---

##  Integrantes

* **Moisés Santana** – @mosasantana  (colaborou com o circuito físico, na adição de imagens e readme)
* **Lucca Lobo** – @Luccacalu (colaborou no circuito digital e na construção do circuito físico)
* **Gustavo Silva** – @guspink (colaborou no código e nos comentários do mesmo)
* **Lucas da Costa Ramos** - @LucasRamows (colaborou no código e testes do mesmo)
* **Matheus Santos** - @GensuTT (colaborou na documentação e montagem do circuito físico) 


---

##  Tecnologias e Componentes Utilizados

* Arduino Uno R3 (ATMEGA328p)
* 2 Displays de 7 segmentos cátodo comum
* 1 Sensor de movimento PIR HC -SR501
* 1 LED 5 mm azul
* 2 Protoboards 830 pontos
* 3 Kits jumpers macho-macho e 3 kits jumpers macho-fêmea
* 2 Transistores BC547
* 1 botão
* 8 resistores de 220 ohms
* 2 resistores de 1k ohm

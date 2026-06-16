# Guia de uso:
Esse guia tem como objetivo mostrar, na prática, como utilizar/operar nosso projeto.

**Ligar e inicializar:** 

Inicialmente, deve-se conectar o arduíno uno à porta USB do pc para energizar o protoboard. Ao iniciar, os displays mostrarão "00". 

**Acionando o sensor de movimento:**

Assim que o detector detectar movimento, o led acenderá e o contador irá para 15 e começará uma contagem regressiva até o 00. Caso detecte movimento novamente, o contador será resetado (voltará ao 15).

**Parada e interrupção:**

Caso o Contador chegue a "00", o led apagará e será necessário que o detector detecte outro movimento para acender novamente. Além disso, há também um botão de interrupção que, ao ser acionado, interrompe o fluxo independente da contagem do display. Ou seja, o led é apagado e o contador vai a 00. 

# Funcionamento: 

#### A Ideia por trás:

A ideia do circuito é aplicar o funcionamento de uma luz que acende automaticamente quando detecta movimento em um cômodo. Dessa forma, quando o detector de movimento percebe movimentação, o led é aceso e o temporizador de 15 segundos é iniciado. Quando o tempo se esgota (chega à 00) o led é apagado, mas se o detector detecta qualquer outro movimento, o tempo volta para 15 segundos e volta a ser decrementado regressivamente. Um detalhe importante é que temos um botão de interrupção que, quando acionado, interrompe o fluxo normal do circuito, fazendo com que o led se apague e o contador vá para "00". 

#### Como foi construído:

Inicialmente, foi construído o diagrama do circuito no simulIDE, onde fizemos a multiplexação de dois displays de 7 segmentos cátodo comum, onde cada display está conectado a um transistor (para caso acendesse todos os segmentos do display, esse não ser queimado). Ainda sobre multiplexação, quando fizemos o circuito físico, usamos os jumpers macho-macho para passar corrente dos pinos de um display para outro display, além de configurarmos manualmente o sensor de movimento para o mínimo de distância e tempo de envio de sinal de alta voltagem. Usamos resistores individuais de 220 ohms nos pinos individuais de segmentos do displays para que as luzes não ficassem fracas se muitos segmentos fossem acesos ao mesmo tempo. Para os transistores, utilizamos resistores de 1k ohm pois eles não necessitam de muita energia para ativação. Ademais, utilizamos a combinação de fios jumpers macho-fêmea e macho-macho para passarmos de um protoboard para outro (utilizamos dois por conta do espaço necessário e facilidade de manutenção). É válido ressaltar que ao contrário do botão, que necessita do pullup ativado, o sensor de movimento não necessita de pullup ou pulldown, já que ele possui um circuito próprio e está sempre alimentando com 0 ou 1. 


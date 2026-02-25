---
layout: post
title: "O que é um autômato?"
author: "Jefferson Quesado"
tags: conceito autômato
base-assets: "/assets/o-que-e-automato/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

> Baseado na minha resposta sobre [O que é um autômato?](https://pt.stackoverflow.com/a/260964/64969)

&nbsp;

> Não quer saber o que eles [autômatos] comem ou como eles se reproduzem?

-- Maniero Junior, Antonio [2017](https://pt.stackoverflow.com/questions/260864/o-que-%c3%a9-um-aut%c3%b4mato#comment534836_260864)

Autômatos comem letras/tokens discretos, vivendo em espaços matemáticos. A
priori, se a matemática não existir, eles estão no mundo imaginário. Se a
matemática existir, então eles estão no plano das ideias.

Eles se reproduzem por geração espontânea, não possuem código genético. Devido
a não terem hereditariedade, eles não estão sujeitos a evolução

Existem entidades que possuem código genético e desse código genético produzem
autômatos. Nesse sentido, o paralelo "autômato" com a biologia seria mais
parecido com "proteínas".

# O que é um autômato?

Autômato, como dito acima, é uma entidade matemática. A etimologia da palavra
vem desde a época das
[máquinas analógicas auto-operadas](https://en.wikipedia.org/wiki/Automaton).
Existem sistemas auto-operados desde o período helenístico, alguns até
anteriores a isso. A única coisa que precisa para manter esses sistemas
funcionando é uma fonte de energia.

Um relógio de corda é um mecanismo auto-operado. A única coisa que você precisa
fornecer a ele é energia. Você fornece essa energia "dando corda", então esse
energia fica armazenada em um capacitor através de energia elástica e fica
abastecendo o mecanismo conforme a energia vai sendo necessária.

Outro exemplo de autômato de corda é esse aqui:

![Um autômato de um arqueiro japonês atirando uma flecha]({{ page.base-assets | append: "arco-flecha.gif" | relative_url }})

Um autômato que ficou conhecido no cinema foi
[A invenção de Hugo Cabret](https://en.wikipedia.org/wiki/Hugo_Cabret), que
desenha cenas de filmes clássicos.

Matematicamente, os autômatos não tem a limitação física de necessitar de
energia para operar, pois no mundo matemático não há problemas com conservação
e gasto de energia. Eles simplesmente são "mecanismos" auto-operados que
funcionam em cima de uma _entrada_.

De maneira típica, a _entrada_ na qual eles trabalham é constituída de células
discreta, cada célula dessa contendo um pedaço de informação. Muitas vezes essa
informação é representada por um número ou uma letra. O mais correto seria
chamar de **símbolo de informação**, ou **token de informação**.

Como a entrada é fornecida através de símbolos?, como o autômato consegue
identificar onde começa e onde termina a informação e onde começa outra?

O modo como essa informação é passada ao autômato varia. Normalmente é uma fita
semi-infinita. Podem ser múltiplas fitas semi-infinitas, ou mesmo infinitas
em ambas as direções. Mas pode ser um plano. Ou um espaço tridimensional. Ou
até mesmo `n`-dimensional. Seja lá como for, o autômato tem uma (ou mais)
"cabeça" de onde ele lê a informação. Semelhante ao HD magnético, que tem
cabeça de leitura/escrita de informações, assim o autômato percorre interage
com sua entrada.

> Uma fita semi-infinita tem o mesmo poder computacional que uma fita infinita
> para ambos os lados. Imagine uma situação hipotética em que uma Máquina de
> Turing encontra-se no começo dos dados da fita e "precisa" escrever algo no
> começo da fita. Em uma fita infinita ele só precisaria ir uma posição a mais
> para a esquerda e, então, escrever o que se necessita.
> 
> Numa fita semi-infinita, entretanto, isso não é possível. Não existe mais
> nada "à esquerda" do começo dos dados. O que poderia ser feito nesse caso
> seria um deslocamento de TODOS os dados da fita uma posição para a direita,
> escrevendo o símbolo desejado no mais a esquerda possível. Esse problema é
> uma instância do
> [Hotel de Hilbert](https://en.wikipedia.org/wiki/Hilbert%27s_paradox_of_the_Grand_Hotel),
> onde é necessário acomodar mais um hóspede e ele é acomodado à esquerda. Se
> for necessário, é possível acomodar mais do que um hóspede, deslocando quem
> já está hospedado `n` quartos para a direita.

Tem alguns modelos matemáticos que a Máquina de Turing (o mais poderoso dos
autômatos) tem 3 fitas semi-infinitas:

1. **fita de leitura**, onde a cabeça só pode ler e só pode ir para frente; sem
   escritas ou _back-tracking_
2. **fita de escrita**, onde a cabeça só pode escrever e ir para frente; sem
   leituras ou _back-tracking_
3. **fita de trabalho**, onde a cabeça se movimenta a vontade e onde ocorre a
   computação; a memória RAM do computador seria essa "fita de trabalho"

Esse modelo matemático oferece tanto poder computacional que uma Máquina de
Turing com apenas uma única fita semi-infinita, onde ele pode realizar escritas
e leituras ilimitadamente e não tem limitação da direção do movimento da
cabeça. A vantagem do modelo que separa em 3 fitas é que algumas propriedades
ficam mais fáceis de serem demonstradas.

# O que fazem os autômatos? Para que servem?

Os autômatos são entidade que vão ler as informações contidas na cabeça de
leitura, possivelmente alterar alguma informação através da cabeça de escrita e
movimentar as cabeças em direções arbitrárias.

Então, eles leem e escrevem. Eles "só" fazem isso. Normalmente eles possuem
estado interno que indicam o que fazer a seguir.

Para representar um autômato, normalmente fazem um desenho através de um grafo
contendo as seguintes informações:

1. os estados (vértices)
2. as transições (arestas)
3. o que é necessário para a transição ocorrer (rótulo das arestas)

Dependendo do autômato, a informação para colocar no rótulo pode variar. Por 
xemplo, em autômatos finitos (entrada em fita finita, cabeça apenas de leitura,
toda leitura movimenta a cabeça uma posição para a esquerda), só é necessário
colocar qual a informação que precisa ser lida para indicar qual a mudança de
estado que vai ocorrer. Veja abaixo:

![exemplo de autômato finito][dfa]

Em autômatos de pilha, você tem a entrada igual a do autômato finito e, também,
possui uma pilha de onde você pode ler e escrever elementos nela (mas apenas na
última posição). Toda leitura da pilha implica em, necessariamente, remover o
último elemento do topo; se quiser manter a pilha intacta após uma leitura,
você deve escrever novamente esse elemento na pilha. Você também pode não ler a
pilha. Assim como pode escrever na pilha sem consumir nada. Veja abaixo:

![exemplo de autômato de pilha]({{ page.base-assets | append: "pda.png" | relative_url }})

Olhe para a primeira transição: `-,-/S`. Isso indica 3 coisas:

1. o traço `-` antes da vírgula indica que ele simplesmente ignorou a entrada,
   então essa transição ocorre sem leituras
1. `-/S` indica que nada é lido da pilha através do `-` antes da barra; e
1. o símbolo `S` é inserido em seu topo

Olhe para a segunda transição, `-,S/-`:

1. novamente, ignora a entrada com o traço
1. é necessário ter `S` no topo da pilha, símbolo esse que, por ter sido lido,
   será sacado fora
1. o traço após a barra em `S/-` indica que não é inserido nada na pilha

Só mais uma transição, `a,S/SBB`:

1. é necessário ler `a` da entrada
1. é necessário ter `S` no topo da pilha
1. vai ser escrito `SBB`, nessa ordem, então o próximo topo da pilha é `S`,
   então `B`, e então terá mais um `B`.

Em Máquinas de Turing de uma fita, como a cabeça se move livremente, você
precisa indicar em cada transição:

1. o símbolo lido (ou algo para indicar que tanto faz)
1. o símbolo escrito (ou algo para indicar que não vai escrever)
1. a direção da leitura

No final, o autômato vai fazer uma computação em cima dessas informações. Sem
precisar de estímulo externo, apenas fornecendo a ele a entrada. Essa
computação pode ser para produzir um novo valor (quando o retorno está contido
em alguma fita/plano/hiperplano de escrita) ou então simplesmente para tomar
uma decisão; no caso da decisão, o estado interno em que o autômato finaliza a
computação indica se aceitou ou recusou a entrada. Voltando ao primeiro
autômato (o autômato finito):

![exemplo de autômato finito][dfa]

Os seguintes estados são de aceitação da entrada:

1. `q0`
1. `qb1`
1. `qb2`
1. `qa`

O seguinte estado indica recusa da entrada:

1. `damnation`

Esse autômato reconhece todas as palavras que não contenham a substring `bbab`.
Então, não importa qual seja sua entrada, se ela contiver `bbab` em algum
lugar, ela vai parar no estado `damnation` e sua palavra será recusada ao
terminar a leitura. Tente executar esse autômato na mão, você aprenderá muito
com ele.

# Onde vivem os autômatos?

Vive na matemática e na cabeça dos nerds =D

---

# Classificação de autômatos

Existem algumas maneiras de classificar os autômatos. Uma delas é diferenciar
um autômato de processamento/computação, onde algo relevante será escrito na
fita de saída, dos autômatos de decisão, onde nada precisa ser escrito e só se
interessa se o seu estado final é um estado de aceitação ou não.

Mas eu prefiro ordená-los pelo seu poder computacional (e características
secundárias de seu funcionamento).

## Máquina de estados finito determinística

Também conhecido como **autômato finito determinístico**, AFD.

Esses autômatos são capazes de reconhecer qualquer gramática regular. Não
importa o quão complicada ela seja, esse autômato a reconhecerá.

Expressões regulares (sem look ahead e outras coisas estranhas) são descrita
por gramáticas regulares, então cada expressão regular terá seu autômato finito
determinístico.

Eles são caracterizados por:

- qualquer leitura avança a fita de leitura, **sempre**
- avançar (na leitura) sempre, retroceder (na leitura) jamais
- não há fita de trabalho
- sabendo o estado atual e o caracter disponível na cabeça de leitura, eu
  **sempre** conheço o estado seguinte, e eu sei que só pode haver um
- só posso mudar de estado com leitura (sem transições lambda/vazias)

AFDs podem gerar saída sim. Se a escrita na fita de saída for determinada única
e exclusivamente pelo estado de destino, então temos uma
[máquina de Moore](https://en.wikipedia.org/wiki/Moore_machine). Caso a
transição disparada seja a responsável por produzir o símbolo na fita de saída,
então temos uma
[máquina de Mealy](https://en.wikipedia.org/wiki/Mealy_machine).

## Máquina de estado finito não determinística sem transições lambda

Também conhecido como autômato finito não determinístico sem transições lambda,
AFN sem lambda.

A diferença deste autômato para o AFD é um relaxamento nas restrições do AFD.

> Restrição removida:
> 
> - sabendo o estado atual e o caracter disponível na cabeça de leitura, eu
>   **sempre** conheço o estado seguinte, e eu sei que só pode haver um

Ela é relaxada, permitindo que, para um mesmo símbolo de leitura, possam haver
2 ou mais destinos possíveis.

Computacionalmente, pode parecer que reconhece mais do que o AFD. Mas isso não
é verdade, tudo que uma AFN sem lambda reconhece, há algum AFD que reconheça.
Ou seja:

- ambos os autômatos possuem o mesmo poder computacional
- é possível obter um AFD a partir de um AFN

## Máquina de estados finito não determinística com transições lambda

Também conhecido como autômato finito não determinístico, AFN.

Esse autômato permite a existência de mudança de estado sem consumo de símbolos
da fita de leitura. A essa mudança de estado sem consumir leitura damos o nome
de "transição lambda".

AFNs podem ser reduzidos para AFDs, sempre. Ambos possuem o mesmo poder
computacional.

## Autômatos de pilha

Semelhante à máquina de estados finito não determinístico com transições
lambda, mas além da fita da entrada ele trabalha com uma fita chamada de
"pilha". Essa fita de trabalho tem três operações:

- lê o token
- apaga o token, movendo a cabeça de leitura para à esquerda
- insere um novo token, movendo a cabeça de leitura para a direita

Transições precisam especificar o que estão lendo da pilha e o que estão
escrevendo nela. Como listado acima, não há opção de acessar outra parte da
memória, apenas um único símbolo, que é o último inserido.

Essa tipo de autômato consegue reconhecer gramáticas livres de contexto.

## Autômato de duas pilhas

Semelhante ao anterior, porém agora existem duas pilhas para trabalho. As
operações em cada uma dessas pilhas continuam as mesmas. Porém, como é possível
simular uma fila com duas pilhas, o poder computacional deste autômato é o
mesmo do poder computacional de um autômato de fila.

As transições nesse tipo de autômato precisam informar para cada pilha (e que
precisam ser pilhas diferenciáveis) está sendo lido de token/escrito de token.

## Autômato de fila

De modo geral, é muito similar a um autômato de pilha. Porém as operaçòes na
fita de trabalho remontam operações de fila no lugar de remontar operações em
pilhas.

Autômatos de fila são tão poderosos quanto máquinas de Turing no reconhecimento
de palavras (ie, "isto é uma solução para o meu problema?"). Você pode conferir
essa equivalência em
[Uma demonstração de que Autômatos de Fila equivalem a Máquinas de Turing em poder computacional, parte 1]({% post_url 2022/2022-05-28-automato-fila-equiv-mt-pt1 %}).

> Sim, eu sei, ainda preciso terminar a parte 2 desse artigo.

## Máquinas de Turing

O mais poderoso dos autômatos, capaz de reconhecer tudo que é computável. Pode
ser modelado como se existisse uma única fita, seja para trabalho, input,
saída, etc.

Esse aut6omato funciona inspecionando o elemento atual da fita, escrevendo algo
naquele lugar (pode ser o mesmo símbolo que foi lido), mudar de estado e
escolher se a cabeça de leitura vai para a esquerda ou para a direita.


 [dfa]: {{ page.base-assets | append: "afd.png" | relative_url }}
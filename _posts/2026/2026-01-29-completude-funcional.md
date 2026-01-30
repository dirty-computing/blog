---
layout: post
title: "Caranguejos como computadores completos?"
author: "Jefferson Quesado"
tags: matemática lógica circuitos-lógicos
base-assets: "/assets/completude-funcional/"
---

> Baseado na _thread_ do Twitter
> [https://twitter.com/JeffQuesado/status/1477843585919770626](https://twitter.com/JeffQuesado/status/1477843585919770626)

O usuário do Twitter [@edo9k](https://twitter.com/edo9k) respondeu uma
brincadeira sobre modelos de computação com o seguinte tuíte:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Water based computing considered harmful.<br>Move your system to crab. <a href="https://t.co/c5MF0aBny6">https://t.co/c5MF0aBny6</a></p>&mdash; Eduardo França (@edo9k) <a href="https://twitter.com/edo9k/status/1475994283303972865?ref_src=twsrc%5Etfw">December 29, 2021</a></blockquote> <!-- <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script> -->

Em cima do comportamento desses caranguejos, foram feitos 2 portas lógicas. Se
quiser se aprofundar mais sobre o que estava sendo discutido, só ler o artigo
no ArXiv [Robust soldier crab ball gate](https://arxiv.org/pdf/1204.1749) (ou
da versão que foi feito upload para o Wolfram:
[Robust soldier crab ball gate](https://wpmedia.wolfram.com/sites/13/2018/02/20-2-2.pdf)).

# Porta OR

[![Porta OR de caranguejos]({{ page.base-assets | append: "or-gate.png" | relative_url }})](https://wpmedia.wolfram.com/sites/13/2018/02/20-2-2.pdf)

> Extraído do Wolfram

Na porta `OR`, chegam dois sinais de caranguejos e tem um único output. Ela é
desenhada de tal forma que, caso tenha pelo menos um sinal chegando, ele saia
pelo output; e caso tenha dois sinais chegando, eles se misturam e saem no
output. A tabela verdade é a mesma da porta `OR` tradicional (tome com `A` e
`B` os dois sinais de input):

{:class="marked-table w90 centered-head"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    0     |
|   1   |   0   |    1     |
|   0   |   1   |    1     |
|   1   |   1   |    1     |


# Porta AND / NOT a AND b / a AND NOT b

[![Porta AND de caranguejos]({{ page.base-assets | append: "and-gate.png" | relative_url }})](https://wpmedia.wolfram.com/sites/13/2018/02/20-2-2.pdf)

A segunda porta lógica proposta... bem, ela tem 3 saídas:

- AND
- NOT a AND b
- a AND NOT b

Se os caranguejos saírem pelo centro, significa que houve caranguejo em ambos
os sinais. Caso saia do lado esquerdo, isso significa que houve apenas o sinal
`b`, portanto ele é algo como `b AND NOT a` (ou equivalentemente
`NOT a AND b`). E se sair apenas do lado direito, temos `a AND NOT b`:

{:class="marked-table w90 centered-head"}
|   A   |   B   |  left  | center | right |
| ----: | ----: |  ----: | -----: | ----: |
|   0   |   0   |    0   | 0      | 0     |
|   1   |   0   |    0   | 0      | 1     |
|   0   |   1   |    1   | 0      | 0     |
|   1   |   1   |    0   | 1      | 0     |

# Porta NOT?

O artigo não traz esquema da porta NOT, apesar de afirmar que a fizeram. Como
não deixaram claro no artigo como ela foi desenhada, vou assumir que só tenho
as outras duas portas para trabalhar.

# Completude funcional

Mas, o que seria essa "completude funcional"? Bem, o ideal seria dizer que é um
"sistema computacional capaz de rodar Doom". Mas, vamos por outras
características? A Wikipedia define que a
[porta NAND](https://en.wikipedia.org/wiki/NAND_logic) tem completude funcional
porque toda relação booleana pode ser escrita usando apenas NAND. Então,
resumidamente, a "completude funcional" vem quando você consegue expressar
todas as operações lógicas, e as operações lógicas "básicas" são:

- AND
- OR
- NOT

Toda outra operação booleana você consegue fazer a partir dessas 3 operações.
E, como implicado pelo `NAND` que mencionei anteriormente, você consegue montar
essas 3 operações usando apenas `NAND`s, encadeados de maneira divertida.

Vou considerar aqui apenas operações binárias e unárias. Uma operação que pega
3 inputs e transforma em um único output pode ser interpretado como um
encadeamento de 2 operações binárias.

> Durante a escrita desse artigo, considere que 1 é `TRUE`, e que 0 é `FALSE`.
> Eu acho mais conveniente em tabelas e quando falo em circuito falar em termos
> de 0s e 1s, mas para falar das operações lógicas em si eu prefiro deixar
> explícito em texto corrido `TRUE` e `FALSE`.
> 
> Isso é apenas uma escolha estilística sem nenhuma implicação maior na leitura
> do artigo.

## Operações unárias

Eu sempre posso obter 2 saídas para cada entrada: `TRUE` ou `FALSE`. E para o
caso de uma única entrada, só posso ter 2 possíveis inputs: `TRUE` ou `FALSE`.

Vamos começar aqui pelo caso básico: eu repito o sinal que vem de entrada:

{:class="marked-table centered-head"}
| input | output |
| ---:  | ----:  |
| 0     |  0     |
| 1     |  1     |

Temos também a negação, que inverte o sinal:

{:class="marked-table centered-head"}
| input | output |
| ---:  | ----:  |
| 0     |  1     |
| 1     |  0     |

Mas, para ter totalmente as operações unárias, ainda faltam mais duas... Uma
que vai responder `TRUE` independente da entrada, e outra que vai responder
`FALSE` também independente da entrada. Na prática é como se elas fossem
funções constantes, em que o input é ignorado, podendo até mesmo serem elas
funções zero-árias.

Para a função que retorna `FALSE`:

{:class="marked-table centered-head"}
| input | output |
| ---:  | ----:  |
| 0     |  0     |
| 1     |  0     |

e `TRUE`:

{:class="marked-table centered-head"}
| input | output |
| ---:  | ----:  |
| 0     |  1     |
| 1     |  1     |

## Operações binárias

As operações básicas já foram apresentadas anteriormente: `AND` e `OR`.

`AND`:

{:class="marked-table w90 centered-head"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    0     |
|   1   |   0   |    0     |
|   0   |   1   |    0     |
|   1   |   1   |    1     |


`OR`:

{:class="marked-table w90 centered-head"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    0     |
|   1   |   0   |    1     |
|   0   |   1   |    1     |
|   1   |   1   |    1     |

Podemos também ter as funções triviais de retorno constante, como se fossem
zero-árias, como `FALSE`

{:class="marked-table w90 centered-head"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    0     |
|   1   |   0   |    0     |
|   0   |   1   |    0     |
|   1   |   1   |    0     |

e `TRUE`

{:class="marked-table w90 centered-head"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    1     |
|   1   |   0   |    1     |
|   0   |   1   |    1     |
|   1   |   1   |    1     |

Também podemos ter funções que simplesmente retornam um dos inputs. Como `A`

{:class="marked-table w90 centered-head"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    0     |
|   1   |   0   |    1     |
|   0   |   1   |    0     |
|   1   |   1   |    1     |

e `B`

{:class="marked-table w90 centered-head"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    0     |
|   1   |   0   |    0     |
|   0   |   1   |    1     |
|   1   |   1   |    1     |

Já falamos do `NAND`, né? `NAND` é o `NOT AND`, a negação do `AND`. Só alterar
os valores retornados:

{:class="marked-table w90 centered-head"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    1     |
|   1   |   0   |    1     |
|   0   |   1   |    1     |
|   1   |   1   |    0     |

Temos também o `NOR`, que é a simples negação do `OR` (parecido com o `NAND`):

{:class="marked-table w90 centered-head"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    1     |
|   1   |   0   |    0     |
|   0   |   1   |    0     |
|   1   |   1   |    0     |

De operações clássicas também temos o `XOR`:

{:class="marked-table w90 centered-head"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    0     |
|   1   |   0   |    1     |
|   0   |   1   |    1     |
|   1   |   1   |    0     |

E o `EQUIV`, ou `XNOR` já que na prática saber se os dois valores são iguais é
negar o `XOR`:

{:class="marked-table w90 centered-head"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    1     |
|   1   |   0   |    0     |
|   0   |   1   |    0     |
|   1   |   1   |    1     |

De operação booleana clássica de livro também tem a implicação, o `IMPLY`, que
retorna `FALSE` apenas quando a premissa é `TRUE` e o consequente é `FALSE`:

{:class="marked-table w90 centered-head"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    1     |
|   1   |   0   |    0     |
|   0   |   1   |    1     |
|   1   |   1   |    1     |

Eu poderia continuar até gerar todas as combinações. O que está faltando? Bem,
que tal... fazermos uma notação para identificar quem está faltando? Toda
entrada vem sempre no mesmo formato:

{:class="marked-table w90 centered-head"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    w     |
|   1   |   0   |    x     |
|   0   |   1   |    y     |
|   1   |   1   |    z     |

Ou seja, podemos representar o fluxo INTEIRO da operação lógica como sendo a
string de resultados `wxyz`. O `AND` nesse caso seria `0001`, e o `XOR` seria a
string `0110`. Então, aqui temos uma string de booleanos de tamanho 4. Eu posso
identificar cada elemento desses booleanos como sendo realmente um bit, e
atribuir para cada posição um valor. Lendo isso como sendo uma string em
little-endian, o `0001` do `AND` pode ser lido como o número 8! E portanto o
`XOR` seria 6!

Como temos uma string de binários de tamanho fixo 4, sabemos que temos um total
de 16 combinações: que seriam os números de 0 a 15. Vou mapear aqui as
operações que já fizemos com seus respectivos valores:

{:class="marked-table w90 centered-head"}
| op    | string | valor |
| :---- | :--:   | ---:  |
| AND   | 0001   |     8 |
| OR    | 0111   |    14 |
| FALSE | 0000   |     0 |
| TRUE  | 1111   |    15 |
| A     | 0101   |    10 |
| B     | 0011   |    12 |
| NAND  | 1110   |     7 |
| NOR   | 1000   |     1 |
| XOR   | 0110   |     6 |
| EQUIV | 1001   |     9 |
| IMPLY | 1011   |    13 |

Hmmm, ordenando pelo valor:

{:class="marked-table w90 centered-head"}
| op    | string | valor |
| :---- | :--:   | ---:  |
| FALSE | 0000   |     0 |
| NOR   | 1000   |     1 |
| XOR   | 0110   |     6 |
| NAND  | 1110   |     7 |
| AND   | 0001   |     8 |
| EQUIV | 1001   |     9 |
| A     | 0101   |    10 |
| B     | 0011   |    12 |
| IMPLY | 1011   |    13 |
| OR    | 0111   |    14 |
| TRUE  | 1111   |    15 |

Ou seja, ainda faltam: 2, 3, 4, 5 e 11. Bem, se `AND` e `OR` e `NOT` são
funcionalmente completos, isso significa que eu consigo expressar esses
elementos que faltam como apenas essas operações.

Para 2, `0100`, temos `a AND NOT b`.

3 `1100` e 5 `1010` são simples negações das entradas. 3 é `NOT b` e 5,
`NOT a`.

O 4 `0010` eu tenho apenas um único bit ligado, e é bastante semelhante ao 2,
porém ele ligar com o oposto dos sinais: `NOT a AND b`.

Finalmente, temos o 11 `1101`. Aqui, ele só é falso quando o sinal B é
verdadeiro e o sinal A é falso. Isso pode ser visto como a negação do
4 `0010`. Se para 4 tenho `NOT a AND b`, então para 11 tenho
`NOT (NOT a AND b)`.

## Pressupostos de circuitos

Aqui estamos lidando com circuitos, que posso pegar um input e dividir ele em
vários cantos. Ainda não usei isso no caso das operações faltantes, mas isso é
importante porque eu _posso_ e muitas vezes _devo_ repetir um input. Por
exemplo, para o `XOR`, eu preciso criar uma duplicação de sinal:

```none
(a OR b) AND NOT (a AND b)
```

Eu preciso nesse caso poder usar o sinal A múltiplas vezes, tal qual usar o
sinal B também.

Além dessa "puxada de fios", eu também posso simplesmente ignorar completamente
um input. Mas, se não satisfizer ignorar um input e eu _precisar_ usar, existe
uma estratégia para isso:

- achar uma tautologia com o sinal ignorado
- usar um `AND` com o sinal desejado e a tautologia

E você se pergunta "o que é uma tautologia"? Bem, algo que é simplesmente
sempre verdade. E nesse caso a tautologia não é equivalente a um sinal `TRUE`,
a tautologia deriva do input e de portas lógicas. E, sim, essa diferença é
importante.

Outra pressuposição importante é que os sinais são discretos e sempre tem o
valor de "presente" ou "ausente". Aqui, um `a AND a` tem o mesmo valor que um
simples `a`, não há nenhuma espécie de "soma" dos sinais de input.

## Derivando os operadores binários usando AND/OR/NOT

Vou continuar usando aqui o sistema de numeração usado em
[Operações binárias](#operações-binárias). No caso, por trivialidade eu tenho
as operações de valor 14 `0111` e 8 `0001`, já que são literalmente as
operações `OR` e `AND` e eu tenho acesso a essas operações.

Em cima disso, eu posso obter 1 `1000` e 7 `1110` negando o resultado dessas
operações: `NOT (a OR b)` vai ser a operação 1 e `NOT (a AND b)` vai ser a
operação 7.

Bem, e se eu quiser eu trivialmente verdadeiro? Diferentemente de uma função
zero-ária real, eu preciso derivar do input o valor, pois afinal nos foi dito
que AND + OR + NOT é funcionalmente completo. Como fazer isso então?

Bem, tem uma operação que é sempre verdade: OR recebendo um sinal verdadeiro e
um sinal falso. Seja com `false OR true` ou com `true OR false`, o resultado
dessas duas operações é `TRUE`. Então como consigo fazer essa operação?

Que tal pegar o mesmo sinal, negar ele, e passar tanto ele quanto a sua negação
como os inputs de um `OR`? Exatamente `a OR (NOT a)`. E com isso obtive uma
tautologia! Algo que é sempre `TRUE`!

Se eu quiser usar o sinal de `B` nesse caso eu posso fazer com ele uma
tautologia e aplicar um `AND` nele. Ou seja, a operação 15 `1111`, a que
retorna sempre `TRUE` em todas as circuntâncias, pode ser escrita como
`(a OR (NOT a)) AND (b OR (NOT b))`.

Ok, e para o sempre falso? Bem, se eu tenho algo que retorna sempre `TRUE`,
posso só negar isso, algo que é uma contradição. Para o operador 0 `0000`,
posso negar qualquer uma das tautologias ou então simplesmente negar o `AND`
que une as tautologias: `NOT ((a OR (NOT a)) AND (b OR (NOT b)))`.

Para pegar apenas o sinal de A? O operador 10 `0101`? Posso pegar `A` com uma
tautologia sobre B: `a AND (b OR (NOT b)))`.

> Equivalente para o sinal de B, operação 12 `0011`.

Para `NOT a` (operador 5 `1010`) é só negar o resultado do sinal A:
`NOT (a AND (b OR (NOT b))))`. E equivalente para o `NOT b` (operador 3
`1100`).

O `XOR` (como mostrado na [seção anterior](#pressupostos-de-circuitos)), que é
a operação 6 `0110`, é `(a OR b) AND NOT (a AND b)`. O `EQUIV`, operação 9
`1001`, é a negação disso: `NOT ((a OR b) AND NOT (a AND b))`.

O `IMPLY`, operação 13 `1011`, é `NOT (a AND (NOT b))`: não pode acontecer de
eu ter a premissa mas não ter o consequente.

As operações 2, 4 e 11 já foram mostradas [anteriormente](#operações-binárias)
em termos dos operadores AND/OR/NOT sobre as entradas, não se faz necessário
repetir novamente,

## Derivando AND/OR/NOT de NAND

Sabemos que NAND tem completude funcional. Ou seja, eu consigo fazer todas as
operações usando apenas o NAND. Então, se eu consigo fazer todas as operações,
eu posso fazer também as operações básicas de AND/OR/NOT.

Para fazer o `NOT`, só lembrar que `NAND` significa "not and". E o que acontece
se eu aplicar `AND` para o mesmo sinal? Bem, redundância, retorna ele mesmo,
independente de ser `TRUE` ou `FALSE`. Ou seja, `a AND a` é o equivalente a
`a`. E, bem, com um `NOT` na frente teríamos `NOT (a AND a)` que é equivalente
a `NOT a`. E, bem, `NOT (a AND a)` é a definição de `NAND` aplicado para o
mesmo sinal nos dois inputs. Ou seja, já construí o `NOT`!

E para construit o `AND`? Eu posso pegar a saída do `NAND` e aplicar um `NOT`.
Algo como: `(a NAND b) NAND (a NAND b)`. Isso pode ser feito ligando a saída de
`a NAND b` nos dois inputs do `NAND` seguinte.

Só falta o `OR` agora. O `OR` é o operador 14 `0111`, que é a negação do
operador 1 `1000`. O operador 1 foi descrito acima como `NOT (a OR b)`, mas ele
tem uma forma equivalente: `(NOT a) AND (NOT b)`. No caso, me interessa a
negação dessa operação: `NOT ((NOT a) AND (NOT b))`. E, bem, podemos expressar
tanto `AND` como `NOT` usando apenas `NAND`, né? Mas, primeiro, `NOT (x AND y)`
é a definição de `x NAND y`, portanto temos que naturalmente surge um `NAND`
aqui: `(NOT a) NAND (NOT b)`. Finalmente, podemos substituir os `NOT x` por
`x NAND x` e obter uma forma de `OR` usando apenas operador `NAND`:
`(a NAND a) NAND (b NAND b)`.

# Completude funcional com caranguejos?

Ok, vamos usar caranguejos agora... será que um circuito feito apenas com
caranguejos tem completude funcional? As operações disponíveis são:

- a OR b
- a AND b
- (NOT a) AND b
- a AND (NOT b)

Infelizmente nenhuma dessas operações disponíveis é capaz de gerar um valor
`TRUE` com base na ausência de caranguejos. Mas... e se eu considerar que além
desses 4 operadores eu também possa inserir caranguejos como um input
arbitrário? Tipo, se além disso eu tiver um `TRUE` como operação válida?

Assumindo um input A qualquer na operação `(NOT a) AND b`, e fixando no input
B o valor `TRUE`, teríamos `(NOT a) AND true`, que é equivalente a `NOT a`. E,
bem, com isso eu tenho a operação `NOT`! E eu já tenho garantido as operações
`AND` e `OR`. AND/OR/NOT é o primeiro exemplo de sistema com completude
funcional descrito, portanto as duas portas descritas no artigo junto com a
porta que sempre retorna caranguejo é um sistema com completude funcional
porque assim consigo simular esses 3 operadores e, portanto, todas as operações
booleanas.

Mas... bem, um dos pressupostos é que não há  "soma" de valores. E aqui nos
caranguejos claramente há a "soma" dos sinais na operação `AND`: ele vai ter o
dobro de caranguejos do que apenas um único sinal de caranguejo. Mas como isso
pode interferir? Bem, se eu precisar fazer um `a AND (b AND c)`, por exemplo.
`b AND c` vai ter como output um "sinal" de caranguejo de 2 clusteres, como se
tivesse "duas vezes" a força de um sinal de entrada comum. Nessa situação, a
colisão do cluster `b AND c` com o `a` pode fazer com que o output seja
diferente do esperado: memso que tenha sinal em `a`, em `b` e em `c`, é
provável que a saída seja `FALSE` para esse sistema. Nos 3 outputs do segundo
tipo de porta que ele apresenta, ele irá sair pelo "output esquerdo".

Um jeito de lidar com essa questão da "força em excesso" é com alguma espécie
de modulador que faz com que o excesso seja descartado. Pode ser até mesmo um
caminho estreito com um "abismo" do lado, o que faz com que os caranguejos a
mais no cluster caiam e deixe o sinal na força adequada.

E quanto a "divisão" de sinal? Um dos pressupostos dos circuitos era que eu
poderia dividir um sinal sem medo de perder valores para poder aproveitar ele
em diversos momentos. Mas se eu dividir demais, o sinal fica fraco e ele acaba
sendo efetivamente `FALSE` ao encontrar com outros sinais.

Uma alternativa para isso seria um "amplificador" de sinal: um mecanismo
sensível para a presença de caranguejos em um corredor, se detectada a presença
de caranguejos, então um caminho com um sinal de caranguejo seria adicionado e
"mergeado" com o sinal que vem, como se fosse uma porta OR. Esse acionamento
poderia ser um sensor de peso no chão a alguma distância antes do momento do
"merge". A quantidade de caranguejos para o merge pode ter o tamanho ajustado
de acordo com a intenção de misturar o sinal antes ou depois de fazer o split
do sinal.

Outra coisa para lidar também é o momento de chegada dos sinais, para que não
aconteça um "erro" no tiro. Os sinais precisam chegar nas portas lógicas no
momento correto. Para isso, eu posso aplicar "atraso" em alguns sinais, mas
jamais vou conseguir fazer um sinal ir mais rápido. A ideia aqui é algo
semelhante a o que Matt Parker e equipe enfrentaram
[ao construir um computador de dominós](https://www.youtube.com/watch?v=OpLU__bhu2w),
em alguns momentos ele precisaram deixar um sinal mais lento do que outro para
ter a sincronia adequada para a computação em questão. A adição do atraso para
se implementar seria simplesmente aumentar o tamanho do percurso que o cluster
de caranguejos precisaria percorrer para chegar na porta de operação desejada.

O desafio do atraso também é enfrentado em circuitos eletrônicos tradicionais,
mas a implementação do atraso não é sempre "aumentar o tamanho do circuito",
existem portas que causam atraso do sinal mantendo o valor dele.

# Computação de bilhar

A computação de bilhar segue princípios bem semelhantes à computação de
caranguejos, inclusive muita coisa da computação de caranguejo teve como base a
computação de bilhar.

Um dos artigos mais clássicos no assunto é
[Fredkin & Toffoli 1982 Conservative Logic](https://www.cs.princeton.edu/courses/archive/fall05/frs119/papers/fredkin_toffoli82.pdf),
e ele considera bolas de bilhar com colisões perfeitamente elásticas entre si e
com as paredes. Ele também considera que a superfície na qual a bola desliza
(ela não gira!) é ideal e sem atrito.

Diferentemente da computação de caranguejos, as colisões perfeitamente
elásticas ajudam para indicar que apenas uma força de sinal irá passar pela
porta. Os caranguejos, que são baseados em colisõoes inelásticas (os dois
clusters dos sinais se unem), já tem esse desafio a mais.

Para maior aprofundamento de computação de bilhar, outra fonte interessante que
achei foi
[Adamatzky & Durand-Lose 2012 Collision-based Computing](https://hal.science/hal-00461197/document).

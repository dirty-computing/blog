---
layout: post
title: "Um case de otimização com programação linear para o jogo City Bloxx"
author: "Jefferson Quesado"
tags: programação-linear js
base-assets: "/assets/city-bloxx-opt/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Quem é antigo lembra da antiga era dos _feature phones_. Celulares antigos,
talvez até mesmo um Nokia com câmera (algo muito chique na época!), capacidade
de reproduzir músicas. Comprar _ring tones_!

Bem, uma das coisas que marcaram essa época também eram os joguinhos de
telefone que vinham nessa época. O jogo da cobrinha é um absoluto clássico. Mas
eu me lembrei de um outro joguinho, da época em que o celular já conseguia
exibir mais cores: o City Bloxx. E o que eu lembrei dele? Porque eu o usei na
disciplina de Programação Linear Inteira para fazer uma modelagem.

Em uma postagem posterior eu me comprometo a falar sobre espaço solução,
simplex, poliedros e essas coisas todas bonitas. Por enquanto, aqui vamos só a
modelagem desse joguinho em específico.

# O jogo

O jogo basicamente se dividia em oids momentos de gameplay distintos:

- no primeiro, você construía uma torre
- no segundo, você posicionava a torre no grid, dada restrições

A primeira parte do jogo era mais relativa a tempo de reação e coisas assim,
sem precisar de tanta matemática por trás. Mas a segunda? Bem, a segunda...
aqui entram as coisas legais que vale a pena discutir aqui!

Quando você ia construir uma torre, você precisava selecionar uma dos 4 tipos
distintos de torres:

- azul (10 andares)
- vermelho (20 andares)
- verde (30 andares)
- amarelo (40 andares)

E cada uma delas vem acompanhada de uma restrição para serem posicionadas:

- vermelho: precisa ter uma azul como vizinha
- verde: precisa ter uma azul e uma vermelha como vizinhas
- amarelo: precisa ter uma azul, uma vermelha e uma verde como vizinhas

Quanto mais alta a torre, maior a sua pontuação. Além do fator altura, a sua
habilidade em construir a torre interfere com o score obtido, mas vamos supor
por hora que na primeira parte do jogo seja um jogador perfeito quem está
encarregado. Agora, só nos resta uma coisa para otimizar o score: como que eu
posso posicionar essas torres de modo a satisfazer suas restrições e otimizar o
score?

E tudo isso em uma grid 5x5...

# Programação linear ao resgate

Esse tipo de problema de otimizaçào lembra bastante os problemas de programaçào
linear:

- eu tenho restrições lineares (ainda a ser provado)
- eu tenho uma função objetiva linear

O bom da programação linear é que existem _solvers_ para elas que otimizam
completamente e garantidamente. Dadas as variáveis e quais restrições elas
devem satisfazer, quais valores essas variáveis precisam assumir para maximizar
o score obtido.

## Modelando função objetiva

{% katexmm %}

Vamos ignorar completamente a questão da habilidade do jogador pra construir a
torre. Portanto, o score se torna dependente apenas do tamanho da torre. Logo,
a função que eu desejo otimizar é algo mais ou menos assim:

$$
10\,sum_{azul} + 20\,sum_{vermelho} + 30\,sum_{verde} + 40\,sum_{amarelo}
$$

Então, agora precisamos modelar como vamos restringir os valores de
$sum_{azul}$ e de variáveis semelhantes.

## Modelando modelagem

Por uma questão de simplificação inicial, vou levar em consideração todas as
possibilidades de torres. Mas não vou levar em consideração a grid completa.
Todo o racional aplicado em uma grid 1x2 pode ser extrapolada para uma grid
NxM.

Logo, aqui abaixo as restrições vão ser modeladas em cima de uma grid 1x2, sem
perca de generalização.

## Modelando restrições: torre por célula

Existem algumas classes importantes de restrições. Vou pensar nelas célula a
célula do grid.

A primeira restrição é bem óbvia: só posso ter no máximo uma torre por célula!
Então, como podemos modelar isso? Que tal... a soma da torre azul, vermelha,
verde e amarela daquela célula menor do que ou igual a 1?

$$
azul_{1,1} + vermelho_{1,1} + verde_{1,1} + amarelo_{1,1} \le 1
$$

Bem, isso resolveu a quantidade máxima de torre na célula `1,1`. Por via das
dúvidas, vamos dizer que não posso ter torres negativas? Só por uma questão de
completude:

$$
azul_{1,1} + vermelho_{1,1} + verde_{1,1} + amarelo_{1,1} \le 1 \\
azul_{1,1} + vermelho_{1,1} + verde_{1,1} + amarelo_{1,1} \ge 0 
$$

Isso se aplica a todas as células:

$$
azul_{1,1} + vermelho_{1,1} + verde_{1,1} + amarelo_{1,1} \le 1 \\
azul_{1,1} + vermelho_{1,1} + verde_{1,1} + amarelo_{1,1} \ge 0 \\
azul_{1,2} + vermelho_{1,2} + verde_{1,2} + amarelo_{1,2} \le 1 \\
azul_{1,2} + vermelho_{1,2} + verde_{1,2} + amarelo_{1,2} \ge 0 
$$

Além disso, para cada torre na posição JxK, ela está ausente ou presente, não
posso ter mais de uma torre nem torre negativa. Isso agora é mais uma restrição
por tipo em si do que a por célula, que não pode ter duas torres na mesma
célula.

Aplicando esse racional, ficamos:

$$
azul_{1,1} + vermelho_{1,1} + verde_{1,1} + amarelo_{1,1} \le 1 \\
azul_{1,1} + vermelho_{1,1} + verde_{1,1} + amarelo_{1,1} \ge 0 \\
azul_{1,2} + vermelho_{1,2} + verde_{1,2} + amarelo_{1,2} \le 1 \\
azul_{1,2} + vermelho_{1,2} + verde_{1,2} + amarelo_{1,2} \ge 0 \\
azul_{1,1} \ge 0 \\
vermelho_{1,1} \ge 0 \\
verde_{1,1} \ge 0 \\
amarelo_{1,1} \ge 0 \\
azul_{1,1} \le 1 \\
vermelho_{1,1} \le 1 \\
verde_{1,1} \le 1 \\
amarelo_{1,1} \le 1
azul_{1,2} \ge 0 \\
vermelho_{1,2} \ge 0 \\
verde_{1,2} \ge 0 \\
amarelo_{1,2} \ge 0 \\
azul_{1,2} \le 1 \\
vermelho_{1,2} \le 1 \\
verde_{1,2} \le 1 \\
amarelo_{1,2} \le 1
$$

Para 2 células e 4 tipos de torres, já temos aqui na base de 20 restrições.
Mas... será mesmo?

Vamos lá. Eu posso garantir individualmente que a torre não pode ser negativa:

$$
azul_{1,1} \ge 0 \\
vermelho_{1,1} \ge 0 \\
verde_{1,1} \ge 0 \\
amarelo_{1,1} \ge 0
$$

Isso por si só também implica, diretamente, que

$$
azul_{1,1} + vermelho_{1,1} + verde_{1,1} + amarelo_{1,1} \ge 0
$$

é verdade! Portanto, aqui eu posso suprimir essa restrição. Não precisamos
listar ela diretamente, ela é resultado direto das outras restrições já
aplicadas.

Agora, sabendo que todos os valores são positivos, eu consigo algum valor para
alguma dessas variáveis que atenda essa restrição

$$
azul_{1,1} + vermelho_{1,1} + verde_{1,1} + amarelo_{1,1} \le 1
$$

porém fira essa outra?

$$
azul_{1,1} \le 1
$$

Vamos começar violando essa restrição. O valor de $azul_{1,1}$ vamos assumir
como $1 + \epsilon$, para algum $\epsilon$ positivo pequeno. Ok, agora vamos
substituir esse valor na primeira inequação:

$$
1 + \epsilon + vermelho_{1,1} + verde_{1,1} + amarelo_{1,1} \le 1
$$

Com isso, temos que

$$
\epsilon + vermelho_{1,1} + verde_{1,1} + amarelo_{1,1} \le 0
$$

Como as variáveis $vermelho_{1,1}$, $verde_{1,1}$ e $amarelo_{1,1}$ são todas
conhecidamente maiores do que ou iguais a 0, colocar qualquer valor diferente
de 0 trivialmente vai ofender a inequação. Então, vamos por 0 e ver como que
fica?

$$
\epsilon + 0 + 0 + 0 \le 0 \\
\therefore\\
\epsilon \le 0
$$

Porém é sabido que $\epsilon$ é garantidamente positivo: $\epsilon \gt 0$. O
que nos leva a contradição. Portanto, se eu tentar violar a inequação
$azul_{1,1} \le 1$, eu vou ser levado a uma contradição. Logo, isso se aplica
por simetria para todos os outros tipos de torre. Logo, colocar essa restrição

$$
azul_{1,1} + vermelho_{1,1} + verde_{1,1} + amarelo_{1,1} \le 1
$$

no contexto em que é garantido

$$
azul_{1,1} \ge 0 \\
vermelho_{1,1} \ge 0 \\
verde_{1,1} \ge 0 \\
amarelo_{1,1} \ge 0
$$

imediatamente já nos fornece que

$$
azul_{1,1} \le 1 \\
vermelho_{1,1} \le 1 \\
verde_{1,1} \le 1 \\
amarelo_{1,1} \le 1
$$

Simplificando essas restrições, ficamos assim:

$$
azul_{1,1} + vermelho_{1,1} + verde_{1,1} + amarelo_{1,1} \le 1 \\
azul_{1,2} + vermelho_{1,2} + verde_{1,2} + amarelo_{1,2} \le 1 \\
azul_{1,1} \ge 0 \\
vermelho_{1,1} \ge 0 \\
verde_{1,1} \ge 0 \\
amarelo_{1,1} \ge 0 \\
azul_{1,2} \ge 0 \\
vermelho_{1,2} \ge 0 \\
verde_{1,2} \ge 0 \\
amarelo_{1,2} \ge 0
$$

Só sobraram 10 restrições, das 20 inicialmente propostas.

## Modelando restrições: total de torres

Bem, até agora usamos 4 variáveis que não estão relacionadas com a função
objetiva, né? Na função objetiva usamos, por exemplo, $sum_{azul}$, mas para as
restrições atuais mencionamos no máximo $azul_{1,2}$. Como podemos mapear isso?

Bem, bora lá. O $sum_{azul}$ é para ser o valor exato da soma de todas as
torres azuis usadas. Aqui em tese deveria ser necessário usar uma igualdade,
porém... vamos deixar em modo de inequação: a soma não pode ultrapassar a
quantidade individual:

$$
\sum_{j=i}^2 azul_{1,j} \ge sum_{azul}
$$

Ok, mas isso é um resultado garantido? Bem, sim!

Se lembra que $sum_{azul}$ é uma variável da função objetiva. Nessa função,
o objeto cresce junto de $sum_{azul}$. Logo, se ela pode valor 3 ou valer 20,
sem nenhum prejuízo das outras variáveis, o $sum_{azul}$ vai precisar ir para o
seu maior valor. Logo, se ele é limitado
$\sum_{j=i}^2 azul_{1,j} \ge sum_{azul}$, o valor que o $sum_{azul}$ ocupar vai
ser o máximo: logo a soma dos azuis! $\sum_{j=i}^2 azul_{1,j}$.

Só isso já me dá as garantias que eu preciso, de que o modelo matemático vai
conseguir ocupar o $sum_{azul}$ (e o mesmo para todas as cores) de maneira
correta.

A inequação normalizada seria assim:

$$
\sum_{j=i}^2 azul_{1,j} - sum_{azul} \ge 0
$$

Expandindo o somatório e aplicando aos demais tipos de torres:

$$
azul_{1,1} + azul_{1,2} - sum_{azul} \ge 0 \\
vermelho_{1,1} + vermelho_{1,2} - sum_{vermelho} \ge 0 \\
verde_{1,1} + verde_{1,2} - sum_{verde} \ge 0 \\
amarelo_{1,1} + amarelo_{1,2} - sum_{amarelo} \ge 0 \\
$$

Aqui adicionamos mais 4 restrições, uma para cada tipo de torre.

## Modelando restrições: vizinhos

Se eu quero uma torre verde na posição `N,M`, isso significa que nos seus
quatro vizinhos precisamos ter pelo 1 vizinho vermelho e 1 vizinho azul. E aqui
é "pelo menos" mesmo, porque eu posso ter 2 ou mais vizinhos de cor azul.

Então, como fazemos? Aqui, a presença do verde implica que a soma dos azuis ao
redor seja ao menos 1, e que a soma dos vermelhos ao redor seja de ao menos 1
também:

$$
verde_{N,M} \le azul_{N-1,M} + azul_{N+1,M} + azul_{N,M-1} + azul_{N,M+1}
$$

Isso me impede que eu tenha um verde e não tenha um azul. Posso extrapolar e
aplicar isso para necessitar ter um vermelho como vizinho:

$$
verde_{N,M} \le vermelho_{N-1,M} + vermelho_{N+1,M} + vermelho_{N,M-1} + vermelho_{N,M+1}
$$

Como temos a restrição de ter no máximo uma torre em uma determinada posição,
combinar com 

$$
azul_{1,1} + vermelho_{1,1} + verde_{1,1} + amarelo_{1,1} \le 1 \\
$$

indica que não vai ser possível adicionar 2 verdes naquela casa (por mais que
tenha diversos azuis a mais).

Agora, por uma questão de sanidade, vamos ver como isso se aplica na grid 5x5?

De modo geral, tem alguns valores que nunca pensamos sobre, como $azul_{1,3}$
ou $verde_{2,1}$ passando por $vermelho_{0,1}$. Para esses casos fora da grid,
que tal ignorar/substituir por 0? Peguemos para a célula `1,2`, para a torre do
tipo verde:

$$
verde_{1,2} \le vermelho_{0,2} + vermelho_{2,2} + vermelho_{1,1} + vermelho_{2,2} \\
verde_{1,2} \le azul_{0,2} + azul_{2,2} + azul_{1,1} + azul_{2,2} \\
$$

Aplicando essa alteração para células inexistentes se tornarem 0:

$$
verde_{1,2} \le vermelho_{1,1} \\
verde_{1,2} \le azul_{1,1} \\
$$

Normalizando:

$$
vermelho_{1,1} - verde_{1,2} \ge 0\\
azul_{1,1} - verde_{1,2} \ge 0\\
$$

Precisamos aplicar esse tipo de restrição para todos as células da grid, para
todos os tipos de torre.

## Recapitulando o modelo

Bem, tinha ficado um ponto aberto que era:

- eu tenho restrições lineares (ainda a ser provado)

Vamos ver as restrições que temos:

1. torre por célula
2. total de torres
3. vizinhos

A primeira dessas classes, "torre por célula", é uma soma de variáveis.
Basicamente algo que pode ser expresso como 

$$
A \cdot X^T <= c
$$

Onde `A` é um vetor e `X` é o vetor com as variáveis e `c` é uma constraint
arbitrária. Como não temos nenhuma variável em potências distintas de 1 ou
multiplicando outras variáveis, então é sim um sistema linear.

O total de torres também funciona na mesma lógica: soma-se as variáveis
multiplicadas por escalares de modo que essa soma toda está limitada a uma
constraint `c`.

E, finalmente, a restrição dos vizinhos. Basicamente, se soma (até) as 4
células vizinhas e, subtraindo da atual, precisa dar 0 ou positivo. Mais uma
combinação linear em que a maioria dos elementos do vetor $A$ vai estar vazia.

Portanto, todas as restrições são lineares. Portanto, esse é sim um problema de
programação linear.

{% endkatexmm %}

# Aplicando programação linear

Achei alguns otimizadores de programação linear online para a escrita deste
post. Um dos que eu gostei de usar foi esse aqui: 
[https://online-optimizer.appspot.com/?model=builtin:default.mod][solver].

Tem esse outro aqui
[https://online.ssclab.org/SscOnline/SolverWorld](https://online.ssclab.org/SscOnline/SolverWorld)
também, mas particularmente achei a sintaxe do outro mais interessante.

De modo geral, para um problema de programação linear tradicional precisamos de
algo a ser otimizado e restrições que nos limita o espaço solução (normalmente
na forma de inequações).

Por exemplo, para o caso da grid 1x2 para esse solver em específico, eu defino
que a função a ser otimizada é:

```gmpl
maximize z:     10*azul + 20*vermelho + 30*verde + 40*amarelo;
```

Eu também preciso determinar as restrições:

```gmpl
subject to c_azules:   azul11 +   azul12 - azul >=  0;
subject to c_vermelhos: vermelho11 +   vermelho12 - vermelho >=  0;
subject to c_verdes: verde11 + verde12 - verde >= 0;
subject to c_amarelos: amarelo11 + amarelo12 - amarelo >= 0;

subject to c_max_11:   azul11 +    vermelho11 + verde11  + amarelo11   <= 1;
subject to c_max_12:   azul12 +    vermelho12 + verde12  + amarelo12  <= 1;

subject to c_viz_vermelho11_azul: azul12 - vermelho11 >= 0;
subject to c_viz_vermelho12_azul: azul11 - vermelho12 >= 0;

subject to c_viz_verde11_azul: azul12 - verde11 >= 0;
subject to c_viz_verde11_vermelho: vermelho12 - verde11 >= 0;
subject to c_viz_verde12_azul: azul11 - verde12 >= 0;
subject to c_viz_verde12_vermelho: vermelho11 - verde12 >= 0;

subject to c_viz_amarelo11_azul: azul12 - amarelo11 >= 0;
subject to c_viz_amarelo11_vermelho: vermelho12 - amarelo11 >= 0;
subject to c_viz_amarelo11_verde: verde12 - amarelo11 >= 0;
subject to c_viz_amarelo12_azul: azul11 - amarelo12 >= 0;
subject to c_viz_amarelo12_vermelho: vermelho11 - amarelo12 >= 0;
subject to c_viz_amarelo12_verde: verde11 - amarelo12 >= 0;
```

E as variáveis usadas (por uma questão da limitação de como essa ferramenta
funciona):

```gmpl
var azul >= 0;
var vermelho >= 0;
var verde >= 0;
var amarelo >= 0;

var azul11 >= 0;
var azul12 >= 0;

var vermelho11 >= 0;
var vermelho12 >= 0;

var verde11 >= 0;
var verde12 >= 0;

var amarelo11 >= 0;
var amarelo12 >= 0;
```

A linguagem usada para representar esse problema é GMPL: Gnu Mathematical
Programming Language. Peguei referências nesse site:
[https://hegyhati.github.io/IMOLS/pages/gmpl_basics.html](https://hegyhati.github.io/IMOLS/pages/gmpl_basics.html).

O programa completo ficou assim:

```gmpl
var azul >= 0;
var vermelho >= 0;
var verde >= 0;
var amarelo >= 0;

var azul11 >= 0;
var azul12 >= 0;

var vermelho11 >= 0;
var vermelho12 >= 0;

var verde11 >= 0;
var verde12 >= 0;

var amarelo11 >= 0;
var amarelo12 >= 0;

maximize z:     10*azul + 20*vermelho + 30*verde + 40*amarelo;

subject to c_azules:   azul11 +   azul12 - azul >=  0;
subject to c_vermelhos: vermelho11 +   vermelho12 - vermelho >=  0;
subject to c_verdes: verde11 + verde12 - verde >= 0;
subject to c_amarelos: amarelo11 + amarelo12 - amarelo >= 0;

subject to c_max_11:   azul11 +    vermelho11 + verde11  + amarelo11   <= 1;
subject to c_max_12:   azul12 +    vermelho12 + verde12  + amarelo12  <= 1;

subject to c_viz_vermelho11_azul: azul12 - vermelho11 >= 0;
subject to c_viz_vermelho12_azul: azul11 - vermelho12 >= 0;

subject to c_viz_verde11_azul: azul12 - verde11 >= 0;
subject to c_viz_verde11_vermelho: vermelho12 - verde11 >= 0;
subject to c_viz_verde12_azul: azul11 - verde12 >= 0;
subject to c_viz_verde12_vermelho: vermelho11 - verde12 >= 0;

subject to c_viz_amarelo11_azul: azul12 - amarelo11 >= 0;
subject to c_viz_amarelo11_vermelho: vermelho12 - amarelo11 >= 0;
subject to c_viz_amarelo11_verde: verde12 - amarelo11 >= 0;
subject to c_viz_amarelo12_azul: azul11 - amarelo12 >= 0;
subject to c_viz_amarelo12_vermelho: vermelho11 - amarelo12 >= 0;
subject to c_viz_amarelo12_verde: verde11 - amarelo12 >= 0;

subject to c_max_azul11: azul11 <= 1;
subject to c_max_azul12: azul12 <= 1;
subject to c_max_vermelho11: vermelho11 <= 1;
subject to c_max_vermelho12: vermelho12 <= 1;
subject to c_max_verde11: verde11 <= 1;
subject to c_max_verde12: verde12 <= 1;
subject to c_max_amarelo11: amarelo11 <= 1;
subject to c_max_amarelo12: amarelo12 <= 1;
```

Vamos rodar pra ver isso em execução? Botando exatamente esse programa, obtive
essa resposta no [solver online][solver]:

{: class="marked-table" }
|                | valor    |
| :------------  |  ------: |
| **z**          |      50  |
| **azul11**     |    0.25  |
| **azul12**     |    0.25  |
| **vermelho11** |    0.25  |
| **vermelho12** |    0.25  |
| **verde11**    |    0.25  |
| **verde12**    |    0.25  |
| **amarelo11**  |    0.25  |
| **amarelo12**  |    0.25  |


Hmmm, por que isso? Bem, basicamente porque eu não delimitei que era um
problema de programação linear inteira. Se, por acaso, eu tivesse removido as
variáveis de verde e amarelo, teria obtido esse valor:

{: class="marked-table" }
|                | valor    |
| :------------  |  ------: |
| **z**          |      30  |
| **azul11**     |       1  |
| **azul12**     |       0  |
| **vermelho11** |       0  |
| **vermelho12** |       1  |

De modo semelhante, outra resposta possível seria:

{: class="marked-table" }
|                | valor    |
| :------------  |  ------: |
| **z**          |      30  |
| **azul11**     |       0  |
| **azul12**     |       1  |
| **vermelho11** |       1  |
| **vermelho12** |       0  |

Com o mesmo valor da função objetiva. Eventualmente também tem a possibilidade
de obter um valor intermediário, que satisfaz todas as dependências:

{: class="marked-table" }
|                | valor    |
| :------------  |  ------: |
| **z**          |      30  |
| **azul11**     |     0.5  |
| **azul12**     |     0.5  |
| **vermelho11** |     0.5  |
| **vermelho12** |     0.5  |

Mas esse valor intermediário não apareceu nem iria aparecer na maioria dos
solvers. E isso não é matéria deste post, fica para um futuro, prometo!

Enfim, mas no caso específico do caso em que o verde e o amarelo entravam na
função objetiva, entrou o caso específico de que o ótimo envolvia variáveis não
inteiras. Mas podemos resolver isso na especificação do problema:

```gmpl
var azul >= 0 integer;
var vermelho >= 0 integer;
var verde >= 0 integer;
var amarelo >= 0 integer;

var azul11 >= 0 integer;
var azul12 >= 0 integer;

var vermelho11 >= 0 integer;
var vermelho12 >= 0 integer;

var verde11 >= 0 integer;
var verde12 >= 0 integer;

var amarelo11 >= 0 integer;
var amarelo12 >= 0 integer;

maximize z:     10*azul + 20*vermelho + 30*verde + 40*amarelo;

subject to c_azules:   azul11 +   azul12 - azul >=  0;
subject to c_vermelhos: vermelho11 +   vermelho12 - vermelho >=  0;
subject to c_verdes: verde11 + verde12 - verde >= 0;
subject to c_amarelos: amarelo11 + amarelo12 - amarelo >= 0;

subject to c_max_11:   azul11 +    vermelho11 + verde11  + amarelo11   <= 1;
subject to c_max_12:   azul12 +    vermelho12 + verde12  + amarelo12  <= 1;

subject to c_viz_vermelho11_azul: azul12 - vermelho11 >= 0;
subject to c_viz_vermelho12_azul: azul11 - vermelho12 >= 0;

subject to c_viz_verde11_azul: azul12 - verde11 >= 0;
subject to c_viz_verde11_vermelho: vermelho12 - verde11 >= 0;
subject to c_viz_verde12_azul: azul11 - verde12 >= 0;
subject to c_viz_verde12_vermelho: vermelho11 - verde12 >= 0;

subject to c_viz_amarelo11_azul: azul12 - amarelo11 >= 0;
subject to c_viz_amarelo11_vermelho: vermelho12 - amarelo11 >= 0;
subject to c_viz_amarelo11_verde: verde12 - amarelo11 >= 0;
subject to c_viz_amarelo12_azul: azul11 - amarelo12 >= 0;
subject to c_viz_amarelo12_vermelho: vermelho11 - amarelo12 >= 0;
subject to c_viz_amarelo12_verde: verde11 - amarelo12 >= 0;
```

## Meta-modelo

Ok, vamos fazer um pequeno JS que faça esse código?

Vou deixar como parâmetro apenas a quantidade de linhas vs a quantidade de
colunas. Vamos primeiro criar as variáveis:

- uma para cada cor
  - azul
  - vermelho
  - verde
  - amarelo
- uma cor para cada célula
    - azul para `1,1`
    - vermelho para `1,1`
    - verde para `1,1`
    - amarelo para `1,1`
    - azul para `1,2`
    - vermelho para `1,2`
    - verde para `1,2`
    - amarelo para `1,2`
    - e assim por diante...

A função objetiva é fácil, se mantém exatamente a mesma sempre para esse
problema:

- soma de quantidade de andares por cada cor

Agora, as restrições... primeiro, a restrição de ocupação por célula:

- soma das cores da célula no máximo 1

Então, a restrição das variáveis de acumulação de cor:

- azul precisa ser menor do que ou igual à soma de todas as azul X,Y

Finalmente, as de vizinhança. Essas tem características especiais, mas de modo
geral são assim:

- para vermelho na casa `X,Y`:
    - soma de azul em `X-1,Y` / `X+1,Y` / `X,Y-1` / `X,Y-1` subtraído de
      vermelho `X,Y` no mínimo 0
- para verde na casa `X,Y`:
    - soma de azul em `X-1,Y` / `X+1,Y` / `X,Y-1` / `X,Y+1` subtraído de
      vermelho `X,Y` no mínimo 0
    - soma de vermelho em `X-1,Y` / `X+1,Y` / `X,Y-1` / `X,Y+1` subtraído de
      vermelho `X,Y` no mínimo 0
- para amarelo na casa `X,Y`:
    - soma de azul em `X-1,Y` / `X+1,Y` / `X,Y-1` / `X,Y+1` subtraído de
      vermelho `X,Y` no mínimo 0
    - soma de vermelho em `X-1,Y` / `X+1,Y` / `X,Y-1` / `X,Y+1` subtraído de
      vermelho `X,Y` no mínimo 0
    - soma de verde em `X-1,Y` / `X+1,Y` / `X,Y-1` / `X,Y+1` subtraído de
      vermelho `X,Y` no mínimo 0

Só que temos alguns cuidados:

- `X-1` não pode ser 0
- `Y-1` não pode ser 0
- `X+1` não pode ultrapassar a quantidade de linhas
- `Y+1` não pode ultrapassar a quantidade de colunas

> Ou `X+1` olha para colunas e `Y+1` olha para linhas, tanto faz. É simétrico,
> basta ser consistente.

Então, com isso, temos os seguintes processos.

Variáveis:

```js
const coresProblema = [ "azul", "vermelho", "verde", "amarelo" ]

function varsModelo(linhas, colunas) {
    const vars = []

    // criar as variáveis de acumulação
    for (const corProblema of coresProblema) {
        const varName = corProblema;
        vars.push(`var ${varName} >= 0 integer;`)
    }

    // para cada célcula, as quatro cores
    for (let i = 1; i <= linhas; i++) {
        for (let j = 1; j <= colunas; j++) {
            const idx = `_${i}_${j}`;
            for (const corProblema of coresProblema) {
                const varName = `${corProblema}_${idx}`;
                vars.push(`var ${varName} >= 0 integer;`)
            }
        }
    }

    return vars;
}
```

Ok, agora hora da função objetivo: maximizar a soma das cores por score:

```js
// coresProblema já fornecido
const scoreCores = { "azul": 10, "vermelho": 20, "verde": 30, "amarelo": 40}

function objFunction() {
    const f = "maximize z: ";

    const parcelas = [];

    for (const corProblema of coresProblema) {
        const scoreCor = scoreCores[corProblema];
        const parcela = `${scoreCor}*${corProblema}`;
        parcelas.push(parcela);
    }
    return f + parcelas.reduce((acc, el) => acc + " + " + el) + ";"
}
```

Muito bem. Agora, vamos para as restrições. Primeira família de restrições: a
do agregador de cor:

```js
function stAgregadorCor(linhas, colunas) {
    const constraints = [];

    // para cada cor, a soma das cores precisa limitar o agregador
    for (const corProblema of coresProblema) {
        const constraintName = `c_${corProblema}`;

        const varNames = []
        for (let i = 1; i <= linhas; i++) {
            for (let j = 1; j <= colunas; j++) {
                const idx = `_${i}_${j}`;
                const varName = `${corProblema}_${idx}`;
                varNames.push(varName)
            }
        }
        const sum = varNames.reduce((acc, el) => `${acc} + ${el}`)

        const fullConstraint = `subject to ${constraintName}: ${sum} - ${corProblema} >= 0;`;
    }    

    return constraints;
}
```

Agora, o máximo por célula. Só somar as cores da célula e limitar a 1:

```js
function stMaxCelula(linhas, colunas) {
    const constraints = [];

    for (let i = 1; i <= linhas; i++) {
        for (let j = 1; j <= colunas; j++) {
            const idx = `_${i}_${j}`;
            const constraintName = `c_max_${idx}`;

            const varNames = [];
            for (const corProblema of coresProblema) {
                const varName = `${corProblema}_${idx}`;
                varNames.push(varName)
            }
            const sum = varNames.reduce((acc, el) => `acc + el`)

            const constraint = `subject to ${constraintName}: ${sum} <= 1;`;
        }
    }

    return constraints;
}
```

Agora, hora do mais chato: dos vizinhos. Posso modelar a restrição de
vizinhança de alguns modos:

- pego a cor pelo índice (ex, 2 -> verde), então as cores de índice 0 e 1 são
  necessárias para a de índice 2
- faço um mapeamento com a chave indicando um vetor de dependências, como
  `{ "azul": [], "vermelho": [ "azul" ]}`
- algo mais _fancy_ em que o mapeamento aponta para a quantidade de vizinhos
  mínimos de cada cor, como como `{ "verde": { "vermelho": 1, "azul": 1 } }`

Mas agora vou optar pelo segundo modelo. Assim, posso iterar nas cores e obter
delas diretamente as dependências delas. E também não preciso fazer algo
_fancy_ como indicar mínimos ou máximos (isso poderia se aplicar muito bem ao
jogo da vida de Conway, mas não estou modelando isso).

Aqui, vou iterar para cada cor cada célula para obter as N restrições: os
vizinhos precisam atender a demanda específica. Vou chamar a restrição de
"constraint de vizinhos para o vermelho `1,2` que precisam ser azuis", ou de
modo mais compacto `c_viz_vermelho__1_2__azul`. Generalizando:
`c_viz_${corProblema}_${idx}_${corVizinho}`.

Mas, vamos por partes, né? Dado o nosso índice conhecido, a cor efetiva do
problema e a cor do vizinho que faz a restrição, precisamos verificar os 4
vizinhos: `X+1,Y` / `X-1,Y` / `X,Y+1` / `X,Y-1`. E aplicar o teste de sanidade
(o que significa carrear o total de linhas e colunas)

```js
const corDeps = {
    "azul": [],
    "vermelho": [ "azul" ],
    "verde": [ "azul", "vermelho" ],
    "amarelo": ["azul", "vermelho", "verde" ]
}

function stVizinhoCorBaseCorVizinho(linhas, colunas, linha, coluna, corProblema, corVizinho) {
    const xP1 = linha + 1;
    const xM1 = linha - 1;

    const yP1 = coluna + 1;
    const yM1 = coluna - 1;

    const vizAptos = [];

    if (xM1 > 0) {
        // X-1 não é zero: apto
        const idxViz = `_${xM1}_${coluna}`;
        const viz = `${corVizinho}_${idxViz}`;
        vizAptos.push(viz)
    }
    if (xP1 <= linhas) {
        // X+1 não é maior que o número de linhas: apto
        const idxViz = `_${xP1}_${coluna}`;
        const viz = `${corVizinho}_${idxViz}`;
        vizAptos.push(viz)
    }
    if (yM1 > 0) {
        // Y-1 não é zero: apto
        const idxViz = `_${linha}_${yM1}`;
        const viz = `${corVizinho}_${idxViz}`;
        vizAptos.push(viz)
    }
    if (yP1 <= colunas) {
        // Y+1 não é maior que o número de colunas: apto
        const idxViz = `_${linha}_${yP1}`;
        const viz = `${corVizinho}_${idxViz}`;
        vizAptos.push(viz)
    }

    if (vizAptos.length == 0) {
        return "";
    }
    const idx = `_${linha}_${coluna}`;
    const constraintName = `c_viz_${corProblema}_${idx}_${corVizinho}`;

    const sum = vizAptos.reduce((acc, el) => `${acc} + ${el}`)
    return `subject to ${constraintName}: ${sum} - ${corProblema}_${idx} >= 0;`;
}

function stVizinhoCorBase(linhas, colunas, linha, coluna, corProblema) {
    const constraints = [];

    for (const corVizinho of corDeps[corProblema]) {
        const corConstraint = stVizinhoCorBaseCorVizinho(
            linhas, colunas,
            linha, coluna,
            corProblema, corVizinho
        );

        if (corConstraint == "") {
            continue;
        }

        constraints.push(corConstraint);
    }

    return constraints;
}

function stVizinhos(linhas, colunas) {
    let constraints = [];

    for (let i = 1; i <= linhas; i++) {
        for (let j = 1; j <= colunas; j++) {
            for (const corProblema of coresProblema) {
                const constraintsCelulaCor = stVizinhoCorBase(linhas, colunas, i, j, corProblema);
                if (constraintsCelulaCor.length == 0) {
                    continue;
                }
                constraints = [ ...constraints, ...constraintsCelulaCor];
            }
        }
    }
    return constraints
}
```

<label for="form-linhas">Linhas</label>
<input type="number" id="form-linhas"  name="form-linhas" step=1 value=1/>
<label for="form-colunas">Colunas</label>
<input type="number" id="form-colunas" name="form-colunas" step=1 value=2/>
<button onclick="generate()">Gerar caso</button>

<script>
    const coresProblema = [ "azul", "vermelho", "verde", "amarelo" ]
    const scoreCores = { "azul": 10, "vermelho": 20, "verde": 30, "amarelo": 40}

    function varsModelo(linhas, colunas) {
        const vars = []

        // criar as variáveis de acumulação
        for (const corProblema of coresProblema) {
            const varName = corProblema;
            vars.push(`var ${varName} >= 0 integer;`)
        }

        // para cada célcula, as quatro cores
        for (let i = 1; i <= linhas; i++) {
            for (let j = 1; j <= colunas; j++) {
                const idx = `_${i}_${j}`;
                for (const corProblema of coresProblema) {
                    const varName = `${corProblema}_${idx}`;
                    vars.push(`var ${varName} >= 0 integer;`)
                }
            }
        }

        return vars;
    }

    function objFunction() {
        const f = "maximize z: ";

        const parcelas = [];

        for (const corProblema of coresProblema) {
            const scoreCor = scoreCores[corProblema];
            const parcela = `${scoreCor}*${corProblema}`;
            parcelas.push(parcela);
        }
        return f + parcelas.reduce((acc, el) => acc + " + " + el) + ";"
    }

    function stAgregadorCor(linhas, colunas) {
        const constraints = [];

        // para cada cor, a soma das cores precisa limitar o agregador
        for (const corProblema of coresProblema) {
            const constraintName = `c_${corProblema}s`;

            const varNames = []
            for (let i = 1; i <= linhas; i++) {
                for (let j = 1; j <= colunas; j++) {
                    const idx = `_${i}_${j}`;
                    const varName = `${corProblema}_${idx}`;
                    varNames.push(varName)
                }
            }
            const sum = varNames.reduce((acc, el) => `${acc} + ${el}`)

            const fullConstraint = `subject to ${constraintName}: ${sum} - ${corProblema} >= 0;`;
            constraints.push(fullConstraint)
        }    

        return constraints;
    }

    function stMaxCelula(linhas, colunas) {
        const constraints = [];

        for (let i = 1; i <= linhas; i++) {
            for (let j = 1; j <= colunas; j++) {
                const idx = `_${i}_${j}`;
                const constraintName = `c_max_${idx}`;

                const varNames = [];
                for (const corProblema of coresProblema) {
                    const varName = `${corProblema}_${idx}`;
                    varNames.push(varName)
                }
                const sum = varNames.reduce((acc, el) => `${acc} + ${el}`)

                const constraint = `subject to ${constraintName}: ${sum} <= 1;`;
                constraints.push(constraint);
            }
        }

        return constraints;
    }

    const corDeps = {
        "azul": [],
        "vermelho": [ "azul" ],
        "verde": [ "azul", "vermelho" ],
        "amarelo": ["azul", "vermelho", "verde" ]
    }

    function stVizinhoCorBaseCorVizinho(linhas, colunas, linha, coluna, corProblema, corVizinho) {
        const xP1 = linha + 1;
        const xM1 = linha - 1;

        const yP1 = coluna + 1;
        const yM1 = coluna - 1;

        const vizAptos = [];

        if (xM1 > 0) {
            // X-1 não é zero: apto
            const idxViz = `_${xM1}_${coluna}`;
            const viz = `${corVizinho}_${idxViz}`;
            vizAptos.push(viz)
        }
        if (xP1 <= linhas) {
            // X+1 não é maior que o número de linhas: apto
            const idxViz = `_${xP1}_${coluna}`;
            const viz = `${corVizinho}_${idxViz}`;
            vizAptos.push(viz)
        }
        if (yM1 > 0) {
            // Y-1 não é zero: apto
            const idxViz = `_${linha}_${yM1}`;
            const viz = `${corVizinho}_${idxViz}`;
            vizAptos.push(viz)
        }
        if (yP1 <= colunas) {
            // Y+1 não é maior que o número de colunas: apto
            const idxViz = `_${linha}_${yP1}`;
            const viz = `${corVizinho}_${idxViz}`;
            vizAptos.push(viz)
        }

        if (vizAptos.length == 0) {
            return "";
        }
        const idx = `_${linha}_${coluna}`;
        const constraintName = `c_viz_${corProblema}_${idx}_${corVizinho}`;

        const sum = vizAptos.reduce((acc, el) => `${acc} + ${el}`)
        return `subject to ${constraintName}: ${sum} - ${corProblema}_${idx} >= 0;`;
    }

    function stVizinhoCorBase(linhas, colunas, linha, coluna, corProblema) {
        const constraints = [];

        for (const corVizinho of corDeps[corProblema]) {
            const corConstraint = stVizinhoCorBaseCorVizinho(
                linhas, colunas,
                linha, coluna,
                corProblema, corVizinho
            );

            if (corConstraint == "") {
                continue;
            }

            constraints.push(corConstraint);
        }

        return constraints;
    }

    function stVizinhos(linhas, colunas) {
        let constraints = [];

        for (let i = 1; i <= linhas; i++) {
            for (let j = 1; j <= colunas; j++) {
                for (const corProblema of coresProblema) {
                    const constraintsCelulaCor = stVizinhoCorBase(linhas, colunas, i, j, corProblema);
                    if (constraintsCelulaCor.length == 0) {
                        continue;
                    }
                    constraints = [ ...constraints, ...constraintsCelulaCor];
                }
            }
        }
        return constraints
    }

    function problemsConstraints(linhas, colunas) {
        const agregadoCor = stAgregadorCor(linhas, colunas);
        const maxCelula = stMaxCelula(linhas, colunas);
        const vizes = stVizinhos(linhas, colunas);
        return [...agregadoCor, ...maxCelula, ...vizes]
    }

    function generateProblema(linhas, colunas) {
        const vars = varsModelo(linhas, colunas);
        const fObj = objFunction();
        const allConstraints = problemsConstraints(linhas, colunas);
        return [...vars, fObj, ...allConstraints]
    }

    function generate() {
        const linhasEl = document.getElementById("form-linhas");
        const colunasEl = document.getElementById("form-colunas");

        const problemEl = document.getElementById("problem")

        const problemaModelo = generateProblema(Number.parseInt(linhasEl.value), Number.parseInt(colunasEl.value));
        problemEl.value = problemaModelo.reduce((acc, el) => acc + "\n" + el);
    }

    async function copiaSolucao() {
        const problemEl = document.getElementById("problem")
        const problemCode = problemEl.value;
        console.log(problemCode)
        await navigator.clipboard.writeText(problemCode);
    }
</script>

<textarea id="problem" disabled="true" cols="80" rows="30" placeholder="ainda a receber o problema">
</textarea>
<button onclick="copiaSolucao()" class="icon">{% include uxwing-copy-icon.svg %}</button>

# Qual o valor ótimo afinal?

O problema de 5x5 gerou 284 linhas do modelo matemático, que você pode
simlpesmente gerar aí pra conferir. O de 1x2 eu posso usar como base para
comparar com aquele que foi escrito na mão:

```gmpl
var azul >= 0 integer;
var vermelho >= 0 integer;
var verde >= 0 integer;
var amarelo >= 0 integer;
var azul__1_1 >= 0 integer;
var vermelho__1_1 >= 0 integer;
var verde__1_1 >= 0 integer;
var amarelo__1_1 >= 0 integer;
var azul__1_2 >= 0 integer;
var vermelho__1_2 >= 0 integer;
var verde__1_2 >= 0 integer;
var amarelo__1_2 >= 0 integer;
maximize z: 10*azul + 20*vermelho + 30*verde + 40*amarelo;
subject to c_azuls: azul__1_1 + azul__1_2 - azul >= 0;
subject to c_vermelhos: vermelho__1_1 + vermelho__1_2 - vermelho >= 0;
subject to c_verdes: verde__1_1 + verde__1_2 - verde >= 0;
subject to c_amarelos: amarelo__1_1 + amarelo__1_2 - amarelo >= 0;
subject to c_max__1_1: azul__1_1 + vermelho__1_1 + verde__1_1 + amarelo__1_1 <= 1;
subject to c_max__1_2: azul__1_2 + vermelho__1_2 + verde__1_2 + amarelo__1_2 <= 1;
subject to c_viz_vermelho__1_1_azul: azul__1_2 - vermelho__1_1 >= 0;
subject to c_viz_verde__1_1_azul: azul__1_2 - verde__1_1 >= 0;
subject to c_viz_verde__1_1_vermelho: vermelho__1_2 - verde__1_1 >= 0;
subject to c_viz_amarelo__1_1_azul: azul__1_2 - amarelo__1_1 >= 0;
subject to c_viz_amarelo__1_1_vermelho: vermelho__1_2 - amarelo__1_1 >= 0;
subject to c_viz_amarelo__1_1_verde: verde__1_2 - amarelo__1_1 >= 0;
subject to c_viz_vermelho__1_2_azul: azul__1_1 - vermelho__1_2 >= 0;
subject to c_viz_verde__1_2_azul: azul__1_1 - verde__1_2 >= 0;
subject to c_viz_verde__1_2_vermelho: vermelho__1_1 - verde__1_2 >= 0;
subject to c_viz_amarelo__1_2_azul: azul__1_1 - amarelo__1_2 >= 0;
subject to c_viz_amarelo__1_2_vermelho: vermelho__1_1 - amarelo__1_2 >= 0;
subject to c_viz_amarelo__1_2_verde: verde__1_1 - amarelo__1_2 >= 0;
```

São 31 linhas. Agora, o original:

```gmpl
var azul >= 0 integer;
var vermelho >= 0 integer;
var verde >= 0 integer;
var amarelo >= 0 integer;

var azul11 >= 0 integer;
var azul12 >= 0 integer;

var vermelho11 >= 0 integer;
var vermelho12 >= 0 integer;

var verde11 >= 0 integer;
var verde12 >= 0 integer;

var amarelo11 >= 0 integer;
var amarelo12 >= 0 integer;

maximize z:     10*azul + 20*vermelho + 30*verde + 40*amarelo;

subject to c_azules:   azul11 +   azul12 - azul >=  0;
subject to c_vermelhos: vermelho11 +   vermelho12 - vermelho >=  0;
subject to c_verdes: verde11 + verde12 - verde >= 0;
subject to c_amarelos: amarelo11 + amarelo12 - amarelo >= 0;

subject to c_max_11:   azul11 +    vermelho11 + verde11  + amarelo11   <= 1;
subject to c_max_12:   azul12 +    vermelho12 + verde12  + amarelo12  <= 1;

subject to c_viz_vermelho11_azul: azul12 - vermelho11 >= 0;
subject to c_viz_vermelho12_azul: azul11 - vermelho12 >= 0;

subject to c_viz_verde11_azul: azul12 - verde11 >= 0;
subject to c_viz_verde11_vermelho: vermelho12 - verde11 >= 0;
subject to c_viz_verde12_azul: azul11 - verde12 >= 0;
subject to c_viz_verde12_vermelho: vermelho11 - verde12 >= 0;

subject to c_viz_amarelo11_azul: azul12 - amarelo11 >= 0;
subject to c_viz_amarelo11_vermelho: vermelho12 - amarelo11 >= 0;
subject to c_viz_amarelo11_verde: verde12 - amarelo11 >= 0;
subject to c_viz_amarelo12_azul: azul11 - amarelo12 >= 0;
subject to c_viz_amarelo12_vermelho: vermelho11 - amarelo12 >= 0;
subject to c_viz_amarelo12_verde: verde11 - amarelo12 >= 0;
```

Basicamente, o mesmo problema:

- 31 linhas
- 12 variáveis
- 1 função objetiva
- 18 linhas de restrições

As únicas que mudaram foram:

- convenção de índice, antes era `vermelho12`, agora `vermelho__1_2`
- ordem de aparecimento de restrição

E só.

Em relação ao modelo para resolver o 5x5, obtivemos que a função otimizada
valeu 610, com a seguinte distribuição:

- azuis: 7
- vermelhos: 6
- azuis; 6
- amarelo: 6

E como seria a distribuição disso?

<script>
    const azul = []
    const vermelho = []
    const verde = []
    const amarelo = []

    const linhas = 5, colunas = 5;

    for (let i = 0; i <= linhas; i++) {
        const linhaAzul = []
        const linhaVermelho = []
        const linhaVerde = []
        const linhaAmarelo = []
        
        for (let j = 0; j <= colunas; j++) {
            linhaAzul.push(0)
            linhaVermelho.push(0)
            linhaVerde.push(0)
            linhaAmarelo.push(0)
        }
        azul.push(linhaAzul)
        vermelho.push(linhaVermelho)
        verde.push(linhaVerde)
        amarelo.push(linhaAmarelo)
    }

    azul[1][1] = 1
    vermelho[1][1] = 0
    verde[1][1] = 0
    amarelo[1][1] = 0
    azul[1][2] = 0
    vermelho[1][2] = 0
    verde[1][2] = 1
    amarelo[1][2] = 0
    azul[1][3] = 1
    vermelho[1][3] = 0
    verde[1][3] = 0
    amarelo[1][3] = 0
    azul[1][4] = 0
    vermelho[1][4] = 0
    verde[1][4] = 1
    amarelo[1][4] = 0
    azul[1][5] = 0
    vermelho[1][5] = 1
    verde[1][5] = 0
    amarelo[1][5] = 0
    azul[2][1] = 0
    vermelho[2][1] = 0
    verde[2][1] = 1
    amarelo[2][1] = 0
    azul[2][2] = 0
    vermelho[2][2] = 1
    verde[2][2] = 0
    amarelo[2][2] = 0
    azul[2][3] = 0
    vermelho[2][3] = 0
    verde[2][3] = 0
    amarelo[2][3] = 1
    azul[2][4] = 0
    vermelho[2][4] = 0
    verde[2][4] = 0
    amarelo[2][4] = 1
    azul[2][5] = 1
    vermelho[2][5] = 0
    verde[2][5] = 0
    amarelo[2][5] = 0
    azul[3][1] = 0
    vermelho[3][1] = 0
    verde[3][1] = 0
    amarelo[3][1] = 1
    azul[3][2] = 1
    vermelho[3][2] = 0
    verde[3][2] = 0
    amarelo[3][2] = 0
    azul[3][3] = 0
    vermelho[3][3] = 0
    verde[3][3] = 1
    amarelo[3][3] = 0
    azul[3][4] = 0
    vermelho[3][4] = 1
    verde[3][4] = 0
    amarelo[3][4] = 0
    azul[3][5] = 0
    vermelho[3][5] = 0
    verde[3][5] = 1
    amarelo[3][5] = 0
    azul[4][1] = 0
    vermelho[4][1] = 1
    verde[4][1] = 0
    amarelo[4][1] = 0
    azul[4][2] = 0
    vermelho[4][2] = 0
    verde[4][2] = 1
    amarelo[4][2] = 0
    azul[4][3] = 0
    vermelho[4][3] = 0
    verde[4][3] = 0
    amarelo[4][3] = 1
    azul[4][4] = 1
    vermelho[4][4] = 0
    verde[4][4] = 0
    amarelo[4][4] = 0
    azul[4][5] = 0
    vermelho[4][5] = 0
    verde[4][5] = 0
    amarelo[4][5] = 1
    azul[5][1] = 1
    vermelho[5][1] = 0
    verde[5][1] = 0
    amarelo[5][1] = 0
    azul[5][2] = 0
    vermelho[5][2] = 0
    verde[5][2] = 0
    amarelo[5][2] = 1
    azul[5][3] = 0
    vermelho[5][3] = 1
    verde[5][3] = 0
    amarelo[5][3] = 0
    azul[5][4] = 1
    vermelho[5][4] = 0
    verde[5][4] = 0
    amarelo[5][4] = 0
    azul[5][5] = 0
    vermelho[5][5] = 1
    verde[5][5] = 0
    amarelo[5][5] = 0

    console.log(azul)
    console.log(vermelho)
    console.log(verde)
    console.log(amarelo)

    function populateTabelaSolucao() {
        const tabelaSolucao = document.getElementById("solucao-final")
        for (let i = 0; i < linhas; i++) {
            const row = document.createElement("tr");
            row.dataset.linha = `${i + 1}`
            for (let j = 0; j < colunas; j++) {
                const column = document.createElement("td")
                column.dataset.coluna = `${j + 1}`

                if (azul[i + 1][j + 1] == 1) {
                    column.style.backgroundColor = "blue"
                } else if (vermelho[i + 1][j + 1] == 1) {
                    column.style.backgroundColor = "red"
                } else if (verde[i + 1][j + 1] == 1) {
                    column.style.backgroundColor = "green"
                } else if (amarelo[i + 1][j + 1] == 1) {
                    column.style.backgroundColor = "yellow"
                }

                row.appendChild(column)

                console.log(`em populateTabelaSolucao com ${i},${j}`)
            }
            tabelaSolucao.appendChild(row)
        }
    }


    window.addEventListener("load", (event) => {
        populateTabelaSolucao();
    });
</script>

<style>
    .min-dim td {
        width: 30px;
    }

    .min-dim tr {
        height: 30px;
    }
</style>
<table id="solucao-final" class="marked-table min-dim">
</table>

# Caveats

Bem, em primeiro lugar de cuidado a se tomar é porque estou assumindo que o
score que tentamos maximizar seja apenas um fator constante multiplicado pela
quantidade de andares, dado um jogador perfeito. Isso não leva em consideração
que, de repente, o jogo tem parâmetros distintos de score para cada tipo de
torre.

E também estou ignorando qualquer fator linear que possa a vir com cada tipo de
torre. Por exemplo, uma mecânica do jogo é o "telhado especial" ou algo assim,
relativo a última peça a ser encaixada. Essa peça não me lembro claramente se
ela vai ser um boost em cima dos valores anteiores, ou um boost fixo por torre,
ou mesmo o mesmo boost para todas as torres que dependa apenas da habilidade do
jogador.

Então os valores das funções objetiva podem se alterar bastante. E isso pode
gerar respostas bem diferentes!

Outra coisa também que vale a pena se preocupar: a resposta aqui é uma
"conformação estável". O jogo permite fazer coisas que eu chamo de "conformação
instável". Por exemplo, dado exatamente o como os prédios estão posicionados,
eu posso colocar uma torre verde na linha 5 coluna 4. Isso porque ela tem um
vizinho azul na posição `4,4` e verelho nas posições `5,3` e `5,5`.

Claro, ao posicionar o verde na posição `5,4` , a torre vermelha da posição
`5,5` passa a estar "inválida". Mas a mecânica do jogo só se aplica no
posicionamento inicial da torre. Se posteriormente derrubamos tudo ao redor
daquela torre, tudo bem porque a validação só ocorre depois.

Esse tipo de arranjo apresenta a "conformação instável" mencionada acima: para
modelar ela, precisamos levar em consideração as rodadas em que se colocam as
novas torres. Se uma torre passa a existir no momento `k`, então no momento
`k-1` precisa estar povoado com os vizinhos corretamente, mas o futuro `k+z`
não precisa garantir que a condição dos vizinhos valha a pena.

Esse tipo de problema é plausível sim modelar com programação linear inteira,
mas como dito acima, precisa modelar a questão não só dos vizinhos, mas do
estado da célula no tempo anterior, o que aumentar a quantidade de variáveis
significativamente, meio que multiplica pela "quantidade de rodadas" que ainda
se deseja deixar o sistema se tornar instável substituindo prédios.

  [solver]: https://online-optimizer.appspot.com/?model=builtin:default.mod

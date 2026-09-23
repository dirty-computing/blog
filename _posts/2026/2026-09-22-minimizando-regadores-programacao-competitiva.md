---
layout: post
title: "Minimizando regadores! Questão de programação competitiva"
author: "Jefferson Quesado"
tags: programação-competitiva matemática geometria grafos grafo-intervalo java
base-assets: "/assets/minimizando-regadores-programacao-competitiva/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

> Baseado na minha resposta sobre
> [Qual o menor número de irrigadores (círculos) necessários para se cobrir a superfície de uma folhagem (retângulo)?](https://pt.stackoverflow.com/a/473495/64969).
> Baseado, não literalmente copiado, como havia um determinado grau de
> interlocução com o autor da pergunta, achei melhor reescrever isso de modo
> que caiba mais naturalmente no blog.

O usuário [Benuck](https://pt.stackoverflow.com/users/44119/benuck) postou uma
dúvida sobre programação competitiva, que achei bem peculiar e respondi. A
íntegra da pergunta encontra-se no StackOverflow em Portguês
[aqui](https://pt.stackoverflow.com/q/369027/64969). Reproduzo abaixo a questão
que ele compartilhou lá.

De coisa a mais, ele mencionou coisas sobre o código que fez que deu o
resultado errado e colocou como tag C++ (classicamente uma das 3 linguagens que
mais vejo em programação competitiva, junto de C e Java). Na resposta original
eu me limitei a explicar o algoritmo que resolveria o problema e, também, a
comentar algo sobre o que ele tinha apresentado. Mas aqui vou fazer diferente:
vou apresentar a resposta mais completinha. E, por ser uma questão de
programação competitiva, vou dar uma resposta em Java. Também diferente do que
eu tinha postado inicialmente, minha análise aqui vai além da análise feita
originalmente, porque percebi coisas a mais que poderiam ser exploradas para
uma melhor resposta! Além disso, não vou trazer aqui a crítica a resposta
original do autor da pergunta, isso era mais coisa de interlocução com o autor
da pergunta.

Como exercício ao leitor vou deixar com você que costure a solução final!
Poucas coisinhas: juntar os snippets relevantes e também cuidar da leitura.

# O enunciado do problema

![Exemplo de um gramado com regadores]({{ page.base-assets | append: "questao.png" | relative_url }})

N borrifadores estão instalados em faixas gramadas de L metros de comprimento
e W metros de largura. Cada borrifador está instalado na linha central da faixa
gramática. Para cada borrifador é fornecido sua posição como sendo a distância
do lado mais a esquerda da linha central e também seu raio de operação.

Qual o menor número de borrifadores ligados para regar toda a faixa gramada?

## Entrada

A entrada consiste de até 35 casos. A primeira linha para cada caso contém os
inteiros N, L e W sendo 1≤N≤10000, 1≤L≤107, e 1≤W≤100. As próximas N linhas
contém 2 inteiros dando a posição x (0≤x≤L) e o raio de operação r (1≤r≤1000)
do borrifador.

## Saída

Para cada caso de teste a saída deve ser o menor número de borrifadores
necessários para regar toda a faixa gramada. Se for impossível regar toda a
faixa a saída deve ser -1.

## Exemplo de entrada

```text
8 20 2
5 3
4 1
1 2
7 2
10 2
13 3
16 2
19 4
3 10 1
3 5
9 3
6 1
3 10 1
5 3
1 1
9 1
```

## Exemplo de saída

```text
6
2
-1
```

# Analisando os componentes básicos do problema

Esse problema pode ser reduzido de cobertura de **área** para cobertura de
**segmentos**. A título de nivelar quem chegar nesta questão, vou explicar essa
transformação. E a área, por incrível que pareça, não é relevante para a
questão por um detalhe simples: o enunciado **garantiu** que todos os
borrifadores estarão exatamente no centro.

Assim, o terreno que nos é fornecido é algo assim:

![Um terreno, com a linha central, sem nenhum regador]({{ page.base-assets | append: "terreno-cru.png" | relative_url }})

De modo geral, você só encontrará estes seguintes 3 tipos de círculos nessa
linha central:

![Um terreno, com a linha central e 3 tipos de regador]({{ page.base-assets | append: "terreno-regadores.png" | relative_url }})

- o primeiro é um círculo que tem um diâmetro de irrigação menor do que `W`
- o círculo do meio é aquele que tem um diâmetro maior do que `W`
- o último círculo é aquele que tem um diâmetro de irrigação idêntico a `W`

Nesse tipo de caso, os pontos mais distantes da linha central do retângulo são
aqueles que são mais difíceis de serem regados. Se esse ponto for regado, eu
tenho por garantia que todo o segmento vertical associado a esse ponto fixo
também é regado.

Então, assim sendo, nosso problema acaba sendo transformado em cobrir esses
pontos extremos. Ou seja, cobrir um segmento inteiro.

Então, como faço para transformar o problema de áreas de círculos dentro do
retângulo para segmentos?

Primeiro, vamos entender como cada tipo de círculo vai ser projetado no
segmento inferior do retângulo (poderia usar simetricamente o superior, apenas
escolhi uma projeção conveniente para fazer o desenho)?

O primeiro tipo de círculo não alcança a borda, logo ele não é útil em regar na
borda inferior e sempre é desnecessário.

O terceiro tipo de círculo adicionará apenas um ponto no segmento inferior.
Como estamos tratando de uma quantidade finita de círculos, a união de muitos
pontos nunca chegará a fazer um segmento, logo esse tipo de borrifador também
não contribuirá para fazer a irrigação, assim como o primeiro tipo de
borrifador.

O segundo tipo vai projetar todo um intervalo, como ilustrado abaixo:

![Foco no regador, de vermelho o raio do alcance do regador até a borda do terreno, de azul um segmento que cobre a borda]({{ page.base-assets | append: "regador.png" | relative_url }})

{% katexmm %}

O raio do círculo foi ilustrado em vermelho, o segmento projetado do círculo
foi indicado em ciano. O cálculo para saber onde começa e onde termina esse
segmento já está na pergunta:
$\left[ x-\sqrt{r^2 - \left(\frac{w}{2}\right)^2} , x+\sqrt{r^2 - \left(\frac{w}{2}\right)^2} \right]$,
onde `x` é a posição do borrifador, `r` o seu raio e `w` a largura do campo.

{% endkatexmm %}

## Derivando a fórmula

Vamos derivar a fórmula sobre o quanto que o regador vai projetar no segmento
da borda do gramado?

![Foco no regador, de vermelho o raio do alcance do regador até a borda do terreno, de azul um segmento que cobre a borda]({{ page.base-assets | append: "regador.png" | relative_url }})

{% katexmm %}

Se você fizer um segmento do centro do círculo até a parte inferior do
retângulo de maneira perpendicular, perceberá que ele cairá exatamente no meio
do segmento. Assim, como ele é perpendicular, se unir esse segmento, um dos
raios e pegar o segmento da ponta do segmento perpendicular obterá um triângulo
retângulo. A hipotenusa é conhecida, o raio do círculo, r; um dos catetos
também é conhecido, que é o comprimento do segmento perpendicular do centro do
círculo até o retângulo, que é metade da largura do campo, portanto
$\frac{w}{2}$; sobrando então o outro cateto para se calcular o comprimento que
é $\sqrt{r^2 - \left(\frac{w}{2}\right)^2}$. Então, se eu pegar o ponto do
centro do círculo e andar para a esquerda, obtenho o ponto a esquerda do
segmento como sendo $x-\sqrt{r^2 - \left(\frac{w}{2}\right)^2}$, e se andar
para a direita $x+\sqrt{r^2 - \left(\frac{w}{2}\right)^2}$. Portanto, o
intervalo coberto é
$\left[x-\sqrt{r^2 - \left(\frac{w}{2}\right)^2}, x+\sqrt{r^2 - \left(\frac{w}{2}\right)^2}\right]$

Note que, para.caso em que o regador tem raio igual a metade da largura do
gramado (ie, $r = \frac{w}{2}$), teremos que o "intervalo" coberto será
pontual, o que não nos serve para completar com a cobertura pois não há
intervalos abertos: $\left[x, x\right] = \left\{x\right\}$.

Para o caso em que o regador tem raio menor do que metade da largura do
gramado, tentar resolver a fórmula vai dar resultados imaginários. O que condiz
com "não tem cobertura significativa"/"pode descartar".

{% endkatexmm %}

# Montando a resposta

Primeiro, vamos precisar ler todos os pontos. Então, descartaremos os círculos
que não contribuirão para fazer o intervalo; ou seja, ficaremos apenas com
círculos cujos raios sejam estritamente maiores do que metade da largura.
Então, transformamos os círculos filtrados em intervalos.

Pronto, agora temos apenas intervalos e desejamos saber qual o menor conjunto
desses intervalos que cobrem todo um segmento. Sabe o que podemos usar para
modelar interseções de intervalos? Um grafo de intervalos!

Sim, agora estou transformando o problema em em problema de grafos. Como montar
esse grafo?

Um grafo de intervalo é uma maneira de representar, em grafo, segmentos e
interseções. Cada segmento é um vértice e a existência de interseções entre
dois intervalos é representado como uma aresta. Então, com o grafo montado,
precisamos sair de algum intervalo que contenha o `0` (origem) e, apenas
navegando pelas arestas, chegar em algum intervalo que contenha o `L`
(destino). Se não for possível, seja porque não tem nenhum intervalo que
contenha o `0` para partida, seja porque não tem nenhum ponto de chegada que
contenha o `L` ou porque o grafo é disconexo, então retorno `-1`.

> Em breve coloco mais sobre grafos de intervalos aqui no Computaria =3
> 
> Por hora, tem essas leituras no StackOverflow em Português para se aprofundar
> no tema:
> 
> - [Escalonamento de máquinas - Teoria dos Grafos](https://pt.stackoverflow.com/q/219143/64969)
> - [Como identificar um grafo inválido para problema de alocação de operadores por máquina?](https://pt.stackoverflow.com/q/257864/64969)
> - [Algoritmo O(n log n) para identificar intervalos contíguos dada uma lista de intervalos](https://pt.stackoverflow.com/q/443525/64969)

O primeiro passo é descobrir qual o vértice de partida. Independente de
qualquer coisa, o ponto de partida precisa englobar o ponto `0`. Portanto, devo
considerar como vértice candidato à partida todo intervalo cujo valor mais a
esquerda é `<=0`. Similarmente com o vértice de chegada, valor mais a direita
`>=L`.

Agora, como definir de maneiras mais assertivas esses pontos? Para o ponto de
partida, aquele que cobrir até o máximo a direita terá cobertura total sobre
qualquer outro ponto candidato de partida, portanto sobra apenas aquele cujo
valor mais a direita é o maior. De maneira semelhante, o ponto de chegada é
aquele cujo valor mais a esquerda é o menor.

Tem o caso especial de que o ponto de partida engloba a saída; nesse caso,
existe ainda a possibilidade de que o meu detector de origem/destino encontre
pontos distintos de origem e destino, mas é trivial verificar se apenas o
borrifador de origem seria o suficiente para cobrir tudo. Para esse caso, basta
retornar `1` e ir para a próxima entrada.

Definidos origem e destino, precisamos das arestas para navegar no grafo. A
priori, um grafo de intervalo é um grafo não-direcionado. Porém, podemos fazer
algumas otimizações e transformar nosso grafo de intervalo num grafo
direcionado acíclico.

Eu vou adicionar uma aresta do intervalo `[c1, f1]` para o intervalo `[c2, f2]`
se e somente se existir interseção entre esses intervalos e o segundo intervalo
terminar depois do primeiro intervalo e o segundo intervalo não englobar
totalmente o primeiro. Ou seja, se `c2 <= f1` (precisa haver interseção) e
`f2 > f1` (o segundo intervalo necessariamente termina depois do primeiro
intervalo) e `c2 > c1` (o primeiro intervalo em um pedaço anterior ao segundo
intervalo). Obviamente que ordenar os intervalos pelo seu valor a esquerda de
modo crescente nos permite fazer diversas otimizações na construção das
arestas.

Montando esse grafo, direcionado mesmo, basta rodar qualquer algoritmo de menor
distância entre vértices (considere todas as arestas com peso `1`) do ponto de
origem até o ponto de destino. Se não for possível alcançar o destino, a saída
precisa ser `-1`. Caso contrário, a saída é a distância encontrada mais um.

## Heurística vs shortest distance

Mas, será que precisa de um algoritmo genérico desses? Ou uma heurística gulosa
resolveria?

Para selecionar o primeiro regador, se seleciona aquele que contém a origem e
que vai mais longe. E se eu aplicasse isso para todos os outros regadores? No
momento em que seleciono, por exemplo, `[-2, 5]`, eu selecione o que irá mais
distante possível que contenha o 5? Então, por exemplo, entre `[3, 10]`,
`[1, 8]` e `[4, 11]`, a solução gulosa iria escolher o `[4, 11]`. Agora, essa
heurística consegue garantir o melhor resultado?

Bem, vamos analizar o que cada intervalo tem a arescentar:

{:class="marked-table"}
| "Nome" | Intervalo | Acréscimo efetivo |
| -----  | ----      |  -------          |
| A      | `[3, 10]` | `(5, 10]`         |
| B      | `[1, 8]`  | `(5, 8]`          |
| C      | `[4, 11]` | `(5, 11]`         |

Ou seja: seguir essa heurística é garantido que se escolha o melhor próximo
passo possível! Porque a interseção no final das contas é descartada, é como se
estivesse partindo de uma "nova origem", e partir de uma origem já se é sabido
que o importante é pegar aquele intervalo que vai mais pra direita o possível.

Em um "shortest path" clássico, eu poderia pegar esses 3 caminhos de modo
indiferente. Por exemplo, vamos supor que eu escolha ir pelo vértice A. Todos
os nós vizinhos que levam mais perto do destino vão ser, também, nós vizinhos
de C, pelo modo como se criam arestas em grafos de intervalo (há interseção?
Pois há aresta então). Os possíveis vizinhos que A pode ter que C não tem são
já vizinhos do intervalo já coberto, pois eles todos estão na interseção do que
já foi coberto e do vértice A. Não há, aqui, vizinhos de A que, ao mesmo tempo:

1. não seja vizinho do intervalo já explorado `[0, 5]`
2. não seja vizinho de C

Para o caso de vizinho hipotético Z que é vizinho também do intervalo já
explorado, o melhor seria explorar esse vértice diretamente partindo de
`[0, 5]`, não fazendo o salto `[0, 5] => A => Z`. Nesse caso, é melhor não
levar em consideração A e fazer `[0, 5] => Z`.

O segundo caso (não ser vizinho de C) valeria a pena para o caso genérico de
grafo em que fazer `O => A => Z =*> D` fosse mais curto do que `O => C =*> D`
(onde `=>` é um salto direto e `=*>` é um conjunto de saltos, possivelmente
usando vários vértices intermediários, portanto `=>` indica necessariamente a
existência da aresta, enquanto `=*>` indica a existência de um caminho com 1 ou
mais arestas).

Vamos analizar em termos de intervalos? Se Z é vizinho de A, e sabemos que C
tem um final além de A, sabemos que:

- `A_f < C_f`, por definição do problema
- `Z_i <= Z_f`, por definição de Z ser um intervalo
- `A_i, C_i <= O`, pois ambos A e C são vizinhos do ponto de partida
- `A_i <= Z_i <= A_f`, pois tem aresta ligando Z e A
- `O < Z_i`, pois não tem ligação de Z com o ponto de partida

Aqui, de `Z_i <= A_f`, temos por transitividade que `Z_i < C_f`. Como não tem
aresta ligando Z e C, isso significa que `Z_f < C_i`, pois isso garante que Z
está a esquerda de C (devido a `Z_i < C_f` sabemos que Z não pode estar a
direita de C). Como `Z_i <= Z_f`, e `Z_f < C_i`, temos que `Z_i < C_i`. Como
`C_i <= O`, podemos deduzir que `Z_i < C_i <= O`, o que implica `Z_i < O`, o
que contradiz `O < Z_i`. Portanto, não é possível que Z seja vizinho de A, não
seja vizinho da origem e não seja vizinho de C simultaneamente.

Se Z for um intervalo importante e essencial na navegação até o destino, isso
significa que poderemos passar nele tanto através de A quanto através de C. E
como C vai mais longe do que A, é mais eficiente navegar através de C.

## Regadores em intervalos

A primeira linha informa:

- a largura do campo
- o comprimento do campo
- a quantidade de regadores

Vou salvar a quadra em uma estrutura com o shape:

```ts
type Quadra = {
    l: int,
    w: int,
}
```

E então vou ler os próximo N regadores. O regador nasce com o shape
`{ x:int, r:int }`, então aqui eu já posso aplicar o filtro: se `r > w/2`,
pode passar. Caso contrário, recuso.

Depois, eu transformo em intervalos usando a fórmula descrita acima. Vou
aproveitar e já ordenar: primeiro pelo ponto mais a esquerda do intervalo;
havendo empate usa o ponto mais a direita para desempatar. Após essa
transformação, vai ter o shape `{ ini:number, fim:number }`.

A função para determinar o quanto é projetado em cima do intervalo da gramado
vou chamar de `shadow`. Ela que determina o quanto eu preciso caminhar a
esquerda a partir do centro do regador para projetar o trecho azul:

![Foco no regador, de vermelho o raio do alcance do regador até a borda do terreno, de azul um segmento que cobre a borda]({{ page.base-assets | append: "regador.png" | relative_url }})

E esse mesmo valor eu navego a direita para determinar o fim do trecho azul.
Esse valor foi [calculado previamente](#derivando-a-fórmula):

```java
static double shadow(int r, int w) {
    final var halfW = w/2.0;
    return Math.sqrt(r*r - halfW*halfW);
}
```

Então, para transformar um regador em um intervalo, peguemos o centro dele e
aplicamos a fórmula:

```java
record Intervalo(double ini, double fim) {}
record Regador(int x, int r) {}
record Quadra(int l, int w) {}

static Intervalo regador2intervalo(Regador g, Quadra q) {
    final var s = shadow(g.r(), q.w());
    return new Intervalo(g.x() - s, g.x() + s);
}
```

E o filtro, que também é super importante (se não aplicar o filtro teremos raiz
de negativo, que é `NaN`):

```java
static boolean valido(Regador g, Quadra q) {
    return g.r() > q.w()/2.0;
}
```

A ordenação é feita assim:

```java
static int compararIntervalos(Intervalo i1, Intervalo i2) {
    if (i1.ini() < i2.ini()) {
        return -1;
    } else if (i1.ini() > i2.ini()) {
        return +1;
    } else {
        if (i1.fim() > i2.fim()) {
            return -1;
        } else if (i1.fim() == i2.fim()) {
            return 0;
        } else {
            return +1;
        }
    }
}
```

Se eu quisesse uma solução mais OO baseado nas abstrações do Java e não me
importasse em performance em frio (talvez em quente seja otimizado pelo JIT),
eu poderia fazer assim:

```java
Comparator.comparingDouble(Intervalo::ini)
    .thenComparing(
        Comparator.comparingDouble(Intervalo::fim)
            .reversed()
    )
```

Portanto, após a leitura e obtenção das estruturas mais básicas da quadra e da
lista de regadores, podemos fazer isso:

```java
// ArrayList<Regador> regadores
// Quadra q
regadores.stream()
    .filter(g -> valido(g, q))
    .map(g -> regador2intervalo(g, q))
    .sorted((i1, i2) -> compararIntervalos(i1, i2))
    .toList();
```

Hmmm, posso fazer o filtro e o mapeamento de modo mais expressivo. Ambos pegam
regador e quadra, regador como argumento variante... e se eu colocar o filtro
"será que esse regador é válido para esta quadra?" e por no "ponto de vista" da
quadra? Ficaria assim:

```java
record Quadra(int l, int w) {
    public boolean valido(Regador g) {
        return g.r() > w/2.0;
    }
}
```

E para pegar o intervalo do regador _naquela_ quadra? Teria o
`regador2intervalo` do mesmo jeito, mas agora a função de `shadow` fica
inerente à quadra:

```java
record Quadra(int l, int w) {
    public boolean valido(Regador g) {
        return g.r() > w/2.0;
    }

    public double shadow(int r) {
        final var halfW = w/2.0;
        return Math.sqrt(r*r - halfW*halfW);
    }

    public Intervalo regador2intervalo(Regador g) {
        final var s = shadow(g.r());
        return new Intervalo(g.x() - s, g.x() + s);
    }
}
```

Aqui poderíamos ter uma expressão bonitinha e pedir o intervalo dada a sombra
projetada para o próprio regador!

```java
record Regador(int x, int r) {
    public Intervalo intervalo(double s) {
        return new Intervalo(x - s, x + s);
    }
}

record Quadra(int l, int w) {
    public boolean valido(Regador g) {
        return g.r() > w/2.0;
    }

    public double shadow(int r) {
        final var halfW = w/2.0;
        return Math.sqrt(r*r - halfW*halfW);
    }

    public Intervalo regador2intervalo(Regador g) {
        return g.intervalo(shadow(g.r()));
    }
}

// ArrayList<Regador> regadores
// Quadra q
regadores.stream()
    .filter(q::valido)
    .map(q::regador2intervalo)
    .sorted((i1, i2) -> compararIntervalos(i1, i2))
    .toList();
```

Hmmm, posso simplificar isso ainda mais transformando o intervalo em algo
comparável aqui:

```java
record Intervalo(double ini, double fim) implements Comparable<Intervalo> {

    @Override
    public int compareTo(Intervalo i2) {
        final var i1 = this; // sim, para aproveitar o código previamente escrito
        if (i1.ini() < i2.ini()) {
            return -1;
        } else if (i1.ini() > i2.ini()) {
            return +1;
        } else {
            if (i1.fim() > i2.fim()) {
                return -1;
            } else if (i1.fim() == i2.fim()) {
                return 0;
            } else {
                return +1;
            }
        }
    }
}

// ArrayList<Regador> regadores
// Quadra q
regadores.stream()
    .filter(q::valido)
    .map(q::regador2intervalo)
    .sorted()
    .toList();
```

Eu posso aproveitar e expremer performance da comparação agora, evitar depender
do JIT e diminuir a quantidade de chamadas adicionais para funções:

```java
record Intervalo(double ini, double fim) implements Comparable<Intervalo> {

    @Override
    public int compareTo(Intervalo i2) {
        if (ini < i2.ini) {
            return -1;
        } else if (ini > i2.ini) {
            return +1;
        } else {
            if (fim > i2.fim) {
                return -1;
            } else if (fim == i2.fim) {
                return 0;
            } else {
                return +1;
            }
        }
    }
}
```

## Navegando os intervalos

Com tudo ordenado, vamos seguir agora montando o que desejamos. Pegamos um
ponto de partida, que o primeiro será o `0`. Então, vamos decidir qual vai ser
o próximo intervalo: ele precisa conter o ponto atual e ir mais longe do que o
intervalo sendo segurado.

Para o caso de impossibilidade trivial, verifiquemos se o primeiro intervalo
contém o `0`: se não conter, já retorna `-1` e fim desse caso. Caso contrário,
vamos navegar assim, levando em conta o "intervalo segurado" como o primeiro
intervalo. Ao chegar em um intervalo que não contém o ponto atual, vamos fazer
a "promoção": o ponto atual se torna o fim do intervalo segurado e vamos
segurar o primeiro intervalo como sendo o elemento que estamos lendo. E então
repetimos o processo.

> Um caso trivial é a lista de regadores chegar vazia! Aí não terá nenhum
> regador que bata no `0` de toda sorte!

Repetimos o processo? Bem, quase... primeiro, vamos validar a questão da
continuidade: o intervalo sendo analisado precisa necessariamente conter o novo
ponto atual. Se não contiver? Retornemos `-1`. E se contiver? Incrementamos um
contador de regadores ligados e seguimos! Aliás, seguimos até a análise da
trivialidade: ao promover, se ultrapassar o limite da quadra, já podemos parar.

Se lermos todos os intervalos e não encontramos o fim da quadra? Bem, então não
tem como regar toda a quadra, `-1`.

```java
static int contaRegadores(List<Intervalo> regadores, Quadra q) {
    if (regadores.isEmpty()) {
        return -1;
    }
    final var max = q.l();
    var segurado = regadores.getFirst();
    var pontoAtual = 0.0;
    var qnt = 1;

    // caso não seja possível ligar com o início
    if (segurado.ini() > pontoAtual) {
        return -1;
    }
    // trivialidade: regador escolhido chega até o fim ou além
    if (segurado.fim() >= max) {
        return qnt;
    }
    for (final var i: regadores) {
        // esse regador contém o ponto atual?
        if (i.ini() <= pontoAtual) {
            // será que chegamos no fim?
            if (i.fim() >= max) {
                return qnt;
            }
            // será que vale a pena trocar o intervalo segurado?
            if (i.fim() > segurado.fim()) {
                segurado = i;
            }

            // ok, pega o próximo elemento
            continue;
        }
        // tá, não contém, mas será que ele linka?
        final var novoPontoAtual = segurado.fim();

        // não contém o novo ponto atual, a interseção é vazia
        if (i.ini() > novoPontoAtual) {
            return -1;
        }

        // vamos fazer a promoção
        pontoAtual = novoPontoAtual;
        segurado = i;
        qnt++;
        // será que chegamos no fim?
        if (i.fim() >= max) {
            return qnt;
        }
    }

    // se chegou aqui é porque achou um intervalo contínuo da origem até um valor
    // menor do que a largura da quadra
    // foi contínuo mas não chegou onde deveria, portanto é impossível cobrir.
    return -1;
}
```

Hmmm, sabe o que percebi? Que a ordenação para manter o "mais longe" acaba não
sendo útil pois de toda sorte vamos passar por todos os pontos. Vai apenas no
máximo evitar algumas trocas na variável `segurado`. Como não vai fazer lá
grandes ajudas, vou remover o excesso de código:

```java
record Intervalo(double ini, double fim) implements Comparable<Intervalo> {

    @Override
    public int compareTo(Intervalo i2) {
        if (ini < i2.ini) {
            return -1;
        } else if (ini > i2.ini) {
            return +1;
        } else {
            return 0;
        }
    }
}
```

De modo geral, com exceção de como lidar com a entrada do problema, fica assim:

```java
static void resolveCaso(Quadra q, List<Regador> regadores) {
    final var intervalos = regadores.stream()
        .filter(q::valido)
        .map(q::regador2intervalo)
        .sorted()
        .toList();
    
    IO.println(contaRegadores(intervalos, q));
}
```

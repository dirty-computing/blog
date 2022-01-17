---
layout: post
title: "Uma demonstração de que Autômatos de Fila equivalem a Máquinas de Turing em poder computacional"
author: "Jefferson Quesado"
tags: computação-teórica autômatos matemática
base-assets: "/assets/automato-fila-equiv-mt"
---

O objetivo aqui é fazer um Autômato de Fila que consiga emular o funcionamento de uma
Máquina de Turing. Assumindo o teorema de que Máquinas de Turing são capazes de realizar
qualquer computação, a tarefa estaria completa. Porém, a primeira demonstração aqui será
mostrando que existe um algoritmo que transforma um Autômato de Fila em uma Máquina de Turing.

Antes de podermos prosseguir, precisamos antes estabelecer algumas definições do que é cada
um desses autômatos, funções de transição e aceitação de entradas.

# Definições

## Transições

{% katexmm %}

Uma transição é uma função que mapeia um estado em outro, recebendo outros argumentos
eventualmente também.

Essa função pode ter dois ou mais mapeamentos distintos para a mesma entrada. Isso nos dá
o seguinte, para o exemplo de uma Máquina de Turing:

$$
(Q, \Sigma) \mapsto (Q, \Sigma, \left \{\Leftarrow, \Rightarrow\right\})
$$

Pode gerar dois mapeamentos:

$$
(q_0, \sigma_0) \mapsto (q_1, \sigma_1, \Leftarrow)\\
(q_0, \sigma_0) \mapsto (q_2, \sigma_2, \Rightarrow)\\
q_0,q_1,q_2 \in Q, \sigma_0,\sigma_1,\sigma_2 \in \Sigma
$$

E isso estaria certo. Podemos dizer então que a função de transição é um elemento
dentro do conjunto $\delta$ que seja do seguinte formato:

$$
t_0 \in \delta \implies t_0 = (A, S \subset B^+)
$$

Onde, para $b_0, b_1 \in B$, os seguintes elementos são equivalentes:

$$
(A, S b_0 b_1 E) = (A, \beta_s b_1 b_0 \beta_e), \forall \beta_s, \beta_e \in S\cup \left\{ \sigma \right\}
$$

Outro ponto importante é que todo elemento na palavra na segunda posição da tupla precisa
ser distinto, e toda string string em $B$ com pelo menos um elemento é aceita em $S$:

$$
b \in B \implies b \in S\\
\forall \beta_0 b_0 \beta_1 b_1 \beta_3 \in S \implies b_0, b_1 \in B, b_0\neq b_1, \beta_0,\beta_1,\beta_2 \in S \cup \left\{ \sigma \right\}
$$

Um elemento $a \in A$ qualquer só pode aparecer uma única vez no lado esquerdo
da tupla.

Nesse sentido, as duas transições acima mencionadas da Máquina de Turing arbitrária seriam representadas assim:

$$
\Bigg( \bigg(q_0, \sigma_0\bigg), \bigg((q_1, \sigma_1, \Leftarrow), (q_2, \sigma_2, \Rightarrow)\bigg) \Bigg)
$$

Ou, em outras palavras, $A = Q\times\Gamma ; B = Q\times\Gamma\times \left \{\Leftarrow, \Rightarrow\right\}$

Isso nos permite montar um conjunto de tuplas $(A, B)$ que equivalam ao conjunto de tuplas
$(A, B^+)$; vamos chamar o mapemaento $(A, B)$ de _mapeamento de transições_, enquanto que
o $(A, B^+)$ é o _mapeamento completo_.

Os dois modelos são equivalentes.

#### Demonstração, mapeamento completo para mapeamento de transição

Tome um elemento do mapeamento de transição $t \in \delta, t: (a, b\beta)$, com $a \in A$, $b \in B$ e $\beta \in B^*$.

Pela definição, $\forall t_x \in \delta, t_x[0] = a \implies t_x = t$. Isso significa que $t$ é a única transição
que tem como argumentos $a$, produzindo um dos elementos dentro de $b\beta$.

Mapeemos para transições simples. Vamos aplicar um algoritmo recursivo para gerar um conjunto de transições $(A, B)$:

$$
mapeamento\_simples\left(a, b\beta\right) \mapsto \{(a, b)\} \cup mapeamento\_simples\left(a, \beta\right)\\
mapeamento\_simples\left(a, \sigma\right) \mapsto \emptyset
$$

No exemplo do mapeamento da máquina de Turing acima:

$$
mapeamento\_simples\Bigg( \bigg(q_0, \sigma_0\bigg), \bigg((q_1, \sigma_1, \Leftarrow), (q_2, \sigma_2, \Rightarrow)\bigg) \Bigg) \mapsto\\
\Big\{\big((q_0, \sigma_0), (q_1, \sigma_1, \Leftarrow)\big)\Big\} \cup mapeamento\_simples\Bigg( \bigg(q_0, \sigma_0\bigg), \bigg((q_2, \sigma_2, \Rightarrow)\bigg) \Bigg) \mapsto\\
\Big\{\big((q_0, \sigma_0), (q_1, \sigma_1, \Leftarrow)\big), \big((q_0, \sigma_0), (q_1, \sigma_1, \Rightarrow)\big)\Big\}\cup mapeamento\_simples\Bigg( \bigg(q_0, \sigma_0\bigg), \sigma \Bigg) \mapsto\\
\Big\{\big((q_0, \sigma_0), (q_1, \sigma_1, \Leftarrow)\big), \big((q_0, \sigma_0), (q_1, \sigma_1, \Rightarrow)\big)\Big\}
$$

#### Demonstração, mapeamento de transição para mapeamento completo

Aqui, temos um conjunto de pares $(A, B)$ e gostaríamos de juntar tudo que tenha o mesmo LHS e gerar uma lista do RHS. Seria o equivalente
Java a:

```java
List<Par<A, B>> transicoes = ...;
Map<A, List<B>> mapemaentoCompleto = transicoes.stream()
  .collect(Collectors.groupingBy(Par::LHS,
           Collectors.mapping(Par::RHS, Collectors.toList())));
```

## Máquina de Turing

Uma máquina de Turing é uma séptupla $\left<Q, q_0, F, \Sigma, b, \Gamma, \delta \right>$ onde:

- $Q$ é o conjunto de todos os estados
- $q_0$ é o estado inicial, $q_0 \in Q$
- $F$ é o conjunto de estados de aceitação, $F \subseteq Q$
- $\Sigma$ é o conjunto de elementos da entrada, $\Sigma \subseteq \Gamma \setminus \{b\}$
- $b$ é o símbolo de espaço em branco, $b \in \Gamma$
- $\Gamma$ é o conjunto de todos os elementos de trabalho, os símbolos da fita
- $\delta$ são as transições, sempre mapeamento de um estado e um símbolo na cabeça de leitura para outro
  estado, o novo símbolo que ficará no lugar do símbolo lido e também se a cabeça de leitura seguiu para
  a esquerda ou para a direita, $(Q\setminus F, \Gamma) \mapsto (Q, \Gamma, \{\Leftarrow, \Rightarrow\})$

Ao alcançar um estado final $q_f \in F$, como não tem transição para esse estado, alcança-se a aceitação.

Caso se esteja em um estado não final $q \in Q, q \not\in F$ com um símbolo de fita $\gamma$ e não seja
possível disparar alguma transição, então a entrada foi rejeitada.

## Autômato de fila

Um autômato de fila é uma sextupla $\left<Q, q_0, \Sigma, \$, \Gamma, \delta \right>$ onde:

- $Q$ é o conjunto de todos os estados
- $q_0$ é o estado inicial, $q_0 \in Q$
- $\Sigma$ é o conjunto de elementos da entrada, $\Sigma \subseteq \Gamma \setminus \{\$\}$
- $\$$ é o símbolo que representa o final da palavra, $\$ \in \Gamma$
- $\Gamma$ é o conjunto de todos os elementos de trabalho
- $\delta$ são as transições, sempre mapeamento de um estado e um símbolo da fita para um novo estado
  e, evantualmente, a inserção de uma string $\Gamma^*$ no final da fila.

Diz-se que houve aceitação ao, no final do processamento, a fila estar vazia. Caso a fila não esteja vazia e não
tenha mais transição para disparar, aconteceu a rejeição de uma palavra.

# Simulando um autômato de fila em uma Máquina de Turing

Temos um autômato de fila $\left<Q, q_0, \Sigma, \$, \Gamma, \delta \right>$. Precisamos de uma Máquina de Turing que
se comporte exatamente como esse autômato de fila.

Vamos iniciar com a fita tendo apenas a palavra de entrada, sem o $\$$, pois estamos numa Máquina de Turing, correto?
Aqui, o foco inicial será o autômato de fila que reconhece a palavra $A^nB^nC^n$. Vamos explorar esse exemplo sem
perder generalidade:

```
qi
V
AAABBBCCC
```

Onde a seta para baixo mostra a cabeça de leitura da Máquina de Turing. O estado está indicado acima da cabeça de
leitura, no caso, $q_i$. Símbolos em branco à esquerda ou à direita serão omitidos exceto quando proveitoso (indicado
por `X` em uma linha abaixo). Por exemplo, a máquina está na estado $q_j$ dois espaços em branco antes da entrada:

```
qj
V
  AAABBBCCC
XX
```

Bem, na simulação da autômato de fila, apenas mantemos a fila e o estado da máquina, sem maiores indicações. Isso permite,
por exemplo, colocar a evolução do autômato assim, com cada transição sendo uma linha:

{% endkatexmm %}


```
q0: AAABBBCCC$
qa: AABBBCCC$
qa: ABBBCCC$A
qa: BBBCCC$AA
qb: BBCCC$AA
qb: BCCC$AAB
qb: CCC$AABB
qc: CC$AABB
qc: C$AABBC
qc: $AABBCC
q0: AABBCC$
```

{% katexmm %}

## Um autômato de fila para $A^nB^nC^n$

Como motivador para a transformação, vamos iniciar com o autômato de fila e então aplicar regras de conversão
para Máquina de Turing. Então, como definir esse autômato? Vamos pelas informações conhecidas: começa em $q_0$,
tem os símbolos de entrada $\Sigma = \left\{A,B,C\right\}$, e tem o símbolo terminal $\$$.

Um ponto importante é que ele precisa reconhecer a palavra gerada quando $n = 0$, portanto $\epsilon$, a palavra
vazia. Isso se dá usando a seguinte transformação:

$$
(q_0, \$) \mapsto (q_0, \epsilon)
$$

Executando o autômato apenas com essa regra passando a palavra vazia para ele:

{% endkatexmm %}

```
q0: $
q0:
```

{% katexmm %}

Como a única opção foi consumir o $\$$ sem produzir nada. A fila ficou vazia após esse consumo, portanto
houve o aceite da entrada.

Agora, e para os outros casos? Meu pensamento aqui é simples:

- seja $\Theta_0, \Theta_1 \in [ABC]^*$
- seja a fila $AA^x\Theta_0\$\Theta_1$
- esteja o autômato em um estado $q_x \neq q_a$
- então a transição $(q_x, A) \mapsto (q_a, \epsilon)$ existe
- e a transição $(q_a, A) \mapsto (q_a, A)$ também existe
- portanto, após $x+1$ transições, sairemos de $q_x: AA^x\Theta_0\$\Theta_1$ para $q_a: \Theta_0\$\Theta_1 A^x$

Note que os estados $q_x, q_a$ e as duas transições descritas acima vão consumir exatamente um único elemento
de uma sequência de $A$s e jogar o resto da sequência para o final. Podemos fazer coisas equivalentes para
$B$ e para $C$. Detalhe que, no caso de $C$, ao encontrar $\$$, podemos usar a estratégia de jogar $\$$ no final
e voltar para $q_0$. Se chegou nesse ponto, então saímos de $q_0: AA^xBB^xCC^x\$$ para $q_0: A^xB^xC^x\$$. Afinal,
consumimos sempre um elemento de uma sequência de $A$, $B$ ou $C$ e jogamos o resto para o final da fila. Basicamente
reduzimos o problema com $n=x+1$ para $n=x$, até o ponto de encontrar $n=0$ que já sabemos reconhecer.

Por questões de simplicidade, usemos $q_y$ para $B$ o que o $q_x$ é para o $A$, e equivalentemente $q_z$ para o $C$.
$q_b$ e $q_c$ são equivalentes ao $q_a$ no sentido que são produzidos pelo $q_x$ ou equivalente e jogam o resto da
sequência no final da fila.

No caso das transições usando $A$, temos que a primeira possibilidade para $q_x$ é $q_0$, pois o sistema iniciará
exatamente em $q_0$ e necessita consumir um $A$ ou aceitar a palavra vazia. Não descartemos, ainda, outras possibilidades
para $q_x$.

Similarmente, chegaremos na sequência de $B$ através de $q_a$, então uma possibilidade para $q_y$ seria justamente
$q_a$. E para $q_c$, temos que chegará da sequência de $B$s, portanto $q_b$ é uma das possibilidades para $q_z$.

Assim, temos as seguintes transições definidas:

$$
\begin{array}{lcl}
	(q_0, \$)&\mapsto&(q_0, \epsilon)\\
	(q_0, A)&\mapsto&(q_a, \epsilon)\\
	(q_a, A)&\mapsto&(q_a, A)\\
	(q_a, B)&\mapsto&(q_b, \epsilon)\\
	(q_b, B)&\mapsto&(q_b, B)\\
	(q_b, C)&\mapsto&(q_c, \epsilon)\\
	(q_C, C)&\mapsto&(q_c, C)\\
	(q_C, \$)&\mapsto&(q_0, \$)
\end{array}
$$

Ok, agora isso realmente reconhece o que desejamos? Vamos ver...

Se tivermos por acaso $q_0$ tentando consumir $B$ ou $C$, não tem transição. O autômato de fila não consegue
disparar nenhuma transição e não está vazio, portanto rejeitou a entrada. Logo, recusa entradas no formato
$[BC][ABC]^*$.

Saindo de $q_a$, se for um $C$, trava também. Logo, entradas do tipo $A^+C[ABC]^*$ também são recusadas. Se chegar
no final da palavra, também recusa, daí $A^+$ também é rejeitado. De modo semelhante, também se recusa quando
em $q_b$ encontrar um $A$ ou o final da palavra, ou quando em $q_c$ encontrar um $A$ ou um $B$. Logo, as únicas
opções são um subconjunto de $A^+B^+C^+|\epsilon$. Tomemos a forma genérica $A^xB^yC^z$, com $x,y,z \ge 0$. Note
que no caso $x = y = z = 0$ temos $\epsilon$, que é aceito.

Esse autômato é de tal forma que sempre repete os mesmos estados nessa ordem: $q_0 \mapsto q_a \mapsto q_b \mapsto q_c
\mapsto q_0$. Já vimos que para ocorrer essa transição toda de $q_0$ para $q_0$ novamente consumimos necessariamente 1
A, 1 B e 1 C. Portanto, do estado inicial $q_0: A^{x+1}B^{y+1}C^{z+1}\$$ iremos naturalmente para $q_0: A^xB^yC^z\$$.

Chamemos essa operação de "rodar um ciclo". Suponha agora que $x,z > y$. Isso significa que poderemos rodar no máximo
$y$ ciclos. Após rodar $y$ ciclos, teremos que o autômato de fila estará $q_0: A^{x-y}C^{z-y}\$$. Porém $A^+C^+$ não é
reconhecido, pois é um subconjunto de $A^+C[ABC]^*$ e já vimos que esse conjunto não é reconhecido. Logo, não podemos ter
$x,z > y$. Agora, e se $x > y \ge z$? Isso ainda é possível... Então, após rodar $z$ ciclos, teremos $q_0: A^{x-z}B^{y-z}\$$.
Isso é uam palavra em $A^+B^*$. O autômato recusa $A^+$, portanto ainda tem $A^+B^+$, porém vimos já que ele não aceita
esse tipo de entrada, portanto também recusa palavras em $A^+B^+$. Portanto, chegamos a conclusão que $x \le y$.

Usando raciocínio semelhante iremos encontrar que $x \le z$. Assim, podemos fazer a hipótese de $y \ne z$.
Como $x \le y$ e $x \le z$, temos que $y-x \ge 0$ e $z-x \ge 0$. Portanto, após rodar $x$ ciclos, teremos
o autômato de fila assim: $q_0: B^{y-x}C^{z-x}$. Se $y-x \ne 0$, teremos um subconjunto de $B^+C^*$, porém
já vimos que entradas $[BC][ABC]^*$ são rejeitadas. Portanto, $y-x = 0$. Isso nos leva a crer que $z-x > 0$,
pois $y \ne z$. Com isso, teremos $C^+$, que também é uma entrada rejeitada por também ser um subconjunto de
$[BC][ABC]^*$. Logo, temos que $x \le y, z = y$. Com um esforço semelhante, temos que se $x < y$ não
iremos reconhecer a palavra, logo só nos resta $x = y = z$. Então, esse autômato de fila realmente
reconhece a linguagem desejada, e apenas ela.

Definindo o autômato de fila:

$$
Q = \left\{ q_0, q_a, q_b, q_c \right\}\\
q_0\ \text{é o estado inicial}\\
\Sigma = \left\{ A, B, C \right\}\\
\$\ \text{é o indicador de final de palavra}\\
\Gamma = \left\{ A, B, C, \$ \right\}\\
\delta=\left\{
	\begin{array}{lcl}
		(q_0, \$)&\mapsto&(q_0, \epsilon)\\
		(q_0, A)&\mapsto&(q_a, \epsilon)\\
		(q_a, A)&\mapsto&(q_a, A)\\
		(q_a, B)&\mapsto&(q_b, \epsilon)\\
		(q_b, B)&\mapsto&(q_b, B)\\
		(q_b, C)&\mapsto&(q_c, \epsilon)\\
		(q_C, C)&\mapsto&(q_c, C)\\
		(q_C, \$)&\mapsto&(q_0, \$)
	\end{array}
\right\}
$$

## Simulando através de uma Máquina de Turing

Inicialmente, vamos pegar a entrada e transformá-la de modo digno. Na Máquina de Turing a entrada
será necessariamente apenas a palavra. Logo, para simular melhor o autômato de fila, nada como
transformar a entrada da Máquina de Turing na entrada do autômato de fila.

Portanto, para o estado inicial da Máquina de Turing $q_t$, temos de sair de

{% endkatexmm %}

```
qt
V
AAABBBCCC
```

para
```
q0'
V
AAABBBCCC$
```

{% katexmm %}
onde $q_{0^{'}}$ é o equivalente ao $q_0$ do autômato de fila.

Seja $q_t$ o estado inicial da Máquina de Turing, o objetivo dela é único e simplesmente inserir o símbolo
terminador $\$$ no final da entrada. Logo, todo e qualquer símbolo da entrada deverá permanecer inalterado
enquanto a Máquina de Turing caminha para a direita até encontrar o primeiro branco, então substituirá esse
branco por $\$$ e passará a caminhar à esquerda para voltar para o início.
{% endkatexmm %}

Exemplificando, sairemos de

```
qt
V
AAABBBCCC
```

passaremos por alguns estágios intermediários como

```
     qt
     V
AAABBBCCC
```

até chegarmos em

```
         qt
         V
AAABBBCCC
         X
```

{% katexmm %}
Nesse momento, o espaço em branco será substituído por $\$$ e o estado mudará para $q_i \ne q_t$, que é o estado
que iremos usar apenas para fazer o rebobinar. Então, o próximo passo é
{% endkatexmm %}

```
        qi
        V
AAABBBCCC$
```

iremos passar por alguns estados intermediários como

```
     qi
     V
AAABBBCCC$
```

e finalmente iremos ultrapassar o início da entrada:

```
qi
V
 AAABBBCCC$
X
```

{% katexmm %}
Nesse momento, iremos manter o branco ali e caminhar a direita, assumindo o estado $q_{0^{'}}$:
{% endkatexmm %}

```
q0'
V
AAABBBCCC$
```

como gostaríamos.

{% katexmm %}
Agora, vamos usar a operação de rebobinar em diversos momentos, pois iremos escrever coisas no final da fita
para representar o que é produzido no final do disparo do autômato de fila. Portanto, podemos deixar um marcador
especial que, ao rebobinador encontrar esse marcador, ele irá para um estado específico mapeado do autômato de
fila. Como no autômato de fila usamos $q_0$, $q_a$ e assim por diante, usarei esse subscrito para representar
esse estado. Isso significa que o começo do nosso processamento não é mais ir para a direita e colocar um $\$$ no
final da entrada, mas sim ir para a esquerda, inserir $0$ na entrada, então ir para a direita para inserir o $\$$
no final, então rebobinar tudo e iniciar o processamento do autômato de fila. Então, chamemos de $q_g$ o estado inicial
da Máuqina de Turing.

$q_g$ tem como única intenção ir para a esquerda mantendo o caracter inicial, escrever $0$ no espaço em branco e ir
para a direita com o $q_t$ já definido.
{% endkatexmm %}

A execução fica assim:

```
qg
V
AAABBBCCC
```

```
qg
V
 AAABBBCCC
X
```

```
 qt
 V
0AAABBBCCC
```

{% katexmm %}
Todo o resto continua sendo bem equivalente, mas temos que $q_i$ irá consumir $0$ e irá para a direita
no estado $q_{0^{'}}$:
{% endkatexmm %}

```
          qi
          V
0AAABBBCCC$
```

```
 qi
 V
0AAABBBCCC$
```

```
qi
V
0AAABBBCCC$
```

```
 q0'
 V
 AAABBBCCC$
X
```

{% katexmm %}
Por algo que irei explicar mais tarde, vamos usar $q_{t_\$}$ no lugar de $q_t$, mas ele faz exatamente o que foi definido para
$q_t$: vai para a direita e, ao achar um estado em branco, produz $\$$ e entra no estado de rebobinar.

Só aqui, para determinar alguns elementos da Máquina de Turing, temos algumas definições:

- todo estado do autômato de fila implica em um símbolo de trabalho da Máquina de Turing e também um estado
  da Máquina de Turing
- vamos chamar o mapeamento de estado do autômato de fila para elemento de trabalho da função $\tau: Q_{AF} \mapsto \Gamma_{MT}$
- vamos chamar o mapeamento de estado do autômato de fila para estado da máquina de Turing da função $\chi: Q_{AF} \mapsto Q_{MT}$
- o alfabeto de entrada do autômato de fila é o mesmo alfabeto de entrada da Máquina de Turing, $\Sigma_{AF} \equiv
  \Sigma_{MT}$
- $\$$ pertence ao alfabeto de trabalho da Máquina de Turing (ou algo equivalente a ele)
- não há equivalente ao branco no autômato de fila, portanto $\forall \gamma \in \Gamma_{AF}, t(\gamma) \ne b$,
  sendo $t: \Gamma_{AF} \mapsto \Gamma_{MT}$ a função que mapeia elementos de trabalho do autômato de fila para
  elementos de trabalho da Máquina de Turing
- de modo similar, não há equivalente do branco dos estados do autômato de fila na fita de trabalho da Máquina
  de Turing, $\forall q \in Q_{AF}, \tau(q) \ne b$, onde $\tau: Q_{AF} \mapsto \Gamma_{MT}$ transforma o estado
  do autômato de fila em um símbolo de trabalho da Máquina de Turing
- a Máquina de Turing começa no estado $q_g$ que tem as transições $\forall \sigma \in \Sigma, (q_g, \sigma)
  \mapsto (q_g, \sigma, \Leftarrow)$ e também $(q_g, b) \mapsto (q_{t_\$}, \tau(q_0), \Rightarrow)$, sendo $q_0$ o estado
  inicial do autômato de fila e $q_{t_\$} \ne q_g$.
- existem estados da máquina de Turing que não devem possuir equivalência no autômato de fila, vamos chamar
  o conjunto desses estados de $R$, portanto $\forall q \in Q_{AF}, \chi(q) \not\in R$, sendo $\chi: Q_{AF} \mapsto Q_{MT}$
  a função que mapeia de um estado do autômato de fila para um estado na máquina de Turing
- $q_g, q_{t_\$}, q_i \in R$
- para colocar o $\$$ no final, temos que ter as seguintes transições $\forall \sigma \in \Sigma, (q_{t_\$}, \sigma)
  \mapsto (q_{t_\$}, \sigma, \Rightarrow)$ e também a transição definitiva de inserção do $\$$, $(q_{t_\$}, b) \mapsto (q_i, \$,
  \Leftarrow)$, sendo que $q_{t_\$} \ne q_i$ (por outras questões temos também que $q_g \ne q_i$)
- para o rebobinar, temos que conseguir recuar sempre, não só para os símbolos da entrada como também para os símbolos
  de trabalho do autômato de fila, portanto as transições $\forall \gamma \in \Gamma_{AF}, (q_i, t(\gamma)) \mapsto (q_i,
  t(\gamma), \Leftarrow)$ existem
- finalmente, temos que, após rebobinar, ir para o estado equivalente do autômato de fila, portanto as seguintes transições
  existem $\forall q \in Q_{AF}, (q_i, \tau(q)) \mapsto (\chi(q), b, \Rightarrow)$

Isso apenas para dar o _bootstraping_ do autômato de fila. Agora precisamos definir as transições.

Vamos dividir essas transições em dois tipos: o tipo $\delta_\epsilon$ são transições que não produzem nada para o final
da fila (portanto, se a i-ésima transição for $t_i: (q_x, \gamma) \mapsto (q_y, \epsilon)$, então $t_i \in \delta_\epsilon$);
e o tipo $\delta_\Omega$, que produz um ou mais elementos no final da fila (portanto, se a i-ésimo transição for $t_i:
(q_x, \gamma) \mapsto (q_y, \omega), \omega \in \Gamma^+$, então $t_i \in \delta_\Omega$).

As transições $\delta_\epsilon$, como não produzem nada de especial no final, podem ser representadas na máquina de Turing
como simplesmente transformando o elemento atual em branco, mudando para o estado $\chi(q_y)$ e avançando para a direita:

$$
\forall t_i = (q_x, \gamma) \mapsto (q_y, \sigma) \in \delta_\epsilon, (\chi(q_x), t(\gamma)) \mapsto (\chi(q_y), b, \Rightarrow)
$$

Para transições $\delta_\Omega$, vamos deixar a marca do novo estado do autômato de fila para quando for feita a rebobinação.
Nessa situação, precisamos ir até o final e inserir exatamente o elemento produzido. Peguemos a transição $t_j \in \delta_\Omega,
t_j = (q_x, \gamma) \mapsto (q_y, \gamma\omega), \gamma \in \Gamma_{AF}, \omega \in \Gamma_{AF}^*$. Para essa transição, precisamos
de um novo $q_{t_{\gamma\omega}} \in R$ que faça um papel semelhante ao $q_{t_\$}$ previamente definido: ir até o final da entrada
e, então, inserir o equivalente à palavra $\gamma\omega$ no final da fita, então mudar para o estado de rebobinar $q_i$.

Nomeemos então o conjunto de estados $Q_\Omega$, onde $q_{t_\omega} \ in Q_\Omega$ se $\omega \in \Gamma_{AF}^+$. Note que $\forall
q_{t_\omega} \in Q_\Omega, q_{t_\omega} \in R, q_{t_\omega} \ne q_i, q_{t_\omega} \ne q_g$. Uma das característica dos estados em
$Q_\Omega$ é que, para elementos de fila mapeados vindos de $f(\gamma), \gamma \in \Gamma_{AF}$, ele simplesmente irá ignorar esse
elemento e seguir para a direita, até encontrar o primeiro elemento em branco que, então, começará a fazer o _dump_ do $\omega$ na
fita:

$$
\forall q_{t_\omega} \in Q_\Omega, \forall \gamma \in \Gamma_{AF}, (q_{t_\omega}, t(\gamma)) \mapsto (q_{t_\omega}, t(\gamma), \Rightarrow)
$$

Note que a premissa original gera u subconjunto dessas transições, já que $\Sigma_{AF} \subseteq \Gamma_{AF} \setminus \{\$\}$.

Quando chega no elemento em branco, temos duas opções para $q_{t_\omega}$: $|\omega| = 1$ ou então $|\omega| > 1$. Para o primeiro
caso, tomemos $q_{t_\gamma}, \gamma \in \Gamma_{AF}$; vamos chamar esse conjunto de $Q_{\Omega^1}$. Ele vai simplesmente colocar na
fita o $t(\gamma)$ e seguir rebobinando, portanto:

$$
\forall q_{t_\gamma} \in Q_{\Omega^1}, \gamma \in \Gamma_{AF}, (q_{t_\gamma}, b) \mapsto (q_i, t(\gamma), \Leftarrow)
$$

Note que, quando $\gamma = \$$, o caso para $q_{t_\$}$ é apenas um caso especial disso.

Para os outros elementos, adotemos a nomenclatura $q_{t_{\gamma\omega}}, \gamma \in \Gamma_{AF}, \omega \in \Gamma_{AF}^+$;
vamos chamar esse conjunto de $Q_{\Omega^{2+}}$. Ele vai colocar na fita o elemento $t(\gamma)$ e irá para a direita para
terminar de colocar o resto do mapeamento de $\omega$. Podemos assumir então que ele irá para o estado $q_{t_\omega}$ tal
que $q_{t_\omega} \in Q_\Omega$:

$$
\forall q_{t_{\gamma\omega}} \in Q_{\Omega^{2+}}, \gamma \in \Gamma_{AF}, (q_{t_{\gamma\omega}}, b) \mapsto (q_{t_\omega}, t(\gamma), \Rightarrow),
q_{t_\omega} \in Q_\Omega
$$

Vale ressaltar que $Q_\Omega = Q_{\Omega^1} + Q_{\Omega^{2+}}, Q_{\Omega^1} \cap Q_{\Omega^{2+}} = \emptyset$.

Essa regra, definida exatamente desse jeito, garante que o elemento produzido pela transição do autômato seja fielmente colocada
apenas no final da fila.

Recapitulando:

- todo estado do autômato de fila implica em um símbolo de trabalho da Máquina de Turing e também um estado
  da Máquina de Turing
- vamos chamar o mapeamento de estado do autômato de fila para elemento de trabalho da função bijetiva $\tau: Q_{AF} \mapsto \Gamma_Q$,
  sendo $\Gamma_Q \subset \Gamma_{MT}$
- vamos chamar o mapeamento de estado do autômato de fila para estado da máquina de Turing da função bijetiva $\chi: Q_{AF} \mapsto Q_Q$,
  sendo $Q_Q \subset Q_{MT}$
- $Q_{MT} = R + Q_Q$
- $Q_Q \cap R = \emptyset$
- os alfabetos de entrada são equivalentes, $\Sigma_{AF} \equiv \Sigma_{MT}$
- o indicador de fim de linha $\$$ no autômato de fila tem seu equivalente na máquina de Turing, representado simplesmente
  por $\$$
- todo elemento de trabalho do autômato de fila tem um equivalente no elemento de fita, $\forall \gamma \in \Gamma_{AF}, t(\gamma) \in
  \Gamma_{\Gamma}$, sendo $\Gamma_{\Gamma} \subset \Gamma_{MT}$
- $\Gamma_{\Gamma} \cap \Gamma_Q = \emptyset$
- seja $b$ o caracter que representa o vazio da fita da máquina de Turing, $b \not\in \Gamma_{\Gamma} + \Gamma_Q$
- $Q_\Omega \subset R, Q_\Omega = Q_{\Omega^1} + Q_{\Omega^{2+}}, Q_{\Omega^1} \cap Q_{\Omega^{2+}} = \emptyset$
- $\forall \gamma \in \Gamma_{AF}, \exists q_\gamma \in Q_{\Omega^1}$
- $q_g, q_i \in R$
- $q_g, q_i \not \in Q_\Omega$
- estado inicial da máquina de Turing é $q_g \in R$, cujas únicas transições são $\forall \sigma \in \Sigma, (q_g, \sigma) \mapsto (q_g,
  \sigma, \Leftarrow)$ e também $(q_g, b) \mapsto (q_{t_\$}, \tau(q_0), \Rightarrow), q_{t_\$} \in Q_{\Omega^1}$
- as seguintes transições existem, $\forall q_{t_\omega} \in Q_\Omega, \forall \gamma \in \Gamma_{AF}, (q_{t_\omega}, t(\gamma)) \mapsto
  (q_{t_\omega}, t(\gamma), \Rightarrow)$
- seja uma transição do autômato de fila que produza a string não vazia $\omega \in \Gamma_{AF}^+$, então temos um estado
  $q_{t_\omega} \in Q_\Omega$; se $|\omega| \ge 2$, então $q_{t_\omega} \in Q_{\Omega^{2+}}$, caso contrário $|\omega| = 1$,
  então $q_{t_\omega} \in Q_{\Omega^1}$
- seja $q_{t_{\gamma\omega}} \in Q_{\Omega^{2+}}, \gamma \in \Gamma_{AF}, \omega \in \Gamma_{AF}^+$, então temos que
  $q_{t_\omega} \in Q_\Omega$; se $|\omega| \ge 2$, então $q_{t_\omega} \in Q_{\Omega^{2+}}$, caso contrário $|\omega| = 1$,
  então $q_{t_\omega} \in Q_{\Omega^1}$
- existem as transições $\forall q_{t_\omega} \in Q_\Omega, \forall \gamma \in \Gamma_{AF}, (q_{t_\omega}, t(\gamma)) \mapsto (q_{t_\omega}, t(\gamma), \Rightarrow)$
- existem as transições $\forall q_{t_\gamma} \in Q_{\Omega^1}, (q_{t_\gamma}, b) \mapsto (q_i, t(\gamma), \Leftarrow)$
- existem as transições $\forall q_{t_{\gamma\omega}} \in Q_{\Omega^{2+}}, (q_{t_{\gamma\omega}}, b) \mapsto (q_{t_\omega}, t(\gamma), \Rightarrow)$
- seja o estado de rebobinar $q_i \in R$, então ele tem apenas as seguintes transições:
  - $\forall \gamma \in \Gamma_{AF}, (q_i, t(\gamma)) \mapsto (q_i, t(\gamma), \Leftarrow)$
  - $\forall q \in Q_{AF}, (q_i, \tau(q)) \mapsto (\chi(q), b, \Rightarrow)$
- se a transição do autômato de fila for $t \in \delta_\epsilon, t: (q_x, \gamma) \mapsto (q_y, \epsilon), q_x,q_y \in Q_{AF}, \gamma \in \Gamma_{AF}$,
  então a seguinte transição existe $(\chi(q_x), t(\gamma)) \mapsto (\chi(q_y), b, \Rightarrow)$
- se a transição do autômato de fila for $t \in \delta_\Omega, t: (q_x, \gamma) \mapsto (q_y, \omega), q_x,q_y \in Q_{AF}, \gamma \in \Gamma_{AF},
  \omega \in \Gamma_{AF}^+$, então a seguinte transição existe $(\chi(q_x), t(\gamma)) \mapsto (q_{t_\omega}, \tau(q_y), \Rightarrow), q_{t_\omega}
  \in Q_\Omega$
- para simular a aceitação, que acontece se e somente se o autômato de fila consumir todos os elementos da entrada, temos que todo
  estado composto por equivalência do autômato de fila quando consumir o branco deve ir para o estado de aceitação $q_f \in F \subset R$, tal que
  $q_f \not\in Q_\Omega + \{q_g, q_i\}$
  - portanto, as seguintes transições existem $\forall q\in Q_{AF}, (\chi(q), b) \mapsto (q_f, b, \Rightarrow)$

Em cima dessas, regras, para o autômato de fila que reconhece $A^nB^nC^n$:

$$
Q_{AF} = \left\{ q_0, q_a, q_b, q_c \right\}\\
q_0\ \text{é o estado inicial}\\
\Sigma_{AF} = \left\{ A, B, C \right\}\\
\$\ \text{é o indicador de final de palavra}\\
\Gamma_{AF} = \left\{ A, B, C, \$ \right\}\\
\delta=\left\{
	\begin{array}{lcl}
		(q_0, \$)&\mapsto&(q_0, \epsilon)\\
		(q_0, A)&\mapsto&(q_a, \epsilon)\\
		(q_a, A)&\mapsto&(q_a, A)\\
		(q_a, B)&\mapsto&(q_b, \epsilon)\\
		(q_b, B)&\mapsto&(q_b, B)\\
		(q_b, C)&\mapsto&(q_c, \epsilon)\\
		(q_C, C)&\mapsto&(q_c, C)\\
		(q_C, \$)&\mapsto&(q_0, \$)
	\end{array}
\right\}
$$

Temos que as seguintes transições são do tipo $\delta_\Omega$:

$$
\begin{array}{lcl}
	(q_a, A)&\mapsto&(q_a, A)\\
	(q_b, B)&\mapsto&(q_b, B)\\
	(q_C, C)&\mapsto&(q_c, C)\\
	(q_C, \$)&\mapsto&(q_0, \$)
\end{array}
$$

e as seguintes são do tipo $\delta_\epsilon$:

$$
\begin{array}{lcl}
	(q_0, \$)&\mapsto&(q_0, \epsilon)\\
	(q_0, A)&\mapsto&(q_a, \epsilon)\\
	(q_a, B)&\mapsto&(q_b, \epsilon)\\
	(q_b, C)&\mapsto&(q_c, \epsilon)
\end{array}
$$

Todas as transições $\delta\epsilon$ geram exatamente um único caracter na saída, portanto temos
que $Q_{\Omega^{2+}} = \emptyset$, portanto:

$$
Q_\Omega = Q_{\Omega^1}\\
Q_{\Omega^1} = \{ q_{t_\$}, q_{t_A}, q_{t_B}, q_{t_C} \}
$$

Também temos que:

$$
\Gamma_\Gamma = \{\$, A, B, C\}\\
\Gamma_Q = \{\tau(q_0), \tau(q_a), \tau(q_b), \tau(q_c)\}\\
Q_Q = \{\chi(q_0), \chi(q_a), \chi(q_b), \chi(q_c)\}
$$

Portanto, temos o seguinte a cerca dos estados e símbolos da máquina de Turing:

$$
Q = \{
      q_g, q_f, q_i,
      q_{t_\$}, q_{t_A}, q_{t_B}, q_{t_C},
      \chi(q_0), \chi(q_a), \chi(q_b), \chi(q_c)
    \}\\
q_g\ \text{é o estado inicial}\\
F = \{q_f\}\\
\Sigma_{MT} = \{A, B, C\}\\
b\ \text{é o símbolo vazio da fita}\\
\Gamma_{MT} = \{
      \$, A, B, C,
      \tau(q_0), \tau(q_a), \tau(q_b), \tau(q_c),
      b
    \}
$$

Faltando definir, portanto, apenas as transições. Temos as seguintes fornecidas pelo estado de rebobinar, estado inicial e
avanços dos estados $q_\omega \in Q_\Omega$ antes de inserir na fita os estados:

$$
\begin{array}{lcl}
	(q_g, A)&\mapsto&(q_g, A, \Leftarrow)\\
	(q_g, B)&\mapsto&(q_g, B, \Leftarrow)\\
	(q_g, C)&\mapsto&(q_g, C, \Leftarrow)\\
	(q_g, b)&\mapsto&(q_{t_\$}, \tau(q_0), \Rightarrow)\\
	(q_i, \$)&\mapsto&(q_i, \$, \Leftarrow)\\
	(q_i, A)&\mapsto&(q_i, A, \Leftarrow)\\
	(q_i, B)&\mapsto&(q_i, B, \Leftarrow)\\
	(q_i, C)&\mapsto&(q_i, C, \Leftarrow)\\
	(q_{t_\$}, A)&\mapsto&(q_{t_\$}, A, \Rightarrow)\\
	(q_{t_A}, A)&\mapsto&(q_{t_A}, A, \Rightarrow)\\
	(q_{t_B}, A)&\mapsto&(q_{t_B}, A, \Rightarrow)\\
	(q_{t_C}, A)&\mapsto&(q_{t_C}, A, \Rightarrow)\\
	(q_{t_\$}, B)&\mapsto&(q_{t_\$}, B, \Rightarrow)\\
	(q_{t_A}, B)&\mapsto&(q_{t_A}, B, \Rightarrow)\\
	(q_{t_B}, B)&\mapsto&(q_{t_B}, B, \Rightarrow)\\
	(q_{t_C}, B)&\mapsto&(q_{t_C}, B, \Rightarrow)\\
	(q_{t_\$}, C)&\mapsto&(q_{t_\$}, C, \Rightarrow)\\
	(q_{t_A}, C)&\mapsto&(q_{t_A}, C, \Rightarrow)\\
	(q_{t_B}, C)&\mapsto&(q_{t_B}, C, \Rightarrow)\\
	(q_{t_C}, C)&\mapsto&(q_{t_C}, C, \Rightarrow)\\
	(q_{t_\$}, \$)&\mapsto&(q_{t_\$}, \$, \Rightarrow)\\
	(q_{t_A}, \$)&\mapsto&(q_{t_A}, \$, \Rightarrow)\\
	(q_{t_B}, \$)&\mapsto&(q_{t_B}, \$, \Rightarrow)\\
	(q_{t_C}, \$)&\mapsto&(q_{t_C}, \$, \Rightarrow)\\
\end{array}
$$

Das transições dos estados $q_\omega \in Q_\Omega$ colocando os símbolos no final da fila:

$$
\begin{array}{lcl}
	(q_{t_\$}, b)&\mapsto&(q_i, \$, \Leftarrow)\\
	(q_{t_A}, b)&\mapsto&(q_i, A, \Leftarrow)\\
	(q_{t_B}, b)&\mapsto&(q_i, B, \Leftarrow)\\
	(q_{t_C}, b)&\mapsto&(q_i, C, \Leftarrow)\\
\end{array}
$$

Das transições vindos do final do rebobinar, recuperando o estado em $\Gamma_Q$:

$$
\begin{array}{lcl}
	(q_i, \tau(q_0))&\mapsto&(\chi(q_0), b, \Rightarrow)\\
	(q_i, \tau(q_a))&\mapsto&(\chi(q_a), b, \Rightarrow)\\
	(q_i, \tau(q_b))&\mapsto&(\chi(q_b), b, \Rightarrow)\\
	(q_i, \tau(q_c))&\mapsto&(\chi(q_c), b, \Rightarrow)\\
\end{array}
$$

Das transições disponíveis no autômato de fila:

$$
\begin{array}{lcl}
	(\chi(q_0), \$)&\mapsto&(\chi(q_0), b, \Rightarrow)\\
	(\chi(q_0), A)&\mapsto&(\chi(q_a), b, \Rightarrow)\\
	(\chi(q_a), B)&\mapsto&(\chi(q_b), b, \Rightarrow)\\
	(\chi(q_b), C)&\mapsto&(\chi(q_c), b, \Rightarrow)\\
	(\chi(q_a), A)&\mapsto&(q_{t_A}, \tau(q_a), \Rightarrow)\\
	(\chi(q_b), B)&\mapsto&(q_{t_B}, \tau(q_b), \Rightarrow)\\
	(\chi(q_c), C)&\mapsto&(q_{t_C}, \tau(q_c), \Rightarrow)\\
	(\chi(q_c), C)&\mapsto&(q_{t_\$}, \tau(q_0), \Rightarrow)\\
\end{array}
$$

{% endkatexmm %}

{% katexmm %}
{% endkatexmm %}
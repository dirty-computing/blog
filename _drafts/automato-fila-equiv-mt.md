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

{% endkatexmm %}
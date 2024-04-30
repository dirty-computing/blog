---
layout: post
title: "Álgebra relacional 101"
author: "Jefferson Quesado"
tags: álgebra matemática álgebra-relacional conjuntos
base-assets: "/assets/algebra-relacional-101/"
pixmecoffe: jeffquesado
---

> Vindo de uma thread do [Twitter](https://twitter.com/JeffQuesado/status/1782748451941253349).

Eu disse que desenho _queries_ com álgebra e me perguntaram "como assim"?
Pois bem, aqui venho mostrar para vocês meu segredo: a álgebra relacional.

{% katexmm %}

# Tuplas

Tuplas são elementos criados em cima de outros elementos.
Dados dois elementos $a$ e $b$, posso criar com eles duas
tuplas distintas:

$$
(a, b)\\
(b, a)
$$

Tuplas são posicionais, mas também podem ser nomeadas.
Pegando o exemplo acima para tuplas da forma $(left:, right:)$:

$$
(left: a, right: b)\\
(left: b, rigleft: ht: a)
$$

Quando lidamos com tuplas posicionais é como se o índice fosse
o "nome" associado ao elemento:

$$
(0: a, 1: b)\\
(0: b, 1: a)
$$

Note que, como estamos colocando nomes nas posições, as seguintes tuplas
são iguais:

$$
(0: a, 1: b)\\
(1: b, 0: a)
$$

Em tese, simplesmente aplicar a "tuplificação" em cima de dois elementos
gera uma nova tupla de 2 posições. Por exemplo, usando os elementos
$(1, 2)$ e $(a, b)$:

$$
\left((1, 2),(a, b)\right)
$$

Porém, por uma questão de vício e para poupar alguns passos, exceto
se comentado o oposto, neste artigo vou deixar os elementos das tuplas
expostos na tupla resultado:

$$
(1, 2, a, b)
$$

Para tuplas nomeadas com produtos cartesianos:

$$
(left: 1, right: 2) \times (esq: a, dir: b) = (left: 1, right: 2, esq: a, dir: b)
$$

# Conjuntos e bags

Conjuntos são caracterizados por uma operação central: $\in$. Essa
operação tem no lado direito um conjunto e no lado esquerdo um elemento.
Em cima apenas disso e sem grandes detalhes você consegue derivar a teoria
ingênua dos conjuntos (com todos os seus paradoxos que não vem ao caso
discorrer aqui agora). Esse operador resulta em um resultado booleano:
ou o elemento pertence ao conjunto ou não.

A partir disso e de operadores de predicado booleanos, podemos derivar outros
operadores. Aqui operadores entre conjuntos:

União:

$$
A \cup B = C \\
\therefore \\
c \in C \implies c \in A \lor c \in B
$$

Interseção:

$$
A \cap B = C \\
\therefore \\
c \in C \implies c \in A \land c \in B
$$

Remoção:

$$
A \setminus B = C \\
\therefore \\
c \in C \implies c \in A \land c \not\in B
$$

Está contido:

$$
A \subseteq B\\
\therefore\\
\forall a \in A, a \in B
$$

Está contido (própriamente):

$$
A \subsetneq B\\
\therefore\\
\forall a \in A, a \in B \land \exists b \in B, b \not\in A
$$

Produto cartesiano:

$$
A \times B = C\\
\therefore\\
\forall a \in A, \forall b \in B \iff \left(a, b\right) \in C
$$

Conseguimos em cima disso fazer operações de conjuntos com elementos,
a partir da definição a seguir para um conjunto $A$ e um elemento $e$,
como "somar":

$$
A + e = A \cup \left\{e\right\}
$$

e "subtrair":

$$
A - e = A \setminus \left\{e\right\}
$$

Note que, nessa operação de "somar" pode gerar o mesmo conjunto $A$ se
tivermos $e \in A$. De modo semelhante, a "subtração" pode resultar
no mesmo conjunto se $e \not\in A$.

Bags são parecidas com conjuntos, ela oferece a operação de "pertence"
tal qual conjuntos, mas não apenas isso. Bags permitem repetição de elementos.
Portanto, ao "somar" um elemento a uma bag obteremos sempre uma nova bag.
A remoção/"subtração" de elementos, entretanto, pode resultar no mesmo
conjunto.

Para representar a multiplicidade temos a função $m_B(e)$. Essa função
mostra quantas vezes o elemento $e$ aparece na bag $B$. Agora, a operação
"pertence" pode ser escrita em cima da operação de multiplicidade:

$$
e \in B \\
\therefore \\
m_B(e) \gt 0
$$

E o "não pertence":

$$
e \not\in B \\
\therefore \\
m_B(e) = 0
$$

Operador de "soma" de um elemento a bag:

$$
B = A + e\\
\therefore\\
\forall a \in A, a \neq e, m_B(a) = m_A(a)\\
m_B(e) = m_A(e) + 1
$$

Operador de "subtração" de um elemento a bag:

$$
B = A - e\\
\therefore\\
\forall a \in A, a \neq e, m_B(a) = m_A(a)\\
e \in A \implies m_B(e) = m_A(e) - 1\\
e \not\in A \implies m_B(e) = 0
$$

A união de duas bags é a soma das multiplicidades dos elementos:

$$
A \cup B = C\\
\therefore\\
c \in C \iff m_C(c) = m_A(c) + m_B(c)
$$

E interseção é o mínimo das multiplicidades:

$$
A \cap B = C\\
\therefore\\
c \in C \iff m_C(c) = min(m_A(c), m_B(c))
$$

Produto cartesiano é semelhante ao de conjuntos, porém permite repetição:

$$
A \times B = C\\
\therefore\\
(a, b) \in C \iff a \in A, b \in B, m_C((a, b))  = m_A(a) \cdot m_B(b)
$$

# Álgebra relacional

Vamos pegar um caso base para motivar o estudo:

Dada uma bag de usuários composta da tupla nomeada de forma
`(id, nome, role, data de criação)` e a bag de acessos cujas tuplas são
da forma `(id acesso, id user, instante)`, precisamos pegar os usuários
que acessaram o sistema entre os instantes e j, com role >= $\rho$ e
dt criação > $\delta$. Desses elementos, só interessa exibir o nome do usuário.

As operações de álgebra relacional são feitas em cima de bags. Exceto se provado
o contrário, podemos sempre assumir que estamos lidando com bags. Por exemplo,
mesmo que `usuários` fosse um conjunto, eu poderia usar um operador de álgebra
relacional e, de lá, obter uma bag.

Vamos assumir que `id` é garantido ser único para toda e qualquer tupla
em `usuários`. Portanto, temos que `usuários` é, na prática, um conjunto.
Porém, nada garante que o `role` seja distinto. Portanto, a seguinte
coleção é válida para `usuários`:

$$
usuários =
\left\{
\begin{array}{l}
(id: 1, nome: Jeff, role: 10, dt\_criação: 2024-04-29),\\(id: 2, nome: Doskya, role: 10, dt\_criação: 2024-04-30)\end{array}
\right\}
$$

E em cima disso posso simplesmente _projetar_ o role de cada linha:

$$
\operatorname*{\huge \Pi}_{role}\left.usuários\right.
=
\left\{
\begin{array}{l}
(role: 10),\\(role: 10)\end{array}
\right\}
$$

Tá, e para o problema, como podemos resolver usando álgebra relacional?

$$
I ::= \operatorname*{\huge \sigma}_{
    \substack{dt criação > \delta \\
        i \leq instante \leq j \\
        role \geq \rho}}
    usuário \operatorname*\bowtie_{u.id = a.id user} acesso\\
\operatorname*{\huge \Pi}_{nome} I
$$

Tá, vamos aos poucos destrinchar a solução. Mas, antes, falar de algo que _não_
aparece na solução, para depois mostrar o que de fato aparece.

Uma das coisas que podemos fazer com duas bags distintas é o produto cartesiano
entre elas. Por exemplo, entre usuários e acessos:

$$
usuário \times acesso
$$

Porém, isso não nos dá muita coisa. Precisamos _selecionar_ apenas as
tuplas em que o id do usuário seja igual ao id user de acesso:

$$
\operatorname*{\huge \sigma}_{u.id = a.id user} usuario\times acesso
$$

Tá vendo aqui o produto cartesiano e a _seleção_ com base na igualdade
de valores das tuplas? A isso damos o nome de _junção natural_. A junção
natural é indicada pelo operador $\bowtie$ e, em seu subscrito, a condição
de junção, um predicando envolvendo as tuplas. Daí, temos que a junção natural
é como se fosse um produto cartesiano seguido de uma seleção:

$$
\operatorname*{\huge \sigma}_{u.id = a.id user} usuario\times acesso = usuario\operatorname*\bowtie_{u.id = a.id user} acesso
$$

Bem, acabou que pra falar da junção natural acabei falando bastante também
da _seleção_. A seleção pode ser feita em cima de uma simples tupla,
não precisa ser a relação de junção entre dois conjuntos tal qual foi
com a junção natural.

Por exemplo, podemos pegar os números naturais pares:

$$
\operatorname*{\huge\sigma}_{v \% 2 == 0}\mathbb{N}
$$

A seleção é indicada pelo $\sigma$. Ele recebe como arugmneto uma bag e deixa
passar apenas as tuplas que satisfaçam o predicado no subscrito. Posso ter
vários subscritos, é a mesma coisa de ter várias seleções distintas:
precisa satisfazer todos os predicados para a tupla ser selecionada.

Agora, a projeção. Pois bem, com a projeção criamos mecanismos de manipular
a tupla em si, não apenas anexar coisas no final dela. Usamos o operador
$\Pi$ e em seu subscrito o que queremos projetar. Por exemplo, os nomes
da bag $I$:

$$
\operatorname*{\huge\Pi}_{nome} I
$$

Aqui eu usei $::=$ para indicar a definição de uma nova bag:

$$
I ::= \operatorname*{\huge \sigma}_{
    \substack{dt criação > \delta \\
        i \leq instante \leq j \\
        role \geq \rho}}
    usuário \operatorname*\bowtie_{u.id = a.id user} acesso
$$

Não sei se a notação clássica de álgebra relacional lida com isso
ou se só usa o sinal de $=$ mesmo (eu acho que é esse segundo caso).
Mas quis deixar bem enfatizado que estou definindo uma bag nova.

Isso foi o básico sobre álgebra relacional. Ela suporta as operações
de conjunto também, como união, interseção etc, como demonstrado na
seção anterior.

## Extensões

Existem algumas extensões comuns a álgebra relacional. A presença do nulo
(indicado por $\omega$), junções laterais, agregações (não vi consenso sobre isso,
usava $\gamma$) e outras coisas legais.

{% endkatexmm %}
---
layout: post
title: "Criando mapas \"apenas\" com funções em java"
author: "Jefferson Quesado"
tags: java estrutura-de-dados
base-assets: "/assets/java-map-stateless/"
---

Bem, já pensou se fosse legal fazer um mapeamento em Java usando
apenas funções? É útil? Bem, sinceramente? Não vejo muita utilidade,
o `HashMap` continua sendo uma linda implementação para mapeamentos.

Mas vale o exercício, não vale?

# Definindo o problema

{% katexmm %}

Pegue uma função, $f: \mathbb D\mapsto \mathbb C$, onde
$\mathbb D \subseteq \mathbb U$. Isso significa que $f$ é
uma função (potencialmente) parcial de $\mathbb U$.

Então, como fazer para que $f$ se comporte de modo "completo"
em $\mathbb U$? Uma maneira é pegar o elemento nulo $\Phi \not\in \mathbb C$.
Então, podemos definir $f': \mathbb U \mapsto \mathbb C \cup \left\{ \Phi \right\}$

Como definimos ela? Bem...

$$
f'(u) =
    \begin{cases}
        f(u) & u \in \mathbb D\\
        \Phi & u \not\in \mathbb D
    \end{cases}
$$

Com isso, temos uma função de mapeamento parcial de $\mathbb U\mapsto \mathbb C$
e transformamos, sem perder semântica e também de modo unívoco, em uma função
total de $\mathbb U \mapsto \mathbb C \cup \left\{ \Phi\right\}$.

Agora, o que eu preciso é criar novos mapeamentos baseados em funções parciais
do tipo $g: \mathbb U \mapsto \mathbb C$. Eu vou definir primeiro uma função
que _remove_ um mapeamento prévio para um elemento $u \in \mathbb U$.

Bem, se eu quero remover o mapeamento, eu posso também fazer um _overwrite_
do mapeamento e detectar que, ao chamar $u$, deveria retornar $\Phi$. Então,
assim conseguimos definir a função $g: \mathbb U \mapsto \mathbb C$.

$$
g'(d) =
    \begin{cases}
        \Phi & d = u\\
        f'(d) & d \in \mathbb D
    \end{cases}
$$

Ok, eu tenho agora a função $remove\_map(f: \mathbb U \mapsto \mathbb C, u: \mathbb U)$. Agora, eu posso criar uma função que adiciona no mapeamento, algo como
$add\_map(f: \mathbb U \mapsto \mathbb C, u: \mathbb U, c: \mathbb C)$:

$$
g'(d) =
    \begin{cases}
        c & d = u\\
        f'(d) & d \in \mathbb D
    \end{cases}
$$

A partir de qualquer função parcial de $\mathbb U \mapsto \mathbb C$ eu posso derivar
novos mapeamentos. E... qual seria o mapeamento mais simples? O caso base
do qual podemos derivar todos os casos possíveis: o caso em que $\mathbb D = \emptyset$. Esse é o caso da funcão $e$. A função total $e'$ é derivada assim:

$$
e'(u) = \Phi
$$

## Escrevendo as funções em si

Começando pela função que cria o mapeamento vazio:

$$
empty\_mapping :
    \emptyset \mapsto
    fun(u: \mathbb U): \mathbb C  \cup \left\{ \Phi \right\}\\
\\
empty\_mapping() = (u) \Rightarrow \Phi
$$

Agora, a função que remove mapeamentos:

$$
remove\_mapping :
    e': (u: \mathbb U): \mathbb C  \cup \left\{ \Phi \right\},
    removed\_key: \mathbb U \mapsto
    fun(u: \mathbb U): \mathbb C  \cup \left\{ \Phi \right\}\\
\\
remove\_mapping(e', removed\_key) = (u) \Rightarrow
    \begin{cases}
        \Phi & u = removed\_key\\
        e'(u) & u \not = removed\_key
    \end{cases}
$$

Finalmente, a função que adiciona mapeamentos:

$$
add\_mapping :
    e': (u: \mathbb U): \mathbb C  \cup \left\{ \Phi \right\},
    new\_key: \mathbb U,
    new\_value:\mathbb C \mapsto
    fun(u: \mathbb U): \mathbb C  \cup \left\{ \Phi \right\}\\
\\
add\_mapping(e', new\_key, new\_value) = (u) \Rightarrow
    \begin{cases}
        new\_value & u = new\_key\\
        e'(u) & u \not = new\_key
    \end{cases}
$$

## Variante: objeto matemático com mapeamento e conjunto domínio

Bem, e se o objeto matemático, além da função, tivesse um campo
chamado `dom` com os elementos de $\mathbb D$? Assim, poderíamos
saber não apenas que $\mathbb D \subseteq \mathbb U$, mas
literamente conhecer $\mathbb D$. Será que seria possível manter essa
propriedade junto das alterações no mapeamento?

Bem, começar pela remoção. Eu tenho um conjunto que potencialmente tem
o elemento $u$ e, após a remoção do mapeamento, não terá mais esse
elemento no domínio:

$$
remove\_mapping_{dom}(e'.dom: \mathbb D \subseteq \mathbb U, u: \mathbb U)
    \mapsto X \mathbb \subseteq \mathbb U:
e'.dom \setminus \left\{ u \right\}
$$

E adicionar um mapeamento? Bem, nesse caso específico não precisamos
saber o valor para o qual será mapeado, apenas a chave. E o bom é que,
como a chave pode sobrescrever algo mapeado anteriormente, não existe
problema nisso.

$$
add\_mapping_{dom}(e'.dom: \mathbb D \subseteq \mathbb U, u: \mathbb U)
    \mapsto X \mathbb \subseteq \mathbb U:
e'.dom \cup \left\{ u \right\}
$$

# Fazendo em Java

Bem, já que queremos usar funções para tudo, que tal começarmos
escrevendo uma interface? Parece o tipo adequado, não é?

```java
interface Mapeamento<D,C> {
    C mapear(D chave);
    Set<D> dominio();
}
```

Antes de começar, já que estamos lidando com funções, que tal ter
uma espécie de "construtor" utilitário para nos auxiliar? Um que
receba duas funções, uma de $D\mapsto C$ e outro que nos forneça
$\mathbb D$?

```java
static <D, C> Mapeamento<D,C> criarMapeamento(Function<D, C> f, Supplier<Set<D>> dominio) {
    return new Mapeamento<>() {

            @Override
            public C mapear(D chave) {
                return f.apply(chave);
            }

            @Override
            public Set<D> dominio() {
                return dominio.get();
            }
    };
}
```

Bem, aqui podemos assumir a ausência de valor como `null`, no mundo
do Java. Vamos criar a função que faz o `emptyMapping`?

```java
static <D, C> Mapeamento<D,C> mapeamentoVazio() {
    return criarMapeamento(unused -> null, Set::of);
}
```

Para remover um mapeamento? Bem, vamos lá. Não vou tentar fazer a melhor solução, nem tampouco que seja eficiente, apenas que reflita a necessidade matemática
por trás, que foi mapeada anteriormente:

```java
static <D, C> Mapeamento<D,C> removerMapeamento(Mapeamento<D, C> e, D chaveRemocao) {
    return criarMapeamento(
        d -> chaveRemocao.equals(d)? null: e.mapear(d),
        () -> {
            HashSet<D> novoDominio = new HashSet<>(e.dominio());
            novoDominio.remove(chaveRemocao);
            return Collections.unmodifiableSet(novoDominio);
        }
    );
}
```

E para adicionar um novo mapeamento?

```java
static <D, C> Mapeamento<D,C> removerMapeamento(Mapeamento<D, C> e, D chaveAdicionada, C novoValor) {
    return criarMapeamento(
        d -> chaveAdicionada.equals(d)? novoValor: e.mapear(d),
        () -> {
            HashSet<D> novoDominio = new HashSet<>(e.dominio());
            novoDominio.add(chaveAdicionada);
            return Collections.unmodifiableSet(novoDominio);
        }
    );
}
```

## Alternativas para evitar mexer no estado de `novoDominio`
Na remoção, poder-se-ia usar `stream`:

```java
e.dominio().stream()
    .filter(d -> !chaveRemocao.equals(d))
    .collect(Collectors.toSet());
```

Para adição, poderíamos juntar duas streams:

```java
Stream.concat(e.dominio().stream(), Arrays.stream(chaveAdicionada))
    .collect(Collectors.toSet());
```

## Por que não passar `Set<D>` como valor?

Bem, estamos em Java. Alguém pode querer criar algo _stateful_
que implemente `Mapeamento`. Se eu recebesse um conjunto "duro",
possivelmente não seria da referência mutável. Então, para evitar
isso, para evitar ter a referência guardada, é melhor sempre
obter a nova referência.

{% endkatexmm %}
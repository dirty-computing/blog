---
layout: post
title: "Reinventando a roda: como escrever streams sem usar stream como base"
author: "Jefferson Quesado"
tags: java programação-funcional stream
base-assets: "/assets/reinventando-roda-java-streams/"
---

Era uma vez um mundo de Java 7. Não existiam streams no Java,
não existiam lambdas no Java (classes anônimas seriam uma
aproximação, mas não conta porque elas são bem anti-práticas).

E desse mundo eu conheci as maravilhas da programação funcional
em Java, e um problema comum de mutabilidade de estados
poderia ser resolvido usando streams.

O primeiro problema era como representar uma função de modo
prático, e graças ao [Retrolambda](https://github.com/luontola/retrolambda)
foi possível adicionar lambdas no projeto. Próximo passo?
Fazer as streams.

Dada as limitações que eu tinha da época, eu precisava ter uma API
próxima o suficiente de streams, não precisa literalmente algo 100%
sem atrito de fazer um `someList.stream()`. Uma alterativa seria
usar um `new Stream<>(someList)` ou então `Stream.streamify(someList)`.

Com isso, eu poderia ter o poder das streams na minha mão. E, acredite,
para a época ter toda uma biblioteca para emular algo semelhante
a streams valeu o esforço.

> Quem estiver curioso, muito do artefato produzido ficou na
> biblioteca open-source chamada de
> [functional-toolbox](https://gitlab.com/geosales-open-source/totalcross-functional-toolbox).

# Setando limitações iniciais

Bem, a primeira limitação é que precisa ser algo feito em cima de um iterável.
A stream produzida precisa receber um iterável e retornar algo com uma API
stream-like.

Em java, a interface
[`Iterable<T>`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/lang/Iterable.html)
tem um único método aberto chamado de `iterator()`
que produz um `Iterator<T>`.

Apesar de na especificação Java
[`Stream<T>`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/stream/Stream.html)
ser uma interface, não há essa necessidade no caso
do clone de streams que faremos aqui.

Não iremos reaproveitar objetos. Uma vez que se faz, por exemplo,
`transformIntoStream(someList).map(someFunction)`, iremos primeiro
criar um objeto com a API stream-like na chamada `transformIntoStream`
e, em seguida, criar um novo objeto ao chamar `map`.

Spliterators não são permitidos nessa primeira reinvenção de roda,
visto que não seria possível acessá-los na época de um runtime
compatível com Java 7 sem precisar reinventá-los. Como não era
necessário um spliterator para o que se estava trabalhando,
mas sim a API de algo semelhante a stream (e, também, da coleção
de `Collectors` disponível por padrão), spliterator não vai ser
levado em consideração.

Intefaces funcionais não precisam ser estritamente compatíveis
por nome 1:1 com o que se tem no Java, mas precisa ter o mesmo método
aberto. Por exemplo, um `map` na stream do Java recebe uma
[`java.util.function.Function<T, R>`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/function/Function.html)
que tem um método aberto `R apply(T)`. Isso significa que eu posso ter uma
interface do tipo `myjava.Function<T, R>` com um único método, aberto
ainda por cima, `R apply(T)`. Por simplicidade (e porque de fato o runtime
permitia) não iremos recriar as interfaces, iremos usá-las, mas estando
limitado apenas ao método aberto. Se for desejável usar algo como
[`<V> Function<V,R> compose(Function<V,T>)`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/function/Function.html#compose(java.util.function.Function))
então não poderia simplesmente fazer `func.compose(otherFunc)`, mas sim
`FunctionUtils.compose(func, otherFunc)`.

# Estratégia de desenvolvimento

Dadas essas limitações, o primeiro alvo deve ser alcançar o `forEach`.
O primeiro desenvolvimento deve ser alcançar essa operação terminal.
Hello world? Vamos imprimir uma lista de strings.

Depois dessa operação terminal, podemos passar para uma operação
intermediária. Nada como `map` aqui para transformar o tipo.
Podemos pegar a lista de palavras e transformar em uma lista
de comprimentos de palavras. Aqui uma operação de transformação
de tipos do jeito errado geraria um `ClassCastException`, o que
é uma ótima maneira de detectar a falha ao rodar.

A operação de `map` mantém a mesma quantidade de elementos.
Outro passo intermediário porém mais problemático (e, portanto,
melhor para se aprender) é o `filter`, justamente porque ele
altera a quantidade de elementos.

Em seguida, coletar (primeiro com `reduce`, em seguida com
`collect` mesmo). Os coletores mais simples são `toList`
e `toSet`, que podem ser tratados como simplesmente casos
especiais de `toCollection`.

# Primeiras implementações

A base é um `Iterable<T>`, que na prática é um jeito de gerar
[`Iterator<T>`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/Iterator.html).
O `Iterator<T>` por sua vez é uma estrutura mutável que tem
apenas dois métodos:

- `hasNext` permite saber se é possível chamar `next` e o
  resultado ser confiável
- `next` retorna o elemento atual do iterador e avança o
  ponteiro

Vamos usar uma classe para se comportar como stream. Como
ela vai receber um `Iterable<T>`, temos isso:

```java
public class Stream<T> {
    private final Iterable<T> it;

    public Stream(Iterable<T> it) {
        this.it = it;
    }
}
```

Pronto, agora vamos separar regiões para operações intermediárias
e operações terminadoras:

```java
public class Stream<T> {
    private final Iterable<T> it;

    public Stream(Iterable<T> it) {
        this.it = it;
    }

    // intermediate operations

    // terminal operations
}
```

Pronto, agora vamos começar a povoar com implementações.

## forEach

O `forEach` é uma operação tranquila: só preciso consumir o
que é gerado pelo iterável:

```java
public void forEach(Consumer<T> action) {
    for (T t: it) {
        action.accept(t);
    }
}
```

Se não quisermos usar a estrutura do `for-each` do Java, podemos
transformar o `Iterable<T>` em um `Iterator<T>` e consumir num laço
`for`:

```java
public void forEach__classicFor(Consumer<T> action) {
    for (Iterator<T> iterator = it.iterator(); iterator.hasNext();) {
        final T t = iterator.next();
        action.accept(t);
    }
}
```

Alternativa com `while`
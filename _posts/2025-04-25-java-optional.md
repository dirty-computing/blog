---
layout: post
title: "Entendendo map() e flatMap() no Optional do Java: Diferenças e Casos de Uso"
author: "Giovanni Rozza"
tags: java optional fp
base-assets: "/assets/java-optional/"
pixmecoffe: rgiovann
---

O `Optional`, introduzido no Java 8, é uma ferramenta poderosa para lidar com
valores que podem ou não estar presentes, ajudando a evitar o temido
`NullPointerException`. Dois de seus métodos mais usados, `map()` e
`flatMap()`, permitem transformar valores de forma segura e elegante, mas eles
têm diferenças cruciais que podem confundir até desenvolvedores experientes.
Neste artigo, vamos explorar essas diferenças, com exemplos práticos, e
esclarecer quando usar cada um. Ambos retornam Optional, mas com um twist!
Tanto `map()` quanto `flatMap()` operam dentro de um Optional e retornam um
novo `Optional`, mantendo a imutabilidade - ou seja, o `Optional` original não
é alterado. A diferença está no tipo de função que cada método espera e como
eles lidam com o resultado dessa função.

Diferença central: **O tipo da função que você passa**

<table class='marked-table'>
 <tr>
  <th>Método</th><th>Espera uma função que retorna...</th><th>Exemplo de função</th><th>Retorna</th>
 </tr>
<tbody>
 <tr>
  <td markdown="1">`map()`
  </td>
  <td>Um valor simples (T -&gt; U)</td>
  <td>String::length → String -&gt; Integer</td>
  <td>Optional&lt;U&gt;</td>
 </tr>
 <tr>
  <td markdown="1">`flatMap()`
  </td>
  <td>Um novo Optional (T -&gt; Optional) </td>
  <td>x -&gt; Optional.of(x.length()) </td>
  <td>Optional&lt;U&gt;</td>
 </tr>
</tbody>
</table>

- `map()`: Usa uma função que transforma o valor contido no `Optional` em um
  valor comum (não-`Optional`). O `map()` embrulha o resultado automaticamente
  em um novo `Optional`.
- `flatMap()`: Usa uma função que já retorna um `Optional`. O `flatMap()`
  "achata" (flattens) o resultado, evitando camadas extras de `Optional`.

# Exemplo com map(): Transformando valores simples

Considere o seguinte código:

```java
Optional<String> nome = Optional.of("Ana");
// String::length é String -> Integer
Optional<Integer> tamanho = nome.map(String::length);
```

O que acontece?
- O `Optional` contém a string "Ana".
- A função `String::length` transforma "Ana" em 3 (um `Integer`).
- O `map()` embrulha o resultado 3 em um `Optional`, retornando `Optional.of(3)`.

## Resultado

```java
Optional<Integer> tamanho = Optional.of(3);
```

E se o Optional estiver vazio?

```java
Optional<String> vazio = Optional.empty();
Optional<Integer> resultado = vazio.map(String::length);
```

Nesse caso, `map()` retorna `Optional.empty()` sem executar a função,
garantindo segurança contra valores ausentes.

# Exemplo com flatMap(): Lidando com funções que retornam Optional

Agora, veja um exemplo com `flatMap()`:

```java
Optional<String> nome = Optional.of("Ana");
// A função já retorna um Optional
Optional<Integer> tamanho = nome.flatMap(n -> Optional.of(n.length()));
```

O que acontece?

- O `Optional` contém "Ana".
- A função `n -> Optional.of(n.length())` transforma "Ana" em `Optional.of(3)`
  (um `Optional<Integer>`).
- O `flatMap()` usa o `Optional` retornado diretamente, sem adicionar outra
  camada, resultando em `Optional.of(3)`

## Resultado

```java
Optional<Integer> tamanho = Optional.of(3);
```

E se o `Optional` estiver vazio?

```java
Optional<String> vazio = Optional.empty();
Optional<Integer> resultado = vazio.flatMap(n -> Optional.of(n.length()));
```

Assim como no `map()`, o `flatMap()` retorna `Optional.empty()` sem executar a
função.

# O erro clássico: Usar map() com uma função que retorna Optional

Um erro comum é usar `map()` com uma função que já retorna um `Optional`. Veja
o que acontece:

```java
Optional<String> nome = Optional.of("Ana");
Optional<Optional<Integer>> errado = nome.map(n -> Optional.of(n.length()));
```

O que acontece?

- A função `n -> Optional.of(n.length())` retorna `Optional.of(3)` para "Ana".
- O `map() ` embrulha esse resultado em outro `Optional`, produzindo
  `Optional.of(Optional.of(3))`.

## Resultado:

```java
Optional<Optional<Integer>> errado = Optional.of(Optional.of(3));
```

Isso cria um Optional aninhado - uma “caixa dentro de outra caixa” - que é
difícil de trabalhar e geralmente não é o desejado. Para corrigir, use
`flatMap()`:

```java
Optional<Integer> correto = nome.flatMap(n -> Optional.of(n.length()));
// Resultado: Optional.of(3)
```

O `flatMap()` achata o resultado, eliminando a camada extra de `Optional`

# Exemplo prático: Encadeamento de operações

Na prática, `map()` e `flatMap()` são frequentemente usados em cadeias de
operações, especialmente em sistemas que lidam com dados que podem estar
ausentes. Considere um cenário onde você busca um nome por ID e quer manipular
o resultado:

```java
Optional<String> encontrarNomePorId(int id) {
  return id == 1 ? Optional.of("Ana") : Optional.empty();
}

Optional<Integer> tamanhoDoNome = Optional.of(1)
  .flatMap(id -> encontrarNomePorId(id)) // Optional<String>
  .map(String::length); // Optional<Integer>
```

O que acontece?
- `Optional.of(1)` contém o ID 1.
- `flatMap(id -> encontrarNomePorId(id))` chama `encontrarNomePorId(1)`, que
  retorna `Optional.of("Ana")`.
- `map(String::length)` transforma "Ana" em 3, retornando `Optional.of(3)`.

## Resultado:

```java
Optional<Integer> tamanhoDoNome = Optional.of(3);
```

Se o ID não existisse:

```java
Optional<Integer> tamanhoDoNome = Optional.of(2)
  .flatMap(id -> encontrarNomePorId(id)) // Optional.empty()
  .map(String::length); // Optional.empty()
```

O encadeamento com `flatMap()` e `map()` é seguro e expressivo, lidando com
valores ausentes sem verificações manuais.

# Conexão com programação funcional: O que é uma mônada?

Os métodos `map()` e `flatMap()` são inspirados em conceitos de programação
funcional, particularmente em estruturas conhecidas como mônadas. Mas o que é
uma mônada?

Uma mônada é um padrão de design que encapsula valores em um contexto,
permitindo operações encadeadas de forma segura e previsível.

No caso do `Optional`, o contexto é a possibilidade de um valor estar presente
ou ausente. Uma mônada geralmente suporta três características principais:

1. Embrulhar um valor: O `Optional` embrulha um valor (ou ausência) usando
   `Optional.of(value)` ou `Optional.empty()`.
2. Transformar valores (`map`): O método `map()` aplica uma função ao valor
   contido, mantendo-o no contexto do `Optional`. Por exemplo, transformar uma
   `String` em seu comprimento mantém o resultado em um `Optional<Integer>`.
3. Encadear operações (`flatMap`): O método `flatMap()` permite transformações
   que já retornam um valor no mesmo contexto (outro `Optional`), "achatando" o
   resultado para evitar estruturas aninhadas, como `Optional<Optional<T>>`.

Em termos simples, o `Optional` é uma mônada porque:
- Encapsula a incerteza (valor presente ou ausente).
- Permite transformações seguras com `map()` e `flatMap()`.
- Suporta encadeamento de operações sem verificações explícitas de nulidade.

Essa abordagem funcional torna o código mais robusto, legível e alinhado com
paradigmas modernos, como os encontrados em linguagens como Haskell ou Scala.
No Java, o Optional traz esses benefícios de forma prática, especialmente com o
suporte a pattern matching no Java 21, que permite inspecionar o conteúdo do
`Optional` de maneira elegante.


# Resumo prático

- Use `map()`:
  - Quando a função transforma o valor em algo simples (não-`Optional`).
  - Exemplo: `nome.map(String::length)` -> `Optional<Integer>`.
  - Retorna `Optional.empty()` se o `Optional` inicial está vazio.
- Use `flatMap()`:
  - Quando a função já retorna um `Optional`.
  - Exemplo: `nome.flatMap(n -> Optional.of(n.length()))` -> `Optional<Integer>`.
  - Achata o resultado, evitando `Optional<Optional<T>>`.
  - Retorna `Optional.empty()` se o Optional inicial está vazio.
- Evite:
  - Usar `map()` com funções que retornam `Optional`, para não criar `Optional` aninhados.

# Dica para desenvolvedores

Ao trabalhar com `Optional` em IDEs modernas (como IntelliJ IDEA ou NetBeans),
aproveite as sugestões de refatoração. Por exemplo, se você acidentalmente usar
`map()` e criar um `Optional<Optional<T>>`, a IDE pode sugerir trocar para
`flatMap()`. Além disso, ao encadear operações, teste os casos de
`Optional.empty()` para garantir que seu código é robusto.

Com `map()` e `flatMap()`, você pode escrever código mais limpo, funcional e
seguro, aproveitando o poder do Optional para lidar com a incerteza de valores
ausentes.
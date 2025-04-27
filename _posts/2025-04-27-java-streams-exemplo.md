---
layout: post
title: "Padrões e anti-padrões ao usar streams do Java: um simples exemplo"
author: "Jefferson Quesado"
tags: java fp
base-assets: "/assets/java-streams-exemplo/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Em um post no LinkedIn sobre usar programação funcional no Java, o
[Luís Reis mencionou sobre alguns anti-patterns ao usar streams](https://www.linkedin.com/feed/update/urn:li:activity:7320827342140940288?commentUrn=urn%3Ali%3Acomment%3A%28activity%3A7320827342140940288%2C7322024843296579584%29&replyUrn=urn%3Ali%3Acomment%3A%28activity%3A7320827342140940288%2C7322025589786263552%29&dashCommentUrn=urn%3Ali%3Afsd_comment%3A%287322024843296579584%2Curn%3Ali%3Aactivity%3A7320827342140940288%29&dashReplyUrn=urn%3Ali%3Afsd_comment%3A%287322025589786263552%2Curn%3Ali%3Aactivity%3A7320827342140940288%29), particularmente o
"streamception":

```java
List<String> resultado = usuarios.stream()
    .filter(u -> u.getEnderecos().stream()
        .anyMatch(e -> e.getCidade().equalsIgnoreCase("São Paulo")))
    .flatMap(u -> u.getPedidos().stream()
        .filter(p -> p.getValorTotal() > 500))
    .map(p -> p.getItens().stream()
        .filter(i -> i.getProduto().isDisponivel())
        .map(i -> i.getProduto().getNome()))
    .flatMap(nomes -> nomes)
    .distinct()
    .sorted()
    .collect(Collectors.toList());
```

# Analisando o problema através da engenharia reversa

Ok, que informações nós temos?

Temos uma coleção de usuário. Usuários tem dois campos conhecidos:

- endereços
- pedidos

Endereços tem cidades. Pedidos?

- valor total
- itens

Item por sua vez tem produto, produto tem nome e também uma informação que diz
se está disponível ou não. Daí, em uma notação de tipagem TS:

```ts
type Usuario = {
    enderecos: Endereco[],
    pedidos: Pedido[]
}

type Endereco = {
    cidade: String
}

type Pedido = {
    valorTotal: number,
    itens: Item[]
}

type Item = {
    produto: Produto
}

type Produto = {
    disponivel: bool,
    nome: String
}
```

O que está sedo resgatado são o nome dos produtos envolvidos em vendas acima de
500 reais para usuários que tem endereço em São Paulo.

# Analisando tipos para verificar o que queremos

Essa é uma análise muito semelhante a usada em
[Somando valores sem laços]({% post_url 2022-09-09-soma-valores-sem-loops %}).

O ponto de partida? O conjunto de usuários.

O que podemos filtrar? Usuários com endereço em São Paulo. Daí:

```java
usuarios.stream()
    .filter(temEnderecoEm("São Paulo"))
```

Até aqui similar a o que o Luís fez, né? Só que eu ainda não abri o que seria
essa função `temEnderecoEm`. Vou pegar diretamente do que o Luís colocou:

```java
private boolean temEnderecoEm(String cidade, Usuario u) {
    return u.getEnderecos().stream()
        .anyMatch(e -> e.getCidade().equalsIgnoreCase(cidade));
}
```

Hmmm, só que tem algo que não está casando. Eu forneci o nome da cidade e
obtive de volta algo para usar em `filter`. Logo, obtive um
`Predicate<Usuario>`, não um `boolean`. Então vamos transformar a função acima
em uma função de alta ordem pra resolver isso? Vou retornar algo que pega um
usuário e retorna se ele atende ao requisito ou não:

```java
private Predicate<Usuario> temEnderecoEm(String cidade) {
    return u -> u.getEnderecos().stream()
        .anyMatch(e -> e.getCidade().equalsIgnoreCase(cidade));
}
```

Ok, atingimos o que queríamos. Filtramos apenas para os usuários que tem
endereço em São Paulo. Pelo requisito, usuário não tem mais nada de útil. Para
navegar rumo ao nome do produto, vamos navegar para pedidos. Cada usuário pode
ter múltiplos pedidos.

Um `map` mapearia para um conjunto de pedidos, mas quero trabalhar com cada
item individualmente. Portanto, esse é um caso típico de se usar `flatMap`:

```java
usuarios.stream()
    .filter(temEnderecoEm("São Paulo"))
    .flatMap(u -> u.getPedidos().stream())
```

Pedido ainda tem algo de útil? Tem sim! Precisamos dos itens apenas de pedidos
acima de um determinado valor:

```java
usuarios.stream()
    .filter(temEnderecoEm("São Paulo"))
    .flatMap(u -> u.getPedidos().stream())
    .filter(p -> p.getValorTotal() > 500)
```

Ok, agora terminamos de obter valores úteis intermediários em de pedidos. Hora
de mapear de novo rumo aos produtos. No caso, novamente um pedido pode ter
múltiplos itens, vamos mapear achatando:

```java
usuarios.stream()
    .filter(temEnderecoEm("São Paulo"))
    .flatMap(u -> u.getPedidos().stream())
    .filter(p -> p.getValorTotal() > 500)
    .flatMap(p -> p.getItens().stream())
```

Certo, e de item, tem algo útil? Não. Mapeamos mais uma vez rumo ao nome do
produto. Dessa vez, o item só tem um produto, mapeamento simples sem necessitar
achatar:

```java
usuarios.stream()
    .filter(temEnderecoEm("São Paulo"))
    .flatMap(u -> u.getPedidos().stream())
    .filter(p -> p.getValorTotal() > 500)
    .flatMap(p -> p.getItens().stream())
    .map(i -> i.getProduto())
```

Tá, mas agora é uma função direta, podemos usar uma referência de método:

```java
usuarios.stream()
    .filter(temEnderecoEm("São Paulo"))
    .flatMap(u -> u.getPedidos().stream())
    .filter(p -> p.getValorTotal() > 500)
    .flatMap(p -> p.getItens().stream())
    .map(Item::getProduto)
```

Ok, agora estamos em produto. Posso obter o nome do produto agora? Posso. Mas
tem mais uma regra a se fazer ainda: filtrar apenas para produtos disponíves:

```java
usuarios.stream()
    .filter(temEnderecoEm("São Paulo"))
    .flatMap(u -> u.getPedidos().stream())
    .filter(p -> p.getValorTotal() > 500)
    .flatMap(p -> p.getItens().stream())
    .map(Item::getProduto)
    .filter(Produto::isDisponivel)
```

Ok, e agora? Pegar o nome dos produtos:

```java
usuarios.stream()
    .filter(temEnderecoEm("São Paulo"))
    .flatMap(u -> u.getPedidos().stream())
    .filter(p -> p.getValorTotal() > 500)
    .flatMap(p -> p.getItens().stream())
    .map(Item::getProduto)
    .filter(Produto::isDisponivel)
    .map(Produto::getNome)
```

Agora valores distintos e únicos:

```java
usuarios.stream()
    .filter(temEnderecoEm("São Paulo"))
    .flatMap(u -> u.getPedidos().stream())
    .filter(p -> p.getValorTotal() > 500)
    .flatMap(p -> p.getItens().stream())
    .map(Item::getProduto)
    .filter(Produto::isDisponivel)
    .map(Produto::getNome)
    .distinct()
    .sorted()
```

E transformar em uma lista:

```java
usuarios.stream()
    .filter(temEnderecoEm("São Paulo"))
    .flatMap(u -> u.getPedidos().stream())
    .filter(p -> p.getValorTotal() > 500)
    .flatMap(p -> p.getItens().stream())
    .map(Item::getProduto)
    .filter(Produto::isDisponivel)
    .map(Produto::getNome)
    .distinct()
    .sorted()
    .toList();
```

# Comparando as alternativas

```java
final var results1 = usuarios.stream()
    .filter(u -> u.getEnderecos().stream()
        .anyMatch(e -> e.getCidade().equalsIgnoreCase("São Paulo")))
    .flatMap(u -> u.getPedidos().stream()
        .filter(p -> p.getValorTotal() > 500))
    .map(p -> p.getItens().stream()
        .filter(i -> i.getProduto().isDisponivel())
        .map(i -> i.getProduto().getNome()))
    .flatMap(nomes -> nomes)
    .distinct()
    .sorted()
    .collect(Collectors.toList());

// vs

private Predicate<Usuario> temEnderecoEm(String cidade) {
    return u -> u.getEnderecos().stream()
        .anyMatch(e -> e.getCidade().equalsIgnoreCase(cidade));
}

final var results2 = usuarios.stream()
    .filter(temEnderecoEm("São Paulo"))
    .flatMap(u -> u.getPedidos().stream())
    .filter(p -> p.getValorTotal() > 500)
    .flatMap(p -> p.getItens().stream())
    .map(Item::getProduto)
    .filter(Produto::isDisponivel)
    .map(Produto::getNome)
    .distinct()
    .sorted()
    .toList();
```

Quais as maiores diferenças entre as duas soluções? Bem, a do Luís claramente é
uma solução que surgiu aos poucos e foram fazendo amends. Algo que surgiu
naturalmente.

Com isso, temos que algumas coisas se tornaram muito aninhadas. Na minha
solução eu fiz um pouco de compartimentação de conhecimento. Você não precisa
necessariamente saber todos os detalhes de saber o como filtrar o usuário pela
cidade, então eu obtenho um filtro pra isso. A implementação padrão é
justamente aquela fornecida pelo post:

```java
u -> u.getEnderecos().stream()
        .anyMatch(e -> e.getCidade().equalsIgnoreCase("São Paulo"))
```

Só abstraí o nome da cidade:

```java
u -> u.getEnderecos().stream()
        .anyMatch(e -> e.getCidade().equalsIgnoreCase(cidade))
```

Assim, a experiência de quem lê o código é melhorada:

```java
usuarios.stream()
    .filter(u -> u.getEnderecos().stream()
        .anyMatch(e -> e.getCidade().equalsIgnoreCase("São Paulo")))
// vs
usuarios.stream()
    .filter(temEnderecoEm("São Paulo"))
```

Outro ponto de diferença é que tratei individualmente as coisas. O mapeamento
de usuário para produtos com um determinado valor foi destrinchado:

```java
usuariosFiltrados
    .flatMap(u -> u.getPedidos().stream()
                    .filter(p -> p.getValorTotal() > 500)
    )

// vs

usuariosFiltrados
    .flatMap(u -> u.getPedidos().stream())
    .filter(p -> p.getValorTotal() > 500)
```

Por fim, a última diferença está em como pegar os nome dos produtos disponíveis
a partir dos pedidos:


```java
pedidosFiltrados
    .map(p -> p.getItens().stream()
        .filter(i -> i.getProduto().isDisponivel())
        .map(i -> i.getProduto().getNome()))
    .flatMap(nomes -> nomes)

// vs

pedidosFiltrados
    .flatMap(p -> p.getItens().stream())
    .map(Item::getProduto)
    .filter(Produto::isDisponivel)
    .map(Produto::getNome)
```

A diferença está em como foi feito o mapeamento. Pra isso, como tem múltiplos
itens para cada pedido, precisamos em algum momento achatar o stream. No caso
da primeira solução, ele retornou um `Stream<Item>` para depois achatar isso
em `Item`.

Nominalmente, a solução tinha algo assim:

```java
pedidosFiltrados
    .map(Function<Pedido, Stream<Item>>)
    .flatMap(Function<Stream<Item>, Stream<Item>>)
```

No `map`, pegou-se um `Pedido` e transformou em `Stream<Item>`. Um único
`Pedido` virou um único `Stream<Item>`, sem achatar. Então, daqui saímos
de `Stream<Pedido>` para `Stream<Stream<Item>>`. Daí, achatamos isso,
transformando o elemento individual (`U`, ou `Stream<Item>`) em streams,
`Stream<Item>`, então transformando de `Stream<Stream<Item>>` para
`Stream<Item>`.

Na abordagem alternativa, os passos foram distintos, mesmo obtendo o mesmo
resultado final. A primeira coisa foi já obter os itens do pedido. Podendo
nessa situação trabalhar com itens individualmente:

```java
pedidosFiltrados
    .flatMap(p -> p.getItens().stream())
```

Como item não tinha nada interessante, mapeou-se para produto:

```java
pedidosFiltrados
    .flatMap(p -> p.getItens().stream())
    .map(Item::getProduto)
```

Aqui, filtrou-se o produto:

```java
pedidosFiltrados
    .flatMap(p -> p.getItens().stream())
    .map(Item::getProduto)
    .filter(Produto::isDisponivel)
```

Então, a partir do produto disponível, obtemos o nome dele:

```java
pedidosFiltrados
    .flatMap(p -> p.getItens().stream())
    .map(Item::getProduto)
    .filter(Produto::isDisponivel)
    .map(Produto::getNome)
```

Depois disso a única diferença é que usei uma JDK mais recente, visto que a
partir do Java 16 temos 
[`Stream::toList`](https://docs.oracle.com/en/java/javase/24/docs/api/java.base/java/util/stream/Stream.html#toList())

> ```java
> default List<T> toList()
> ```
> 
> **Since**: 16
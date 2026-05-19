---
layout: post
title: "Implementando uma pilha a partir de uma fila"
author: "Jefferson Quesado"
tags: estrutura-de-dados java
base-assets: "/assets/lifo-from-fifo/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Em uma conversa despretenciosa com o [Leandro Proença](https://leandronsp.com)
no LinkedIn, mencionei que dá pra implementar pilha usando apenas uma fila.

Bem, vamos fazer isso? Primeiro, vamos definir exatamente o que é "implementar
uma estrutura X com uma estrutura Y", então vamos pro caso mais trivial que é
implementar uma fila usando duas pilhas, então vamos implementar uma pilha
usando apenas uma fila.

Nota importante aqui, muitos desses resultados e das estratégias usadas são
decorrentes de conversas que já tivemos aqui no Computaria, como por exemplo:

- [Uma demonstração de que Autômatos de Fila equivalem a Máquinas de Turing em poder computacional, parte 1]({% post_url 2022/2022-05-28-automato-fila-equiv-mt-pt1 %})
- [Quem é mais poderoso, uma Máquina de Turing com fita limitada ou um Autômato Finito?]({% post_url 2026/2026-02-25-tm-fita-limitada-vs-nfa %})

# Definindo pilhas e filas

Já definimos antes essas estruturas, né? Como em
[Criando filas e pilhas "apenas" com funções em java]({% post_url 2023/2023-08-31-java-pilha-fila-apenas-funcoes %}),
mas ali tinha algumas limitações diferentes (como a questão dos efeitos
colaterais) que me levaram a decisões de design... diferentes... do que se
encontraria em um código Java selvagem em seu habitat natural.

No caso, aqui vamos usar algo mais parecido com as estruturas de dados que
foram usadas para percorrer os grafos em
[Meu take sobre o algoritmo de Dijkstra]({% post_url 2024/2024-07-31-dijkstra-algorithm %}):

- `push(element: T) => void`
- `pop() => T`
- `empty() => boolean`

Aqui tanto pilha como fila vão seguir esse mesmo _shape_: um container que eu
posso inserir objetos, recuperar objetos de lá de dentro e verificar se está
vazio.

# Uma fila com duas pilhas

Bem, aqui a implementação básica é a pilha, então vou precisar instanciar ela.
Vou fazer de modo bem simples: um `ArrayList` que eu insiro e removo do final:

```java
public class Pilha<T> {
    private final ArrayList<T> elementos = new ArrayList<>();

    public void push(T t) {
        elementos.addLast(t);
    }

    public T pop() {
        return elementos.removeLast();
    }

    public boolean empty() {
        return elementos.isEmpty();
    }
}
```

Ok, agora vamos fazer a partir disso uma `Fila<T>`. Eu posso simplesmente
quando chegar um novo elemento colocar na pilha? Posso, só preciso tomar
cuidado na hora de _remover_ o elemento: não posso remover com um simples
`pop`, preciso garantir que seja o primeiro a entrar!

O jeito clássico de fazer isso é usando uma pilha secundária: ao chegar uma
requisição de `pop`, eu recoloco os elementos da pilha principal na pilha
secundária. O último elemento removido da pilha principal equivale à parte da
frente da fila, portanto precisa ser retornado. Após isso, só colocar de volta
no lugar os elementos que foram deslocados (em tese daria para otimizar para
muitos `pop` seguidos, mas aqui o foco não é otimização):

```java
public class Fila<T> {
    private final Pilha<T> elementos = new Pilha<>();
    private final Pilha<T> secundaria = new Pilha<>();

    public void push(T t) {
        elementos.push(t);
    }

    public T pop() {
        while (!elementos.empty()) {
            secundaria.push(elementos.pop());
        }
        final var v = secundaria.pop();
        while (!secundaria.empty()) {
            elementos.push(secundaria.pop());
        }
        return v;
    }

    public boolean empty() {
        return elementos.isEmpty();
    }
}
```

Existe uma outra maneira de imoplementar isso, que seria pegar o elemento antes
do fim. Vai sacando os valores e, ao detectar o fim, retornar o elemento
encontrado:

```java
public class Fila<T> {
    private final Pilha<T> elementos = new Pilha<>();
    private final Pilha<T> secundaria = new Pilha<>();

    public void push(T t) {
        elementos.push(t);
    }

    public T pop() {
        while (true) {
            final var candidato = elementos.pop();
            if (elementos.empty()) {
                // devolve os elementos de volta
                while (!secundaria.empty()) {
                    elementos.push(secundaria.pop());
                }
                return candidato;
            }
            secundaria.push(candidato);
        }
    }

    public boolean empty() {
        return elementos.isEmpty();
    }
}
```

# Uma pilha com duas filas

Bem, já que estamos trocando de empurrar no começo pro empurrar no fim, será
que dá para pegar o exato mesmo algoritmo de duas pilhas simulando uma fila e
fazer duas filas simulando uma pilha? Na real... dá sim!

Não importa o como vai ser implementada a fila em si, apenas que siga a
convenção de comportamento. Então, podemos até assumir que vamos usar a fila
desenvolvida na seção anterior.

Com isso fora de preoucupação, vamos seguir o mesmo formato de algoritmo:

```java
public class Pilha<T> {
    private final Fila<T> elementos = new Fila<>();
    private final Fila<T> secundaria = new Fila<>();

    public void push(T t) {
        elementos.push(t);
    }

    public T pop() {
        while (true) {
            final var candidato = elementos.pop();
            if (elementos.empty()) {
                // devolve os elementos de volta
                while (!secundaria.empty()) {
                    elementos.push(secundaria.pop());
                }
                return candidato;
            }
            secundaria.push(candidato);
        }
    }

    public boolean empty() {
        return elementos.empty();
    }
}
```

# Uma pilha com uma fila

Vamos pensar aqui qual o objetivo de se usar a fila secundária? Vamos fazer um
desenho de como está sendo a questão do uso dessas coisas?

- eu diminuo a fila principal
- se eu cheguei no final da fila principal, o último elemento removido precisa
  ser retornado
- se eu não cheguei no final da fila principal, preciso guardar o que foi
  removido
- após detectar o momento do retorno, tudo que foi removido preciso ser
  inserido de volta na fila principal

Ou seja, eu preciso de:

- indicador de fim
- um buffer para restaurar a fila

E se... eu conseguir fazer isso usando apenas uma única fila? Bem, pra isso eu
preciso trabalhar com a fila de modo... especial... No lugar da fila ter apenas
elementos do tipo `T`, preciso que ela tenha um elemento tal que não seja do
tipo `T` que eu possa diferenciar. As operações que eu faço via pilha são todas
em cima de `T`, a API externa não muda. Mas internamente eu preciso de um novo
elemento que seja incompatível com os elementos que estou inserindo. Algo
semelhante foi usado para poder transformar função parcial em função total no
artigo
[Criando mapas "apenas" com funções em java]({% post_url 2023/2023-08-21-java-map-stateless %}).

A minha primeira ideia seria fazer com que o _backbone_ da implementação de
`Pilha<T>` fosse `Fila<Object>` e eu iria inserir forçosamente um
`new Object()`, que ficaria marcado no momento da criação como "elemento de
diferenciação". Mas então lembrei que eu posso fazer algo semelhante a um
sum-type usando `sealed interface` (exploro mais isso no artigo
[Usando Java moderno para fazer aritmética de Peano]({% post_url 2025/2025-03-10-peano-java-moderno %})):

```java
sealed interface Elemento<V> {
    record Demarcador<V>() implements Elemento<V> {}
    record Container<V>(V v) implements Elemento<V> {}
}
```

Agora vou usar uma instância `Demarcador` para indicar que cheguei no final da
fila. Se eu tenho um final forte, isso significa que eu posso simplesmente
readicionar os elementos que eu tinha após o final da fila. Logo, isso
significa que manter uma estrutura secundária apenas por buffer de elementos de
torna desnecessário.

Agora, ao dar um `pop`, preciso verificar se o elemento é o demarcador. Se for,
preciso retornar o elemento que foi sacado logo antes dele. Se não for um
demarcador, preciso guardar o penúltimo elemento de volta na fila, e reservar o
elemento que acabei de sacar para a próxima iteração:

```java
public class Pilha<T> {

    private sealed interface Elemento<V> {
        record Demarcador<V>() implements Elemento<V> {}
        record Container<V>(V v) implements Elemento<V> {}
    }

    private final Fila<Elemento<T>> elementos = new Fila<>();
    
    public void push(T t) {
        elementos.push(new Elemento.Container<>(t));
    }
    
    public T pop() {
        elementos.push(new Elemento.Demarcador<>());
        Elemento.Container<T> penultimo = null;
        while (true) {
            final var candidato = elementos.pop();
            if (candidato instanceof Elemento.Container<T> anotherValue) {
                if (penultimo != null) {
                    elementos.push(penultimo);
                }
                penultimo = anotherValue;
            } else {
                return penultimo.v();
            }
        }
    }
    
    public boolean empty() {
        return elementos.empty();
    }
}
```

Como teste, adicionei 4 elementos e depois saquei até o esgotamento da pilha:

```java
final var p = new Pilha<String>();
p.push("a");
p.push("b");
p.push("c");
p.push("d");
while (!p.empty()) {
    System.out.println(p.pop());
}
```

Note algumas coisas interessantes:

- o elemento `Demarcador` só é inserido durante o processo de `pop`, e o
  processo de `pop` só termina após sacar o `Demarcador`
- eu só preciso fazer a reinserção dos elementos após o segundo saque

Essa observação do "segundo saque" me leva a uma implementação alternativa, que
incondicionalmente faz o primeiro saque e reserva o valor, antes mesmo de
sequer cogitar inserir o demarcador. A ideia é:

- saca o elemento
- se estiver vazio, retorna o elemento
- se não estiver vazio, reserva esse elemento
- insere o demarcador
- continue sacando próximos elementos
- se o elemento sacado for demarcador, retorne o elemento reservado
- se não, insira o elemento reservado de volta e reserve o elemento sacado

```java
public T pop() {
    var reservado = (Elemento.Container<T>) elementos.pop();
    if (elementos.empty()) {
        return reservado.v();
    }
    elementos.push(new Elemento.Demarcador<>());
    while (true) {
        final var candidato = elementos.pop();
        if (candidato instanceof Elemento.Container<T> anotherValue) {
            elementos.push(reservado);
            reservado = anotherValue;
        } else {
            return reservado.v();
        }
    }
}
```

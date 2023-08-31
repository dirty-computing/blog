---
layout: post
title: "Criando filas e pilhas \"apenas\" com funções em java"
author: "Jefferson Quesado"
tags: java estrutura-de-dados
base-assets: "/assets/java-pilha-fila-apenas-funcoes/"
---

Na postagem [anterior, criando mapeamento com
funções]({% post_url 2023-08-21-java-map-stateless %}),
o desafio proposto era implementar um mapeamento usando apenas
funções. Agora, que tal expandir para mais estruturas de dados?
Que tal pilha e fila?

# Fazendo uma pilha

Os principais métodos da pilha são:

- `pop`, em que a pilha remove o elemento do topo e permite
  a sua manipulação por terceiros
- `push`, em que um novo elemento é colocado no topo da pilha

Também é conveniente ter o `empty`: chegamos no fim da pilha?

Pois bem, vamos pensar nos métodos da pilha.

Ao chamar `push`, como não se deseja alterar o estado da pilha
atual, devemos retornar um novo objeto de pilha com o topo modificado.
Tranquilo fazer o `push`, aparentemente ele é algo como
`push(p: Pilha<T>, el: T): Pilha<T>`.

Mas, e o `pop`? Bem, para ele precisamos retornar o novo elemento da pilha.
Como fazemos isso? Se pormos no retorno, isso implica que o objeto pilha
precisa ter o estado alterado, e não queremos isso. Então, quais opções
a mais temos?

Uma delas seria retorno múltiplo: `pop(p: Pilha<T>): [Pilha<T>, T]`. Mas
a linguagem java não favorece muito isso. Outra alternativa seria retornar
a pilha e passar algo para _consumir_ o que a pilha produzir. Que tal
essa abordagem? `pop(p: Pilha<T>, sink: (el: T) => void): Pilha<T>`.
Com isso conseguimos manipular a pilha em todas as suas opções.

Assim, os métodos abertos de pilha seriam esses:

```java
interface Pilha<T> {
    boolean empty();
    Pilha<T> push(T el);
    Pilha<T> pop(Consumer<T> sink);
}
```

Bem, e se eu simplesmente quiser queimar o elemento do topo da pilha
sem fazer nada com ele? Podemos adicionar um método `pop` sem o `sink`:

```java
default Pilha<T> pop() {
    return pop(unsued -> {});
}
```

Tem utilidade? Não sei. Mesmo. Mas sempre que pensei na API me parece
que seria algo útil.

Antes de ir atrás dos detalhes da implementação, vamos contar quantos
elementos tem na pilha, transformar em um iterador, e essas coisas?

## Métodos auxiliares e não diretamente ligados à estrutura de dados

Pois bem... vamos começar definindo um `Iterator<T>` em cima da `Pilha<T>`?
Disso para `Pilha<T>` implementar `Iterable<T>` é simplesmente ensinar a
interface a chamar o método que cria o `Iterator<T>`.

Pela definição de [`Iterator<T>`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/Iterator.html):

```java
interface Iterator<T> {
    boolean hasNext();
    T next();
    default void forEachRemaining(Consumer<? super E> action) {
        while (hasNext()) {
            action.accept(next());
        }
    }

    default void remove() {
        throw new UnsupportedOperationException();
    }
}
```

Primeira pergunta: tem elemento? A resposta é a simples negação do `empty`.
Então, para o iterador de `Pilha<T>`, ele só precisa perguntar à instância
de `Pilha<T>` que ele está ajudando a percorrer se ela está vazia.

E o `next()`? Bem, nele precisamos guardar o que o `pop` joga para o
`Consumer<T>` e atualizar também a referência que o iterador tem da `Pilha<T>`,
já que a instância de `Pilha<T>` que iremos trabalhar é imutável:

```java
public class PilhaIterator<T> implements Iterator<T> {

    private Pilha<T> pilha;
    private static class Indirecao<X> {
        public X x;
    }

    public PilhaIterator(Pilha<T> inicial) {
        this.pilha = inicial;
    }

    @Override
    public boolean hasNext() {
        return !pilha.empty();
    }

    @Override
    public T next() {
        if (pilha.empty()) {
            throw new NoSuchElementException();
        }
        var guardaRetorno = new Indirecao<T>();
        this.pilha = this.pilha.pop(topo -> guardaRetorno.x = topo);
        return guardaRetorno.x;
    }
}
```

E se eu quisesse contar quantos elementos tem em `Pilha<T>`?
Bem, temos algumas alternativas. Recursivas (com trampolim ou não),
usando `while` sem iterador ou simplesmente usando o iterador recém
criado. Por que não implementar dos 3 jeitos?

Essas criações dependem apenas da API públic de `Pilha<T>`, então
a `Pilha<T>` sempre será passada como parâmetro. Esses métodos podem
ser estáticos de uma classe utilitária:

```java
<T> int contarElementosPilha_recursivo(Pilha<T> p) {
    if (p.empty()) {
        return 0;
    }
    return 1 + contarElementosPilha_recursivo(p.pop());
}

<T> int contarElementosPilha_while(Pilha<T> p) {
    Pilha<T> it = p;
    int c = 0;
    while (!it.empty()) {
        it = it.pop();
        c++;
    }
    return c;
}

<T> int contarElementosPilha_for(Pilha<T> p) {
    int c = 0;
    Iterable<T> it = () -> new PilhaIterator<>(p);
    for (T t: it) {
        c++;
    }
    return c;
}
```

E que tal inverter uma pilha? Podemos gerar uma pilha vazia e ficar dando
`push` nela para cada `pop` da pilha original. Vamos fazer isso também
dos 3 modos: recursão, `while` e `for`, pelo simples prazer do exercício.

Começando pelo modo recursivo. Para ter uma iteração saudável, vou começar
com um `entrypoint`, em que recebo apenas uma única pilha. A minha
recursão propriamente dita vai envolver duas pilhas:
- a original, que eu vou desempilhando, no lado esquerdo
- a nova, que eu vou empilhando em cima, no lado direito

A estratégia vai ser sempre desempilhar da original e empilhar na nova.
Então eu passo recursivamente a original com um desempilhar adiante
e a nova após empilhar recursivamente. Como o `pop` recebe um `Consumer<T>`,
vou usar ele para guardar uma indireção com uma referência ao
`empilhando.push(el)`. Vale ressaltar que o `entrypoint` precisa chamar o
procedimento recursivo com a pilha original do lado esquerdo e uma pilha
vazia do lado direito:

```java
private static class Indirecao<X> {
    public X x;
}

<T> Pilha<T> inverte_recursivo_entrypoint(Pilha<T> t) {
    return inverte_recursivo(t, Pilha.emptyStack());
}

private <T> Pilha<T> inverte_recursivo(Pilha<T> original, Pilha<T> empilhando) {
    if (original.empty()) {
        // não tem mais operações
        return empilhando;
    }
    var indirecao = new Indirecao<Pilha<T>>();
    var pilhaDesempilhada = original.pop(e -> indirecao.x = empilhando.push(e));
    return inverte_recursivo(pilhaDesempilhada, indirecao.x);
}
```

Com while podemos simplesmente usar a indireção constantemente: guardando
na indireção o valor de adicionar na pilha da indireção.

```java
<T> Pilha<T> inverte_while(Pilha<T> t) {
    Indirecao<Pilha<T>> indirecao = new Indirecao<>();
    indirecao.x = Pilha.emptyStack();

    Pilha<T> it = t;
    while (!it.empty()) {
        it = it.pop(el -> indirecao.x = indirecao.x.push(el));
    }
    return indirecao.x;
}
```

Com `for` não tem segredo:

```java
<T> Pilha<T> inverte_for(Pilha<T> t) {
    Pilha<T> invertida = Pilha.emptyStack();
    Iterable<T> it = () -> new PilhaIterator<>(t);
    for (T el: it) {
        invertida = invertida.push(el);
    }
    return invertida;
}
```

## Definindo as operações básicas da pilha

Bem, que tal começarmos com a operação `push`? Ela vai ser idêntica para
toda pilha que vier, então vai ser um método `default`. Basicamente,
preciso guardar uma referência à instância original para poder devolver
quando houver um `pop`. O `sink` que é passado para o `pop` irá receber
o argumento passado para o `push`, o único ponto em que esse argumento
se torna necessário. De resto, posso garantir que a pilha não está mais
vazia:

```java
default Pilha<T> push(T el) {
    Pilha<T> original = this;

    return new Pilha<>() {

        @Override
        public boolean empty() {
            return false;
        }

        @Override
        public Pilha<T> pop(Consumer<T> sink) {
            sink.accept(el);
            return original;
        }
    };
}
```

Bem, e a pilha vazia? Como seria ela?

A primeira coisa é que ela responderia que está vazia. A segunda
coisa é que tentar dar `pop` nela não é significativo, então não
irei consumir nada com o `sink` e retornar a si mesma:

```java
static <T> Pilha<T> emptyStack() {
    return new Pilha<>() {

        @Override
        public boolean empty() {
            return true;
        }

        @Override
        public Pilha<T> pop(Consumer<T> sink) {
            return this;
        }
    };
}
```

# Fazendo uma fila

Bem, na pilha precisamos seguir o princípio de `LIFO`: _last-in, first-out_,
último a entrar é o primeiro a sair. Agora, com fila, temos outro princípio, o
`FIFO`: _first-in, first-out_, primeiro a entrar, primeiro a sair.

Enquanto na pilha, se movimentava a cabeça, aqui precisa se movimentar a
cauda. Ou seja: enquanto na pilha eu consigo fazer reaproveitamento, na fila
eu preciso criar novo.

Se eu fosse fazer em JavaScript, implementaria a inserção de elementos na
fila mais ou menos assim:

```js
(fila, n) => [...fila, n];
```

Mas, a ideia não é usar JS, mas sim Java. Como fazer isso? Bem,
nada como fazer algo como `car`/`cdr`. Aqui as operações `car`/`cdr`
são as mesmas operações de `car`/`cdr` descritas em Lisp:

- `car`: primeiro elemento da lista
- `cdr`: a lista menos o primeiro elemento

Além do `car` e do `cdr`, seria bom também a operação `push`.
E para auxiliar com algumas questões, podemos verificar se
a fila está vazia também.

Tal qual na pilha, o método `pop` precisa receber um `Consumer<T>`
para lidar com o elemento sendo removido. E ao estar vazia e
receber o `pop`, não precisa fazer nada.

Vamos já fazer o método `pop` então? Baseado em `car` e `cdr`?
Basicamente, se for uma fila vazia, retorna a si mesma. Caso
contrário, pega `car` e passa para o `Consumer<T>` e retorna
o `cdr`:

```java
default Fila<T> pop(Consumer<T> sink) {
    if (empty()) {
        return this;
    }
    sink.accept(car());
    return cdr();
}
```

Bem, agora precisamos responder como implementar `car`, `cdr` e `push`.
Vamos fazer `push` logo.

Se eu tenho uma lista `L` e empurro o elemento `a` nela, então eu teria
a lista `[...L, a]` como resultado. Bem, e se `L = [ c | B ]`? Isto é,
se `L` for uma lista não vazia, com pelo menos um elemento na cabeça?
Com isso, temos que:

- `L.car() => c`
- `L.cdr() => B`

E, ao empurrar o elemento `a` para o final dela, a cabeça permanece
inalterada, porém é como se o corpo fosse feito um novo anexo. Saímos
de `[c, ...B]` para algo como `[c, ...B, a]`. E, bem, veja só! A nova
fila é como se eu empurasse `a` no final do corpo da primeira lista,
como se `L = [ c | B ], L.push(a) = [ c | B.push(a) ]`. Então, para
`L` não vazio:

- `L.push(a).car() => c`
- `L.push(a).cdr() => B.push(a)`

Porém, e se `L` for vazio? Bem, nesse caso, o `cdr` se mantém (continua
retornando o vazio), porém `car` passa a ser o elemento empurrado:

- `L.push(a).car() => a`
- `L.push(a).cdr() => L`

Então, basicamente, tendo acesso `car`, `cdr` e `empty`, consigo fazer
o `push`:

```java
default Fila<T> push(T a) {
    final var L = this;
    if (empty()) {
        return new Fila<>() {

            @Override
            public T car() {
                return a;
            }

            @Override
            public Fila<T> cdr() {
                return L;
            }

            @Override
            public boolean empty() {
                return false;
            }
        };
    }
    return new Fila<>() {

        @Override
        public T car() {
            return L.car();
        }

        @Override
        public Fila<T> cdr() {
            return L.cdr().push(a);
        }
    };
}
```

E a implementação da fila vazia?

```java
static <T> Fila<T> emptyQueue() {
    return new Fila<>() {

        @Override
        public T car() {
            return null;
        }

        @Override 
        public Fila<T> cdr() {
            return this;
        }

        @Override
        public boolean empty() {
            return true;
        }
    };
}
```

Com isso, o que teríamos na interface:

```java
interface Fila<T> {
    T car();
    Fila<T> cdr();
    boolean empty();

    default Fila<T> push(T a) {
        final var L = this;
        if (empty()) {
            return new Fila<>() {

                @Override
                public T car() {
                    return a;
                }

                @Override
                public Fila<T> cdr() {
                    return L;
                }

                @Override
                public boolean empty() {
                    return false;
                }
            };
        }
        return new Fila<>() {

            @Override
            public T car() {
                return L.car();
            }

            @Override
            public Fila<T> cdr() {
                return L.cdr().push(a);
            }

            @Override
            public boolean empty() {
                return false;
            }
        };
    }

    default Fila<T> pop(Consumer<T> sink) {
        if (empty()) {
            return this;
        }
        sink.accept(car());
        return cdr();
    }

    static <T> Fila<T> emptyQueue() {
        return new Fila<>() {

            @Override
            public T car() {
                return null;
            }

            @Override 
            public Fila<T> cdr() {
                return this;
            }

            @Override
            public boolean empty() {
                return true;
            }
        };
    }
}
```

Outras implementações, como o `.pop()` sem argumentos por
conveniência, o iterador e a contagem de elementos é idêntica
a essas mesmas operações na pilha, portanto não vejo necessidade
de colocar aqui. Mas... podemos inverter uma fila.

## Invertendo a fila

Tome uma fila na forma `F = [ c | B ]`. A inversão dessa fila seria
algo como `F' = [ c | B ]' == [ B' | c ]`, com o apóstrofo indicando
que é a versão invertida, no caso `F'` é a inversão de `F` e `B'` a
inversão de `B`.

Além disso, vale ressaltar que uma fila vazia é a inversão dela mesma:
`[] == []'`. Então, em cima das operações de `car`, `cdr` e `push`, como
inverter a fila?

Bem, se a fila estiver vazia, retorna ela mesma. Caso contrário, pega
a cabeça dela e guarda, então inverte o `cdr` e, em cima do `cdr`
invertido, dá um `push` na cabeça que foi guardada:

```java
<T> Fila<T> inverteFila(Fila<T> L) {
    if (L.empty()) {
        return L;
    }
    return inverteFila(L.cdr()).push(L.car());
}
```

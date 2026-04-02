---
layout: post
title: "Reinventando a roda: como escrever streams sem usar stream como base"
author: "Jefferson Quesado"
tags: java programação-funcional stream
base-assets: "/assets/reinventando-roda-java-streams/"
---

Era uma vez um mundo de Java 7. Não existiam streams no Java, não existiam
lambdas no Java (classes anônimas seriam uma aproximação, mas não conta porque
elas são bem anti-práticas).

E desse mundo eu conheci as maravilhas da programação funcional em Java, e um
problema comum de mutabilidade de estados poderia ser resolvido usando streams.

O primeiro problema era como representar uma função de modo prático, e graças
ao [Retrolambda](https://github.com/luontola/retrolambda) foi possível
adicionar lambdas no projeto. Próximo passo? Fazer as streams.

Dada as limitações que eu tinha da época, eu precisava ter uma API próxima o
suficiente de streams, não precisa literalmente algo 100% sem atrito de fazer
um `someList.stream()`. Uma alterativa seria usar um `new Stream<>(someList)`
ou então `Stream.streamify(someList)`.

Com isso, eu poderia ter o poder das streams na minha mão. E, acredite, para a
época ter toda uma biblioteca para emular algo semelhante a streams valeu o
esforço.

> Quem estiver curioso, muito do artefato produzido ficou na biblioteca
> open-source chamada de
> [functional-toolbox](https://gitlab.com/geosales-open-source/totalcross-functional-toolbox).

# Setando limitações iniciais

Bem, a primeira limitação é que precisa ser algo feito em cima de um iterável.
A stream produzida precisa receber um iterável e retornar algo com uma API
stream-like.

Em java, a interface
[`Iterable<T>`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/lang/Iterable.html)
tem um único método aberto chamado de `iterator()` que produz um `Iterator<T>`.

Apesar de na especificação Java
[`Stream<T>`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/stream/Stream.html)
ser uma interface, não há essa necessidade no caso do clone de streams que
faremos aqui.

Não iremos reaproveitar objetos. Uma vez que se faz, por exemplo,
`transformIntoStream(someList).map(someFunction)`, iremos primeiro criar um
objeto com a API stream-like na chamada `transformIntoStream` e, em seguida,
criar um novo objeto ao chamar `map`.

Spliterators não são permitidos nessa primeira reinvenção de roda, visto que
não seria possível acessá-los na época de um runtime compatível com Java 7 sem
precisar reinventá-los. Como não era necessário um spliterator para o que se
estava trabalhando, mas sim a API de algo semelhante a stream (e, também, da
coleção de `Collectors` disponível por padrão), spliterator não vai ser levado
em consideração.

Intefaces funcionais não precisam ser estritamente compatíveis por nome 1:1 com
o que se tem no Java, mas precisa ter o mesmo método aberto. Por exemplo, um
`map` na stream do Java recebe uma
[`java.util.function.Function<T, R>`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/function/Function.html)
que tem um método aberto `R apply(T)`. Isso significa que eu posso ter uma
interface do tipo `myjava.Function<T, R>` com um único método, aberto ainda por
cima, `R apply(T)`. Por simplicidade (e porque de fato o runtime permitia) não
iremos recriar as interfaces, iremos usá-las, mas estando limitado apenas ao
método aberto. Se for desejável usar algo como
[`<V> Function<V,R> compose(Function<V,T>)`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/function/Function.html#compose(java.util.function.Function))
então não poderia simplesmente fazer `func.compose(otherFunc)`, mas sim
`FunctionUtils.compose(func, otherFunc)`.

Outra limitação é, por mais que seja difícil, é abrir mão de novidades do Java.
Eu preciso usar como target Java 8, para poder rodar o Retrolambda e
transformar o bytecode para Java 7. Então, de modo geral, a API que eu vou usar
precisa ser compatível com o Java 7. Porém, devido a questões da facilidade da
plataforma alvo, eu posso usar as interfaces funcionais.

As limitações de sintaxe tem um pouco mais de liberdade, mas mesmo assim vou
tentar de manter nas restrições que eu tinha na época: posso usar tudo do Java
7 e também lambdas. Entretanto, não posso usar anotações em runtime, só para
geração de código.

Para códigos de teste, vou me dar a possibilidade de chamar `List.of`, isso
facilita demais o trabalho sem perder a generalidade.

Em resumo, minhas limitações são:

- Java 7 (menos anotações de runtime)
- sem métodos `default` de interface
- sem métodos estáticos de interface
- interfaces funcionais do Java 8 (`Supplier`, `Consumer`, `Function` etc)
- lambdas liberado

Para testes não preciso de nenhuma restrição (afinal, a restrição só pra
produção), mas vou tentar manter o máximo possível de compatibilidade com as
restrições acima.

# Estratégia de desenvolvimento

Dadas essas limitações, o primeiro alvo deve ser alcançar o `forEach`. O
primeiro desenvolvimento deve ser alcançar essa operação terminal. Hello world?
Vamos imprimir uma lista de strings.

Depois dessa operação terminal, podemos passar para uma operação intermediária.
Nada como `map` aqui para transformar o tipo. Podemos pegar a lista de palavras
e transformar em uma lista de comprimentos de palavras. Aqui uma operação de
transformação de tipos do jeito errado geraria um `ClassCastException`, o que é
uma ótima maneira de detectar a falha ao rodar.

A operação de `map` mantém a mesma quantidade de elementos. Outro passo
intermediário porém mais problemático (e, portanto, melhor para se aprender) é
o `filter`, justamente porque ele altera a quantidade de elementos.

Em seguida, coletar (primeiro com `reduce`, em seguida com `collect` mesmo). Os
coletores mais simples são `toList` e `toSet`, que podem ser tratados como
simplesmente casos especiais de `toCollection`.

# Primeiras implementações: stream

A base é um `Iterable<T>`, que na prática é um jeito de gerar
[`Iterator<T>`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/Iterator.html).
O `Iterator<T>` por sua vez é uma estrutura mutável que tem apenas dois
métodos:

- `hasNext` permite saber se é possível chamar `next` e o resultado ser
  confiável
- `next` retorna o elemento atual do iterador e avança o ponteiro

Vamos usar uma classe para se comportar como stream. Como ela vai receber um
`Iterable<T>`, temos isso:

```java
public class Stream<T> {
    private final Iterable<T> it;

    public Stream(Iterable<T> it) {
        this.it = it;
    }
}
```

Pronto, agora vamos separar regiões para operações intermediárias e operações
terminadoras:

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

E, por fim, as factories! Como `.of(1, 2, 3)` e `.iterate(seed, operator)`!

```java
public class Stream<T> {
    private final Iterable<T> it;

    public Stream(Iterable<T> it) {
        this.it = it;
    }

    // intermediate operations

    // terminal operations

    // factories
}
```

## forEach

O `forEach` é uma operação tranquila: só preciso consumir o que é gerado pelo
iterável:

```java
public void forEach(Consumer<T> action) {
    for (T t: it) {
        action.accept(t);
    }
}
```

Se não quisermos usar a estrutura do `for-each` do Java, podemos transformar o
`Iterable<T>` em um `Iterator<T>` e consumir num laço `for`:

```java
public void forEach__classicFor(Consumer<T> action) {
    for (Iterator<T> iterator = it.iterator(); iterator.hasNext();) {
        final T t = iterator.next();
        action.accept(t);
    }
}
```

Alternativa com `while`:

```java
public void forEach__while(Consumer<T> action) {
    final Iterator<T> iterator = it.iterator();
    while (iterator.hasNext()) {
        final T t = iterator.next();
        action.accept(t);
    }
}
```

Aqui foram apresentadas essas alternativas por pura curiosidade, o padrão vai
ser usar `for-each` se possível (na maioria dos casos não é).

## map

Vamos mapear. Agora, vamos precisar gerar uma nova stream, não podemos
modificar o objeto. E também vamos deixar ela ser lazy! Nada de coletar
em uma lista (ocupar a memória) e depois passar a usar essa lista. Vamos
encadear várias e várias vezes, não tem porque juntar.

Então, bora lá! O `map` vai receber uma função `T -> R`. E o retorno vai ser
uma `Stream<R>`. E como construímos `Stream<R>`? Com um `Iterable<R>`.

Agora, o `Iterable<T>` é uma classe que possui um único método, que retorna um
`Iterator<T>`. Posso representar por um lambda! (Já que tenho Retrolambda!)

Mas o `Iterator<T>` é uma classe que tem estado, precisa manter noção de que
tem um `next`, o `hasNext`, essas coisas. O esqueleto da função seria isso:

```java
public <R> Stream<R> map(Function<T, R> mapper) {
    return new Stream<>(() -> new Iterator<>() {
        
        @Override
        public boolean hasNext() {
            return false;
        }

        @Override
        public R next() {
            return null;
        }
    });
}
```

Agora, como preencher isso? Para começar, que tal manter o iterador da stream
com o elemento a ser sacado como estado desse `Iterador`? Algo assim:

```java
public <R> Stream<R> map(Function<T, R> mapper) {
    return new Stream<>(() -> new Iterator<>() {

        private final Iterator<T> innerIterator;
        
        {
            this.innerIterator = it.iterator();
        }

        @Override
        public boolean hasNext() {
            return false;
        }

        @Override
        public R next() {
            return null;
        }
    });
}
```

E agora? Bem, podemos fazer um wrapper puro. Se o `innerIterator` tiver
elementos, eu garanto que o meu `next` irá existir:

```java
@Override
public boolean hasNext() {
    return innerIterator.hasNext();
}
```

E quanto ao `next`? Bem, agora usamos a função para mapear o que o iterador
interno nos responder˜

```java
@Override
public R next() {
    final T el = innerIterator.next();
    return mapper.apply(el);
}
```

Vamos testar?

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3));
s.map(x -> 2*x).forEach(System.out::println);
```

E isso imprime corretamente:

```none
2
4
6
```

Tá, mas isso não alterou o tipo, né? E que tal... se eu transformar em string,
então pegar o comprimento desse número como inteiro, e imprimir?

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3));
s.map(i -> stringify(i)).map(String::length).forEach(System.out::println);

static String stringify(int i) {
    switch (i) {
        case 0: return "zero";
        case 1: return "um";
        case 2: return "dois";
        case 3: return "tres";
        case 4: return "quatro";
        case 5: return "cinco";
        case 6: return "seis";
        case 7: return "sete";
        case 8: return "oito";
        case 9: return "nove";
        default: return "muito grande";
    };
}
```

Ele imprime:

```none
2
4
4
```

Que é o comprimento de `um`, `dois` e `seis`, respectivamente. Então, feliz,
conseguimos! Fizemos o mapeamento!

## filter

O filter não muda o tipo. Ou seja, eu só posso usar o que eu resgatei, não
altero o objeto resgatado. Porém, nesse caso, eu vou selecionar qual o objeto
que eu de fato vou retornar.

Como para saber se tenho um próximo elemento na prática eu preciso alterar o
valor do iterador, vou já fazer um "pre-fetch" para saber qual o próximo
elemento (se é que existe). Assim, eu vou sempre saber se tenho um próximo e
qual seria esse próximo. O iterador vai ser lazy, apenas um pequeno fetch
inicial mais eager do que absolutamente lazy, o que tá dentro das limitações.

Então, bora lá? Vamos criar uma rotina para buscar o próximo elemento válido
segundo o filtro, que vai povoar ao mesmo tempo uma variável para indicar se
tem próximo e também qual o próximo em questão. Eventualmente o próximo pode
ser nulo, por sinal.

Se essa rotina existir, como que a gente poderia usar ela? Bem, na construção
do objeto, eu a chamo e povoo as variáveis `_next` e `_hasNext`. Já, ao chamar
o `hasNext()` do iterador, eu simplesmente retorno `_hasNext`. Ao chamar o
`next()` do iterador, eu preciso retornar o elemento que tenho em mãos e chamar
essa função:

```java
public Stream<T> filter(Predicate<T> filter) {
    return new Stream<>(() -> new Iterator<>() {

        private final Iterator<T> innerIterator;
        private boolean _hasNext;
        private T _next;
        
        {
            this.innerIterator = it.iterator();
            magicFunction();
        }

        @Override
        public boolean hasNext() {
            return _hasNext;
        }

        @Override
        public T next() {
            final T returnedValue = _next;
            magicFunction();
            return returnedValue;
        }

        private void magicFunction() {
            // ...
        }
    });
}
```

Ok, parece ser bom o suficiente. Então, para o algoritmo! Eu só posso continuar
iterando enquanto eu tenho um próximo elemento. Se eu achar um elemento que
passe no filtro, eu salvo o elemento e paro a iteração. Se eu chegar no final
da iteração, preciso apenas marcar que não tem próximo e finalizar.

```java
private void magicFunction() {
    while (innerIterator.hasNext()) {
        final T element = innerIterator.next();
        if (filter.test(element)) {
            // o primeiro que encontra que satisfaz a condição para o laço
            _next = element;
            _hasNext = true;
            return;
        }
    }
    _next = null; // apenas para marcar que não tem
    _hasNext = false;
}
```

Vamos testar? Vamos pegar uma lista e filtrar apenas os pares:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
s.filter(i -> i%2 == 0).forEach(System.out::println);
```

Como esperado:

```txt
2
4
6
```

## peek

Nada de segredo aqui: o `peek` permite interceptar um elemento no meio do
pipeline de streaming sem alterar o elemento em si. Portanto, pode ser usado
para simplesmente gerar um efeito colateral.

Vai ser bem parecido com o `map`, porém aqui não há intenção de mapear o valor,
apenas de realizar um efeito colateral com ele:

```java
public Stream<T> peek(Consumer<T> action) {
    return new Stream<>(() -> new Iterator<>() {

        private final Iterator<T> innerIterator;
        
        {
            this.innerIterator = it.iterator();
        }

        @Override
        public boolean hasNext() {
            return innerIterator.hasNext();
        }

        @Override
        public T next() {
            final T el = innerIterator.next();
            action.accept(el);
            return el;
        }
    });
}
```

Usando aqui para verificar se de fato a stream está passando por todos os
elementos antes do filtro ser aplicado, acumulando em uma lista, apenas como um
exemplo bem artificial do que se pode fazer com o `peek`:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
final ArrayList<Integer> l = new ArrayList<>();
s.peek(i -> System.out.println(stringify(i))).filter(i -> i%2 == 0).forEach(l::add);
System.out.println(l);
```

Saída:

```txt
um
dois
tres
quatro
cinco
seis
[2, 4, 6]
```

Se for por em contraste a estratégia do `filter` colocando o `peek`, pode-se
observar que a estragégia do pipeline do Java padrão é diferente da estratégia
que usei aqui. Aqui eu procuro sempre responder o `hasNext` e ter isso
carregado, já no stream padrão do Java ele de fato é completamente lazy. Isso
foi uma escolha de design razoável para o local de aplicação.

## limit

Agora precisamos permitir que apenas uma pequena quantidade de elementos seja
passada. Aqui, se por acaso a quantidade de elementos resgatados ultrapassar um
valor, preciso barrar e falar "já deu", mesmo que eventualmente tenha mais
coisas para se tratar.

Basicamente, cada `next` vai remover um do "pool" que posso remover. Se chegar
no final do iterável antes desse "pool", chegou, fim. Caso contrário, o "pool"
indica que a coisa já deu, e que não tem mais nada:

```java
public Stream<T> limit(long maxSize) {
    return new Stream<>(() -> new Iterator<>() {

        private final Iterator<T> innerIterator;
        private long remaining = maxSize;
        
        {
            this.innerIterator = it.iterator();
        }

        @Override
        public boolean hasNext() {
            return remaining > 0 && innerIterator.hasNext();
        }

        @Override
        public T next() {
            if (remaining <= 0) {
                throw new NoSuchElementException("End of stream: read more than " + maxSize + " elements");
            }
            remaining--;
            return innerIterator.next();
        }
    });
}
```

Vamos testar? `limit(3)` na lista de 6 inteiros:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
s.limit(3).forEach(System.out::println);
```

E funcionou perfeitamente!

```txt
1
2
3
```

Testado para `limit(15)` também, sem surpresa alguma: deixou passar todos os
elementos.

## skip

Bem, ao contrário do `limit` que, digamos, deixava o iterador rodar até o
final, aqui bem dizer precisamos ser _eager_ e já pular esses elementos. Aqui
podemos deixar pra fazer isso em um processo de inicialização a ser chamado
seja no `hasNext` ou no `next`, não precisa ser no construtor (apesar de que
também é viável assim):

```java
public Stream<T> skip(long n) {
    return new Stream<>(() -> new Iterator<>() {

        private final Iterator<T> innerIterator;
        private boolean initialized = false;
        
        {
            this.innerIterator = it.iterator();
        }

        @Override
        public boolean hasNext() {
            init();
            return innerIterator.hasNext();
        }

        @Override
        public T next() {
            init();
            return innerIterator.next();
        }

        private void init() {
            if (initialized) {
                return;
            }
            initialized = true;
            for (long i = 0; i < n; i++) {
                if (!innerIterator.hasNext()) {
                    return;
                }
                innerIterator.next();
            }
        }
    });
}
```

O mesmo teste feito para `limit`, `skip(3)`:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
s.skip(3).forEach(System.out::println);
```

Impresso conforme esperado:

```java
4
5
6
```

Funcionou perfeitamente bem para números além da quantidade de elementos
também.

## flatMap

O `flatMap` é um dos mais delícias de fazer! Porque agora um elemento pode se
transformar em múltiplos!

Então, como resolver? Bem, eu posso chegar lá, pegar a stream retornada e, como
é um objeto do meu tipo, acessar o campo privado dela e resgatar um `Iterator`
adequado e iterar em cima dele! Bonito? Não, mas dá conta do recado!

Primeiro passo: garantir que eu tenho um `interator` do outro tipo disponível.
Isso é literalmente o primeiro passo e não deve se repetir nunca!

```java
public <R> Stream<R> flatMap(Function<T, Stream<R>> mapper) {
    return new Stream<>(() -> new Iterator<>() {

        private final Iterator<T> innerIterator;
        private Iterator<R> otherTypeIterator = null;

        {
            this.innerIterator = it.iterator();
        }
        
        @Override
        public boolean hasNext() {
            fetchNext();
            return false; // placeholder
        }

        @Override
        public R next() {
            fetchNext();
            return null; // placeholder
        }
        
        private void fetchNext() {
            if (otherTypeIterator == null) {
                // primeira vez
                if (innerIterator.hasNext()) {
                    final T el = innerIterator.next();
                    final Stream<R> intermediateStream = mapper.apply(el);
                    otherTypeIterator = intermediateStream.it.iterator();
                }
            }
            // continuar processo
        }
    });
}
```

Próximo passo? Agora que eu tenho garantidamente o iterador do outro tipo, o
que fazer com ele?

Hmmm, mas e o caso do `else` se não tiver elementos no `innterIterator`? Bem,
aqui é de certo modo "fácil": crio um iterador vazio e deixo seguir como se
fosse o caso anterior:

```java
private void fetchNext() {
    if (otherTypeIterator == null) {
        // primeira vez
        if (innerIterator.hasNext()) {
            final T el = innerIterator.next();
            final Stream<R> intermediateStream = mapper.apply(el);
            otherTypeIterator = intermediateStream.it.iterator();
        } else {
            otherTypeIterator = new Iterator<>() {
                @Override
                public boolean hasNext() {
                    return false;
                }

                @Override
                public R next() {
                    throw new NoSuchElementException("No element");
                }
            };
        }
    }
    // continuar processo
}
```

Ok, agora eu tenho certeza do `otherTypeIterator`. Bem, se ele tiver um
elemento, eu pego esse elemento. Aqui vou usar uma estratégia similar a o que
usei no `filter`, com o `_hasNext` e com o `_next`:

```java
private void fetchNext() {
    if (otherTypeIterator == null) {
        // primeira vez
        if (innerIterator.hasNext()) {
            final T el = innerIterator.next();
            final Stream<R> intermediateStream = mapper.apply(el);
            otherTypeIterator = intermediateStream.it.iterator();
        } else {
            otherTypeIterator = new Iterator<>() {
                @Override
                public boolean hasNext() {
                    return false;
                }

                @Override
                public R next() {
                    throw new NoSuchElementException("No element");
                }
            };
        }
    }
    // continuar processo
    if (otherTypeIterator.hasNext()) {
        _hasNext = true;
        _next = otherTypeIterator.next();
        return;
    }
}
```

Parece bom? Bem, é um passo. Mas talvez ele não tenha mais elementos, portanto
preciso iterar no `innerIterator`. Basicamente essa iteração vai ser até
esgotar tudo, um laço infinito: dou um fetch do próximo iterador e, se ele for
vazio, sigo no laço; caso de não ter mais nada nem no `otherTypeIterator` nem
no `innerIterator`, paro ali indicando que não tem mais nada:

```java
private void fetchNext() {
    if (otherTypeIterator == null) {
        // primeira vez
        if (innerIterator.hasNext()) {
            final T el = innerIterator.next();
            final Stream<R> intermediateStream = mapper.apply(el);
            otherTypeIterator = intermediateStream.it.iterator();
        } else {
            otherTypeIterator = new Iterator<>() {
                @Override
                public boolean hasNext() {
                    return false;
                }

                @Override
                public R next() {
                    throw new NoSuchElementException("No element");
                }
            };
        }
    }
    // continuar processo
    while (true) {
        if (otherTypeIterator.hasNext()) {
            _hasNext = true;
            _next = otherTypeIterator.next();
            return;
        } else if (innerIterator.hasNext()) {
            final T el = innerIterator.next();
            final Stream<R> intermediateStream = mapper.apply(el);
            otherTypeIterator = intermediateStream.it.iterator();
        } else {
            _next = null; // apenas para marcar que não tem
            _hasNext = false;
            return;
        }
    }
}
```

Hmmm, podemos melhorar essa conversa de extrair o `otherTypeIterator`!

```java
private void fetchNext() {
    if (otherTypeIterator == null) {
        // primeira vez
        if (innerIterator.hasNext()) {
            otherTypeIterator = getOtherTypeIterator(innerIterator.next());
        } else {
            otherTypeIterator = new Iterator<>() {
                @Override
                public boolean hasNext() {
                    return false;
                }

                @Override
                public R next() {
                    throw new NoSuchElementException("No element");
                }
            };
        }
    }
    while (true) {
        if (otherTypeIterator.hasNext()) {
            _hasNext = true;
            _next = otherTypeIterator.next();
            return;
        } else if (innerIterator.hasNext()) {
            otherTypeIterator = getOtherTypeIterator(innerIterator.next());
        } else {
            _next = null; // apenas para marcar que não tem
            _hasNext = false;
            return;
        }
    }
}

private Iterator<R> getOtherTypeIterator(T el) {
    final Stream<R> intermediateStream = mapper.apply(el);
    return intermediateStream.it.iterator();
}
```

Ok! Agora, bem... o `hasNext` deve ser seguro de se chamar múltiplas vezes. Em
tese eu posso fazer `it.hasNext(); it.hasNext();` como se fosse igual a
`it.hasNext()` sem maiores consequências. Portanto, eu não posso chamar
`fetchNext` toda vida ao bater no `hasNext`! Preciso só chamar caso não tenha
sido ainda inicializado! Vamos refazer ele:

```java
@Override
public boolean hasNext() {
    if (otherTypeIterator == null) {
        fetchNext();
    }
    return _hasNext;
}
```

Ok, parece justo agora. E quanto ao `next`? Bem, lembra do `filter`? Ele faz
algo bem semelhante, podemos beber da ideia! E também garantir a inicialização
que nem no `hasNext`!

```java
@Override
public R next() {
    if (otherTypeIterator == null) {
        fetchNext();
    }
    final R r = _next;
    fetchNext();
    return r;
}
```

Vamos testar? Dado um número, o mapeamento vai ser todos os inteiros menores do
que ele em ordem crescente:

```java
static Stream<Integer> positivosMenoresCrescente(int n) {
    ArrayList<Integer> acc = new ArrayList<>();
    for (int i = 1; i < n; i++) {
        acc.add(i);
    }
    return new Stream<>(acc);
}
```

E o teste?

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
s.flatMap(i -> positivosMenoresCrescente(i)).forEach(System.out::println);
```

Com o resultado esperado:

```none
1
1
2
1
2
3
1
2
3
4
1
2
3
4
5
```

## distinct

Podemos fazer isso aqui como uma abstração acima do `filter`. Se o elemento for
novo em um `HashSet` do tipo apropriado, deixa passar!

```java
public Stream<T> distinct() {
    HashSet<T> x = new HashSet<>();
    return filter(x::add);
}
```

Para o teste? Bem, vamos usar o `flatMap` anterior, junto com o `distinct`:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
s.flatMap(i -> positivosMenoresCrescente(i))
    .distinct()
    .forEach(System.out::println);
```

Resultado conforme esperado:

```none
1
2
3
4
5
```

Streams do java utilizam flags para indicar se estão ordenadas, entre outras
coisas, que permitiriam muita otimização. Aqui, por simplicidade, não farei
isso. Vai ser do modo comum, sem otimização alguma.

## sorted

Aqui... bem, aqui vou precisar consumir completamente a stream que veio, e
então aplicar a ordenação. Existem dois sabores de `sorted`: o que recebe o
comparador, e o que assume ser ordenação natural. Vamos primeiro lidar com o
`sorted` que recebe o comparador.

Primeiro, vamos juntar todos os elementos:

```java
public Stream<T> sorted(Comparator<T> comparator) {
    ArrayList<T> list = new ArrayList<>();
    for (T el: it) {
        list.add(el);
    }
    return this; // placeholder
}
```

Ok, e agora? Agora, vamos ordenar a lista acumulada e retornar o stream sobre
ela:

```java
public Stream<T> sorted(Comparator<T> comparator) {
    ArrayList<T> list = new ArrayList<>();
    for (T el: it) {
        list.add(el);
    }
    list.sort(comparator);
    return new Stream<>(list);
}
```

E quanto ao `sorted` que usa ordem natural? Bem, esse eu vou... fazer uma
gambiarra mesmo 🤷‍♂️ Vou fazer um cast e pronto:

```java
public Stream<T> sorted() {
    return sorted((Comparator<T>) Comparator.naturalOrder());
}
```

Vamos testar?

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
s.map(i -> stringify(i))
    .sorted()
    .forEach(System.out::println);
```

Isso já testa ao mesmo tempo se o `sorted` por ordenação natural funciona e se
também se o `sorted` passando um comparador explícito funciona. E o resultado?

```txt
cinco
dois
quatro
seis
tres
um
```

Perfeito! Agora, vamos ver se ele aceita algo que não seja um `Comparable`?
Vamos criar um `Wrapper` bem tosquinho?


```java
static class Wrapper {
    final String s; 
    Wrapper(String s) {
        this.s = s;
    }

    @Override
    public String toString() {
        return "[wrapping <" + s + ">]";
    }
}
```

E o código em si:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
s.map(i -> stringify(i))
    .map(Wrapper::new)
    .sorted()
    .forEach(System.out::println);
```

Com resultado:

```none
Exception in thread "main" java.lang.ClassCastException: class com.jeffque.Main$Wrapper cannot be cast to class java.lang.Comparable
```

Agora, para corrigir isso? Transformar o `Wrapper` em um `Comparable<Wrapper>`:

```java
static class Wrapper implements Comparable<Wrapper> {
    final String s; 
    Wrapper(String s) {
        this.s = s;
    }

    @Override
    public String toString() {
        return "[wrapping <" + s + ">]";
    }

    @Override
    public int compareTo(Wrapper o) {
        return this.s.compareTo(o.s);
    }
}
```

Sem mudanças em como o `stream` é testado:

```none
[wrapping <cinco>]
[wrapping <dois>]
[wrapping <quatro>]
[wrapping <seis>]
[wrapping <tres>]
[wrapping <um>]
```

E se eu não quiser agora passar um `Comparator` explícito?

```java
static class Wrapper {
    final String s; 
    Wrapper(String s) {
        this.s = s;
    }

    @Override
    public String toString() {
        return "[wrapping <" + s + ">]";
    }

    public int aaaa(Wrapper o) {
        return this.s.compareTo(o.s);
    }
}

final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
s.map(i -> stringify(i))
    .map(Wrapper::new)
    .sorted(Wrapper::aaaa)
    .forEach(System.out::println);
```

## count

Para essa operação final, vamos só esgotar a quantidade de elementos do
iterador, estilo o que fizemos no `sorted`:

```java
public long count() {
    long acc = 0;
    for (T el: it) {
        acc++;
    }
    return acc;
}
```

Experimentos? Vamos imprimir o total e para o caso com filtro de apenas números
pares:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
System.out.println(s.count());

// ...

final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
System.out.println(s.filter(i -> i % 2 == 0).count());
```

E a impressão deu conforme o esperado:

```none
6
3
```

## min e max

Aqui temos praticamente a mesma implementação. Vamos primeiramente verificar se
está vazio. Estando vazio, retornamos `Optional.empty()` (ah, sim, teremos uma
seção dedicada a sua implementação).

Então, caso contrário, peguemos o primeiro elemento, e depois esgotamos a
stream, sempre comparando com o menor obtido até então:

```java
public Optional<T> min(Comparator<T> comparator) {
    final Iterator<T> iterator = it.iterator();
    if (!iterator.hasNext()) {
        return Optional.empty();
    }
    T minimumElement = iterator.next();
    while (iterator.hasNext()) {
        final T el = iterator.next();
        // se o menor elemento _até agora_ for maior que o elemento sendo
        // inspecionado, atuliza o menor elemento encontrado
        if (comparator.compare(minimumElement, el) > 0) {
            minimumElement = el;
        }
    }
    return Optional.of(minimumElement);
}
```

De modo semelhante, temos o `max`:

```java
public Optional<T> max(Comparator<T> comparator) {
    final Iterator<T> iterator = it.iterator();
    if (!iterator.hasNext()) {
        return Optional.empty();
    }
    T maximumElement = iterator.next();
    while (iterator.hasNext()) {
        final T el = iterator.next();
        // se o maior elemento _até agora_ for menor que o elemento sendo
        // inspecionado, atuliza o maior elemento encontrado
        if (comparator.compare(maximumElement, el) < 0) {
            maximumElement = el;
        }
    }
    return Optional.of(maximumElement);
}
```

Para testar? Usemos o `Integer::compareTo`:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
System.out.println(s.min(Integer::compareTo));
// Optional[1]
```

max?

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
System.out.println(s.max(Integer::compareTo));
// Optional[6]
```

Se quiser também podemos pegar a subtração dos números como `Comparator`:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
System.out.println(s.min((a, b) -> a - b));
// Optional[1]
```

## findFirst e findAny

O `findFirst`, bem dizer, é só ver se tem algo, retornando esse algo:

```java
public Optional<T> findFirst() {
    final Iterator<T> iterator = it.iterator();
    if (!iterator.hasNext()) {
        return Optional.empty();
    }
    return Optional.of(iterator.next());
}
```

O comportamento padrão do Java é não permitir nulos no `findFirst`, por isso
mantive o `Optional.of`.

A ideia do `findAny` no Java era uma otimização para retornar qualquer elemento
que potencialmente pudesse existir na stream. Por exemplo, em um `TreeMap`, o
`findAny` não iria precisar rodar até encontrar o elemento relativo da menor
chave registrada, poderia simplesmente retornar o elemento associado à raiz.

Como aqui sempre vamos de um `iterator`, não precisamos _necessariamente_
otimizar. Então vou fazer o `findAny` simplesmente apontar pro `findFirst`:

```java
public Optional<T> findAny() {
    return findFirst();
}
```

A ideia dessas streams é permitir uma melhor experiência programando, não
suprir com grande performance. Então essas coisas são aceitáveis, até porque
as streams daqui não são para ARTS (_almost real time systems_).

## anyMatch, allMatch, noneMatch

Todas aqui são estruturas que tem curto circuito com um teste. No caso do
`anyMatch`, o primeiro retorno positivo retorna `true`. No caso do `noneMatch`,
o primeiro retorno positivo retorna `false`. O `allMatch` retorna falso no
primeiro negativo que encontrar.

Esse tipo de operação permite fazer um `for-each`:

```java
public boolean anyMatch(Predicate<T> t) {
    for (final T el: it) {
        if (t.test(el)) {
            return true;
        }
    }
    return false;
}
```

O `noneMatch`?

```java
public boolean noneMatch(Predicate<T> t) {
    for (final T el: it) {
        if (t.test(el)) {
            return false;
        }
    }
    return true;
}
```

E finalmente, o `allMatch`:

```java
public boolean allMatch(Predicate<T> t) {
    for (final T el: it) {
        if (!t.test(el)) {
            return false;
        }
    }
    return true;
}
```

Para comparar, usemos pequenas variações de predicados:

- `i -> i > 5`: deve dar verdade para `anyMatch` apenas
- `i -> i > 7`: deve dar verdade para `noneMatch` apenas
- `i -> i > 0`: deve dar verdade para `allMatch` e `anyMatch`

## toArray

Aqui temos duas variantes: uma que vai retornar um `Object[]`, e outra que vai
gerar um `A[]` baseado em um `int`. Para construir o array, de toda sorte, vou
precisar juntar a stream inteira. O tipo `A` não precisa necessariamente estar
relacionado com o tipo `T`.

Bem, o `ArrayList` tem um método chamado `toArray` passando um array. Se não
tiver o tamanho adequado, ele gera um novo array com o tamanho certo; caso você
passe um array com o tamanho adequado (maior ou igual à quantidade de itens),
ele povoa o array com os elementos.

Então, bem, vamos usar primeiro o `int -> A[]`, e então depois o que gera o
`Object[]`.

Para testar, vamos usar o exemplo do `flatMap`, porém para deixar mais fácil
examinar o resultado usemos também o `sorted`:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
final Integer[] a = s.flatMap(i -> positivosMenoresCrescente(i)).sorted().toArray(Integer[]::new);
System.out.println(a.getClass());
for (final int i: a) {
    System.out.println(i);
}
```

Como a ideia é acumular em um `ArrayList` e depois passar para o array recém
criado com o tamanho certo, vamos iterar e acumular:

```java
public <A> A[] toArray(IntFunction<A[]> arrayBuilder) {
    ArrayList<T> arr = new ArrayList<>();
    for (final T el: it) {
        arr.add(el);
    }
    return arr.toArray(arrayBuilder.apply(arr.size()));
}
```

A saída:

```none
class [Ljava.lang.Integer;
1
1
1
1
1
2
2
2
2
3
3
3
4
4
5
```

Conforme esperado.

Agora, para o `toArray` sem especificar a função que cria o array? Bem, vamos
aqui simplesmente passar um `Object[]::new` para retornar o array, e assim
deixamos a carga pesada toda em um único ponto:

```java
public Object[] toArray() {
    return toArray(Object[]::new);
}
```

## forEachOrdered

Aqui é só para garantir o processamento dos itens de acordo com o que eles são
produzidos na stream. Isso é útil quando temos processamento em paralelo ou
fora da ordem. Mas para o nosso caso já processamos na ordem de geração.

Aqui, o `forEachOrdered` é apenas um wrapper para o `forEach`:

```java
public void forEachOrdered(Consumer<T> action) {
    forEach(action);
}
```

## reduce

O `reduce` aqui vem em 3 sabores:

- o que não se conhece a identidade (retorna um `Optional<T>`)
- o que se conhece o elemento neutro e se acumula nele (retorna um `T`)
- o que se conhece o elemento neutro, e se combina ele com o próximo elemento
  de modo arbitrário, e eventualmente se unem os elementos combinados (retorna
  um `U`)

Aqui vou tratar o primeiro sabor como algo a parte, e o segundo sabor como um
sabor especial do terceiro: se o elemento neutro é do tipo do resultado de sua
combinação com o tipo novo, então podemos usar essa mesma função para combinar
esses elementos acumulados também.

Para teste, vamos usar dois tipos de acumulações distintas: a primeira vai ser
mantendo o mesmo tipo (no caso, vamos pra multiplicação), e pro segundo caso
vamos para uma mudança de tipo brusca: vamos juntar em uma lista minha, uma
variação do que foi usado em
[Usando Java moderno para fazer aritmética de Peano]({% post_url 2025/2025-03-10-peano-java-moderno %}),
porém com os limites de não poder usar `record` nem `sealed interface`.

Para os dois primeiros sabores, vai ser em cima do mesmo tipo, então vai ser
só o exemplo da soma. No terceiro sabor, vamos usar tanto a soma quanto o
acúmulo na lista.

Como o exemplo mais fácil é a soma, não vamos encrencar com outra coisa antes,
vamos fazer o `reduce` de um elemento logo:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
final Optional<Integer> sum = s.reduce((a, b) -> a + b);
System.out.println(sum);
// Optional[21]
```

Vou seguir aqui o mesmo esquema usado no `min`:

```java
public Optional<T> reduce(BinaryOperator<T> acc) {
    final Iterator<T> iterator = it.iterator();
    if (!iterator.hasNext()) {
        return Optional.empty();
    }
    T r = iterator.next();
    while (iterator.hasNext()) {
        final T el = iterator.next();
        r = acc.apply(r, el);
    }
    return Optional.of(r);
}
```

Ok, e agora para o outro sabor da soma, passando o elemento neutro? O `reduce`
vai passar para o `reduce` com o combinador o mesmo elemento passado como
acumulador:

```java
public T reduce(T identity, BinaryOperator<T> acc) {
    return reduce(identity, acc, acc);
}
```

E para o terceiro sabor? Bem, primeiro temos a identidade. Tendo a identidade,
cada elemento novo recebido podemos acumular na identidade e ser feliz:

```java
public <U> U reduce(U identity, BiFunction<U, T, U> acc, BinaryOperator<U> comb) {
    U r = identity;
    for (final T el: it) {
        r = acc.apply(r, el);
    }
    return r;
}
```

O teste é bem similar, só precisa por o elemento neutro:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
final int sum = s.reduce(0, (a, b) -> a + b);
System.out.println(sum);
// 21
```

Para o teste com o combinador da soma? É literalmente repetir o acumulador, só
por uma questão de completude:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
final int sum = s.reduce(0, (a, b) -> a + b, (a, b) -> a + b);
System.out.println(sum);
// 21
```

Muito bem, e para a questão do acumulador que usa a lista própria? Bem, vamos
criar nosso próprio elemento de lista, o `List`:

```java
public class List<T> {
    public final T head;
    public final List<T> tail;

    public List(T element) {
        this.head = element;
        this.tail = empty();
    }

    public List(T head, List<T> tail) {
        this.head = head;
        this.tail = tail;
    }

    static class EOL<T> extends List<T> {
        EOL() {
            super(null, null);
        }

        @Override
        public boolean end() {
            return true;
        }

        @Override
        public String toString() {
            return "[]";
        }

        private static final EOL<Object> SingletonEOL = new EOL<>();
    }

    public boolean end() {
        return false;
    }

    public static <T> List<T> empty() {
        return (List<T>) EOL.SingletonEOL;
    }

    @Override
    public String toString() {
        return "[" + toStringSansBrackets() + "]";
    }

    private String toStringSansBrackets() {
        if (tail.end()) {
            return "" + this.head;
        }
        return head + "," + tail.toStringSansBrackets();
    }
}
```

Aqui demos que necessariamente não iremos incorrer em ciclos porque os campos
são todos `final`, então eu preciso passar para frente um `List` já devidamente
criado e povoado (não posso referenciar ele e sobrescrever algum campo dele).
Bem, se não fizerem reflexão profunda para lascar essa condição, estamos bem! E
não vou entrar nessas neuras aqui.

Para exemplificar, fiz alguns experimentos:

```java
System.out.println(new List<String>("456", new List<String>("123", empty())));
// [456,123]
System.out.println(new List<String>("123", empty()));
// [123]
System.out.println(empty());
// []
```

Ok, parece razoável o como ele imprime. Vamos para o exemplo, a gente inicia
com a lista vazia e vai adicionando elementos como `head` dela:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
final List<Integer> l = s.reduce(List.empty(), (acc, el) -> new List<>(el, acc), /* ??? */);
System.out.println(l);
```

> Vamos passar um placeholder válido, não importa exatamente qual agora, ok?

E, bem, o resultado esperado:

```
[6,5,4,3,2,1]
```

Para fazer o combinador, vamos precisar mecher fortemente nessa função de
concatenação. Vamos esgotar os elementos, para obter a resposta e remontar?

```java
List<T> concat(List<T> first, List<T> second) {
    if (first.end()) {
        return second;
    }
    final T head = first.head;
    return new List<>(head, concat(first.tail, second));
}
```

Bem, para testar, vamos ver:

```java
System.out.println(concat(new List<>(123, new List<>(0)), new List<>(456, new List<>(789))));
// [123,0,456,789]
```

Para fazer o combiner adequado:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
final List<Integer> l = s.reduce(
                                    List.empty(),
                                    (acc, el) -> new List<>(el, acc),
                                    (a, b) -> concat(a, b)
                                );
System.out.println(l);
```

## collect

Bem, aqui vamos passar para um coletor, o grosso da implementação está em
`Collector`, que vai ser mostrado com carinho. Aqui vamos apenas passar pro
coletor. Como não está sendo usado paralelismo, o `combiner` não vai na prática
ser executado.

Mas vamos garantir que o `combiner` funcione! Existem dois sabores para o
`collect`, um que passa o `Collector` e outro que passa os elementos lembram
bastante um `Collector`:

Argumentos de collect:
- `Supplier<A> supplier`
- `BiConsumer<T, A> acc`
- `BiConsumer<T, T> combiner`

Partes do `Collector`:
- `Supplier<A> supplier`
- `BiConsumer<T, A> acc`
- `BinaryOperator<T> combiner`

Na descrição do terceiro argumento da função `collect`:

> The combiner function must fold the elements from the second result container
> into the first result container.

Ou seja, posso transformar o `BiConsumer` em um `BinaryOperator` se eu retornar
o primeiro elemento!

```java
<T> BinaryOperator<T> toOperator(BiConsumer<T, T> consumer) {
    return (first, second) -> {
        consumer.accept(first, second);
        return first;
    };
}
```

Diferente da implementação padrão Java, o `of` vou colocar dentro do
`Collectors` para continuar fazendo jus a não tem métodos estáticos/default em
interfaces que eu estou aqui implementando, mantendo o `Collector` como uma
interface. Então vou delegar aqui o funcionamento completo do `collect` com as
3 funções para quando o `Collectors` estiver completo.

A implementação seria algo assim:

```java
private static <T> BinaryOperator<T> toOperator(BiConsumer<T, T> consumer) {
    return (first, second) -> {
        consumer.accept(first, second);
        return first;
    };
}

public <R> R collect(Supplier<R> supplier, BiConsumer<R, T> acc, BiConsumer<R, R> combiner) {
    return collect(Collectors.of(supplier, acc, toOperator(combiner)));
}
```

Então, com esse _caveat_ em mãos, vamos implementar o `collect` em que se passa
o `Collector`? No momento, irei abstrair o funcionamento do `Collector` (ie,
simularei com o do Java).

Para começar, o `Collector` é um genérico do Java que tem 3 tipos:

- `T`: o elemento que chega e é processado
- `R`: o elemento de retorno
- `A`: o elemento de acumulação, que em muitos casos vem com `?` porque não
  importa pro chamador

Então, a primeira coisa a se fazer é obter um elemento de acumulação. Em
seguida, precisamos seguir acumulando os elementos. Finalmente, transformamos o
resultado acumulado usando um `finisher`:

```java
public <A, R> R collect(Collector<T, A, R> collector) {
    A a = collector.supplier().get();
    final BiConsumer<A, T> acc = collector.accumulator();
    for (final T el: it) {
        acc.accept(a, el);
    }
    return collector.finisher().apply(a);
}
```

Pegando aqui o coletor `summingInt`:

```java
final Stream<Integer> s = new Stream<>(List.of(1, 2, 3, 4, 5, 6));
final int l = s.collect(Collectors.summingInt(i -> i));
System.out.println(l);
// 21
```

De modo geral, é isso. Agora só precisaremos da implementação dos coletores na
seção adequada.

## empty

Retorna um iterador vazio: que não tem `hasNext`, e coloca como `Stream`:

```java
public static <T> Stream<T> empty() {
    return new Stream<>(() -> new Iterator<>() {

        @Override
        public boolean hasNext() {
            return false;
        }

        @Override
        public T next() {
            return null;
        }
    });
}
```

## of

Aqui vem em dois sabores: o `of` unitário e o com varargs. O unitário é fazer
um iterator de apenas um único elemento. Já o com varargs, bem, pega até
esgotar o array mesmo:

```java
public static <T> Stream<T> of(T value) {
    return new Stream<>(() -> new Iterator<>() {
        boolean available = true;

        @Override
        public boolean hasNext() {
            return available;
        }

        @Override
        public T next() {
            available = false;
            return value;
        }
    });
}
```

O teste mais simples seria contar a quantidade de elementos, precisa ser
necessariamente 1:

```java
final Stream<String> s = Stream.of("valor");
final long l = s.count();
System.out.println(l);
// 1
```

Para a opção com varargs, é só manter o índice da posição de leitura:

```java
@SafeVarargs
public static <T> Stream<T> of(T ...values) {
    return new Stream<>(() -> new Iterator<>() {
        int idx = 0;

        @Override
        public boolean hasNext() {
            return idx < values.length;
        }

        @Override
        public T next() {
            final T el = values[idx];
            idx++;
            return el;
        }
    });
}
```

> Ah, sim, precisei anotar como `@SafeVarargs` porque tem cenários que usar
> varargs com genéricos causa problemas.

Para demonstração, vamos usar o `Collectors.summingInt`:

```java
final Stream<Integer> s = Stream.of(1, 2, 3, 4, 5, 6);
final int l = s.collect(Collectors.summingInt(i -> i));
System.out.println(l);
// 21
```

## concat

Existem algumas alternativas para isso. Uma delas é pegar um
`Stream<Stream<T>>` e fazer um `flatMap`:

```java
public static <T> Stream<T> concat(Stream<T> a, Stream<T> b) {
    return Stream.of(a, b).flatMap(s -> s);
}
```

Para testar, que tal usar o `summingInt` da mesma `Stream.of` duas vezes? Isso
significa que o resultado esperado seria 42:

```java
final Stream<Integer> s = Stream.concat(Stream.of(1, 2, 3, 4, 5, 6), Stream.of(1, 2, 3, 4, 5, 6));
final int l = s.collect(Collectors.summingInt(i -> i));
System.out.println(l);
// 42
```

Uma implementação mais direta disso seria um caso específico da implementação
usada em `flatMap`: eu pego o iterador da primeira stream, levo até o fim.
Quando chegar no fim, troco para o iterador da segunda stream e vou até o fim,
aí acaba.

Aqui, diferente do `flatMap`, vou precisar me preocupar novamente com streams
esgotadas ao começar. Vou adicionar variantes do teste:

- 2 streams cheias (igual o teste anterior)
- primeira stream vazia
- segunda stream vazia
- ambas streams vazias

```java
final Supplier<Stream<Integer>> stream1to6 = () -> Stream.of(1, 2, 3, 4, 5, 6);
final Stream<Integer> cheios = Stream.concat(stream1to6.get(), stream1to6.get());
final Stream<Integer> primeiroVazio = Stream.concat(Stream.empty(), stream1to6.get());
final Stream<Integer> segundoVazio = Stream.concat(stream1to6.get(), Stream.empty());
final Stream<Integer> vazios = Stream.concat(Stream.empty(), Stream.empty());

final int soma_cheios = cheios.collect(Collectors.summingInt(i -> i));
System.out.println(soma_cheios);
// 42

final int soma_primeiroVazio = primeiroVazio.collect(Collectors.summingInt(i -> i));
System.out.println(soma_primeiroVazio);
// 21

final int soma_segundoVazio = segundoVazio.collect(Collectors.summingInt(i -> i));
System.out.println(soma_segundoVazio);
// 21

final int soma_vazios = vazios.collect(Collectors.summingInt(i -> i));
System.out.println(soma_vazios);
// 0
```

Para eu começar usando o primeiro iterador, ele precisa ter um elemento pelo
menos. A cada `next` eu verifico se estou usando o primeiro iterador e, se eu
estiver usando ele, se ele está vazio; se for esse o caso, então eu marco que
não uso mais o primeiro iterador.

```java
public static <T> Stream<T> concat(Stream<T> a, Stream<T> b) {
    return new Stream<>(() -> new Iterator<T>() {
        private final Iterator<T> first = a.it.iterator();
        private final Iterator<T> second = b.it.iterator();

        private boolean useFirst = first.hasNext();

        private Iterator<T> getUsedIterator() {
            return useFirst? first: second;
        }
        
        @Override
        public boolean hasNext() {
            return getUsedIterator().hasNext();
        }

        @Override
        public T next() {
            final T v = getUsedIterator().next();
            
            if (useFirst && !first.hasNext()) {
                useFirst = false;
            }
            
            return v;
        }
    });
}
```

## iterate

Surgiu no Java 9 a versão do
`iterate(T seed, Predicate<T> hasNext, UnaryOperator<T> next)`, mas vou puxar
ele para cá como caso geral do
`iterate(T seed, UnaryOperator<T> next)`, que existe no Java 8. A ideia do
sabor com `hasNext` é identificar quando precisa parar a geração de elementos.
Ou seja: a versão geral precisa ser limitada de alguma maneira (normalmente com
`limit`, ou nas APIs posteriores com `takeWhile`).

Assumindo a existência do sabor com `hasNext`, o `iterate` de dois elementos
pode simplesmente passar um predicado tautologicamente verdade:

```java
public static <T> Stream<T> iterate(T seed, UnaryOperator<T> next) {
    return iterate(seed, t -> true, next);
}
```

O funcionamento com 3 sabores é o seguinte: ele pega o elemento corrente, se
passar no crivo do `hasNext`, retorna ele e atualiza o elemento corrente:

```java
public static <T> Stream<T> iterate(T seed, Predicate<T> hasNext, UnaryOperator<T> next) {
    return new Stream<>(() -> new Iterator<>() {
        T curr = seed;

        @Override
        public boolean hasNext() {
            return hasNext.test(curr);
        }

        @Override
        public T next() {
            final T r = curr;
            curr = next.apply(r);
            return r;
        }
    });
}
```

Para testar, vamos gerar a soma de todos os elementos de 0 até um `n`
especificado? Vamos testar para com `n = 6` (esperado 21) e com `n = 10`
(esperado 55):

```java
final Stream<Integer> s = Stream.iterate(0, i -> i <= n, i -> i+1);
final int l = s.collect(Collectors.summingInt(i -> i));
System.out.println(l);
```

## generate

Bem, esse cara gera uma lista infinita. Basicamente, sempre posso criar um novo
objeto chamando `get`:

```java
public static <T> Stream<T> generate(Supplier<T> s) {
    return new Stream<>(() -> new Iterator<>() {
        @Override
        public boolean hasNext() {
            return true;
        }

        @Override
        public T next() {
            return s.get();
        }
    });
}
```

Para testar, vou fazer a soma dos primeiros 6 elementos, gerando como entrada
para 6 e com 10:

```java
final Stream<Integer> s = Stream.generate(() -> n).limit(6);
final int l = s.collect(Collectors.summingInt(i -> i));
System.out.println(l);
```

E isso retornou os valores esperados de 36 e 60.

## builder

O método `builder` retorna um `Stream.Builder` (interface). Não preciso me ater
a manter isso mas... por que não, né?

Mantendo a mesma estrutura do `Stream.Builder`, preciso definir ele como uma
interface derivada de `Consumer`. A documentação diz que é mutável (até porque
o método do `Consumer` retorna `void`, né?, aí não dá pra fazer sem
_side-effects_). Então, vamos lá:


```java
public interface Builder<T> extends Consumer<T> {
    Builder<T> add(T t);
    Stream<T> build();
}
```

Bom começo. Estou evitando usar os `default` devido a questão do retrolambda,
então deixei o `add` como método aberto mesmo. Agora, vamos ver uma
implementação pra isso?

```java
private static class ArrayBuilder<T> implements Builder<T> {

    private final ArrayList<T> l = new ArrayList<>();

    @Override
    public Builder<T> add(T t) {
        accept(t);
        return this;
    }

    @Override
    public void accept(T t) {
        l.add(t);
    }


    @Override
    public Stream<T> build() {
        return new Stream<>(l);
    }
}
```

Aparentemente é isso, né? Agora, a doc diz que se tiver mudado o estado para
"built", precisa dar ruim caso sofra alguma outra alteração ou tente buildar de
novo. Então, vamos botar esses safeguards?

```java
private static class ArrayBuilder<T> implements Builder<T> {

    private final ArrayList<T> l = new ArrayList<>();
    private boolean built = false;

    @Override
    public Builder<T> add(T t) {
        accept(t);
        return this;
    }

    @Override
    public void accept(T t) {
        checkIfBuilt();
        l.add(t);
    }


    @Override
    public Stream<T> build() {
        checkIfBuilt();
        built = true;
        return new Stream<>(l);
    }
    
    private void checkIfBuilt() {
        if (built) {
            throw new IllegalStateException("já foi buildado");
        }
    }
}
```

E o `builder`?

```java
public static <T> Builder<T> builder() {
    return new ArrayBuilder<>();
}
```

# Implementação acessória: optional

Antes da parte mais interessante (os `Collectors`), vamos normalizar aqui a
questão do `Optional`? Eles foram usados no `findAny`, `findFirst`, `min` e
`max`, afinal. Como a API é a mesma, isso não foi levado em consideração antes,
mas de toda sorte é necessário.

Existem algumas estratégias para isso. Uma delas é usar subclasses,
`Optional.None` e `Optional.Just`. Outra é enfiar `if`s em todo método. Vamos
explorar ambos?

## Optional observando o próprio estado

Aqui, vamos fazer o `Optional` olhando para ele mesmo. Sem subclasses.

O construtor é privado:

```java
private Optional() {
    // aqui cria o optional vazio
    this.v = null;
}

private Optional(T value) {
    this.v = value;
}
```

Para não precisar ficar criando vazia a toda momento, vou pendurar um objeto
vazio e reutilizar ele:

```java
private static final Optional<Object> EMPTY = new Optional<>();

public static <T> Optional<T> empty() {
    return (Optional<T>) EMPTY;
}

public static <T> Optional<T> of(T v) {
    if (v == null) {
        throw new NullPointerException("aqui só aceita valor, sem nulos");
    }
    return new Optional<>(v);
}

public static <T> Optional<T> ofNullable(T v) {
    if (v == null) {
        return (Optional<T>) EMPTY;
    }
    return new Optional<>(v);
}
```

A implementação de `equals` e `hashCode` é direta ao assunto:

```java
@Override
public int hashCode() {
    return v == null? 0: v.hashCode();
}

@Override
public boolean equals(Object o) {
    if (!(o instanceof Optional)) { // isso já testa o nulo
        return false;
    }
    Optional<T> other = (Optional<T>) o;
    return areEquals(this.v, other.v);
}

// basicamente uma versão de Objects.equals, porém que eu não tenho acesso nesse runtime
private static boolean areEquals(Object a, Object b) {
    if (a == null) {
        return b == null;
    }
    return a.equals(b);
}
```

O `toString` não precisa seguir nenhuma convenção explícita, mas precisam ser
suficientemente distintos para não misturar:

```java
@Override
public String toString() {
    return v == null? "Empty[]": "Valued[" + v + "]";
}
```

O `map` retorna a aplicação da função no objeto. Como pode retornar nulo,
retorna com `ofNullable`. O `flatMap` eu não preciso cuidar do que é gerado, só
retornar diretamente:

```java
public <R> Optional<R> map(Function<T, R> mapper) {
    return v == null? (Optional<R>) this: Optional.ofNullable(mapper.apply(v));
}

public <R> Optional<R> flatMap(Function<T, Optional<R>> mapper) {
    return v == null? this: mapper.apply(v);
}
```

O filtro é interessante: se não passar no filtro, retorna `EMPTY`. E se tá nulo
já assumimos que não pasosu no filtro:

```java
public Optional<T> filter(Predicate<T> f) {
    return v == null || !f.test(v)? (Optional<T>) EMPTY : this;
}
```

O `isPresent` é direto ao assunto (semelhante ao `isEmpty` do Java 11):

```java
public boolean isPresent() {
    return v != null;
}

public boolean isEmpty() {
    return v == null;
}
```

Agora é só o consumidor de valores, como `ifPresent`, `orElse`, essas coisas (e
o quase trivial `get`):

```java
public void ifPresent(Consumer<T> r) {
    if (v != null) {
        r.accept(v);
    }
}

public T get() {
    if (v == null) {
        throw new NoSuchElementException("No value present");
    }
    return v;
}

public T orElse(T t) {
    return v == null? t: v;
}

public T orElseGet(Supplier<T> s) {
    return v == null? s.get(): v;
}

public <E extends Exception> T orElseThrow(Supplier<E> s) throws E {
    if (v != null) {
        return v;
    }
    throw s.get();
}
```

## Com subclasses

Aqui resolvemos tudo no polimorfismo. Temos as subclasses escondidas `Just` e
`None`. `Just` possui apenas um único campo (vou chamar de `v` para aproveitar
a implementação anterior) e `None` não tem campo algum, portanto podemos salvar
ele do mesmo modo que usamos o `EMPTY` anterior (agora morando em
`None.EMPTY`).

Sem muito segredo, boa parte do código foi simplesmente "resolver o branch" que
se estava da implementação anterior, com exceção do `filter` para quando se
tinha elemento:

```java
public abstract class Optional<T> {

    public static <T> Optional<T> empty() {
        return (Optional<T>) None.EMPTY;
    }

    public static <T> Optional<T> of(T v) {
        if (v == null) {
            throw new NullPointerException("aqui só aceita valor, sem nulos");
        }
        return new Just<>(v);
    }

    public static <T> Optional<T> ofNullable(T v) {
        if (v == null) {
            return (Optional<T>) None.EMPTY;
        }
        return new Just<>(v);
    }

    @Override
    public abstract int hashCode();
    @Override
    public abstract boolean equals(Object o);
    @Override
    public abstract String toString();

    public abstract <R> Optional<R> map(Function<T, R> mapper);
    public abstract <R> Optional<R> flatMap(Function<T, Optional<R>> mapper);
    public abstract Optional<T> filter(Predicate<T> f);
    public abstract boolean isPresent();
    public abstract boolean isEmpty();
    public abstract void ifPresent(Consumer<T> r);
    public abstract T get();
    public abstract T orElse(T t);
    public abstract T orElseGet(Supplier<T> s);
    public abstract <E extends Exception> T orElseThrow(Supplier<E> s) throws E;
    
    
    private static class Just<T> extends Optional<T> {

        private final T v;
        private Just(T v) {
            if (v == null) {
                throw new NullPointerException("aqui só aceita valor, sem nulos");
            }
            this.v = v;
        }


        @Override
        public int hashCode() {
            return v.hashCode();
        }

        @Override
        public boolean equals(Object o) {
            if (!(o instanceof Just)) { // isso já testa o nulo
                return false;
            }
            Just<T> other = (Just<T>) o;
            return this.v.equals(other.v);
        }

        @Override
        public String toString() {
            return "Valued[" + v + "]";
        }

        @Override
        public <R> Optional<R> map(Function<T, R> mapper) {
            return Optional.ofNullable(mapper.apply(v));
        }

        @Override
        public <R> Optional<R> flatMap(Function<T, Optional<R>> mapper) {
            return mapper.apply(v);
        }

        @Override
        public Optional<T> filter(Predicate<T> f) {
            return f.test(v)? this: (Optional<T>) None.EMPTY;
        }

        @Override
        public boolean isPresent() {
            return true;
        }

        @Override
        public boolean isEmpty() {
            return false;
        }

        @Override
        public void ifPresent(Consumer<T> r) {
            r.accept(v);
        }

        @Override
        public T get() {
            return v;
        }

        @Override
        public T orElse(T t) {
            return v;
        }

        @Override
        public T orElseGet(Supplier<T> s) {
            return v;
        }

        @Override
        public <E extends Exception> T orElseThrow(Supplier<E> s) throws E {
            return v;
        }
    }
    
    private static class None<T> extends Optional<T> {

        private static final None<Object> EMPTY = new None<>();

        @Override
        public int hashCode() {
            return 0;
        }

        @Override
        public boolean equals(Object o) {
            return o instanceof None;
        }

        @Override
        public String toString() {
            return "Empty[]";
        }

        @Override
        public <R> Optional<R> map(Function<T, R> mapper) {
            return (Optional<R>) this;
        }

        @Override
        public <R> Optional<R> flatMap(Function<T, Optional<R>> mapper) {
            return (Optional<R>) this;
        }

        @Override
        public Optional<T> filter(Predicate<T> f) {
            return this;
        }

        @Override
        public boolean isPresent() {
            return false;
        }

        @Override
        public boolean isEmpty() {
            return true;
        }

        @Override
        public void ifPresent(Consumer<T> r) {
        }

        @Override
        public T get() {
            throw new NoSuchElementException("No value present");
        }

        @Override
        public T orElse(T t) {
            return t;
        }

        @Override
        public T orElseGet(Supplier<T> s) {
            return s.get();
        }

        @Override
        public <E extends Exception> T orElseThrow(Supplier<E> s) throws E {
            throw s.get();
        }
    }
}
```

Muito bem, funcionalmente parece correto. Agora precisamos ter uma garantia que
nos era dado pelo `Optional`: o consumidor dessa lib não pode nem instanciar
diretamente nem tampouco fazer subclasse. Ou seja, mesmo que eu implementasse
todos os métodos, isso aqui na classe `Main` (onde moram os testes) deveria dar
erro de compilação:

```java
private static class X<T> extends Optional<T> {
    X() {
    }

    // ...
}
```

Mas, como eu consigo isso? Bem, meu primeiro experimento foi colocar construtor
privado vazio em `Optional`:

```java
public abstract class Optional<T> {

    private Optional() {
    }

    // ...
}
```

E, bem, isso manteve a compilação funcionando adequadamente dentro da mesma
unidade de compilação! Ufa... E, sim, para fora da unidade de compilação passou
a dar problema, com a mensagem de erro:

> There is no no-arg constructor available in 'Optional'

### Variações de subclasses?

Será que eu posso fazer essas implementações com a subclasse não sendo uma
_nested class_? Isto é, algo assim:

```java
public abstract class Optional<T> {
    private Optional() {
    }

    // ...
}

class None extends Optional<T> {
    // ?
}
```

E a resposta é não. Dá o mesmíssimo erro. Colocar duas classes no _root level_
é mais ou menos equivalente a ter separado em dois arquivos. Só que apenas uma
das classes pode ser pública (pela JLS apenas a que tem o mesmo nome do arquivo
que pode ser pública,
[JLS §7.6](https://docs.oracle.com/javase/specs/jls/se8/html/jls-7.html#jls-7.6)).

Para permitir esse tipo de implementação, eu precisaria deixar o nível de
acesso do construtor de `Optional` para `package private`. Ou seja: qualquer um
poderia ter uma classe no pacote `com.jeffque` (ou o nome de pacote escolhido)
e fazer uma subclasse. O que fere a intenção de proibir todo mundo de conseguir
fazer subclasse (lembrando que não tenho `sealed` aqui devido às restrições).

E com classe anônima? Bem, na real daria quase certo sim. Só teríamos problemas
no `equals`. E como se resolveria isso? Bem, vamos tentar?

Para simplificar, vou criar uma classe de experimento chamada de `Xp`. Tal qual
o `Optional`, ela vai ser genérica e abstrata com o construtor privado. Para
implementar o `equals`, vou assumir algo relativamente ok e aceitável: que
vamos ter um singleton do `EMPTY`. Com isso, só é igual se for igual via
igualdade de referência:

```java
public abstract class Xp<T> {
    
    @Override
    public abstract boolean equals(Object obj);
    @Override
    public abstract int hashCode();
    @Override
    public abstract String toString();

    private Xp() {
    }
    
    private static final Xp<Object> EMPTY = new Xp<>() {

        @Override
        public boolean equals(Object obj) {
            return this == obj;
        }

        @Override
        public int hashCode() {
            return 0;
        }

        @Override
        public String toString() {
            return "Empty[]";
        }
    };
    
    public static <T> Xp<T> empty() {
        return (Xp<T>) EMPTY;
    }   
}
```

Ok, para terminar as factories, vamos implementar o `of` e `ofNullable` (por
hora o `of` como um placeholder):

```java
public static <T> Xp<T> ofNullable(T v) {
    if (v == null) {
        return empty();
    }
    return of(v);
}

public static <T> Xp<T> of(T v) {
    if (v == null) {
        throw new NullPointerException("aqui só aceita valor, sem nulos");
    }
    return new Xp<T>() {
        @Override
        public int hashCode() {
            return v.hashCode();
        }

        @Override
        public boolean equals(Object obj) {
            return false;
        }

        @Override
        public String toString() {
            return "Value[" + v + "]";
        }
    };
}
```

Até aqui, tudo bem, preciso garantir o funcionamento do `equals`. Pegando via
clausura eu sei que não vai ser possível obter o valor `v` de nenhum jeito,
portanto vamos criar um campo pra ele:

```java
public static <T> Xp<T> of(T value) {
    if (value == null) {
        throw new NullPointerException("aqui só aceita valor, sem nulos");
    }
    return new Xp<T>() {

        final T v = value;

        @Override
        public int hashCode() {
            return v.hashCode();
        }

        @Override
        public boolean equals(Object obj) {
            return false;
        }

        @Override
        public String toString() {
            return "Value[" + v + "]";
        }
    };
}
```

Ok, assim eu tenho um campo `v`. Será que eu consigo fazer um _cast_ para a
classe anônima? Bem, usando apenas a sintaxe java? Não. Mas eu posso pegar a
classe daquele objeto específico e tentar, né? Eu não tenho nenhum tipo para
segurar a variável, então eu preciso fazer inline o `class.cast()` e pegar o
campo. Bora tentar?

```java
@Override
public boolean equals(Object obj) {
    if (obj == null) {
        return false;
    }
    if (!this.getClass().isInstance(obj)) {
        return false;
    }
    return this.getClass().cast(obj).v.equals(this.v);
}
```

Primeiro, verifico que não é nulo. Então, verifico que é da instancia da minha
classe anônima. E então eu faço o cast do objeto e pego seu campo para comparar
com a minha variável local!

Ok, além disso, temos outra opção? Podemos procurar pelo campo via reflection,
que tal?

```java
@Override
public boolean equals(Object obj) {
    if (obj == null) {
        return false;
    }
    if (!(obj instanceof Xp)) {
        return false;
    }
    final Xp<?> other = (Xp<?>) obj;
    try {
        final Field field = other.getClass().getDeclaredField("v");
        final Object otherV = field.get(other);
        return otherV.equals(this.v);
    } catch (NoSuchFieldException | IllegalAccessException e) {
        return false;
    }
}
```

Note que, caso eu faça algo como `Xp.of("str").equals(Xp.empty())` é necessário
que eu pegue o `NoSuchFieldException`, pois a classe do `empty()` não tem de
fato o campo `v`.

Como questão de experimento, resolvi colocar um breakpoint para examinar os
objetos em mão, e obtive coisas peculiares:

1. o IntelliJ está acusando os objetos de terem o campo `v` e o campo `value`,
   que foi pegue via clausura
2. o _evaluate_ reclama quando eu peço `other.v`, mas mostra o resultado
3. o _evaluate_ se recusa a trabalhar com `other.value`

Aqui o acesso para `other.v`:

![evaluate marcando de vermelho o campo "v", mostrando o valor no resultado e o objeto "aberto" mostrando os campos "v" e "value"]({{ page.base-assets | append: "other-v.png" | relative_url }})

Aqui o acesso para `other.value`:

![evaluate marcando de vermelho o campo "value", resultado acusando exceção "No such instance field: 'value'" e o objeto "aberto" mostrando os campos "v" e "value"]({{ page.base-assets | append: "other-value.png" | relative_url }})

Hmmm, fiquei com um gostinho de que eu consigo me livrar do singleton. Será?
Bora testar simplesmente verificar se o objeto é instância de
`this.getClass()`?

```java
@Override
public boolean equals(Object obj) {
    return this.getClass().isInstance(obj);
}
```

_Et voilà!_ Tudo certo! Alguns experimentos que eu fiz com essas variações:

```java
final Xp<String> one = Xp.of("one");
final Xp<String> uno = Xp.of("one");
final Xp<Integer> unonumber = Xp.of(1);
final Xp<Integer> duonumber = Xp.of(2);
final Xp<String> empty = Xp.empty();

System.out.println("one x uno: " + one.equals(uno));
System.out.println("one x unon: " + one.equals(unonumber));
System.out.println("duon x unon: " + duonumber.equals(unonumber));
System.out.println("uno x empty: " + uno.equals(empty));
System.out.println("empty x empty: " + empty.equals(empty));
System.out.println("empty x uno: " + empty.equals(uno));

System.out.println("empty x null: " + empty.equals(null));
```

# Parte mais interessante: os coletores

Um coletor, de modo geral, ele se separa em 4 níveis:

- um iniciador do acumulador
- uma função de acumulação (pega um elemento T e mistura com o acumulador)
- uma função de combinação (dados dois acumuladores, como combiná-los)
- um finalizador (transforma o acumulador em resultado final)

Muitas vezes (nem sempre) o acumulador é do mesmo tipo do resultado final,
então nesses casos o finalizador é a função identidade. As duas factories que
tem na JavaDoc indicam exatamente isso: uma retorna um
[`Collector<T, A, R>`](https://docs.oracle.com/javase/8/docs/api/java/util/stream/Collector.html#of-java.util.function.Supplier-java.util.function.BiConsumer-java.util.function.BinaryOperator-java.util.function.Function-java.util.stream.Collector.Characteristics...-)
e a outra um
[`Collector<T, R, R>`](https://docs.oracle.com/javase/8/docs/api/java/util/stream/Collector.html#of-java.util.function.Supplier-java.util.function.BiConsumer-java.util.function.BinaryOperator-java.util.stream.Collector.Characteristics...-).

Dito isso, e dado o compromisso de que não iremos usar métodos estáticos em
interfaces, o `Collector` daqui vai ser só a interface com métodos abertos e as
factories vão precisar residir em `Collectors`. E como não lidamos com as
características das streams, também não vou implementar isso para os coletores:

```java
public interface Collector<T, A, R> {

    Supplier<A> supplier();
    BiConsumer<A, T> accumulator();
    BinaryOperator<A> combiner();
    Function<A, R> finisher();
}
```

E as implementações das factories são resultados derivados diretamente disso,
tanto o caso do coletor sem um finalizador próprio como o que implementa tudo:

```java
public final class Collectors {

    public static <T, A, R> Collector<T, A, R> of(Supplier<A> supplier, BiConsumer<A,T> acc, BinaryOperator<A> combiner, Function<A, R> finisher) {
        return new Collector<>() {
            @Override
            public Supplier<A> supplier() {
                return supplier;
            }

            @Override
            public BiConsumer<A, T> accumulator() {
                return acc;
            }

            @Override
            public BinaryOperator<A> combiner() {
                return combiner;
            }

            @Override
            public Function<A, R> finisher() {
                return finisher;
            }
        };
    }

    public static <T, R> Collector<T, R, R> of(Supplier<R> supplier, BiConsumer<R,T> acc, BinaryOperator<R> combiner) {
        return of(supplier, acc, combiner, i -> i);
    }
}
```

Para exemplificar o teste, vou transformar um coletor arbitrário do Java em um
coletor próprio para a minha implementação:

```java
static <T, A, R> Collector<T, A, R> toMyCollector(java.util.stream.Collector<T, A, R> collector) {
    return Collectors.of(
        collector.supplier(),
        collector.accumulator(),
        collector.combiner(),
        collector.finisher()
    );
}
```

E com isso eu consigo aproveitar os testes feitos sobre `Stream#concat`:

```java
final Supplier<Stream<Integer>> stream1to6 = () -> Stream.of(1, 2, 3, 4, 5, 6);
final Stream<Integer> cheios = Stream.concat(stream1to6.get(), stream1to6.get());
final Stream<Integer> primeiroVazio = Stream.concat(Stream.empty(), stream1to6.get());
final Stream<Integer> segundoVazio = Stream.concat(stream1to6.get(), Stream.empty());
final Stream<Integer> vazios = Stream.concat(Stream.empty(), Stream.empty());

final int soma_cheios = cheios.collect(toMyCollector(java.util.stream.Collectors.summingInt(i -> i)));
System.out.println(soma_cheios);
// 42

final int soma_primeiroVazio = primeiroVazio.collect(toMyCollector(java.util.stream.Collectors.summingInt(i -> i)));
System.out.println(soma_primeiroVazio);
// 21

final int soma_segundoVazio = segundoVazio.collect(toMyCollector(java.util.stream.Collectors.summingInt(i -> i)));
System.out.println(soma_segundoVazio);
// 21

final int soma_vazios = vazios.collect(toMyCollector(java.util.stream.Collectors.summingInt(i -> i)));
System.out.println(soma_vazios);
// 0
```

Ok, prova de conceito de que funciona tá ok. Hora de implementar os demais
coletores em termos de `Collectors.of`!

Uma observação importante é que, para efeito de quem vai consumir o coletor,
saber quem é o acumulador do coletor é detalhe de implementação irrelevante,
até porque ele é usado apenas internamente e não é exposto ao mundo externo,
por isso que a maioria dos coletores são apresentados como
`Collector<T, ?, R>`, onde o elemento de entrada `T` é importante e o elemento
retornado `R` também é importante. O meio do caminho? Não.

## toList, toSet, toCollection

Aqui eu agrupei esses por um bom motivo:

```java
public static <T> Collector<T, ?, List<T>> toList() {
    return toCollection(ArrayList::new);
}

public static <T> Collector<T, ?, Set<T>> toSet() {
    return toCollection(HashSet::new);
}
```

Como na documentação sobre o `toList` e `toSet` não é especificado nenhuma
capacidade da coleção sendo retornada, estou tranquilo de que ela pode fazer
qualquer coisa, até ser mutável. Do javadoc do `toSet`:

> There are no guarantees on the type, mutability, serializability, or
> thread-safety of the Set returned

Para fazer isso, basicamente é adicionar elemento a coleção no acumulador e
pegar o `toOperator` que foi usado pra transformar um `BiConsumer` em um
`BinaryOperator`:

```java
public static <T, C extends Collection<T>> Collector<T, ?, C> toCollection(Supplier<C> supplier) {
    return of(supplier, Collection::add, toOperator(Collection<T>::addAll));
}
```

## joining

Aqui só vamos juntar strings. São 3 sabores de `joining`:

- um que só junta tudo
- um que coloca um separador
- o final que coloca um prefixo e um sufixo além do separador

Podemos modelar como o que só junta é uma chamada para o separador, porém que
usa o separador string vazia. E finalmente o que usa o separador chama o sabor
completo porém passando string vazia para sufixo e prefixo:

```java
public static Collector<String, ?, String> joining() {
    return joining("");
}

public static Collector<String, ?, String> joining(String delim) {
    return joining(delim, "", "");
}
```

Muito bem, agora vamos fazer a versão completa. Não vou me preocupar com
otimizações, só API. Infelizmente o `accumulator` é um `BiConsumer`, não um
`BiFunction`. Ou seja, vai ser de toda sorte necessário ter uma estrutura
mutável (não posso simplesmente fazer operações de string). Então vamos
usar como elemento de acumulação um container de string! Uma variável cuja
única função é ter uma string, e que eu possa trocar essa string. Para
facilitar essa troca, vou colocar os métodos `acc` que recebe uma string e
altera o seu conteúdo, e o `combiner` que recebe outro elemento do mesmo tipo
e combina.

Tanto no `acc` quanto no `combiner` colocamos o delimitador, exceto se ainda
não tiver sido inicializado. Se não tiver sido inicializado, só aceita a nova
string no lugar sem colocar nada. Para fazer isso, vou chamar essa estrutura de
`StringHolder`. Ele vai ter um construtor vazio e os métodos `acc` e `combine`,
onde `acc` recebe uma nova string e `combine` recebe outro `StringHolder`:

```java
public static Collector<String, ?, String> joining(String delim, String preffix, String suffix) {
    class StringHolder {
        boolean initialized = false;
        String v = "";
        StringHolder() {
        }

        void acc(String s) {
            if (!initialized) {
                initialized = true;
                this.v = s;
                return;
            }
            this.v += delim + s;
        }

        StringHolder combine(StringHolder other) {
            if (!initialized) {
                if (!other.initialized) {
                    return this;
                } else {
                    this.acc(other.v);
                    return this;
                }
            } else if (other.initialized) {
                this.acc(other.v);
                return this;
            }
            return this;
        }

        String finish() {
            return preffix + v + suffix;
        }
    }
    return of(
        StringHolder::new,
        StringHolder::acc,
        StringHolder::combine,
        StringHolder::finish
    );
}
```

Para testes:

```java
System.out.println(
    Stream.<String>empty().collect(Collectors.joining(", ", "[", "]"))
);
// []
System.out.println(
    Stream.of(1, 2, 3, 4).map(s -> "" + s).collect(Collectors.joining(", ", "[", "]"))
);
// [1, 2, 3, 4]
```

E imprimiu conforme esperado. Agora, a lógica do `combine` me parece exagerada.
Hmmm, vamos examinar uma coisinha...

Se ambos estão não inicializados, então preciso retornar um elemento não
inicializado também, e aqui o `this` é um ótimo candidato (eles são
indistinguíveis nesse estado). Agora, se o elemento que eu estiver recebendo
esteja inicializado, então preciso causar os efeitos colaterais no elemento
corrente, marcando ele como inicializado e "acumulando" o que vier do outro
acumulador.

Por fim, não tem o que fazer com o valor atual pois o outro elemento não foi
inicializado, então posso retornar `this` sem maiores complicações:

```java
StringHolder combine(StringHolder other) {
    if (!initialized && !other.initialized) {
        return this;
    } else if (other.initialized) {
        this.acc(other.v);
        return this;
    }
    return this;
}
```

Mas lendo agora percebi que é mais simples ainda: eu preciso alterar o estado
do `this` apenas se o outro já tiver sido inicializado. Caso contrário, retorno
diretamente o que já temos:

```java
StringHolder combine(StringHolder other) {
    if (other.initialized) {
        this.acc(other.v);
        return this;
    }
    return this;
}
```

## mapping

Aqui a intenção é mapear antes de passar para um outro coletor. Por exemplo,
eu não posso passar diretamente uma stream de inteiros para o
`Collectors.joining()`, mas eu posso mapear o inteiro em uma string e adaptar
isso para o `Collectors.joining()`:

```java
Collectors.mapping(i -> "" + i, Collectors.joining(", "));
```

De certo modo, vamos decorar o `accumulator` do coletor passado como argumento,
de modo que a entrada que se ele aceita `(A, U)`, vamos passar `(A, T)` e a
função `T => U`. O resto não se altera.

Então, vamos aplicar o padrão de projeto `decorator`?, tal qual temos no post
[Funções como padrões de projeto: do GoF pro Computaria]({% post_url 2025/2025-05-24-functions-as-design-patterns %}#decorator)
(especificamente o sabor "Estou ativamente escolhendo passar os argumentos para
a função não decorada" descritos para `decorator`):

```java
public static <T, A, U, R> Collector<T, ?, R> mapping(Function<T, U> mapper, Collector<U, A, R> baseCollector) {
    final BiConsumer<A, T> baseAcc = baseCollector.accumulator();
    return of(
        baseCollector.supplier(),
        (a, t) -> baseAcc.accept(a, mapper.apply(t)),
        baseCollector.combiner(),
        baseCollector.finisher()
    );
}
```

Para testar, vou pegar o exemplo do `joining` só que, no lugar de mapear usando
operações intermediárias de stream pra coletar depois, vou fazer tudo usando
apenas `Collectors.mapping`:

```java
System.out.println(
    Stream
        .of(1, 2, 3, 4)
        .collect(Collectors.mapping(s -> "" + s, Collectors.joining(", ", "[", "]")))
);
// [1, 2, 3, 4]
```

E o funcionamento foi adequadamente.


## collectingAndThen

De modo semelhante ao `mapping`, o `collectingAndThen` tem a pegada de ser uma
alteração feito em outro coletor. Mas aqui a mudança ocorre no final: o
`finisher` passa a ser transformado em outra coisa depois. Para exemplificar o
desafio, vou pegar a coleção do exemplo do `mapping` e vou aplicar a função
`String::length` para obter um inteiro:

```java
System.out.println(
    Stream
        .of(1, 2, 3, 4)
        .collect(
            Collectors.collectingAndThen(
                Collectors.mapping(s -> "" + s, Collectors.joining(", ", "[", "]")),
                String::length
            )
        )
);
// 12
```

Basicamente, vou montar um coletor tal qual meu coletor base, porém vou decorar
a saída do `finisher` original do coletor:

```java
public static <T, A, R, RR> Collector<T, ?, RR> collectingAndThen(Collector<T, A, R> baseCollector, Function<R, RR> finisher) {
    return of(
        baseCollector.supplier(),
        baseCollector.accumulator(),
        baseCollector.combiner(),
        a -> finisher.apply(baseCollector.finisher().apply(a))
    );
}
```

E o teste executa perfeitamente, sem maiores repercussões. Note que se eu
tivesse acesso a métodos `default` das interfaces eu faria composição de função
no lugar dessa linha gigantesca em que a ordem de leitura respeitasse a ordem
de chamada de funções:

```diff
-a -> finisher.apply(baseCollector.finisher().apply(a))
+baseCollector.finisher().andThen(finisher)
```

## groupingBy

> XXX

## counting

Esse é bem... tosco. Basicamente faz algo semelhante ao `Stream.count`, mas a
nível de coletor.

Basicamente começo com 0 elementos encontrados, o acumulador incrementa o que
encontrei e o _combiner_ soma o que encontrei, e por fim eu retorno apenas o
que encontrei descartando o `holder`:

```java
public static <T> Collector<T, ?, Long> counting() {
    class Holder {
        long c = 0;

        long c() {
            return c;
        }

        void inc() {
            c++;
        }

        Holder add(long a) {
            c += a;
            return this;
        }
    }
    return of(
        Holder::new,
        (h, v) -> h.inc(),
        (h1, h2) -> h1.add(h2.c),
        Holder::c
    );
}
```

Um caso de uso para ele? Bem, tem situações que eu não recebo nenhuma stream e
mesmo assim eu preciso contar. Como, por exemplo, saber quantos elementos tem a
mesma chave: posso usar o `groupingBy` seguido de `counting` como o coletor que
vai lidar com "o que fazer com os elementos que tem a mesma chave de
agrupamento".

## maxBy/minBy

Praticamente tão sem graça quanto o `counting` anterior. Tem o mesmo caso de
uso e historinha motivadora: tem coisa de stream que é obviamente muito
similar, porém tem situações que eu não terei stream.

Para motivar, no lugar de contar quantos elementos tem após agrupar usando o
`groupingBy`, vou querer o elemento máximo/mínimo desse agrupamento. Como
diferença eu tenho que talvez o meu `Holder` não tenha sido ainda inicializado,
situação em que retorna um `Optional.empty()`.

```java
public static <T> Collector<T, ?, Optional<T>> maxBy(Comparator<T> comparator) {
    class Holder {
        T max;
        boolean initialized = false;

        Optional<T> get() {
            if (!initialized) {
                return Optional.empty();
            }
            return Optional.of(max);
        }

        void acc(T t) {
            if (!initialized) {
                initialized = true;
                max = t;
                return;
            }
            if (comparator.compare(max, t) < 0) {
                max = t;
            }
        }

        Holder combine(Holder other) {
            if (other.initialized) {
                this.acc(other.max);
            }
            return this;
        }
    }
    return of(
        Holder::new,
        Holder::acc,
        Holder::combine,
        Holder::get
    );
}
```

O `minBy` segue a mesma lógica, só trocando com o que estou verificando o
retorno do `Comparator`:

```java
public static <T> Collector<T, ?, Optional<T>> minBy(Comparator<T> comparator) {
    class Holder {
        T min;
        boolean initialized = false;

        Optional<T> get() {
            if (!initialized) {
                return Optional.empty();
            }
            return Optional.of(min);
        }

        void acc(T t) {
            if (!initialized) {
                initialized = true;
                min = t;
                return;
            }
            if (comparator.compare(min, t) > 0) {
                min = t;
            }
        }

        Holder combine(Holder other) {
            if (other.initialized) {
                this.acc(other.min);
            }
            return this;
        }
    }
    return of(
        Holder::new,
        Holder::acc,
        Holder::combine,
        Holder::get
    );
}
```

## partitioningBy

Aqui o primeiro sabor do `partitioningBy` eu posso simplesmente dizer que é um
`groupingBy` com o booleano da função de particionamento:

```java
public static <T> Collector<T, ?, Map<Boolean, List<T>>> partitioningBy(Predicate<T> predicate) {
    return groupingBy(predicate::test);
}
```

mas... eu poderia lidar melhor com isso, não poderia? Posso guardar em duas
listas aqueles que atendem ao requisito de teste e os que não atendem, e só no
final criar um `HashMap` (por exemplo) com `TRUE` e `FALSE` e inserir essas
listas:

```java
public static <T> Collector<T, ?, Map<Boolean, List<T>>> partitioningBy(Predicate<T> predicate) {
    class Holder {
        final ArrayList<T> atende = new ArrayList<>();
        final ArrayList<T> naoAtende = new ArrayList<>();

        void acc(T t) {
            final ArrayList<T> alvo = predicate.test(t)? atende: naoAtende;
            alvo.add(t);
        }

        Holder combine(Holder other) {
            atende.addAll(other.atende);
            naoAtende.addAll(other.naoAtende);
            return this;
        }

        Map<Boolean, List<T>> finish() {
            final HashMap<Boolean, List<T>> r = new HashMap<>();
            r.put(Boolean.TRUE, atende);
            r.put(Boolean.FALSE, naoAtende);

            return r;
        }
    }
    return of(
        Holder::new,
        Holder::acc,
        Holder::combine,
        Holder::finish
    );
}
```

Até aqui tá legal. Mas falta o outro sabor do `partitioningBy`: o que recebe a
função de partição e também o que fazer com os elementos que chegam lá. Nesse
sentido, o mais fácil é delegar para o `groupingBy` passando o coletor para
ele:

```java
public static <T, D, A> Collector<T, ?, Map<Boolean, D>> partitioningBy(Predicate<T> predicate, Collector<T, A, D> baseCollector) {
    return groupingBy(predicate::test, baseCollector);
}
```

Mas eu posso adaptar a solução de cima também, né? Só que no lugar de usar
`ArrayList<T>` como elemento acumulador, passo a usar `A`. E no `finish`, eu
aplico o `baseCollector.finisher()` nos `atende` e `naoAtende`:

```java
public static <T, D, A> Collector<T, ?, Map<Boolean, D>> partitioningBy(Predicate<T> predicate, Collector<T, A, D> baseCollector) {

    class Holder {
        A atende = baseCollector.supplier().get();
        A naoAtende = baseCollector.supplier().get();

        void acc(T t) {
            final A alvo = predicate.test(t)? atende: naoAtende;
            baseCollector.accumulator().accept(alvo, t);
        }

        Holder combine(Holder other) {
            atende = baseCollector.combiner().apply(atende, other.atende);
            naoAtende = baseCollector.combiner().apply(naoAtende, other.naoAtende);
            return this;
        }

        Map<Boolean, D> finish() {
            final HashMap<Boolean, D> r = new HashMap<>();
            r.put(Boolean.TRUE, baseCollector.finisher().apply(atende));
            r.put(Boolean.FALSE, baseCollector.finisher().apply(naoAtende));

            return r;
        }
    }
    return of(
        Holder::new,
        Holder::acc,
        Holder::combine,
        Holder::finish
    );
}
```

E sabe uma coisa que seria divertida? Escrever o primeiro sabor do
`paritioningBy` como chamando o segundo sabor:

```java
public static <T> Collector<T, ?, Map<Boolean, List<T>>> partitioningBy(Predicate<T> predicate) {
    return partitioningBy(predicate, Collectors.toList());
}
```

Para testar, vou particionar os elementos como pares e ímpares. Para o caso do
segundo sabor, no lugar de esperar por uma lista, vou simplesmente querer
contar:

```java
System.out.println(
    Stream.of(1, 2, 3, 4).collect(Collectors.partitioningBy(i -> i % 2 == 0))
);
// { false = [1, 3], true = [2, 4]}

System.out.println(
    Stream.of(1, 2, 3, 4).collect(Collectors.partitioningBy(i -> i % 2 == 0, Collectors.counting()))
);
// { false = 2, true = 2}
```

## reducing

> XXX

## summing

Aqui temos 3 funções, que compartilham da mesma alma:

- `summingInt`
- `summingLong`
- `summingDouble`

O `summingDouble` pode ter um cuidado adicional para evitar perda de precisão
por ponto flutuante? Pode ter. Vou abordar isso? Não. Vou simplesmente delegar
para a exata mesma forma que vou resolver os demais `summing`: um receptáculo
para carregar os elementos somados com o tipo que está sendo usado (porém sem
_boxing_). Vou implementar apenas o `summingInt`, o resto é inferência trocando
`int` por `long` ou `double` e `Integer` por `Long` ou `Double`. E também
adequando o tipo da função que retorna primitivo: `ToIntFunction.applyAsInt` vs
`ToLongFunction.applyAsLong` vs `ToDoubleFunction.applyAsDouble`.

No sumário da documentação não cita, mas na descrição completa é citado que se
a stream estiver vazia o retorno deve ser `0`:

```java
public static <T> Collector<T, ?, Integer> summingInt(ToIntFunction<T> mapper) {

    class Holder {
        int soma = 0;

        void acc(T t) {
            final int v = mapper.applyAsInt(t);
            soma += v;
        }

        Holder combine(Holder other) {
            soma += other.soma;
            return this;
        }

        int finish() {
            return soma;
        }
    }
    return of(
        Holder::new,
        Holder::acc,
        Holder::combine,
        Holder::finish
    );
}
```

Para testar, aproveitei o código do `partitioningBy` e somei os pares/ímpares
do meu conjunto:

```java
System.out.println(
    Stream.of(1, 2, 3, 4)
        .collect(
            Collectors.partitioningBy(
                i -> i % 2 == 0,
                Collectors.summingInt(i -> i)
            )
        )
);
// {false=4, true=6}
```

## averaging

Tal qual o `summing`, tem 3 funções que compartilham a mesma alma:

- `averagingInt`
- `averagingLong`
- `averagingDouble`

O código é a cópia do `summing` com 2 diferenças:

- vou contar a quantidade de elementos (em um `long`)
- para finalizar, vou dividir pela quantidade de elementos (exceto se vaio, aí
  retorna 0 mesmo)

Mesma linha de pensamento aqui que só vou apresentar o `averagingInt`, não vou
me repetir mais do que o código abaixo ser uma verdadeira duplicação:

```java
public static <T> Collector<T, ?, Double> averagingInt(ToIntFunction<T> mapper) {

    class Holder {
        int soma = 0;
        long contagem = 0;

        void acc(T t) {
            final int v = mapper.applyAsInt(t);
            soma += v;
            contagem++;
        }

        Holder combine(Holder other) {
            soma += other.soma;
            contagem += other.contagem;
            return this;
        }

        double finish() {
            if (contagem == 0) {
                return 0;
            }
            return ((double)soma)/contagem;
        }
    }
    return of(
        Holder::new,
        Holder::acc,
        Holder::combine,
        Holder::finish
    );
}
```

Mesmo teste adequando o coletor:

```java
System.out.println(
    Stream.of(1, 2, 3, 4)
        .collect(
            Collectors.partitioningBy(
                i -> i % 2 == 0,
                Collectors.averagingInt(i -> i)
            )
        )
);
// {false=2.0, true=3.0}
```

## summarizing

Tal qual `summing`, mesma alma em 3 cantos:

- `summarizingInt`
- `summarizingLong`
- `summarizingDouble`

Esses coletores retornam o `*SummaryStatistics` adequado ao tipo. Basicamente
o tipo `*SummaryStatistics` vai guiar a aplicação das funções `summarizing`,
então só vou delegar pra ela. Vou usar o `mapping` para fazer a decoração
adequada e diminuir fricção de implementação:

```java
public static <T> Collector<T, ?, IntSummaryStatistics> summarizingInt(ToIntFunction<T> mapper) {
    return Collectors.mapping(mapper, of(
        IntSummaryStatistics::new,
        IntSummaryStatistics::accept,
        IntSummaryStatistics::combine
    ));
}
```

Vamos usar o `IntSummaryStatistics` do java inicialmente como rascunho e...
Hmmm, não compilou? Ué... Ah! Claro! `combiner` aceita um `BinaryOperator` e
aqui o `IntSummaryStatistics::combine` retorna `void`. Nada que um `toOperator`
não resolva.

Mas ainda não foi, ué... Ah! `mapper` não é do tipo `Function<T, Integer>`, mas
posso passar pra ele a referência do método, que então o compilador vai
transformar em `Function<T, Integer>`:

```java
public static <T> Collector<T, ?, IntSummaryStatistics> summarizingInt(ToIntFunction<T> mapper) {
    return Collectors.mapping(mapper::applyAsInt, of(
        IntSummaryStatistics::new,
        IntSummaryStatistics::accept,
        toOperator(IntSummaryStatistics::combine)
    ));
}
```

Ok, isso de lado, vamos agora implementar o `IntSummaryStatistics`! Aqui ele
vai ter algo em comum com o `averagingInt`: vou precisar contar também quantos
elementos foram aceitos. Mas tem algumas variações a mais:

- precisa guardar o máximo e o mínimo
- implementa `IntConsumer`
- mínimo e máximo tem placeholders
  (vide [documentação](https://docs.oracle.com/javase/8/docs/api/java/util/IntSummaryStatistics.html#IntSummaryStatistics--))

Como estratégia, ao aceitar um novo valor, ao faço a soma dele e aumenta a
contagem, e também aproveito para verificar o `max` e o `min`. Em relação à
média, bem... eu posso manter ele sempre atualizado ou então marcar o registro
como sujo. É, isso parece mais barato. E quando eu pedir a média eu a calculo,
registro ela no campo e marco que está limpo.

```java
public class IntSummaryStatistics implements IntConsumer {

    private int max = Integer.MIN_VALUE;
    private int min = Integer.MAX_VALUE;
    private long count = 0;
    private long acc = 0;
    private boolean dirty = false;
    private double avg;

    @Override
    public void accept(int value) {
        dirty = true;
        acc += value;
        count++;

        if (value > max) {
            this.max = value;
        }
        if (value < min) {
            this.min = value;
        }
    }

    public void combine(IntSummaryStatistics other) {
        if (other.count == 0) {
            // não tem nada o que fazer aqui
            return;
        }

        this.dirty = true;
        this.acc += other.acc;
        this.count += other.count;

        if (other.max > this.max) {
            this.max = other.max;
        }
        if (other.min < this.min) {
            this.min = other.min;
        }
    }

    public double getAverage() {
        if (count == 0) {
            return 0.0;
        }
        if (dirty) {
            avg = ((double) acc)/count;
            dirty = false;
        }
        return avg;
    }

    public int getMax() {
        return max;
    }

    public int getMin() {
        return min;
    }

    public long getSum() {
        return acc;
    }

    public long getCount() {
        return count;
    }
}
```

Para teste? Que tal pegar o `summaryzingInt` para os números de 1 a 4?

```java
System.out.println(
    Stream.of(1, 2, 3, 4)
        .collect(
            Collectors.summarizingInt(i -> i)
        )
);
```

E... `IntSummaryStatistics@234bef66`? Ah, sim. Ele não define um `toString`
adequado. Vamos imprimir então a média, mínima, máximo, soma e contagem:

```java
final IntSummaryStatistics s = Stream.of(1, 2, 3, 4)
        .collect(
            Collectors.summarizingInt(i -> i)
        );
final HashMap<String, Object> valores = new HashMap<>();
valores.put("avg", s.getAverage());
valores.put("sum", s.getSum());
valores.put("max", s.getMax());
valores.put("min", s.getMin());
valores.put("cnt", s.getCount());
System.out.println(valores);
```

E o resultado veio conforme esperado (aqui eu dei um _prettify_):

```none
{
    avg=2.5,
    min=1,
    max=4,
    cnt=4,
    sum=10
}
```

## toMap

> XXX

# APIs além do Java 8

Os gatherers serão deixados de lado, irei pegar as evoluções de `Stream` e de
`Optional` até o Java 17.

> XXX COMPLETAR
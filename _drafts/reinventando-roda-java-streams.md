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

E, por fim, as factories! Como `.of(1, 2, 3)` e `iterate(seed, operator)`!

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

Para o teste? Bem, vamos usar o `flatMap` anterior, junto com o `distintct`:

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
o `Collecetor`?



> XXX COMPLETAR

## empty

> XXX COMPLETAR

## of

> XXX COMPLETAR

## concat

> XXX COMPLETAR

## iterate

> XXX COMPLETAR

## generate

> XXX COMPLETAR

## builder

> XXX COMPLETAR

# optional

Antes da parte mais interessante (os `Collectors`), vamos normalizar aqui a
questão do `Optional`? Eles foram usados no `findAny`, `findFirst`, `min` e
`max`, afinal. Como a API é a mesma, isso não foi levado em consideração antes,
mas de toda sorte é necessário.

Existem algumas estratégias para isso. Uma delas é usar subclasses,
`Optional.None` e `Optional.Just`. Outra é enfiar `if`s em todo método. Vamos
explorar ambos?

> XXX COMPLETAR

# Os coletores

> XXX COMPLETAR

# APIs além do Java 8

> XXX COMPLETAR
---
layout: post
title: "Java 24 chegou! Vamos reescrever streams com gatherers!"
author: "Jefferson Quesado"
tags: java programação-funcional stream
base-assets: "/assets/java-24-gatherers/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Java 24 chegou e com ele chegaram os Gatherers!

[Esse artigo](https://todd.ginsberg.com/post/java/gatherers/) foi o que me deu
uma visão geral do que são esses Gatherers, espero que a leitura seja
proveitosa pra você também.

# O que são Gatherers?

De modo geral, são a generalização de operações intermediárias de uma stream.
O exemplo dado por Todd Ginsberg é `distinctBy`, onde se seleciona os elementos
de uma stream, mas que apenas um atenda ao parâmetro de distinção:

```java
Stream.of("A", "B", "CC", "DD", "EEE")
      .distinctBy(it -> it.length())   // <-- Not real!
      .toList();
// Gives: ["A", "CC", "EEE"]
```

O `distinctBy` não existe no Java, mas com gatherer você pode implementar. Fica
algo assim:

```java
Stream.of("A", "B", "CC", "DD", "EEE")
      .gather(distinctBy(String::length))
      .toList();
// Gives: ["A", "CC", "EEE"]
```

Vamos implementar?

Bem, como queremos algo distinto, isso significa que nosso gatherer precisa ter
estado. Por questões de simplicidades, podemos assumir que a função passada
para o gatherer vai gerar uma espécie de chave, que precisa ser única.

Bem, vamos adicionar a chave (e o elemento que gerou a chave) no estado
intermediário e, após processar tudo, na hora de finalizar, vou coletar os
elementos do estado.

Se eu usar `LinkedHashMap` para o estado, eu coloco cada chave unicamente com
`putIfAbsent` e, na hora de resgatar os valores com `state.values()` eles ainda
estarão em ordem.

Existe também a eventual necessidade de combinar com estados que vem de outras
threads, para isso precisamos fazer um `combiner`, No caso, quem está no estado
a esquerda foi adicionado antes, então posso simplesmente pegar tudo novo do
estado a direita e jogar no estado a esquerda.

Aqui uma implementação para testar:

```java
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Gatherer;
import java.util.stream.Stream;

<A, D> Gatherer<A, Map<D, A>, A> disctincBy(Function<A, D> disctinction) {
	return Gatherer.of(
		LinkedHashMap::new,
		Gatherer.Integrator.ofGreedy( (state, element, downstream) -> {
			state.putIfAbsent(disctinction.apply(element), element);
			return !downstream.isRejecting();
		}),
		(stateLeft, stateRight) -> {
			stateRight.forEach((k, v) -> stateLeft.putIfAbsent(k, v));
			return stateLeft;
		},
		(state, downstream) -> {
			state.values().forEach(downstream::push);
		}
	);
}

final var l = Stream.of("A", "B", "CC", "DD", "EEE")
        .gather(disctincBy(String::length))
        .toList();
System.out.println(l);
```

Leia mais na
[JavaDoc de `Gatherer`](https://docs.oracle.com/en/java/javase/24/docs/api/java.base/java/util/stream/Gatherer.html)

# O desafio

Já que gatherers são a generalização das operações intermediárias, isso
significa que eu posso trabalhar unicamente com gatherers. Então, vamos brincar
de trocar todas as operações intermediárias para gatherers?

Basicamente, onde antes tínhamos algo assim:

```java
Stream.of("A", "B", "CC", "DD", "EEE")
    .map(String::length)
    .toList();
```

Iremos substituir pelo gatherer `map` mantendo a mesma API da função
intermediária `.map`:

```java
Stream.of("A", "B", "CC", "DD", "EEE")
    .gather(map(String::length))
    .toList();
```

Para consultar as operações intermediárias, consultei a javadoc para
[`java.util.stream.Stream`](https://docs.oracle.com/en/java/javase/24/docs/api/java.base/java/util/stream/Stream.html#)
e peguei todos os métodos de instância que retornavam outras streams. Mesmo
métodos com implementações default vão aqui, apesar de ter implementação
default _por que não_, né?

Para ilustrar as operações intermediárias, vou colocar contra esse conjunto de
elementos, por os parâmetros adequados e mostrar a saída esperada:

```java
final var l = Stream.of("A", "A", "B", "A", "CC", "A", "DD", "EEE")
    .gather(...)
    .toList();
// Gives [...]
```

E agora, com vocês, as operações intermediárias de streams do java, mas agora
implementadas com gatherer!

## Memória muscular

Bem, fazendo as operações intermediárias, surgiu um pouco de memória muscular
na hora de implementar o próximo gatherer. A anatomia da interface é essa:

```java
interface Gatherer<FromUpstream, State, ToDownstream> {...}
```

Os tipos que chegam no gatherer são o primeiro tipo genérico. O estado
(normalmente indicado por `?`) é o estado usado pelos gatherers, e tal qual o
`Collector` faz sentido que essa representação intermediária não seja visível
para o mundo externo. Assim, ao precisar alterar o estado, não irá quebrar
compatibilidade com código existente nem tampouco precisa expor uma classe que
só faça sentido dentro de um contexto muito específico.

Falando em estado, se ele não for algum estado baseado obviamente em uma
estrutura de dados já presente na sua code base (como, por exemplo, o
`ArrayList` do próprio Java para o intermediário `sorted`, ou mesmo o
`LinkedHashSet` para `distinct`), provavelmente o estado é um objeto de uso
único local naquela função. Então basicamente, ao precisar de um estado novo,
criei a classe dentro do método.

Por exemplo:

```java
<A> Gatherer<A, ?, A> dropWhile(Predicate<? super A> predicate) {
	class State {
		boolean drop = true;
	}

	return Gatherer.ofSequential(State::new,
		Gatherer.Integrator.ofGreedy((state, element, ds) -> {
            if (state.drop) {
                if (!predicate.test(element)) {
                    state.drop = false;
                    return ds.push(element);
                }
                return !ds.isRejecting();
            }
            return ds.push(element);
        })
	);
}
```

O nome dessa classe não importa, então colocar `State` acaba sendo um ótimo
ponto de partida.

Por fim, o terceiro tipo genérico, que eu representei como `ToDownstream`, ele
representa o tipo que será passado para o downstream, que será consumido
posteriormente.

Ao criar o integrator do gatherer, preciso me perguntar uma coisa: o meu
integrator vai fazer curto circuito (como por exemplo `limit`)? Se vai fazer,
crio ele com `Gatherer.Integrator.of`. Caso contrário, o padrão é criar com
`Gatherer.Integrator.ofGreedy`, pois esse gatherer vai tentar consumir tudo até
o fim.

Outras coisas para se levar em consideração é se o meu gatherer vai se importar
com a ordem com que recebe os argumentos. Por exemplo, o `distinctBy` acima
(que não é operação intermediária) se importa com a ordem, ou então o `skip` ou
o `limit`. Para esses casos, melhor usar `Gatherer.ofSequential`. Mas eu posso
ter gatherers que não se importam com a ordem, como por exemplo `map`.

> Não se importar com a ordem não quer dizer que o output será bagunçado,
> apenas que a ordem de recebimento das informações não altera o resultado
> final. Mesmo o `map` gera o resultado na mesma ordem de chegada, depois de
> combinar as streams paralelas.

Para o caso de paralelismo e também de gatherers com estado, é necessário unir
os estados para evitar uma surpresa ruim. Exemplo de gatherer stateful com
paralelismo? `sorted`.

Dá para complicar bastante o estado, como por exemplo nas implementações de
`takeWhile2` (que satisfaz `takeWhile`) e `dropWhile2` (que satisfaz
`dropWhile`), mas quando mais plano for o objeto de estado, mais fácil de
entender o que está acontecendo. Além de que a lógica fica mais no próprio
integrator.

Ao usar um combiner, se faz necessário usar um finisher.

## distinct

`distinct` claramente precisa guardar estado. Aqui é importante a ordem com que
chegam os elementos, então `Gatherer.ofSequential`.

```java
// Stream<T> distinct()
// aqui uma solução sequencial
<A> Gatherer<A, ?, A> distinct() {
	return Gatherer.ofSequential(
		HashSet::new,
		Gatherer.Integrator.ofGreedy((state, element, downstream) -> {
			if (state.add(element)) {
				return downstream.push(element);
			}
			return !downstream.isRejecting();
		})
	);
}
```

Mas eu poderia fazer com `Gatherer.of` contanto que eu tomasse alguns cuidados:

- o estado agora precisa necessariamente ser `LinkedHashSet`, pois ele vai
  guardar a ordem de inserção
- o combiner deve favorecer o lado esquerdo
- eu só posso enviar os dados downstream no finisher

É possível adaptar a implementação do `disctincBy` para satisfazer o
`distinct`, visto que o combiner dele já lida com "favorecer o lado esquerdo".

Executando:

```java
final var l = Stream.of("A", "A", "B", "A", "CC", "A", "DD", "EEE")
    .gather(distinct())
    .toList();
// Gives ["A", "B", "CC", "DD", "EEE"]
```

## dropWhile

Aqui eu preciso manter estado, apenas pra saber se preciso continuar dropando.
Não tenho uso para o estado após virar a chave para aceitar as coisas.

Portanto, se eu ainda estiver em "estado de drop", eu preciso testar com o
predicado passo. O predicado indicando que não precisa mais dropar, altero o
estado para "estado de aceite" e não preciso nunca mais testar os elementos.

Como eu preciso dropar as coisas até achar algo novo, esse gatherer é
essencialmente sequencial. Eu vou consumir o input inteiro.

```java
// Stream<T> dropWhile(Predicate<? super T> predicate)
// aqui uma solução sequencial
<A> Gatherer<A, ?, A> dropWhile(Predicate<? super A> predicate) {
	class State {
		boolean drop = true;
	}

	return Gatherer.ofSequential(State::new,
		Gatherer.Integrator.ofGreedy((state, element, ds) -> {
            if (state.drop) {
                if (!predicate.test(element)) {
                    state.drop = false;
                    return ds.push(element);
                }
                return !ds.isRejecting();
            }
            return ds.push(element);
        })
	);
}

<A> Gatherer<A, ?, A> dropWhile2(Predicate<? super A> predicate) {
	class State {
		BiPredicate<A, Gatherer.Downstream<? super A>> whatToDo;

		State() {
			this.whatToDo = (e, ds) -> {
				if (!predicate.test(e)) {
					final var pushed = ds.push(e);
					this.whatToDo = (el, ds2) -> ds2.push(el);
					return pushed;
				}
				return !ds.isRejecting();
			};
		}
	}

	return Gatherer.ofSequential(State::new,
		Gatherer.Integrator.ofGreedy((state, element, ds) ->
			state.whatToDo.test(element, ds)
		)
	);
}
```

Na implementação secundária eu tentei guardar no estado a próxima ação, assim
a função `whatToDo` mantém o que precisa ser feito.

Executando:

```java
final var l = Stream.of("A", "A", "B", "A", "CC", "A", "DD", "EEE")
    .gather(dropWhile(s -> s.length() == 1))
    .toList();
// Gives ["CC", "A", "DD", "EEE"]
```

## filter

No filtro eu não preciso manter estado. A ordem de chegada não afeta o próximo
elemento, então posso paralelizar livremente. Vou consumir até o fim.

```java
// Stream<T> filter(Predicate<? super T> predicate)
<A> Gatherer<A, ?, A> filter(Predicate<? super A> predicate) {
    return Gatherer.of(
        Gatherer.Integrator.ofGreedy((state, element, ds) -> {
            if (predicate.test(element)) {
                return ds.push(element);
            }
            return !ds.isRejecting();
        })
    );
}
```

Executando:

```java
final var l = Stream.of("A", "A", "B", "A", "CC", "A", "DD", "EEE")
    .gather(filter(s -> s.length() == 1))
    .toList();
// Gives ["A", "A", "B", "A", "A"]
```

## flatMap

A ordem também não é importante pra o `flatMap`, nem tampouco o estado
anterior. Irei consumir até o fim

```java
// <R> Stream<R> flatMap(Function<? super T, ? extends Stream<? extends R>> mapper)
<A, R> Gatherer<A, ?, R> flatMap(Function<? super A, ? extends Stream<? extends R>> mapper) {
    return Gatherer.of(
        Gatherer.Integrator.ofGreedy((state, element, ds) -> {
            mapper.apply(element).forEach(ds::push);
			return !ds.isRejecting();
		})
    );
}
```

Por um tempo fiquei me questionando como eu faria para indicar que o downstream
iria receber novos elementos. No fim, a solução é iterar na stream obtida pelo
mapper e, para cada elemento da stream, passar adiante. Esse código poderia ser
melhor otimizado caso o `ds.push` recusasse o elemento, mas está bom o
suficiente para o meu fim.

Outra coisa que eu me confundi bastante foi na tipagem do downstream. Eu
coloquei erroneamente que seria um `Gatherer<A, ?, Stream<R>>`, mas na verdade
eu não vou consumir elementos do tipo `Stream<R>`, apenas elementos do tipo
`R`. Eu me enganei bastante por conta do tipo do `mapper`, que é
`A -> Stream<R>`.

Executando:

```java
final var l = Stream.of("A", "A", "B", "A", "CC", "A", "DD", "EEE")
    .gather(flatMap(e -> e.chars().mapToObj(c -> ((char) c) + "")))
    .toList();
// Gives ["A", "A", "B", "A", "C", "C", "A", "D", "D", "E", "E", "E"]
```

## limit

Aqui eu quero realizar um curto circuito! Ao chegar em determinado valor,
acabou a streaming de dados! Então `Gatherer.Integrator.of`.

A ordem de chegada é extremamente importante, pois só vou pegar os `maxSize`
primeiros elementos. O estado indica quantos elementos já foram adicionados ao
downstream. Poderia ter feito equivalentemente "quantos elementos faltam", mas
achei mais semântico comparar com `state.qnt >= maxSize` do que
`state.remaining > 0`.

```java
// Stream<T> limit(long maxSize)
<A> Gatherer<A, ?, A> limit(long maxSize) {
    class State {
        long qnt = 0;
    }
    return Gatherer.ofSequential(
        State::new,
        Gatherer.Integrator.of((state, element, ds) -> {
            if (state.qnt >= maxSize) {
                return false;
            }
            state.qnt++;
			return ds.push(element);
		})
    );
}
```

Executando:

```java
final var l = Stream.of("A", "A", "B", "A", "CC", "A", "DD", "EEE")
    .gather(limit(3))
    .toList();
// Gives ["A", "A", "B"]
```

## map

Aqui nota que finalmente temos um mapeamento trivial que altera o retorno! Não
preciso guardar estado, não preciso me preocupar com o que veio antes e irei
consumir tudo até o fim:

```java
// <R> Stream<R> map(Function<? super T, ? extends R> mapper)
<A, R> Gatherer<A, ?, R> map(Function<? super A, ? extends R> mapper) {
    return Gatherer.of(
        Gatherer.Integrator.ofGreedy((state, element, ds) -> ds.push(mapper.apply(element)))
    );
}
```

Executando:

```java
final var l = Stream.of("A", "A", "B", "A", "CC", "A", "DD", "EEE")
    .gather(map(String::length))
    .toList();
// Gives [1, 1, 1, 1, 2, 1, 2, 3]
```

## mapMulti

Aqui basicamente as mesmas dificuldades do `flatMap`, mas eu passei antes pela
experiência com o `flatMap` portanto já vim calejado.

```java
// default <R> Stream<R> mapMulti(BiConsumer<? super T, ? super Consumer<R>> mapper)
<A, R> Gatherer<A, ?, R> mapMulti(BiConsumer<? super A, ? super Consumer<R>> mapper) {
    return Gatherer.of(
        Gatherer.Integrator.ofGreedy((state, element, ds) -> {
            mapper.accept(element, (Consumer<R>) ds::push);
            return !ds.isRejecting();
        })
    );
}
```

Uma coisa que pegou é que `? super Consumer<R>` não é `Consumer<R>`, então
`ds::push` não estava funcionando. `? super Consumer<R>` basicamente indica
super tipos de `Consumer<R>`, logo não tem nenhuma garantia de que precisa
implementar `accept`, e é por isso que eu faço o cast `(Consumer<T>) ds::push`.

Executando:

```java
final var l = Stream.of("A", "A", "B", "A", "CC", "A", "DD", "EEE")
    .gather(mapMulti((s, c) -> {
        for (int i = 0; i < s.length(); i++) {
            c.accept(s.charAt(i));
        }
    }))
    .toList();
// Gives ["A", "A", "B", "A", "C", "C", "A", "D", "D", "E", "E", "E"]
```

## peek

Pego um elemento, olho ele, passo pra frente. Stateless, sem preocupação com
ordem de chegada, sem preocupação com curto circuito.

```java
// Stream<T> peek(Consumer<? super T> action)
<A> Gatherer<A, ?, A> peek(Consumer<? super A> action) {
    return Gatherer.of(
        Gatherer.Integrator.ofGreedy((state, element, ds) -> {
            action.accept(element);
            return ds.push(element);
        })
    );
}
```

Executando:

```java
final var l = Stream.of("A", "A", "B", "A", "CC", "A", "DD", "EEE")
    .gather(peek(System.out::println))
    .toList();
// Gives ["A", "A", "B", "A", "CC", "A", "DD", "EEE"]
// Output:
// A
// A
// B
// A
// CC
// A
// DD
// EEE
```

## skip

Similar ao `limit`, mas aqui eu quero ir até o fim (portanto
`Gatherer.Integrator.ofGreedy`). Não faz sentido ter uma implementação
paralelizada disso, pois preciso ignorar os primeiros `n` elementos.

Basicamente o estado serve para contar quantos elementos foram criados no meio
do caminho.

```java
// Stream<T> skip(long n)
<A> Gatherer<A, ?, A> skip(long n) {
    class State {
        long qnt = 0;
    }
    return Gatherer.ofSequential(
        State::new,
        Gatherer.Integrator.ofGreedy((state, element, ds) -> {
            if (state.qnt < n) {
                state.qnt++;
                return !ds.isRejecting();
            }
            return ds.push(element);
        })
    );
}
```

Executando:

```java
final var l = Stream.of("A", "A", "B", "A", "CC", "A", "DD", "EEE")
    .gather(skip(3))
    .toList();
// Gives ["A", "CC", "A", "DD", "EEE"]
```

## sorted

Aqui eu só posso passar adiante após o fim da streaming. Mas adivinha uma coisa
interessante? A ordem meio que não importa: eu posso acumular as coisas e, na
hora de juntar, manter o que tava na esquerda a esquerda, daí a função de
`sort` vai manter a ordenação estável (tendo fé o Timsort, claro).

O estado é basicamente um `ArrayList`, sem segredos. Para combinar, é adicionar
os elementos da direito após os elementos da esquerda, algo assim:

```java
(left, right) -> {
    left.addAll(right);
    return left;
}
```

Basicamente, na hora de terminar o recebimento precisamos ordenar a lista e,
então, passar `sortedList.forEach(ds::push)`. Se usar um for-each clássico dá
para otimizar e terminar o laço na primeira falha de `ds.push`, mas isso
funcionou bem o suficiente para mim.

```java
// Stream<T> sorted(Comparator<? super T> comparator)
<A> Gatherer<A, ?, A> sorted(Comparator<? super A> comparator) {
    return Gatherer.of(
		ArrayList<A>::new,
        Gatherer.Integrator.ofGreedy((state, element, ds) -> {
            state.add(element);
            return !ds.isRejecting();
        }),
        (left, right) -> {
            left.addAll(right);
            return left;
        },
        (state, ds) -> {
			state.sort(comparator);
			state.forEach(ds::push);
		}
    );
}
```

Nota que eu tive tendo problemas com `state.sort(comparator)` lá no finisher
porque eu estava criando o estado com `ArrayList::new`. E esse tipo o Java não
conseguiu inferir nada de interessante, portanto o tipo de `state` não tinha um
generics compatível com o de `comparator`. Para resolver isso, descobri que
posso tipar a lambda de criação usando `ArrayList<A>::new`.

Finalmente, para o `sorted` sem argumentos, passei o `Comparator.naturalOrder`
para o `sorted` com o comparator. Fiz um casting porque o compilador não pode
garantir que `A extends Comparable<A>`, então forcei a barra com
`(Comparator<A>) Comparator.naturalOrder()`.

```java
// Stream<T> sorted()
@SuppressWarnings("unchecked")
<A> Gatherer<A, ?, A> sorted() {
    return sorted((Comparator<A>) Comparator.naturalOrder());
}
```

Executando:

```java
final var l = Stream.of("A", "A", "B", "A", "CC", "A", "DD", "EEE")
    .gather(sorted())
    .toList();
// Gives ["A", "A", "A", "A", "B", "CC", "DD", "EEE"]
```

Outra execução:

```java
final var l = Stream.of("A", "A", "B", "A", "CC", "A", "DD", "EEE")
    .gather(map(String::length))
    .gather(sorted())
    .toList();
// Gives [1, 1, 1, 1, 1, 2, 2, 3]
```


## takeWhile

Aqui mais um caso de que devemos receber as coisas sequencialmente, pois afinal
abortar no primeiro sinal de "não precisa mais". Ou seja, também precisa fazer
curto-circuito.

Eu posso fazer stateless no momento que eu disparar o curto-circutio, pois,
afinal, já indico que não irei continuar recebendo novos elementos.

```java
// default Stream<T> takeWhile(Predicate<? super T> predicate)
<A> Gatherer<A, ?, A> takeWhile(Predicate<? super A> predicate) {
    return Gatherer.ofSequential(
        Gatherer.Integrator.of((state, element, ds) -> {
			if (predicate.test(element)) {
				return ds.push(element);
			}
			return false;
		})
    );
}
```

Antes de chegar na implemtação stateless, passei antes por guardar o estado. Eu
poderia estar no estado de "aceitando", estado "bom", ou já poderia ter passado
dele. Ao recusar o primeiro elemento, precisava atualizar o estado para "não
está saudável". Note que a primeira consulta sempre era ao estado, pra saber se
estava saudável o suficiente para continuar.

```java
<A> Gatherer<A, ?, A> takeWhile2(Predicate<? super A> predicate) {
    class State {
        boolean good = true;
    }
    return Gatherer.ofSequential(
        State::new,
        Gatherer.Integrator.of((state, element, ds) -> {
            if (!state.good) {
                return false;
            }
            final var t = predicate.test(element);
            if (t) {
                return ds.push(element);
            }
            return state.good = false;
        })
    );
}
```

E, finalmente, a implementação baseada na complicação do `dropWhile2`.

```java
// default Stream<T> takeWhile(Predicate<? super T> predicate)
<A> Gatherer<A, ?, A> takeWhile3(Predicate<? super A> predicate) {
    class State {

        BiPredicate<A, Gatherer.Downstream<? super A>> whatToDo;
        State() {
            whatToDo = (e, d) -> {
                if (!predicate.test(e)) {
                    this.whatToDo = (_, _) -> false;
                    return false;
                }
                return d.push(e);
            }
        }
    }
    return Gatherer.ofSequential(
        State::new,
        Gatherer.Integrator.of((state, element, ds) -> state.whatToDo.test(element, ds))
    );
}
```

Executando:

```java
final var l = Stream.of("A", "A", "B", "A", "CC", "A", "DD", "EEE")
    .gather(takeWhile(s -> s.length() == 1))
    .toList();
// Gives ["A", "A", "B", "A"]
```
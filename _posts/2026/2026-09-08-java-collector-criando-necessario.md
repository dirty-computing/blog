---
layout: post
title: "Criando um Collector novo para o Java"
author: "Jefferson Quesado"
tags: java fp stream
base-assets: "/assets/java-collector-criando-necessario/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Estava refatorando um código no trabalho e peguei uma iteração bem peculiar:

```java
// record AlgumObjeto(String key, ...) {}
Set<AlgumObjeto> detectaInvalidos(List<AlgumObjeto> todosObjetos) {
    Set<AlgumObjeto> invalidos = new HashSet<>();
    Set<String> chavesValidas = new HashSet<>();

    for (final var o: todosObjetos) {
        final var k = o.key();
        if (!chavesValidas.add(k)) {
            invalidos.add(o);
        }
    }

    return invalidos;
}

List<AlgumObjeto> todosObjetos = ...;
Set<AlgumObjeto> invalidos = detectaInvalidos(todosObjetos);

// log dos invalidos

List<AlgumObjeto> validos = new ArrayList<>(todosObjetos);
validos.removeAll(invalidos);

return validos;
```

E fiquei imaginando... será que a gente consegue transformar isso em um
coletor?

# Os casos de uso

Basicamente o que se deseja é classificar e utilizar 2 classes de objetos:

- o primeiro que aparece com determinada característica, retornando a lista dos
  inéditos
- os repetidos que aparecem com a dada característica, retornando a lista
  apenas com esses repetidos

No fundo é o mesmo processo para ambos, mas com fins distintos. A função
pública retorna o resultado apenas dos inéditos. Mas também tem o fato de que
sim, é usado o resultado dos inválidos para logar e fazer alguns ajustes, por
mais que publicamente isso não esteja exposto programaticamente.

A chave usada para classificação de "inédito" só existe como componente
temporário, sendo descartada no fim. No final, o coletor seguirá a seguinte
assinatura (lembrando do que são as partes genéricas dele, conforme foi
conversado em
[Reinventando a roda: como escrever streams sem usar stream como base]({% post_url 2026/2026-05-06-reinventando-roda-java-streams %})),
`Collector<T, A, R>`:

- `T`: o elemento que chega e é processado
- `R`: o elemento de retorno
- `A`: o elemento de acumulação, que em muitos casos vem com `?` porque não
  importa pro chamador

Para aqui, o coletor é algo do tipo `Collector<T,  ?, List<T>>`. Além disso,
para criar esse coletor vai ser necessário fornecer o discriminador, a função
que extrai do elemento a chave: `Function<T, K>`.

Aqui vamos seguir por dois caminhos: o caminho dos inéditos e o caminho dos
repetidos. Apesar da ideia ser bem dizer a mesma, existem nuances que eu
gostaria de explorar separadamente.

## Os inéditos! Em cima de coletores existentes

Aqui o ponto é usar os `Collectors` previamente existentes para fazer o
`Collector` adequado, sem se preocupar com otimizações nem nada do tipo.

Como queremos fazer discriminação dos elementos por uma característica, podemos
usar o
[`groupingBy`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/Collectors.html#groupingBy(java.util.function.Function))
que recebe como argumento justamente a função classificadora. Assim, a saída é
um `Map<K, List<T>>`. Daqui eu posso simplesmente pegar o primeiro elemento da
lista (já que o `Collectors.groupingBy` retorna por ordem de aparição). De modo
ainda mais imperativo, eu poderia fazer o seguinte:

```java
List<T> elementos = ...;
Function<T, K> classifier = ...;

final var grupos = elementos.stream().collect(Collectors.groupingBy(classifier));

return grupos.values()
    .stream()
    .map(List::getFirst)
    .toList();
```

Então, como posso expressar isso através de um coletor? Algo como "primeiro eu
faço essa coleta, e depois eu faço esse outro terminador"? Bem, temos o
[`.colletingAndThen`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/Collectors.html#collectingAndThen(java.util.stream.Collector,java.util.function.Function))
que permite passar uma função que faz um novo processamento em cima do final.
Ela mapeia de `R` para um outro tipo desejado, `RR`. No caso, podemos mapear de
`Map<K, List<T>>` para `List<T>`:

```java
List<T> elementos = ...;
Function<T, K> classifier = ...;

final var grupos = elementos.stream()
    .collect(
        Collectors.collectingAndThen(
            Collectors.groupingBy(classifier),
            grupos -> grupos.values()
                            .stream()
                            .map(List::getFirst)
                            .toList()
        )
    );
```

Massa! Mas... e se eu não _precisar_ juntar a lista antes de tudo? No
`groupingBy` tem uma opção de passar um `Collector` para lidar com o conflito
de coisas com a mesma classificação. Nesse caso, creio que um coletor do tipo
`first` resolveria, né? Como que eu implementaria um coletor do tipo `first`?
Bem, vamos lá: ele recebe um `T` e devolve um `T`, sem nada _fancy_ `finisher`.
A única coisa que eu precisaria dele seria um estado interno para indicar se
ele já recebeu alguém, preciso de um "agregador" que simplesmente é algo como
"tenho" ou "não tenho".

A implementação do `first` seria algo assim:

```java
sealed interface Achei<V> {
    V v();
    Achei<V> accept(V v);
    Achei<V> merge(Achei<V> other);

    record Nao<V>() implements Achei<V> {
        @Override
        public V v() {
            return null;
        }

        @Override
        public Achei<V> accept(V v) {
            return new Achei.Sim(v);
        }

        @Override
        public Achei<V> merge(Achei<V> other) {
            return other;
        }
    }

    record Sim<V>(V v) implements Achei<V> {

        @Override
        public Achei<V> accept(V v) {
            return this;
        }

        @Override
        public Achei<V> merge(Achei<V> other) {
            return this;
        }
    }

    final class Wrapper<V> implements Achei<V> {
        Achei<V> wrapped = new Achei.Nao<>();

        @Override
        public V v() {
            return wrapped.v();
        }
        
        @Override
        public Achei<V> accept(V v) {
            wrapped = wrapped.accept(v);
            return this;
        }
        
        @Override
        public Achei<V> merge(Achei<V> other) {
            wrapped = wrapped.merge(other);
            return this;
        }
    }
}

<T> Collector<T, ?, T> first() {
    return Collector.<T, Achei<T>, T>of(
        Achei.Wrapper::new,
        Achei::accept,
        Achei::merge,
        Achei::v
    );
}
```

Aqui no `first()` eu tenho a interface `Achei`, que bem dizer pode ter dois
tipos:

- a que de fato achou, então acabou o processamento e depois disso tudo retorna
  `this`
- a que ainda não achou, então sempre que possível retorna o outro elemento

Mas como `Collector.of` espera que seja algo mutável, e não algo 100% imutável,
coloquei uma implementação de `wrapper` simplesmente para delegar ao que de
fato está sendo trabalhado, independente de qualquer coisa.

Beleza, usando o `groupingBy` junto do `first` agora eu tenho um retorno do
tipo `Map<K, T>`. Para transformar isso em um retorno do tipo `List<T>`, eu
aplico um novo `finisher` que transforma o mapa na lista de seus valores:

```java
List<T> elementos = ...;
Function<T, K> classifier = ...;

final var grupos = elementos.stream()
    .collect(
        Collectors.collectingAndThen(
            Collectors.groupingBy(classifier, first()),
            grupos -> List.copyOf(grupos.values())
        )
    );
```

Portanto, em um único `Collector`:

```java
<T, K> Collector<T, ?, List<T>> firstFromKind(Function<T, K> classifier) {
    return Collectors.collectingAndThen(
        Collectors.groupingBy(classifier, first()),
        grupos -> List.copyOf(grupos.values())
    );
}
```

## Os inéditos! Com coletor totalmente próprio

A ideia agora é inventar um novo coletor adequado para o uso. Não iremos reusar
nenhum coletor prviamente existente, o que não quer dizer que não possamos
reusar ideias...

Bem, vamos lá. Já que falei em reusar ideias, bora? Vamos ter um mapa do tipo
`K => T`. Para manter a ordem da inserção no mapa, vamos usar um
`LinkedHashMap`. Basicamente a ação que vou tomar a cada elemento a ser
inserido será "colocar se não tiver": `putIfAbsent`. E para o `combiner`? Bem,
aqui podemos meio que assumir que vai ter o mesmo comportamento de inserir um a
um iterando sobre o elemento "do lado direito". E para finalizar? Apenas
retornar em ordem os valores! Que o `LinkedHashMap` já me fornece
gratuitamente!

Aparentemente o acumulador pode ser diretamente o `LinkedHashMap`, sem nenhuma
abstração por cima:

```java
<T, K> Collector<T, ?, List<T>> firstFromKind(Function<T, K> classifier) {
    return Collector.of(LinkedHashMap<K, T>::new,
                        (a, t) -> a.putIfAbsent(classifier.apply(t), t),
                        (x, y) -> {
                            for (final var es: y.entrySet()) {
                                x.putIfAbsent(es.getKey(), es.getValue());
                            }
                            return x;
                        },
                        a -> List.copyOf(a.values()));
}
```

## Os repetidos! Ignorando a cabeça

Ok, vamos agora explorar o caminho dos repetidos. Aqui é um caso direto do uso
de coletar as listas e, logo depois, remover a cabeça de cada uma delas. Posso
fazer isso de modo muito semelhante a o que fizemos mais cedo ao usar o
`groupingBy` e depois remapear.

Da base:

```java
Collectors.collectingAndThen(
    Collectors.groupingBy(classifier),
    grupos -> grupos.values()
                    .stream()
                    .map(List::getFirst)
                    .toList()
);
```

Só que agora, no lugar de pegar o primeiro, pego a sublista com todos os
outros!

```java
Collectors.collectingAndThen(
    Collectors.groupingBy(classifier),
    grupos -> grupos.values()
                    .stream()
                    .map(l -> l.subList(1, l.size()))
                    .toList()
);
```

Hmmm, mas isso dá errado com lista vazia... então primeiro filtro?

```java
Collectors.collectingAndThen(
    Collectors.groupingBy(classifier),
    grupos -> grupos.values()
                    .stream()
                    .filter(Predicate.not(List::isEmpty))
                    .map(l -> l.subList(1, l.size()))
                    .toList()
);
```

Ok, ok, funciona. Mas ainda preciso aplainar a lista:

```java
Collectors.collectingAndThen(
    Collectors.groupingBy(classifier),
    grupos -> grupos.values()
                    .stream()
                    .filter(Predicate.not(List::isEmpty))
                    .map(l -> l.subList(1, l.size()))
                    .flatMap(List::stream)
                    .toList()
);
```

Hmmm... e se eu usasse das streams desde mais cedo? No lugar de ficar criando
sublistas? Tipo, para toda string eu vou e pulo o primeiro elemento delas?
Antes de retornar a stream? Nesse caso nem preciso me preocupar com o caso
especial da lista vazia!

```java
Collectors.collectingAndThen(
    Collectors.groupingBy(classifier),
    grupos -> grupos.values()
                    .stream()
                    .flatMap(l -> l.stream().skip(1))
                    .toList()
);
```

E pronto! Não tem como ficar muito mais simples do que isso!

Ao tentar elaborar um coletor próprio, percebi que iria precisar de toda sorte
manter o primeiro elemento, por conta do `combiner`. E o `combiner` iria ter
uma lógica bem complicada, pois se o acumulador do lado direito já tivesse um
elemento associado à classificação em questão, primeiro precisaria absorver o
elemento que gerou àquela chave para depois absorver o resto da lista. E também
seria necessário absorver todos os elementos que foram apresentados porém não
tiveram ainda repetição.

Logo, é mais fácil seguir com essa implementação como "canônica".

# Plot twist: agora com gatherer!

Qual a diferença central entre um `gatherer` e um `collector`? Bem dizer, o
`collector` termina o processamento, enquanto que o `gatherer` permite que ele
continue downstream. Enquanto que um `collector` faz uma operação abstrata que
permite terminar a computação, `gatherer` generaliza a operação intermediária.

> Precisa de um reminder?
> [Java 24 chegou! Vamos reescrever streams com gatherers!]({% post_url 2025/2025-03-21-java-24-gatherers %}),
> para relembrar!

Assim sendo, e se eu precisasse que os inéditos/repetidos aparecessem depois
para continuar fazendo um processamento?

## Inéditos com gatherer

Vamos simplesmente passar para frente apenas os inéditos. Vamos precisar
guardar um conjunto apenas com as classificações que já consumimos.

Esse `gatherer` ele não tem curto circuito, portanto precisa ser `ofGreedy`.
Aqui também a ordem é importante, portanto `ofSequential`. O estado, como dito
acima, vai ser só o conjunto com as chaves que já foram consumidas.

```java
<T, K> Gatherer<T, ?, T> ineditos(Function<T, K> classifier) {
    return Gatherer.ofSequential(HashSet<K>::new,
		Gatherer.Integrator.ofGreedy((state, element, ds) -> {
            final var k = classifier.apply(element);
            if (state.add(k)) {
                return ds.push(element);
            }
            return !ds.isRejecting();
        })
	);
}
```

Para testar:

```java
<T, K> Gatherer<T, ?, T> ineditos(Function<T, K> classifier) {
  return Gatherer.ofSequential(HashSet<K>::new,
		Gatherer.Integrator.ofGreedy((state, element, ds) -> {
            final var k = classifier.apply(element);
            if (state.add(k)) {
                return ds.push(element);
            }
            return !ds.isRejecting();
        })
	);
}


var feature =  Runtime.version().feature();
IO.println(List.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
               .stream()
               .gather(ineditos(i -> i % 3))
               .toList().toString());
// [1, 2, 3]
```

> A propósito, fiquei com preguiça de configurar o ambiente local para permitir
> Java 24, então mergulhei no [PlayGround](https://dev.java/playground/) para
> escrever este código deste artigo!

## Repeditos com gatherer

Basicamente a mesma coisa, mas agora eu empurro no caso de não adicionar e
consulto o downstream no caso de adicionar:

```java
<T, K> Gatherer<T, ?, T> repetidos(Function<T, K> classifier) {
  return Gatherer.ofSequential(HashSet<K>::new,
		Gatherer.Integrator.ofGreedy((state, element, ds) -> {
            final var k = classifier.apply(element);
            if (state.add(k)) {
                return !ds.isRejecting();
            }
            return ds.push(element);
        })
	);
}


var feature =  Runtime.version().feature();
IO.println(List.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
               .stream()
               .gather(repetidos(i -> i % 3))
               .toList().toString());
// [4, 5, 6, 7, 8, 9, 10, 11, 12]
```

Agora... notou uma coisa interessante? Não é nem a questão aqui da simetria com
o código de detecção de inéditos com o de repeditos usando gatherers, mas sim a
semelhança com o código original:

```java
Set<AlgumObjeto> invalidos = new HashSet<>();
Set<String> chavesValidas = new HashSet<>();

for (final var o: todosObjetos) {
    final var k = o.key();
    if (!chavesValidas.add(k)) {
        invalidos.add(o);
    }
}

return invalidos;
```

Eu tenho um estado que é criado fora do laço, porém alimentado dentro do laço.
Então, quando eu adiciono uma nova chave nesse estado, eu ignoro o elemento,
caso contrário eu o coleto (que no gatherer é "passar pra frente"):

```java
(state, element, ds) -> {
    final var k = classifier.apply(element);
    if (state.add(k)) {
        return !ds.isRejecting();
    }
    return ds.push(element);
}
```

Claro que no caso do `gatherer` tem a questão de olhar se o downstream continua
recebendo elementos ou se ele já indica que pode parar, coisa que não é
possível fazer usando a iteração tradicional. Mas o core, o núcleo, toda a
decisão está lá! A estrutura altera um pouco, mas é basicamente a mesma
essência.

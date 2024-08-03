---
layout: post
title: "Trampolim para funções além do primitivo recursivo? Implementação para a função de Ackermann Peter"
author: "Jefferson Quesado"
tags: recursão trampoline java
base-assets: "/assets/trampoline-ackermann-peter/"
---

Desde que aprendi sobre [trampolim]({% post_url 2023-10-02-trampoline %})
eu apenas fazia questão de usar essa estratégia em casos
mais simples, com uma recursão apenas, provavelmente um
subconjunto próprio de funções primitivas recursivas.

Mas surgiu uma necessidade no trabalho de fazer uma computação
extraordinariamente longa. A primeira função que pensei foi
_busy beaver_, mas além de saber que ela é a mais custosa
possível computacionalmente, não tenho muito familiaridade
com ela. Então, fui para um caminho que eu tinha mais
costume: a função de Ackermann Peter.

# Definindo a função de Ackermann Peter

Ela é uma função simples de entender, que recebe dois argumentos
como entrada:

```java
int ackermannPeter(int m, int n) {
    if (m == 0) {
        return n + 1;
    } else if (n == 0) {
        return ackermannPeter(m - 1, 1);
    }
    return ackermannPeter(m - 1, ackermannPeter(m, n - 1));
}
```

Você pode ler mais sobre ela na sua própria [página da Wikipedia](https://en.wikipedia.org/wiki/Ackermann_function),
ou no [Wolframalpha](https://mathworld.wolfram.com/AckermannFunction.html).

# Utilizando a função

{% katexmm %}

Rodei `achermannPeter` para verificar se era possível usá-lo na
demonstração da POC, o primeiro teste (`ackermannPeter(3, 3)`) demonstrou
que se estava calculando corretamente, mas era pouco para o que
se desejava fazer. Quando coloquei `ackermannPeter(4, 3)`, em algum
tempo aconteceu o famoso _stack overflow_. Isso porque a chamada da função
de Ackermann Peter é extremamente profunda, o simples fato de mudar o
primeiro argumento de 3 para 4 fez com que a saída que era 61 passasse
a ser $2^{2^{65536}} - 3$.

{% endkatexmm %}

# Contornando a falta de espaço em pilha

Bem, o problema reside no fato de que a função de Ackermann Peter
é muito intensa na recursão, ocupando rapidamente toda a pilha.
Então, que tal usarmos de continuação para evitar colocar tudo na
pilha? Basicamente, por em prática a ideia do
[trampolim]({% post_url 2023-10-02-trampoline %}).

Revisando o trampolim: o passo precisa ter 3 comportamentos:

- saber se a computação foi finalizada
- resgatar o valor computado
- dar um passo e pegar a próxima continuação

Em suma, para o nosso caso em que se retorna um inteiro:

```java
interface Continuation {
    boolean finished();
    int value();
    Continuation step();
    
    // computation has over
    static Continuation found(int v) {
        return new Continuation() {
            @Override
            public boolean finished() {
                return true;
            }

            @Override
            public int value() {
                return v;
            }

            @Override
            public Continuation step() {
                return this;
            }
        };
    }
    
    // go on computing
    static Continuation goon(Supplier<Continuation> nextStep) {
        return new Continuation() {
            @Override
            public boolean finished() {
                return false;
            }

            @Override
            public int value() {
                return 0;
            }

            @Override
            public Continuation step() {
                return nextStep.get();
            }
        };
    }
}
```

E o trampolim propriamente dito é assim:

```java
static int compute(Continuation c) {
    while (!c.finished()) {
        c = c.step();
    }
    return c.value();
}
```

Mas, como aplicar no caso da função de Ackermann Peter?

Bem, vamos lá. A função é dividida em 3 casos:

- caso base, em que se retorna o valor
- recursão simples, que se retorna uma chamada simples a função de Ackermann Peter
- segunda recursão, em que se faz uma chamada recursiva usando como valor o resultado
  de uma chamada recursiva

Hmmm, temos recursão sendo chamada para prover o resultado de uma chamada recursiva?

Bem, nesse caso seria bom que o trampolim controlasse também o resultado
da segunda recursão. Mas como ele faria isso?

Bem, bora lá. O primeiro passo é detectar que não temos um valor
propriamente dito, mas sim uma `Continuation`. Isso significa que,
no lugar de receber `n` como um inteiro, passarei a receber ele
como uma `Continuation`. E o que fazer então? Bem, basicamente é
verificar se `n` já finalizou e, se sim, tudo segue mais ou menos
normalmente. Mas caso contrário...

Aí daria um único passo nessa continuation e geraria uma nova continuation.

Então, como que ficaria mais ou menos? O esquema geral seria algo assim:

```ts
ackermannPeter(m: int, c: Continuation): Continuation {
    if (!c.finished) {
        return goon(() => {
            const next = c.step();
            return goon(() => ackermannPeter(m, next));
        });
    }
    const n: int = c.value();
    // ... trabalha mais ou menos normal
}
```

Ok, e como seria a parte em que o valor está, de fato, computado? Quando `m <= 0`,
não tem segredo, só dizer que achou o valor `n + 1`. Agora, e com `n <= 0` no caso
de `m != 0`? Aí é um trampolim mais tradicional, usando `1` como valor encontrado
de `n`:

```ts
ackermannPeter(m: int, c: Continuation): Continuation {
    if (!c.finished) {
        return goon(() => {
            const next = c.step();
            return goon(() => ackermannPeter(m, next));
        });
    }
    const n: int = c.value();
    if (m == 0) {
        return found(n + 1);
    } else if (n == 0) {
        return goon(() => ackermannPeter(m - 1, found(1)));
    }
    // ... e aqui o pulo do gato!
}
```

Ok, e o pulo do gato? Bem, o argumento é uma continuação, né?
Então criemos a continuação, passemos ela para uma continuação
que chama Ackermann Peter e retornemos essa continuação. Algo
como:

```ts
const next = goon(() => ackermannPeter(m, found(n - 1)));
return goon(() => ackermannPeter(m - 1, next));
```

Tudo junto?

```ts
ackermannPeter(m: int, c: Continuation): Continuation {
    if (!c.finished) {
        return goon(() => {
            const next = c.step();
            return goon(() => ackermannPeter(m, next));
        });
    }
    const n: int = c.value();
    if (m == 0) {
        return found(n + 1);
    } else if (n == 0) {
        return goon(() => ackermannPeter(m - 1, found(1)));
    }
    return goon(() => ackermannPeter(m - 1, goon(() => ackermannPeter(m, found(n - 1)))));
}
```

E em um esquema Java, menos typescript-esco?

```java
private static Continuation ackermannPeter(int m, Continuation c) {
    if (!c.finished()) {
        return Continuation.goon(() -> {
            final var next = c.step();
            return Continuation.goon(() -> ackermannPeter(m, next));
        });
    }
    int n = c.value();
    if (m <= 0) {
        return Continuation.found(n + 1);
    }
    if (n <= 0) {
        return Continuation.goon(() -> ackermannPeter(m - 1, Continuation.found(1)));
    }
    return Continuation.goon(() ->
        ackermannPeter(m - 1,
            Continuation.goon(() -> ackermannPeter(m, Continuation.found(n - 1)
        )))
    );
}
```

Esse foi o mais próximo que consegui chegar de um trampolim para a função de Ackermann Peter.
Ainda não é perfeito porque chega a serializar a continuação em até `n` passos aninhados
um dentro do outro.

# Adicionando memoização

Bem, e se fosse possível memoizar? Vamos ter duas situações de memoização:

1. aquela que já sabemos o resultado e só precisa retornar o que está na memória
2. sabemos o passo seguinte e conseguimos inferir o resultado atual

Para o passo 1 funcionar, já precisamos estar com a continução do segundo argumento
resolvida. Portanto, só posso usar depois de saber quem é `n`:

```java
private static Continuation ackermannPeterMemo(int m, Continuation c) {
    if (!c.finished()) {
        return Continuation.goon(() -> {
            final var next = c.step();
            return Continuation.goon(() -> ackermannPeterMemo(m, next));
        });
    }
    int n = c.value();
    if (jah tem memoizado para(m, n)) {
        return memoization;
    }
    if (m <= 0) {
        return Continuation.found(n + 1);
    }
    if (n <= 0) {
        return Continuation.goon(() -> ackermannPeterMemo(m - 1, Continuation.found(1)));
    }
    return Continuation.goon(() ->
        ackermannPeterMemo(m - 1,
            Continuation.goon(() -> ackermannPeterMemo(m, Continuation.found(n - 1)
        )))
    );
}
```

Ok, ainda não consigo fazer muita coisa porque não ensino os resultados. Bem,
podemos ensinar a primeira classe de resultados, que é quando `m <= 0`:

```java
private static Continuation ackermannPeterMemo(int m, Continuation c) {
    if (!c.finished()) {
        return Continuation.goon(() -> {
            final var next = c.step();
            return Continuation.goon(() -> ackermannPeterMemo(m, next));
        });
    }
    int n = c.value();
    if (jah tem memoizado para(m, n)) {
        return memoization;
    }
    if (m <= 0) {
        memoizar(m, n).o valor(n + 1);
        return Continuation.found(n + 1);
    }
    if (n <= 0) {
        return Continuation.goon(() -> ackermannPeterMemo(m - 1, Continuation.found(1)));
    }
    return Continuation.goon(() ->
        ackermannPeterMemo(m - 1,
            Continuation.goon(() -> ackermannPeterMemo(m, Continuation.found(n - 1)
        )))
    );
}
```

Ok, parece interessante. Mas aqui prende para valor de `m` constante `0` (já que
em tese nunca chega em negativo, exceto em caso de fluke). Vamos
expandir para outros valores de `m`? Se nós soubermos quanto seria para `m-1, 1` já conseguimos
aprender para `m, 0`:

```java
private static Continuation ackermannPeterMemo(int m, Continuation c) {
    if (!c.finished()) {
        return Continuation.goon(() -> {
            final var next = c.step();
            return Continuation.goon(() -> ackermannPeterMemo(m, next));
        });
    }
    int n = c.value();
    if (jah tem memoizado para(m, n)) {
        return memoization;
    }
    if (m <= 0) {
        memoizar(m, n).o valor(n + 1);
        return Continuation.found(n + 1);
    }
    if (n <= 0) {
        if (jah tem memoizado para(m-1, 1)) {
            memoizar(m, n).o valor(memoization);
            return memoization;
        }
        return Continuation.goon(() -> ackermannPeterMemo(m - 1, Continuation.found(1)));
    }
    return Continuation.goon(() ->
        ackermannPeterMemo(m - 1,
            Continuation.goon(() -> ackermannPeterMemo(m, Continuation.found(n - 1)
        )))
    );
}
```

Ok, muito bom. Conseguimos expandir para diversos valores, mas ainda temos
a classe mais abundante de valores: para quando temos argumentos estritamente
positivos, que nesse caso teremos duas chamadas à função de Ackermann Peter.

Bem, podemos primeiro checar se temos memoização para `m, n-1`. Se tiver, apesar
de ainda não conseguirmos usar para aprender, ao menos evitamos algumas computações.
Se não tiver, aí seguimos com o cálculo clássico:

```java
private static Continuation ackermannPeterMemo(int m, Continuation c) {
    if (!c.finished()) {
        return Continuation.goon(() -> {
            final var next = c.step();
            return Continuation.goon(() -> ackermannPeterMemo(m, next));
        });
    }
    int n = c.value();
    if (jah tem memoizado para(m, n)) {
        return memoization;
    }
    if (m <= 0) {
        memoizar(m, n).o valor(n + 1);
        return Continuation.found(n + 1);
    }
    if (n <= 0) {
        if (jah tem memoizado para(m-1, 1)) {
            memoizar(m, n).o valor(memoization);
            return memoization;
        }
        return Continuation.goon(() -> ackermannPeterMemo(m - 1, Continuation.found(1)));
    }
    // note que aqui vejo a NÃO memoização agora
    if (!jah tem memoizado para(m-1, 1)) {
        return Continuation.goon(() ->
            ackermannPeterMemo(m - 1,
                Continuation.goon(() -> ackermannPeterMemo(m, Continuation.found(n - 1)
            )))
        );
    }
    // ok, aqui já podemos seguir com o valor memoizado da chamada recursiva interna
    return Continuation.goon(() ->
        ackermannPeterMemo(m - 1, Continuation.found(memoization))
    );
}
```

Beleza. Agora, podemos verificar se por acaso já conhecemos algo
de `m-1, memoization`, né?

```java
private static Continuation ackermannPeterMemo(int m, Continuation c) {
    if (!c.finished()) {
        return Continuation.goon(() -> {
            final var next = c.step();
            return Continuation.goon(() -> ackermannPeterMemo(m, next));
        });
    }
    int n = c.value();
    if (jah tem memoizado para(m, n)) {
        return memoization;
    }
    if (m <= 0) {
        memoizar(m, n).o valor(n + 1);
        return Continuation.found(n + 1);
    }
    if (n <= 0) {
        if (jah tem memoizado para(m-1, 1)) {
            memoizar(m, n).o valor(memoization);
            return memoization;
        }
        return Continuation.goon(() -> ackermannPeterMemo(m - 1, Continuation.found(1)));
    }
    // note que aqui vejo a NÃO memoização agora
    if (!jah tem memoizado para(m, n - 1)) {
        return Continuation.goon(() ->
            ackermannPeterMemo(m - 1,
                Continuation.goon(() -> ackermannPeterMemo(m, Continuation.found(n - 1)
            )))
        );
    }
    // ok, aqui já podemos seguir com o valor memoizado da chamada recursiva interna
    if (jah tem memoizado para(m - 1, memoization)) {
        memoizar(m, n).o valor(novaMemoization);
        return novaMemoization;
    }
    return Continuation.goon(() ->
        ackermannPeterMemo(m - 1, Continuation.found(memoization))
    );
}
```

Ok, muito bonito. Mas, como memoizar isso? Bem, a estrutura mais fácil
seria um `hashmap`. Mas pra isso preciso de uma chave, e a chave se for
um `record` implica na criação de muitos objetos para simplesmente verificar
se está dentro do mapa.

Mas sabe o que é legal? Que eu preciso de apenas 64 bits para representar
todos os meus parâmetros, `m` e `n`. Como? Colocando `m` na parte mais
significativa de um `long` e `n` na menos:

```java
static long key(int m, int n) {
    return ((long)m) << 32 | (long) n;
}
```

_Voi là_. O java trata de fazer o _boxing_ automaticamente de `long -> Long`,
então não preciso me preocupar mais com isso. E o melhor: o Java vai ser ótimo
fazendo reuso de objetos.

> A propósito, o excesso de _casts_ para `long` na função acima é para garantir
> que vai usar a operação de 64 bits corretamente e não perder precisão.

O primeiro teste podemos usar uma memória global:

```java
static HashMap<Long, Integer> paMemory = new HashMap<>();
private static Continuation ackermannPeterMemo(int m, Continuation c) {
    if (!c.finished()) {
        return Continuation.goon(() -> {
            final var next = c.step();
            return Continuation.goon(() -> ackermannPeterMemo(m, next));
        });
    }
    int n = c.value();
    {
        long k = key(m, n);
        Integer memoized = paMemory.get(k);
        if (memoized != null) {
            return Continuation.found(memoized);
        }
    }
    if (m <= 0) {
        long k = key(m, n);
        paMemory.put(k, n + 1);
        return Continuation.found(n + 1);
    }
    if (n <= 0) {
        long kRecursivo = key(m - 1, 1);
        Integer memoized = paMemory.get(kRecursivo);
        if (memoized != null) {
            long k = key(m, n);
            paMemory.put(k, memoized);
            return Continuation.found(memoized);
        }
        return Continuation.goon(() -> ackermannPeterMemo(m - 1, Continuation.found(1)));
    }
    // note que aqui vejo a NÃO memoização agora
    long kRecursivoInterno = key(m, n - 1);
    Integer memoizedInterno = paMemory.get(kRecursivoInterno);
    if (memoizedInterno == null) {
        return Continuation.goon(() ->
            ackermannPeterMemo(m - 1,
                Continuation.goon(() -> ackermannPeterMemo(m, Continuation.found(n - 1)
            )))
        );
    }
    // ok, aqui já podemos seguir com o valor memoizado da chamada recursiva interna
    long kRecursivoExterno = key(m - 1, memoizedInterno);
    Integer memoizedExterno = paMemory.get(kRecursivoExterno);
    if (memoizedExterno != null) {
        long k = key(m, n);
        paMemory.put(k, memoizedExterno);
        return Continuation.found(memoizedExterno);
    }
    return Continuation.goon(() ->
        ackermannPeterMemo(m - 1, Continuation.found(memoizedInterno))
    );
}
```

Essa função computa fazendo 53.406 chamadas recursivas para `ackermannPeterMemo(3, 2)`,
enquanto que a primeira implementação fazia 1.073.692.222 operações.

Agora, vamos nos livrar do global? Basicamente vai ser transformar o que antes era
global em argumento.

```java
private static Continuation ackermannPeterMemo(int m, Continuation c, HashMap<Long, Integer> paMemory) {
    if (!c.finished()) {
        return Continuation.goon(() -> {
            final var next = c.step();
            return Continuation.goon(() -> ackermannPeterMemo(m, next, paMemory));
        });
    }
    int n = c.value();
    {
        long k = key(m, n);
        Integer memoized = paMemory.get(k);
        if (memoized != null) {
            return Continuation.found(memoized);
        }
    }
    if (m <= 0) {
        long k = key(m, n);
        paMemory.put(k, n + 1);
        return Continuation.found(n + 1);
    }
    if (n <= 0) {
        long kRecursivo = key(m - 1, 1);
        Integer memoized = paMemory.get(kRecursivo);
        if (memoized != null) {
            long k = key(m, n);
            paMemory.put(k, memoized);
            return Continuation.found(memoized);
        }
        return Continuation.goon(() -> ackermannPeterMemo(m - 1, Continuation.found(1), paMemory));
    }
    // note que aqui vejo a NÃO memoização agora
    long kRecursivoInterno = key(m, n - 1);
    Integer memoizedInterno = paMemory.get(kRecursivoInterno);
    if (memoizedInterno == null) {
        return Continuation.goon(() ->
            ackermannPeterMemo(m - 1,
                Continuation.goon(() -> ackermannPeterMemo(m, Continuation.found(n - 1), paMemory
            )), paMemory)
        );
    }
    // ok, aqui já podemos seguir com o valor memoizado da chamada recursiva interna
    long kRecursivoExterno = key(m - 1, memoizedInterno);
    Integer memoizedExterno = paMemory.get(kRecursivoExterno);
    if (memoizedExterno != null) {
        long k = key(m, n);
        paMemory.put(k, memoizedExterno);
        return Continuation.found(memoizedExterno);
    }
    return Continuation.goon(() ->
        ackermannPeterMemo(m - 1, Continuation.found(memoizedInterno), paMemory)
    );
}
```

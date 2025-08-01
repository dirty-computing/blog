---
layout: post
title: "Trampolim, exemplo em Java"
author: "Jefferson Quesado"
tags: recursão trampoline java tail-call
base-assets: "/assets/trampoline/"
---

Vamos fazer um programinha bem simples que soma os
números de `n` até 0? Só que, no lugar de fazer ele
iterativo, que tal fazer recursivo?

Bem, vamos chamar esse programa de `sum`. Sabemos que
`sum(0) == 0`, então temos o caso base. E como chegamos
no caso base? Bem, `sum(n) == n + sum(n-1)`, até que
eventualmente chegamos em `sum(0)`. Ficaria assim em Java:

```java
int sum(int n) {
    if (n == 0) {
        return 0;
    }
    return n + sum(n - 1);
}
```

# Problema de recursão?

Bem, recursão tem um problema inerente quando o caso
base está muito distante do valor passado... na maioria
das linguagens, a chamada de função acaba fazendo uso
da _stack_ do programa para inserir os dados sobre a
chamada da função, então eventualmente uma recursão muito
grande poderá gerar um estouro de pilha.

Mas, será que tem como evitar isso? Na real, tem sim.
E isso é uma estratégia _as old as time_. Se chama _trampoline_.

# O trampolim

Basicamente a estratégia do _trampoline_ é você fazer um
pedaço do programa que retorna um "valor" ou uma
"continuation". O que seria a continuation? Uma função que
irá continuar o processamento.

É mais ou menos isso daqui:

```
let trampolim = primeiraChamada(input);

while (trampolim is continuation) {
    trampolim = trampolim.continue();
}
return trampolim;
```

## O que seria a continuation do `sum`?

Vamos modelar o programa `sum` para, no lugar de ser
simplesmente recursivo, ter uma continuation. Bem, uma
maneira é passando o `acc` como uma espécie de objeto
passado pela continuidade. Então, ao chegar em
`sum_trampoline(0, acc)` retornemos `acc`. E
passar para o passo seguinte? Bem...

Bora lá, saímos de `sum_trampoline(n, acc)` para
`sum_trampoline(n-1, acc+n)`. E a primeira entrada
é com `sum_trampoline(n, 0)`.

Logo, ficaria assim o código:

```java
Object sum_trampoline_bootstrap(int n) {
    return sum_trampoline(n, 0);
}

Object sum_trampoline(int n, int acc) {
    if (n == 0) {
        return acc;
    }
    return (Supplier<Object>) () -> sum(n - 1, acc + n);
}
```

## Descrevendo trampolim com tipos

O trampolim precisa ter mais ou menos a seguinte forma:

```
let trampolim = primeiraChamada(input);

while (trampolim is continuation) {
    trampolim = trampolim.continue();
}
return trampolim;
```

Só que isso tem uma liberdade de codificação muito grande,
não é muito literal para o mundo Java. Podemos detectar que
é continuidade perguntando ao objeto. E que tal se perguntarmos
"já achou o valor?"? Outra coisa também é que, como em Java
não temos sum-types, o `return trampolim` ali literalmente
retornaria o tipo `trampolim`, no lugar de retornar o valor.
Podemos retornar `trampolim.value()`.

Finalmente, temos um ponto crucial que é o _bootstrapping_ do
trampolim. Para isso, poderíamos ter uma função que
transformasse o input no trampolim de retorno adequado. E input
e resultado podem ser generalizados para melhor uso:

```java
public static <IN, R> R trampoline(IN input,
                                   Function<IN, TrampolineStep<R>> trampolinebootStrap) {
  TrampolineStep<R> nextStep = trampolinebootStrap.apply(input);
  while (!nextStep.gotValue()) {
    nextStep = nextStep.runNextStep();
  }
  return nextStep.value();
}
```

E a interface de `TrampolineStep<R>`?

De instância, ficaram definidos 3 métodos:
- `gotValue`, pergunta se já tem valor
- `value`, retorna o valor encontrado
- `runNextStep`, retorna um valor ou uma continuidade

Bem, basicamente ela vai ter dois estados:
- achou o valor
- é uma continuidade

Então podemos colocar com métodos estáticos para
linicialização dela. Para o caso de já achou o valor,
precisa-se passar o valor:

```java
static <X> TrampolineStep<X> valueFound(X value) {
    return new TrampolineStep<>() {
        @Override
        public boolean gotValue() {
            return true;
        }

        @Override
        public X value() {
            return value;
        }

        @Override
        public TrampolineStep<X> runNextStep() {
            return this;
        }
    };
}
```

Para o caso de contnuidade, precisa passar como obter
o próximo item da continuidade:

```java
static <X> TrampolineStep<X> goonStep(Supplier<TrampolineStep<X>> x) {
    return new TrampolineStep<>() {
        @Override
        public boolean gotValue() {
            return false;
        }

        @Override
        public X value() {
            throw new RuntimeException("dont call this");
        }

        @Override
        public TrampolineStep<X> runNextStep() {
            return x.get();
        }
    };
}
```

Para o `sum_trampoline`, como ele ficaria?

```java
TrampolineStep<Integer> sum_trampoline_bootstrap(int n) {
    return sum_trampoline(n, 0);
}

TrampolineStep<Integer> sum_trampoline(int n, int acc) {
    if (n == 0) {
        return TrampolineStep.valueFound(acc);
    }
    return TrampolineStep.goonStep(() -> sum_trampoline(n - 1, acc + n));
}
```

# Tail call Fibonacci

A implementação clássica de Fibonacci segue a definição recursiva:

```java
int fib(int n) {
    if (n <= 1) {
        return n;
    }
    return fib(n-1) + fib(n-2);
}
```

Existe ainda a versão iterativa, que desenrola a definição de
Fibonacci não recursivamente, mas para a frente: começando de 0 e
1 e indo até o valor correspondente:

```java
int fib_iterativo(int n) {
    int a = 0, b = 1;
    if (n == 0) {
        return a;
    }
    int i = 1;
    while (i < n) {
        int x = a + b;
        a = b;
        b = x;
        i++;
    }
    return b;
}
```

Essa implementação tem uma versão rolando para frente, usando
o "tail call recursion":

```java
int fib_tc_entrada(int n) {
    return fib_tc(0, 1, 0, n);
}

int fib_tc(int a, int b, int i, int n) {
    if (i == n) {
        return a;
    }
    return fib_tc(b, a+b, i+1, n);
}
```

Aqui separei na interface de entrada que prepara os dados
que serão usados no Fibonacci com tail call recursion. Como
ele avança para frente, começamos com os mapeamentos
`fib[0] => 0`, `fib[1] => 1` navegando a partir do índice
`0` até chegar no índice `n`.

## Fibonacci, de tail call a trampoline

Bem, o exemplo de `fib_tc` já dá uma ideia bem boa do que
seria o `trampoline` para Fibonacci:

```java
TrampolineStep<Integer> fib_bootstrap(int n) {
    return fib_trampoline(0, 1, 0, n);
}

TrampolineStep<Integer> fib_trampoline(int a, int b, int i, int n) {
    if (i == n) {
        return TrampolineStep.valueFound(a);
    }
    return TrampolineStep.goonStep(() -> fib_trampoline(b, a+b, i+1, n));
}
```

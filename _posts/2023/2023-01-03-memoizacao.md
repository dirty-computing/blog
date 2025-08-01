---
layout: post
title: "Vamos memoizar? Desafio da recursão"
author: "Jefferson Quesado"
tags: recursão matemática
base-assets: "/assets/memoizacao/"
---

Peguei o [seguinte desafio no Twitter](https://twitter.com/wesleynepo/status/1594888656233418752):

{% katexmm %}

$$
f(n) = \left\{
    \begin{array}{lr}
    n & \text{se } n < 3\\
    f(n-1) + 2 f(n-2) + 3 f(n-3) & \text{se } n \ge 3
    \end{array}
\right.
$$

{% endkatexmm %}

O problema originalmente pedia para calcular:

1. usando recursão direta
1. usando iteração

Vamos resolver o problema?

# Código de companhia

O código final de testes está no companion:
[https://gitlab.com/computaria/blog-companion/-/tree/main/memoizacao](https://gitlab.com/computaria/blog-companion/-/tree/main/memoizacao)

# Recursão direta

Aqui a ideia é simplesmente definir uma recursão. Nada de crítico:

```js
const f = (n) => n < 3? n: f(n-1) + 2*f(n-2) + 3*f(n-3)
```

## Complexidade

Primeiro ponto para ver aqui é: essa função tem fim?

Pois bem. Note que a recursão está sendo sempre passando um valor monotonicamente
menor do que o parâmetro de entrada. Ela é diferente da função de Ackermann-Péter:

{% katexmm %}

$$
A(m, n) = \left\{
    \begin{array}{lr}
    n+1 & \text{se } m == 0\\
    A(m-1, 1) & \text{se } m > 0 \text{ e } n == 0\\
    A(m-1, A(m, n-1)) & \text{se } m > 0 \text{ e } n > 0\\
    \end{array}
\right.
$$

O primeiro desdobramento da função de Ackermann-Péter é caso base.
Já o segundo caso tem uma pegada em que um argumento diminui e o outro
aumenta.

Já no terceiro caso... Bem, no terceiro caso o parâmetro passado para a
função de Ackermann-Péter é o resultado da chamada da função de Ackermann-Péter.

Note que o primeiro argumento da função de Ackermann-Péter na recursão é sempre
menor. Porém temos um comportamento interessante em relação ao segundo arguento:
seu valor aumenta dependendo de um caso menor menor do retorno de Ackermann-Péter
da chamada original, ou simplemente aumenta quando $n = 0$ e $m > 0$.

Note que, para calcular o argumento $n$ no terceiro desdobramento da recursão,
iremor sempre lidar com um problema menor do que o inicial. Para servir de
exemplo, peguemos $A(3, 2)$ e foquemos apenas no passo recursivo para achar o
segundo argumento. Para calcular $A(3, 2)$, precisamos antes entender $A(3, 1)$,
e para entender de $A(3, 1)$ precisamos de $A(3, 0)$. A seguir todo o caminho
necessário percorrer para achar os diversos $n$ passados adiante:

- $A(3, 2)$
- $A(3, 1)$
- $A(3, 0)$
- $A(2, 1)$
- $A(2, 0)$
- $A(1, 1)$
- $A(1, 0)$
- $A(0, 1)$

Dá para ter uma noção que essa função vai chegar ao fim, né? Em todo momento
ela precisa resolver uma instância sempre menor de si mesma, e mesmo quando há
um aumento em um dos argumentos, esse aumento é calculado em cima de um
problema menor do que o problema original.

Voltando a função do exercício, a função sempre reduz o problema ao chamar-se
recursivamente. E esse problema menor é sempre rumo ao caso base, que é com
$n < 3$. Se até na função de Ackermann-Péter se via a possibilidade de se
chegar no caso base, esta função tem sim um fim.

E qual a complexidade esperada dessa função? Bem, se formos rigorosos e ela
sempre entrar nas recursões, ela ocupará $o(n)$ de memória extra porque irá
chamar até chegar no 3.

```
f(n)
  |
  +------+------+
  |      |      |
  f(n-1) f(n-2) f(n-3)
  |
  +------+------+
  |      |      |
  f(n-2) f(n-3) f(n-4)
  |
  +------+------+
  |      |      |
  f(n-3) f(n-4) f(n-5)
  |
  +------+------+
  |      |      |
  f(n-4) f(n-5) f(n-6)
  |
  +------+------+
  |      |      |
  f(n-5) f(n-6) f(n-7)
```

E temos no máximo $n$ níveis ($n-2$ pra ser exato, mas isso não importa para
este assunto atual).

A cada nível que se desse são abertos 3 ramos de recursão distintos. Cada ramo
desse precisa ser navegado até as suas folhas, e cada descida eu obtenho 3 novos
ramos. Portanto, se eu fosse focar apenas na descida completa de dois níveis:

```
f(n)
  |
  +------+---------+
  |      |         |
  f(n-1) f(n-2)    f(n-3)  // derivados f(n)
  |      |         |
  +------|--+------|-+
  |      |  |      | |
  f(n-2) |  f(n-3) | f(n-4)  // derivados f(n-1)
         |         |
  +------+--+------|-+
  |         |      | |
  f(n-3)    f(n-4) | f(n-5)  // derivados f(n-2)
                   |
  +---------+------+-+
  |         |        |
  f(n-4)    f(n-5)   f(n-6)  // derivados f(n-3)
```

O que é um indicativo de que é um créscimo $o(3^n)$, já que a cada
elemento em um nível eu terei o triplo no nível anterior.

Mas isto seria se seguisse a implementação recursiva desse algoritmo
fazendo sempre o recálculo. Mas e se... aproveitássemos os cálculos?

Observe que $f$ é uma função pura: ela depende apenas dos seus argumentos
para ser calculada. Uma vez que se encontra $f(30)$, o valor
de $f(30)$ será conhecido e podemos memoizar o valor alcançado.

Portanto, ao aplicar a memoização, conseguimos reduzir a complexidade
temporal de $o(3^n)$ para $o(n-m)$ (amortizado), onde $m$ é o último
valor memoizado obtido.
{% endkatexmm %}

## Memoização

Memoização é o processo de guardar o valor previamente obtido de uma
função pura para poder usá-lo novamente. Isto é útil quando a função
para calcular é cara, principalmente se for recursiva e cada passo da
recursão for caro. Quando uma função não é pura, usar memoização vai
gerar resultados incorretos, visto que ela depende de estado externo
aos seus argumentos.

Um exemplo de função impura:

```ts
const myFunc = (() => {
  let acc = 0;
  return (x: number) => {
    acc += x;
    return acc;
  };
})();

console.log(myFunc(1));
console.log(myFunc(1));
```

Ao executar, obtemos:

```
$ npx ts-node <<EOL
> const myFunc = (() => {
>   let acc = 0;
>   return (x: number) => {
>     acc += x;
>     return acc;
>   };
> })();
> 
> console.log(myFunc(1));
> console.log(myFunc(1));
> EOL
1
2
```

Mesmos argumentos, valores distintos. Portanto a função é impura.

Agora, como podemos fazer uma memoização para a função original?

```ts
const f = (n) => n < 3? n: f(n-1) + 2*f(n-2) + 3*f(n-3)
```

Bem, uma maneira é deixar ela com uma memória. Como fazer isso? Bem, podemos
botar num módulo e exportar apenas a função.

```ts
const memory: number[] = [];
export function f(n: number): number {
  // TODO: usar memoização aqui
  return n < 3? n: f(n-1) + 2*f(n-2) + 3*f(n-3)
}
```

Muito bem, aqui conseguimos já deixar visível apenas a função. Quem for
consumir o módulo precisa dar um `import { f } from './memoizacao.js'`, algo
assim, dependendo de como foi organizado o código. Tentar importar a variável
`memory` vai resultar em erro:

```
src/index.ts:1:13 - error TS2459: Module '"./memoizacao.js"' declares 'memory' locally, but it is not exported.

1 import { f, memory } from './memoizacao.js'
              ~~~~~~

  src/memoizacao.ts:1:7
    1 const memory: number[] = [];
            ~~~~~~
    'memory' is declared here.
```

> Se você preferir escrever como arrow-function, tome cuidado com os tipos,
> [tem este _zettelstaken_](https://github.com/jeffque/digital-garden/blob/main/ts-lambda-type.md)
> tentando explicar.

Agora, focar na memoização de `f`. Primeiro, precisamos lidar com os casos
base. Existem duas alternativas para isso:

- escrever na memória logo de cara
- deixar o caso base na função

Deixar o caso base na função é mais simples:

```ts
const memory: number[] = [];
export function f(n: number): number {
  if (n < 3) {
    return n;
  }
  const fromMemory = memory[n];
  if (fromMemory != undefined) {
    return fromMemory;
  }
  // TODO: usar memoização aqui
  return f(n-1) + 2*f(n-2) + 3*f(n-3)
}
```

Deixar na memória logo de cara é. digamos, controverso. E ainda assim
nesse caso não protege de tudo (eg, não tratei números negativos):

```ts
const memory: number[] = [];

for (let i = 0; i < 3; i++) {
  memory[i] = i;
}

export function f(n: number): number {
  const fromMemory = memory[n];
  if (fromMemory != undefined) {
    return fromMemory;
  }
  // TODO: usar memoização aqui
  return f(n-1) + 2*f(n-2) + 3*f(n-3)
}
```

Para de fato memoizar, é o mesmo trabalho nos dois ramos. Basicamente é
atribuir à posição `n` de memória qual o valor do cálculo. Um jeito
simples de fazer isso é colocar a atribuição no `return`:

```ts
return memory[n] = f(n-1) + 2*f(n-2) + 3*f(n-3)
```

Particularmente esse jeito não me agrada. Para mim fica mais claro colocar
o resultado do cálculo em uma variável, e então usar tal variável para
colocar na memória e no retorno:

```ts
const newValue = f(n-1) + 2*f(n-2) + 3*f(n-3);
memory[n] = newValue;
return newValue;
```

Então, com isso, agora temos uma versão memoizada:

```ts
const memory: number[] = [];
export function f(n: number): number {
  if (n < 3) {
    return n;
  }
  const fromMemory = memory[n];
  if (fromMemory != undefined) {
    return fromMemory;
  }
  const newValue = f(n-1) + 2*f(n-2) + 3*f(n-3);
  memory[n] = newValue;
  return newValue;
}
```

# E a solução iterativa?

Bem, para a solução iterativa precisamos dar um passo para trás.

Lembram da função para achar o número de Fibonacci?

{% katexmm %}

$$
fib(n) = \left\{
    \begin{array}{lr}
    0 & \text{se } n == 0\\
    1 & \text{se } n == 1\\
    f(n-1) + f(n-2) & \text{se } n \gt 1
    \end{array}
\right.
$$

{% endkatexmm %}

Poderíamos fazer a implementação usando memoização também:

```ts
const memory: number[] = [];
export function fib(n: number): number {
  if (n == 0) {
    return 0;
  }
  if (n == 1) {
    return 1;
  }
  const fromMemory = memory[n];
  if (fromMemory != undefined) {
    return fromMemory;
  }
  const newValue = fib(n-1) + fib(n-2);
  memory[n] = newValue;
  return newValue;
}
```

Mas ainda iríamos cair na questão do: e como fazer iterativo?

No caso da iteração da função de Fibonacci você guarda os valores
anteriores, calcula o novo valor, então "envelhece" as variáveis
controladamente:

```ts
const fib = (n: number) => {
  if (n == 0) {
    return 0;
  }
  if (n == 1) {
    return 1;
  }
  let fib_n_minus_2 = 0;
  let fib_n_minus_1 = 1;
  let fib_n = -1;
  for (let i = 2; i <= n; i++) {
    fib_n = fib_n_minus_1 + fib_n_minus_2;
    fib_n_minus_2 = fib_n_minus_1;
    fib_n_minus_1 = fib_n;
  }
  return fib_n;
}
```

Será que poderíamos fazer algo nesse sentido? E a resposta é: sim.

Comecemos com o caso base, como já começamos antes. Então, como se
precisa usar a função avaliada em 3 valores anteriores distintos,
guardemos esses valor na interação, algo assim:

```ts
let f_n_minus_3 = 0;
let f_n_minus_2 = 1;
let f_n_minus_1 = 2;
let f_n = -1;
```

Quando encontrar o novo valor para `f_n`, façamos o envelhecimento
de modo extremamente controlado. O valor atual de `f_n_minus_3` será
esquecido, então podemos sobrescrever esse valor logo de cara. O
novo valor a ser armazenado nele será `f_n_minus_2`, que por sua vez
essa variável irá guardar o que está em `f_n_minus_1`, que por sua vez
irá guardar `f_n`:

```ts
f_n_minus_3 = f_n_minus_2;
f_n_minus_2 = f_n_minus_1;
f_n_minus_1 = f_n;
```

E para calcular o novo valor de `f_n`? Bem, segue a fórmula mesmo:

```ts
f_n = f_n_minus_1 + 2*f_n_minus_2 + 3*f_n_minus_3;
```

E só isso.

```ts
 const f_iterative = (n: number) => {
  if (n < 3) {
    return n;
  }
  let f_n_minus_3 = 0;
  let f_n_minus_2 = 1;
  let f_n_minus_1 = 2;
  let f_n = -1;
  for (let i = 3; i <= n; i++) {
    f_n = f_n_minus_1 + 2*f_n_minus_2 + 3*f_n_minus_3;
    f_n_minus_3 = f_n_minus_2;
    f_n_minus_2 = f_n_minus_1;
    f_n_minus_1 = f_n;
  }
  return f_n;
}
```

{% katexmm %}

A solução iterativa roda em tempo $o(n)$, tal qual a solução
iterativa da função de Fibonacci.

{% endkatexmm %}

# Memoização aplicada genericamente é possível?

Peguemos uma função pura qualquer. Conseguimos memoizar ela? A resposta é
sim. Mas essa memoização será sempre útil? A resposta é... depende.

Peguemos a função `f` que motivou este post:

```ts
const f = (n: number): number => n < 3? n: f(n-1) + 2*f(n-2) + 3*f(n-3)
```

Podemos criar uma memoização em cima dela assim:

```ts
function createMemoization(f: (n:number):number): (n:number):number {
  const memory: number[] = [];
  return (n) => {
    const fromMemory = memory[n];
    if (fromMemory != undefined) {
      return fromMemory;
    }
    const newValue = f(n);
    memory[n] = newValue;
    return newValue;
  };
}
```

Mas essa forma de memoização tem suas limitações. Por exemplo, ela não permite
que se aprenda recursivamente os valores que deveriam ser retornados.

Então, como melhorar isso? Bem, usando uma função recursiva que recebe como
entrada dois valores, sendo o primeiro valor a mesma entrada e como segundo
valor a função em si, e o retorno seria a mesma coisa.

Para tal, vamos definir o tipo desta função?

```ts
type RecFunc = (n: number, f: RecFunc) => number;
```

Um exemplo de função que é desse tipo:

```ts
function f_self_recursive(n: number, self_f: RecFunc) => {
  if (n < 3) {
    return n;
  }
  return self_f(n-1, self_f) + 2*self_f(n-2, self_f) + 3*self_f(n-3, self_f);
}
```

E posso transformar essa função em uma função recursiva simples desse jeito:

```ts
function fix_point_memoized(f: RecFunc): (n: number) => number {
  const memory: number[] = [];
  const memoized_f = (n: number, self_f: RecFunc): number => {
    const fromMemory = memory[n];
    if (fromMemory != undefined) {
      return fromMemory;
    }
    const newValue = f(n, self_f);
    memory[n] = newValue;
    return newValue;
  }
  return n => memoized_f(n, memoized_f);
}
```

E para transformar a função para por a memoização recursiva:

```ts
const f_self_memo = fix_point_memoized(f_self_rec);
```

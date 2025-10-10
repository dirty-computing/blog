---
layout: post
title: "A vida sem if, um desafio para escrever código sem estruturas de controle"
author: "Jefferson Quesado"
tags: js
base-assets: "/assets/controless/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Meu amigo {{ site.data.podcasts.people["samsantosb"] }} publicou no Twitter um
exemplo de código JS em que a execução condicional de um trecho de código era
disparada sem a necessidade de estruturas sintáticas. Era algo mais ou menos
assim:

```js
const n = 15;
const fizz = n % 3 == 0;
const buzz = n % 5 == 0;

fizz && (() => console.log("fizz"))()
buzz && (() => console.log("buzz"))()
!(fizz || buzz) && (() => console.log(n))()
```

Ele já era conhecido como Samuelse, por já ter banido o `else` em outros
momentos, pois afinal _early return_ deixa o código mais limpo e com menos
voltas para entender.

Ao ver esse trecho de código e esse estilo de programar... pensei... "e se eu
fizesse um programa todinho sem estruturas sintáticas de controle de fluxo?"
Então eu lancei um auto-desafio, que chamei de `controlless`:

1. vai ser em JS, sem tipos explícitos
1. você pode criar valores constantes, sem `let` nem `var`, apenas `const`
1. você tem total liberdade de usar OPERADORES, mas não pode usar controle
   sintático
1. recursão é permitida
1. só pode hazer um único `return`
1. só posso criar _arrow functions_

Meu desafio vai ser escrever `quicksort` no estilo `controlless`.

# Explicando o funcionamento do código do Sam

O Sam usou operadores binários para fazer a execução. Ao fazer `a && b`, ele
está avaliando uma expressão lógica em que, se `a` for _truthy_, o valor de `b`
é carregado. Por exemplo:

```js
const awesomeFunction = () => console.log("AWESOME")
false && awesomeFunction()
```

Aqui o valor `false` é _falsy_, portanto o resultado da operação `false && ???`
será sempre falso, não se fazendo necessário computar o valor da função. Então
nada é impresso. Diferente disto daqui:

```js
const awesomeFunction = () => console.log("AWESOME")
true && awesomeFunction()
```

que imprime `AWESOME` no console.

Se aproveitando desse operador, ele também criou uma função
imediatamente chamada (IIFE, Immediately Invoked Function Expression) é uma
expressão em que uma função é criada e imediatamente executada.

Por exemplo, para uma função que calcula quantos passos a função de Collatz vai
iterar até obter `1` como resposta. Para quem não sabe, essa função é a do
`3n+1`:

{% katexmm %}
$$
c(n) = \left\{
    \begin{array}{lr}
    3n + 1 & \text{se } n \text{ ímpar}\\
    \frac{n}{2} & \text{se } n \text{ par}
    \end{array}
\right.
$$

Essa simples função levou à conjectura de Collatz. A conjectura é da seguinte
forma, para um valor $a_i$:

$$
a_i = \left\{
    \begin{array}{lr}
    n & \text{se } i = 0\\
    c(a_{i-1}) & \text{se } i \ge 1
    \end{array}
\right.
$$

Para qualquer que seja $a_0$ inteiro positivo, existirá algum $s$ tal que
$a_s = 1$. Ou seja, a aplicação repetidas vezes da função de Collatz
eventualmente chega no valor `1`.

A quantidade de passos até chegar nesse valor é o $s$ acima descrito. Então,
assim, consigo definir uma função `step(n)` desse modo:

$$
step(n) = s, c^s(n) = 1 \wedge \not\exists k \lt s, c^k(n) = 1
$$
{% endkatexmm %}

Por exemplo, `step(3) = 7`:

```none
c(3) => 10
c(10) => 5
c(5) => 16
c(16) => 8
c(8) => 4
c(4) => 2
c(2)=> 1
```

São dados 7 passos até obter o valor `1`.

Então, vamos fazer o cálculo da função `step(n)`? Um jeito de fazer é assim:

```js
function collatz(n) {
    if (n % 2 == 1) return 3*n + 1;
    return n/2;
}

function step(n) {
    if (n == 1) return 0;
    return 1 + step(collatz(n));
}
```

Como `step` é uma função pura, podemos aplicar memoização a ela, e fazer com
que essa função consulte a memória:

```js
const memoria = {}
memoria[1] = 0;

function collatz(n) {
    if (n % 2 == 1) return 3*n + 1;
    return n/2;
}

function step(n, memoria) {
    if (memoria[n] != undefined) return memoria[n]
    
    return memoria[n] = 1 + step(collatz(n), memoria);
}
```

Mas aqui eu mudei a assinatura de `step` para por a memória, e isso não é o que
eu gostaria. E também acontece de que eu crio uma variável solta `memoria` que
pode ser mexida de modo indevido. Então, para evitar isso, eu posso deixar tudo
englobado e retornar uma função da forma `(n) => step(n, memoria)`!

```js
const step = (() => {
    const memoria = {}
    memoria[1] = 0;

    function collatz(n) {
        if (n % 2 == 1) return 3*n + 1;
        return n/2;
    }

    function step_with_memory(n, memoria) {
        if (memoria[n] != undefined) return memoria[n]
        
        return memoria[n] = 1 + step_with_memory(collatz(n), memoria);
    }
    return (n) => step_with_memory(n, memoria)
})()
```

E agora o valor de `step` foi inicializado pelo retorno da função anônima. Essa
função por sua vez cria o estado `memoria`, cria duas funções internas e
retorna um lambda que mantém o acesso a `memoria` em sua clausura. E essa
função foi imediatamente chamada após sua declaração. Isso faz dela uma IIFE.

# Escrevendo Collatz em controlless

Bem, antes de embarcar no desafio propriamente dito, podemos aqui aplicar o
desafio do `controlless` para a função `step` e para a função de Collatz.

A função implicitamente tem um `if-else`, porém a escrita não foi usado `else`
explícito porque eu havia colocado um _early return_. Agora, com `controlless`,
_early return_ não é mais uma opção. Então, como expressar isso só com
operadores?

Bem, aqui eu tiro inspirações da minha leitura de _dive into python_! Na época
do Python 2, não existia o construto equivalente a `cond? whenT: whenF`, o
operador ternário tão comum em linguagens como C e seus descendentes. Então,
para contornar isso, pessoal se valia do fato de que avaliações booleanas em
Python eram feitas de modo semelhante a como hoje temos as avaliações de JS:
usando _truthy_ e _falsy_! E no caso, ao fazer `a && b`, eu retorno `a` se
`a` for _falsy_ ou retorno `b` se `a` for `truthy`. De modo semelhante com
o `a || b`. Inclusive usei esse mesmo tipo de lógica no artigo
[Escrevendo as funções booleanas do cálculo lambda, em Java]({% post_url 2025/2025-06-29-boolean-lambda-calc %}).

Naquela fatídica época do Python 2, o contorno era fazer `a and b or c`.
Explicando rapidamente:

- se `a` for `truthy`, ele vai executar `a and b`, retornando `b`
- caso contrário, `a and b` será `a`, então ele retornará `c`

> Tem um caveat aqui que é se `b` for _falsy_, então essa técnica tem pontos de
> falha, e também com Python mais moderno temos o construto `b if a else c`.

E, bem, podemos fazer isso com Collatz! No lugar do IIFE ser o que está do lado
direito do operador `&&`, podemos fazer algo como
`(cond && lambda1 || lambda2)()`, pois assim o resultado da operação booleana
será, necessariamente, ou o `lambda1` ou o `lambda2`, e eu vou executar esse
resultado.

> Ah, sabe o caveat descrito acima? Pois bem, no JS lambdas são _truthy_, estou
> livre dele!

Então, como podemos fazer o `collatz`? Assim:

```js
const collatz = (n) => ((n % 2 == 1) && (() => 3*n + 1) || (() => n/2))()
```

E para `steps`? Bem, vamos implementar a versão sem memoização primeiro? Ela
envolve também um `if-else`. baseado em `n`:

```js
const collatz = (n) => ((n % 2 == 1) && (() => 3*n + 1) || (() => n/2))()
const step = (n) => ((n == 1) && (() => 0) || (() => 1 + step(collatz(n))))()
```

E a versão `controlless` do step com memoização? Fica de modo muito parecido:

```js
const step = (() => {
    const memoria = {}
    memoria[1] = 0;

    const collatz = (n) => ((n % 2 == 1) && (() => 3*n + 1) || (() => n/2))()

    const step_with_memory = (n, memoria) => {
        const mn = memoria[n]

        return (
                mn != undefined &&
                    (() => mn) ||
                    (() => memoria[n] = 1 + step_with_memory(collatz(n), memoria))
            )()
    }

    return (n) => step_with_memory(n, memoria)
})()
```

# Ackermann-Peter em controlless

Pois bem, um dos desafios para `controlless` é uma operação Turing Completa. A
função de Ackermann-Peter é uma das funções recursivas que não é
primitiva-recursiva, que precisa de uma máquina com poder computacional grande
como a máquina de Turing para computar. Para ler mais sobre ela, pode consultar
esse post:
[Trampolim para funções além do primitivo recursivo? Implementação para a função de Ackermann Peter]({% post_url 2024/2024-01-23-trampoline-ackermann-peter %}).

A função é definida assim:

```js
function ackermannPeter(m, n) {
    if (m == 0) {
        return n + 1;
    } else if (n == 0) {
        return ackermannPeter(m - 1, 1);
    }
    return ackermannPeter(m - 1, ackermannPeter(m, n - 1));
}
```

Aqui nós temos 2 elses encadeados! `if-elif-else`. Para deixar mais paupável,
vou tratar assim: `if-else-(if-else)`, assim o resultado dessa operação será a
função que será chamada:

```js
const ackermannPeter = (m, n) => (
    (m == 0) &&
        (() => n + 1) ||
        (
            (n == 0) &&
                (() => ackermannPeter(m - 1, 1)) ||
                (() => ackermannPeter(m - 1, ackermannPeter(m, n - 1)))
        )
)()
```

# Quicksort em controlless

Ok, vamos fazer um quicksort. Finalmente chegou a hora.

O Primeagen constantemente briga com sugestões de LLM para código porque,
segundo ele, o quicksort precisa ser inplace, e as sugestões normalmente
dependem do _spread operator_ fazendo trabalho em memória extra. Por exemplo,
isso ele diz que não é quicksort:

```js
function pseudo_qsort(elements, cmp) {
    if (elements.length == 0) return elements;
    const pivot = elements[0];
    return [
        ...pseudo_qsort(elements.slice(1).filter((el) => cmp(pivot, el) >= 0), cmp),
        pivot,
        ...pseudo_qsort(elements.slice(1).filter((el) => cmp(pivot, el) < 0), cmp)
    ]
}

pseudo_qsort([1, 7, 3, 6, 3, 5], (a, b) => a - b)
```

Se eu usasse essa função como controlless, ela ficaria assim:

```js
const pseudo_qsort = (elements, cmp) =>
    (elements.length == 0) && elements || (() => {
        const pivot = elements[0];
        return [
            ...pseudo_qsort(elements.slice(1).filter((el) => cmp(pivot, el) <= 0), cmp),
            pivot,
            ...pseudo_qsort(elements.slice(1).filter((el) => cmp(pivot, el) > 0), cmp)
        ]
    })()
```

Aqui, como um vetor sem elementos é _truthy_, resolvi não englobar tudo em uma
expressão para executar e só executar se cair no caso `else`. Mas... esse não é
o quicksort que buscamos, pois queremos algo inplace!

Vamos para uma abordagem um pouco mais clássico, com coisas de controle:

```js
const qsort = (elements, cmp) => {
    const partition = (pivot, start, end) => {
        if (start >= end) {
            return end;
        }
        const head = elements[start];

        if (cmp(pivot, head) >= 0) {
            return partition(pivot, start + 1, end);
        }

        const tail = elements[end - 1];
        // pivot é estritamente menor do que tail
        if (cmp(pivot, tail) < 0) {
            return partition(pivot, start, end - 1);
        }
        elements[end - 1] = head;
        elements[start] = tail;
        return partition(pivot, start, end)
    }

    const innerQsort = (start, end) => {
        if (end - start <= 1) {
            return;
        }
        const pivot = elements[end - 1];
        const middlePartition = partition(pivot, start, end - 1);
        const middleElement = elements[middlePartition];

        elements[end - 1] = middleElement;
        elements[middlePartition] = pivot;
        innerQsort(start, middlePartition);
        innerQsort(middlePartition + 1, end);
    }

    innerQsort(0, elements.length);
}

qsort([1, 7, 3, 6, 3, 5], (a, b) => a - b)
```

## Criando um validador

Bem, eu preciso examinar se a abordagem deu certo. Então, que tal fazer um
validador de que o sort realmente ordenou? Eu não preciso ordenar o array para
validar isso, apenas comparar com o elemento seguinte. Se for estritamente
maior, deu ruim. Como o exemplo vou fazer com números, não vou passar a função
de comparação como argumento, mas isso é fácil de resolver.

Então, temos uma função `sorted` que recebe o array e retorna `true` se tiver
tudo ok ou retorna `false` caso tenha pelo menos um elemento fora de ordem!

Como estamos fazendo `controlless`, vamos fazer essa função em `controlless`
também? Tal qual o quicksort, vou começar com uma base ainda com algumas
statements de controle, depois adapto isso. Vamos receber um array, para já
lidar com o laço vamos passar também o ponto o qual estamos fazendo a
verificação:

```js
function sorted(arr, start) {
    if (start >= arr.length - 1) {
        return true
    }
    if (arr[start] > arr[start + 1]) {
        return false
    }
    return sorted(arr, start + 1)
}
```

Muito bem, agora vamos por em `controlless`? Basicamente se o `start`
ultrapassar o tamanho do vetor, concluímos. Caso contrário, se o próximo
estiver bagunçado, já sabemos que não precisa ir adiante. Podemos também, nessa
situação, verificar se está em ordem _E TAMBÉM_ que o resto do vetor esteja
ordenado. Ou seja, no lugar de fazer

```js
if (arr[start] > arr[start + 1]) {
    return false
}
return sorted(arr, start + 1)
```

colocar isso aqui:

```js
(arr[start] <= arr[start + 1]) && sorted(arr, start + 1)
```

Note que `(arr[start] <= arr[start + 1])` é idêntico à negação de
`arr[start] > arr[start + 1]`. Portano, `sorted` poderia ser escrito assim em
`controlless`:

```js
const sorted = (arr, start) => 
    start >= arr.length - 1 || (
        (arr[start] <= arr[start + 1]) && sorted(arr, start + 1)
    )
```

Mas e como posso verificar que a função `sorted` está funcionando devidamente?
Bem, podemos fazer uma verificação que imprima caso não esteja funcionando. Ou
seja, para o teste da função `sorted` passar, ele precisa não imprimir nada.
Algo nesse sentido aqui:


```js
function issorted(arr, expected) {
    const s = sorted(arr, 0)
    if (s != expected) {
        console.log({s, expected, arr})
    }
}
```

Exemplos de chamada que indicam que a implementação está retornando o resultado
correto:

```js
issorted([], true)
issorted([1], true)
issorted([1, 2], true)
issorted([2, 1], false)
issorted([1, 1], true)
issorted([1, 2, 1], false)
issorted([1, 1, 1], true)
issorted([1, 1, 2], true)
issorted([2, 1, 1], false)
```

Adaptando para `controlless`, vamos passar o resultado se está ordenado ou não
como argumento para a função, e a avaliação se devemos imprimir ou não vai
ficar fora dessa função:

```js
const issorted = (arr, expected) => {
    const loggar = (s) => console.log({s, expected, arr})

    const s = sorted(arr, 0);
    (s != expected) && loggar(s)
}
```

Beleza, mas na hora que eu for executar o teste, eu vou querer que imprima o
vetor original para ter uma ideia de como as coisas desandaram (e para poder
reproduzir ele especificamente). Vou pegar o `issorted` como base, assumir que
deveria retornar sempre `true`, e imprimir o vetor original:

```js
const doStuff = (v) => {
    const orig = [...v]; // crio uma cópia de v

    qsort(v, (a, b) => a - b);

    const logga = (orig, v) => console.log({v, orig})
    const result = sorted(v, 0);

    result || logga(orig, v);

    return result;
}
```

## Gerando os casos de teste

Bem, eu preciso de casos de teste para dar uma olhada por cima para validar se
deu certo. Além do caso `[1, 7, 3, 6, 3, 5]` que motivou o começo dessa seção
do artigo, seria legal se eu conseguisse gerar aleatoriamente, né?

Pois bem, o JavaScript tem um construtor de vetor que você passa uma
propriedade e uma função de geração,
[`Array.from`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/from).

No caso, se eu quiser gerar um array de 5 elementos, posso fazer isso:

```js
Array.from({ length: 5 })
// [ undefined, undefined, undefined, undefined, undefined ]
```

Mas aqui ele só gera o array, nem define com o que ele de fato vai ser povoado.
Como eu quero com coisas aleatórias, posso passar a função `Math.random`:

```js
Array.from({ length: 5 }, Math.random)
/*
[
  0.4366370972945681,
  0.4612824283143957,
  0.15061762899680176,
  0.7328764102523664,
  0.7277451936950374
]
 */
```

Mas, como que ele gera esses elementos? Bem, na real a função que ele espera
recebe dois argumentos, `(v, i)`, onde o `v` vem do iterador base que ele tá
usando para construir (no caso, como passamos `{ length: 5 }`, é sempre
`undefined`), e o `i` é o índice começando de 0.

Bem, temos números, mas sinceramente? Números quebrados são feios. Tem como
deixar eles inteiros? Claro!!

O `Math.random()` gera um número de ponto flutuante entre 0 e 1, então posso
multiplicar por uma constante e arredondar usando `toFixed`:

```js
Array.from({ length: 5 }, Math.random).map(x=> x*100).map(x=>x.toFixed())
// [ '92', '47', '26', '66', '34' ]
```

Mas isso acaba por gerar strings de números inteiros... então só mapear usando
`Number`!

```js
Array.from({ length: 5 }, Math.random).map(x=> x*100).map(x=>x.toFixed()).map(Number)
// [ 39, 87, 87, 44, 33 ]
```

> [Cortesia do Daniel](https://bsky.app/profile/danielocl.com.br/post/3lyo7tuhx2k2d)

Então, com isso, conseguimos gerar o caso de teste. Encadeando as coisas:

```js
const v = Array.from({ length: 7 }, Math.random).map(x=> x*100).map(x=>x.toFixed()).map(Number)
doStuff(v)
```

Tá, mas isso não dá uma visão clara de quando dá certo, só notifica alguns
problemas. Preciso ter uma visão mais clara quando deu ruim. Posso fazer então
algo como:

```js
const v = Array.from({ length: 7 }, Math.random).map(x=> x*100).map(x=>x.toFixed()).map(Number)
const sucesso = doStuff(v)

console.log({ sucesso })
```

Mas rodar uma vez perdida tá com nada, né? Vamos rodar isso várias vezes:

```js
let success = true;
for (const i of [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) {
    const v = Array.from({length:7}, Math.random).map(x=> x*100).map(x=>x.toFixed()).map(Number)
    success &&= doStuff(v)
}
console.log({success})
```

Mas isso não vai bem na alma do `controlless`, né? Loop, `let`? Bem, vamos
resolver isso. Vamoz fazer uma função que vai até 0, no 0 ela para. Bem no
esquema da
[função de cauda]([Otimização de função de cauda em uma toy function]({% post_url 2025/2025-08-07-c-tail-call-opt %}))
passando o acumulador como argumento:

```js
const testBench(i, acc) => {
    return (i == 0 && (() => acc) || (() => {
        const v = Array.from({length:7}, Math.random).map(x=> x*100).map(x=>x.toFixed()).map(Number)
        const result = doStuff(v)

        return testBench(i - 1, result && acc)
    }))()
}

const success = testBench(10, true)
console.log({success})
```

## Pegando caso específico

Bem, sabe um dos motivos que eu botei no `doStuff` para imprimir o vetor
original? Para servir de desafio, e por para rodar novamente. Vou fazer isso
através da linha de comando. Como minha chamada é:

```bash
node controlless.js
```

posso simplesmente identificar se tem 3 ou mais elementos passados no ARGV,
como por exemplo:

```bash
node controlles.js 1 7 3 6 3 5
```

Como fazer isso? Usando a variável de sistema `process.argv`. Posso pegar o
slice que remove os dois primeiros elementos e verificar se tá vazio:

```js
const args = process.argv.slice(2);

const success = (
    (args.length > 0) && (() => doStuff(args.map(Number))) || (() => testBench(10, true))
)()

console.log({success})
```

## Voltando pra terminar quicksort

Bem, antes de entrar nas tangentes, o quicksort estava assim:

```js
const qsort = (elements, cmp) => {
    const partition = (pivot, start, end) => {
        if (start >= end) {
            return end;
        }
        const head = elements[start];

        if (cmp(pivot, head) >= 0) {
            return partition(pivot, start + 1, end);
        }

        const tail = elements[end - 1];
        // pivot é estritamente menor do que tail
        if (cmp(pivot, tail) < 0) {
            return partition(pivot, start, end - 1);
        }
        elements[end - 1] = head;
        elements[start] = tail;
        return partition(pivot, start, end)
    }

    const innerQsort = (start, end) => {
        if (end - start <= 1) {
            return;
        }
        const pivot = elements[end - 1];
        const middlePartition = partition(pivot, start, end - 1);
        const middleElement = elements[middlePartition];

        elements[end - 1] = middleElement;
        elements[middlePartition] = pivot;
        innerQsort(start, middlePartition);
        innerQsort(middlePartition + 1, end);
    }

    innerQsort(0, elements.length);
}
```

Basicamente `qsort` pode ser vista assim:

```js
const qsort = (elements, cmp) => {
    const partition = (pivot, start, end) => {
        //...
    }

    const innerQsort = (start, end) => {
        //...
    }

    innerQsort(0, elements.length);
}
```

Basicamente vai ser a definição de `partition` e `innerQsort` que vai indicar
se consegui escrever o `qsort` com `controlless`. Parece que `innerQsort` é
mais tranquilo de transformar, vamos começar com ele? Eu só computo algo se
`end - start <= 1` for falso, caso conrário só deixo nada ocorrer:

```js
const innerQsort = (start, end) => {
    (end - start <= 1) || (() => {
        const pivot = elements[end - 1];
        const middlePartition = partition(pivot, start, end - 1);
        const middleElement = elements[middlePartition];

        elements[end - 1] = middleElement;
        elements[middlePartition] = pivot;
        innerQsort(start, middlePartition);
        innerQsort(middlePartition + 1, end);
    })()
}
```

Agora, o `partition`... bem, vou abusar nesse caso de execução de lambdas. Uma
eliminação de `if` por vez. Começamos com o `parition` base:

```js
const partition = (pivot, start, end) => {
    if (start >= end) {
        return end;
    }
    const head = elements[start];

    if (cmp(pivot, head) >= 0) {
        return partition(pivot, start + 1, end);
    }

    const tail = elements[end - 1];
    // pivot é estritamente menor do que tail
    if (cmp(pivot, tail) < 0) {
        return partition(pivot, start, end - 1);
    }
    elements[end - 1] = head;
    elements[start] = tail;
    return partition(pivot, start, end)
}
```

Vamos transformar os dois branches do primeiro `if` em lambdas, e fazer IIFE no
final:

```js
const partition = (pivot, start, end) =>
    ((start >= end) && (() => end) || (() => {

        const head = elements[start];

        if (cmp(pivot, head) >= 0) {
            return partition(pivot, start + 1, end);
        }

        const tail = elements[end - 1];
        // pivot é estritamente menor do que tail
        if (cmp(pivot, tail) < 0) {
            return partition(pivot, start, end - 1);
        }
        elements[end - 1] = head;
        elements[start] = tail;
        return partition(pivot, start, end)

    }))()
```

Agora só repetir para os demais...

```js
const partition = (pivot, start, end) =>
    ((start >= end) && (() => end) || (() => {

        const head = elements[start];

        return (
            (cmp(pivot, head) >= 0) &&
            (() => partition(pivot, start + 1, end)) ||
            (() => {
                const tail = elements[end - 1];
                // pivot é estritamente menor do que tail
                if (cmp(pivot, tail) < 0) {
                    return partition(pivot, start, end - 1);
                }
                elements[end - 1] = head;
                elements[start] = tail;
                return partition(pivot, start, end)
            })
        )()
    }))()
```

E só mais uma vez:

```js
const partition = (pivot, start, end) =>
    ((start >= end) && (() => end) || (() => {

        const head = elements[start];

        return (
            (cmp(pivot, head) >= 0) &&
            (() => partition(pivot, start + 1, end)) ||
            (() => {
                const tail = elements[end - 1];
                return (
                    (cmp(pivot, tail) < 0) &&
                    (() => partition(pivot, start, end - 1)) ||
                    (() => {
                        elements[end - 1] = head;
                        elements[start] = tail;
                        return partition(pivot, start, end)
                    })
                )()
            })
        )()
    }))()
```

E finalmente eu posso mostrar o quicksort em controlless!

```js
const qsort = (elements, cmp) => {
    const partition = (pivot, start, end) =>
        ((start >= end) && (() => end) || (() => {

            const head = elements[start];

            return (
                (cmp(pivot, head) >= 0) &&
                (() => partition(pivot, start + 1, end)) ||
                (() => {
                    const tail = elements[end - 1];
                    // pivot é estritamente menor do que tail
                    return (
                        (cmp(pivot, tail) < 0) &&
                        (() => partition(pivot, start, end - 1)) ||
                        (() => {
                            elements[end - 1] = head;
                            elements[start] = tail;
                            return partition(pivot, start, end)
                        })
                    )()
                })
            )()
        }))()

    const innerQsort = (start, end) => {
        (end - start <= 1) || (() => {
            const pivot = elements[end - 1];
            const middlePartition = partition(pivot, start, end - 1);
            const middleElement = elements[middlePartition];

            elements[end - 1] = middleElement;
            elements[middlePartition] = pivot;
            innerQsort(start, middlePartition);
            innerQsort(middlePartition + 1, end);
        })()   
    }

    innerQsort(0, elements.length);
}
```

## Recapitulando o código

```js
const qsort = (elements, cmp) => {
    const partition = (pivot, start, end) =>
        ((start >= end) && (() => end) || (() => {

            const head = elements[start];

            return (
                (cmp(pivot, head) >= 0) &&
                (() => partition(pivot, start + 1, end)) ||
                (() => {
                    const tail = elements[end - 1];
                    // pivot é estritamente menor do que tail
                    return (
                        (cmp(pivot, tail) < 0) &&
                        (() => partition(pivot, start, end - 1)) ||
                        (() => {
                            elements[end - 1] = head;
                            elements[start] = tail;
                            return partition(pivot, start, end)
                        })
                    )()
                })
            )()
        }))()

    const innerQsort = (start, end) => {
        (end - start <= 1) || (() => {
            const pivot = elements[end - 1];
            const middlePartition = partition(pivot, start, end - 1);
            const middleElement = elements[middlePartition];

            elements[end - 1] = middleElement;
            elements[middlePartition] = pivot;
            innerQsort(start, middlePartition);
            innerQsort(middlePartition + 1, end);
        })()   
    }

    innerQsort(0, elements.length);
}

const sorted = (arr, start) => 
    start >= arr.length - 1 || (
        (arr[start] <= arr[start + 1]) && sorted(arr, start + 1)
    )

const issorted = (arr, expected) => {
    const loggar = (s) => console.log({s, expected, arr})

    const s = sorted(arr, 0);
    (s != expected) && loggar(s)
}

issorted([], true)
issorted([1], true)
issorted([1, 2], true)
issorted([2, 1], false)
issorted([1, 1], true)
issorted([1, 2, 1], false)
issorted([1, 1, 1], true)
issorted([1, 1, 2], true)
issorted([2, 1, 1], false)

const doStuff = (v) => {
    const orig = [...v]; // crio uma cópia de v

    qsort(v, (a, b) => a - b);

    const logga = (orig, v) => console.log({v, orig})
    const result = sorted(v, 0);

    result || logga(orig, v);

    return result;
}


const args = process.argv.slice(2);

const testBench = (i, acc) => {
    return (i == 0 && (() => acc) || (() => {
        const v = Array.from({length:7}, Math.random).map(x=> x*100).map(x=>x.toFixed()).map(Number)
        const result = doStuff(v)

        return testBench(i - 1, result && acc)
    }))()
}

const success = (
    (args.length > 0) && (() => doStuff(args.map(Number))) || (() => testBench(10, true))
)()

console.log({success})
```
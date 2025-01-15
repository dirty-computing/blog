---
layout: post
title: "Recursão a moda clássica em TS: auto referência do tipo de função"
author: "Jefferson Quesado"
tags: typescript recursão
base-assets: "/assets/ts-self-type-referential-function/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

> Esse post é um foco em cima da parte final do post
> [Vamos memoizar? Desafio da recursão]({% post_url 2023-01-03-memoizacao %})

Um jeito de fazer recursão é fazer uma função que recebe a si mesma.

Para tal, é preciso declarar o tipo da função, para poder passar a ela mesma
como referência:

```ts
export type RecFunc = (n: number, f: RecFunc) => number;

export function fix_point(f: RecFunc): (x: number) => number {
        return x => f(x, f)
}
```

E para implementar uma função como essa (por exemplo, função de Fibonacci):

```ts
import { RecFunc, fix_point } from './genericMemoization.js'

const fibPrimitive = (n: number, selfFib: RecFunc): number => n <= 0? 0: n == 1? 1: selfFib(n-1, selfFib) + selfFib(n-2, selfFib);

const fib = fix_point(fibPrimitive);
console.log(fib(12)); // 144
```

É possível extender para quaisquer argumentos de entrada e saída, apenas foquei aqui em entrada
e saída com número simples.

Função de Péter-Ackermann:

```ts
export type RecFunc2 = (m:number, n: number, f: RecFunc) => number;

export function fix_point2(f: RecFunc2): (x: number, y: number) => number {
        return (x, y) => f(x, y, f)
}
```

```ts
import { RecFunc2, fix_point2 } from './genericMemoization.js'

const ackPrimitive = (m:number, n: number, selfAck: RecFunc2): number => {
  if (m == 0) return n + 1;
  if (n == 0) return selfAck(m-1, 1, selfAck);
  return selfAck(m-1, selfAck(m, n-1, selfAck), selfAck);
}

const ack = fix_point2(ackPrimitive);
```

# Decorando a função

Posso adicionar tratativas simples às recursões. Como, por exemplo, imprimir
no `console.log` toda vida que a função é chamada com os parâmetros passados,
no nível correto. Por exemplo, o nível de entrada é 0, depois a cada passagem
aumenta em um o nível.

Vamos chamar de `param_logger` o objeto que vai lidar com isso. Eu posso
interagir com ele de 2 maneiras:

- logar o que recebi, imprimindo o nível
- criar outro `param_logger` de um nível mais baixo

O `param_logger` para satisfazer isso precisa ter duas funções:

```ts
type ParamLogger = {
    log: (param: number) => void,
    deeper_logger: () => ParamLogger
}
```

Uma estratégia que não se importa ainda com a correção do `deeper_logger` seria
simplesmente isso:

```ts
const lyingLogger: ParamLogger = {
    log: (param: number) => console.log(`0: ${param}`),
    deeper_logger: () => lyingLogger
}
```

Certo, agora para manter o nível eu preciso de alguma espécie de parâmetro com
o nível. Como eu não tenho explícito, isso significa que vou precisar capturar
na clausura. Então isso significa que vou precisar de uma função para criar o
logger. E ela vai precisar ser recursiva!

```ts
const loggerByLevel = (level: number): ParamLogger => ({
    log: (param: number) => console.log(`${level}: ${param}`),
    deeper_logger: () => loggerByLevel(level + 1)
})
```

Mas eu não devo expor essa função, né? Posso expor apenas o meu `baseLogger`.
Como faço isso? Através de uma IIFE (_immediately invoked function
expression_):

```ts
const baseLogger: ParamLogger = (() => {
    const loggerByLevel = (level: number): ParamLogger => ({
        log: (param: number) => console.log(`${level}: ${param}`),
        deeper_logger: () => loggerByLevel(level + 1)
    })
    return loggerByLevel(0)
})();
```

Agora, para deixar no espírito desse post, vamos passar a função recursivamente
para si mesma?

```ts
const baseLogger: ParamLogger = (() => {
    type ParamLoggerCreator = (level: number, func: ParamLoggerCreator) => ParamLogger

    const loggerByLevel: ParamLoggerCreator = (level: number, func: ParamLoggerCreator) => ({
        log: (param: number) => console.log(`${level}: ${param}`),
        deeper_logger: () => func(level + 1, func)
    })
    return loggerByLevel(0, loggerByLevel)
})();
```

Agora, como iríamos lidar com essa decoração? Uma decoração simples no caso do
Fibonacci para simplesmente imprimir o parâmetro:

```ts
fibPrimitive(12, (n, self) => {
    console.log(n)
    return fibPrimitive(n, self)
})
```

Note que a função sendo passada recursivamente adiante é a função `self`, que
inicialmente ela é simplesmente uma chamada de `console.log` com uma chamada da
função principal passando `self`. Agora eu preciso alterar o `self`.

Vou me basear na implementação feita para memoização, começando, para
eventualmente mudar o `self`:

```ts
function fix_point_log(f: RecFunc): (n: number) => number {
    const logging = (n: number, self: RecFunc): number => {
        baseLogger.log(n)
        return f(n, logging)
    }
    return n => logging(n, logging)
}
```

Hmmm, até aí ok, eu diria. Eu posso simular uma espécie de `step` também:

```ts
function fix_point_log(f: RecFunc): (n: number) => number {
    const logging = (n: number, self: RecFunc): number => {
        baseLogger.log(n)
        const step = (n: number, s: RecFunc): number => {
            return self(n, s)
        }
        return f(n, step)
    }
    return n => logging(n, logging)
}
```

Ok, `step` aqui é uma arrow-function. Isso significa que eu posso adicionar
propriedades a ela agora:

```ts
function fix_point_log(f: RecFunc): (n: number) => number {
    const logging = (n: number, self: RecFunc): number => {
        baseLogger.log(n)
        const step = (n: number, s: RecFunc): number => {
            return self(n, s)
        }
        step.log = baseLogger.deeper_logger()
        return f(n, step)
    }
    return n => logging(n, logging)
}
```

Qual seria o tipo de `step` nesse momento?

```ts
type TipoDeStep = RecFunc & { log: ParamLogger }

// ou então equivalentemente...

type TipoDeStep = ((n: number, s: RecFunc) => number) & { log: ParamLogger }

// outra maneira...

type TipoDeStep = {
    (n: number, s: RecFunc): number,
    log: ParamLogger
}
```

Essa terceira notação é a anotação de "call signature" (vide
[geeksforgeeks](https://www.geeksforgeeks.org/typescript-call-signatures/)).
Você até não consegue criar diretamente um objeto _callable_ através de uma
arrow-function, mas o TS permite que você coloque o valor logo em seguida. Por
exemplo, isso é válido:

```ts
type BinOp = {
    (a: number, b: number): number,
    nome: string
}

const soma: BinOp = (a, b) => a + b
soma.nome = "+"
```

Mas isso é inválido:

```ts
type BinOp = {
    (a: number, b: number): number,
    nome: string
}

const soma: BinOp = (a, b) => a + b
// erro de TS
// Property 'nome' is missing in type '(a: number, b: number) => number' but required in type 'BinOp'.ts(2741)
```

Massa! Agora eu preciso detectar quando o `self` passado é do tipo com a
assinatura de chamada e com o atributo `log`. O jeito mais fácil é fazendo uma
função de guarda!

```ts
function isRecFuncEtlog(f: RecFunc): f is RecFunc & { log: ParamLogger } {
    return (f as any)["log"] != null
}
```

Com isso agora eu posso interceptar e usar o `log`:

```ts
function fix_point_log(f: RecFunc): (n: number) => number {
    const logging = (n: number, self: RecFunc): number => {
        if (isRecFuncEtlog(self)) {
            self.log.log(n)
            return f(n, self)
        }
        baseLogger.log(n)
        const step = (n: number, s: RecFunc): number => {
            return self(n, s)
        }
        step.log = baseLogger.deeper_logger()
        return f(n, step)
    }
    return n => logging(n, logging)
}
```

Pronto! Agora só falta o passo na chamada de quando é uma função com o log. Vou
por a mesma lógica do `step`, só que agora no lugar de usar o
`baseLogger.deeper_logger()` vou usar o `.deeper_logger()` do `self.log`:

```ts
function fix_point_log(f: RecFunc): (n: number) => number {
    const logging = (n: number, self: RecFunc): number => {
        if (isRecFuncEtlog(self)) {
            self.log.log(n)
            const step = (n: number, s: RecFunc): number => {
                return self(n, s)
            }
            step.log = self.log.deeper_logger()
            return f(n, step)
        }
        baseLogger.log(n)
        const step = (n: number, s: RecFunc): number => {
            return self(n, s)
        }
        step.log = baseLogger.deeper_logger()
        return f(n, step)
    }
    return n => logging(n, logging)
}
```

---
layout: post
title: "O combinador Y"
author: "Jefferson Quesado"
tags: fp recursão js python
base-assets: "/assets/y-combinator/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

No cálculo lambda, você não pode ter auto-referência. Mas, como que resolve
isso para, por exemplo, a função de Fibonacci? Simples! Você passa uma função
como argumento!

Eu investiguei coisas desse tipo em alguns posts anteriores:

- [Vamos memoizar? Desafio da recursão]({% post_url 2023/2023-01-03-memoizacao %})
- [Recursão a moda clássica em TS: auto referência do tipo de função]({% post_url 2025/2025-01-15-ts-self-type-referential-function %})
- [Escrevendo as funções booleanas do cálculo lambda, em Java]({% post_url 2025/2025-06-29-boolean-lambda-calc %})

Então, vamos falar sobre o famigerado Y-combinator? Uma função especial que
permite que a gente escreva funções recursivas sem precisar de capacidade
recursiva na linguagem!

{% katexmm %}

$$
Y = \lambda f\ .\ \lambda x\ .f(x \ x)\ \lambda x\ .f(x \ x)
$$

{% endkatexmm %}

# Recursão no cálculo lambda

> Para não entrar repetidas vezes no modo matemático, vou usar `\` para
> substituir o lambda nas expressões abaixo.

Toda essa conversa sobre Y-combinator origina no cálculo lambda. Basicamente no
cálculo lambda você tem variáveis ligadas ao seu contexto ou variáveis
"livres". Mas uma coisa é clara sobre esses tipos de valores: você não pode
referenciar algo ainda não definido. Ou seja, você não pode fazer isso:

```
f = \x . x > 0? x + f(x-1): 0
```

Porque o você está definindo o objeto `f`, ele ainda não está definido. Para
contornar isso, podemos passar a função para si mesma:

```
sum = \x . \f . x > 0? x + f(x-1)(f): 0
```

Para chamar essa função:

```
sum(5)(sum)
```

Vamos desenrolar essa função?

```
sum = \x . \f . x > 0? x + f(x-1)(f): 0

sum(5)(sum) = 5 > 0? 5 + sum(5-1)(sum): 0      # 5 é maior do que zero
            = 5 + sum(5-1)(sum)
            = 5 + sum(4)(sum)

sum(4)(sum) = 4 > 0? 4 + sum(4-1)(sum): 0      # 4 é maior do que zero
            = 4 + sum(4-1)(sum)
            = 4 + sum(3)(sum)

sum(3)(sum) = 3 > 0? 3 + sum(3-1)(sum): 0      # 3 é maior do que zero
            = 3 + sum(3-1)(sum)
            = 3 + sum(2)(sum)

sum(2)(sum) = 2 > 0? 2 + sum(2-1)(sum): 0      # 2 é maior do que zero
            = 2 + sum(2-1)(sum)
            = 2 + sum(1)(sum)

sum(1)(sum) = 1 > 0? 1 + sum(1-1)(sum): 0      # 1 é maior do que zero
            = 1 + sum(1-1)(sum)
            = 1 + sum(0)(sum)

sum(0)(sum) = 0 > 0? 0 + sum(0-1)(sum): 0      # 0 não é maior do que zero
            = 0

sum(5)(sum) = 5 + sum(4)(sum)                  # substituindo os valores encontrados
            = 5 + 4 + sum(3)(sum)
            = 5 + 4 + 3 + sum(2)(sum)
            = 5 + 4 + 3 + 2 + sum(1)(sum)
            = 5 + 4 + 3 + 2 + 1 + sum(0)(sum)
            = 5 + 4 + 3 + 2 + 1 + 0
            = 15
```

E é assim uma das estratégias para se faaer recursão com cálculo lambda.

# U-combinator

Antes de qualquer coisa, vamos falar sobre um combinador mais trivial do que o
Y-combinator: o U-combinator.

Pegue a função como função de soma, apresentada anteriormente. Ela é trabalhosa
porque você precisa se lembrar de passar a função como argumento dela mesma. E
você abre a chance para fazer besteira, como por exemplo:

```
sum(5)(\x.\f.x) = 5 > 0? 5 + (\x.\f.x)(5 - 1)(\x .\f.x): 0  # 5 é maior que zero
                = 5 + (\x.\f.x)(5 - 1)(\x.\f.x)
                = 5 + (\x.\f.x)(4)(\x.\f.x)                 # beta reduction x=>4
                = 5 + (\f.4)(\x.\f.x)                       # beta reduction f=>(\x.\f.x)
                = 5 + 4
                = 9
```

E se tivesse uma maneira de fazer essa atribuição da função nela mesma antes de
expor? Bem, a função é uma variável ligada, então eu preciso receber ela de
algum jeito. Que tal criar uma nova função, mas com a função sendo passada via
contexto de clausura? Como variável livre?

```
c = \f . \x . f(x)(f)
```

Vamos ver o que acontece passando a função `sum` original para `c`?

```
c = \f . \x. f(x)(f)
sum = \n . \f . n > 0? n + f(n-1)(f): 0
c(sum) = \x . sum(x)(sum)
```

Perfeito! Agora eu apliquei a função nela mesma de modo garantido! Vamos
reescrever um pouco para não restar dúvidas? Afinal, o `sum` anterior não é a
função de soma que eu gostaria de ter:

```
c = \f . \x. f(x)(f)
sum = c(\n . \f . n > 0? n + f(n-1)(f): 0)
    = \n . n > 0? n + (\n . \f . n > 0? n + f(n-1)(f): 0)(n-1)(\n . \f . n > 0? n + f(n-1)(f): 0): 0
```

Eu estou bem perto de ter uma função universal para resolver esse problema da
recursão... mas aqui a função tem seu valor recursivo passado no segundo
argumento. Por exemplo, função de Ackermann Peter:

```
ack = \m . \n . \a .
                       m == 0? n + 1:
                       n == 0? a(m-1)(1)(a):
                       a(m-1)(  a(m)(n-1)(a)  )(a)
```

Não posso usar aqui o combinador `c` anteriormente definido, pois agora a
função recursiva como argumento está no terceiro argumento, não no segundo. Tem
como unificar isso?

A resposta é: tem sim! Só colocar a função recursiva como **primeiro**
argumento! Vamos ver como ficaria `sum`?

```
c = \f . \n . f(f)(n)
sum = c(\f . \x . x > 0? x + f(f)(x-1): 0)
```

Hmmm, podemos simplificar ainda mais. Como `f(f)` retorna uma função, não
precisamos aqui deixar isso explícito:

```
c = \f . f(f)
sum = c(\f.\x.x > 0? x + f(f)(x-1): 0)
    = \x .
           x > 0?
                   x +
                   (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(x-1)
                : 0
```

Vamos destrinchar para `x=5`?

```
sum = \x .
           x > 0?
                  x +
                  (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(5-1)
                : 0

sum(5) = 5 > 0?
                5 +
                (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(5-1)
              : 0
       = 5 + (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(5-1)
       = 5 + (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(4)
       = 5 + (\x.x > 0?
                         x +
                         (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(x-1)
                      : 0)(4)
       = 5 + (4 > 0?
                     4 +
                     (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(4-1)
                   : 0)
       = 5 + 
         4 +
         (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(4-1)
       = 5 + 
         4 +
         (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(3)
       = 5 + 
         4 +
         (\x.x > 0?
                     x + (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(x-1)
                  : 0
         )(3)
       = 5 + 
         4 +
         (3 > 0?
                  3 + (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(3-1)
               : 0
         )
       = 5 + 
         4 +
         3 +
         (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(3-1)
       = 5 + 
         4 +
         3 +
         (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(2)
       = 5 + 
         4 +
         3 +
         (\x.x > 0? x + (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(x-1): 0)(2)
       = 5 + 
         4 +
         3 +
         (2 > 0? 2 + (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(2-1): 0)
       = 5 + 
         4 +
         3 +
         2 +
         (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(2-1)
       = 5 + 
         4 +
         3 +
         2 +
         (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(1)
       = 5 + 
         4 +
         3 +
         2 +
         (\x.x > 0? x + (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(x-1): 0)(1)
       = 5 + 
         4 +
         3 +
         2 +
         (1 > 0? 1 + (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(1-1): 0)
       = 5 + 
         4 +
         3 +
         2 +
         1 +
         (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(1-1)
       = 5 + 
         4 +
         3 +
         2 +
         1 +
         (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(0)
       = 5 + 
         4 +
         3 +
         2 +
         1 +
         (\x.x > 0? x + (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(x-1): 0)(0)
       = 5 + 
         4 +
         3 +
         2 +
         1 +
         (0 > 0? 0 + (\f.\x.x > 0? x + f(f)(x-1): 0)(\f.\x.x > 0? x + f(f)(x-1): 0)(0-1): 0)
       = 5 + 
         4 +
         3 +
         2 +
         1 +
         0
       = 15
```

Funciona...

Pois bem, esse combinador que resolve a função nela mesma para o primeiro
argumento de um função que recebe argumentos via _currying_ é o U-combinator!

```
U = \f.f(f)
```

Em JavaScript?

```js
const U = f => f(f)
const sum = U(f => n => n > 0? n + f(f)(n-1): 0)
sum(5) // 15
```

Em Python?

```python
u = lambda f: f(f)
sum = u(lambda f: lambda n: 0 if n == 0 else n + f(f)(n-1))
```

# O que são combinadores?

Falei bastante de combinadores até aqui e não defini o que eles são, né?

Bem, combinadores são funções sem variáveis livres. Funções que dependem
unicamente das variáveis passadas para elas. Por exemplo:

```
c = \f . \n . f(n)(f)
```

O que esse combinador produz depende apenas do seu input. No caso, ele recebe
como input uma função e retorna uma função que vai depender apenas da variável
que foi passada para o combinador.

No caso do combinador U, ele produz uma função de maneira singela:

```
U = \f . f(f)
```

De modo semelhante, o combinador Y depende apenas do seu argumento:

```
Y = \f . (\x. f(x x))(\x. f(x x))
```

As funções `TRUE` e `FALSE` em notação de Church:

```
TRUE  = \a.\b.a
FALSE = \a.\b.b
```

Aqui, a função `NOT` não é um combinador:

```
NOT = \p.p FALSE TRUE
```

Pois `NOT` está sendo definida em termos de valores que não estão no input, no
caso `FALSE` e `TRUE`.

# Y-combinator

Ok, chegamos na tão temida hora. Vamos precisar aplicar o Y-combinator.

Vamos ver quanto seria `Y(f)`?

```
Y(f) = (\f . (\x. f(x x))(\x. f(x x)))(f)
     = (\x. f(x x))(\x. f(x x))
```

Por curiosidade, vamos ver só o que acontece se fizermos a redução beta que
está praticamente implorando para ser feita? `x = (\x. f(x x))`

```
Y(f) = (\x. f(x x))(\x. f(x x))
     = f((\x. f(x x))(\x. f(x x)))
```

Mas, veja só! Já encontramos anteriormente o valor de
`(\x. f(x x))(\x. f(x x))`! Ele é `Y(f)`! Portanto, `Y(f) = f(Y(f))`!!

Ok, mas o que o Y-combinator pode nos trazer que o U-combinator não trouxe?
Afinal, o Y-combinator parece bem mais complexo do que o U-combinator, ele
precisa compensar de alguma maneira para usar ele, não é mesmo?

Pois bem. Sabe como fizemos com que a função passada fosse do mesmo formato da
função declarada? Para usar com U-combinator, eu tenho uma função assim:

```ts
type Recfunc = (f: Recfunc) => (n: number) => number
type NumFunc = (n: number) => number

const sum: Recfunc = f => n => n > 0? n + f(f)(n-1): 0


const U = (f: Recfunc): NumFunc => f(f)

const trueSum = U(sum)

const inlineSum = U(f => n => n > 0? n + f(f)(n-1): 0)

console.log(trueSum(5))
console.log(inlineSum(5))
```

Tanto a função que estou passando para o U-combinator como o parâmetro `f` tem
a mesma forma: recebem um `Recfunc` e depois um número. Agora, quando estamos
lidando com o Y-combinator, o primeiro parâmetro tem outro tipo:

```ts
type NumFunc = (n: number) => number

const y_sum = (f: NumFunc) => (n: number) => n > 0? n + f(n-1): 0
```

E é esse o ponto forte do Y-combinator, ele deixa mais fácil expressar as
funções recursivas!

Bem, podemos expressar o Y-combinator em termos dele mesmo:

```js
const Y = f => f(Y(f))
const y_sum = f => n => n > 0? n + f(n-1): 0
const sum = Y(y_sum)
sum(5)
```

Hmmm, isso tentou resolver de modo _eager_ o `Y(y_sum)`, o que resultou em
estouro de pilha. Então vamos calcular isso de modo _lazy_!

```js
const Y = f => n => f(Y(f))(n)
const y_sum = f => n => n > 0? n + f(n-1): 0
const sum = Y(y_sum)
sum(5) // 15
```

Será que funciona para a função de Fibonacci? Deve funcionar, né?

```js
const Y = f => n => f(Y(f))(n)
const fib = Y( f => n => n <= 1? n: f(n-1) + f(n-2) )
fib(12) // 144
```

Ok, ok. Isso foi divertido, fizemos um Y-combinator em JavaScript, mas em
termos de si mesmo. Ainda tem aqui auto-referência. E como queremos fazer um
Y-combinator, não podemos deixar que essa auto-referência se mantenha no nosso
código. Precisamos deixar ele mais adequado para o cálculo lambda!

Bem, como fazemos? Só lembrar aqui que o passo que queremos é resolver a função
nela mesma e depois mandar o argumento. Algo semelhante ao U-combinator. Vamos
ter uma primeira função/argumento chamada de "step", então vamos receber uma
função que queremos fazer com que ela faça a combinação recursiva adequada e,
para ser lazy, finalmente iremos receber o nosso argumento.

Ou seja, aqui nós temos algo assim:

```js
const Y = (s => f => n => ...)
```

Vamos computar as coisas? Pois bem. Agora vamos chamar a função que estamos
adaptando, passar como primeiro argumento algo... mágico... e como segundo
argumento o número:

```js
const Y = (s => f => n => f(?)(n))
```

Muito bem. A função a ser adaptada será o que iremos passar. Para isso,
precisamos dar um passo nela. Mas, como vai ser esse passo? Bem, o passo recebe
os mesmos argumento: o step, a função, e o valor como input. Ou seja, `s(s)(f)`
que vai gerar uma função anônima que depende de um input `n` para dar o
resultado.

```js
const Y = (s => f => n => f(s(s)(f))(n))
```

Mas... como definimos esse step? Ora, ora, ora... é EXATAMENTE essa função que
criamos! Então passamos como argumento justamente a mesma função, de modo que
agora o `s` já vai estar resolvido

```js
const Y = (s => f => n => f(s(s)(f))(n))(s => f => n => f(s(s)(f))(n))
```

Para o função de Fibonacci:

```js
const Y = (s => f => n => f(s(s)(f))(n))(s => f => n => f(s(s)(f))(n))
const fib = Y(f => n => n <= 1? n: f(n-1) + f(n-2))

fib(12) // 144
```

Em Python:

```python
Y = ( lambda s: lambda f: lambda n: f(s(s)(f))(n) )( lambda s: lambda f: lambda n: f(s(s)(f))(n) )
Y(lambda f: lambda n: n if n <= 1 else f(n-1) + f(n-2))(12) # 144
```
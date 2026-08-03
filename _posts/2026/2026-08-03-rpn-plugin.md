---
layout: post
title: "RPN como um sistema de plugins, ou minha primeira proto-linguagem de programação"
author: "Jefferson Quesado"
tags: rpn language-design ts estrutura-de-dados
base-assets: "/assets/rpn-plugin/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Onde termina uma simples linguagem e onde começa uma linguagem de programação?
Bem, aqui é um terreno bem complicado para lidar, onde muitas pessoas tem
emoções e "verdades" (mais opiniões mas enfim...) muito fortes por aí... Então,
como que eu consigo determinar onde que uma acaba e outra começa?

Bem, alguns vão dizer que é quando você alcança a famigerada "completude
Turing"! Outros vão argumentar que você não precisa ser Turing Completo para
alcançar o status de linguagem de programação!

Mas independente de semânticas e lados mais ou menos pesados nessa brincadeira,
podemos ter um _common ground_? Existem coisas que são simplesmente
"programáveis" e "extensíveis", onde:

- programável: você define (seja imperativamente ou declarativamente) o tipo de
  computação (aka, transformação de dados) vai ocorrer
- extensível: além daquilo que o ambiente fornece, você consegue adicionar
  novas funcionalidades para aquele ambiente, incluindo coisas que não estavam
  previstas

E sabe onde eu aprendi a fazer isso pela primeira vez? Bem, pelo menos de forma
mais explícita... Simplesmente permitindo que o usuário determinasse o modo
como ele queria calcular um preço!

# Permitindo fórmulas

A primeira ideia era simplesmente permitir que o usuário injetasse um código
(potencialmente) JavaScript dizendo como que ele iria calcular um valor. Porém
aqui eu fui pegue por uma limitação técnica: eu precisava rodar isso em
TotalCross e eu não tinha acesso a um motor JavaScript que rodasse em
TotalCross! Poderia escrever o meu? Poderia, mas sinceramente não iria ficar
nem um pouco bom...

Tentei começar com algo mais simples, como um simples interpretador Lisp, e nem
precisava ainda de um `eval` avançado, mas fiquei perdido na questão de fazer
um Lexer bem TotalCross... então essa alternativa ficou de lado.

Outra ideia que surgiu foi permitir que o usuário escrevesse as fórmulas de
modo tradicional, como ele escreveria no papel mesmo. Mas isso acabou
esbarrando em algo chato: resolução de ambiguidades... e como não queria abrir
o mínimo de margem, isso foi deixado de lado...

Então me lembrei de algo que eu tinha visto de relance em um tópico estudando
para programação competitiva! Notação polonesa reversa!

Isso é algo simples, que se poderia treinar o usuário para escrever, que não
tem ambiguidades e que é fácil computar! E que permite fazer sabe o quê?
Inserir variáveis de modo arbitrário!

## Mas por que fórmulas?

Nesse caso específico, o cliente tinha a ideia de como se formava a
precificação dele. No comportamento tradicional do sistema, o valor já vinha
totalmente formatado do ERP, e os valores eram integrados dentro do força de
vendas.

O produto era vendido em diversas "tabelas de preço" distintas. E cada "tabela
de preço" dessas permitia que o produto fosse vendido de forma escalonada. E
para cada elemento nesse escalonamento se tinha uma faixa de preço (preços
unitários informados abaixo):

{:class="marked-table"}
| Quantidade   | Mínimo  | Sugerido | Máximo |
| -----------: | -----:  | -----:   | -----: |
|         0    |   1.00  |     2.80 |   5.00 |
|         5    |   0.70  |     2.15 |   4.70 |
|        50    |   0.70  |     1.80 |   3.00 |

E a variação de valor era livre, contanto que respeitasse duas condições:

- valor sugerido menor ou igual ao valor máximo
- valor mínimo menor ou igual ao valor sugerido

Porém esse cliente específico não tinha uma tabela bem formatada para extrair
os preços. Ele calculava na hora da venda! E como que ele fazia isso? Bem, ele
usava o conceito de "variáveis" e "cálculos". Muito inovador, não é?

Pois bem, como que ele fazia aqui? Vamos supor que o cliente específico lidasse
com fabricação de carrinhos em miniatura colecionáveis. Ele precificava o carro
com base em fórmulas, afinal. E para um carrinho de polícia de 30cm em escala
com pouco realismo ele calculava assim:

{% katexmm %}

$$
Carrinho_{30cm} = (4\times pneu\_plástico + 2\times Eixo\_aço + \\
10 \times tempo\_trabalho + 30\times carroceria\_comum)\\ \times \\
\left(\frac{100 + margem\_lucro\_brinquedo}{100}\right)
$$

E para um carro Wiener 50cm premium com rodas brilhantes?

$$
Carrinho_{premium} = (4\times pneu\_led + 2\times Eixo\_aço + \\
200 \times tempo\_trabalho + 50\times carroceria\_premium + 8\times fator\_raridade)\\ \times \\
\left(\frac{100 + margem\_lucro\_colecionador}{100}\right)
$$

{% endkatexmm %}

E essa era a fórmula associada ao produto. Porém, cada tabela de preço vinha
acompanhada de suas variáveis. Então ele poderia ter um comprador especial
confiável que ele poderia definir uma margem de lucro menor. Ou então poderia
se definir de modo diferente, se aquele era um comprador que tradicionalmente
comprava brinquedos eventualmente poderia colocar para tentar pulverizar mais o
produto de colecionador e portanto dar uma vantagem ao colocar o
`fator_raridade` como 0 para isso não interferir na negociação e tentar fazer
com que esse comprador diversifique o leque de produtos que ele costuma
comprar.

E assim surgiu a modelagem:

- o produto está ligado a uma fórmula
- fórmula menciona variáveis
- tabelas de preços contém valores de variáveis
- vendas são feitas utilizando-se de uma tabela de preços
- os compradores estão em tabelas de preço específicas que o vendedor conhece

E esse foi o cenário base para começar a expandir.

# RPN: uma árvore escondida

A notação polonesa reversa (Reverse Polish Notation,
[RPN](https://en.wikipedia.org/wiki/Reverse_Polish_notation)) é um tipo de
notação não ambígua que permite escrever árvores de computação. Por exemplo,
pegando o exemplo da Wikipedia:

```text
3 4 - 5 +
```

Isso aqui representa exatamente esta conta:

```text
(3-4) + 5
```

Mas como que isso acontece? Bem, basicamente porque a notação polonesa é uma
maneira de se escrever uma árvore binária em notação prefixa:

- o nó pai aparece logo
- então aparece o primeiro filho desse nó (filho esquerdo)
- e então aparece o segundo filho desse nó (filho direito)

Mas tem uma coisa bem interessante: dá para trivialmente identificar um nó como
terminal (ou folha, em nomenclatura de árvores)! Se ele for um número, ele é um
terminal, e se for uma operação, ele é um nó intermediário.

Mas aqui estamos lidando com notação polonesa reversa, logo se a notação
polonesa direta usava notação prefixa, a notação polonesa reversa usa uma
notação posfixa para representar a árvore! Que é basicamente a mesma coisa
porém com os filhos aparecendo antes e a raiz sendo o último elemento da lista!

Como ficaria no caso a árvore para o exemplo acima, `3 4 - 5 +`?

```none
3       4
 \     /
  \   /
   \ /
    -       5
     \     /
      \   /
       \ /
        +
```

E para calcular o valor eu faço uma navegação na árvore. Ao chegar em um nó
intermediário, eu sei que ele poderia ser substituído pelo resultado da
operação, então computo a operação nele contida. Nesse caso específico, o
primeiro elemento resolvido seria o `-`, com operandos `3` e `4` nessa ordem. A
árvore após resolver isso fica:

```none
-1       5
  \     /
   \   /
    \ /
     +
```

E agora é só resolver o `+`, com os operandos `-1` e `5` (nesse caso como o
operador é comutativo a ordem não importa mais tanto assim):

```none
4
```

Ok, agora... nem tudo é uma árvore, não é? Isso significa que eu preciso
validar como que os dados estão sendo inputados, e em cima disso preciso
informar se é uma fórmula válida ou não. E se for inválida preciso barrar o
cadastro. Como se tivesse um erro de sintaxe, saca?

## Validando a RPN

Como que se expressa a gramática de uma RPN? Bem, o lado bom é que eu não
precisei desenhar a gramática livre de contexto formalmente através de BNF nem
nada do tipo, mas pude usar algo específico do domínio:

- todos os tipos são numéricos
- operadores consomem `n` folhas anteriores a ele e trocam por um valor

Então eu preciso bem dizer acompanhar a chegada e transformação de valores. E o
melhor é que eu nem preciso identificar quais seriam esses valores folha nem os
resultados das operações!

Basicamente, ao chegar um valor, eu incremento o contador de "valores
empilhados". Ao chegar um operador, eu removo `n` elementos do contador e
depois somo 1. No final do processo, para a RPN ser válida, eu preciso ficar
com exatamente 1 elemento empilhado. E também eu não posso, em nenhum momento,
remover mais elementos do que de fato existiam. Ou seja: em nenhum momento a
quantidade de elementos empilhadas pode ficar negativa.

Para experimentar, algumas entradas para a gente analisar:

- `3 4 - 5 6 *`
- `3 4 - 97 100 / * + 12 42 34 - *`

A primeira fórmula é inválida porque não há como juntar `3-4` e `5*6`. Eu fico
com dois valores empilhados.

A segunda fórmula é inválida porque, ao tentar aplicar a soma, ele vai somar o
quê? Resolvendo as coisas antes de chegar no operação de soma nós temos
`0.7275` e então vem o `+`. Essa adição, vai somar `0.7275` com o quê? Com
nada, não tem nada a ser somado na pilha, portanto essa fórmula está inválida
também.

Uma análise mais inocente da segunda fórmula poderia aceitar ela erradamente,
dando um falso positivo. Dadas as duas restrições para identificar se uma
fórmula é válida, a quantidade de operadores precisa ser igual a quantidade de
valores exceto por 1 (para apenas operadores binários). Como por exemplo
`3 4 - 5 +`, temos 3 valores e 2 operadores. A análise mais ingênua poderia
simplesmente aplicar isso apenas no fim, mas na prática isso permitiria
absurdos como o do exemplo acima: temos 7 valores para 6 operadores.

## Tá, mas e tem BNF?

Sim, temos BNF pra definir se é uma WFF (well formed formula). Basicamente é
isso (para operadores binários só para exemplificar):

```none
S ::= S S OP
OP ::= '+' , '-' , '*' , '/'
S ::= FOLHA
FOLHA ::= NÚMERO
```

Para representar `(3-4)+5`, vamos começar partindo da operação mais externa: o
`+`. De modo intermediário temos algo assim:

```none
XXX 5 +
```

Onde o `XXX` é a representação de `3-4`. Que é basicamente isso:

```none
3 4 -
```

Substituindo acima:

```none
3 4 - 5 +
```

Fazendo as derivações bonitinhas da gramática para gerar a árvore:

```none
S ==> S S OP
S S OP ==[resolvendo OP]> S S '+'
S S '+' ==[resolvendo o segundo S]> S NÚMERO '+'
S NÚMERO '+' ==> S '5' '+'
S '5' '+' ==> S S OP '5' '+'
S S OP '5' '+' ==[resolvendo OP]> S S '-' '5' '+'
S S '-' '5' '+' ==[resolvendo o primeiro S]> NÚMERO S '-' '5' '+'
NÚMERO S '-' '5' '+' ==> '3' S '-' '5' '+'
'3' S '-' '5' '+' ==[resolvendo o S restante]> '3' NÚMERO '-' '5' '+'
'3' NÚMERO '-' '5' '+' ==> '3' '4' '-' '5' '+'
```

Tá, eu sei que não foi uma resolução mais `LL`, que fiz derivações de coisas
mais a direita, mas foi para exemplificar.

## Por que bater tanto na tecla de "operações binárias"?

Porque existem outras. E existem motivos para existirem outras. Por exemplo, em
uma divisão eu posso ter o valor `0` como divisor. O que deveria causar um
resultado absurdo, não é? Bem, sim... exceto se eu tiver uma operação chamada
`/-safe` que pega 3 elementos:

- o dividendo
- o divisor
- o resultado placeholder caso o divisor seja 0

Como isso pode se aplicar? Bem, de modo simples:

```none
A B C - /
```

Se eu por acaso tiver um conjunto de dados de tal modo que `B == C`, então isso
vai ser uma divisão por 0, e nada de bom surge de uma divisão por 0. Logo, uma
alternativa é fornecer um valor placeholder para caso isso aconteça:

```none
A B C - 0.1 /-safe
```

Aqui o `B-C` é resolvido e vira o divisor. Se por acaso `B == C`, então esse
divisor será 0 e o `/-safe` vai entender que devo substituir essa operação toda
por `0.1`.

## Operador esquisito...

Então, isso é uma extensão. Lembra que eu falei sobre ser "extensível"?
Então... A interpretação que estamos fazendo da RPN é uma interpretação que
permite não apenas programar como que o cálculo vai ser feito, quais as
operações são feitas, como também podemos extender o que a RPN entende como
operador. Aqui foi adicionado o operador `/-safe` que consome 3 elementos.

Podemos também adicionar o operador `.max` e `.min`, ambos operadores binários.
Essas extensões eu posso chamar de "plugins", afinal são trechos de computação
que eu plugo/acoplo ao meu trecho programático que tem uma interface bem
definida. No caso deles, receber uma quantidade específica de números e
devolver um único número.

Podemos também ter operadores unários como `.ln` e `.exp`. Ou então até mesmo
operadores zero-ários, que representação uma computação externa.

Vamos por um momento esquecer disso e se focar no básico das quatro operações
aritméticas binárias? Depois a gente retorna para extender...

## Calculando uma RPN

Você deve imaginar que identificar todos os componentes da árvore não é o jeito
mais otimizado de se fazer as operações em uma RPN. E sim, você está certo ao
pensar isso. Existe uma maneira muito mais fácil de pensar a RPN!

Lembra de quando falamos da validação de uma RPN que foi mencionado "empilhar"
valores? Então... aquilo não foi mencionado à toa. Literalmente usamos pilha
para calcular uma RPN!

Achou um nó de valor? A gente dá push nele, e ele fica na pilha. Achou um nó de
operação? Então damos múltiplos pops! E depois de calcular tudo damos push de
novo com o que foi computado.

Voltando ao exemplo inicial da Wikipedia, `3 4 - 5 +`. A primeira coisa
encontrada é uma folha com o valor `3`. Então, empurramos ela: agora a pilha
está `[3]` e ainda temos para ler `4 - 5 +`. A próxima leitura é `4`, então
também empurramos ele na pilha, ficando com `[3, 4]` e para leitura residual
`- 5 +`. Agora lemos o `-`; e ele precisa sacar dois elementos da pilha. Então,
temos aqui a operação `-(3, 4)` e a pilha ficou `[]`. Após computar, coloco de
volta o resultado na pilha, `[-1]`, e preciso terminar de ler o `5 +`.
Novamente, ao receber o `5` empilho ele, portanto fica `[-1, 5]`, e finalmente
vem o `+`, que saca dois elementos da pilha para computar `+(-1, 5)`, cujo
resultado é empilhado novamente: `[4]`.

Agora vou fazer o mesmo algoritmo, só que para a RPN `3 4 / 3 4 - 5 + *`. Vou
ser mais expressivo agora: do lado direito vai ficar o "resíduo" que ainda
preciso computar da fórmula, no meio entre `{`chaves`}` o elemento que foi lido
(começa vazio porque no começo eu não li nada) e no lado direito a pilha, que
também começa vazia:

```none
resíduo              lido           pilha
3 4 / 3 4 - 5 + *    {}             []
  4 / 3 4 - 5 + *    {3}            []
  4 / 3 4 - 5 + *    {}             [3]
    / 3 4 - 5 + *    {4}            [3]
    / 3 4 - 5 + *    {}             [3, 4]
      3 4 - 5 + *    {/}            [3, 4]
      3 4 - 5 + *    {/(3, 4)}      []
      3 4 - 5 + *    {0.75}         []
      3 4 - 5 + *    {}             [0.75]
        4 - 5 + *    {3}            [0.75]
        4 - 5 + *    {}             [0.75, 3]
          - 5 + *    {4}            [0.75, 3]
          - 5 + *    {}             [0.75, 3, 4]
            5 + *    {-}            [0.75, 3, 4]
            5 + *    {-(3, 4)}      [0.75]
            5 + *    {-1}           [0.75]
            5 + *    {}             [0.75, -1]
              + *    {5}            [0.75, -1]
              + *    {}             [0.75, -1, 5]
                *    {+}            [0.75, -1, 5]
                *    {+(-1, 5)}     [0.75]
                *    {4}            [0.75]
                *    {}             [0.75, 4]
                     {*}            [0.75, 4]
                     {*(0.75, 4)}   []
                     {3}            []
                     {}             [3]
```

# Operacionalizando

Vamos deixar a RPN operacional e funcionando? Para começar, vamos deixar apenas
números e a operação de `+`. Vamos fazer esse exercício em TS, só pela
praticidade mesmo. A RPN em si (por enquanto) é uma mistura de:

- números
- operadores disponíveis (no caso, o `+`)

Porém, como ela vem de um banco de dados, podemos simplesmente dizer que ela
vem de um vetor de strings que depois é transformado em números e operadores. E
essa operação é sob demanda. Então precisamos descobrir uma forma de saber
quando algo é um número. E como fazemos isso? Bem, que tal fazer o parse usando
primitivas do próprio JS? E ao fazer o parse, existem dois resultados
possíveis:

- ou retorna um número próprio
- ou retorna um "Not-a-Number", NaN, um número não numérico (???)

Podemos fazer isso usando
[`Number(arg)`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number#number_coercion):

> Strings are converted by parsing them as if they contain a number literal.
> Parsing failure results in NaN.

Tem alguns caveats menores também, mas satisfaz bem o suficiente. Então, para
saber se um vetor de strings é uma RPN válida, precisamos validar se o símbolo
recebido é um número ou um operador conhecido. Vamos ver como podemos fazer
isso?

Vamos ler da esquerda pra direita. Ao receber o símbolo, verifico se é um
operador conhecido. Se for um operador, vamos subtrair a quantidade de
elementos que aquele operador consome e somemos 1 para a pilha. Caso contrário,
vamos verificar se é um número. Sendo número, somemos 1 à pilha. Então,
seguindo a [lógica da validação](#validando-a-rpn) já apresentada, precisa
ter o retorno 1 e nunca jamais ter algum valor negativo no meio do caminho.

Então, bora lá. Vamos ter nosso conjunto de operadores e, na ausência deles,
posso pegar os números. Bacana? Pois bora!

```ts
type Operador = {
  n: number,    // quantidade de argumentos que o operador recebe
  name: string, // a representação do operador em si
  eval: (...args: number[]) => number // a operação em si
};

const plus : Operador = {
    n: 2,
    name: "+",
    eval: (a: number, b: number) => {
        return a + b;
    }
}

function goodAsNum(s: string): boolean {
  return !Number.isNaN(Number(s))
}

function rpnValida(formula: string[], operadores: Record<string, Operador>): boolean {
  let stack = 0;
  for (const element of formula) {
    const op = operadores[element]

    if (op) {
      // é um operador!!!
      // consome n elementos
      stack -= op.n
      if (stack < 0) {
        return false;
      }
      // adiciona 1
      stack += 1
    } else if (goodAsNum(element)) {
      // não é um operador...
      // mas é um número
      stack += 1
    } else {
      // não reconheço essa marmota...
      return false
    }
  }
  return stack == 1
}

console.log(rpnValida(["1", "2", "+"], {
  [plus.name]: plus
}))
```

Muito bom. Vamos dificultar a vida? E se eu quiser a operação `/-safe`? Como
validaria isso?

Bem, primeiro definindo essa operação. Ela é uma operação ternária que, se o
segundo elemento for 0, retorna o terceiro elemento, caso contrário retorna a
divisão do primeiro pelo segundo:

```ts
const divSafe = {
  n: 3,
  name: "/-safe",
  eval: (num: number, div: number, failsafe: number) => {
    if (div == 0) return failsafe
    return num/div
  }
}
```

E para validar isso? Bem, só passar o novo operador como parte dos operadores
da RPN:

```ts
console.log(rpnValida(["1", "2", "-2", "+", "8", "/-safe"], {
 [plus.name]: plus,
 [divSafe.name]: divSafe
}))
```

E... aqui começamos o sistema de plugins! Com operações!

Mas aqui leva em consideração apenas operações. Podemos ter outras coisas, como
variáveis!

Mas ok, cenas dos próximos capítulos! Estou me adiantando... temos uma fórmula
e sabemos que ela é válida, e temos os operadores prontos! Vamos calcular?
Agora, diferente da validação... vamos precisar sim calcular de verdade.

Então, o que precisamos? Bem, precisamos empurrar na pilha, e precisamos sacar
da pilha. Quantas vezes? `n` vezes, o operador quem indica. Vamos lá, de modo
geral validar e executar é bem parecido. Mas, vou fazer uma ligeira diferença
na questão da validação do número: ao saber que é um número, retornemos também
o seu valor. Porque atualmente retornamos apenas `true` ou `false`, mas aqui
eu quero saber qual o valor retornado se de fato for um número, e um tipo mais
rico de retorno poupa uma nova compilação.

No lugar da stack ter apenas um único inteiro, agora realmente vai conter
vários valores nela:

```ts
type NumParsed = {
  parse: "fail"
} | {
  parse: "success",
  value: number
}

function tryParseNum(s: string): NumParsed {
  const value = Number(s)
  if (Number.isNaN(value)) {
    return {
      parse: "fail"
    }
  }
  return {
    parse: "success",
    value
  }
}

function rpnCompute(formula: string[], operadores: Record<string, Operador>): number {
  const stack: number[] = [];
  for (const element of formula) {
    const op = operadores[element]

    if (op) {
      const resultOperation = doRpnOperation(op, stack);
      stack.push(resultOperation)
      continue
    }
    const parsedNum = tryParseNum(element)
    if (parsedNum.parse === "success") {
      // não é um operador...
      // mas é um número
      stack.push(parsedNum.value)
    } else {
      // não reconheço essa marmota...
      return 0
    }
  }
  return stack[0]
}
```

Ok, agora preciso de fato pegar as coisas da pilha e colocar para o `eval` do
operador... seria tão bom se tivesse como empurrar no começo do array... E,
bem... Tem sim! Usando o
[`Array.unshift`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/unshift)!
Ou isso ou brincar com deconstrução excessiva de array...

```ts
function doRpnOperation(op: Operador, stack: number[]): number {
    const args: number[] = []
    let n = op.n

    while (n > 0) {
        const stackValue = stack.pop()
        if (stackValue == undefined) {
            // deu ruim aqui...
            return 0
        }
        args.unshift(stackValue)
        n -= 1
    }

    return op.eval(...args)
}
```

Para ver funcionando, só chamar com os diversos valores:

```ts
// -0.2
console.log(rpnCompute(["1", "2", "-7", "+", "10", "/-safe"], {
 [plus.name]: plus,
 [divSafe.name]: divSafe
}))

// 8
console.log(rpnCompute(["1", "2", "-2", "+", "8", "/-safe"], {
 [plus.name]: plus,
 [divSafe.name]: divSafe
}))
```

Então, já conseguimos começar o mundo de plugins. Bacana, né?

## Facilitando a vida para o mapa de operadores

Percebeu como tanto em `rpnCompute` como em `rpnValida` foi feito um esforço
hercúleo de tornar uma eventual lista de operadores em uma espécie de
dicionário? Então, que tal unificar isso?

Posso fazer isso com uma única redução, pegando a partir de um objeto vazio,
então adicionando nele uma nova chave `op.name` fazer referência ao próprio
operador:

```ts
const listaOperadores: Operador[] = [plus, divSafe]

const dictOperadores: Record<string, Operador> = listaOperadores.reduce( (acc, el) => ({...acc, [el.name]: el}), {})
```

Aqui um quick recap:

- `.reduce` com dois argumentos: o primeiro argumento é a função de redução em
  si e o segundo sendo o primeiro "acumulado" da redução
- o primeiro argumento da redução é o acumulado até então, e o segundo é o
  elemento atual sendo reduzido

Depois disso, temos duas operações estranhas (e também o contorno sintático do
`({})` explicado no artigo
[Cacofonia em código?]({% post_url 2026/2026-07-24-cacofonia %})). Vamos
começar pela operação estranha a direita: `[el.name]: el`.

Aqui, ao colocar `el.name` no campo, o JS reclama do que o que eu estou
tentando é estranho. Para dizer para ele "não interprete isso como literal"
precisa colocar entre colchetes. Isso a gente já tá usando a um tempo, desde o
primeiro exemplo fornecido para `rpnValida`.

Então, basicamente ao colocar `[el.name]: el` dentro de um objeto, estamos
criando um campo nesse objeto cuja chave é `el.name` e cujo valor é o próprio
`el`.

Tá, mas se eu só fizesse isso o meu resultado seria apenas o último elemento
passado:

```ts
const listaOperadores: Operador[] = [plus, divSafe]

const dictOperadores: Record<string, Operador> = listaOperadores.reduce( (acc, el) => ({[el.name]: el}), {})
```

Aqui eu tirei o _spread_ `...acc`. Ou seja, estou aqui criando um novo objeto
cuja única chave é `el.name`. Ao fazer o `...acc`, estou pegando o valor antigo
acumulado e colocando no objeto novo.

Faz diferença colocar esse spread no lado direito ou esquerdo do campo novo
sendo criado? De modo geral sim, mas no caso específico não. Digo no caso
específico porque não iremos ter conflito de nomes! E a diferença ocorre
quando você vai ter conflitos!

Por exemplo, vamos espalhar o objeto `{a: 1}` em um objeto que estamos
vinculando a ele a chave `a: 2`:

```js
{ ...{ a: 1 }, a: 2 } // { a: 2 }
{ a: 2, ...{ a: 1 } } // { a: 1 }
```

A chave que está do lado direito vence!

Ah, de toda sorte vai fazer diferença no layout do objeto criado após o spread,
e isso pode ter implicações de runtime, mas não no fato dos valores finais
serem os mesmos. Por exemplo, agora a nova chave adicionada é `b: 2`:

```js
{ ...{ a: 1 }, b: 2 } // { a: 1, b: 2 }
{ b: 2, ...{ a: 1 } } // { b: 2, a: 1 }
```

## Entram funções

Qual a diferença de operações e funções? Bem, de modo geral ambas são coisas
que pegam N valores e devolvem 1 valor. Mas eu posso fazer uma diferença:
funções podem ser definidas em torno de RPNs! E operadores são coisas que são
descritas fora da linguagem que são assumidas como "primitivos" os quais a
linguagem funciona com eles.

Para tornar as coisas um pouco mais fáceis, no meu caso específico, defini que
funções iriam sempre começar com letra maiúscula. E para o meu caso específico,
eu tinha uma limitação que não é o caso genérico que todo mundo precisa se
preocupar: eu não quero ter recursão.

A fórmula precisa ser previsível, não pode entrar em loop infinito. Se eu tiver
recursão, eu não vou ter garantia sobre parar ou não. Simples assim. Existem
uma série de heurísticas para validar isso nos casos mais comuns e que essas
heurísticas (para esses casos) dão a resposta correta? Sim. Mas aqui eu quero
simplesmente saber se um programa vai parar. Isso é _literalmente_ o problema
da parada! E a solução foi: não deixar o problema sequer pensar em existir.

Apenas permitindo operações e funções, sem maneiras de controlar o fluxo, e
podendo apenas passar números para as funções, a única maneira de haver loops
(e, portanto, estarmos sujeitos a investigar o problema da parada) era se
houvesse uma função recursiva.

E, bem, a ideia era poder definir preços nas faixas de preço, né? Faixa mínima,
faixa sugerida e faixa máxima? Para isso, foram definidas essas 3 funções,
zero-árias, que quem estivesse descrevendo os preços poderia usar. E elas,
segundo a convenção de nomes, eram, respectivamente: `Fm`, `FS`, `FM`.

E, bem, como era feita essa investigação para determinar se algo tinha o
cadastro válido? Basicamente, a fórmula era validada de modo independente.
Para que uma fórmula fosse válida, era feita a análise descrita acima, porém
aqui fazíamos a extração de funções que ela mencionava. E as funções, nesse
momento, eram todas zero-árias, então elas eram consideradas de modo semelhante
a um número _para validação_ da fórmula individualmente.

No cadastro da faixa de preço, porém, era iniciada uma outra investigação. Ao
associar as fórmulas às faixas mínima, sugerida e máxima se fazia uma navegação
de grafo: o cadastro da faixa de preço mínima não podia em nenhum momento
depender de `Fm`, seja direta ou indiretamente. Então aqui se fazia uma descida
no grafo: ao encontrar uma função, se navegava nela até o final, anotando os
pontos que se visitou; se encontrasse por acaso um `Fm`, abortava a validação.
Simples assim. E o mesmo para `FS` e `FM`.

Em outras palavras: se fazia a validação da existência de ciclos em grafos.

Enfim, era assim que funcionava a validação. Agora, ao encontrar um objeto que
começasse com uma letra maiúscula, se verificava se por acaso aquilo era uma
função conhecida (sim, no caso específico só existiam 3 funções, mas deixa isso
baixo, ok? Era mais fácil pensar no caso geral!). A função existindo, pegava da
memória qual a RPN que essa função apontava e calculava ela. Simples assim.

Porém, com um detalhe ainda não mencionado: o cálculo usava os mesmos
"valores"! As variáveis cadastradas nas tabelas de preço!

Então, sabe aquela fórmula do começo? Que passa simplesmente um mapa apontando
de uma string para os operadores? Então, existiam também outros mapas:

- os que apontavam para funções
- os que apontavam para valores

E esses mapas eram os passados para todo o cálculo das RPNs.

Mas, tem um segredo maroto aqui... lembra que eu falei sobre convencionar que
os nomes de funções começavam com letras maiúsculas? Então, se eu convencionar
que o nome dos operadores começam com um caracter não alfa-numérico (como um
`.`, ou um `/`, ou simplesmente tudo que case com `[^a-zA-Z0-9_]`), e
convencionar que os valores começam com letras minúsculas, eu posso reusar
aquele mesmo `Record<string, Operador>` e ser feliz! Bem, quase, porque no caso
de funções eu preciso passar o esse mesmo `Record` para baixo com os seus
valores.

Vamos definir aqui que, no lugar de simplesmente ser um `Operador`, vamos ter
um tipo `LazyNumero` que por sua vez é um sum-type:

```ts
type Operador = {
  tipo: "Operador",
  n: number,    // quantidade de argumentos que o operador recebe
  name: string, // a representação do operador em si
  eval: (...args: number[]) => number // a operação em si
}

type Funcao = {
  tipo: "Funcao",
  name: string,     // a representação da função em si
  formula: string[] // a RPN que essa função chama
}

type LazyNumero = Operador | Funcao
```

Notou que aqui eu nem dei a opção da função ter operandos? Então, proposital.
Para deixar ela zero-ária. Se eu fosse deixar ela com um outro valor teria de
criar alguma maneira para indicar quais seriam os nomes dos parâmetros sendo
passados para baixo ou mesmo alguma convenção para indicar quais seriam esses
valores.

Agora, vamos operacionalizar a criação do dicionário: basicamente vai ser a
mesma coisa de antes porém com `LazyNumero`:

```ts
const dictLazy: Record<string, LazyNumero> = [
  ...listaOperadores,
  ...listaFuncoes
].reduce( (acc, el) => ({[...acc, el.name]: el}), {})
```

Aqui eu só garanto que vai dar certo por conta da convenção de nomes. Se os
nomes chocassem, eu teria perdido algum desses objetos.

Ok, mas dado o dicionários de valores "lazy", como que fica afinal a computação
da RPN? Bem, primeiro precisamos descobrir se é um operador ou se é uma função.
Sendo um operador, tudo funciona como era antes, mas sendo uma função, preciso
chamar recursivamente o cálculo de RPN:

```ts
// isso aqui continua igual, operador não mudou
function doRpnOperation(op: Operador, stack: number[]): number {
    const args: number[] = []
    let n = op.n

    while (n > 0) {
        const stackValue = stack.pop()
        if (stackValue == undefined) {
            // deu ruim aqui...
            return 0
        }
        args.unshift(stackValue)
        n -= 1
    }

    return op.eval(...args)
}

type NumParsed = {
  parse: "fail"
} | {
  parse: "success",
  value: number
}

// o parse também não mudou nada
function tryParseNum(s: string): NumParsed {
  const value = Number(s)
  if (Number.isNaN(value)) {
    return {
      parse: "fail"
    }
  }
  return {
    parse: "success",
    value
  }
}

// Nova função!
function computeLazy(lazy: LazyNumero, stack: number[], dictLazy: Record<string, LazyNumero>): number {
  // se for operador, funciona igual 
  if (lazy.tipo == "Operador") {
    return doRpnOperation(lazy, stack);
  } else {// por hora só pode ser isso aqui... if (lazy.tipo == "Funcao") {
    // aqui, computamos a função via rpnCompute
    return rpnCompute(lazy.formula, dictLazy)
  }
}

// Aqui vem as mudanças!
function rpnCompute(formula: string[], dictLazy: Record<string, LazyNumero>): number {
  const stack: number[] = [];
  for (const element of formula) {
    const lazy = dictLazy[element]

    if (lazy) {
      // ok, obtive algo, vamos computar?
      const result = computeLazy(lazy, stack, dictLazy)
      stack.push(result)
      continue
    }
    const parsedNum = tryParseNum(element)
    if (parsedNum.parse === "success") {
      // não é um operador...
      // mas é um número
      stack.push(parsedNum.value)
    } else {
      // não reconheço essa marmota...
      return 0
    }
  }
  return stack[0]
}
```

## Finalmente, os valores

Bem, os valores são fornecidos como um dicionário: nomes para números. Para o
caso do casdastro específico, ao colocar a fórmula no produto, ele só pode ser
vendido nas tabelas de preço que contemplam essa variável.

Lembra a questão das convenções? Aqui, a convenção é que essas variáveis
advindas das tabelas de preço tenham sempre o nome começando com letras
minúsculas. E assim conseguimos ter portanto uma garantia que não irá colidir
com os operadores nem com as funções.

Aqui, os valores vão ser uma simples extensão ao `LazyNumero`:

```ts
// não precisamos mexer nos tipos anteriores...
type Operador = {
  tipo: "Operador",
  n: number,    // quantidade de argumentos que o operador recebe
  name: string, // a representação do operador em si
  eval: (...args: number[]) => number // a operação em si
}

type Funcao = {
  tipo: "Funcao",
  name: string,     // a representação da função em si
  formula: string[] // a RPN que essa função chama
}

// O novo tipo!
type Valor = {
  tipo: "Valor",
  name: string,
  valor: number
}

// acrescentando no sum-type
type LazyNumero = Operador | Funcao | Valor
```

E o único ponto de diferença aqui é na resolução do `Lazy`, que agora precisa
levar em consideração o tipo do `Valor`:

```ts
// única alteração necessária
function computeLazy(lazy: LazyNumero, stack: number[], dictLazy: Record<string, LazyNumero>): number {
  // se for operador, funciona igual 
  if (lazy.tipo == "Operador") {
    return doRpnOperation(lazy, stack);
  } else if (lazy.tipo == "Funcao") {
    // chegou a hora de verificar se é função...
    return rpnCompute(lazy.formula, dictLazy)
  } else { // bem, sem mais outros tipos, né? if (lazy.tipo == "Valor") {
    return lazy.valor
  }
}
```

E aqui temos a operação completa! Com valores, operadores, funções!

Aqui, no cadastro, foi definida a convenção de como usar funções. Ainda pobre?
Sim, ainda pobre. Mas essas funções servem para permitir expansões do que se
tinha anteriormente. E também posso plugar novos operadores via plugins.

# Outros usos de RPN

Recentemente fiz uma atividade na pós que precisava de fórmulas. E essas
fórmulas eram arbitrárias. Para resolver esse tipo de impasse de permitir
quaisquer fórmulas, usei RPN! Assim, eu não precisava me submeter a rodar um
`eval` do JS em produção.

Mas aqui o contexto era ligeiramente diferente: a fórmula dizia quais variáveis
o usuário precisaria preencher. E também não aceitava funções, funciona só com
as 4 operações básicas (binárias). Mas os conceitos básicos foram os mesmos:

- como eu empilho e desempilho os valores
- usar o dicionários de operadores
- validar as fórmulas
- extrair quais as variáveis usadas nas fórmulas

Eu comecei declarando que uma fórmula RPN é composta por:

- operadores binários
- strings (para representar a variáveis)
- números

Algo assim (perdoe o latim):

```ts
type RPNFormulae = (BinOp | string | number)[]
```

Para indicar quais eram os operadores binários, a primeira reação é justamente
criar um tipo como um sum-type:

```ts
type BinOp = "+" | "-" | "*" | "/";
```

Porém, ao tentar validar se uma string é um `BinOp`, eu iria ter de replicar
esse trecho com as operações no reconhecimento de valores, na guard function
`isBinOp`. 

Aqui o [Claude](https://claude.ai) ajudou com uma sugestão: criar o tipo a
partir de uma vetor! Então, como foi a sugestão? Algo nessa linha:

```ts
const BIN_OP = ["+", "-", "*", "/"] as const;
type BinOp = typeof BIN_OP[number];
```

Aqui `typeof BIN_OP[number]` pega os possíveis tipos que o objeto `BIN_OP`
retorna acessando o "campo" através de um número arbitrário. Se pedir para a
IDE exibir o tipo de `BinOP`, ela vai dizer
`type BinOp = "+" | "-" | "*" | "/"`. E o mais legal é que eu posso fazer isso
na função de guarda:

```ts
const BIN_OP = ["+", "-", "*", "/"] as const;
type BinOp = typeof BIN_OP[number];

function isBinOp(s: string): s is BinOp {
    for (const op of BIN_OP) {
        if (op == s) {
            return true;
        }
    }
    return false;
}
```

Aqui o vetor que ajuda a definir o tipo também é usado na função de guarda! Ah,
sabe aquele `as const` na declaração da função? Então, ele está dizendo que
aquele valor não será alterado. Se eu remover o `as const`, o tipo de `BinOp`
acaba sendo o que `BIN_OP` pode carregar: strings!

```ts
const BIN_OP2 = ["+", "-", "*", "/"];
type BinOp2 = typeof BIN_OP2[number];
// tipo calculado pela IDE: type BinOp2 = string
```

O que lasca com minha ideia de opeações fechadas.

O dicionário de operações foi facilmente desenhado:

```ts
const opMap: Record<BinOp, (lhs: number, rhs: number) => number> = {
    "+": (lhs, rhs) => lhs + rhs,
    "-": (lhs, rhs) => lhs - rhs,
    "*": (lhs, rhs) => lhs * rhs,
    "/": (lhs, rhs) => rhs == 0? 0: lhs / rhs
} as const;
```

Aqui, ao remover um elemento o compilador me aponta o erro:

```ts
const opMap: Record<BinOp, (lhs: number, rhs: number) => number> = {
    "+": (lhs, rhs) => lhs + rhs,
    "-": (lhs, rhs) => lhs - rhs,
    "*": (lhs, rhs) => lhs * rhs,
    // oops, removi a divisão, que desastrado eu sou...
    // "/": (lhs, rhs) => rhs == 0? 0: lhs / rhs
} as const;

/* mensagem de erro (quebras de linha/indentação adicionados para melhorar legibilidade):

Property '"/"' is missing in type
'{
  readonly "+": (lhs: number, rhs: number) => number;
  readonly "-": (lhs: number, rhs: number) => number;
  readonly "*": (lhs: number, rhs: number) => number;
}'
but required in type 'Record<"+" | "-" | "*" | "/", (lhs: number, rhs: number) => number>'.

 */
```

Eu posso extrair as variáveis a serem usadas (e, portanto, pedir elas ao
usuário):

```ts
function extractParamsRPNFormulae(formulae: RPNFormulae): string[] {
    const vars: Set<string> = new Set()
    let i = 0

    while (i < formulae.length) {
        const el = formulae[i]

        if (typeof el == "string") {
            if (!isBinOp(el)) {
                vars.add(el)
            }
        }
        i++
    }
    return [ ...vars ]
}
```

Note que estou querendo retornar um array de strings, não um `Set<string>`. E
para isso o mais fácil foi usar o `Set<string>` para acumular as strings
recebidas e no final extrair o valor desse `Set`. Para extrair, usei o spread
aqui `[ ...vars ]`.

Para validar se é uma RPN, usei as mesmas magias anteriormente descritas de
adicionar e remover elementos de uma "stack" que é puramente um número. Porém
acelerei o processo ao assumir apenas operações binárias e ausência de função:

```ts
function rpnValidate(formulae: RPNFormulae): boolean {
    let stackSize = 0
    let i = 0

    while (i < formulae.length) {
        const el = formulae[i]

        if (typeof el == "string") {
            if (isBinOp(el)) {
                if (stackSize < 2) {
                    return false
                }
                stackSize -= 1
            } else {
                stackSize += 1
            }
        }
        if (typeof el == "number") {
            stackSize += 1
        }
        i++
    }

    return stackSize == 1
}

function isRpn(a: any): a is RPNFormulae {
    if (!Array.isArray(a)) {
        return false
    }
    for (const el of a) {
        if (typeof el == "string") {
            continue;
        }
        if (typeof el == "number") {
            continue;
        }
        return false
    }
    return rpnValidate(a as RPNFormulae)
}
```

Note que separei a função de guarda `isRPn(a: any) is RPNFormulae` da lógica
simples de validar se a pilha está correta. Inclusive, eu chamo a função para
verificar se a pilha entra em estado inválido após uma simples validação muito
básica de tipos.

Na parte de validar se a pilha fica negativa, no lugar de subtrair 2, validar
negativo, somar 1, optei por uma alternativa mais direta:

```ts
if (typeof el == "string") {
    if (isBinOp(el)) {
        if (stackSize < 2) {
            return false
        }
        stackSize -= 1
    } else {
        stackSize += 1
    }
}
if (typeof el == "number") {
    stackSize += 1
}
```

Se for uma string que é um operador binário, verifica se na pilha tem menos de
dois elementos: se tiver, já sei que vai ficar com "valor negativo". Então, ao
remover 2 elementos e adicionar um elemento, o saldo final é como se eu tivesse
diminuído em 1 a pilha. Para todo o resto, strings que não sejam operadores
binários ou mesmo para números, eu simplesmente coloco o valor na pilha.

Para calcular afinal, passamos pelo passo muito semelhante de chamar operador,
substituir variável, que fizemos nas sessões anteriores:

```ts
function rpnCalculate(params: { [paramName: string]: number; }, formulae: RPNFormulae): number {
    const stack: number[] = []
    let i = 0

    while (i < formulae.length) {
        const el = formulae[i]

        if (typeof el == "string") {
            if (isBinOp(el)) {
                const f: ((lhs: number, rhs: number) => number) = opMap[el]
                const rhs = stack.pop()!
                const lhs = stack.pop()!
                const r = f(lhs, rhs)
                stack.push(r)
            } else {
                const v = params[el]
                stack.push(v)
            }
        }
        if (typeof el == "number") {
            stack.push(el)
        }
        i++
    }

    return stack[0]
}
```

Se for número, a resolução está feita e é só empurrar:

```ts
if (typeof el == "number") {
    stack.push(el)
}
```

Se for uma string que não seja um operador, resolve o valor da variável e é só
empurrar o resultado:

```ts
const v = params[el]
stack.push(v)
```

No caso de operador binário, extraímos a função que dá o valor desejado,
desempilhamos os dois últimos elementos e chamamos a função:

```ts
const f: ((lhs: number, rhs: number) => number) = opMap[el]
const rhs = stack.pop()!
const lhs = stack.pop()!
const r = f(lhs, rhs)
stack.push(r)
```

Notou que depois de `stack.pop()` tem um bang `!`? Então, ele está aqui de
propósito, porque o tipo de retorno de `Array.pop` é `undefined` ou o tipo do
array. O bang ali serve para dizer para o sistema de tipos que aquele valor
existe, que não tem como dar `undefined`. Assim, os tipos de `rhs` e `lhs`, bem
nesse trecho aqui, são entendidos como `number`.

O código inteiro se encontra abaixo:

```ts
const BIN_OP = ["+", "-", "*", "/"] as const;
type BinOp = typeof BIN_OP[number];

type RPNFormulae = (BinOp | string | number)[]

type RPN = {
    formulae: RPNFormulae,
    paramNames: string[]
}

function isBinOp(s: string): s is BinOp {
    for (const op of BIN_OP) {
        if (op == s) {
            return true;
        }
    }
    return false;
}

const opMap: Record<BinOp, (lhs: number, rhs: number) => number> = {
    "+": (lhs, rhs) => lhs + rhs,
    "-": (lhs, rhs) => lhs - rhs,
    "*": (lhs, rhs) => lhs * rhs,
    "/": (lhs, rhs) => rhs == 0? 0: lhs / rhs
} as const;

function extractParamsRPNFormulae(formulae: RPNFormulae): string[] {
    const vars: Set<string> = new Set()
    let i = 0

    while (i < formulae.length) {
        const el = formulae[i]

        if (typeof el == "string") {
            if (!isBinOp(el)) {
                vars.add(el)
            }
        }
        i++
    }
    return [ ...vars ]
}

function rpnCalculate(params: { [paramName: string]: number; }, formulae: RPNFormulae): number {
    const stack: number[] = []
    let i = 0

    while (i < formulae.length) {
        const el = formulae[i]

        if (typeof el == "string") {
            if (isBinOp(el)) {
                const f: ((lhs: number, rhs: number) => number) = opMap[el]
                const rhs = stack.pop()!
                const lhs = stack.pop()!
                const r = f(lhs, rhs)
                stack.push(r)
            } else {
                const v = params[el]
                stack.push(v)
            }
        }
        if (typeof el == "number") {
            stack.push(el)
        }
        i++
    }

    return stack[0]
}

function rpnValidate(formulae: RPNFormulae): boolean {
    let stackSize = 0
    let i = 0

    while (i < formulae.length) {
        const el = formulae[i]

        if (typeof el == "string") {
            if (isBinOp(el)) {
                if (stackSize < 2) {
                    return false
                }
                stackSize -= 1
            } else {
                stackSize += 1
            }
        }
        if (typeof el == "number") {
            stackSize += 1
        }
        i++
    }

    return stackSize == 1
}

function isRpn(a: any): a is RPNFormulae {
    if (!Array.isArray(a)) {
        return false
    }
    for (const el of a) {
        if (typeof el == "string") {
            continue;
        }
        if (typeof el == "number") {
            continue;
        }
        return false
    }
    return rpnValidate(a as RPNFormulae)
}

export type { RPN, RPNFormulae }

export { rpnCalculate, isRpn , extractParamsRPNFormulae}
```
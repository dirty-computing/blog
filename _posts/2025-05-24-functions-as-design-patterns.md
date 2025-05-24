---
layout: post
title: "Funções como padrões de projeto: do GoF pro Computaria"
author: "Jefferson Quesado"
tags: design-pattern fp ts
base-assets: "/assets/functions-as-design-patterns/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Fui passear no Twitter e uma coisa (nominalmente a conta do HTMX) me gravitou
rumo ao Uncle Bob (Clean Code, Clean Architecture, signatário do manifesto ágil
etc). E eis que ele lançou um dos rants de roupão:

[https://x.com/unclebobmartin/status/1919727590488588400](https://x.com/unclebobmartin/status/1919727590488588400)

Em resumo, ele fala do GoF e do estudo que foi feito pelos 4 para catalogar os
23 padrões iniciais com nome, caso de uso etc, e o rant foi sobre os functional
bros que falam "é tudo função, mano".

Tem partes que concordo? Sim, quando ele fala no meio do rant que esses
functional bros dizem "num liga pra isso não, isso é tão década de 1990". Eu
particularmente acho que tem seu aspecto relevante sim, por isso estou aqui
oferecendo minha visão de "é tudo função, mano".

Estou com o GoF em mãos, então vou seguir na ordem que ele coloca os padrões.
A propósito, vou ilustrar as funções com TypeScript.

Em diversos pontos vou pegar textos do livro, principalmente na descrição dos
padrões de projeto. Basicamente tudo que tiver em um bloco de citação neste
post adveio do GoF, reimpressão de 2004 pela Bookman, versão localizada para o
Brasil.

# Padrões de criação

Parafraseando do livro:

> Os padrões de criação abstraem o processo de instanciação.

Hmmm, então aqui vamos ter algo no formato geral:

```ts
const factory = ...;
const item1 = factory();
const item2 = factory();
```

## Abstract factory

> Fornecer uma interface para a criação de famílias de objetos [...] sem
> especificar suas classes concretas

No exemplo, ele utiliza componentes para o _look-and-feel_ "Motif" e para o
"Presentation Manager". Como isso para mim soa vazio, imagina que seja para
TCL/TK e para HTML. Ele lida com janelas e barra de rolagem, `window` e
`scrollbar`.

O cliente (que vai exibir visualmente as coisas) precisa ser capaz de entender
o que deveria dar o display. Como seria isso com funções? Pois bem:

```ts
type WidgetCreation = {
    createWindow : (properties: WindowProperties) => Window,
    createScrollBar : (properties: ScrollBarProperties) => ScrollBar,
}
```

E... é isso. Na hora de instanciar o client só precisa criar um objeto que
respeite o shape `WidgetCreation` e pronto, finito. O typesystem garante pra
você as coisas. E inclusive o `Window` ou `ScrollBar` que ele gera nem precisa
ser uma "classe", precisa ter um formato mínimo reconhecível pra dizer que é
uma window ou uma scrollbar. O client manipula windows e scrollbar e fim.

## Builder

> Separar a construção de um objeto complexo da sua representação de modo que o
> mesmo processo de construção possa criar diferentes representações.

O exemplo mais clássico que temos é o da simples criação de um objeto complexo
com muitos campos. Vamos fazer um exemplo de construção matemática complexa?
Fórmulas com operadores binários. O tipo de um operador é `BinOp` e vamos
definir para os 4 básicos: adição, subtração, multiplicação e divisão. Como
vamos seguir o padrão de projeto? Com clausuras!

```ts
type BinOp = (lhs: number) => LackRhs

type LackRhs = {
    (rhs: number): OpReady,
    lhs : (newLhs: number) => LackRhs
}

type OpReady = {
    () : number,
    lhs : (newLhs: number) => LackRhs,
    rhs : (newRhs: number): OpReady
}
```

A ideia aqui é construir o número no final. Além disso, dei a possibilidade de
reescrever o operando anterior. E por fim, o builder vai estar pronto quando
estiver no tipo `OpReady`, que aí basta chamar ele que ele irá criar o objeto,
que no caso é o número alvo.

Mas, antes, vamos pegar o caso mais trivial e depois chegar nisso? Vamos ver
implementado?

```ts
type BinOpTrivial = (lhs: number) => (rhs: number) => number

const soma : BinOpTrivial = (lhs) => (rhs) => lhs + rhs
const sub : BinOpTrivial = (lhs) => (rhs) => lhs - rhs
const mult : BinOpTrivial = (lhs) => (rhs) => lhs * rhs
// tratando o caso do denominador 0 só por via das dúvidas
const div : BinOpTrivial = (lhs) => (rhs) => rhs == 0 ? 0 :lhs / rhs


// ((6-1)*2)   /   (1+1)
// no final imprime 5
console.log(div(mult(sub(6)(1))(2))(soma(1)(1)))
```

Agora vamos ver como é para dar a opção do backtracking? Primeiro, adicionar a
camada no momento desnecessário da operação pronta para construção, o
`OpReady`, ainda sem opção de backtracking:

```ts
type BinOp_OpReadyTrivial = (lhs: number) => (rhs: number) => OpReadyTrivial
type OpReadyTrivial = () => number

const soma : BinOp_OpReadyTrivial = (lhs) => (rhs) => () => lhs + rhs
const sub : BinOp_OpReadyTrivial = (lhs) => (rhs) => () => lhs - rhs
const mult : BinOp_OpReadyTrivial = (lhs) => (rhs) => () => lhs * rhs
// tratando o caso do denominador 0 só por via das dúvidas
const div : BinOp_OpReadyTrivial = (lhs) => (rhs) => () => rhs == 0 ? 0 :lhs / rhs


// ((6-1)*2)   /   (1+1)
// no final imprime 5
console.log(div(mult(sub(6)(1)())(2)())(soma(1)(1)())())
```

Ok, vamos adicionar no `OpReady` a opção do `rhs`:

```ts
type BinOp_OpReadyRhs = (lhs: number) => (rhs: number) => OpReadyRhs
type OpReadyRhs = {
    (): number,
    rhs: (newRhs: number) => OpReadyRhs
}

const soma : BinOp_OpReadyRhs = (lhs) => (rhs) => {
  const baseOp: OpReadyRhs = () => lhs + rhs
  const rhsOverride = (newRhs: number) => {
    const baseOp2: OpReadyRhs = () => lhs + newRhs;
    baseOp2.rhs = rhsOverride;
    return baseOp2
  }
  baseOp.rhs = rhsOverride
  return baseOp
}

// 2 + ~~2~~  3
// no final imprime 5
console.log(soma(2)(2).rhs(3)())
```

Isso demanda um pouco mais de explicação. Vamos já para a operação que retorna
um `OpReadyRhs`:

```ts
// lhs e rhs via clausura
const baseOp: OpReadyRhs = () => lhs + rhs
const rhsOverride = (newRhs: number) => {
    const baseOp2: OpReadyRhs = () => lhs + newRhs;
    baseOp2.rhs = rhsOverride;
    return baseOp2
}
baseOp.rhs = rhsOverride
return baseOp
```

No primeiro lugar, a operação pura. Apenas o LHS somado ao RHS. Como visto no
[Recursão a moda clássica em TS: auto referência do tipo de função]({% post_url 2025-01-15-ts-self-type-referential-function %}),
para um tipo que é uma função e um objeto com atributo, para declarar e o
compilador ficar feliz, uma estratégia é começar pela função

```ts
const baseOp: OpReadyRhs = () => lhs + rhs
```

e então posteriormente adicionar o atributo

```ts
baseOp.rhs = rhsOverride
```

Para `rhsOverride`, eu comecei declarando uma nova operação base:

```ts
const baseOp2: OpReadyRhs = () => lhs + newRhs;
```

e então, aproveitando a criação do `rhsOverride`, usei ele recursivamente
dentro dele para terminar de povoar `baseOp2`:

```ts
baseOp2.rhs = rhsOverride
```

E pronto, magia!

Agora, basta replicar esse mesmo pensamento para as outras operações:

```ts
type BinOp_OpReadyRhs = (lhs: number) => (rhs: number) => OpReadyRhs
type OpReadyRhs = {
    (): number,
    rhs: (newRhs: number) => OpReadyRhs
}

const soma : BinOp_OpReadyRhs = (lhs) => (rhs) => {
  const baseOp: OpReadyRhs = () => lhs + rhs
  const rhsOverride = (newRhs: number) => {
    const baseOp2: OpReadyRhs = () => lhs + newRhs;
    baseOp2.rhs = rhsOverride;
    return baseOp2
  }
  baseOp.rhs = rhsOverride
  return baseOp
}

const sub : BinOp_OpReadyRhs = (lhs) => (rhs) => {
  const baseOp: OpReadyRhs = () => lhs - rhs
  const rhsOverride = (newRhs: number) => {
    const baseOp2: OpReadyRhs = () => lhs - newRhs;
    baseOp2.rhs = rhsOverride;
    return baseOp2
  }
  baseOp.rhs = rhsOverride
  return baseOp
}

const mult : BinOp_OpReadyRhs = (lhs) => (rhs) => {
  const baseOp: OpReadyRhs = () => lhs * rhs
  const rhsOverride = (newRhs: number) => {
    const baseOp2: OpReadyRhs = () => lhs * newRhs;
    baseOp2.rhs = rhsOverride;
    return baseOp2
  }
  baseOp.rhs = rhsOverride
  return baseOp
}
// tratando o caso do denominador 0 só por via das dúvidas
const div : BinOp_OpReadyRhs = (lhs) => (rhs) => {
  const baseOp: OpReadyRhs = () => rhs == 0 ? 0 : lhs / rhs
  const rhsOverride = (newRhs: number) => {
    const baseOp2: OpReadyRhs = () => newRhs == 0 ? 0 : lhs / newRhs;
    baseOp2.rhs = rhsOverride;
    return baseOp2
  }
  baseOp.rhs = rhsOverride
  return baseOp
}


// 2 + ~~3~~  2
// no final imprime 5
console.log(soma(2)(2).rhs(3)())

// ((6-1)*2)   /   (1+1)
// no final imprime 5
console.log(div(mult(sub(6)(1)())(2)())(soma(1)(1)())())
```

Ok, agora para o experimento em que o `OpReady` está completo! Podendo
sobrescrever LHS e RHS! Começar na adição:

```ts
type BinOp_OpReady = (lhs: number) => (rhs: number) => OpReady
type OpReady = {
    (): number,
    lhs: (newlhs: number) => OpReady
    rhs: (newRhs: number) => OpReady
}

const soma : BinOp_OpReady = (lhs) => (rhs) => {
  const baseOp: OpReady = () => lhs + rhs
  baseOp.lhs = (newLhs) => soma(newLhs)(rhs)
  const rhsOverride = (newRhs: number) => {
    const baseOp2: OpReady = () => lhs + newRhs;
    baseOp2.lhs = (newLhs) => soma(newLhs)(newRhs)
    baseOp2.rhs = rhsOverride;
    return baseOp2
  }
  baseOp.rhs = rhsOverride
  return baseOp
}

// 2 + ~~3~~  2
// no final imprime 5
console.log(soma(2)(2).rhs(3)())

// 2 + 2         ... ?
// ~~2~~ 3 + 2   ... ?
// 3 + ~~2~~ 3   ... ?
// ~~3~~ 2 + 3   ... ?
// 2 + 3         ... !
// no final imprime 5
console.log(soma(2)(2).lhs(3).rhs(3).lhs(2)())
```

Bora lá explicar? Bora! A parte do RHS se mantém intacta. Afinal, só mudou a
adição do LHS. E o que é adicionar o LHS se não começar a operação tudo de
novo? Só aproveitando o RHS corrente? Pois foi isso que fiz. No caso externo:

```ts
const baseOp: OpReady = () => lhs + rhs
baseOp.lhs = (newLhs) => soma(newLhs)(rhs)
```

E no caso interno, que só preicsei tomar cuidado de usar o `newRhs` no lugar do
`rhs` da clausura:

```ts
const baseOp2: OpReady = () => lhs + newRhs;
baseOp2.lhs = (newLhs) => soma(newLhs)(newRhs)
```

Aplicando o mesmo conceito nos outros operadores:

```ts
type BinOp_OpReady = (lhs: number) => (rhs: number) => OpReady
type OpReady = {
    (): number,
    lhs: (newlhs: number) => OpReady
    rhs: (newRhs: number) => OpReady
}

const soma : BinOp_OpReady = (lhs) => (rhs) => {
  const baseOp: OpReady = () => lhs + rhs
  baseOp.lhs = (newLhs) => soma(newLhs)(rhs)
  const rhsOverride = (newRhs: number) => {
    const baseOp2: OpReady = () => lhs + newRhs;
    baseOp2.lhs = (newLhs) => soma(newLhs)(newRhs)
    baseOp2.rhs = rhsOverride;
    return baseOp2
  }
  baseOp.rhs = rhsOverride
  return baseOp
}

const sub : BinOp_OpReady = (lhs) => (rhs) => {
  const baseOp: OpReady = () => lhs - rhs
  baseOp.lhs = (newLhs) => sub(newLhs)(rhs)
  const rhsOverride = (newRhs: number) => {
    const baseOp2: OpReady = () => lhs - newRhs;
    baseOp2.lhs = (newLhs) => sub(newLhs)(newRhs)
    baseOp2.rhs = rhsOverride;
    return baseOp2
  }
  baseOp.rhs = rhsOverride
  return baseOp
}

const mult : BinOp_OpReady = (lhs) => (rhs) => {
  const baseOp: OpReady = () => lhs * rhs
  baseOp.lhs = (newLhs) => mult(newLhs)(rhs)
  const rhsOverride = (newRhs: number) => {
    const baseOp2: OpReady = () => lhs * newRhs;
    baseOp2.lhs = (newLhs) => mult(newLhs)(newRhs)
    baseOp2.rhs = rhsOverride;
    return baseOp2
  }
  baseOp.rhs = rhsOverride
  return baseOp
}
// tratando o caso do denominador 0 só por via das dúvidas
const div : BinOp_OpReady = (lhs) => (rhs) => {
  const baseOp: OpReady = () => rhs == 0 ? 0 : lhs / rhs
  baseOp.lhs = (newLhs) => div(newLhs)(rhs)
  const rhsOverride = (newRhs: number) => {
    const baseOp2: OpReady = () => newRhs == 0 ? 0 : lhs / newRhs;
    baseOp2.lhs = (newLhs) => div(newLhs)(newRhs)
    baseOp2.rhs = rhsOverride;
    return baseOp2
  }
  baseOp.rhs = rhsOverride
  return baseOp
}

// 2 + ~~3~~  2
// no final imprime 5
console.log(soma(2)(2).rhs(3)())

// 2 + 2         ... ?
// ~~2~~ 3 + 2   ... ?
// 3 + ~~2~~ 3   ... ?
// ~~3~~ 2 + 3   ... ?
// 2 + 3         ... !
// no final imprime 5
console.log(soma(2)(2).lhs(3).rhs(3).lhs(2)())

// ((6-1)*2)   /   (1+1)
// no final imprime 5
console.log(div(mult(sub(6)(1)())(2)())(soma(1)(1)())())
```

Agora vamos para a versão final? Não só o `OpReady` pode redefinir o LHS, como
a operação logo no começo dela pode fazer isso. Basicamente vou pegar a ideia
de usar `.lhs = (newLhs) => OPERACAO(newLhs)` e aplicar no resultado
intermediário. O final não importa, não vai ser alterado.

```ts
type BinOp = (lhs: number) => LackRhs
type LackRhs = {
    (rhs: number): OpReady,
    lhs: (newLhs: number) => LackRhs
}
type OpReady = {
    (): number,
    lhs: (newlhs: number) => OpReady
    rhs: (newRhs: number) => OpReady
}

const soma : BinOp = (lhs) => {
    const baseLackRhs: LackRhs = (rhs) => {
        const baseOp: OpReady = () => lhs + rhs
        baseOp.lhs = (newLhs) => soma(newLhs)(rhs)
        const rhsOverride = (newRhs: number) => {
            const baseOp2: OpReady = () => lhs + newRhs;
            baseOp2.lhs = (newLhs) => soma(newLhs)(newRhs)
            baseOp2.rhs = rhsOverride;
            return baseOp2
        }
        baseOp.rhs = rhsOverride
        return baseOp
    }
    baseLackRhs.lhs = (newLhs) => soma(newLhs)
    return baseLackRhs
}

// 2 + ~~3~~  2
// no final imprime 5
console.log(soma(2)(2).rhs(3)())

// 2 + 2         ... ?
// ~~2~~ 3 + 2   ... ?
// 3 + ~~2~~ 3   ... ?
// ~~3~~ 2 + 3   ... ?
// 2 + 3         ... !
// no final imprime 5
console.log(soma(2)(2).lhs(3).rhs(3).lhs(2)())

// 5            ... ?
// ~~5~~ 2      ... !
// 2 + 2        ... ?
// 2 + ~~2~~  3 ... !
// no final imprime 5
console.log(soma(5).lhs(2)(2).rhs(3)())
```

Mas isso porque eu quis dificultar o builder e dar acesso a coisas de trás!
Normalmente builders são mais lineares.

## Factory Method

> Definir uma interface para criar um objeto, mas deixar as subclasses decidirem
> que classe instanciar. O Facotry Method permite adiar a instanciação.

Tive de recorrer ao
[Refactoring Guru](https://refactoring.guru/design-patterns/factory-method)
para o guaxinim me dar um exemplo mais concreto.

Pegando o exemplo fornecido pelo Refactoring Guru: em um software de logística,
preciso definir se devo enviar uma carega via caminhão ou navio. O caminhão
precisa ser carregado com as informações de viagens terrestres e o navio com as
informações de viagens marítimas. Enquanto isso o por cima do software só
precisa se preocupar com "vai ter algo que vai viajar e entregar".

Então...

```ts
type AbstractFactory<T> = () => T
```

Ou qualquer combinação de input. Por exemplo, origem e destino:

```ts
type FactoryRota = (origem: Lugar, destino: Lugar) => Rota
```

E basicamente precisa atender a essa assinatura. Só isso. Muitos problemas
simplesmente somem quando você lida com tipagem estrutural no lugar de tipagem
nominal.

## Prototype

> Especificar os tipos de objetos a serem criados usando uma instância
> protótipo e criar novos objetos pela cópia desse protótipo.

Pois bem, esse parece legal. Vamos pegar um protótipo de carro vermelho, quero
gerar um carro igual a esse vermelho mudando que agora eu quero que seja
amarelo. Ou que rode baseado em álcool/elétrico. Enfim.

Basicamente o operador _spread_ permite isso de maneira muito simples. Para dar
a opção de trabalhar com todos os parâmetros de customização possível, usemos o
tipo `Partial` do TS:

```ts
type Carro = {
    cor: string,
    motor: ("elétrico" | "gasolina" | "diesel" | "álcool")[]
}

type CarroCustom = Partial<Carro>

const prototipado = (carroPrototipo: Carro) => (custom: CarroCustom) => ({...carroPrototipo, ...custom})

const carroVermelho: Carro = {
    cor: "vermelho",
    motor: ["gasolina"]
}

const fabrica = prototipado(carroVermelho)

const carroAmarelo = fabrica({cor: "amarelo"})
console.log(carroAmarelo)

const carroEletroAlcool = fabrica({motor: ["elétrico", "álcool"]})
console.log(carroEletroAlcool)
```

Basicamente o `prototipado` vai garantir que os objetos criados sejam feitos
com base na semelhança do objeto protótipo passado como opção.

Novamente aqui a tipagem estrutural ajudando a combater coisas que teríamos com
tipagem nominal.

No livro os objetos implementam `clone`. Mas esse detalhe é irrelevante para TS
e sua tipagem estrutural. A escolha continuaria sendo usar um _spread_ para
representar a operação de `clone`.

## Singleton

> Garantir que uma classe tenha somente uma instância e fornecer um ponto
> global de acesso.

```ts
import {instance} from "./modulo.js"
```

E claro que no `modulo` devo exportar a constante `instance`.

Esse é um tipo de padrão de projeto que foi resolvido no mundo Java, por
exemplo, através de injeção de dependência do Spring. Existem casos como em
dependências circulares que você precisaria obter esse objeto, mas existem
outros caminhos para isso que não a injeção a priori para ter um objeto bem
formado em tempo de instanciação, mas esse tipo de dependência deveria ser
muito rara.

O maior problema do lazy singleton é a questão de "e se chegarem duas threads
ao mesmo tempo?", situação em que muitas pessoas vão adotar o padrão "double
checked lock".

Mas para isso a solução é delegar a uma parte da própria linguagem que ela vai
ter mais ferramentas de controle do que você. Por exemplo, em Java, é comum
fazer uma volta dessas para obter o singleton:

```java
public class MustBeSingleton {

    private MustBeSingleton() {
    }

    public static MustBeSingleton getInstance() {
        return SINGLETON_LOADER.singleton;
    }

    private static class SINGLETON_LOADER {
        static final MustBeSingleton singleton = new MustBeSingleton();
    }
}
```

Isso funciona em Java porque você só pode mencionar a classe `MustBeSingleton`.
Ela é então carregada e inicializada, e ela não guarda instância de si mesma,
não é um _eager singleton_. No momento em que alguém for dar um
`getInstance()`, o que vai acontecer é que ele vai tentar identificar
`MustBeSingleton$SINGLETON_LOADER`, a classe interna, e vai verificar que a
classe não foi carregada. Nesse momento o classloader do Java vai se travar e
nenhuma outra thread mais vai poder carregar nenhuma classe (lock). Logo,
carregamentos em paralelo não vão ocorrer, vai sequenciar.

Logo em seguida, ao inicializar a classe `MustBeSingleton$SINGLETON_LOADER` o
campo `MustBeSingleton$SINGLETON_LOADER.singleton` vai ficar preenchido e então
o classloader vai liberar. Quem estava esperando o classloader soltar vai
encontrar uma classe carregada e vai retornar esse campo.

# Padrões estruturais

Parafraseando da primeira frase do capítulo 4:

> Os padrões estruturais se preocupam com a forma como classes e objetos são
> compostos para formar estruturas maiores.

Ele menciona que "estruturas de classes" resolve na herança, incluindo herança
múltipla. E que "estruturas de objetos" ele faz pondo objetos em cima do outro
sem mexer com a classe em si.

## Adapter

> Adapter permite que classes com interfaces incompatíveis trabalhem em
> conjunto o que, de certa forma, seria impossível.

Aqui ele está falando de interface. E tem dois pensamentos para isso:

- shape
- conjunto de métodos que podem ser chamados

Ok, muito bem. Para adaptar o shape é algo fácil: só criar uma função de
mapeamento: `f(input: I): O`.

Por exemplo: peguemos aqui 2 objetos bem distintos:

- triângulo
- círculo

Como seriam os shapes deles?

```ts
type Triangulo = {
    a: number,
    b: number,
    c: number
}

type Circulo = {
    r: raio
}
```

Onde o triângulo é fornecido pelos seus lados e o círculos descrito pelo seu
raio. Podemos precisar adaptar para um componente de preço que vai pegar um
`ElementoGeometrico` e gerar o preço a partir do perímetro e da área. No caso,
vamos considerar no exemplo que todo triângulo é bem formado (ie, a soma de
quaisquer dois lados é maior do que o terceiro lado).

Vamos definir o tipo para `ElementoGeometrico` e então fazer os adaptadores:

```ts
type ElementoGeometrico = {
    perimetro : number,
    area: number
}

function perimetroTriangulo(t: Triangulo): number {
    return t.a + t.b + t.c
}

function areaTriangulo(t: Triangulo): number {
    // fórmulan de Herón
    const s = perimetroTriangulo(t)/2

    return Math.sqrt(s * (s-a) * (s-b) * (s-c))
}

function perimetroCirculo(c: Circulo): number {
    return 2*Math.PI*c.r
}

function areaCirculo(c: Circulo): number {
    return Math.PI * c.r * c.r
}

function adapterTriangulo2ElementoGeometrico(t: Triangulo): ElementoGeometrico {
    return {
        perimetro: perimetroTriangulo(t),
        area: areaTriangulo(t)
    }
}

function adapterCirculo2ElementoGeometrico(c: Circulo): ElementoGeometrico {
    return {
        perimetro: perimetroCirculo(c),
        area: areaCirculo(c)
    }
}
```

Muito bem, adaptamos o shape, falta agora a questão de comportamento. Imagina
que você precisa receber um objeto do tipo `Repository`, e nele temos o
seguinte comportamento:

- pode inserir novos elementos
- pode remover elemento (dado uma condição)
- pode atualizar elemento (dada uma função de transformação e uma condição de
  ativação)
- resgata elementos que satisfazem uma condição

Em outras palavras:

```ts
type Repository<T> = {
    insert : (el: T) => void,                                             // insere um novo
    removeIf : (condition : (el:T) => boolean) => void,                   // remove os que preciso
    getAll : (condition : (el:T) => boolean) => T[],                      // resgata tudo que satisfaz
    update : (condition : (el:T) => boolean, map : (el:T) => T) => void   // resgata tudo que satisfaz
}
```

Muito bem. Vamos começar com um array? Vamos criar um adaptador para o array
ser usado tal qual esse `Repository` acima descrito.

```ts
function adapter2array<T>(elements: T[]): Repository<T> {
    type Conditional = (el:T) => boolean;
    const insert = (t: T) => {
        elements.push(t)
    }
    const removeIf = (cond: Conditional) => {
        elements = elements.filter(e => !cond(e))
    }
    const getAll = (cond: Conditional) => {
        return elements.filter(cond)
    }
    const update = (cond: Conditional, map: (el:T) => T) => {
        elements = elements.map(e => cond(e) ? map(e): e)
    }

    return {
        insert,
        removeIf,
        getAll,
        update
    }
}
```

E como usar? Bem, imagina que eu quero manipular um repositório de números:

```ts
const repository: Repository<number> = ...
repository.insert(6)

const pares = arrayRepository.getAll(e => e % 2 == 0)

arrayRepository.update(e => e % 2 != 0, e => 3*e + 1)
arrayRepository.removeIf(e => e >= 5)
```

Mas como eu posso criar um repositório? Uma das alternativas é adaptar um
array! E nós já sabemos como adaptar o array!

```ts
const numbers = [ 1, 2, 3 ]

const arrayRepository = adapter2array(numbers)
console.log(arrayRepository.getAll(_ => true))
// 1, 2, 3

arrayRepository.insert(6) // [1, 2, 3, 6]
console.log(arrayRepository.getAll(_ => true))
// 1, 2, 3, 6
console.log(arrayRepository.getAll(e => e % 2 == 0))
// 2, 6

arrayRepository.update(e => e % 2 != 0, e => 3*e + 1) // [4, 2, 10, 6]
console.log(arrayRepository.getAll(_ => true))
// 4, 2, 10, 6


arrayRepository.removeIf(e => e >= 5) // [4, 2]
console.log(arrayRepository.getAll(_ => true))
// 4, 2
```

O array não tinha suporte a nada disso, mas nada como por o adaptar no lugar,
né? Só uma função que adapte o básico do objeto e permita ele obedecer outra
sequência de protocolos.

Apesar de um livro focar que adaptador é de uma classe para outra, podemos
compor também para uma entrada de múltiplos elementos. Tudo questão de
modelagem.

## Bridge

> Desacoplar uma abstração de sua implementação, de modo que as duas possam
> evoluir independentemente.

Na minha leitura não vi grande diferença entre o bridge e o adapter, então
agora recorri ao Stack Overflow, e eis que encontro [essa resposta do Jeff
Wilcox](https://stackoverflow.com/a/1425192/4438007):

> O padrão bridge vai permitir que você tenha implementações alternativas de um
> algoritmo/sistema.

O exemplo que ele menciona: para salvar, quem vê de fora só chama "salvar",
eles chamam a bridge que vai de fato chamar quem faz as operações finais. E eu
posso ter implementações completamente contrárias: uma que se baseia em tempo e
outra que vai salvar ocupando menos espaço em disco.

A interface vai continuar sendo a mesma, e então colocamos uma ponte pra ligar
a interface as implementações. Em outras palavras:

- Adapter: você já tem algo que funciona e se molda a ele
- Bridge: desenho upfront para o funcionamento desacoplado

No fundo, coisas bem semelhantes, mas motivações distintas. Então o exemplo de
adaptador que eu coloquei acima pode ser usado para a bridge sem problema.

Como aqui estamos falando de tipagem estrutural e não tipagem nominal, a
questão da necessidade de que o adapter seja uma subclasse de algo some,
tornando efetivamente um ponto de vista/ponto de origem de pensamento o que
causa a distinção. Isso se reflete no GoF logo ao falar da motivação da bridge,
que demonstra que é um _language issue_:

> Quando uma abstração pode ter uma entre várias implementações possíveis, a
> maneira usual de acomodá-las é usando a herança.

E de lá ele continua explicando a questão da herança e reuso do código e também
dos problemas. Mas isso é uma das mentiras do OOP que eu expus neste artigo
[As mentiras que te contaram sobre OOP]({% post_url 2024-08-21-mentiras-oop %}).
Especificamente a mentira #2: Reuso de software através de métodos. Me
parafraseando: "Isso aí é desculpa pra herança".

Por fim, defendendo o que foi pontuado, logo no final da seção sobre bridge, no
GoF está escrito algo que corrobora com o que pesquei das respostas do Stack
Overflow (ênfase minha):

> O padrão adapter é orientado para fazer com que classes não-relacionadas
> trabalhem em conjunto. Ele é normalmente aplicado a sistemas que
> **já foram projetados**. Por outro lado, bridge é usado em um projeto,
> **desde o início**, para permitir que abstrações e implementações possam
> variar independentemente.

## Composite

> Compor objetos em estruturas de árvore para representarem uma hierarquia
> partes-todo. Composite permite aos clientes tratarem de maneira uniforme
> objetos individuais e composição de objetos.

Na parte da motivação no GoF tem uma explicação um pouco mais aprofundada:

> O padrão composite descreve como usar a composição de maneira recursiva de
> maneira que os clientes não tenham que fazer essa distinção.

Ou seja: basicamente um shape em que eu tenho primitivos e containeres que por
sua vez são compostos por elementos desse mesmo shape. Aqui esse padrão é muito
mais relacionado com tipagem do que com funções.

O exemplo motivador do composite é um componente gráfico:

```ts
type LeafComponent = {
    draw: () => void
};

type ContainerComponent = {
    addComponent : (c: Component) => void,
    removeComponent : (c: Component) => void,
    children : () => Component[],
    draw: () => void
};

type Component = {
    draw: () => void
};
```

Note que a tipagem estrutural não faz com que seja necessário listar os
components individuais como sumtype, apenas que eles tenham o shape. Aqui um
modelo bem simples colocando containeres e elementos dentro do container:

```ts
type LeafComponent = {
    draw: () => void
};

type ContainerComponent = {
    addComponent : (c: Component) => void,
    removeComponent : (c: Component) => void,
    children : () => Component[],
    draw: () => void
};

type Component = {
    draw: () => void
};

function simpleContainer() : ContainerComponent {
    let children: Component[] = []
    return {
        addComponent : (c) => {
            children.push(c)
        },
        removeComponent : (c) => {
            children = children.filter(e => e != c)
        },
        children: () => {
            return children
        },
        draw: () => {
            console.log("[")
            for (const c of children) {
                c.draw();
            }
            console.log("]")
        }
    }
}

function labelComponent(s: string) {
    return {
        draw : () => console.log(s)
    }
}

const container1 = simpleContainer();
const container2 = simpleContainer();

container1.addComponent(labelComponent("before child"))
container1.addComponent(container2)
container1.addComponent(labelComponent("after child"))

container2.addComponent(labelComponent("child"))

container1.draw()

/*

 [
 before child
 [
 child
 ]
 after child
 ]

 */
```

## Decorator

> Dinamicamente, agregar responsabilidades adicionais a um objeto. Os 
> decorators fornecem uma alternatival flexível ao uso de subclasses para
> extensão de funcionalidades.

A ideia do decorator é alterar o comportamento de um objeto de uma classe. Como
que se faz isso? Vamos primeiro dar uma olhada em um simples wrapper que passa
adiante uma chamada que recebe dois inteiros:

```ts
function myFunction(base: string, m: number, n: number): string {
    return `${base}: ${m} + ${n}`
}

function decorated<T, R>(base: T, m: number, n: number, notDecorated: (b: T, m: number, n: number) => R): R {
    return notDecorated(t, m, n)
}

console.log(myFunction("soma", 2, 3))
console.log(decorated("soma", 2, 3, myFunction))
```

Note que aqui estou fazendo uma "decoração explícita", o que o decorator não
deveria transparecer, mas é só pelo exemplo. Além disso, tem outro ponto no
decorator: estou tratando aqui uma função que recebe o objeto como argumento
como sendo um método. Isso é uma aproximação preguiçosa a fim de mostrar o
exemplo. Afinal, o que é decorar uma chamada?

Basicamente, tem algumas coisas acontecendo na chamada da função não decorada:

- tem um retorno específico
- estou ativamente escolhendo chamar a função não decorada
- estou ativamente escolhendo passar os argumentos para a função não decorada
- ativamente não tem nada antes
- ativamente não tem nada depois
- ativamente está sendo usado o retorno da função sendo chamada

Agora, vamos desenhar um decorator real, o decorator noop, para uma função que
recebe um elmento base e dois parâmetros inteiros:

```ts
function myFunction(base: string, m: number, n: number): string {
    return `${base}: ${m} + ${n}`
}

function noopDecorator<T, R>(baseFunction: (base: T, m: number, n: number) => R): (base: T, m: number, n: number) => R {
    return (base: T, m: number, n: number) => baseFunction(base, m, n)
}

const decorated = noopDecorator(myFunction)


console.log(myFunction("soma", 2, 3))
console.log(decorated("soma", 2, 3))
```

O que podemos fazer pra decorar? Vamos olhar os pontos levantados anteriormente
de coisas sendo feitas e para cada ponto fazer uma decoração distinta.

### Tem um retorno específico

Ok, que tem um retorno tem. Podemos alterar o tipo do retorno, mas para isso
precisamos também mapear o retorno possivelmente. Isso vai ser tratado
posteriormente, e normalmente para o cenário de decoração que o GoF traz não é
algo válido.

Uma decoração que muda o tipo do retorno pode ser usado em um adapter, por
sinal.

### Estou ativamente escolhendo chamar a função não decorada

Vamos ativamente não chamar a função decorada? Imagina que para a entrada
`m == 0` querendo simplesmente retornar `chamada ruim`, aqui retornando apenas
strings:

```ts
function mNot0<T, string>(baseFunction: (base: T, m: number, n: number) => string): (base: T, m: number, n: number) => string {
    return (base: T, m: number, n: number) => {
        if (m === 0) {
            return "chamada ruim"
        }
        return baseFunction(base, m, n)
    }
}
```

Com isso, decoramos quando que ocorrerá a invocação, apenas para quando o `m`
não for 0.

### Estou ativamente escolhendo passar os argumentos para a função não decorada

Posso simplesmente fixar os valores e permitir quem chame de continuar chamando
sem medo:

```ts
function params_0_0<T, R>(baseFunction: (base: T, m: number, n: number) => R): (base: T, m: number, n: number) => R {
    return (base: T, m: number, n: number) => baseFunction(base, 0, 0)
}
```

Ok, isso foi um exemplo extremo. Eu posso passar qualquer mudança nos parâmetros:

```ts
function paramsDobrados<T, R>(baseFunction: (base: T, m: number, n: number) => R): (base: T, m: number, n: number) => R {
    return (base: T, m: number, n: number) => baseFunction(base, 2*m, 2*n)
}
```

Isso pode ser útil quando quero, por exemplo, decorar um elemento para ficar
"mais vermelho", adicionando uma camada de "vermelhidão" nas cores (essa camada
normalmente é uma multiplicação/soma no vetor de cores RGB seguindo alguma
lógica).

Ou então também dá para simplesmente trocar os parâmetros de ordem

```ts
function paramsDobrados<T, R>(baseFunction: (base: T, m: number, n: number) => R): (base: T, m: number, n: number) => R {
    return (base: T, m: number, n: number) => baseFunction(base, n, m)
}
```

Enfim, a bagunça que se quiser fazer nas chamadas.

### Ativamente não tem nada antes

Se aqui a escolha é não ter nada antes, o contrário é ter algo antes!

```ts
function logaAntes<T, R>(baseFunction: (base: T, m: number, n: number) => R): (base: T, m: number, n: number) => R {
    return (base: T, m: number, n: number) => {
        console.log(`chamando com m: ${m} e n: ${n}`)
        return baseFunction(base, m, n)
    }
}
```

Isso pode ser feito para gerar efeitos colaterais, algumas vezes para ter um
trace debug. Assim, se você quiser manter um log de chamadas você pode decorar
uma função para fazer isso, diminuindo o quanto de mudança seria necessária na
codebase e podendo focar em "e se o objeto que estiver sendo atingido for esse,
que é alcançado nessa rota afinal?".

### Ativamente não tem nada depois

Literalmente o que foi dito na seção anterior, mas agora aplicada a o que
acontece depois da chamada:

```ts
function logaDepois<T, R>(baseFunction: (base: T, m: number, n: number) => R): (base: T, m: number, n: number) => R {
    return (base: T, m: number, n: number) => {
        const r = baseFunction(base, m, n)
        console.log(`chamou com m: ${m} e n: ${n} e o resultado foi ${r}`)
        return r
    }
}
```

Logar depois permite criar uma base bem legal de entrada/saída obtida para
fazer migração de código. Esse conjunto de informações é utilizado para testar
uma substituição feita no padrão
[_strangler fig_](https://martinfowler.com/bliki/StranglerFigApplication.html).

### Ativamente está sendo usado o retorno da função sendo chamada

E se eu quiser multiplicar por 3 e somar um no resultado?

```ts
function tres_r_mais_1<T>(baseFunction: (base: T, m: number, n: number) => number): (base: T, m: number, n: number) => number {
    return (base: T, m: number, n: number) => {
        const r = baseFunction(base, m, n)
        return 3*r + 1
    }
}
```

Note que, por facilidade, estou decorando agora funções que retornam números.

### Retornando ao assunto...

Vimos aqui onde interceptar as coisas de uma chamada de função com uma
decoração. Sabe onde é muito aplicado a questão de usar decoradores? Em
programação orientada a aspecto!

Por exemplo, eu posso fazer uma decoração para iniciar uma transação com o
banco de dados. Ou então para logar quando entrou/saiu para ter uma ideia de
performance (ou só logar quando saiu, contanto o tempo desde antes da chamada
até o depois da chamada).

No cenário do GoF, eles colocam decorators para adicionar comportamentos
específicos em um método. Vou pegar o exemplo de repositório usado no adapters
para fazer uma decoração nele:

```ts
type Repository<T> = {
    insert : (el: T) => void,                                             // insere um novo
    removeIf : (condition : (el:T) => boolean) => void,                   // remove os que preciso
    getAll : (condition : (el:T) => boolean) => T[],                      // resgata tudo que satisfaz
    update : (condition : (el:T) => boolean, map : (el:T) => T) => void   // resgata tudo que satisfaz
}

function decorateRepositoryWithLoggingInsert<T>(base: Repository<T>): Repository<T> {
    const novoInsert = (el: T) => {
        console.log(`inserindo novo elemento >${el}<`)
        base.insert(el)
    }
    return {
        ...base,
        insert: novoInsert
    }
}

function decorateRepositoryWithLoggingRemovedCount<T>(base: Repository<T>): Repository<T> {
    const novoRemove = (condition : (el:T) => boolean) => {
        console.log(`removendo >${base.getAll(condition)}< elementos`)
        base.update(condition, map)
    }
    return {
        ...base,
        removeIf: novoRemove
    }
}
```

A decoração pode ser de quantos métodos quiser, não precisa ser um por um:


```ts
function decorateRepositoryWithLoggingChangedCount<T>(base: Repository<T>): Repository<T> {
    const novoRemove = (condition : (el:T) => boolean) => {
        console.log(`removendo >${base.getAll(condition)}< elementos`)
        base.removeIf(condition)
    }
    const novoUpdate = (condition : (el:T) => boolean, map : (el:T) => T) => {
        console.log(`atualizando >${base.getAll(condition)}< elementos`)
        base.update(condition, map)
    }
    return {
        ...base,
        removeIf: novoRemove,
        update: novoUpdate
    }
}
```

## Façade

> Fornecer uma interface unificada para um conjunto de interfaces em um
> subsistema. Façade define uma interface de nível mais alto que torna o
> subsistema mais fácil de ser usado.

Basicamente, o façade é uma espécie de adapter invertido: eu chamo a fachada e
deixo que ela delibere quem chamar e como chamar. O exemplo do GoF é um
compilador que conhece quem é o scanner/parser/analisar sintático/etc. Ele pode
ser um delegador e/ou orquestrador.

Um exemplo de fachada que se usa no mundo Java? Usar Spring Boot para gerenciar
os end-points HTTP. O Spring Boot está criando a fachada para que se chegue uma
requisição HTTP pelo código cliente e ele saiba como direcionar para a função
correta.

Vamos fazer uma fachada bobinha? Para um sistema de cache, vamos fornecer um ID
e retornar o objeto. Temos um cache local, um cache no Redis (abstraído já em
uma função adequada) e finalmente no banco de dados. Vamos procurar?

```ts
// as variáveis não estão exportadas
let proximaInsercao = 0;
const sizeMemoria = 30
const memoriaCurta: ([string, CoisaComplexa]|null)[] = inicia(sizeMemoria)

// inicia: procedimento para iniciar a memória de curto prazo
// fornecido por fora

// não preciso expor isso
function buscaMemoriaCurta(id: string): CoisaComplexa|null {
    for (const e of memoriaCurta) {
        if (e == null) {
            continue
        }
        const [idEl, el] = e
        if (idEl == id) {
            return el
        }
    }
    return null
}

// nem preciso expor isso
function insereMemoria(id: string, el: CoisaComplexa) {
    memoriaCurta[proximaInsercao] = [id, el]
    proximaInsercao += 1
    if (proximaInsercao >= sizeMemoria) {
        proximaInsercao = 0
    }
}

// exporto isso
// buscaRedis e buscaBanco são funções importadas na fachada
function fachadaDeAcesso(id: string): CoisaComplexa|null {
    const pelaMemoriaCurta = buscaMemoriaCurta(id)
    if (pelaMemoriaCurta != null) {
        return pelaMemoriaCurta
    }
    const peloRedis = buscaRedis(id)
    if (peloRedis != null) {
        return peloRedis
    }
    return buscaBanco(id)
}

// e exporto isso
// insereBanco e insereRedis são funções importadas na fachada
function fachadaDeEscrita(id: string, el: CoisaComplexa) {
    insereBanco(id, el)
    insereRedis(id, el)
    insereMemoria(id, el)
}
```

## Flyweight

> Usar compartilhamento para suportar eficientemente grandes quantidades de
> objetos de granularidade fina.

Vamos imaginar a seguinte situação: estamos em um joguinho, e precisamos
carregar a imagem de um inimigo. Um Koopa Troopa. Essa imagem é dada através de
uma sprite, sprite essa que está em um arquivo.

Pra uma fase que tem vários Koopa Troopas, o jeito, digamos, mais naïve de se
implementar seria fazer uma carga de sprite por Koopa Troopa. Isso significa
que eu gastaria mais tempo de carregamento de disco (potencialmente otimizado
por rotinas de cache de leitura do sistema operacional), mais processamento
para fazer a carga e mais memória pois cada inimigo ocuparia um espaço de
memória com sua sprite.

Mas, os sprites são os mesmos, não são? Então por que não carregar o mesmo
sprite no lugar de ficar fazendo esforço desnecessário? Posso identificar pelo
nome do arquivo e tratar o carregamento dessa forma:

```ts
// função privada
function loadSprite(path: string): Sprite | null {
    // ...
}

type PlaceholderType = {}
const placeholder: PlaceholderType = {}
const cache: Record<string, Sprite | PlaceholderType> = {}

function isPlaceholder(o: Sprite | PlaceholderType | null): o is PlaceholderType {
    return o === placeholder
}

// função exportada
function getSprite(path: string): Sprite | null {
    const prev = cache[path]
    if (isPlaceholder(prev)) {
        return null
    }
    if (prev) {
        return prev
    }
    const created = loadSprite(path)
    cache[path] = created != null? created : placeholder
    return created
}
```

Com isso, posso colocar todos os sprites para pegar da mesma fonte. Além desse
uso, tem outras coisinhas que posso aplicar com flyweight: por exemplo, Koopas
vermelhos são apenas Koopas verdes que mudou a palheta de cores da sprite. A
priori a palheta de cores está no carregamento da sprite, mas também é possível
indicar que, naquele instante, a renderização do sprite vai ser feito com uma
decoração da palheta, no lugar de pegar a palheta direta do sprite.

Na hora de renderizar, é importante que cada elemento do jogo tenha um "estado
de animação", pois assim eles podem usar o mesmo sprite cortanto "frames"
distintos justamente para poder emular animações na pixel art. Então no final
eu teria algo assim:

```ts
type VisualElement = {
    coord: Coord,
    graphic: Graphic,
    state: number
}

type Graphic = Sprite | ColorSwappedSprite

type ColorSwappedSprite = {
    baseSprite: Sprite,
    pallete: Pallete
}

...
```

Tal qual os sprites foram cacheados em termos de path para o arquivo, os
inimigos com color swap eu posso pegar de outra facotry com cache que pega não
só o sprite base, como também aplica a palheta passada.

Note que apesar de que o desenho final necessite saber qual a posição do
elemento visual, o desenho do sprite em si é bem dizer o mesmo, no máximo com a
palheta de cores trocadas. E para desenhar é necessário o estado do sprite para
pegar o quadro certo para renderizar.

No GoF ele fala de "estado intrínseco" e "estado extrínseco", usando como
exemplo fonte tipográfica. Uma fonte Times 12 vai ser sempre uma fonte Times
12, não importa a posição do texto. A posição portanto se torna algo extrínseco
às propriedades usadas no desenho da fonte, assim como aqui no caso do sprite,
tanto o estado quanto as coordenadas (x,y) são propriedades não inerentes ao
sprite em si, mas que pertencem ao ato de renderizar.

Um outro exemplo para flyweight? Que tal... prepared statements? Podemos manter
na mesma conexão do banco de dados um conjunto de statements preparadas, de
modo que, ao chegar uma nova requisição de preparar uma statement, se por acaso
for referente a uma query que já foi preparada antes, podemos reusar a
statement! Isso vai evitar uma _round trip_ nova para o banco de dados para
fazer novamente o mesmo trabalho.

Aqui, o flyweight é um pouco mais do que uma função apenas:

- precisa da função de entrada
- precisa de uma memória
- precisa de uma factory

A memória é um chaveamento condições de valores para o elemento em si. A única
coisa necessária expor para o código que consome o flyweight é a função de
entrada, a factory e a memória podem ser internalizadas.

## Proxy

> Fornecer um substituo (_surrogate_) ou marcador da localização de outro
> objeto para controlar o acesso ao mesmo.

Já usamos proxy pelo menos duas vezes aqui no Computaria:

- [O que é o hikari pool?]({% post_url 2024-12-27-o-que-e-hikari-pool %})
- [Conheça-te a ti mesmo! Reflexão e meta-programação em Java]({% post_url 2025-01-10-java-mirror-mirror-on-the-wall %})

No caso do post sobre reflexão em Java foi abordado o tema de proxy de maneira
bem ampla e dado alguns exemplos. No Hikari Connection Pool? Bem, nesse caso
aqui as conexões obtidas eram proxies, pois o objeto retornado por
`hikariDataSource.getConnection()` retornava uma conexão que estava disponível
no pool, removendo-a de lá. Toda interação com essa conexão obtida é repassada
para a conexão real, exceto uma: o `.close()`. Nesse caso, a conexão era
"magicamente" reposta no pool de conexões. O objeto de `HikariConnection` é um
proxy.

Sabe outro exemplo de proxy que mencionamos aqui mesmo neste post? Logo atrás?
Na seção anterior? Um cache de prepared statements dentro de uma conexão com o
banco! Aqui, temos todas as características para o flyweight e também o proxy
no meio do caminho:

- a conexão que o código interage envelopa a conexão de verdade; portanto é uma
  conexão proxy
- a conexão recebe uma string com a query
- a conexão proxy mantém uma **memória** chaveando as queries às suas
  respectivas prepared statements
- ela tem uma **factory** de prepared statement (só passar a query para a conexão
  de baixo)
- ela tem a **função de entrada** (a função da conexão proxy)

No GoF ele cita alguns tipos de proxy, mas achei a lista do Refactoring Guru
mais completa (e não é exaustiva!). Leia mais em
[Proxy no Refactoring Guru](https://refactoring.guru/design-patterns/proxy):

- virtual proxy (aqui no contexto de instanciar lazily)
- proxy de proteção
- proxy remoto (voltado pra RPC)
- proxy de logging
- proxy de cache
- smart reference

No caso do Hikari, o proxy é usado para smart reference. No exemplo de
statements preparadas, foi um caso de proxy de cache.

Proxy de proteção, de logging, de cache poodem ser implementados tais quais
decorators, em que você adiciona comportamentos adicionais em uma função.
Inclusive, como o Refatoring Guru fala, proxies e decorators tem bastante coisa
em comum.

Para smart pointers, você necessita de um pool ou de uma factory.

O proxy de lazy loading oferece uma coisa diferente. Ele permite que você não
instancie o objeto a priori, só sob demanda. Mas mesmo assim você consegue usar
e posicionar o objeto de proxy. Por exemplo, não preciso instanciar uma imagem
a partir do arquivo PNG para saber o tamanho dela. Eu posso colocar em um proxy
de lazy loading para perguntar qual o tamanho da imagem (imagem passada como
um path do PNG) e isso permite que eu pergunte a altura de um documento (por
exemplo) sem precisar de fato instanciar a imagem dentro dele. Eu posso
inclusive determinar quantas páginas a renderização em PDF vai ter sem precisar
de nada real.

E se a imagem for usada em múltiplos pontos, posso usar flyweight para retornar
a referência do proxy no lugar de instanciar o objeto real.

Como o mecanismo de proxy de caching/de logging/diversos outros é o mesmo do
decorator, não vou exemplificar. Mas e para o lazy loading?

```ts
type BitMap = ...

type Image = {
    height: () => number,
    bmp: () => BitMap
}

function createImageFromPath(arg: string): Image {
    return ...
}

function getHeightFromPath(arg: string): number {
    return ...
}

type Lazy<T> = {
    get: () => T
}

function cacheFunction<I, T>(input: I, factory: (i: I) => T): Lazy<T> & { loaded: boolean } {
    let value: T | null = null
    let loaded = false
    const get = () => {
        if (!value) {
            value = factory(input)
            loaded = true
        }
        return value
    }
    return {
        get,
        loaded
    }
}

function lazyImageProxy(path: string): Image {
    const cache = cacheFunction(path, createImageFromPath)
    const height = cacheFunction(cache, (t: Lazy<Image> & { loaded: boolean }) => {
        if (t.loaded) {
            return t.get().height()
        }
        return getHeightFromPath(path)
    })
    return {
        height: () => height.get(),
        bmp : () => cache.get().bmp()
    }
}
```

Vamos destrinchar? Eu tenho uma função para o lazy loading de imagem, o
`lazyImageProxy`. Ele tem acesso ao tamanho da imagem através do `height`, e ao
bitmap carregando à imagem.

O `height`, por sua vez, é um objeto que ainda não foi carregado. Ele depende
do `cache`, e pergunta ao cache se ele já foi carregado ou não. Em já tendo
sido carregado, já era, a imagem já está formada posso pegar dela mesmo o
valor. Agora, caso ela não esteja formada, pega através do caminho usando
`getHeightFromPath`.

E note que o próprio `height` ele é lazy e também guarda valor cacheado, então
ao ser computado pela primeira vez, ele não precisa ser computado novamente.

Todos esses caches só funcionam por conta da função `cacheFunction`, que
retorna um objeto do tipo `Lazy<T> & { loaded: boolean }`. Isso quer dizer que
o objeto atende tanto ao requisito de ser `Lazy<T>` como também em ter um campo
booleano chamado `loaded`. Ele é um tipo de interseção: precisa atender às duas
tipagens. E ele controla tudo colocando a função de carga (chamada de `get`) e
o objeto `loaded` dentro de sua clausura.

Finalmente, a interface `Lazy<T>` só diz que ela tem uma função chamada `get`
que, ao ser chamada, retorna um objeto do tipo `T`. Portanto, o `cacheFunction`
pode muito bem implementar ela de modo que aproveite o resultado anterior. Isso
é dado assim:

```ts
// params input: I, factory: (i: I) => T
let value: T | null = null
const get = () => {
    if (!value) {
        value = factory(input)
    }
    return value
}

return {
    get
}
```

Mas `cacheFunction` retorna a interseção de `Lazy<T>` com
`{ loaded: boolean }`. Mas por quê? Porque é útil saber se o objeto está
carregado. Por exemplo, no caso do tamanho da imagem, isso foi usado para
saber se faz uma leitura de disco específica para esse fim ou se utiliza o que
já vem da imagem. Por isso que foi colocado o `loaded`, para identificar isso e
para poder adaptar o comportamento:

```ts
// params input: I, factory: (i: I) => T
let value: T | null = null
let loaded = false
const get = () => {
    if (!value) {
        value = factory(input)
        loaded = true
    }
    return value
}

return {
    get,
    loaded
}
```

# Padrões comportamentais

Parafraseando do livro:

> Os padrões comportamentais se preocupam com algoritmos e a atribuição de
> responsabilidades entre objetos. Os padrões comportamentais não descrevem
> apenas padrões de objetos ou classes, mas também os padrões de comunicação
> entre eles.

Então, pelo que espero aqui, as funções ficam cada vez mais claras. Talvez
algum malabarismo de tipo, mas mais fortemente creio que vamos ver mais e mais
funções.

## Chain of responsability

> Evitar o acoplamento do remetente de uma solicitação ao seu receptor [...]
> passando a solicitação ao longo da cadeia até que um objeto a trate.

Mais uma vez, o exemplo motivador do GoF é o de uma aplicação gráfica. Isso
também foi implementado no DOM: sair borbulhando o evento, até que alguém o
trate.

Então, como implementamos a cadeia de responsabilidade?

Basicamente, temos uma `Chain` que trata elementos do tipo `T`:

```ts
type Handler<T> = (e: T) => void;
type EndOfChain<T> = Handler<T>;

type Link<T> = {
    shouldHandle : (e: T) => boolean,
    handler: Handler<T>
}

type Chain<T> = {
    link: Link<T>,
    nextLink: Chain<T> | EndOfChain<T>
}
```

E então cada elo é adicionado no começo da corrente. Então, nesse esquema, como
ficaria uma implementação? Primeiro, precisamos delimitar quando o `nextLink`
vai ser um `Chain` ou um `EndOfChain`. Enquando for `chain`, testa para ver se
é possível lidar, e se for possível lida e termina a execução.

`EndOfChain` é o caso em que não há ninguém que faça o tratamento. Existem
outras maneiras de expressar, como por exemplo o elo nulo (que aí deixaria
escapar), ou então um elo final especial que é garantido
`shouldHandle(any) => true`. O jeito mais fácil de garantir é tornar o
`EndOfChain` um elemento especial que vai tratar o elemento:

```ts
function isChain<T>(nextLink: Chain<T> | EndOfChain<T>): nextLink is Chain<T> {
    return (nextLink as any)['link'] && (nextLink as any)['nextLink'] != null
}

function bubbleEvent<T>(event: T, chain: Chain<T>) {
    let current: Chain<T> | EndOfChain<T> = chain
    while (isChain(current)) {
        const link = current.link
        if (link.shouldHandle(event)) {
            link.handler(event)
            return
        }
        current = current.nextLink
    }

    current(event)
}
```

Mas, como seria usado isso? Por exemplo, ao colocar um componente de tela que
precisa borbulhar, por exemplo, um comando de alteração de um carrinho de
compras?

A priori a ação é informar que não deu certo tomar a ação. Mas poderia ser um
drop da ação silencioso. Então temos o nosso `EndOfChain`:

```ts
const droparAction: EndOfChain<Action> = (a: Action) => {}
const logarAction: EndOfChain<Action> = (a: Action) => console.log(`ignorando ação ${a}`)
```

Então inserimos as regras de lidar com isso: passando uma condição, um handler
e o elo seguinte da sequência. Por exemplo, se a ação for "enviar orçamento" e
tiver um email, ele enviar o orçamento por email:

```ts
function addLinkToChain<T>(accepter: (t: T) => boolean, handler: Handler<T>, link: Chain<T> | EndOfChain<T>): Chain<T> {
    return {
        link: {
            shouldHandle: accepter,
            handler
        },
        nextLink: link
    }
}

function ehParaEnviarOrcamentoViaEmail(action: Action): boolean {
    return ...
}

function enviaOrcamentoViaEmail(action: Action) {
    ...
}

const base = logarAction;

const chain: Chain<Action> = addLinkToChain(ehParaEnviarOrcamentoViaEmail, enviaOrcamentoViaEmail, base);


const a: Action = ...
bubbleEvent(a, chain)
```

Aqui, ao inserir o componente de enviar orçamento via email, precisamos agora
apenas manter a cadeia e pronto.

Mas, se eu tenho a cadeia e preciso passar ela para cima... será que eu não
poderia, no lugar de borbulhar via vários níveis de uma lista encadeada, só
fazer um find/fire?

Ainda com o pensamento do `Link`, poderia até aproveitar a interface dele: um
elo na corrente é algo que pode lidar com aquilo. Assim, posso simplesmente
passar a corrente e a lida padrão. Então bastaria passar a lista de elos, a
tratativa padrão e a ação, né? Algo assim:

```ts
function handle<T>(chain: Link<T>[], defaultHandler: EndOfChain<T>, t: T) {
    ...
}
```

Sabendo quem vou ter, basta agir agora. Vamos pegar o link adequado? É o
primeiro que conseguir lidar com o objeto:

```ts
const link: Link<T> | undefined = chain.find(l => l.shouldHandle(t))
```

Ok, agora eu precido do `handler` dele:

```ts
const handler: Handler<T> | undefined = chain.find(l => l.shouldHandle(t))?.handler
```

Só lidar com o caso de não encontrar:

```ts
const handler: Handler<T> = chain.find(l => l.shouldHandle(t))?.handler ?? defaultHandler
```

Juntando tudo:

```ts
function handle<T>(chain: Link<T>[], defaultHandler: EndOfChain<T>, t: T) {
    (chain.find(l => l.shouldHandle(t))?.handler ?? defaultHandler)(t)
}
```

Isso lida com o uso da corrente, mas e a criação? Basicamente é uma função que
pega `Link<T>[], Handler<T>, (t:T) => boolean` e concatena em um único array de
`Link<T>`. Algo como:

```ts
function adicionaElo<T>(accepter: (t: T) => boolean, handler: Handler<T>, chain: Link<T>[]): Link<T>[] {
    return [ {
        shouldHandle: accepter,
        handler
    }, ...chain]
}
```

E, para usar, só precisa passar o componente da corrente de responsabilidade
para cima.

## Command

> Encapsular uma solicitação como um objeto, desta forma permitindo
> parametrizar clientes com diferentes solicitações, enfileirar ou fazer o
> registro (log) de solicitações e suportar operaçòes que podem ser desfeitas.

Basicamente, o padrão de projeto _command_ é mandar uma mensagem de comando
"pelo fio". Um tipo e um interpretador. No caso, como no GoF o pensamento era
voltado ainda muito a efeitos colaterais (vide a questão de economia de
memória, preocupação muito comum e pertinente na época), o próprio objeto que
será alterado é o interpretador do comando, alterando seu estado interno.

Mas aqui a ideia maior é que o command é aplicado para alterar um objeto.
Especificamente:

```ts
type CommandHandler<T> = (t: T, c: Command) => T
```

Se quiser tratativa de erro no command (por exemplo, se o estado que o objeto
novo assumir for irreconciliavelmente), podemos retornar uma tagged union com o
sucesso/erro:

```ts
type CommandHandler<T, E> = (t: T, c: Command) => { success: T } | { error: E }
```

"Ah, e o desfazer?" Bem, mudamos o estado e podemos guardar o estado anterior.
Nenhum problema nisso. Daí só restaurar.

Para um exemplo? Vamos pegar um pedido, que tem itens. O comando é "aumentar a
quantidade do item #3 em 2 unidades".

Primeiro, as coisas básicas: os objetos que serão alterados pelo comando:

```ts
type Pedido = {
    valor: number, // valor total do pedido
    itens : Item[]
}

type Item = {
    produto: Produto,
    valorUnitario: number,
    quantidade: number
}
```

Ok, e o comando? O comando bem dizer pega a posição do item (totalmente
arbitrário, poderia ser outra coisa) e o quanto vai aumentar. Como é um comando
com potencialmente diversos outros, vamos desenhar ele pronto para estar em uma
tagged-union através do campo `command`:

```ts
type Command = {
    command: string
}

type AlteraQuantidadeItemCommand = {
    command: "AlteraQuantidadeItem",
    item: number, // posição do item
    delta: number // variação da quantidade do item
}
```

Tem coisa que pode dar errado com esse comando? Sim! Duas, na verdade:

- o item não existir (por exemplo, alterar o 10º item de 3)
- passar um delta não positivo

Para criar o comando "aumentar a quantidade do item #3 em 2 unidades":

```ts
const comando: AlteraQuantidadeItemCommand = {
    command: "AlteraQuantidadeItem",
    item: 3,
    delta: 2
}
```

Como seria para lidar com esse comando?

```ts
type CommandReturn = {
    success: Pedido
} | {
    error: string
}

function handleAlteraQuantidadeItem(pedido: Pedido, command: AlteraQuantidadeItemCommand): CommandReturn {
    return ...
}

function alteraPedido(pedido: Pedido, command: Command): CommandReturn {
    switch (command.command) {
        case "AlteraQuantidadeItem": {
            return handleAlteraQuantidadeItem(pedido, command as AlteraQuantidadeItemCommand);
        }
    }

    return {
        error: `comando não reconhecido ${command.command}`
    }
}
```

Precisava criar a função `handleAlteraQuantidadeItem`? Não, poderia resolver em
`alteraPedido` mesmo. Mas o pattern-matching deixou claro, pelo menos para mim,
que isso seria uma boa estratégia: faz a multiplexação para saber qual
interpretador de comando chamar e invocar o interpretador de comando.

Enfim, e a implementação de como lidar com essa alteração de quantidade? Vamos
primeiro desconsiderar erros:

```ts
function handleAlteraQuantidadeItem(pedido: Pedido, command: AlteraQuantidadeItemCommand): CommandReturn {
    const {
        item,
        delta
    } = command

    const itens = [ ...pedido.itens ]

    const itemAntigo = itens[item]
    const itemNovo: Item = {
        ...itemAntigo,
        quantidade: itemAntigo.quantidade + delta
    }

    itens[item] = itemNovo
    const valor = pedido.valor + delta*itemAntigo.valorUnitario
    return { success: { valor, itens } }
}
```

Aqui estou favorecendo não alterar o objeto que veio de fora, tentando deixar o
mais imutável possível. Abri mão levemente ali no `itens[item] = itemNovo`
porque é mais prático.

O `itemNovo` eu crio com base no `itemAntigo` (lembra do padrão prototype?),
mas aqui eu altero a quantidade:

```ts
const itemNovo = {
    ...itemAntigo, // usando o itemAntigo como protótipo
    quantidade: itemAntigo.quantidade + delta
}
```

Declarei que `const itemNovo: Item` por dois motivos:

1. garantir que eu estou escrevendo de fato o tipo correto
2. habilitar o intelissense do VSCode descobrir que tem o campo `quantidade`

Fora isso, eu apenas calculei o valor do pedido novo.

Mas, e inserir os casos de erro? Bem simples, na real:

```ts
function handleAlteraQuantidadeItem(pedido: Pedido, command: AlteraQuantidadeItemCommand): CommandReturn {
    const {
        item,
        delta
    } = command

    const itens = [ ...pedido.itens ]

    if (item >= itens.length) {
        return { error: `item ${item} inexistente` }
    }
    if (delta <= 0) {
        return { error: `delta ${delta} inválido` }
    }

    const itemAntigo = itens[item]
    const itemNovo: Item = {
        ...itemAntigo,
        quantidade: itemAntigo.quantidade + delta
    }

    itens[item] = itemNovo
    const valor = pedido.valor + delta*itemAntigo.valorUnitario
    return { success: { valor, itens } }
}
```

Hmmm, é só isso o command?

Sim, é só isso. Vou colocar o exemplo com o comando de adicionar um item além
do alterar a quantidade:

```ts
type Command = {
    command: string
}

type AlteraQuantidadeItemCommand = {
    command: "AlteraQuantidadeItem",
    item: number, // posição do item
    delta: number // variação da quantidade do item
}

type InserirItemCommand = {
    command: "InserirItem",
    produto: Produto,
    valorUnitario: number,
    quantidade: number
}

const altera: AlteraQuantidadeItemCommand = {
    command: "AlteraQuantidadeItem",
    item: 3,
    delta: 2
}

type Produto = string // apenas para exemplificar

type Pedido = {
    valor: number, // valor total do pedido
    itens : Item[]
}

type Item = {
    produto: Produto,
    valorUnitario: number,
    quantidade: number
}

type CommandReturn = {
    success: Pedido
} | {
    error: string
}

function handleAlteraQuantidadeItem(pedido: Pedido, command: AlteraQuantidadeItemCommand): CommandReturn {
    const {
        item,
        delta
    } = command

    const itens = [ ...pedido.itens ]

    if (item >= itens.length) {
        return { error: `item ${item} inexistente` }
    }
    if (delta <= 0) {
        return { error: `delta ${delta} inválido` }
    }

    const itemAntigo = itens[item]
    const itemNovo: Item = {
        ...itemAntigo,
        quantidade: itemAntigo.quantidade + delta
    }

    itens[item] = itemNovo
    const valor = pedido.valor + delta*itemAntigo.valorUnitario
    return { success: { valor, itens } }
}

function handleInserirItem(pedido: Pedido, command: InserirItemCommand): CommandReturn {
    const {
        produto, valorUnitario, quantidade
    } = command

    if (valorUnitario <= 0) {
        return {
            error: "valor unitário precisa ser positivo"
        }
    }
    if (quantidade <= 0) {
        return {
            error: "quantidade precisa ser positiva"
        }
    }
    const item: Item = {
        produto,
        valorUnitario,
        quantidade
    }
    return {
        success: {
            valor: pedido.valor + (valorUnitario * quantidade),
            itens: [
                ...pedido.itens,
                item
            ]
        }
    }
}

function alteraPedido(pedido: Pedido, command: Command): CommandReturn {
    switch (command.command) {
        case "AlteraQuantidadeItem": {
            return handleAlteraQuantidadeItem(pedido, command as AlteraQuantidadeItemCommand);
        }
        case "InserirItem": {
            return handleInserirItem(pedido, command as InserirItemCommand);
        }
    }

    return {
        error: `comando não reconhecido ${command.command}`
    }
}

let pedido: Pedido = {
    valor: 0,
    itens: []
}

const inserirItem1 : InserirItemCommand = {
    command: "InserirItem",
    produto: "coca cola lata",
    valorUnitario: 4.00,
    quantidade: 2
}

const inserirItem2 : InserirItemCommand = {
    command: "InserirItem",
    produto: "brigadeiro",
    valorUnitario: 1.00,
    quantidade: 1
}

const inserirItem3 : InserirItemCommand = {
    command: "InserirItem",
    produto: "salgado",
    valorUnitario: 9.00,
    quantidade: 1
}

const inserirItem4 : InserirItemCommand = {
    command: "InserirItem",
    produto: "café",
    valorUnitario: 3.00,
    quantidade: 1
}


let maybePedido = alteraPedido(pedido, inserirItem1);
pedido = (maybePedido as { success: Pedido }).success

maybePedido = alteraPedido(pedido, inserirItem2);
pedido = (maybePedido as { success: Pedido }).success

maybePedido = alteraPedido(pedido, inserirItem3);
pedido = (maybePedido as { success: Pedido }).success

maybePedido = alteraPedido(pedido, inserirItem4);
pedido = (maybePedido as { success: Pedido }).success

console.log(pedido)

maybePedido = alteraPedido(pedido, altera);
console.log(maybePedido)

pedido = (maybePedido as { success: Pedido }).success
console.log(pedido)

maybePedido = alteraPedido(pedido, { ...altera, item: 15} as AlteraQuantidadeItemCommand); // erro por item inexistente
console.log(maybePedido)

maybePedido = alteraPedido(pedido, { ...altera, delta: -1} as AlteraQuantidadeItemCommand); // erro por quantidade negativa
console.log(maybePedido)

maybePedido = alteraPedido(pedido, { command: "marmota" });
console.log(maybePedido)
```

Restaurar o estado anterior é basicamente falando só manter o histórico dos
objetos na mão.

"Ah, mas isso não é o padrão COMMAND do jeito que tá no Gof!"

Sim, de fato não é exato. É uma versão simplificado e que, aqui, assumi que era
tranquilo manipular o objeto daquela maneira. Normalmente faz sentido. Se fosse
um active record? Bem, aí active record da vida é outro conceito, orientado a
efeitos colaterais. Aqui não necessitei dos efeitos colaterais.

Aqui, diferente do GoF, o comando em si foi separado em 3 partes:

- o objeto com a intenção da alteração (e posíveis argumentos)
- a função que lida com o polimorfismo dos comandos
- a função que executa a intenção da alteração

No GoF, o objeto e a função que lida com a alteração eram intrínsecos um no
outro, indissociáveis. Devido a isso, o próprio polimorfismo das funções
virtuais lidavam com a questão da escolha da função, juntando tudo em uma coisa
só. Como eu já tive experiência de necessitar enviar commands _over the wire_,
preferi essa abordagem que não força a serialização da função.

Outro ponto de distinção é que no GoF o objeto a ser alterado já está contido
no command, enquanto que eu descrevi isso através da chamada de função,
passando o objeto sujeito aos comandos e o comando em si. Isso implicou, por
exemplo, que quando a alteração não é diretamente no objeto em si, mas sim em
algum nível mais interno, que se faça a busca pelo objeto sujeito da
manipulação. Com isso, preciso passar nos argumentos do meu objeto de command
as coordenadas para buscar tal elemento.

## Interpreter

> Dada uma linguagem, definir uma representação para a sua gramática juntamente
> com um interpretador que usa representação para interpretar sentenças da
> linguagem.

Basicamente a função `eval` do Lisp, mas para uma linguagem arbitrária e não
somente Lisp.

O GoF determina que é, bem dizer, montar a árvore de sintaxe e depois descer
ela usando um visitor (padrão a ser definido a frente). Na real o GoF tenta se
esquivar das árvores de sintaxe, mas na prática é isso (elemento raiz, elemento
não terminal, elemento folha).

Além das questões do visitor e da árvore de sintaxe, tem também um contexto que
ficam informações sobre a interpretação.

Tal qual foi no command, o interpreter aqui na definição do GoF tem, para cada
nó da árvore ele tem um método chamado `Execute`, que por sua vez o próprio nó
é o visitor.

Uma coisa que ele não cita no GoF é a capacidade de fazer a árvore via DSL.
Tomando como exemplo o Builder ali de cima, em que fizemos uma árvore de
expressões numéricas em cima de operadores binários.

Vamos definir uma pequena linguagem interpretada? Essa linguagem tem variáveis
booleanas, variáveis de funções unárias, constantes `true` e `false`, um jeito
de definir input em variáveis, e clausuras. As funções vão retornar ou
booleanos ou funções unárias. Claro que, além de setar os valores das
variáveis, posso ler eles. E também teria branches.

Vamos focar aqui no mínimo para a linguagem? A função "XOR". Vou fazer via
retorno de funções de acordo com o primeiro argumento, e outra que passa o
argumento via clausura.

Como seria essa linguagem? Vamos ver um exemplo:

```js
let xorClojure := (a) => (b) => {
    if (a) {
        return !b
    } else {
        return b
    }
}
let xorBranching := (a) => {
    if (a) {
        return (b) => !b
    } else {
        return (b) => b
    }
}

let fromClosure := xorClosure(true)(false)
let fromBranching := xorBranching(true)(false)
```

Os específicos de como fazer a tokenização dessa linguagem, ou o parsing dela,
não interessa. Vamos pegar apenas a nível de estrutura sintática e fazer o
interpretador baseado nesses nós!

Antes de entrar nos detalhes, vamos ver uma possível árvore para a última
linha do exemplo: `let fromBranching := xorBranching(true)(false)`.

Primeiro: temos um `let`. Essa expressão precisa de um nome. Vamos fazer com
que `let var := value` seja um syntax sugar para `let var; var := value`?
Assim, para a gente expressar logo o começo dessa expressão, precisamos já
declarar dois elementos sintáticos: o `let` e o `attr`.

Então, bora lá, como seria a criação desses objetos?

```ts
const program: BoolNode[] = []
program.push(nodeLet("fromBranching"))
program.push(nodeAttr("fromBranching").value(...))
```

Hmmm, parece bacana. agora precisamos lidar com a questão de chamada de função,
mas pra isso precisamos também resgatar o valor da função (como se fosse uma
variável):

```ts
const program: BoolNode[] = []
program.push(nodeLet("fromBranching"))

const callXorBranching: BoolNodeValue = nodeVar("xorBranching")
                                           .call(nodeValue(true))
                                           .call(nodeValue(false))
program.push(nodeAttr("fromBranching").value(callXorBranching))
```

Aproveitei também e coloquei o valor de uma constante: `nodeValue`. Essa a DSL,
mas como seria a estrutura gramatical que isso representa?

Bem, o `call` na real tem do lado esquerdo um valor (que é esperado que o
retorno seja uma função) e do lado direito um valor. A representação seria mais
ou menos isso:

```js
[
    {
        nodetype: "let",
        name: "fromBranching"
    },
    {
        nodetype: "attr",
        name: "fromBranching",
        value: {
            nodetype: "call",
            function: {
                nodetype: "call",
                function: {
                    nodetype: "var",
                    name: "xorBranching"
                },
                param:{
                    nodetype: "value",
                    value: {
                        kind: "boolean",
                        value: true
                    }
                }
            },
            param: {
                nodetype: "value",
                value: {
                    kind: "boolean",
                    value: false
                }
            }
        }
    }
]
```

Muito bem. E a definição de função? Vamos fazer aqui para o `xorBranching`:

```js
let xorBranching := (a) => {
    if (a) {
        return (b) => !b;
    } else {
        return (b) => b;
    }
}
```

Temos aqui a definição de `let` seguido de atribuição. Então o valor passa a
ser uma função. A função tem uma variável como argumento, usada para ser
mencionada abaixo. Vamos dar um nome a esse argumento, por simplicidade.
Então, ela passa a ter um conjunto de nós. Aqui temos o `if` para permitir
branching e também o `return`, o que causa o fim prematuro da função. Note que
aqui o retorno é uma função anônima, e que essa função não faz uso de captura
de variáveis locais. A clausura dela é vazia.

Como seria isso expreso na DSL?

```ts
const program: BoolNode[] = []
program.push(nodeLet("xorBranching"))

const xorBranchingFunction = nodeFunction("a")
                                .execution([
                                    nodeIf(nodeVar("a"))
                                        .ifBranch(
                                            nodeReturn(
                                                nodeFunction("b")
                                                    .execution([
                                                        nodeReturn(
                                                            nodeNot(nodeVar("b"))
                                                        )
                                                    ])
                                            )
                                        )
                                        .elseBranch(
                                            nodeReturn(
                                                nodeFunction("b")
                                                    .execution([
                                                        nodeReturn(
                                                            nodeVar("b")
                                                        )
                                                    ])
                                            )
                                        )
                                ])
program.push(nodeAttr("xorBranching", xorBranchingFunction))
```

Aqui o `nodeFunction` recebe como parâmetro o nome do argumento, e então vem o
código com a execução da função. A função retorna de modo explícito, então
precisa de um `nodeReturn` com o valor. Note que os primeiros retornos são
funções anônimas, portanto eles retornam `nodeFunction`.

Finalmente, temos uma chamada de `nodeIf`, passando a condicional (o resultado
da variável `a`), o `ifBranch` para informar o caso de a condição ser
satisfeita e `elseBranch` com o caso contrário. Neles temos os `nodeReturn`,
que retornam a função anônima.

O total fica assim:

```ts
const program: BoolNode[] = []
program.push(nodeLet("xorBranching"))

const xorBranchingFunction = nodeFunction("a")
                                .execution([
                                    nodeIf(nodeVar("a"))
                                        .ifBranch(
                                            nodeReturn(
                                                nodeFunction("b")
                                                    .execution([
                                                        nodeReturn(
                                                            nodeNot(nodeVar("b"))
                                                        )
                                                    ])
                                            )
                                        )
                                        .elseBranch(
                                            nodeReturn(
                                                nodeFunction("b")
                                                    .execution([
                                                        nodeReturn(
                                                            nodeVar("b")
                                                        )
                                                    ])
                                            )
                                        )
                                ])
program.push(nodeAttr("xorBranching", xorBranchingFunction))
program.push(nodeLet("fromBranching"))

const callXorBranching: BoolNodeValue = nodeVar("xorBranching")
                                           .call(nodeValue(true))
                                           .call(nodeValue(false))
program.push(nodeAttr("fromBranching").value(callXorBranching))
```

E o `xorClosure`? Bem, podemos adicionar coisas na clausura com um
`nodeWithClosure(... nome das variáveis)` e sair passando ela para baixo. Em
seguida dentro da clausura precisa de uma declaração de função, essa função vai
ter como clausura aquilo que foi declarado. Vamos ver como que fica?

```ts
const program: BoolNode[] = []
program.push(nodeLet("xorClosure"))

const xorClosureFunction = nodeFunction("a")
                                       .execution([
                                        nodeReturn(
                                            nodeWithClosure("a")
                                                    .nodeFunction("b")
                                                            .execution([
                                                                nodeIf(nodeVar("a"))
                                                                        .ifBranch(
                                                                            nodeReturn(nodeNot(nodeVar("b")))
                                                                        )
                                                                        .elseBranch(
                                                                            nodeReturn(nodeVar("b"))
                                                                        )
                                                            ])
                                        )
                                       ])

program.push(nodeAttr("xorClosure", xorClosureFunction))
```

Tudo isso para gerar esses objetos:

```js
[
    {
        nodetype: "let",
        name: "xorClosure"
    },
    {
        nodetype: "attr",
        name: "xorClosure",
        value: {
            nodetype: "value"
            value: {
                kind: "function",
                arg: "a",
                execution: [
                    {
                        nodetype: "return",
                        value: {
                            nodetype: "capturing",
                            closure: [ "a" ],
                            function: {
                                kind: "lambda",
                                closure: [ "a" ],
                                arg: "b",
                                execution: [
                                    {
                                        nodetype: "if",
                                        condition: {
                                            nodetype: "var",
                                            name: "a"
                                        },
                                        ifBranch: [
                                            {
                                                nodetype: "return"
                                                value: {
                                                    nodetype: "not"
                                                    value: {
                                                        nodetype: "var",
                                                        name: "b"
                                                    }
                                                }
                                            }
                                        ],
                                        elseBranch: [
                                            {
                                                nodetype: "return"
                                                value: {
                                                    nodetype: "var",
                                                    name: "b"
                                                }
                                            }
                                        ]
                                    }
                                ]
                            }
                        }
                    }
                ]
            }
        }
    }
]
```

Muito bem, agora que temos desenhado o programa, onde que entra o padrão
interpreter? Na hora de fazer a computação desses valores!

Deixe os tipos guiarem até as funções, depois eu faço um artigo apenas para
esse interpretador. Por agora, fiquem com os tipos pensados para satisfazer a
linguagem:

```ts
type BoolNodeLet = {
    nodetype: "let",
    name: string
}

type BoolNodeAttr = {
    nodetype: "let",
    name: string,
    value: BoolNodeComputable
}

type BoolNodeValue = {
    nodetype: "value"
    value: BoolNodeBool | BoolNodeFunction
}

type BoolNodeBool = {
    kind: "boolean",
    value: true|false
}

type BoolNodeFunction = {
    kind: "function",
    arg: string,
    execution: BoolNode[]
}

type BoolNodeVar = {
    nodetype: "var",
    name: string
}

type BoolNodeNot = {
    nodetype: "not",
    value: BoolNodeComputable
}

type BoolNodeCall = {
    nodetype: "call",
    param: BoolNodeComputable,
    function: BoolNodeComputable
}

type BoolNodeAnd = {
    nodetype: "and",
    lhs: BoolNodeComputable,
    rhs: BoolNodeComputable
}

type BoolNodeOr = {
    nodetype: "or",
    lhs: BoolNodeComputable,
    rhs: BoolNodeComputable
}

type BoolNodeReturn = {
    nodetype: "return",
    value: BoolNodeComputable
}

type BoolNodeClosure = {
    nodetype: "capturing",
    closure: string[],
    function: {
        kind: "lambda",
        closure: string[],
        arg: string,
        execution: BoolNode[]
    }
}

type BoolNodeIf = {
    nodetype: "if",
    condition: BoolNodeComputable,
    ifBranch: BoolNode[],
    elseBranch: BoolNode[]
}

type BoolNodeComputable = BoolNodeValue | BoolNodeVar | BoolNodeNot |
                          BoolNodeCall | BoolNodeAnd | BoolNodeOr |
                          BoolNodeClosure

type BoolNode = BoolNodeLet | BoolNodeAttr | BoolNodeValue |
                BoolNodeVar | BoolNodeNot | BoolNodeCall |
                BoolNodeReturn | BoolNodeClosure | BoolNodeAnd |
                BoolNodeOr | BoolNodeIf
```

Aqui, `BoolNodeLet` cria uma variável, `BoolNodeAttr` escreve no valor da
variável, `BoolNodeValue` define constantes que podem ser substituídas na
execução, `BoolNodeVar` faz a leitura de uma variável que foi povoado (seja
essa variável do contexto de execução atual, da clausura, dos parâmetros).

No caso quando se encontra `BoolNodeClosure`, a transformação é mais sutil.
Antes de poder retornar esse valor, precisamos resolver ele. Pegando o caso
atual:

```js
{
    nodetype: "capturing",
    closure: [ "a" ],
    function: {
        kind: "lambda",
        closure: [ "a" ],
        arg: "b",
        execution: [
            {
                nodetype: "if",
                condition: {
                    nodetype: "var",
                    name: "a"
                },
                ifBranch: [
                    {
                        nodetype: "return"
                        value: {
                            nodetype: "not"
                            value: {
                                nodetype: "var",
                                name: "b"
                            }
                        }
                    }
                ],
                elseBranch: [
                    {
                        nodetype: "return"
                        value: {
                            nodetype: "var",
                            name: "b"
                        }
                    }
                ]
            }
        ]
    }
}
```

A variável `a` no final das contas ao chegar nesse momento tem o valor `CONST`
qualquer. Então, como sabemos o valor de `a`, "removemos" ele da lista de
coisas sendo capturadas e de coisas sendo esperadas na clausura, transformando
em uma espécie de `let` junto de `attr` na primeira linha da função:

```js
{
    nodetype: "capturing",
    closure: [ ],
    function: {
        kind: "lambda",
        closure: [ ],
        arg: "b",
        execution: [
            {
                nodetype: "let",
                name: "a"
            },
            {
                nodetype: "attr",
                name: "a",
                value: {
                    nodetype: "value",
                    kind: "boolean",
                    value: CONST
                }
            },
            {
                nodetype: "if",
                condition: {
                    nodetype: "var",
                    name: "a"
                },
                ifBranch: [
                    {
                        nodetype: "return"
                        value: {
                            nodetype: "not"
                            value: {
                                nodetype: "var",
                                name: "b"
                            }
                        }
                    }
                ],
                elseBranch: [
                    {
                        nodetype: "return"
                        value: {
                            nodetype: "var",
                            name: "b"
                        }
                    }
                ]
            }
        ]
    }
}
```

Agora que o `capturing` está com o `closure` vazio, só transformar em valor. E
note que agora não precisa mais ser um `lambda`, pode ser uma `function` comum.
E é assim que vamos implementar:

```js
{
    nodetype: "value",
    value:  {
        kind: "function",
        arg: "b",
        execution: [
            {
                nodetype: "let",
                name: "a"
            },
            {
                nodetype: "attr",
                name: "a",
                value: {
                    nodetype: "value",
                    kind: "boolean",
                    value: CONST
                }
            },
            {
                nodetype: "if",
                condition: {
                    nodetype: "var",
                    name: "a"
                },
                ifBranch: [
                    {
                        nodetype: "return"
                        value: {
                            nodetype: "not"
                            value: {
                                nodetype: "var",
                                name: "b"
                            }
                        }
                    }
                ],
                elseBranch: [
                    {
                        nodetype: "return"
                        value: {
                            nodetype: "var",
                            name: "b"
                        }
                    }
                ]
            }
        ]
    }
}
```

## Iterador

> Fornecer um meio de acessar, sequencialmente, os elementos de um objeto
> agregado sem expor a sua representação subjacente.

Isso aqui na prática era uma falta na linguagem. Agora, simplesmente temos em
muitas linguagens. Pedimos um iterador para um objeto e iteramos em cima.
Basicamente, precisa ter um algo que pegue o iterando atual e algo que pegue o
próxio para continuar processando.

Algo que satisfaça o seguinte:

```ts
// dado iterable como input
let iterator = pegaIterator(iterable)

while (iterator.hasValue) {
    const value = iterator.value
    iterator = iterator.next()

    // faz coisas com value
}
```

O `pegaIterator` é dependente de quem ele está tentando iterar, mas a ideia
básica é a seguinte (pegando como exemplo um vetor):

```ts
type IteratorType<T> = {
    value: T,
    hasValue: true
    next: () => IteratorType<T>
} | {
    hasValue: false
}

function pegaIterador<T>(colecao: T[]): IteratorType<T> {
    let i = 0
    let len = colecao.length

    const currentStep = (idx: number): IteratorType<T> => {
        if (idx == len) {
            return {
                hasValue: false
            }
        }
        return {
            hasValue: true,
            value: colecao[idx],
            next: () => currentStep(idx+1)
        }
    } 
    return currentStep(0)
}
```

Para a maioria dos casos, o próprio JS já fornece um jeito de iterar em uma
lista de modo escondido:

```js
for (const v of [1, 2, 3]) {
    console.log(v)
}
// imprime:
// 1
// 2
// 3
```

Para o padrão de projeto o próprio iterável deveria ter uma maneira de retornar
o seu iterador.

## Mediator

> Definir um objeto que encapsula a forma como um conjunto de objetos interage.
> O Mediator promove acoplamento fraco ao evitar que os objetos se refiram uns
> aos outros excplicitamente e permite variar suas interações
> independentemente.

Aqui, os objetos interagem com o mediator, que por sua vez repassa para outros
objetos em cena. As interações são entre os objetos de cena e a cena, e depois
da cena com os objetos de cena.

Sabe um canto bem comum de encontrar isso? Nos controllers! Quando você coloca
os componentes da camada de view, eles falam com o controller, mandando
eventos e recebendo eventos. O mediator em si não tem tanta relevância na visão
do padrão.

"Ah, mas no GoF ele fala que..."

Calma, gafanhoto, vem comigo. A função do mediator é receber eventos e
distribuir ações. E sabe como ele pode fazer isso? Acoplando no objeto algo que
será disparado na situação específica!

Por exemplo, podemos construir uma tela com um botão e, ao pressionar esse
botão, consultar um serviço remoto (pegando a URL de uma text box) e escrever o
resultado em uma área específica para isso!

Um jeito de permitir fazer isso é fazer com que cada um desses componentes
conheça o barramento, o que deixaria esses elementos conhecendo mais do que
deveria. Outra, entretanto, é dizendo que esses elementos tem eventos que podem
ser interceptados. Por exemplo, o botão tem o `onClick`. Eu posso fazer isso:

```js
btn.onClick = () => {
    const url = textBox.getText()
    const answer = await (await fetch(url)).text()
    answerArea.setInnerText(answer)
}
```

Quem adiciona essas questões? O mediator! Ele que determinou como que cada
evento vai desenrolar. O exemplo do mediator do GoF é baseado em um barramento
em que cada par evento/originador é disparado no mediator. O código acima
ficaria assim:

```js
const btn = ...
btn.publisher = mediator

btn.onClick = (event) => {
    if (!!mediator) {
        mediator.click(btn, event)
    }
}

mediator.click = (origin, event) => {
    if (origin === btn) {
        const url = textBox.getText()
        const answer = await (await fetch(url)).text()
        answerArea.setInnerText(answer)
        return
    }
}
```

## Memento

> Sem violar o encapsulamento, capturar e externalizar um estado interno de um
> objeto, de maneira que o objeto possa ser restaurado para este estado mais
> tarde.

Memento tira uma foto do estado do objeto. No padrão do GoF, ele não expõe
nada dos dados originais.

Basicamente o problema que o memento ataca existe por conta do acoplamento
dados/métodos com mutabilidade. Ele bem dizer para de existir quando temos
imutabilidade.

Mais pra frente, no padrão "State", temos uma espécie de "memento". A entidade
chamada `Breakpoint` é uma espécie de memento para um objeto do tipo
`Importacao`.

## Observer

> Definir uma dependência um-para-muitos entre objetos, de maneira que quando
> um objeto muda de estado todos os seus dependentes são notificados e
> atualizados automaticamente.

O GoF diz que esse padrão também é conhecido como pub/sub.

Então, como ele funciona? Basicamente, quando um estado interno muda, ele avisa
a quem está subscrito a ele que houve alteração. Só isso.

Esse padrão é quem motivou o `setter` no mundo java. Alterar um estado,
notificar que foi alterado.

Existem níveis e níveis de como se submeter a um publisher. O mais básico o
subscriver assiste a todos os episódios de alteração do publisher. Mas podem
ter esquemas mais sofisticados em que o subscriver informa o que ele quer
escutar.

De modo geral, o padrão pub/sub tem uma coleção de subscribers para um evento
de alteração. Se os subscribers vão receber ou não o evento é questão de como o
problema se apresenta. Vamos fazer sem lidar com o evento:

```ts
type Subscriber = () => void
function publishEvent(subs: Subscriber[]) {
    for (const sub of subs) {
        sub()
    }
}

function fazAlteracaoCampoX<V>(alvo: { x: V, subs: Subscriber[] }, novoX: V) {
    alvo.x = novoX
    publishEvent(alvo.subs)
}
```

## State

> Permite alterar o comportamento do objeto quando seu estado interno muda. O
> objeto parecerá ter mudado de classe.

Note que aqui "ter mudado de classe" não se refere necessariamente a interface,
mas sim o comportamento observável do objeto através de seus efeitos colaterais
e retornos.

Um exemplo de `state` (ou coisa semelhante) feita para garantir a construção de
um objeto foi implementado no
[Fluent Builder com região crítica]({% post_url 2021-12-23-fluent-builder %}).
Mas nesse caso aqui usamos o estado através do tipo do objeto para fazer com
que ele mudasse a interface. Logo, as transições de estado são gerenciadas
internamente de modo que seja impossível bater em uma API se o estado não for o
adequado.

Mas vamos lá, e quando não muda a interface? Vamos pegar um caso baseado em
implementações reais?

Eu trabalhei na integração de dados vindos do ERP para serem povoados dentro
das estruturas internas da firma. Essa integração era feita enviando pacotes de
delta do ERP para o sistema em que eu trabalhava.

Mas isso implicava que o ERP precisava calcular o delta. E isso nem sempre era
possível. Então foi feito uma solução para os casos de "importação big bang":
um pequeno serviço no meio do caminho que recebia os dados do ERP, todos eles,
e então calculava qual seria o delta para enviar o delta.

O caso mais comum de se usar esse sistema é para detectar quando uma relação
entre duas entidades deixou de existir. Essa relação era possível obter através
de uma projeção dos dados do ERP, mas para detectar que ela não existia mais a
questão ficava complicada. Complicava porque aí o ERP precisaria manter o
estado da última integração, calcular o estado desejado através de SELECTS e
então determinar quais deixaram de existir.

Fazer isso dentro do ERP era algo invasivo e que (com razão) nem todo mundo
queria fazer. Como o processamento era feito tabela-a-tabela, não tinha muito
segredo nisso: uma solução de meio do caminho seria mais do que o suficiente
para generalizar e atender os clientes.

Assim, foi colocado o sistema de meio de campo. Ele recebia a requisição
completa do ERP, comparava com os dados antigos, enviava para o sistema o que
necessitava ser enviado.

O workflow básico era:

- recebia o JSON (isso indicava o começo do trabalho)
- inseria o JSON na base de dados local
- comparava os novos dados com o anterior, determinando o delta
- enviava o delta
- consolidava os novos dados

Eventualmente algo poderia dar errado, e eventualmente também poderia haver o
cancelamento do fluxo do workflow. E também poderiam inserir outros workflows
com outros tipos de controle. Por exemplo, o ERP poderia necessitar fazer
várias requisições para povoar uma tabela (pois ele iria cair caso tentasse
povoar completamente uma tabela). Ou então parte do que foi enviado era
incremental e parte o delta deveria ser calculado localmente pelo meio de
campo.

E por fim, o meio de campo tinha um desafio adicional: ele precisava ser
resiliente contra ser derrubado. Caso ele fosse derrubado, ele precisaria ser
capaz de continuar trabalhando como se nada tivesse acontecido. Como se fosse
um "breakpoint", que foi parado naquele momento mas que poderia ser dado um
step a qualquer momento.

Com isso, nós temos o seguinte:

- workflow (abstrato)
- importação
- estágios
- breakpoints
- status

O ponto central é a importação. Ao receber uma requisição do ERP, inicia ou dá
continuidade em uma importação. Quando uma importação é criada, a ela é
atribuída um workflow e ela começa no estágio enfileirado. O resgate do
breakpoint dessa importação vai dar que ela está no estágio enfileirado, com o
status "esperando", e que ela segue um workflow específico.

Nesse momento, um scheduler vai pegar uma importação para dar continuidade.
Então, ao definir que precisa trabalhar com aquela importação, ele vai dar um
"step". E quem define o que é esse "step"? O estágio! A partir desse momento,
o código fica mais ou menos assim:

```ts
function realizaImportacao(importacao) {
    while (importacao.goon()) {
        importacao.step()
        salvaBreakpoint(importacao)
    }
}
```

O comportamento para cada chamada de `step` é definido única e exclusivamente
pelo estágio do workflow no qual a importação se encontra. De modo geral, o
resgate vindo do breakpoint até virar uma importação propriamente dita é assim:

```ts
type StatusImportacao = "ESPERANDO" | "EM_PROCESSAMENTO" | "ACEITE" | "RECUSA" | "CANCELADO"
type Breakpoint = {
    id: string,
    workflow_id: string,
    estagio_id: string,
    status: StatusImportacao
    // ... mais dados
}

type Workflow = {
    id: string,
    nome: string,
    estagios: Estagio[]
}

type Estagio = {
    id: string,
    nome: string,
    status: StatusImportacao,
    step: (importacao: Importacao) => Estagio
}

type Importacao = {
    id: string,
    workflow: Workflow,
    estagio: Estagio,
    goon: () => boolean,
    step: () => void

    // ... mais dados
}

function resgataWorkflow(id: string): Workflow {
    // ...
}

function statusGoon(status: StatusImportacao): boolean {
    return status == "ESPERANDO" || status ==  "EM_PROCESSAMENTO"
}

function importacao2breakpoint(importacao: Importacao): Breakpoint {
    return {
        id: importacao.id,
        workflow_od: importacao.workflow.id,
        estagio_id: importacao.estagio.id,
        status: importacao.estagio.status

        // ... mais dados
    }
}

function salvaBreakpoimt(importacao: Importacao) {
    const breakpoint = importacao2breakpoint(importacao)

    repository.salva(breakpoint)
}

function breakpoint2importacao(breakpoint: Breakpoint): Importacao {
    const step = (importacao: Importacao) => {
        const proxEstagio = importacao.estagio.step(importacao)
        importacao.estagio = proxEstagio
    }
    const goon = (importacao: Importacao): boolean => {
        return statusGoon(importacao.estagio.status)
    }

    const workflow = resgataWorkflow(breakpoint.workflow_id)
    const estagioInvalido: Estagio = {
        id: breakpoint.estagio_id,
        nome: "inválido",
        status: "RECUSA",
        step: (importacao: Importacao) => {
            return estagioInvalido
        }
    }

    const estagio = workflow.estagios.find(e => e.id == breakpoint.estagio_id) ?? estagioInvalido
    const imp: Importacao = {
        id: breakpoint.id,
        estagio,
        workflow,
        step: () => step(imp),
        goon: () => goon(imp),
    }

    return imp
}
```

O padrão de projeto state dessa importação é representado pelo código contido
dentro de `Estagio`.

## Strategy

> Definir uma família de algoritmos, encapsular cada uma delas e torná-las
> intercambiáveis. Strategy permite que o algoritmo varie independentemente dos
> clientes que o utilizam.

Tudo isso para defender o princípio de substituição de Liskov. Tomemos como
exemplo um algoritmo de busca em grafo, como os do post
[Meu take sobre o algoritmo de Dijkstra]({% post_url 2024-07-31-dijkstra-algorithm %}).
Lá, eu preciso passar uma estratégia de como pegar o próximo nó a ser visitado.

Como que faço para selecionar o próximo nó? Defino uma estratégia! Vamos pegar
o código original e transpor para TypeScript:

```ts
type Nodo = {
    vizinhos: Nodo[]
}

type EstruturaBusca = {
    push: (n: Nodo) => void,
    pop: () => Nodo,
    empty: () => boolean
}

function busca(origem: Nodo, destino: Nodo): boolean {
    const estruturaDados: EstruturaBusca = createEstruturaDados()
    estruturaDados.push(origem)

    const jaVisitados = new Set<Nodo>()

    while (!estruturaDados.empty()) {
        const sendoVisitado = estruturaDados.pop()
        if (sendoVisitado == destino) {
            return true
        }
        if (!jaVisitados.has(sendoVisitado)) {
            jaVisitados.add(sendoVisitado)
            for (const vizinho of sendoVisitado.vizinhos) {
                if (!jaVisitados.has(vizinho)) {
                    estruturaDados.push(vizinho)
                }
            }
        }
    }
    return false
}
```

Como explicado no artigo, basta mudar essa `EstruturaBusca` que eu tenho
algoritmos distintos. Por exemplo, se for FIFO, temoa uma busca em largura,
se for LIFO temos uma busca em profundidade, se tiver uma alternativa para
acumular distâncias percorridas temos Dijkstra, se tiver uma heurística para
estimar a distância entre um ponto `x` qualquer e o destino temos uma busca
`A*`. E o que define o que que eu vou usar? A estratégia.

Basicamente, posso posso a estratégia como argumeto:

```ts
type Nodo = {
    vizinhos: Nodo[]
}

type EstruturaBusca = {
    push: (n: Nodo) => void,
    pop: () => Nodo,
    empty: () => boolean
}

function busca(origem: Nodo, destino: Nodo, createEstruturaDados: () => EstruturaBusca): boolean {
    const estruturaDados: EstruturaBusca = createEstruturaDados()
    estruturaDados.push(origem)

    const jaVisitados = new Set<Nodo>()

    while (!estruturaDados.empty()) {
        const sendoVisitado = estruturaDados.pop()
        if (sendoVisitado == destino) {
            return true
        }
        if (!jaVisitados.has(sendoVisitado)) {
            jaVisitados.add(sendoVisitado)
            for (const vizinho of sendoVisitado.vizinhos) {
                if (!jaVisitados.has(vizinho)) {
                    estruturaDados.push(vizinho)
                }
            }
        }
    }
    return false
}
```

E pronto, defini a estratégia de busca. Apenas funções de alta ordem e o
princípio de substituição de Liskov.

## Template method

> Definir o esqueleto de um algoritmo em uma operaçãp, postergando (deffering)
> alguns passos para subclasses. Template method (gabarito de método) permite
> que subclasses redefinam certos passos de um algoritmo sem mudar a estrutura
> do mesmo.

Na real, esse padrão foi pensado por ausência de função de alta ordem. E ele é
bem dizer uma desculpa para usar herança como estratégia de reuso de código,
verificar a segunda mentira em
[As mentiras que te contaram sobre OOP]({% post_url 2024-08-21-mentiras-oop %}).

Mas, vamos lá, defender meu ponto, né?

Basicamente a ideia é ter um arcabouço no qual eu possa trocar alguns métodos
via herança. Por exemplo, eu posso estar sincronizando uma base de dados em um
formato proprietário. Imagina que isso seja feito tabela a tabela. Nele, você
precisa avisar ao usuário que está lendo determinada tabela, em qual linha
(aproximadamente) ele está:

```js
// dentro da classe tem `lidaNovaTabela` e `lidaNovaLinhaUpsert` como métodos abertos
function sync(dadaStream) {
    while (!dataStream.vazio()) {
        const b = dataStream.leByte();
        // trabalha com o byte b e cria o event

        if (event == NEW_TABLE) {
            lidaNovaTabela(nomeTabela)
        } else if (event == NEW_LINHA) {
            lidaNovaLinhaUpsert(data)
        // ...
        }
    }
}
```

Pois bem, essa função é o template method. Só falta agora configurar as ações.

Mas... sabe aquele papo de que é função? Então. Para isso, basta passar as
funções no lugar de delegar para métodos:

```js
// dentro da classe tem `lidaNovaTabela` e `lidaNovaLinhaUpsert` como métodos abertos
function sync(dadaStream, lidaNovaTabela, lidaNovaLinhaUpsert) {
    while (!dataStream.vazio()) {
        const b = dataStream.leByte();
        // trabalha com o byte b e cria o event

        if (event == NEW_TABLE) {
            lidaNovaTabela(this, nomeTabela)
        } else if (event == NEW_LINHA) {
            lidaNovaLinhaUpsert(this, data)
        // ...
        }
    }
}
```

E um exeplo de chamada disso?

```js
const syncer = ...
const dataStream = ...

const payload = {
    tabela: null,
    numeroLinhas: 0
}

syncer.sync(dataStream, (syncer, novaTabela) => {
    payload.tabela = novaTabela
    payload.numeroLinhas = 0
    console.log(novaTabela)
}, (syncer, dadosLinha) => {
    payload.numeroLinhas++
    console.log(payload)
})
```

E pronto, passei funções como argumentos e obtive assim o template method.

Percebeu como o template method e o strategy são bem semelhantes? Então,
segundo essa
[resposta no StackOverflow](https://stackoverflow.com/a/669366/4438007) a maior
diferença se dá porque o template method seria "definido em compile-time", já o
strategy em runtime. Basicamente, o template method do jeito que foi pensado
para C++ no GoF envolve subclasse. Aqui, para alcançar o mesmo efeito, foi
usado passagem de função de alta ordem, foi usado uma strategy.

## Visitor

> Representar uma operação a sewr executada nos elementos de uma estrutura de
> objetos. Visitor permite definir uma nova operação sem mudar as classes dos
> elementos sobre os quais opera.

Basicamente, o visitor vai ser aplicado em uma estrutura, que é um grafo de
objetos. O visitor é algo que o GoF deixa mais importante devido a tipagem
nominal. Com a tipagem estrutural, é bem dizer redundante o visitor. O visitor
precisa conhecer a estrutura de quem ele está visitando e, para cada um deles,
visitar o elemento.

A solução para Java/C++ que o GoF oferece implica que a solução do método que
vai ser executado é escolhido em tempo de compilação (_sigle dispatch_). Com o
visitor, isso vira _double dispatch_.

Basicamente, em java, o visitor vai chegar em um nó. Vai fazer o que precisa lá
e, então, começar a visitar na descida os outros nós. Só que no lugar de chamar
`visitor.visita(noFilho)` ele chama `noFilho.aceitaVisita(visitor)`. Por sua
vez, o código em **todo** nó filho é apenas isso:

```java
@Override // afinal, precisa em todos os que implementam um componente
public void aceitaVisita(Visitor v) {
    v.visita(this);
}
```

> Ah, mas qual o grande ganho disso? Uma maneira tediosa de declarar a mesma
> coisa em mais métodos?

Bem, não. O visitor não sabe visitar a classe abstrata de componente, apenas as
classes concretas. Logo, se não souber logo de cara a classe do `noFilho`,
temos que `visitar.visita(noFilho)` não existe para o nó pai, logo é impossível
fazer essa chamada. Por isso o `accept`, pois agora ao chamar `v.visita(this)`,
o método `visita` chamado já vai estar em um contexto em que `this` tem o tipo
adequado para que `.visita` seja chamado corretamnte.

# Padrões fora do GoF

Aqui temos alguns padrões que não podem simplesmente ser exercitados como
funções. São padrões de uma camada acima do código, por exemplo.

## Double checked lock

Já citado, tem o padrão _double checked lock_. A ideia desse padrão é evitar
gastar tempo com um lock sendo que trivialmente se deveria saber que aquilo
está resolvido. Normalmente usado para singletons, ou para um ambiente em que a
resposta é única mesmo para várias chamadas distintas, e precisa ser único. Não
é algo que se deve ser levado em consideração em aplicações que são
efetivamente monoprocessadas, portanto você vai encontrar mais em C#, Java, e
outras langs que favorecem a criação de threads selvagens.

Basicamente, tem um formato assim:

```java
private static final Object lockObj = new Object();
private static SomeType singletonianValue = null; // null é inválido, precisa povoar

public static SomeType getSingleton() {
    if (singletonianValue == null) {
        synchronize (lockObj) {
            if (singletonianValue != null) {
                return singletonianValue;
            }
            // imagine uma criação complexa abaixo
            singletonianValue = new SomeType();
        }
    }
    return singletonianValue;
}
```

A nível de Java, essa solução pode até parecer ok, mas ela está errada. O erro
acontece poruqe como a variável em si não é `volatile`, não há garantia do que
se chama de _happens before_: talvez a leitura dessa variável traga nulo em um
outro núcleo do processador, mesmo que o valor já tenha sido calculado, porque
em cache o valor daquela região de memória estava nulo. Como evitar? Usando
`volatile` já garante:

```java
private static final Object lockObj = new Object();
private static volatile SomeType singletonianValue = null; // null é inválido, precisa povoar

public static SomeType getSingleton() {
    if (singletonianValue == null) {
        synchronize (lockObj) {
            if (singletonianValue != null) {
                return singletonianValue;
            }
            // imagine uma criação complexa abaixo
            singletonianValue = new SomeType();
        }
    }
    return singletonianValue;
}
```

Mas a leitura de valores `volatile` são caros, justamente porque eles fazem um
flush no cache, garantindo que, depois da leitura daquele valor `volatile`,
todas as operações de escrita em memória que aconteceram _antes_ também estejam
visíveis para futuras leituras.

Podemos complicar um pouco mais a checagem para evitar passar pela leitura de
`volatile`:

```java
private static final Object lockObj = new Object();
private static SomeType singletonianValue = null; // null é inválido, precisa povoar
private static volatile SomeType singletonianValueVolatile = null; // null é inválido, precisa povoar

public static SomeType getSingleton() {
    if (singletonianValue == null) {
        if (singletonianValueVolatile == null) {
            synchronize (lockObj) {
                final var singletonVolatileRead = singletonianValueVolatile;
                if (singletonVolatileRead != null) {
                    return singletonVolatileRead;
                }
                // imagine uma criação complexa abaixo
                singletonianValue = new SomeType();
                singletonianValueVolatile = singletonianValue;
            }
        }
    }
    return singletonianValue;
}
```

## Strangling fig

Esse padrão é um padrão de engenharia de software, independente de linguagem.
Inclusive algumas vezes usado para trocar a linguagem do programa, sem fazer
uma FFI pra comunicar a nova versão com a antiga, normalmente resolvendo isso a
nível de gateway.

Basicamente, o strangling fig é uma estratégia em que você começa a reescrever
uma pequena parte do código antigo. E sempre comparando o resultado do código
novo com o antigo. Inicialmente pode ser feito um encaminhamento das
requisições comparando os resultados obtidos, tanto da versão nova quanto da
antiga.

Aí a ideia é substituir a versão antiga pela nova, aos poucos e constantemente.
Esse padrão não tem como ser uma função porque ele está acima do código.

[Material do Martin Fowler](https://martinfowler.com/bliki/StranglerFigApplication.html).

## Object Pool

Um pool é um objeto especial, em que objetos podem ser tirados dele até um
esgotamento. Após usado, o objeto é retornado ao pool para poder ser reusado.

Exemplos de object pool: HikariCP, reuso de sprites em jogos.

Mais detalhes nesse post:
[O que é o hikari pool?]({% post_url 2024-12-27-o-que-e-hikari-pool %})

## Active record

O active record é um padrão de bind do estado do objeto com a camada de
persistência. Até onde me consta, Ruby on Rails foi um grande popularizador e
utilizador desse padrão.

Basicamente, existem duas versões para esse padrão:

1. buffered: em que você precisa explicitar para ele se salvar
2. automático: a cada alteração o banco é afetado

[Leia mais](https://en.wikipedia.org/wiki/Active_record_pattern).
E [leia mais aqui também](https://guides.rubyonrails.org/active_record_basics.html).

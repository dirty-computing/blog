---
layout: post
title: "Resta um, em React"
author: "Jefferson Quesado"
tags: javascript node
---

> Confira o [Peg Kitten React](https://github.com/jeffque/peg-kitten-react)

Esse vai ser um blog post sobre a criação do jogo Resta Um (também conhecido como
_peg solitaire_) em React.

# Iniciando

Seguindo as dicas do [https://create-react-app.dev/](https://create-react-app.dev/),
devo apenas inserir o comando para criar o app em react:

```bash
npx create-react-app peg-kitten-react
```

Essa linha de comando, desse jeito, criou as coisas dentro da pasta `peg-kitten-react/`
de dentro do repositório. Não o melhor dos mundos... gostaria de ter criado na raiz
do repositório. Mas enfim, durou 3 minutos, não um experimento que eu estaria disposto
a replicar livremente como se não houvesse custos.

De toda sorte, o que o `-h` nos fornece?

```bash
$ npx create-react-app -h
Usage: create-react-app <project-directory> [options]

Options:
  -V, --version                            output the version number
  --verbose                                print additional logs
  --info                                   print environment debug info
  --scripts-version <alternative-package>  use a non-standard version of react-scripts
  --template <path-to-template>            specify a template for the created project
  --use-pnp
  -h, --help                               output usage information
    Only <project-directory> is required.
```

Nada relevante para mudar o que eu gostaria. Minha conclusão era que, a partir
de onde eu fiz o `git clone`, eu deveria também ter dado o `create-react-app`.
Fica o aprendizado, Jeff...

# TypeScript

Próximo passo? TypeScript!

Por que TypeScript? Bem, em projeto pequeno assim de fato não é tão necessário, não
espero que eu ou eventualmente alguém que entre vá se perder ao olhar o código em JS,
mas estou criando esse projeto para aprender. E tipos são legais.

Vamos habilitar o TS? Primeiro passo: aprender a instalar uma dependência de dev via NPM.

`npm -h` não me provou extremamente frutífero, apenas exibiu algumas informações gerais
sobre alguns subcomandos... mas `npm i -h` já mostrou bastante coisa interessante.
Entre eles a opção `--save-dev`, que se não me engano é o que preciso:

```bash
$ npm i --save-dev typescript
```

Procurando sobre "react + typescript", encontro a seguinte referência:

- [https://www.typescriptlang.org/pt/docs/handbook/react.html](https://www.typescriptlang.org/pt/docs/handbook/react.html)

que por sua vez aponta para o "create react app":

- [https://create-react-app.dev/docs/adding-typescript/](https://create-react-app.dev/docs/adding-typescript/)

que indica criar um app com template TypeScript... logo de cara...

Bem, pois não, vamos dar o passo para trás para poder ir pra frente melhor. Destruí meu repositório
clonado anterior e deixei que o seguinte comando lidasse com isso;

```bash
npm create-react-app peg-kitten-react --template typescript
```

# Customizações básicas

A estrutura do projeto criada é bem simples:

```none
public/
├── favicon.ico
├── index.html
├── logo192.png
├── logo512.png
├── manifest.json
└── robots.txt
src/
├── App.css
├── App.test.tsx
├── App.tsx
├── index.css
├── index.tsx
├── logo.svg
├── react-app-env.d.ts
├── reportWebVitals.ts
└── setupTests.ts
README.md
package-lock.json
package.json
tsconfig.json
```

No `index.html` extraído do template temos várias coisas já. As primeiras coisas
a si fazer são ajeitar título e meta-dados.

Ok, e depois disso? O "fork me" no cantinho, por que não? Recentemente vi o
[Akinn](https://twitter.com/akinncar) fazendo isso em seu app para acompanhar o apuramento
das urnas nas eleições 2022.

> Link do app [https://tse2022-presidente.vercel.app/](https://tse2022-presidente.vercel.app/)
>
> Link do repositório [https://github.com/akinncar/tse2022](https://github.com/akinncar/tse2022)

O commit em que se adicionou o "fork me corner" foi o [252e1285](https://github.com/akinncar/tse2022/commit/252e128504feaa7c31de0e11288f05b3c633b6f5).
Como ele fez isso?

Pois bem, aparentemente já existe uma dependência chamada `fork-me-corner`, que fornece um
componente pronto para usar no app react. Vamos testar?

Pronto, foi só instalar a dependência e usar o componente `ForkMe` passando para ele a URL
do projeto. Coloquei ele no `index.tsx` para ser o mais amplamente visível.

Agora o próximo passo está claro: editar o `App.tsx` e criar o jogo.

# O que consiste o Resta Um

Bem, Resta Um é um jogo de tabuleiro cuja mecânica é movimentar pinos no tabuleiro. As regras
de movimentação são bem claras:

- uma peça precisa parar em um lugar livre
- toda peça precia passar por cima de um única outra peça
- o movimento precisa ser através das arestas

e a regra para determinar se ganhou ou perdeu são simples:

- restou uma única peça: ganhou
- restaram mais de uma peça, porém, não há mais movimentos válidos: perdeu

Pronto. Só isso. O resto são detalhes. Como, por exemplo tamanho do tabuleiro (7 x 7 na versão
mais clássico) e distribuição de peças e casas livres.

Então, como podemos modelar? Podemos ter um Tabuleiro, que é retangular, e uma matriz de
posições indicando seu estado:

- livre
- com peça
- bloqueada

E então sobre isso projetar uma view. No meu caso, quero determinar que, ao ganhar, o usuário seja
gratificado com uma foto aleatória de um gatinho.

## Criando o jogo

### O tabuleiro

Meu primeiro passo foi representar o tabuleiro. Para representar o tabuleiro, preciso:

- da quantidade de linhas `l`
- da quantidade de colunas `c`
- para cada uma das `l * c` casas, uma representação do estado daquela casa

A partir disso surgiu o tipo de `Position`, que representa as posições (livre, ocupado, bloqueado)
e o tipo de `Board`, que representa o tabuleiro:

```ts
type Position = 'FREE' | 'PEG' | 'BLOCKED';

type Board = {
    lines: number,
    columns: number,
    t: Position[][]
}
```

Ok, preciso de um tabuleiro inicial. O padrão do tabuleiro de resta um é o seguinte, com `#` representando
uma peça e `.` um espaço livre (espaço bloqueado não é exibido por questões estéticas):

```none
    # # #    
    # # #    
# # # # # # #
# # # . # # #
# # # # # # #
    # # #    
    # # #    
```

Então, eu tenho 3 tipos de linhas:

- as linhas dos extremos
- as linhas cheias, perto do meio
- a linha central

Na primeira modelagem que fiz para a criação do tabuleiro básico usei justamente isso:

```ts
function createTabuleiro(): Board {
    const t:Position[][] = [];
    for (let i = 0; i < 7; i++) {
        const linha: Position[] = createLinha(i);
        t[i] = linha;
    }
    return {linhas: 7, colunas: 7, t};
}

function createLine(i: number): Position[] {
    if (i < 2 || i >= 5) {
        return createLineExtreme();
    } else if (i === 3) {
        return createLineCentral();
    } else {
        return createLineFull();
    }
}

function createLineFull(): Position[] {
    const l: Position[] = [];

    for (let i = 0; i < 7; i++) {
        l[i] = 'PEG';
    }
    return l;
}

function createLineCentral(): Position[] {
    const l: Position[] = [];

    for (let i = 0; i < 7; i++) {
        l[i] = i === 3? 'FREE': 'PEG';
    }
    return l;
}

function createLineExtreme(): Position[] {
    const l: Position[] = [];

    for (let i = 0; i < 2; i++) {
        l[i] = 'BLOCKED';
    }
    for (let i = 2; i < 5; i++) {
        l[i] = 'PEG';
    }
    for (let i = 5; i < 7; i++) {
        l[i] = 'BLOCKED';
    }
    return l;
}
```

Mais tarde, tendo a necessidade de criar tabuleiros de modo arbitrário, remodelei isso
para funcionar como a desserialização de uma string do tabuleiro. Ela é codificada da seguinte
maneira:

```ts
${lines as number}_${columns as number}_${board as PositionString}
```

onde `PositionString` casa com a regex `[BPF]*`. Aqui eu encodo as dimensões do tabuleiro (através
dos dois primeiros números, separados com `_`) e a distribuição de ocupação do tabuleiro. Se por acaso
a string `board` for menor do que `lines * columns`, então o resto é completado com `BLOCKED`. Caso
tenha mais elementos do que `lines * columns`, o excedente é ignorado. O resultado é o seguinte
código:

```ts
function char2Position(ch: string): Position {
    switch (ch) {
        case 'F': return 'FREE';
        case 'P': return 'PEG';
        case 'B':
        default:
            return 'BLOCKED';
    }
}

function desserializeBoard(s: string): Board {
    const fragments = s.split('_');
    const lines = Number.parseInt(fragments[0]);
    const columns = Number.parseInt(fragments[1]);
    const t: Position[][] = [];
    const stringLen = fragments[2].length;
    const expectedLen = lines * columns;
    console.log({lines, columns, fragments})
    for (let i = 0; i < Math.min(stringLen, expectedLen); i++) {
        const ch = fragments[2][i];
        const c = i % columns;
        const l = Math.floor((i-c)/columns);
        console.log({i, l, c, t, len: t.length})
        if (t.length <= l) t.push([])
        t[l][c] = char2Position(ch);
    }
    for (let i = expectedLen; i < stringLen; i++) {
        const c = i % columns;
        const l = Math.floor((i-c)/columns);
        if (t.length <= l) t.push([])
        t[l][c] = 'BLOCKED';
    }
    return {
        lines,
        columns,
        t
    }
}

function createBoard(modelo?: string): Board {
    if (!modelo) {
        modelo = '7_7_BBPPPBB' +
                     'BBPPPBB' +
                     'PPPPPPP' +
                     'PPPFPPP' +
                     'PPPPPPP' +
                     'BBPPPBB' +
                     'BBPPPBB';
    }
    return desserializeBoard(modelo);
}
```

### Representação estática

O próximo passo é representar o tabuleiro. Minha primeira ideia foi através de uma `<table>`.

Com o formato `<table>` eu poderia representar os estados de cada posição como uma cor distinta.

Dada essa representação, vamos por no React. Para mim, faz setido eu passar o tabuleiro como parâmetro.
Mas, como faz isso? Bem, deixei a IDE me guiar um pouco.

No começo, tinha-se algo assim dentro de `App.tsx`:

```tsx
function App() {
    return (<>
      <Gameboard/>
    </>)
}
```

Se eu quero passar o argumento para `Gameboard` com o tabuleiro, precisamos adicionar isso:

```tsx
function App() {
    return (<>
      <Gameboard board={createBoard()}/>
    </>)
}
```

Mas só fazer isso gera um erro. E o VSCode aponta para onde: o uso do `board` como propriedade do nó
que não foi atendida pela assinatura da função `Gameboard`.

Então, como passar essas propriedades? Pesquisando um pouco, vi que todos os argumentos passados adiante.
Já que estou fazendo em TS, que tal criar um tipo para passar os parâmetros?

```tsx
type GameboardProp = {
    board: Board
}

function Gameboard({board}: GameboardProp)
```

onde `GameboardProp` são as propriedades que se pode receber. Todas elas.

E, não, não tem como passar argumentos posicionais. Eles precisam ser argumentos nominais.
Até mesmo pela estruturação da tag para representar a chamada ao componente.

Por exemplo, as seguintes chamadas deveriam ser indistinguíveis:

```tsx
const oneInfo: TypeA = ...
const another: TypeB = ...

<Marmota a={oneInfo} b={another} />
<Marmota b={another} a={oneInfo} />
```

Portanto, para receber os argumentos, preciso definir que espero um elemento `a: TypeA` e
um elemento `b: TypeB`, e não confiar que eles irão aparecer em posições arbitrárias na
chamada da função. Como essas propriedades são chamadas comumente de `props`, o tipo passado
acaba sendo no formato `${Component}Props`. No caso do componente `Marmota`, teríamos
o tipo `MarmotaProps` definido e usado assim:

```tsx
type MarmotaProps = {
  a: TypeA,
  b: TypeB
}

function Marmota({a, b}: MarmotaProps)
```

Voltando aqui ao jogo, como eu quero manter uma `table` HTML, faz sentido que no nível
do componente `Gameboard` eu crie a tabela. Especificamente, modelei aqui para que cada
linha dentro de `board` gere um `GameboardRow` distinto.

> Aprendi inclusive aqui que tentar usar diretamente de um `<table>` um  `<tr>` tá lá.
> É necessário ter um `<tbody>` entre `<table>` e `<tr>`.

Então, acabou ficando algo assim:

```tsx
return <table className={styles.game}>
  <tbody>
  {
    myBoard.tiles.map((row, i) => <GameboardRow p={i} row={row} key={i}/>)
  }
  </tbody>
</table>
```

Descobri que o react acaba forçando você a colocar o `key`, que precisa ser único
entre cada conjunto de elementos que nascem a partir de um mapeamento de dados.

Portanto daí nasce o termo `key`, mesmo não estando na descrição do `GameboardRowProps`.
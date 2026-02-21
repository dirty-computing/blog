---
layout: post
title: "Pequeno template em Node para programação competitiva"
author: "Jefferson Quesado"
tags: js node programação-competitiva
base-assets: "/assets/template-node-spoj/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Abri o [Spoj](https://www.spoj.com/problems/classical/) e resolvi fazer um
pouco de flex com Node pelo bel prazer de resolver as coisas com JavaScript,
quick n'dirt. E, bem... me deparei com um problema que eu não havia ainda
cuidado: como faço para ler da entrada padrão no Node?

# Objetivo

Agora, eu preciso fazer um template para usar no Spoj. A ideia é ter uma
espécie de mini-boilerplate estilo o que foi fornecido
[nessa resposta](https://stackoverflow.com/a/79416756/4438007). Por que fazer
um template distinto? Porque não gostei desse, achei pouco intuitivo para mim.

Aqui a solução que o autor publicou:

```js
// Source - https://stackoverflow.com/a/79416756
// Posted by bikeman868
// Retrieved 2026-02-20, License - CC BY-SA 4.0

const partialLine = '';
const lines = [];
const emitter = new EventEmitter()

process.stdin.on('data', (data) => {
  const buffer = this._partialLine + data
  const newLines = buffer.split('\n')
  partialLine = newLines.pop() || ''
  lines.push(...newLines)
  if (lines.length) this._emitter.emit('data')
})
```

Por que eu não gostei? Porque aqui eu preciso fazer uma magia com o `emitter`,
tem muito estado do boilerplate que tá como estado global. Enfim, eu queria
algo mais direto, algo como:

```js
// resolve o problema

// define a magica

process.stdin.on('data', magica.on(solveProblemLinePerLine))
```

E nessa brincadeira a função `solveProblemLinePerLine` recebe uma linha de cada
vez.

> Ah, por que esse `process.stdin.on('data', ...)`?

Vamos por partes:

- `process` é um objeto que carrega dados sobre o processo em si
- `stdin` é a stream que representa a entrada padrão
- `.on('data', ...)` é uma reação de evento de quando recebeu um dado (ou seja,
  de fato fez uma leitura)

Então, se eu não puser um wrapper bonito na frente, é com isso que eu preciso
lidar. E, bem, meu objetivo é passar a linha inteira para frente, né? Vamos
abstrair como isso é feito e pensar em soluções de problemas?

## A vida, o universo e tudo mais

O [primeiro problema do Spoj](https://www.spoj.com/problems/TEST/) é um
problema bem simples: repita o número informado, até encontrar o primeiro 42.
A partir de então, ignore todos os números até o fim, incluindo o 42. Por
exemplo, para a entrada:

```txt
1
2
88
42
99
```

A saída será:

```txt
1
2
88
```

Como fazer isso? Podemos fazer uma máquina de estados, em que tem um estado
inicial `GO` e que, ao receber o valor 42, transita para o estado `STOP`. Se a
transição não ocorrer, emite o mesmo símbolos que recebeu.

```js
let state = "GO";
function solveProblemLinePerLine(line) {
    if (line == "42") {
        state = "STOP";
    }
    if (state == "STOP") {
        return;
    }
    console.log(line);
}
```

Como posso testar isso? Simples: passo cada linha manualmente!

```js
solveProblemLinePerLine("1");
solveProblemLinePerLine("2");
solveProblemLinePerLine("88");
solveProblemLinePerLine("42");
solveProblemLinePerLine("99");
```

Essa questão aceita que você submeta uma resposta em Node para ela!

## Gerador de primos

Aqui estou me baseando no problema
[Prime Generator](https://www.spoj.com/problems/PRIME1/), mas que infelizmente
não aceita submissão em Node.

Na primeira linha, é informada a quantidade de casos de casos de teste, `T`.
Para cada uma das `T` linhas seguintes, é informado um caso de teste que
consiste de 2 números, `m` e `n`. A ideia é imprimir, para cada caso de teste,
todos os primos `p` tal que `m <= p <= n`, e, ao final de um caso de testes,
imprimir uma linha em branco.

Por exemplo, para a entrada:

```txt
2
1 10
3 5
```

Temos a saída:

```txt
2
3
5
7

3
5

```

Como fazer isso? Bem, no primeiro momento, temos o estado `INIT`, então eu
entro no estado `INSTANCE`. Eu todo `T` vezes no estado `INSTANCE`, então após
esse tempo irei para o estado `END` e encerro o processo.

Então, posso colocar essa máquina de estados de modo geral na função
`solveProblemLinePerLine`:

```js
let state = "INIT";
let nProblems = 0;

function solveProblemLinePerLine(line) {
    switch (state) {
        case "INIT":
            readNProblems(Number(line));
            state = "INSTANCE";
            break;
        case "INSTANCE":
            const s = line.split(" ")
            readInstance(Number(s[0]), Number(s[1]));
            console.log();
            nProblems--;
            if (nProblems == 0) {
                state = "END";
                process.exit(0)
            }
            break;
    }
}
```

Na primeira leitura, eu transformo essa linha em um número e passo para quem
de fato lida com o estado. Então, altero o estado para `INSTANCE`.

Nas próximas leituras, eu sei que são 2 números, separados por um espaço. Então
eu separo a linha pelo espaço e transformo em números essas duas partes,
transmitindo esses números para quem de fato lida com isso. Após isso, eu
imprimo a linha vazia que separa cada instância e subtraiu da quantidade de
instâncias restante. Se a quantidade chegou em zero, muda o status para `END` e
termino a execução do programa.

Agora, com isso em mente, como lidamos com as partes abertas? Bem, não vou
tratar de modo esperto. No caso de `readNProblems` eu simplesmente povoo a
variável `nProblems`. Poderia colocar isso no `switch` do
`solveProblemLinePerLine`? Claro! Mas meu pensamento estava em tratar os
estados, eu quis separar isso por design mesmo.

Então, eu tenho o `readInstance`. Aqui eu preciso iterar do começo ao fim
(incluso) e, para cada primo encontrado, imprimir ele. Vou para a solução mais
tosca mesmo:

```js
function readInstance(menor, maior) {
    for (let i = menor; i <= maior; i++) {
        if (isPrime(i)) {
            console.log(i);
        }
    }
}
```

Agora eu preciso resolver `isPrime`. Bem, aqui eu poderia usar o Crivo de
Eratótenes, algumas soluções mais interessantes, ou simplesmente validar
dividindo pelos números menores. Como a ideia é ser simples, não vou focar em
como fazer isso, vou pelo jeito bruto. Se é menor do que ou igual a 1, não é
primo. Se é 2, é primo. Se é par, não é primo. Depois, de `i` a partir do 3 e
incrementando de 2 em dois até que `i*i` seja maior do que o número em questão;
se em algum momento esse `i` dividir o número em questão, então o número em
questão não é primo. Se chegou no final dessa iteração, então o número é primo:

```js
function isPrime(p) {
    if (p <= 1) {
        return false;
    }
    if (p == 2) {
        return true;
    }
    if (p % 2 == 0) {
        return false;
    }
    for (let i = 3; i * i <= p; i += 2) {
        if (p % i == 0) {
            return false;
        }
    }
    return true;
}
```

Juntando tudo:

```js
let state = "INIT"
let nProblems = 0

function readNProblems(n) {
    nProblems = n
}

function isPrime(p) {
    if (p <= 1) {
        return false;
    }
    if (p == 2) {
        return true;
    }
    if (p % 2 == 0) {
        return false;
    }
    for (let i = 3; i * i <= p; i += 2) {
        if (p % i == 0) {
            return false;
        }
    }
    return true;
}

function readInstance(menor, maior) {
    for (let i = menor; i <= maior; i++) {
        if (isPrime(i)) {
            console.log(i);
        }
    }
}

function solveProblemLinePerLine(line) {
    switch (state) {
        case "INIT":
            readNProblems(Number(line));
            state = "INSTANCE";
            break;
        case "INSTANCE":
            const s = line.split(" ")
            readInstance(Number(s[0]), Number(s[1]));
            console.log();
            nProblems--;
            if (nProblems == 0) {
                state = "END";
                process.exit(0)
            }
            break;
    }
}
```

Testando:

```js
solveProblemLinePerLine("2");
solveProblemLinePerLine("1 10");
solveProblemLinePerLine("3 5");
```

# Implementando a mágica

Beleza, eu preciso pegar os eventos de dados, transformar ele em linhas e
passar essas linhas adiante. Eventualmente meus dados não terão uma linha
completa, então sempre o último elemento fica como resíduo. Felizmente, para os
casos de programação competitiva tradicionais, a entrada é bem formatada e
sempre termina com uma quebra de linha, não tem resíduo após a última quebra de
linha.

Então eu preciso de uma função, que internamente tenha um eventual resíduo que
se aproveita entre runs seguidas. Essa função recebe os dados e emite linhas
para outra função. Como a mágica precisa ser uma coisa só, então eu preciso de
uma função que retorne a função, e que mantenha dentro dela o resíduo entre
linhas. Algo assim:

```js
function splitLines() {
    let buff = "";
    const f = (data) => {
        buff += data;
        const parts = buff.split("\n")

        for (const atom of parts.slice(0, -1)) {
            console.log(atom)
        }
        buff = parts[parts.length - 1];
    }
    return f;
}
```

Aqui, eu primeiro junto o resíduo da rodada anterior (começa com resíduo vazio)
com a entrada, então eu separo as linhas e envio todas as linhas completas
(`parts.slice(0, -1)`). A última parte é o resíduo, então após enviar as linhas
eu atualizo o resíduo e fico pronto para receber mais dados.

Agora, eu preciso indicar o que vai acontecer com essas linhas, como se fossem
"eventos". Por isso sinalizei com o `.on()`. Vamos usar o esquema de adicionar
atributos/métodos em funções? Estilo o que foi mostrado em
[Recursão a moda clássica em TS: auto referência do tipo de função]({% post_url 2025/2025-01-15-ts-self-type-referential-function %})
e em
[Funções como padrões de projeto: do GoF pro Computaria]({% post_url 2025/2025-05-24-functions-as-design-patterns %}):

```js
function splitLines() {
    let buff = "";
    const f = (data) => {
        buff += data;
        const parts = buff.split("\n")

        for (const atom of parts.slice(0, -1)) {
            console.log(atom)
        }
        buff = parts[parts.length - 1];
    }
    f.on = (action) => {
        // registra a ação
        return f;
    }
    return f;
}
```

Nota que o `.on` retorna a própria função, visto que o retorno dele que vai ser
usado para o `process.stdin.on('data', magica.on(...))`.

Ok, agora eu preciso ligar a ação passada com o laço. E... bem, por que não
manter as ações anteriores? Isso pode facilitar minha vida (inclusive me ajudou
a debugar a geração de primos (eu tinha esquecido de mudar o estado após a
primeira leitura)). E qual seria a ação neutra para poder juntar? A `noop`:
`(linha) => {}`. E agora para juntar? Eu posso executar a função anterior e
depois a função nova:

```js
let action = (linha) => {}

//...

const addAction = (newAction) => {
    const oldAction = action;
    action = (linha) => {
        oldAction(linha);
        newAction(linha);
    }
}

addAction(console.log)
addAction(linha => console.error(`recebi como entrada: >>>${linha}<<<`))
```

Juntando tudo isso:

```js
// solveProblemLinePerLine definido

function splitLines() {
    let buff = "";
    let _action = (el) => {};
    const f = (data) => {
        buff += data;
        const parts = buff.split("\n")

        for (const atom of parts.slice(0, -1)) {
            _action(atom)
        }
        buff = parts[parts.length - 1];
    }
    f.on = (action) => {
        const oldAction = _action;
        _action = (el) => {
            oldAction(el);
            action(el);
        };
        return f;
    }
    return f;
}

process.stdin.on('data', splitLines().on(solveProblemLinePerLine))
```

## Exemplo do gerador de primos

O código completo fica assim:

```js
let state = "INIT"
let nProblems = 0

function readNProblems(n) {
    nProblems = n
}

function isPrime(p) {
    if (p <= 1) {
        return false;
    }
    if (p == 2) {
        return true;
    }
    if (p % 2 == 0) {
        return false;
    }
    for (let i = 3; i * i <= p; i += 2) {
        if (p % i == 0) {
            return false;
        }
    }
    return true;
}

function readInstance(menor, maior) {
    for (let i = menor; i <= maior; i++) {
        if (isPrime(i)) {
            console.log(i);
        }
    }
}

function solveProblemLinePerLine(line) {
    switch (state) {
        case "INIT":
            readNProblems(Number(line));
            state = "INSTANCE";
            break;
        case "INSTANCE":
            const s = line.split(" ")
            readInstance(Number(s[0]), Number(s[1]));
            console.log();
            nProblems--;
            if (nProblems == 0) {
                state = "END";
                process.exit(0)
            }
            break;
    }
}

// boilerplate abaixo!!

function splitLines() {
    let buff = "";
    let _action = (el) => {};
    const f = (data) => {
        buff += data;
        const parts = buff.split("\n")

        for (const atom of parts.slice(0, -1)) {
            _action(atom)
        }
        buff = parts[parts.length - 1];
    }
    f.on = (action) => {
        const oldAction = _action;
        _action = (el) => {
            oldAction(el);
            action(el);
        };
        return f;
    }
    return f;
}

process.stdin.on('data', splitLines().on(solveProblemLinePerLine))
```

Durante a execução, note que o programa para (devido ao `process.exit(0)`)
quando é informado os casos de teste. Isso favorece o teste manual, ao executar
o código, ele para no momento que se espera.

## Exemplo da vida, o universo e tudo mais

Aqui, o código executa eternamente até o fim da entrada, por mais que chegue o
42 em algum momento:

```js
let state = "GO";
function solveProblemLinePerLine(line) {
    if (line == "42") {
        state = "STOP";
    }
    if (state == "STOP") {
        return;
    }
    console.log(line);
}

// boilerplate abaixo!!

function splitLines() {
    let buff = "";
    let _action = (el) => {};
    const f = (data) => {
        buff += data;
        const parts = buff.split("\n")

        for (const atom of parts.slice(0, -1)) {
            _action(atom)
        }
        buff = parts[parts.length - 1];
    }
    f.on = (action) => {
        const oldAction = _action;
        _action = (el) => {
            oldAction(el);
            action(el);
        };
        return f;
    }
    return f;
}

process.stdin.on('data', splitLines().on(solveProblemLinePerLine))
```

# Usando o template: macaco prego

Bem, para usar o template, precisamos entender como ele funciona. Basicamente,
para usar corretamente o modelo, precisamos pensar na máquina de estados e em
como ela vai reagir às entradas.

Como motor de exemplo, vamos pegar a questão 
[Macaco Prego](https://br.spoj.com/problems/MACACO/). Basicamente aqui a
entrada vai se dividir em dois blocos:

- primeira linha: N, a quantidade de quadrados
- próximas N linhas: descrições de quadrados

tl;dr da questão: ele precisa da interseção de todos os quadrados. Se não
houver, imprimir `nenhum`. Os quadrados são definidos por quatro números:
`LEFT`, `TOP`, `RIGHT`, `BOTTOM`.

Ah, o N pode ser `0` para indicar saída (na saída não se imprime nada).

Para cada caso de teste, a impressão deve ser `Teste X`, onde X é o número do
teste sendo executado (começa do 1), seguido da interseção (ou `nenhum`) e
seguido de uma linha em branco.

Bem, vamos analisar como resolver?

Basicamente, temos o estado `INIT`. Quando recebe 0, vamos para o estado de
`END`. Caso contrário, vamos para as leituras. Aqui, a primeira leitura vou
tratar como especial, pois precisamos da interseção e a interseção de todos os
retângulos sempre vai ser uma parte do retângulo inicial. Então, vamos para o
estado `READ_0`. Após essa leitura, contamos N-1 vezes a leitura no estado
`READ`, após isso imprimimos a resposta e voltamos para o estado `INIT`.

Isso já deve dar um bom esqueleto para o `solveProblemLinePerLine`:

```js
let state = "INIT";
let testNumber = 1;

function solveProblemLinePerLine(line) {
    switch (state) {
        case "INIT":
            leQuantidade(Number(line));
            if (quantidadeRestante == 0) {
                state = "END";
                process.exit(0);
            } else {
                state = "READ_0";
            }
            break;
        case "READ_0": {
            const [left, top, right, bottom] = line.split(" ");
            leituraZero(Number(left), Number(top), Number(right), Number(bottom));
            quantidadeRestante--;
            state = "READ";
            break;
        }
        case "READ": {
            const [left, top, right, bottom] = line.split(" ");
            leituraInc(Number(left), Number(top), Number(right), Number(bottom));
            quantidadeRestante--;
            if (quantidadeRestante == 0) {
                imprimeResposta(testNumber);
                testNumber++;
                state = "INIT";
            }
            break;
        }
        case "END":
            process.exit(0);
            break;
    }
}
```

Vamos preencher as lacunas? Começar por `leituraZero`. Aqui, a melhor solução é
preencher um objeto chamado `intersec` com o valor `left, top, right, bottom`,
sem segredo:

```js
let intersec = {};

function leituraZero(left, top, right, bottom) {
    intersec = { left, top, right, bottom }
}
```

Bem tranquilo, né? Bem, agora vamos na leitura incremental. Aqui, ao descobrir
que a interseção é impossível, eu posso simplesmente sobrescrever o objeto
`intersec` com o valor `nenhum`. Agora posso fazer uma tratativa especial para
esse valor. De resto, se a nova esquerda estiver mais pra lá do que a velha
esquerda, escolhe a nova. Vai ter uma tratativa dessas para cada um:

```js
function leituraInc(left, top, right, bottom) {
    if (intersec == "nenhum") {
        // caso especial, precisa fazer nada
        return;
    }
    const leftR = Math.max(left, intersec.left);
    const topR = Math.min(top, intersec.top);
    const rightR = Math.min(right, intersec.right);
    const bottomR = Math.max(bottom, intersec.bottom);

    intersec = {
        left: leftR,
        top: topR,
        right: rightR,
        bottom: bottomR
    };
}
```

É isso? Bem, não, preciso validar antes se a interseção existe. Em que caso a
interseção pode não existir? No caso em que a esquerda está depois da direita,
ou que o topo está debaixo do fundo:

```js
function leituraInc(left, top, right, bottom) {
    if (intersec == "nenhum") {
        // caso especial, precisa fazer nada
        return;
    }
    const leftR = Math.max(left, intersec.left);
    const topR = Math.min(top, intersec.top);
    const rightR = Math.min(right, intersec.right);
    const bottomR = Math.max(bottom, intersec.bottom);

    if (leftR > rightR || topR < bottomR) {
        intersec = "nenhum";
        return;
    }

    intersec = {
        left: leftR,
        top: topR,
        right: rightR,
        bottom: bottomR
    };
}
```

Finalmente, a impressão. Se for `nenhum`, só imprime o `nenhum` e seja feliz.
Caso contrário, precisa imprimir left, top, right, bottom nessa ordem separado
por espaços. E então uma linha em branco a mais:

```js
function imprimeResposta() {
    console.log(`Teste ${testNumber}`);
    if (intersec == "nenhum") {
        console.log(intersec);
    } else {
        const { left, top, right, bottom } = intersec;
        console.log(`${left} ${top} ${right} ${bottom}`)
    }
    console.log();
}
```

É isso? Bem, na real esqueci de um caso. Se for informada apenas uma única
área, a resposta vai ser exatamente a entrada, já que a interseção de todos os
retângulos, quando tem somente um único retângulo, é ele mesmo. Posso lidar com
isso como caso especial? Posso. Posso lidar com isso no `READ_0`? Posso.

Me parece mais trivial criar um caso especial: `READ_UNICO`!

```js
function solveProblemLinePerLine(line) {
    switch (state) {
        case "INIT":
            leQuantidade(Number(line));
            if (quantidadeRestante == 0) {
                state = "END";
                process.exit(0);
            } else if (quantidadeRestante == 1) {
                state = "READ_UNICO";
            } else {
                state = "READ_0";
            }
            break;
        case "READ_UNICO": {
            const [left, top, right, bottom] = line.split(" ");
            leituraZero(Number(left), Number(top), Number(right), Number(bottom));
            imprimeResposta(testNumber);
            testNumber++;
            state = "INIT";
            break;
        }
        case "READ_0": {
            const [left, top, right, bottom] = line.split(" ");
            leituraZero(Number(left), Number(top), Number(right), Number(bottom));
            quantidadeRestante--;
            state = "READ";
            break;
        }
        case "READ": {
            const [left, top, right, bottom] = line.split(" ");
            leituraInc(Number(left), Number(top), Number(right), Number(bottom));
            quantidadeRestante--;
            if (quantidadeRestante == 0) {
                imprimeResposta(testNumber);
                testNumber++;
                state = "INIT";
            }
            break;
        }
        case "END":
            process.exit(0);
            break;
    }
}
```

Juntando tudo:

```js
let state = "INIT";
let testNumber = 1;
let intersec = {};
let quantidadeRestante = 0;

function leQuantidade(quantidade) {
    quantidadeRestante = quantidade;
}

function leituraZero(left, top, right, bottom) {
    intersec = { left, top, right, bottom }
}

function leituraInc(left, top, right, bottom) {
    if (intersec == "nenhum") {
        // caso especial, precisa fazer nada
        return;
    }
    const leftR = Math.max(left, intersec.left);
    const topR = Math.min(top, intersec.top);
    const rightR = Math.min(right, intersec.right);
    const bottomR = Math.max(bottom, intersec.bottom);

    if (leftR > rightR || topR < bottomR) {
        intersec = "nenhum";
        return;
    }

    intersec = {
        left: leftR,
        top: topR,
        right: rightR,
        bottom: bottomR
    };
}

function imprimeResposta() {
    console.log(`Teste ${testNumber}`);
    if (intersec == "nenhum") {
        console.log(intersec);
    } else {
        const { left, top, right, bottom } = intersec;
        console.log(`${left} ${top} ${right} ${bottom}`)
    }
    console.log();
}

function solveProblemLinePerLine(line) {
    switch (state) {
        case "INIT":
            leQuantidade(Number(line));
            if (quantidadeRestante == 0) {
                state = "END";
                process.exit(0);
            } else if (quantidadeRestante == 1) {
                state = "READ_UNICO";
            } else {
                state = "READ_0";
            }
            break;
        case "READ_UNICO": {
            const [left, top, right, bottom] = line.split(" ");
            leituraZero(Number(left), Number(top), Number(right), Number(bottom));
            imprimeResposta(testNumber);
            testNumber++;
            state = "INIT";
            break;
        }
        case "READ_0": {
            const [left, top, right, bottom] = line.split(" ");
            leituraZero(Number(left), Number(top), Number(right), Number(bottom));
            quantidadeRestante--;
            state = "READ";
            break;
        }
        case "READ": {
            const [left, top, right, bottom] = line.split(" ");
            leituraInc(Number(left), Number(top), Number(right), Number(bottom));
            quantidadeRestante--;
            if (quantidadeRestante == 0) {
                imprimeResposta(testNumber);
                testNumber++;
                state = "INIT";
            }
            break;
        }
        case "END":
            process.exit(0);
            break;
    }
}

// boilerplate abaixo!!

function splitLines() {
    let buff = "";
    let _action = (el) => {};
    const f = (data) => {
        buff += data;
        const parts = buff.split("\n")

        for (const atom of parts.slice(0, -1)) {
            _action(atom)
        }
        buff = parts[parts.length - 1];
    }
    f.on = (action) => {
        const oldAction = _action;
        _action = (el) => {
            oldAction(el);
            action(el);
        };
        return f;
    }
    return f;
}

process.stdin.on('data', splitLines().on(solveProblemLinePerLine))
```

E... _voi là!_ Estamos prontos! Vamos submeter!

E claro que agora eu descubro que o Spoj não aceita Node para essa questão em
específico! Triste...

Mas, sabe o que ele aceita? SpiderMonkey JS! Vamos lá!

Quais são as transformações a serem feitas? Bem, para começar, não temos a
leitura daquele jeito. A leitura da linha é uma função chamada `readline()` que
devolve uma linha lida (ou `null` se chegar no final da stream, o que não
acontece aqui porque para sair se informa `0`).

Além disso, o `console.log` é substituído por `print`. E finalmente não tem o
`process.exit(0)`. No lugar, vou coloar um loop de leitura infinita até o
estado ser `END`, aí para a execução:

```js

let state = "INIT";
let testNumber = 1;
let intersec = {};
let quantidadeRestante = 0;

function leQuantidade(quantidade) {
    quantidadeRestante = quantidade;
}

function leituraZero(left, top, right, bottom) {
    intersec = { left, top, right, bottom }
}

function leituraInc(left, top, right, bottom) {
    if (intersec == "nenhum") {
        // caso especial, precisa fazer nada
        return;
    }
    const leftR = Math.max(left, intersec.left);
    const topR = Math.min(top, intersec.top);
    const rightR = Math.min(right, intersec.right);
    const bottomR = Math.max(bottom, intersec.bottom);

    if (leftR > rightR || topR < bottomR) {
        intersec = "nenhum";
        return;
    }

    intersec = {
        left: leftR,
        top: topR,
        right: rightR,
        bottom: bottomR
    };
}

function imprimeResposta() {
    print(`Teste ${testNumber}`);
    if (intersec == "nenhum") {
        print(intersec);
    } else {
        const { left, top, right, bottom } = intersec;
        print(`${left} ${top} ${right} ${bottom}`)
    }
    print();
}

function solveProblemLinePerLine(line) {
    switch (state) {
        case "INIT":
            leQuantidade(Number(line));
            if (quantidadeRestante == 0) {
                state = "END";
                return;
            } else if (quantidadeRestante == 1) {
                state = "READ_UNICO";
            } else {
                state = "READ_0";
            }
            break;
        case "READ_UNICO": {
            const [left, top, right, bottom] = line.split(" ");
            leituraZero(Number(left), Number(top), Number(right), Number(bottom));
            imprimeResposta(testNumber);
            testNumber++;
            state = "INIT";
            break;
        }
        case "READ_0": {
            const [left, top, right, bottom] = line.split(" ");
            leituraZero(Number(left), Number(top), Number(right), Number(bottom));
            quantidadeRestante--;
            state = "READ";
            break;
        }
        case "READ": {
            const [left, top, right, bottom] = line.split(" ");
            leituraInc(Number(left), Number(top), Number(right), Number(bottom));
            quantidadeRestante--;
            if (quantidadeRestante == 0) {
                imprimeResposta(testNumber);
                testNumber++;
                state = "INIT";
            }
            break;
        }
        case "END":
            break;
    }
}

// boilerplate abaixo!!

while (state != "END") {
    const linha = readline();
    solveProblemLinePerLine(linha);
}
```

Beleza, aparentemente agora lembra o que o SpiderMonkey aceita. Agora, que tal
antes validar? Felizmente descobri um sandbox online para experimentar:
[https://mozilla-spidermonkey.github.io/sm-wasi-demo/](https://mozilla-spidermonkey.github.io/sm-wasi-demo/).

Mas, bem, roda no browser, né? Não aceita bem o `readline`, como comportar?
Ora, ora, ora... lembra ainda antes de implementar o loop em cima do
`process.stdin.on('data', ...)`? Que testamos passando as strings linha a linha
para a função `solveProblemLinePerLine`? Façamos isso! No lugar do loop de
leitura do boilerplate:

```js
const linhas = [
    "3",
    "0 6 8 1",
    "1 5 6 3",
    "2 4 9 0",
    "3",
    "0 4 4 0",
    "3 1 7 -3",
    "6 4 10 0",
    "0"
]

for (const linha of linhas) {
    //const linha = readline();
    solveProblemLinePerLine(linha);
}
```

Só como teste de sanidade mesmo, e funcionou. Vamos submeter?

Bem, a submissão foi com suceso. O boilerplate funciona, e adaptar ele para
SpiderMonkey também deu certo.

## Nota sobre leitura de dados vs programação competitiva

Particularmente eu estou bem mais acostumado com ter domínio do fluxo do
programa quando estou em uma questão de programação competitiva. No lugar de
definir uma máquina de estados manualmente, eu simplesmente deixo o código
fazer isso diretamente. Por exemplo, seria muito mais natural fazer assim:

```js
function calculaIntersec(intersec, left, top, right, bottom) {
    if (intersec == "nenhum") {
        // caso especial, precisa fazer nada
        return "nenhum";
    }
    const leftR = Math.max(left, intersec.left);
    const topR = Math.min(top, intersec.top);
    const rightR = Math.min(right, intersec.right);
    const bottomR = Math.max(bottom, intersec.bottom);

    if (leftR > rightR || topR < bottomR) {
        return "nenhum";
    }

    return {
        left: leftR,
        top: topR,
        right: rightR,
        bottom: bottomR
    };
}

function resolveProblema(quantidadeRestante) {
    let intersec;
    let [left, top, right, bottom] = readline().split(" ");
    intersec = { left, top, right, bottom };
    quantidadeRestante--;

    while (quantidadeRestante > 0) {
        [left, top, right, bottom] = readline().split(" ");

        intersec = calculaIntersec(intersec, left, top, right, bottom);
        quantidadeRestante--;
    }
    return intersec;
}

function imprimeResposta(intersec, testNumber) {
    print(`Teste ${testNumber}`);
    if (intersec == "nenhum") {
        print(intersec);
    } else {
        const { left, top, right, bottom } = intersec;
        print(`${left} ${top} ${right} ${bottom}`)
    }
    print();
}

let testNumber = 1;
while (true) {
    const quantidadeRestante = Number(readline())
    if (quantidadeRestante == 0) {
        break;
    }
    const intersec = resolveProblema(quantidadeRestante);
    imprimeResposta(intersec, testNumber);
    testNumber++;
}
```

Aqui tá muito mais direto, a "máquina de estados" agora é o `while (true)` no
programa, tenho muito mais controle da submissão, consigo controlar muito
melhor como eu faço a leitura. Mas, bem, o ponto era mostrar o boilerplate em
Node, e isso foi demonstrado que funciona. E que é possível adaptar para rodar
com SpiderMonkey em cima da mesma mentalidade.

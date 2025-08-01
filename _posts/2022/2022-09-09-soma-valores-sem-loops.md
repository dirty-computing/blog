---
layout: post
title: "Somando valores sem laços"
author: "Jefferson Quesado"
tags: javascript programação algoritmos
---

O [Zan Franceschi](https://twitter.com/zanfranceschi) publicou o
seguinte [desafio](https://dev.to/zanfranceschi/desafio-calculo-em-estruturas-aninhadas-sem-lacos-2311):

> Como calculas a soma das compras sem usar laços? Map, filter, reduce e recursão são permitidos.
> 
> ![Exemplo de array com compras](https://res.cloudinary.com/practicaldev/image/fetch/s--6bkAeukk--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/38e90586tfpxnzifj150.png)

# Analisando os tipos

Bem, logo de começo, percebi que temos um objeto bem formado. Portanto, ele tem um tipo muito bem
definido e reproduzível. Vamos pegar o json original e destrinchar?

```json
{
    "compras": [
        {
            "data": "2022-01-01",
            "produtos": [
                {
                    "cod": "a",
                    "qtd": 2,
                    "valor_unitario": 12.24
                },
                {
                    "cod": "b",
                    "qtd": 1,
                    "valor_unitario": 3.99
                },
                {
                    "cod": "c",
                    "qtd": 3,
                    "valor_unitario": 98.14
                }
            ]
        },
        {
            "data": "2022-01-02",
            "produtos": [
                {
                    "cod": "a",
                    "qtd": 6,
                    "valor_unitario": 12.34
                },
                {
                    "cod": "b",
                    "qtd": 1,
                    "valor_unitario": 3.99
                },
                {
                    "cod": "c",
                    "qtd": 1,
                    "valor_unitario": 34.02
                }
            ]
        }
    ]
}
```

Na raiz, temos um objeto que tem um único campo chamado `compras`.
Vou chamar esse objeto com o nome absurdamente criativo `compras`.

Dentro desse campo, eu tenho um array de objetos do tipo `compra`.

Ok, agora, o que é um objeto do tipo `compra`? Ele é composto por
dois campos:

1. a data da compra, `data`
2. um array de produtos comprados naquela compra, `produtos`

O campo `data` é do tipo de data, já o campo `produtos` é um array
de objetos do tipo `produto`. E, por sua vez, o que é um `produto`?

1. tem um código de produto, tipo string, `cod`
2. a quantidade comprada, tipo número, `qtd`
3. o valor unitário de cada unidade comprada, tipo número, `valor_unitario`

Em uma notação free-style:

```
compras:
    - compras: compra[]

compra:
    - data: data
    - produtos: produto[]

produto:
    - cod: string
    - qtd: número
    - valor_unitario: número
```

E como conseguir a soma de todas as compras? Bem, para isso precisamos chegar até `produto`
e achar o valor da compra do `produto`, para então achar o valor da `compra`, para então
achar a soma do vetor de `compras`.

# Navegando os tipos

Eu sei transformar um `produto` em um valor. Se eu comprei 2 Coca-Colas 2L por 12.24
unitariamente, então o valor total desse produto é valor unitário vezes quantidade,
portanto 24.48.

Daí, consigo fazer o mapeamento `produto => valor` assim:

```ts
function produto2valor(p: Produto): number {
    return p.qtd * p.valor_unitario;
}
```

Mas eu não começo com produto. Eu começo com `compras`. Como chegar lá? Bem, a resposta
é simples: mapeando. Resgatando os tipos novamente pegando apenas o que nos interessa
(até chegar em `produto` que `produto` eu sei trabalhar), temos o seguinte:

```
compras:
    - compras: compra[]

compra:
    - produtos: produto[]
```

Ou seja, de `compras` consigo acessar um array de `compra`, e de elementos de `compra` posso
pegar um mapeamento planificado para o campo `produtos`, o que me retorna um array de
`produto` com todos os elementos individuais de trabalho. A diferença entre um mapeamento
clássico e um mapeamento "aplainado" é que no mapeamento clássico eu obtenho o array para
trabalhar com cada array individualmente; já no aplainado eu obtenho os elementos individuais
desse array para trabalhar.

```js
compra.map(c => c.produtos) // cada elemento é do tipo produto[]

compra.flatMap(c => c.produtos) // cada elemento é do tipo produto
```

Então, agora, se eu souber reduzir uma compra a um valor, posso pegar todas essas reduções e
reduzir em uma soma, confere?

```ts
function compra2valor(compra: Compra): number {
    return // algum valor
}

compras.compras
        .map(compra2valor) // agora só somar, trabalhando com tipo number
```

Confere. A redução de soma é basicamente a seguinte:

- se começa com o elemento neutro da soma `0`
- o acumulador é um número
- cada elemento recebido é um número
- a função é simplesmente a soma do acumulador com o atual `acc + current`

```ts
function compra2valor(compra: Compra): number {
    return // algum valor
}

compras.compras
        .map(compra2valor)
        .reduce((acc, curr) => acc + curr, 0)
```

Basicamente é isso, agora é só preencher a função mágica `compra2valor`.

Já sabemos usar `produto2valor`, então bastaria que eu transformasse
`Compra =[]> Produto` do mesmo jeito que transformei `Compras =[]> Compra`,
que então eu aproveitaria o fato de que já tenho `Produto => valor`. E, bem,
temos aqui a possibilidade de fazer um mapeamento aplainado para `produtos`:

```ts
function compra2valor(compra: Compra): number {
    return compra.flatMap(c => c.produtos) // aqui trabalhando com elementos do tipo Produto
}
```

Que por sua vez posso mapear com `produto2valor` e reduzir com a soma:

```ts
function compra2valor(compra: Compra): number {
    return compra.flatMap(c => c.produtos) // aqui trabalhando com elementos do tipo Produto
            .map(produto2valor) // aqui cada elemento é um número
            .reduce((acc, curr) => acc + curr, 0) // somei todos os números
}
```

Portanto, o todo seria:

```ts
function produto2valor(p: Produto): number {
    return p.qtd * p.valor_unitario;
}

function compra2valor(compra: Compra): number {
    return compra.flatMap(c => c.produtos)
            .map(produto2valor)
            .reduce((acc, curr) => acc + curr, 0)
}

compras.compras
        .map(compra2valor)
        .reduce((acc, curr) => acc + curr, 0)
```

E se quiser fazer one-liner:

```ts
compras.compras
        .map(c => c.flatMap(c => c.produtos)
                .map(p => p.qtd * p.valor_unitario)
                .reduce((acc, curr) => acc + curr, 0))
        .reduce((acc, curr) => acc + curr, 0)
```


# Usando propriedades da soma

Eu particularmente achei essa versão one-liner feia. Preciso repetir a mesma
operação de soma, não ficou visualmente agradável. Será que tem algo que eu
possa fazer para deixar mais elegante?

A resposta é? Sim, claro que há. Vamos rapidinho retornar aqui a como se pega
o valor de uma compra:

```ts
function compra2valor(compra: Compra): number {
    return compra.flatMap(c => c.produtos)
            .map(produto2valor)
            .reduce((acc, curr) => acc + curr, 0)
}
```

Note que, aqui, independente do objeto `compra` passado, se por acaso
tiverem o mesmo array de produtos, então a soma é exatamente a mesma.
De modo geral, as propriedade de `compra` não importam para o valor
da compra, apenas as propriedade de cada `produto`. Demais, como a
soma é assossiativa e comutativa:

- por ser assossiativa, `a + (b + c) = (a + b) + c`
- por ser comutativa, `a + b = b + a`

será que posso usar essas propriedades para pegar algo interessante?

Vamos supor que eu tenho 2 compras, as compras `a` e `b`. Cada compra
tem um total de item, e a compra `a` tem 3 itens, cujos valores vão
ser representados por `a1`, `a2` e `a3`. De modo semelhante tenho `b`,
com 2 itens. Se eu for inicialmente somar os valores das compras
individualmente para depois somar os valores das compras entre si,
teria a seguinte soma:

```js
((a1 + a2) + a3) +
(b1 + b2)
```

O que é a mesma coisa disto:

```js
let a12 = a1 + a2
let b12 = b1 + b2

(a12 + a3) + b12
```

Pela assossiação, tenho que isso é equivalente a

```js
let a12 = a1 + a2
let b12 = b1 + b2

(a12 + a3) + b12
a12 + (a3 + b12) // a partir daqui toda linha é equivalente à de cima
(a1 + a2) + (a3 + b12)
a1 + (a2 + (a3 + b12))
a1 + (a2 + (a3 + (b1 + b2)))
```
E como também é comutativa, não importa se primeiro eu somo `b1 + b2` ou se faço
`a1 + b1` se no final das contas eu vou somar tudo. Logo, eu posso ignorar o fato
de que eu preciso transformar `Compra` em `number`. Posso seguir tranquilamente
de `Compra =[]> Produto => valor`. E então somar tudo em uma bolada só:

```ts
// original
compras.compras
        .map(c => c.flatMap(c => c.produtos)
                .map(p => p.qtd * p.valor_unitario)
                .reduce((acc, curr) => acc + curr, 0))
        .reduce((acc, curr) => acc + curr, 0)

// usando as propriedades da soma
compras.compras // Array<Compra>
        .flatMap(c => c.produtos) // Array<Produto>
        .map(p => p.qtd * p.valor_unitario) // Array<number>
        .reduce((acc, curr) => acc + curr, 0) // number
```

E aqui temos a resposta ao desafio, usando uma única redução de soma:

```ts
compras.compras
        .flatMap(c => c.produtos)
        .map(p => p.qtd * p.valor_unitario)
        .reduce((acc, curr) => acc + curr, 0)
```

# Pequenas variações

Se eu quisesse apenas as compras que foram realizadas em maio de 2022? Bem,
aqui posso aplicar um filtro nas compras:

```ts
compras.compras
        .filter(comprasMaio2022)
        .flatMap(c => c.produtos)
        .map(p => p.qtd * p.valor_unitario)
        .reduce((acc, curr) => acc + curr, 0)
```

e implementar a função de filtro `comprasMaio2022` de modo adequado.

E se forem apenas para os produtos de código `"a"`, `"b"` e `"c"`?
Novamente, apenas um filtro nos produtos antes de transformar eles em
valores e reduzir:

```ts
compras.compras
        .flatMap(c => c.produtos)
        .filter(produtosAdequados)
        .map(p => p.qtd * p.valor_unitario)
        .reduce((acc, curr) => acc + curr, 0)
```

e implementar a função de filtro `produtosAdequados` de modo adequado.
---
layout: post
title: "Magia com XOR! Achando o elemento faltante de um array"
author: "Jefferson Quesado"
tags: matemática lógica
base-assets: "/assets/xor-search-missing-array/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Estava eu distraidamente assistindo
[este vídeo do Primeagen](https://youtu.be/YNObatXvhZc?si=tqVTYkhp1vdcDEe8)
sobre magias de XOR, quando ele apresenta um problema (sem apresentar a
solução):

> Dado um vetor de tamanho `n-1`, preenchido com inteiros distintos do
> intervalo `[1, n]`, ache o elemento faltante.

Pois bem, como fazer isso? São dois passos apenas:

```ts
function elementoFaltante(v: number[], n: number): number {
    let xn = 0;
    for (let i = 1; i <= n; i++) {
        xn ^= i;
    }
    return v.reduce((a, b) => a ^ b) ^ xn;
}
```

E... _voi là_, resolvido.

> Dá para ser mais ótimo ainda por sinal!

# Tá, mas por quê?

Para isso ser a resposta, precisamos conhecer 4 propriedades relevantes do XOR.

A primeira é que todo elemento é seu oposto. Isto é, `a ^ a = 0` **sempre**.
Não há casos especiais. Isso está na definição do ou exclusivo: um bit só é
verdade se ambos os bits operados tenham valores distintos. Caso tenham o mesmo
valor, seja ele verdadeiro ou falso, o retorno é falso. Operações bitwise são
aplicadas a cada um dos bits individualmente, logo todos os bits de `a`, ao
aplicar a operação sobre si mesma, são zerados nesse processo.

A segunda propriedade interessante é que o 0 é o elemento neutro. Portanto,
para todo `a`, `a ^ 0 = a`. Inclusive 0.

Outra propriedade é que o XOR é comutativo. Isto é, `a ^ b` é igual a `b ^ a`.
De novo, não há exceções para isso. O XOR é uma operação binária que,
diferentemente do IMPLY a ordem não importa: se ambos forem iguais, não importa
alterar a ordem, e se ambos forem diferentes dá sempre verdade, logo é
comutativo.

E por fim, XOR é associativo. Isso quer dizer que `(a ^ b) ^ c` tem o mesmo
valor do que `a ^ (b ^ c)`. Isso nos dá 8 possibilidades de valores para as 3
variáveis:

<table class='marked-table numeric'>
    <tr>
        <th>a</th>
        <th>b</th>
        <th>c</th>
        <th>a^b^c</th>
        <th>a^b</th>
        <th>b^c</th>
    </tr>
    <tbody>
        <tr>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
        </tr>
        <tr><!-- a -->
            <td>1</td>
            <td>0</td>
            <td>0</td>
            <td>1</td>
            <td>1</td>
            <td>0</td>
        </tr>
        <tr><!-- b -->
            <td>0</td>
            <td>1</td>
            <td>0</td>
            <td>1</td>
            <td>0</td>
            <td>1</td>
        </tr>
        <tr><!-- a,b -->
            <td>1</td>
            <td>1</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>1</td>
        </tr>
        <tr><!-- c -->
            <td>0</td>
            <td>0</td>
            <td>1</td>
            <td>1</td>
            <td>0</td>
            <td>1</td>
        </tr>
        <tr><!-- a,c -->
            <td>1</td>
            <td>0</td>
            <td>1</td>
            <td>0</td>
            <td>1</td>
            <td>1</td>
        </tr>
        <tr><!-- b,c -->
            <td>0</td>
            <td>1</td>
            <td>1</td>
            <td>0</td>
            <td>1</td>
            <td>0</td>
        </tr>
        <tr><!-- a,b,c -->
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>0</td>
            <td>0</td>
        </tr>
    </tbody>
</table>

O que nós podemos ver que a ordem em si em que são aplicadas as operações não
importa.

Outro jeito de pensar é: se tiver uma quantidade par de bits ligados, vai ser
falso, caso seja ímpar, dá verdadeiro. Contar é feito independente da ordem em
que os elementos são agrupados na operação (e também garante a comutatividade),
logo, como é equivalente à contagem e a contagem inerentemente vai ser
associativa, então a operação é associativa.

Como temos aqui que as operações são associativas, comutativas e que
`a ^ a = 0`, por que fizemos esses dois laços? Vamos lá.

Tudo é uma grande operação de XOR. O primeiro conjunto de XOR é de 1 até n.
Então temos aqui `1^2^...^(n-1)^n`. Depois, passamos a fazer o XOR com os
elementos do vetor. Sabemos que todos os elementos do vetor são distintos.
Vamos supor que esteja faltando o valor `(n-1)` no vetor. Aqui também teremos
um grande XOR. Colocando os dois valores um embaixo do outro:

```
1..n  : 1 ^ 2 ^ 3 ^ ... ^ (n-2) ^ (n-1) ^ n
vetor : 1 ^ 2 ^ 3 ^ ... ^ (n-2) ^ n
```

Vamos agora só por um espaço visual para que todos os elementos fiquem um
debaixo do outro:

```
1..n  : 1 ^ 2 ^ 3 ^ ... ^ (n-2) ^ (n-1) ^ n
vetor : 1 ^ 2 ^ 3 ^ ... ^ (n-2) ^         n
```

Como sabemos que é uma operação comutativa e associativa, podemos agrupar os
elementos com os pares na vertical:

```
(1^1) ^ (2^2) ^ (3^3) ^ ... ^ ((n-2) ^ (n-2)) ^ ( (n-1) ) ^ (n^n)
```

Notou que todo mundo ficou com par, exceto o `n-1`? Sabe o que acontece com XOR
de dois elementos iguais? Exatamente, eles se anulam, ficando assim:


```
(0) ^ (0) ^ (0) ^ ... ^ (0) ^ ( (n-1) ) ^ (0)
```

E o 0 é elemento neutro, portanto ficou apenas o `n-1` no final. Isso da
eliminação dos repetidos iria acontecer com todos os números, independente de
qual número fosse o elemento faltante. E essa recombinação só foi possível por
conta da comutatividade e da associatividade da operação XOR.

Então, resumindo:

- pelas propriedades de comutatividade e associatividade, podemos agrupar os
  pares de elementos idênticos
- pela propriedade de que o elemento é o seu próprio inverso, todos os pares se
  aniquilam
- pela propriedade que o 0 é o elemento neutro, só resta o elemento que não se
  aniquilou


Assim demonstramos que, ao fazer o XOR de todos os elementos de `[1..n]` e
depois de todos os elementos do vetor, obtemos o número faltante.

# Otimizando ainda mais

Sabe uma coisa interessante sobre os XORs de `[1..n]`? São duas coisas:

1. como o 0 é elemento netro, dá no mesmo resultado fazer `[0..n]`
2. o XOR no intervalo `[0..4k-1]`, para um `k` inteiro, é 0

O primeiro item é trivial, mas como provar o segundo item?

Para chegar lá, vou provar uma versão mais fraca disso antes: o XOR no
intervalo `[4k..4k+3]` é 0 para um `k` inteiro. Mas, se isso for verdade, isso
significa imediatamente que o item 2 é verdade. Então, vamos supor que isso
seja verdade.

O intervalo `[4k..4k+3]` pode ser reescrito assim, para `m=k+1`:
`[4m-4..4m-1]`. Para `m = 1` (equivalente a `k = 0`), isso dá o intervalo
`[0..3]`. Para `m = 2`, temos o intervalo `[4..7]`. Então, como a união de
`[0..3] U [4..7] = [0..7]`, temos que o XOR nos intervalos menores dá 0
(afinal, estamos assumindo isso), e portanto o XOR dos resultados dos
intervalos também dá 0. Logo, se o XOR nos elementos de `[4k..4k+3]` realmente
der 0, então temos que é verdade que o XOR de `[0..4k]` é 0.

Ok, vamos agora demonstrar que aplicar o XOR no intervalo `[4k..4k+3]` dá 0.
Os elementos que estamos fazendo XOR são:

- `4k`
- `4k + 1`
- `4k + 2`
- `4k + 3`

Como `k` é um inteiro, `4k` vai ter necessariamente os dois bits menos
significativos zerados. Como os números de 0 a 3 interferem **apenas** nos dois
bits menos significativos, isso significa que podemos considerar esses
elementos de modo independentes.

Assim, temos o seguinte grande XOR:

```none
4k ^ (4k + 1) ^ (4k + 2) ^ (4k + 3)
```

Devido a questão dos bits, podemos tratar `4k + 1` como `4k ^ 1`, e o mesmo
pensamento para 2 e 3:

```none
4k ^ (4k ^ 1) ^ (4k ^ 2) ^ (4k ^ 3)
```

Reordenando, consigo fazer dois pares de `4k`:

```none
(4k ^ 4k) ^ (4k ^ 4k) ^ 1 ^ 2 ^ 3
```

Logo, anulando os elementos idênticos:

```none
1 ^ 2 ^ 3
```

Lembrando que, por 1 e 2 não compartilharem nenhum bit ligado, a operação de
soma e o XOR se tornam a mesma coisa, portanto `1 + 2 = 1 ^ 2 = 3`, daí:

```none
3 ^ 3
```

E... eliminamos os repetidos. Portanto, aplicar XOR nos elementos de
`[4k..4k+3]` sempre resulta em 0.

## Utilizando essa otimização na prática

Basicamente, do intervalo `[1..n]`, podemos eliminar todos os intervalos todos
os subintervalor no formato `[4k..4k+3]`. Logo, para o maior `k` possível tal
que `4k+3 < n`, ficamos apenas com o XOR no intervalo `[4k+4..n]`.

Agora, precisamos achar esse `k`? Na real, não. Se `n % 4 = 3`, isso significa
que aplicar o XOR no intervalo restante, `[4k+4..n]`, que pode ser escrito da
forma `[4(k+1)..4x+3]` vai resultar em 0.

Agora, e se `n % 4 = 0`? Bem, aqui `n` vai ser o único número (pois todo o
intervalo `[1..n-1]` vai virar 0 ao aplicar o XOR).

Para `n % 4 = 1`, vamos ter que `n = 4x + 1`, portanto os dois elementos
restantes são `4x` e `4x + 1`. Aplicar o XOR nesses dois resulta em `1`.

Agora, para `n % 4 = 2`? Bem, podemos aproveitar o resultado anterior e fazer
um XOR a mais com o novo `n`, que vai dar `n + 1`.

Portanto, de acordo com `n % 4`:

<table class='marked-table numeric'>
    <tr>
        <th>n % 4</th>
        <th>valor do XOR [0..n]</th>
    </tr>
    <tbody>
        <tr>
            <td>0</td>
            <td>n</td>
        </tr>
        <tr>
            <td>1</td>
            <td>1</td>
        </tr>
        <tr>
            <td>2</td>
            <td>n + 1</td>
        </tr>
        <tr>
            <td>3</td>
            <td>0</td>
        </tr>
    </tbody>
</table>

Logo, posso reescrever aquela função assim:

```ts
function elementoFaltante(v: number[], n: number): number {
    let xn = 0;
    switch (n % 4) {
        case 0:
            xn = n;
            break;
        case 1:
            xn = 1;
            break;
        case 2:
            xn = n + 1;
            break;
        case 3:
            xn = 0;
            break;
    }
    return v.reduce((a, b) => a ^ b) ^ xn;
}
```

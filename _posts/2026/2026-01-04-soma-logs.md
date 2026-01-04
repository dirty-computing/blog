---
layout: post
title: "Somando logs: alternativa para agregar multiplicação em SQL"
author: "Jefferson Quesado"
tags: matemática sql
base-assets: "/assets/soma-logs/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Eu tinha de manter um sistema de força de vendas. E nele eu precisava calcular
o valor de venda de um produto. E, bem, até aí tranquilo. Mas eu precisava ir
além! Porque era necessário calcular em um outro momento qual era o valor base
em um outro sistema! E, claro, o valor "base" que estava na tabela de preço do
produto já tinha sido atualizado.

Então, como que fazia? Em um lado do sistema, carregava os objetos em Java e
computava normalmente:

{% katexmm %}
$$
Preço_{base} = Preço_{cru} \times \left(1 - \frac{desconto_{cond pgto}}{100}\right)\\
Preço_{venda} = Preço_{base} \times \left (1 - \frac{desconto_{manual}}{100}\right)
$$
{% endkatexmm %}

E no outro lado? Bem, no outro lado era em SQL, algo como:

```sql
SELECT
    i.id,
    i.id_pedido,
    i.preco_cru *
        (1 - p.desc_cond_pgto/100) *
        (1 - i.desconto_manual/100) AS valor_venda
FROM
    item_pedido i
INNER JOIN
    pedido p ON (i.id_pedido = p.id)
```

Bem, isso funcionava. Mas, o sistema evoluiu. E agora não só existem apenas os
descontos da condição de pagamento e o desconto manual. A preocupação era o
"pra frente", então não houve necessidade de backfill.

E por definição arquitetural, um sistema não poderia simplesmente pedir pro
outro para pegar o valor novo. Ambos deveriam consultar o banco como fonte de
verdade.

# Solução a nível de linguagem imperativa

Basicamente:

{% katexmm %}
$$
Preço_{venda} = Preço_{cru} \times \prod_i \left(1 - \frac{desconto_i}{100}\right)
$$
{% endkatexmm %}

Aqui já englobando todos os descontos que foram aplicados. Resgato os
descontos, faço o produtório, e aplico no final.

## Tá, mas por que assim?

Vamos rapidamente simular uma operação com dois descontos de 60%. Se eu começar
com um preço cru de 100, ao aplicar o primeiro desconto (removendo 60% do
valor) vou ficar com preço de 40. Aplicando novamente, vou ter 40 subtraindo
outros 60%, agora desse 40, para um valor final de 16.

# E no SQL?

Será que eu tenho o produtório no SQL? Tenho o somatório então não seria
impossível, né?

Mas... não. De agregador eu tenho normalmente `sum` (somatório), `avg` (média),
`stdev` (desvio padrão), mas não `prod` nem nada assim. E agora, vou precisar
mudar todo o sistema? Onde deveria ser uma simples mudança de consulta?

Bem, `avg` não "acumula" pra cima, e `stddev` também não. Só nos resta somar...
Seja lá como fazer, precisamos transformar somas em multiplicações... E sabe
onde a gente aprende sobre isso?

No ensino médio, em _logaritmos_! Então, vamos ver como que funciona isso?
Depois do mergulho na matemática vamos voltar ao produtório, só que dessa vez
em SQL.

# Logaritmo: multiplicações e somas

{% katexmm %}
Bem, a definição básica de logaritmo é: se eu preciso elevar um número $A$ por
$x$ para obter o número $N$, então o logaritmo de $N$ na base $A$ é $x$:

$$
A^x = N \iff \log_A(N) = x
$$

Agora, imagine que eu tenha os seguintes números positivos: $X$ e $Y$. Eu quero
qual o logaritmo do produto deles na base $B$ (também positivo, maior que 1).

$$
\log_B(X\times{}Y) = ?
$$

Eu posso não saber o quanto é $X$, mas de uma coisa eu sei: que existe um
número $w$ tal que $B^w = X$. E de modo similar, tenho que $B^z = Y$. Portanto:

$$
\log_B(X\times{}Y) = \log_B(B^w\times{}B^z)
$$

Mas, bem, uma coisa legal da multiplicação de potências da mesma base é que eu
posso somar os expoentes:

$$
B^w\times{}B^z = B^{w + z}
$$

Daqui, nós temos:

$$
\log_B(X\times{}Y) = \log_B(B^{w+z})
$$

Por definição de logaritmo:

$$
\log_B(X\times{}Y) = \log_B(B^{w+z}) = w+z
$$

Mas, só um minuto... a definição de $w$ e de $z$ foi tirada como? Bem, $w$ era
o expoente em $B$ que daria $X$, $B^w = X$. Portanto, $\log_B(X) = w$. E de
modo semelhante achamdos $\log_B(Y) = z$. Substituindo acima:

$$
\log_B(X\times{}Y) = w+z = \log_B(X) + \log_B(Y)
$$

Isso nos deu que o logaritmo da multiplicação é a soma dos logaritmos. Legal!
Mas... como usar?

Bem, voltemos aqui rapidinho:

$$
\log_B(X\times{}Y) = \log_B(X) + \log_B(Y)
$$

E se eu elevar a $B$ em ambos os lados?

$$
X\times{}Y = B^{\log_B(X) + \log_B(Y)}
$$

E se eu tivesse que na verdade $Y = \Gamma \times{}\Delta$?

$$
X\times{}Y = X\times{}\Gamma\times{}\Delta = B^{\log_B(X) + \log_B(Y)} =
B^{\log_B(X) + \log_B(\Gamma\times{}\Delta)} = B^{\log_B(X) + \log_B(\Gamma) + \log_B(\Delta)}
$$

Em outras palavras, enquanto eu for transformando em produtos de outros
números, eu consigo continuar na mesma lógica. Trocando as variáveis por outras
com um subscrito... intencional... temos que:

$$
X\times{}Y=V_1\times{}V_2\times{}V_3 = B^{\log_B(V_1) + \log_B(V_2) + \log_B(V_3)}
$$

Em outros palavras:

$$
\prod_i V_i = B^{\sum_i \log_B(V_i) }
$$

E isso é uma propriedade válida! Para qualquer base positiva diferente de 1!
Inclusive eu posso usar uma base mais conveninete:

$$
\prod_i V_i = e^{\sum_i \ln(V_i) }
$$

## Mas como eu sei que existe w?

Bem, vamos aos fatos. Eu simplesmente postulei que $B^w = X$. Mas, como eu
posso saber se existe esse $w$?

Vamos lá. A função exponencial é uma função monotonicamente crescente. Em
outras palavras, se eu pegar $f(x)$ e $f(x+\delta)$, com $\delta \gt 0$,
necessariamente eu vou ter que $f(x) \lt f(x+\delta)$.

E eu tenho que a assíntota da exponencial (com base maior do que 1) quando o
seu parâmetro vai para o infinito negativo é 0.

> Curioso sobre assíntota? Veja aqui:
> [O que é uma assíntota?, ou sobre Aquiles e a Tartaruga]({% post_url 2021/2021-12-28-assintota-ou-aquiles-e-a-tartaruga %})

Isso pode ser entendido de modo intuitivo. Peguemos o número na primeira
potência: $B^1$. Então, dividamos por $B$, obtendo $B^0 = 1$, que é menos do
que $B$. Se dividir de novo, teremos $B^{-1} = \frac{1}{B}$, que é menor do que
$1$. E se dividir de novo, vai ficar cada vez menor. Se eu dividir infinitas
vezes, só sobra um resquício infinitesimal, o que significa que o limite é 0:

$$
\lim_{x\rightarrow -\infty} B^x = 0
$$

Então temos uma linha base, $0$. O valor da função exponencial vai ao infinito
quando o parâmetro é infinito:

$$
\lim_{x\rightarrow +\infty} B^x = +\infty
$$

Como a função é contínua, para todo valor entre $0$ e $+\infty$ tem como ser
obtido a partir da função. Como ela é monotonicamente crescente, eu garanto que
esse valor é único. Em outras palavras:

$$
\forall y \in \left[ 0, +\infty \right) \implies \exists x, B^x = y\, \land \not\exists z \neq x, B^z = y
$$

Por conta disso, de ser uma função monotonicamente crescente, e que começa com
assíntota em 0 e "vai ao infinito", e que o número $X$ passado é um valor
positivo, eu sei que existe um número que irá satisfazer $B^w = X$.

## Mais propriedades interessantes do logaritmo

Antes de voltar pro causo do post, passar por algumas propriedades
interessantes:

$$
B^{\log_B(x)} = x
$$

Mas, por que isso? Bem, tiremos o logaritmo do número a esquerda:

$$
\log_B(B^{\log_B(x)})
$$

Por definição, $log_B(B^n) = n$, então podemos chegar a conclusão que:

$$
\log_B(B^{\log_B(x)}) = \log_B(x)
$$

Portanto, como sabemos que a função exponencial é (para bases maiores do que 1)
monotonicamente crescente, temos que necessariamente o que tem dentro do
operador $\log_B$ precisa ser idêntico:

$$
\log_B(B^{\log_B(x)}) = \log_B(x) \iff B^{\log_B(x)} = x
$$

Se a base for $B \in \left(0, 1\right)$, então temos uma função monotonicamente
decrescente. A imagem é idêntica a exponencial, porém refletida no eixo Y. Por
ser monotonicamente decrescente, também temos que isso continua sendo verdade.
E para base 1... bem, não falamos sobre isso.

Portanto, para bases positivas diferentes de 1, temos que:

$$
B^{\log_B(x)} = x
$$

{% endkatexmm %}

# Mas como podemos resolver em SQL?

Vamos lá, para o resultado encontrado:

{% katexmm %}
$$
\prod_i V_i = e^{\sum_i \ln(V_i) }
$$

E o que eu preciso fazer?

$$
Preço_{venda} = Preço_{cru} \times \prod_i \left(1 - \frac{desconto_i}{100}\right)
$$

Portanto, se eu definir:

$$
V_i = \left(1 - \frac{desconto_i}{100}\right)
$$

Temos que:

$$
Preço_{venda} = Preço_{cru} \times \prod_i V_i
$$

E isso é equivalente a:

$$
Preço_{venda} = Preço_{cru} \times e^{\sum_i \ln(V_i) }
$$

{% endkatexmm %}

Aqui já sumimos com o produtório! Massa! E nos bancos de dados normalmente se
encontra funções para logaritmo natural (`ln`) e exponenciação na base de Euler
(`exp`).

Portanto, podemos expressar isso da seguinte maneira:

```sql
SELECT
    i.id,
    i.id_pedido,
    i.preco_cru * exp(sum(ln(v))) AS valor_venda
FROM
    item_pedido i
INNER JOIN
    pedido p ON (i.id_pedido = p.id)
GROUP BY
    i.id, i.id_pedido
```

Ok, agora só precisamos saber quem é o valor `v`. Ele vem dos descontos, então
posso assumir que vem de `item_pedido_desconto`. Substituindo de volta:

```sql
SELECT
    i.id,
    i.id_pedido,
    i.preco_cru * exp(sum(ln(1 - ipd.desconto)/100)) AS valor_venda
FROM
    item_pedido i
INNER JOIN
    item_pedido_desconto ipd ON (ipd.id_item = i.id)
INNER JOIN 
    pedido p ON (i.id_pedido = p.id)
GROUP BY
    i.id, i.id_pedido
```

Hmmm, até parece razoável, mas eventualmente não vai ser necessário salvar nada
em `item_pedido_desconto`. Agora só resolver esse pequeno problema de
cardinalidade!

Vamos reordenar para manter a junção lateral no final para evitar _shenanigans_
de misturar `INNER` e `OUTTER` joins:

```sql
SELECT
    i.id,
    i.id_pedido,
    i.preco_cru * exp(sum(ln(1 - ipd.desconto)/100)) AS valor_venda
FROM
    item_pedido i
INNER JOIN 
    pedido p ON (i.id_pedido = p.id)
LEFT JOIN
    item_pedido_desconto ipd ON (ipd.id_item = i.id)
GROUP BY
    i.id, i.id_pedido
```

Hmmm, outra coisa legal é que não estamos mais consumindo de `PEDIDO`, então
podemos remover essa tabela:

```sql
SELECT
    i.id,
    i.id_pedido,
    i.preco_cru * exp(sum(ln(1 - ipd.desconto)/100)) AS valor_venda
FROM
    item_pedido i
INNER JOIN 
    pedido p ON (i.id_pedido = p.id)
LEFT JOIN
    item_pedido_desconto ipd ON (ipd.id_item = i.id)
GROUP BY
    i.id, i.id_pedido
```

E... _voi là_! Temos produtório em SQL!

## Caveats, porque sempre tem

Bem, essa estratégia só funciona em números que são _float_. Os detalhes de
transformação de `DECIMAL` para float com todo o carinho do mundo. Isso
significa alguma potencial perca de precisão.

Também temos que essa exponenciação só é viável com números próximos. Também
questão de float, de precisão, de erro acumulado em operações. Aqui o esperado
é que os descontos sejam semelhantes. Algo que não mude em uma ordem de
grandeza o número, então nesse tipo de cenário é uma aproximação boa o
suficiente. Mesmo que um desconto seja 8x maior do que o outro, vai ser algo
como 5% para 40%: o fator passado para `ln` seria algo entre 95% ou 60%, na
mesma grandeza de modo geral.

Apesar de teoricamente ser possível de utilizar dessa fórmula para calcular a
média geométrica, o acúmulo de erros também é grande.

Muitos elementos, elementos negativos e zero também são campeões para fazer
essa fórmula se comportar mal. Essa fórmula eu testei para números próximos em
um universo uma ou duas dezenas de valores.

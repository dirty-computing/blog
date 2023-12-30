---
layout: post
title: "Determinando interseção de circunferências programaticamente"
author: "Jefferson Quesado"
tags: python geometria tartaruga
base-assets: "/assets/intersecao-circulos/"
---

> Baseado na minha resposta no StackOverflow em Português sobre este mesmo problema [https://pt.stackoverflow.com/a/260073/64969](https://pt.stackoverflow.com/a/260073/64969)

Dadas duas circunferências, elas se tocam em algum ponto?

Bem, existem algumas possibilidades para isso. Vamos considerar inicialmente circunferências com raios distintos,
estudar suas possibilidades, e então passar a estudar com o mesmo raio.

# Circunferências de raios distintos

Vamos começar com elas concêntricas e ir andando aos pouquinhos a menor circunferência pra direita?

{% assign sizes = "0 80 90 95 100 105 110 120" | split: " " %}
{% for off in sizes %}
  {% capture name %}noteqr-{{off}}.png{% endcapture %}
  ![Círculo pequeno no offset {{off}}, com raio 10, e círculo grande na origem com raio 100]({{ page.base-assets | append: name | relative_url }})
{% endfor %}

Aqui nós temos todos os casos que eu gostaria de mostrar, sem perder generalidade.

Explicar eles aqui inicialmente:

1. concêntricos, não há nenhum toque
1. circunferência menor dentro da maior, mas sem toque
1. circunferência menor tangenciando a maior por dentro
1. circunferência menor cortando a maior, centro dentro da maior
1. circunferência menor cortando a maior, centro na circunferência maior
1. circunferência menor cortando a maior, centro externo
1. circunferência menor tangenciando a maior por fora
1. circunferência menor totalmente fora da maior, sem nenhum ponto de toque

Para o caso de circunferências de tamanhos distintos, temos esses 8 casos. Variações em tamanho
das circunferências não é importante, ainda assim todos esses casos acontecem caso os raios sejam
distintos.

## Por que não perco a generalidade?

{% katexmm %}
Bem, vamos começar com assuntos tangentes. Por que não perco a generalização das posições relativas?
Estou prendendo a circunferência maior a um único ponto (a origem) e movendo a menor em uma única
direção (eixo horizontal) a partir também da origem. Aparentemente isso remove uma infinidade de
possibilidades para duas circunferências com raios $r1$ e $r2$

Se uma transformação $\nabla: SC_1 \mapsto SC_2$ que mantém o posicionamento relativo de todos
os seus pontos, então temos que todas as verdade que se encontra para o sistema de coordenada 1
($SC_1$) também vale para o sistema de coordedas 2 ($SC_2$).

Assim, temos que

$\forall p,q \in SC_1 \mid |\overline{pq}| = |\overline{\nabla(p)\nabla(q)}|$

onde a operação $|\overline{X}|$ é a operação que calcula o tamanho do segmento
$\overline{X}$. Se a propriedade acima for mantida, então isso significa que tudo que eu encontrar
para um sistema de coordenadas $SC_1$ é perfeitamente válido para o sistema de coordenadas
$SC_2 = \nabla(SC_1)$. Vale ressaltar que isso é transitivo, posso ter duas transformações desse tipo.

Aqui, as transformações que me interessam são:

1. translação
2. rotação
3. refexão

Uma operação $\nabla(x,y) = (x - c, y - d)$ mantém a propriedade de que as distâncias relativas de todos
os pontos são mantidas. A rotação, fornecida pela matriz de rotação, também nos garante essa propriedade.

Logo, eu posso deslocar o centro da maior circunferência com uma operação de translação. Se seu centro for
$(C_x, C_y)$, a operação é $\nabla_t(x, y) = (x - C_x, y - C_y)$. Ao aplicar no centro da circunferência, ela
irá para a origem. Essa operação só é necessário aplicar se $(C_x, C_y) \not= (0, 0)$.

Depois, basta rotacionar o centro da menor circunferência de modo que ela fique no lado positivo do eixo horizontal.
A rotação só precisa ser aplicada se e somente se $c'_y \not= 0$.

Essa rotação é "fácil" alcançar pois com o vetor $\overrightarrow{C'c'}$ temos o valor da tangente. Para achar o ângulo,
basta aplicar o $\arctan(c'_y / c'_x)$ (já que o centro da circunferência maior $C'$ é a origem nesse novo sistema de
coordenadas). Se girarmos no ângulo contrário, teremos que o centro da circunfência menor vai pro eixo horizontal:

$$
\nabla_r(p) = rot_{-\arctan(c'_y / c'_x)}(p) = p'
$$

Após aplicado isso, pode acontecer de o centro da circunferência menor estar no lado negativo do eixo horizontal. Então,
podemos refletir todos os pontos usando o eixo vertical como base, usando a operação $\nabla_s(x, y) = (-x, y)$. Isso
só seria aplicado caso $c'_x < 0$.

Portanto, dado duas circunferências quaisquer de raios distintos em quaisquer posições do plano cartesiano, só aplicar a seguinte
transformação para ter a circunferência maior na origem e a circunferência menor à sua direita:

$$
(\nabla_s \circ \nabla_r \circ \nabla_t)(x, y)
$$
{% endkatexmm %}

# Circunferências de mesmo raio

Para circunferências de mesmo raio existem menos casos. Começando da
origem:

1. mesma circunferência
1. secantes
1. tangentes
1. não se tocam

Não ocorre o "sem toque, por dentro" nem o "tangente, por dentro".

# Fazendo as detecções

O primeiro passo é determinar se as circunferências tem o mesmo raio
ou não. Se elas tiverem o mesmo raio, só temos 4 categorias para elas.

## Mesmo raio

{% katexmm %}
Para serem a mesma circunferência, os dois centros devem ser o mesmo.
Para tal, $|\overline{c_1 c_2}| = 0$

Agora, se a distância entre os centros for entre 0 e duas vezes o
raio (a soma dos raios das duas circunferências), então elas são
secantes. $0 < |\overline{c_1 c_2}| < 2r$

Se for exatamentea soma dos raios, as circunferências de tangenciam.
$|\overline{c_1 c_2}| = 2r$

Se for maior do que a soma dos raios, então elas não se tocam.
$|\overline{c_1 c_2}| > 2r$

## Raios distintos

Vamos assumir aqui que o raio da circunferência maior é $R$ e o da
menor é $r$.

Podemos pegar a lição apendida do caso de círculos de mesmo raio.

Se for maior do que a soma dos raios, então elas não se tocam.
$|\overline{c_1 c_2}| > R+r$

Se for exatamente igual a soma dos raios, então são tangentes
externas. $|\overline{c_1 c_2}| = R+r$

Agora, entre  um pouco menor que a soma dos raios até o meomento
que vira tangente interna, os círculos são secantes. Agora, quando
será que eles são tangentes internas uma a outra?

A resposta é simples: quando a distância entre os centros leva até
pertinho da circunferência grande, e você só precisa caminhar mais
$r$ até chegar na circunferência maior. Ou seja, a distância
entre os centros mais o raio da menor é o raio da maior.

Então, para serem tangentes internas, $|\overline{c_1 c_2}| + r = R$.
Como estamos anotando com base na distância entre os pontos, podemos
isolar essa variável e ficamos assim: $|\overline{c_1 c_2}| = R - r$

Ou seja, é secante no intervalo  $R + r > |\overline{c_1 c_2}| > R - r$

Para ser não secante interna, basta ter a distância entre os centros
menor do que a necessária para ser tangente. $R - r > |\overline{c_1 c_2}| \geq 0$

# Circunferências representada pelo centro e raio

Dadas duas circunferências, $C_1 = (x_1, y_1, r_1)$ e $C_2 = (x_2, y_2, r_2)$,
onde $r_i$ indica o raio e $(x_i, y_i)$ o centro da circunferência, como saber
a posição relativa entre elas?

Bem, vamos organizar de tal modo que $C_M$ e $C_m$ que $r_M \ge r_m$.
Então, peguemos a distância entre os centros:
$D = \sqrt{(x_M - x_m)^2 + (y_M - y_m)^2}$.

Caso $D \gt r_M + r_m$, então as circunferências são não secantes
externas.

Caso $D = r_M + r_m$, então elas são tangentes externas. Em breve iremos achar o ponto de tangência.

Agora, caso tenhamos $r_M + r_m \gt D \gt r_M - r_m$, então isso
indica que as circunferências são secantes. Note que isso é
verdade independnete se elas tem o mesmo raio ou se são raios
distintos.

Agora, para casos além desses, precisamos ramificar em
**mesmo raio** e **raios distintos**.

No caso específico de mesmo raio, a única outra possibilidade
restante é com $D = r_m - r_m = 0$, onde as circunferências
são sobrepostas uma na outra.

Para o caso de raios distintos, temos o cenário de $D =
r_M - r_m$, tangente interna.

E por fim, se $r_M - r_m \gt D \ge 0$, temos não secantes internas.

## Fórmula da circunferência

Em geometria analítica, ao descrever uma curva, temos uma função
que só é possível ter valores nela para os pontos da curva.

Por exemplo, temos uma notação para a [curva do
barbante]({% post_url 2022-11-17-comprimento-arco %}). Mas
para esse caso específico aqui não precisamos de uma curva
parametrizda (apesar de ser possível e fácil), apenas
um conjunto de ponto que satisfaçam uma condição.

No caso de um circunferência, os pontos são aqueles que estão
a mesma distância do centro. Então, pegue um ponto
qualquer, $(x, y)$, basta que a distância dela até o centro
$(x_c, y_c)$ seja igual ao raio $r$. Daí temos que:

$$
\sqrt{\left(x - x_c\right)^2 + \left(y - y_c\right)^2} = r
$$

Ou então equivalentemente:

$$
\left(x - x_c\right)^2 + \left(y - y_c\right)^2 = r^2
$$

Manipulando mais um pouco em troca de mágica:

$$
\left(x - x_c\right)^2 + \left(y - y_c\right)^2 - r^2 = 0
$$

## Tangências externa e interna

Para o caso de tangentes, tem um truque que podemos utilizar:
o vetor entre os centros de ambas as circunferências.

A interseção se situará na reta que liga os centros, então
se for calculado o vetor entre os dois centros e manipular
a sua magnitude para o tamanho do raio de uma das
circunferências, então teremos que o ponto obtido por
"somar" esse vetor esticado ao centro da circunferência
se encontrará na circunferência e ele que será o ponto de
interseção.

Tomemos `C_1` como a circunferência base. Daí, o vetor
entre os centros de `C_1` e `C_2` será:

$$
V = (x_2 - x_1, y_2 - y_1) = (x_v, y_v)
$$

Com $(x_v, y_v)$ devidamente calculado, o módulo dele
é $|V| = \sqrt{x_v^2 + y_v^2}$. Podemos então transformar
o vetor dessa magnitude $|V|$ em um vetor unitário
dividindo por $|V|$:

$$
U = (x_v / |V|, y_v / |V|) = (x_u, y_u)
$$

E então basta multiplicar pelo raio da circunferência
que obteremos o vetor adequado:

$$
V' = (x_u\times r_1, y_u\times r_1)
$$

Então, colocando o vetor em cima do centro obtemos o ponto
de tangência:

$$
T = (x_1, y_1) + (x_u\times r_1, y_u\times r_1) =
  (x_1 + x_u\times r_1, y_1 + y_u\times r_1)
$$

## Secante

Para secante não conheço nenhuma estratégia interessante. Então,
vamos achar um ponto `(x, y)` que satisfaça ambas as condições
para `C_1` e `C_2`?

Podemos resolver através de um sistema não linear:

$$
\left(x - x_{c_1}\right)^2 + \left(y - y_{c_1}\right)^2 - r_1^2 = 0\\
\left(x - x_{c_2}\right)^2 + \left(y - y_{c_2}\right)^2 - r_2^2 = 0
$$

ou achando o valor de `y` dado `x` em termos de `C_1`, e então
substituir em `C_2`.

### Pelo sistema não linear

TBD

### Achando y = f(x)

Temos que:

$$
\left(x - x_{c_1}\right)^2 + \left(y - y_{c_1}\right)^2 - r_1^2 = 0
$$

portanto:

$$
y^2 - 2 y_{c_1} y  + y_{c_1}^2  + \left(x - x_{c_1}\right)^2 - r_1^2 = 0
$$

Aplicando Bhaskara para achar $y$ em função de $x$:

$$
y = \frac{-\left(- 2 y_{c_1}\right) \pm \sqrt{\left(- 2 y_{c_1}\right)^2 - 4\left(y_{c_1}^2  + \left(x - x_{c_1}\right)^2 - r_1^2\right)}}{2}
\\ \\
= y_{c_1} \pm \sqrt{r_1^2 - \left(x - x_{c_1}\right)^2}
$$

Com isso, podemos substituir $y$ na equação do segundo círculo:

$$
\left(x - x_{c_2}\right)^2 + \left(y_{c_1} \pm \sqrt{r_1^2 - \left(x - x_{c_1}\right)^2} - y_{c_2}\right)^2 - r_2^2 = 0
$$

Manipulando um pouco os termos:

$$
\left(x - x_{c_2}\right)^2 + \left(\pm \sqrt{r_1^2 - \left(x - x_{c_1}\right)^2} + \left(y_{c_1} - y_{c_2}\right)\right)^2 - r_2^2 =
\\
\left(x - x_{c_2}\right)^2 + (r_1^2 - \left(x - x_{c_1}\right)^2) + \left(y_{c_1} - y_{c_2}\right)^2 \pm \left(\sqrt{r_1^2 - \left(x - x_{c_1}\right)^2} \times \left(y_{c_1} - y_{c_2}\right)\right) - r_2^2 =
\\
\left(x - x_{c_2}\right)^2 - \left(x - x_{c_1}\right)^2 + r_1^2 - r_2^2 + \left(y_{c_1} - y_{c_2}\right)^2 \pm \left(\sqrt{r_1^2 - \left(x - x_{c_1}\right)^2} \times \left(y_{c_1} - y_{c_2}\right)\right) =
\\
\left(\left(x - x_{c_2}\right) - \left(x - x_{c_1}\right)\right)\times\left(\left(x - x_{c_2}\right) + \left(x - x_{c_1}\right)\right) + r_1^2 - r_2^2 + \left(y_{c_1} - y_{c_2}\right)^2 \pm \left(\sqrt{r_1^2 - \left(x - x_{c_1}\right)^2} \times \left(y_{c_1} - y_{c_2}\right)\right) =
\\
\left(x_{c_1} - x_{c_2}\right)\times\left(2x - x_{c_1} - x_{c_2}\right) + r_1^2 - r_2^2 + \left(y_{c_1} - y_{c_2}\right)^2 \pm \left(\sqrt{r_1^2 - \left(x - x_{c_1}\right)^2} \times \left(y_{c_1} - y_{c_2}\right)\right) =
$$


<!-- \left(\left(x - x_{c_2}\right) - \left(x - x_{c_1}\right))\times\left(\left(x - x_{c_2}\right) + \left(x - x_{c_1}\right)\right)  + r_1^2 - r_2^2 + \left(y_{c_1} - y_{c_2}\right)^2 \pm \left(\sqrt{r_1^2 - \left(x - x_{c_1}\right)^2} \times \left(y_{c_1} - y_{c_2}\right)\right) =
-->
{% endkatexmm %}
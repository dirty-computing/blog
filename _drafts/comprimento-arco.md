---
layout: post
title: "Calculando o comprimento de um barbante num rolo, the hard way"
author: "Jefferson Quesado"
tags: matemática integral
---

Esses dias, fui apresentado com a seguinte questão no Twitter: [https://twitter.com/pickover/status/1529582555359494144](https://twitter.com/pickover/status/1529582555359494144)

[![Imagem da descrição do problema, tanto com o texto quanto com a imagem do barbante ao redor do rolo](https://pbs.twimg.com/media/CDWqW9LWgAADZFi?format=jpg&name=small)](https://twitter.com/pickover/status/1529582555359494144)

Bem, vamos lá... Como calcular o comprimento desse barbante?

# O problema

Um basbante é colado de modo simestricamente perfeito ao redor de um cilindro. Esse barbante dá exatas quatro voltas da base do cilindro até o seu topo.
A circunferência do cilindro é 4cm e seu comprimento é 12cm. Qual o comprimento do cilindro?

# Estratégias de solução

Existem algumas possibilidades para resolver esse problema. Um deles, o jeito mais esperto,
é perceber que você pode "recortar" um lado do cilindro e planificar ele. Assim sendo,
obtém-se um retângulo de 12cm por 4cm, e o fio forma a cada 3cm uma inclinação reta completa em
cima do planificado, como se fossem 4 retângulos de 3cm por 4cm postos lado a lado e o barbante
seria a soma das diagonais desses 4 retângulos.

{% katexmm %}
Outro jeito de se fazer é usando comprimento de arco. Para isso, precisamos definir uma função
$\mathbb{R} \mapsto \mathbb{R}^3$ cujos pontos, para $t \in \left[0, 1\right]$, defina todas
as posições do barbante. Com essa função em mãos, podemos calcular o tamanho do arco variando
$\left(t, t'\right) = (t, t + \epsilon), \lim \epsilon = 0$.
{% endkatexmm %}

# Definindo a função "posição do barbante"

Essa função ela é de tal forma que:

{% katexmm %}
$$
pos(t) = (comp_x(t), comp_y(t), comp_z(t))
$$

Onde por definição do problema $comp_z$ é diretamente proporcional a $t$.

E também precisa ser definida em $t \in \left[0, 1\right]$. Porém, olha que bacana se eu pegar um
$v \equiv \frac{t}{12}$:

$$
pos(v) = (comp2_x(v), comp2_y(v), comp2_z(v))
$$

E olha que interessante... como $comp2_z(v)$ precisa ser diretamente proporcional a $v$
e crescer de modo linear, começando de 0 e indo até 12, como $v \equiv \frac{t}{12}$ então
a função precisa estar definida no intervalo $v \in \left[0, 12\right]$. Portanto,
$comp2_z(v) = v$. Claro, isso assumindo que o cilindro está com a base encontasndo no
plano $xy$ e que ele se estende na direção do eixo z.

Agora precisamos definir $comp2_x(v), comp2_y(v)$. O que sabemos sobre esses componentes?
Basicamente que eles formam círculos contínuos e conforma $v$ cresce o giro é sempre para
o mesmo lado. Assumindo que a origem das coordenadas $xy$ seja o centro do rolo cilíndrico,
teremos que $\left(comp2_x(\theta), comp2_y(\theta)\right) = (\cos(\theta)\times r, \sin(\theta)\times r)$.
Onde $r$ é o valor do raio.

Agora, falta converter de $v$ para $\theta$. Como são 4 voltas, em um total de 12cm,
então a cada variação de 3cm em $v$ temos que demos uma volta completa. Em outras palavras,
seja $to_\theta(v) \mapsto \theta$ a função que transforma $v$ em $\theta$:

$$
to_\theta(v) = \theta\\
to_\theta(v + 3) = \theta + 2\times\pi\\
$$

E quanto $v = 0$, temos que $to_\theta(v) = 0$ também. Portanto:

$$
to_\theta(v) = \frac{2}{3}\times\pi\times{v}
$$

Então temos que:

$$
pos(v) = \left\{
    \begin{array}{ll}
        \cos(\frac{2}{3}\times\pi\times{v})\times r & x\\
        \sin(\frac{2}{3}\times\pi\times{v})\times r & y\\
        v & z
    \end{array}
\right.
$$

## Qual o valor exato de $r$?

Temos que a circunferência do cilindro é de 4cm. Portanto, $circ = 2\times\pi\times r = 4$.
Ou seja:

$$
r = \frac{2}{\pi}
$$

## O que é o comprimento de arco?

Bem, peguemos uma função qualquer. Por exemplo:

$$
f(x) = x^2
$$

Quanto de tinta se gastaria cobrindo essa curva no intervalo de $x \in \left[1, 3\right]$.
Como calcular isso?

Para isso, precisamos definir os pontos que irá compor nosso arco. Por exemplo, ele começa em
$(1,1)$ e vai até $(3,9)$. Podemos transformar isso em uma função do "tempo" da caneta
percorrendo esse intervalo:

$$
pos_f(t) = (t, t^2)
$$

Se pegarmos $t'$, um infinitésimo depois de $t$, teremos então praticamente uma reta que vai
de $\overrightarrow{pos_f(t), pos_f(t')}$. Então, basicamente se conseguirmos pegar a soma de
todos os intervalos infinitesimais do começo até o final, então teremos calculado o comprimento
do arco nesse intervalo. Ou seja:

$$
\int^3_1 len(t)dt
$$

E como é definido o comprimento do segmento $\overrightarrow{pos_f(t), pos_f(t')}$? Bem,
basicamente, pitágoras, já que $t'$ é basicamente um infinitésimo depois de $t$, então
próximo o suficiente de ser um segmento de reta. O jeito de se calcular $pos_f(t)$ nós
já conhecemos, e para calcular $pos_f(t')$? Bem, isso vai dependenter do quanto a função
$pos_f$ varia de acordo com o seu argumento. Portanto, $pos_f(t') = pos_f(t) +
pos_f'(t)\times(t'-t)$, onde $pos_f'(t) = \frac{pos_f(t)}{dt}$ é a derivada de $pos_f(t)$.

Como se interessa a distância entre os pontos $pos_f(t), pos_f(t')$, podemos transladar
ambos os pontos de tal modo que $pos_f(t)$ seja coincidente com a origem.

> Demonstração dessa propriedade será feita em outro blog post.

{% endkatexmm %}
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
f(x) = \frac{2}{3}\sqrt{x^3}
$$

Quanto de tinta se gastaria cobrindo essa curva no intervalo de $x \in \left[4, 9\right]$.
Como calcular isso?

Para isso, precisamos definir os pontos que irá compor nosso arco. Por exemplo, ele começa em
$(4,5\frac{1}{3})$ e vai até $(9,18)$. Podemos transformar isso em uma função do "tempo" da caneta
percorrendo esse intervalo:

$$
pos_f(t) = (t, \frac{2}{3}\sqrt{t^3})
$$

Se pegarmos $t'$, um infinitésimo depois de $t$, teremos então praticamente uma reta que vai
de $\overrightarrow{pos_f(t), pos_f(t')}$. Então, basicamente se conseguirmos pegar a soma de
todos os intervalos infinitesimais do começo até o final, então teremos calculado o comprimento
do arco nesse intervalo. Ou seja:

$$
\int^9_4 len(t)dt
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

Nessa situação, $pos_f(t')$ após o translado vai coincidir com $pos_f'(t)\times(t'-t)$.
Como a ideia é pegar isto em um instante infinitesimal, podemos considerar que o
movimento do arco nesse infinitésimo de deslocamento foi uma reta infinitesimal.
Então, vai ser basicamente a magnitude $|pos_f'(t)\times(t'-t)|$, pitágoras como antes
mencionado.

Só recapitulando a função:

$$
pos_f(t) = (t, \frac{2}{3}\sqrt{t^3})
$$

Portanto, a derivada dela em $t$ será:

$$
pos_f'(t) = (1, \sqrt{t})
$$

Portanto, o tanto de arco criado no infinitésimo ao redor do tempo $t$ será de:

$$
|pos_f'(t)| = \sqrt{1^2 + (\sqrt{t})^2} =\\
\sqrt{1 + t}
$$

Como se deseja a integral dessa função de 4 até 9,

$$
\int^9_4 \sqrt{1 + t} dt = \left. \frac{2}{3}\left(\sqrt{1 + t}\right)^3\right|^9_4 =\\
\frac{2}{3} \left(10\sqrt{10} - 5\sqrt{5}\right) = \\
\frac{10}{3}\sqrt{5}\left(2\sqrt{2} - 1\right)
$$

Então, o comprimento do arco é isso. Em termos leigos pode ser entendimento com
o quanto se gasta de caneta para percorrer uma distância em uma função.

Aqui achamos o comprimento de uma função $\mathbb{R}\mapsto\mathbb{R}$. Porém,
como na verdade a função acaba codificando uma coordenada no plano cartesiano,
o que nos interessou foi o mapeamento $\mathbb{R}\mapsto\mathbb{R}^2$, onde a
primeira ordenada é $X$.

Nada impede de pegar este conceito e expandir, seja para um par ordenado onde
nenhuma das funções sejam exatamente $X$, seja para $\mathbb{R}^3$.

Então, para uma curva descrita pela função $\mathbb{R}\mapsto\mathbb{R}^3$:

$$
f(t) = \left\{
    \begin{array}{l}
        X(t)\\
        Y(t)\\
        Z(t)
    \end{array}
\right.
$$

O comprimento de arco dela entre os pontos $a$ e $b$ será de:

$$
arclen(a, b, f) = \int^b_a\sqrt{X'(t)^2+Y'(t)^2+Z'(t)^2}dt
$$

## Calculando o comprimento de arco do barbante

Temos a função que descreve a curva da bastante:

$$
pos(v) = \left\{
    \begin{array}{ll}
        \cos(\frac{2}{3}\times\pi\times{v})\times r & x\\
        \sin(\frac{2}{3}\times\pi\times{v})\times r & y\\
        v & z
    \end{array}
\right.
$$

A derivada em relação ao parâmetro $v$ é:

$$
pos'(v) = \left\{
    \begin{array}{ll}
        -\frac{2}{3}\times\pi\times\sin(\frac{2}{3}\times\pi\times{v})\times r & x\\
        \frac{2}{3}\times\pi\times\cos(\frac{2}{3}\times\pi\times{v})\times r & y\\
        1 & z
    \end{array}
\right.
$$

Aplicando o valor calculado de $r$:

$$
pos'(v) = \left\{
    \begin{array}{ll}
        -\frac{2}{3}\times\pi\times\sin(\frac{2}{3}\times\pi\times{v})\times \frac{2}{\pi} & x\\
        \frac{2}{3}\times\pi\times\cos(\frac{2}{3}\times\pi\times{v})\times \frac{2}{\pi} & y\\
        1 & z
    \end{array}
\right. \\= 
\left\{
    \begin{array}{ll}
        -\frac{4}{3}\times\sin(\frac{2}{3}\times\pi\times{v}) & x\\
        \frac{4}{3}\times\cos(\frac{2}{3}\times\pi\times{v}) & y\\
        1 & z
    \end{array}
\right.
$$

O comprimento de arco será:

$$
arclen(a, b, pos) =
    \int^b_a\sqrt{
        \left(-\frac{4}{3}\times\sin(\frac{2}{3}\times\pi\times{v})\right)^2 +
        \left(\frac{4}{3}\times\cos(\frac{2}{3}\times\pi\times{v})\right)^2 +
        1^2
    }dv\\
    = \int^b_a\sqrt{
        \frac{16}{9}\times\sin(\frac{2}{3}\times\pi\times{v})^2 +
        \frac{16}{9}\times\cos(\frac{2}{3}\times\pi\times{v})^2 +
        1
    }dv
$$

Usando o fato de que $\sin(\theta)^2 + \cos(\theta)^2 = 1$:

$$
arclen(a, b, pos) =
    \int^b_a\sqrt{
        \frac{16}{9} + 1
    }dv = \int^b_a\sqrt{
        \frac{25}{9}
    }dv = \int^b_a\frac{5}{3}dv = \left.v\times\frac{5}{3}\right|^a_b
$$

No nosso caso em específico, o valor inicial é 0 e o final é 12:

$$
arclen(0, 12, pos) = \left.v\times\frac{5}{3}\right|^{12}_0 = 12\times\frac{5}{3} - 0\times\frac{5}{3} \\
    = 20
$$

# Resumo

- Identifiquei uma função que representa as posições do barbante
- Fiz ajuste fino nessa função de tal modo que a ordenada no eixo Z
  em $F(v)$ fosse $v$
- Reduzi o problema para um problema de comprimento de arco
- Relembrei a fórmula para achar o comprimento de arco de uma função
  $\mathbb{R}\mapsto\mathbb{N}^n$
- Apliquei a fórmula de comprimento de arco na curva achada anteriormente
- Foi usada a identidade pitagórica que descreve que $\sin^2 x + \cos^2 x = 1$
  para deixar a integral mais simples
- Calculei a integral resultante, $\left.v\times\frac{5}{3}\right|^a_b$
- Dá 20

{% endkatexmm %}
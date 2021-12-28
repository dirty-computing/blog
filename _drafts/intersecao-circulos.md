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
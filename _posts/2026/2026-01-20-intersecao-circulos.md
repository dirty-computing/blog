---
layout: post
title: "Determinando interseção de circunferências"
author: "Jefferson Quesado"
tags: geometria geometria-analítica matemática python tartaruga
base-assets: "/assets/intersecao-circulos/"
---

> Baseado na minha resposta no StackOverflow em Português sobre este mesmo
> problema
> [https://pt.stackoverflow.com/a/260073/64969](https://pt.stackoverflow.com/a/260073/64969)

Dadas duas circunferências, elas se tocam em algum ponto?

Bem, existem algumas possibilidades para isso. Vamos considerar inicialmente
circunferências com raios distintos, estudar suas possibilidades, e então
passar a estudar com o mesmo raio.

# Circunferências de raios distintos

Vamos começar com elas concêntricas e ir andando aos pouquinhos a menor
circunferência pra direita?

{% assign sizes = "0 80 90 95 100 105 110 120" | split: " " %}
{% for off in sizes %}
  {% capture name %}noteqr-{{off}}.png{% endcapture %}
  ![Círculo pequeno no offset {{off}}, com raio 10, e círculo grande na origem com raio 100]({{ page.base-assets | append: name | relative_url }})
{% endfor %}

Aqui nós temos todos os casos que eu gostaria de mostrar, sem perder
generalidade.

Explicar eles aqui inicialmente:

1. concêntricos, não há nenhum toque
1. circunferência menor dentro da maior, mas sem toque
1. circunferência menor tangenciando a maior por dentro
1. circunferência menor cortando a maior, centro dentro da maior
1. circunferência menor cortando a maior, centro na circunferência maior
1. circunferência menor cortando a maior, centro externo
1. circunferência menor tangenciando a maior por fora
1. circunferência menor totalmente fora da maior, sem nenhum ponto de toque

Para o caso de circunferências de tamanhos distintos, temos esses 8 casos.
Variações em tamanho das circunferências não é importante, ainda assim todos
esses casos acontecem caso os raios sejam distintos.

## Por que não perco a generalidade?

{% katexmm %}
Bem, vamos começar com assuntos tangentes. Por que não perco a generalização
das posições relativas? Estou prendendo a circunferência maior a um único ponto
(a origem) e movendo a menor em uma única direção (eixo horizontal) a partir
também da origem. Aparentemente isso remove uma infinidade de possibilidades
para duas circunferências com raios $r1$ e $r2$

Se uma transformação $\nabla: SC_1 \mapsto SC_2$ que mantém o posicionamento
relativo de todos os seus pontos, então temos que todas as verdade que se
encontra para o sistema de coordenada 1 ($SC_1$) também vale para o sistema de
coordedas 2 ($SC_2$).

Assim, temos que

$\forall p,q \in SC_1 \mid |\overline{pq}| = |\overline{\nabla(p)\nabla(q)}|$

onde a operação $|\overline{X}|$ é a operação que calcula o tamanho do segmento
$\overline{X}$. Se a propriedade acima for mantida, então isso significa que
tudo que eu encontrar para um sistema de coordenadas $SC_1$ é perfeitamente
válido para o sistema de coordenadas $SC_2 = \nabla(SC_1)$. Vale ressaltar que
isso é transitivo, posso ter duas transformações desse tipo.

Aqui, as transformações que me interessam são:

1. translação
2. rotação
3. refexão

Uma operação $\nabla(x,y) = (x - c, y - d)$ mantém a propriedade de que as
distâncias relativas de todos os pontos são mantidas. A rotação, fornecida pela
matriz de rotação, também nos garante essa propriedade.

Logo, eu posso deslocar o centro da maior circunferência com uma operação de
translação. Se seu centro for $(C_x, C_y)$, a operação é
$\nabla_t(x, y) = (x - C_x, y - C_y)$. Ao aplicar no centro da circunferência,
ela irá para a origem. Essa operação só é necessário aplicar se
$(C_x, C_y) \not= (0, 0)$.

Depois, basta rotacionar o centro da menor circunferência de modo que ela fique
no lado positivo do eixo horizontal. A rotação só precisa ser aplicada se e
somente se $c'_y \not= 0$.

Essa rotação é "fácil" alcançar pois com o vetor $\overrightarrow{C'c'}$ temos
o valor da tangente. Para achar o ângulo, basta aplicar o
$\arctan(c'_y / c'_x)$ (já que o centro da circunferência maior $C'$ é a origem
nesse novo sistema de coordenadas). Se girarmos no ângulo contrário, teremos
que o centro da circunfência menor vai pro eixo horizontal:

$$
\nabla_r(p) = rot_{-\arctan(c'_y / c'_x)}(p) = p'
$$

Após aplicado isso, pode acontecer de o centro da circunferência menor estar no
lado negativo do eixo horizontal. Então, podemos refletir todos os pontos
usando o eixo vertical como base, usando a operação $\nabla_s(x, y) = (-x, y)$.
Isso só seria aplicado caso $c'_x < 0$.

Portanto, dado duas circunferências quaisquer de raios distintos em quaisquer
posições do plano cartesiano, só aplicar a seguinte transformação para ter a
circunferência maior na origem e a circunferência menor à sua direita:

$$
(\nabla_s \circ \nabla_r \circ \nabla_t)(x, y)
$$
{% endkatexmm %}

# Circunferências de mesmo raio

Para circunferências de mesmo raio existem menos casos. Começando da origem:

1. mesma circunferência
1. secantes
1. tangentes
1. não se tocam

Não ocorre o "sem toque, por dentro" nem o "tangente, por dentro".

# Fazendo as detecções

O primeiro passo é determinar se as circunferências tem o mesmo raio ou não. Se
elas tiverem o mesmo raio, só temos 4 categorias para elas.

## Mesmo raio

{% katexmm %}
Para serem a mesma circunferência, os dois centros devem ser o mesmo. Para tal,
$|\overline{c_1 c_2}| = 0$

Agora, se a distância entre os centros for entre 0 e duas vezes o raio (a soma
dos raios das duas circunferências), então elas são secantes.
$0 < |\overline{c_1 c_2}| < 2r$

Se for exatamentea soma dos raios, as circunferências de tangenciam.
$|\overline{c_1 c_2}| = 2r$

Se for maior do que a soma dos raios, então elas não se tocam.
$|\overline{c_1 c_2}| > 2r$

## Raios distintos

Vamos assumir aqui que o raio da circunferência maior é $R$ e o da menor é $r$.

Podemos pegar a lição apendida do caso de círculos de mesmo raio.

Se for maior do que a soma dos raios, então elas não se tocam.
$|\overline{c_1 c_2}| > R+r$

Se for exatamente igual a soma dos raios, então são tangentes
externas. $|\overline{c_1 c_2}| = R+r$

Agora, entre um pouco menor que a soma dos raios até o momento que vira
tangente interna, os círculos são secantes. Mas... quando será que eles são
tangentes internas uma a outra?

A resposta é simples: quando a distância entre os centros leva até pertinho da
circunferência grande, e você só precisa caminhar mais $r$ até chegar na
circunferência maior. Ou seja, a distância entre os centros mais o raio da
menor é o raio da maior.

Então, para serem tangentes internas, $|\overline{c_1 c_2}| + r = R$. Como
estamos anotando com base na distância entre os pontos, podemos isolar essa
variável e ficamos assim: $|\overline{c_1 c_2}| = R - r$

Ou seja, é secante no intervalo  $R + r > |\overline{c_1 c_2}| > R - r$

Para ser não secante interna, basta ter a distância entre os centros menor do
que a necessária para ser tangente. $R - r > |\overline{c_1 c_2}| \geq 0$

# Circunferências representada pelo centro e raio

Dadas duas circunferências, $C_1 = (x_1, y_1, r_1)$ e $C_2 = (x_2, y_2, r_2)$,
onde $r_i$ indica o raio e $(x_i, y_i)$ o centro da circunferência, como saber
a posição relativa entre elas?

Bem, vamos organizar de tal modo que $C_M$ e $C_m$ que $r_M \ge r_m$. Então,
peguemos a distância entre os centros:
$D = \sqrt{(x_M - x_m)^2 + (y_M - y_m)^2}$.

Caso $D \gt r_M + r_m$, então as circunferências são não secantes externas.

Caso $D = r_M + r_m$, então elas são tangentes externas. Em breve iremos achar
o ponto de tangência.

Agora, caso tenhamos $r_M + r_m \gt D \gt r_M - r_m$, então isso indica que as
circunferências são secantes. Note que isso é verdade independnete se elas tem
o mesmo raio ou se são raios distintos.

Agora, para casos além desses, precisamos ramificar em **mesmo raio** e
**raios distintos**.

No caso específico de mesmo raio, a única outra possibilidade restante é com
$D = r_m - r_m = 0$, onde as circunferências são sobrepostas uma na outra.

Para o caso de raios distintos, temos o cenário de $D = r_M - r_m$, tangente
interna.

E por fim, se $r_M - r_m \gt D \ge 0$, temos não secantes internas.

## Fórmula da circunferência

Em geometria analítica, ao descrever uma curva, temos uma função que só é
possível ter valores nela para os pontos da curva.

Por exemplo, temos uma notação para a
[curva do barbante]({% post_url 2022/2022-11-17-comprimento-arco %}). Mas para
esse caso específico aqui não precisamos de uma curva parametrizda (apesar de
ser possível e fácil), apenas um conjunto de ponto que satisfaçam uma condição.

No caso de um circunferência, os pontos são aqueles que estão a mesma distância
do centro. Então, pegue um ponto qualquer, $(x, y)$, basta que a distância dela
até o centro $(x_c, y_c)$ seja igual ao raio $r$. Daí temos que:

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

Para o caso de tangentes, tem um truque que podemos utilizar: o vetor entre os
centros de ambas as circunferências.

A interseção se situará na reta que liga os centros, então se for calculado o
vetor entre os dois centros e manipular a sua magnitude para o tamanho do raio
de uma das circunferências, então teremos que o ponto obtido por "somar" esse
vetor esticado ao centro da circunferência se encontrará na circunferência e
ele que será o ponto de interseção.

Tomemos $C_1$ como a circunferência base. Daí, o vetor entre os centros de
$C_1$ e $C_2$ será:

$$
V = (x_2 - x_1, y_2 - y_1) = (x_v, y_v)
$$

Com $(x_v, y_v)$ devidamente calculado, o módulo dele é
$|V| = \sqrt{x_v^2 + y_v^2}$. Podemos então transformar o vetor dessa magnitude
$|V|$ em um vetor unitário dividindo por $|V|$:

$$
U = (x_v / |V|, y_v / |V|) = (x_u, y_u)
$$

E então basta multiplicar pelo raio da circunferência que obteremos o vetor
adequado:

$$
V' = (x_u\times r_1, y_u\times r_1)
$$

Então, colocando o vetor em cima do centro obtemos o ponto de tangência:

$$
T = (x_1, y_1) + (x_u\times r_1, y_u\times r_1) =
  (x_1 + x_u\times r_1, y_1 + y_u\times r_1)
$$

## Secante

Para secante não conheço nenhuma estratégia interessante. Então, vamos achar um
ponto `(x, y)` que satisfaça ambas as condições para `C_1` e `C_2`?

Podemos resolver através de um sistema não linear:

$$
\left(x - x_{c_1}\right)^2 + \left(y - y_{c_1}\right)^2 - r_1^2 = 0\\
\left(x - x_{c_2}\right)^2 + \left(y - y_{c_2}\right)^2 - r_2^2 = 0
$$

Ou então achar em um sistema de coordenadas e fazer a transformação. A primeira
transformação seria para centralizar a circunferência 1 na origem, depois
rotacionar de modo que o $y_{c_2}$ seja 0, e por fim até mesmo pegar o "reflexo
de espelho"? Enfim após essas transformações eu tenho esse outro sistema não
linear:

$$
x'^2 + y'^2 - r_1^2 = 0\\
\left(x' - x'_{c_2}\right)^2 + y'^2 - r_2^2 = 0
$$

Trabalhando essa expressão:

$$
x'^2 + y'^2 = r_1^2\\
x'^2 - 2\times{}x'\times{}x'_{c_2} + x'^2_{c_2} + y'^2 - r_2^2 = 0
$$

Assim, podemos achar o valor de $x'$ substituindo $x'^2 + y'^2$:

$$
-2\times{}x'\times{}x'_{c_2} + x'^2_{c_2} + r_1^2 - r_2^2 = 0
$$

Ajeitando a equação:

$$
x'^2_{c_2} + r_1^2 - r_2^2 = 2\times{}x'\times{}x'_{c_2} \ \therefore\\
x' = \frac{x'^2_{c_2} + r_1^2 - r_2^2}{2\times{}x'_{c_2}}
$$

E com isso nós temos a ordenada $x'$ no sistema de coordenadas com as
transformações de rotação e translação para ficar tudo bonitinho.

> Ah, por que só tem um único $x'$ se posso ter dois pontos?

Basicamente porque o $x'$ vai ser único:

![Círculo pequeno no offset 105, com raio 10, e círculo grande na origem com raio 100]({{ page.base-assets | append: "noteqr-105.png" | relative_url }})

O que vai mudar é o $y'$!!! Então, vamos achar esse $y'$?

Vamos pegar a equação do círuclo de raio 1 de novo (por quê? Conveniência, ele
tá no centro do sistema de coordenadas):

$$
x'^2 + y'^2 = r_1^2
$$

Sabemos o valor de $x'$ para que ele pertença a interseção. Então, falta saber
os valores de $y'$. De modo geral, é bem tranquilo:

$$
y'^2 = r_1^2 - x'^2
$$

Sem segredos. Como temos que o raio é maior do que o $x'$, esse número será
positivo (caso contrário, caso seja igual, então o número é 0 e seria uma
tangente, ou se fosse menor isso seria uma não-secante, o que não tem mesmo
solução real). Como o sistema de coordenadas é perfeitamente ajustado, temos
que as soluções parfa $y'$ serão bem dizer um o espelho do outro: a mesma
magnitude, positiva e negativa. Então, a solução será:

$$
y' = \pm{}\sqrt{r_1^2 - x'^2}
$$

{% endkatexmm %}

# Fazendo os desenhos

Como foram feitos os desenhos dessas circunferências colocadas no começo do
post? Aqui usamos python e tartaruga!

> Sim, finalmente estou publicando o artigo mencionado em
> [Desenhando com Python e tartarugas]({% post_url 2021/2021-09-17-desenhos-python-turtle %}).

Para cá, precisei basicamente desenhar os eixos, desenhar um círculo centrado
na origem e desenhar um círculo mais afastado com o centro no eixo X, de uma
cor distinta. Por uma questão de representação do que eu precisava tirar a
foto, resolvi também capturar os desenhos em momentos específicos. Poderia usar
algo mais nativo que o `turtle` do python fornecesse para gerar um PNG?
Poderia. Mas nesse caso eu queria usar prints mesmo. Então para controlar o
_pacing_ das mudanças dos desenhos coloquei para ser disparado no click.

Então, bora lá, como que fazemos isso? Eu preciso passar para o `onclick` uma
lista de parâmetros que vão indicar como fazer o desenho. E também passar a
função de desenho em si!

Comecemos do básico:

```python
import turtle
sc = turtle.Screen()
t = turtle.Turtle()
t.shape('blank')

sc.mainloop()
```

Aqui criamos uma tartaruga sem formato (não faz diferença como ela aparece na
tela, melhor não aparecer), capturamos a tela e pedimos para ficar no
`mainloop`. Nada significativo.

Agora, vamos capturar cliques. Como indicado no
[Desenhando com Python e tartarugas]({% post_url 2021/2021-09-17-desenhos-python-turtle %}),
para o `onclick` precisamos passar uma função que receba como argumentos o x do
clique e o y do click. Algo como:

```python
def something(x, y):
  pass

import turtle
sc = turtle.Screen()
t = turtle.Turtle()
t.shape('blank')

sc.onclick(lambda x, y: something(x, y))

sc.mainloop()
```

Hmmm, mas o python permite um jeito mais esperto de passar uma função como
argumento, literalmente... passar a função como argumento! Sem precisar criar
uma lambda só pra ela! Afinal, para esse caso específico, a função é perfeita
para o meu fim:

```python
def something(x, y):
  pass

import turtle
sc = turtle.Screen()
t = turtle.Turtle()
t.shape('blank')

sc.onclick(something)

sc.mainloop()
```

Perfeito! Para o meu caso específico, preciso criar algo evolua com o tempo e
que eu consiga construir ele passando uma lista como argumento. Então, como
fazer isso? Bem, que tal começar com receber uma lista e retornar uma função?

```python
def generate(collection):
  def something(x, y):
    pass
  return something

import turtle
sc = turtle.Screen()
t = turtle.Turtle()
t.shape('blank')

sc.onclick(generate([0, 80, 90, 95, 100, 105, 110, 120]))

sc.mainloop()
```

Bem, pelo menos tô retornando a função `something` que não faz nada. Porém...
não é idiomático esperar que uma função mude de estado. Diria que causaria
menos espanto se fosse um objeto próprio. Vamos fazer um objeto que faça isso?

```python
class click_clicker:
  def __init__(self, collection):
    self.collection = collection
  
  def something(self, x, y):
    pass

def generate(collection):
  return click_clicker(collection).something

import turtle
sc = turtle.Screen()
t = turtle.Turtle()
t.shape('blank')

sc.onclick(generate([0, 80, 90, 95, 100, 105, 110, 120]))

sc.mainloop()
```

Hmmmm, eu posso resolver tudo no construtor e passar o método, né? O `generate`
ali como placeholder não se faz mais necessário. Aproveitar e... que tal
chamar de `accept_click`? Afinal, é isso que esse método faz:

```python
class click_clicker:
  def __init__(self, collection):
    self.collection = collection
  
  def accept_click(self, x, y):
    pass

import turtle
sc = turtle.Screen()
t = turtle.Turtle()
t.shape('blank')

sc.onclick(click_clicker([0, 80, 90, 95, 100, 105, 110, 120]).accept_click)

sc.mainloop()
```

Ok, temos um cara que aceita cliques, mas que ainda não faz nada. Tranquilo.
Vamos agora iterar até o fim? A cada clique, incremento em um o índice, até
chegar no fim da lista. E como detectar o fim da lista? Bem, um dos jeitos é
tentar o acesso direto e capturar o `IndexError`, que é disparado ao chamar um
vetor com um índice fora dos limites:

```python
class click_clicker:
  def __init__(self, collection):
    self.collection = collection
    self.idx = 0
  
  def accept_click(self, x, y):
    try:
      v = self.collection[self.idx]
      self.idx += 1
      print(v) # placeholder para desenho
    except IndexError:
      pass

import turtle
sc = turtle.Screen()
t = turtle.Turtle()
t.shape('blank')

sc.onclick(click_clicker([0, 80, 90, 95, 100, 105, 110, 120]).accept_click)

sc.mainloop()
```

Hmmm, ok, vai até o fim. Mas e depois? Eu preciso basicamente dar um `bye` na
screen. Então... por que não passamos a `sc` como argumento do `click_clicker`?

> Ah, mas o Jeff que eu conheço é todo do lado funcional, quem é esse aqui?

Aqui é o Jeff de 2026 continuando um conteúdo que o Jeff de 2021 começou, ok?
Eu gostava de funcional na época mas ainda não era muito versado! Então vou
honrar o eu do passado e manter o código do desenho! Enfim, voltando a passar
`sc` como argumento:

```python
class click_clicker:
  def __init__(self, collection, sc):
    self.collection = collection
    self.idx = 0
    self.sc = sc
  
  def accept_click(self, x, y):
    try:
      v = self.collection[self.idx]
      self.idx += 1
      print(v) # placeholder para desenho
    except IndexError:
      sc.bye()

import turtle
sc = turtle.Screen()
t = turtle.Turtle()
t.shape('blank')

sc.onclick(click_clicker([0, 80, 90, 95, 100, 105, 110, 120], sc).accept_click)

sc.mainloop()
```

Muito bem, clicamos o suficiente para chegar no final e fechar. Agora... que
tal passar a função de desenho? Podemos substituir o `print` lá por um
argumento!

```python
class click_clicker:
  def __init__(self, draw, collection, sc):
    self.collection = collection
    self.idx = 0
    self.draw = draw
    self.sc = sc
  
  def accept_click(self, x, y):
    try:
      v = self.collection[self.idx]
      self.idx += 1
      self.draw(v)
    except IndexError:
      sc.bye()

import turtle
sc = turtle.Screen()
t = turtle.Turtle()
t.shape('blank')

sc.onclick(click_clicker(lambda x: print(x), [0, 80, 90, 95, 100, 105, 110, 120], sc).accept_click)

sc.mainloop()
```

Hmmm, mas estou sentindo falta de algo pra função `draw`... Ah! Falta a
tartaruga em si! Pois vamos passar a tartaruga então! Mas... como que vou
passar a tartaruga em `accept_click`? Passando como argumento de construtor, é
lógico!

```python
class click_clicker:
  def __init__(self, draw, collection, t, sc):
    self.collection = collection
    self.idx = 0
    self.draw = draw
    self.t = t
    self.sc = sc
  
  def accept_click(self, x, y):
    try:
      v = self.collection[self.idx]
      self.idx += 1
      self.draw(self.t, v)
    except IndexError:
      sc.bye()

import turtle
sc = turtle.Screen()
t = turtle.Turtle()
t.shape('blank')

sc.onclick(click_clicker(lambda t, x: print(x), [0, 80, 90, 95, 100, 105, 110, 120], t, sc).accept_click)

sc.mainloop()
```

Beleza. Agora, eu quero sempre ter os eixos desenhados e começar de uma tela em
branco. Então, vamos garantir isso? Ah, aproveitando... eu não quero ver o
desenho, ele pode ser imediato. Aproveitar e colocar isso da velocidade da
tartaruga para instantâneo também:

```python
def eixos(t, sc):
  pass

class click_clicker:
  def __init__(self, draw, collection, t, sc):
    self.collection = collection
    self.idx = 0
    self.draw = draw
    self.t = t
    self.sc = sc
  
  def accept_click(self, x, y):
    try:
      v = self.collection[self.idx]
      self.idx += 1
      self.sc.reset()
      self.t.speed(0)
      eixos(self.t, self.sc)
      self.draw(self.t, v)
    except IndexError:
      sc.bye()

import turtle
sc = turtle.Screen()
t = turtle.Turtle()
t.shape('blank')

sc.onclick(click_clicker(lambda t, x: print(x), [0, 80, 90, 95, 100, 105, 110, 120], t, sc).accept_click)

sc.mainloop()
```

Hmmm, só não tá pintando nada... Vou aproveitar a ideia do
[Desenhando com Python e tartarugas]({% post_url 2021/2021-09-17-desenhos-python-turtle %})
para desenho dos eixos:

```python
def eixos(t, sc):
  def eixo(t, s):
    t.fd(s)
    t.back(s + s)
    t.fd(s)
  x, y = sc.screensize()
  eixo(t, x)
  t.left(90)
  eixo(t, y)
  t.right(90)

class click_clicker:
  def __init__(self, draw, collection, t, sc):
    self.collection = collection
    self.idx = 0
    self.draw = draw
    self.t = t
    self.sc = sc
  
  def accept_click(self, x, y):
    try:
      v = self.collection[self.idx]
      self.idx += 1
      self.sc.reset()
      self.t.speed(0)
      eixos(self.t, self.sc)
      self.draw(self.t, v)
    except IndexError:
      sc.bye()

import turtle
sc = turtle.Screen()
t = turtle.Turtle()
t.shape('blank')

sc.onclick(click_clicker(lambda t, x: print(x), [0, 80, 90, 95, 100, 105, 110, 120], t, sc).accept_click)

sc.mainloop()
```

Muito bem, agora só falta fazer o desenho! Vou desenhar dois círculos, de raios
distintos, um na origem e outro em outro ponto do eixo X. Então para isso eu
preciso:

- do raio do primeiro círculo
- do raio do segundo círculo
- do `x` do segundo círculo
- da tartaruga

Hmmm, dá pra por em uma função tranquila!

```python
def eixos(t, sc):
  def eixo(t, s):
    t.fd(s)
    t.back(s + s)
    t.fd(s)
  x, y = sc.screensize()
  eixo(t, x)
  t.left(90)
  eixo(t, y)
  t.right(90)

def circulos(t, r1, r2, c2 = 0):
  print(r1, r2, c2)

class click_clicker:
  def __init__(self, draw, collection, t, sc):
    self.collection = collection
    self.idx = 0
    self.draw = draw
    self.t = t
    self.sc = sc
  
  def accept_click(self, x, y):
    try:
      v = self.collection[self.idx]
      self.idx += 1
      self.sc.reset()
      self.t.speed(0)
      eixos(self.t, self.sc)
      self.draw(self.t, v)
    except IndexError:
      sc.bye()

import turtle
sc = turtle.Screen()
t = turtle.Turtle()
t.shape('blank')

sc.onclick(click_clicker(lambda t, x: circulos(t, 100, 10, x), [0, 80, 90, 95, 100, 105, 110, 120], t, sc).accept_click)

sc.mainloop()
```

Ok, vamos para o detalhe da função `circulos` agora... Todo o resto vai ser
mantido _as is_, então só vou passar a alterar essa função, ok?

Vamos fazer dois desenhos de círculos, então nesse momento vou... abstrair o
que é um círculo, tá?

```python
def circulos(t, r1, r2, c2 = 0):
  def circulo(t, r, c):
    pass
  circulo(t, r1, 0)
  circulo(t, r2, c2)
  print(f'imprimiu o círculo com deslocamento {c2}')
```

Ok, parece justo. Mas... repara uma coisinha... os dois círculos vão ter a
mesma cor? Que tal mudar a cor? E... se eu vou mudar a cor, eu preciso retornar
para a original.

```python
def circulos(t, r1, r2, c2 = 0):
  def circulo(t, r, c):
    pass
  circulo(t, r1, 0)
  old_color = t.pencolor()
  t.pencolor('red')
  circulo(t, r2, c2)
  t.pencolor(old_color)
  print(f'imprimiu o círculo com deslocamento {c2}')
```

Ok, se eu souber desenhar um círculo com centro em `c` e raio `r` usando a
tartaruga `r`, tudo funciona!

Bem, vamos agora desenhar o círculo... Relembrando do artigo

```python
t.penup()
t.circle(10)
```

![Desenhando um círculo com tartaruga]({{ "/assets/desenhos-python-turtle/" | append: "circle-dry-run.gif" | relative_url }})

Ele pega de onde está e faz um círculo com o raio informado no sentido
anti-horário. Para desenhar com centro no eixo X, preciso primeiro virar 90
graus pro lado. E pro lado esquerdo. E não basta isso... preciso também antes
deslocar a tartaruga. Para o desenho centrado na origem, primeiro eu preciso
andar o raio do círculo:

```python
t.penup() # levanta para não escrever nada sem querer
t.fd(r)
t.left(90)
t.pendown() # agora baixa porque a intenção é escrever
t.circle(r)
```

Ok, tudo certo? Mas ou menos... agora eu preciso retornar a tartaruga para o
estado anterior:

```python
t.penup() # levanta para não escrever nada sem querer
t.fd(r)
t.left(90)
t.pendown() # agora baixa porque a intenção é escrever
t.circle(r)

t.penup()
t.right(90) # desfaz a rotação
t.back(r) # desfaz o translado do raio
t.pendown()
```

Hmmm, agora só falta levar em consideração o centro do círculo...

```python
t.penup() # levanta para não escrever nada sem querer
t.fd(r + c)
t.left(90)
t.pendown() # agora baixa porque a intenção é escrever
t.circle(r)

t.penup()
t.right(90) # desfaz a rotação
t.back(r + c) # desfaz o translado do raio
t.pendown()
```

E assim fica a função afinal:

```python
def circulos(t, r1, r2, c2 = 0):
  def circulo(t, r, c):
    # considerando a tartaruga na origem
    t.penup()
    t.fd(r + c)
    t.pendown()
    t.left(90)
    t.circle(r)
    t.right(90)
    t.penup()
    t.back(r+c)
    t.pendown()
  circulo(t, r1, 0)
  old_color = t.pencolor()
  t.pencolor('red')
  circulo(t, r2, c2)
  t.pencolor(old_color)
  print(f'imprimiu o círculo com deslocamento {c2}')
```

# Mas e cálculo programático das interseções?

Bora lá então? Primeiro, vamos determinar o tipo de interseção entre dois
círculos. Então, em cima disso, podemos ter os pontos em si.

Para criar uma enumeração no Python, podemos
[extender de `enum`](https://docs.python.org/3/library/enum.html):

```python
from enum import Enum

class TiposIntersecao(Enum):
  IGUAIS = 0
  NAO_SECANTES_INTERNAS = 1
  TANGENTE_INTERNA = 2
  SECANTE = 3
  TANGENTE_EXTERNA = 4
  NAO_SECANTE = 5
```

> Ah, mas não eram 8 casos?

Então, "concêntrico sem toques" e "circunferência menor dentro da maior, sem
toques" são ambos casos de "não secantes internas". Além disso, esses casos são
simplesmente "secantes":

- circunferência menor cortando a maior, centro dentro da maior
- circunferência menor cortando a maior, centro na circunferência maior
- circunferência menor cortando a maior, centro externo

Para o caso de "mesmo tamanho", só dá para ter os seguintes casos:

- IGUAIS
- SECANTE
- TANGENTE_EXTERNA
- NAO_SECANTE

Show! Agora, vamos representar os círculos? Bora lá:

```python
class Circulo:
  def __init__(self, centro, raio):
    self.centro = centro
    self.raio = raio
```

Ok, agora precisamos representar o `ponto`:

```python
class Ponto:
  def __init__(self, x, y):
    self.x = x
    self.y = y
```

Hmmm, mas isso pode ser incoveniente... Porque para o caso de circunferências
secantes o cálculo foi feito em cima de um sistema de coordenadas. Então, vamos
passar para o ponto o sistema de coordenadas que ele se encontra?

```python
class Ponto:
  def __init__(self, x, y, sc):
    self.x = x
    self.y = y
    self.sc = sc
```

Hmmm, mas não é conveniente eu _sempre_ passar o sistema de coordenadas, vale a
pena ter um sistema de coordenada canônico (centrada no origem) que é usado
como padrão. Vamos trabalhar um pouquinho mais o sistema de coordenadas?

O sistema de coordenadas bem dizer precisa de 3 coisas:

- uma função que pega o ponto no sistema canônico e transforma para o novo
  sistema
- uma função inversa, que pega o ponto no sistema atual e transforma no
  canônico

Além disso, eu posso acumular transformações: posso aplicar primeira uma
transformação de translado, para depois uma de rotação, para depois uma
transformação especular. E essas transformações tem ordem específica para ser
aplicada: se no meu sistema de coordenadas estou primeiro fazendo translado e
depois fazendo a rotação, na hora de pegar a função inversa primeiro eu preciso
desfazer a rotação e depois desfazer o translado.

Com isso em mente, bora lá! Eu tenho o sistema de coordenadas canônico, que a
função de transformação e a inversa são a função identidade:

```python
class SistemaCoordenadas:
  def __init__(self, f, f_inv):
    self.f = f
    self.f_inv = f_inv

ID = lambda p: (p.x, p.y)
SC_CANON = SistemaCoordenadas(ID, ID)
```

Beleza, aparentemente é isso. Agora, o sistema de coordenadas pode se apropriar
de um ponto, ele cria um "novo ponto", porém no novo sistema de coordenadas. E
também preciso "canonizar" de volta o ponto, aplicar a inversa. Vou chamar
essas operações de `transforma_coordenadas` e `invert`:

```python
class SistemaCoordenadas:
  def __init__(self, f, f_inv):
    self.f = f
    self.f_inv = f_inv

  def invert(self, ponto):
    (x, y) = self.f_inv(ponto)
    return Ponto(x, y, SC_CANON)

  def transforma_coordenadas(self, ponto):
    (x, y) = self.f(ponto.canon())
    return Ponto(x, y, self)
```

E, bem, fazemos a transformação em cima do ponto canônico porque é o correto,
isso permite, por exemplo, que eu faça
`sc_10_10 = SC_CANON.translado_x(10).translado_y(10)` e que o ponto `(0,0)`
nesse sistema de coordenadas seja o `(10,10)` no canônico. Eu combino um
sistema de coordenadas em cima do anterior. Mas... bem, o como fazer essas
transformações fica pra depois.

Agora, posso pegar a representação canônica do ponto, né? Vamos lá? Basicamente
eu peço para que o sistema de coordenadas me dê as informações do ponto em
relação ao sistema canônico (ou seja, aplicar o inverso). No ponto, isso seria
`canon`.

Mas, por que eu precisaria do canon do ponto? Bem, agora é para depuração.
Vamos lá? Botar isso para poder imprimir o ponto:

```python
class Ponto:
  def __init__(self, x, y, sc = SC_CANON):
    self.x = x
    self.y = y
    self.sc = sc

  def __str__(self):
    canon = self.canon()
    return str({
        "x": canon.x,
        "y": canon.y,
        "canon?": self.sc == SC_CANON
    })

  def canon(self):
    return self.sc.invert(self)
```

Bom saber se o ponto está usando coordenadas canônicas, né?

E, para informações de debug do círculo? Bora lá:

```python
class Circulo:
  def __init__(self, centro, raio):
    self.centro = centro
    self.raio = raio

  def __str__(self):
    return str({
        "centro": str(self.centro),
        "raio": str(self.raio)
    })
```

Se eu quiser mudar o sistema de coordenadas do círculo, eu posso simplesmente
alterar o sistema de coordenadas do ponto do centro dele. Bem, sabe o que eu
posso fazer com círculos e sistemas de coordenadas? Verificar se está
desenhando corretamente!

Bem, vamos adaptar a função que faz os desenhos. Para começar, que quero agora
receber dois círculos arbitrários, não mais x do centro dos círculos 1 e 2 e o
raio do segundo.

Portanto, a assinatura da função de desenho já vai mudar. Vamos receber a
tartaruga e dois círculos:

```python
def circulos(t, c1, c2):
  pass
```

Abstraindo a função que desenha um círculo unitariamente, o resto da função
`circulos` fica bem dizer igualzinha:

```python
def circulos(t, c1, c2):
  def circulo(t, circulo):
    pass
  circulo(t, c1)
  print(f'imprimiu o círculo {c1}')
  old_color = t.pencolor()
  t.pencolor('red')
  circulo(t, c2)
  t.pencolor(old_color)
  print(f'imprimiu o círculo {c2}')
```

As únicas diferenças foram a assinatura de `circulo` em si e que o deslocamento
é o centro do círculo... mas, já que agora estou passando círculos em si, e
eles são devidamente imprimíveis, posso imprimir eles diretamente, né?

Ok, agora vamos adaptar a questão do centro que agora não é apenas o `x`, mas
também tem o `y`. Como no desenho em si eu preciso pegar das coordenadas
canônicas, vou pegar `c.centro.canon()` e operar em cima disso. Então, os
passos para o desenho vão ser:

- levantar pena
- compensar pelo deslocamento do centro no eixo x
- compensar pelo deslocamento do centro no eixo y
- deslocar o tamanho do raio
- baixar pena
- virar pra esquerda
- mandar imprimir o círculo com tamanho do raio
- desvirar
- levantar pena
- descontar o deslocamento do tamanho do raio
- descontar o deslocamento do eixo y
- descontar o deslocamento do eixo x

Ah, eu errei algumas vezes até acertar corretamente o desenho! Para depurar o
desenho, eu deixar a tartaruga com a forma padrão (removi o `t.shape('blank')`)
e também deixei ela com velocidade padrão (removi o `self.t.speed(0)` do
`accept_click`).

Ficou assim no final, após algumas iterações vendo alguns bugs:

```python
def circulos(t, c1, c2):
  def circulo(t, c):
    # considerando a tartaruga na origem
    centro_canone = c.centro.canon()
    (cx, cy) = (centro_canone.x, centro_canone.y)
    r = c.raio
    t.penup()

    # desloca o centro
    t.fd(cx)
    t.left(90)
    t.fd(cy)
    t.right(90)

    # desloca o raio para desenhar
    t.fd(r)

    t.pendown()
    t.left(90)
    t.circle(r)
    t.right(90)

    t.penup()
    # compensa o raio
    t.back(r)
    # compensa o centro
    t.back(cx)
    t.left(90)
    t.back(cy)
    t.right(90)

    t.pendown()
  circulo(t, c1)
  print(f'imprimiu o círculo {c1}')
  old_color = t.pencolor()
  t.pencolor('red')
  circulo(t, c2)
  t.pencolor(old_color)
  print(f'imprimiu o círculo {c2}')
```

Agora eu tenho os círculos em si e posso ver no desenho se estão no lugar
adequado. Todo o resto fica mais fácil agora.

Mas agora eu preciso adaptar o lambda que passo para o `accept_click`. Vou
passar a informar círculos:

```python
sc.onclick(click_clicker(
  lambda t, x: circulos(
    t,
    Circulo(Ponto(0, 0), 100),
    Circulo(Ponto(x, 0), 10)
  ), [0, 80, 90, 95, 100, 105, 110, 120], t, sc).accept_click)
```

## Transformação de coordenadas: translados

Vamos fazer os translados!

As transformações são operações diretas no sistema de coordenadas. A função de
transformação e a função de transformação inversa operam em cima de um objeto
que tenha dois campos: `p.x` e `p.y`. Por conta de uma... falha... de design
nas primeiras implementações, ele retorna uma tupla com dois valores: `(x, y)`.

Bem, como eu consigo fazer para pegar a saída de uma transformação e passar
para outra? Eu posso criar um objeto que tenha o `x` e `y`. Mas... não fiquei
contente com isso. Então, que tal criar um objeto no Python que aceite campos
arbitrários? Algo para usar como `placeholder`?

Felizmente alguém já teve essa dúvida e encontrei algumas respostas de como
fazer isso:

- [https://stackoverflow.com/a/52089152/4438007](https://stackoverflow.com/a/52089152/4438007)
- [https://stackoverflow.com/a/42816745/4438007](https://stackoverflow.com/a/42816745/4438007)

Então eu posso criar um `placeholder` do jeito indicado, e usar das mais
diversas maneiras, como por exemplo:


```python
def placeholder(**kwargs):
  # https://stackoverflow.com/a/52089152/4438007
  # https://stackoverflow.com/a/42816745/4438007
  return type("", (), kwargs)

p = placeholder()
p.x = 3
p.y = 1
p.x # 3
p.y # 1

p1 = placeholder(x = 10, y = 15)
p1.x # 10
p1.y # 15
```

Ok, agora vamos fazer o translado em X! Se eu quiser fazer um translado
adicionando 10 no x, então o ponto `(0, 0)` desse sistema de coordenadas
equivale ao `(10, 0)` no sistema canônico. Portanto, ao pedir o ponto com
coordenada `x = -10` nesse sistema de coordenadas, a posição dele deveria ser
a origem no sistema de coordenadas canônico. Em outras palavras:

```python
print(Ponto(-10, 0, SC_CANON.translado_x(10)))
```

Deveria imprimir

```python
{'x': 0, 'y': 0, 'canon?': False}
```

A função de transformação de um sistema de coordenadas seria aplicar a
transformação base, e depois alterar o `x` com o delta correto, algo como:

```python
def novo_f(p):
  (x, y) = self.f(p)
  return (x - delta_x, y)
```

A função inversa? Bem, essa primeiro eu preciso aplicar o contrário da
transformação e só depois aplicar a inversa do sistema base, e aqui entra
o `placeholder` para passar o `x,y` para a transformação base:

```python
def novo_f_inv(p):
  (x, y) = (p.x, p.y)
  x = x + delta_x
  p = placeholder(x = x, y = y)

  return self.f_inv(p)
```

De modo geral, fica assim:

```python
class SistemaCoordenadas:
  # ... coisas anteriores
  def translado_x(self, delta_x):
    def novo_f(p):
      (x, y) = self.f(p)
      return (x - delta_x, y)
    def novo_f_inv(p):
      (x, y) = (p.x, p.y)
      x = x + delta_x
      p = placeholder(x = x, y = y)
      
      return self.f_inv(p)
    return SistemaCoordenadas(novo_f, novo_f_inv)
```

Para o `translado_y` é bem semelhante, mexendo apenas nas coordenadas do `y` no
caso:

```python
class SistemaCoordenadas:
  # ... coisas anteriores
  def translado_x(self, delta_x):
    def novo_f(p):
      (x, y) = self.f(p)
      return (x - delta_x, y)
    def novo_f_inv(p):
      (x, y) = (p.x, p.y)
      x = x + delta_x
      p = placeholder(x = x, y = y)
      
      return self.f_inv(p)
    return SistemaCoordenadas(novo_f, novo_f_inv)

  def translado_y(self, delta_y):
    def novo_f(p):
      (x, y) = self.f(p)
      return (x, y - delta_y)
    def novo_f_inv(p):
      (x, y) = (p.x, p.y)
      y = y + delta_y
      p = placeholder(x = x, y = y)
      
      return self.f_inv(p)
    return SistemaCoordenadas(novo_f, novo_f_inv)
```

Ok, isso faz sentido na teoria, e na prática? Como posso ver isso? Bem, podemos
brincar com os círculos gerados no `accept_click`! Em vez de passar em sistemas
de coordenadas canônicos, podemos passar em sistemas de coordenadas enviesados,
e compensar isso no seu centro. Por exemplo:

```python
sc.onclick(click_clicker(
    lambda t, x: circulos(
        t,
        Circulo(Ponto(-50, 15, SC_CANON.translado_x(50).translado_y(-15)), 100),
        Circulo(Ponto(x + 15, -30, SC_CANON.translado_x(-15).translado_y(30)), 10)
    ),
    [0, 80, 90, 95, 100, 105, 110, 120], t, sc).accept_click)
```

E, bem, está mostrando de maneira adequada. Pode colocar o código, fazer
variações e testar!

## Transformação de coordenadas: rotação

Para fazer transformação de rotação, vou pegar diretamente da definição de
[matriz de rotação](https://en.wikipedia.org/wiki/Rotation_matrix):

{% katexmm %}

$$
P' = \left[\begin{array}{cc}
\cos{\theta} & -\sin{\theta} \\
\sin{\theta} & \cos{\theta}
\end{array}\right] P
$$

E a operação reversa? Basicamente girar no ângulo contrário:

$$
P' = \left[\begin{array}{cc}
\cos{-\theta} & -\sin{-\theta} \\
\sin{-\theta} & \cos{-\theta}
\end{array}\right] P
$$

{% endkatexmm %}

Então, como ficaria? O ponto `(1,0)`, ao aplicar a rotação de 90º, vai ser
visto como o ponto `(0,1)`. Ou seja, no código seria algo como
`Ponto(0, 1, SC_CANON.rotate(90))`, a representação canônica dele seria
`(1, 0)`.

Podemos, tal qual a transformação de translação, criar o método de rotação. É
mais simples pedir na rotação o ângulo em graus e converter internamente em
radianos:

```py
class SistemaCoordenadas:
  # ...
  def rotate(self, angle_degrees):
    angle_radians = angle_degrees*math.pi/180.0
    def novo_f(p):
      (x, y) = self.f(p)
      rot = (
        x*math.cos(angle_radians) - y*math.sin(angle_radians),
        x*math.sin(angle_radians) + y*math.cos(angle_radians)
      )
      return rot
    def novo_f_inv(p):
      (x, y) = (p.x, p.y)
      p = placeholder(
        x = x*math.cos(-angle_radians) - y*math.sin(-angle_radians),
        y = x*math.sin(-angle_radians) + y*math.cos(-angle_radians)
      )
      return self.f_inv(p)
    return SistemaCoordenadas(novo_f, novo_f_inv)
```

Porém, vai ter situações que eu vou saber o ângulo em radianos (por exmeplo,
ao aplicar `math.atan2` para pegar o ângulo entre os centros). Então vamos
criar a função que roda em radianos? E a "rotação por graus" chama a rotação
por radianos:

```py
class SistemaCoordenadas:
  # ...
  def rotate(self, angle_degrees):
    angle_radians = angle_degrees*math.pi/180.0
    return self.rotate_radians(angle_radians)

  def rotate_radians(self, angle_radians):
    def novo_f(p):
      (x, y) = self.f(p)
      rot = (
        x*math.cos(angle_radians) - y*math.sin(angle_radians),
        x*math.sin(angle_radians) + y*math.cos(angle_radians)
      )
      return rot
    def novo_f_inv(p):
      (x, y) = (p.x, p.y)
      p = placeholder(
        x = x*math.cos(-angle_radians) - y*math.sin(-angle_radians),
        y = x*math.sin(-angle_radians) + y*math.cos(-angle_radians)
      )
      return self.f_inv(p)
    return SistemaCoordenadas(novo_f, novo_f_inv)
```

> Ah, quer saber mais sobre a transformação de graus para randianos ou o que é
> o `atan2` citado acima?
> [Usando Java moderno para fazer aritmética de Peano]({% post_url 2025/2025-03-10-peano-java-moderno %})

## Transformação de coordenadas: espelhamento

Basicamente, mudo o sinal do X:

```py
class SistemaCoordenadas:
  # ...
  def espelho(self):
    def novo_f(p):
      (x, y) = self.f(p)
      return (-x, y)
    def novo_f_inv(p):
      (x, y) = (p.x, p.y)
      p = placeholder(x = -x, y = y)
      return self.f_inv(p)
    return SistemaCoordenadas(novo_f, novo_f_inv)
```

## Determinando os tipos de interseção

Sabemos manusear corretamente os sistemas de coordenadas. Fazer isso ajuda
bastante na hora de resolver o caso das secantes. Mas, com esse ferramental em
mãos, vamos agora saber se iremos precisar disso?

Vamos lá, dividir tal qual foi feito no começo do artigo: primeiro decidir com
base em raios iguais, depois com base em raios distintos.

Então, vamos lá?

```python
def tipo_encontro(c1, c2):
  def mesmo_raio(c1, c2):
    pass
  def raios_distintos(c1, c2):
    pass

  if (c1.raio == c2.raio):
    return mesmo_raio(c1, c2)
  else:
    return raios_distintos(c1, c2)
```

Colocando as funções de `mesmo_raio` e `raios_distintos` como sendo parte da
função `tipo_encontro` porque em tese não faz sentido chamar em casos
arbitrários.

Certo, pois vamos lá. Primeiro, começando a lidar com o caso de "mesmo raio".
Temos 4 casos para isso, e para determinar eu preciso dos dois centros e da
distância entre eles:

```py
def mesmo_raio(c1, c2):
  centro_canon1 = c1.centro.canon()
  centro_canon2 = c2.centro.canon()
  pass
```

Se por acaso for o mesmo centro, então são a mesma circunferência:

```py
def mesmo_raio(c1, c2):
  centro_canon1 = c1.centro.canon()
  centro_canon2 = c2.centro.canon()
  if centro_canon1.x == centro_canon2.x and centro_canon1.y == centro_canon2.y:
      return TiposIntersecao.IGUAIS
  pass
```

Depois disso, preciso da distância e relembrar o que achamos no começo:

Secantes:

{% katexmm %}
$$
0 < |\overline{c_1 c_2}| < 2r
$$

Tangente:

$$
|\overline{c_1 c_2}| = 2r
$$

Não-secantes:

$$
|\overline{c_1 c_2}| > 2r
$$
{% endkatexmm %}

O caso 0 (coincidentes/mesma circunferência) já foi tratado. Eu posso também
calcular com `c1.raio + c2.raio` o `2r`. Fiz assim:

```py
def mesmo_raio(c1, c2):
  centro_canon1 = c1.centro.canon()
  centro_canon2 = c2.centro.canon()
  if centro_canon1.x == centro_canon2.x and centro_canon1.y == centro_canon2.y:
      return TiposIntersecao.IGUAIS
  dist = math.sqrt((centro_canon2.x - centro_canon1.x)**2 + (centro_canon2.y - centro_canon1.y)**2)
  if dist > c1.raio + c2.raio:
      return TiposIntersecao.NAO_SECANTE
  if dist == c1.raio + c2.raio:
      return TiposIntersecao.TANGENTE_EXTERNA

  return TiposIntersecao.SECANTE
```

Ok, e para raios distintos? Continuo pegando os dois centros, só que agora vale
a pena já calcular a distância. No caso de tangente interna, a distância entre
os raios precisa ser exatamente o raio maior menos o raio menor. Ou o absoluto
da diferença. Entre 0 e esse valor, é não secantes. Entre tangete interna e
tangente externa, secante. Além disso, é não secante:

```py
def raios_distintos(c1, c2):
  centro_canon1 = c1.centro.canon()
  centro_canon2 = c2.centro.canon()

  dist = math.sqrt((centro_canon2.x - centro_canon1.x)**2 + (centro_canon2.y - centro_canon1.y)**2)
  if dist > c1.raio + c2.raio:
      return TiposIntersecao.NAO_SECANTE
  if dist == c1.raio + c2.raio:
      return TiposIntersecao.TANGENTE_EXTERNA
  delta_raio = abs(c1.raio - c2.raio)
  if dist > delta_raio:
      return TiposIntersecao.SECANTE
  if dist == delta_raio:
      return TiposIntersecao.TANGENTE_INTERNA

  return TiposIntersecao.NAO_SECANTE
```

## Determinando os pontos

Vamos lá. Para os casos de `IGUAIS` e `NAO_SECANTE`, vou retornar uma tupla
vazia. Para tangentes, apenas um único ponto. Junto do ponto, vou retornar
também o tipo do encontro, para que quem for ler o resultado saiba o que
esperar.

De modo geral, o retorno vai ser algo nesse formato:

```
retorno = [ TipoIntersecao, [...Ponto]? ]
```

Especificamente:

```
retorno = [ IGUAIS | NAO_SECANTE ] |
          [ TANGENTE_INTERNA | TANGENTE_EXTERNA, [Ponto] ] |
          [ SECANTE, [ Ponto, Ponto ] ]
```

Poderia dar um retorno mais estruturado? Sim, mas não vem ao caso. Foi
intencional esse retorno com baixa estrutura, não quero elevar esse retorno a
uma espécie de "cidadão de primeira classe".

Para os casos triviais:

```py
def intersecao(c1, c2):
  tipo = tipo_encontro(c1, c2)
  if tipo in (TiposIntersecao.NAO_SECANTE, TiposIntersecao.IGUAIS):
    return (tipo,)
  pass
```

Note que a ideia era retornar uma tupla para que o acesso fosse mais uniforme.
O python, ao tentar retornar apenas `(tipo)`, entende que esse parêntese é um
operador de precedência, então `(tipo)` é funcionalmente equivalente a `tipo`.
Para evitar isso e para que ele identifique que é uma tupla unária, se faz
necessário colocar vírgula: `(tipo,)`. Esse foi um ponto de frustração forte
enquanto fazia o código.

Para o caso de tangente, vou seguir a fórmula: pegar o vetor apontando de um
centro para o outro e estender ele até o raio. Só preciso prestar atenção em
uma coisinha! Necessariamente o raio que vou seguir é o maior. Por que isso?
Porque se por acaso eu selecionar o menor raio, para tangentes internas, sair
do centro da menor circunferência rumo ao da maior circunferência vai bater no
ponto diametralmente oposto. Se eu pegar sempre da maior circunferência para a
menor, não há casos especiais:

```py
def intersecao(c1, c2):
  tipo = tipo_encontro(c1, c2)
  if tipo in (TiposIntersecao.NAO_SECANTE, TiposIntersecao.IGUAIS):
    return (tipo,)
  if tipo in (TiposIntersecao.TANGENTE_EXTERNA, TiposIntersecao.TANGENTE_INTERNA):
    if (c1.raio < c2.raio):
      c1, c2 = c2, c1
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()
    diff = placeholder(x = centro2.x - centro1.x, y = centro2.y - centro1.y)
    diff_mag = math.sqrt(diff.x**2 + diff.y**2)
    return (tipo, (Ponto((diff.x*c1.raio)/diff_mag + centro1.x, (diff.y*c1.raio)/diff_mag + centro1.y),))
  pass
```

> Note que a segunda tupla eu também fiz
> `(Ponto((diff.x*c1.raio)/diff_mag + centro1.x, (diff.y*c1.raio)/diff_mag + centro1.y),)`
> com essa vírgula no final para que o parêntese não fosse interpretado como
> operador de precedência.

Ok, agora o caso das secantes... Esse caso é bem especial, porque simplesmente
eu encontrei a resposta para o caso em que ambas as circunferências estão sobre
o eixo x, sendo que uma delas na origem. Partindo desse caso específico, eu
posso fazer as contas:

```py
def intersecao(c1, c2):
  tipo = tipo_encontro(c1, c2)
  if tipo in (TiposIntersecao.NAO_SECANTE, TiposIntersecao.IGUAIS):
    return (tipo,)
  if tipo in (TiposIntersecao.TANGENTE_EXTERNA, TiposIntersecao.TANGENTE_INTERNA):
    if (c1.raio < c2.raio):
      c1, c2 = c2, c1
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()
    diff = placeholder(x = centro2.x - centro1.x, y = centro2.y - centro1.y)
    diff_mag = math.sqrt(diff.x**2 + diff.y**2)
    return (tipo, (Ponto((diff.x*c1.raio)/diff_mag + centro1.x, (diff.y*c1.raio)/diff_mag + centro1.y),))
  if tipo == TiposIntersecao.SECANTE:
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()
    # assume centro1 na origem; assume centro2 com y = 0
    x_ponto = (centro2.x**2 + c1.raio**2 - c2.raio**2)/(2*centro2.x)
    y_ponto = math.sqrt(c1.raio**2 - x_ponto**2)
    return (tipo, (Ponto(x_ponto, y_ponto), Ponto(x_ponto, -y_ponto)))
```

Essa é apenas a aplicação direta da fórmula encontrada na
[seção sobre secantes](#secante). Mas sabe uma coisa que foi feita no começo da
modelagem dos pontos? Que eles estariam em sistemas de coordenadas. Sabe o que
vou fazer? Vou aplicar diversas transformações de sistemas de coordenadas até
satisfazer as condições de que `centro1` na origem e que `centro2` esteja sobre
o eixo x. De modo geral, o final vai ser quase o mesmo... mas agora eu preciso
indicar que os pontos foram encontrados no sistema de coordenadas alterado:

```py
def intersecao(c1, c2):
  tipo = tipo_encontro(c1, c2)
  if tipo in (TiposIntersecao.NAO_SECANTE, TiposIntersecao.IGUAIS):
    return (tipo,)
  if tipo in (TiposIntersecao.TANGENTE_EXTERNA, TiposIntersecao.TANGENTE_INTERNA):
    if (c1.raio < c2.raio):
      c1, c2 = c2, c1
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()
    diff = placeholder(x = centro2.x - centro1.x, y = centro2.y - centro1.y)
    diff_mag = math.sqrt(diff.x**2 + diff.y**2)
    return (tipo, (Ponto((diff.x*c1.raio)/diff_mag + centro1.x, (diff.y*c1.raio)/diff_mag + centro1.y),))
  if tipo == TiposIntersecao.SECANTE:
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()

    # magia com sistemas de coordenadas
    x_ponto = (centro2.x**2 + c1.raio**2 - c2.raio**2)/(2*centro2.x)
    y_ponto = math.sqrt(c1.raio**2 - x_ponto**2)
    return (tipo, (Ponto(x_ponto, y_ponto, centro2.sc), Ponto(x_ponto, -y_ponto, centro2.sc)))
```

Muito bom. Vamos agora lidar com as transformações adequadas? Não existe
nenhuma ordem mandatória em que elas precisam ser aplicadas, eu apenas acho que
a seguinte ordem é mais intuitiva:

- compensa o `x` do centro 1 estar fora do eixo y com um translado em x
- compensa o `y` do centro 1 estar fora do eixo x com um translado em y
- compensa o `y` do centro 2 estar fora do eixo x com uma rotação

Após os dois primeiros passos, eu tenho que o centro 1 estará na origem do novo
sistema de coordenadas. E após a rotação, o centro 2 vai estar respousando
exatamente no eixo x, e como é rotação o centro 1 vai se manter no mesmo canto.

E como fazer isso? Bem, vamos passo a passo:

```py
def intersecao(c1, c2):
  tipo = tipo_encontro(c1, c2)
  if tipo in (TiposIntersecao.NAO_SECANTE, TiposIntersecao.IGUAIS):
    return (tipo,)
  if tipo in (TiposIntersecao.TANGENTE_EXTERNA, TiposIntersecao.TANGENTE_INTERNA):
    if (c1.raio < c2.raio):
      c1, c2 = c2, c1
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()
    diff = placeholder(x = centro2.x - centro1.x, y = centro2.y - centro1.y)
    diff_mag = math.sqrt(diff.x**2 + diff.y**2)
    return (tipo, (Ponto((diff.x*c1.raio)/diff_mag + centro1.x, (diff.y*c1.raio)/diff_mag + centro1.y),))
  if tipo == TiposIntersecao.SECANTE:
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()

    if centro1.x != 0:
      compensa_x = # alguma magia para compensar o x
      centro1 = compensa_x.transforma_coordenadas(centro1)
      centro2 = compensa_x.transforma_coordenadas(centro2)
    if centro1.y != 0:
      compensa_y = # alguma magia para compensar o y
      centro1 = compensa_y.transforma_coordenadas(centro1)
      centro2 = compensa_y.transforma_coordenadas(centro2)
    if centro1.y != centro2.y:
      # compensa rotação
      angulo = # magia para achar o angulo
      compensa_rotacao = # magia para compensar o angulo
      centro1 = compensa_rotacao.transforma_coordenadas(centro1)
      centro2 = compensa_rotacao.transforma_coordenadas(centro2)

    x_ponto = (centro2.x**2 + c1.raio**2 - c2.raio**2)/(2*centro2.x)
    y_ponto = math.sqrt(c1.raio**2 - x_ponto**2)
    return (tipo, (Ponto(x_ponto, y_ponto, centro2.sc), Ponto(x_ponto, -y_ponto, centro2.sc)))
```

E aqui o nosso sistema de coordenadas recebe um ponto e "adota" ele! Usando o
`transforma_coordenada`! Como os sistemas de coordenadas precisam ser
companesados um em cima do outro, vou sempre partir de `centro1.sc` para fazer
as transformações de coordenadas. No caso de compensar o translado no eixo x,
basta chamar a função `translado_x` do próprio sistema de coordenadas. De modo
similar ao translado no eixo y:

```py
def intersecao(c1, c2):
  tipo = tipo_encontro(c1, c2)
  if tipo in (TiposIntersecao.NAO_SECANTE, TiposIntersecao.IGUAIS):
    return (tipo,)
  if tipo in (TiposIntersecao.TANGENTE_EXTERNA, TiposIntersecao.TANGENTE_INTERNA):
    if (c1.raio < c2.raio):
      c1, c2 = c2, c1
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()
    diff = placeholder(x = centro2.x - centro1.x, y = centro2.y - centro1.y)
    diff_mag = math.sqrt(diff.x**2 + diff.y**2)
    return (tipo, (Ponto((diff.x*c1.raio)/diff_mag + centro1.x, (diff.y*c1.raio)/diff_mag + centro1.y),))
  if tipo == TiposIntersecao.SECANTE:
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()

    if centro1.x != 0:
      compensa_x = centro1.sc.translado_x(centro1.x)
      centro1 = compensa_x.transforma_coordenadas(centro1)
      centro2 = compensa_x.transforma_coordenadas(centro2)
    if centro1.y != 0:
      compensa_y = centro1.sc.translado_y(centro1.y)
      centro1 = compensa_y.transforma_coordenadas(centro1)
      centro2 = compensa_y.transforma_coordenadas(centro2)
    if centro1.y != centro2.y:
      # compensa rotação
      angulo = # magia para achar o angulo
      compensa_rotacao = centro1.sc...# magia para compensar o angulo
      centro1 = compensa_rotacao.transforma_coordenadas(centro1)
      centro2 = compensa_rotacao.transforma_coordenadas(centro2)

    x_ponto = (centro2.x**2 + c1.raio**2 - c2.raio**2)/(2*centro2.x)
    y_ponto = math.sqrt(c1.raio**2 - x_ponto**2)
    return (tipo, (Ponto(x_ponto, y_ponto, centro2.sc), Ponto(x_ponto, -y_ponto, centro2.sc)))
```

Ok, agora eu preciso rotacionar. E, temos também uma transformação para isso! E
digo mais! Se achar o valor em radianos, só rotacionar em radianos! Façamos
isso:

```py
def intersecao(c1, c2):
  tipo = tipo_encontro(c1, c2)
  if tipo in (TiposIntersecao.NAO_SECANTE, TiposIntersecao.IGUAIS):
    return (tipo,)
  if tipo in (TiposIntersecao.TANGENTE_EXTERNA, TiposIntersecao.TANGENTE_INTERNA):
    if (c1.raio < c2.raio):
      c1, c2 = c2, c1
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()
    diff = placeholder(x = centro2.x - centro1.x, y = centro2.y - centro1.y)
    diff_mag = math.sqrt(diff.x**2 + diff.y**2)
    return (tipo, (Ponto((diff.x*c1.raio)/diff_mag + centro1.x, (diff.y*c1.raio)/diff_mag + centro1.y),))
  if tipo == TiposIntersecao.SECANTE:
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()

    if centro1.x != 0:
      compensa_x = centro1.sc.translado_x(centro1.x)
      centro1 = compensa_x.transforma_coordenadas(centro1)
      centro2 = compensa_x.transforma_coordenadas(centro2)
    if centro1.y != 0:
      compensa_y = centro1.sc.translado_y(centro1.y)
      centro1 = compensa_y.transforma_coordenadas(centro1)
      centro2 = compensa_y.transforma_coordenadas(centro2)
    if centro1.y != centro2.y:
      # compensa rotação
      angulo = # magia para achar o ângulo
      compensa_rotacao = centro1.sc.rotate_radians(-angulo)
      centro1 = compensa_rotacao.transforma_coordenadas(centro1)
      centro2 = compensa_rotacao.transforma_coordenadas(centro2)

    x_ponto = (centro2.x**2 + c1.raio**2 - c2.raio**2)/(2*centro2.x)
    y_ponto = math.sqrt(c1.raio**2 - x_ponto**2)
    return (tipo, (Ponto(x_ponto, y_ponto, centro2.sc), Ponto(x_ponto, -y_ponto, centro2.sc)))
```

Agora só falta achar o ângulo... mas, lembra que eu já mencionei o `atan2`?
Então, ele serve para basicamente dado dois lados de um triângulo retângulo
achar essa abertura!

```py
def intersecao(c1, c2):
  tipo = tipo_encontro(c1, c2)
  if tipo in (TiposIntersecao.NAO_SECANTE, TiposIntersecao.IGUAIS):
    return (tipo,)
  if tipo in (TiposIntersecao.TANGENTE_EXTERNA, TiposIntersecao.TANGENTE_INTERNA):
    if (c1.raio < c2.raio):
      c1, c2 = c2, c1
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()
    diff = placeholder(x = centro2.x - centro1.x, y = centro2.y - centro1.y)
    diff_mag = math.sqrt(diff.x**2 + diff.y**2)
    return (tipo, (Ponto((diff.x*c1.raio)/diff_mag + centro1.x, (diff.y*c1.raio)/diff_mag + centro1.y),))
  if tipo == TiposIntersecao.SECANTE:
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()

    if centro1.x != 0:
      compensa_x = centro1.sc.translado_x(centro1.x)
      centro1 = compensa_x.transforma_coordenadas(centro1)
      centro2 = compensa_x.transforma_coordenadas(centro2)
    if centro1.y != 0:
      compensa_y = centro1.sc.translado_y(centro1.y)
      centro1 = compensa_y.transforma_coordenadas(centro1)
      centro2 = compensa_y.transforma_coordenadas(centro2)
    if centro1.y != centro2.y:
      # compensa rotação
      angulo = math.atan2(centro2.y - centro1.y, centro2.x - centro1.x)
      compensa_rotacao = centro1.sc.rotate_radians(-angulo)
      centro1 = compensa_rotacao.transforma_coordenadas(centro1)
      centro2 = compensa_rotacao.transforma_coordenadas(centro2)

    x_ponto = (centro2.x**2 + c1.raio**2 - c2.raio**2)/(2*centro2.x)
    y_ponto = math.sqrt(c1.raio**2 - x_ponto**2)
    return (tipo, (Ponto(x_ponto, y_ponto, centro2.sc), Ponto(x_ponto, -y_ponto, centro2.sc)))
```

E é isso! Acabamos de determinar programaticamente os pontos de interseção
entre duas circunferências!

Ah, quer saber qual o ponto exato? Bem, podemos pegar as coordenadas com
referência ao sistema de coordenadas canônico e pronto. O próprio `Ponto` tem
uma função que faz isso. E foi com esse intento que o sistema de coordenadas
tem a opção tanto de aplicar a transformação como também de fazer o inverso
dessa mesma transformação.

## Desenhando a interseção

Para os casos triviais, não há o que desenhar. Fim de jogo. Mas... e para
secantes e tangentes?

Vamos desenhar a secante primeiro? Porque a secange eu já tenho dois pontos, e
isso permite facilmente fazer a tartaruga pintar o espaço desejado. Lembra a
função `circulos` que a gente desenhava os círculos? Vamos continuar dela:


```py
def circulos(t, c1, c2):
  def circulo(t, c):
    # considerando a tartaruga na origem
    centro_canone = c.centro.canon()
    (cx, cy) = (centro_canone.x, centro_canone.y)
    r = c.raio
    t.penup()

    # desloca o centro
    t.fd(cx)
    t.left(90)
    t.fd(cy)
    t.right(90)

    # desloca o raio para desenhar
    t.fd(r)

    t.pendown()
    t.left(90)
    t.circle(r)
    t.right(90)

    t.penup()
    # compensa o raio
    t.back(r)
    # compensa o centro
    t.back(cx)
    t.left(90)
    t.back(cy)
    t.right(90)

    t.pendown()
  circulo(t, c1)
  print(f'imprimiu o círculo {c1}')
  old_color = t.pencolor()
  t.pencolor('red')
  circulo(t, c2)
  t.pencolor(old_color)
  print(f'imprimiu o círculo {c2}')
  i = intersecao(c2, c1)
  if i[0] in (TiposIntersecao.TANGENTE_INTERNA, TiposIntersecao.TANGENTE_EXTERNA):
    # marca a tangente
    pass
  elif i[0] == TiposIntersecao.SECANTE:
    # marca a secante
    pass
  t.pencolor(old_color)
```

Bem, vou ser bem preguiçoso aqui no desenho: vou colocar a tartaruga na posição
adequada e depois mando um `goto` para o outro ponto. E em seguida em retorno a
tartaruga para a posiçãom original:

```py
def circulos(t, c1, c2):
  def circulo(t, c):
    # considerando a tartaruga na origem
    centro_canone = c.centro.canon()
    (cx, cy) = (centro_canone.x, centro_canone.y)
    r = c.raio
    t.penup()

    # desloca o centro
    t.fd(cx)
    t.left(90)
    t.fd(cy)
    t.right(90)

    # desloca o raio para desenhar
    t.fd(r)

    t.pendown()
    t.left(90)
    t.circle(r)
    t.right(90)

    t.penup()
    # compensa o raio
    t.back(r)
    # compensa o centro
    t.back(cx)
    t.left(90)
    t.back(cy)
    t.right(90)

    t.pendown()
  circulo(t, c1)
  print(f'imprimiu o círculo {c1}')
  old_color = t.pencolor()
  t.pencolor('red')
  circulo(t, c2)
  t.pencolor(old_color)
  print(f'imprimiu o círculo {c2}')
  i = intersecao(c2, c1)
  if i[0] in (TiposIntersecao.TANGENTE_INTERNA, TiposIntersecao.TANGENTE_EXTERNA):
    # marca a tangente
    pass
  elif i[0] == TiposIntersecao.SECANTE:
    t.pencolor('pink')
    old_p = t.pos()
    t.penup()
    p1 = i[1][0].canon()
    t.fd(p1.x)
    t.left(90)
    t.fd(p1.y)
    t.right(90)
    t.pendown()
    p2 = i[1][1].canon()
    t.setpos(p2.x, p2.y)
    t.teleport(*old_p)
  t.pencolor(old_color)
```

Note que aqui estou recebendo a posição da tartaruga quando faço
`old_p = t.pos()`. Essa posição é uma tupla com as coordenadas da tartaruga, e
no `teleport` eu preciso passar as duas coordenadas corretamente. Então, para
isso, eu uso o _spread operator_: `t.teleport(*old_p)`. Hmmm, isso me deu uma
ideia, e se a função de `circulos` recebesse um número arbitrário de círculos?

Eu posso fazer essa ideia. E defino que o primeiro elemento é especial nesse
quesito, que ele vai ser a base que vou comparar os demais. De modo geral, a
função passa a ter um argumento variádico com `*args`. Para desenhar os muitos
círculos, a ideia é basicamente a mesma que foi usada com `c1` e `c2`, mas
agora usando iterações explícitas. E também preciso aqui me preparar para lidar
com as cores! No lugar de simplesmente ir para vermelho e fim, bom ciclar em
algumas opções:

```py
def circulos(t, *circulos):
  def circulo(t, c):
    # considerando a tartaruga na origem
    centro_canone = c.centro.canon()
    (cx, cy) = (centro_canone.x, centro_canone.y)
    r = c.raio
    t.penup()

    # desloca o centro
    t.fd(cx)
    t.left(90)
    t.fd(cy)
    t.right(90)

    # desloca o raio para desenhar
    t.fd(r)

    t.pendown()
    t.left(90)
    t.circle(r)
    t.right(90)

    t.penup()
    # compensa o raio
    t.back(r)
    # compensa o centro
    t.back(cx)
    t.left(90)
    t.back(cy)
    t.right(90)

    t.pendown()
  cores = ( 'black', 'red', 'green', 'blue', 'orange' )
  i = 0
  old_color = t.pencolor()
  for c in circulos:
    cor = cores[i]
    t.pencolor(cor)
    i = (i + 1) % len(cores)
    circulo(t, c)
    print(f'imprimiu o círculo {c}')
  t.pencolor(old_color)
```

Ok, e para usar? Bem, é tranquilo, só chamar a função `circulos` com quantos
argumentos desejar. Por exemplo:

```py
sc.onclick(click_clicker(
    lambda t, x: circulos(
        t,
        Circulo(Ponto(0, 0), 250),
        Circulo(Ponto(x*2.5, 0), 25),
        Circulo(Ponto(x*2.5, 0, SC_CANON.rotate(-45)), 25),
        Circulo(Ponto(x*2.5, 0, SC_CANON.espelho().rotate(-45)), 25),
        Circulo(Ponto(x*2.5, 0, SC_CANON.rotate(-45).espelho()), 25),
        Circulo(Ponto(x*2.5, 0, SC_CANON.espelho().rotate(-45).espelho()), 25)
    ),
    [0, 80, 90, 95, 100, 105, 110, 120], t, sc).accept_click)
```

Ok, vamos voltar a desenhar os pontos de encontro? No caso, vou fixar
`c1 = circulos[0]`, por convenção. Agora preciso iterar no slice que contém
todos os outros elementos, exceto o primeiro. O python fornece um operador que
gera o slice desejado:

```py
def circulos(t, *circulos):
  def circulo(t, c):
    # considerando a tartaruga na origem
    centro_canone = c.centro.canon()
    (cx, cy) = (centro_canone.x, centro_canone.y)
    r = c.raio
    t.penup()

    # desloca o centro
    t.fd(cx)
    t.left(90)
    t.fd(cy)
    t.right(90)

    # desloca o raio para desenhar
    t.fd(r)

    t.pendown()
    t.left(90)
    t.circle(r)
    t.right(90)

    t.penup()
    # compensa o raio
    t.back(r)
    # compensa o centro
    t.back(cx)
    t.left(90)
    t.back(cy)
    t.right(90)

    t.pendown()
  cores = ( 'black', 'red', 'green', 'blue', 'orange' )
  i = 0
  old_color = t.pencolor()
  for c in circulos:
    cor = cores[i]
    t.pencolor(cor)
    i = (i + 1) % len(cores)
    circulo(t, c)
    print(f'imprimiu o círculo {c}')

  c1 = circulos[0]
  for c2 in circulos[1 : len(circulos)]:
    pass
  t.pencolor(old_color)
```

E, bem, o resto continua igual, né? Detectar o tipo de interseção e tudo o
mais. Inclusive nomeei as variáveis de modo a favorecer retornar o código
anterior aqui:

```py
def circulos(t, *circulos):
  def circulo(t, c):
    # considerando a tartaruga na origem
    centro_canone = c.centro.canon()
    (cx, cy) = (centro_canone.x, centro_canone.y)
    r = c.raio
    t.penup()

    # desloca o centro
    t.fd(cx)
    t.left(90)
    t.fd(cy)
    t.right(90)

    # desloca o raio para desenhar
    t.fd(r)

    t.pendown()
    t.left(90)
    t.circle(r)
    t.right(90)

    t.penup()
    # compensa o raio
    t.back(r)
    # compensa o centro
    t.back(cx)
    t.left(90)
    t.back(cy)
    t.right(90)

    t.pendown()
  cores = ( 'black', 'red', 'green', 'blue', 'orange' )
  i = 0
  old_color = t.pencolor()
  for c in circulos:
    cor = cores[i]
    t.pencolor(cor)
    i = (i + 1) % len(cores)
    circulo(t, c)
    print(f'imprimiu o círculo {c}')

  c1 = circulos[0]
  for c2 in circulos[1 : len(circulos)]:
    i = intersecao(c2, c1)
    if i[0] in (TiposIntersecao.TANGENTE_INTERNA, TiposIntersecao.TANGENTE_EXTERNA):
      # marca a tangente
      pass
    elif i[0] == TiposIntersecao.SECANTE:
      t.pencolor('pink')
      old_p = t.pos()
      t.penup()
      p1 = i[1][0].canon()
      t.fd(p1.x)
      t.left(90)
      t.fd(p1.y)
      t.right(90)
      t.pendown()
      p2 = i[1][1].canon()
      t.setpos(p2.x, p2.y)
      t.teleport(*old_p)
  t.pencolor(old_color)
```

Ok, e para marcar a tangente? Bem, eu fix um `X` em cima do ponto. Basicamente,
vai para o ponto, vira 45º, vai para frente e para traz, então gira 90º. Faz
esse processo um total de 4 vezes. Compensa a rotação 45º e pronto, volta à
posição anterior:

```py
def circulos(t, *circulos):
  def circulo(t, c):
    # considerando a tartaruga na origem
    centro_canone = c.centro.canon()
    (cx, cy) = (centro_canone.x, centro_canone.y)
    r = c.raio
    t.penup()

    # desloca o centro
    t.fd(cx)
    t.left(90)
    t.fd(cy)
    t.right(90)

    # desloca o raio para desenhar
    t.fd(r)

    t.pendown()
    t.left(90)
    t.circle(r)
    t.right(90)

    t.penup()
    # compensa o raio
    t.back(r)
    # compensa o centro
    t.back(cx)
    t.left(90)
    t.back(cy)
    t.right(90)

    t.pendown()
  cores = ( 'black', 'red', 'green', 'blue', 'orange' )
  i = 0
  old_color = t.pencolor()
  for c in circulos:
    cor = cores[i]
    t.pencolor(cor)
    i = (i + 1) % len(cores)
    circulo(t, c)
    print(f'imprimiu o círculo {c}')

  c1 = circulos[0]
  for c2 in circulos[1 : len(circulos)]:
    i = intersecao(c2, c1)
    if i[0] in (TiposIntersecao.TANGENTE_INTERNA, TiposIntersecao.TANGENTE_EXTERNA):
      t.pencolor('pink')
      old_p = t.pos()
      t.penup()
      p1 = i[1][0].canon()
      t.fd(p1.x)
      t.left(90)
      t.fd(p1.y)
      t.right(90)
      t.pendown()
      t.left(45)
      for a in range(4):
        t.fd(20)
        t.back(20)
        t.left(90)
      t.left(-45)
      t.penup()
      t.teleport(*old_p)
    elif i[0] == TiposIntersecao.SECANTE:
      t.pencolor('pink')
      old_p = t.pos()
      t.penup()
      p1 = i[1][0].canon()
      t.fd(p1.x)
      t.left(90)
      t.fd(p1.y)
      t.right(90)
      t.pendown()
      p2 = i[1][1].canon()
      t.setpos(p2.x, p2.y)
      t.teleport(*old_p)
  t.pencolor(old_color)
```

## Ambiente para visualizar

Encontrei esse projeto bem bacana:

[https://pythonandturtle.com/turtle/](https://pythonandturtle.com/turtle/)

Ele permite justamente lidar com o desenho de tartaruga usando Python. Nem
todas as opções estão disponíveis, como por exemplo o objeto `Screen` (e
portanto a sensibilidade aos cliques).

Mas de modo geral com pouca adaptação do código você consegue rodar no site
"python and turtle". Segue abaixo um pequeno teste já com essas correções:

```py
# Turtle script example
t = turtle.Turtle('turtle')

import math

def placeholder(**kwargs):
  # https://stackoverflow.com/a/52089152/4438007
  # https://stackoverflow.com/a/42816745/4438007
  return type("", (), kwargs)


class SistemaCoordenadas:
  def __init__(self, f, f_inv):
    self.f = f
    self.f_inv = f_inv

  def invert(self, ponto):
    (x, y) = self.f_inv(ponto)
    return Ponto(x, y, SC_CANON)

  def transforma_coordenadas(self, ponto):
    (x, y) = self.f(ponto.canon())
    return Ponto(x, y, self)

  def translado_x(self, delta_x):
    def novo_f(p):
      (x, y) = self.f(p)
      return (x - delta_x, y)
    def novo_f_inv(p):
      (x, y) = (p.x, p.y)
      x = x + delta_x
      p = placeholder(x = x, y = y)
      
      return self.f_inv(p)
    return SistemaCoordenadas(novo_f, novo_f_inv)

  def translado_y(self, delta_y):
    def novo_f(p):
      (x, y) = self.f(p)
      return (x, y - delta_y)
    def novo_f_inv(p):
      (x, y) = (p.x, p.y)
      y = y + delta_y
      p = placeholder(x = x, y = y)

      return self.f_inv(p)
    return SistemaCoordenadas(novo_f, novo_f_inv)

  def rotate(self, angle_degrees):
    angle_radians = angle_degrees*math.pi/180.0
    return self.rotate_radians(angle_radians)

  def rotate_radians(self, angle_radians):
    def novo_f(p):
      (x, y) = self.f(p)
      rot = (
        x*math.cos(angle_radians) - y*math.sin(angle_radians),
        x*math.sin(angle_radians) + y*math.cos(angle_radians)
      )
      return rot
    def novo_f_inv(p):
      (x, y) = (p.x, p.y)
      p = placeholder(
        x = x*math.cos(-angle_radians) - y*math.sin(-angle_radians),
        y = x*math.sin(-angle_radians) + y*math.cos(-angle_radians)
      )
      return self.f_inv(p)
    return SistemaCoordenadas(novo_f, novo_f_inv)
  
  def espelho(self):
    def novo_f(p):
      (x, y) = self.f(p)
      return (-x, y)
    def novo_f_inv(p):
      (x, y) = (p.x, p.y)
      p = placeholder(x = -x, y = y)
      return self.f_inv(p)
    return SistemaCoordenadas(novo_f, novo_f_inv)

ID = lambda p: (p.x, p.y)
SC_CANON = SistemaCoordenadas(ID, ID)

class Ponto:
  def __init__(self, x, y, sc = SC_CANON):
    self.x = x
    self.y = y
    self.sc = sc

  def __str__(self):
    canon = self.canon()
    return str({
        "x": canon.x,
        "y": canon.y,
        "canon?": self.sc == SC_CANON
    })

  def canon(self):
    return self.sc.invert(self)

class Circulo:
  def __init__(self, centro, raio):
    self.centro = centro
    self.raio = raio

  def __str__(self):
    return str({
        "centro": str(self.centro),
        "raio": str(self.raio)
    })

class TiposIntersecao:
  IGUAIS = 0
  NAO_SECANTES_INTERNAS = 1
  TANGENTE_INTERNA = 2
  SECANTE = 3
  TANGENTE_EXTERNA = 4
  NAO_SECANTE = 5

def tipo_encontro(c1, c2):
  def mesmo_raio(c1, c2):
    centro_canon1 = c1.centro.canon()
    centro_canon2 = c2.centro.canon()
    if centro_canon1.x == centro_canon2.x and centro_canon1.y == centro_canon2.y:
        return TiposIntersecao.IGUAIS
    dist = math.sqrt((centro_canon2.x - centro_canon1.x)**2 + (centro_canon2.y - centro_canon1.y)**2)
    if dist > c1.raio + c2.raio:
        return TiposIntersecao.NAO_SECANTE
    if dist == c1.raio + c2.raio:
        return TiposIntersecao.TANGENTE_EXTERNA

    return TiposIntersecao.SECANTE

  def raios_distintos(c1, c2):
    centro_canon1 = c1.centro.canon()
    centro_canon2 = c2.centro.canon()

    dist = math.sqrt((centro_canon2.x - centro_canon1.x)**2 + (centro_canon2.y - centro_canon1.y)**2)
    if dist > c1.raio + c2.raio:
        return TiposIntersecao.NAO_SECANTE
    if dist == c1.raio + c2.raio:
        return TiposIntersecao.TANGENTE_EXTERNA
    delta_raio = abs(c1.raio - c2.raio)
    if dist > delta_raio:
        return TiposIntersecao.SECANTE
    if dist == delta_raio:
        return TiposIntersecao.TANGENTE_INTERNA

    return TiposIntersecao.NAO_SECANTE

  if (c1.raio == c2.raio):
    return mesmo_raio(c1, c2)
  else:
    return raios_distintos(c1, c2)

def intersecao(c1, c2):
  tipo = tipo_encontro(c1, c2)
  if tipo in (TiposIntersecao.NAO_SECANTE, TiposIntersecao.IGUAIS):
    return (tipo,)
  if tipo in (TiposIntersecao.TANGENTE_EXTERNA, TiposIntersecao.TANGENTE_INTERNA):
    if (c1.raio < c2.raio):
      c1, c2 = c2, c1
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()
    diff = placeholder(x = centro2.x - centro1.x, y = centro2.y - centro1.y)
    diff_mag = math.sqrt(diff.x**2 + diff.y**2)
    return (tipo, (Ponto((diff.x*c1.raio)/diff_mag + centro1.x, (diff.y*c1.raio)/diff_mag + centro1.y),))
  if tipo == TiposIntersecao.SECANTE:
    centro1 = c1.centro.canon()
    centro2 = c2.centro.canon()

    if centro1.x != 0:
      compensa_x = centro1.sc.translado_x(centro1.x)
      centro1 = compensa_x.transforma_coordenadas(centro1)
      centro2 = compensa_x.transforma_coordenadas(centro2)
    if centro1.y != 0:
      compensa_y = centro1.sc.translado_y(centro1.y)
      centro1 = compensa_y.transforma_coordenadas(centro1)
      centro2 = compensa_y.transforma_coordenadas(centro2)
    if centro1.y != centro2.y:
      # compensa rotação
      angulo = math.atan2(centro2.y - centro1.y, centro2.x - centro1.x)
      compensa_rotacao = centro1.sc.rotate_radians(-angulo)
      centro1 = compensa_rotacao.transforma_coordenadas(centro1)
      centro2 = compensa_rotacao.transforma_coordenadas(centro2)

    x_ponto = (centro2.x**2 + c1.raio**2 - c2.raio**2)/(2*centro2.x)
    y_ponto = math.sqrt(c1.raio**2 - x_ponto**2)
    return (tipo, (Ponto(x_ponto, y_ponto, centro2.sc), Ponto(x_ponto, -y_ponto, centro2.sc)))


def eixos(t):
  def eixo(t, s):
    t.fd(s)
    t.back(s + s)
    t.fd(s)
  x, y = 200, 200
  eixo(t, x)
  t.left(90)
  eixo(t, y)
  t.right(90)


t.speed(9)
eixos(t)

def circulos(t, *circulos):
  def circulo(t, c):
    # considerando a tartaruga na origem
    centro_canone = c.centro.canon()
    #centro_canone = c.centro.canon()
    (cx, cy) = (centro_canone.x, centro_canone.y)
    r = c.raio
    t.penup()

    # desloca o centro
    t.fd(cx)
    t.left(90)
    t.fd(cy)
    t.right(90)

    # desloca o raio para desenhar
    t.fd(r)

    t.pendown()
    t.left(90)
    t.circle(r)
    t.right(90)

    t.penup()
    # compensa o raio
    t.back(r)
    # compensa o centro
    t.back(cx)
    t.left(90)
    t.back(cy)
    t.right(90)

    t.pendown()
  cores = ( 'black', 'red', 'green', 'blue', 'orange' )
  i = 0
  old_color = t.pencolor()
  for c in circulos:
    cor = cores[i]
    t.pencolor(cor)
    i = (i + 1) % len(cores)
    circulo(t, c)
  c1 = circulos[0]
  for c2 in circulos[1 : len(circulos)]:
    t.pencolor(old_color)
    i = intersecao(c2, c1)
    if i[0] in (TiposIntersecao.TANGENTE_INTERNA, TiposIntersecao.TANGENTE_EXTERNA):
      t.pencolor('pink')
      old_p = t.pos()
      t.penup()
      p1 = i[1][0].canon()
      t.fd(p1.x)
      t.left(90)
      t.fd(p1.y)
      t.right(90)
      t.pendown()
      t.left(45)
      for a in range(4):
        t.fd(20)
        t.back(20)
        t.left(90)
      t.left(-45)
      t.penup()
      t.goto(*old_p)
      t.pendown()
    elif i[0] == TiposIntersecao.SECANTE:
      t.pencolor('pink')
      old_p = t.pos()
      t.penup()
      p1 = i[1][0].canon()
      t.fd(p1.x)
      t.left(90)
      t.fd(p1.y)
      t.right(90)
      t.pendown()
      p2 = i[1][1].canon()
      t.setpos(p2.x, p2.y)
      t.penup()
      t.goto(*old_p)
      t.pendown()
  t.pencolor(old_color)


x = 100
circulos(t,
        Circulo(Ponto(0, 0), 250),
        Circulo(Ponto(x*2.5, 0), 25),
        Circulo(Ponto(x*2.5, 0, SC_CANON.rotate(-50)), 25),
        Circulo(Ponto(x*2.5, 0, SC_CANON.espelho().rotate(-50)), 25),
        Circulo(Ponto(x*2.5, 0, SC_CANON.rotate(-50).espelho()), 25),
        Circulo(Ponto(x*2.5, 0, SC_CANON.espelho().rotate(-50).espelho()), 25),
        Circulo(Ponto(x*2.5 + 10, 0), 10),
        Circulo(Ponto(x*2.5 + 10, 0, SC_CANON.rotate(-45)), 10),
        Circulo(Ponto(x*2.5 + 10, 0, SC_CANON.espelho().rotate(-45)), 10),
        Circulo(Ponto(x*2.5 + 10, 0, SC_CANON.rotate(-45).espelho()), 10),
        Circulo(Ponto(x*2.5 + 10, 0, SC_CANON.espelho().rotate(-45).espelho()), 10)
)

print("olá, mundo")

turtle.done()
```
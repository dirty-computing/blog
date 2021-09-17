---
layout: post
title: "Desenhando com Python e tartarugas"
author: "Jefferson Quesado"
base-assets: "/assets/desenhos-python-turtle/"
tag: python tartaruga
---

Senti a necessidade de fazer alguns desenhos para fazer a explicação sobre
interseções de círculos (a publicar). Para isso, me lembrei que na [resposta
original que dei no StackOverflow](https://pt.stackoverflow.com/a/260073/64969)
fiz os desenhos usando o módulo `Turtle` do Python. Porém, não consegui resgatar os
códigos originais.

Então, vamos aprender a mexer com tartarugas em Python?

Meu foco aqui é:

- desenhar os eixos principais
- desenhar círculos
- desenhar segmentos de retas
- mudar a cor do que está sendo desenhado

No final deste artigo eu terei descrito como fazer essas 4 coisas. Não necessariamente
nessa mesma ordem. Outras coisas também serão estudadas, tanto sobre Python quanto sobre seu
próprio módulo `turtle`.

# Iniciando a tartaruga

> Estou com uma instalação padrão do Python 3.9.7 instalado pelo Windows. Simplesmente digitei
> `python` na linha de comando e segui as instruções para instalá-lo.

Para começar e deixar mais simples, escolhi por brincar no REPL do Python. Isso permite que
eu teste conforme digito e obtenho o resultado imediatamente.

Ok, importar a tartaruga. O módulo literalmente se chama `turtle`, então é `import turtle`.

Eu posso simplesmente iniciar uma tartaruga fazendo `t = turtle.Turtle()`. Isso criará uma
tela padrão com a tartaruga:

![Print da tela exibindo a criação da tela através da instanciação da tartaruga]({{
page.base-assets | append: "turtle.Turtle.png" | relative_url }})

Porém, iniciar desse jeito não tem tanta interação com a tela. Não tenho de imediato a tela
para pegar dimensões, setar o título, deixar interativo, coisas assim. Nesse caso, podemos iniciar
a tela e, então, criar a tartaruga:

```python
import turtle

sc = turtle.Screen()
t = turtle.Turtle()
sc.title("Uma tortuguita")
```

![Iniciando a tartaruga e setando título na tela]({{ page.base-assets |
append: "uma-tortuguita.png" | relative_url }})

# Prendendo a eventos para poder gravar

Tentei desenhar o eixo X:

```python
import turtle

sc = turtle.Screen()
t = turtle.Turtle()
sc.title("Uma tortuguita")
x, y = sc.screensize()

t.fd(x)
```

E com isso obtive o seguinte resultado:

![Tela mostrando um segmento reto do centro até o lado direito]({{ page.base-assets |
append: "t.fd-oops.png" | relative_url }})

Só que não consegui gravar o processo... O ideal seria que eu conseguisse prender a um
evento (um clique, por exemplo), para disparar o evento quando eu estivesse pronto para gravar.
Um `sleep` também poderia fornecer o resultado esperado, me deixar gravar, mas isso significa que
eu preciso me preparar antes do começo do processo e esperar ele iniciar; isso significa que tenho
um belo ponto de falha (não conseguir me preparar a tempo) e um belo ponto de tédio (me preparo muito
rapidamente e preciso ficar esperando).

A classe `turtle.Screen` fornece um método de interceptar cliques do mouse passando uma função lambda
que consuma dois parâmetros `x,y`. Posso então prender no clique e poder gravar a animação que eu desejo:

```python
import turtle

sc = turtle.Screen()
t = turtle.Turtle()
sc.title("Uma tortuguita")

sc.onscreenclick(lambda x,y: t.fd(100))
```

![Mostrando a tartaruga prosseguindo conforme]({{ page.base-assets |
append: "onscreenclick.gif" | relative_url }})

A partir de agora, exceto se especificado o contrário, toda a função de desenho será feito dentro da função
`desenha(t, sc)`, que recebe uma tartaruga e uma tela. Ela será disparada no clique. Os parâmetros fornecidos
pelo lambda são ignorados pois não nos interessa saber nada sobre o clique. O corpo será feito assim:

```python
import turtle

def desenha(t, sc):
    # código do desenho reside aqui
    pass

sc = turtle.Screen()
t = turtle.Turtle()
sc.title("Uma tortuguita")

sc.onscreenclick(lambda x,y: desenha(t, sc))
```

Eventualmente o título pode ser diferente.

> Posteriormente descobri que `onclick` é um método sinônimo de `onscreenclick`. Não irei retroadequar o que foi escrito,
> mas eventualmente algum trecho de código pode ser escrito de maneira distinta, assim como material de apoio também.

# Desenhando os eixos principais

Lembrando que resgatamos as dimensões da tela fazendo `x, y = sc.screensize()`, primeiro
experimento é mandar avançar a tartaruga `x` adiante: `t.fd(x)`

![]({{ page.base-assets |
append: "fdx.gif" | relative_url }})

Ok, agora então para terminar de desenhar o eixo horizontal só mandar a tartaruga voltar 2 vezes
`x`. E para ficar na origem de novo é só avançar `x` de novo:

```python
t.fd(x)
t.back(2*x)
t.fd(x)
```

![]({{ page.base-assets |
append: "eixo-x.gif" | relative_url }})

E para o eixo vertical é a mesma coisa, mas antes preuciso rodar a tartaruga 90º (no sentido anti-horário
para que ela aponte para cima, por uma questão estética). Mas, já que é exatamente a mesma coisa, por que
não extrair isso numa função `desenha_eixo(t,s)`? Sem problemas, mas e como rodar a tartaruga? E, em cima disso,
qual a unidade de rotação que é usada?

Sobre a unidade, existem duas principais candidatas:

- radianos
- graus

Como descobrir qual ela estará usando? Uma chance seria lendo a documentação, mas é mais rápido
e barato simplesmente testar:

```python
t.left(90)
```

se estiver usando graus, vai dar um quarto de volta, bem bonitinho. Se for em radianos, vai dar um
pouco menos do que 30 voltas, parando em algum estado intermediário da trigésima volta.

![]({{ page.base-assets |
append: "rotate-left.gif" | relative_url }})

Ok, minha tartaruga subiu usando graus. Vamos desenhar os eixos?

```python
def desenha_eixo(t, s):
  t.fd(s)
  t.back(2*s)
  t.fd(s)

x, y = sc.screensize()
desenha_eixo(t, x)
t.left(90)
desenha_eixo(t, y)
t.right(90)
```

![]({{ page.base-assets |
append: "eixos.gif" | relative_url }})

Tá, e se não estiver veloz o suficiente? Posso mexer no `t.speed`. `help(t.speed)` vem me ajudar:

```none
>>> help(t.speed)
Help on method speed in module turtle:

speed(speed=None) method of turtle.Turtle instance
    Return or set the turtle's speed.

    Optional argument:
    speed -- an integer in the range 0..10 or a speedstring (see below)

    Set the turtle's speed to an integer value in the range 0 .. 10.
    If no argument is given: return current speed.

    If input is a number greater than 10 or smaller than 0.5,
    speed is set to 0.
    Speedstrings  are mapped to speedvalues in the following way:
        'fastest' :  0
        'fast'    :  10
        'normal'  :  6
        'slow'    :  3
        'slowest' :  1
    speeds from 1 to 10 enforce increasingly faster animation of
    line drawing and turtle turning.

    Attention:
    speed = 0 : *no* animation takes place. forward/back makes turtle jump
    and likewise left/right make the turtle turn instantly.

    Example (for a Turtle instance named turtle):
    >>> turtle.speed(3)
```

Então posso guardar o valor anterior `old_speed = t.speed()` e então mandar ir o mais rápido
possível não instantâneo `t.speed(10)`:

![]({{ page.base-assets |
append: "eixos-10.gif" | relative_url }})

Por curiosidade, para aproveitar o _canvas_ levantado no REPL, eu não fecho a tela e a recrio,
faço apenas o mesmo movimento com a tartaruga pintando de branco (já que esta é a cor de fundo mesmo).
Para mudar a cor da caneta da tartaruga, só chamar `t.color('white')`.:

![]({{ page.base-assets |
append: "apagar-eixos.gif" | relative_url }})

Para voltar pro preto, só depois chamar para a cor desejada `t.color('black')`. Posso guardar a cor
resgatando de `t.color()`, mas tem uma coisinha que preciso prestar atenção: `t.color` se refere a ambos
`pencolor` (cor da caneta) como a `fillcolor` (cor do preenchimento), nessa ordem.

Então, se eu quiser um controle mais específico do que estou lidando, posso chamar `t.pencolor`.

# Desenhando círculos

A primeira coisa que me veio à cabeça para desenhar círculos foi fazer uns _dry runs_. Mas, como
fazer isso com tartarugas?

Bem, a tartaruga desenha porque ela tem uma "caneta" em sua barriga que está para baixo, rumo ao "chão",
portato o movimento da tartaruga faz com que a caneta risque o chão. E... e se... eu "levantar" a caneta?

```python
t.penup()
t.circle(10)
```

![]({{ page.base-assets |
append: "circle-dry-run.gif" | relative_url }})

Ótimo. Temos o experimento feito. A tartaruga irá percorrer um círculo de raio `10` no sentido horário:

```python
for a in range(4):
  t.circle(10)
  t.left(90)
```

![]({{ page.base-assets |
append: "4-circulos.gif" | relative_url }})

Se eu quiser fazer uma circunferência que tenha o eixo horizontal coincidindo com seu diâmetro? Basicamente
seria necessário afastar a tartaruga raio verticalmente, deixar ela virada para a direção adequada e mandar desenhar
o círculo de raio raio. O mais natural para codificar para mim seria jogar a tartaruga para baixo e deixar ela olhando
para a direita, mas se eu jogar a tartaruga para cima eu consigo lidar com isso apenas virando à esquerda 90º:

1. levanta a caneta, não queremos riscar o raio
1. vira à esquerda 90º
1. avança raio
1. vira à esquerda 90º
1. abaixa a caneta
1. desenha círculo de raio raio
1. levanta a caneta
1. vira à esquerda 90º
1. avança raio
1. vira à esquerda 90º
1. baixa a caneta (para voltar ao estado anterior)

```python
t.penup()
t.left(90)
t.fd(raio)
t.left(90)
t.pendown()
t.circle(raio)
t.penup()
t.left(90)
t.fd(raio)
t.left(90)
t.pendown()
```

Para ficar claro se eu fiz alguma besteira, desloquei a tartaruga 45 unidades da origem.
Fazendo o experimento com 60 de raio:

![]({{ page.base-assets |
append: "circulo-eixo-x.gif" | relative_url }})

Se eu tivesse seguido minha intuição, de primeiro mandar para baixo a tartaruga, iria mudar as viradas:

1. direita
1. esquerda
1. esquerda
1. direita

O resto seria idêntico, nas mesmas ordens. Vou já deixar a tartaruga com violeta `t.color('violet')` e
desenhar sobre o círculo anterior para mostrar que está funcionando mesmo:

```python
t.penup()
t.right(90)
t.fd(raio)
t.left(90)
t.pendown()
t.circle(raio)
t.penup()
t.left(90)
t.fd(raio)
t.right(90)
t.pendown()
```

![]({{ page.base-assets |
append: "circulo-eixo-x-2.gif" | relative_url }})

> Note que o gif deixou como artefato no meio da caminho uma tartaruga no terceiro quadrante,
> mas isso não foi um material natural do meu desenho, assim como também ficou um trecho com
> coloração fraca, outro artefato do gif ou da ferramenta de captura. Veja como ficou abaixo:
> 
> ![]({{ page.base-assets |
append: "circulo-violeta.png" | relative_url }})
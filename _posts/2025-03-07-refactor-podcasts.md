---
layout: post
title: "Refatorando página de podcasts"
author: "Jefferson Quesado"
tags: meta yaml js jekyll liquid ts html
base-assets: "/assets/refactor-podcasts/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Tem uma página aqui dedicada aos podcasts os quais fui convidado, sabia? Yep, é
a [podcasts]({{ "/podcasts/" | prepend: site.baseurl }}). Só que acabou que eu
participei de alguns podcasts e não atualizei mais ela. A questão é... por quê?

Pois bem, não atualizei porque era oneroso.

# O esquema original

Vou botar abaixo o jeito que eu fazia para uma menção ao podcast "Engineering
sessions" do {{ site.data.podcasts.people["carlosenog"] }}:

{% raw %}
```md
# Agile 2024 (Carlos Nogueira, Engineering Sessions)

Engineering Sessions, summer edition (pt 1):

- [YouTube](https://youtu.be/rq_iSKWR3SI?feature=shared)

Host:
- [Carlos Nogueira](https://twitter.com/carlosenog)

Convidados:
- Jefferson Quesado
- [Rodolvo De Nadai](https://twitter.com/rdenadai)
- [Victor Osório](https://twitter.com/vepo)

Canal:
- [YouTube](https://www.youtube.com/@carlosenog)
```
{% endraw %}

Pois bem, era um conjunto de coisas sem muita estrutura mas que eu deveria
povoar:

- nome do show
- host
- episódio
- links para o canal
- nome do episódio
- links para o episódio (no caso de estar hospedado em múltiplas plataformas)
- convidados do episódio com links para os convidados

E isso cansa. Inclusive na última entrada que eu adicionei para o "Engineering
sessions" eu não coloquei os links dos convidados, o que é um ultraje.

> Por sinal, minha última participação no "Engineering sessions" não tinha nem
> entrada.

Os convidados algumas vezes se repetem. Se repetem ao ponto de que eu acho
melhor referenciar a eles através de um nick do que através do seu nome e um
link para o seu domínio ou rede social.

# Modelando o novo esquema

Com base em [Usando data files para redes
sociais]({% post_url 2025-01-13-jekyll-data-files %}), tenho agora conhecimento
para lidar com datafiles. Então, vamos modelar as coisas? Para então conseguir
apresentar de modo satisfatório?

Primeiramente, quero agrupar por show. Então, os episódios dos quais
participei. Com isso já conseguimos ter um início do formato do dado:

```ts
type podcasts_datafile = {
    podcasts: podcast[]
}

type podcast = {
    episodes: episode[]
}

type episode = {
    links: link[]
}

type link = string
```

Beleza. Para exibir, eu itero nos shows, exibo a informação geral do show,
então entro em detalhe sobre cada episódio.

Agora, vamos lá. Precisamos ter o host do show também. Vou por aqui só o
diferencial perante o esquema anterior:

```ts
type podcast = {
    episodes: episode[],
    host: person
}

type person = string // para representar o nome com o link
                     // por exemplo: "[Carlos Nogueira](https://carlosenog.dev/)"
```

Ok, um avanço. Mas eu não botei o nome do canal ainda, né? Nem uma pequena
breve descrição. E preciso dos links dos canais!

```ts
type podcast = {
    episodes: episode[],
    host: person,
    show: string,
    description: string,
    channels: link[]
}
```

Muito bom. Agora, precisamos enriquecer os episódios. Colocar a lista de guests
já ajuda, né? O título e uma pequena descrição também:

```ts
type episode = {
    links: link[],
    guests: person[],
    title: string,
    description: string
}
```

Ufa! Vamos ver um exemplo?

```yaml
- show: "Engineering Sessions"
  host: "[Carlos Nogueira](https://carlosenog.dev/)"
  description: "Conversa de engenheiro a engenheiro sobre o ofício."
  episodes:
    - title: "Embrace Legacy!"
      description: "Engineering Sessions, S03E05"
      links:
        - "[YouTube](https://youtu.be/zOzLwJOe96w?feature=shared)"
      guests:
        - "Jefferson Quesado"
        - "[Leandro Proença](https://leandronsp.com)"
        - "[Rafael Ponte](https://www.linkedin.com/in/rponte/)"
    - title: "Agile 2024 part 1"
      description: "Engineering Sessions, summer edition (pt 1)"
      links:
        - "[YouTube](https://youtu.be/rq_iSKWR3SI?feature=shared)"
      guests:
        - "Jefferson Quesado"
        - "[Rodolfo De Nadai](https://rdenadai.com.br/)"
        - "[Victor Osório](https://vepo.dev/)"
```

Ok, aqui temos a questão dos nicks. Preferiria citar as pessoas via nicks do
que repetir elas sempre. Até porque para mim é mais fácil associar o nick à
pessoa da rede social do que essa papagaiada toda entre aspas e com as
marcações do markdown de colchetes e parênteses e o link ligando para as
pessoas. Então, como fazer? Antes de me preocupar com a renderização disso via
liquid, já modelar corretamente aqui.

Para começo, preciso já ajeitar no datafile: vou deixar os podcasts e as
pessoas juntas, no mesmo datafile. Assim fica na minha cabeça mais fácil de
localizar as coisas.

Bem, vamos começar mudando o host e os guests: eles não serão mais `person`,
serão `nick`:

```diff
 type podcast = {
     episodes: episode[],
-    host: person,
+    host: nick,
     show: string,
     description: string,
     channels: link[]
 }
 
 type episode = {
     links: link[],
-    guests: person[],
+    guests: nick[],
     title: string,
     description: string
 }
+
+type nick = string // exemplo: carlosenog
```

Com isso:

```yaml
- show: "Engineering Sessions"
  host: carlosenog
  description: "Conversa de engenheiro a engenheiro sobre o ofício."
  episodes:
    - title: "Embrace Legacy!"
      description: "Engineering Sessions, S03E05"
      links:
        - "[YouTube](https://youtu.be/zOzLwJOe96w?feature=shared)"
      guests:
        - jeffque
        - leandronsp
        - rponte
    - title: "Agile 2024 part 1"
      description: "Engineering Sessions, summer edition (pt 1)"
      links:
        - "[YouTube](https://youtu.be/rq_iSKWR3SI?feature=shared)"
      guests:
        - jeffque
        - rdenadai
        - vepo
```

Show! Agora preciso de um mapeamento de nick para pessoas:

```ts
type podcasts_datafile = {
    podcasts: podcast[],
    people: nick2person
}

type nick2person = {
    [nickname: nick] : person
}
```

Bem, parece bem modelado. Como fica isso? Assim:

```yaml
podcasts:
- show: "Engineering Sessions"
  host: carlosenog
  description: "Conversa de engenheiro a engenheiro sobre o ofício."
  episodes:
    - title: "Embrace Legacy!"
      description: "Engineering Sessions, S03E05"
      links:
        - "[YouTube](https://youtu.be/zOzLwJOe96w?feature=shared)"
      guests:
        - jeffque
        - leandronsp
        - rponte
    - title: "Agile 2024 part 1"
      description: "Engineering Sessions, summer edition (pt 1)"
      links:
        - "[YouTube](https://youtu.be/rq_iSKWR3SI?feature=shared)"
      guests:
        - jeffque
        - rdenadai
        - vepo

people:
  carlosenog: "[Carlos Nogueira](https://carlosenog.dev/)"
  jeffque: "Jefferson Quesado"
  leandronsp: "[Leandro Proença](https://leandronsp.com)"
  rdenadai: "[Rodolfo De Nadai](https://rdenadai.com.br/)"
  rponte: "[Rafael Ponte](https://www.linkedin.com/in/rponte/)"
  vepo: "[Victor Osório](https://vepo.dev/)"
```

# Renderizando show e episódios

Até aqui, tudo alegria. Só modelagem. Vamos botar esses elementos pra
interagir? Pra de fato serem úteis?

Aqui não vou seguir a linha de raciocínio de como eu estava fazendo, vou ir
para uma abordagem mais _freestyle_. Começando com: como que eu faço para pegar
um nick e transformar em uma pessoa?

Esse é um problema já resolvido na real. Só ler de novo o post
[Usando data files para redes sociais]({% post_url 2025-01-13-jekyll-data-files %}).
Então, se eu quiser imprimir o valor relacionado ao nick `carlosenog`, basta
por {% raw %}`{{ site.data.podcasts.people["carlosenog"] }}`{% endraw %} e
temos o valor: {{ site.data.podcasts.people["carlosenog"] }}.

Notou que usei as aspas no caso específico que queria um nick determinado? É
para tratar como string literal. Se eu não tivesse usado as aspas ele tomaria
como uma variável liquid. E como variável liquid eu posso pegar os guests, por
exemplo, e iterar neles.

Só por exemplo:

{% raw %}
```liquid
{% assign nick_test = "carlosenog" %}
- {{ nick_test }}
- {{ site.data.podcasts.people[nick_test] }}
```
{% endraw %}

Resultado:

{% assign nick_test = "carlosenog" %}
- {{ nick_test }}
- {{ site.data.podcasts.people[nick_test] }}

Hmmm, ficar mencionando `site.data.podcasts.people` toda hora não parece muito
auspicioso. Muita repetição, muita sujeira (principalmente em algumas situações
de pouco espaço) e, o pior, muito sujeito a eu cometer um typo e ficar horas
procurando a origem. Vou jogar em uma variável para mencionar apenas ela
depois:

{% raw %}
```liquid
{% assign podcast_people = site.data.podcasts.people %}
- {{ nick_test }}
- {{ site.data.podcasts.people[nick_test] }}
- {{ podcast_people[nick_test] }}
```
{% endraw %}

Resultado:

{% assign podcast_people = site.data.podcasts.people %}
- {{ nick_test }}
- {{ site.data.podcasts.people[nick_test] }}
- {{ podcast_people[nick_test] }}

Perfeito!

Agora, vamos iterar nos podcasts:

{% raw %}
```liquid
{% for show in site.data.podcasts.podcasts %}
## {{ show.show }}
{{ show.description }}

Host: {{ podcast_people[show.host] }}

Canais para acompanhar o podcast:

{% for channel in show.channels -%}
- {{ channel }}
{% endfor %}

{% endfor %}
```
{% endraw %}

Renderizou um markdown mais ou menos assim (dá desconto no espaço em branco):

```md
## Engineering Sessions
Conversa de engenheiro a engenheiro sobre o ofício.

Host: [Carlos Nogueira](https://carlosenog.dev/)

Canais para acompanhar o podcast:

- [YouTube](https://www.youtube.com/@carlosenog)
```

Ah, sabe como eu fiz para renderizar o markdown acima? Um truque bem simples!
Se você colocar dentro de tags html, o kramdown não tenta renderizar markdown
a priori, então vira tudo texto. Com isso, eu posso depois simplesmente pegar o
show "Engineering sessions" como exemplo! Aqui o modelo que usei para resgatar
a string gerada de markdown:

{% raw %}
```liquid
<pre><code>
{% for show in site.data.podcasts.podcasts %}
## {{ show.show }}
{{ show.description }}

Host: {{ podcast_people[show.host] }}

Canais para acompanhar o podcast:

{% for channel in show.channels -%}
- {{ channel }}
{% endfor %}

{% endfor %}
</code></pre>
```
{% endraw %}

Ok, renderizou bonitinho o esquema geral do podcast. Hora de entrar na iteração
dos episódios!

{% raw %}
```liquid
<!-- assumindo que tá dentro do loop para show -->
{% for episode in show.episodes %}
### {{ episode.title }}

{{ episode.description }}

{% for link in episode.links %}
- {{ link }}
{%- endfor %}
{% endfor %}
```
{% endraw %}

Renderizou assim:

```md
### Embrace Legacy!

Engineering Sessions, S03E05

- [YouTube](https://youtu.be/zOzLwJOe96w?feature=shared)
```

Hmmm, meio cru. Vamos colocar os participantes?

{% raw %}
```liquid
<!-- assumindo que tá dentro do loop para show -->
{% for episode in show.episodes %}
### {{ episode.title }}

{{ episode.description }}

{% for guest in episode.guests %}
- {{ podcast_people[guest] }}
{%- endfor %}

{% for link in episode.links %}
- {{ link }}
{%- endfor %}
{% endfor %}
```
{% endraw %}

```md
### Embrace Legacy!

Engineering Sessions, S03E05

- Jefferson Quesado
- [Leandro Proença](https://leandronsp.com)
- [Rafael Ponte](https://www.linkedin.com/in/rponte/)

- [YouTube](https://youtu.be/zOzLwJOe96w?feature=shared)
```

Definitivamente continua muito cru. Um pequeno texto "onde assistir?" vai
ajudar nos links, mas a lista de convidados tá muito crua de toda sorte.

E... se a lista de convidados for um único parágrafo? Algo como

> Com a participação de XXX, YYY, ZZZ

será que fica legal? Vamos tentar!

{% raw %}
```liquid
<!-- assumindo que tá dentro do loop para show -->
{% for episode in show.episodes %}
### {{ episode.title }}

{{ episode.description }}

Com a participação de {% for guest in episode.guests %} {{ podcast_people[guest] }} {% endfor %}

Onde assistir esse episódio?

{% for link in episode.links %}
- {{ link }}
{%- endfor %}
{% endfor %}
```
{% endraw %}

Renderizando

```md
### Embrace Legacy!

Engineering Sessions, S03E05

Com a participação de  Jefferson Quesado  [Leandro Proença](https://leandronsp.com)  [Rafael Ponte](https://www.linkedin.com/in/rponte/) 

Onde assistir esse episódio?
```

Bem, vamos ver como renderiza de fato o parágrafo de participantes?

> Com a participação de  Jefferson Quesado  [Leandro Proença](https://leandronsp.com)  [Rafael Ponte](https://www.linkedin.com/in/rponte/) 

É... não ficou dos melhores... Preciso separar com vírgulas. Mas como posso
fazer pra saber se estou no primeiro elemento do loop? Pois bem, a
[documentação do liquid](https://shopify.github.io/liquid/tags/iteration/#forloop-object)
tá aqui pra ajudar!

Ao criar uma iteração, podemos perguntar ao objeto `forloop` se ele está na
primeira iteração! E, caso não esteja, imprimir uma vírgula separando as
pessoas:

{% raw %}
```liquid
<!-- assumindo que tá dentro do loop para show -->
{% for episode in show.episodes %}
### {{ episode.title }}

{{ episode.description }}

Com a participação de {% for guest in episode.guests %}
{%- unless forloop.first -%}, {% endunless -%}
{{ podcast_people[guest] }}{% endfor %}

Onde assistir esse episódio?

{% for link in episode.links %}
- {{ link }}
{%- endfor %}
{% endfor %}
```
{% endraw %}

Renderizando assim:

```md
### Embrace Legacy!

Engineering Sessions, S03E05

Com a participação de Jefferson Quesado, [Leandro Proença](https://leandronsp.com), [Rafael Ponte](https://www.linkedin.com/in/rponte/)

Onde assistir esse episódio?

- [YouTube](https://youtu.be/zOzLwJOe96w?feature=shared)
```

Já melhorou bastante. Mas se eu pude pegar e separar por vírgulas, que tal por
o "e" no final? Além de simplesmente uma vírgula? Para dar uma suavizada na
leitura? E sem a vírgula de Oxford, claro! A propósito, liquid suporta `else`
e tem a propriedade `forloop.last`, o que permite esse pequeno controle do
separador:

{% raw %}
```liquid
<!-- assumindo que tá dentro do loop para show -->
{% for episode in show.episodes %}
### {{ episode.title }}

{{ episode.description }}

Com a participação de {% for guest in episode.guests %}
{%- unless forloop.first -%}{% if forloop.last %} e {% else -%}, {% endif -%}{% endunless -%}
{{ podcast_people[guest] }}{% endfor %}

Onde assistir esse episódio?

{% for link in episode.links %}
- {{ link }}
{%- endfor %}
{% endfor %}
```
{% endraw %}

Renderizando:

```md
### Embrace Legacy!

Engineering Sessions, S03E05

Com a participação de Jefferson Quesado, [Leandro Proença](https://leandronsp.com) e [Rafael Ponte](https://www.linkedin.com/in/rponte/)

Onde assistir esse episódio?

- [YouTube](https://youtu.be/zOzLwJOe96w?feature=shared)
```

> Sim, eu testei para o caso em que só tem eu como convidado e renderizou
> corretamente. Colocar o separador no começo de loop e fazer ele ser executado
> a não ser que seja o primeiro item foi feito de propósito para pegar esse
> tipo de cenário.

## Colapsando

Bem, sinceramente achei que ficou um tanto quanto poluído a priori. Antes
estava poluído? Sim. Mas eu posso aproveitar e deixar um pouco mais agradável.

A ideia então passa a ser deixar algo como as tags `<details><summary>`. Se for
possível usar essas tags então melhor ainda!

E dá? Na real, dá sim. "Ah, mas e se você fizer isso não vai renderizar
markdown blablablá..."

Lembra o que ue citei acima quando estava fazendo as renderizações parciais
para pegar os exemplos para este post? Vou copiar abaixo com destaque no
detalhe importante:

> Se você colocar dentro de tags html, o kramdown não tenta renderizar
> markdown **a priori**

Ou seja, há contorno! E como seria esse contorno? Por um simples atributo na
tag html: `markdown="1"`.

Por exemplo:

```html
Sem atributo:
<div>
- primeiro item
- segundo item
</div>

Com atributo:
<div markdown="1">
- primeiro item
- segundo item
</div>
Fim do teste
```

Sem atributo:
<div>
- primeiro item
- segundo item
</div>

Com atributo:
<div markdown="1">
- primeiro item
- segundo item
</div>
Fim do teste

Show. Assim eu coloco a lista de episódios dentro do `<details>`:

{% raw %}
```liquid
<details markdown="1">
<summary>
Episódios
</summary>
<!-- assumindo que tá dentro do loop para show -->
{% for episode in show.episodes %}
### {{ episode.title }}

{{ episode.description }}

Com a participação de {% for guest in episode.guests %}
{%- unless forloop.first -%}{% if forloop.last %} e {% else -%}, {% endif -%}{% endunless -%}
{{ podcast_people[guest] }}{% endfor %}

Onde assistir esse episódio?

{% for link in episode.links %}
- {{ link }}
{%- endfor %}
{% endfor %}
</details>
```
{% endraw %}

Texto gerado:

```md
<details markdown="1">
<summary>
Episódios
</summary>

### Embrace Legacy!

Engineering Sessions, S03E05

Com a participação de Jefferson Quesado, [Leandro Proença](https://leandronsp.com) e [Rafael Ponte](https://www.linkedin.com/in/rponte/)

Onde assistir esse episódio?

- [YouTube](https://youtu.be/zOzLwJOe96w?feature=shared)
</details>
```

E aqui o renderizado:

<details markdown="1">
<summary>
Episódios
</summary>

### Embrace Legacy!

Engineering Sessions, S03E05

Com a participação de Jefferson Quesado, [Leandro Proença](https://leandronsp.com) e [Rafael Ponte](https://www.linkedin.com/in/rponte/)

Onde assistir esse episódio?

- [YouTube](https://youtu.be/zOzLwJOe96w?feature=shared)
</details>

Fim do teste.

Hmmm, eu podia ter uma contagem de episódios, né? Então mudar o conteúdo do
`<summary>` para {% raw %}`Episódios {{ show.episodes | size }}`{% endraw %}:

{% raw %}
```liquid
<details markdown="1">
<summary>
Episódios {{ show.episodes | size }}
</summary>
<!-- assumindo que tá dentro do loop para show -->
{% for episode in show.episodes %}
### {{ episode.title }}

{{ episode.description }}

Com a participação de {% for guest in episode.guests %}
{%- unless forloop.first -%}{% if forloop.last %} e {% else -%}, {% endif -%}{% endunless -%}
{{ podcast_people[guest] }}{% endfor %}

Onde assistir esse episódio?

{% for link in episode.links %}
- {{ link }}
{%- endfor %}
{% endfor %}
</details>
```
{% endraw %}

Texto gerado:

```md
<details markdown="1">
<summary>
Episódios 1
</summary>

### Embrace Legacy!

Engineering Sessions, S03E05

Com a participação de Jefferson Quesado, [Leandro Proença](https://leandronsp.com) e [Rafael Ponte](https://www.linkedin.com/in/rponte/)

Onde assistir esse episódio?

- [YouTube](https://youtu.be/zOzLwJOe96w?feature=shared)
</details>
```

E aqui o renderizado:

<details markdown="1">
<summary>
Episódios 1
</summary>

### Embrace Legacy!

Engineering Sessions, S03E05

Com a participação de Jefferson Quesado, [Leandro Proença](https://leandronsp.com) e [Rafael Ponte](https://www.linkedin.com/in/rponte/)

Onde assistir esse episódio?

- [YouTube](https://youtu.be/zOzLwJOe96w?feature=shared)
</details>

Fim do teste.

## Randomizando

Sabe outra coisa que poderia ficar legal? Se fosse feita a randomização dos
shows! No Python temos uma função de array chamada `shuffle`, mas não 
isso no JS. Então peguei um
[shuffle da freeCodeCamp](https://www.freecodecamp.org/news/how-to-shuffle-an-array-of-items-using-javascript-or-typescript/).
Especificamente escolhi o algoritmo `Fisher-Yates`:

```js
// https://www.freecodecamp.org/news/how-to-shuffle-an-array-of-items-using-javascript-or-typescript/
function shuffle(list) {
    const array = [...list]
    for (let i = array.length - 1; i > 0; i--) { 
        const j = Math.floor(Math.random() * (i + 1)); 
        [array[i], array[j]] = [array[j], array[i]]; 
    } 
    return array;
}
```

Algumas pequenas diferenças:
- eu não queria fazer inplace, portanto copiei
- declarei como função tradicional no lugar de arrow-function

Perfeito. Agora eu preciso pegar os elementos filhos de... de quê? Hmmm, não
tenho um elemento geral abarcando todos os shows... Logo? Hora de criar! Uma
grande `<div>` que vai abarcar todos os elementos! E agora eu preciso tomar
um cuidado, porque além disso eu preciso abarcar cada show em outra `<div>`,
que vai conter o cabeçalho geral do show e os episódios. Toda essa ginástica
para que cada podcast seja possível pegar individualmente.

Mas eu posso pegar essa coisa da randomização e fazer um trabalho bem bacana.
Não preciso me limitar a única e exclusivamente me limitar a fazer isso apenas
para os podcasts. Posso fazer aqui! E como posso fazer isso? Identificando os
elementos a serem randomizados, através de uma classe. Vou determinar que todos
os elementos que tenham a classe `randomize` estão aptos a serem randomizados.

Por exemplo, vou por duas listagens de 1 a 5 por extenso, sempre em ordem
crescente, e identificar as listagens com essa classe:

```html
<ul class="randomize">
    <li>Um</li>
    <li>Dois</li>
    <li>Três</li>
    <li>Quatro</li>
    <li>Cinco</li>
</ul>
... separando...
<ul class="randomize">
    <li>1:Um</li>
    <li>2:Dois</li>
    <li>3:Três</li>
    <li>4:Quatro</li>
    <li>5:Cinco</li>
</ul>
```

<ul class="randomize">
    <li>Um</li>
    <li>Dois</li>
    <li>Três</li>
    <li>Quatro</li>
    <li>Cinco</li>
</ul>
... separando...
<ul class="randomize">
    <li>1:Um</li>
    <li>2:Dois</li>
    <li>3:Três</li>
    <li>4:Quatro</li>
    <li>5:Cinco</li>
</ul>

Além de atualizar a página, você também pode apertar o botão para randomizar:

<button onclick="startRandomization(false)">Randomizar as listas</button>

Bem, o `shuffle` já foi descrito, mas e perante o resto?

Dado um elemento html, quero randomizar seu conteúdo. Então isso justifica ter
uma função assim:

```js
function randomize(htmlRoot) {
    // ...
}
```

E essa função trabalhar essa questão da randomização. Para listar os filhos do
elemento basta fazer `htmlRoot.children`, mas isso retorna um `HTMLCollection`.
E a própria documentação sobre
[`HTMLCollection` na MDN](https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection)
menciona em "transformar" em um array clássico usando `Array.from`. No momento
que eu tenho um array clássico eu posso mandar pro shuffle, então bora lá,
começar a avançar a função:

```js
function randomize(htmlRoot) {
    const children = Array.from(htmlRoot.children)
    const shuffled = shuffle(children)
    // ...
}
```

Show! Agora eu preciso indicar ao `htmlRoot` que a nova ordem de seus filhos é
essa. Mas em tese `HTMLCollection` é uma coleção imutável... logo, não é
manipulando esse campo que vou obter o que eu preciso. Então eu vou remover
todos os elementos filhos e inserir agora os filhos já depois de embaralhados!
Precisei pescar uma
[referência no Geeks for Geeks](https://www.geeksforgeeks.org/remove-all-the-child-elements-of-a-dom-node-in-javascript/)
pra isso. Aproveita que tá aqui e olha a documentação para
[adicionar elementos no DOM da MDN](https://developer.mozilla.org/en-US/docs/Web/API/Node/appendChild)

```js
function randomize(htmlRoot) {
    const children = Array.from(htmlRoot.children)
    const shuffled = shuffle(children)
    // based on https://www.geeksforgeeks.org/remove-all-the-child-elements-of-a-dom-node-in-javascript/
    for (const child of children) {
        htmlRoot.removeChild(child)
    }
    // doc https://developer.mozilla.org/en-US/docs/Web/API/Node/appendChild
    for (const child of shuffled) {
        htmlRoot.appendChild(child)
    }
}
```

E com isso a randomização de um elemento está completa.

Mas e quanto ao ponto de partida? Bem, podemos pedir pelos elementos de uma
classe usando `document.getElementsByClassName("randomize")`, e mandar para o
`randomize` cada um desses elementos:

```js
function startRandomization() {
    const whatToRandomize = document.getElementsByClassName("randomize");
    for (const elementToRandomize of whatToRandomize) {
        randomize(elementToRandomize)
    }
}

startRandomization()
```


<script>
// https://www.freecodecamp.org/news/how-to-shuffle-an-array-of-items-using-javascript-or-typescript/
function shuffle(list) {
    const array = [...list]
    for (let i = array.length - 1; i > 0; i--) { 
        const j = Math.floor(Math.random() * (i + 1)); 
        [array[i], array[j]] = [array[j], array[i]]; 
    } 
    return array;
}

function randomize(htmlRoot) {
    const children = Array.from(htmlRoot.children)
    const shuffled = shuffle(children)

    // based on https://www.geeksforgeeks.org/remove-all-the-child-elements-of-a-dom-node-in-javascript/
    for (const child of children) {
        htmlRoot.removeChild(child)
    }
    // doc https://developer.mozilla.org/en-US/docs/Web/API/Node/appendChild
    for (const child of shuffled) {
        htmlRoot.appendChild(child)
    }
}

function openParents(element) {
    // chegou no fim, para
    if (!element.parentElement) {
        return
    }
    openParents(element.parentElement)
    if (element.parentElement.localName.toLocaleLowerCase() == "details") {
        element.parentElement.open = true
    }
}

function startRandomization(shouldScroll) {
    const whatToRandomize = document.getElementsByClassName("randomize");
    for (const elementToRandomize of whatToRandomize) {
        randomize(elementToRandomize)
    }

    if (shouldScroll && whatToRandomize.length > 0 && !!window.location.hash) {
        const id = window.location.hash.substring(1)
        const element = document.getElementById(id)
        if (!!element) {
            openParents(element)
            // https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollIntoView
            element.scrollIntoView(true);
        }
    }
}

startRandomization(false)
</script>

Show, consigo randomizar. MAS... preciso adaptar meus elementos renderizados.
Basicamente: uma `<div markdown="1" class="randomize">` _overarching_ todos os
podcasts, e para cada iteração em um podcast uma
`<div markdown="1" class="podcast">` também _overarching_ de cada passo da
iteração como um todo:

{% raw %}
```liquid
<div markdown="1" class="randomize"> <!-- overarching div -->
{% for show in site.data.podcasts.podcasts %}

<div markdown="1" class="podcast"> <!-- a div de cada iteração -->
## {{ show.show }}

{{ show.description }}

Host: {{ podcast_people[show.host] }}

Canais para acompanhar o podcast:

{% for channel in show.channels -%}
- {{ channel }}
{% endfor %}

... details dos episódios ...

</div> <!-- fechando a div de cada iteração -->
{% endfor %}
</div> <!-- fechando a overarching div -->
```
{% endraw %}

## Âncoras

Até aqui, tudo ótimo. Mas e ao compartilhar a lista de podcasts? Como por
exemplo
[podcasts#engineering-sessions]({{ "/podcasts/#engineering-sessions" | prepend: site.baseurl }})?

Hmmm, pra isso eu preciso detectar qual o elemento que foi compartilhado o
`id`, e também verificar se tem algum elemento pra começo de conversa.

Como eu vejo qual o elemento apontado? Preciso começar procurando por
`window.location.hash` pra pegar o fragmento da URL. Por sinal,
`window.location.hash` traz a informação com a `#`! Então para o link acima
mencionado traria `#engineering-sessions`. Como só interessa o elemento de `id`
que é esse fragmento menor o símbolo hash #, basta das um `.substring(1)`.

Mas para olhar isso primeiro precisa existir `window.location.hash`! Portanto,
só vou me preocupar em dar foco caso `!!window.location.hash`. Note aqui o
operador `bang bang` para deixar mais explícita a mensagem que estou
trabalhando com um booleano. Outra coisa importante é que se não teve nenhum
trabalho de randomização então não necessita forçar nada ir pro canto. E
finalmente, para o caso do botão de randomização: ele não precisa fazer foco em
nada. Então o que antes era uma simples função sem argumentos
`startRandomization()`, agora eu preciso indicar se eu quero dar um foco ou
não com o parâmetro `startRandomization(shouldScroll)`:

```js
function startRandomization(shouldScroll) {
    const whatToRandomize = document.getElementsByClassName("randomize");
    for (const elementToRandomize of whatToRandomize) {
        randomize(elementToRandomize)
    }

    if (shouldScroll && whatToRandomize.length > 0 && !!window.location.hash) {
        const id = window.location.hash.substring(1)
        const element = document.getElementById(id)
        if (!!element) {
            // https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollIntoView
            element.scrollIntoView(true);
        }
    }
}
```

Então detectado o elemento que eu quero mergulhar (que também precisa existir),
eu simplesmente peço para
[scrollar o foco nele](https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollIntoView).

Mas... e se o elemento estiver dentro de um `<details>`?

Para abrir um elemento `details` basta fazer `details.open = true`. Para saber
se um elemento é desse tipo? Eu testei vários atributos do DOM, e encontrei
finalmente o `.localName`. Se `.localName` do elemento em questão for
`details`, entào eu preciso abrir ele. Mas como eu sempre estou olhando para o
`.parentElement`, a comparação gira em torno de
`element.parentElement.localName`. Por via das dúvidas ainda posso pedir para
controlar tudo em caixa baixa:

```js
if (element.parentElement.localName.toLocaleLowerCase() == "details") {
    element.parentElement.open = true
}
```

Mas... e se o meu elemento pai não for `details`, mas o pai dele for? Que tal
fazer isso uma função recursiva que vai abrindo tudo!

```js
function openParents(element) {
    // chegou no fim, para
    if (!element.parentElement) {
        return
    }
    openParents(element.parentElement)
    if (element.parentElement.localName.toLocaleLowerCase() == "details") {
        element.parentElement.open = true
    }
}
```

E ela é integrada assim:

```js
function startRandomization(shouldScroll) {
    const whatToRandomize = document.getElementsByClassName("randomize");
    for (const elementToRandomize of whatToRandomize) {
        randomize(elementToRandomize)
    }

    if (shouldScroll && whatToRandomize.length > 0 && !!window.location.hash) {
        const id = window.location.hash.substring(1)
        const element = document.getElementById(id)
        if (!!element) {
            openParents(element)
            // https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollIntoView
            element.scrollIntoView(true);
        }
    }
}
```

Isso permite por exemplo linkar esse podcast aqui que o
{{ podcast_people["leandronsp"] }} gravou comigo:
[podcasts#computaria-com-coelho]({{ "/podcasts/#computaria-com-coelho" | prepend: site.baseurl }}).
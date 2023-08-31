---
layout: post
title: "Criando páginas discretas"
author: "Jefferson Quesado"
tags: meta liquid jekyll
base-assets: "/assets/paginas-discretas/"
---

Eu tava querendo por faz algum tempo um compilado das minhas
apresentações. Mas, ao tentar colocar aqui uma nova página
com o layout `page` (como é o [`/about/`]({{ "/about/" |
prepend: site.baseurl }})), essa página aparece no canto
superior direito do blog. E o problema é que quebra o layout,
e quebra feio o layout.

Então, qual seria a solução? Uma solução seria não usar título,
já que isso já garantiria que não iria mostrar. Eis o template
usado para garantir isso (`_includes/header.html`):

{% raw %}
```liquid
<div class="trigger">
{% for my_page in site.pages %}
    {% if my_page.title %}
    <a class="page-link" href="{{ my_page.url | prepend: site.baseurl }}">{{ my_page.title }}</a>
    {% endif %}
{% endfor %}
</div>
```
{% endraw %}

Mas, bem... não fica totalmente legal. Isso significa optar por não colocar
o título, mas o título é algo bacana e significativo, não posso omitir
sempre. Como proceder?

Bem, procedi tomando inspiração no [publicando rascunho]({% post_url
2022-10-26-public-draft %}). Só que aqui, no lugar de ser uma marcação
para _não_ aparecer, a marcação é para aparecer. Como fazer isso?

Pois bem, criei o atributo `show` no frontmatter. Se ele existir e o valor
for verdadeiro, então exibe.

Daí:

```diff
 ---
 layout: page
 title: Sobre
 permalink: /about/
+show: true
 ---
```

Isso foi o suficiente para pedir para exibir. E como consumir isso?

Bem, voltemos ao `header.html`:

{% raw %}
```liquid
<div class="trigger">
{% for my_page in site.pages %}
    {% if my_page.title %}
    <a class="page-link" href="{{ my_page.url | prepend: site.baseurl }}">{{ my_page.title }}</a>
    {% endif %}
{% endfor %}
</div>
```
{% endraw %}

Hmmm, e se o `liquid` permitir inserir `AND`? Bem, testemos:

{% raw %}
```liquid
<div class="trigger">
{% for my_page in site.pages %}
    {% if my_page.title and my_page.show %}
    <a class="page-link" href="{{ my_page.url | prepend: site.baseurl }}">{{ my_page.title }}</a>
    {% endif %}
{% endfor %}
</div>
```
{% endraw %}

E funcionou. Remover o atributo faz com que o `Sobre` suma, assim
como colocar o valor como `false`.

# Mostrar todas as páginas?

Bem, com isso, evitei de mostrar onde eu não queria: no canto superior
direito. Mas... e como eu alcanço o resto?

Pois bem, temos um problema. Seria bom ter isso dentro do alcance,
nem que seja uma seção dentro do `/about/`...

Será que eu tenho alcance às páginas tal qual no `header.html`?
Na real: sim. Basta iterar em cima de `pages`. Só que esse `pages`
traz alguns resultados que não é bem o que eu queria, pelo menos
não unicamente o que eu queria:

- `.css`
- `feed.xml`
- o próprio `/about/`
- raiz `/`

Pois bem, vamos programar em liquid! Separar o `/about/`
da informação sobre mim e o blog dos links com um `<hr/>`,
em markdown é só colocar `---` em uma linha vaiza.

Agora, iterar. Para fazer iteração em cima da coleção `pages`,
só fazer um `for`:

{% raw %}
```liquid
{% for my_page in pages %}
  ...
{% endfor %}
```

Muito bem, agora precisamos nos livrar de tudo que terminar com `.css`
ou com `.xml`. Chamar o método `String.end_with?` do Ruby não funcionou.
Então, que tal partir o `page.url` em cima do `.`? Assim eu obtenho um
vetor. Vamos testar?

```liquid
{% assign partes = "a.css" | split: "." %}
{% for parte in partes %}
- `{{parte}}`
{% endfor %}
```

{% endraw %}

Testando daqui...

{% assign partes = "a.css" | split: "." %}
{% for parte in partes %}
- `{{parte}}`
{% endfor %}

... até aqui.

{% raw %}

Hmmm, não ficou com um espaçamento legal entre os itens,
mas deu para mostrar o ponto. Dá para controlar com mais
carinho os
[espaços em branco do liquid](https://shopify.github.io/liquid/basics/whitespace/)
ao redor dos filtros/tags usando `{%-`/`{{-` para limpar os
espaços antes da expansão do liquid ou `-%}`/`-}}` para limpar
depois.

Após um tantinho de tentativa e erro, cheguei nisto:

```liquid
{% assign partes = "a.css" | split: "." %}
{%- for parte in partes %}
- `{{parte}}`
{%- endfor %}
```
{% endraw %}

Testando daqui...

{% assign partes = "a.css" | split: "." %}
{%- for parte in partes %}
- `{{parte}}`
{%- endfor %}

... até aqui.

{% raw %}
Ok, agora eu preciso saber se é `css`, ou `xml`. Como só me interessa
a extenção do arquivo, posso acessar com `vetor[-1]`. E, bem, resolvi testar
usando o `or`, o `and` funcionou ali em cima, né?

Cheguei nisto daqui:

```liquid
{% for my_page in site.pages %}
  {% assign my_page_parts = my_page.url | downcase | split: "."  %}
  {% unless
        my_page_parts[-1] == "css" or
        my_page_parts[-1] == "xml" %}
  - {{ my_page.url | prepend: site.baseurl }}
  {% endunless %}
{% endfor %}
```

e deu certo. Agora, vamos excluir a própria página e a raiz?

```liquid
{% for my_page in site.pages %}
  {% assign my_page_parts = my_page.url | downcase | split: "."  %}
  {% unless
        my_page_parts[-1] == "css" or
        my_page_parts[-1] == "xml" or
        my_page_parts[0] == "/" or
        my_page.url == page.url %}
  - {{ my_page.url | prepend: site.baseurl }}
  {% endunless %}
{% endfor %}
```

Ok, agora ajeitar o espaçamento:

```liquid
{% for my_page in site.pages %}
  {%- assign my_page_parts = my_page.url | downcase | split: "."  -%}
  {%- unless
        my_page_parts[-1] == "css" or
        my_page_parts[-1] == "xml" or
        my_page_parts[0] == "/" or
        my_page.url == page.url %}
  - {{ my_page.url | prepend: site.baseurl }}
  {%- endunless -%}
{% endfor %}
```

Pronto. Só falta deixar o link mais agradável. A priori, vamos querer
o próprio título, mas eventualmente ele pode estar em branco...
vamos por um placeholder no caso contrário?

```liquid
[{% if my_page.title %}{{my_page.title}}{% else %}PLACEHOLDER{% endif %}]({{ my_page.url | prepend: site.baseurl }})
```

Ok, com isso ficou mais agradável quando tem título:

{% endraw %}

- [Talks]({{ "/talks/" | prepend: site.baseurl }})

{% raw %}
Mas e em casos de ausência de título? Hmmm... sabe o que sempre tem?
Um `my_page.url`. Então, podemos exibir isso. Eu acho que fica mais bonito,
nesse tipo de caso, exibir como se fosse código, monoespaçado, então:

```liquid
[{% if my_page.title %}{{my_page.title}}{% else %}`{{my_page.url}}`{% endif %}]({{ my_page.url | prepend: site.baseurl }})
```

{% endraw %}

No caso, ficaria assim (caso não tivesse título na página de talks):

- [`/talks/`]({{ "/talks/" | prepend: site.baseurl }})
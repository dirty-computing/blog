---
layout: post
title: "Posts patrocinados"
author: "Jefferson Quesado"
tags: meta liquid
base-assets: "/assets/sponsoring-posts/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Eu sei, eu sei. Estou devendo alguns posts. Alguns de tempo imemoriais. Mas,
não tema. Estou aqui para tentar compensar.

Além de poder acompanhar pelo menos a intenção de posts futuros/correções pelas
[issues do GitLab](https://gitlab.com/computaria/blog/-/issues), agora coloquei
uma coisa a mais: posts que me foram requisitados e devidamente patrocinados
para eu escrever!

# De onde veio isso, Jeff?

Bem, algum tempo atrás, o [Lobão](https://bsky.app/profile/lobaorn.bsky.social)
quase comeu meu fígado porque não encontrou como patrocinar um post aqui no
Computaria.

Bem, não sei se já viram, mas todo post tá acompanhado de um copinho de café.
Assim: <a href='{{site.pixmeurl}}/{% if page.pixmecoffe %}{{ page.pixmecoffe }}{% else %}jeffquesado{% endif %}' target="_blank"><span class="icon">{% include icon-pixme.svg %}</span></a>

> Por favor perceba o popup quando coloca o mouse em cima do cafezinho, é fofo.

E isso é um botão clicável que leva para o Pix me a Coffee, iniciativa do
Daniel Limae, que inclusive usei para motivar esse post:
[Editando SVG na mão pra pedir café]({% post_url 2024/2024-03-16-edita-svg-manualmente %})

E nele tem a minha chave pix por sinal. Mas para não deixar dúvidas, criei
também uma nova seção no blog: [Patrocinado]({% link sponsored.md %}).

# Mudanças no blog

Para começar, uma pequena lista dos patrocínios que recebi que ainda devo
posts. Na página [Patrocinado]({% link sponsored.md %}) eu leio de um datafile
para criar a estrutura. A lista está em
[`_data/sponsored_wip.yaml`]({{ site.repository.blob_root }}/_data/sponsored_wip.yaml).

Coloquei as informações relevantes: quem patrocinou, o que patrocinou. Poderia
ter organizado como uma tabela, mas uma lista foi mais simples (inclusive
preciso formalizar melhor o modelo de tabelas aqui no computaria). Aqui o que
usei para gerar:

{% raw %}
```liquid
{% if site.data.sponsored_wip %}
Enquanto isso, estou trabalhando nesses posts patrocinados aqui:

{% for sponsored_post in site.data.sponsored_wip -%}
- {{ sponsored_post.subject }}, patrocinado por {{ sponsored_post.sponsor | join: ", " }}
{% endfor %}

{% else %}

Já terminou as requisições, esperando você!
{% endif %}
```
{% endraw %}

Resultado para as entradas atuais:

```md
- JPMS, patrocinado por Daniel Lobão
- IA 101, patrocinado por IO Prudente
```

Caso não tivesse nada na listagem, apareceria o seguinte texto:

> Já terminou as requisições, esperando você!

Além disso, coloquei também uma listagem com os posts patrocinados! Que por
hora é apenas um, mas deixei já pronto para receber múltiplos! Mas, para isso,
precisei fazer algumas pequenas mudanças nos dados básicos do frontmatter.

Nesse caso específico, não quero gerar uma página, então não criei um plugin do
Jekyll para criação de páginas. Fiz a mesma estratégia que existia no
[`index.html`]({{ site.repository.blob_root }}/index.html): listei os posts
que não estão marcados como rascunho (vide
[Rascunhos publicados em Jekyll]({% post_url 2022/2022-10-26-public-draft %}))
e filtrei apenas pelos que tem o campo `sponsored_by` no frontmatter.

Nesse caso, não me preocupei com a lista vazia, pois afinal um `<ul></ul>` não
deveria causar grande estrago, né? Aqui a ideia de como vou listar as coisas,
filtrando o que eu preciso, mas sem renderizar ainda os posts:

{% raw %}
```liquid
<ul class="post-list">
{% for post in site.posts %}
{% unless post.draft == 'true' %}
{% if post.sponsored_by %}
...
{% endif %}
{% endunless %}
{% endfor %}
</ul>
```
{% endraw %}

Além disso, estou sentindo a real necessidade de criar um componente para o
post. Pois agora preciso replicar o como estou citando os posts em diversos
lugares:

- a página de patrocinados
- o índice
- a página de tags ([Usando as tags - Parte 1: página de tags]({% post_url 2024/2024-06-03-pagina-tags %}))

Eu ia deixar isso quieto na real, mas aí eu vi essa publicação aqui:
[Creating reusable tip component for Jekyll](https://www.roberthorvick.com/blog/creating-reusable-tip-component-jekyll-liquid-markdown)
e pensei "quer saber? Vou mergulhar aqui".

A ideia é simples: colocar a lista de quem patrociou o post junto à data de
publicação. Para o caso em que não criei o componente (pois assim eu não
preciso cuidar da vírgula):

{% raw %}
```liquid
<li>
    <span class="post-meta">{{ post.date | date: "%b %-d, %Y" }}, gentil patrocínio de
    {{ post.sponsored_by | join: ", "}}</span>

    <h2>
    <a class="post-link" href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
    </h2>
</li>
```
{% endraw %}

Renderizando assim:

<ul class="post-list">
<li>
    <span class="post-meta">Jan 10, 2025, gentil patrocínio de
    David Fornazier, Rodolfo de Nadai</span>

    <h2>
    <a class="post-link" href="/blog/2025/01/10/java-mirror-mirror-on-the-wall">Conheça-te a ti mesmo! Reflexão e meta-programação em Java</a>
    </h2>
</li>
</ul>

E, finalmente, outro pequeno ponto de mudança: dar um destaque no próprio post
que gerou a publicação. Para isso, uma pequena mudança no
[`_layouts/post.html`]({{ site.repository.blob_root }}/_layouts/post.html):

{% raw %}
```diff
   <script defer src="{{ "/js/citation.js" | prepend: site.baseurl }}">
   </script>
 
   <button id="citationCopier" style="display: none;" class="icon" onclick="citation2clipboard('{{ page.title | escape }}', '{{ page.url | slugify }}')">{% include uxwing-copy-icon.svg %}</button>
 
+  {% if page.sponsored_by %}
+  <blockquote>
+    <p>Com o gentil patrocínio de {{ page.sponsored_by | join: ", " }}</p>
+  </blockquote>
+  {% endif %}
+
   <div class="post-content" itemprop="articleBody">
     {{ content }}
   </div>
```
{% endraw %}

Ficou bonito? Bem, por hora não, mas cumpriu com o que eu queria no momento,
depois procuro estilizar melhor. Quer ver como ficou? Olha aqui:
[Conheça-te a ti mesmo! Reflexão e meta-programação em Java]({% post_url 2025/2025-01-10-java-mirror-mirror-on-the-wall %}).

Ok, rumo à criação do componente de link propriamente dito!

## O componente como um liquid include

Baseado na referência
[Creating reusable tip component for Jekyll](https://www.roberthorvick.com/blog/creating-reusable-tip-component-jekyll-liquid-markdown),
a criação de um componente bem dizer é uma convenção em cima de como utilizar
um {% raw %}`{% include %}`{% endraw %}.

Eu não tinha me apercebido disso, mas eu já tinha criado um componente antes, e
nesse estilo de entendimento:
[Usando data files para redes sociais]({% post_url 2025/2025-01-13-jekyll-data-files %}).
O
[`_includes/social/icon.html`]({{ site.repository.blob_root }}/_includes/social/icon.html)
é exatamente o componente modelado!

Muito bem, agora vamos modelar o componente de link. Para começar? Pegar
exatamente o que tem no de post patrocinado. Só que agora eu vou incluir o post
como um argumento, algo assim:

{% raw %}
```liquid
{% include component/main-link.html
    post=post
%}
```
{% endraw %}

Eu _suponho_ que consigo passar objetos profundos para o `include`, vou testar.
Para renderizar, eu tenho a opção de torcar em todo lugar que faz a expansão de
{% raw %}`{{ post }}` por `{{ include.post }}` ou então de brincar de fazer
atribuição: `{% assign post=include.post %}`{% endraw %}. Esse `assign` eu já
tenho mais confiança de que funciona, até porque já usei algo similar em outros
momentos, e é isso que me faz crer que funcionaria para passar o objeto de
`post` para o elemento de `main-link`. Falando nele, nesse primeiro teste vai
ser com patrocinadores então não preciso me preocupar com maiores detalhes, ele
fica assim:

{% raw %}
```liquid
{% assign post=include.post %}
<li>
    <span class="post-meta">{{ post.date | date: "%b %-d, %Y" }}, gentil patrocínio de
    {{ post.sponsored_by | join: ", "}}</span>

    <h2>
    <a class="post-link" href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
    </h2>
</li>
```

A iteração fica:

```liquid
<ul class="post-list">
{% for post in site.posts %}
{% unless post.draft == 'true' %}
{% if post.sponsored_by %}
  {% include component/main-link.html
      post=post
  %}
{% endif %}
{% endunless %}
{% endfor %}
</ul>
```
{% endraw %}

E o resultado... 🥁🥁🥁

<ul class="post-list">
<li>
    <span class="post-meta">Jan 10, 2025, gentil patrocínio de
    David Fornazier, Rodolfo de Nadai</span>

    <h2>
    <a class="post-link" href="/blog/2025/01/10/java-mirror-mirror-on-the-wall">Conheça-te a ti mesmo! Reflexão e meta-programação em Java</a>
    </h2>
</li>
</ul>

SUCESSO! Ok, hora de aplicar no `index.html`! Vou aplicar do jeito que está
para fazer um teste. Como esperado, renderizou o a frase de "gentil patrocínio"
vazia:

<ul class="post-list">
<li>
    <span class="post-meta">Aug 30, 2021, gentil patrocínio de
    </span>

    <h2>
    <a class="post-link" href="/blog/2021/08/30/criando-blog-jekyll">Criando o blog com Jekyll no GitLab</a>
    </h2>
</li>
</ul>

Ok, hora de remover isso. Basicamente vou usar a mesma ideia usada para filtrar
no `for`, filtrar pela existência do campo:

{% raw %}
```liquid
{% assign post=include.post %}
<li>
    <span class="post-meta">{{ post.date | date: "%b %-d, %Y" }}{% if post.sponsored_by %}, gentil patrocínio de
    {{ post.sponsored_by | join: ", "}}{% endif %}</span>

    <h2>
    <a class="post-link" href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
    </h2>
</li>
```
{% endraw %}

E é isso, renderizou legal. Por aqui em contraponto o post patrocinado e o
primeiro post do blog:

<ul class="post-list">
<li>
    <span class="post-meta">Jan 10, 2025, gentil patrocínio de
    David Fornazier, Rodolfo de Nadai</span>

    <h2>
    <a class="post-link" href="/blog/2025/01/10/java-mirror-mirror-on-the-wall">Conheça-te a ti mesmo! Reflexão e meta-programação em Java</a>
    </h2>
</li>
<li>
    <span class="post-meta">Aug 30, 2021
    </span>

    <h2>
    <a class="post-link" href="/blog/2021/08/30/criando-blog-jekyll">Criando o blog com Jekyll no GitLab</a>
    </h2>
</li>
</ul>

E agora alterar o layout para página da tag específica, sem nenhum prejuízo.

Em breve devo querer categorizar por autor, para dar um destaque aos autores
convidados. Falando neles, eis aqui uma alternativa para listá-los:

{% raw %}
```liquid
<ul class="post-list">
{% for post in site.posts -%}
{%- unless post.draft == 'true' -%}
{%- unless post.author == 'Jefferson Quesado' -%}
  {% include component/main-link.html
      post=post
  %}
{%- endunless -%}
{%- endunless -%}
{%- endfor %}
</ul>
```
{% endraw %}

Ficando assim, na data de escrita deste post:

<ul class="post-list">
<li>
  <span class="post-meta">Apr 25, 2025
  </span>

  <h2>
  <a class="post-link" href="/blog/2025/04/25/java-optional">Entendendo map() e flatMap() no Optional do Java: Diferenças e Casos de Uso</a>
  </h2>
</li>

<li>
  <span class="post-meta">Apr 6, 2024
  </span>

  <h2>
  <a class="post-link" href="/blog/2024/04/06/colocando-coelhinhos-no-computaria">Colocando coelhinhos no Computaria e enlouquecendo</a>
  </h2>
</li>

</ul>
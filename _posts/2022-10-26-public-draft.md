---
layout: post
title: "Rascunhos publicados em Jekyll"
author: "Jefferson Quesado"
tags: jekyll meta liquid
---

Tenho a necessidade de disponibilizar alguns posts para visualização pública,
porém não gostaria que eles ficassem visíveis. Então, como fazer isso?

# Explorando o index.html

Dentro do `index.html` padrão temos o modo como se listam os posts:

{% raw %}
```html
    {% for post in site.posts %}
      <li>
        <span class="post-meta">{{ post.date | date: "%b %-d, %Y" }}</span>

        <h2>
          <a class="post-link" href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
        </h2>
      </li>
    {% endfor %}
```
{% endraw %}

Bem, aqui eu tenho um `for` trabalhando em cima do campo `site.posts`. Essa iteração
é feita em cima da variável `post`, que por sua vez tem 3 campos que são utilizados
aqui na listagem:

- `post.date`, com a data da publicação
- `post.url`, com o link para o próprio post
- `post.title`, aquilo que será exibido ao leitor humano para ele decidir
  se vai ler ou não a postagem

# Explorando a pasta de layouts

Outra coisa que me chamou a atenção foram os layouts. Provavelmente fosse melhor
eu ir atrás da documentação oficial do Jekyll para saber como ele lida com isso,
mas sinceramente? Dá para fazer muita coisa com observação e um tanto de engenharia
reversa.

Bem, bora lá. No frontmatter de todo asset textual normalmente se tem o campo `layout`.
Para páginas com cara de postagem elas seguem o layout `post`, para páginas que não
tem cara de post (como o `about`) eles herdam de `page`. O `index` herda diretamente
de `default`.

Além disso, temos os casos dos próprios layouts. O `default` não herda de ninguém.
`page` e `post`, em compensação, herdam de `default`. E olha que legal! Da data de
publicação deste post, temos que `page` está desse jeito:

{% raw %}
```html
---
layout: default
---
<article class="post">

  <header class="post-header">
    <h1 class="post-title">{{ page.title }}</h1>
  </header>

  <div class="post-content">
    {{ content }}
  </div>

</article>
```
{% endraw %}

E o `default` está assim:

{% raw %}
```html
<!DOCTYPE html>
<html>

  {% include head.html %}

  <body>

    {% include header.html %}

    <div class="page-content">
      <div class="wrapper">
        {{ content }}
      </div>
    </div>

    {% include footer.html %}

  </body>

</html>
```
{% endraw %}

Hmmmm, que interessante... ambos mencionam uma variável mágica do liquid que é
o `content`, e outra variável mágica que é `page`. A variável `page` ele consegue
acessar valores internos dela, como data de publicação, autor, título etc.

E olha que interessante... o layout `page` tem a menção de um também, e por
sua vez o layout `default` tem menção de `content` também.

Observando essas coisas, aparentemente `page` simboliza o objeto com os metadados
(seja obtido da convenção de nomes, seja do frontmatter) e `content` é literalmente
o conteúdo daquela coisa. Por exemplo, no caso de uma publicação cujo conteúdo seja
apenas `marm` e que seja do tipo `page`, podemos fazer um exercício e ver mais ou
menos como ficaria.

O primeiro passo é criar essa `page`:

{% raw %}
```html
---
layout: page
title: Marmota
---

marm
```
{% endraw %}

então podemos fazer a substituição desse objeto dentro do layout `page`, que daí
obtemos:

{% raw %}
```html
---
layout: default
---
<article class="post">

  <header class="post-header">
    <h1 class="post-title">Marmota</h1>
  </header>

  <div class="post-content">
    marm
  </div>

</article>
```
{% endraw %}

Isso fazendo as substituições tanto de `page` quanto também de `content`. Ok,
tendo isso em mente, vamos agora aplicar isso no `default`? Essas coisas vão para o
`content` dentro do `default`:

{% raw %}
```html
<!DOCTYPE html>
<html>

  {% include head.html %}

  <body>

    {% include header.html %}

    <div class="page-content">
      <div class="wrapper">
<article class="post">

  <header class="post-header">
    <h1 class="post-title">Marmota</h1>
  </header>

  <div class="post-content">
    marm
  </div>

</article>
      </div>
    </div>

    {% include footer.html %}

  </body>

</html>
```
{% endraw %}

E é assim que funciona os layouts, aparentemente, baseado em observações
empíricas e experimentações anteriores com esses layouts.

# Tinkering o layout para não aparecer

Basicamente, o que eu desejo é:

- um post, que seja do layout post
- que não esteja na listagem do index
- que seja acessível publicamente se tiver a URL direta

Então o primeiro passo aqui é evitar aparecer na listagem. Isso significa
que também não vai aparecer na listagem ao rodar `jekyll serve --drafts`?
Bem, sim, vai afetar. Como eu não sei a fundo como o `jekyll` insere na
lista de posts as coisas dentro de `_draft`, não vou conseguir pedir para
ele fazer um processamento especial no meu post de rascunho público. O ideal
seria que, caso subisse com `--drafts`, esse post aparecesse na listagem.
Fica para um próximo momento isso.

Bem, e como fazer isso? Eu tenho duas hipóteses:

- usar a ausência do campo `date` dentro dos metadados da página para lidar
  com isso e sumir com o post da listagem
- criar um campo novo no frontmatter específico para isso

## Experimento com a ausência do campo date

Durante a publicação de um post, ele passa a ganhar a data a partir do nome
do arquivo. E se eu tiver um arquivo que não fosse `2022-10-26-marmota.md`? E
sim apenas `marmota.md` dentro da pasta `_posts`?

Bem, isso significa que vou precisar fazer no mínimo 2 mudanças:

- no `index.html` preciso validar pela presença do `date`
- no layout `post.html` preciso validar pela presença do `date`

Validar a presença de um campo é bem simples, basta fazer {% raw %}
`{% if obj.prop %}` {% endraw %}. Se a propriedade for nula, esse `if`
vai ser avaliado como falso.

Portanto, no `index`, eu coloco o seguinte no `for`:

{% raw %}
```diff
    {% for post in site.posts %}
+     {% if post.date %}
      <li>
        <span class="post-meta">{{ post.date | date: "%b %-d, %Y" }}</span>

        <h2>
          <a class="post-link" href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
        </h2>
      </li>
+     {% endif %}
    {% endfor %}
```
{% endraw %}

E de modo semelhante no layout `post`, o único canto que menciona `page.date` passaria
a passar por validações.

{% raw %}
```diff
-<p class="post-meta"><time datetime="{{ page.date | date_to_xmlschema }}" itemprop="datePublished">{{ page.date | date: "%b %-d, %Y" }}</time>{% if page.author %} • <span itemprop="author" itemscope itemtype="http://schema.org/Person"><span itemprop="name">{{ page.author }}</span></span>{% endif %}</p>
+<p class="post-meta">{% if page.date %}<time datetime="{{ page.date | date_to_xmlschema }}" itemprop="datePublished">{{ page.date | date: "%b %-d, %Y" }}</time>{% endif %}{% if page.author %} • <span itemprop="author" itemscope itemtype="http://schema.org/Person"><span itemprop="name">{{ page.author }}</span></span>{% endif %}</p>
```
{% endraw %}

E agora, o que nos resta? Experimentar.

Bem... pelo menos não quebrou, mas não foi útil. Não consegui acessar nem ficou ali
dentro do `feed.xml`. Portanto, este experimento para o estado atual do blog não
funcionou.

## Experimento com campo novo

Basicamente aqui a ideia é, se o campo novo existir, com o valor adequado,
não listo. A publicação precisa continuar com data em seu nome de arquivo, mas
agora vou simplesmente ignorar. Só precisa de mudança no `index`. Note que
estou ativamente ignorando mudanças no `feed.xml`.

Bem, a situação que eu gostaria de testar é:

- se o meu post tiver o campo específico
- se o campo específico tiver o valor específico

Se isso for verdade, ignora. Como se fosse algo como `if !(post.field == 'value')`.
E advinha se por acaso o Ruby não tem algo equivalente ao `if ! condition`? Sim,
tem a cláusula `unless condition`. E o liquid possui a tag de controle de fluxo
`unless` também, além da `if`.

Com isso, se o nome do campo dentro do frontmatter for `draft`, ele ser uma string
que é para sumir se tiver o valor `true`, eu só preciso fazer isto no `index`:

{% raw %}
```diff
    {% for post in site.posts %}
+     {% unless post.draft == 'true' %}
      <li>
        <span class="post-meta">{{ post.date | date: "%b %-d, %Y" }}</span>

        <h2>
          <a class="post-link" href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
        </h2>
      </li>
+     {% endunless %}
    {% endfor %}
```
{% endraw %}

E pronto.

E adivinha? Sim, deixei [um exemplo de rascunho público]({% post_url 2022-10-26-eu-sou-rascunho %}).
---
layout: post
title: "Linkando post com arquivo do GitLab"
author: "Jefferson Quesado"
tags: jekyll meta gitlab liquid
base-assets: "/assets/doubly-link-post-file/"
---

Fui começar a fazer um artigo e senti a real necessidade de fazer o link
de um post com seu arquivo no GitLab.

Na real, a origem ser o GitLab é irrelevante, afinal poderia ser qualquer
repositório Git que fosse possível pegar um arquivo. A ideia é basicamente
adicionar nos posts (talvez abra para outras páginas com _frontmatter_?)
um link para onde o arquivo está publicado, simples assim.

Bem, os posts seguem o layout
[`post.html`]({{ site.repository.blob_root }}/_layouts/post.html). Então
podemos alterar logo ele para pegar isso. Mas, só isso não é o suficiente.
Sabe por quê? Porque precisamos de mais metadados do blog, especificamente
do repositório. Então, que tal começar com isso?

# Achando o link adequado

No Jekyll tem um arquivo de configuração chamado
[`_config.yml`]({{ site.repository.blob_root }}/_config.yml) que preenche
uma variável que podemos usar nas páginas chamada de `site`. Então, se eu
quero poder manusear a raiz dos blobs, posso criar um objeto dentro de `site`
chamado de `repository`, e dentro dele posso botar por exemplo `blob_root`:

```yml
repository:
  base: "https://gitlab.com/computaria/blog/"
  blob_root: "https://gitlab.com/computaria/blog/-/blob/master/"
  tree_root: "https://gitlab.com/computaria/blog/-/tree/master/"
```

Por que colocar o `blob_root` e não ficar apenas com a UTL base do repositório?
Porque o GitLab coloca na navegação `/-/blob/{branch}/` para navegar em um blob
dentro de um branch e `/-/tree/{branch}/` para navegar em um diretório dentro
do branch. Existe essa particularidade de posições que eu não costumo lembrar,
então para evitar precisar ficar se repetindo continuamente, preferi adotar
essa abordagem de acessar o atributo do `repository`. Mas, como fica isso de
apontar para, por exemplo, o layout do post?

Fica assim:

```md
{%- raw -%}
[`post.html`]({{ site.repository.blob_root }}/_layouts/post.html)
{% endraw %}
```

[`post.html`]({{ site.repository.blob_root }}/_layouts/post.html)

Ok, e para gerar a partir do post? Preciso manusear os dados do post.
Como por exemplo `page.url`. Estamos lidando com algo que se escreve assim:
`{{ page.url }}`. Na estrutura atual de posts, a data fica no format
`yyyy-MM-dd`, e depois vem `-<nome na url do post>.md`, tudo
isso na pasta [`/_posts/`]({{ site.repository.tree_root }}/_posts/). Ou seja,
seria transformar o que se tem `{{ page.url }}` arrancando o primeiro caracter, 
trocaria todas as barras `/` por `-`, colocaria `.md` no final e faria um
`prepend` com a base da URL para blobs seguido de `/_posts/`. E sabe o
que faz isso essa substituição de `/` por `-` do jeito certo? O
filtro liquid `slugify` ([referência](https://jekyllrb.com/docs/liquid/filters/)):

```md
{%- raw -%}
`{{ page.url | slugify }}`
{% endraw %}
```

> `{{ page.url | slugify }}`

Ou seja, a partir disso, só precisa fazer os prepends e o append, certo? Vamos testar:

```md
{%- raw -%}
[Auto referente]({{ page.url | slugify | prepend: "/_posts/" | prepend: site.repository.blob_root | append: ".md" }})
{% endraw %}
```

> [Auto referente]({{ page.url | slugify | prepend: "/_posts/" | prepend: site.repository.blob_root | append: ".md" }})

Bem, não tem como testar agora pelo fato de que este post está em draft e não no repositório do
branch principal. Mas podemos tentar com outro post, vamos? Que tal com o
[Rakefile, parte 2 - criando rascunho]({% post_url 2023-12-30-rakefile-create-draft %})?
Que foi o último meta-post até o momento?

Vamos lá. Estou citando dessa maneira: `{%- raw -%}{% post_url 2023-12-30-rakefile-create-draft %}{% endraw %}`. Primeiro eu não consigo manusear diretamente esse `post_url`, ele é uma tag liquid,
não um filtro. Então eu posso jogar o valor dele em uma variável:

```liquid
{%- raw -%}
{% capture rake2_create %}{% post_url 2023-12-30-rakefile-create-draft %}{% endcapture %}
{% endraw %}
```

Então eu poderia citar `rake2_create` em uma expansão liquid convencional. Abaixo o resultado:

{%- capture rake2_create -%}{% post_url 2023-12-30-rakefile-create-draft %}{% endcapture %}

```
{{ rake2_create }}
```

Ok, bingo! Ou quase... acabou capturando `blog` que não estava na minha mente. Mas posso remover
tranquilamente isso usando o
[filtro liquid `remove_first`](https://shopify.github.io/liquid/filters/remove_first/):

```liquid
{%- raw -%}
{{ rake2_create | remove_first: "/blog" }}
{% endraw %}
```

```
{{ rake2_create | remove_first: "/blog" }}
```

Ok, hora de aplicar o resto da concatenação acima:

```liquid
{%- raw -%}
{{ rake2_create | remove_first: "/blog" | slugify | prepend: "/_posts/" | prepend: site.repository.blob_root | append: ".md" }}
{% endraw %}
```

```
{{ rake2_create | remove_first: "/blog" | slugify | prepend: "/_posts/" | prepend: site.repository.blob_root | append: ".md" }}
```

E o link?
[Aqui, vai clica]({{ rake2_create | remove_first: "/blog" | slugify | prepend: "/_posts/" | prepend: site.repository.blob_root | append: ".md" }}).
Curtiu?

# Aplicando no layout

Ok, link em mãos (na real, obtível), vamos alterar o layout afinal? Eu acho que ficaria
super bonitinho com o ícone do GitLab (já que o uso como repositório).

```html
{%- raw -%}
<a href='{{ rake2_create | remove_first: "/blog" | slugify | prepend: "/_posts/" | prepend: site.repository.blob_root | append: ".md" }}'>
<span class="icon icon--gitlab">{% include icon-gitlab.svg %}</span>
</a>
{% endraw %}
```

E fica assim:

<a href='{{ rake2_create | remove_first: "/blog" | slugify | prepend: "/_posts/" | prepend: site.repository.blob_root | append: ".md" }}'>
<span class="icon icon--gitlab">{% include icon-gitlab.svg %}</span>
</a>



O exemplo foi com o post
[Rakefile, parte 2 - criando rascunho]({% post_url 2023-12-30-rakefile-create-draft %}),
mas podemos simplesmente usar a auto referência usada mais cedo:
<a href='{{ page.url | slugify | prepend: "/_posts/" | prepend: site.repository.blob_root | append: ".md" }}'>
<span class="icon icon--gitlab">{% include icon-gitlab.svg %}</span>
</a>. Usando isso no layout
de posts, ao lado do nome do usuário. E funcionou para todas as páginas.
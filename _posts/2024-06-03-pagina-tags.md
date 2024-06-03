---
layout: post
title: "Usando as tags - Parte 1: página de tags"
author: "Jefferson Quesado"
tags: meta jekyll ruby
base-assets: "/assets/pagina-tags/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Eu sempre coloco tags nos posts com intenção de
fazer linkagem entre as tags. Mas, que tal, fazer
uso dessa metadado e transformar em algo útil?

Esse é o primeiro post em uma série de 3 posts
sobre colocar tags no Computaria. Os outros são:

1. Página de tags
1. Tags nos posts, visível
1. Tags no índice

# Plugins do Jekyll

Para alterar o comportamento do Jekyll para algo além
do que ele foi configurado para fazer, você precisa
enxertar código nele. No caso, como Jekyll roda em Ruby,
se enxerta código Ruby. E o jeito que o Jekyll prevê de
se fazer isso é usando o que ele chama de "plugins".

Os plugins se situam (localmente) na pasta `/_plugins/`,
com referência da raiz padrão do Jekyll, onde está o
`_config.yml`. Localmente, não precisa fazer nenhuma
alteração no arquivo de configuração, o que é diferente
de quando se importa uma gem que você precisa especificar
em no campo `plugins` o que você deseja usar, como aqui
no computaria se usa o `jekyll-katex`.

## Generators do Jekyll

Especificamente, para gerar uma página, as referências apontam
para se usar um tal de
[`generator`](https://jekyllrb.com/docs/plugins/generators/).
No primeiro momento, não entendi o que se dizia da documentação,
mas uma coisa me chamou muito a atenção:

> Method: `generate`. Description: Generates content as a side-effect.

Tradução livre da descrição:

> Gera conteúdo como efeito-colateral.

O que fazer com isso? Bem, por hora, guardar na cabeça. Vamos
a classe foco daqui: `Jekyll::Generator`. Ela tem um método de
atenção: `generate(site)`. Como brincar com isso? Que tal
interceptar isso?

Coloca a dependência do `irb`, `bundle install` para pegar
a atualização disso em específico, e no arquivo que está o
`Generator`, dentro do `generate(site)`: `IRB.start(__FILE__)`.

Ok, _naïve_ demais. Colocar o campo `site` como acessível
ao `irb` seria bem melhor:

```ruby
require "jekyll"
require 'irb'

module Computaria
    def self.s(site)
        @@site = site
    end

    def self.site
        @@site
    end
    
    class Generator < Jekyll::Generator
        def generate(site)
            @@site = site
            Computaria.s(site)

            IRB.start(__FILE__)
        end
    end
end
```

E dentro do `irb` bastaria um `Computaria.site` para inspecionar os
seus atributos:

```ruby
rb(main):001> Computaria.site
=> #<Jekyll::Site @source=/path/to/computaria/blog>
```
 
Lá dentro, conheci o seguinte:

- `site.categories`: um mapa de nome da categoria para lista de páginas daquilo
- `site.posts`: a lista de postagens
- `site.pages`: a lista de "páginas"
- `site.tags`: a "lista" de tags
- `site.static_files`: a lista de arquivos estáticos

Sobre `site.pages` descobri uma coisa bem legal, que fez bastante sentido
agora quando percebi problemas em
[Oops, quebrei o about, e agora?]({% post_url 2024-05-19-oops-about %})
e [Criando páginas discretas]({% post_url 2023-08-31-paginas-discretas %}):
na listagem de `site.pages` aparecia `.css`, aparecia `.js`, até `.xml`.
Porque, ao ser um arquivo a ser processado com Liquid, ele era colocado
em `site.pages` antes de ser processado pelo Liquid. Logo, aquilo que
eventualmente seria processado pelo Liquid era considerado a priori
como uma "page" e, por isso, estava ali. Como no
[Deixando a pipeline visível para acompanhar deploy do blog]({% post_url 2024-05-19-pipeline-visible %})
foi usado o Liquid para (por exemplo) o javascript de carregar
a página de pipeline, ele acabou indo parar no `about` e
causando a quebra mencionado no
[Oops, quebrei o about, e agora?]({% post_url 2024-05-19-oops-about %}).

Para adicionar uma página, preciso apenas fazer um `site.pages << my_page`,
considerando que `my_page` seja um objeto do tipo `Jekyll::Page`.

## Criando uma página

Primeiro, experimentar criar uma página de exemplo. Examinando uma das páginas
geradas, vi que o conteúdo era gerado dentro do campo `@content`. Então, vamos
criar um conteúdo com parte markdown? E parte Liquid?

Coloquei no generator uma coisa bem simples:

```ruby
site.pages << Marmota.new(site)
```

E agora fica a questão de definir `Marmota`. Para interpretar markdown, precisei
identificar a extensão (campo `@ext`) como sendo `.md`. No primeiro momento eu
fiz assim:

{% raw %}
```ruby
class Marmota < Jekyll::Page
    def initialize(site)
        @site = site
        @ext = ".md"
        @content = "
# Título

Alguma coisa

> {{ site.url }}
        "
    end
end
```
{% endraw %}

E falhou miseravelmente:

```none
  Liquid Exception: undefined method `[]' for nil:NilClass in <...>/computaria/blog/_layouts/default.html
rake aborted!
NoMethodError: undefined method `[]' for nil:NilClass (NoMethodError)

      @excerpt = data["excerpt"] ? data["excerpt"].to_s : nil
                     ^^^^^^^^^^^
<...>/computaria/blog/Rakefile:11:in `block in <top (required)>'
```

Mas por quê? Porque basicamente tudo no Liquid é gerado lendo o campo `data`. Próxima iteração,
adicionar um `@data` vazio:

{% raw %}
```ruby
class Marmota < Jekyll::Page
    def initialize(site)
        @site = site
        @ext = ".md"
        @data = {

        }
        @content = "
# Título

Alguma coisa

> {{ site.url }}
        "
    end
end
```
{% endraw %}

Ok, agora gerou. Mas teve um conflito:

```none
Conflict: The following destination is shared by multiple files.
          The written file may end up with unexpected contents.
          <...>/computaria/blog/_site/index.html
          - index.html
          - 
```

Por que isso? Porque o Jekyll usa algumas dicas para gerar a URL
da página. E no caso na ausência de dicas ele assume `index.html`
do local onde ele aponta. No caso, não aponta pra nada, então
é um conflito com a raiz do blog. Nada bom. Cutucando as propriedades
descobri que era `@basename`, e assim funcionou:

{% raw %}
```ruby
class Marmota < Jekyll::Page
    def initialize(site)
        @site = site
        @ext = ".md"
        @data = {

        }
        @basename = "marmota"
        @content = "
# Título

Alguma coisa

> {{ site.url }}
        "
    end
end
```
{% endraw %}

E ficou assim o renderizado:

```html
<html><head></head><body><h1 id="título">Título</h1>

<p>Alguma coisa</p>

<blockquote>
  <p>https://computaria.gitlab.io</p>
</blockquote>

</body></html>
```

<iframe src="{{ page.base-assets | append: 'marmota1.html' | relative_url }}" class="clean-background">
</iframe>

> Para colocar esse `<iframe>` bonitinho eu precisei limpar o background.
> Para tal, poderia ter feito inline um `style="background-color: white"`. Mas
> ao examinar como o resto do blog estava lidando com a cor de fundo, cheguei
> a conclusão que talvez não fosse a melhor escolha deixar inline, pois se
> dependia de um valor `$background-color` no `scss`. Para manter isso,
> criei a classe `clean-background` assim:
> 
> ```scss
.clean-background {
    background-color: $background-color;
}
```
> e adicionei as classes da tag `<iframe class="clean-background">`

Mas, falando sério? Ficou feio pra caramba. Porque não pegou o layout básico.
Como o layout é algo que vai ser no frigir de tudo manipulado pelo Liquid,
ele reside dentro do campo `data`:

{% raw %}
```ruby
class Marmota < Jekyll::Page
    def initialize(site)
        @site = site
        @ext = ".md"
        @data = {

        }
        @basename = "marmota"
        @content = "
# Título

Alguma coisa

> {{ site.url }}
        "
    end
end
```
{% endraw %}

Vale a pena criar subir localmente e acessar baseado no nome do arquivo
(no caso, `/marmota`).

Mais alguns campos que podem vir a ser úteis, por questão de completude:

{% raw %}
```ruby
class Marmota < Jekyll::Page
    def initialize(site)
        @site = site
        @ext = ".md"
        @data = {

        }
        @basename = "marmota"
        @base = "#{site.source}/marmota"
        @name = "marmota.md"
        @content = "
# Título

Alguma coisa

> {{ site.url }}
        "
    end
end
```
{% endraw %}

## Criando uma página de tags

Ok, agora que sei o básico de se criar uma página dinamicamente,
vamos focar no alvo principal: criar a página das tags.

Vou pegar a tag `frontend` para motivar, porque ela tem diversos
posts (5 publicados, 1 rascunho local). A priori, quero fazer ela
tal qual é a [`index.html`]({{ site.repository.blob_root}}/index.html).

Esse vai ser um layout a ser usado pelas diversas listagens de tags,
portanto vou aproveitar e criar logo o layout
[`tag-list.html`]({{ site.repository.blob_root}}/_layouts/tag-list.html).
Só que, no caso, no lugar de resgatar as informações através da
variável `site.posts`, vou resgatar de `page.posts`. Ficou assim
a primeira iteração:

{% raw %}
```html
---
layout: default
---

<div class="home">

  <h1 class="page-heading">Posts</h1>

  <ul class="post-list">
    {% for post in page.posts %}
      {% unless post.draft == 'true' %}
        <li>
          <span class="post-meta">{{ post.date | date: "%b %-d, %Y" }}</span>

          <h2>
            <a class="post-link" href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
          </h2>
        </li>
      {% endunless %}
    {% endfor %}
  </ul>

  <p class="rss-subscribe">subscribe <a href="{{ "/feed.xml" | prepend: site.baseurl }}">via RSS</a></p>

</div>
```
{% endraw %}

Hmmmm, o "subscribe" ali ficou fora de canto, melhor remover. E também não está
indicando qual a tag, então melhor colocar a tag em ênfase. Próxima iteração:

{% raw %}
```html
---
layout: default
---

<div class="home">

  <h1 class="page-heading">Posts de {{ page.tag }}</h1>

  <ul class="post-list">
    {% for post in page.posts %}
      {% unless post.draft == 'true' %}
        <li>
          <span class="post-meta">{{ post.date | date: "%b %-d, %Y" }}</span>

          <h2>
            <a class="post-link" href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
          </h2>
        </li>
      {% endunless %}
    {% endfor %}
  </ul>
</div>
```
{% endraw %}

Ok, melhorou. Agora preciso me lembrar de, na hora de criar a página,
além de povoar o `@data["posts"]` com os posts também preencher o
`@data["tag"]` com o nome da tag.

Bem, tudo tranquilo. Certo? Vamos inserir na nossa página `Marmota`
para ver como fica, depois vamos lidar com outras questões como
botar no canto certo:

```ruby
class Marmota < Jekyll::Page
    def initialize(site)
        @site = site
        @ext = ".html"
        @data = {
            "layout" => "tag-list",
            "tag" => "frontend",
            "posts" => site.tags["frontend"]
        }
        @basename = "marmota"
    end
end
```

Ok, deu bom. Mas tem um caso estranho... e se por acaso todas
as publicações forem com
[`posts.draft == "true"`]({% post_url 2022-10-26-public-draft %})?
Isso significa gerar uma página apenas com o nome da tag sem post algum.

Para eventualmente contornar isso, vou assumir um protocolo:
só irei criar páginas de tags caso tenho no mínimo uma
postagem sem ser `draft`. E digo mais: já irei passar,
garantidamente, os posts filtrados sem nenhum `draft`.

Bem, já que estou seguindo esse protocolo, não tem mais porque filtrar
para exibir apenas os posts não rascunhos, né? Nesse caso, vamos
remover o condicional do layout:

{% raw %}
```html
---
layout: default
---

<div class="home">

  <h1 class="page-heading">Posts de {{ page.tag }}</h1>

  <ul class="post-list">
    {% for post in page.posts %}
        <li>
          <span class="post-meta">{{ post.date | date: "%b %-d, %Y" }}</span>

          <h2>
            <a class="post-link" href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
          </h2>
        </li>
    {% endfor %}
  </ul>
</div>
```
{% endraw %}

Como vou chamar desse jeito, vamos adaptar aqui a chamada de `Marmota`
para já construir em cima dos posts filtrados:

```ruby
posts = site.tags["frontend"]
posts_local = posts.select do |p|
    p.data["draft"] != 'true'
end
site.pages << Marmota.new(site, posts_local) unless posts_local.empty?

# definição da classe Marmota

class Marmota < Jekyll::Page
    def initialize(site, posts)
        @site = site
        @ext = ".html"
        @data = {
            "layout" => "tag-list",
            "tag" => "frontend",
            "posts" => posts
        }
        @basename = "marmota"
    end
end
```

E assim temos o layout
[`tag-list.html`]({{ site.repository.blob_root}}/_layouts/tag-list.html).

## Iterando para gerar as páginas de tags

Já temos quase tudo que precisamos para a página de tags.
Podemos deixar ainda mais adequado passando os posts filtrados
e, também, a tag em si. Desse modo, não precisamos mais nos
preocupar com a tag hard-codada. Aproveitar também e aposentar
a classe `Marmota`, vamos chamar de `TabPage`.

A iteração vai ser feita em cima de `site.tags`. Para iterar
em cima de um dicionário em Ruby, pedimos para `dict.each` e
passamos um bloco de código que aceita duas variáveis: a
chave do dicionário e o seu valor. A filtragem de valor
é usando `array.select`, passando um bloco que, ao retornar
`true`, mantém o elemento e ao retornar `false` ele não é
inserido na coleção resultante.

```ruby
site.tags.each do |tag, posts|
    posts_local = posts.select do |p|
        p.data["draft"] != 'true'
    end
    site.pages << TagPage.new(site, tag, posts_local) unless posts_local.empty?
end
```

Só isso infelizmente gerou o conflito de nomes. Todas as tags foram geradas
para o mesmo endereço. Para resolver, basta colocar que o `basename` dela
dependa também da tag passada:

```ruby
class TagPage < Jekyll::Page
    attr_reader :tag, :posts, :data
    def initialize(site, tag, posts)
        @site = site             # the current site instance.
        @base = "#{site.source}/#{tag}"  # path to the source directory.
        @dir  = "tags/#{tag}"         # the directory the page will reside in.
        @tag = tag
        @posts = posts

        # All pages have the same filename, so define attributes straight away.
        @basename = 'index'      # filename without the extension.
        @ext      = '.html'      # the extension.
        @name     = 'index.html' # basically @basename + @ext.

        # Initialize data hash with a key pointing to all posts under current category.
        # This allows accessing the list in a template via `page.linked_docs`.
        @data = {
            "layout" => "tag-list",
            "tag" => tag,
            "posts" => @posts,
            "title" => tag
        }
    end
end
```

Para ter um permalink mais adequado, coloquei as páginas geradas dentro
da categoria `tags`. Isso significou, neste instante, que preciso criar
o objeto de `TabPage` e adicionar simultaneamente a `site.pages`
e também a `site.categories["tags"]`.

Para isso, vou usar o `continue` adequado dentro do bloco: o `next`.
Assim, ao chegar em um valor que não deve ser manipulado (todos os posts
da tag serem rascunhos), ele irá ignorar a execução daquele bloco
específico e partir pra próxima iteração:

```ruby
site.categories["tags"] = []
site.tags.each do |tag, posts|
    posts_local = posts.select do |p|
        p.data["draft"] != 'true'
    end
    next if posts_local.empty?
    tagPage = TagPage.new(site, tag, posts_local)
    site.categories["tags"] << tagPage
    site.pages << tagPage
end
```

## Listando todas as tags

Até agora, tudo bom, mas essas páginas estão inalcançáveis.
Precisaria ter uma página central com a listagem de todas as
tags. Vamos criar uma página central que recebe todas as páginas
de tags criadas? Já tenho mesmo um vetor só pra isso
através das categorias. A ideia é chamar uma classe de página
e isto bastar:

```ruby
central = CentralTag.new(site, site.categories["tags"])
site.categories["tags"] << central
site.pages << central
```

Vamos seguir o modelo de páginas do índice de posts e também do
índice de posts por tag. Só que, agora, como o post individual não
está sendo levado em consideração na iteração, preciso de outra
coisa para o metadado. Que tal a quantidade de postagens? Algo assim:

{% raw %}
``` html
<div class='home'>

<h1 class='page-heading'>Posts por tag</h1>

<ul class='post-list'>
    {% for tag in page.sitetags %}
        <li>
            <span class='post-meta'>{{ tag.posts.size }} posts</span>
            <h2>
                <a class='post-link' href='{{ tag.url | prepend: site.baseurl }}'>{{ tag.tag }}</a>
            </h2>
        </li>
    {% endfor %}
</ul>
</div>
```
{% endraw %}

Do jeito que está a ordem das tags parece bem aletória. Então, será que podemos
organizar por nome? Claro. O array fornece o método `sort_by`:

```ruby
tags.sort_by do |element|
    element.tag
end
```

esse método permite dizer o que deve ser levado em consideração na hora de
ordenar os elementos. No caso, estou querando usar a string `tag`, que é
um atributo de `TagPage`.

Hmmm, algumas coisas não ficaram legais. Para garantir uma bela ordenação,
resolvi que deveria comparar com "lowercase". Depois percebi que o 
acento em `álgebra` estava atrapalhando. Daí foi mal fácil resolver esse
problema de imediato com o `á` trocando-o por `a`:

```ruby
tags.sort_by do |element|
    element.tag.downcase.gsub("á", "a")
end
```

Ficando assim o todo:

{% raw %}
```ruby
class CentralTag < Jekyll::Page
    def initialize(site, tags)
        @site = site           # the current site instance.
        @base = site.source    # path to the source directory.
        @dir  = "tags"         # the directory the page will reside in.

        # All pages have the same filename, so define attributes straight away.
        @basename = 'index'      # filename without the extension.
        @ext      = '.html'      # the extension.
        @name     = 'index.html' # basically @basename + @ext.

        # Initialize data hash with a key pointing to all posts under current category.
        # This allows accessing the list in a template via `page.linked_docs`.
        @data = {
            "layout" => "default",
            "sitetags" => tags.sort_by do |element| element.tag.downcase.gsub("á", "a") end,
            "show" => true,
            "title" => "Tags"
        }

        @content = "
<div class='home'>

<h1 class='page-heading'>Posts por tag</h1>

<ul class='post-list'>
    {% for tag in page.sitetags %}
        <li>
            <span class='post-meta'>{{ tag.posts.size }} posts</span>
            <h2>
                <a class='post-link' href='{{ tag.url | prepend: site.baseurl }}'>{{ tag.tag }}</a>
            </h2>
        </li>
    {% endfor %}
</ul>
</div>
          
        "
    end
end
```
{% endraw %}

# Leituras sobre o assunto

- [Documentação oficial](https://jekyllrb.com/docs/plugins/generators/)
- [Um exemplo](https://github.com/avillafiorita/jekyll-datapage_gen/blob/master/lib/jekyll-datapage-generator.rb)
- [Fonte de `Page`](https://github.com/jekyll/jekyll/blob/master/lib/jekyll/page.rb)
- [Fonte de `Site`](https://github.com/jekyll/jekyll/blob/master/lib/jekyll/site.rb)

---
layout: post
title: "Criando o blog com Jekyll no GitLab"
author: "Jefferson Quesado"
tags: meta jekyll liquid ruby gitlab-ci
---

O primeiro passo para isso foi de fato pegar o exemplo do GitLab. Porém, o template
fornecido me dava acesso a uma versão antiga do Jekyll, a `3.4.0`... E eu realmente desejava
rodar com a versão 3 do Ruby (que tinha recém instalado na minha máquina).

Então, o que fazer? Bem, a primeira coisa foi tentar corrigir o `Gemfile.lock`. Como? Apagando-o
e mandando o `bundler` gerar novamente.

```bash
$ rm Gemfile.lock
$ bundle update
```

Com isso, consegui atualizar o arquivo de lock, porém as coisas ainda não estavam indo bem.
Chegou a hora de mudar a versão do `jekyll` dentro do `Gemfile`. Ele ficou assim:

```ruby
source "https://rubygems.org"
ruby RUBY_VERSION

# This will help ensure the proper Jekyll version is running.
gem "jekyll", "4.2.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
```

Então a primeira coisa que vi foi uma observação para colocar a gem [`wdm`](https://rubygems.org/gems/wdm/).
O que é essa gem? Bem, o nome dela significa _Windows directory monitor_, ela é uma espécie de observador que permite
que o Jekyll fique constantemente monitorando o diretório e percebendo atualizações nele através da API
de arquivos do Windows. Adicionei-a no caso de usar o Windows:


```ruby
source "https://rubygems.org"
ruby RUBY_VERSION

# This will help ensure the proper Jekyll version is running.
gem "jekyll", "4.2.0"
gem 'wdm', '~> 0.1.0' if Gem.win_platform?

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
```

Ainda assim, ao tentar subir o Jekyll localmente, deu problema ao carregar o `webrick` em uma das bibliotecas
internas. Achei estranho, pois estava acostumado com o `webrick` sendo parte padrão do Ruby, então fiz o seguinte teste:


```bash
$ irb
irb(main):001:0> require 'webrick'
<internal:C:/Ruby30-x64/lib/ruby/3.0.0/rubygems/core_ext/kernel_require.rb>:85:in `require': cannot load such file -- webrick (LoadError)
        from <internal:C:/Ruby30-x64/lib/ruby/3.0.0/rubygems/core_ext/kernel_require.rb>:85:in `require'
        from (irb):1:in `<main>'
        from C:/Ruby30-x64/lib/ruby/gems/3.0.0/gems/irb-1.3.5/exe/irb:11:in `<top (required)>'
        from C:/Ruby30-x64/bin/irb:23:in `load'
        from C:/Ruby30-x64/bin/irb:23:in `<main>'
irb(main):002:0>
```

E aí? Cheguei a conclusão que é melhor confiar o `webrick` da gem do que o que deveria vir no Ruby, então adicionei-o ao `Gemfile`:

```ruby
source "https://rubygems.org"
ruby RUBY_VERSION

# This will help ensure the proper Jekyll version is running.
gem "jekyll", "4.2.0"
gem "webrick"
gem 'wdm', '~> 0.1.0' if Gem.win_platform?

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
```

Ok, com isso eu já tenho o Jekyll rodando na minha máquina e posso inciar os _drafts_:

```bash
$ bundle exec jekyll server --drafts
```

E assim ele sobe o servidor pronto para ser acessado em http://localhost:4000/jekyll/

## Revisando o _bootstrapping_

1. instalar o Ruby 3
2. `gem install bundler`
3. atualizar a versão do `jekyll`
3. no caso de mexer no Windows, adicionar a dependência do `wdm`  
   a importância do `if Gem.win_platform?` é a garantia de só aplicar isso no Windows
4. adicionar a dependência do `webrick`

Tudo isso feito com base no exemplo do próprio GitLab, que me forneceu baseado num Jekyll antigo.

## Corrigindo o CI

Com a parte mais corrigida em relação a rodar localmente o Jekyll, ainda precisamos
por no ar o blog. A imagem padrão que vem no `.gitlab-ci.yml` é `ruby:2.3`, e ele não
funciona adequadamente com as novas versões das gems. O exemplo do GitLab usa `ruby:latest`,
mas eu particularmente preferi me ater a uma versão específica do Ruby, então optei por usar a
imagem `ruby:3.0-alpine`.

Isso permite que se consiga fazer o deploy do blog, e agora?

## Corrigindo configuração quebrada

A primeira coisa que pude perceber é que o CSS estava completamente desformatado:

![Print CSS quebrado]({{ "/assets/criando-blog/screen-css-quebrado.png" | relative_url }})

Mas, onde poderia ter quebrado o link do CSS?

Olhando a aba de "rede" no painel do desenvolvedor, verifiquei que o CSS realmente deu 404 para a URL
[{{ site.url }}/jekyll/css/main.css]({{ site.url }}/jekyll/css/main.css)

Vamos lá, o site está sendo lançado em [{{ site.url }}{{ site.baseurl }}]({{ site.url }}{{ site.baseurl }}), não tenho nenhum domínio
sobre [{{ site.url }}/jekyll]({{ site.url }}/jekyll) !!

Portanto, a atenção precisa ser voltado ao `_config.yml`. Ele veio inicialmente com a seguinte configuração:

```yml
title: Example Jekyll site using GitLab Pages
email: your-email@domain.com
description: > # this means to ignore newlines until "baseurl:"
  Write an awesome description for your new site here. You can edit this
  line in _config.yml. It will appear in your document head meta (for
  Google search results) and in your feed.xml site description.
baseurl: "/jekyll" # the subpath of your site, e.g. /blog
url: "/" # the base hostname & protocol for your site
twitter_username: jekyllrb
github_username:  jekyll
gitlab_username:  pages

# Outputting
permalink: /:categories/:year/:month/:day/:title

# Build settings
markdown: kramdown
exclude: ["README.md"]
```

Como resolver isso? Colocando as informações corretas em `url` e em `baseurl`. No meu caso:

```yml
baseurl: "/blog" # the subpath of your site, e.g. /blog
url: "https://computaria.gitlab.io" # the base hostname & protocol for your site
```

Ao subir essas mudanças:

![Print CSS quebrado]({{ "/assets/criando-blog/screen-css-ok.png" | relative_url }})

# Adicionando assets visuais

Sofri com um problema ao tentar colocar as imagens deste artigo. Mas, por quê?

Bem, eu escrevi em markdown. Então, tentei usar _apenas_ markdown para descrever o blog.
Então, fiz o link normal apontando para `/assets/criando-blog/screen-css-quebrado.png`. O
que aconteceu? Aconteceu que o link local apontou para `http://localhost:4000/assets/criando-blog/screen-css-quebrado.png`,
e isso não estava sendo servido pelo Jekyll. O que estava sendo servido era
`http://localhost:4000/blog/assets/criando-blog/screen-css-quebrado.png`. Então, como faço para
deixar o link para o canto correto?

Bem, lendo sobre como [Jekyll interpreta as coisas](https://jekyllrb.com/tutorials/orderofinterpretation/),
percebi que uma das primeiras etapas é expandir as variáveis Liquid, antes mesmo de interpretar
o markdown. Então chego exatamente no seguinte exemplo de _liquid filter_:

{% raw %}
```none
{{ "css/main.css" | relative_url }}
```
{% endraw %}

O que isso faz? Primeiro, ele pega uma string, `"css/main.css"`. Então ele manda essa string
e envia para o filtro `relative_url`. O que esse filtro faz exatamente? Ele assume que você quer
colocar uma string como um link relativo ao blog, então o próprio Jekyll vai resgatar as variáveis no
`_config.yml` e descobrir qual valor ele deve inserir para tornar isso em uma URL relativa.

Então, será que podemos usar isso dentro do próprio markdown? Bem, por que não testar?

{% raw %}
```md
> ![Print CSS quebrado]({{ "/assets/criando-blog/screen-css-ok.png" | relative_url }})
```
{% endraw %}

Isso gera:

> ![Print CSS quebrado]({{ "/assets/criando-blog/screen-css-ok.png" | relative_url }})

Bacana, né? Infelizmente não encontrei um jeito mais direto, mas também não é uma volta muito grande.

# Imprimindo Liquid literal

Para explicar como eu consegui imprimir as informações 

```md
{{ "%7B%25 raw %25%7D" | url_decode }}

{%- raw -%}
{{ "/assets/criando-blog/screen-css-ok.png" | relative_url }}
{% endraw %}

{{ "%7B%25 endraw %25%7D" | url_decode }}
```

Ok, e como fiz para imprimir o código acima? Com as tags do Liquid bem direitinho?
Bem, eu caminhei por algumas alternativas antes...

1. tentei atribuir a uma variável [`{{ "%7B%25 assign var = valor %25%7D" | url_decode }}`](https://shopify.github.io/liquid/tags/variable/#assign),
   porém quando conseguia compilar soltava warnings
2. tentei capturar com [`{{ "%7B%25 capture var %25%7D" | url_decode }}`](https://shopify.github.io/liquid/tags/variable/#capture),
   mas ainda assim precisei depois fazer tratativas de substituição
3. pegar uma string com escapes URL e mandar pro filtro `url_decode`, como em
   `{{ "%7B%7B %22%257B%2525 raw %2525%257D%22 %7C url_decode %7D%7D" | url_decode }}`, que gera `{{ "%7B%25 raw %25%7D" | url_decode }}`

A última alternativa se mostrou a mais fácil de tratar e expandir. Quando preciso imprimir informações sobre a tag, só aumentar
a quantidade de escapes URL.

# Habilitando TeX

O último passo para a subir o blog é colocar o TeX para funcionar. Eu particularmente
gosto do KaTeX. Inclusive é esse [o motor de renderização de TeX que o
GitLab usa](https://docs.gitlab.com/ee/user/markdown.html#math).

Então, como habilitar no Jekyll?

Felizmente, tem bastante informação no `README` deles para começar: [https://github.com/linjer/jekyll-katex](https://github.com/linjer/jekyll-katex)

1. colocar a gem
2. habilitar o plugin no `_config.yml`
3. incluir os CSSs do KaTeX

Só que isso não fornece o suficiente para trabalhar TeX via Markdown, apenas TeX via Liquid:


{% katex display %} 2^{10} \equiv 24 \pmod{1000} {% endkatex %}

Com direito à renderização inline também {% katex %}2^{10}\equiv 24\pmod{1000}{% endkatex %}.

Mas o KaTeX me fornece a outra tag Liquid, deixa as coisas ligeiramente mais amigáveis.

{% katexmm %}
Um exemplo inline $c = \pm\sqrt{a^2 + b^2}$

O mesmo exemplo em bloco:

$$
c = \pm\sqrt{a^2 + b^2}
$$
{% endkatexmm %}

Ainda assim, foram necessários alguns ajustes.

O primeiro foi que, para executar corretamente as coisas do KaTeX, eu precisava instalar um runtime
que falasse JavaScript com o Ruby. Existem algumas possibilidades, mas o que funcionou logo de cara
para mim foi a gem [`duktape`](https://github.com/judofyr/duktape.rb). Usei-a na versão mais atual na
época, `2.6.0.0`.

Com isso, obtivemos as seguintes alterações:

- `_config.yml`

  ```yml
  ...
  plugins:
    - jekyll-katex
  ...
  ```
  
- `_includes/head.html`

  ```html
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.13.13/dist/katex.min.css" integrity="sha384-RZU/ijkSsFbcmivfdRBQDtwuwVqK7GMOw6IMvKyeWL2K5UAlyp6WonmB8m7Jd0Hn" crossorigin="anonymous">

  <!-- The loading of KaTeX is deferred to speed up page rendering -->
  <script defer src="https://cdn.jsdelivr.net/npm/katex@0.13.13/dist/katex.min.js" integrity="sha384-pK1WpvzWVBQiP0/GjnvRxV4mOb0oxFuyRxJlk6vVw146n3egcN5C925NCP7a7BY8" crossorigin="anonymous"></script>
  ```
  
  > Note que é possível automatizar a compilação do KaTeX no client-side usando `<script defer src="https://cdn.jsdelivr.net/npm/katex@0.13.13/dist/contrib/auto-render.min.js" integrity="sha384-vZTG03m+2yp6N6BNi5iM4rW4oIwk5DfcNdFfxkk9ZWpDriOkXX8voJBFrAO7MpVl" crossorigin="anonymous" onload="renderMathInElement(document.body);"></script>`,
  > isso inclusive deixa livre das marcações Liquid, mas sinceramente acho seu uso para o meu fim questionável.
  > Melhor por hora deixar SSR mesmo.

- `Gemfile`

  ```ruby
  ...
  gem 'execjs', '~> 2.8.1'
  gem 'duktape', '~> 2.6.0.0'

  group :jekyll_plugins do
    gem 'jekyll-katex'
  end
  ...
  ```

Para gerar as fórmulas Tex acima usei os seguintes códigos:

```md
{{ "%7B%25 katex display %25%7D" | url_decode }}
{%- raw -%}
2^{10} \equiv 24 \pmod{1000}
{% endraw %}
{{ "%7B%25 endkatex %25%7D" | url_decode }}
```

{% katex display %}
2^{10} \equiv 24 \pmod{1000}
{% endkatex %}

Com `katexmm`:

```md
{{ "%7B%25 katexmm %25%7D" | url_decode }}
{%- raw -%}
Um exemplo inline $c = \pm\sqrt{a^2 + b^2}$

O mesmo exemplo em bloco:

$$
c = \pm\sqrt{a^2 + b^2}
$$
{% endraw %}
{{ "%7B%25 endkatexmm %25%7D" | url_decode }}
```

{% katexmm %}
Um exemplo inline $c = \pm\sqrt{a^2 + b^2}$

O mesmo exemplo em bloco:

$$
c = \pm\sqrt{a^2 + b^2}
$$
{% endkatexmm %}
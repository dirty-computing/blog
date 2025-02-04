---
layout: post
title: "Alpine morreu! Vida longa ao Alpine!"
author: "Jefferson Quesado"
tags: gitab-ci meta linux ruby
base-assets: "/assets/long-live-alpine/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

No começo, eu queria só atualizar uma lib:
[Atualizando o SASS do Computaria]({% post_url 2025-01-29-updating-sass %}).
Então, tudo começou a desandar...
[Quebrei o CSS com a publicação anterior, e agora?]({% post_url 2025-01-30-quebrei-css %}).

E eu saí com uma vitória amargurada, colocando para fazer o build do sistema
via uma imagem Debian, e não sobre o Alpine.

# A morte do rei

> -- Envenenado, ele foi envenenado.
> 
> O legista, sobre a causa da morte

Foi uma sucessão de erros que gerou o problema no final. Para começar, eu não
havia levantado o `Gemfile.lock` com as mudanças locais. Fui fazer isso apenas
em um momento posterior.

Depois, eu percebi que não havia aplicado o _freeze_. Minha primeira solução
foi inserir manualmente, mas um `bundle update` ou `bundle install` logo em
seguida iria remover as linhas inseridas manualmente. Isso não é bom, porque
o `Gemfile.lock` ficaria distinto do desejado. Como corrigir isso?

Bem, vamos olhar o final do lock:

```lock
PLATFORMS
  arm64-darwin-22
  x64-mingw32
  x86_64-linux

DEPENDENCIES
  cli-ui
  dotenv (~> 3.1)
  duktape (~> 2.6.0.0)
  execjs (~> 2.8.1)
  jekyll (= 4.3.3)
  jekyll-katex
  tzinfo-data
  webrick

RUBY VERSION
   ruby 3.2.1p31

BUNDLED WITH
   2.5.11
```

Olha que legal! Uma seção chamada `PLATFORMS`! Tem outra chamada
`DEPENDENCIES`, que contém as dependências explicitamente citadas no `Gemfile`.
Ok, `PLATFORMS` não tá no `Gemfile` em si. Então, será que consigo adicionar
uma plataforma no `lock`? Depois de pesquisar em alguns lugares, encontrei:

```bash
bundle lock --add-platform x86_64-linux-musl
```

Isso foi um dos pontos que causou problema ao atualizar, um dos pontos que
envenenou rodar no Alpine. Mas, tem mais?

Bem, sim. No final das contas, a atualização do `google-protobuf` teve um
efeito colateral: aparentemente ele tenta buscar a gem com extensões nativas. E
por que atualizamos o `google-protobuf`? Por conta da atualização do SASS.

Para atualizar o SASS, precisamos atualizar o `sass-embedded`:

```diff
-    google-protobuf (4.26.1)
+    google-protobuf (4.29.3)
+      bigdecimal
+      rake (>= 13)
+    google-protobuf (4.29.3-arm64-darwin)
+      bigdecimal
+      rake (>= 13)
+    google-protobuf (4.29.3-x86_64-linux)
+      bigdecimal
       rake (>= 13)

 ...

-    sass-embedded (1.77.2-arm64-darwin)
-      google-protobuf (>= 3.25, < 5.0)
-    sass-embedded (1.77.2-x64-mingw32)
-      google-protobuf (>= 3.25, < 5.0)
-    sass-embedded (1.77.2-x86_64-linux-gnu)
-      google-protobuf (>= 3.25, < 5.0)
-    strscan (3.1.0)
+    sass-embedded (1.83.4-arm64-darwin)
+      google-protobuf (~> 4.29)
+    sass-embedded (1.83.4-x64-mingw32)
+      google-protobuf (~> 4.29)
+    sass-embedded (1.83.4-x86_64-linux-gnu)
+      google-protobuf (~> 4.29)
```

E não há, explicitamente, nenhuma dependência relativa ao `sass` nem ao
`google-protobuf`. Tudo isso é gem que foi atualizada e compatível com as
restrições colocadas de version range, gems que são dependências transitivas
das dependências listadas explicitamente:

```lock
DEPENDENCIES
  cli-ui
  dotenv (~> 3.1)
  duktape (~> 2.6.0.0)
  execjs (~> 2.8.1)
  jekyll (= 4.3.3)
  jekyll-katex
  tzinfo-data
  webrick
```

Mas, afinal, qual foi o problema da extensão nativa do `google-protobuf`?
Bem, vamos lá. temos aqui esses comentários em issue que me ajudaram a chegar
on diagnóstico final:

- [#sass-embedded-host-ruby/282](https://github.com/sass-contrib/sass-embedded-host-ruby/issues/282)
- [#protobuf/16853 (comment)](https://github.com/protocolbuffers/protobuf/issues/16853#issuecomment-2111685999)


Basicamente, o build para do  `google-protobuf` com extensões nativas 
que é `aarch64-linux`, `x86-linux`, `x86_64-linux`. Não especifica que é
`*-linux-gnu`, o esperado para extensões nativas do ruby para Linux baseados em
GLIBC. Em contraponto, `sass-embedded` tem extensões nativas para diversos
alvos linux, como `*-linux-gnu`, `*-linux-android` e `*-linux-musl`. E advinha?
O Alpine Linux é um sistema Linux baseado em MUSL, não em GLIBC. Portanto, meio
que por definição, a ABI que o Alpine Linux espera não é compatível com as
coisas compiladas para GLIBC.

# Vida longa ao rei

Tendo em mente que a ABI das extensões nativas da gem `google-protobuf` não são
compatíveis com Alpine Linux e demais sistemas baseados em MUSL, vamos desistir
de tudo e ficar no Debian, não é?

Óbvio que não! Vamos aos fatos!

O mantenedor do `sass-embedded` colocou o workaround em alguns lugares. Entre
eles, no próprio repositório do `sass-embedded` para ajudar no desenvolvimento
da lib tem isso no `Gemfile`:

```ruby
# ...

group :development do
  # TODO: https://github.com/protocolbuffers/protobuf/issues/16853
  gem 'google-protobuf', force_ruby_platform: true if RUBY_PLATFORM.include?('linux-musl')
  # ...
end
```

Ou seja: nessa situação específica de que está rodando em uma plataforma
`linux-musl`, colocar para usar a versão Ruby pura da Gem `google-protobuf`,
sem usar as extensões nativas. Com isso em mente, podemos começar o trabalho de
contornar esse problema.

Primeiramente, adicionar a plataforma`x86_64-linux-musl` ao lock:

```bash
bundle lock --add-platform x86_64-linux-musl
```

Então, vamos atualizar as gems com `bundle update`. O diff importante:

```diff
     ffi (1.17.1-arm64-darwin)
     ffi (1.17.1-x86_64-linux-gnu)
+    ffi (1.17.1-x86_64-linux-musl)
 ...
     sass-embedded (1.83.4-x86_64-linux-gnu)
       google-protobuf (~> 4.29)
+    sass-embedded (1.83.4-x86_64-linux-musl)
+      google-protobuf (~> 4.29)
     terminal-table (3.0.2)
 ...
   x86_64-linux
+  x86_64-linux-musl
```

Muito bem. Mas isso não resolveu a questão do `google-protobuf` ser forçado ao
usar uma plataforma com MUSL. Aplicando cegamente o contorno:

```ruby
gem 'google-protobuf', force_ruby_platform: true if RUBY_PLATFORM.include?('linux-musl')
```

Isso não gera _nenhunma_ alteração no lock. Por quê? Porque minha plataforma
local é um Mac, não termina em `linux-musl`, portanto essa linha (que está
condicionada a executar apenas quando é `linux-musl`) não irá ser executada.
Então, que tal sempre executar essa linha? Apenas vou pedir para forçar ser
Ruby na situação que é um sistema Linux baseado em MUSL?

```ruby
gem 'google-protobuf', force_ruby_platform: RUBY_PLATFORM.include?('linux-musl')
```

Pronto, agora pelo menos `google-protobuf` aparece na lista das dependência.
Mas... estou deixando passar algo...

Se a ideia toda dessa atualização é por conta do SASS, para atualizar o SASS, e
estou usando o `sass-embedded` para alcançar isso, por que não atualiaar a gem
do SASS também? Porque, se por acaso eu usar o padrão apontado pelo Jekyll na
versão que estou segurando

```ruby
gem "jekyll", "4.3.3" # note que não tem o squigly operator ~>, é exato 4.3.3
```

posso pegar algum SASS que não está atualizado com as funções que eu estou a
usar. Portanto, vamos atualizar no próprio Gemfile também para usar uma versão
moderna do `sass-embedded`:

```ruby
gem 'sass-embedded', '~> 1.83'
```

Ok, hora de empurrar e ver se o build funciona bem no Alpine! Caro leitor,
saiba que nesse momento estarei salvando o draft e empurrando as diferenças do
Gemfile, do lock e deste próprio draft para o blog. Vou rodar o job
`alpine-test` que eu criei no artigo
[Quebrei o CSS com a publicação anterior, e agora?]({% post_url 2025-01-30-quebrei-css %})
para ver se deu certo. Mas... na verdade eu testei em um outro branch até
funcionar. Estou recriando o que eu fiz lá para transformar em artigo, o que
vem não é exatamente surpresa (mas também não fiz os exatos mesmos passos
também, apenas aproximadamente e de modo mais controlado).

# Fallout

Ok, vamos ver o resultado. Vamos baixar os artefatos. Ele baixa tudo, mas tudo
bem, melhor do que baixar cada item criado individualmente pelo Jekyll.

Quando abri o `index.html` pela primeira vez pensei "pronto, quebrei foi tudo!"
O CSS estava todo mal formatado, as coisas ilegíveis, parecia o primeiro
instante da abertura do Computaria como descrevi no post
[Quebrei o CSS com a publicação anterior, e agora?]({% post_url 2025-01-30-quebrei-css %}).
Então me lembrei que talvez seja só o caminho do CSS que esteja apontando para
um lugar que o browser não consegue carregar. Vamos testar essa hipótese?

No `index.html`, vamos ver como ele aponta para a folha de estilo...

```html
<link rel="stylesheet" href="/blog/css/main.css">
```

ARRÁ! É isso! Ele tá apontando para um lugar que não existe! No temrinal tratei
de criar o link simbólico `blog` para o diretório atual

```bash
ln -s ./ blog
```

E... continua quebrado? Tá. Quebrei tudo. Abro o `main.css` em desespero e...
ele tá perfeitinho do jeito que eu esperaria ele estar. Então o que houve?

Ah! As referências são todas a `/blog`, não a `./blog` nem a `blog`. Uma
referência assim significa pegar a partir da autoridade (que normalmente é
determinado por protocolo/endereço/porta) o caminho. Por exemplo, no caso do
Computaria significa `https://computaria.gitlab.io`. Então, o `href` em
`<link rel="stylesheet" href="/blog/css/main.css">` aponta para um recurso em
`https://computaria.gitlab.io/blog/css/main.css`. Mas quem é a autoridade no
caso do protocolo `file://`? Nada por que logo em seguida já começa o path?
(Inclusive é por isso que no protocolo `file` você sempre vê começando com 3
barras, diferente do `https://<site>/<caminho>/<do>/<arquivo>.html` tem
`file:///home/<fulano>/<caminho>/<do>/<arquivo>.html`).

Então, e se eu mudar para apontar, no lugar de `/blog/`, apontar para
`./blog/`? Ou mesmo apenas `blog/`? Faço o teste e... tudo renderiza normal!
Ufa!

Não achei nenhuma deformidade no HTML gerado, nem no CSS gerado que foi o que
pegou da última vez. Com isso em mãos, posso voltar a subir as coisas via
Alpine.

Vamos retornar o alpine para o estado atual de build.

# Revisitando o CI

Eu estava pensando em como aproveitar e deixar o `script` único. Fui olhar a
documentação do [GitLab-CI YAML](https://docs.gitlab.com/ee/ci/yaml/), mais
especificamente fui logo em
[`before_script`](https://docs.gitlab.com/ee/ci/yaml/#before_script) para ver
se achava um link para um `script` global. E eis que acho isso:

> Using `before_script` at the top level [...] is deprecated. 

Em tradução livre:

> Usar `before_script` diretamente da raiz do arquivo é deprecado.

Hmmmm, e qual a sugestão? Usar
[`default`](https://docs.gitlab.com/ee/ci/yaml/#default). Ok, vamos usar
`default` então. O que temos de comum? Basicamente:

- `before_script`
- `image`
- `artifacts`

Variáveis tem definição em top-level, então não preciso me preocupar. Ficou
assim o `default`:

```yaml
default:
  image: ruby:3.2-alpine
  before_script:
    - echo -e "\e[0Ksection_start:`date +%s`:install-deps\r\e[0KInstalando dependêncidas gerais"
    - apk add gcc g++ make
    - gem install bundler
    - echo -e "\e[0Ksection_end:`date +%s`:install-deps\r\e[0K"
    - gem --version
    - echo -e "\e[0Ksection_start:`date +%s`:install-bundle-deps\r\e[0KInstalando dependêncidas via bundle"
    - bundle install
    - echo -e "\e[0Ksection_end:`date +%s`:install-bundle-deps\r\e[0K"
  artifacts:
    when: always
    paths:
    - public
    - Gemfile.lock
```

Show! Próximo passo? Remover o `only:ref` e `except:ref`, são mais duas coisas
marcadas para remoção futura. Para isso temos `rule`. Como funciona? Bem, de
modo bem semelhante na real. Mas `rule` permite eu ter um controle, por
exemplo, de fazer um evento de abertura de PR. Legal, né?

Vamos lá. O build manual já está bem definido com o `when: manual`. Agora, para
quando desejamos rodar ao empurrar algo no `master`? Primeiro, vamos controlar
que estamos lidando com o evento de `$CI_PIPELINE_SOURCE == "push"`. Segundo,
para quando o alvo for o branch `master`: `$CI_COMMIT_BRANCH == "master"`.
Juntando isso:

```yaml
pages:
  # ...
  rules:
    - if: $CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH == "master"
```

De modo semelhante para quando for `$CI_COMMIT_BRANCH != "master"`.

Eu sei que tem um jeito que permitia fazer uma espécie de "herança" de
um "job" (ou hidden-job/template) por outro... tem uma documentação toda sobre
isso. [Veja aqui](https://docs.gitlab.com/ee/ci/yaml/yaml_optimization.html).
Inicialmente eu aprendi a fazer as coisas através de "YAML merge". Mas segundo
a documentação o melhor seria eu fazer com `extends`. A ideia é a mesma, mas
sem magias.

Bem, vamos especificar aqui então um template chamado `.run-jekyll`. É
importante esse `.` na frente, porque com isso o objeto YAML não é interpretado
como um job object.

```yaml
.run-jekyll:
  script:
    - echo -e "\e[0Ksection_start:`date +%s`:jekyll-build\r\e[0KIniciando o Jekyll"
    - bundle exec jekyll build -d public
    - echo -e "\e[0Ksection_end:`date +%s`:jekyll-build\r\e[0K"
```

Com isso, o job principal fica assim:

```yaml
pages:
  extends: .run-jekyll
  rules:
    - if: $CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH == "master"
```

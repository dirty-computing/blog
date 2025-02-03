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
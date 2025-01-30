---
layout: post
title: "Quebrei o CSS com a publicação anterior, e agora?"
author: "Jefferson Quesado"
tags: meta gem gitlab-ci bash
base-assets: "/assets/quebrei-css/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Fiz o seguinte post: [Atualizando o SASS do Computaria]({% post_url 2025-01-29-updating-sass %}).
Em um primeiro instante o pipeline havia quebrado:

![Pipeline failed]({{ page.base-assets | append: "pipeline-failed.jpg" | relative_url }})

Hmmm, estranho. Vamos ver o porquê? Antes de abrir e entender o porquê percebi
que não subi o `Gemfile.lock`. Subi, e agora corrigiu a compilacão.

Aí quando eu fui acessar... já era. Impossível. O CSS estava quebrado demais
para qualquer conteúdo se tornar legível.

Quando fui inspecionar o arquivo `main.css`:

```css
@use "base";
@use "layout";
@use "syntax-highlighting";

/*# sourceMappingURL=main.css.map */
```

Hmmm, então ele não compilou como eu esperava, não é?

Uma coisa que eu percebi no build que falhou foi isso:

![Foco em **(was 1.77.2)** ao instalar]({{ page.base-assets | append: "falha-gemfile-lock-update.png" | relative_url }})

Pegando a versão 1.64 da gem `sass-embedded`.

E no build que estava com o CSS zoado?

![Foco em **sassc** ao instalar]({{ page.base-assets | append: "falha-gemfile-sassc.png" | relative_url }})

Nessa versão ele tá tentando gerar com o `sassc`? Mas eu nem tenho essa gem!

Ok, ok, ok. E o que ele tava utilizando ao escrever o
[Manipulando query string para melhor permitir compartilhar uma página carregada dinamicamente]({% post_url 2025-01-23-genomics-daily-query %})?

![Dá para ver o sass-embedded]({{ page.base-assets | append: "genomics.png" | relative_url }})

Tal qual na versão que deu pane, ele usava o `sass-embedded`, não o `sassc`.
Será que posso fazer algo para evitar ele baixar o `sassc` e ficar com o
`sass-embedded` que já tá no `Gemfile.lock`? Bem, vamos abrir o
[RubyGems](https://rubygems.org/) do `sass-embedded`?
[https://rubygems.org/gems/sass-embedded](https://rubygems.org/gems/sass-embedded).

Uma coisa me chamou a atenção, as versões:

![Várias artefatos para a mesma versão, com archs distintas]({{ page.base-assets | append: "rubygem-sass-embedded-1.png" | relative_url }})

Várias opções de download para o mesmo número de versão! E o que diferencia
elas entre si? A arquitetura alvo.

Clico em mostrar mais versões e procuro por `musl`...

![Muitas opções para as versões 1.83.4 e 1.83.3, com as versões musl em destaque]({{ page.base-assets | append: "rubygem-sass-embedded-2.png" | relative_url }})

Arrá! Tem para a arquitetura `x86_64-linux-musl`, vou pegar ela. Como não
apareceu no Gemfile sozinha, vou inserir na mão:

```diff
     sass-embedded (1.83.4-arm64-darwin)
       google-protobuf (~> 4.29)
     sass-embedded (1.83.4-x64-mingw32)
       google-protobuf (~> 4.29)
     sass-embedded (1.83.4-x86_64-linux-gnu)
       google-protobuf (~> 4.29)
+    sass-embedded (1.83.4-x86_64-linux-musl)
+      google-protobuf (~> 4.29)
```

Adicionei a linha do `google-protobuf` por via das dúvidas na real. Não testei
sem ela, apenas segui o padrão.

Aproveitei e alterei uma coisa no `.gitlab-ci.yaml`:

```yaml
pages:
  # ...
  artifacts:
    - public
    - Gemfile.lock
```

Para ver como ficou o `Gemfile.lock`. E eis que... ele usa o mesmo `sassc` e o
`Gemfile.lock` está distinto do que está no repositório.

Ok, próximo passo? Evitar alterações no `Gemfile.lock`? Justo, né? Eu sabia que
era possível congelar o `.lock`, mas não me lembrava como... até que vi em
algum lugar que era só questão de envvar: `BUNDLE_FROZEN=true`.

E aí o buiild quebrou.

![gem muito antigo para o ffi]({{ page.base-assets | append: "falha-gem-incompativel-ffi.png" | relative_url }})

Ok, vamos atualizar o ruby. Na minha máquina é `3.2.1`. Será que conseguimos
alguma próxima disso? Consegui a imagem base para ser `ruby:3.2-alpine`! Ela
roda com o Ruby `3.2.6`, mas perto o suficiente... E agora, será que rodou?

Nops, agora voltou a dar o `segfault`. Deixa eu pegar aqui o `Gemfile.lock` pra
analisar e... cadê o `Gemfile.lock` nos artefatos? Não tem!!!

Por que não tem? Porque eu mandei manter os artefatos assim:

```yaml
page:
    # ...
    artifacts:
    paths:
    - public
    - Gemfile.lock
```

Vamos mandar guardar o `Gemfile.lock` em caso de falha? Criei esse YAML errado:

```yaml
page:
    # ...
    artifacts:
      when: on_success
        paths:
        - public
        - Gemfile.lock
      when: on_failure
        paths:
        - Gemfile.lock
```

E deu erro de compilação! Chave `when` tá duplicada no mesmo objeto, `when` não
deveria receber um objeto após a enumeração falar que é no caso de
`on_success`, e outros errinhos bobos. Como corrigir? Coloquemos `when: always`
para sempre armazenar, e `path:` no mesmo nível de `when`, pois ambos são
propriedades do mesmo objeto.

Corrigido isso...

```yaml
page:
    # ...
    artifacts:
      when: always
      paths:
      - public
      - Gemfile.lock
```

voltamos ao segfault. Progresso? Talvez...

Ok, ok! Desisto! Pelo visto o Alpine me derrotou, vou abrir mão dele e usar a
versão `3.2-slim`. Ao mudar de Alpine para Debian, as seguintes coisas me
pegaram:

- usar `apt`, não `apk`
- eu preciso antes de instalar atualizar os repositórios do `apt`, normalmente
  com `apt update` antes de chamar o `apt install`
- o `apk` assumia que eu queria instalar, já o `apt` tenta ser gentil e
  **pergunta** para instalar; e se o `stdin` estiver fechado, ele assume
  que foi um "não" e portanto não instala; para contornar, usar `-y` no
  final

E **finalmente** o blog voltou ao ar. Com CSS descente, não algo que deixa o
acesso ao conteúdo tenebroso.

Muito bem, com isso corrigido, resolvi adicionar mais um job: `alpine-test`.
Para colocar isso, algumas regrinhas precisavam ser retomadas à versão
original, como usar `apk` no lugar de `apt`, explicitar o `before_script` e a
imagem base. Mas uma coisa precisava ser distinta! O `when`! Se eu quero que
rode manualmente, então `when: manual`. Ficou assim:

```yaml
alpine-test:
  image: ruby:3.2-alpine
  stage: test
  before_script:
    - echo -e "\e[0Ksection_start:`date +%s`:install-deps\r\e[0KInstalando dependêncidas gerais"
    - apk add gcc g++ make
    - gem install bundler
    - echo -e "\e[0Ksection_end:`date +%s`:install-deps\r\e[0K"
    - gem --version
    - echo -e "\e[0Ksection_start:`date +%s`:install-bundle-deps\r\e[0KInstalando dependêncidas via bundle"
    - bundle install
    - echo -e "\e[0Ksection_end:`date +%s`:install-bundle-deps\r\e[0K"
  script:
    - echo -e "\e[0Ksection_start:`date +%s`:jekyll-build\r\e[0KIniciando o Jekyll"
    - bundle exec jekyll build -d public
    - echo -e "\e[0Ksection_end:`date +%s`:jekyll-build\r\e[0K"
  artifacts:
    when: always
    paths:
    - public
    - Gemfile.lock
  when: manual
```

# O que são esses `echo -e`?

Faz um tempo que o build time. Para otimizar o processo, eu preciso entender
onde está levando tempo. Uma das hipóteses era que eu estava refazendo o build
de tudo sempre e isso estava consumindo muito tempo. Então, para comprovar
isso, precisei medir o tempo.

No gitlab-ci, para medir o tempo, você abre uma seção com uma tag, e então
fecha essa seção com a mesma tag. Por exemplo, para medir o tempo entre
instalar as dependências do sistema para começar a ter acesso livre ao
`bundler`:

```yaml
before_script:
  - echo -e "\e[0Ksection_start:`date +%s`:install-deps\r\e[0KInstalando dependêncidas gerais"
  - apk add gcc g++ make
  - gem install bundler
  - echo -e "\e[0Ksection_end:`date +%s`:install-deps\r\e[0K"
```

Aqui eu iniciei uma seção com a tag `install-deps`:

```bash
echo -e "\e[0Ksection_start:`date +%s`:install-deps\r\e[0KInstalando dependêncidas gerais"
```

Para iniciar a seção, precisa imprimir:

- `\e[0K`: um caracter de escape para limpar a linha (achei mais informação
  [neste gist](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797))
- `section_start:`
- `date +%s:`: o `date` pega o momento atual, e `date +%s` pega o
  unix-timestamp; após o `section_start:` só precisa de um unix-timestamp,
  então por isso que está entre backticks, para expandir e colocar o
  unix-timestamp no lugar correto
- `install-deps`: minha tag personalizada
- `\r\e[0K`: retorna pro começo da linha e apaga a linha com o escape `\e[0K`
- `Instalando dependêncidas gerais`: uma mensagem, pode ser qualquer coisa,
  inclusive é opcional

Para marcar o final da seção:

```bash
echo -e "\e[0Ksection_end:`date +%s`:install-deps\r\e[0K"
```
- `\e[0K`: um caracter de escape para limpar a linha (achei mais informação
  [neste gist](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797))
- `section_end:`
- `date +%s:`: o `date` pega o momento atual, e `date +%s` pega o
  unix-timestamp; após o `section_end:` só precisa de um unix-timestamp, então
  por isso que está entre backticks, para expandir e colocar o unix-timestamp
  no lugar correto
- `install-deps`: minha tag personalizada
- `\r\e[0K`: retorna pro começo da linha e apaga a linha com o escape `\e[0K`

Não sei se pode ter mensagem adicional, nunca precisei e não vi cenários que
para mim fazem sentido.

Tem mais coisa na documentação para
[Custom collapsable sections](https://docs.gitlab.com/ee/ci/jobs/job_logs.html#custom-collapsible-sections).

# Commitando assets

Já que estou por aqui publicando algo um pouco mais intenso de assets...
que tal facilitar minha vida? Commitar logo os assets? Aproveitnado o shell
script criado em
[Movendo de draft para post]({% post_url 2021-12-28-publish-draft %}). Vamos
detectar se por acaso tem algo na pasta de assets do que está sendo publicado?
E, em tendo, commitar junto? Ou na ausência remover o diretório vazio?

O código estava assim:

```bash
git add "$DRAFT"

POST="_posts/`get-today`-${DRAFT#_draft/}"

git mv -v "$DRAFT" "$POST"
```

Isso basicamente gera o caminho do post a partir do caminho do draft. E ele
segue os seguintes passos:

- adiciona o draft para não perder nada
- então, move o draft para o caminho esperado em post

Beleza. No caso dos assets, eu também vou precisar do `${DRAFT#_draft/}"`.
Afinal, meus assets ficam em `assets/<slug>/`. Então... que tal chamar o draft
removendo o diretório `_draft` de `SLUG`?

```bash
git add "$DRAFT"
SLUG="${DRAFT#_drafts/}"

POST="_posts/`get-today`-${SLUG}"

git mv -v "$DRAFT" "$POST"

ASSETS_DIR="assets/${SLUG}/"
```

Hmmm, ainda tem a extensão `.md` no `SLUG`... Ok, consigo conviver com isso, só
garantir que ao criar `ASSETS_DIR` expandir `SLUG` removendo do fim `.md`:

```bash
git add "$DRAFT"
SLUG="${DRAFT#_drafts/}"

POST="_posts/`get-today`-${SLUG}"

git mv -v "$DRAFT" "$POST"

ASSETS_DIR="assets/${SLUG%.md}/"
```

Ok, já tenho meu `ASSETS_DIR` também. Vamos verificar se o diretório está
vazio? Não achei nenhum teste direto pelos comandos de `test`, mas posso listar
e contar as linhas listadas!

```bash
ls -A "${ASSETS_DIR}" | wc -l
```

Para testar isso, pra vazio, só colocar em um bloco de teste em uma expansão de
comando:

```bash
[ "`ls -A "${ASSETS_DIR}" | wc -l`" -eq 0 ]
```

Caso isso seja verdade, caso esteja vazio, vamos remover o diretório? E caso
contrário adicionar?

```bash
if [ "`ls -A "${ASSETS_DIR}" | wc -l`" -eq 0 ]; then
	echo "Removendo assets dir: ${ASSETS_DIR}"
	rmdir -v "${ASSETS_DIR}"
else 
	git add "${ASSETS_DIR}"
fi
```

Essa parte ainda não está no Ruby, então posso me dar essa liberdadezinha em
bash. Quem sabe no futuro próximo eu altere para ser completamente em Rakfile?

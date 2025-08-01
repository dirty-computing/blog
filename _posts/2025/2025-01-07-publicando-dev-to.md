---
layout: post
title: "Computaria no dev.to"
author: "Jefferson Quesado"
tags: dev.to meta markdown
base-assets: "/assets/publicando-dev-to/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Ok, chegou a hora de federar em outros lugares. E no caso escolhi federar no
hub oficial dos programadores: [dev.to](https://dev.to).

Resolvi começar pequeno: pegar um artigo simples e passar pra lá.

Escolhi o [O que é o hikari
pool?]({% post_url 2024/2024-12-27-o-que-e-hikari-pool %}), justamente por ser um
artigo simples sem muita enrolação e direto ao ponto. E logo de cara tive de
lidar com algumas coisas que eu não estava esperando.

Em primeiro lugar: a interface.

![Interface de publicação do dev.to]({{ page.base-assets | append: "create-post.png" | relative_url }})

Isso para mim indicava claramente que eu teria de extrair o título e as tags do
meu frontmatter e colocar nos lugares específicos. Primeiramente crio um
rascunho bem rápido: título "teste" e conteúdo "testando", botei umas tags...
Só para poder continuar sem medo.

![Publicação em rascunho no dev.to]({{ page.base-assets | append: "draft-testando.png" | relative_url }})

Ok, rascunho em mãos, não tenho mais o que temer, né? Explorando um pouco a
interface eu vejo ali aquele mini-hamburguer na barra de edição e clico nele,
ele me oferece 4 opções:

- underline 
- strikethrough
- separador de linha
- ?

Cliquei no `?`, o que me levou a [esse guia](https://dev.to/p/editor_guide). E
esse guia começa com o quê?

> We use a markdown editor that uses [Jekyll front
> matter](https://jekyllrb.com/docs/frontmatter).

Bem, frustrante? Ok, vamos lá. Colocar o frontmatter e vamos ver no que dá...
E... ele reclama das tags.

![Mensagem de erro de tag ruim]({{ page.base-assets | append: "error-tags.png" | relative_url }})

Ok, ok, erro meu. A tag aqui no [dev.to](https://dev.to) precisa ser separada
por vírgulas... por isso ficou "tag muito extensa". 

Mas depois de ajeitar isso ele continuou reclamando de `design-pattern` e de
`resource-pool`. Testei colocar underscore `_`, ponto `.`, espaço, e nada
resolveu. Tive de me render ao que estava de escrito na caixinha de erro:
remover os caracteres que não sejam alfanuméricos. Então coloquei
`designpatterns` no lugar do original `design-pattern` e `resourcepool` no
lugar de `resource-pool` e deu certo! Salvei o rascunho!

Próximo passo? Vamos limpar o frontmatter. No guia ele cita alguns poucos
campos do frontmatter, então não preciso guardar campos que não vou usar, né?
E atraindo meu olhar tem um campo que não existe no meu frontmatter:

- `canonical_url`: link for the canonical version of the content

Um link canônico _justamente_ para fazer a federação de conteúdo! Então basta
por esse campo que fica subentendido a origem do post! Não vou precisar sofrer
editando o conteúdo do post para indicar que vem de outro canto, massa!

Do original:

```yaml
---
layout: post
title: "O que é o hikari pool?"
author: "Jefferson Quesado"
tags: java resource-pool pool design-pattern
base-assets: "/assets/o-que-e-hikari-pool/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---
```

Sobrou apenas:

```yaml
---
title: "O que é o hikari pool?"
tags: java,resourcepool,pool,designpatterns
canonical_url: {{ site.url }}{% post_url 2024/2024-12-27-o-que-e-hikari-pool %}
---
```

Em um diff:

```diff
 ---
-layout: post
 title: "O que é o hikari pool?"
-author: "Jefferson Quesado"
-tags: java resource-pool pool design-pattern
+tags: java,resourcepool,pool,designpatterns
-base-assets: "/assets/o-que-e-hikari-pool/"
-pixmecoffe: jeffquesado
-twitter: jeffquesado
+canonical_url: {{ site.url }}{% post_url 2024/2024-12-27-o-que-e-hikari-pool %}
 ---
```

Com isso pacificado, vamos publicar o resto do artigo. Com isso, ao clicar em
preview, me deparo com 2 surpresas...

A primeira é uma "dica de acessibilidade":

> Consider changing "# First things first, conceito de pool" to a level two
> heading by using "##" [Learn
> more](https://dev.to/p/editor_guide#accessible-headings)

Ok, fácil resolver. Só subir um nível TODAS as minhas seções porque eu começo
do `h1` mesmo para separar seções, mas o [dev.to](https://dev.to) espera
diferente. E ok, realmente do jeito que ele espera dá mais ênfase no título do
artigo sendo o `h1` e todas as partes depois indo de `h2` em diante.

Mas a outra parte que me pegou legal...

![Parágrafos quebrados no meio]({{ page.base-assets | append: "broken-paragraphs.png" | relative_url }})

Hmmm, o que poderia ser? Parece que ele está quebrando linha onde não devia?
Pois bem, isso já aconteceu comigo antes. No GitHub. Qual a solução? Deixar
tudo em uma looooonga linha 🤷‍♂️

Tá, mas por que disso? EU estava acostumado ao flavored markdown **me
permitir** quebrar o parágrafo no meio. Isso me era bom. O guia de edição não
fala nada sobre parágrafos, mas menciona uma cheatsheet de markdown. Que é do
[Markdown here](https://github.com/adam-p/markdown-here/wiki/Markdown-Here-Cheatsheet).

Muito bem, nessa documentação ele fala sobre parágrafos!

![Paragrafação do markdown here com exemplos]({{ page.base-assets | append: "markdown-here.png" | relative_url }})

E embaixo dos exemplos tem essa nota:

> Technical note: Markdown Here uses GFM line breaks, so there's no need to use
> MD's two-space line breaks.

Isso explicou muita coisa. E também a diferença entre o GitLab Flavored
Markdown que eu estava acostumado a parágrafos longos em múltiplas linhas
versus GitHub Flavored Markdown, com parágrafos longos em linhas longas.

O jeito mais fácil de ajeitar isso foi abrir no VSCode e desabilitar o "word
wrapping" com `option + z`:

![Toggle word wrap, comando no VSCode]({{ page.base-assets | append: "word-wrap.png" | relative_url }})

Por que isso? Por conta de dica visual! Olha aqui a diferença:

![Excerto com word wrap]({{ page.base-assets | append: "com-word-wrap.png" | relative_url }})

![Excerto sem word wrap]({{ page.base-assets | append: "sem-word-wrap.png" | relative_url }})

Agora eu visualmente só preciso procurar por diversas linhas agrupadas fora de
blocos de código. Isso ajudou bastante a procurar rapidamente onde ainda
faltava ajeitar os detalhes.

Ok, formatação resolvida... como publicar? A interface não me dá nenhuma
dica... então sou forçado a ler a documentação de novo. O que será que posso
fazer para finalmente publicar? [Vendo o guia](https://dev.to/p/editor_guide),
nada interessante na primeira parte, que é a parte supostamente mais geral. Em
compensação, na parte do frontmatter, eu encontro o que preciso!

> published: boolean that determines whether or not your article is published.

E ele assume `published: false` na ausência de valor! Só mudar o frontmatter
agora para refletir isso e...

```diff
 ---
 title: "O que é o hikari pool?"
 tags: java,resourcepool,pool,designpatterns
 canonical_url: {{ site.url }}{% post_url 2024/2024-12-27-o-que-e-hikari-pool %}
+published: true
 ---
```

_Voi là_! Artigo corretamente [publicado no
dev.to](https://dev.to/jeffque/o-que-e-o-hikari-pool-1lin)!

# Key take aways

Isso aqui foi um esforço inicial simplesmente para aprender quais as diferenças
de publicação aqui no Computaria, no meu blog em que controlo todos os detalhes
da geração do markdown e coloco algumas customizações minhas nisso, comparando
com o [dev.to](https://dev.to). Em breve pretendo automatizar isso, e vão vir
mais posts sobre o assunto.

Eu descobri (posteriormente) que dá para fazer o próprio
[dev.to](https://dev.to) criar posts de rascunho com base simplesmente no meu
RSS, mas aí qual seria a graça, né? Além disso, eu queria com bastante vontade
fazer uma espécie de cadastro de federação de aritgos. Por exemplo, eu passar
o artigo para o [dev.to](https://dev.to) eu detectei um typo. Ter o link do
post original para os federados ajuda na edição desses typos em todos os
lugares publicados.

Pois bem, com foco em automatizar o Computaria em si, e não simplesmente usar
as automatizações do [dev.to](https://dev.to), o que eu preciso para publicar
lá?

Em primeiro lugar, eu creio que ter uma transformação de frontmatter é
fundamental. Eu uso o `title` _as is_. O `tags` eu preciso separar por
vírgulas e também remover traços, underscores etc.

Além desse primeiro trato no frontmatter com base no frontmatter do artigo, cai
bem também adicionar o `canonical_url`.

Adaptando o frontmatter, o próximo passo é lidar com paragrafação. Tudo que não
for bloco de código é melhor aglutinar em uma linha grande. Por exemplo, no
lugar de ter algo assim:

```md
Adaptando o frontmatter, o próximo passo é lidar com paragrafação. Tudo que não
for bloco de código é melhor aglutinar em uma linha grande. Por exemplo, no
lugar de ter algo assim:
```

Preferir ter algo assim:

```md
Adaptando o frontmatter, o próximo passo é lidar com paragrafação. Tudo que não for bloco de código é melhor aglutinar em uma linha grande. Por exemplo, no lugar de ter algo assim:
```

E o próximo passo? Pois bem, rumo a automatização, o próximo passo var ser um
simples algoritmo de tratamento textual: aglutinar parágrafos. E também
garantir blocos de código sendo mantidos como estão.

Aguardem novidades em breve!
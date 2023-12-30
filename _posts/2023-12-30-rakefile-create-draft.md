---
layout: post
title: "Rakefile, parte 2 - criando rascunho"
author: "Jefferson Quesado"
tags: meta ruby rakefile
base-assets: "/assets/rakefile-create-draft/"
---

Dando continuadade ao [post sobre Rakefile]({% post_url
2023-01-06-rakefile-publish-draft %}). Agora, vamos focar
na criação de rascunhos e na menção de imagens.

Apenas para recordar, esse artigo é a segunda parte de 3:

Na [primeira parte]({% post_url 2023-01-06-rakefile-publish-draft %}) tivemos:

1. apanhado geral do Rakefile
1. rodar o Jekyll
1. fazer a ação de publicar (leia artigo [Movendo de draft para post]({% post_url 2021-12-28-publish-draft %}))

Na parte 2 teremos:

1. regras e patterns simples
1. criar um novo post (leia artigo [Criando posts com Makefile]({% post_url 2022-10-16-new-post %}))
1. pegar menção de imagem (leia artigo [Automatizando menção de imagem]({% post_url 2022-10-19-automatizando-mencao-imagem %}))

E por fim, na parte 3:

1. iremos remover chamadas de bash e ficar apenas com ruby

# Regras e patterns simples

No primeiro artigo vimos o exemplo de como criar uma `task`
simples. Aqui, vamos começar com um arquivo simples e evoluir
para uma `rule` simples.

> Você pode se aprofundar mais no assunto
> [consultando a documentação](https://ruby.github.io/rake/doc/rakefile_rdoc.html#label-Rules)

## Arquivos simples, `file`

Vamos criar um arquivo simples chamado de `hello.md`. Para começar,
podemos ter no conteúdo dele o seguinte conteúdo:

```md
# Hello, world!
```

Para isso, no Rakefile precisamos criar um alvo para ele criar: que no caso
será o `hello.md`:

```ruby
file 'hello.md'
```

Só que essa task ainda não faz nada. Pelo manos não falha. Podemos
incrementar apenas para ver que está funcionando colocando um `puts`
com o nome do arquivo algo:

```ruby
file 'hello.md' do |t|
    puts t.name
end
```

E _voi là_, imprimiu o nome base:

```none
$ rake hello.md
hello.md
```

Ok, prova de conceito estabelecida. Agora, como escrever o conteúdo
nesse arquivo?

Bem, uma maneira é abrir o arquivo em modo de escrita e escrever lá.
O ruby oferece uma maneira de abrir o arquivo e passar um bloco logo
em seguida; nesse bloco operações podem ser feitas no arquivo e, ao
sair do bloco, o arquivo será fechado e liberado. Para tal, só usar
o `File.open` do Ruby e passar o arquivo em questão, o modo de abertura
(que para escrita é `w`) e o bloco com a escrita para o arquivo.

No caso, o trecho responsável por escrever no arquivo é o seguinte:

```ruby
File.open t.name, mode = 'w' do |file|
    file.write '# Hello, world!'
end
```

Ao executar `rake hello.md`, podemos perceber que agora ele cria
o arquivo `hello.md` com o conteúdo esperado. Alterar o arquivo e
fazer subsequentes chamadas a `rake hello.md` não ocasiona nenhuma
alteração, conforme esperado.

Essa regra fica assim:

```ruby
file 'hello.md' do |t|
    File.open t.name, mode = 'w' do |file|
        file.write '# Hello, world!'
    end
end
```

## Regras de criação, `rule`

Agora, vamos aumentar o poder do nosso "hello, world"? Vamos criar
arquivos `.md` com o nome das pessoas que queremos dar "hello"?
Por exemplo, podemos criar um `jeff-hello.md`, com os dizeres
`# Hello, jeff!`.

Para isso, usamos uma `rule` no rakefile. Vamos primeiro adaptar o
que já existia e depois adicionamos a capacidade dele de detectar
o nome:

```ruby
rule '-hello.md' do |t|
    File.open t.name, mode = 'w' do |file|
        file.write '# Hello, world!'
    end
end
```

Com isso já conseguimos fazer um `rake jeff-hello.md`.

Notou que a regra usamos `-hello.md` e isso passou a identificar
o que em Makefile detectaria `%-hello.md`? Então, os padrões mais
simples de regras no Rakefile seguem essa lógica. Inclusive, caso
se deseje colocar dependência, automaticamente ele detectar isso.

### Side-track: usando dependências

Um exemplo de dependência da própria docimentação:

```ruby
rule '.o' => '.c'
```

Isso quer dizer que para gerar o `bola.o` ele vai precisar consultar
o arquivo `bola.c`, e alterações em `bola.c` vão desencadear na geração
de um novo `bola.o`.

Hmmm, e se eu tivesse um requisito? Vamos supor que queremos criar um
arquivo `.md.bkp`, que é a cópia de um arquivo `.md` (apenas para
motivo de exemplo, não tem muita coisa por baixo disso). Podemos
fazer essa regra de dependência desse jeito:

```ruby
rule '.md.bkp' => '.md'
```

E para processar? Bem, nesse caso podemos chamar o método `File.copy_stream`,
passando como arquivo o nosso fonte e o nosso alvo. A regra inteira fica assim:

```ruby
rule '.md.bkp' => '.md' do |t|
    File.copy_stream(t.source, t.name)
end
```

E se eu chamar, por exemplo, com `jeff-hello.md.bkp`, sendo que
não existe o arquivo `jeff-hello.md` a priori? Bem, como temos uma
regra que define como computar arquivos `-hello.md`, ela será disparada
para criar o `jeff-hello.md` e, logo em seguida, a chamada para
criar `jeff-hello.md.bkp` descrita ali em cima.

Note que não é mandatório que só se tenha uma única dependência,
podemos ter diversas dependências.

### Finalizando a escrita

Deixando a _side-track_ de lado, agora precisamos identificar o nome
passado para dar as saudações no arquivo. O jeito mais fácil é remover
o `-hello.md` do nome do arquivo. Então, por que não?

```ruby
rule '-hello.md' do |t|
    fileName = t.name
    person = fileName.sub '-hello.md', ''
    File.open fileName, mode = 'w' do |file|
        file.write "# Hello, #{person}!"
    end
end
```

### Padrões avançados

Ao ser informada uma string para o `rule`, ele vai tratar que tudo
que estiver com aquele terminador será um arquivo a ser tratado.
Porém, podemos passar coisas mais inteligentes para esse fim:
pode ser uma regex.

No caso específico, gostaria que ficasse dentro do diretório `_drafts/`
e que termine com `.md`.  No caso de passar uma regex para o `rule`
precisamos envolver com parênteses todo o conteúdo antes do bloco:

```ruby
rule(/^_drafts\/.*\.md$/)
```

As dependências podem ser declaradas como uma função que recebe a
task em questão e retorna a lista com as dependências.

# Criando um novo post

Bem, já demos um spoiler ao indicar que rascunhos são criados
necessariamente na pasta `_drafts`, e para o caso específico
eles são `.md`, e que não tem dependência.

```ruby
rule(/^_drafts\/.*\.md$/) do |t|
    # magic here
end
```

Pegando a ideia do [criando posts com Makefile]({% post_url 2022-10-16-new-post %}),
seria interessante perguntar o título e as tags. Então, obtendo essas informações,
e sabendo o nome do arquivo (chamado de `radix`), podemos substituir no template:

```ruby
# title lido do usuário
# tags lido do usuário
# radix baseado em t.name
    template =  "---
layout: post
title: \"#{title}\"
author: \"Jefferson Quesado\"
tags: #{tags}
base-assets: \"/assets/#{radix}/\"
---
"
```

Então, com o modelo em mãos, só abrir o arquivo e escrever:

```ruby
rule(/^_drafts\/.*\.md$/) do |t|
    fileName = t.name

    radix = fileName.sub /_drafts\/(.*)\.md/, '\1'
    require "cli/ui"
    title = CLI::UI::Prompt.ask('Qual o título?')
    tags = CLI::UI::Prompt.ask('Quais as tags (separadas por espaço)?')

    template =  "---
layout: post
title: \"#{title}\"
author: \"Jefferson Quesado\"
tags: #{tags}
base-assets: \"/assets/#{radix}/\"
---
"
    File.open fileName, mode = 'w' do |file|
        file.write template
    end
end
```

Porém, tem uma coisa que poderia deixar mais fácil o meu
trabalho: abrir o markdown recém criado no VSCode. Para
tal, a maneira mais fácil que eu achei foi gerar um novo
processo da shell e esperar ele se concluir:

```ruby
spawn("command")
Process.wait
```

No caso específico do VSCode, fiz o bund das saídas com
as saídas do terminal. Ficou algo assim:

```ruby
spawn("command", :out -> :out, :err => :err)
Process.wait
```

E, finalmente, o comando de verdade é esse, chamando `code` na CLI
e passando como argumento o nome do arquivo:

```ruby
spawn("code #{fileName}", :out => :out, :err => :err)
Process.wait
```

# Mencionando imagens

A menção de imagens não consegui fazer de modo tão natural
quanto no shell script, já que o auto-complete do rakefile
vai inspecionar atrás de tasks internas cadastradas.

De toda sorte, foi feito.

Tal qual o `mention-image.sh`, ele produz uma saída bem simples:

```ruby
{{ "%7B%7B page.base-assets | append: <IMAGE-TO-BE-CITED> | relative_url %7D%7D" | url_decode }}
```

Para evitar chocar com nomes existentes, usei por convenção que
comandos de citação são necessariamente terminados em `:mention`.

Então, para mencionar o Ferris associado a ester artigo, faço a chamada:

```bash
rake assets/rakefile-create-draft/ferris.jpg:mention
```

E obtenha como saída:

```ruby
{{ "%7B%7B page.base-assets | append: %22ferris.jpg%22 | relative_url %7D%7D" | url_decode }}
```

E posso usar o output para colocar o Ferris aqui:

![Ferris, como imagem de exemplo]({{ page.base-assets | append: "ferris.jpg" | relative_url }})

A regra para criar isso:

```ruby
rule(/^assets\/.*\.(png|jpe?g|gif|svg):mention$/) do |t|
    referenceFromBaseAssets = t.name.split(":")[0..-2].join(":").split("/")[2..].join("/")

    {{ "puts %22%7B%7B page.base-assets | append: \%22#%7BreferenceFromBaseAssets%7D\%22 | relative_url %7D%7D%22" | url_decode }}
end
```

Por partes:

- eu pego o algo (`t.name`)
- removo apenas o `:mention` do final (na real, o último `:<string>`):
  - separo em cima do `:` com `split(":")`
  - pego um slice do vetor, indo da primeira posição `0` até a penúltima `-2`
  - para pegar um slice, só usar `<ini>..<fim>`
  - a última posição é `-1`, portanto a penúltima é `-2`
  - junto tudo de novo com `join(":")`
- removo o `assets/<nome da base dos assets>/`
  - semelhante a como removi o `:mention`, mas removendo os 2 primeiros componentes de diretórios
  - separo em cima do `/` com `split("/")`
  - pego a terceira posição `2` até o fim com um splice `2..`
  - junto tudo de novo com `join("/")`
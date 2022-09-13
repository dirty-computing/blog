---
layout: post
title: "Criando uma Gem - SCREAM OUT!!"
author: "Jefferson Quesado"
tags: ruby
---

Ao fazer o post de publicar no Discord, acabei criando uma Gem. Vamos
falar sobre ela aqui?

Primeiro ponto que gostaria de discorrer é: essa Gem tem uso muito particular,
então no momento de sua criação não há interesse em publicá-la. Ela foi criada
de modo meio descartável para lidar com o projeto.

Então, vamos falar um pouco sobre esse processo?

# .gemspec, Gemfile, Gemfile.lock...

O [`bundler`](https://bundler.io/) prevê a existência do arquivo `Gemfile` para
lidar com questões de depedências e outras coisas. Como eu desejo que o `scream-out`
se torne um executável de linha de comando, então eu preciso, também, fornecer
o jeito padrão Ruby de descrever uma Gem: o  `.gemspec`.

Por padrão o `.gemspec` vem precedido do nome da Gem sendo criada. No meu caso,
então, é o `scream-out.gemspec`.

Para informar ao `Gemfile` que você está usando um `.gemspec`, use a função
`gemspec` e ele funcionará lindamente:

```rb
# frozen_string_literal: true

source "https://rubygems.org"

gemspec
```

Se quiser adicionar dependências no `Gemfile`, basta chamar a função `gem`
passando a Gem adequada. Por exemplo:

```rb
# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "nokogiri"
```

Dá para ser bem _fancy_ aqui também, passando como segundo argumento a versão:

```rb
# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "nokogiri", '~> 1.13.0'
```

e como é código Ruby, podemos também fazer coisas de Ruby, como condicionar a importar
a Gem apenas se estiver em uma plataforma:

```rb
# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem 'wdm', '~> 0.1.0' if Gem.win_platform?
```

> Inclusive isto foi feito no post
> [criando o blog]({% post_url 2021-08-30-criando-blog-jekyll %})

Para verificar que de fato as coisas estão indo de acordo com o desejado, podemos
fazer um simples `bundle update` para ver as coisas sendo baixadas.

Além disso, o `Gemfile.lock` vai informar quais as dependências exatas usadas. Ele
é criado ao chamar `bundle update`.

# Adicionando arquivos

Pela Gemspec, você precisa listar os arquivos da sua Gem em `spec.files`.

No meu caso, para fazer parte da Gem, só me interessa o `bin/scream-out` e também
tudo dentro da pasta `lib/` que seja arquivo `.rb`. Então, para isso, usando
o `rake` (conforme uma das possíveis sugestões no [site da
Gemspec](https://guides.rubygems.org/specification-reference/#files)), listei
os arquivos assim:

```rb
FileList[
    "bin/scream-out",
    "lib/**/*.rb"
].to_a
```

Como o `.gemspec` é um código Ruby válido, pude validar que de fato estava fazendo o
que eu queria: coloquei esse resultado em uma variável e mandei imprimi-la, então executei
um `bundle update` para validar que realmente estes eram os arquivos que eu gostaria de estar
importando:

```rb
fl = FileList[
    "bin/scream-out",
    "lib/**/*.rb"
].to_a

puts fl
spec.files = FileList[
    "bin/scream-out",
    "lib/**/*.rb"
].to_a
```

E a chamada do `bundle update` retornando exatamente o que desejava (executado no começo do
projeto, só tinha isso mesmo de arquivos):

```bash
$ bundle update
bin/scream-out
lib/scream-out.rb
lib/scream-out/version.rb
Fetching gem metadata from https://rubygems.org/.......
Resolving dependencies...
Using bundler 2.2.25
Using racc 1.6.0
Using nokogiri 1.13.8 (x64-mingw32)
Using scream-out 0.0.1 from source at `.`
Bundle updated!
```

# Tornando executável

Hora de tentar executar. Para isso, bastaria um `bundle install` seguido de um
`bundle exec scream-out`, não é?

```
$ bundle install
Using bundler 2.2.25
Using racc 1.6.0
Using nokogiri 1.13.8 (x64-mingw32)
Using scream-out 0.0.1 from source at `.`
Bundle complete! 2 Gemfile dependencies, 4 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.

$ bundle exec scream-out
bundler: command not found: scream-out
Install missing gem executables with `bundle install`
```

Hmmm... o que poderia ter acontecido? Bem, na verdade o que aconteceu foi
que eu simplesmente não declarei qual era o meu executável. Só isso. Obviamente
que se eu tivesse [seguido a documentação](https://guides.rubygems.org/make-your-own-gem/)
com calma teria visto que ele tem o exemplo da definição do executável. Basta
dar um `append` no array de `spec.executables` com os arquivos executáveis.

Ah, sim, o Gemspec só considera os executáveis dentro de `spec.bindir`. E,
também, se eu quero o `scream-out` dentro de `bin/` eu só dou um _append_
em `scream-out`:

```rb
spec.bindir = 'bin'
spec.executables << 'scream-out'
```

Depois de fazer isso, tudo se comportou naturalmente:

```
$ bundle install
Using bundler 2.2.25
Using racc 1.6.0
Using nokogiri 1.13.8 (x64-mingw32)
Using scream-out 0.0.1 from source at `.` and installing its executables
Bundle complete! 2 Gemfile dependencies, 4 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.

$ bundle exec scream-out
Oi
```

# Definindo módulo

Para mexer no `scream-out`, criei inicialmente um arquivo de entrada que importa
demais coisas e que deveria ser vazio além desse básico, o `lib/scream-out.rb`.
Mas, para efeitos de deputação, coloquei a função `oi` dentro do módulo `ScreamOut`
para dar o bom e velho "olá, mundo".

Além desse arquivo, também criei um arquivo para manter a versão do módulo, seguindo
o padrão de estar dentro de um diretório com o nome da Gem. Veja como ficou o esquema:

```
.
├── Gemfile
├── Gemfile.lock
├── bin
│   ├── console
│   ├── scream-out
│   └── setup
├── lib
│   ├── scream-out
│   │   └── version.rb
│   └── scream-out.rb
└── scream-out.gemspec
```

> Notou os `bin/console` e `bin/setup`? Pois bem, eles são de uma convenção
> muito útil, explicarei [adiante](#desenvolvendo-eficientemente).

Pois bem, tudo tranquilo... Como que eu faço para o `bin/scream-out` poder enxergar
os códigos da Gem? Bem, dando um simples `require`:

```rb
#!/usr/bin/env ruby

require 'scream-out'
ScreamOut::oi
```

Saída:

```
$ bundle exec scream-out
oi, na versão 0.0.1
```

# Desenvolvendo eficientemente

Bem, agora eu simplesmente sei que o executável vai se comportar bem. Mas, e para
codificar de maneira mais eficiente? Uma codificação exploratória e tranquila?

Ficar constantemente escrevendo arquivos Ruby, salvá-los e chamar o `bundle exec scream-out`
é muito trabalhoso, deveria ter um modo mais interativo. Eu sempre defendo que para
programação exploratória o melhor que se pode ter é um REPL...

E, bem, em Ruby temos o `irb` que é o REPL padrão dele. Mas para rodar o `irb` precisa
configurar muitas coisas de ambiente. Aí que entra o `bin/console`: normalmente com
ele você deixa pronto para usar o `irb` já com as importações realizadas e o
objeto pronto para que você possa codificar com ele. Bacana, né?

E, nesse setido, o que fazer com o executável? Bem, a ideia é tornar o executável
responsável por resgatar informações passadas como argumento/variáveis de ambiente
e configurar o código de negócio dentro do `lib`. Assim, o executável lida com
sua preocupação de interação com o usuário/ambiente e o código dentro do `lib`
pode ser mais "puro".

O arquivo `bin/setup` é outro padrão bastante usado para simplesmente permitir o
uso inicial da Gem.

# Lidando com a CLI

Olhando o próprio código do executável do Jekyll vi a menção a Gem
[`mercenary`](https://rubygems.org/gems/mercenary/versions/0.4.0). E, aparentemente,
o jeito que o Jekyll estava usando essa Gem era para lidar com o recebimento de argumentos
de linha de comando:

```rb
require "mercenary"

Jekyll::PluginManager.require_from_bundler

Jekyll::Deprecator.process(ARGV)

Mercenary.program(:jekyll) do |p|
  p.version Jekyll::VERSION
  p.description "Jekyll is a blog-aware, static site generator in Ruby"
  p.syntax "jekyll <subcommand> [options]"

  p.option "source", "-s", "--source [DIR]", "Source directory (defaults to ./)"
  p.option "destination", "-d", "--destination [DIR]",
    "Destination directory (defaults to ./_site)"
  p.option "safe", "--safe", "Safe mode (defaults to false)"
  p.option "plugins_dir", "-p", "--plugins PLUGINS_DIR1[,PLUGINS_DIR2[,...]]", Array,
    "Plugins directory (defaults to ./_plugins)"
  # ...
end
```

Então, fui atrás de ler sobre essa Gem e encontro isso:

> Lightweight and flexible library for writing command-line apps in Ruby.

Portanto, perfeito para o que eu quero! Vamos testar?

Bem, por hora vou querer apenas que eu passe um webhook e eventualmente que possa
sobrescrever a questão de onde ler o `feed.xml` e também onde posso executar o comando
`git` para pegar as informações do último commit.

Então, vamos lá... Temos o `Mercenary.program` que vai iniciar a tratativa da linha
de comando. Para iniciar ele corretamente, preciso passar um _symbol_ representando
o executável. Tentei passar de modo tradicional `:scream-out` (até porque no Jekyll
o exemplo era `:jekyll`), mas o modo de criar símbolos com `:string` não aceitou bem
a presença do `-`, então passei `"scream-out"` como string tradicional mesmo.

Ok, agora se tem um bloco de construção do programa, onde recebo o programa `p`.
O que fazer com ele?

Bem, posso descrever a sintaxe de uso básico dele:

```
scream-out [options] <discord-webhook>
```

Usando a função `p.syntax`. Também não custa nada adicionar uma descrição, não é?
Ela está no `p.description`. Existe também a possibilidade de se adicionar a versão
`p.version`.

Além disso, preciso configurar as opções de linha de comando. Como fazer? Simples,
chamo a função `p.option`. Essa função recebe vários argumentos, mas vou marcar alguns
que achei especiais:

- o primeiro argumento vai ser o identificador interno da opção CLI  
  por exemplo, posso marcar `"git"` como sendo o marcados para a flag `-g`
- o possível penúltimo argumento pode ser um tipo  
  interessante para lidar com arrays e outros tipos, como números
- o último argumento, opcional, que é a descrição
- argumentos do miolo indicam qual a flag e se ela tem complemento  
  por exemplo, `"-f PATH"` indica que tem um argumento chamado, já `"-g"`
  indica a ausência de complemento
- no caso de variáveis sem complemento, ela recebe valor verdade
- normalmente, no miolo primeiro é a _short switch_ seguido de _long switgh_

Por exemplo, fiz os seguintes cadastros de opções:

```rb
p.option "feed_path", "--feed-path PATH", "Caminho para o feed, sobrescrever env var FEED_PATH"
p.option "git", "-g PATH", "--git PATH", "Caminho para o repositório git, padrão é diretório atual"
p.option "verboso", "-V", "--verbose", "Verbosidade"
```

E recebo os seguintes mapeamentos, dependendo dos argumentos:

```rb
# --feed-path ../../feed.xml oi -g ./ -V
{"feed_path"=>"../../feed.xml", "git"=>"./", "verboso"=>true}

# --feed-path ../../feed.xml oi -g ./ +V
{"feed_path"=>"../../feed.xml", "git"=>"./"}

# --feed-path ../../feed.xml oi ./ -V -g
# lança exceção porque -g precisa de argumento

# --feed-path ../../feed.xml -V
{"feed_path"=>"../../feed.xml", "verboso"=>true}
```

E, só preenchendo essas informações, conseguimos chamar `scream-out --help`, por exemplo:

```
$ bundle exec scream-out -h
scream-out 0.0.1 -- grita em um canal do Discord os últimos posts de um RSS que batem com o último git commit

Usage:

  scream-out [options] <discord-webhook>

Options:
            --feed-path PATH  Caminho para o feed, sobrescrever env var FEED_PATH
   -g PATH, --git PATH     Caminho para o repositório git, padrão é diretório atual
        -V, --verbose      Verbosidade
        -h, --help         Show this message
        -v, --version      Print the name and version
        -t, --trace        Show the full backtrace when an error occurs
```

Muito bem, mas e como lidar com a chamada do programa? Bem, para este caso temos a
função `p.action`. Ela vai receber os argumentos que não se encaixam em opções de
linha de comando e o mapeamento de linha de comando mostrado acima. E aqui, nesse
momento, o programador que se vire para fazer sentido dos argumentos recebidos, ao
menos as opções de linha de comando já foram devidamente parseadas.

Por exemplo, explorando essas opções, eu quis imprimir os argumentos, as opções
preenchidas pelas flags de linha de comando e, se o primeiro argumento for `"oi"`,
chamar a função de "hello world":

```rb
p.action do |args, options|
    puts "imprimindo os args: #{args}"
    puts "imprimindo os args: #{options}"

    if args.empty?
        puts "Esperava o webhook"
        abort
    end
    ScreamOut::oi if args[0] == 'oi'
end
```

E foi assim que eu descobri como lidar com as flags de linha de comando e os
argumentos.

E com isso eu concluo o esqueleto da criação da Gem, posso voltar a focar em
de fato publicar no Discord quando eu subo uma nova postagem no blog.
---
layout: post
title: "Criando uma pequena ferramente GUI com Ruby"
author: "Jefferson Quesado"
tags: ruby gui tcl/tk
base-assets: "/assets/ruby-gem-tcl-tk/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Preciso criar uma aplicação GUI. Vamos criar em Ruby?

Por uma questão de praticidade, vou chamar ela de `jeffgui`.

# Iniciando a gem

Bem, no post [Criando uma Gem - SCREAM OUT!!]({% post_url 2022-09-13-criando-gem %})
eu criei na mão a gem. Mas posso usar outra alternativa:

```bash
bundle init
```

Isso gera o seguinte `Gemfile`:

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

# gem "rails"
```

Um placeholder para o arquivo de entrada em `lib/jeffgui.rb`:

```ruby
# frozen_string_literal: true

module JeffGui
  class Error < StandardError; end
  # Your code goes here...
end
```

Como queremos usar GUI, adiciono a gem `tk`. Vou usar ela mais tarde. Finalmente, para
a o resto das coisas básicas, `bin/setup`:

```bash
#!/usr/bin/env bash
set -euo pipefail
set -vx

bundle install
```

E o `bin/console`:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "jeffgui"

# (If you use this, don't forget to add pry to your Gemfile!)
# require "pry"
# Pry.start

require "irb"

IRB.start(__FILE__)
```

Não posso me esquecer de `chmod u+x bin/*`, e pronto, projeto iniciado.
Só chamar o `bin/setup` para iniciar as coisas e `bin/console` para testar e...

Hmmm, deu problema. `jeffgui` não é uma gem válida. Ok, talvez seja só porque
eu não executei em cima do bundler? Vamos ver:

```bash
$ bundle exec bin/console
bundler: failed to load command: bin/console (bin/console)
<internal:~/.asdf/installs/ruby/3.2.1/lib/ruby/site_ruby/3.2.0/rubygems/core_ext/kernel_require.rb>:37:in `require': cannot load such file -- jeffgui (LoadError)
	from <internal:~/.asdf/installs/ruby/3.2.1/lib/ruby/site_ruby/3.2.0/rubygems/core_ext/kernel_require.rb>:37:in `require'
	from bin/console:9:in `<top (required)>'
	from ~/.asdf/installs/ruby/3.2.1/lib/ruby/site_ruby/3.2.0/bundler/cli/exec.rb:58:in `load'
```

Hmmm, ainda não tá legal como eu imaginei que estaria. Pesquisei aqui por exemplos,
para ver o que eu estava fazendo de errado. E eis que encontro
[essa referência](https://mutelight.org/bin-console), que direcionava
para o diretório do `hekla`. E lá encontro isso aqui no
[`bin/console`](https://github.com/brandur/hekla/blob/9ae8a4c05101b667c78cfa5046f9e8da2647605d/bin/console#L12C1-L12C32):

```ruby
#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

require "irb"
require "irb/completion"

DB = Sequel.connect(ENV["DATABASE_URL"] ||
  raise("missing_environment=DATABASE_URL"))

require_relative "../lib/hekla"

# Sinatra actually has a hook on `at_exit` that activates whenever it's
# included. This setting will suppress it.
set :run, false

IRB.start
```

Hmmm, `require` relativo para a gem então... Vamos lá! Alterando o meu `bin/console`:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require_relative "../lib/jeffgui"

# (If you use this, don't forget to add pry to your Gemfile!)
# require "pry"
# Pry.start

require "irb"

IRB.start(__FILE__)
```

E executando:

```bash
› bundle exec bin/console
irb(main):001:0>
```

Ótimo, setup do projeto funcionou! Vamos começar a trabalhar!

# Setup mínimo para tela e bloqueios

Peguei um projeto anterior que eu tinha feito no trabalho para adaptar para
a nova aplicação GUI que vou fazer. Basicamente uma tela com um campo de
texto e um botão:

```rb
module JeffGui
    class Gui
        def initialize
            @prepared = false
        end
        def prepare
            require 'tk'
            root = TkRoot.new { title "Ex1" }
            txt = TkText.new(root) {
              pack { padx 15 ; pady 15; side 'left' }
            }
            TkButton.new(root) {
                text 'Aperta!!'
                pack { padx 20 ; pady -20; side 'right' }
                command(proc {
                    v = txt.value
                    txt.value = ">>" + v + "<<"
                })
            }
            @prepared = true
        end
        def show
            prepare unless @prepared
            Tk.mainloop
        end
    end
end
```

Basicamente possibilita criar um objeto de interface gráfica e manipular ele
antes de entrar no loop do tcl/tk (`gui.prepare`) e então exibir/entrar
no loop principal do tcl/tk (`gui.show`).

Atributos de classe são sempre privados, e são indicados com o modificador de
escopo `@`. Então, no construtor (`initialize`), temos que já iniciamos o valor
`@prepared = false`. Então, no método `show`, iremos chamar `prepare` a não ser
que ele já esteja preparado (`prepare unles @prepared`). Então seguimos
com a chamada do main loop `Tk.mainloop`. Nenhum segredo.

Para `prepare` basicamente um boiler plate para por uma caixa de texto e
um botão com uma ação (que consiste em colocar `>>` no começo do texto
da caixa de texto e `<<` no final do texto).

E vamos adaptar o arquivo central para que, caso ele seja chamado diretamente,
suba a janela:

```ruby
# frozen_string_literal: true

require_relative "jeffgui/gui"

module JeffGui
  class Error < StandardError; end
  # Your code goes here...

  if __FILE__ == $0
    gui = Gui.new
    gui.show
  end
end
```

Então vamos chamar em cima do bundler e...

```bash
$ bundle exec ruby lib/jeffgui.rb
```

![Janela simples]({{ page.base-assets | append: "tcl-tk_1.png" | relative_url }})

Pronto, consegui levantar!

Mas uma coisa que eu curto muito no ruby é levantar via `console` para poder
futricar as coisas ao vivo via IRB. Então, vamos lá:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"

require_relative "../lib/jeffgui"

# (If you use this, don't forget to add pry to your Gemfile!)
# require "pry"
# Pry.start

require "irb"

$gui = JeffGui::Gui.new
$gui.show
IRB.start(__FILE__)
```

A variável com `$` deixa ela com escopo global, então isso permite que eu a acesse dentro do IRB.
Vamos rodar pra começar a macacar?

```bash
› bundle exec bin/console
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'NSWindow should only be instantiated on the main thread!'
```

Hmmm, ué? Bem, vamos remover o `show`. `irb` abriu normalmente. Hmmm, e se a gente só preparar? Mudar
o final do arquivo para isto daqui:

```ruby
$gui = JeffGui::Gui.new
$gui.prepare
IRB.start(__FILE__)
```

Mesmo problema. E se eu deixar o final só assim? Removendo a chamada pro `irb`?

```ruby
$gui = JeffGui::Gui.new
$gui.prepare
IRB.start(__FILE__)
```

Também mesmo problema... E se eu remover o `require 'irb'`? Bem, executou sem problemas...

Hmmmm, será que é algum problema do IRB com o Tcl/Tk implementado no Ruby? Vamos ver...

```ruby
require 'irb'
require 'tk'

puts "aquiiiii"
# fim do arquivo
```

Resultado?

```bash
› bundle exec bin/console
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'NSWindow should only be instantiated on the main thread!'
```

É, simplesmente importar dá problema. E se eu importar na ordem contrária?

```ruby
require 'tk'
require 'irb'

puts "aquiiiii"
# fim do arquivo
```


```bash
› bundle exec bin/console
aquiiiii

```

Funcionou. Pronto, ufa. Preciso garantir que o `tk` seja importando antes do `irb`. Mas isso funciona mesmo?
Com certeza? Bem, vamos ver. Ao chamar `$gui.show` eu fico com o processamento preso, portanto se eu quiser
invocar o `irb` preciso iniciar esse processo antes do `show`. Mas chamar o `IRB.start(__FILE__)` também
deixa o processo preso. Então? Vamos usar threads. Só por teimosia... vamos por o `$gui.show` na thread
secundária?

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"

require_relative "../lib/jeffgui"

# (If you use this, don't forget to add pry to your Gemfile!)
# require "pry"
# Pry.start

require 'tk'

Thread.new do
    $gui = JeffGui::Gui.new
    $gui.show
end

require 'irb'
IRB.start(__FILE__)
```

```bash
› bundle exec bin/console
irb(main):001:0> #<Thread:0x0000000110110308 bin/console:14 run> terminated with exception (report_on_exception is true):
~/.asdf/installs/ruby/3.2.1/lib/ruby/gems/3.2.0/gems/tk-0.5.0/lib/tk/pack.rb:43:in `flatten': can't convert Tk::Text to Array (Tk::Text#to_ary gives String) (TypeError)

    args.flatten(1).each{|win| params.push(_epath(win))}
                 ^
	from ~/.asdf/installs/ruby/3.2.1/lib/ruby/gems/3.2.0/gems/tk-0.5.0/lib/tk/pack.rb:43:in `configure'
	from ~/.asdf/installs/ruby/3.2.1/lib/ruby/gems/3.2.0/gems/tk-0.5.0/lib/tk.rb:5098:in `pack'
	from ~/jeffgui/lib/jeffgui/gui.rb:10:in `block in prepare'
	from ~/.asdf/installs/ruby/3.2.1/lib/ruby/gems/3.2.0/gems/tk-0.5.0/lib/tk/text.rb:267:in `instance_exec'
	from ~/.asdf/installs/ruby/3.2.1/lib/ruby/gems/3.2.0/gems/tk-0.5.0/lib/tk/text.rb:267:in `new'
	from ~/jeffgui/lib/jeffgui/gui.rb:9:in `prepare'
	from ~/jeffgui/lib/jeffgui/gui.rb:23:in `show'
	from bin/console:55:in `block in <top (required)>'
irb(main):002:0>
```

> A segunda linha do irb só foi exibida porque eu dei um <enter> para confirmar que ainda o ruby
> ainda estava no ar

Ok, ok, realmente o TK não gosta da ideia de ser cidadão em thread secundária. Entendi. Não vou mais
insistir. Vou trocar as preocupações agora: iniciar primeiro `$gui.prepare`, então iniciar a thread
do irb, e então vou dar o `$gui.show`:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"

require_relative "../lib/jeffgui"

# (If you use this, don't forget to add pry to your Gemfile!)
# require "pry"
# Pry.start


$gui = JeffGui::Gui.new
$gui.prepare

Thread.new do
    require 'irb'
    IRB.start(__FILE__)
end

$gui.show
```

Rufem os tambores... Vamos testar...

```bash
› bundle exec bin/console
irb(main):001:0>
```

E a janela subiu. Pronto. Pronto? Bem, não, ainda preciso dar um jeito de passar comandos
para a janela executar na main thread... **sigh**

Como posso fazer isso? Bem, uma maneira é ter um atributo acessível de `$gui` que permita
eu injetar threads. Vou chamar ele de `queue`. Mas ruby não tem atributos visíveis externamente,
apenas métodos... Pois bem, aí eu posso indicar pra ele pra criar um método para me enganar
e trabalhar como se aquele atributo fosse público, usando o `attr_read`. Ficou assim
o `lib/jeffgui/gui.rb`

```ruby
module JeffGui
    class Gui
        attr_reader :queue
        def initialize
            @prepared = false
            @queue = Thread::Queue.new
        end
        def prepare
            require 'tk'
            root = TkRoot.new { title "Ex1" }
            txt = TkText.new(root) {
              pack { padx 15 ; pady 15; side 'left' }
            }
            TkButton.new(root) {
                text 'Aperta!!'
                pack { padx 20 ; pady -20; side 'right' }
                command(proc {
                    v = txt.value
                    txt.value = ">>" + v + "<<"
                })
            }
            @prepared = true
        end
        def show
            prepare unless @prepared
            Tk.mainloop
        end
    end
end
```

E com isso eu consigo via IRB enviar coisas para o objeto que contém
a janela:

```ruby
irb(main):016:1* $gui.queue << Proc.new do ||
irb(main):017:1*   puts "eu sou um outro print de debug"
irb(main):018:0> end
=> #<Thread::Queue:0x00000001051d00a0>
irb(main):019:1* $gui.queue << Proc.new do ||
irb(main):020:1*   puts "eu sou um outro print de debug"
irb(main):021:0> end
=> #<Thread::Queue:0x00000001051d00a0>
irb(main):022:0> $gui.queue
=> #<Thread::Queue:0x00000001051d00a0>
irb(main):023:0> $gui.queue.size
=> 2
```

Isso já dá pano pra manga para fazer as coisas. Por exemplo, eu não posso alterar
as coisas via IRB, pois aí as alterações da tela não estariam na thread principal.
Em compensação, eu posso mandar a alteração para a tela. Mas... ainda não consigo
trabalhar ainda. Preciso de mais. Por exemplo, preciso de um ponto de entrada
para por elementos no Tk. Tipo, se eu quiser um botão adicionado dinamicamente,
algo assim:

![Janela simples]({{ page.base-assets | append: "adicionado-agora.png" | relative_url }})

Preciso fazer algo assim para ele:

```ruby
TkButton.new(root) {
    text 'adicionado agora'
    pack { padx 20 ; pady -20; side 'right' }
}
```

Ou seja, preciso passar exatamente esse `root` como argumento. Então vamos fazer isso,
deixar as funções passadas prontas para receberem `root`. Por sinal, podemos declarar
blocos de funções a serem executados de outros modos do que apenas o
`Proc.new do |arg, list| end`. O que fizemos anteriormente foi um `Proc.new`, mas
podemos também fazer lambdas:

```ruby
$gui.queue << lambda do |root|
  puts "eu sou um print de debug"
end
$gui.queue << -> (root) {
  puts "eu sou um outro print de debug"
}
$gui.queue << lambda { |root|
  puts "eu sou mais um outro print de debug"
}
```

Lambdas oferecem algumas vantagens perantes `proc`s, como por exemplo
em `proc` o `return` vai de fato retornar da função e não apenas
parar o `proc`, já em lambda como a lambda é uma função o return tem
efeito local. Você pode ler mais do assunto
[neste post](https://scoutapm.com/blog/how-to-use-lambdas-in-ruby).

Beleza, mas como podemos executar essas funções? Criando um botão cuja única
função é executar esses comandos:

```ruby
# dentro da classe JeffGui::Gui
def prepare
    require 'tk'
    @root = root = TkRoot.new { title "Ex1" }

    exec_queued = -> {
        unless @queue.empty? then exec_comandos_main_queue
        else puts "fila tá vazia"
        end
    }

    txt = TkText.new(root) {
        pack { padx 15 ; pady 15; side 'left' }
    }
    TkButton.new(root) {
        text 'Aperta!!'
        pack { padx 20 ; pady -20; side 'right' }
        command(proc {
            v = txt.value
            txt.value = ">>" + v + "<<"
        })
    }
    TkButton.new(root) {
        text 'comandos pendentes'
        pack { padx 20 ; pady -20; side 'right' }
        command(proc {
            exec_queued.call
        })
    }
    @prepared = true
end

private

def exec_comandos_main_queue
    until @queue.empty? do
        cmd = @queue.pop
        begin
            cmd.call @root
        rescue => e
            puts "oops, #{e}"
        end
    end
end
```

## Algumas gotas de sintaxe e semântica do ruby

Bastante coisa acontecendo, deixa eu ir com calma...
Primeiro ponto: eu preciso do elemento `root` para passar
nas chamadas dos comandos da fila. Portanto eu guardo o
`@root = root = TkRoot.new {...}`. Mantive o `root` como variável local
pela simples conveniência de poder escrever `root` nos elementos visuais,
não precisei trocar para `@root`.

Depois, o `private`. Basicamente `private` vai determinar que todas as
declarações após ele não devem ser expostas fora do local em que ele se situa
(módulo, classe). Aqui estou dizendo que a função `exec_comandos_main_queue`
é privada da classe `JeffGui::Gui`.

Dentro da função, temos aqui um laço até algo ser verdade: `until @queue.empty?`.
Da hora a expressividade do Ruby, né? Pois bem, nesse laço temos esse bloco:

```ruby
begin
    cmd.call @root
rescue => e
    puts "oops, #{e}"
end
```

Aqui o `begin` marca uma região, que poderá ser resgatado caso ocorra alguma exceção.
No meu caso, eu não especifiquei o topo da exceção para resgatar, mas é possível
fazer isso com `rescue SomeException => e`. Vários resgates podem ser feitos com
exceções distintas, e inclusive a exceção não precisa ser atribuída, apenas
capturada no resgate. Um exemplo completamente arbitrário só para mostrar a sintaxe:

```ruby
begin
  puts "olá"
rescue EOFError => e
  puts "eof?"
rescue NameError, Exception
 puts "hmmm?"
rescue => e
  puts "oh oooh"
end
```

Caso você queira fazer algo no final (independente de sucesso/falha, como o bloco
`finally` do Java ou do JS), você pode se assegurar (`ensure`) que foi feito:

```ruby
begin
  puts "sucesso"
ensure
  puts "no final das contas"
end
```

E você pode adicionar resgates também:

```ruby
begin
  puts "sucesso"
rescue
  puts "falha"
ensure
  puts "no final das contas"
end
```

O bloco conforme foi desenhado permite executar tudo até o esgotamento
da fila de execução. E quando há alguma falha, eu forneço um resgate, simples,
mas ainda assim um resgate para não parar abruptamente a execução de outros
comandos na fila:

```ruby
until @queue.empty? do
    cmd = @queue.pop
    begin
        cmd.call @root
    rescue => e
        puts "oops, #{e}"
    end
end
```

Ok, agora por que não chamar esse método diretamente na ação do botão?
Bem, minha primeira tentativa foi verificar por `@queue`, e ele reclamou que o atributo
`@queue` não existia/estava `nil`. Eis minhas tentativas e seus resultados:


```ruby
TkButton.new(root) {
    text 'comandos pendentes'
    pack { padx 20 ; pady -20; side 'right' }
    command(proc {
        puts @queue.size
    })
}
```

![unknwon size]({{ page.base-assets | append: "unknown-size.png" | relative_url }})

```ruby
TkButton.new(root) {
    text 'comandos pendentes'
    pack { padx 20 ; pady -20; side 'right' }
    command(proc {
        exec_comandos_main_queue
    })
}
```

![unknwon exec_comandos_main_queue]({{ page.base-assets | append: "unknown-exec_comandos_main_queue.png" | relative_url }})

Como contorna isso? Eu não sei. Só sei que variáveis na clausura funciona, então criei um lambda para
fazer essa chamada, e uso esse lambda na chamada:

```ruby
exec_queued = -> {
    unless @queue.empty? then exec_comandos_main_queue
    else puts "fila tá vazia"
    end
}

# ...

TkButton.new(root) {
    text 'comandos pendentes'
    pack { padx 20 ; pady -20; side 'right' }
    command(proc {
        exec_queued.call
    })
}
```

# Criando botão dinamicamente

Bem, agora que eu tenho a minha interface em Tk, a capacidade de passar
comandos pra ela pra ser executados na thread principal e, principalmente,
o IRB disponível para trabalhar, vamos começar a brincar com adicionar
elementos na interface?

Vamos começar adicionando um botão com uma ação bobinha?

```ruby
irb(main):001:1* $gui.queue << -> (root) {
irb(main):002:2*   TkButton.new(root) {
irb(main):003:2*     text "adicionado posteriormente"
irb(main):004:2*     pack {padx 20; pady -10; side 'right' }
irb(main):005:4*     command(proc {
irb(main):006:4*         puts "botão novo"
irb(main):007:2*         })
irb(main):008:1*   }
irb(main):009:0> }
```

<video controls width="250" alt="adicionando botão arbitrário">
  <source src="{{ page.base-assets | append: "add-botao.mov" | relative_url }}" type="video/quicktime" />
</video>

## Facilitando meu trabalho

Bem, uma coisa que estava particularmente me incomodando era
o modo como se fazia para mandar um comando. Precisa chamar uma variável global
chamada `$gui` e acessar um método dela e empurrar um valor... muita coisa.

A minha sensação era de que poderia ser mais simples. Então, e se eu declarasse
uma função no `console` de modo que ficasse acessível pro IRB? Bem, por que não?

Cenário de teste, função `hello`:

```ruby
def hello
    puts "oi oi"
end

require 'irb'
IRB.start(__FILE__)
```

E feliz, eu tinha o acesso a `hello` dentro do IRB. Assim sendo? Posso simplesmente
definir a função para enfileirar a chamda: `enqueue`. Ela recebe um único argumento
e passa para o `$gui` no campo `queue` chamando o operador de empurrar o argumento
receber para dentro de `queue`:

```ruby
def enqueue(cmd)
    $gui.queue << cmd
end
```

## Temporizador

Bem, por mais que eu tenha conseguido chegar até aqui, eu poderia simplesmente esperar
que o comando passado para a janela se executasse sozinho. Eu descobri o
[`TkTimer`](https://ruby-doc.org/stdlib-trunk/libdoc/tk/rdoc/TkTimer.html), que faz isso
que eu procura.

Pelo que encontrei em algumas fontes, você passa 2 argumentos e um bloco para esse `TkTimer`,
e depois pede para que ele se execute. No caso, o primeiro argumento é o intervalo de tempo
de repetição em mili segundos e o segundo é quantas vezes será repetido (onde `-1` é
infinitamente). Vamos testar aqui algo:

```ruby
enqueue -> (root) {
    TkTimer.new(250, -1) {
        puts "oi?"
    }.start
}
```

> Favor notar que o `start` é um método de `TkTimer`, e que ele está colocado após o bloco.

Ok, clicar no botão de "comandos pendentes" e... bem, uma enxurrada aqui de "oi?" "oi?"
"oi?" sem fim. Executando o timer na thread principal tudo ficou bem tranquilo. Hora de
testar no app. No método `show`, que é quando inicio o `Tk.mainloop`, vou antes iniciar
esse contador. Não precisa ser imediato para mim, então 1 segundo de delay tá ótimo.
Para alguns testes arbitrários eu precisei colocar um intervalor maior ou menor,
então não estranhe se vir por aqui um intervalo de 10000, foi só um rascunho para
provar um conceito que esqueci de normalizar o valor.

`show` ficou assim:

```ruby
def show
    prepare unless @prepared
    TkTimer.new(1000, -1) do
        exec_comandos_main_queue
    end.start
    Tk.mainloop
end
```

Então a cada segundo vai ser tentado zerar a fila. Com isso, os comandos serão executados
a cada segundo, tornando o botão de executar os comandos restantes desnecessários.
Para provar que funciona, vamos por uma label:

```ruby
enqueue -> (root) { TkLabel.new(root) { text "loucura"; pack {
 padx 20 ; pady -20; side 'right' }  }
```

E, _voi là_, o elemento está lá, no lugar. O `loucura` apareceu no lugar:

![loucura]({{ page.base-assets | append: "loucura.png" | relative_url }})

<!-- https://www.tutorialspoint.com/ruby/ruby_tk_guide.htm -->

# Geometrias, tutorial e mais enganos

Eu estava cometendo alguns erros que não estava satisfeito, mas também eu não
sabia informar quais erros. Então fui atrás de mais informações e achei
[este ótimo tutorial da Tutorials Point](https://www.tutorialspoint.com/ruby/ruby_tk_guide.htm).

Nele ele explica que você pode posicionar elementos e eles estarão dispostos de acordo
com uma geometria. As geometrias são:

- `pack`, que tentou-se usar aqui
- `grid`, ideia de colocar coisas na grid mesmo, por coluna e linha
- `place`, posicionamento mais "hardcore"

No `pack`, podemos selecionar o rumo que ele vai colocar. No caso, o padrão
é o `top`. O que acontece quando colocamos múltiplos elementos no `top`? Bem,
o primeiro elemento vai tocar na parte de cima do container. O segundo elemento
vai naquele rumo de tocar na parte de cima, mas naquele caminho existe o primeiro
elemento, então ele não vai se sobrepor a quem veio antes. E assim por diante.

De modo semelhante a `left`. O primeiro elemento adicionado com `left` vai
ficar o mais a esquerda possível, e depois o segundo elemento vai ficar o mais
a esquerda possível com exceção de quem entrou antes.

O padrão é `top`. Eu tentou criar duas caixas de texto, mas em cima dessas
caixas de texto uma label sugestiva "coisa ali na {lado}", onde {lado}
pode ser ou "esquerda" ou "direita". Primeira tentativa:

```ruby
irb(main):014:1* enqueue -> (root) {
irb(main):015:2*   frame = TkFrame.new(root) {
irb(main):016:2*     pack { side 'top'}
irb(main):017:1*   }
irb(main):018:1*
irb(main):014:1* enqueue -> (root) {
irb(main):015:2*   frame = TkFrame.new(root) {
irb(main):016:2*     pack { side 'top'}
irb(main):017:1*   }
irb(main):018:1*
irb(main):019:2*   def lbl(titulo, rel_root)
irb(main):020:3*     mini_frame = TkFrame.new(rel_root) {
irb(main):021:3*       pack {side 'left'}
irb(main):022:2*     }
irb(main):023:3*     TkLabel.new(mini_frame) {
irb(main):024:3*       pack {side 'top' }
irb(main):025:3*       text titulo
irb(main):026:2*     }
irb(main):027:3*     TkText.new(mini_frame) {
irb(main):028:3*       pack {side 'top' }
irb(main):029:2*     }
irb(main):030:2*     mini_frame
irb(main):031:1*   end
irb(main):032:1*   lbl('coisa ali na esquerda', frame)
irb(main):033:1*   lbl('coisa ali na direita', frame)
irb(main):034:0> }
```

![elementos ficaram todos como se fossem "top"]({{ page.base-assets | append: "tentativa-1.png" | relative_url }})

Bem, mas por quê? Vou pegar um exemplo do tutorial e ver a diferença:

```ruby
f1 = TkFrame.new {
   relief 'sunken'
   borderwidth 3
   background "red"
   padx 15
   pady 20
   pack('side' => 'left')
}
f2 = TkFrame.new {
   relief 'groove'
   borderwidth 1
   background "yellow"
   padx 10
   pady 10
   pack('side' => 'right')
}

TkButton.new(f1) {
   text 'Button1'
   command {print "push button1!!\n"}
   pack('fill' => 'x')
}
TkButton.new(f1) {
   text 'Button2'
   command {print "push button2!!\n"}
   pack('fill' => 'x')
}
TkButton.new(f2) {
   text 'Quit'
   command 'exit'
   pack('fill' => 'x')
}
Tk.mainloop
```

Notou a diferença? No meu código eu passei um bloco para `pack`. E aparentemente
esse bloco não foi executado (na real eu confirmei a não execução do bloco depois,
tanto pela inexistência da "função" `side` como também pondo um `puts`). Só que
`pack` não trabalha com bloco. `pack` vai trabalhar com argumento mapeado.

Entendido isso, vamos corrigir aquele código? Pelo menos posicionar os "mini frames"
internos lado a lado?

```ruby
irb(main):035:1* enqueue -> (root) {
irb(main):036:2*   frame = TkFrame.new(root) {
irb(main):037:2*     pack { side 'top'}
irb(main):038:1*   }
irb(main):039:1*
irb(main):040:2*   def lbl(titulo, rel_root)
irb(main):041:3*     mini_frame = TkFrame.new(rel_root) {
irb(main):042:3*       pack("side" => 'left')
irb(main):043:2*     }
irb(main):044:3*     TkLabel.new(mini_frame) {
irb(main):045:3*       pack {side 'top' }
irb(main):046:3*       text titulo
irb(main):047:2*     }
irb(main):048:3*     TkText.new(mini_frame) {
irb(main):049:3*       pack {side 'top' }
irb(main):050:2*     }
irb(main):051:2*     mini_frame
irb(main):052:1*   end
irb(main):053:1*   lbl('coisa ali na esquerda', frame)
irb(main):054:1*   lbl('coisa ali na direita', frame)
irb(main):055:0> }
```

![novos elementos posicionados]({{ page.base-assets | append: "tentativa-2.png" | relative_url }})

Sim, só agora escrevendo o artigo pude perceber que ainda estou fazendo besteira com o `pack`.
Ainda irei me acostumar com isso.

## Componentes

Acabei usando ali componentes complexos, mas nem expliquei nada, só usei.
Um `TkFrame` (tal qual o `TkRoot` também é um `TkFrame` para todos os efeitos)
é um container que posso colocar coisas dentro. No meu caso, eu queria criar
um componente composto por uma label e, abaixo dela, uma caixa de texto.
De personalização é só o texto mesmo da label.

Como fazemos para criar um componente que reflete isso? O `TkFrame`
vai servir de cola dos componentes, tal qual o `<> ... </>` que é comum em react.
O frame só está ali para juntar componentes atômicos. Dentro desse container,
eu coloco a label e em seguida o campo de texto. Recebo o título como argumento
e devolvo o frame que está envolvendo os componentes (assim como o `parent`,
receber o `parent` é uma necessidade no Tk):

```ruby
def lbl(titulo, rel_root)
  mini_frame = TkFrame.new(rel_root) {
    pack("side" => 'left')
  }
  TkLabel.new(mini_frame) {
    pack("side" => 'top')
    text titulo
  }
  TkText.new(mini_frame) {
    pack("side" => 'top')
  }
  mini_frame
end
```

Claro que provavelmente você quer ter um acesso mais rico aos
componentes internos, mas você pode inverter o controle e passar
para o compoenente algo para que o componente possa dar alguma
sinalização. Ou então permitir capturar os valores textuais
para fazer algum trabalho com isso.

Ou então expor os componentes internos, usando um objeto intanciado
localmente a partir de uma classe anônima:

```ruby
def lbl(titulo, rel_root)
    mini_frame = TkFrame.new(rel_root) {
        pack("side" => 'left')
    }
    TkLabel.new(mini_frame) {
        pack("side" => 'top')
        text titulo
    }
    txtComponent = TkText.new(mini_frame) {
        pack("side" => 'top')
    }
    Class.new do
        def initialize(mini_frame, txtComponent)
            @mini_frame = mini_frame
            @txtComponent = txtComponent
        end
        def container
            @mini_frame
        end

        def txt
            @txtComponent
        end
    end.new mini_frame, txtComponent
end


# exemplo manipulando

esquerda = lbl("parada a esquerda", root)
esquerda.txt.value = "inserindo o valor"
```

Ok, mas eu posso brincar um pouco mais com isso. Posso resgatar o valor do texto
como se ele fosse a variável principal. E também posso setar esse valor. Para tal,
vou criar os métodos `value` e `value=`:

```ruby
def lbl(titulo, rel_root)
    mini_frame = TkFrame.new(rel_root) {
        pack("side" => 'left')
    }
    TkLabel.new(mini_frame) {
        pack("side" => 'top')
        text titulo
    }
    txtComponent = TkText.new(mini_frame) {
        pack("side" => 'top')
    }
    Class.new do
        def initialize(mini_frame, txtComponent)
            @mini_frame = mini_frame
            @txtComponent = txtComponent
        end
        def container
            @mini_frame
        end

        def txt
            @txtComponent
        end
        def value
            @txtComponent.value
        end
        def value=(newValue)
            @txtComponent.value = newValue
        end
    end.new mini_frame, txtComponent
end


# exemplo manipulando

esquerda = lbl("parada a esquerda", root)
esquerda.value = "inserindo o valor"
```

## Popup

Precisei exibir uma mensagem em um popup. Para ser a resposta de uma chamada.
O problema do popup é que ele prende a thread principal até ser liberado,
além de que no Mac ele não renderizou legal:

![um simples popup]({{ page.base-assets | append: "popup.png" | relative_url }})

O código para gerar foi o seguinte (onde `lhsComponent` e `rhsComponent` são `TkText`).

```ruby
Tk.messageBox(
    type: 'ok',
    icon: "info",
    title: "A random title",
    message: "over #{lhsComponent.value} as LHS and #{rhsComponent.value} as RHS",
    detail: 'detalhe'
)
```

## Manipulando componente a partir de "wpath"

Assim como no DOM se tem o XPath, no Tk temos algo similar. Podemos inspecionar a partir de um
elemento container os seus filhos. Eu previsava
de dois campos textuais lado a lado, cada um com um título, e um botão de ação:

```ruby
def prepare
    require 'tk'
    @root = root = TkRoot.new { title "Ex1" }

    def lbl(titulo, rel_root)
        mini_frame = TkFrame.new(rel_root) {
            pack("side" => 'left')
        }
        TkLabel.new(mini_frame) {
            pack("side" => 'top')
            text titulo
        }
        txtComponent = TkText.new(mini_frame) {
            pack("side" => 'top')
        }
        Class.new do
            def initialize(mini_frame, txtComponent)
                @mini_frame = mini_frame
                @txtComponent = txtComponent
            end
            def container
                @mini_frame
            end

            def value
                @txtComponent.value
            end

            def value=(newValue)
                @txtComponent.value = newValue
            end

            def txt
                @txtComponent
            end
        end.new mini_frame, txtComponent
    end

    mini_frame = TkFrame.new(root) {
        pack('side' => 'top')
    }

    lhsComponent = lbl('lhs', mini_frame)
    rhsComponent = lbl('rhs', mini_frame)

    submit = TkButton.new(root) {
        pack('side' => 'bottom')
        text "submit"
        command do
            Tk.messageBox(
                type: 'ok',
                icon: "info",
                title: "A random title",
                message: "over #{lhsComponent.value} as LHS and #{rhsComponent.value} as RHS",
                detail: 'detalhe'
            )
            puts "lhs text value #{lhsComponent.value}"
            puts "rhs text value #{rhsComponent.value}"
            lhsComponent.value = ">>#{lhsComponent.value}<<"
        end
    }

    @prepared = true
end
```

Então, para alterar o título do campo de texto a esquerda, precisei navegar através da raiz
(um `TkRoot`, representado por `$gui`) assim:

```ruby
irb(main):002:0> $gui.root
=> #<Tk::Root:0x0000000104a26b38 @path=".">
irb(main):003:0> $gui.root.winfo_children
=>
[#<Tk::Frame:0x0000000104b42940 @path=".w00000">,
 #<Tk::Button:0x0000000104c00f80 @path=".w00007">]
irb(main):004:0> $gui.root.winfo_children[0].winfo_children
=>
[#<Tk::Frame:0x0000000104c2d120 @path=".w00000.w00001">,
 #<Tk::Frame:0x0000000104ac1278 @path=".w00000.w00004">]
irb(main):005:0> $gui.root.winfo_children[0].winfo_children[0].winfo_children
=>
[#<Tk::Label:0x0000000104bceb70 @path=".w00000.w00001.w00002">,
 #<Tk::Text:0x00000001043e0850 @path=".w00000.w00001.w00003">]
irb(main):006:0> $gui.root.winfo_children[0].winfo_children[0].winfo_children[0]
=> #<Tk::Label:0x0000000104bceb70 @path=".w00000.w00001.w00002">
irb(main):007:0>
```

Vamos chamar esse carinha de `label`:

```ruby
irb(main):011:0> label = $gui.root.winfo_children[0].winfo_children[0].winfo_children[0]
=> #<Tk::Label:0x0000000104bceb70 @path=".w00000.w00001.w00002">
```

Para alterar seu texto, só escrever no campo `text`. Como estou no IRB, precisei
mandar para o `enqueued`:

```ruby
irb(main):016:0> enqueue -> (root) { label.text = "esquerda" }
```

A outra label que eu queria mudar é do componente irmão desse. Ao analisar a descida na
árvore, tem um lugar que tem como filhos dois `Tk::Frame`s distintos:

```ruby
irb(main):004:0> $gui.root.winfo_children[0].winfo_children
=>
[#<Tk::Frame:0x0000000104c2d120 @path=".w00000.w00001">,
 #<Tk::Frame:0x0000000104ac1278 @path=".w00000.w00004">]
```

Então, para localizar a outra label e alterar seu texto, só descer no componente
irmão:

```ruby
irb(main):021:0> label2 = $gui.root.winfo_children[0].winfo_children[1].winfo_children[0]
=> #<Tk::Label:0x0000000104c07100 @path=".w00000.w00004.w00005">
```

Em contraponto, a primeira label era esta:

```ruby
irb(main):011:0> label = $gui.root.winfo_children[0].winfo_children[0].winfo_children[0]
=> #<Tk::Label:0x0000000104bceb70 @path=".w00000.w00001.w00002">
```

E usando a mesma estratégia pude mudar o text do outro título:

```ruby
irb(main):022:0> enqueue -> (root) { label2.text = "direita" }
```

![os componentes da tela]({{ page.base-assets | append: "aplicacao-teste.png" | relative_url }})

# Fechando

O que foi mostrado aqui deve ser o suficiente para permitir uma experiência
interativa para codar janelas em Tk usando Ruby. Como uma interface gráfica,
Tk é muito mais do que apenas isso. Existem outras coisas a mais para lidar,
como outras questões de posicionamentos e principalmente eventos. Mas
acredito que o que foi mostrado aqui foi o suficiente para que se consiga
adiantar bastante no uso disso.

Em cima de um canvas no Tk eu fiz um joguinho simples em Python:
[https://github.com/jeffque/games-tk-breakout](https://github.com/jeffque/games-tk-breakout).
Note que no repositório o código é Python, mas a base de toda a interface
gráfica é Tk, e portanto a parte de interface e comunicação coma lógica
de negócio é a mesma, independente da lang que tem o Tk embarcado.

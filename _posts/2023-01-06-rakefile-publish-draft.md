---
layout: post
title: "Rakefile, parte 1 - publicar rascunho"
author: "Jefferson Quesado"
tags: ruby meta rakefile
---

Estou bem acostumado com Makefile, e se eu fosse customizar
minhas ações com Rakefile? Vamos ver como seria?

O objetivo aqui é substituir o Makefile (que atualmente conta
com duas ações) por um Rakefile, e de preferência também permitir
outras automatizações que por enquanto não são Makefile também
se tornarem Rakefile. Fazendo isso enquanto me baseio na
[documentação](https://ruby.github.io/rake/doc/rakefile_rdoc.html).

O artigo se dividirá nas seguintes seções:

1. apanhado geral do Rakefile
1. rodar o Jekyll
1. fazer a ação de publicar (leia artigo [Movendo de draft para post]({% post_url 2021-12-28-publish-draft %}))

E na parte 2 teremos:

1. criar um novo post (leia artigo [Criando posts com Makefile]({% post_url 2022-10-16-new-post %}))
1. pegar menção de imagem (leia artigo [Automatizando menção de imagem]({% post_url 2022-10-19-automatizando-mencao-imagem %}))

# Apanhado geral do Rakefile

Antes de mais nada, o Rakefile é um código Ruby. Portanto, qualquer
coisa Ruby que você imaginar pode ser colocado.

Rakefile é dividido por algumas regrinhas para interação com a linha
de comando. Entre elas:

- `task`: tarefas, multi propósito; se quiser algo realizado, queira uma tarefa
- `file`: uma especificação de tarefa, mas para a geração de um arquivo
- `rule`: uma generalização de `file`, mas com padrões, similar ao `%` do Makefile

Uma task tem um nome. Existe a task especial `:default`. Chamar o comando
`rake` sem nada fará chamar a task `:default`.

Opcionalmente, uma task pode ter uma lista de tasks as quais a task
original depende.

Por exemplo:

```ruby
task :default => :run
```

Aqui tá dizendo que a task `default` depende da task `run`.

Além disso, você pode dizer como se executa uma task:

```ruby
task :hello do |t|
    p 'hello'
end
```

# Rodar o Jekyll

Meu primeiro objetivo é substituir o meu comando `make`.

Atualmente, ele está assim:

```Makefile
run:
        bundle exec jekyll s --drafts -w
```

Eu até posso invocar a gem diretamente, mas isso implica chamar a shell
do sistema e outras indireções que eu não gostaria.

Bem, Jekyll é uma gem ruby, né? Então, o código dela é plausível de ser
chamado programaticamente dentro do Ruby. No caso específico do Jekyll,
ele usa Mercenary para lidar com a linha de comando, e eu [já tive
experiência com ela]({% post_url 2022-09-13-criando-gem %}).

Poderia tentar fazer uma gambiarra e chamar o Mercenary? Bem, sim, mas não
era a minha intenção. Eu queria uma chamada mais direta, e achei [esta
resposta no Stack Overflow][so-answer]
que me deu a ideia de como fazer a engenharia reversa.

Depois de várias experimentações, o que me chamou a atenção de modo mais efetivo
foi essa linha [`exe/jekyll#L41`](https://github.com/jekyll/jekyll/blob/a891118af45d6c96a2859dd6d914be78326e211d/exe/jekyll#L41):

```ruby
Jekyll::Command.subclasses.each { |c| c.init_with_program(p) }
```

Aqui ele está adicionando todas as subclasses de `Jekyll::Command` para
inicializar o `program`. Não fui atrás exatamente como que se faz para se
obter esses detalhes, mas fui atrás do comando
([`lib/jekyll/commands/`](https://github.com/jekyll/jekyll/tree/a891118af45d6c96a2859dd6d914be78326e211d/lib/jekyll/commands))
que me interessava: `serve`.

Como pegar esse comando? Bem, por sorte existe um
[`lib/jekyll/commands/serve.rb`](https://github.com/jekyll/jekyll/blob/a891118af45d6c96a2859dd6d914be78326e211d/lib/jekyll/commands/serve.rb).
E aqui peguei as seguintes informações:

- ele na real se chama `serve`
([`#L62`](https://github.com/jekyll/jekyll/blob/a891118af45d6c96a2859dd6d914be78326e211d/lib/jekyll/commands/serve.rb#L62))  
  ```ruby
  prog.command(:serve) do |cmd|
  ```
- ele tem alias para `s` e `server`
([`#L65-66`](https://github.com/jekyll/jekyll/blob/a891118af45d6c96a2859dd6d914be78326e211d/lib/jekyll/commands/serve.rb#L65-L66))  
  ```ruby
  cmd.alias :server
  cmd.alias :s
  ```
- de fato ele chama uma função chamada `process_with_graceful_failure` passando
  como argumentos `Build` e, também, `Serve` ([`#L86`](https://github.com/jekyll/jekyll/blob/a891118af45d6c96a2859dd6d914be78326e211d/lib/jekyll/commands/serve.rb#L86))
  ```ruby
  process_with_graceful_fail(cmd, config, Build, Serve)
  ```

Tá, mas e o que essa função faz? Bem, sinceramente, não liguei muito inicialmente
não. Vi que na [resposta do Stack Overflow][so-answer] ele construía um
`Jekyll::Configuration` e chamava o método `process`. Para não ficar
apenas tentando adivinhar nas cegas, abri o `irb`, fiz o `require` da gem
e fiquei testando até encontrar alguma coisa interessante.

A primeira coisa interessante que encontrei era que a classe meio que funciona
como um singleton, diferentemente do que tem na [resposta][so-answer]. Na
versão do Jekyll que ele usava, ele precisa instanciar o `command` específico,
mas aqui não preciso disso. Outro ponto é que a configuração agora é passada para
o método específico de servir, não está na contrução do objeto.

Então, para chamar o `Serve`, para uma configuração abstrata `conf`:

```ruby
Jekyll::Commands::Serve.process conf
```

Beleza, até aqui tudo bom. Mas... eu estava sentindo falta da capacidade
do Jekyll de fazer o build. Então, fui olhar a origem do
[`process_with_graceful_failure`](https://github.com/jekyll/jekyll/blob/a891118af45d6c96a2859dd6d914be78326e211d/lib/jekyll/command.rb#L90-L101):

```ruby
def process_with_graceful_fail(cmd, options, *klass)
  klass.each { |k| k.process(options) if k.respond_to?(:process) }
rescue Exception => e
  raise e if cmd.trace

  msg = " Please append `--trace` to the `#{cmd.name}` command "
  dashes = "-" * msg.length
  Jekyll.logger.error "", dashes
  Jekyll.logger.error "Jekyll #{Jekyll::VERSION} ", msg
  Jekyll.logger.error "", " for any additional information or backtrace. "
  Jekyll.logger.abort_with "", dashes
end
```

O `cmd` ele usa apenas como argumento para obter o nome do comando ou
para imprimir o stack trace em eventual exceção em alguma configuração.
De resto, ele investiga todas as clases passadas como argumento (note que
o último argumento é `*klass` com asterisco, portanto indicando que
`klass` é vararg).

Em cima de `klass`, ele pergunta para cada argumento se ele é capaz de
atender à chamada do método `.process` (`if k.respond_to?(:process)`).
Se responder, então ele chama passando a configuração como
argumento (`k.process(conf)`).

Então... vamos lá?

Se é para simular como o `Serve` funciona...

```ruby
Jekyll::Commands::Build.process conf
Jekyll::Commands::Serve.process conf
```

Mas... ele não fica observando para postar, nem posta rascunhos.
As opções que usei para lidar com isso na CLI foram `-w` e `--drafts`.
Essas seriam opções específicas do `Serve`? Hmmm, não. Mas estão localizadas
no global
[`command`](https://github.com/jekyll/jekyll/blob/a891118af45d6c96a2859dd6d914be78326e211d/lib/jekyll/command.rb#L54-L76):

```ruby
cmd.option "watch", "-w", "--[no-]watch", "Watch for changes and rebuild"
#...
cmd.option "show_drafts", "-D", "--drafts", "Render posts in the _drafts folder"
```

O mercenary lida com isso colocando na configuração um mapa, no caso de
configurações sem argumentos (como essas) ao ligar a configuração ele
coloca `true`. Portanto...

```ruby
conf = Jekyll.configuration({
    'show_drafts' => true,
    'watch' => true
})
Jekyll::Commands::Build.process conf
Jekyll::Commands::Serve.process conf
```

é... não saiu bem como esperado

```
     Generating...
                    done in 7.051 seconds.
 Auto-regeneration: enabled for 'C:/repos/computaria/blog'
```

Ao dar um `ctrl+c` aparece a seguinte mensagem:

```
    Server address: http://127.0.0.1:4000/blog/
  Server running... press ctrl-c to stop.
```

Pelo visto alguma coisa não deixou satisfeito o `Build`... Ao examinar
como o `Build` responde ao `.process` percebi que ele coloca um default
nas opções, `opt["serving"] = false` na ação do Mercenary. E que no `Serve`
a ação do mercenary coloca justamente o contrário, `opt["serving"] = true`.
Então fiquei curioso para ver o que acontecia ao chamar o `'watch' => true`
e encontrei isto, no [`jekyll-watch`](https://github.com/jekyll/jekyll-watch/blob/9c9d2ab3c995784343c7791bc6f02f7c6b2dc1e5/lib/jekyll/watcher.rb#L30-L38):

```ruby
unless options["serving"]
    trap("INT") do
        listener.stop
        Jekyll.logger.info "", "Halting auto-regeneration."
        exit 0
    end

    sleep_forever
end
```

basicamente aqui ele indica que, caso `opt["serving"]` não for verdade,
então ele vai entrar no laço infinito, quebrável justamente pelo
`SIGINT` disparado pelo `ctrl+c`.

Então, qual minha conclusão? Vamos tentar adicionar o `"serving" => true`
nas configurações:

```ruby
conf = Jekyll.configuration({
    'show_drafts' => true,
    'watch' => true,
    'serving' => true
})
Jekyll::Commands::Build.process conf
Jekyll::Commands::Serve.process conf
```

E pronto, com isso conseguimos fazer o site ficar se auto-construindo de modo suave.

# Ação de publicar

Bem, a ação de publicar atualmente consiste em chamar o script `bin/publish.sh`
passado como argumento o arquivo a ser transformado em publicação, seja com
caminho completo. E antes ficava como argumento de CLI quem seria publicado.

Bem, posso continuar chamando o script. Assim como posso criar a ação `:publish`
e, dentro dessa ação, listar o que eu tenho para publicar e chamar o tal
script (ao menos por hora) com a informação selecionada.

Rapidamente numa procura por "terminal ui ruby" encontrei a gem
[`cli-ui`](https://github.com/Shopify/cli-ui), e logo de cara ele tem um exemplo
com uma seleção:

```ruby
CLI::UI.ask('What language/framework do you use?', options: %w(rails go ruby python))
```

Testando aqui, descobri que `CLI::UI.ask` retorna a opção selecionada. Ele também
fornece como exemplo chamar alguma função de callback baseado na escolha.

No meu caso, quero listar todos os arquivos dentro de `_drafts`. Descobri que
[o ruby já fornece isso](https://stackoverflow.com/a/1755713/4438007):

```ruby
Dir["_drafts/*.md"]
```

Agora, só mapear para remover a extenção do final e o `_drafts/` do começo e `.md`
do fim. Posso tacar uma regexp para sanar isso. Eis um experimento:

```ruby
irb(main):012:0> "_drafts/abc.md".sub(/^_drafts\/(.*)\.md$/, '\1')
=> "abc"
```

Juntando tudo isso tenho:

```ruby
Dir["_drafts/*.md"].map {|s| s.sub(/^_drafts\/(.*)\.md$/, '\1') }
```

Agora sim, pronto para por nas opções da task `publish` do Rakefile:

```ruby
task :publish do |t|
    require "cli/ui"

    draft2publish = CLI::UI::Prompt.ask('What language/framework do you use?', options:  Dir["_drafts/*.md"].map {|s| s.sub(/^_drafts\/(.*)\.md$/, '\1') })
    sh "#{"bash " if Gem.win_platform?}bin/publish.sh #{draft2publish}"
end
```

Como o script chamado é um script bash, precisei invocar a bash na mão no
caso de se estar no windows.

[so-answer]: https://stackoverflow.com/a/18409462/4438007

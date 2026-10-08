---
layout: post
title: "Transferindo conteúdo entre máquinas usando WEBrick"
author: "Jefferson Quesado"
tags: ruby webrick html htmx
base-assets: "/assets/webrick-transfer/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Meu desafio é simples: transferir arquivos de uma máquina para outra. Mas eu
tenho algumas dificuldades adicionais: sem SSH. E isso torna as coisas mais
interessantes.

A ideia é transferir alguns diretórios da máquina antiga para a máquina nova.
Eu poderia fazer isso usando Node? Provável. Mas eu quis fazer com Ruby usando
WEBrick para servir HTTP.

# Arquitetura

Basicamente a ideia é ter um end point que, ao ser requisitado com algum
parâmetro que indique o diretório do computador corrente, retorne um zip com
todo o conteúdo daquele diretório. Assim fica fácil extrair.

Para deixar tudo mais simples, não vou fazer processamento de path do HTTP, vai
ser tudo argumento de `POST`.

Para não precisar de um script por trás da nova máquina (e também porque não
tenho tanta coisa a ser transferida assim), a raiz vai retornar uma simples
página com uma combobox listando os diretórios e um botão para fazer o
download. Vou povoar essa combobox dinamicamente usando HTMX.

Para conseguir listar as opções do combobox, vou precisar de um endpoint com os
possíveis caminhos. De modo geral, fica assim:

- `/` _human-facing_ HTML com a seleção do que baixar e o botão
- `/download` recebe um diretório (`POST`) como parâmetro e retorna o zip disso
- `/list` retorna as opções do combobox com os caminhos

# Listando diretório recursivamente

Uma das principais coisas do zip é poder adicionar recursivamente tudo que
estiver dentro do diretório. Basicamente, se eu listar o diretório `sandbox`
com essa estrutura

```none
sandbox
├── bin
│   └── webserver.rb
├── Gemfile
├── Gemfile.lock
└── lib
    ├── zippy
    │   ├── descent.rb
    │   └── zipdir.rb
    └── zippy.rb
```

Vou precisar navegar em todos os diretórios e arquivos, para uma lista final de
arquivos:

- `sandbox/bin/weserver.rb`
- `sandbox/Gemfile`
- `sandbox/Gemfile.lock`
- `sandbox/lib/zippy/descent.rb`
- `sandbox/lib/zippy/zipdir.rb`
- `sandbox/lib/zippy.rb`

Como quero transferir também diretórios parcialmente trabalhados, então vem bem
a calhar enviar os próprios `.git` desses diretórios. Logo, preciso explorar
tanto arquivos trandicionais como arquivos ocultos.

> Ah, para quem vem do mundo Unix e tá acostumado sabe do que estou falando.
> Mas de toda sorte, só pra deixar claro: todo arquivo que começa com `.` é
> um arquivo/diretório oculto em sistemas de arquivo Unix, como o próprio
> `.git/`, o `.gitignore`, `.file.swp` etc.

De modo geral, o algoritmo é algo nesse esqueleto:

```rb
def recursivo(dir)
  explode(dir).each do |f|
    if File.file? f
      visita(f)
    elsif File.directory? f
      recursivo(f)
    end
  end
end
```

Como eu faço a "explosão"? Uma das alternativas que encontrei foi usar
`Dir["path/*"]`. Essa estratégia não me parece muito ruim, vou adotar ela.
Por hora, vamos usar como "visita" imprimir o nome do arquivo, ok?

```rb
def recursivo(dir)
  Dir["#{dir}/*"].each do |f|
    if File.file? f
      puts(f)
    elsif File.directory? f
      recursivo(f)
    end
  end
end
```

Usando isso apontando para `sandbox`:

```none
sandbox/Gemfile
sandbox/Gemfile.lock
sandbox/bin/webserver.rb
sandbox/lib/zippy/descent.rb
sandbox/lib/zippy/zipdir.rb
sandbox/lib/zippy.rb
```

Como o esperado. Agora, talvez o diretório passado (na real, provável) tenha
uma sequência de caracteres que não seja feliz para o zip gerado. Como, por
exemplo, `../sandbox`. Vamos ver como que ficaria passando isso como arugmento
(e adequando o diretório em que se roda isso, obviamente):

```none
../sandbox/Gemfile
../sandbox/Gemfile.lock
../sandbox/bin/webserver.rb
../sandbox/lib/zippy/descent.rb
../sandbox/lib/zippy/zipdir.rb
../sandbox/lib/zippy.rb
```


Ehhh, não exatamente o que eu queria. Então que tal remover o diretório base na
hora de identificar o arquivo senod visitado? Posso gerar um nome de "arquivo
limpo", digamos asim:

```rb
def recursivo(dir)
  Dir["#{dir}/*"].each do |f|
    f_limpo = f[dir.length + 1..]
    if File.file? f
      puts(f_limpo)
    elsif File.directory? f
      recursivo(f)
    end
  end
end
```

E o resultado:

```none
Gemfile
Gemfile.lock
webserver.rb
descent.rb
zipdir.rb
zippy.rb
```

Éeeeee... ok, e se eu acompanhasse com uma espécie de "diretório base" que a
cada descida recursiva eu adicionava o "arquivo limpo"? E aí se removia o
`dir` porém colocava esse diretório base antes para indicar o caminho visitado
até o momento?

Ah, claro, com uma tratativa especial de borda: se o caminho base for string
vazia, preciso obter

```none
Gemfile
Gemfile.lock
bin/webserver.rb
lib/zippy/descent.rb
lib/zippy/zipdir.rb
lib/zippy.rb
```

e não

```none
/Gemfile
/Gemfile.lock
/bin/webserver.rb
/lib/zippy/descent.rb
/lib/zippy/zipdir.rb
/lib/zippy.rb
```

com essa barra no começo.

```rb
def recursivo(dir, base)
  Dir["#{dir}/*"].each do |f|
    f_limpo = f[dir.length + 1..]
    full_path = unless base.empty? then File.join(base, f_limpo) else f_limpo end
    if File.file? f
      puts(full_path)
    elsif File.directory? f
      recursivo(f, full_path)
    end
  end
end
```

E o resultado foi

```none
Gemfile
Gemfile.lock
bin/webserver.rb
lib/zippy/descent.rb
lib/zippy/zipdir.rb
lib/zippy.rb
```

Passando `sandbox` como argumento para `base`?

```none
sandbox/Gemfile
sandbox/Gemfile.lock
sandbox/bin/webserver.rb
sandbox/lib/zippy/descent.rb
sandbox/lib/zippy/zipdir.rb
sandbox/lib/zippy.rb
```

Muito bem! Conseguimos fazer uma descida recursiva nos arquivos!

Mas... será que daria para fazer algo mais simples na descida? Se eu
simplesmente enumerasse os arquivos com nomes crus e o recebedor
tratasse o nome removendo eventual prefixo?

Algo como se a chamada fosse:

```rb
recursivo_visitante("../sandbox") do |f|
  f_limpo = f["../sandbox".length + 1..]
  puts(f_limpo)
end
```

que produzisse

```none
Gemfile
Gemfile.lock
bin/webserver.rb
lib/zippy/descent.rb
lib/zippy/zipdir.rb
lib/zippy.rb
```

Assim a enumeração recursiva fica bem mais simples! Bem, o Ruby permite que eu
passe blocos para baixo, né? E eu mando argumento pro bloco usando `yield`.
Poderia fazer algo assim:

```rb
def recursivo_visitante(dir)
  Dir["#{dir}/*"].each do |f|
    if File.file? f
      yield f
    elsif File.directory? f
      recursivo_visitante(f)
    end
  end
end
```

Só que isso gera pane na chamada recursiva porque não tem bloco explícito na
chamada recursiva (ele não herda imediatamente do chamador).

```err
Gemfile
Gemfile.lock
~/sandbox/lib/zippy/descent.rb:40:in 'block in Object#recursivo_visitante': no block given (yield) (LocalJumpError)
```

Uma gambiarra simples seria fazer:

```rb
def recursivo_visitante(dir)
  Dir["#{dir}/*"].each do |f|
    if File.file? f
      yield f
    elsif File.directory? f
      recursivo_visitante(f) do |ff| yield ff end
    end
  end
end
```

e isso resolve o problema completamente. Mas... feio, né? Eu posso pegar o
bloco e passar para baixo também, explicitamente:

```rb
def recursivo_visitante(dir, &block)
  Dir["#{dir}/*"].each do |f|
    if File.file? f
      yield f
    elsif File.directory? f
      recursivo_visitante(f, &block)
    end
  end
end
```

Isso aqui me parece mais adequado porque não fico criando blocos de indireção
no meio do caminho. E para ficar organizadinho, vou colocar dentro de um módulo
chamado `Zippy`:

```rb
module Zippy
  def self.recursivo_visitante(dir, &block)
    Dir["#{dir}/*"].each do |f|
      if File.file? f
        yield f
      elsif File.directory? f
        recursivo_visitante(f, &block)
      end
    end
  end
end
```

Para simplificar a escrita, onde não for estritamente necessário mencionar o
módulo propriamente dito ele vai ser ignorado, e com isso tratarei as funções
como coisas soltas e portanto sem o `self.` na frente.

## Arquivos ocultos

Me percebi agora que não tratei nenhum caso com arquivos ocultos! Bem, bora
lá...

Preciso listar os arquivos comuns e os ocultos. Se estou usando splicing no
índice do diretório, será que funciona botar um `,` e outro padrão _glob_?

```rb
Dir["#{dir}/*", "#{dir}/.*"].each do |f|
  puts f
end
```

E dá certo... de certo modo... Digo isso porque essa expansão adiciona o `.` e
também um arquivo que o MacOS meio que coloca automaticamente:

```none
../sandbox/Gemfile
../sandbox/Gemfile.lock
../sandbox/bin
../sandbox/lib
../sandbox/.
../sandbox/.DS_Store
```

Notou as duas últimas entradas? O `../sandbox/.` indica o próprio diretório
acima; ou seja, `../sandbox`. Já o `.DS_Store` é uma pastinha oculta que o
MacOS mantém. Para nossos efeitos, só preciso ignorar.

Vamos rejeitar as entradas nesses casos? Em que o arquivo "limpinho" ficaria só
`.` ou seria `.DS_Store`? Para isso uso o `reject` da lista:

```rb
Dir["#{dir}/*", "#{dir}/.*"].reject do |f|
  f_limpo = f[dir.length + 1..]
  f_limpo == "." || f_limpo == ".DS_Store"
end.each do |f|
  puts f
end
```

Colocando isso na função de listagem recursiva:

```rb
def recursivo_visitante(dir, &block)
  Dir["#{dir}/*", "#{dir}/.*"].reject do |f|
    f_limpo = f[dir.length + 1..]
    f_limpo == "." || f_limpo == ".DS_Store"
  end.each do |f|
    if File.file? f
      yield f
    elsif File.directory? f
      recursivo_visitante(f, &block)
    end
  end
end
```

# Zip

Agora que eu sei listar recursivamente, vamos montar o arquivo zip para baixar
as coisas? Mas eu quero montar com uma condição em especial: não quero ocupar
espaço em disco com coisa temporária, quero que ele seja tratado totalmente em
memória sem a criação de arquivos.

Pesquisando rapidamente, encontrei a Gem
[`rubyzip`](https://rubygems.org/gems/rubyzip) que lida com questões de
arquivos zip e tem o que eu precisava através da
[`Zip::OutputStream.write_buffer`](https://www.rubydoc.info/gems/rubyzip/3.7.0/Zip/OutputStream#write_buffer-class_method).

No primeiro experimento, queria obter a zip stream e então copiar ela na saída
padrão. A chamada na linha de comando vai ser:

```bash
bundle exec ruby bin/webserver.rb > test.zip
```

E, enquanto não monto o webserver propriamente dito, aproveito o arquivo para
fazer essas coisas de IO:

```rb
require_relative "../lib/zippy"

stream = Zippy::create_zip_stream("../sandbox")
IO.copy_stream(stream, STDOUT)
```

Eu imaginava que ficaria algo assim o `create_zip_stream`:

```rb
def create_zip_stream(dir)
  Zip::OutputStream.write_buffer do |out|
    recursivo_visitante(dir) do |f|
      f_limpo = f[dir.length+1..]
      out.put_next_entry f_limpo
      File.open(f) do |ff|
        IO.copy_stream ff, out
      end
    end
  end
end
```

E isso de fato retorna a stream, mas o arquivo `test.zip` nasce zerado...
Hmmm...

Olhando aqui uma
[resposta no StackOverflow](https://stackoverflow.com/a/9712252/4438007)
percebi que antes de passar a stream adiante primeiro se rebobinava ela.
Então, será que isso seria o suficiente? Vamos ver:

```rb
def create_zip_stream(dir)
  out = Zip::OutputStream.write_buffer do |out|
    recursivo_visitante(dir) do |f|
      f_limpo = f[dir.length+1..]
      out.put_next_entry f_limpo
      File.open(f) do |ff|
        IO.copy_stream ff, out
      end
    end
  end
  out.rewind
  out
end
```

E... foi! Sim, isso foi o suficiente!

Mas isso é para quando eu vou retornar uma stream para depois manipular ela...
e se eu já tiver a stream que eu queira escrever? Esse vai ser o caso para, por
exemplo, quando eu estiver manipulando a saída via HTTP. Então, vamos passar
diretamente uma stream? Vou enviar `STDOUT` diretamente, desse modo a minha
chamada na CLI continua sendo

```bash
bundle exec ruby bin/webserver.rb > test.zip
```

Porém agora o `webserver.rb` fica assim:

```rb
require_relative "../lib/zippy"

stream = Zippy::zip_stream("../sandbox", STDOUT)
```

Segundo a própria documentação do `Zip::write_buffer`, o primeiro argumento
pode ser diretamente uma stream, que nessa situação ele vai trabalhar em cima
dela no lugar de criar uma pseudo-stream para que eu possa trabalhar:

```rb
def zip_stream(dir, stream)
  Zip::OutputStream.write_buffer(stream) do |out|
    recursivo_visitante(dir) do |f|
      f_limpo = f[dir.length+1..]
      out.put_next_entry f_limpo
      File.open(f) do |ff|
        IO.copy_stream ff, out
      end
    end
  end
end
```

_Et voi là_! Tudo funcionou maravilhoramente bem!

# WEBrick

A primeira coisa é descobrir como servir um arquivo. Existem diversos servlets
no WEBrick que servem um par de coisas padrão, incluindo aqui o
`WEBrick::HTTPServlet::FileHandler`.

O bootstrap para as coisas do WEBrick é bem curtinho:

```rb
require "webrick"

server = WEBrick::HTTPServer.new :Port => :8000

server.mount "/path", ServletClassExample
server.mount_proc "/other-path" do |req, res|
  # código do serviço
end

trap "INT" do
    server.shutdown
end

server.start
```

Esse `trap` serve para adicionar um hook a um sinal Unix. No caso, estou
colocando para o SIGINT a ação de dar um `server.shutdown`. Como o bloco
passado não tem argumentos, isso é indicado por nada depois do `do`. Mas se
quiser ser explícito pode passar `| |` (com um espaço separando, pra não
confundir com o operador `||` _or_).

> Tá, na verdade o ruby em si aceita o `do || ... end` sem o espaço, mas isso
> quebra o syntax highlighting do VSCode. Mas não o do IRB.

Primeiro teste, vamos servir um arquivo? Vou servir om próprio `webserver.rb`
porque ele já está ali!

```rb
server.mount "/", WEBrick::HTTPServlet::FileHandler, "webserver.rb"
```

E ao acessar o `/`? 404. Hmmm, mas por quê? Bem, será que é porque não está no
diretório correto? E no caso não é nem o `Dir.pwd`, que pega o diretório
corrente, mas sim o do próprio arquivo. Tal qual em C, tem o token que gera
essa informação automaticamente, o `__FILE__`. Para pegar o diretório corrente
é usar `File.dirname`. E para juntar tem o `File.join`. Juntando tudo:

```rb
server.mount "/", WEBrick::HTTPServlet::FileHandler, File.join(File.dirname(__FILE__), "webserver.rb")
```

E ele serviu o arquivo correto! Show! Mas... queremos carregar um HTML, né?
Para isso, vamos agora apontar para a pasta `assets`, ao lado da basta `bin`,
para buscar o `index.html` de lá:

```rb
server.mount "/", WEBrick::HTTPServlet::FileHandler, File.join(File.dirname(__FILE__), "..", "assets", "index.html")
```

Até agora tem funcionado!

Próximo teste... será que montar outro path funciona? Vou montar após definir o
`/` com uma função simples:

```rb
server.mount "/", WEBrick::HTTPServlet::FileHandler, File.join(File.dirname(__FILE__), "..", "assets", "index.html")

server.mount_proc "/ola" do |req, res|
    res.content_type = "text/plain"
    res.body = "hello world"
end
```

E o `/ola` funcionou perfeitamente! E o melhor: o `/` que servia antes continua
servindo tal qual servia antes!

Ok, com esse end-point de teste implementado com sucesso, vamos fazer o
`/list`? Basicamente ele vai ter a mesma função de selecionar algo que o combo
box da
[Publicando coisas da Computaria no Bluesky]({% post_url 2025/2025-01-14-publicar-bsky %}).
E vamos povoar com HTMX mesmo.

No HTML eu tenho

```html
<select name="selectedFile" hx-get="/list" hx-swap="innerHTML" hx-trigger="load" id="dirs" hx-target="#dirs"></select>
```

Já no lado do `/list`, eu pego uma lista de strings (retornada por
`Zippy.list_dir`) e envelopo em tags `<option>`:

```rb
Zippy.list_dir.each do |d|
    """
        <option value='#{d}'>#{d}</option>
    """
end
```

Agora, para permitir povoar, digamos, "sob demanda", eu posso passar uma função
para o `body` da `response` do WEBrick (e pela doc é bom colocar
`res.chunked = true`):

```rb
server.mount_proc "/list" do |req, res|
    res.chunked = true
    res.body = proc { |out|
        out.write """
                <option disabled selected>Selecione uma opção</option>
            """
        Zippy.list_dir.each do |d|
            out.write """
                <option value='#{d}'>#{d}</option>
            """
        end
    }
end
```

Ok, agora precisamos fortalecer a questão de como vai ser a interação do HTML e
o end-point de download. Vou fazer a tela primeiro, mas pra isso vou fazer um
dummy pro `/download`. Colocar ele pra servir um servlet de exemplo, que vai
reagir ao receber um `POST`:

```rb
module ServZippy
    class ZippyDownloader < WEBrick::HTTPServlet::AbstractServlet
        def do_POST req, res
            res.body = "oi oi oi"
        end
    end
end

# ...

server.mount "/download", ServZippy::ZippyDownloader
```

Isso deve ser o suficiente para começar. Vamos pegar o que tenho do HTML, que
não tinha deixado explícito antes:

```html
<html>
    <head>
        <script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0/dist/htmx.min.js"></script>
    </head>
    <body>
        <h1>Baixar as coisas</h1>
        <select name="selectedFile" hx-get="/list" hx-swap="innerHTML" hx-trigger="load" id="dirs" hx-target="#dirs"></select>
    </body>
</html>
```

Pronto. Como vai ser um `POST`, quero enviar as coisas via um `<form>`. E
preparar um botão de submit pra isso também:

```html
<html>
    <head>
        <script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0/dist/htmx.min.js"></script>
    </head>
    <body>
        <h1>Baixar as coisas</h1>
        <form hx-post="/download">
            <select name="selectedFile" hx-get="/list" hx-swap="innerHTML" hx-trigger="load" id="dirs" hx-target="#dirs"></select>
            <button type="submit" >Fazer download</button>
        </form>
    </body>
</html>
```

Vamos abrir a tela e...

```none
http://localhost:2997/? -> /list?selectedFile=
```

Ué? O WEBrick tá dizendo que eu fiz um `GET` no end-point `/list` passando como
query param `selectedFile` vazio? Hmmm, vejamos...

No HTMX, as coisas são colocadas de modo hierárquico. Logo, ao colocar o
`hx-get` dentro do `<form>` aconteceu que ele pegou os valores do formulário
para passar pra baixo? Será que foi isso?

Bem, eu posso colocar dentro do `<body>` a questão para carregar os valores da
combo box assim que carrega a página. Vamos adaptar?

```html
<html>
    <head>
        <script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0/dist/htmx.min.js"></script>
    </head>
    <body hx-get="/list" hx-swap="innerHTML" hx-trigger="load" hx-target="#dirs">
        <h1>Baixar as coisas</h1>
        <form hx-post="/download">
            <select name="selectedFile" id="dirs"></select>
            <button type="submit" >Fazer download</button>
        </form>
    </body>
</html>
```

E é isso, deu certo:

```none
http://localhost:2997/ -> /list
```

Ok, e para iniciar download? Nesse momento, clicar no link renderiza o
`oi oi oi` dentro do `form`. Ficou assim ao inspecionar:

```html
<html><head>
        <script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0/dist/htmx.min.js"></script>
    </head>
    <body hx-get="/list" hx-swap="innerHTML" hx-trigger="load" hx-target="#dirs" data-htmx-powered="true">
        <h1>Baixar as coisas</h1>
        <form hx-post="/download" data-htmx-powered="true">oi oi oi</form>
    
</body></html>
```

Hmmm, precisamos então de algo a mais pro HTMX entender que quero baixar o
arquivo, e não renderizar o texto na tela...

Pesquisando sobre isso me deparo com
[`hx-download`](https://four.htmx.org/extensions/hx-download), uma extensão do
HTMX que permite fazer isso! Só adicionar ela ao HTML e dizer que o swap do
HTMX é `download` e pronto:

```html
<html>
    <head>
        <script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0/dist/htmx.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0/dist/ext/hx-download.js"></script>
    </head>
    <body hx-get="/list" hx-swap="innerHTML" hx-trigger="load" hx-target="#dirs">
        <h1>Baixar as coisas</h1>
        <form hx-post="/download" hx-swap="download">
            <select name="selectedFile" id="dirs"></select>
            <button type="submit" >Fazer download</button>
        </form>
    </body>
</html>
```

Ok, agora tudo funciona perfeitamnte! Aliás, quase... o nome do download tá
ficando com o nome do path da URL, e isso não é ótimo. Não quero que fique
`download`. Bem, na documentação ele menciona algo legal que podemos usar o
header HTTP `Content-Disposition: attachment`, e esse header eu posso indicar o
nome do arquivo: `Content-Disposition: attachment; filename="oi.txt"`. O
servlet fica

```rb
module ServZippy
    class ZippyDownloader < WEBrick::HTTPServlet::AbstractServlet
        def do_POST req, res
            res.header['Content-Disposition'] = "attachment; filename=\"oi.txt\""
            res.body = "oi oi oi"
        end
    end
end
```

e... show! Deu certo com o nome adequado pro download! Agora, nesse mesmo lugar
da doc fala que nem precisa alterar o `hx-swap`! Que a extensão detecta
automaticamente que é um download dada a presença do header. Bora testar?

```html
<html>
    <head>
        <script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0/dist/htmx.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0/dist/ext/hx-download.js"></script>
    </head>
    <body hx-get="/list" hx-swap="innerHTML" hx-trigger="load" hx-target="#dirs">
        <h1>Baixar as coisas</h1>
        <form hx-post="/download">
            <select name="selectedFile" id="dirs"></select>
            <button type="submit" >Fazer download</button>
        </form>
    </body>
</html>
```

E pronto, magia realizada! Agora... vamos focar no servlet agora! Podemos
começar tanto pela questão de fazer o download de um zip como de ler o
formulário recebido...

E, bem, vamos de formulário. Após quebrar um pouco a cabeça pensando que estava
recebendo as coisas como se fosse um `form-data` (`multipart/form-data`), mas
quando fui olhar o `req.body` percebi que aquilo na verdade era o formulário no
formato url encoded! (`applicaiton/x-www-form-urlencoded`)

Quando trilhei os caminhos corretos, percebi que para entender o que foi
fornecido era só pedir por um
[`WEBrick::HTTPUtils.parse_query`](https://ruby-doc.org/stdlib-2.6.3/libdoc/webrick/rdoc/WEBrick/HTTPUtils.html#parse_query-method)
e depois lidar como se fosse um mapa (ou `Hash`, na nomenclatura Ruby):

```rb
module ServZippy
    class ZippyDownloader < WEBrick::HTTPServlet::AbstractServlet
        def do_POST req, res
            form_data = WEBrick::HTTPUtils.parse_query req.body
            selected_file = form_data["selectedFile"]
            puts selected_file

            res.header['Content-Disposition'] = "attachment; filename=\"oi.txt\""
            res.body = "oi oi oi"
        end
    end
end
```

E isso dava o entendimento perfeito de qual era o arquivo. Como pretendo baixar
a partir da minha `HOME`, posso simplesmente concatenar com a variável de
ambiente para obter o valor correto:

```rb
puts File.join(ENV["HOME"], selected_file)
```

E é isso. Mudar o nome do attachment para `"#{selected_file}.zip"` e é isso.
Ou... será que podemos fazer algo melhor? Eu marquei alguns arquivos para
baixar, então eu posso marcar diretamente esse arquivo para baixar! Sem colocar
ele num `zip` nem nada! Ah, aproveitar tb e falhar caso não existe o arquivo...
vai que, né?

```rb
module ServZippy
    class ZippyDownloader < WEBrick::HTTPServlet::AbstractServlet
        def do_POST req, res
            form_data = WEBrick::HTTPUtils.parse_query req.body
            selected_file = form_data["selectedFile"]

            if selected_file.nil?
                res.status = 404
                return
            end

            selected_file_abs = File.join(ENV["HOME"], selected_file)

            res.chunked = true
            if File.file? selected_file_abs
                res.header['Content-Disposition'] = "attachment; filename=\"#{selected_file}\""
                res.body = File.open(selected_file_abs, "r")
            elsif File.directory? selected_file_abs
                res.chunked = true
                res.header['Content-Disposition'] = "attachment; filename=\"#{selected_file}.zip\""
                res.body = "oi oi oi"
            else
                res.status = 404
            end
        end
    end
end
```

Pronto, agora só colocar a streaming no download, né? Bora testar? Vou só mudar
aqui a parte dentro do `elsif`

```rb
res.chunked = true
res.header['Content-Disposition'] = "attachment; filename=\"#{selected_file}.zip\""
res.body = proc { |out| Zippy::zip_stream(selected_file_abs, out) }
``` 

E... oops?

```none
[2026-10-08 13:57:04] ERROR NoMethodError: undefined method 'reopen' for an instance of WEBrick::HTTPResponse::ChunkedWrapper
        ~/.asdf/installs/ruby/4.0.1/lib/ruby/gems/4.0.0/gems/rubyzip-3.7.0/lib/zip/output_stream.rb:37:in 'Zip::OutputStream#initialize'
```

Ok, e se eu definir que o retorno vai ser aquilo criado em `create_zip_stream`?

```rb
res.chunked = true
res.header['Content-Disposition'] = "attachment; filename=\"#{selected_file}.zip\""
res.body = Zippy::create_zip_stream(selected_file_abs)
``` 

E pronto, é isso!

# Notas sobre a criação do projeto e considerações finais

Diferentemente do
[post sobre criar uma Gem]({% post_url 2022/2022-09-13-criando-gem %}), resolvi
ir aqui pelo caminho mais tradicional usando o `bundle`, tanto para criar o
projeto como para lidar com as dependências dele.

Então comecei com `bundle init` e usei ele ele para adicionar as dependências
necessárias para rodar:

```bash
bundle add rubyzip
bundle add webrick
```

O `Gemfile` ficou assim:

```gemfile
# frozen_string_literal: true

source "https://rubygems.org"

# gem "rails"

gem "webrick", "~> 1.9"

gem "rubyzip", "~> 3.7"
```

O `Gemfile.lock` não tem nada de especial. A estrutura final ficou desse jeito:

```tree
.
├── assets
│   └── index.html
├── bin
│   └── webserver.rb
├── Gemfile
├── Gemfile.lock
└── lib
    ├── zippy
    │   ├── descent.rb
    │   ├── listing.rb
    │   └── zipdir.rb
    └── zippy.rb
```

A estrutura final do `bin/webserver.rb` ficou assim:

```rb
require_relative "../lib/zippy"
require "webrick"


module ServZippy
    class ZippyDownloader < WEBrick::HTTPServlet::AbstractServlet
        def do_POST req, res
            form_data = WEBrick::HTTPUtils.parse_query req.body
            selected_file = form_data["selectedFile"]
            puts selected_file

            if selected_file.nil?
                res.status = 404
                return
            end

            selected_file_abs = File.join(ENV["HOME"], selected_file)

            res.chunked = true
            if File.file? selected_file_abs
                res.header['Content-Disposition'] = "attachment; filename=\"#{selected_file}\""
                res.body = File.open(selected_file_abs, "r")
            elsif File.directory? selected_file_abs
                res.chunked = true
                res.header['Content-Disposition'] = "attachment; filename=\"#{selected_file}.zip\""
                res.body = Zippy::create_zip_stream(selected_file_abs)
            end
        end
    end
end

server = WEBrick::HTTPServer.new :Port => 2997
server.mount "/", WEBrick::HTTPServlet::FileHandler, File.join(File.dirname(__FILE__), "..", "assets", "index.html")
server.mount "/download", ServZippy::ZippyDownloader

server.mount_proc "/list" do |req, res|
    res.chunked = true
    res.body = proc { |out|
        out.write """
                <option disabled selected>Selecione uma opção</option>
            """
        Zippy.list_dir.each do |d|
            out.write """
                <option value='#{d}'>#{d}</option>
            """
        end
    }
end

trap "INT" do
    server.shutdown
end

server.start
```

A descida recursiva pelo diretório ficou em `lib/zippy/descent.rb`:

```rb
module Zippy
  def self.recursivo_visitante(dir, &block)
    Dir["#{dir}/*", "#{dir}/.*"].reject do |f|
      f_limpo = f[dir.length + 1..]
      f_limpo == "." || f_limpo == ".DS_Store"
    end.each do |f|
      if File.file? f
        yield f
      elsif File.directory? f
         recursivo_visitante(f, &block)
      end
    end
  end
end
```

E a criação da stream de zip ficou em `lib/zippy/zipdir.rb`:

```rb
require  "zip"
require_relative "./descent"

module Zippy
  def self.create_zip_stream(dir)
    out = Zip::OutputStream.write_buffer do |out|
      recursivo_visitante(dir) do |f|
        f_limpo = f[dir.length+1..]

        out.put_next_entry f_limpo
        File.open(f) do |ff|
          IO.copy_stream ff, out
        end
      end
    end

    out.rewind
    out
  end
  def self.zip_stream(dir, stream)
    Zip::OutputStream.write_buffer(stream) do |out|
      recursivo_visitante(dir) do |f|
        f_limpo = f[dir.length+1..]

        out.put_next_entry f_limpo
        File.open(f) do |ff|
          IO.copy_stream ff, out
        end
      end
    end
  end
end
```

Em finalmente, o HTML para lidar com a UI ficou asism:

```html
<html>
    <head>
        <script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0/dist/htmx.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0/dist/ext/hx-download.js"></script>
    </head>
    <body hx-get="/list" hx-swap="innerHTML" hx-trigger="load" hx-target="#dirs">
        <h1>Baixar as coisas</h1>
        <form hx-post="/download">
            <select name="selectedFile" id="dirs"></select>
            <button type="submit" >Fazer download</button>
        </form>
    </body>
</html>
```

Claro, eu poderia ter feito renderização no lado do server, mas devo admitir
aqui que era mais prático delegar para a tela do que lidar com template engine
do lado do server.

Isso causa uma chamada adicional de HTTP? Causa... mas como é para uso local,
não me importei.

Esse projeto foi feito para rodar dentro de uma rede interna, nada em rede
pública. Note que ele não tem o mínimo de segurança. E isso não era o que eu
queria exercitar neste post, é uma preocupação ortogonal.

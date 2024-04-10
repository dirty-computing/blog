---
layout: post
title: "Pequenas melhorias no Computaria"
author: "Jefferson Quesado"
tags: meta frontend redirect seo rakefile ruby rakefile liquid gitlab-pages
base-assets: "/assets/little-improves/"
---

Pequenas melhorias para o Computaria.

# Redirect

O primeiro ponto foi o redirect ao entrarem em [https://computaria.gitlab.io](https://computaria.gitlab.io).
Originalmente, ao entrar nessa URL, a pessoa recebia um 404 padrão do GitLab. Por exemplo:

![gitlab 404 padrão]({{ page.base-assets | append: "gitlab404.png" | relative_url }})

Isso facilitaria minha digitação e, também, permitiria um pouco mais de facilidade para as pessoas
que só lembravam que o endereço do blog era "alguma coisa computaria gitlab".

Para tal, precisei criar um repositório para ser a "cara" do grupo no repositório,
que respondesse para a raiz. Segundo a
[documentação do GitLab Pages](https://docs.gitlab.com/ee/user/project/pages/getting_started_part_one.html),
precisaria criar um repositório com o nome `computaria.gitlab.io` dentro do grupo
`computaria`: [https://gitlab.com/computaria/computaria.gitlab.io](https://gitlab.com/computaria/computaria.gitlab.io).

Nele, fui atrás de fazer um [redirect](https://docs.gitlab.com/ee/user/project/pages/redirects.html).
De lá tinha as opções de fazer rewrite de URL, onde pela documentação
retornaria um HTML com o redirect dentro dele, ou um 301, que retornaria
no header mesmo o status 301 para redirecionar:

```
/ /blog/ 301
/favicon.ico /blog/favicon.ico 301
```

Redirecionado para a raiz (e apenas a raiz) para a raiz do blog. Também redirecionado
o `favicon.ico` para o do blog.

Esse arquivo precisa necessariamente se chamar `_redirects`. A priori, tudo o que está na pasta
`/public` dentro da raiz do projeto é o que será usado pelo GitLab Pages. Mesmo sendo configurável,
resolvi simplesmente seguir o padrão por simplicidade.

Simplesmente botar a pasta `/public` não foi o suficiente para o GitLab entender que eu queria
publicar como uma GitLab Pages, ele exigia rodar algo no CI. Então, atendendo às demandas
do GitLab Pages, criei um script que simplesmente soltava uma mensagem e guardava a pasta
`/public`:

```yml
image: ruby:3.0-alpine

pages:
  stage: deploy
  script:
    - echo "Só queria deployar redicets..."
  artifacts:
    paths:
    - public
  only:
  - main
```

# `favicon.ico`

Uma coisa que incomodava bastante era que o `faicon.ico` o browser sempre
reclamava na aba de "networks" do developer console. Então, chegou a hora de por o
ícone. Temporariamente escolhi o café do [Pix me a coffee](https://www.pixme.bio/),
a versão usada no [Editando SVG na mão para pedir café]({% post_url 2024-03-16-edita-svg-manualmente %}).

A primeira tentativa foi literalemnte por na pasta `/public` o ícone. A primeira tentativa
foi usando o SVG diretamente. Ao pedir o reload do browser na minha lembrança funcionou,
carregou o ícone na rede. Mas ao parar e subir de novo o blog o ícone, assim como toda a
pasta `/public`, deixava de existir. Então deixei na
[raiz do repositório]({{ site.repository.tree_root }}):
[`/favicon.ico`]({{ site.repository.blob_root }}/favicon.ico).

Inicialmente minha tentativa foi de usar o SVG de 16x16. Não funcionou. Não apareceu
na aba do Firefox o café. Então, usei o [SVG to PNG](https://svgtopng.com/pt/)
para transformar em um pequeno ícone. E tudo funcionou adequadamente.

# Carga inicial do coelho

Ao aceitar o PR do Kauê com o post dele sobre
[Colocando coelhinhos no Computaria e enlouquecendo]({% post_url 2024-04-06-colocando-coelhinhos-no-computaria %}),
percebi que o tempo de carga do coelho ao lado do título estava demorando mais do que o
usual. Primeira hipótese é que o próprio coelho fosse muito pesado.

Então, confirmei o tamanho do coelho: mais de 2MB. Isso causa mesmo um
impacto considerável ainda mais considerando que é um elemento que fica
prontamente visível ao carregar a página. Então fiz um downsize para
ocupar apenas 80 pixels de largura/altura usando o [resize png](https://onlinepngtools.com/resize-png)
do "Online PNG tools". O tamanho caiu para 4KB, muito mais suave.
Também aproveitei para colocar no diretório "global":

- originalmente [`/assets/colocando-coelhinhos-no-computaria/coelho.png`]({{ site.repository.blob_root }}//assets/colocando-coelhinhos-no-computaria/coelho.png)
- após alterações [`/assets/coelho.png`]({{ site.repository.blob_root }}/assets/coelho.png)

# `.env` para devs

Com o surgimento de um guest writer e a ideia de facilitar outros, resolvi criar um `.env`
que guarda as variáveis de opções de desenvolvimento. Já que agora não teríamos apenas
criação de blog posts sob o meu nome, por que não facilitar?

Fui atrás da `gem` para fazer isso: [`dotenv`](https://rubygems.org/gems/dotenv/).
Adicionei no `gemspec` no gripo de `development`:

```ruby
group :development do
    gem 'dotenv', '~> 3.1'
end
```

E, no Rakefile, onde era conveniente (task `_drafts/%.md`):

```ruby
require 'dotenv/load'

author = ENV["COMPUTARIA_AUTHOR"]
author = "Jefferson Quesado" if author.nil?
pixme = ENV["COMPUTARIA_PIXME"]

#...

template =  "layout: post
title: \"#{title}\"
author: \"#{author}\"
tags: #{tags}
base-assets: \"/assets/#{radix}/\"
"
File.open fileName, mode = 'w' do |file|
    file.write "---\n"
    file.write template
    file.write "pixmecoffe: #{pixme}\n" unless pixme.nil?
    file.write "---\n"
end
```

Agora parametrizado! A ausência de um `pixme` vai manter o comportamento atual.

## Criando o `.env` via Rakefile

Bem, de que adianta um `.env` se eu não disponibilizo de um mecanismo fácil de criação
para ele, não é mesmo?

> Obviamente que, como `.env` contém dados específicos para o ambiente
> local do desenvolvedor, ele não pode ser registrado no sistema de
> versão. Isso significa que ele precisa estar dentro do
[`.gitignore`]({{ site.repository.blob_root }}/.gitignore).

Pois adicionemos o novo target `file '.env'`, que depende do `.env.example`.
Não vou fazer nada de outro mundo, apenas ler linha a linha o conteúdo do
`.env.example` e perguntar qual o conteúdo associado. O valor padrão será
o associado à variável de ambiente correspondente. Ausência de valor total
não vou escrever no `.env`.

Para ler um arquivo em sua totalidade podemos usar `File.readlines 'nome/do/arquivo'`,
que retorna um array de string com todas as strings lidas. No caso, o formato de um
arquivo `.env.example` é: `NOME_VAR=\n`, com a quebra de linha. Ou seja,
para pegar apenas o nome da variável, eu preciso remover os últimos dois caracteres
da string. O Ruby permite passar para um array (ou, no caso, uma string) um
_range_. E permite range com valores negativos. Por exemplo:

```ruby
puts("marmota"[..-2]) # imprime 'marmot'
puts("marmota"[...-2]) # imprime 'marmo'
```

O _range_ com `ini..fim` é fechado no fim. Ou seja, se fim é `-2`, ele vai incluir
o penúltimo caracter. Como a intenção é remover o penúltimo caracter, optei por usar
o _range_ aberto, `ini...fim`.

Então, seguimos usando o pacote `cli-ui` para fazer a pergunta. Ele permite passar
um parâmetro nomeado com o valor default:

> Na primeira e na terceira interação abaixo, apenas digitei `enter` e deixei vazia a linha.

```ruby
irb(main):004:0> CLI::UI::Prompt.ask("Oi?", default: "Turo pão?")
? Oi? (empty = Turo pão?)
>   Turo pão?                                                                                            
=> "Turo pão?"                                                                                           
irb(main):005:0> CLI::UI::Prompt.ask("Oi?", default: "Turo pão?")
? Oi? (empty = Turo pão?)
> oi!                                                                                                    
=> "oi!"
irb(main):006:0> CLI::UI::Prompt.ask("Oi?")
? Oi?
>                                                                                          
=> ""
```

Note que, na ausência de entrada e de um valor default,
é retornada uma string vazia, jamais `nil`.

Para escrever em um arquivo existe a alternativa auto-fechável, em que
se escreve no arquivo dentro de um bloco que recebe o objeto de arquivo
como argumento, ou criando o objeto de arquivo e se preocupando em fechar
manualmente quando terminar o uso. Particularmente, como o uso é todo
local, me parece mais razoável seguir a estratégia do bloco.

Daí, dentro do bloco, faço as perguntas referentes as variáveis do
`.env.example` e escrevo no arquivo destino:

```ruby
file '.env' => '.env.example' do |t|
    linhasEnv = File.readlines '.env.example'
    require "cli/ui"
    
    File.open '.env', mode = 'w' do |file|
        linhasEnv.each do |linha|
            envvar = linha[...-2]
            envvalue = title = CLI::UI::Prompt.ask( "Qual o valor para [#{envvar}]?", default: ENV[envvar])
            file.write "#{envvar}=\"#{envvalue}\"\n" unless envvalue.empty?
        end
    end
end
```

## Usando o `page.pixmecoffe`

Criamos a variável para indicar o Pixme a Coffe, mas não a usamos ainda.

```diff
-        <a href='https://www.pixme.bio/jeffquesado' target="_blank">
+        <a href='https://www.pixme.bio/{% if page.pixmecoffe %}{{ page.pixmecoffe }}{% else %}jeffquesado{% endif %}' target="_blank">
```

O foco é usar se tiver, e caso contrário manter o padrão (assim evitamos ter de
alterar o frontmatter dos artigos anteriores). Então, caso a variável tenha valor, usemo-la.
Caso contrário, fiquemos com `jeffquesado`. Liquid permite bloco `if - else - endif`.

## Melhorias no `README` e no `Rakefile`

O [`README`]({{ site.repository.blob_root }}/README.md) original do repositório era um placeholder
para guiar quem estava criando o blog pelo GitLab. Agora que ele está criado, ele é desnecessário.
Foi mantido, entretanto, as badges do começo. O `README` agora foi reescrito de modo a tentar
ajudar na criação de novos artigos.

Foram adicionadas descrições nas tasks do Rakefile:

```bash
› rake -T                                                   
rake .env     # Guia o usuário na criação do arquivo com as variáveis de ambiente para ter opções padrões ao criar novos artigos
rake publish  # Publica um rascunho, perguntando ao usuário qual rascunho publicar
rake run      # Inicia o blog em modo de desenvolvimento na porta 4000, depois é só abrir http://localhost:4000/blog/
```

Colocar o `desc` antes da `task` cria essa documentação automaticamente:

```ruby
desc "Publica um rascunho, perguntando ao usuário qual rascunho publicar"
task :publish do |t|
```

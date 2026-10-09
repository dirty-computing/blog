---
layout: post
title: "Extendendo o syntax highlighter Rouge para uma nova linguagem!"
author: "Jefferson Quesado"
tags: ruby meta jekyll github-pages markdown
base-assets: "/assets/rouge-lexer/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Estava eu feliz escrevendo o
[post de programação linear]({% post_url 2026/2026-10-01-city-bloxx-opt %})
e descobri que não tinha syntax-highlighter padrão para a linguagem GMPL!
Então, o que eu fiz? Fui atrás de fazer o meu!

# Achando o syntax-highlighter

Vamos começar pelo básico. Eu uso o Jekyll. Tem algumas customizações? Tem, mas
a maioria das coisas são de fábrica. É tanto que o único plugin externo que eu
coloquei foi o `jekyll-katex` da época da 
[criação do blog]({% post_url 2021/2021-08-30-criando-blog-jekyll %}).

Depois disso, adicionei algumas funcionalidades extras através de plugins
internos, como o normalizador de tags
[`normalize_tags`]({% post_url 2025/2025-01-17-tags-alias %}).

Dito isso, e vendo que não achei um caminho direto para o syntax highlighter,
fui olhar o padrão que o Jekyll usa para Markdown. E temos resposta para isso
[em doc oficial](https://jekyllrb.com/docs/configuration/markdown/). E essa doc
mostra como personalizar o `kramdown`, que é o processador padrão de markdown
do Jekyll. Ainda não fala quem é que faz o syntax highlighting, mas ao menos já
restringe bastante as opções! E também significa que **não** é o CodeRay!

Olhando pra documentação do `kramdown`, mexendo aqui e ali finalmente paramos
na parte da
[documentação sobre syntax highlighter](https://kramdown.gettalong.org/syntax_highlighter/rouge.html).
Finalmente nossa busca está chegado ao fim! E aqui descobri que é a gem chamada
de [`rouge`](https://rouge.jneen.ca/).

Originalmente ela era hospedada no
[GitHub](https://github.com/rouge-ruby/rouge), mas recentemente o código foi
totalmente migrado para [Codeberg](https://codeberg.org/rouge-ruby/rouge).

Bem, agora sabemos qual o syntax-highlighter que se usa.

# Antes da primeira escrita

O primeiro experimento foi simplesmente fazer uma leitura do Lexer de
[Brainfuck](https://codeberg.org/rouge-ruby/rouge/src/branch/main/lib/rouge/lexers/brainfuck.rb).
Em cima dele, algumas coisas se destacam:

- é um lexer baseado em regex (herda diretamente `Brainfuck < RegexLexer`)
- tem diversos estados
- cada estado permite uma interpretação específica

Um cuidado para se tomar é que, como a ideia é um syntax highlighter e não um
validador do programa, eu posso passar um simples _trecho_ e o syntax
highlighter precisa aceitar. Por exemplo:

```gmpl
s.t. azul11 <= 1;
subject to c_azules:   azul11 +   azul12 - azul >=  0;
```

Independente de que eu preciso primeiro passar pelo trecho de declaração de
variáveis.

Outra coisa relacionada a estados, que vou precisar tomar cuidado quando
estiver lidando com [Kof](https://koflang.github.io/): abrir aspas eu passo a
estar no estado de string, então não devo considerar que `"class Abc"` vá fazer
destaque sintático porque `class` é uma palavra-chave da linguagem. Afinal,
estarei dentro do estado de string, preciso levar em consideração tudo nas
aspas como se fosse uma string.

Além disso, percebi que `tag` vai criar a tag que identifica no bloco sintático
que faz o highlight. Por exemplo:

`````md
```brainfuck
+++++[-]
```
`````

Além da tag, também tem o `aliases` que permite que eu faça com o bloco `bf`:

`````md
```bf
+++++[-]
```
`````

Existe também o estado inicial via `start`.

Olhando a hierarquia, encontrei em
[`Rouge::Lexer`](https://codeberg.org/rouge-ruby/rouge/src/branch/main/lib/rouge/lexer.rb)
o método `register`, porém não distingui como que ele era de fato chamado na
hierarquia de carregamento das classes. Fica no automágico.

## Curiosidade sobre fenced blocks

Eu precisei escrever o como se faz um fenced block para o exemplo do Brainfuck,
né? Para isso, precisei deixar visível o triplo backtick. A questão é, como que
faz isso?

No padrão, o markdown (e nisso o kramdown segue) que usamos no dia-a-dia
permite que eu defina o como vou começar o trecho de bloco de código. Só tem
uma limitação: que sejam _pelo menos_ 3 backticks. Ou seja: posso usar mais!

No caso específico dos examples acima, usei blocos com 5 backticks para iniciar
e fechar, usando a linguagem `md` para fazer o destaque sintático correto. Vou
até ilustrar abaixo como que eu fiz (e, por sinal, para poder colocar o exemplo
com 5 backticks estou usando blocos também de `md` com 7 backticks):

```````md
# Tag

`````md
```brainfuck
+++++[-]
```
`````

# Alias

`````md
```bf
+++++[-]
```
`````
```````

Tem alguma convenção seguir números ímpares? Não, nenhuma. Apenas me apetece
visualmente. A diferença de apenas um backtick não me é tão facilmente
perceptível.

# O primeiro lexer

Antes de tentar fazer funcionar para GMPL, defini uma linguagem minha:
`abobora`. Essa linguagem basicamente tem uma única palavra chave, chamada de
`abobora`:

```abobora
abobora
abobra
```

E eis o código para fazer rodar:

```rb
require "rouge"
require "rouge/lexer"

module Rouge
    module Lexers
        class Abobora < RegexLexer
            tag 'abobora'

            start do
                push :root
            end

            state :inline_whitespace do
                rule %r/[ \t\r]+/, Text
                rule %r/\\\n/, Text # line continuation
            end

            state :whitespace do
                rule %r/\n+/m, Text
                mixin :inline_whitespace
            end

            state :root do
                mixin :whitespace
                rule %r/abobora/, Keyword
            end
        end
    end
end
```

Ao subir o blog tem warning sobre redefinição de módulos? Tem...

```log
~/.asdf/installs/ruby/4.0.1/lib/ruby/gems/4.0.0/gems/rouge-4.7.0/lib/rouge/lexer.rb:528: warning: already initialized constant Rouge::Lexers::BASE_DIR
~/.asdf/installs/ruby/4.0.1/lib/ruby/gems/4.0.0/gems/rouge-4.7.0/lib/rouge/lexer.rb:528: warning: previous definition of BASE_DIR was here
```

Mas subiu.

> Ah, por que você está importando o `rouge/lexer`?

Sendo sincero? Só tava tentando fazer funcionar. Meu primeiro teste foi
simplesmente ver se eu encontrava o lexer de `abobora`, então adicionei a busca
pelo lexer no meu plugin:

```rb
require "rouge"
require "rouge/lexer"

module Rouge
    module Lexers
        class Abobora < RegexLexer
            # o resto do lexer...
        end
    end
end

p Rouge::Lexer.find("abobora")
```

E eis que imprime:

```txt
Rouge::Lexers::Abobora
```

O que significa que sim, estamos encontrando o lexer e o `register` funciona
magicamente!

As primeiras tentativas de fazer o lexer funcionar fora do módulo
`Rouge::Lexers` falharam e eu desisti nesse instante... então, vamos para a
implementação?

# Lexer de GMPL

O primeiro lexer de uma lang de verdade que eu fui fazer agora peguei o exemplo
do
[lexer C](https://codeberg.org/rouge-ruby/rouge/src/branch/main/lib/rouge/lexers/c.rb).
Por que o lexer de C? Porque foi o que eu lembrei com menos palavras chaves. E
eis que fiz o seguinte código:

```rb
require "rouge"
require "rouge/lexer"

module Rouge
   module Lexers
        class GMPL < RegexLexer
            # baseado em https://github.com/rouge-ruby/rouge/blob/v4.7.0/lib/rouge/lexers/c.rb

            tag 'gmpl'
            desc 'GNU MathProg Lang'

            ws = %r((?:\s|//.*?\n|/[*].*?[*]/)+)
            id = /[a-zA-Z_][a-zA-Z0-9_]*/

            def self.keywords
                @keywords ||= Set.new %w(
                    "subject to"
                    "subj to"
                    "s.t."
                    var
                    min
                    minimize
                    max
                    maximize
                    end
                    integer
                    solve
                    display
                    printf
                )
            end

            start { push :bol }

            state :expr_bol do
                mixin :inline_whitespace

                rule %r/#if\s0/, Comment, :if_0
                rule %r/#/, Comment::Preproc, :macro

                rule(//) { pop! }
            end
            state :bol do
                rule %r/#{id}:(?!:)/, Name::Label
                mixin :expr_bol
            end


            state :inline_whitespace do
                rule %r/[ \t\r]+/, Text
                rule %r/\\\n/, Text # line continuation
                rule %r(/(\\\n)?[*].*?[*](\\\n)?/)m, Comment::Multiline
            end

            state :whitespace do
                rule %r/\n+/m, Text, :bol
                rule %r(//(\\.|.)*?$), Comment::Single, :bol
                mixin :inline_whitespace
            end

            state :root do
                mixin :whitespace
                rule %r((\d+[.]\d*|[.]?\d+)e[+-]?\d+[lu]*)i, Num::Float
                rule %r/\d+[lu]*/i, Num::Integer
                rule %r([+-/*<>=]), Operator
                rule %r([:;]), Punctuation
                rule %r/subject to/, Keyword
                rule %r/subj to/, Keyword
                keywords id do
                    rule :keywords, Keyword
                    default Name
                end
            end
        end
   end
end
```

E... isso quebrou imediatamente. A versão do `rouge` que estava sendo usada era
a `4.7.0`, e eu peguei o exemplo do C na versão `5.1.0`, que adicionava a API
`keywords`. Então eu voltei no tempo e peguei da tag `4.7.0`:


```rb
require "rouge"
require "rouge/lexer"

module Rouge
   module Lexers
        class GMPL < RegexLexer
            # baseado em https://github.com/rouge-ruby/rouge/blob/v4.7.0/lib/rouge/lexers/c.rb

            tag 'gmpl'
            desc 'GNU MathProg Lang'

            ws = %r((?:\s|//.*?\n|/[*].*?[*]/)+)
            id = /[a-zA-Z_][a-zA-Z0-9_]*/

            def self.keywords
                @keywords ||= Set.new %w(
                    "subject to"
                    "subj to"
                    "s.t."
                    var
                    min
                    minimize
                    max
                    maximize
                    end
                    integer
                    solve
                    display
                    printf
                )
            end

            start { push :bol }

            state :expr_bol do
                mixin :inline_whitespace

                rule %r/#if\s0/, Comment, :if_0
                rule %r/#/, Comment::Preproc, :macro

                rule(//) { pop! }
            end
            state :bol do
                rule %r/#{id}:(?!:)/, Name::Label
                mixin :expr_bol
            end


            state :inline_whitespace do
                rule %r/[ \t\r]+/, Text
                rule %r/\\\n/, Text # line continuation
                rule %r(/(\\\n)?[*].*?[*](\\\n)?/)m, Comment::Multiline
            end

            state :whitespace do
                rule %r/\n+/m, Text, :bol
                rule %r(//(\\.|.)*?$), Comment::Single, :bol
                mixin :inline_whitespace
            end

            state :root do
                mixin :whitespace
                rule %r((\d+[.]\d*|[.]?\d+)e[+-]?\d+[lu]*)i, Num::Float
                rule %r/\d+[lu]*/i, Num::Integer
                rule %r([+-/*<>=]), Operator
                rule %r([:;]), Punctuation
                rule %r/subject to/, Keyword
                rule %r/subj to/, Keyword
                rule id do |m|
                    name = m[0]
                    if self.class.keywords.include? name
                        token Keyword
                    else
                        token Name
                    end
                end
            end
        end
   end
end
```

E pronto, funcionou!

## Ajustes

Bem, após bater cabeça contra o lexer... achei mais recursos sobre o assunto.
Entre eles:

- [Rouge Wiki: adding a new lexer](https://codeberg.org/rouge-ruby/rouge/wiki/Adding-a-new-lexer)
- [Lexer development](https://rouge-ruby.github.io/docs/file.LexerDevelopment.html)


Mas principalmente, esse achei esse aqui:
[rouge-plugin-example](https://codeberg.org/rouge-ruby/rouge-plugin-example).

Em cima disso percebi que estava cometendo alguns erros. Um deles era
requisitar `rouge/lexer` no lugar de importar apenas o `rouge` e deixar a gem
se resolver.

Outro ponto, que inclusive eu desconhecia completamente, é que eu posso fazer
o `require` condicionado em não existir um módulo:

```rb
require "rouge" unless defined?(Rouge)
```

E, finalmente, necessitar usar o módulo `Rouge::Lexers` era decorrente da minha
bagunça ao fazer os `require`. Usando o padrão do exemplo de
[plugin para Magritte](https://codeberg.org/rouge-ruby/rouge-plugin-example/src/branch/main/lib/rouge-magritte.rb):

```rb
require 'rouge' unless defined?(Rouge)

module RougeMagritte
  class Magritte < Rouge::RegexLexer
    # provide a unique tag, lower case with underscores
    tag 'magritte'

    # ...
  end
end
```

Além disso, ao tentar usar comentários no esquema original, eu percebi que fiz
uma besteira... porque mapeava para um estado que não existia! O comentário em
GMPL é usando `#`, onde o resto da linha se torna um comentário. Mas do jeito
que estava feito entrava em um estado inválido:

```rb
state :expr_bol do
    mixin :inline_whitespace

    rule %r/#if\s0/, Comment, :if_0
    rule %r/#/, Comment::Preproc, :macro

    rule(//) { pop! }
end
```

No estado `:expre_bol`, ao encontrar o `#`, entra no estado `:macro`. Porém,
esse estado jamais foi descrito.

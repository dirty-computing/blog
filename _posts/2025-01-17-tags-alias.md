---
layout: post
title: "Aliases de tags no Computaria"
author: "Jefferson Quesado"
tags: meta jekyll ruby liquid javascript js
base-assets: "/assets/tags-alias/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Agora com o poder de [datafiles]({% post_url 2025-01-13-jekyll-data-files %})
eu posso fazer algo que está me incomodando: dar aliases a tags.

# Por que isso me incomoda?

No meu processo de criação de post, a primeira coisa que eu faço é chamar o
`rake`, como visto em [Rakefile, parte 2 - criando
rascunho]({% post_url 2023-12-30-rakefile-create-draft %}). Nessa parte, eu me
faço algumas perguntas:

- qual o título do post?
- quais as tags?

E por hora são só essas. E nisso de perguntar quais tags as opções são abertas.
Isso permite que eu coloque as tags que eu quiser. E isso é bom, até que
acontecem coisas... assim...

![javacript e js como tags distintas]({{ page.base-assets | append: "javascipt-js.png" | relative_url }})

e assim...

![markdown e md como tags distintas]({{ page.base-assets | append: "markdown-md.png" | relative_url }})

E, bem... essa flexibilidade ao mesmo tempo que é uma coisa boa ao mesmo tempo
me é uma maldição por conta de como a criatividade funciona...

Então, como posso resolver isso? Posso resolver da maneira mais simples, que
seria interceptando no processo de `rake`, mas também posso resolver isso com
um plugin no Jekyll!

# Ideia geral

Existem alguns cantos que uso tags, mas os mais proeminentes são:

- [feed rss]({{ site.repository.blob_root }}/feed.xml)
- [página de tags]({% post_url 2024-06-03-pagina-tags %})

Para o caso do `feed.xml` e outros cantos que itera em cima das tags do post
via liquid, a solução é pra ser via liquid puramente. Algo como

{% raw %}
```liquid
{{ tags | normalize_tags | uniq }}
```
{% endraw %}

onde `normalize_tags` é uma função liquid que eu mesmo irei criar, que usa o
datafile de aliases de tags, e
[`uniq`](https://shopify.github.io/liquid/filters/uniq/) já existe.

Para o caso de código Ruby, a solução vai ser via Ruby mesmo. Além disso, vou
tentar aproveitar e adicionar a lista de aliases na página da tag, só por pura
diversão mesmo.

# Fazendo testes

Bem, vamos fazer testes de adicionar filtros liquid antes de por em para valer
nos lugares que deveriam de fato ser usados. Vamos primeiro definir o conteúdo
do [datafile]({{ site.repository.blob_root }}/_data/tag_alias.yaml)?

Os dados usados no teste são esses, eventualmente eles serão alterados após a
escrita dessa seção do artigo:

```yaml
- tag: javascript
  alias: [ js, javaescripto ]
  description: "gambiarra web"
- tag: typescript
  alias: [ ts ]
  description: "gambiarra web, porém tipada"
- tag: markdown
  alias: [ md ]
  description: "linguagem de marcação mais bonita que html"
```

Dito isso, hora dos testes...

## Acessando os dados para uma tabela simples

Vamos fazer uma escrita simples? No primeiro nível de itemização, a tag em si.
No segundo nível, seus aliases.

{% raw %}
```liquid
{%- for tag_data in site.data.tag_alias %}
- {{ tag_data.tag }}
{% for tag_alias in tag_data.alias %}
  - {{ tag_alias }}
{% endfor %}
{% endfor %}
```
{% endraw %}

E isso renderiza:

```md
- javascript

  - js

  - javaescripto


- typescript

  - ts


- markdown

  - md


```

Que gera isso daqui:

- javascript

  - js

  - javaescripto


- typescript

  - ts


- markdown

  - md


Até aqui.

Hmm, esqueci de controlar os espaços... Depois de um pouco de tentativa e erro
consegui isso:

{% raw %}
```liquid
{%- for tag_data in site.data.tag_alias %}
- {{ tag_data.tag }}
{%- for tag_alias in tag_data.alias %}
  - {{ tag_alias }}{% endfor %}{% endfor %}
```
{% endraw %}

Que renderiza

```md
- javascript
  - js
  - javaescripto
- typescript
  - ts
- markdown
  - md
```

Com resultado final daqui:

- javascript
  - js
  - javaescripto
- typescript
  - ts
- markdown
  - md

Até aqui. Bem mais satisfatório.

## Alterando a lista

Será que eu consigo mapear os elementos da lista? Digamos que eu queira ir
diretamente para as descrições das tags, sem passar pelas tags. Se eu fizer um
{% raw %}`{% assign %}`{% endraw %} eu sei que consigo. E diretamente no
{% raw %}`{% for %}`{% endraw %}?

{% raw %}
```liquid
{% for description in site.data.tag_alias | map: "description" %}
<!-- mensagem de erro:
  Liquid Warning: Liquid syntax error (line 181): Expected end_of_string but found pipe in "description in site.data.tag_alias | map: "description""
  -->
{% for description in site.data.tag_alias map: "description" %}
<!-- mensagem de erro:
  Liquid Warning: Liquid syntax error (line 181): Invalid attribute in for loop. Valid attributes are limit and offset in "description in site.data.tag_alias map: "description""
  -->
```
{% endraw %}

É, não deu. Preciso do passo anterior para fazer
{% raw %}`{% assign %}`{% endraw %}.

{% raw %}
```liquid
{%- assign tag_descriptions = site.data.tag_alias | map: "description" -%}
{%- for description in tag_descriptions %}
- {{ description }}{% endfor %}
```
{% endraw %}

Que gerou:

- gambiarra web
- gambiarra web, porém tipada
- linguagem de marcação mais bonita que html

## Criando uma lista

O modo mais fácil que eu vejo de testar a tag liquid para fazer o processamento
de normalizar as tags das publicações é criar uma variável de vetor e pedir pra
normalizar. Algo que seria mais ou menos assim:

```ts
[ "js", "md", "javaescripto" ]
```

e que depois de fazer o mapeamento ficasse assim:

```ts
[ "javascript", "markdown", "javascript" ]
```

Então, como criar uma variável de array via liquid? A resposta simples: não é
diretamente. O mais fáicl é fazer uma lista DSV e pedir para explodir a lista
em cima do divisor:

{% raw %}
```liquid
{%- assign arr = "js,md,javaescripto" | split: "," -%}
{%- for el in arr %}
- {{ el }}{% endfor %}
```
{% endraw %}

E _voi là_:

- js
- md
- javaescripto

Conforme esperado. Agora, após normalizar, esperaria encontrar algo assim:

- javascript
- markdown
- javascript

Tudo em campo, vamos lá! Estudar como fazer o primeiro filtro em liquid!

A partir desse momento, vou ter uma variável doravante denominada `teste_array`
com o conteúdo acima, já com o valor, pronta para uso.

{% assign teste_array = "js,md,javaescripto" | split: "," %}

Isso significa que não preciso me preocupar com nenhum detalhe sobre instanciar
essa variável novamente, só usar.

## Mais um plugin em liquid?

Sim, mais um plugin em liquid.
[Aqui as docs do Jekyll](https://jekyllrb.com/docs/plugins/filters/). Vamos
explorar?

Basicamente eu declaro um módulo e exporto sua função em
`Liquid::Template.register_filter`. Vamos fazer um teste. Vou aproveitar o [meu
plugin]({% post_url 2024-06-03-pagina-tags %}) e adicionar a função de
normalizar tag. Para o primeiro instante, vou retornar `batata`, a string, só
para confirmar o funcionamento. Ficou assim:

```rb
module Computaria

    # ... coisas sobre paginação e tags ...

    module TagNormalizer
        def normalize_tags(input)
            "batata"
        end
    end
end

Liquid::Template.register_filter(Computaria::TagNormalizer)
```

Bora testar?

{% raw %}
```liquid
{%- assign arr = teste_array | normalize_tags -%}
{%- for el in arr %}
- {{ el }}{% endfor %}
```
{% endraw %}

E com isso obtive....

```md
- batata
```

Por quê? Bem, porque o filter se aplica ao input, e no caso o input era o
array em si, não os elementos do array. Bora corrigir isso então? O chato é que
para testar no Computaria em si vou precisar ficar derrubando e levantando de
novo o servidor. Eu poderia testar de modo mais otimizado? Obviamente. Irei?
Não, vou sofrer mesmo.

A correção seria algo assim:

```rb
module Computaria

    # ... coisas sobre paginação e tags ...

    module TagNormalizer
        def normalize_tags(input)
            input.map do |element|
                "batata"
            end
        end
    end
end

Liquid::Template.register_filter(Computaria::TagNormalizer)
```

Vamos testar?

{% raw %}
```liquid
{%- assign arr = teste_array | normalize_tags -%}
{%- for el in arr %}
- {{ el }}{% endfor %}
```
{% endraw %}

E com isso obtive...

```md
- batata
- batata
- batata
```

## Pegando contexto

Bem, aparentemente a única coisa que o filtro tem acesso é aquilo que é passado
explicitamente para ele. Então vou precisar alterar um pouco a API de uso do
liquid: vou precisar passar os aliases. Mas, como que eu crio um filtro com
parâmetro? Bem, descobri que não vi isso nas documentações consultados...

- [Jekyll](https://jekyllrb.com/docs/plugins/filters/)
- [Liquid for programmers](https://github.com/Shopify/liquid/wiki/Liquid-for-Programmers)

Em compensação, achei no repositório os filtros padrões!

[https://github.com/Shopify/liquid/blob/main/lib/liquid/standardfilters.rb](https://github.com/Shopify/liquid/blob/main/lib/liquid/standardfilters.rb)

E aqui tem um exemplo:

```rb
    def map(input, property)
      InputIterator.new(input, context).map do |e|
        e = e.call if e.is_a?(Proc)

        if property == "to_liquid"
          e
        elsif e.respond_to?(:[])
          r = fetch_property(e, property)
          r.is_a?(Proc) ? r.call : r
        end
      end
    rescue TypeError
      raise_property_error(property)
    end
```

Isso permite que eu passe um parâmetro posicional para o filtro. Vamos testar?

Primeiro por experimento só ver o que acontece sem alterar o código do meu
filtro (não deve ter nenhuma alteração no resultado final se o liquid aceitar
isso):

{% raw %}
```liquid
{%- assign arr = teste_array | normalize_tags "ostra" -%}
{%- for el in arr %}
- {{ el }}{% endfor %}
```
{% endraw %}

Como esperado, o liquid não alterou o resultado, nas mostrou que tem problemas:

{% raw %}
> Liquid Warning: Liquid syntax error (line 387): Expected end_of_string but found string
> in "{{teste_array | normalize_tags "ostra" }}"
{% endraw %}

Ok, hora de permitir passar essa string!

```rb
module Computaria

    # ... coisas sobre paginação e tags ...

    module TagNormalizer
        def normalize_tags(input, renomeio)
            input.map do |element|
                renomeio
            end
        end
    end
end

Liquid::Template.register_filter(Computaria::TagNormalizer)
```

E...

{% raw %}
```none
    Liquid Warning: Liquid syntax error (line 387): Expected end_of_string but found string in "{{teste_array | normalize_tags "ostra" }}" in ~/computaria/blog/_drafts/tags-alias.md
  Liquid Exception: Liquid error (line 387): wrong number of arguments (given 1, expected 2) in ~/computaria/blog/_drafts/tags-alias.md
rake aborted!
Liquid::ArgumentError: Liquid error (line 387): wrong number of arguments (given 1, expected 2) (Liquid::ArgumentError)
~/computaria/blog/_plugins/tags.rb:89:in `normalize_tags'
~/computaria/blog/Rakefile:11:in `block in <top (required)>'

Caused by:
ArgumentError: wrong number of arguments (given 1, expected 2) (ArgumentError)
~/computaria/blog/_plugins/tags.rb:89:in `normalize_tags'
~/computaria/blog/Rakefile:11:in `block in <top (required)>'
Tasks: TOP => default => run
(See full trace by running task with --trace)
```
{% endraw %}

Nem sobe... mas por que será?

Olhando o exemplo do `map`:

{% raw %}
```liquid
{%- assign tag_descriptions = site.data.tag_alias | map: "description" -%}
```
{% endraw %}

Puts, esqueci o `:`! Foi isso? Primeiro vou testar com a versão sem o renomeio,
só pra ver se dá o mesmo erro. Então voltemos o filtro pra versão anterior:

```rb
module Computaria

    # ... coisas sobre paginação e tags ...

    module TagNormalizer
        def normalize_tags(input)
            input.map do |element|
                "batata"
            end
        end
    end
end

Liquid::Template.register_filter(Computaria::TagNormalizer)
```

E o teste:

{% raw %}
```liquid
{%- assign arr = teste_array | normalize_tags: "ostra" -%}
{%- for el in arr %}
- {{ el }}{% endfor %}
```
{% endraw %}

O liquid recusou! Agora não foi warning, foi erro mesmo:

{% raw %}
```none
Liquid Exception: Liquid error (line 454): wrong number of arguments (given 2, expected 1)
```
{% endraw %}

Muito bem, retornando a versão com renomeio e voltamos a testar:

```rb
module Computaria

    # ... coisas sobre paginação e tags ...

    module TagNormalizer
        def normalize_tags(input, renomeio)
            input.map do |element|
                renomeio
            end
        end
    end
end

Liquid::Template.register_filter(Computaria::TagNormalizer)
```


{% raw %}
```liquid
{%- assign arr = teste_array | normalize_tags: "ostra" -%}
{%- for el in arr %}
- {{ el }}{% endfor %}
```
{% endraw %}

Perfeito, renomeou tudo para `ostra` agora!

```md
- ostra
- ostra
- ostra
```

Muito bem, vamos passar o argumento `site.data.tag_alias`... vou voltar a
imprimir `batata`, mas agora vou dar a quantidade de elementos passados no
argumento:

```rb
module Computaria

    # ... coisas sobre paginação e tags ...

    module TagNormalizer
        def normalize_tags(input, tag_alias)
            input.map do |element|
                "batata #{tag_alias.size}"
            end
        end
    end
end

Liquid::Template.register_filter(Computaria::TagNormalizer)
```

E o teste:

{% raw %}
```liquid
{%- assign arr = teste_array | normalize_tags: site.data.tag_alias -%}
{%- for el in arr %}
- {{ el }}{% endfor %}
```
{% endraw %}

Resultado:

- batata 3
- batata 3
- batata 3

Perfeito, está funcionando! Agora vou fazer um mapa reverso (do alias para a
tag principal) e então bater nos itens para ver se aparece alguma coisa
interessante. Se aparecer, usar o que encontrou. Caso contrário, usar o item
literal.

Primeiro, verificar se eu fiz o código correto do mapa reverso:

```ruby
def normalize_tags(input, tag_alias)
    reverse_alias = { }
    for tag in tag_alias do
        for single_alias in tag.alias do
            reverse_alias[single_alias] = tag
        end
    end
    puts reverse_alias
    input.map do |element|
        "batata #{tag_alias.size}"
    end
end
```

O resultado gerado não deve mudar, mas deve imprimir no console só para eu
constatar se tá funcionando ou não...

E, bem, esqueci que mapa não é objeto...

```none
NoMethodError: undefined method `alias' for {"tag"=>"javascript", "alias"=>["js", "javaescripto"], "description"=>"gambiarra web"}:Hash (NoMethodError)

                for single_alias in tag.alias do
                                       ^^^^^^
```

Ok, vamos acessar como um mapa mesmo:

```rb
def normalize_tags(input, tag_alias)
    reverse_alias = { }
    for tag in tag_alias do
        for single_alias in tag["alias"] do
            reverse_alias[single_alias] = tag
        end
    end
    puts reverse_alias
    input.map do |element|
        "batata #{tag_alias.size}"
    end
end
```

E, bem, deu certo?

```rb
{
    "js"=>{"tag"=>"javascript", "alias"=>["js", "javaescripto"], "description"=>"gambiarra web"},
    "javaescripto"=>{"tag"=>"javascript", "alias"=>["js", "javaescripto"], "description"=>"gambiarra web"},
    
    "ts"=>{"tag"=>"typescript", "alias"=>["ts"], "description"=>"gambiarra web, porém tipada"},
    
    "md"=>{"tag"=>"markdown", "alias"=>["md"], "description"=>"linguagem de marcação mais bonita que html"}}
```

Eu posso pegar qualquer informação da tag. Beleza, vamos botar no teste agora.
Se tiver, pega `reverse_alias[el].tag`, caso contrário pega `el`:

```rb
def normalize_tags(input, tag_alias)
    reverse_alias = { }
    for tag in tag_alias do
        for single_alias in tag["alias"] do
            reverse_alias[single_alias] = tag
        end
    end
    input.map do |element|
        unless reverse_alias[element].nil?
            reverse_alias[element]["tag"]
        else
            element
        end
    end
end
```

{% raw %}
```liquid
{%- assign arr = teste_array | normalize_tags: site.data.tag_alias -%}
{%- for el in arr %}
- {{ el }}{% endfor %}
```
{% endraw %}

E o resultado foi:

```md
- javascript
- markdown
- javascript
```

Perfeito! Como eu queria! Mas... e se eu errei na hora de pegar o default?
Vou passar o filtr duas vezes, só pra garantir (com um sort no meio pra ter
certeza que tá duplo filtrando):

{% raw %}
```liquid
{%- assign arr = teste_array | normalize_tags: site.data.tag_alias | sort | normalize_tags: site.data.tag_alias -%}
{%- for el in arr %}
- {{ el }}{% endfor %}
```
{% endraw %}

E como esperado, deu certíssimo:

```md
- javascript
- javascript
- markdown
```

Um reverse antes do segundo filtro por via das dúvidas?

{% raw %}
```liquid
{%- assign arr = teste_array | normalize_tags: site.data.tag_alias | sort | reverse | normalize_tags: site.data.tag_alias -%}
{%- for el in arr %}
- {{ el }}{% endfor %}
```
{% endraw %}

```md
- markdown
- javascript
- javascript
```

Ok, minhas desconfianças são infundadas.

## Pegando realmente contexto

Sabe aquela conversa de que o filtro pega apenas os argumentos? Aparentemente?
Então... eu esqueci de ler algo na documentação do próprio Jekyll...

> ProTip™: Access the site object using Liquid
> 
> Jekyll lets you access the `site` object through the `@context.registers`
> feature of Liquid at `@context.registers[:site]`. For example, you can access
> the global configuration file `_config.yml` using
> `@context.registers[:site].config`

Oops... falha minha... Mas deve facilitar bastante! Minha API deve voltar ao
que era esperado!

```rb
def normalize_tags(input)
    tag_alias = @context.registers[:site].data["tag_alias"]
    reverse_alias = { }
    for tag in tag_alias do
        for single_alias in tag["alias"] do
            reverse_alias[single_alias] = tag
        end
    end
    input.map do |element|
        unless reverse_alias[element].nil?
            reverse_alias[element]["tag"]
        else
            element
        end
    end
end
```

{% raw %}
```liquid
{%- assign arr = teste_array | normalize_tags -%}
{%- for el in arr %}
- {{ el }}{% endfor %}
```
{% endraw %}

Com resultado:

```md
- javascript
- markdown
- javascript
```

Bem, pelo menos o sofrimento anterior serviu para eu aprender a passar
parâmetros posicionais aos filtros.

Antes de sair, deixa só eu deixar seguro caso não tenha os aliases...

```rb
def normalize_tags(input)
    tag_alias = @context.registers[:site].data["tag_alias"]
    return input if tag_alias.nil?
    reverse_alias = { }
    for tag in tag_alias do
        for single_alias in tag["alias"] do
            reverse_alias[single_alias] = tag
        end
    end
    input.map do |element|
        unless reverse_alias[element].nil?
            reverse_alias[element]["tag"]
        else
            element
        end
    end
end
```

## Reverse alias no contexto

Não quero ficar constantemente fazendo o mapeamento reverso dos aliases, até
porque posso esperar executar isso constantemente durante o ciclo de
compilação. Então, já que existe o contexto, por que não usá-lo?

Vou fazer aqui para guardar e já imprimir alguns testes no console:

```rb
module Computaria

    # ... coisas sobre paginação e tags ...

    module TagNormalizer
        def normalize_tags(input)
            reverse_alias = Computaria::reverse_alias_tag @context
            return input if reverse_alias.nil?
            input.map do |element|
                unless reverse_alias[element].nil?
                    reverse_alias[element]["tag"]
                else
                    element
                end
            end
        end
    end

    private

    def self.reverse_alias_tag(context)
        reverse_alias = context.registers[:reverse_alias]
        tag_alias = context.registers[:site].data["tag_alias"]
        return nil if tag_alias.nil?

        unless reverse_alias.nil?
            old_tag_alias = context.registers[:old_tag_alias]

            if old_tag_alias == tag_alias
                puts "old e atual são iguais"
            else
                puts old_tag_alias
                puts tag_alias
            end
            return reverse_alias
        end

        reverse_alias = { }
        for tag in tag_alias do
            for single_alias in tag["alias"] do
                reverse_alias[single_alias] = tag
            end
        end
        puts "computou e guardou"
        context.registers[:reverse_alias] = reverse_alias
        context.registers[:old_tag_alias] = tag_alias
        return reverse_alias
    end
end

# ... registros ...
```

Fiz o seguinte teste:

{% raw %}
```liquid
{%- assign arr = teste_array | normalize_tags -%}
{%- for el in arr %}
- {{ el }}{% endfor %}

{%- assign arr = teste_array | normalize_tags -%}
{%- for el in arr %}
- {{ el }}{% endfor %}

{%- assign arr = teste_array | normalize_tags -%}
{%- for el in arr %}
- {{ el }}{% endfor %}
```
{% endraw %}

```liquid
{%- assign arr = teste_array | normalize_tags -%}
{%- for el in arr %}
- {{ el }}{% endfor %}

{%- assign arr = teste_array | normalize_tags -%}
{%- for el in arr %}
- {{ el }}{% endfor %}

{%- assign arr = teste_array | normalize_tags -%}
{%- for el in arr %}
- {{ el }}{% endfor %}
```

E ele imprimiu:

```none
      Generating... 
computou e guardou
old e atual são iguais
old e atual são iguais
                    done in 2.724 seconds.
```

Ok, sucesso. E incrementalmente, como ele se comporta? Salvar aqui o arquivo do
post e...

```none
                    _drafts/tags-alias.md
computou e guardou
old e atual são iguais
old e atual são iguais
                    ...done in 6.681899 seconds.
```

Ok, ok. E alterações no datafile?

```none
                    _data/tag_alias.yaml
computou e guardou
old e atual são iguais
old e atual são iguais
                    ...done in 2.245662 seconds.
```

Muito bom. Isso para mim significa que o objeto de contexto é efêmero, sendo
criado um novo a cada vez que o Jekyll precisa regerar o blog. Portanto, se eu
já memoizei o meu `reverse_alias`, posso confiar nisso doravante: não será
alterado.

A versão final fica mais assim:

```rb
module Computaria

    # ... coisas sobre paginação e tags ...

    module TagNormalizer
        def normalize_tags(input)
            reverse_alias = Computaria::reverse_alias_tag @context
            return input if reverse_alias.nil?
            input.map do |element|
                unless reverse_alias[element].nil?
                    reverse_alias[element]["tag"]
                else
                    element
                end
            end
        end
    end

    private

    def self.reverse_alias_tag(context)
        reverse_alias = context.registers[:reverse_alias]
        return reverse_alias unless reverse_alias.nil?

        tag_alias = context.registers[:site].data["tag_alias"]
        return nil if tag_alias.nil?

        reverse_alias = { }
        for tag in tag_alias do
            for single_alias in tag["alias"] do
                reverse_alias[single_alias] = tag
            end
        end
        context.registers[:reverse_alias] = reverse_alias
        return reverse_alias
    end
end

# ... registros ...
```

## Alterando o feed

{% raw %}
```diff
+        {% assign tags = post.tags | normalize_tags | uniq %}
-        {% for tag in post.tags %}
+        {% for tag in tags %}
         <category>{{ tag | xml_escape }}</category>
         {% endfor %}
```
{% endraw %}

Só essa mudança e tudo mágico. Para testar, localizei onde ficava este post no
RSS e brinquei com as tags dele. Exemplos de valores que usei:

- `meta jekyll ruby liquid js`
- `meta jekyll ruby liquid js javascript`
- `meta javascript jekyll ruby liquid js`

Tudo funcionou como esperado.

## Alterando a paginação

Hmmm, aqui eu não tenho acesso ao `context` que eu tinha no liquid. Até tentei
procurar alguma maneira de recuperar isso... mas sem sucesso.

O que eu tenho, confirmado? `site.data` funciona igual ao
`context.registers[:site].data` (na real o `context.registers[:site]` é
exatamente `site`, porém armazenado no contexto do liquid). Pelo menos ao rodar
o generator ele só irá executar mais uma vez a reversão de tags, né? Eu até
poderia adicionar no `site.data["reverse_tag"]`... mas não. Vou jogar seguro
por hora.

Extraí a parte que faz o grafo reverso da parte que lida com o contexto:

```rb
def self.reverse_alias_tag(context)
    reverse_alias = context.registers[:reverse_alias]
    return reverse_alias unless reverse_alias.nil?

    tag_alias = context.registers[:site].data["tag_alias"]
    return nil if tag_alias.nil?

    reverse_alias = reverse_alias_tag_pure_data tag_alias

    context.registers[:reverse_alias] = reverse_alias
    return reverse_alias
end

def self.reverse_alias_tag_pure_data(tag_alias)
    return nil if tag_alias.nil?

    reverse_alias = { }
    for tag in tag_alias do
        for single_alias in tag["alias"] do
            reverse_alias[single_alias] = tag
        end
    end
    return reverse_alias
end
```

E agora que vem a parte divertida...

O código original da separação por tags:

```rb
site.tags.each do |tag, posts|
    posts_local = posts.select do |p|
        p.data["draft"] != 'true'
    end
    next if posts_local.empty?
    tagPage = TagPage.new(site, tag, posts_local)
    site.categories["tags"] << tagPage
    site.pages << tagPage
end
```

Mas esse código carrega algumas _hidden assuptions_. Que são BEM RAZOÁVEIS na
verdade.

A primeira é que `posts_local` estará ordenada do mais novo ao mais antigo. E
isso de fato acontece nesse caso.

A segunda é que cada `tag` é única. Porém, ao adicionar aliases, eu posso vir a
ter tags sinânimas repetidas. Ou seja: eu adiciono o mesmo post múltiplas vezes
na tag real, depois de resolver os aliases todos. Fiz um teste adicionando o
post atual com as tags `meta jekyll ruby liquid js javascript`, ele apareceu no
começo da listagem porém também apareceu posteriormente!

Então, como resolver essa bagunça? Fazendo por partes.

Primeiro, vamos separar a questão de aglutinar os posts da tag de gerar o
`TagPage`. Com isso, podemos mexer melhor neles:

```rb
normalized_tags_posts = { }
site.tags.each do |tag, posts|
    posts_local = posts.select do |p|
        p.data["draft"] != 'true'
    end
    next if posts_local.empty?
    normalized_tags_posts[tag] = posts_local
end
normalized_tags_posts.each do |tag, posts_local|
    tagPage = TagPage.new(site, tag, posts_local)
    site.categories["tags"] << tagPage
    site.pages << tagPage
end
```

Ok, com isso, agora eu posso me preocupar com as coisas distintas: separar nos
buckets de tags e de fato gerar as páginas de tags:

```rb
normalized_tags_posts = { }

# buckets
site.tags.each do |tag, posts|
    posts_local = posts.select do |p|
        p.data["draft"] != 'true'
    end
    next if posts_local.empty?
    normalized_tags_posts[tag] = posts_local
end

# gerar TagPage
normalized_tags_posts.each do |tag, posts_local|
    tagPage = TagPage.new(site, tag, posts_local)
    site.categories["tags"] << tagPage
    site.pages << tagPage
end
```

Bem, agora precisamos remover o alias das tags. No momento vamos trabalhar só
com a parte "buckets".

Para começar, preciso ter meu `reverse_alias`:

```rb
reverse_alias = Computaria::reverse_alias_tag_pure_data site.data["tag_alias"]
```

Ótimo! Agora, preciso trabalhar, no bucket, com a versão canônica, sem o alias.
Vou chamar de `unaliased_tag`. Aqui vou só preparando o terreno, ainda sem
maiores resoluções de alias reverso:

```rb
reverse_alias = Computaria::reverse_alias_tag_pure_data site.data["tag_alias"]
site.tags.each do |tag, posts|
    posts_local = posts.select do |p|
        p.data["draft"] != 'true'
    end
    next if posts_local.empty?
    unalised_tag = tag
    normalized_tags_posts[unalised_tag] = posts_local
end
```

Ok, hora do alias reverso. Porém, algumas coisas podem acontecer:

- o `reverse_alias` ser nulo
- o `reverse_alias` não tem referência reversa à tag específica

Então, a não ser que `reverse_alias.nil?` ou que `reverse_alias[tag].nil?`,
e pego o valor de `reverse_alias[tag]`. Caso contrário eu pego simplesmente
`tag`:

```rb
reverse_alias = Computaria::reverse_alias_tag_pure_data site.data["tag_alias"]
site.tags.each do |tag, posts|
    posts_local = posts.select do |p|
        p.data["draft"] != 'true'
    end
    next if posts_local.empty?
    unaliased_tag = unless reverse_alias.nil? or reverse_alias[tag].nil?
        reverse_alias[tag]["tag"]
    else
        tag
    end
    normalized_tags_posts[unalised_tag] = posts_local
end
```

Agora eu preciso concatenar o `posts_local` e associar a
`normalized_tags_posts[unalised_tag]`! Para eu poder fazer isso, primeiramente
preciso garantir a inicialização de `normalized_tags_posts[unalised_tag]`:

```rb
reverse_alias = Computaria::reverse_alias_tag_pure_data site.data["tag_alias"]
site.tags.each do |tag, posts|
    posts_local = posts.select do |p|
        p.data["draft"] != 'true'
    end
    next if posts_local.empty?
    unaliased_tag = unless reverse_alias.nil? or reverse_alias[tag].nil?
        reverse_alias[tag]["tag"]
    else
        tag
    end
    if normalized_tags_posts[unaliased_tag].nil?
        normalized_tags_posts[unaliased_tag] = []
    end
    normalized_tags_posts[unalised_tag] += posts_local
end
```

O oprtador `+=` com arrays fará com que eu tenho agora um array que seja a
concatenação do array anterior com o novo. Mas, eu posso ser melhor do que
isso, não posso? Claro! Se é a primeira vez, e já que o `posts_local` não é
reutilizado adiante, eu posso colocar ele diretamente no mapa. E para os outros
casos? `+=` mesmo.

```rb
reverse_alias = Computaria::reverse_alias_tag_pure_data site.data["tag_alias"]
site.tags.each do |tag, posts|
    posts_local = posts.select do |p|
        p.data["draft"] != 'true'
    end
    next if posts_local.empty?
    unaliased_tag = unless reverse_alias.nil? or reverse_alias[tag].nil?
        reverse_alias[tag]["tag"]
    else
        tag
    end
    if normalized_tags_posts[unaliased_tag].nil?
        normalized_tags_posts[unaliased_tag] = []
    else
        normalized_tags_posts[unalised_tag] += posts_local
    end
end
```

Mas por uma questão de depuração... vou imprimir os posts que advém do alias:

```rb
reverse_alias = Computaria::reverse_alias_tag_pure_data site.data["tag_alias"]
site.tags.each do |tag, posts|
    posts_local = posts.select do |p|
        p.data["draft"] != 'true'
    end
    next if posts_local.empty?
    unaliased_tag = unless reverse_alias.nil? or reverse_alias[tag].nil?
        reverse_alias[tag]["tag"]
    else
        tag
    end
    if normalized_tags_posts[unaliased_tag].nil?
        normalized_tags_posts[unaliased_tag] = []
    else
        for post in posts_local do
            puts "adicionando post #{post.data["title"]} na tag real <#{unaliased_tag}> advindo de <#{tag}>" if unaliased_tag == 'javascript'
        end
        normalized_tags_posts[unalised_tag] += posts_local
    end
end
```

E pronto, estou satisfeito. Agora, vamos garantir a geração correta do
`TagPage`. Começando da base:

```rb
normalized_tags_posts.each do |tag, posts_local|
    tagPage = TagPage.new(site, tag, posts_local)
    site.categories["tags"] << tagPage
    site.pages << tagPage
end
```

A primeira coisa que eu quero é ordenar por data:

```rb
normalized_tags_posts.each do |tag, posts_local|
    tagPage = TagPage.new(site, tag, posts_local.sort_by do |post| post.date end)
    site.categories["tags"] << tagPage
    site.pages << tagPage
end
```

Hmm, tá duplicando alguns resultados (os que forçadamente tem `js` e
`javascript`). Ok, resolve-se isso com `uniq`:

```rb
normalized_tags_posts.each do |tag, posts_local|
    tagPage = TagPage.new(site, tag, posts_local.sort_by do |post| post.date end.uniq)
    site.categories["tags"] << tagPage
    site.pages << tagPage
end
```

E finalmente... está invertida a ordem...

```rb
normalized_tags_posts.each do |tag, posts_local|
    tagPage = TagPage.new(site, tag, posts_local.sort_by do |post| post.date end.uniq.reverse)
    site.categories["tags"] << tagPage
    site.pages << tagPage
end
```

Com isso, tenho o site funcionando com plenitude.

# Notas finais

Por hora, não tenho muito o que eu _desejo_ falar sobre cada tag
individualmente. Então no
[datafile]({{ site.repository.blob_root }}/_data/tag_alias.yaml) não vou
colocar descrição. Por hora, ficou assim:

```yaml
- tag: javascript
  alias: [ js ]
- tag: typescript
  alias: [ ts ]
- tag: markdown
  alias: [ md ]
- tag: bash
  alias: [ shell, shell-script ]
```

Para acompanhar novas mudanças, só acessar o [arquivo no
repositório]({{ site.repository.blob_root }}/_data/tag_alias.yaml).

Também aproveitei e removi o layout hardcoded que estava gerando a página de
tags, e coloquei em um layout apropriado:
[`tags.html`]({{ site.repository.blob_root }}/_layouts/tags.html).

Para isso:

```diff
     class CentralTag < Jekyll::Page
         def initialize(site, tags)
             @site = site           # the current site instance.
             @base = site.source    # path to the source directory.
             @dir  = "tags"         # the directory the page will reside in.

             # All pages have the same filename, so define attributes straight away.
             @basename = 'index'      # filename without the extension.
             @ext      = '.html'      # the extension.
             @name     = 'index.html' # basically @basename + @ext.

             # Initialize data hash with a key pointing to all posts under current category.
             # This allows accessing the list in a template via `page.linked_docs`.
             @data = {
-                "layout" => "default",
+                "layout" => "tags",
                 "sitetags" => tags.sort_by do |element| element.tag.downcase.gsub("á", "a") end,
                 "show" => true,
                 "title" => "Tags"
             }
-
-            @content = "
-<div class='home'>
-
-<h1 class='page-heading'>Posts por tag</h1>
-
-<ul class='post-list'>
-    {% for tag in page.sitetags %}
-        <li>
-            <span class='post-meta'>{{ tag.posts.size }} posts</span>
-            <h2>
-                <a class='post-link' href='{{ tag.url | prepend: site.baseurl }}'>{{ tag.tag }}</a>
-            </h2>
-        </li>
-    {% endfor %}
-</ul>
-</div>
-          
-            "
         end
     end
```

Como o `layout` base era o `default`, mantive isso no frontmatter do
`tags.html`. O conteúdo é idêntico a o que tinha antes, mas agora posso delegar
completamente, não preciso injetar mais nada a nível de ruby. Fica até mais...
idiomático?... o uso da ferramenta assim.

---
layout: post
title: "Oops, quebrei o about, e agora?"
author: "Jefferson Quesado"
tags: scss meta liquid rakefile
base-assets: "/assets/oops-about/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Fui colocar no ar o carregador de pipeline, e acabei fazer algumas
bagunças com o [Sobre]({{ "about" | prepend: site.baseurl }}).
"Quão bagunçado?" você pode se perguntar. Bem, deixe eu mostrar:

![Links que não deveriam existir]({{ page.base-assets | append: "bagunca.png" | relative_url }})

Porém o que eu queria mesmo era algo assim, como estava antes:

![Estado desejado]({{ page.base-assets | append: "desejo.png" | relative_url }})

Bem, com isso, sabe o que consegui? Basicamente tornar tudo feito no
[Criando páginas discretas]({% post_url 2023-08-31-paginas-discretas %})
pouco útil.

A intenção original das "páginas discretas" foi não enfeiar a parte ao redor
do "Sobre". Aproveitei essa ocasião então para deixar esses outros links dento
do hamburguer:

![Hamburguer com as 3 páginas]({{ page.base-assets | append: "hamburguer.png" | relative_url }})

# Ajeitando o Rakefile para gerar pasta de assets

Eu comecei como normalmente começo a escrever artigo:

```bash
rake _drafts/oops-about.md
```

Porém só com um pouquinho do artigo preenchido e eu percebi um erro que eu cometi:
ainda não havia criado a pasta de assets. Então, para minimamente automatizar isso,
resolvi criar minha própria pasta de assets para quando eu precisar. E automatizar
isso.

Então, minha primeira reação foi correr atrás de um padrão de diretório. Porém
as tasks do tipo `directory` só aceitam strings. Para aceitar padrões, preciso
invariavelmente usar `rule`. Então criei a `rule` adequada para refletir o
formato do diretório:

```ruby
rule(/^assets\/[^\/]+\/?$/) do |t|
    puts "criando diretório de assets #{t.name}"
    mkdir t.name
end
```

Aparentemente, tudo bem, com isso o diretório passou a ser criado. Mas e para
chamar a task dentro da outra? Achei
[essa resposta](https://stackoverflow.com/a/1290119/4438007) e fui tentar. Isolei
em uma task de teste chamada de `t`:

```ruby
task :t do |t|
    Rake::Task["/assets/lala"].invoke
end
```

E, bem, no primeiro momento eu ainda não havia percebido que estava
tentando criar a partir da raiz... mas, quer saber de algo? Esse teste
ter falhado me fez aprender mais coisas em Ruby!

Pois bem, cheguei a conclusão que eu precisaria invocar uma `task`
e passar parâmetros pra ela. E para evitar duplicar código, eu só
teria uma única task `:assets_dir` que iria receber como argumento
o novo caminho. Com isso, finalmente chegou a oportunidade de
praticar
[tasks que recebem parâmetros](http://docs.seattlerb.org/rake/doc/rakefile_rdoc.html#label-Tasks+that+Expect+Parameters).
Então declarei a task com o argument `:new_dir` e organizei `t` para
chamar essa nova task.

Para invocar uma task programaticamente com argumentos, me baseei
[nessa resposta](https://stackoverflow.com/a/31859538/4438007):
basicamente se chama `.invoke` com os arugmentos. Por exemplo:

```ruby
Rake::Task[:assets_dir].invoke "assets/lala"
```

E as regras adaptadas para isso:

```ruby
task :assets_dir, [:new_dir] do |t, args|
    puts "criando diretório de assets #{args.new_dir}"
    mkdir args.new_dir
end

task :t do |t|
    Rake::Task[:assets_dir].invoke "/assets/lala"
end
```

Uma task com parâmetros é declarada como uma task, e após seu
identificador de nome vem um vetor com os nomes dos argumentos.
Para acessar os argumentos, é necessário passar um bloco de código
que receba a task de trabalho e os argumentos, por conveniência
denotados como `|t, args|`.

Aqui eu finalmente consegui enxergar que tinha algo estranho com o
argumento, ele estava recebendo uma barra `/` a mais do que deveria
logo no começo da palavra. Existia a solução de remover essa `/`
via Ruby chamando `args.new_dir[1..]`, ou simplesmente corrigindo o
texto. Optei pelo segundo, mais fácil. Aproveitei e fiz a task
baseada no nome do diretório chamar o `:assets_dir`:

```ruby
rule(/^assets\/[^\/]+\/?$/) do |t|
    Rake::Task[:assets_dir].invoke t.name
end

task :assets_dir, [:new_dir] do |t, args|
    puts "criando diretório de assets #{args.new_dir}"
    mkdir args.new_dir
end

task :t do |t|
    Rake::Task[:assets_dir].invoke "assets/lala"
end
```

Bem, agora eu me toquei do erro do começo da experiência: `/assets/lala`,
com `/` no começo. E se eu remover a barra? Será que invoca?

Aqui eu adaptei `t` para chamar corretamente:

```ruby
task :t do |t|
    Rake::Task["assets/lala"].invoke
end
```

E assim funcionou, PERFEITAMENTE! Corri atrás de coisas mais complexas e,
já que eu as colhi, aproveitei e deixei aqui para conhecimento futuro.

Na task `rule(/^_drafts\/.*\.md$/)`, coloquei o diretório destino de
assets como `assetsDir = "/assets/#{radix}/"` e invoquei
`Rake::Task[assetsDir[1..]].invoke`.

# Correção no about

Para começar, eu quero sumir com tudo que não seja de interessante
de dentro da listagem do [`/about`]({{ "about" | prepend: site.baseurl }}). Bem, o jeito
foi criando um novo campo no frontmatter. Adicionado o campo `interesting` que, se tiver
com o valor `true`, vai ser listado no about. Toda a questão de quebrar a string
em partes agora não se faz mais necessária:

{% raw %}
```diff
 {% for my_page in site.pages %}
-  {%- assign my_page_parts = my_page.url | downcase | split: "."  -%}
-  {%- unless
-        my_page_parts[-1] == "css" or
-        my_page_parts[-1] == "xml" or
-        my_page_parts[0] == "/" or
-        my_page.url == page.url %}
+  {%- if my_page.interesting %}
   - [{% if my_page.title %}{{my_page.title}}{% else %}`{{my_page.url}}`{% endif %}]({{ my_page.url | prepend: site.baseurl }})
   {%- endif -%}
 {% endfor %}
```
{% endraw %}

E para exibir apenas o que se deseja bastou um simples `interesting: true` no frontmatter.

# Ajeitando o hamburguer

Ok, resolvido o problema da exibição em tela grande, e agora, para lidar em telas pequenas,
como as de celular?

Bem, a primeira dica que eu tive foi analisando a página gerada: existe uma `<div>` que engloba
o `<a>Sobre</a>`. E essa `<div>` tem a classe `trigger`.

Cheguei no arquivo que ainda muito pouco havia mexido:
[`/_sass/_layout.scss`]({{ site.repository.blob_root}}/_sass/_layout.scss). Por sinal,
apenas nele que se tem declaração CSS para essa classe. Logo, deve estar aí o segredo
do hamburguer. E, bem? Meio que estava lá sim. Quando se chega no nível que está
indicado no `scss` como sendo `@include media-query($on-palm)`, o `.trigger`
ficava assim:

```scss
.trigger {
    clear: both;
    display: none;
}

&:hover .trigger {
    display: block;
    padding-bottom: 5px;
}

.page-link {
    display: block;
    padding: 5px 10px;

    &:not(:last-child) {
        margin-right: 0;
    }
    margin-left: 20px;
}
```

Para mim isso significou que, ao estar em um tamanho pequeno, o
bloco `trigger`fica invisível (`.trigger { display: none; } `),
mas se tiver o efeito de `onhover` ele passa a expandir o hamburger.

```scss
&:hover .trigger {
    display: block;
    padding-bottom: 5px;
}
```

Com essa informação em mãos, vamos atacar o problema. Eu quero que
os links existam no hamburguer porém não fora. Posso resolver isso
com CSS, adicionando uma nova class: `.large-hidden`. Para ser
exatamente o que se pretendia usar, vou declarar para elementos
que possuam ambos `.large-hidden` e também para `.page-link`.

Para atender duas classes ao mesmo tempo, me baseei
[nessa resposta](https://stackoverflow.com/a/2554853/44380070):

```scss
.page-link.large-hidden {
    display: none;
}

@include media-query($on-palm) {
    //....

    .page-link.large-hidden {
        display: block;
    }
}
```

Ok, agora isso acontece do jeitinho que havia imaginado. Só falta preencher as
classes adequadamente.

Agora, parto para [`/_includes/header.html`]({{ site.repository.blob_root}}/_includes/header.html).
Ele estava gerando assim os links:

```html
<div class="trigger">
{% for my_page in site.pages %}
    {% if my_page.title and my_page.show %}
    <a class="page-link" href="{{ my_page.url | prepend: site.baseurl }}">{{ my_page.title }}</a>
    {% endif %}
{% endfor %}
</div>
```

Isso evitava completamente de ser exibido. Agora, eu poderia pegar esse mesmo mecanismo
que não a presença do `title` e construir em cima dele a adição da classe:

```html
<div class="trigger">
{% for my_page in site.pages %}
    {% if my_page.title %}
    <a class="page-link{% unless my_page.show %} large-hidden{% endunless %}" href="{{ my_page.url | prepend: site.baseurl }}">{{ my_page.title }}</a>
    {% endif %}
{% endfor %}
</div>
```
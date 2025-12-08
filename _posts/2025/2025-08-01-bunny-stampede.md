---
layout: post
title: "Debandada de coelhos! Invertendo a direção de uma animação de background usando CSS e HTML"
author: "Jefferson Quesado"
tags: css html meta liquid jekyll
base-assets: "/assets/bunny-stampede/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

O [Camilo Micheletto](https://bsky.app/profile/lixeletto.bsky.social)
recentemente entregou umas alterações bem legais no Computaria. Pedi pra ele
ajuda pra colocar o
[dark-theme](https://gitlab.com/computaria/blog/-/merge_requests/4), aí ele
aproveitou e colocou uma animção nos links de navegação!

Sério, olha que legal, bota o mouse em cima:

<style>
.stampede-container {
    position: relative;
    min-height: 32px;
}

.stampede-container.local-stampede:hover {
    background-image: url("{{ site.baseurl }}/assets/coelho-pattern.png");

    background-repeat: repeat;
    animation: infinite-scroll 4s linear infinite;
}

.stampede-container:hover .stampede {
    background-image: url("{{ site.baseurl }}/assets/coelho-pattern.png");

    background-repeat: repeat;
    animation: infinite-scroll 4s linear infinite;
}

.stampede {
    width: 100%;
    height: 100%;
}

.stampede-position-fix {
    position: absolute;
    top: 0px;
    left: 0px;
    z-index: -1;
}
</style>

{% verbatim_etc html %}
<div class="stampede-container local-stampede">
    <p>HOVER AQUI</p>
</div>
{% endverbatim_etc %}

Ok, isso exemplifica a animação. Mas, qual foi o problema?

Bem, a animação ia da direita para a esquerda. O _bunny stampede_ tinha uma
direção. Porém, eu queria que o lance fosse:

- previous: coelhos indo para a esquerda (indo pra "trás")
- next: coelhos indo para a direita (indo pra "frente")

Ou seja: a direção do movimento dos coelhos igual à direção que a seta aponta.

E eu também não queria fazer uma nova imagem! Ou seja, eu queria uma solução em
que a direção da imagem fosse alterada usando apenas CSS.

A solução para isso é fácil, né? Só colocar um `transform: scaleX(-1)`? Vamos
tentar, vou adicionar isso no estilo do componente acima:

{% verbatim_etc html %}
<div class="stampede-container local-stampede" style="transform: scaleX(-1);">
    <p>HOVER AQUI</p>
</div>
{% endverbatim_etc %}

Então... ele virou tudo, né? Não só o `stampede` dos coelhos... então, como que
resolvemos isso? Adicionando um novo componente HTML!

Esse novo componente precisa de algumas características:

- precisa ocupar a altura e o comprimento do pai
- não pode interferir no posicionamenot dos irmãos

Em tese tanto faz a tag, escolhi fazer com `<span>`. Para ficar com a mesma
altura e comprimento do pai, coloquei `heigth: 100%; width: 100%;`. Mas isso
ainda luta com a questão de posicionamento dos irmãos...

Procurando um pouco, encontrei essa referência aqui:
[How to create same height div as parent height](https://dev.to/snehalkadwe/how-to-create-same-height-div-as-parent-height-h6j).
E notei que para fazer o que ele precisava de cobrir todo o elemento pai ele
usou `position: absolute;`, e colocou o pai com `position: relative;`. Então,
será que agora dá certo? Primeiramente, vamos testar com o `stampede` apenas
na `<span>`, sem dar o `scaleX` nos coelhos...

{% verbatim_etc html %}
<div class="stampede-container">
    <p>HOVER AQUI</p>
    <span class="stampede"></span>
</div>
{% endverbatim_etc %}

Hmmm, ele não tá localizando a questão do height nem do width corretamente. E
se eu mandar ele se posicionar de modo absoluto?

{% verbatim_etc html %}
<div class="stampede-container">
    <p>HOVER AQUI</p>
    <span class="stampede" style="position: absolute;"></span>
</div>
{% endverbatim_etc %}

Muito bem. Agora ele detecta o hover. Porém tá ainda... um tanto quanto off.
Vou resetar a posição dele, pra ver no que que dá:

{% verbatim_etc html %}
<div class="stampede-container">
    <p>HOVER AQUI</p>
    <span class="stampede" style="position: absolute; top: 0px;"></span>
</div>
{% endverbatim_etc %}

Ok, agora parece bom. Vamos adicionar o `scaleX` para ver se apenas a direção
do _stampede_ é alterada:

{% verbatim_etc html %}
<div class="stampede-container">
    <p>HOVER AQUI</p>
    <span class="stampede" style="position: absolute; top: 0px; transform: scaleX(-1);"></span>
</div>
{% endverbatim_etc %}

Resolvido! Só para evitar colocar classes soltas, vamos agregar as coisas no
lugar correto? Em uma classe fechadinha?

Bem, fica assim:

{% verbatim_etc html %}
<div class="stampede-container">
    <p>HOVER AQUI</p>
    <span class="stampede stampede-position-fix"></span>
</div>
{% endverbatim_etc %}

As classes CSS usadas foram essas:

{% raw %}
```css
.stampede-container {
    position: relative;
    min-height: 32px;
}

.stampede-container.local-stampede:hover {
    background-image: url("{{ site.baseurl }}/assets/coelho-pattern.png");

    background-repeat: repeat;
    animation: infinite-scroll 4s linear infinite;
}

.stampede-container:hover .stampede {
    background-image: url("{{ site.baseurl }}/assets/coelho-pattern.png");

    background-repeat: repeat;
    animation: infinite-scroll 4s linear infinite;
}

.stampede {
    width: 100%;
    height: 100%;
}

.stampede-position-fix {
    position: absolute;
    top: 0px;
    left: 0px;
    z-index: -1;
}
```
{% endraw %}

# Cadastro de bloco Liquid

Bem, eu estava me repetindo demais colocando o código de exibição e ao mesmo
tempo repetindo-o como bloco de código para ficar visível ao leitor. Por
exemplo:


````md
```html
<div class="stampede-container">
    <p>HOVER AQUI</p>
    <span class="stampede stampede-position-fix"></span>
</div>
```
<div class="stampede-container">
    <p>HOVER AQUI</p>
    <span class="stampede stampede-position-fix"></span>
</div>
````

Então, para evitar ficar fazendo essa reescrita constante, resolvi que deveria
emitir tanto verbatim como também como bloco de código. Para tal, fiz o
seguinte construto:

{% raw %}
```liquid
{% verbatim_etc html %}
<div class="stampede-container">
    <p>HOVER AQUI</p>
    <span class="stampede stampede-position-fix"></span>
</div>
{% endverbatim_etc %}
```
{% endraw %}

Que automaticamente deveria gerar as duas coisas. Mas, como fazer?

Usei como base o código para o bloco `highlight` e também uma dica que vi
[nessa resposta](https://talk.jekyllrb.com/t/markdown-parsing-order-in-custom-liquid-tags/4397/3).

Assim, registrei meu bloco:

```ruby
Liquid::Template.register_tag("verbatim_etc", Computaria::VerbatimEtc)
```

E agora preciso implementar o `VerbatimEtc`. Tal qual em
[Usando as tags - Parte 1: página de tags]({% post_url 2024/2024-06-03-pagina-tags %}),
o jeito de fazer isso é usando o sistema de plugins de Jekyll. Agora para
blocos, descrito em [`tags`](https://jekyllrb.com/docs/plugins/tags/).

Finalmente, a magia para renderizar foi apenas pedir uma instância do
renderizador de markdown e de renderizador de Liquid:

```ruby
class VerbatimEtc < Liquid::Block
    def initialize(tag_name, markup, tokens)
        super
    end

    # https://talk.jekyllrb.com/t/markdown-parsing-order-in-custom-liquid-tags/4397/3
    def render(context)
        code = super.to_s.strip

        site = context.registers[:site]
        converter = site.find_converter_instance(::Jekyll::Converters::Markdown)



        rendered = Liquid::Template.parse(converter.convert("""
{{ "%7B%25 raw %25%7D" | url_decode }}
\`\`\`
#{code}
\`\`\`
{{ "%7B%25 endraw %25%7D" | url_decode }}

#{code}
        """)).render(context)

        rendered
    end
end
```

No primeiro momento não estranhei a questão de que não tem tinha uma linguagem
informada. Fui atrás de descobrir como que se informaria uma linguagem e eu
descobri que ela vem no segundo parâmetro do construtor, denominado `markup`.
Então, bastou guardar ele em uma variável de objeto e invocar quando for
renderizar o bloco de código:

```ruby
class VerbatimEtc < Liquid::Block
    def initialize(tag_name, markup, tokens)
        super

        @lang = markup.strip
    end

    # https://talk.jekyllrb.com/t/markdown-parsing-order-in-custom-liquid-tags/4397/3
    def render(context)
        code = super.to_s.strip

        site = context.registers[:site]
        converter = site.find_converter_instance(::Jekyll::Converters::Markdown)



        rendered = Liquid::Template.parse(converter.convert("""
{{ "%7B%25 raw %25%7D" | url_decode }}
\`\`\`#{@lang}
#{code}
\`\`\`
{{ "%7B%25 endraw %25%7D" | url_decode }}

#{code}
        """)).render(context)

        rendered
    end
end
```

O método `strip` da string remove as "pontas" dela. Necessário no
`@lang = markup.strip`.

E com isso consegui fornecer tanto uma rápida visualização para o conteúdo sem
grandes possibilidades de eu cometer falhas em replicar para ter algo visível
para o artigo, mantendo tanto o código quanto o efeito desejado na
visualização.
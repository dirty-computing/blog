---
layout: post
title: "Atualizando o SASS do Computaria"
author: "Jefferson Quesado"
tags: sass meta
base-assets: "/assets/updating-sass/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Após o
[Manipulando query string para melhor permitir compartilhar uma página carregada dinamicamente]({% post_url 2025-01-23-genomics-daily-query %})
acabei atualizando no meu sistema a gem com o SASS. E isso teve um efeito um
tanto quanto inesperado: o SASS começou a disparar novos warnings.

# Primeiro warning: `darken`

A primeira reclamação que me subiu fortemente foi em relação ao `darken`. Ele
sugeria usar outra alternativa, simplesmente trocar por `color.adjust`:

```scss
$grey-color-dark: darken($grey-color, 15%); // original
$grey-color-dark: color.adjust($color, $lightness: -15%); // sugestão
```

Mas ao usar ele dava um erro:

```
Error: There is no module with the namespace "color".
   ╷
40 │ $grey-color-dark: color.adjust($grey-color, $lightness: -25%);
```

Mas então, o que seria isso?

Bem, descobri que é porque agora o SASS está indo para um caminho mais modular.
E eu não chamei o módulo `color`. Como faço pra usar o módulo? Chamo com
`@use`! Como é um módulo bem padrão, ele é prefixado com `sass:`, então vamos
chamar o módulo `color` do `sass`?

```scss
@use "sass:color";

$grey-color-dark: color.adjust($grey-color, $lightness: -25%);
```

Perfeito, aparentemente funcionou! Efetivamente o SASS reclamou a mesma coisa
pro `lighten`, então tal qual foi pro `darken`, só fazer um ajuste de
`lighteness` da cor. Como é para ficar mais clara, o ajuste é positivo, já que
o ajuste para dicar mais escuro era negativo:

```scss
@use "sass:color";

$grey-color-dark: color.adjust($grey-color, $lightness: -25%);
$grey-color-light: color.adjust($grey-color, $lightness: 40%);
```

Ok, como vemos se tá dando certo? Abrindo o `_site/css/main.css`! Sim, eu
valido o artefato final e _profit_!

No começo eu realmente fiz isso, ao ponto de comparar com o artefato do blog
disponível na web em
[https://computaria.gitlab.io/blog/css/main.css](https://computaria.gitlab.io/blog/css/main.css)
(inclusive tinha mudanças que o `diff` não estava pegando direito, então fiz na
mão o meu diferencial).

Mas tem um jeito muito melhor! Posso usar o comando `@debug`!

Então, vamos verificar se a cor está de acordo com o que eu tinha no blog já
compilado! Pegar um trecho aqui do SCSS:

```scss
blockquote {
    color: $grey-color;
    border-left: 4px solid $grey-color-light;
    /* ... */
}
```

```css
/* da web */
blockquote {
  color: #828282;
  border-left: 4px solid #e8e8e8;
  /* .. */
}
/* gerado local */
blockquote {
  color: #828282;
  border-left: 4px solid #e8e8e8;
  /* .. */
}
```

Muito bem, o `lighten` foi dominado. E para o `darken`?

```scss
.site-header {
    border-top: 5px solid c.$grey-color-dark;
    /* .. */
}
```

```css
/* original */
.site-header {
  border-top: 5px solid #424242;
  /* .. */
}
/* gerado local */
.site-header {
  border-top: 5px solid rgb(66.25, 66.25, 66.25);
  /* .. */
}
```

Ok, não foi o resultado que eu queria. O `$lightness: -15%` resultou em um
número quebrado. Qual diferença um `0.25` faria em um olho humano em um
intervalo que vai de `[0, 255)`? Nenhuma. Mas eu queria resolver isso. E já que
eu vou ajeitar pro `darken` por conta de uma coincidência de valores, vou
aproveitar e fazer pro `lighten` também! Vamos começar a testar hipóteses com
`@debug`?

Vamos lá, e se eu arredondar o valor? Eu tenho o módulo `math` e após declarar
que vou usá-lo tenho acesso a `math.round`. Mas pra isso vou precisar acessar
o vermelho, o verde e o vermelho da cor... e, bem? temos `color.channel`!

Aqui, o `color.channel` você passa a cor e de que canal quer tirar a
propriedade. Como eu quero tirar o vermelho de `$grey-color-dark`:

```scss
@debug color.channel($grey-color-dark, "red");
```

E isso imprimiu `Debug: 66.25`. Ok, progresso. Arredondar esse valor:

```scss
@debug math.round(color.channel($grey-color-dark, "red"));
```

Arredondado bonitinho: `Debug: 66`. Qual o próximo passo? Criar uma nova cor!
Mas como faço isso? Bem, vou tentar colocar o vermelho, o verde e o azul dentro
da função `rgb` e ver no que dá... criei uma variável `$grey-j` só para ficar
mais fácil manipular e eu conseguir ler o que estou imprimindo:

```scss
@use "sass:math";

/* ... */
$grey-j: rgb(
    math.round(color.channel($grey-color-dark, "red")),
    math.round(color.channel($grey-color-dark, "green")),
    math.round(color.channel($grey-color-dark, "blue"))
);

@debug $grey-j;
```

E o resultado foi um decepcionante `Debug: rgb(66, 66, 66)`. Não obtive o que
eu deseja, que era o equivalente `#424242`. E se... e se eu usar a função
`color.change` para criar uma nova cor?

Vou continuar usar o `$grey-j` para os testes, mas vou por o valor original
criado pelo ajuste de escurecimento em uma variável `raw`, digamos assim.
`$grey-color-dark-raw`:

```scss
$grey-color:       #828282;
$grey-color-dark-raw:  color.adjust($grey-color, $lightness: -25%);

$grey-j: color.change($grey-color-dark-raw,
    $red: math.round(color.channel($grey-color-dark-raw, "red")),
    $green: math.round(color.channel($grey-color-dark-raw, "green")),
    $blue: math.round(color.channel($grey-color-dark-raw, "blue"))
);

@debug $grey-j;
```

E com isso obtive `Debug: #424242`! Uhulll!!!

A versão sem o código de debug ficou assim:

```scss
$grey-color:         #828282;
$grey-color-light-raw: color.adjust($grey-color, $lightness: 40%);
$grey-color-dark-raw:  color.adjust($grey-color, $lightness: -25%);

$grey-color-dark: color.change($grey-color-dark-raw,
    $red: math.round(color.channel($grey-color-dark-raw, "red")),
    $green: math.round(color.channel($grey-color-dark-raw, "green")),
    $blue: math.round(color.channel($grey-color-dark-raw, "blue"))
);

$grey-color-light: color.change($grey-color-light-raw,
    $red: math.round(color.channel($grey-color-light-raw, "red")),
    $green: math.round(color.channel($grey-color-light-raw, "green")),
    $blue: math.round(color.channel($grey-color-light-raw, "blue"))
);
```

# Segundo warning: `@import`

Bem, o SASS reclamou também do `@import`. Não devo usá-lo porque o SASS começou
o processo de remoção disso. Antes eu tinha o arquivo `main.scss` assim:

```scss
@charset "utf-8";
@use "sass:color";    // para lidar com o escurecer de cores
@use "sass:math";     // para usar o round

// Our variables
$base-font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
$base-font-size:   16px;

/** outras variáveis */

@mixin media-query($device) {
    @media screen and (max-width: $device) {
        @content;
    }
}

// Import partials from `sass_dir` (defaults to `_sass`)
@import
        "base",
        "layout",
        "syntax-highlighting"
;
```

A propósito, a crítica ao `@import` você pode encontrar na documentação
[aqui](https://sass-lang.com/documentation/at-rules/import/). Como o `@import`
funcionava na prática?

Bem, na prática era como se os arquivos `_base.scss`, `_layout.scss` e
`_syntax-highlighting.scss` fossem, nessa exata ordem porque é a ordem que
aparecem no `@import`, fossem concatenados no final do `main.scss`. Então todas
as declarações feitas em `main.scss` estão disponíveis para os arquivos
importados.

Então precisamos usar o `@use` no lugar, né? Bem, não. Para começar, cada
`@use` é próprio, não posso colocar como no `@import` lá em cima que eram todos
juntos separados por vírgula, isso dá erro:

```scss
@use
        "base",
        "layout",
        "syntax-highlighting"
;
```

Então façamos para cada um desses individualmente? Ficaria assim mais ou menos:

```scss
@charset "utf-8";
@use "sass:color";    // para lidar com o escurecer de cores
@use "sass:math";     // para usar o round

// Our variables
$base-font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
$base-font-size:   16px;

/** outras variáveis */

@mixin media-query($device) {
    @media screen and (max-width: $device) {
        @content;
    }
}

// Import partials from `sass_dir` (defaults to `_sass`)
@use "base";
@use "layout";
@use "syntax-highlighting";
```

Só que isso também dá pane!

```
Error: @use rules must be written before any other rules.
   ╷
52 │ @use "syntax-highlighting";
```

Hmmm, então vou precisar mudar as coisas de canto. Os `@use` vão precisar
surgir antes das outras coisas...

Bem, se eu vou por o `@use` antes de declarar as variáveis, hora de refatorar
e colocar minhas variáveis em um novo lugar, né?

## Refatorando: variáveis em lugar comum

Primeira coisa que eu fiz foi mudar o `main.scss` para ficar assim:

```scss
@charset "utf-8";

// Import partials from `sass_dir` (defaults to `_sass`)
@use "base";
@use "layout";
@use "syntax-highlighting";
```

E o miolo dele eu coloquei em um arquivo `_common.scss`. Sem nenhum segredo
aqui.

Mas isso implicou algumas coisas... por exemplo, como usar essas variáveis em
outros lugares. Começando pelo `_base.scss`:

```scss
a {
    color: $brand-color;
    text-decoration: none;

    &:visited {
        color: color.adjust($brand-color, $lightness: -15%);
    }

    &:hover {
        color: $text-color;
        text-decoration: underline;
    }
}
```

Aqui ele reclama pois não conhece nenhuma dessas variáveis. Ao simplesmente
chamar `@use "common"` também não funciona, pois o módulo está em outro
namespace. Como eu resolveria isso? Bem, a primeira opção seria usar o nome do
módulo, que nem foi feito para `color`:

```scss
@use "sass:color";
@use "common";

// ...
a {
    color: common.$brand-color;
    text-decoration: none;

    &:visited {
        color: color.adjust(common.$brand-color, $lightness: -15%);
    }

    &:hover {
        color: common.$text-color;
        text-decoration: underline;
    }
}
```

Mas, sinceramente? Ficou feio. Se eu pudesse importar o módulo como `c`... E,
bem, eu _posso_ sim fazer isso:

```scss
@use "sass:color";
@use "common" as c;

// ...
a {
    color: c.$brand-color;
    text-decoration: none;

    &:visited {
        color: color.adjust(c.$brand-color, $lightness: -15%);
    }

    &:hover {
        color: c.$text-color;
        text-decoration: underline;
    }
}
```

E eu também posso importar no escopo local, que não necessitaria de mais
mudanças:

```scss
@use "sass:color";
@use "common" as *;

// ...
a {
    color: $brand-color;
    text-decoration: none;

    &:visited {
        color: color.adjust($brand-color, $lightness: -15%);
    }

    &:hover {
        color: $text-color;
        text-decoration: underline;
    }
}
```

Ok, preciso adequar também outros cantos de uso, como os `media-query`. Por
exemplo:

```scss
.wrapper {
    max-width: -webkit-calc(#{c.$content-width} - (#{c.$spacing-unit} * 2));
    max-width:         calc(#{c.$content-width} - (#{c.$spacing-unit} * 2));
    margin-right: auto;
    margin-left: auto;
    padding-right: c.$spacing-unit;
    padding-left: c.$spacing-unit;
    @extend %clearfix;

    // perceba a alteração do media-query, agora é um elemento de `common.scss`
    @include c.media-query(c.$on-laptop) {
        max-width: -webkit-calc(#{c.$content-width} - (#{c.$spacing-unit}));
        max-width:         calc(#{c.$content-width} - (#{c.$spacing-unit}));
        padding-right: calc(c.$spacing-unit / 2);
        padding-left: calc(c.$spacing-unit / 2);
    }
}
```

## Estender algo que não existe?

Ok, tá vendo o `@extend %clearfix`? O `%clearfix` é o que o SASS chama de
"seletor placeholder". O que isso significa? Bem, a classe `.wrapper` acima
compila para algo assim no blog (vai ser alterado após as alterações deste
post):

```css
.footer-col-wrapper:after, .wrapper:after {
    content: "";
    display: table;
    clear: both;
}
```

Em `_layout.scss` tenho a classe `.footer-col-wrapper` que também faz
`@extend %clearfix`. E em `_base.scss` tenho a declaração desse seletor:

```scss
/**
 * Clearfix
 */
%clearfix {

    &:after {
        content: "";
        display: table;
        clear: both;
    }
}
```

E, bem. Agora o `%clearfix` reside dentro do `_base.scss`. E como não está
sendo usado o `@import` que faz um append dos arquivos, o `%clearfix` não está
mais prontamente disponível. Qual minha primeira reação? "VAMOS REFATORAR!"

E eu coloco o seletor placeholder em `_common.scss`. Só que...

```none
Error: The target selector was not found.
Use "@extend %clearfix !optional" to avoid this error.
    ╷
171 │     @extend %clearfix;
```

Ok, posso fazer isso. Eu coloco o `!optional`, mas a que custo? Eu descobri que
colocar o `!optional` resolve o problema de compilação, mas será que o
resultado é mesmo o esperado? Não sei, e fiquei com medo. Preferi contornar!

Eu não consegui de jeito nenhum com importação de módulo nomeado.

Tentei `@extend c.%clearfix` para o SASS reclamar de mim. Tentei algumas
variações na posiçãdo do `%`, mas nada deu certo...

E... se lembra que tem a importação de mesmo escopo? Então... tentei fazer
`@use "common" as *` agora só pra ver se ele pega o seletor placeholder. E qual
não foi minha surpresa quando isso funcionou!

Mas, não. Não quero isso. Parece demais com cheiro de gambiarra! E se no lugar
disso eu não tentasse usar como um `mixin`? Eu já tinha o exemplo do
`media-query`, e ele funcionava bem. Então transformei o `clearfix`, de um
seletor placeholder, em um `mixin`:

```scss
@mixin clearfix {

    &:after {
        content: "";
        display: table;
        clear: both;
    }
}
```

E para usar, só chamar com `@include` do mixin, não o `@extend` do seletor.

```scss
.wrapper {
    max-width: -webkit-calc(#{c.$content-width} - (#{c.$spacing-unit} * 2));
    max-width:         calc(#{c.$content-width} - (#{c.$spacing-unit} * 2));
    margin-right: auto;
    margin-left: auto;
    padding-right: c.$spacing-unit;
    padding-left: c.$spacing-unit;
    @include c.clearfix;

    @include c.media-query(c.$on-laptop) {
        max-width: -webkit-calc(#{c.$content-width} - (#{c.$spacing-unit}));
        max-width:         calc(#{c.$content-width} - (#{c.$spacing-unit}));
        padding-right: calc(c.$spacing-unit / 2);
        padding-left: calc(c.$spacing-unit / 2);
    }
}
```

Obtive um resultado distinto? Sim, obtive. O que antes ele soltava assim

```css
.footer-col-wrapper:after, .wrapper:after {
    content: "";
    display: table;
    clear: both;
}
```

Agora ele solta assim:

```css
.wrapper:after {
    content: "";
    display: table;
    clear: both;
}

/* ... */
/* muito distante */
/* ... */

.footer-col-wrapper:after {
    content: "";
    display: table;
    clear: both;
}
```

Tinha outro seletor placeholder, `%vertical-rhythm`, que também mudou algumas
coisas. Antes era assim:

```scss
/**
 * Set `margin-bottom` to maintain vertical rhythm
 */
h1, h2, h3, h4, h5, h6,
p, blockquote, pre,
ul, ol, dl, figure,
%vertical-rhythm {
    margin-bottom: calc($spacing-unit / 2);
}
```

E no `_syntax_highlighting.scss` o `vertical-rhythm` também era usado:

```scss
.highlight {
    background: #fff;
    @extend %vertical-rhythm;
    // ...
}
```

Antes o resultado era assim:

```css
h1, h2, h3, h4, h5, h6,
 p, blockquote, pre,
 ul, ol, dl, figure,
 .highlight {
    margin-bottom: 15px;
}

/* ... */

.highlight {
    background: #fff;
}
```

Ao alterar para tornar o `%vertical-rhythm` para um mixin ficou assim:

```scss
// common.scss
@mixin vertical-rhythm {
    margin-bottom: calc($spacing-unit / 2);
}

// base.scss
h1, h2, h3, h4, h5, h6,
p, blockquote, pre,
ul, ol, dl, figure {
    @include c.vertical-rhythm;
    // note aqui a inversão dos valores, antes era aqui que declarava
    // vertical-rhythm, agora aqui apenas usa o vertical-rhythm, a fonte de
    // verdade dele está em outro lugar
}

// syntax-highlighting.scss
.highlight {
    background: #fff;
    @include c.vertical-rhythm;
    // ...
}
```

Agora o resultado gerou assim:

```css
h1, h2, h3, h4, h5, h6,
 p, blockquote, pre,
 ul, ol, dl, figure {
    margin-bottom: 15px;
}

/* ... */

.highlight {
    background: #fff;
    margin-bottom: 15px;
}
```

# Pequeno ajuste no `h1`

Ok, eu só descobri essa recomendação enquanto escrevia esse trecho específico:

> Apesar do padrão do HTM permitir usar múltiplos `<h1>` na mesma página, isso
> não é considerado uma boa prática. Uma página deve em geral ter apenas um
> único elemento `<h1>` que descreva o seu conteúdo

Extraído da
[MozDev](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Heading_Elements#avoid_using_multiple_h1_elements_on_one_page)
e traduzido por mim.

Original:

> While using multiple `<h1>` elements on one page is allowed by the HTML
> standard (as long as they are not nested), this is not considered a best
> practice. A page should generally have a single `<h1>` element that describes
> the content of the page (similar to the document's `<title>` element).

Mas eu espalhei o uso indiscriminado de `<h1>` ao usar um único `#` para
representar títulos de seção.

Enfim, algo que sempre me incomodava era que o título das seções mais
importantes acabavem ficando menor do que `<h2>`. Aproveitei que estava
mexendo no `_layout.scss` e notei que estava faltando o `<h1>`. Então resolvi
consertar o meu incômodo. O trecho que me chamou atenção foi esse:

```scss
.post-content {
    margin-bottom: c.$spacing-unit;

    h2 {
        font-size: 32px;

        @include c.media-query(c.$on-laptop) {
            font-size: 28px;
        }
    }

    h3 {
        font-size: 26px;

        @include c.media-query(c.$on-laptop) {
            font-size: 22px;
        }
    }

    h4 {
        font-size: 20px;

        @include c.media-query(c.$on-laptop) {
            font-size: 18px;
        }
    }
}
```

Olha que interessante! Todo aumento do nível o `font-size` diminui em 6 pontos.
Então, se eu vou diminuir um nível para um nível mais básico... eu aumento 6
pontos? Bem, vamos ver no que dá:

```scss
.post-content {
    margin-bottom: c.$spacing-unit;

    h1 {
        font-size: 38px;

        @include c.media-query(c.$on-laptop) {
            font-size: 34px;
        }
    }

    h2 {
        font-size: 32px;

        @include c.media-query(c.$on-laptop) {
            font-size: 28px;
        }
    }

    h3 {
        font-size: 26px;

        @include c.media-query(c.$on-laptop) {
            font-size: 22px;
        }
    }

    h4 {
        font-size: 20px;

        @include c.media-query(c.$on-laptop) {
            font-size: 18px;
        }
    }
}
```

E sinceramente? Nem pareceu tão ruim assim, melhorou significativamente em
relação a o que se tinha antes. A próxima alteração vai ser para remover os
`<h1>` excessivos. Inclusive isso vai ajudar na hora de portar um conteúdo para
o [dev.to](https://dev.to). E isso foi um dos pontos que eu comentei no
[Computaria no dev.to]({% post_url 2025-01-07-publicando-dev-to %}).
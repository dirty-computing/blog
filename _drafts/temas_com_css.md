---
layout: post
title: "Criando um toggle de tema pro Computaria usando a malandragem do CSS"
author: "Camilo Micheletto"
tags: css dom html
base-assets: "/assets/temas_com_css/"
twitter: lixeletto
---

Tudo começou com essa mensagem:

![Jeff Quesado me falando via chat do bluesky que precisava de um toggle de temas pro blog dele]({{ page.base-assets | append: "request.png" | relative_url }})

A missão era a seguinte:

- Criar um elemento de toggle na barra de navegação
- Ele precisa informar seu estado, ser ativado via teclado com barra de espaço
- Preciso criar uma paleta de cores pro tema

# Criando o toggle

Eu jamais inventaria a roda, principalmente com HTML. Busquei "switch pattern APG" pra ver como a WCAG recomenda que um Switch seja. A versão que mais gosto da APG (Authoring Practices Guide) é a [usando checkbox](https://www.w3.org/WAI/ARIA/apg/patterns/switch/examples/switch-checkbox/), na minha opinião é a mais simples de estilizar. A implementação ficou assim:

```html
<label for="theme" class="switch" aria-label="Tema claro">
  <input
    class="switch__input"
    type="checkbox"
    id="theme"
    name="theme"
    role="switch"
    checked
  />
  <span class="switch__slider"></span>
</label>
```

- O `aria-label` anuncia "Tema claro" quando o elemento é selecionado com o leitor de tela ligado
- A `role=switch` do input faz o leitor de tela identificar o elemento como "Alternar", ele diz "Tema claro, ativado, alternar. Tema claro, grupo", demonstrando que o estado atual é "Tema claro" e que é possível alternar esse estado.
- A label ao redor do input é importante pois ao clicar nela, ela automaticamente transfere o foco para o input e troca o estado do `checked` dele. Ele faz isso devido ao valor de `for=` ser igual ao seu `id=`

Para os estilos precisamos ocultar o checkbox, transformar o label em um container e o span no toggle com círculo que vai animar de um lado para o outro quando mudarmos o estado de `checked`.

No HTML usei o [padrão BEM](https://getbem.com/introduction/), então temos o bloco `switch` e seus filhos `__input` e `__slider`. Além de isso simplificar na hora de escrever o Sass, isso demonstra pros autores quais elementos são indepententes e quais são acoplados. Mexer no `switch` (bloco) pode afetar os elementos que dependem dele. Essa relação fica transparente através da forma de escrever.

Primeiro criei o `.switch`, usei variáveis CSS pra além de reutilizar os valores identificar pra que eles servem. É literalmente a mesma lógica de criar e nomear variáveis em linguagens de programação:

```css
.switch {
  --toggle-inline-size: 40px;
  --toggle-block-size: 25px;
  position: relative;
  display: inline-block;
  width: var(--toggle-inline-size);
  height: var(--toggle-block-size);
  margin-left: auto;
  border-radius: var(--toggle-block-size);
}
```

Como o [tamanho mínimo pra um elemento interativo](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) é de pelo menos 24 x 24px, o fiz 25px x 40px pra ficar bem amigável pra interações via ponteiro e touch action (dedinhos e dedões).

Por esse switch ser um filho de um container flex ele já se comporta como `inline-block`, mas adicionei esse display pra ele não depender do container pra se comportar como elemento inline. Flexível mas ainda assim opinionado.

Depois eu sumi com o input e criei o slider. Como uso o tamanho do circulo do pra calcular a interação, guardei ele em uma variável.

```css
.switch {
  --toggle-handle-size: 16px;
  /* etc */

  &__input {
    opacity: 0;
    width: 0;
    height: 0;
  }
  /* Container do toggle */
  &__slider {
    position: absolute;
    cursor: pointer;
    inset: 0;
    background-color: c.$grey-color;
    transition: 400ms;
    border-radius: 34px;

    /* Bolinha do toggle */
    &::before {
      position: absolute;
      content: "";
      height: var(--toggle-handle-size);
      width: var(--toggle-handle-size);
      left: 4px;
      bottom: 4.5px;
      background-color: var(--color-background);
      transition: 400ms;
      border-radius: 50%;
    }
  }
}
```

Quando o input tiver `:checked` precisamos mudar a bolinha de lugar e alterar a cor de fundo. Pra isso usamos sibling selector `+`. Ele seleciona o elemento irmão imediatamente após o elemento selecionado. O `&` representa o nome da classe parent no Sass, logo `&__input:checked + &__slider` compila pra `.switch:checked + .switch__slider`.

Isso se chama [string interpolation](https://sass-lang.com/documentation/interpolation/) e é uma delícia pra escrever classes no padrão BEM, pois como os elementos são prefixados com o nome do bloco, podemos aninhar um dentro do outro.

Como o toggle tem 25px de altura e a bolinha tem 16px de altura, defini o espaço entre a bolinha e o fundo do input como 4.5px (`4.5px + 16px + 4.5px = 25px`).

Ao mudar o estado do botão, vou mover ele pra direita em 16px, a largura dele mesmo, como o toggle tem largura de 40px, menos os 32px do estaço que a bolinha percorre, sobram 4px de espaço nas laterais, por isso `left: 4px`.

```css
.switch {
  /* SE <input:checked> + <atualiza o slider> */
  &__input:checked + &__slider {
    background-color: var(--color-brand);
  }

  /* SE <input:checked> + <atualiza o ::before do slider> */
  &__input:checked + &__slider::before {
    transform: translateX(var(--toggle-handle-size));
  }
}
```

Precisei também criar um estilo de foco pra esse elemento, como o `input` (que é um elemento interativo e recebe foco) tá oculto, precisamos criar um foco ao redor do switch, que é representado pelo span.

```css
.switch {
  /* etc */
  &__input:focus + &__slider {
    box-shadow: 0 0 1px var(--color-brand);
  }
}
```

Usei `box-shadow` pro foco pois tem mais opções de efeitos e controle que o `outline` e não ocupa espaço no layout como o `border`.

Beleza! O toggle tá pronto, quem navega usando tecnologias assistivas consegue usar, mas e pessoas videntes, como vão saber pra que serve esse toggle sem nenhuma label?

Como é algo só visual, usei o elemento `::before` pra mostrar a label do botão, ainda usei o conteúdo do `aria-label` como texto:

```css
.switch {
  /* etc */

  &::before {
    content: attr(aria-label);
    position: absolute;
    top: 0;
    left: 0;
    transform: translate(calc((100% + 6px) * -1), -15%);
    font-size: 0.8rem;
  }
}
```

O `attr()` é uma função que pega o $value dos atributos declarado no elemento. No caso eu to dizendo que `content` é igual ao valor do atributo `atria-label`.

Essa conta no `transform` tem a seguinte lógica:

- _Transforms_ usam plano cartesiano, como eu quero colocar a label à esquerda, eu preciso movimentar ele pra -x. `tranform` recebe (x,y) como argumento
- 100% em `transform` significa 100% da largura (x) ou altura (y) do elemento transformado, logo `calc(100% + 6px)` significa que eu quero que ele se movimente na _mesma distância que sua própria largura_ com mais uma margem de 6px.
- Com,o eu preciso que ele vá pra esquerda, preciso que ele se mova pra -x, então multipliquei o valor por `-1`.
- O -15% no eixo Y foi olhômetro, me julguem

Massa! Vamos ver como ficou:

![Navbar todo torto com o toggle recém adicionado]({{ page.base-assets | append: "layout-parcial.png" | relative_url }})

Credo! Fui ver como tava o layout desse nav, chequei o HTML e CSS:

```html
<header class="site-header">
  <div class="wrapper">
    <a class="site-title beta-link" href="{{ site.baseurl }}/"
      >{{ site.title }}</a
    >

    <nav class="site-nav">
      <label for="theme" class="switch">
        <input class="switch__input" type="checkbox" id="theme" name="theme" />
        <span class="switch__slider"></span>
      </label>

      <a href="#" class="menu-icon">
        <!-- ícone do menu -->
      </a>

      <div class="trigger">
        <!-- Código da navegação -->
      </div>
    </nav>
  </div>
</header>
```

Ok por aqui, e o CSS:

```css
/* base.scss */

.wrapper {
  max-width: -webkit-calc(#{c.$content-width} - (#{c.$spacing-unit} * 2));
  max-width: calc(#{c.$content-width} - (#{c.$spacing-unit} * 2));
  margin-right: auto;
  margin-left: auto;
  padding-right: c.$spacing-unit;
  padding-left: c.$spacing-unit;
  @include c.clearfix;

  @include c.media-query(c.$on-laptop) {
    max-width: -webkit-calc(#{c.$content-width} - (#{c.$spacing-unit}));
    max-width: calc(#{c.$content-width} - (#{c.$spacing-unit}));
    padding-right: calc(c.$spacing-unit / 2);
    padding-left: calc(c.$spacing-unit / 2);
  }
}

/* layout.css */

.site-nav {
  float: right;
  line-height: 56px;
  /* etc */
}
```

Eu vi esse CSS de 2009 e escorreu uma lágrima de alegria, que nostalgia, <span lang="jp" title="ohisashiburi desu ne!">お久しぶりですね!</span>. Mas não podia ficar assim né? Vamos mexer no coitado desse layout!

# Implementando o holy grail no header do Jef

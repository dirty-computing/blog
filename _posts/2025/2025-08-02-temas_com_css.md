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

# Implementando um layout melhor no header do Jeff

Hoje não precisamos mais desse tanto de media query ou float. Na realidade, media queries historicamente não foram feitas pra tornar um layout responsivo, tampouco float. Na ausência de esforços de engenharia em torno de uma melhor DX pra implementar layouts, o módulo de media query passou a ser utilizado.

Após meados de 2016 que tivemos um bom baseline com CSS grid, pudemos criar algoritmos de layout que respondem aos valores de altura e largura do container pra organizarem o layout, e é isso que vamos usar.

O algoritmo abaixo é inspirado no artigo [Full-Bleed Layout Using CSS Grid do Josh Comeau](https://www.joshwcomeau.com/css/full-bleed/)

```css
.grid-wrapper {
  --content-width: #{c.$content-width};
  display: grid;
  grid-template-columns: 1fr min(var(--content-width), 100%) 1fr;
  padding-inline: 16px;
  & > * {
    grid-column: 2;
  }
}
```

- Aproveitei a variável `c.$content-width` que sinaliza a largura máxima que o conteúdo do blog vai ocupar
- `grid-template-columns` cria as colunas do grid, como o padrão do grid é empurrar novos items pra novas linhas, não precisei configurar
- `min()` seleciona o menor entre dois valores, nesse caso eu quero o menor entre `c.$content-width` (800px) e 100%. Se a tela tiver 900px de largura, a função vai computar `min(800px, 900px)` e retornar 800px pra coluna do meio. Se a tela tiver 630px de largura, ele computa `min(800px, 630px)`, retornando dessa vez os 630px.
- Os `1fr` nas extremidades representa uma fração do espaço disponível. Numa tela de 900px de largura, com a coluna do meio ficando 800px de largura, "sobram 100px". Cada lado ter `1fr` de largura, isso representa que cada um ficará com 1/2 do espaço restante.
- Num layout de 600px de largura, `min()` vai pender pro lado dos 100%, não sobrando espaço pras colunas das extremidades, logo essas colunas que são dedicadas apenas pros espaços laterais ficam com 0px de largura.
- `& > * { grid-column: 2 }` coloca todos os filhos do grid, de qualquer tipo, dentro da coluna do meio

Essa técnica é mais efetiva do que `margin-inline: auto` (ou `margin: 0 auto`) pois se quisermos que algum elemento ocupe 100% da largura podemos só declarar `grid-column: 1 / -1` (significa "da primeira à última"), sem precisar fazer truques malignos com margem negativa.

<table>
  <thead>
    <tr>
      <th>Layout desktop</th>
      <th>Layout mobile</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <img 
          src="{{ page.base-assets | append: 'layout-desktop.png' | relative_url }}" 
          alt="Layout desktop com espaçamento nas extremidades">
      </td>
      <td>
        <img 
          src="{{ page.base-assets | append: 'layout-mobile.png' | relative_url }}" 
          alt="Layout mobile do header com o espaçamento nas extremidades como zero">
      </td>
    </tr>
  </tbody>
</table>

# Criando um tema

A parte dos temas é a mais chatinha, mas menos pior usando variáveis CSS ao invés de runtime. A implementação é simples, mas a criação dos tokens de cores pode ser trabalhosa.

A estratégia é criar 3 categorias de variáveis e usar elas pra organizar a paleta de cores:

**Variáveis da paleta de cores**
Elas já existiam no arquivo `commom.scss` e se referem às cores base. É o token mais primitivo de cor. Geralmente são nomeadas como `--color-green-200`, representando o `<tipo de token> | <matiz da cor> | <luminosidade da cor (hsl)>`. Nesse caso, decidi manter os nomes originais pra se manter pregnante pro Jeff.

```scss
$text-color: #111;
$background-color: #fdfdfd;
$brand-color: #2a7ae2;
$ascent-color: #eef;
$grey-color-dark-2: #565656;
$grey-color: #828282;
```

**Variáveis de escopo**
São variáveis que define a aplicação da cor do token, sem limitar à um componente específico. São elas `--color-surface`, `--color-text`, `--color-ascent` e afins. Elas serão aplicadas de forma geral nos elementos de layout. Pra design systems mais complexos temos esse tipo de variável específica pra componentes, como `--button-text`, `--button-hover-color` ou `--button-primary-background`.

No caso do blog, criei essas:

```scss
:root {
  --color-text-light: #{c.$text-color};
  --color-background-light: #{c.$background-color};
  --color-brand-light: #{c.$brand-color};
  --color-visited-light: #{c.$grey-color-dark};
  --color-code-light: #{c.$ascent-color};
  --color-code-border-light: #e8e8e8;
  --color-button-border-light: #800080;
  --color-dynamic-bg-light: #{c.$ascent-color};
}
```

> O `#{}` serve pra interpolar variáveis de Sass com CSS

**Variáveis de tema**
Por fim crio as variáveis de tema que vão representar os temas claro e escuro e serão colocadas como valor nas variáveis de escopo quando o tema for escolhido:

```scss
:root {
  // Tema claro
  --color-text-light: #{c.$text-color};
  --color-background-light: #{c.$background-color};
  --color-brand-light: #{c.$brand-color};
  --color-visited-light: #{c.$grey-color-dark};
  --color-code-light: #{c.$ascent-color};
  --color-code-border-light: #e8e8e8;
  --color-button-border-light: #800080;
  --color-dynamic-bg-light: #{c.$ascent-color};

  // Tema escuro
  --color-text-dark: #{c.$background-color};
  --color-background-dark: #{c.$text-color};
  --color-brand-dark: #{c.$ascent-color};
  --color-visited-dark: #{c.$ascent-color};
  --color-code-dark: #{c.$color-code-dark};
  --color-code-border-dark: var(--color-blue-dark);
  --color-button-border-dark: #d9beff;
  --color-dynamic-bg-dark: #{c.$color-code-dark};

  // Valores default
  --color-text: var(--color-text-light);
  --color-background: var(--color-background-light);
  --color-brand: var(--color-brand-light);
  --color-visited: var(--color-visited-light);
  --color-code: var(--color-code-light);
  --color-code-border: var(--color-code-border-light);
  --color-button-border: var(--color-button-border-light);
  --color-dynamic-bg: var(--color-dynamic-bg-light);
}
```

Pra isso funcionar, criei duas classes, a `.theme-light` pra fazer override dos valores default pra cores claras e `.theme-dark` pra fazer cores escuras. Essas classes seriam aplicadas no HTML e sobrescreveriam os valores padrão declarados no `:root`.

```scss
.theme-light {
  --color-text: var(--color-text-light);
  --color-background: var(--color-background-light);
  --color-brand: var(--color-brand-light);
  --color-visited: var(--color-visited-light);
  --color-code: var(--color-code-light);
  --color-code-border: var(--color-code-border-light);
  --color-button-border: var(--color-button-border-light);
  --color-dynamic-bg: var(--color-dynamic-bg-light);
}

.theme-dark {
  --color-text: var(--color-text-dark);
  --color-background: var(--color-background-dark);
  --color-brand: var(--color-brand-dark);
  --color-visited: var(--color-visited-dark);
  --color-code: var(--color-code-dark);
  --color-code-border: var(--color-code-border-dark);
  --color-button-border: var(--color-button-border-dark);
  --color-dynamic-bg: var(--color-dynamic-bg-dark);
}
```

Pra deixar o tema claro como padrão, ainda no `:root` posso injetar o código da classe `.theme-light` usando o `@extend`:

```scss
:root {
  // ...
  @extend .theme-light;
}
```

Por fim, pra trocar o tema quando o usuário configurar o computador pro modo escuro usei a feature query `prefers-color-scheme`. Essa feature query identifica os padrões que o usuário configurou e aplica o CSS que você escolher de acordo com ele [(documentação da MDN)](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-color-scheme).

```scss
:root {
  // Tema light
  --color-text-light: #{c.$text-color};
  --color-background-light: #{c.$background-color};
  --color-brand-light: #{c.$brand-color};
  --color-visited-light: #{c.$grey-color-dark};
  --color-code-light: #{c.$ascent-color};
  --color-code-border-light: #e8e8e8;
  --color-button-border-light: #800080;
  --color-dynamic-bg-light: #{c.$ascent-color};

  // Tema dark
  --color-text-dark: #{c.$background-color};
  --color-background-dark: #{c.$text-color};
  --color-brand-dark: #{c.$ascent-color};
  --color-visited-dark: #{c.$ascent-color};
  --color-code-dark: #{c.$color-code-dark};
  --color-code-border-dark: var(--color-blue-dark);
  --color-button-border-dark: #d9beff;
  --color-dynamic-bg-dark: #{c.$color-code-dark};

  // Tema light como default
  @extend .theme-light;
  @media (prefer-color-scheme: dark) {
    // Tema dark se dark mode do sistema
    --color-text: var(--color-text-dark);
    --color-background: var(--color-background-dark);
    --color-brand: var(--color-brand-dark);
    --color-visited: var(--color-visited-dark);
    --color-code: var(--color-code-dark);
    --color-code-border: var(--color-code-border-dark);
    --color-button-border: var(--color-button-border-dark);
    --color-dynamic-bg: var(--color-dynamic-bg-dark);
  }
}
```

> Ainda tive que criar variáveis pras classes do syntax highlight, omiti pois são muitas e foi só corno job mesmo

# Implementando a troca de temas

A lógica da troca de tema parece simples, mas pra fazer bem feito tem de se atentar a uma série de coisas, temos que

- Trocar a label do toggle pra refletir o estado atual dele
- Trocar a classe do html pra sobrescrever os estilos
- Manipular o foco artificialmente pois a label tem que ser "focada" quando o input for selecionado
- Persistir o tema no `localStorage`
- Invocar o tema em um script síncrono pra evitar FOUC (Flash of Unstiled Content), ou seja, a tela piscando com o tema default antes do tema novo ser computado

A primeira e a segunda parte são simples:

```js
const toggleSwitch = document.querySelector("[role='switch']");

const THEMES = {
  "theme-light": "Tema claro",
  "theme-dark": "Tema escuro",
};

function setThemeLabel(themeName) {
  const toggleLabel = THEMES[themeName];
  const toggleWrapper = toggleSwitch.closest("label");
  toggleWrapper.ariaLabel = toggleLabel;
}

toggleSwitch.addEventListener("click", ({ target }) => {
  const isToggled = target.checked;
  const toggleClass = isToggled ? "theme-light" : "theme-dark";

  const currentClass = document.documentElement.className;

  // Verifica se existe uma classe de tema no elemento
  const hasTheme = Array.from(document.documentElement.classList).filter(
    (classNames) => Object.keys(THEMES).includes(classNames)
  ).length;

  // Aplica a label
  setThemeLabel(toggleClass);

  // Se houver um tema, substituí, senão adiciona
  if (hasTheme) {
    document.documentElement.classList.replace(currentClass, toggleClass);
  } else {
    document.documentElement.classList.add(toggleClass);
  }

  // Decide se o toggle ainda está checked
  toggleSwitch.checked = toggleClass === "theme-light";
});
```

Alguns pontos interessantes aqui:

- `document.documentElement` retorna o elemento `<html>`
- `classList.replace` substituí uma classe por outra, esse objeto tem vários métodos legais!
- `element.closest(element)` procura o elemento mais próximo na árvore com as características passadas como argumento. É mais tranquilo de usar do que o `.parentElement`, pois podem ter vários parents.

Depois gerenciei o foco usando eventos do tipo `focus` e `blur` e adicionando e removendo a classe `.switch--focus` que estiliza o toggle no estado de focado.

```js
toggleSwitch.addEventListener("focus", (event) => {
  event.currentTarget.parentNode.classList.add("switch--focus");
});

toggleSwitch.addEventListener("blur", (event) => {
  event.currentTarget.parentNode.classList.remove("switch--focus");
});
```

Pra persistir no `localStorage` criei duas funções assistentes:

```js
function setThemeLocalstorage(themeName) {
  localStorage.setItem("theme", themeName);
}

function getThemeLocalstorage() {
  const theme = localStorage.getItem("theme");
  return theme ?? "theme-light";
}
```

Faço o `set` do tema no evento de click e faço o get do tema assim que o HTML e os scripts são avaliados usando o evento de `DOMContentLoaded` (quem começou quando não existia `defer` lembra desse). Dessa forma eu consigo alterar a label assim que o HTML está disponível.

```js
toggleSwitch.addEventListener("click", ({ target }) => {
  //  etc ...
  setThemeLocalstorage(toggleClass);
});

window.addEventListener("DOMContentLoaded", () => {
  const theme = getThemeLocalstorage();
  setThemeLabel(theme);
  toggleSwitch.checked = theme === "theme-light";
});
```

Se eu aplicasse a classe do tema no `DOMContentLoaded`, como o CSS é carregado antes do Javascript a gente veria primeiro o tema claro (pois ele é padrão) e depois o tema escuro, quase como um flash. Pra resolver isso coloquei uma IIFE (Imediatly Evoked Function Expression) em um script **síncrono** no `head.html`.

Nesse script eu busco o tema no `localStorage`, se não tiver presente eu aplico o tema claro, se tiver presente eu aplico ele como classe no `<html>`. Isso só funciona porque a tag `<html>` é lida antes do Javascript mesmo se ele tiver síncrono hehehehe.

```html
<script>
  (function () {
    const theme = localStorage.getItem("theme");
    if (!theme) {
      window.localStorage.setItem("theme", "theme-light");
    }
    document.documentElement.className = theme ?? "theme-light";
  })();
</script>
```

Como ia ficar muito feio injetar a label também na IIFE, decidi colocar um delay na animação dela, pra mascarar a troca dela quando o tema oposto é carregado via JS. Nesses casos, nada como 300ms de delay né?

```scss
.switch {
  // etc
  &::before {
    position: absolute;
    top: 0;
    left: 0;
    transform: translate(calc((100% + 0px) * -1), -15%);
    opacity: 0;
    animation: switch-label-appear-left 300ms ease-in forwards 300ms;
    font-size: 0.8rem;
  }
}

@keyframes switch-label-appear-left {
  from {
    transform: translate(calc((100% + 0px) * -1), -15%);
    opacity: 0;
  }
  to {
    transform: translate(calc((100% + 6px) * -1), -15%);
    opacity: 1;
  }
}
```

E foi assim que com dois PRs construí o toggle de tema do blog maravilhoso do Jeff dos coelhos, com muito front-endimento e computaria!

![Gif do toggle de dark mode funcionando]({{ page.base-assets | append: "dark-mode.gif" | relative_url }})

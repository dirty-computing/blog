---
layout: post
title: "Descobrindo dataset! Dados próprios no seu elemento DOM"
author: "Jefferson Quesado"
tags: html js dom css
base-assets: "/assets/dom-dataset/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Em um review sobre
[Funcionalidade beta no Computaria]({% post_url 2025/2025-07-29-beta %}), o
[Camilo Micheletto](https://bsky.app/profile/lixeletto.bsky.social) fez um
comentário sobre o
[como eu estava manipulando o DOM](https://bsky.app/profile/lixeletto.bsky.social/post/3lv6ljpeiak2o):

> `data-` tem getters e setters em dataset
> 
> É interessante se você tiver mais de uma propriedade `data-*`
> 
> ```
> const attrAtual = foguete.dataset.beta;
> 
> // Resto inalterado
> ```
> 
> https://developer.mozilla.org/en-US/docs/Web/HTML/How_to/Use_data_attributes

E, bem, se o mestre falou, vamos seguir, né?

Eu descobri que o uso dos atributos `data-*` deveriam ser priorizados perante
atributos sem nome durante um experimento enquanto eu fazia um joguinho em
react usando TypeScript. Usei o campo do elemento para guardar o estado, e na
época usei algo como `<td state="occupied"></td>`. E o compilador do TS
reclamou disso no meu TSX, e foi aí que eu descobri o uso do `data-*`.

Desde então, tenho usado nas tags o atributo `data-*` para guardar o estado do
elemento em questão. E tenho usado bastante disso para manipular a exibição via
seletores CSS (vide
[Funcionalidade beta no Computaria]({% post_url 2025/2025-07-29-beta %}) e
[Carrossel em markdown no GitHub]({% post_url 2024/2024-11-01-github-carousel %})).

# Mudanças para o beta

A maior parte das mudanças foram diretas ao ponto:

```diff
-const rotate = Number(elementRotate.getAttribute("data-rotation"))
+const rotate = Number(elementRotate.dataset.rotation)
 const newRotate = (rotate + delta)%4
-elementRotate.setAttribute("data-rotation", newRotate)
+elementRotate.dataset.rotation = newRotate
```

Tanto no post, nos scripts do post, como também no `meta.js`. MAS... teve um
caso em particular:

```js
betaElement.setAttribute("data-beta-applied", "beta-applied")
```

Como lidar com o atributo `<tag data-beta-applied="beta-applied">`? Pois bem,
experimentei com o `elemento.dataset.*` para ver como lidava com isso.

Uma descoberta foi que eu posso criar novos atributos on-the-fly:

```js
const elemento = ...;
elemento.dataset.marm = "ota"
```

Posso acessar atributos não definidos:

```js
const elemento = ...;
console.log(elemento.dataset.undef)
```

Para depurar isso de modo visual, que tal usar um dedo de CSS? Usei para
preencher visualmente o pseudoelemento `::after` com o conteúdo
`attr(data-marmota)`:

<style>
.show::after {
    content: attr(data-marmota);
}
</style>

<script>
function incrementaMarmota() {
    const elemento = document.getElementById("marmotoso")
    const marmotaIncrementada = Number(elemento.dataset.marmota) + 1
    elemento.dataset.marmota = marmotaIncrementada
}
</script>

<p id="marmotoso" data-marmota="0" class="show">Vê ali:&nbsp;</p>

<button onclick="incrementaMarmota()" md=1>Incrementa o `data-marmota`</button>

E abaixo o código para exibir isso:

```html
<style>
.show::after {
    content: attr(data-marmota);
}
</style>

<script>
function incrementaMarmota() {
    const elemento = document.getElementById("marmotoso")
    const marmotaIncrementada = Number(elemento.dataset.marmota) + 1
    elemento.dataset.marmota = marmotaIncrementada
}
</script>

<div id="marmotoso" data-marmota="0" class="show">Vê ali:&nbsp;</div>

<button onclick="incrementaMarmota()" md=1>Incrementa o `data-marmota`</button>
```

Beleza, mas ainda não consegui acessar o `data-beta-applied`. Pensei que eu
iria acessar usando `elemento.dataset["nome-com-tracos"]`, mas isso não deu
certo.

Então decidi usar o poder do REPL: adicionei no HTML um atributo com traços e
pedi o auto-complete do dataset dele. No meu caso, peguei um parágrafo
arbitrário e customizei ele:

```diff
-<p>Texto</p>
+<p id="aqui" data-marm-ota="123">Texto</p>
```

Peguei o elemento pelo ID dele e imprimi o `dataset`:

```js
const aqui = document.getElementById("aqui")
//undefined
aqui.dataset
//DOMStringMap { marmOta → "123" }
```

Massa! Isso significa que agora eu consigo acessar o elemento! O que era
`data-marm-ota` virou camelCase!

E... eu posso criar atributo assim?

```js
aqui.dataset.outroTeste = "valor"
//"valor"
aqui
//<p id="aqui" data-marm-ota="123" data-outro-teste="valor">Texto</p>
```

Legal! e... se eu criar o atributo com camel case, como acesso ele no dataset?

```html
<p id="aqui" data-marm-ota="123" data-outro-teste="valor" data-camelCase="abcDef">Texto</p>
```

Com resultado:

```js
aqui
//<p id="aqui" data-marm-ota="123" data-outro-teste="valor" data-camelcase="abcDef">
```

Então, usar camelCase nos atributos não tem efeito. Tal qual o `onClick`.

Para fazer a alteração que estava restando no `meta.js`, só usar o camelCase:

```diff
-if (betaElement.hasAttribute("href") && betaElement.getAttribute("data-beta-applied") != "beta-applied") {
-    betaElement.setAttribute("data-beta-applied", "beta-applied")
+if (betaElement.hasAttribute("href") && betaElement.dataset.betaApplied != "beta-applied") {
+    betaElement.dataset.betaApplied = "beta-applied"
     betaElement.href += window.location.search
 }
```

# Girando o carrossel

Para o post do
[Carrossel em markdown no GitHub]({% post_url 2024/2024-11-01-github-carousel %}),
eu coloquei lá para depurar uma manipulação de dataset:

```js
function toggleHighlightCarrosselFalho() {
    const spanCarrosselFalho = document.getElementById("carrossel-falho")
    if (spanCarrosselFalho.hasAttribute("data-highlight")) {
        spanCarrosselFalho.removeAttribute("data-highlight")
    } else {
        spanCarrosselFalho.setAttribute("data-highlight", "true")
    }
}
```

Seria tudo simples se não fosse o `removeAttribute`...

Ok, o que podemos fazer com isso? Setar como nulo? Não adianta, o valor no
atributo é convertido em string:

```js
aqui
//<p id="aqui" data-marm-ota="123" data-outro-teste="valor">Texto</p>
aqui.dataset.marmOta = null
//<p id="aqui" data-marm-ota="null" data-outro-teste="valor">Texto</p>
aqui.dataset.marmOta
//"null"
```

E se eu usar o
[`delete`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/delete)?
Esse operador eu quase nunca uso. E o teste foi positivo:

```js
aqui.dataset.marmOta = null
//<p id="aqui" data-marm-ota="null" data-outro-teste="valor">Texto</p>
delete aqui.dataset.marmOta
//<p id="aqui" data-outro-teste="valor">Texto</p>
```

Ou seja, eu posso reescrever aquela função acima totalmente orientado a
dataset agora!

```js
function toggleHighlightCarrosselFalho() {
    const spanCarrosselFalho = document.getElementById("carrossel-falho")
    if (!!spanCarrosselFalho.dataset.highlight) {
        delete spanCarrosselFalho.dataset.highlight
    } else {
        spanCarrosselFalho.dataset.highlight = "true"
    }
}
```

Focando agora no diff:

```diff
 function toggleHighlightCarrosselFalho() {
     const spanCarrosselFalho = document.getElementById("carrossel-falho")
-    if (spanCarrosselFalho.hasAttribute("data-highlight")) {
-        spanCarrosselFalho.removeAttribute("data-highlight")
+    if (!!spanCarrosselFalho.dataset.highlight) {
+        delete spanCarrosselFalho.dataset.highlight
     } else {
-        spanCarrosselFalho.setAttribute("data-highlight", "true")
+        spanCarrosselFalho.dataset.highlight = "true"
     }
 }
```
---
layout: post
title: "Organizando tags"
author: "Jefferson Quesado"
tags: js dom meta ts
base-assets: "/assets/sorting-tags/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Uma coisa que eu sempre tive curiosidade de fazer era saber qual a tag que uso
com mais frequência aqui no computaria. E, também, por que não, poder olhar em
ordem as tags mais utilizadas.

Então, vamos ordenar a lista de tags?

# Esquema geral

Atualmente, a ordenação das posts é em ordem alfabética. Então, se eu quero
ordenar com quantidade de posts, eu também devo conseguir retornar a lista
original. Então devo ser capaz de ordenar de ordem decrescente de posts e ordem
alfabética (ou, de certo modo, "crescente") de nomes.

Logo, por questão de completude, vou querer ordenar de modo
crescente/decrescente tanto por quantidade de posts como por nome das tags.

Para fazer essa ordenação, não gostaria de depender de nada além do que existe
como atributo nas tags. Portanto, vamos lá usar
[datasets]({% post_url 2025/2025-07-30-dom-dataset %})!

Como a UI não está bem consolidada, irei colocar botões para essa ordenação bem
feios. Daí, essas coisas não podem vir a ser algo "prod-like", vamos considerar
essa incursão como algo [beta]({% post_url 2025/2025-07-29-beta %}) até ficar
devidamente limado.

Se quiser ver como que ficou, pode clicar
[aqui]({{ "/tags?beta=true" | prepend: site.baseurl }}) (tags com beta ligado).

Além do mais, gostaria de que um atributo fosse alterado e, em cima desse
atributo, a árvore se ordenasse. Eu deveria escutar o atributo do `<ul>` que
tem a listagem das tags.

# A criação do HTML

Para lidar com as questões necessárias de dados para a ordenação, primeiro eu
preciso povoar dentro do próprio HTML. Como a página de tags foi transportada
para um layout a ser povoado (checar a última seção do post
[Aliases de tags no Computaria]({% post_url 2025/2025-01-17-tags-alias %})),
era exatamente ali que eu precisava mexer:
[`tags.html`]({{ site.repository.blob_root }}/_layouts/tags.html).

Para começar, vamos identificar o `<ul>` com um id: `tag-list`. Dentro dessa
tag, o Liquid para gerar os itens é:

{% raw %}
```liquid
{% for tag in page.sitetags %}
    <li>
        <span class='post-meta'>{{ tag.posts.size }} posts</span>
        <h2>
            <a class='post-link beta-link' href='{{ tag.url | prepend: site.baseurl }}'>{{ tag.tag }}</a>
        </h2>
    </li>
{% endfor %}
```
{% endraw %}

Bem, aparentemente tenho tudo que eu preciso aí já! Posso pegar a quantidade de
posts com `{{ tag.posts.size }}` e o nome com `{{ tag.tag }}`. Como o elemento
que vai ser ordenado vai ser o item da lista, vou colocar essas informações no
`<li>`:

{% raw %}
```liquid
<li data-name='{{ tag.tag }}' data-size="{{ tag.posts.size }}">
```
{% endraw %}

Ficou interessante. Aparentemente, tudo resolvido, né? Só que... bem, algumas
tags tem coisas inconvenientes, como destaquei no post
[Usando as tags - Parte 1: página de tags]({% post_url 2024/2024-06-03-pagina-tags %}):

> Hmmm, algumas coisas não ficaram legais. Para garantir uma bela ordenação,
> resolvi que deveria comparar com “lowercase”. Depois percebi que o acento em
> álgebra estava atrapalhando. Daí foi mal fácil resolver esse problema de
> imediato com o `á` trocando-o por `a`

Ou seja, os acentos estavam dando problema já naquela época! Como eu poderia
lidar com isso agora em ambiente puramente Liquid? Descobri que existe uma
opção em `slugify` que faz isso:
[`slugify: "latin"`](https://jekyllrb.com/docs/liquid/filters/#options-for-the-slugify-filter):

{% raw %}
```liquid
<li data-name='{{ tag.tag | slugify: "latin" }}' data-size="{{ tag.posts.size }}">
```
{% endraw %}

Para finalizar, podemos deixar a página consistente em relação a o como ela vem
ordenada com o atributo de ordenação. Então, o `<ul>`, que vai ser identificado
para poder ser melhor manipulado, vai vir com um atributo específico para
indicar a ordenação, atributo isso que irei escutar. Então, para indicar que
estou ordenando de maneira alfabética nos títulos, e que está crescente,
escolhi colocar o seguinte como essa indicação: `data-sorted="alpha:↑"`.

Aqui, o atributo é indicado como `data-sorted`, acessado como
`element.dataset.sorted`. Usei `alpha` para indicar ordenação alfabética. Isso
é o suficiente para no contexto indicar ordenação alfabética pelo nome da tag,
ao menos na minha visão. Usei também a seta `↑` para indicar que está
crescendo, que vai aumentando. E também um separador, `:`, para indicar como o
dado está estruturado: um identificador de tipo, e a seta indicando se "cresce"
ou se diminui.

# Encodando a ordenação

Já ficou mais ou menos claro como é o esquema da ordenação, né? Basicamente eu
tenho o tipo de coisa que irei ordenar, um separador, e a direção da ordenação.

E podemos representar isso através de uma tipagem em TypeScript! Então, por que
não, né? Não iremos usar o TS na página, mas exibindo aqui como mecanismo de
pensamento, modelagem do problema.

Para fazer isso, preciso primeiro definir os tipos de campo e de seta, por
assim dizer. Eles são bem simples, `alpha` para os títulos, em ordem
alfabética, e `num` para a contagem de posts:

```ts
type Field = "alpha" | "num";
```

Um tipo de constantes bem definido, joia! E sobre as setas, eu tenho a seta pra
cima e a seta pra baixo, indicando "ordem crescente" e "ordem decrescente":

```ts
type Arrow = "↓" | "↑";
```

Agora, para o tipo da ordenação em si, preciso pegar o tipo `Field`, concatenar
com o literal `:`, e por fim concatenar com o tipo `Arrow`. Felizmente o TS já
previu esse tipo de necessidade com o
["template literal types"](https://www.typescriptlang.org/docs/handbook/2/template-literal-types.html):

```ts
type Field = "alpha" | "num";
type Arrow = "↓" | "↑";
type Sort = `${Field}:${Arrow}`;
```

Para testar, posso tentar inicializar uma variável do tipo `Sort` com algum
valor arbitrário:

```ts
const ordenaTitulos: Sort = "alpha:↓";
```

## Validando a string de ordenação

O campo `data-sorted` está definido como se fosse do tipo `Sort`. Agora, como
validar se é desse tipo mesmo? Uma alternativa até simples:

- cortar a string no separador `:`
- verificar se tem exatamente 2 elementos após o `split`
- verificar que o primeiro elemento é `alpha` ou `num`
- verificar que o segundo elemento é uma seta, `↓` ou `↑`

Basicamente, essa função aqui:

```js
function validSortStuff(sortCondition) {
    const {type, arrow, etc} = sortStuffAsObject(sortCondition)

    if (etc.length != 0) {
        return false
    }
    switch (arrow) {
        case "↓":
        case "↑":
            break
        default:
            return false
    }
    switch (type) {
        case "alpha":
        case "num":
            return true
        default:
            return false
    }
}

function sortStuffAsObject(sortCondition) {
    const [type, arrow, ...etc] = sortCondition.split(":");
    return {
        type,
        arrow,
        etc
    }
}
```

Note que estou colhendo o corte em cima do `:` com a desestruturação do array,
`[type, arrow, ...etc] = sortCondition.split(":")`, então já retorno em um
objeto com uso um pouco mais semântico do que ficar usando `parts[0]` para
indicar o tipo da ordenação ou `parts[1]` para indicar a seta. E estou colhendo
o `etc` justamente para garantir a inexistência de 3º campo (ou além, caso
existam mais).

# Escutando a mudança

Eu gostaria de mudar apenas quando um atributo fosse alterado. Então, para
fazer a alteração do atributo, criei os botões adequados:

```html
<div class="beta beta-hidden" data-beta="hidden">
    <button onclick="sortPosts('num:↑')">↑ sort by #</button>
    <button onclick="sortPosts('num:↓')">↓ sort by #</button>

    <button onclick="sortPosts('alpha:↑')">↑ sort by a-z</button>
    <button onclick="sortPosts('alpha:↓')">↓ sort by z-a</button>
</div>
```

Onde defino `sortPosts` da seguinte maneira:

```js
function sortPosts(sortCondition) {
    if (!validSortStuff(sortCondition)) {
        console.log(`<${sortCondition}> não é válido`)
        return
    }
    const element = document.getElementById("tag-list")
    if (element.dataset.sorted != sortCondition) {
        element.dataset.sorted = sortCondition
    }
}
```

Então, pesquisando exatamente por "disparar função quando alterar atributo no
DOM", cheguei neste artigo
[How to ‘listen’ for attribute changes in JavaScript](https://gwtrev.medium.com/run-code-when-an-elements-attribute-changes-b0cc1a2b184c).
Basicamente, criar um
[`MutationObserver`](https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver),
botar ele pra observar um elemento e dizer que quer observar mudanças de
atributos.

Então, vamos brincar com o `MutationObserver`?

```js
const observer = new MutationObserver((mutationList, observer) => {
    console.log("mudou")
}

observer.observe(document.getElementById("tag-list"), { attributes: true })
```

Show! Consigo ver que a função foi disparada no clique do botão! Agora, vamos
investigar a questão dessa lista de mutação? Eu poderia ler a documentação mas
eu prefiro mexer com REPL... Sou ligeiramente suspeito... Evidência
[1]({% post_url 2021/2021-09-17-desenhos-python-turtle %}),
[2]({% post_url 2022/2022-09-13-criando-gem %}),
[3]({% post_url 2025/2025-07-30-dom-dataset %}) e a prova definitiva em que saí
totalmente do caminho para habilitar o REPL onde normalmente não teria na
evidência
[4]({% post_url 2024/2024-09-23-ruby-gem-tcl-tk %}). Eu quero que o valor desse
objeto esteja acessível no meu console da web, então como eu faço isso?
Simplesmente faço uma atribuição arbitrária:

```js
const observer = new MutationObserver((mutationList, observer) => {
    console.log("mudou")
    myGrandGlobal = mutationList
}

observer.observe(document.getElementById("tag-list"), { attributes: true })
```

Note que usar `let` deixaria no escopo da função. E que usar o `var` não vai
permitir acessar fora da função (mas deixaria acessível abaixo da função).
Então, é assim que se declara globais em javascript? Sim, você simplesmente
atribui para um nome que não está definido no escopo. E com isso eu consigo
facilmente puxar no console da web o que tem em seu conteúdo:

![Print do console da web, mostrando que a variável myGrandGlobal está disponível]({{ page.base-assets | append: "console-myGrandGlobal.png" | relative_url }})

Bem, ele normalmente vem só com um único elemento, mas não custa nada iterar na
lista, né? Ele também traz o `target` que houve a alteração, o tipo da
alteração que foi disparado, e também, quando é uma alteração de atributo, o
nome do atributo que sofreu alteração.

No caso, como eu já estou colocando apenas no elemento desejado (via 
`document.getElementById("tag-list")`), não preciso validar o target
específico. Eu também pedi para observar apenas em situações de alterações de
atributos (no `observer.observe(elemento, { attributes: true })`). Então, não
preciso validar essas coisinhas. Mas o nome do atributo? Esse sim.

> A propósito, nos meus testes o `mutationRecord.oldValue` estava sempre nulo
> 🤷‍♂️. Na documentação desse atributo em específico na
> [MDN](https://developer.mozilla.org/en-US/docs/Web/API/MutationRecord/oldValue),
> ele lista que precisa passar `{ attributes: true, attributeOldValue: true }`
> como argumento de `observer.observe`.

Então, aqui, eu preciso simplesmente filtrar aquilo que eu desejo. Poderia
fazer `mutationList.filter`, mas meu instinto primordial me fez fazer um loop
clássico:

```js
for (const mutation of mutationList) {
    // precisamos ter certeza que é o atributo "data-sorted"
    if (mutation.attributeName != "data-sorted") {
        continue;
    }
    const tag = mutation.target;
    const sortCondition = tag.dataset.sorted;

    // ...
}
```

Muito bem, já selecionei apenas as mutações do target correto (que não preciso
recuperar do DOM, já está ali), e cuja alteração foi no atributo correto. Agora
preciso aplicar a ordenação. Mas, como eu posso fazer isso?

Primeiro, porque não custa nada, podemos validar que o `sortCondition` está
válido. Então, extrair as informações do tipo da ordenação e o sentido:

```js
// verificando se tá válido mesmo
if (!validSortStuff(sortCondition)) {
    console.log(`ordenação inválida [${sortCondition}], ignorando`);
    continue;
}
const sortStuff = sortStuffAsObject(sortCondition);
```

Em cima do `sortStuff` eu consigo elaborar uma função para ordenar as tags. E,
bem, já que os dados estão dentro das tags, que tal ter uma função para extrair
o atributo a ser ordenado em cima de `sortStuff.type` e definir o sentido da
ordenação através do `sortStuff.arrow`. Em cima disso, posso definir uma forma
de ordenação como uma função de alta ordem:

```js
const extractor = extractSortingAttribute(sortStuff.type);
const comparor = extractComparor(sortStuff.arrow);
const sortFunction = (a, b) => {
    const aAttr = extractor(a);
    const bAttr = extractor(b);
    return comparor(aAttr, bAttr);
};
```

Ok, agora sabemos como ordenar (por mais que o como vou extrair o valor da tag
esteja abstraído agora, e por mais que o detalhe do sentido da ordenação esteja
também abstraído), precisamos saber **o que** ordenar.

No caso, baseado no `myGrandGlobal[0].target`, o melhor jeito seria pegando
`myGrandGlobal[0].target.children`. Esse método retorna os nodos filhos do HTML
bem bonitinho, já `myGrandGlobal[0].target.childNodes` retorna até detalhes
como os espaços em branco do HTML entre o `<ul>` e o primeiro `<li>`, ou entre
o `</li>` e o `<li>` seguinte, informações não necessárias. Portanto, pego o
`tag.children`. Isso retorna um objeto do tipo `HTMLCollection`, que posso
trivialmente transformar em um `Array` usando `Array.from`. Agora, com um
`Array`, eu posso simplesmente aplicar o `.sort` e ser feliz!

Com as coisas ordenadas, eu posso seguir o mesmo raciocínio aplicado ao
randomizar a aparição dos podcasts em
[Refatorando página de podcasts]({% post_url 2025/2025-03-07-refactor-podcasts %}):
remover todos os elementos e depois readicionar eles como filhos do nó:

```js
const childrenArray = Array.from(tag.children);

childrenArray.sort(sortFunction);

for (const child of childrenArray) {
    tag.removeChild(child)
}
for (const child of childrenArray) {
    tag.appendChild(child)
}
```

Muito bem, juntando tudo eu tenho isso:

```js
const observer = new MutationObserver((mutationList, observer) => {
    for (const mutation of mutationList) {
        // precisamos ter certeza que é o atributo "data-sorted"
        if (mutation.attributeName != "data-sorted") {
            continue;
        }
        const tag = mutation.target;
        const sortCondition = tag.dataset.sorted;

        // verificando se tá válido mesmo
        if (!validSortStuff(sortCondition)) {
            console.log(`ordenação inválida [${sortCondition}], ignorando`);
            continue;
        }
        const sortStuff = sortStuffAsObject(sortCondition);

        const extractor = extractSortingAttribute(sortStuff.type);
        const comparor = extractComparor(sortStuff.arrow);
        const sortFunction = (a, b) => {
            const aAttr = extractor(a);
            const bAttr = extractor(b);
            return comparor(aAttr, bAttr);
        };

        const childrenArray = Array.from(tag.children);

        childrenArray.sort(sortFunction);

        for (const child of childrenArray) {
            tag.removeChild(child)
        }
        for (const child of childrenArray) {
            tag.appendChild(child)
        }
    }
})

observer.observe(document.getElementById("tag-list"), { attributes: true })
```

## Esclhendo o sentido

Vamos ordenar agora pelo nome da tag. Vou ignorar completamente o como o
atributo é resgatado, mas assumindo que eles vão estar resgatador. Então,
basicamente vou assumir que eu tenho o atributo, que vou estar comparando ele,
e que eu preciso definir, com a ajuda do `arrow`, definir como organizar.

Vamos fazer um operador de ordenação natural?

```js
const baseCmp = (a, b) => {
    if (a < b) {
        return -1;
    } else if (a > b) {
        return +1;
    }
    return 0;
}
```

Se eu quiser ordenar no sentido contrário? Bem, eu inverto a ordem dos
argumentos e envio para o ordenador base, a ordenação natural:

```js
(a, b) => baseCmp(b, a)
```

Agora, para saber se uso a ordenação natural ou a ordenação natural invertida,
eu preciso verificar o `arrow` que é passado. Se for crescente, eu uso o
`baseCmp`. Se for decrescente, uso o invertido:

```js
function extractComparor(arrow) {
    const baseCmp = (a, b) => {
        if (a < b) {
            return -1;
        } else if (a > b) {
            return +1;
        }
        return 0;
    };
    if (arrow == "↑") {
        return baseCmp
    }
    return (a, b) => baseCmp(b, a);
}
```

## Extraindo o atributo

Basicamente, eu preciso receber uma tag HTML e puxar um atributo dentro do
`dataset`. Bem, e eu ainda preciso extrair de modo que eles sejam ordenados
naturalmente, o que significa que eu preciso diferenciar `1` de `"1"` (afinal,
`10 > 2`, mas `"10" < "2"`).

Eu tenho dois casos para isso:

- `alpha`: extrai a propriedade `name`
- `num`: extrai a propriedade `size`, como um número

Então, posso simplesmente extrair dessa maneira:

```js
function extractSortingAttribute(type) {
    if (type == "alpha") {
        return (n) => n.dataset.name;
    }
    return (n) => Number(n.dataset.size)
}
```

# Resultado final

Bem, esse é o design inicial. Você pode encontrar ele
[nas tags com beta ligado]({{ "/tags?beta=true" | prepend: site.baseurl }}),
pelo menos até uma versão mais final da interface. No futuro, independente de
como vai ficar, os princípios vão se manter:

- pegar o `tag-list`
- observar quando o `data-sorted` for alterado
- extrair as propriedade desejadas dos list items
- ordenar
- reinserir o conjunto ordenado em `tag-list`

Detalhes podem mudar? Podem. Talvez um link com um query param para
compartilhar com os outros como que fica a listagem? (Vide 
[Manipulando query string para melhor permitir compartilhar uma página carregada dinamicamente]({% post_url 2025/2025-01-23-genomics-daily-query %})).
Provável.

Também posso eventualmente mudar o nome dos atributos para resgatar mais
diretamente do datase, ou mesmo deixar de usar setas literais e passar a usar
algo como `ascending` ou `descending`.

Mas o coração vai ficar aí, só esperando para consolidar e sair do beta.

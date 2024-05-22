---
layout: post
title: "Post facilmente citável"
author: "Jefferson Quesado"
tags: meta javascript localstorage frontend clipboard
base-assets: "/assets/citable/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Na alma do post
[Deixando a pipeline visível para acompanhar deploy do blog]({% post_url 2024-05-19-pipeline-visible %}),
achei que estava deveras complicado citar meus próprios textos. Então,
decidi fazer um botão que aparece em uma situação para permitir copiar em markdown
o esquema tão logo possível.

O modelo mais ou menos que uso em markdown para citar um post é:

{% raw %}
```md
[{{ page.title }}](% post_url {{ page.url | slugify }} %})
```
{% endraw %}

Então, se eu tivesse um jeito de passar o título e o slug da página para uma função,
eu teria condição de gerar a string acima. Algo como:

{% raw %}
```js
function citation2clipboard(title, slug) {
    alert(`[${title}]({% post_url ${slug} %})`)
}
```
{% endraw %}

# A função de copiar

Para copiar no clipboard, [as fontes que eu tinha](https://stackoverflow.com/a/30810322/4438007)
falavam para usar a
[API Clipboard](https://developer.mozilla.org/en-US/docs/Web/API/Clipboard).
Ao brincar com ela no console, qual minha surpresa ao ler esta  mensagem:

```none
Uncaught (in promise) DOMException: Clipboard write was blocked due to lack of user activation.
    <anonymous> debugger eval code:2
    <anonymous> debugger eval code:3
```

Isso significa que foi sucesso chamar a API, mas eu precisaria de mais robustez
para poder usar. Então deixei ligada a uma função de `onClick` e pronto,
foi possível. Vale lembrar que tanto a leitura do que já está no clipboard como
a opção de escrever no clipboard são assíncronas.

Ficou assim o código:

{% raw %}
```js
async function citation2clipboard(title, slug) {
    try {
        await navigator.clipboard.writeText(`[${title}]({% post_url ${slug} %})`)
        console.log("citação copiada")
    } catch (e) {
        console.log("erro ocorreu")
    }
}
```
{% endraw %}

# O mecanismo de habilitar

Eu escolhi para habilitar o botão o `localStorage`. No caso, se o valor associado
a `computaria-cite` for `"true"`. Coloquei para a página observar quando houver mudanças
nessa chave pelo storage de outra aba aberta, a aba em segundo plano irá avaliar isso e irá
se adaptar.

Clica nos botões abaixo para inserir/remover o valor no `localStorage`. A caixa de texto contém o valor
atual que está associado a essa chave.

<button onClick="inserirCite()">Inserir computaria-cite</button>
<button onClick="removerCite()">Remover computaria-cite</button>
<textarea id="garbage-place" disabled="true" cols="80" rows="6" placeholder="(sem valor...)">
</textarea>

<script>
    {
        const atualizarGarbagePlace = (txt) => {
            const txtSanitized = !!txt? txt: ""
            document.getElementById("garbage-place").value = txtSanitized;
        }

        window.addEventListener("storage", event => {
            if (event.key == "computaria-cite" || !event.key) {
                atualizarGarbagePlace(event.newValue);
                console.log({
                    value: event.value,
                    newValue: event.newValue,
                    oldValue: event.oldValue
                })
            }
        });

        function inserirCite() {
            localStorage.setItem("computaria-cite", "true")
            atualizarGarbagePlace("true")
            enableOrDisableCitationCopier()
        }

        function removerCite() {
            localStorage.removeItem("computaria-cite")
            atualizarGarbagePlace()
            enableOrDisableCitationCopier()
        }

        atualizarGarbagePlace(localStorage.getItem("computaria-cite"))
    }
</script>

A grosso modo, faze-se um `localStorage.getItem("computaria-cite") === "true"` e,
dependendo do valor dessa comparação, podemos colocar o ícone de copiar como
visível (`display: block`) ou como não-visível (`display: none`).

Os eventos relativos ao armazenamento possuem a chave `storage`, então para
adicionar um evento de armazenamento basta fazer:

```js
window.addEventListener("storage", event => {
    if (event.key == "computaria-cite" || !event.key) {
        algumaAcao(event.newValue);
    }
});
```

Note que `event.key` carrega a chave do armazenamento alterado **OU**
nulo caso o `localStorage` tenha sido limpo de todas os seus valores:
`localStorage.clear()`.

Para os casos em que existe a chave, no caso de `event.newValue` ser nulo aconteceu
a remoção do valor, no caso de `event.oldValue` ser nulo aconteceu a
inserção do valor e caso ambos sejam não nulos aconteceu uma atualização.

Não existe `event.value`, e eu descobri isso a duras penas. Adicionei o
seguinte para verificar as propriedades de `event`:

```js
console.log({
    value: event.value,
    newValue: event.newValue,
    oldValue: event.oldValue
})
```

# O esqueleto no layout

Tal qual o esquema escolhido em [deixando a pipeline visível para
acompanhar deploy do blog]({% post_url 2024-05-19-pipeline-visible %}),
escolhi usar o `defer` em um script. Para habilitar corretamente o
funcionamento do script, precisei usar um elemento no DOM de ID `citationCopier`.
É o suficiente para o meu caso, pois a partir daí eu consigo manipular
ele de acordo com o que eu preciso.

Usei o ícone disponível em [`https://uxwing.com/copy-icon/`](https://uxwing.com/copy-icon/)
(livre para uso pessoal e comercial, atribuição não necessária) para servir de "copiar".
Coloquei dentro de [`/_layout/post.html`]({{ site.repository.blob_root}}/_layout/post.html)
um botão com o ícone e o script para gerenciar isso, e só:

{% raw %}
```html
<script defer src="{{ "/js/citation.js" | prepend: site.baseurl }}">
</script>

<button id="citationCopier" style="display: none;" class="icon" onclick="citation2clipboard('{{ page.title }}', '{{ page.url | slugify }}')">{% include uxwing-copy-icon.svg %}</button>
```
{% endraw %}

A interface ficou devendo um bocado, mas o botão ali e a mensagem no console já
são o suficiente para mim.

Como eu não quero que `citation.js` rode o Liquid e faça suas indevidas
expansões, eu poderia por tudo dentro de um bloco de `raw` eu simplesmente
não adicionar o frontmatter. Optei por hora na segunda opção.

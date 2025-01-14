---
layout: post
title: "Deixando a pipeline visível para acompanhar deploy do blog"
author: "Jefferson Quesado"
tags: meta js frontend jekyll
base-assets: "/assets/pipeline-visible/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Uma das coisas que me aperreia no Computaria é não conseguir acompanhar
o deploy pelo próprio blog. Então, já que isso me incomoda, por que não
resolver?

# O pipeline

Atualmente existem 2 maneiras para saber se o deploy está rodando:

- abrir o repositório na página de
  [jobs]({{ site.repository.base }}/-/jobs)/[pipelines]({{ site.repository.base }}/-/pipelines)
  e ver o último em execução
- abrir no repositório e scrollar pro [`README.md`]({{ site.repository.base }})

Ambas as soluções não me parecem ótimas. Gostaria de algo mais leve no próprio Computaria.

# A ideia

Após uma breve consulta com [Kauê](https://twitter.com/rkauefraga) resolvi seguir a dica
dele: por no `/about`.

No primeiro experimento:

![Como ficou a badge na página sobre]({{ page.base-assets | append: "prev.png" | relative_url }})

Nah, ficou feio. Já sei que não quero por padrão isso aparecendo. Mas para trazer a informação
está suficiente. Preciso apenas esconder o que é feio, e deixar disponível mesmo que feio
se pedido explicitamente.

## Prova de conceito: trava exceto especificado

Bem, a primeira coisa a se fazer é saber se devemos tomar alguma ação. Para tal, foi definido
como API a presença do query param `status` com o valor `true`.

Para pegar a URL, usei [`window.location`](https://developer.mozilla.org/en-US/docs/Web/API/Window/location).
Dentro do objeto de [`Location`](https://developer.mozilla.org/en-US/docs/Web/API/Location)
tem o campo [`search`](https://developer.mozilla.org/en-US/docs/Web/API/Location/search), que serve
justamente para manter os query params usados para acessar a URL específica.

Por exemplo, para `http://localhost:4000/blog/about?q=1` o valor de `window.location.search`
é `?q=1`. Para facilitar lidar com o conteúdo de dentro dos query params, tem o objeto
do tipo [`URLSearchParams`](https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams/).
Até onde pude perceber da documentação, para instanciar `URLSearchParams`, eu preciso da query
string porém sem o `?` do prefixo. Consigo alcançar isso com `window.location.search.substring(1)`.

Agora, com esse objeto em mãos, consigo simplesmente consultar o valor de algum query
param que eu desejar:

```js
const queryParams = new URLSearchParams(window.location.search.substring(1));

if (queryParams.get("status") === "true") {
    console.log("oba, vamos exibir o pipeline!")
} else {
    console.log("nops, não vamos exibir nada")
}
```

Com isso em mãos, preciso tomar a ação de exibir o badge de pipeline. Por uma questão de facilidade,
resolvi colocar como um trecho de HTML incluível:
[`_includes/pipeline.html`]({{ site.repository.blob_root }}/_includes/pipeline.html).
Assim, tenho um HTML livre para poder manipular como eu bem entender.

No começo, ele simplesmente era uma `<div>` invisível:

```html
<div style="display: none" id="pipeline">
</div>
```

Para importar, no [`/about`]({{ "/about/" | prepend: site.baseurl }}) só precisei colocar
{% raw %}`{%include pipeline.html%}`{% endraw %} no começo do arquivo, o Jekyll se encarregou
de montar tudo certo.

Ok, vamos por o script para detectar se deveria ou não exibir a tag:

```html
<script>
    const queryParams = new URLSearchParams(window.location.search.substring(1));

    if (queryParams.get("status") === "true") {
        console.log("oba, vamos exibir o pipeline!")
    } else {
        console.log("nops, não vamos exibir nada")
    }
</script>
<div style="display: none" id="pipeline">
</div>
```

So far, so good. Agora, vamos mudar a exibição para `display: block` caso seja para
exibir o pipeline, ou sumir logo de uma vez com a `<div>`. Pelo console da web,
bastaria fazer algo nesse esquema:

```js
const pipeline = document.getElementById("pipeline")

if (...) {
    pipeline.style.display = "block"
} else {
    pipeline.remove()
}
```

Colocando no fragmento de HTML:

```html
<script>
    const queryParams = new URLSearchParams(window.location.search.substring(1));
    const pipeline = document.getElementById("pipeline")

    if (queryParams.get("status") === "true") {
        pipeline.style.display = "block"
    } else {
        pipeline.remove()
    }
</script>
<div style="display: none" id="pipeline">
</div>
```

E... falhou. Por quê? Porque no momento que a função rodar ainda não tem definido quem é o elemento
com id `pipeline`. Então preciso mudar o ciclo de vida para rodar o script apenas quando a página
for carregada. Basta colocar o `<script defer>`, certo? Bem, não. Porque `defer` não funciona bem
com inline, apenas com arquivo de source explícito.
[Veja a documentação](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script#defer).

Ou seja, precisei colocar o arquivo JavaScript explicitamente para o Computaria. Como a priori
tudo que está solto na pasta do blog é colocado como asset disponível para o Jekyll publicar,
criei o [`js/pipeline-loader.js`]({{ site.repository.blob_root }}/js/pipeline-loader.js):

{% raw %}
```html
<script src="{{ "/js/pipeline-loader.js" | prepend: site.baseurl }}" defer>
</script>
<div style="display: none" id="pipeline">
</div>
```
{% endraw %}

E no script:

```js
const queryParams = new URLSearchParams(window.location.search.substring(1));
const pipeline = document.getElementById("pipeline")

if (queryParams.get("status") === "true") {
    pipeline.style.display = "block"
} else {
    pipeline.remove()
}
```

Ótimo, vamos fazer algo útil e colocar a imagem? Para criar dinamicamente um elemento, só
usar o `document.createElement`. Então coloco a URL da badge:

{% raw %}
```js
const queryParams = new URLSearchParams(window.location.search.substring(1));
const pipeline = document.getElementById("pipeline")

if (queryParams.get("status") === "true") {
    pipeline.style.display = "block"

    const pipelineImg = document.createElement("img")
    pipelineImg.src = "{{site.repository.base}}/badges/master/pipeline.svg"

    pipeline.appendChild(pipelineImg)
} else {
    pipeline.remove()
}
```
{% endraw %}

Só que mostrou uma imagem quebrada... hmmm, qual a mensagem exibida no console?
{% raw %}
```
GET http://localhost:4000/blog/about/{{site.repository.base}}/badges/master/pipeline.svg [HTTP/1.1 404 Not Found 4ms]
```
{% endraw %}

Estranho, ele deveria ter pegue a URL bonitinha do rpositório? Ah, percebi. Ele não processou nada Liquid.
Para lidar com isso resolvi seguir o exemplo em [`css/main.scss`]({{site.repository.blob_root}}/css/main.scss), um frontmatter vazio.

{% raw %}
```js
---
# frontmatter vazio para fazer o parse do liquid
---

const queryParams = new URLSearchParams(window.location.search.substring(1));
const pipeline = document.getElementById("pipeline")

if (queryParams.get("status") === "true") {
    pipeline.style.display = "block"

    const pipelineImg = document.createElement("img")
    pipelineImg.src = "{{site.repository.base}}/badges/master/pipeline.svg"

    pipeline.appendChild(pipelineImg)
} else {
    pipeline.remove()
}
```
{% endraw %}

Isso aparece uma mensagem de erro porque frontmatter não é javascript, e o erro é mostrado
no primeiro `const`. Como isso me incomoda, o jeito mais direto que eu pensei para lidar com isso
foi criando um "erro inóquo" mais cedo. Adicionei um `;` logo após o frontmatter:

{% raw %}
```js
---
# frontmatter vazio para fazer o parse do liquid
---
;

const queryParams = new URLSearchParams(window.location.search.substring(1));
const pipeline = document.getElementById("pipeline")

if (queryParams.get("status") === "true") {
    pipeline.style.display = "block"

    const pipelineImg = document.createElement("img")
    pipelineImg.src = "{{site.repository.base}}/badges/master/pipeline.svg"

    pipeline.appendChild(pipelineImg)
} else {
    pipeline.remove()
}
```
{% endraw %}

### Annoyances...

Ao continuar nos testes, percebi que constantemente aparecia na aba de network um
[`308`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/308). Mas, por que ele
aparecia? Bem, porque ao fazer a expansão do Liquid acabava com dupla barra antes de
`badges`.

Eu obtia originalmente isso:

- [`https://gitlab.com/computaria/blog//badges/master/pipeline.svg`](https://gitlab.com/computaria/blog//badges/master/pipeline.svg)

Com redirecionamento para:

- [`https://gitlab.com/computaria/blog/badges/master/pipeline.svg`](https://gitlab.com/computaria/blog/badges/master/pipeline.svg)

E isso começou a me incomodar conforme eu fazia análises se estava usando cache ou não.
Para resolver isso eu deveria me livrar da dupla barra. Eu poderia simplesmente me livrar
dela não colocar a barra logo depois do valor Liquid sendo expandida, porque afinal
eu poderia saber a priori que a string de {% raw %}`{{site.repository.base}}`{% endraw %}
terminava com `/`. Mas, por via das dúvidas, não custa nada realisticamente colocar
aquela barra antes de `/badges/master/pipeline.svg`, inclusive é até um indicador
para mim mesmo como leitor.

Mas, já que eu não quero me confiar no conhecimento prévio da existência ou não
dessa barra, eu tinha duas opções para isso:

- tratar a nível de expansão Liquid para remover a barra terminal
- tratar a nível de javascript a criação dessa string

O lado JavaScript me pareceu mais fácil. Então só substituir `//` por `/`, correto?
Hmmm, não. Porque o protocolo aparece antes de `://`, então só fazer essa substituição
grosseira iria resultar na url começar assim: `https:/computaria.gitlab.io`. Para
contornar isso então teu faço a seguinte substituição:

```js
const url = "{{ liquid.expansible.value }}/lalala".replaceAll(/([^:])\/\//, "$1/")
```

Destrinchando:

- no lugar da substituição, se coloca o que foi encontrado no "primeiro grupo" seguido de uma barra
- a regex combina: qualquer coisa que não `:` (em um grupo), barra, barra

Com essa mudança, `https://` não tem _match_ com `([^:])\/\/`, porém todas as outras ocorrências de `//`
no path tem match perfeito, pois não estarão na frente de um `:`. Para ser mais estrito poderia trabalhar
para evitar que o match ocorra em query param/fragmento, mas me pareceu overkill demais.

## Prova de conceito: carregamento sem cache

Ok, definido o detalhe de onde situar e mecanismo de trava, precisamos de mecanismo de recarga.
Primeira tentativa: simplesmente criar um novo elemento de imagem. Mas, ainda assim, como?
O ideal seria "após algum tempo". Então, isso me dá duas opções, bem dizer:

- [`setTimeout`](https://developer.mozilla.org/en-US/docs/Web/API/setTimeout)
- [`setInterval`](https://developer.mozilla.org/en-US/docs/Web/API/setInterval)

Ok, bora lá com o que isso faz? `setTimeout` recebe um comando que será executado
após um intervalo de tempo E também o dado intervalo. Ele te devolve um ID que você
pode remover usando
[`clearTimeout`](https://developer.mozilla.org/en-US/docs/Web/API/clearTimeout).
Para repetir a chamada, o `setTimeout` precisa ser chamado de novo no final.

`setInterval` é quase a mesma coisa, só que ele sempre executará o comando
após o intervalo de tempo. O retorno deveria ser um ID que você chamaria
[`clearInterval`](https://developer.mozilla.org/en-US/docs/Web/API/clearInterval)
para remover, mas pela documentação funciona com  `clearTimeout` também
(por via das dúvidas, não confie, use o de semântica correta).

### Usando setTimeout

Vamos criar uma chamada em laço com `setTimeout`? Que tal imprimir 5
vezes a palavra `abóbora` em um campo de texto?
Vou colocar uma [`textarea`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/textarea)
para esse experimento:

```html
<textarea id="garbage-place" disabled="true" cols="80" rows="6" placeholder="(ainda sem valor...)">
</textarea>
```

Importante o `disable="true"` para impedir interação humana direta. Fica pianinho, leitor, vou
te dar botões para interagir aqui.

Bem, hora de adicionar interação a caixa de texto... Vamos definir a função para adicionar
um contador que imprime `abóbora`, uma ação para parar esses timeouts, e finalmente um
para limpar a caixa de texto. Pelo menos as ações são claras:

```html
<button onClick="iniciaTimeout()">Inicia timeout</button>
<button onClick="paraTimeout()">Para timeout</button>
<button onClick="clearGarbagePlace()">Limpa o place abaixo</button>
```

Ok, tenho 3 funções então que eu gostaria que fossem alcaançáveis
pelo HTML. E elas dividem (mesmo que de maneira muito leve) um estado.
Eu sou maníaco por esconder as coisas, então não quero que esse
estado esteja visível fora da tag `<script>`.

A minha solução mais óbvia é deixar debaixo de um bloco, assim,
ao sair do bloco, as variáveis lá dentro serão invisíveis fora:

```js
{
    let aboboraId = null;
}
```

Tá, mas como deixar as funções visíveis? Bem, experimentando encontrei uma
maneira: `function` escapa do escopo. E como variáveis local não exptrapolam
os limites do bloco, eu ainda posso colocar umas funções auxiliares dentro
do bloco de modo que elas não tem significado lá fora. Algo assim:

```js
{
    // arrow functions não escapam escopo, porque são variáveis
    const sanitizeText = text => text ?? "";
    const findGarbagePlace = () => document.getElementById("garbage-place");

    const appendGarbagePlace = (text) => {
        const gp = findGarbagePlace();
        gp.value += sanitizeText(text);
    }

    let aboboraId = null;

    // functions escapam escopo
    function iniciaTimeout() {
        // yep, por hora isto é fake, hehe
        if (aboboraId) {
            paraTimeout(aboboraId)
        }
        clearGarbagePlace();
        appendGarbagePlace("abobora\n")
    }

    function paraTimeout() {
        if (aboboraId) {
            clearTimeout(aboboraId);
            aboboraId = null; // limpando
        }
    }

    function clearGarbagePlace() {
        const gp = findGarbagePlace();
        gp.value = "";
    }
}
```

Beleza, agora eu preciso lidar com chamadas de timeout. Minha ideia é executar um passo
e, ao concluir esse passo, cadastrar o próximo timeout, chamando o mesmo passo. E só
para não ficar eterno limitar esse passo a poucas vezes.

Então, se não tivesse a questão do timeout, como seria? Uma chamada recursiva:

```js
function step(cnt) {
    if (cnt == 0) {
        return;
    }
    appendGarbagePlace(`abobora ${cnt}\n`) // o cnt é para dar a sensação de avanço
    step(cnt - 1)
}
```

Parece bom, e para adicionar o timeout? Bem, dentro do corpo do passo,
então chamar `step` é setar o timeout. Para um bom timeout, preciso do tempo:

```js
function step(cnt, timeout) {
    setTimeout(() => {
        if (cnt == 0) {
            return;
        }
        appendGarbagePlace(`abobora ${cnt}\n`) // o cnt é para dar a sensação de avanço
        step(cnt - 1, timeout)
    }, timeout)
}
```

Ok, só falta guardar o identificador de timeout e estamos prontos. Coloco
esse step dentro da função pública exposta e estamos prontos:

```js
function iniciaTimeout() {
    if (aboboraId) {
        paraTimeout()
    }
    clearGarbagePlace();
    const stepAppendAbobora = (cntDown, timeout) => {
        aboboraId = setTimeout(() => {
            if (cntDown == 0) {
                aboboraId = null; // limpando
                return;
            }
            appendGarbagePlace(`abobora ${cntDown}\n`)
            stepAppendAbobora(cntDown - 1, timeout)
        }, timeout);
    }

    stepAppendAbobora(5, 200)
}
```

Pronto, temos espaço para diversão agora:

<script>
{
    // arrow functions não escapam escopo, porque são variáveis
    const sanitizeText = text => text ?? "";
    const findGarbagePlace = () => document.getElementById("garbage-place");

    const appendGarbagePlace = (text) => {
        const gp = findGarbagePlace();
        gp.value += sanitizeText(text);
    }

    let aboboraId = null;

    // functions escapam escopo
    function iniciaTimeout() {
        if (aboboraId) {
            paraTimeout()
        }
        clearGarbagePlace();
        const stepAppendAbobora = (cntDown, timeout) => {
            aboboraId = setTimeout(() => {
                if (cntDown == 0) {
                    aboboraId = null; // limpando
                    return;
                }
                appendGarbagePlace(`abobora ${cntDown}\n`)
                stepAppendAbobora(cntDown - 1, timeout)
            }, timeout);
        }

        stepAppendAbobora(5, 200)
    }

    function paraTimeout() {
        if (aboboraId) {
            clearTimeout(aboboraId);
            aboboraId = null; // limpando
        }
    }

    function clearGarbagePlace() {
        const gp = findGarbagePlace();
        gp.value = "";
    }
}
</script>

<button onClick="iniciaTimeout()">Inicia timeout</button>
<button onClick="paraTimeout()">Para timeout</button>
<button onClick="clearGarbagePlace()">Limpa o place abaixo</button>
<textarea id="garbage-place" disabled="true" cols="80" rows="6" placeholder="(ainda sem valor...)">
</textarea>

### Usando setInterval

O uso do `setInterval` é bem similar, mas o passo de "chamar novamente" é
implícito. Se eu quero parar o laço, preciso explicitamente cancelar o
`setInterval` cadastrado.

Bem, que tal começar igual ao exemplo acima? Só que com o ID da área de
rascunho diferente:

```html
<button onClick="iniciaInterval()">Inicia interval</button>
<button onClick="paraInterval()">Para interval</button>
<button onClick="clearGarbagePlace2()">Limpa o place abaixo</button>

<textarea id="garbage-place2" disabled="true" cols="80" rows="6" placeholder="(ainda sem valor...)">
</textarea>
```

O que vai mudar de fato vai ser a função de `iniciaInterval()`, ela
vai diferir bastante da `iniciaTimeout()`. Agora eu não posso me confiar
em chamdas recursivas para o step. Então, na função de entrada eu inicializo
uma variável interna que fará parte da clausura passada para `setInterval`.
Além disso, quando essa variável chegar em 0, eu removo o registro dela:

```js
function iniciaInterval() {
    if (aboboraId) {
        paraInterval()
    }
    clearGarbagePlace2();
    let cntDown = 5;
    aboboraId = setInterval(() => {
        if (cntDown == 0) {
            paraInterval();
            return
        }
        appendGarbagePlace(`abobora ${cntDown}\n`)
        cntDown -= 1;
    }, 200)
}
```


<script>
{
    // arrow functions não escapam escopo, porque são variáveis
    const sanitizeText = text => text ?? "";
    const findGarbagePlace = () => document.getElementById("garbage-place2");

    const appendGarbagePlace = (text) => {
        const gp = findGarbagePlace();
        gp.value += sanitizeText(text);
    }

    let aboboraId = null;

    // functions escapam escopo
    function iniciaInterval() {
        if (aboboraId) {
            paraTimeout(aboboraId)
        }
        clearGarbagePlace2();
        let cntDown = 5;
        aboboraId = setInterval(() => {
            if (cntDown == 0) {
                paraInterval();
                return
            }
            appendGarbagePlace(`abobora ${cntDown}\n`)
            cntDown -= 1;
        }, 200)
    }

    function paraInterval() {
        if (aboboraId) {
            clearInterval(aboboraId);
            aboboraId = null; // limpando
        }
    }

    function clearGarbagePlace2() {
        const gp = findGarbagePlace();
        gp.value = "";
    }
}
</script>

<button onClick="iniciaInterval()">Inicia interval</button>
<button onClick="paraInterval()">Para interval</button>
<button onClick="clearGarbagePlace2()">Limpa o place abaixo</button>

<textarea id="garbage-place2" disabled="true" cols="80" rows="6" placeholder="(ainda sem valor...)">
</textarea>

### Tentativas de recarregar

Com o mecanismo de tempo para repetição definido, agora é uma questão de definit como recarregar
a imagem. Primeiramente, analisar os cabeçalhos que o GitLab retorna ao buscar a badge:
[`{{site.repository.base}}/badges/master/pipeline.svg`]({{site.repository.base}}/badges/master/pipeline.svg):

```http
cache-control: private, no-store
cf-cache-status: MISS
expires: Fri, 01 Jan 1990 00:00:00 GMT
strict-transport-security: max-age=31536000
```

Comparando múltiplas etags de diversas requisições por via das dúvidas:

```http
W/"fb90979d9127d0ecad1fa7bd554426ed"
W/"fb90979d9127d0ecad1fa7bd554426ed"
W/"fb90979d9127d0ecad1fa7bd554426ed"
```

Bem, a etag foi sempre a mesma, indicando que é o mesmo recurso. O
[`cache-control: no-store`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
me indica fortemente que não é para armazenar o cache. O `expires` apontando para o passado
indica fortemente que a intenção era indicar que esse recurso não deveria ser considerado
para cache. Até onde se prove o contrário, o `cf-cache-status: MISS` apenas indicou que
não bateu no cache da Cloudflare.

Finalmente,
[`strict-transport-security`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security).
O que isso quer dizer? O que isso tem a ver com o recurso em si?

Bem, não tem a ver com o recurso sendo acessado. Mas é um indicador de que o site deve ser acessado
apenas com HTTPS.

Ok, tudo isso indica que a imagem não deve ser cacheada. Um F5 sempre ocasiona nela sendo baixada
novamente, como esperado. Isso para mim é um indicador muito forte de que se eu tiver problema
com cache, ele não estará no servidor nem na rede, mas sim alguma coisa a nível de browser-level.

Primeira tentativa: criar um novo elemento `img` e jogar o anterior fora.

Para comodidade, nada como ter uma função que retorna o elemento:

```js
const createPipelineImg = () => {
    const pipelineImg = document.createElement("img")
    pipelineImg.src = ...;
    return pipelineImg;
}
```

E no `setTimeout` eu preciso remover os filhos de `#pipeline` e inserir
a nova imagem. As opções que achei com ações a partir do pai são:

- [`removeChild`](https://developer.mozilla.org/en-US/docs/Web/API/Node/removeChild)
- [`replaceChild`](https://developer.mozilla.org/en-US/docs/Web/API/Node/replaceChild)
- [`replaceChildren`](https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceChildren)

Bem, `removeChild` e `replaceChild` envolvem conhecer guardar o elemento antigo para
pedir sua remoção. Já o `replaceChildren` não tem drama algum, só passa o novo elemento e bom:

```js
pipeline.replaceChildren(createPipelineImg())
```

só isso já faz a mágica. Então, como se comporta afinal?

![Imagem cacheada]({{ page.base-assets | append: "cached-badge.png" | relative_url }})

Criar a nova `img` não foi suficiente.

Outra alternativa que encontrei foi setar novamente o valor da variável. Com isso,
já não precisa ter a função que gera elementos idênticos, eu só vou "modificar"
a URL que a `img` aponta. E, bem, foi assim que eu descobri que um mesmo asset
utilizado em vários lugares da mesma página pode sofrer alguma espécie de caching...

Ok, e se a cada repetição for adicionado um `' '` no final da URL para tentar
enganar o GitLab? Bem, o gitlab percebeu que eu estava tramando...

E se for um `queryParam` passado com um argumento o iterador dele?

![Imagem não cacheada]({{ page.base-assets | append: "not-cached-badge.png" | relative_url }})

Mas, a que custo?

Ok, com isso fora de cogitação porque é uma gambiarra, vamos tentar dar um `fetch`? E depois
de dar o `fetch` pensar em como substituir a imagem?

{% raw %}

```js
fetch("{{site.repository.base}}/badges/master/pipeline.svg")
```

{% endraw %}

Hmm, erro, de CORS. E como eu não tenho controle sobre o GitLab,
o que mais posso fazer?

A tag `<img>` não tem reload, mas a tag `<iframe>` [aparentemente tem](https://stackoverflow.com/a/86771/4438007)...

Ok, novo experimento: criar um `/assets/pipeline.html` simplesmente com a tag
`img` e apontar pra ele de um iframe. Para a operação de forçar o reload usei
tal qual a resposta do Stack Overflow:

```js
const pipelineIFrame = document.createElement("iframe")

// povoa os valores adequados, enxerta no canto, etc...
// usando src="http://localhost:4000/assets/pipeline-badge.html


// para reload
pipelineIFrame.contentWindow.location.reload();
```

Para o HTML

E, _voi là_! Deu certo!

![Imagem não cacheada via subdocument]({{ page.base-assets | append: "not-cached-badge-iframe.png" | relative_url }})

Agora, questões de ajustes para deixar adequado:

- controle de parar/reiniciar o recarregar da badge
- no iframe: seguir as dicas do [Editando SVG na mão pra pedir café]({% post_url 2024-03-16-edita-svg-manualmente %})
  para lidar com iframe
- dentro do documento: remover margens do `body` para só ter espaço da badge

Fazendo esses ajustes, sai disso

![About com o iframe sem ajustes]({{ page.base-assets | append: "about-antes.png" | relative_url }})

pra isso

![About com o ajuste do iframe]({{ page.base-assets | append: "about-depois.png" | relative_url }})

Você pode conferir aqui os arquivos usados:

- [`/about.md`]({{ site.repository.blob_root}}/about.md)
- [`/_includes/pipeline.html`]({{ site.repository.blob_root}}/_includes/pipeline.html)
- [`/assets/pipeline-badge.html`]({{ site.repository.blob_root}}/assets/pipeline-badge.html)
- [`/js/pipeline-loader.js`]({{ site.repository.blob_root}}/js/pipeline-loader.js)
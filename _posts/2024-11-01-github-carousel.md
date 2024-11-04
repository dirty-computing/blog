---
layout: post
title: "Carrossel em markdown no GitHub"
author: "Jefferson Quesado"
tags: svg html github md bash css
base-assets: "/assets/github-carousel/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

> Baseado nesta [minha publicação no Twitter](https://x.com/jeffquesado/status/1599361918795333632)

Eu queria adicionar um carrossel de imagens em um `README.md` de
projeto no GitHub. Mas o componente de carrossel não é algo tão
trivial de se fazer. Então, como contornar?

# O carrossel

Normalmente carrossel se dá ao nome de um componente que tem
uma sequência de imagens e fica girando entre elas, até voltar
para o começo. Não há um componente nativo para ele em HTML.
Então, como fazer?

Uma alternativa é usar JS para esse fim (a parte Liquid será processada
para gerar o endereço definitivo dos assets):

{% raw %}

```html
<style>
    .hidden {
        display: none
    }
</style>
<script>
    function prepareCarousel(carouselRoot) {
        const children = carouselRoot.children
        let idx = 0
        setInterval(() => {
            const nextIdx = (idx + 1) % children.length
            children[idx].className = "hidden"
            children[nextIdx].className = ""
            idx = nextIdx
        }, 1000)
    }
    const tryAndRepeat = () => {
        const carousels = document.querySelectorAll(".carousel")
        if (carousels.length == 0) {
            setTimeout(tryAndRepeat, 200)
            return
        }
        for (const carousel of carousels) {
            prepareCarousel(carousel)
        }
    }
    tryAndRepeat()
</script>
<div class='carousel'>
    <img                src='{{ page.base-assets | append: "girassol-girl1.png" | relative_url }}' height='80' />
    <img class="hidden" src='{{ page.base-assets | append: "girassol-girl2.png" | relative_url }}' height='80' />
    <img class="hidden" src='{{ page.base-assets | append: "girassol-kisses.png" | relative_url }}' height='80' />
    <img class="hidden" src='{{ page.base-assets | append: "girassol-steampunk.png" | relative_url }}' height='80' />
    <img class="hidden" src='{{ page.base-assets | append: "girassol.png" | relative_url }}' height='80' />
</div>
```

{% endraw %}

<style>
    .hidden {
        display: none
    }
</style>
<script>
    function prepareCarousel(carouselRoot) {
        const children = carouselRoot.children
        let idx = 0
        setInterval(() => {
            const nextIdx = (idx + 1) % children.length
            children[idx].className = "hidden"
            children[nextIdx].className = ""
            idx = nextIdx
        }, 1000)
    }
    const tryAndRepeat = () => {
        const carousels = document.querySelectorAll(".carousel")
        if (carousels.length == 0) {
            setTimeout(tryAndRepeat, 200)
            return
        }
        for (const carousel of carousels) {
            prepareCarousel(carousel)
        }
    }
    tryAndRepeat()
</script>
<div class='carousel'>
    <img                src='{{ page.base-assets | append: "girassol-girl1.png" | relative_url }}' height='80' />
    <img class="hidden" src='{{ page.base-assets | append: "girassol-girl2.png" | relative_url }}' height='80' />
    <img class="hidden" src='{{ page.base-assets | append: "girassol-kisses.png" | relative_url }}' height='80' />
    <img class="hidden" src='{{ page.base-assets | append: "girassol-steampunk.png" | relative_url }}' height='80' />
    <img class="hidden" src='{{ page.base-assets | append: "girassol.png" | relative_url }}' height='80' />
</div>

Nessa implementação, estou usando um CSS para controlar
visibilidade dos itens e mantendo um índice de qual
foi a última coisa visível. Estou assumindo que tudo
dentro do carrossel são elementos que precisam ficar
girando. Também estou assumindo que só vou ter isso
de classe nesses elementos (vai, pressuposições
aceitáveis para um componente específico que não
irá ver os raios de sol, que estará para sempre
preso em uma única página).

A função que deixa tudo pronto é essa:

```js
function prepareCarousel(carouselRoot) {
    const children = carouselRoot.children
    let idx = 0
    setInterval(() => {
        const nextIdx = (idx + 1) % children.length
        children[idx].className = "hidden"
        children[nextIdx].className = ""
        idx = nextIdx
    }, 1000)
}
```

A cada janela de tempo eu determino qual será o próximo
elemento visível, então torno o elemento atual invisível
e só depois torno o seguinte visível. Após terminar essa
atribuição no atributo `class`, atualizamos o valor do
`idx` atual com o próximo que foi calculado. Pequena nota
para perceber que `nextIdx` já leva em consideraçãoa
possibilidade de se chegar no final da lista e precisar
loopar.

Note que eu poderia fazer assim, que estaria "certo":

```js
const nextIdx = idx + 1
children[idx % children.length].className = "hidden"
children[nextIdx % children.length].className = ""
idx = nextIdx
```

Só que isso pode levar a `idx` estourar, caindo no ponto
em que a precisão do ponto flutuante impeça a atualização
correta, pois em ponto flutuante `a + 1 == a` pode ser
verdade. Iria demorar um tempo absurdamente lobgo? Iria,
mas melhor garantir que isso nunca aconteça, nõa é mesmo?

Para detectar os elementos que eu queria como carrossel,
tentei uma abordagem para executar apenas ao estar carregado,
mas como não tenho acesso ao `<body onload='...'>` de maneira
trivial no blog, resolvi não seguir por esse caminho.

Após falhar de diversas maneiras a captura do evento de
carregamento da página, resolvi usar uma alterativa covarde:

- se eu não detectei os elementos do carrossel, tenta de novo
  daqui um tempinho
- se eu detectei os elementos do carrossel, para cada um deles
  chamar o `prepareCarousel` com esse elemento

Para fazer essa estratégia usei o `tryAndRepeat`. Ao ser invocado,
ele mesmo detecta se está faltando algo, então ele se cadastra
novamente para se invocar:

```js
const tryAndRepeat = () => {
    const carousels = document.querySelectorAll(".carousel")
    if (carousels.length == 0) {
        setTimeout(tryAndRepeat, 200)
        return
    }
    for (const carousel of carousels) {
        prepareCarousel(carousel)
    }
}
tryAndRepeat()
```

# Download dos PNGs

As imagens que estou usando foram geradas usando algumas
ferramentas de IA generativa de imagens, como MidJourney.
Eu as salvei dentro do repositório do
[Girassol](https://github.com/girassol-rb/girassol) (projeto
que no momento da escrita deste artigo está intocado desde a
concepção, 2 anos atrás). Para deixar este artigo auto-contido,
melhor deixar tudo ao meu dispor dentro do repositório do
blog do Computaria.

Então, para baixar as imagens, precisava iterar em cada imagem
do repositório original e baixar. Tradicionalmente se faz isso
com curl. Peguemos um exemplo de imagem:

[![Garota](https://raw.githubusercontent.com/girassol-rb/girassol/refs/heads/main/assets/girassol-girl1.png)](https://raw.githubusercontent.com/girassol-rb/girassol/refs/heads/main/assets/girassol-girl1.png)

A URL inteira dela é `https://raw.githubusercontent.com/girassol-rb/girassol/refs/heads/main/assets/girassol-girl1.png`.
Vamos analisar por partes?

Primeiro, o domínio é um lugar para indicar onde estão guardadas as coisas
_raw_ do GitHub. É bem padrão isso, qualquer arquivo que você pedir o link
para o objeto _raw_ ele dará algo lá dentro.

No path da URL, temos uma parte significativa aqui: `girassol-rb/girassol`.
Isso contém o identificador do repositório, no formato `OWNER/REPO`.

Após a indicação do repositório, temos `refs/heads/main`. Isso simplesmente
indica qual a referência do repositório que estamos usando. No caso específico
é um branch chamado `main`.

Finalmente, chegamos na última parte do path da URL: `assets/girassol-girl1.png`.
Essa parte indica o caminho do arquivo a partir da raiz do repositório.

```none
https://raw.githubusercontent.com/girassol-rb/girassol/refs/heads/main/assets/girassol-girl1.png
        \_______________________/\___________________/\______________/\________________________/
          domínio de coisas raw     identificador do    git-ref            path do arquivo
                                    repo, no formato    aqui é o branch
                                    OWNER/REPO          main
```

No meu caso específico, tudo que vou pegar vai ser dentro de `assets`,
então bastaria ter a lista com os nomes dos arquivos que eu poderia
iterar neles e passar pro curl. E é fácil obter essa lista:

- girassol-girl1.png
- girassol-girl2.png
- girassol-kisses.png
- girassol-steampunk.png
- girassol.png

Vamos testar o download?

```bash
#!/bin/bash

BASE_URL=https://raw.githubusercontent.com/girassol-rb/girassol/refs/heads/main/assets/

for img in girassol-girl1.png girassol-girl2.png girassol-kisses.png girassol-steampunk.png girassol.png; do
        echo $img
        curl -o $img $BASE_URL/$img
done
```

Hmmm, o VSCode disse que não conseguiu abrir o arquivo, por que será?
Abrindo com o VIM o arquivo...

```html
<a href="/girassol-rb/girassol/refs/heads/main/assets/girassol-girl1.png">Moved Permanently</a>.
```

Oops? Ok, se eu adicionar o `-L` o curl seguirá redirects, quem sabe seja só isso?
Vamos testar e...

Ok, era só isso mesmo. Agora, para onde ele estaria redirecionando? Vou pegar um único
exemplo e pedir para ele me mostrar mais sobre as interações, com `-i`:

```bash
> curl -i https://raw.githubusercontent.com/girassol-rb/girassol/refs/heads/main/assets/girassol-girl1.png
HTTP/2 200 
cache-control: max-age=300
content-security-policy: default-src 'none'; style-src 'unsafe-inline'; sandbox
content-type: image/png
etag: "XXXX"
strict-transport-security: max-age=31536000
x-content-type-options: nosniff
x-frame-options: deny
x-xss-protection: 1; mode=block
x-github-request-id: XXXX
accept-ranges: bytes
date: XXXX
via: 1.1 varnish
x-served-by: XXXX
x-cache: HIT
x-cache-hits: 0
x-timer: XXXX
vary: Authorization,Accept-Encoding,Origin
access-control-allow-origin: *
cross-origin-resource-policy: cross-origin
x-fastly-request-id: XXXX
expires: XXXX
source-age: 293
content-length: 1650809

Warning: Binary output can mess up your terminal. Use "--output -" to tell 
Warning: curl to output it to your terminal anyway, or consider "--output 
Warning: <FILE>" to save to a file.
```

Hmmm, nada demais. O que será que tá acontecendo? Vou tentar reproduzir o resultado
num comando. Vou usar a característica de criar variáveis de ambiente específicas de um
comando em bash, colocando no começo da linha todas as variáveis que eu quero dar
valor para o comando específico, e depois de criar essas variáveis executar o comando.

Como o comando que eu quero usar vai usar essas variáveis, então eu preciso delegar
para o comando em questão fazer a expansão dessas variáveis em texto, caso contrário,
caso eu tentasse expandir o valor da variável de ambiente na linha que estou declarando,
como a expansão é feita antes da execução do comando, eu estaria com o valor errado
desses valores. Para executar um comando que execute um comando, nada como o `bash -c CMD`,
assim eu posso passar `bash -c 'echo $LALALA'` e a expansão `$LALALA` será feita pelo
comando `bash` como ele começar a executar.

```bash
> BASE_URL=https://raw.githubusercontent.com/girassol-rb/girassol/refs/heads/main/assets/ img=girassol-girl1.png bash -c 'curl -i $BASE_URL/$img'
HTTP/2 301 
content-type: text/html; charset=utf-8
location: /girassol-rb/girassol/refs/heads/main/assets/girassol-girl1.png
x-github-request-id: XXXX
accept-ranges: bytes
date: XXXX
via: 1.1 varnish
x-served-by: XXXX
x-cache: HIT
x-cache-hits: 1
x-timer: XXXX
access-control-allow-origin: *
cross-origin-resource-policy: cross-origin
x-fastly-request-id: XXXX
expires: XXXX
source-age: 425
vary: Authorization,Accept-Encoding
content-length: 98

<a href="/girassol-rb/girassol/refs/heads/main/assets/girassol-girl1.png">Moved Permanently</a>.
```

Hmmm, aqui obtivemos o resultado que obtivemos ao usar o script que não seguia links.
Agora, por que será que usando as variáveis obtive o resultado, mas usando a URL
diretamente eu consegui baixar a imagem corretamente?

O uso de variáveis para fazer isso com certeza não é um fator pra isso,
pois o bash vai fazer a expansão de variável antes de executar o comando.
Então vamos focar na expansão de `$BASE_URL/$img`.

```bash
> BASE_URL=https://raw.githubusercontent.com/girassol-rb/girassol/refs/heads/main/assets/ img=girassol-girl1.png bash -c 'echo $BASE_URL/$img'   
https://raw.githubusercontent.com/girassol-rb/girassol/refs/heads/main/assets//girassol-girl1.png
```

Conseguiu ver o problema? Pois bem, como eu declarei a variável com um `/` no final,
e usei o texto `$BASE_URL/$img`, isso significou que eu coloquei uma barra a mais.
Portanto, estava gerando o nome do arquivo com duas barras ali, e o GitHub,
ao perceber isso, redirecionou de `/assets//girassol-girl1.png` para
`/assets/girassol-girl1.png`.

Para provar a hipótese, removi do script a barra no final de `BASE_URL` e o `-L` do curl.

E deu certo! O script para download se encontra
[aqui]({{ page.base-assets | prepend: site.repository.blob_root | append: "download-girassol.sh" }}).

# Limitações no GitHub

Bem, o GitHub limita as tags HTML que posso usar
para escrever markdown. Especificamente ele vai
impedir uso das tags `<script>` e `<style>`. Por
exemplo, usar o seguinte markdown em comentários
(que em tese passa pelo mesmo trecho de renderização
de um `README.md`):

```md
<style>
  .marm {
    background-color: pink !important;
  }
</style>
<script>
console.log("lala")
</script>

I like to <span class='marm'>MOVE IT</span>
```

Gerou isso daqui:

![Não renderizou as tags acima com a semântica HTML, mas
como se fossem texto plano]({{ page.base-assets | append: "forbidden-tags.png" | relative_url }})

Esse comportamento está mapeado na especificação do
GitHub Flavored Markdown, mais especificamente na
[seção 6.11, Disallowed Raw HTML (extension)](https://github.github.com/gfm/#disallowed-raw-html-extension-).

Com isso, não consigo usar o componente de carrossel criado
neste post.

Seria tão bom se eu pudesse usar alguma coisa que eu conseguisse
enganar as tags bloqueadas do GitHub sobre markdown...

# Surge uma esperança: SVG

Vendo [esta resposta no Stack Overflow](https://stackoverflow.com/a/66981634/4438007),
o pessoal já usava essa estratégia de se usar SVG para gerar a imagem desejada
e com isso exibir no GitHub.

Basicamente a ideia é fazer com um SVG oco, contendo uma tag `<foreignObject>`
e dentro dela um carrossel feito em HTML/CSS puros. Então, com esse SVG em mãos,
podemos mencionar ele como uma imagem dentro do repositório do GitHub.

Então, vamos fazer a animação em CSS?

## Criando uma transição com CSS

Na [própria resposta](https://stackoverflow.com/a/66981634/4438007) o autor já
dá um caminho muito importate: animações e keyframes. Uma alternativa para usar
imagem no CSS é definir a imagem como sendo um `background-image`, e usar uma
`<div>` de tamanho fixo para caber a imagem.

Para a parte da animação, preciso definir os `@keyframes`. Como vai ser um loop
em cima de diversas imagens, uma das maneiras de seguir é definir a porcentagem
de "andamento" da animação, casa porcengagem com uma imagem de fundo diferente:

```css
@keyframes carousel {
    0% {
        background-image: url("girassol.png");
    }
    25% {
        background-image: url("girassol-girl1.png");
    }
    50% {
        background-image: url("girassol-girl2.png");
    }
    75% {
        background-image: url("girassol-kisses.png");
    }
    100% {
        background-image: url("girassol-steampunk.png");
    }
}
```

E para o estilo que usa essa animação? Bem, eu quero que ela se repita
indefinidamente, que tenha uma duração de 10s (para não parecer muito
corrida a troca de imagens) e suave, igual para todas as imagens.
Portanto a animação vai ser `carousel 10s linear infinite`.

Além disso, copiei alguns atributos CSS cujo conteúdo não entendi
de verdade. `background-repeat: no-repeat` é para ter uma certeza,
e `background-image: url("girassol.png")` é um placeholder,
inclusive é a primeira imagem das animações no keyframe.
`background-size: contain` foi uma novidade para mim; basicamente,
ele garante que a imagem fique dentro dos limites do componente,
sem que ela seja esticada ou cortada para caber lá.
[MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/background-size#contain)
falando sobre o assunto.

```css
.girassol {
    margin: 0;
    height: 400px;
    aspect-ratio: 1 / 1;
    background-image: url("girassol.png");
    background-repeat: no-repeat;
    background-size: contain;
    animation: carousel 10s linear infinite;
}
```

Adaptando os links das URLs para poder usar `<iframe>` inline
(leia sobre o atributo [`srcdoc`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe#srcdoc))
e com isso eu tenho esse HTML:

<iframe height="450" width="450" srcdoc='
            <style>
                @keyframes carousel {
                    0% {
                        background-image: url("{{ page.base-assets | append: "girassol.png" | relative_url }}");
                    }
                    25% {
                        background-image: url("{{ page.base-assets | append: "girassol-girl1.png" | relative_url }}");
                    }
                    50% {
                        background-image: url("{{ page.base-assets | append: "girassol-girl2.png" | relative_url }}");
                    }
                    75% {
                        background-image: url("{{ page.base-assets | append: "girassol-kisses.png" | relative_url }}");
                    }
                    100% {
                        background-image: url("{{ page.base-assets | append: "girassol-steampunk.png" | relative_url }}");
                    }
                }

                .girassol {
                    margin: 0;
                    height: 400px;
                    aspect-ratio: 1 / 1;
                    background-image: url("{{ page.base-assets | append: "girassol.png" | relative_url }}");
                    background-repeat: no-repeat;
                    background-size: contain;
                    animation: carousel 10s linear infinite;
                }
            </style>
            <div class="girassol">
            </div>
    '>
</iframe>

Ok, estou satisfeito com o resultado.

## Embarcando HTML no SVG e o SVG no HTML

Vamos ver se funciona? Basicamente criei um SCG com view-box de 400x400,
começando do ponto (0,0).
[Clica aqui para abrir ele]({{ page.base-assets | append: "girassol-orig.svg" | relative_url }}).

Se eu fosse usar diretamente no markdown, fica assim (ajustando porque inline
ele não está no mesmo diretório do que as imagens):

```xml
<svg fill="none" viewBox="0 0 400 400" width="400" height="400" xmlns="http://www.w3.org/2000/svg">
    <foreignObject width="100%" height="100%">
        <div xmlns="http://www.w3.org/1999/xhtml">
            <style>
                @keyframes carousel {
                    0% {
                        background-image: url("{{ page.base-assets | append: "girassol.png" | relative_url }}");
                    }
                    25% {
                        background-image: url("{{ page.base-assets | append: "girassol-girl1.png" | relative_url }}");
                    }
                    50% {
                        background-image: url("{{ page.base-assets | append: "girassol-girl2.png" | relative_url }}");
                    }
                    75% {
                        background-image: url("{{ page.base-assets | append: "girassol-kisses.png" | relative_url }}");
                    }
                    100% {
                        background-image: url("{{ page.base-assets | append: "girassol-steampunk.png" | relative_url }}");
                    }
                }

                .girassol {
                    margin: 0;
                    height: 400px;
                    aspect-ratio: 1 / 1;
                    background-image: url("{{ page.base-assets | append: "girassol.png" | relative_url }}");
                    background-repeat: no-repeat;
                    background-size: contain;
                    animation: carousel 10s linear infinite;
                }
            </style>
            <div class="girassol">
            </div>
        </div>
    </foreignObject>
</svg>
```

<svg fill="none" viewBox="0 0 400 400" width="400" height="400" xmlns="http://www.w3.org/2000/svg">
    <foreignObject width="100%" height="100%">
        <div xmlns="http://www.w3.org/1999/xhtml">
            <style>
                @keyframes carousel {
                    0% {
                        background-image: url("{{ page.base-assets | append: "girassol.png" | relative_url }}");
                    }
                    25% {
                        background-image: url("{{ page.base-assets | append: "girassol-girl1.png" | relative_url }}");
                    }
                    50% {
                        background-image: url("{{ page.base-assets | append: "girassol-girl2.png" | relative_url }}");
                    }
                    75% {
                        background-image: url("{{ page.base-assets | append: "girassol-kisses.png" | relative_url }}");
                    }
                    100% {
                        background-image: url("{{ page.base-assets | append: "girassol-steampunk.png" | relative_url }}");
                    }
                }

                .girassol {
                    margin: 0;
                    height: 400px;
                    aspect-ratio: 1 / 1;
                    background-image: url("{{ page.base-assets | append: "girassol.png" | relative_url }}");
                    background-repeat: no-repeat;
                    background-size: contain;
                    animation: carousel 10s linear infinite;
                }
            </style>
            <div class="girassol">
            </div>
        </div>
    </foreignObject>
</svg>

Mas a ideia não é embarcar um objeto SVG inline no markdown do github, até
porque isso é coibido pelo GFM. Mas, mas será que tem alguma maneira de adicionar
o SVG no documento? Bem, podemos usar um `<object>` para deixar a coisa
embarcada (já que a tag `<svg>` não aceita URLs com recursos externos):

```html
<object type="image/svg+xml" data="{{ page.base-assets | append: "girassol-orig.svg" | relative_url }}">
</object>
```

<object type="image/svg+xml" data="{{ page.base-assets | append: "girassol-orig.svg" | relative_url }}">
</object>

Pois bem, o GitHub de toda sorte impede o uso do `<object>`, mas pelo
menos consegui mostrar uma alternativa de como colocar um SVG na página
HTML citando o link, não um SVG inline dentro da tag `<svg>`.

Pois então, acho que chegou a hora da verdade, não é mesmo? Pois vejam!!

<style>
    .highlight-opt[data-highlight="true"]>img {
        background-color: deeppink;
    }
</style>

<span id='carrossel-falho' class="highlight-opt">
![Um SVG com um carrossel de imagens]({{ page.base-assets | append: "girassol-orig.svg" | relative_url }})
</span>

Ué... O que ocorreu? Será que o elemento tá no canto? Clica aqui embaixo para
pintar de rosa o backgound:

<script>
    function toggleHighlightCarrosselFalho() {
        const spanCarrosselFalho = document.getElementById("carrossel-falho")
        if (spanCarrosselFalho.hasAttribute("data-highlight")) {
            spanCarrosselFalho.removeAttribute("data-highlight")
        } else {
            spanCarrosselFalho.setAttribute("data-highlight", "true")
        }
    }
</script>

<button onclick="toggleHighlightCarrosselFalho()">Toggle destaque</button>

Hmmm, então esse objeto está aí... mas não carregou?

### Depurando com CSS

Em primeiro ponto, para saber se o objeto estava no canto, queria algo que
ficasse óbvio e marcante a seleção. Tons de rosa bem impactantes foram
a primeira coisa que me vieram a cabeça. Inicialmente usar `pink` como
a cor parecia uma boa ideia, mas na verdade essa cor não chamava tanto
a atenção. Procurei no MDN uma
[lista de cores nomeadas](https://developer.mozilla.org/en-US/docs/Web/CSS/named-color),
e nelas escolhi o `deeppink` porque me pareceu mais chamativo.

No lugar de alterar o estilo do componente diretamente (como fiz no
poost [Editando SVG na mão pra pedir café]({% post_url 2024-03-16-edita-svg-manualmente %})),
resolvi adotar uma outra abordagem: que o CSS escolha o componente
HTML correto. Para isso, fiz com que o CSS olhasse para um atributo da
tag e que só fosse ativo caso tivesse um valor específico. Para deixar
mais amarradinho, prendi que esse destaque fosse feito não somente
na presença do atributo, mas também em uma classe específica
`highlight-opt`. Então com essa intenção, temos a primeira parte
do seletor CSS:

```css
.highlight-opt[data-highlight="true"] {
    background-color: deeppink;
}
```

Do jeito que está construído o seletor acima, ele só será ativado
caso o elemento HTML tenha a classe `.highlight-opt` e também
o atributo `data-highlight` com o valor `true`.

Mas agora tem um problema, como consigo adicionar a classe ao `<img>`
da importação do SVG? O SVG eu importei através da diretiva de markdown
`![alt-text](url)`, que não me permite trabalhar diretamente com o
nó HTML. Inclusive estou usando markdown para poder abstrair o DOM a
maior parte do tempo e tornar isso transparente para mim, então
é uma feature desejável essa limitação.

Para contornar isso, no lugar de tentar manipular diretamente o
`<img>`, coloquei a imagem dentro de um `<span>` para poder
interagir. Poderia ter escolhido `<span>` ou `<div>` para esse
exemplo, mas o `<span>` tem como premissa não quebrar o fluxo
dos elementos, então seria mais um envelope em cima do que vem
dentro dele, já a `<div>` delimita um local contíguo.

Ficou assim o posicionamento da imagem no blog:

{% raw %}
```html
<span id='carrossel-falho' class="highlight-opt">
![Um SVG com um carrossel de imagens]({{ page.base-assets | append: "girassol-orig.svg" | relative_url }})
</span>
```
{% endraw %}

Com isso o posicionamento não deve ser absurdamente afetado pelo `<span>`
e eu consigo selecionar especificamente o elemento do `<span>`. Em cima
disso eu pego o elemento pelo ID específico e posso adicionar/remover o atributo
dele:

```js
function toggleHilightCarrosselFalho() {
    const spanCarrosselFalho = document.getElementById("carrossel-falho")
    if (spanCarrosselFalho.hasAttribute("data-highlight")) {
        spanCarrosselFalho.removeAttribute("data-highlight")
    } else {
        spanCarrosselFalho.setAttribute("data-highlight", "true")
    }
}
```

E dentro do botão eu chamo a função `toggleHilightCarrosselFalho()` ao
ser clicado:

```html
<button onclick="toggleHilightCarrosselFalho()">Toggle destaque</button>
```

Mas isso não deixa pintado todo o comprimento da imagem, e sim
a linha que o `span` supostamente envelopa. Para resolver essa
questão, posso colocar no seletor do CSS para pegar as tags `img`
filhas daquele seletor que foi definido inicialmente:

```css
.highlight-opt[data-highlight="true"]>img {
    background-color: deeppink;
}
```

Esse `>` vai pegar o elemento `img` que seja filho imediato de um
nó que satisfaça `.highlight-opt[data-highlight="true"]`. Se eu colocar
um espaço ` ` no lugar do `>` (`.highlight-opt[data-highlight="true"] img`),
a interpretação é "um elemento `img` que seja descendente de um nó
que satisfaça `.highlight-opt[data-highlight="true"]`".

Inclusive essa questão do espaçamento pode gerar um incômodo no
backender que está escrevendo o CSS. Por exemplo, eu costumeiramente
colocava espaços entre as partes que deveriam ser satisfeitas do seletor
CSS. Por exemplo, colocar `.highlight-opt [data-highlight="true"]`
no lugar de `.highlight-opt[data-highlight="true"]`. Só que as semânticas
são distintas demais entre esses dois seletores, e minha cabeça de
backender se confundia com isso. Ao botar tudo junto, estou dizendo
"um nó que seja da classe `highlight-opt` e que tenha o atributo
`data-highlight` com valor `true`". Ao por o espaço, a interpretação
é "um nó que tenha o atributo `data-highlight` com valor `true` que
seja descendente de um nó com classe `highlight-opt`".

### O que aconteceu com o SVG na imagem?

Bem, nesse caso específico é que SVG ao ser importado como imagem
precisa atender algumas restrições a mais. Importar como `<object>`
é tranquilo e o SVG é feliz para trabalhar como quiser, mas
como `<img>` não. Aqui na documentação da
[MDN sobre a tag SVG como imagem](https://developer.mozilla.org/en-US/docs/Web/SVG/SVG_as_an_Image):

> External resources (e.g. images, stylesheets) cannot be loaded

Em tradução livre:

> Recursos externos (tais como imagens, folhas de estilo) não podem ser carregados

## Evitando a carga de recursos externos

O problema é recurso exerno? Então não tem problema. No lugar
de apontar para o recurso externo, posso usar o recurso para
a contrução do meu objeto. Como fazer isso? Usando URLs `data:`
para descrever o conteúdo das imagens de fundo.

Basicamente, onde antes se tinha `background-image: url("girassol.png");`,
agora preciso embarcar esse `girassol.png` dentro do CSS.
Então vamos ter um `background-image: url("data:..."))`, só falta
descobrir o miolo desse `data`.

A primeira parte é indicar o que é que está sendo carregado.
Então é `data:image/png`. Mas só isso não é o suficiente, preciso
carregar o resto da imagem. Mas preciso que seja enviado
textualmente a imagem, não pode ser um binário. E advinha só qual
o esquema de representação de dados binários para apenas caracteres
imprimíveis? Isso mesmo, `base64`!

Dentro do `data` então preciso definir que tem mais coisa
além do `image/png`. O jeito que eu fiz para alcançar isso foi
`data:image/png;base64,...`, onde a elipse é a representação
em base64 do blob da imagem.

## Geração automática do SVG

Vamos fazer em bash? Primeiro, preciso deixar claro que esse
programa vai inspecionar o seu ambiente para determinar quais
são as imagens, sem haver possibilidade de passar para o programa
as imagens via argumentos de CLI.

Vamos definir o formato geral do SVG primeiro?

```xml
<svg fill="none" viewBox="0 0 400 400" width="400" height="400" xmlns="http://www.w3.org/2000/svg">
	<foreignObject width="100%" height="100%">
		<div xmlns="http://www.w3.org/1999/xhtml">
			<style>
				@keyframes carousel {
					/* injetar os frames aqui */
				}
				.girassol {
					margin: 0;
					height: 400px;
                    aspect-ratio: 1 / 1;
					background-image: url(/* inserir imagem do girassol padrão */);
					background-repeat: no-repeat;
					background-size: contain;
					animation: carousel 10s linear infinite;
				}
			</style>
			<div class="girassol">
			</div>
		</div>
	</foreignObject>
</svg>
```

Estamos usando bash, então posso imprimir com heredoc:

```bash
cat <<EOG
<svg fill="none" viewBox="0 0 400 400" width="400" height="400" xmlns="http://www.w3.org/2000/svg">
	<foreignObject width="100%" height="100%">
		<div xmlns="http://www.w3.org/1999/xhtml">
			<style>
				@keyframes carousel {
					/* injetar os frames aqui */
				}
				.girassol {
					margin: 0;
					height: 400px;
                    aspect-ratio: 1 / 1;
					background-image: url(/* inserir imagem do girassol padrão */);
					background-repeat: no-repeat;
					background-size: contain;
					animation: carousel 10s linear infinite;
				}
			</style>
			<div class="girassol">
			</div>
		</div>
	</foreignObject>
</svg>
EOG
```

Ok, bacana. Vamos aproveitar que o Bash faz substituição textual
no heredoc e já deixar marcado que precisam pegar sol:

```bash
cat <<EOG
<svg fill="none" viewBox="0 0 400 400" width="400" height="400" xmlns="http://www.w3.org/2000/svg">
	<foreignObject width="100%" height="100%">
		<div xmlns="http://www.w3.org/1999/xhtml">
			<style>
				@keyframes carousel {
					`create_frames`
				}
				.girassol {
					margin: 0;
					height: 400px;
                    aspect-ratio: 1 / 1;
					background-image: url(`create_base_64 girassol.png`);
					background-repeat: no-repeat;
					background-size: contain;
					animation: carousel 10s linear infinite;
				}
			</style>
			<div class="girassol">
			</div>
		</div>
	</foreignObject>
</svg>
EOG
```

> Note que antes onde estava comentário foi substituído por shell expansions.

Ok, e como seria o `create_base_64`? Pois bem, já ouviu falar do comando
`base64`?

Basicamente esse comando vai criar um binário e irá produzir o output
em base 64. Mas esse comando tem um problema: ele insere uma quebra
de linha no final. Para evitar isso, que iria ficar indesejado,
eu passo pelo `tr` para remover o conteúdo:

```bash
create_base_64() {
    base64 "$1" | tr -d $"\r\n"
}
```

Aqui o `tr -d` indica que estou apagando o caracter, não trocando.
O comando `tr` vem de "translate", mas aqui a interpretação é mais
literal: a tradução se dá ao nível de cacarter.

O `-d` indica ao `tr` que ele precisa de comportamento específico:
não precisa traduzir, apenas deletar. Então chegamos na expansão
shell de string: `$"\r\n"`. Isso basicamente vai indicar ao shell
para fazer a interpretação desses _scape sequencies_.

Agora adicionemos o cabeçalho necessário:

```bash
create_base_64() {
    echo -n "data:image/png;base64,"
    base64 "$1" | tr -d $"\r\n"
}
```

E pronto! Aqui o `-n` passado para o `echo` indica que ela não insira
a quebra de linha no final, pois assim a representação em base 64 do banco
estará na linha correta.

Ok, mas e como funciona o `create_frames`? Basicamente aqui eu vou pegar
a quantidade de fotos e, em cima disso, ir calculando quantos porcento
vai avançar. Basicamente para cada paso vou criar um frame passando
um arquivo e o porcentual de progressão (com exceção da última imagem,
que é 100%).

Vamos primeiro examinar o `create_frame` em si? E depois voltar
para o `create_frames`? Basicamente aqui vou dar o step da animação.
Só isso. O formato geral é:

```css
$progression% {
    background-image: url("`create_base_64 "$image"`");
}
```

E só isso. O `create_base_64` já foi discutido. O resto é apenas
receber os argumentos e parsear corretamente:

```bash
create_frame() {
    local image="$1"
    local progression="$2"

    cat <<FRAME
$progression% {
    background-image: url("`create_base_64 "$image"`");
}
FRAME
}
```

Ok, agora só faltou os detalhes do `create_frames`.
Logo no começo desta seção mencionei que o script
iria fazer uma inspeção e em cima disso ele pegava
os dados. Então, essa inspeção vai preencher a
variável `GIRASSOLES`:

```bash
GIRASSOLES=( girassol*.png )
```

Como a variável está sendo criada com o valor dentor de
parênteses, a ideia é transformar em vetor. Ser vetor
ajuda bastante a trabalhar com índices e listagem
de elementos de dentro das variáveis. O jeito que foi
construída a expansão glob `( girassol*.png )` vai gerar
um vetor com os arquivos que começam com `girassol` e
terminam com `.png`. Isso implica que automaticamente
o tamanho do vetor vai se adequar, basta que se coloque
o nome da imagem do arquivo de imagem com esse formato.

Então, precisamos agora contar quantos passos iremos dar.
Se temos 3 fotos, comecemos da foto 0, então damos um passo
para a foto 1 no meio, e finalmente chegamos no segudo passo
no 100% com a foto 2. A quantidade de passos vai ser igual a
quantidade de imagens disponíveis menos uma, que vai ser
usado no 0% (ou no 100%).

Mas como fazer isso em cima da variável `GIRASSOLES`?
Bem, o Bash oferece uma expansão de variável específica
de vetores: `${#GIRASSOLES[@]}`. Aqui o `${...}` é só
para indicar que haverá uma expansão de variável. O
`#` no começo da expansão é para fazer uma contagem.
Só que se eu fizer apenas `${#GIRASSOLES}` ele irá
contar a quantidade de caracteres do primeiro
elemento do vetor. Para contornar isso, colocamos o "índice"
`[@]`, ficando finalmente `${#GIRASSOLES[@]}`.

Então a quantidade de steps vai ser a quantidade
de fotos menos 1. Para poder fazer aritmética,
eu posso declarar a variável de interesse como sendo
inteira, e em cima disso fazer as contas:

```bash
create_frames() {
    local -i n_frames=${#GIRASSOLES[@]}-1
    # ...
}
```

Ok, agora vamos calcular o quanto avançamos a cada step?
Basicamente 100 dividido pela quantidade de passos:

```bash
create_frames() {
    local -i n_frames=${#GIRASSOLES[@]}-1
    local -i step=100/$n_frames
    # ...
}
```

Ok, agora é só iterar, não é? Existem várias maneiras
de iterar em cima de `GIRASSOLES`. Mas nesse caso
específico eu quero ignorar o último elemnto, para
ter uma lida diferente. Então usar o `for-each` não
satisfaria:

```bash
for girassol in "${GIRASSOLES[@]}"; do
    # blablabla
done
```

Note que a expansão do vetor protegido com aspas e com
"índice" `@` fará com que esse vetor se expanda em cada
um de seus itens individuais. Se eu não tivesse protegido
com aspas, o IFS entraria em ação para separar os pedaços
da string.

E a expansão protegida com aspas em cima do índice asterisco
`*` teria um resultado diferente: seria gerado um único
elemento que é a concatenação de todos os elementos:
`"${GIRASSOLES[@]}"` é muito diferente de `"${GIRASSOLES[*]}"`.

Para poder lidar especificamente com o valor final, posso iterar
usando o "for c-style":

```bash
for (( i=0; i < $n_frames; i++ )); do
    # corpo do laço...
done
```

A sintaxe para usar esse tipo de `for` é:

- palavra-chave `for`
- dois parênteses abrindo juntos
- campos de inicialização, verificação e avanço separados pom `;`
- uma quebra de comando (por exemplo com `;`) e a palavra-chave `do`
- o corpo do laço
- fechamento do laço com palavra-chave `done`

No caso, preciso calcular a progressão para enviar para o `create_frame`.
De modo geral, ficaria assim:

```bash
create_frames() {
    local -i n_frames=${#GIRASSOLES[@]}-1
    local -i step=100/$n_frames
    local -i progression

    for (( i=0; i < $n_frames; i++ )); do
        progression=... # cálculo mágico...
        create_frame ${GIRASSOLES[$i]} $progression
    done
    create_frame ${GIRASSOLES[$n_frames]} 100
}
```

E, bem. Temos o tamanho do passo, e temos o índice. Podemos
simplesmente dizer que a progressão do momento é simplesmente
usar `progression=$step*$i`. Note que eu posso fazer a
multiplicação porque o tipo de `progression` é inteiro e
que `step` é inteiro:

```bash
create_frames() {
    local -i n_frames=${#GIRASSOLES[@]}-1
    local -i step=100/$n_frames
    local -i progression

    for (( i=0; i < $n_frames; i++ )); do
        progression=$step*$i
        create_frame ${GIRASSOLES[$i]} $progression
    done
    create_frame ${GIRASSOLES[$n_frames]} 100
}
```

Vamos testar como que fica?

O SVG passou a ter essa cara geral (o base 64 só está sendo
exibido parcialmente, não pus ele todo aqui):

```xml
<svg fill="none" viewBox="0 0 400 400" width="400" height="400" xmlns="http://www.w3.org/2000/svg">
	<foreignObject width="100%" height="100%">
		<div xmlns="http://www.w3.org/1999/xhtml">
			<style>
				@keyframes carousel {
					0% {
    background-image: url("data:image/png;base64,iVBORw0KGgoAAAA...");
}
25% {
    background-image: url("data:image/png;base64,iVBORw0KGgoAAAA...");
}
50% {
    background-image: url("data:image/png;base64,iVBORw0KGgoAAAA...");
}
75% {
    background-image: url("data:image/png;base64,iVBORw0KGgoAAAA...");
}
100% {
    background-image: url("data:image/png;base64,iVBORw0KGgoAAAA...");
}
				}
				.girassol {
					margin: 0;
					height: 400px;
                    aspect-ratio: 1 / 1;
					background-image: url("data:image/png;base64,iVBORw0KGgoAAAA...");
                    background-repeat: no-repeat;
                    background-size: contain;
					animation: carousel 10s linear infinite;
				}
			</style>
			<div class="girassol">
			</div>
		</div>
	</foreignObject>
</svg>
```

![Carrossel de fotos]({{ page.base-assets | append: "girassol.svg" | relative_url }})

_Voi là_! Deu certo! Se quiser observar no GitHub, só clicar [neste link](https://github.com/girassol-rb/girassol/blob/9380f3c141116185916daa3c8af4c62ba2abf2c2/README.md), que foi o proeto que disparou
minha necessidade de colocar um carrossel de fotos no painel do GitHub.

# Resumindo

Devido as restrições do GitHub, para fazer um carrossel só se
for animação CSS. Mas GitHub não permite que você suba assim
coisas de CSS. Para contornar, você precisa importar um SVG
como uma imagem e dentro do SVG determinar via CSS
a animação.

SVG como imagem é proibido de pegar recursos externos, então
se tiver dependência de outras coisas precisa importar
manualmente dentro do SVG para ser tudo local. Por exemplo,
carregar imagens PNG internamente usando as URLs `data:...`
com o conteúdo da imagem em base 64.
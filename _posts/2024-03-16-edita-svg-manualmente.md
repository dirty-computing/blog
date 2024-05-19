---
layout: post
title: "Editando SVG na mão pra pedir café"
author: "Jefferson Quesado"
tags: svg ruby html css js javascript browser-api frontend meta
base-assets: "/assets/edita-svg-manualmente/"
---

<style>
    .pixmeacoffe {
        border-width: 0px;
    }
    @media (max-width: 800px) {
        .pixmeacoffe {
            display: none;
        }
        .hide-on-mobile {
            display: none;
        }
    }
    @media (min-width: 801px) {
        .pixmeacoffe {
            float: right;
        }
        .hide-on-full {
            display: none;
        }
    }
</style>

<script>
    {
        const focusElementById = (id) => {
            window.location.hash = `#${id}`;
        }

        const recoverPixmeaCoffe = (() => {
            let pixmeacoffe;
            let csspmc;

            return () => {
                if (pixmeacoffe) {
                    return [pixmeacoffe, csspmc];
                }
                pixmeacoffe = document.getElementById("pixmeacoffe");
                csspmc = getComputedStyle(pixmeacoffe)
                return [pixmeacoffe, csspmc];
            }
        })()

        function pixme() {
            const [pixmeacoffe, csspmc] = recoverPixmeaCoffe();

            if (csspmc.float !== "right") {
                const displayToggledValue = pixmeacoffe.style.display === "" ? "block" : "";
                pixmeacoffe.style.display = displayToggledValue;
                if (displayToggledValue === "block") {
                    focusElementById("pixmeacoffe");
                    window.location.href = window.location.href.replace(/#.*$/, "#pixmeacoffe")
                }
            }
        }

        onresize = event => {
            const [pixmeacoffe, csspmc] = recoverPixmeaCoffe();
            if (csspmc.float === "right") {
                if (pixmeacoffe.style.display === "block") {
                    pixmeacoffe.style.display = "";
                }
            }
        }
    }
</script>

<iframe id="pixmeacoffe" src="https://www.pixme.bio/jeffquesado" width="400"
    height="800" class="pixmeacoffe" loading="lazy" sandbox="allow-scripts">
</iframe>

A propósito, quero um café, compra um pra mim?

Quero café.
<a href="#pixmeacoffe" class="hide-on-mobile"><span class="icon hide-on-mobile">{% include icon-pixme.svg %}</span></a>
<button class="icon hide-on-full" onclick="pixme()">{% include icon-pixme-no-title.svg %}</button>

O post de hoje tem tudo a ver com café. Na real, tudo começou
com uma treta quando atacaram a [AlertPix](https://alertpix.live/)
acusando injustamente baseado no valor mais competitivo.

Falei com o fundador da AlertPix para por as doações no Computaria
e ele me deu a ideia de usar o [Pix me a Coffe](https://pixme.bio),
já que o AlertPix é mais voltado para streamers justamente dando
o alerta na live ao receber um pix. Já o foco do Pix me a Coffe
é justamente essa de ter uma porta aberta e bonitinha para que
a pessoa possa me pagar um café.

Então pedi o ícone da Pix me a Coffe em svg para o fundador e
ele prontamente me entregou! E ainda entregou com a coloração
no tom de cinza adequada prevendo que eu não iria me atentar
ao esquema de cores e que provavelmente iria fazer besteira
ao embarcar aqui no Computaria o logo do cafezinho.

Porém... o [Daniel Limae](https://twitter.com/daniellimae)
me entregou em 23 x 27, e o padrão que está sendo usado é
16 x 16... então chegou o ponto de customizar o SVG para
se adequar a mim.

# Antes, o embed

Antes de entrar no tema principal, abordar primeiro aqui
um tema secundário rápido: como fazer o embed do cartão
do Pix me a Coffe.

A minha primeira ideia foi por um `<iframe>`, pois
através da tag iframe se consegue colocar informações
de um HTML provido por outro site dentro do meu site:

```html
<iframe src="https://www.pixme.bio/jeffquesado"></iframe>
```

Só que ficou mais feio do que eu imaginei que ia ficar:

![Primeira tentativa com iframe, bem feio na verdade]({{ page.base-assets | append: "1-iframe-cru.png" | relative_url }})

Não me restou muita alternativa além de deixar bonito. A
primeira coisa que fiz foi abrir a referência sobre iframe:
[documentação da MDN](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe)

Primeiras coisas que eu percebi que eu desejava:

- remover a borda ([propriedade `frameboder="0"`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe#frameborder))
- impedir o scroll ([propriedade `scrolling="no"`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe#scrolling))

Fui pela alternativa clássica de remover a borda e de impedir o scroll.
Ainda precisava resolver a questão do tamanho:

```html
<iframe src="https://www.pixme.bio/jeffquesado" frameboder="0" scrolling="no"></iframe>
```

Inspecionei o conteúdo do iframe e cutuquei as propriedade `width` e
`height` pelo próprio browser até chegar no tamanho adequado:
400 x 800:

```html
<iframe src="https://www.pixme.bio/jeffquesado" frameborder="0" width="400"
    height="800" scrolling="no">
</iframe>
```

Ficou assim:

![Terceira tentativa, seguindo o fluxo do texto, porém sem barra de rolagem]({{ page.base-assets | append: "2-iframe-normal-flow.png" | relative_url }})

Porém, parecia que o iframe embarcado no blog não estava no lugar adequado.
Tinha muito espaço para a direita e o iframe impedia o fluxo natural de leitura
do artigo. E se desse para aproveitar o lado da direita? Bem, por que nào?
Usar como se fosse um objeto flutuante a direita? Daí achei
a [propriedade CSS `float`](https://developer.mozilla.org/en-US/docs/Web/CSS/float).

Coloquei para testar um estilo inline com `float: right`, e eis que ficou
assim:

```html
<iframe src="https://www.pixme.bio/jeffquesado" frameborder="0" width="400"
    height="800" scrolling="no" style="float: right">
</iframe>
```

![Estágio final, flutuando a direita]({{ page.base-assets | append: "3-iframe-float.png" | relative_url }})

Ótimo, tudo no lugar. Uma revisada na documentação pra saber se estava tudo
perfeitinho e percebo que tanto o `scrolling` quanto o `frameborder` estão
marcados como deprecados. Hmmmm, para a borda recomendou usar propriedades
CSS, mas para o scroll recomendou apenas remover. Ok, então:

```html
<iframe src="https://www.pixme.bio/jeffquesado" width="400"
    height="800" style="float: right; border-width: 0px">
</iframe>
```

## O caso para mobile

Bem, ao abrir no modo mobile ficou horrível o post. Primeiro precisava fazer
um pouco mais de um scroll completo de tela para sair do banner pedindo
café. E segundo porque o banner não ficou centralizado.

![Visualização mobile original]({{ page.base-assets | append: "4-iframe-mobile.png" | relative_url }})

Nada como usar as propriedades do browser para fazer testes
antes de lançar o artigo, não é?

Bem, e se eu sumir com o iframe no caso de ser mobile? Já temos um ponto
de quebra no blog que é saindo de 800px de largura para 801px de largura.

Podemos fazer isso usando [`@media` query](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_media_queries/Using_media_queries).
Para usar as `@media` queries preciso estar dentro da tag `<style>` para
escrever CSS localmente, e consigo determinar valor de clases CSS
dentro das `@media` queries. Como o ponto de partida é <= 800px
e > 800, podemos fazer as seguintes queries:

```css
@media (max-width: 800px) {
    .pixmeacoffe {
        display: none;
    }
}
@media (min-width: 801px) {
    .pixmeacoffe {
        float: right;
        border-width: 0px;
    }
}
```

Assim, podemos remover o estilo inline do iframe e dizer
que ele é da classe `pixmeacoffe`:

```html
<iframe src="https://www.pixme.bio/jeffquesado" width="400"
    height="800" class="pixmeacoffe">
</iframe>
```

Só que isso tem um revés... a carga do iframe irá ocorrer
mesmo que o usuário de mobile em nenhuma hipótese abra
o iframe. Seria bom se tivesse uma alternativa que permitisse
lazy loading,,,

Bem, veja só! Existe! Atributo [`load="lazy"`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe#lazy)!!

Olhando o console da web o Firefox ainda me mostrou a seguinte mensagem:

> Partitioned cookie or storage access was provided to
> “[https://www.pixme.bio/jeffquesado](https://www.pixme.bio/jeffquesado)” because it
> is loaded in the third-party context and dynamic state partitioning is enabled.
> [[Learn more]](https://developer.mozilla.org/docs/Mozilla/Firefox/Privacy/Storage_access_policy/Errors/CookiePartitionedForeign?utm_source=devtools&utm_medium=firefox-cookie-errors&utm_campaign=default)

Ok, então como posso desabilitar acesso ao storage e cookies?
Bem, usando o modo de [`sandbox`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe#sandbox).
A primeira alternativa é deixar em branco, mas isso não foi bom para o banner,
já que ele se monta usando JS. Então dei a permissão `allow-scripts`:

```html
<iframe src="https://www.pixme.bio/jeffquesado" width="400"
    height="800" class="pixmeacoffe" loading="lazy" sandbox="allow-scripts">
</iframe>
```

Ok, mas agora o café sumiu totalmente do radar. E se eu adicionasse o copinho
de café na frase? E fizesse ele aparecer no final da frase? E ao
clicar no clique no cafezinho e o banner ficar visível?

Bem, vamos deixar o ambiente arrumado? Adicionar o logo foi simples:

```html
{%- raw -%}
<span class="icon">{% include icon-pixme.svg %}</span>
{% endraw %}
```

> Ele precisa estar em [`/_includes/`]({{ site.repository.tree_root }}/_includes/).
>
> Por algum motivo que me foge ao conhecimento o SVG precisa estar em uma única linha,
> caso contrário não renderiza corretamente.

Agora precisamos chamar uma função ao clicar no café: `onclick="pixme()"`.
Pronto, precisamos agora declarar o script para fazer isso usando a função `pixme`. O
iframe precisa ser identificado, portanto podemos por uma id nele,
que vai ser chamado de `pixmeacoffe`.

A ideia é tornar visível com estilo "inline". Para fazer
isso, podemos invocar o atributo `.style` do objeto visutal e adicionar o valor
arbitrariamente como chave valor, como `pixmeacoffe.style.display = "block";`:

> [Referência Stack Overflow](https://stackoverflow.com/a/15241987/4438007)

```js
function pixme() {
    const pixmeacoffe = document.getElementById("pixmeacoffe");

    pixmeacoffe.style.display = "block";
}
```

Mas poderia ser melhor, né? Poderia ativar e desativar:

```js
function pixme() {
    const pixmeacoffe = document.getElementById("pixmeacoffe");

    const displayToggledValue = pixmeacoffe.style.display === "" ? "block" : "";
    pixmeacoffe.style.display = displayToggledValue;
}
```

Agora, isso faz sentido sempre? Não, só quando está com a `@media` query
apontando que é pequeno. Para isso, posso validar que o atributo CSS
efetivo de `pixmeacoffe` para `.float` é `"right"`.
Mas para isso primeiro precisa resgatar o estilo computado,
[`getComputedStyle(element)`](https://developer.mozilla.org/en-US/docs/Web/API/Window/getComputedStyle):

```js
function pixme() {
    const pixmeacoffe = document.getElementById("pixmeacoffe");
    const csspmc = getComputedStyle(pixmeacoffe)

    if (csspmc.float !== "right") {
        const displayToggledValue = pixmeacoffe.style.display === "" ? "block" : "";
        pixmeacoffe.style.display = displayToggledValue;
    }
}
```

Ok, bacana. Mas e se eu detectasse que ele aumentou a página?
E usar isso para remover a propriedade do `style` inline?
De modo geral, seria fazer a seguinte computação:

```js
const pixmeacoffe = document.getElementById("pixmeacoffe");
const csspmc = getComputedStyle(pixmeacoffe)

if (csspmc.float === "right") {
    if (pixmeacoffe.style.display === "block") {
        pixmeacoffe.style.display = "";
    }
}
```

Mas se eu pegar esses valores a cada alteração de tamanho não ia ser legal,
iria gastar bastante processamento desnecessariamente. Bem, então eu posso
criar uma função que resgata isso e memoiza. A ideia é ter uma clausura
local de modo que quem requisita só sabe que receberá o valor, não que
ele pode ser computado. Uma estratégia para isso é criar uma arrow function
auto chamada que retorna uma função que faz a memoização, com os valores
a se memoizar na corpo da primeira função:

```js
() => {
    let pixmeacoffe
    let csspmc

    return () => {
        if (pixmeacoffe) {
            return [pixmeacoffe, csspmc];
        }
        pixmeacoffe = document.getElementById("pixmeacoffe");
        csspmc = getComputedStyle(pixmeacoffe)
        return [pixmeacoffe, csspmc];
    }
}
```

Essa função acima retorna uma função que fará a computação
memoizada. Note que `pixmeacoffe` e `csspmc` estão dentro da
clausura do retorno, mas inacessíveis externamente.

Essa função que cria a clausura não é interessante manter,
o ideal seria que essa função já retornasse imediatamente,
para guardar o retorno. Como fazer isso? Chamando ela imediatamente
ao criar. Envolve com `(` parênteses `)` a arrow-function
e invoca ela:

```js
(() => {
    let pixmeacoffe
    let csspmc

    return () => {
        if (pixmeacoffe) {
            return [pixmeacoffe, csspmc];
        }
        pixmeacoffe = document.getElementById("pixmeacoffe");
        csspmc = getComputedStyle(pixmeacoffe)
        return [pixmeacoffe, csspmc];
    }
})();
```

Pronto, agora só falta guardar o valor. Podemos guardar na
variável `recoverPixmeaCoffe`:

```js
const recoverPixmeaCoffe = (() => {
    let pixmeacoffe
    let csspmc

    return () => {
        if (pixmeacoffe) {
            return [pixmeacoffe, csspmc];
        }
        pixmeacoffe = document.getElementById("pixmeacoffe");
        csspmc = getComputedStyle(pixmeacoffe)
        return [pixmeacoffe, csspmc];
    }
})();
```

Só que por isso no script top-level vai fazer "vazar" essa constante.
Posso colocar dentro de `<script>` em um bloco. `const` e `let` não
vazam para fora do bloco, mas `function` vaza. Então posso criar
tudo o que eu quiser escondido e se expor a API da função desejada:

```html
<script>
    {
        const recoverPixmeaCoffe = (() => {
            let pixmeacoffe
            let csspmc

            return () => {
                if (pixmeacoffe) {
                    return [pixmeacoffe, csspmc];
                }
                pixmeacoffe = document.getElementById("pixmeacoffe");
                csspmc = getComputedStyle(pixmeacoffe)
                return [pixmeacoffe, csspmc];
            }
        })();

        function pixme() {
            const [pixmeacoffe, csspmc] = recoverPixmeaCoffe();

            if (csspmc.float !== "right") {
                const displayToggledValue = pixmeacoffe.style.display === "" ? "block" : "";
                pixmeacoffe.style.display = displayToggledValue;
            }
        }
    }
</script>
```

Beleza, com isso consigo expor apenas a função `pixme()` para ser
chamada pelo clique no HTML. Ela é ótima que só computa uma vez
e memoiza o resultado. Adequada para usar no
[evento de resize](https://developer.mozilla.org/en-US/docs/Web/API/Window/resize_event):

```js
onresize = event => {
    const [pixmeacoffe, csspmc] = recoverPixmeaCoffe();
    if (csspmc.float === "right") {
        if (pixmeacoffe.style.display === "block") {
            pixmeacoffe.style.display = "";
        }
    }
}
```

Note que a escolha é sempre analisando o estilo efetivo, pois se for preciso
alterar o breakpoint das `@media` queries o que importa está garantido, que é
mudar se exibe condicionado ao tamanho do elemento vs da tela.

# SVG

Os demais SVGs que eu tenho para os ícones não são limitados em tamanho, então
eles abrem _unbounded_ no browser. Por exemplo o ícone do GitLab:
[`icon-gitlab.svg`]({{ site.repository.blob_root }}/_includes/icon-gitlab.svg).

Mas o Daniel Limae me mandou com limitações nisso. Veja
[`icon-pixme-original.svg`]({{ site.repository.blob_root }}/{{ page.base-assets }}/icon-pixme-original.svg).
São os atributos `width` e `height` da tag `<svg>`.

Outra coisa que me chamou a atenção foi que a tag `<path>` tem um atributo
chamado `opacity`. Quanto mais opaco (até `1`), mas visível. Opacidade
`0` significa perfeitamente transparente.

Esses foram meus primeiros ajustes, remover o `width` e `height`
para que o ícone seja _unbounded_ e deixar a opacidade
padrão, removendo o atributo.

Ok, agora a `viewBox` não está batendo perfeitamente encaixada com as demais.
A `viewBox` nada mais é do que aquilo que será projetado do SVG. Dentro do
SVG eu posso desenhar em todo o plano cartesiano, mas apenas aquilo que
está dentro do `viewBox` de fato será exibido.

A `viewBox` dos outros ícones é quadrada, e no `icon-pixme-original` ela é
retangular: `0 0 23 27`. Isso significa que vai do ponto `(0, 0)` até o ponto
`(23, 27)`. Mas deixar ela quadrada não é simplesmente alterar o valor para
`0 0 27 27`, pois isso significa que estarei alterando a composição do desenho.

Adicionar os 4 pixels no eixo horizontal pode ser encarado como adicionar 2
pixels a esquerda e 2 pixels a direita, o que mantém a imagem centralizada se
ela estivesse centralizada antes (estava). Bem, agora preciso ver como é o desenho...

Abaixo um excerto de como é o SVG do Pix me a Coffe:

```xml
<svg viewBox="0 0 23 27" width="23" height="27" fill="none" xmlns="http://www.w3.org/2000/svg">
<path opacity="1" d="M20.3747 4.1841L20.7902 4.19132 [...] L5.25937 24.4217L16.6876 24.6202L18.0103 9.73399L4.45443 9.49853Z" fill="#828282"/>
</svg>
```

Bem vamos lá. A única tag dentro de `<svg>` é `<path>`. Então é seguro afirmar que os
desenhos estão todos dentro dessa tag. Procurando mais informações a respeito do que
seriam esses detalhes, achei a seguinte
[referência inicial](https://webdesign.tutsplus.com/how-to-hand-code-svg--cms-30368t).

Na referência aprendi que o atributo `d` carrega toda a magia. E que na verdade ele
é uma lista de comandos para desenhar e que eu poderia (para questão de _minha_
leitura do SVG) separar os comandos em 1 por linha que continuaria um comando válido.
Cada comando é indicado por uma letra distinta dentro do `d`. Cada comando recebe
uma quantidade pré-determinada de coordenadas (muitas vezes em múltiplos de `x y`).

Por exemplo, pegando o excerto acima:

```xml
<svg viewBox="0 0 23 27" width="23" height="27" fill="none" xmlns="http://www.w3.org/2000/svg">
<path opacity="1" d="
    M20.3747 4.1841
    L20.7902 4.19132
    [...]
    L5.25937 24.4217
    L16.6876 24.6202
    L18.0103 9.73399
    L4.45443 9.49853
    Z
    " fill="#828282"/>
</svg>
```

Para "adicionar" os 2 pixels a direita não preciso fazer nada, pois o que está a direita da imagem é vazio.
Mas o para a esquerda da imagem eu preciso atualizar todas as coordenadas `x` em +2. No exemplo acima:

```xml
```

onde `M` é o comando `moveto` que move a caneta para uma posição arbitrária sem tocar,
`L` é um comando `line` que move a caneta para uma posição arbitrária TOCANDO o papel,
e `Z` é o comando de "fechamento" `closepath`, como se fosse um `L` para o ponto inicial (onde
ponto inicial é determinado como o último ponto para o qual se deu um `moveto`).
[Podem ler mais](https://www.w3.org/TR/SVG/paths.html#TheDProperty)

No caso do Pix me a Coffe, ainda tem o comando `C`: curva de Bézier. Ela recebe 3
pares de coordenadas. Fica assim após somar 2 pixels de ambos os lados.

```xml
<svg viewBox="0 0 27 27" fill="none" xmlns="http://www.w3.org/2000/svg">
<path opacity="1" d="
    M22.3747 4.1841
    L22.7902 4.19132
    [...]
    L7.25937 24.4217
    L18.6876 24.6202
    L20.0103 9.73399
    L6.45443 9.49853
    Z
    " fill="#828282"/>
</svg>
```

E para uma curva de Bezier:

```diff
-C23.011   4.19481  23.2234  4.27664 23.3895  4.42221
+C25.011   4.19481  25.2234  4.27664 25.3895  4.42221
```

Agora, agora preciso normalizar para caber em
16 x 16 pixels. Isso significa agora que os pontos,
a partir da origem, serão encolhidos em:

{% katexmm %}
$$
\frac{16}{27}
$$
{% endkatexmm %}

Pronto, agora eu preciso pegar todos os valores e, individualmente,
multiplicar por `16.0/27.0`. Vamos fazer isso com Ruby?

Inicialmente, vamos deixar os comandos bem formados. Cada comando
em sua própria linha. Só vamos começar a processar no momento
em que encontrar o `<path`, não precisa fechar o comando agora,
o objeto de interesse não é o `path`. Então, em algum momento teremos
o `d="`, que iniciará o processo até encontrar uma linha que começa
com `"`.

Essa solução não é boa o suficiente, mas funciona para o caso em minhas
mãos: com apenas um `<path>` no SVG.

Para ler um arquivo em Ruby, uma alternativa é usar o `IO.readlines(path)`,
que me retorna um array de linhas. Depois disso posso ir escrevendo no array
de output e, ao final, só escrever o output na stdout. Com o array
em mãos, consigo facilmente detectar em qual linha termina com `d="`.

Irei processar as coisas de `linhas` e jogar o resultado desejado em
`novas_linhas`. Então, para imprimir, só fazer `puts novas_linhas.join "\n"`.
Primeiro, a prova de conceito, jogar as coisas em `novas_linhas` e imprimir:

```ruby
linhas = IO.readlines "./icon-pixme-linha-separada.svg"

novas_linhas = []

for linha in linhas do
    novas_linhas.append linha
end

puts novas_linhas.join "\n"
```

Bem, isso gerou uma saída que começou assim:

```xml
<svg viewBox="0 0 27 27" xmlns="http://www.w3.org/2000/svg" fill-rule="evenodd" clip-rule="evenodd" stroke-linejoin="round" stroke-miterlimit="1.414">

<path opacity="1" d="

M22.3747  4.1841

L22.7902  4.19132
```

Isso porque o `IO.readlines` mantém o fim de linha, e mandei dar o `.join "\n"`. Vamos
nos livrar das coisas desnecessárias do começo e final de linha? É só dar um `.strip`
que se resolve:

```ruby
linhas = IO.readlines "./icon-pixme-linha-separada.svg"

novas_linhas = []

for linha in linhas do
    linha = linha.strip
    novas_linhas.append linha
end

puts novas_linhas.join "\n"
```

Saída:

```xml
<svg viewBox="0 0 27 27" xmlns="http://www.w3.org/2000/svg" fill-rule="evenodd" clip-rule="evenodd" stroke-linejoin="round" stroke-miterlimit="1.414">
<path opacity="1" d="
M22.3747  4.1841
L22.7902  4.19132
```

Pronto, agora sim, bacana. Bem, podemos aplicar uma tratativa especial para a primeira linha logo
e retornar o `viewBox` que eu desejo, né? Seria o equivalente a fazer um `s/0 0 27 27/0 0 16 16/`.
Para isso a string fornece o método `.sub(pattern, replace)`. Tem o método `.gsub(pattern, replace)`
também que funciona de modo similar, mas fazendo geral na string, enquanto que `sub` é só o
primeiro match.

```ruby
linhas = IO.readlines "./icon-pixme-linha-separada.svg"

novas_linhas = []

for linha in linhas do
    linha = linha.strip
    novas_linhas.append linha
end

# tratando a primeira linha
novas_linhas[0] = novas_linhas[0].sub("0 0 27 27", "0 0 16 16")
puts novas_linhas.join "\n"
```

Saída:

```
<svg viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" fill-rule="evenodd" clip-rule="evenodd" stroke-linejoin="round" stroke-miterlimit="1.414">
<path opacity="1" d="
M22.3747  4.1841
L22.7902  4.19132
C23.011   4.19481  23.2234  4.27664 23.3895  4.42221
```

Ok, agora vamos lidar de modo diferente caso eu tenho encontrado um `d="`?
Adicionemos a flag de transformação para indicar que estamos lendo
coisas de dentro da tag `<path>`:

```ruby
linhas = IO.readlines "./icon-pixme-linha-separada.svg"

novas_linhas = []
lendoPath = false

for linha in linhas do
    linha = linha.strip
    if lendoPath then
        novas_linhas.append linha + "PATH DETECTED!" # só para debug memso
    else
        if linha.end_with? 'd="' then
           lendoPath = true 
        end
        novas_linhas.append linha
    end
end

# tratando a primeira linha
novas_linhas[0] = novas_linhas[0].sub("0 0 27 27", "0 0 16 16")
puts novas_linhas.join "\n"
```

Saída:

```
<svg viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" fill-rule="evenodd" clip-rule="evenodd" stroke-linejoin="round" stroke-miterlimit="1.414">
<path opacity="1" d="
M22.3747  4.1841PATH DETECTED!
L22.7902  4.19132PATH DETECTED!
C23.011   4.19481  23.2234  4.27664 23.3895  4.42221PATH DETECTED!
```

Beleza, tá detectando corretamente que tá iniciando o tratamento do `<path>`.
Mas não indica onde terminou, o que pod eser problemático. Pelo jeito que organizamos
aqui, ele termina em uma string que começa com `"`:

```ruby
linhas = IO.readlines "./icon-pixme-linha-separada.svg"

novas_linhas = []
lendoPath = false

for linha in linhas do
    linha = linha.strip
    if lendoPath then
        if linha.start_with? '"' then
            lendoPath = false
            novas_linhas.append linha
        else
            novas_linhas.append linha + "PATH DETECTED!" # só para debug memso
        end
    else
        if linha.end_with? 'd="' then
           lendoPath = true 
        end
        novas_linhas.append linha
    end
end

# tratando a primeira linha
novas_linhas[0] = novas_linhas[0].sub("0 0 27 27", "0 0 16 16")
puts novas_linhas.join "\n"
```

Saída:

```
<svg viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" fill-rule="evenodd" clip-rule="evenodd" stroke-linejoin="round" stroke-miterlimit="1.414">
<path opacity="1" d="
M22.3747  4.1841PATH DETECTED!
L22.7902  4.19132PATH DETECTED!
C23.011   4.19481  23.2234  4.27664 23.3895  4.42221PATH DETECTED!
    [ omitido ]
L18.6876  24.6202PATH DETECTED!
L20.0103  9.73399PATH DETECTED!
L6.45443  9.49853PATH DETECTED!
ZPATH DETECTED!
" fill="#828282"/>
</svg>
```

Perfeitinho, já detectou todas as linhas que precisam de alteração.
Agora, qual vai ser a transformação delas?

Bem, vamos lá. A linha é composta de um caracter de comando seguido
de vários pares de coordenadas, que são indicados como pontos flutuantes
separados por espaços. Para pegar o primeiro caracter, podemos fazer
`linha[0]`. Para pegar os outros caracteres, `linha[1..]`.

O resto da linha, `restoLinha = linha[1..]` é composto de vários
números separados por espaço. O Ruby me fornece o método de
`string.split(pattern)`, que permite transformar a string em um
array dado aquele `pattern`. Experimentalmente verifiquei que
a quantidade de espaços entre os números é desconsiderado
ao pedir `restoLinha.split " "`:

```ruby
"123 abc def".split " "
# => ["123", "abc", "def"]
"123   abc      def".split " "
# => ["123", "abc", "def"]
```

Pelo jeito como o arquivo foi separado, podemos pegar cada elemento
desse do vetor e transformar em ponto flutuante (método `to_f`),
assim teremos eles na versão numérica para calcular:

```ruby
restoLinha.split(" ").map do |n|
    n.to_f
end
```

Como tenho o número, basta fazer a transformação adequada para sair
de 27 para 16 pixels: multiplicar por `16/27`:

```ruby
restoLinha.split(" ").map do |n|
    n.to_f * (16.0/27.0)
end
```

E para gerar a linha depois, só juntar com o comando a esquerda e pedir uma
junção do array. Algo assim:

```ruby
linha_transformada = linha[0] + restoLinha.split(" ").map do |n|
    n.to_f * (16.0/27.0)
end.join(" ")
novas_linhas.append(linha_transformada)
```

Agora, na real? Essa variável `restoLinha` parece que meio que perdeu
o sentido, posso trocar ela pelo seu dado de origem:

```ruby
linha_transformada = linha[0] + linha[1..].split(" ").map do |n|
    n.to_f * (16.0/27.0)
end.join(" ")
novas_linhas.append(linha_transformada)
```

Juntando tudo?


```ruby
linhas = IO.readlines "./icon-pixme-linha-separada.svg"

novas_linhas = []
lendoPath = false

for linha in linhas do
    linha = linha.strip
    if lendoPath then
        if linha.start_with? '"' then
            lendoPath = false
            novas_linhas.append linha
        else
            linha_transformada = linha[0] + linha[1..].split(" ").map do |n|
                n.to_f * (16.0/27.0)
            end.join(" ")
            novas_linhas.append(linha_transformada)
        end
    else
        if linha.end_with? 'd="' then
           lendoPath = true 
        end
        novas_linhas.append linha
    end
end

# tratando a primeira linha
novas_linhas[0] = novas_linhas[0].sub("0 0 27 27", "0 0 16 16")
puts novas_linhas.join "\n"
```

Saída:

```xml
<svg viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" fill-rule="evenodd" clip-rule="evenodd" stroke-linejoin="round" stroke-miterlimit="1.414">
<path opacity="1" d="
M13.25908148148148 2.4794666666666667
L13.505303703703703 2.4837451851851853
```

E pronto, transformamos. Bem, na real _quase_, porque para importar o SVG precisa ser em uma única
linha. Basicamente a resposta foi fazer tudo do jeito que estava porém fazer join sem parâmetro:

```ruby
puts novas_linhas.join
```

Pronto, tudo sanado e logo transformada. Você pode ver o script ruby completo aqui no
[`transform.rb`]({{ site.repository.blob_root }}/{{ page.base-assets }}/transform.rb).

## Adicionando comportamento de alt-text

Senti uma falta de alt-text ao colocar o cafezinho. Como resolver?

Bem, achei uma fica no [CSS Tricks](https://css-tricks.com/accessible-svgs/):
tag `<title>` dentro do SVG. Ela funciona na prática como alt-text para o
meu fim.

Então, dentro do SVG, adicionei:

```xml
<svg ...>
    <title>Me compra um café 🥺</title>
    <path .../>
</svg>
```

O ícone ficou assim: <span class="icon">{% include icon-pixme.svg %}</span>.

Para usar aqui para indicar o café achei que seria mais adequado
não colocar o alt-text.

## O botão do café

Bem, inicialmente o café no meio do texto era só um ícone. Depois
eu senti a necessidade de transformar ele em algo mais interativo
e com isso surgiu a necessidade de tornar ele clicável. Mas
eu fiz isso a nível apenas de colocar um `onclick` na tag HTML,
não era algo semântico. Então, que tal, colocar dois elementos
internos idêncos cujo invólucro apareça de acordo com o
`@media` query adequada?

Daí surgiu a ideia de colocar tanto um `<span>` (para visão completa)
e um `<button>` (para indicar ação). No `<span>` temos um `<a>`
envolvendo o `<span>` com um `href` para `#pixmeacoffe`, para focar no
`iframe`.

No caso do `<button>` focar no `<iframe>` foi um pouco mais complicado.
Só faz sentido focar no `<iframe>` se eu estiver colocando o `<iframe>`
para ser visível, e só faz sentido focar depois de mandar ser visível.
Não fiz a transação mais suave possível, mas consegui fazer.

No caso, para simular o "ir para o elemento específico" precisa
manipular o `window.location` (ou `window.location.href`, são [APIs
compatíveis nesse sentido](https://stackoverflow.com/a/1226718/4438007)).
Pode ler mais na
[documentação da `Window.location API`](https://developer.mozilla.org/en-US/docs/Web/API/Window/location).

Em um primeira momento procurei pelo fragmento da URL e não achei
algo semelhante em `window.location`. Não havendo imediatamente, fui atrás
de controlar o fragmento através do `href`. Quando havia um elemento
previamente selecionado, bastaria substituir tudo que tivesse depois do
`#` por `#${id}`. Uma solução que permite essa substituição é usar
uma regex que casa com `#` e vai até o fim da string: `/#.*$`.
Então trocaria por `#pixmeacoffe`. Para manter a generalidade
no JS, posso usar a interpolação de string:

```js
const focusElementByIdIfAlreadyFragment = (id) => {
    window.location.href = window.location.href.replace(/#.*$/, `#${id}`);
}
```

Mas essa substituição só funciona se tiver um `#`. E na ausência?
Bem, na ausência basta concatenar o `#${id}`:

```js
const focusElementByIdIfNoFragment = (id) => {
    window.location.href += `#${id}`;
}
```

Juntando as duas, basta detectar a presença de um `#` na representação
em string do `window.location`:

```js
const focusElementById = (id) => {
    if (window.location.toString().includes("#")) {
        window.location.href = window.location.href.replace(/#.*$/, `#${id}`);
    } else {
        window.location.href += `#${id}`;
    }
}
```

Porém descobri posteriormente que esse trabalho todo já havia sido
feito, mas em uma API com um nome que eu não esperava:
[`.hash`](https://developer.mozilla.org/en-US/docs/Web/API/Location/hash).
O que simplifica o código:

```js
const focusElementById = (id) => {
    window.location.hash = `#${id}`;
}
```

Agora, para garantir o sumiço das coisas? Preciso manipular os pontos
de quebra da `@media` query:

```css
@media (max-width: 800px) {
    .hide-on-mobile {
        display: none;
    }
}
@media (min-width: 801px) {
    .hide-on-full {
        display: none;
    }
}
```

Desse jeito, ao colocar a classe `hide-on-full`, o elemento não é mostrado
quando se tem uma largura mínima de 801px. E de modo semelhante o
`hide-on-mobile` só se esconde até a largura máxima de 800px. Para
consultar a largura da tela você pode usar
[`window.innerWidth`](https://developer.mozilla.org/en-US/docs/Web/API/Window/innerWidth).
Usei isso para debugar o ponto de quebra padrão do Computaria.

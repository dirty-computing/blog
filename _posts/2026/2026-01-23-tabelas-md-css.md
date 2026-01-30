---
layout: post
title: "Fazendo bootstrapping de tabelas aqui no blog"
author: "Jefferson Quesado"
tags: meta markdown liquid table css sass html
---

No começo do Computaria, eu tentei usar as tabelas do markdown no tema padrão
(que eu acredito ser uma variação do
[`Minima`](https://github.com/jekyll/minima), se não o próprio `Minima`),
criado a partir do exemplo fornecido pelo GitLab.

> O começo foi descrito em
> [Criando o blog com Jekyll no GitLab]({% post_url 2021/2021-08-30-criando-blog-jekyll %})

Porém, eu não obtive um resultado satisfatório:

|   A   |   B   |  output  |
| :---: | :---: |  :---:   |
|   0   |   0   |    0     |
|   1   |   0   |    1     |
|   0   |   1   |    1     |
|   1   |   1   |    1     |

Aqui não tem colunas, fica visualmente... esquisito. E, bem, tem indícios que
eu tentei resolver esse problema
[desde 2022]({{ site.repository.base }}/-/commit/f065e9208df4451520bbf47711fa4ab99a517414).
Mas eu commitei a primeira vez algo com alguma relevância em relação a isso
quando criei a [página de gerenciamento]({% link managerial.md %}) das opções
do blog, como mostrado
[neste commit do ano passado]({{ site.repository.base }}/-/commit/9da65618e2db3cfd0338d6bf136d89162c4f5ab2),
inclusive servindo de base para artigos que usavam tabelas de abril do mesmo
ano.

Mas essas alternativas ainda eram... conservadoras. Usando apenas HTML para
desenhar as tabelas. Mas então eu perdi o medo e fiz um experimento! E coloquei
pela primeira vez uma tabela com markdown neste post:
[Brincando com JMH: microbenchmarking em Java]({% post_url 2025/2025-09-02-microbenchmark-jmh %}).

Tomei algumas decisões questionáveis? Tomei. Entre elas colocar a classe
`marked-table` como tendo a `width` fixa para 90%. Inclusive isso ficou bem
feio no post
[Magia com XOR! Achando o elemento faltante de um array]({% post_url 2025/2025-07-17-xor-search-missing-array %}),
quando fui criar a tabela que relacionava o módulo de um valor por 4 e o valor
do operador `XOR` no intervalo fechado `[0..n]`, que usou 90% da tela com uma
tabelinha pequena e bestinha. Mas, sabe uma coisa legal? É fácil replicar o que
eu fiz lá!

O resultado visual era efetivamente esse aqui:

{:class="marked-table centered-head w90"}
| n % 4 | valor do XOR [0..n] |
| ----: |               ----: |
|     0 |                   n |
|     1 |                   1 |
|     2 |               n + 1 |
|     3 |                   0 |

E eu achei que iria ficar mais satisfatório algo assim:

{:class="marked-table centered-head"}
| n % 4 | valor do XOR [0..n] |
| ----: |               ----: |
|     0 |                   n |
|     1 |                   1 |
|     2 |               n + 1 |
|     3 |                   0 |

> Inclusive se você for agora conferir o post a tabela vai estar com o layout
> atualizado, ocupando menos tela.

Vamos começar vendo a solução desde o começo?

# A solução temporária

Inicialmente, não quis forçar um estilo único de tabela. Existem motivos para
estilizar a tabela de outras maneiras que não se marque toda e qualquer divisão
de coluna ou de linha (tem um post que usa isso **fortemente** como rascunho
durante a escrita deste post, mas também tem o exemplo que o Camilo fez no
artigo
[Criando um toggle de tema pro Computaria usando a malandragem do CSS]({% post_url 2025/2025-08-02-temas_com_css %}),
que não só não precisou estilizar a tabela com isso como também tentar
estilizar a tabela de modo a destacar separação de células iria ficar feio).

Portanto, tentar colocar um estilo para ficar de maneira irrestrita para todo e
qualquer `<table>` para mim é um "no-go". Logo, minha conclusão é que eu
preciso marcar explicitamente as tabelas que eu gostaria de que tivessem esse
estilo. E, sinceramente? Para mim tudo bem.

Para alcançar esse fim, criei uma classe `lalala` com o estilo que eu precisava
dentro de um `<style>` nas publicações:

```html
<style>
    table.lalala {
        border: 1px solid gray;
        width: 90%
    }
    table.lalala tr {
        /* width: 90% */
    }
    table.lalala th {
        border: 1px solid gray;
        font-weight: bold;
    }
    table.lalala td {
        border: 1px solid gray;
    }
</style>

<table class="lalala">
    ...
</table>
```

E isso atendeu bem meus casos iniciais.

# A unificação

Ok, usar `lalala` em produção não é bem a coisa mais legível, semântica e
escalável para nome de variável, né? O que eu queria fazer com isso?
Basicamente indicar que aquela tabela estava marcada para renderizar daquela
maneira, com as células devidamente marcadas. Então o ponto da unificação
partiu da criação de um nome que identificasse esse conceito: `marked-table`.

Durante a escrita do
[Magia com XOR! Achando o elemento faltante de um array]({% post_url 2025/2025-07-17-xor-search-missing-array %})
foi necessário usar tabelas com valores numéricos, então foi criada uma classe
a mais para poder fazer o alinhamento correto dos números. E essa classe foi
chamada de... muito criativamente, `numeric`. Então foi feita a unificação via
SASS:

```scss
table.marked-table {
    border: 1px solid gray;
    width: 90%;

    th {
        border: 1px solid gray;
        font-weight: bold;
    }
    td {
        border: 1px solid gray;
    }
}

.marked-table.numeric {
    td {
        text-align: right;
    }
}
```

E isso foi o início de uma Era em que eu poderia usar tabelas no blog e ter o
visual que eu achasse minimamente mais adequado para leitura! Sofisticado? Não,
apenas minimamente funcional.

# Migração para markdown

Isso deu certo para usar através do elemento HTML. E as vezes no HTML ficava um
tanto quanto incômodo usar o markdown dentro das células: toda vida era
necessário colocar o atributo `markdown="1"` dentro da tag HTML "folha" para
poder inserir markdown dentro, de modo feliz, como descrito em
[Refatorando página de podcasts]({% post_url 2025/2025-03-07-refactor-podcasts %}).

Para uso ocasional dentro de uma coisa ou outra, essa abordagem até que é ok,
mas para usar em tabelas que precisa lembrar das células... isso fica um
tanto quanto mais chato e propenso a erros.

Logo, o ideal seria usar a tabela do markdown propriamente dita para fazer
isso! Então... como faço para inserir atributos no HTML a ser renderizado pelo
kramdown? Ah, eu uso o kramdown para renderizar o markdown, era a opção padrão
que vinha no template do Jekyll, e ele me atende satisfatoriamente bem.

E, olha que legal, eu consigo sim ensinar ao kramdown coisas para serem
inseridas como atirbutos HTML de um nó!

## Uma tangente: começando uma lista de outro número

> O texto abaixo foi gerado para um outro artigo, mas como esse texto das
> tabelas evoluiu mais rápido, acabei por adaptar o texto para caber aqui. Se
> algo ficar muito deslocado, mencionar algo que não existe, bem, já sabe, né?
> Foi adaptação de contexto que não foi feita completamente.

Que tal começar uma itemização de algo que começa não no número 1, mas, sei lá,
no número 3? Que eu pudesse enumerar alguns itens, quebrar com texto corrido
normal em parágrafos, e depois retomar a enumeração?

De modo geral, queria fazer algo nessa pegada:

{% verbatim_etc md %}
Lorem ipsum

1. dolor
2. sit

Amet.

3. consectetur
4. adipiscing
5. elit
{% endverbatim_etc %}

Porém... não renderizou legal, né?

> OBS: Se por acaso renderizou corretamente, é um sinal de que eu mudei o
> renderizador de markdown e portanto isso não faz mais sentido, e seria melhor
> eu "emular" o comportamento original mudando o `3. consectur` para
> `1. consectur`. Se isso acontecer, me mande uma mesagem, abre uma issue, mas
> isso significa que o blog evoluiu e eu esqueci de dar manutenção em coisa do
> passado.

Ou seja, não renderiza como eu quero. Ele volta a contar do 1.

Mas eu não desisto! Eu sei que eu poderia alterar o renderizador de markdown
para outra coisa que não o padrão do Jekyll? Sim, sei. Mas estou usando o
padrão do Jekyll! Que é o Kramdown!

Então me deparei com
[esta resposta no Stack Overflow](https://stackoverflow.com/a/48612359/4438007).
Ela contém exatamente a minha dor e dúvida. E, claro o autor dá um exemplo e
ainda explica como fazer isso! Que no caso é "passando atributos" do markdown
para o html.

Ficaria assim o exemplo do _lorem ipsum_:

{% verbatim_etc md %}
Lorem ipsum

1. dolor
2. sit

Amet.

{:start="3"}
3. consectetur
4. adipiscing
5. elit
{% endverbatim_etc %}

Pronto, assim eu passei um elemento para o `<ol>` gerado. Renderizando bem
melhor agora, né?

Note que isso não é Liquid, mas uma especificidade do Kramdown e de como ele
lida com markdown. Por exemplo, posso adicionar uma classe CSS com fundo rosa:

```css
.fundo-rosa {
    background-color: deeppink;
}
```

<style>
.fundo-rosa {
    background-color: deeppink;
}
</style>

E então posso adicionar isso a um parágrafo talvez?

{% verbatim_etc md %}
{:class="fundo-rosa"}
Lorem ipsum dolor sit amet.

Consectetur adipiscing elit.
{% endverbatim_etc %}

Hmmm, e para um link, será que vai?

{% verbatim_etc md %}{%- raw -%}
Lorem ipsum {:class="fundo-rosa"}[link do blog]({{ site.url }}).
{% endraw %}{% endverbatim_etc %}

Bem, não foi nessa que eu passei para um element in-line... e se eu botar o
`{:class}` no começo da linha mantendo o parágrafo?

{% verbatim_etc md %}{%- raw -%}
Lorem ipsum
{:class="fundo-rosa"}[link do blog]({{ site.url }}).
{% endraw %}{% endverbatim_etc %}

Também não foi... enfim, última tentativa? Deixar em uma linha sozinho?

{% verbatim_etc md %}{%- raw -%}
Lorem ipsum
{:class="fundo-rosa"}
[link do blog]({{ site.url }}).
{% endraw %}{% endverbatim_etc %}

Hmmm, interessante... o fundo rosa acabou pintando o que veio *antes*! E se...
eu trocar a ordem? E pedir para colocar a classe após a URL?

{% verbatim_etc md %}{%- raw -%}
Lorem ipsum [link do blog]({{ site.url }}){:class="fundo-rosa"}.
{% endraw %}{% endverbatim_etc %}

YAY! Funcionou!

Nada como meia hora de tentativa e erro para aprender algo que tem na
[documentação](https://kramdown.gettalong.org/syntax.html#inline-attribute-lists)
que eu poderia ter consultado em menos de 5 minutos. Mas... acho que o
aprendizado na tentativa serviu para eu criar alguma espécie de memória do
episódio.

Agora eu posso ter uma flexibilidade maior na hora de querer fazer as coisas no
blog. Blocos de alerta mais especiais, sei lá. Com a mecânica nova, eu posso
desbravar em novas regras.

## Usando no markdown

Basicamente, eu indico com esse bloco especial que eu quero preencher o
atributo `class` do meu nó:

{% verbatim_etc md %}
{:class="marked-table w90"}
|   A   |   B   |  output  |
| :---: | :---: |  :---:   |
|   0   |   0   |    0     |
|   1   |   0   |    1     |
|   0   |   1   |    1     |
|   1   |   1   |    1     |
{% endverbatim_etc %}

E basicamente é isso.

# Ajustes no estilo

Não poderia ficar apenas com isso, não é? Bem, para começar, usar tudo com
`width: 90%` foi um erro, e já tem um spoiler acima de como eu resolvi isso:
criei uma classe auxiliar para indicar isso.

Em uma vibe inspirada de muito longe o que eu vi as pessoas fazendo com
[Tailwind css](https://tailwindcss.com/), uma classe utilitária que indica o
desejo de algo com largura de 90%:

```scss
.w90 {
  width: 90%;
}
```

E essa diretriz foi removida do `table.marked-table`:

```scss

table.marked-table {
  border: 1px solid gray;

  th {
    border: 1px solid gray;
    font-weight: bold;
  }
  td {
    border: 1px solid gray;
  }
}
```

Mas, mesmo assim, isso ainda me trouxe um inconveniente... Por exemplo, ao
tentar alinhas os números à direita (o caso de uso que a classe `numeric`
emulava), o cabeçalho acabou ficando também alinhado à direita:

{% verbatim_etc %}
{:class="marked-table w90"}
| a     | b     | c     | a^b^c | a^b   | b^c   |
| ----: | ----: | ----: | ----: | ----: | ----: |
| 0     | 0     | 0     | 0     | 0     | 0     |
| 1     | 0     | 0     | 1     | 1     | 0     |
| 0     | 1     | 0     | 1     | 1     | 1     |
| 1     | 1     | 0     | 0     | 0     | 1     |
| 0     | 0     | 1     | 1     | 0     | 1     |
| 1     | 0     | 1     | 0     | 1     | 1     |
| 0     | 1     | 1     | 0     | 1     | 0     |
| 1     | 1     | 1     | 1     | 0     | 0     |
{% endverbatim_etc %}

Mas eu queria na verdade que o cabeçalho ficasse centralizado, algo assim:

{:class="marked-table w90 centered-head"}
| a     | b     | c     | a^b^c | a^b   | b^c   |
| ----: | ----: | ----: | ----: | ----: | ----: |
| 0     | 0     | 0     | 0     | 0     | 0     |
| 1     | 0     | 0     | 1     | 1     | 0     |
| 0     | 1     | 0     | 1     | 1     | 1     |
| 1     | 1     | 0     | 0     | 0     | 1     |
| 0     | 0     | 1     | 1     | 0     | 1     |
| 1     | 0     | 1     | 0     | 1     | 1     |
| 0     | 1     | 1     | 0     | 1     | 0     |
| 1     | 1     | 1     | 1     | 0     | 0     |

Então, como contornar isso? Bem, aqui eu vou precisar marcar que eu quero que o
cabeçalho da tabela específica fique centralizado, não pegar algo e generalizar
(sempre isso, né?). Então vou precisar criar uma classe para esse fim. E, bem,
essa classe eu só preciso que ela seja de algo dentro de `table.marked-table`,
e que afete apenas `th` descendente disso. Em termos de seletor CSS, seria algo
assim o resultado desejado:

```css
table.marked-table.centered-head th {
    /* ... */
}
```

Mas eu posso pegar um aprendizado que o Camilo deixou para mim no artigo
[Criando um toggle de tema pro Computaria usando a malandragem do CSS]({% post_url 2025/2025-08-02-temas_com_css %}):
usar o `&` do SASS! Então com isso cheguei nesse código:

```scss
table.marked-table {
  border: 1px solid gray;

  &.centered-head th {
    /* ... */
  }

  th {
    border: 1px solid gray;
    font-weight: bold;
  }
  td {
    border: 1px solid gray;
  }
}
```

Agora eu preciso dar um jeito de mandar alinhar ao centro algo que estava sendo
alinhado a direita. Bem, como será que o kramdown está compilando a tabela?
Vamos inspecionar o componente da web e...

```html
<th style="text-align: right">a</th>
<th style="text-align: right">b</th>
<th style="text-align: right">c</th>
<th style="text-align: right">a^b^c</th>
<th style="text-align: right">a^b</th>
<th style="text-align: right">b^c</th>
```

Ué? Bem, é isso, quando colocamos a posição que desejo alinhar na tabela ele
insere esse `style` como atributo:

{% verbatim_etc md %}
{:class="marked-table w90"}
| neutro | esquerda | centro | direita |
| ------ | :------- | :----: | ------: |
| 0      | 0        | 0      | 0       |
| 1      | 0        | 0      | 1       |
| 0      | 1        | 0      | 1       |
| 1      | 1        | 0      | 0       |
| 0      | 0        | 1      | 1       |
| 1      | 0        | 1      | 0       |
| 0      | 1        | 1      | 0       |
| 1      | 1        | 1      | 1       |
{% endverbatim_etc %}


E o HTML renderizado para o cabeçalho foi esse:

```html
      <th>neutro</th>
      <th style="text-align: left">esquerda</th>
      <th style="text-align: center">centro</th>
      <th style="text-align: right">direita</th>
```

Ok, como venço um `style` inline no próprio HTML? Não tem muito jeito, é
usando `!important`:

```scss
table.marked-table {
  border: 1px solid gray;

  &.centered-head th {
    text-align: center !important;
  }

  th {
    border: 1px solid gray;
    font-weight: bold;
  }
  td {
    border: 1px solid gray;
  }
}
```

> Ah, mas você poderia ajeitar o kramdown para não gerar assim o estilo do
> alinhamento da coluna...

Shhhh 🤫

Aqui eu estou pela solução simples, que funciona e é trivialmente repetível.

Enfim, para conseguir gerar da maneira adequada e para o post
[Magia com XOR! Achando o elemento faltante de um array]({% post_url 2025/2025-07-17-xor-search-missing-array %})
ficar renderizando adequadamente, basta adicionar a classe desejada que a
renderização ocorre corretamente:

{% verbatim_etc md %}
{:class="marked-table w90 centered-head"}
| neutro | esquerda | centro | direita |
| ------ | :------- | :----: | ------: |
| 0      | 0        | 0      | 0       |
| 1      | 0        | 0      | 1       |
| 0      | 1        | 0      | 1       |
| 1      | 1        | 0      | 0       |
| 0      | 0        | 1      | 1       |
| 1      | 0        | 1      | 0       |
| 0      | 1        | 1      | 0       |
| 1      | 1        | 1      | 1       |
{% endverbatim_etc %}

O HTML gerado é o mesmo de cima, mas aqui o `!important` no `text-align` fez
com que o style inline fosse ignorado para esse caso específico.

Ah, sim, e com isso agora de usar opções do próprio markdown para fazer esse
tipo de alinhamento não tenho mais nenhum uso para a classe `numeric`... então
após esses ajustes a classe foi simplesmente apagada.

O [Gerancial]({% link managerial.md %}) não foi adaptado para usar a tabela de
markdown, a geração de tabelas dele mesmo já era complicada o suficiente e
nesse caso tentar forçar markdown só iria dificultar as coisas, já que as
células são previstas para serem multi-linhas.

# Voltando pra tabelinha do começo

Bem, vamos voltar para a tabelinha que começou tudo:

{% verbatim_etc %}
|   A   |   B   |  output  |
| :---: | :---: |  :---:   |
|   0   |   0   |    0     |
|   1   |   0   |    1     |
|   0   |   1   |    1     |
|   1   |   1   |    1     |
{% endverbatim_etc %}

Xoxa, capenga, manca, anêmica, frágil e inconsistente... vamos adicionar a
classe para ela ser uma tabela marcada?

{% verbatim_etc md %}
{:class="marked-table"}
|   A   |   B   |  output  |
| :---: | :---: |  :---:   |
|   0   |   0   |    0     |
|   1   |   0   |    1     |
|   0   |   1   |    1     |
|   1   |   1   |    1     |
{% endverbatim_etc %}

E se não estiver satisfeito, podemos ocupar boa parte horizontal também:

{% verbatim_etc md %}
{:class="marked-table w90"}
|   A   |   B   |  output  |
| :---: | :---: |  :---:   |
|   0   |   0   |    0     |
|   1   |   0   |    1     |
|   0   |   1   |    1     |
|   1   |   1   |    1     |
{% endverbatim_etc %}

Hmmm, como essa tabela foi desenhada originalmente para falar sobre operadores
de
[lógica booleana com carangueijos]( post_url 2026/2026-01-29-completude-funcional %})
(yep, acredite), podemos colocar os números à direita:

{% verbatim_etc md %}
{:class="marked-table w90"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    0     |
|   1   |   0   |    1     |
|   0   |   1   |    1     |
|   1   |   1   |    1     |
{% endverbatim_etc %}

E se estiver insatisfeito com isso por que o header saiu do centro? Só pedir
para alinhar o header!

{% verbatim_etc md %}
{:class="marked-table w90 centered-head"}
|   A   |   B   |  output  |
| ----: | ----: |  ----:   |
|   0   |   0   |    0     |
|   1   |   0   |    1     |
|   0   |   1   |    1     |
|   1   |   1   |    1     |
{% endverbatim_etc %}
---
layout: post
title: "Usando data files para redes sociais"
author: "Jefferson Quesado"
tags: jekyll meta liquid
base-assets: "/assets/jekyll-data-files/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Recentemente comecei a federar as coisas do Computaria no
[dev.to](https://dev.to/jeffque). E percebi sabe o quê? Que não tinha menção à
minha conta do [dev.to](https://dev.to/jeffque) no footer. Tenho diversas
outras redes sociais, mas não essa conta específica.

Então vamos adicionar?

# Antes

Originalmente eu adicionava na mão todos os detalhes do
[`footer`]({{ site.repository.blob_root }}/_includes/footer.html). O formato
original era adicionar um elemento na lista:

{% raw %}
```html
<div class="footer-col footer-col-2">
  <ul class="social-media-list">
    {% if site.gitlab_username %}
      <li>
        {% include icon-gitlab.html username=site.gitlab_username %}
      </li>
    {% endif %}
    <!-- outros elementos -->
  </ul>
</div>
```
{% endraw %}

É uma lista uniforme seguindo sempre a mesma exata lógica:

- se eu tiver um user name
- adiciona um `<li>` cujo conteúdo é um `icon-<media>.html` passando como
  argumento `username=<usuário checado antes>`

E qual o formato geral do `icon-<media>.html`? Por exemplo, o
[`icon-gitlab.html`]({{ site.repository.blob_root }}/_includes/icon-gitlab.html)?
(Exibido aqui _pretty-printed_)

{% raw %}
```html
<a href="https://gitlab.com/{{ include.username }}">
    <span class="icon icon--gitlab">{% include icon-gitlab.svg %}</span>
    <span class="username">{{ include.username }}</span>
</a>
```
{% endraw %}

Basicamente um link `<a>` com href usando o `username` passado como parâmetro.
O conteúdo é um `<span>` com classes `icon` e `icon--<media>`, e o conteúdo
desse `<span>` é um SVG incluído via Liquid:
{%- raw %}`{% include icon-<media>.svg %}`{% endraw %}.

E depois tem um `span` com o `username` com a classe `username`.

Então, manter isso é bem trabalhoso... gostaria de um jeito que não precisar
fazer tudo isso na mão.

# O que é comum

Basicamente, a única coisa que realmente é única para cada elemento é o SVG de
cada rede. De resto, poderíamos ter, em termos de Liquid:

{% raw %}
```html
<a href="{{ include.media_base_url}}/{{ include.username }}">
    <span class="icon icon--{{include.media_name}}">{% include icon-{{include.media_name}}.svg %}</span>
    <span class="username">{{ include.username }}</span>
</a>
```
{% endraw %}

# Testando o Liquid

Ok, vamos tentar renderizar o link do gitlab. Primeiramente, criar o ícone
template para incluir os links. Vou abstrair no
[`_includes/social/icon.html`]({{ site.repository.blob_root }}/_includes/social/icon.html).

Vamos testar? Vou colocar dentro do `<ul>` com a classe adequada para efeitos
de exibição, para pegar as classes corretas. Vou também por em primeiro lugar o
ícone original usado do gitlab e depois o ícone comum:

{% raw %}
```html
<ul class="social-media-list">
    <li>{% include icon-gitlab.html
                   username=site.gitlab_username %}</li>
    <li>{% include social/icon.html
                   username=site.gitlab_username
                   media_base_url="https://gitlab.com/"
                   media_name="gitlab" %}</li>
</ul>
```
{% endraw %}

<ul class="social-media-list">
    <li>{% include icon-gitlab.html
                   username=site.gitlab_username %}</li>
    <li>{% include social/icon.html
                   username=site.gitlab_username
                   media_base_url="https://gitlab.com/"
                   media_name="gitlab" %}</li>
</ul>

Bem, foi sucesso, os dois ícones ficaram iguais, a única diferença foi uma
barra a mais na URL dentro do href. Mas isso não é crítico e não interfere nada
por hora.

# Refatorando: datafiles

Para evitar ficar dando a manutenção manual em cada item individual, resolvi
usar uma espécie de banco de dados de arquivo. Isso permite que eu consiga
trabalhar sem me preocupar em montar manualmente cada elemento. E o Jekyll
oferece já uma solução: [datafiles](https://jekyllrb.com/docs/datafiles/).

Vamos criar um desses datafiles?
[`_data/social_media.yaml`]({{ site.repository.blob_root }}/_data/social_media.yaml).

Primeiro, só para ver se de fato vai ter alguma iteração:

{% raw %}
```liquid
{% for social_media in site.data.social_media %}
oi oi oi
{% endfor %}
```
{% endraw %}

{% for social_media in site.data.social_media %}
oi oi oi
{% endfor %}

Muito bom, de fato iterou. Agora, vamos listar os atributos? Por em um `<li>`
sem pretenção, separado por vírgulas. Pelo experimento anterior eu preciso de 3
atributos:

- `media_name`
- `username`
- `media_base_url`

Vamos ver como fica?

{% raw %}
```liquid
<ul>
{% for social_media in site.data.social_media %}
    <li>
        {{social_media.media_name}}, {{social_media.username}}, {{social_media.media_base_url}}
    </li>
{% endfor %}
</ul>
```
{% endraw %}

Os dados:

```yaml
- media_name: "gitlab"
  username: site.gitlab_username
  media_base_url: "https://gitlab.com/"
- media_name: "github"
  username: site.github_username
  media_base_url: "https://github.com/"
```

Renderizou assim (eu fiz algumas alterações nos dados depois):

<ul>

    <li>
        gitlab, site.gitlab_username, https://gitlab.com/
    </li>

    <li>
        github, site.github_username, https://github.com/
    </li>

</ul>

Hmmm, eu queria ter acesso a dados do `_config.yml` onde já tenho o
`gitlab_username` e outras coisas, e isso não deu certo. Eu queria poder
cadastrar isso como referências, não literais. Mas como eu consigo testar se
isso funciona mesmo?

Primeiro teste, botar duas vezes a expansão Liquid, {%- raw -%} algo como
`{{ {{ "site.gitlab_username" }} }}`{% endraw %}?

Nah, não funcionou como eu esperava...

![Erro de Liquid: abrir chave não esperado]({{ page.base-assets | append: "dupla-dupla-chave.png" | relative_url }})

Hmmm, procurando um pouco mais sobre Liquid achei essas outras documentações:

- [Liquid](https://shopify.github.io/liquid/basics/introduction/)
- [Shopify Liquid](https://shopify.dev/docs/api/liquid/basics)

E no Shopify Liquid achei uma referência ao operador `[]` na expansão de
valores. Então, vamos testar? Pela doc, {%- raw -%}
`{{ site.gitlab_username }}` deveria renderizar igual a
`{{ site["gitlab_username"] }}`{% endraw %}. Vamos testar?

{% raw %}
```liquid
<ul>
    <li>{{ site.gitlab_username }}</li>
    <li>{{ site["gitlab_username"] }}</li>
</ul>
```
{% endraw %}

<ul>
    <li>{{ site.gitlab_username }}</li>
    <li>{{ site["gitlab_username"] }}</li>
</ul>

Funcionou!! Vamos refazer o experimento de como renderizar? Ajustando para usar
o `[]`:

{% raw %}
```liquid
<ul>
{% for social_media in site.data.social_media %}
    <li>
        {{social_media.media_name}}, {{ site[social_media.username]}}, {{social_media.media_base_url}}
    </li>
{% endfor %}
</ul>
```
{% endraw %}


Os dados:

```yaml
- media_name: "github"
  username: github_username
  media_base_url: "https://github.com/"
- media_name: "gitlab"
  username: gitlab_username
  media_base_url: "https://gitlab.com/"
```

Renderizou assim (eu fiz algumas alterações nos dados depois):

<ul>

    <li>
        gitlab, jefferson.quesado, https://gitlab.com/
    </li>

    <li>
        github, jeffque, https://github.com/
    </li>

</ul>

Massa!

## Alterando o footer

Vamos alterar o footer. No lugar de usar literalmente cada verificação, vou
simplesmente usar o datafile:

{% raw %}
```html
<ul class="social-media-list">
    {% for social_media in site.data.social_media %}
    <li>{% include social/icon.html
                   username=site[social_media.username]
                   media_base_url=social_media.media_base_url
                   media_name=social_media.media_name %}</li>
    {% endfor %}
</ul>
```
{% endraw %}

E...

![Sintaxe inválida, username=site[social_media.username]]({{ page.base-assets | append: "erro-liquid.png" | relative_url }})

Ok, ok... e se no lugar de usar diretamente o `site[social_media.username]` eu
atribuir a uma variável?

{% raw %}
```html
<ul class="social-media-list">
    {% for social_media in site.data.social_media -%}
    {%- assign username = site[social_media.username] -%}
    <li>{%- include social/icon.html
                   username=username
                   media_base_url=social_media.media_base_url
                   media_name=social_media.media_name -%}</li>
    {% endfor %}
</ul>
```
{% endraw %}

Para temporariamente esses dados:

```yaml
- media_name: "gitlab"
  username: gitlab_username
  media_base_url: "https://gitlab.com/"
- media_name: "github"
  username: github_username
  media_base_url: "https://github.com/"
```

Renderizou assim

<ul class="social-media-list">
    <li><a href="https://gitlab.com//jefferson.quesado"><span class="icon icon--gitlab">{% include icon-gitlab.svg %}</span><span class="username">jefferson.quesado</span></a></li>
    <li><a href="https://github.com//jeffque"><span class="icon icon--github">{% include icon-github.svg %}</span><span class="username">jeffque</span></a></li>
</ul>

Muito bem, hora de expandir

### Um parêntese antes de expandir, controlando o espaçamento

Na real, a renderização foi (com exceção do SVG) assim:

{% raw %}
```html
<ul class="social-media-list">
  
  
  <li><a href="https://gitlab.com//jefferson.quesado"><span class="icon icon--gitlab">{% include icon-gitlab.svg %}
</span><span class="username">jefferson.quesado</span></a></li>
  
  
  <li><a href="https://github.com//jeffque"><span class="icon icon--github">{% include icon-github.svg %}
</span><span class="username">jeffque</span></a></li>
  
</ul>
```
{% endraw %}

E isso tinha muito espaço em branco. Vou colocar aqui o diff da versão que
renderizou com esses espaços para o da versão que gerou sem o excesso de
espaços:

{% raw %}
```diff
 <ul class="social-media-list">
-    {% for social_media in site.data.social_media %}
-    {% assign username = site[social_media.username] %}
-    <li>{% include social/icon.html
+    {% for social_media in site.data.social_media -%}
+    {%- assign username = site[social_media.username] -%}
+    <li>{%- include social/icon.html
                    username=username
                    media_base_url=social_media.media_base_url
-                   media_name=social_media.media_name %}</li>
+                   media_name=social_media.media_name -%}</li>
     {% endfor %}
 </ul>
```
{% endraw %}

Notou a diferença? Foram só os tracinhos nos filtros. Isso permitiu fazer o
controle de espaços. Colocar o traço no começo do `for` causou uma ausência
muito grande de espaços que me incomodou, o `<li>` encostado no `<ul>`.

## A exceção: StackOverflow

Bem, o StackOverflow segue um outro padrão que não uma URL seguido do nome do
usuário. O padrão é:

```text
https://pt.stackoverflow.com/users/<userid>/<username>
```

Ou seja, agora tenho duas variáveis, não apenas uma. Inclusive o mais
importante é o ID para mostrar o usuário correto. Inclusive, ao tentar acessar
[https://pt.stackoverflow.com/users/64969/](https://pt.stackoverflow.com/users/64969/),
você é direcionado para
[https://pt.stackoverflow.com/users/64969/jefferson-quesado](https://pt.stackoverflow.com/users/64969/jefferson-quesado).

Vamos definir um novo campo no yaml: `media_url_literal`. Posto isto, não se
faz necessário mais a construção da URL. Vamos passar isso adiante e deixar com
o `icon` para lidar com qual usar.

No `href`, vou por para renderizar o `include.media_url_literal` se ele
existir, caso contrário vou para o método de construção de URL em cima do
`username` que já tinha antes:

{% raw %}
```html
<a href="{%- if include.media_url_literal -%}{{include.media_url_literal}}{%- else -%}{{ include.media_base_url }}/{{ include.username }}{% endif %}">
    <span class="icon icon--{{include.media_name}}">{% include icon-{{include.media_name}}.svg %}</span>
    <span class="username">{{ include.username }}</span>
</a>
```
{% endraw %}

E na chamada eu simplesmente passo o novo atributo:

{% raw %}
```liquid
{%- include social/icon.html
            username=username
            media_base_url=social_media.media_base_url
            media_url_literal=social_media.media_url_literal
            media_name=social_media.media_name -%}
```
{% endraw %}

## Username literal

Peguei outro caso excepcional: quando preciso lidar com nome literal, no lugar
de nome via referência. Para lidar com isso, aproveitei que já tinha uma
atribuição sendo feita à variável `username` e coloquei um trecho condicional.

{% raw %}
Saí disso:

```liquid
{%- assign username =  site[social_media.username] -%}
```

Para isso:

```liquid
{%- if social_media.username_literal -%}
  {%- assign username =  social_media.username_literal -%}
{%- else -%}
  {%- assign username =  site[social_media.username] -%}
{% endif %}
```

E assim consegui renderizar do jeito que eu queria.

Mas, sinceramente? Isso me parece um tanto quanto... cumbersome... muitos
comandos Liquid. Será que eu posso usar a tag
[`liquid`](https://shopify.github.io/liquid/tags/template/#liquid)?

Pelo que eu li, seria assim:

```liquid
{%- liquid
  if social_media.username_literal
    assign username =  social_media.username_literal
  else
    assign username =  site[social_media.username]
  endif
-%}
```
{% endraw %}

E a resposta é...

... não:

> Unknown tag 'liquid'

Ok, ao menos tentei. Talvez atualizar o Liquid usado no computaria no futuro?

## Escondendo o que não quero mostrar

Ok, não tenho gostado do ramo que o Twitter tomou, inclusive em maior parte saí
de lá. Mas... a rede social tá lá, né? Já que estou catalogando minhas redes
sociais, vou ao menos cadastrar o Twitter no meu datafile. Mas para isso
preciso também esconder ele, já que ativamente não quero mais mostrar.

Tentei inicialmente usar no `for` um filtro `where`, o que não deu muito
certo...

{% raw %}
```liquid
{% for social_media in social_media_shown | where: "show" %}
{% endfor %}
```
{% endraw %}

Não fez efeito algum. Então resolvi fazer o exemplo que estava vendo associado
ao `where`: colocar no `assign`.

Tentei isso

{% raw %}
```liquid
{% assign social_media_shown = site.data.social_media | where: "show" %}
```
{% endraw %}

e com isso obtive

> Liquid error (line 485): wrong number of arguments (given 2, expected 3)

Ué. Mas é bem dizer o exemplo do
[site](https://shopify.github.io/liquid/filters/where/)! Mas, será que... Bem,
o próprio Liquid admite que existem duas versões do Liquid, o Spotify Liquid e
o Jekyll Liquid. Será que eu peguei o caso em que diferenciam?

Vamos ver a documentação do Jekyll Liquid em relação ao
[`where`](https://jekyllrb.com/docs/liquid/filters/#where)...

> Select all the objects in an array where the key has the given value.

E o exemplo

{% raw %}
```liquid
{{ site.members | where:"graduation_year","2014" }}
```
{% endraw %}

É, peguei justamente o caso em que o Jekyll Liquid difere do padrão...

Mas olha que legal logo ali debaixo do `where`, em
[`where_exp`](https://jekyllrb.com/docs/liquid/filters/#where-expression)!

> Select all the objects in an array where the expression is true.

Com os exemplos:

{% raw %}
```liquid
{{ site.members | where_exp:"item", "item.graduation_year < 2014" }}
```
{% endraw %}

Ou seja, o primeiro argumento se torna o alias do elemento dentro da expressão,
e o segundo argumento é a expressão em si! Será que temos alguma expressão para
pegar apenas quem tem `show != false`?

{% raw %}
```liquid
{% assign social_media_shown = site.data.social_media | where_exp: "social_media", "social_media.show != false" %}
{%- for social_media in social_media_shown -%}
- {{social_media.media_name}}
{% endfor %}
```
{% endraw %}

{% assign social_media_shown = site.data.social_media | where_exp: "social_media", "social_media.show != false" %}
{%- for social_media in social_media_shown -%}
- {{social_media.media_name}}
{% endfor %}

Com o resultado esperado.

# Limpeza final

Basicamente os `icon-<media>.html` perderam sentido de ser. O
[`icon-gitlab.html`]({{ site.repository.blob_root }}/_includes/icon-gitlab.html)
vai ser mantido por conta do exemplo usado nesta publicação e também por conta
das coisas no [sobre]({{ "/about" | prepend: site.baseurl }}).

O `icon-stackoverflow` também é usado na mesma página. Então vou manter esses
dois. Já os outros não tem necessidade. Vou remover e deixar o
[`_includes`]({{ site.repository.tree_root }}/_includes) limpo.
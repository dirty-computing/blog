---
layout: post
title: "Ajuste no \"pequeno espaço\" das logos no rodapé do blog"
author: "Jefferson Quesado"
tags: meta html
base-assets: "/assets/pequeno-espaco-logos/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Por um tempo, uma coisa me incomodou MUITO no blog: no rodapé, na lista de
redes sociais, alguns logos apareciam com um espaçamento entre o logo da rede
específica e o nick, e outras não tinha o espaçamento.

E por muito tempo eu fiquei sem entender o que era isso! Por exemplo:

![Logo do Bluesky sem espaço para o username]({{ page.base-assets | append: "logos-sem-espaco.png" | relative_url }})

Note que o logo do Bluesky, do Instagram e do dev.to estão diferentes dos logos
do GitLab, GitHub e StackOverflow no print acima.

Esses logos eles foram adicionados aos poucos. Alguns vieram no template
(GitLab, GitHub, entre outros), outros foram surgindo aos poucos.

Minha primeira investigação foi em torno de tentar procurar alguma diferença no
CSS ou no HTML usado para representar esses elementos visualmente. Não
encontrei nada. Foquei nos elementos que foram adicionados principalmente
depois do post
[Usando data files para redes sociais]({% post_url 2025/2025-01-13-jekyll-data-files %}),
mas nada chamou a atenção.

Não havia algo diferente na estrutura do HTML, não tinha nenhum seletor CSS que
era disparado em alguns casos e outros não. Voltei-me então a o como eu tinha
feito a inserção das logos, o que foi imensamente facilitado graças à
centralizacão feita
[no post sobre isso]({% post_url 2025/2025-01-13-jekyll-data-files %}):

{% raw %}
```liquid
<div class="footer-col footer-col-2">
    <ul class="social-media-list">
        {%- assign social_media_shown = site.data.social_media | where_exp: "social_media", "social_media.show != false" -%}
        {% for social_media in social_media_shown -%}
        {%- if social_media.username_literal -%}
        {%- assign username =  social_media.username_literal -%}
        {%- else -%}
        {%- assign username =  site[social_media.username] -%}
        {% endif %}
        <li>{%- include social/icon.html
                        username=username
                        media_base_url=social_media.media_base_url
                        media_url_literal=social_media.media_url_literal
                        media_name=social_media.media_name -%}</li>
        {% endfor %}
    </ul>
</div>
```
{% endraw %}

Hmmm, isso nos leva apenas ao preenchimento de variáveis e delega a
[`social/icon.html`]({{ site.repository.blob_root }}/_includes/social/icon.html):

{% raw %}
```liquid
<a href="{%- if include.media_url_literal -%}{{include.media_url_literal}}{%- else -%}{{ include.media_base_url }}/{{ include.username }}{% endif %}"><span class="icon icon--{{include.media_name}}">{% include icon-{{include.media_name}}.svg %}</span><span class="username">{{ include.username }}</span></a>
```
{% endraw %}

Basicamente um `<a>` com dois `<span>` dentro, o primeiro `<span>` incluindo o
SVG. Nada que chame a atenção...

Então tive a ideia de inspecionar novamente, e dessa vez olhei para o conteúdo
exato que estava sendo mostrado, não apenas o HTML mas cada mínimo detalhe que
o browser mostrava:

![Inspeção mostrando o conteúdo para os ícones do Bluseky e do StackOverflow]({{ page.base-assets | append: "inspect.png" | relative_url }})

Notou a diferença? Não? Bem, eu também tive bastante dificuldade no começo, mas
em um momento de "claridade" finalmente eu percebi: para o íconde do Bluesky (o
primeiro mostrado no print), após o `</svg>` vem um `</span>`, mas no ícone do
StackOverflow há um `[whitespace]` entre o `</svg>` e o `</span>`!

Ok, descobri que realmente havia algo que causava a diferença visual. E, bem, a
estrutura que cuidava das inclusões claramente não estava com problemas.
Portanto, a diferença deveria estar dentro dos próprios arquivos de SVG!

Vou exemplificar usando o ícone do GitLab e o do Bluesky. Coloquei duas variáveis para
representar isso aqui nesse post: `gitlabico` que gera o ícone sem o
espaçamento, e o `bskyico` que gera com o espaçamento.

{%- capture gitlabico -%}<svg viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" fill-rule="evenodd" clip-rule="evenodd" stroke-linejoin="round" stroke-miterlimit="1.414"><path d="M15.97 9.058l-.895-2.756L13.3.842c-.09-.282-.488-.282-.58 0L10.946 6.3H5.054L3.28.842C3.188.56 2.79.56 2.7.84L.924 6.3.03 9.058c-.082.25.008.526.22.682L8 15.37l7.75-5.63c.212-.156.302-.43.22-.682"/></svg>
{% endcapture %}

{%- capture bskyico -%}<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 568 501"><title>Bluesky butterfly logo</title><path fill="currentColor" d="M123.121 33.664C188.241 82.553 258.281 181.68 284 234.873c25.719-53.192 95.759-152.32 160.879-201.21C491.866-1.611 568-28.906 568 57.947c0 17.346-9.945 145.713-15.778 166.555-20.275 72.453-94.155 90.933-159.875 79.748C507.222 323.8 536.444 388.56 473.333 453.32c-119.86 122.992-172.272-30.859-185.702-70.281-2.462-7.227-3.614-10.608-3.631-7.733-.017-2.875-1.169.506-3.631 7.733-13.43 39.422-65.842 193.273-185.702 70.281-63.111-64.76-33.89-129.52 80.986-149.071-65.72 11.185-139.6-7.295-159.875-79.748C9.945 203.659 0 75.291 0 57.946 0-28.906 76.135-1.612 123.121 33.664Z"></path></svg>{% endcapture %}

Eis o conteúdo delas:

GitLab:

```svg
{{ gitlabico }}
```

Bluesky:

```svg
{{ bskyico }}
```

E aqui um exemplo de como fica a geração do ícone do lado de um texto:

{% verbatim_etc html %}{% raw %}
<ul>
<li><span markdown="0" class="icon">{{ gitlabico }}</span><span>Exemplo</span></li>
<li><span markdown="0" class="icon">{{ bskyico }}</span><span>Exemplo</span></li>
</ul>
{% endraw %}{% endverbatim_etc %}

Veja bem o conteúdo dos arquivos... não tem nenhuma informação no SVG, nos
atributos da tag, nada ao redor. Mas tem algo de diferente, bem sutil: o ícone
do GitLab termina com uma linha em branco!

Para ilustrar nesse post, criei a variáveis `bskyico-ws` capturando a expansão
do `bskyico` com uma linha em branco no final:

{% verbatim_etc liquid %}{% raw %}
{%- capture bskyico-ws -%}{{ bskyico }}
{% endcapture %}
{% endraw %}{% endverbatim_etc %}

Vamos ver se funcionou?

{% verbatim_etc html %}{% raw %}
<ul>
<li><span markdown="0" class="icon">{{ gitlabico }}</span><span>Exemplo</span></li>
<li><span markdown="0" class="icon">{{ bskyico-ws }}</span><span>Exemplo</span></li>
<li><span markdown="0" class="icon">{{ bskyico }}</span><span>Exemplo</span></li>
</ul>
{% endraw %}{% endverbatim_etc %}

Super funcionou! Note que o simples fato de eu ter colocado uma quebra de linha
entre a expansão da variável Liquid e o fim do `capture` foi o suficiente para
isso ser devidamente capturado.

E de onde poderia ter vindo esse erro? Bem, veio de minha húbris! Sim, minha
mesmo! Eu simplesmente assumi que, ao salvar o SVG no VSCode, ele viria com a
quebra de linha! Afinal, é isso que acontece ao se salvar um arquivo via `vim`:
ele adiciona a quebra de linha no final do arquivo se ela não existir. Pois é
isso o que diz a convenção de um arquivo de texto bem formatado no Unix. Mas...
não é isso o que acontece com o VSCode.

A solução foi adicionar a linha em branco no final de todos os SVGs que não o
tinham. Como pode ser visto no commit 
[465d353e]({{ site.repository.base }}/-/commit/465d353eb13699c36d2a7b7c4263081f24a416e6).

Eu simulei apagar a linha em branco e dar um `cat` no arquivo. No meu terminal,
a ausência do `\n` no final do arquivo é demonstrado por um `%` com as cores
invertidas:

![Comando cat mostrando o arquivo do ícone do GitLab com o indicador de que o arquivo não tem a quebra de linha no final]({{ page.base-assets | append: "cat-no-lf.png" | relative_url }})

Mas se tiver o `\n` bonito de final de arquivo, fica assim:

![Comando cat mostrando o arquivo do ícone do GitLab]({{ page.base-assets | append: "cat-lf.png" | relative_url }})

Por sinal, ao abrir o arquivo sem o `\n` no `vim` ele reclama que o arquivo não
tem, mostranod a tag `[noeol]`:

![vim reclamando da ausência de fim de linha]({{ page.base-assets | append: "vim-noeol.png" | relative_url }})

Mas ao sair do arquivo com `:wq`, ele adiciona o `\n` no final!

Enfim, esse artigo foi só para explorar um pouco mais do processo de descoberta
dessa questão do espaçamento que eu não havia documentado.
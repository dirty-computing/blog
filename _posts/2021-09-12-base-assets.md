---
layout: post
title: "Manipulando Liquid para permitir uma base dos assets"
author: "Jefferson Quesado"
tags: meta jekyll liquid
---

# Base dos assets

Na criação de algumas páginas aqui do blog, eu curto de subir alguns assets
de imagens/gifs. Para isso, eu estava usando o padrão de criar uma pasta específica
dentro de `/assets` com os recursos específicos do post sendo escrito.

Por exemplo, sobre o [criando o blog]({% post_url 2021-08-30-criando-blog-jekyll %}), usei a pasta
`/asset/criando-blog/`. Assim consegui aglutinar lá as informações relativas a esse post específico.

Quando estava lidando com outro post, senti que isso ficou muito repetitivo. Então, será que não tinha
um modo mais fácil de lidar com isso? Incluindo eventual _rename_ de um desses diretórios?

O ideal seria fazer um filtro/tag adequado no Liquid, mas para isso significa aprender como criar isso.
Então, como lidar com isso sem maiores customizações? Se fosse num programa, eu colocaria a base dos assets
em uma variável dentro do objeto. Para usar, teria um método que eu informaria o nome do asset de dentro
desse diretório base e, então, passaria pelo filtro `relative_url` o resultado dessa variável base apendada
do valor passado. Algo assim:

```ruby
def to_asset_url(asset_name)
  relative_url(@baseAsset + asset_name)
end
```

Bem, e como eu posso fazer algo nesse sentido? A "variável" posso declarar no
[FrontMatter](https://jekyllrb.com/docs/front-matter/), posso chamar de `base-assets`, e para
acessar seu valor é só usar `page.base-assets` dentro de algum processamento Liquid. Apendar o valor
desejado eu descobri como fazer via filtro, algo como {% raw %}`{{ page.base-assets | append: "valor.png" }}`{% endraw %}.
Então, finalmente, aplicar o filtro `relative_url`: {% raw %}`{{ page.base-assets | append: "valor.png" | relative_url }}`{% endraw %}.

## Mudanças no post de criação do blog

A primeira alteração foi no FrontMatter:


```diff
  ---
  layout: post
  title: "Criando o blog com Jekyll no GitLab"
  author: "Jefferson Quesado"
+ base-assets: "/assets/criando-blog/"
  ---
```

Então, nos lugares que se mencionavam as imagens, fiz a troca:

{% raw %}
```diff
- ![Print CSS OK]({{ "/assets/criando-blog/screen-css-ok.png" | relative_url }})
+ ![Print CSS OK]({{ page.base-assets | append: "screen-css-ok.png" | relative_url }})
```
{% endraw %}

Por uma questão de simplicidade não alterei o texto que menciona essas imagens, mas coloquei
uma nota se refereindo a este post.

# Menção de outro post

Para fazer a menção entre os posts, descobri que existe a tag `post_url`. Com ela, consigo
apontar ao post adequado usando o nome dele/do seu permalink. No caso, o post original era o
`2021-08-30-criando-blog-jekyll`. Então, passo isso como argumento da tag `post_url` assim:
`{{ "%7B%25 post_url 2021-08-30-criando-blog-jekyll %25%7D" | url_decode }}`. Daí,
com isso, posso apontar [pro post original]({% post_url 2021-08-30-criando-blog-jekyll %}).
Ou então para [este atual post]({% post_url 2021-09-12-base-assets %}).
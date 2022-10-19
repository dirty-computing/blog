---
layout: post
title: "Adicionando tags - Parte 1, no post"
author: "Jefferson Quesado"
tags: meta jekyll liquid html
---

Como adicionar a lista de tags no post? Atualmente, 
as tags existem apenas para organização interna, elas
não refletem em hyperlinks nem nada do tipo, nem
tampouco elas são exibidas no post. Este vai ser o
primeiro post voltado a colocar tags de conteúdo. No
caso, voltado a por no post.

Os posts dessa série são:

1. tags no post - este daqui
2. tags no índice
3. página de tags

# A estrutura do post

Vamos lá, como que o Jekyll pega meu markdown e
transrorma num html que será exibido? Ele precisa
ter um esqueleto que, em cima dele, vai conseguir
fazer um trabalho efetivo. Como será ele?

Bem, o primeiro ponto a ver é a pasta `_layouts`.
É de se esperar, pelo princípio da mínima surpresa,
que nela tenhamos os layouts para se fazer algo. Como
uma espécie de reforço a esse pensamento, no
_frontmatter_ dos posts temos um atributo `layout`
com o valor `post`, e existe o arquivo
`_layouts/post.html`. Além disso, para publicações
do tipo fixo, páginas mesmo, como o `about`, tem o
`about.md` que tem no _frontmatter_ `layout: page`,
e existe o `_layouts/page.html`.
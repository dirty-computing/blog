---
layout: post
title: "Avisando no Discord"
author: "Jefferson Quesado"
tags: gitlab gitlab-ci meta discord jekyll ruby
---

Vamos publicar, obter o feed e publicar em um canal do Discord?

Bem, eu acabei de publicar um post ([Desafio do Zan]({% post_url 2022-09-09-soma-valores-sem-loops %})),
e eu queria automatizar subir isso num server do Discord. Como fazer, para onde ir?

Bem, um dos passos é simplesmente avisar no Discord algo. Para fazer isso, uma das alternativas
existentes é usar o webhook no canal que eu desejo. Para mais detalhes, [veja sobre isso nas docs
Discord](https://support.discord.com/hc/pt-br/articles/228383668). O que eu gostaria de enviar é 
o permalink do último post para um canal específico no Discord.

Então, como podemos fazer? Bem, podemos verificar se por acaso no `feed.xml` do RSS tem alguma publicação
como "hoje", sendo "hoje" o dia do commit.

# Resumo

1. [Parsear o `feed.xml`](#parsear-o-feedxml)
2. identificar as últimas publicações com a mesma data
3. ler o commit para identificar se a data bate
4. publicar no Discord usando webhook

Mas para fazer tudo isso preciso definir alguma tecnologia para tal. Como o Jekyll é em Ruby, vou usar
Ruby também para fazer essas atividades.

Para ajudar nesta atividade, criei o [`scream-out`]({% post_url 2022-09-13-criando-gem %}). Então toda discussão
programática será ao redor dessa gem.

# Parsear o `feed.xml`

Preciso fazer o parse de um arquivo XML usando Ruby. Pesquisando sobre o assunto achei a Gem
[Nokogiri](https://nokogiri.org/), que já tinha usado outro momento no projeto
[Coach](https://gitlab.com/geosales-open-source/coach/).

Para fazer funcionar, meu primeiro passo foi encontrar um `feed.xml` válido, já que o da raiz
do diretório do blog começa com um front-matter que atrapalha no parse de um XML.
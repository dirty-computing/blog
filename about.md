---
layout: page
title: Sobre
permalink: /about/
show: true
---

{% include pipeline.html %}

Olá, eu sou o Jefferson! Mas pode me chamar de Jeff, acho fofo =3

Meus principais projetos acabo hospedando mais no GitLab, por uma questão
de estética pessoal mesmo (acho aqui muito mais bonito)
{% include icon-gitlab.html username=site.gitlab_username %}

Talvez você me conheça como o Coelho no StackOverflow em português
{% include icon-stackoverflow.html username=site.stackoverflow_username userid=site.stackoverflow_userid %}

Aqui minha intenção é compartilhar um tanto do que aprendi, do que achei
interessante ou mesmo do que estou mexendo atualmente.

Dá uma olhadinha aqui do lado em [talks]({{ "/talks/" | prepend: site.baseurl }})
que estou guardando como repositório de palestras e apresentações gravadas.

Participei de alguns podcasts também, olha lá [podcasts]({{ "/podcasts/" | prepend: site.baseurl }})

-----

Outros locais interessantes do blog:

{% for my_page in site.pages %}
  {%- assign my_page_parts = my_page.url | downcase | split: "."  -%}
  {%- unless
        my_page_parts[-1] == "css" or
        my_page_parts[-1] == "xml" or
        my_page_parts[0] == "/" or
        my_page.url == page.url %}
  - [{% if my_page.title %}{{my_page.title}}{% else %}`{{my_page.url}}`{% endif %}]({{ my_page.url | prepend: site.baseurl }})
  {%- endunless -%}
{% endfor %}
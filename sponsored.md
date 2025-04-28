---
layout: page
permalink: /sponsored/
show: true
title: Patrocinado
interesting: true
---

Alguns posts aqui do Computaria foram patrocinado. Quer ser um patrocinador do
meu trabalho? Pois me paga um café e me manda o comprovante!

- [Pix me a coffee]({{ site.pixmeurl }}/jeffquesado)

Chave pix:

{% include pix-qrcode.svg %}

Me patrocina e manda na mensagem do pix o que você quer que eu fale \o/

Posts patrocinados e seus patrocinadores:

<ul class="post-list">
{% for post in site.posts %}
{% unless post.draft == 'true' %}
{% if post.sponsored_by %}
  {% include component/main-link.html
      post=post
  %}
{% endif %}
{% endunless %}
{% endfor %}
</ul>

{% if site.data.sponsored_wip %}
Enquanto isso, estou trabalhando nesses posts patrocinados aqui:

{% for sponsored_post in site.data.sponsored_wip -%}
- {{ sponsored_post.subject }}, patrocinado por {{ sponsored_post.sponsor | join: ", " }}
{% endfor %}

{% else %}

Já terminou as requisições, esperando você!
{% endif %}
---
layout: page
title: Gerencial
permalink: /managerial/
show: true
---

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

Ambiente Jekyll que gerou essa página? `{{jekyll.environment}}`

<table class='lalala'>
    <tr>
        <th>Variável/ambiente</th><th>Descrição</th><th>Valor</th><th>Toggle</th><th>Posts</th>
    </tr>
    <tbody>
        {% for var in site.data.meta.variables -%}
        {% if var.env == '*' or var.env == jekyll.environment %}
        <tr>
            <td>{{ var.name }}/{{ var.env }}</td><td>{{ var.description }}</td>
            <td id="td-{{ var.name }}"></td>
            <td><button onclick="alterarStorage('{{ var.name }}')">Alterar</button></td>
<td markdown="1">
{% if var.posts.size > 0 %}
{%- for bg_post in var.posts -%}
- [{{ bg_post.title }}]({% post_urlwa {{ bg_post.slug }} %})
{% endfor %}
{% endif %}
</td>
        </tr>
        {% endif %}
        {% endfor %}
    </tbody>
</table>

Links para meta informação (post citando):

{% for meta_link in site.data.meta.links %}
{% if meta_link.env == '*' or meta_link.env == jekyll.environment %}
- {{ meta_link.link }}
  - Ambiente: {{  meta_link.env }}
{%- for bg_post in meta_link.posts %}
  - [{{ bg_post.title }}]({% post_urlwa {{ bg_post.slug }} %})
{%- endfor %}
{% endif %}
{% endfor %}

<script>
const varaiveisStorage = [
{% for var in site.data.meta.variables -%}
{% unless forloop.first %} , {% endunless %}
"{{var.name}}"
{% endfor %}
]

function toTdId(varName) {
    return "td-" + varName
}

function alterarStorage(varName) {
    const currValue = localStorage.getItem(varName)
    const newValue = (currValue === "true")? "false": "true"
    localStorage.setItem(varName, newValue)

    const id = toTdId(varName)
    const element = document.getElementById(id)
    if (!!element) {
        element.innerText = newValue
    }
}

function populateVar(varName) {
    const id = toTdId(varName)
    const element = document.getElementById(id)
    if (!!element) {
        const varValue = localStorage.getItem(varName)
        element.innerText = varValue
    }
}

for (const varName of varaiveisStorage) {
    populateVar(varName)
}
</script>
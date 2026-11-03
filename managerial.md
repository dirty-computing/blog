---
layout: page
title: Gerencial
permalink: /managerial/
show: true
---

Ambiente Jekyll que gerou essa página? `{{jekyll.environment}}`

<table class='marked-table'>
    <tr>
        <th>Variável/ambiente</th><th>Descrição</th><th>Valor</th><th>Toggle</th><th>Posts</th>
    </tr>
    <tbody>
        {% for var in site.data.meta.variables -%}
        {% if var.env == '*' or var.env == jekyll.environment %}
        <tr>
            <td>{{ var.name }}/{{ var.env }}</td><td>{{ var.description }}</td>
            <td id="variable-td-{{ var.name }}"></td>
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

Customizações diversas:

<table class='marked-table'>
    <tr>
        <th>Variável</th><th>Descrição</th><th>Valor</th><th>Toggle</th><th>Posts</th>
    </tr>
    <tbody>
        {% for var in site.data.meta.customizations -%}
        <tr>
            <td>{{ var.name }}</td><td>{{ var.description }}</td>
            <td id="custom-td-{{ var.name }}"></td>
            <td><button onclick="alterarCustomStorage('{{ var.name }}')">Alterar</button></td>
<td markdown="1">
{% if var.posts.size > 0 %}
{%- for bg_post in var.posts -%}
- [{{ bg_post.title }}]({% post_urlwa {{ bg_post.slug }} %})
{% endfor %}
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
const variaveisStorage = [
{% for var in site.data.meta.variables -%}
{% unless forloop.first %} , {% endunless %}
"{{var.name}}"
{% endfor %}
]

function toVariableTdId(varName) {
    return "variable-td-" + varName
}

function alterarStorage(varName) {
    const currValue = localStorage.getItem(varName)
    const newValue = (currValue === "true")? "false": "true"
    localStorage.setItem(varName, newValue)

    const id = toVariableTdId(varName)
    const element = document.getElementById(id)
    if (!!element) {
        element.innerText = newValue
    }
}

function populateVar(varName) {
    const id = toVariableTdId(varName)
    const element = document.getElementById(id)
    if (!!element) {
        const varValue = localStorage.getItem(varName)
        element.innerText = varValue
    }
}

for (const varName of variaveisStorage) {
    populateVar(varName)
}

const customStorage = [
{% for var in site.data.meta.customizations -%}
{% unless forloop.first %} , {% endunless %}
"{{var.name}}"
{% endfor %}
]

function toCustomTdId(varName) {
    return "custom-td-" + varName
}

function listenerCustom(varName) {
    switch (varName) {
        case "theme":
            return () => {
                addToggleChangeListener((newValue) => {
                    const id = toCustomTdId(varName)
                    const element = document.getElementById(id)
                    if (!!element) {
                        element.innerText = newValue
                    }
                })
            };
            break;
        default:
            return null;
    }
}

function customVariableNewValueFunction(varName) {
    switch (varName) {
        case "theme":
            return (oldValue) =>  {
                const component = document.querySelector("[role='switch']");
                component.checked = !component.checked;
                return changeToggleSwitchState(component)
            };
            break;
        default:
            return (oldValue) => "";
    }
}

function alterarCustomStorage(varName) {
    const currValue = localStorage.getItem(varName)
    const newValue = customVariableNewValueFunction(varName)(currValue);
    localStorage.setItem(varName, newValue)

    const id = toCustomTdId(varName)
    const element = document.getElementById(id)
    if (!!element) {
        element.innerText = newValue
    }
}

function populateCustom(varName) {
    const id = toCustomTdId(varName)
    const element = document.getElementById(id)
    if (!!element) {
        const varValue = localStorage.getItem(varName)
        element.innerText = varValue
    }
}

for (const varName of customStorage) {
    populateCustom(varName)
}

window.addEventListener("storage", event => {
    if (customStorage.includes(event.key)) {
        populateCustom(event.key);
    }
});

window.addEventListener("DOMContentLoaded", () => {
    for (const varName of customStorage) {
        const id = toCustomTdId(varName)
        const element = document.getElementById(id)
        if (!!element) {
            const listener = listenerCustom(varName);
            if (!!listener) {
                listener();
            }
        }
    }
})
</script>
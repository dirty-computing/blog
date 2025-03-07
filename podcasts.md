---
layout: page
permalink: /podcasts/
show: true
title: Podcasts
interesting: true
---


Podcasts dos quais participei, episódios agrupados por podcast:

{% assign podcast_people = site.data.podcasts.people %}

<div markdown="1" class="randomize">
{% for show in site.data.podcasts.podcasts %}

<div markdown="1" class="podcast">
## {{ show.show }}

{{ show.description }}

Host: {{ podcast_people[show.host] }}

Canais para acompanhar o podcast:

{% for channel in show.channels -%}
- {{ channel }}
{% endfor %}

<details markdown="1">
<summary>
Episódios ({{ show.episodes | size }})
</summary>

{% for episode in show.episodes %}
### {{ episode.title }}

{{ episode.description }}

Com a participação de {% for guest in episode.guests %}
{%- unless forloop.first -%}{% if forloop.last %} e {% else -%}, {% endif -%}{% endunless -%}
{{ podcast_people[guest] }}{% endfor %}

Onde assistir esse episódio?

{% for link in episode.links %}
- {{ link }}
{%- endfor %}

{% endfor %}
</details>
</div>
{% endfor %}
</div>

<script>
// https://www.freecodecamp.org/news/how-to-shuffle-an-array-of-items-using-javascript-or-typescript/
function shuffle(list) {
    const array = [...list]
    for (let i = array.length - 1; i > 0; i--) { 
        const j = Math.floor(Math.random() * (i + 1)); 
        [array[i], array[j]] = [array[j], array[i]]; 
    } 
    return array;
}

function randomize(htmlRoot) {
    const children = Array.from(htmlRoot.children)
    const shuffled = shuffle(children)

    // based on https://www.geeksforgeeks.org/remove-all-the-child-elements-of-a-dom-node-in-javascript/
    for (const child of children) {
        htmlRoot.removeChild(child)
    }
    // doc https://developer.mozilla.org/en-US/docs/Web/API/Node/appendChild
    for (const child of shuffled) {
        htmlRoot.appendChild(child)
    }
}

function openParents(element) {
    // chegou no fim, para
    if (!element.parentElement) {
        return
    }
    openParents(element.parentElement)
    if (element.parentElement.localName.toLocaleLowerCase() == "details") {
        element.parentElement.open = true
    }
}

function startRandomization(shouldScroll) {
    const whatToRandomize = document.getElementsByClassName("randomize");
    for (const elementToRandomize of whatToRandomize) {
        randomize(elementToRandomize)
    }

    if (shouldScroll && whatToRandomize.length > 0 && !!window.location.hash) {
        const id = window.location.hash.substring(1)
        const element = document.getElementById(id)
        if (!!element) {
            openParents(element)
            // https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollIntoView
            element.scrollIntoView(true);
        }
    }
}

startRandomization(true)
</script>
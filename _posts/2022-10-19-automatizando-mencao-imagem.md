---
layout: post
title: "Automatizando menção de imagem"
author: "Jefferson Quesado"
tags: bash meta
base-assets: "/assets/automatizando-mencao-imagem/"
---

No post [Manipulando Liquid para permitir uma base dos assets]({% post_url 2021-09-12-base-assets %})
é mencionado que eu arranjei um jeito
de deixar mais bonitinho o agrupamento de imagem por pasta de assets. Mas, sabe de
uma coisa? Eu vivo esquecendo como fazer o Liquid para importar a imagem.

Então, que tal construir ele?

Basicamente, precisamos apontar para uma imagem qualquer. Que tal uma imagem do
Big Buck Bunny? Essa daqui:

![Big Buck Bunny]({{ page.base-assets | append: "big-buck-bunny.png" | relative_url }})

> (c) copyright 2008, Blender Foundation / www.bigbuckbunny.org, CC-BY 3.0

Pois bem. Como criar a string de menção do asset? Mais especificamente, capaz de
gerar isto {% raw %}`{{ page.base-assets | append: "big-buck-bunny.png" | relative_url }}`{% endraw %}?

Basicamente, vou precisar apenas de uma entrada para preencher o campo `append` ali. Então,
um pequeno shell que receba o argumento e devolva
{% raw %}`{{ page.base-assets | append: "$1" | relative_url }}`{% endraw %} estaria o suficiente.

Mas tem outro ponto também que me agrada: que eu não precise mencionar diretamente que é um `.png`,
já que esse é o tipo padrão a ser usado. Então, se não tiver extenção, posso simplesmente
por a extenção:

```bash
FILE_NAME="$1"

# normaliza fim de arquivo para png

if [ "$FILE_NAME" = "${FILE_NAME%.*}" ]; then
    FILE_NAME+=.png
fi
```

Mas tem outra coisinha também... as vezes eu quero simplesmente ajuda para mencionar algo que
já está na pasta dos `assets`, e eu poder ir navegando usando `tab`s no terminal para
autocompletar. Então, se meu argumento começar com `assets/`, devo eliminar esse prefixo e
também o primeiro diretório mencionado. Algo que me permita trabalhar assim:

![Usando a ferramenta linha de comando para pegar a string liquid dos meus dois assets]({{ page.base-assets | append: "terminal-vscode-mention-image.png" | relative_url }})

E bash me oferece uma substituição adequada para
remoção de prefixos: `${var#prefixo}`. No caso, o prefixo é `assets/*/`. Assim,
para adicionar essa remoção do prefixo, o código fica assim:

```bash
FILE_NAME="${1#assets/*/}"

# normaliza fim de arquivo para png

if [ "$FILE_NAME" = "${FILE_NAME%.*}" ]; then
    FILE_NAME+=.png
fi
```

E incluindo o echo já gerar a parte liquid:

{% raw %}
```bash
#!/bin/bash

FILE_NAME="${1#assets/*/}"

# normaliza fim de arquivo para png

if [ "$FILE_NAME" = "${FILE_NAME%.*}" ]; then
    FILE_NAME+=.png
fi

echo "{{ page.base-assets | append: \"$FILE_NAME\" | relative_url }}"
```
{% endraw %}

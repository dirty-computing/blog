---
layout: post
title: "Habilitando git bash como terminal no VSCode no Windows"
author: "Jefferson Quesado"
tags: windows vscode bash
base-assets: "/assets/git-bash-vscode-windows/"
---

Criando aqui porque sofri bastante com isso. Como fazer para no windows
ter a opção de rodar o bash no terminal do VSCode?

![Exemplo mostrando o VSCode funcionando com o git-bash]({{ page.base-assets | append: "exemplo-rodando-vscode.png" | relative_url }})

Eu particularmente não consegui fazer via interface, precisei abrir as
configurações e inserir a informação na mão. Digite `Ctrl+Shift+P` e entre
o comando `settings.json`. Vai aparecer a opção `Preferences: Open Settings
(JSON)`. Abra essa opção.

![Listagem de comandos]({{ page.base-assets | append: "command-options.png" | relative_url }})

O campo que nos interessa é aquele de chave `"terminal.integrated.profiles.windows"`.
O próprio VSCode nos mostra este hint:

![Hint de mouse-hover para a propriedade "terminal.integrated.profiles.windows"]({{ page.base-assets | append: "hint-profiles-terminal.png" | relative_url }})

Esse campo, por sua vez, tem campos que, independentemente de seu valor, apontam para
objetos do tipo "objetos de shell":

![Mostrando os campos de um objeto de shell]({{ page.base-assets | append: "tipo-obj-shell.png" | relative_url }})

Seus campos são:

- `args`
- `color`
- `env`
- `extensionIdentifier`
- `icon`
- `id`
- `overrideName`
- `path`
- `source`
- `title`

Desses, usei o `path` para especificar onde estava exatamente o meu executável.
Como eu queria pegar da minha instalação local do `git-bash`, que estava em
local não padronizado, precisei apenas mencionar o `bash` diretamente.

Por sinal, na estrutura da instalação do `git-bash`, você precisa invocar apenas
o `bash`. Ele está não na raiz do diretório de instalação, mas dentro de `bin`.

![Como é a estrutura de arquivos e pastas na instalação padrão do git-bash]({{ page.base-assets | append: "git-bash-file-structure.png" | relative_url }})

No meu caso, a instalação fica em `~/AppData/Local/git`. Mas não consigo mencionar
isso desse jeito para o VSCode entender onde está. Primeiro que o padrão é usar
o separador de diretórios do Windows, que é `\`, não `/`. Segundo que eu preciso
mencionar variáveis de ambiente que de fato existam a nível de VSCode, expansão
tilde não é garantido e `${HOME}` não é uma dessas variáveis no Windows.

Mas sabe o que o Windows me oferece? A variável `Homepath`. Tomando como exemplo
o que tem para o `Command prompt`

```json
"Command Prompt": {
    "path": [
        "${env:windir}\\Sysnative\\cmd.exe",
        "${env:windir}\\System32\\cmd.exe"
    ],
    "args": [],
    "icon": "terminal-cmd"
}
```

citar a variável de ambiente é fazer `${env:someVar}`. Como eu quero `Homepath`,
então é `${env:Homepath}`. Isso me daria o seguinte:

```json
"bash": {
    "path": "${env:Homepath}\\AppData\\Local\\git\\bin\\bash.exe",
    "args": [],
    "icon": "git-branch"
}
```

porém, se eu for fazer a expansão disso, não começa do o drive de disco C, onde
está de fato a minha home. Começa direto com `\Users\MyUser`. E como fazer para
mostrar também o drive de onde se situa a minha home? Bem, buscando de modo
meio aleatório descobri a variável `Homedrive`...

```json
"bash": {
    "path": "${env:Homedrive}${env:Homepath}\\AppData\\Local\\git\\bin\\bash.exe",
    "args": [],
    "icon": "git-branch"
}
```

Essa expansão com `Homedrive` na frente, já me fornece o caminho `C:\Users\MyUser`,
como esperado.

Então, para criar o perfil para bash, preciso criar um novo elemento no mapeamento
`"terminal.integrated.profiles.windows"` (chamado de `bash` para facilitar a
identificação), que tenha o `path` com o valor
`"${env:Homedrive}${env:Homepath}\\AppData\\Local\\git\\bin\\bash.exe"`.

Além disso, não quero passar nenhum parâmetro específico nos argumentos, ao menos
por hora, então cito que `"args": []`. E também vale a pena citar qual o ícone a ser
utilizado. Nesse caso, um que achei bonitinho foi o `git-branch`, serviu para a minha
finalidade de indicar que é uma shell vinda do `git-bash`. Veja no lado direito o
ícone do `git-branch`:

![Print mostrando o git-bash do lado esquerdo no VSCode e no lado direito as instâncias abertas, que são 4, todas com o ícone do git-branch]({{ page.base-assets | append: "icon-git-branch.png" | relative_url }})

Depois de configurado isso, podemos setar o perfil padrão. Um dos modos de setar
isso é apertando o menu de opções ao lado do `+` de adicionar um novo terminal:

![Mostrando as diversas opções, inclusive a de configurar o default]({{ page.base-assets | append: "select-default-from-terminal.png" | relative_url }})

Ao clicar no `Select Default Profile`, os perfis são exibidos na barra de comando.

![Opções de perfis que eu posso selecionar nas minhas configurações atuais]({{ page.base-assets | append: "select-your-default-profile.png" | relative_url }})

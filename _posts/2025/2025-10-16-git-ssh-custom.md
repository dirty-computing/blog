---
layout: post
title: "Usando chave ssh \"custom\" para comandos git"
author: "Jefferson Quesado"
tags: git ssh bash
base-assets: "/assets/git-ssh-custom/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Eu tenho uma chave SSH para o GitHub, e outra para o GitLab. Sim,
propositadamente distintas. Então, como faço para gerenciar qual a chave SSH
vou usar no hora de dar um `git fetch` da vida? Ou um `git clone`?

# Configurando para um repositório existente

Eu posso configurar algumas coisas no `.git/config` do repositório. Por
exemplo, quando se cria um repositório, podemos criar ele no modo
[`bare`](https://pt.stackoverflow.com/q/80182/64969), vai ter uma flag na seção
`[core]` indicando `bare = true`.

Aqui um exemplo de `.git/config` de um reposirório recentemente criado, vazio:

```ini
[core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
        ignorecase = true
        precomposeunicode = true
```

Nele também tem outras informações, como por exemplo informações sobre os
remotos, alguns metadados sobre os branches que você tem, email distinto do
usuário global do git etc. Por exemplo, aqui no clone local do Computaria:

```ini
[remote "origin"]
        url = git@gitlab.com:computaria/blog.git
        fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
        remote = origin
        merge = refs/heads/master
        vscode-merge-base = origin/master
[user]
        email = jeff.quesado@gmail.com
[branch "build-time-test"]
        vscode-merge-base = origin/master
        remote = origin
        merge = refs/heads/build-time-test
[branch "test-force-ruby-platform-protobuff"]
        vscode-merge-base = origin/master
        remote = origin
        merge = refs/heads/test-force-ruby-platform-protobuff
```

O jeito que eu encontrei para colocar dentro de um repositório para usar uma
chave SSH personalizada foi adicionar uma opção a mais na parte `[core]`:

```ini
        sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
```

Isso aqui está indicando que o git vai usar um comando ssh para fazer a
comunicação, e que a chave que ele vai usar para autenticar está localizada no
diretório `computaria/.ssh` dentro da home do meu usuário, e que o arquivo com
a chave se chave `id_ed25519`. Bem, sim, eu uso curva de de Edwards para me
identificar.

Até hoje eu só me preocupava com isso! Mas agora eu vi que tem o resto do
comando, `-o IdentitiesOnly=yes`. Rapidamente relacionei o `-o` do SSH ao `-o`
do `set`. Em diversos scripts eu super acho que vale a pena começar eles assim:

```bash
set -euo pipefail
```

O que isso quer dizer? Bem, o `set` vai configurar algumas coisas na bash. O
`-e` indica que uma falha (saída com valor diferente de 0) deveria fazer o
script parar. Claro, uma falha não esperada, se for um
`if [ "$option" = y ]; then ...` o comando `test` (indicado pelo `[`) está
tendo o seu retorno consumido pelo `if`, tal qual se for fazer algo como
`try-login || echo >&2 "login falhou, ignorando"`, o `||` é um operador de `OR`
booleano que vai executar o `echo` caso o `try-login` falhe, e como o `echo`
não costuma falhar, o resultado disso é que esse comando inteiro vai ser
considerado sucesso, não ocasionando o fim da execução do script. O `-u` vem
de "unknown", basicamente indica que qualquer expansão de variável de uma
variável que não teve o valor definido causa a shell em que ele está sendo
expandida a falhar.

Por exemplo, digitando na linha da própria shell:

```bash
echo $abacate # linha em branco, abacate não está preenchido, retorno 0
abacate=2
echo $abacate # 2, retorno 0
unset abacate # removo o valor
set -u        # configura para falhar em unknown variables
echo $abacate # mensagem de erro, retorna 1
abacate=2
echo $abacate # 2, retorno 0
```

Agora, se fosse em um script:

```bash
#!/bin/bash

set -u
echo $abacate
echo $?
```

![print mostrando a execução do script test.sh com a mensagem de erro "./teste.sh: line 4: abacate: unbound variable"]({{ page.base-assets | append: "unknown-var.png" | relative_url }})

Mas eu posso colocar a execução desse `echo` dentro de uma subshell usando o
operador `(` parênteses `)`:

```bash
#!/bin/bash

set -u
( echo $abacate; echo $? )
echo $?
```

Com isso eu obtenho:

![print mostrando a execução do script test.sh com a mensagem de erro "./teste.sh: line 4: abacate: unbound variable" seguido de, na linha de baixo, o número 1]({{ page.base-assets | append: "unknown-var-2.png" | relative_url }})

Quem falhou foi a subshell `( echo $abacate; echo $? )`, por isso que o comando
seguinte foi possível imprimir que saiu com falhas. No primeiro teste não
coloquei o `echo` em nenhuma subshell, portanto ele falhava na "main shell".

E finalmente temos no final o `set -o pipefail`. O que isso quer dizer? Bem,
quer dizer que, em uma situação de montar um pipeline, qualquer parte do
pipeline que falhar vai ser considerado que todo o comando do pipeline falha.
Ao usar o pipe `|` pode acontecer de um programa a esquerda falhar, mas ele
ainda pode ter cuspido algo na `stdout` para ser consumido por quem está a
direita, e o programa da direita finalizar normalmente. Com `-o pipefail`, com
a opção de `pipefail` ligada, o pipeline ao todo vai ser considerado uma falha.
Como o pipeline falhou, o `-e` garante que o script termine abruptamente.

E, bem, o que é `-o pipeline`? Basicamente quer dizer que a
<span style="color: red;" markdown=1>**o**</span>pção `pipefail` está ligada.

E a mesma coisa no caso do `ssh -o IdentitiesOnly=true`. Então vamos pesquisar
o que é isso?

Para começar, `man ssh`. A primeira referência a `IdentitiesOnly` se encontra
dentro da explicação da flag `-o option`, como sendo uma das possíveis
`options`:

```txt
     -o option
             Can be used to give options in the format used in the configuration file.  This is useful for specifying
             options for which there is no separate command-line flag.  For full details of the options listed below,
             and their possible values, see ssh_config(5).

                   AddKeysToAgent
                   AddressFamily
                   BatchMode
                   BindAddress
                   CanonicalDomains
                   CanonicalizeFallbackLocal
                   CanonicalizeHostname
                   CanonicalizeMaxDots
                   [...]
                   IdentitiesOnly
                   IdentityAgent
                   IdentityFile
                   [...]
```

Bem, ele disse explicitamente para consultar `ssh_config(5)`. Como não obtive a
resposta de imediato, eu continuo olhando a manpage do `ssh`?

Claro que não! Vamos consultar a do `ssh_config`! `man 5 ssh_config` para abrir
corretamento a página indicada, que é sobre `ssh_config`, mas não qualquer
manpage sobre `ssh_config`, especificamente a manpage `5`!

E finalmente nessa manpage ele descreve o que esse `IdentitisOnly` realiza:
mesmo se tiver outras fontes/certificados no sistema, usar apenas o que foi
explicitado para o `ssh`. Por exemplo, naturalmente existe a possibilidade de
se procurar certificados/chaves com algum `PKCS11Provider` ou
`SecurityKeyProvider`, essa opção inibe isso. Portanto, no meu caso, ele indica
que vai ser usada a chave ssh explícita passada no comando.

# Para comandos stand-alone, como git clone

Nem sempre eu vou realizar as mudanças de dentro de um repositório git be
definido. As vezes eu preciso clonar um repositório! E eu quero usar minha
chave customizada, não a padrão que está no meu diretório `~/.ssh/`! Como que
faz isso?

Bem, basicamente "usando" a opção de `core.sshCommand`. Mas se precisar criar
um `.git/config` para tal! Por exemplo, para clonar o blog eu posso fazer
assim:

```bash
git -c core.sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes" clone git@gitlab.com:computaria/blog.git
```

A opção `-c` basicamente indica que vai setar um valor de configuração para
aquela rodada local. Inclusive a manpage do git fala que a opção `-c`
sobrescreve não só valores padrões de configuração, como também opções do
repositório em específico.

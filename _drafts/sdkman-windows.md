---
layout: post
title: "Instalando Sdkman! no Windows"
author: "Jefferson Quesado"
tags: java sdkman windows
---

Uma das dificuldades quem trabalha com múltiplas versões do Java sofre é ficar alternando
entre elas. E sabia que tem uma ferramenta para lidar com isso? Sim, é o [Sdkman!](https://sdkman.io/).

Aqui é um pequeno tutorial ajudando você a instalá-lo. Se tiver alguma coisa a acrescentar, pode me
alcançar [neste tuíte em específico](https://twitter.com/JeffQuesado/status/1508803374241796104).
No momento da criação deste post, apenas o [@vepo](https://twitter.com/vepo) havia interagido com uma
experiência de sucesso, mas eventualmente outras dúvidas podem surgir ou você pode ir lá compartilhar
algo mais tortuoso pelo qual você passou.

Aqui um índice para que você possa navegar para a parte adequada:

1. [Zerando meu ambiente](#zerando-meu-ambiente) (pode pular, é seguro)
1. [Pré-requisitos](#pré-requisitos)
1. [Instalando o Sdkman!, happy ending](#instalando-o-sdkman-happy-ending)
1. [Problemas comuns na instalação](#problemas-comuns-na-instalação)
   1. zip
   1. nome de usuário com espaços e acentos
1. Testando para garantir que tudo funciona

# Zerando meu ambiente

No meu ambiente já tenho instalado o Sdkman! e, na iteração passada da instalação dele, instalei também
o GoW (GNU on Windows) para ter acesso a alguns executáveis que o Sdkman! requeria no momento de sua instalação. Então, para
tentar simular esse ambiente, "removi" do `PATH` a referência ao GoW. Dos muitos modos que eu tinha para fazer isso,
resolvi fazer por expansão de variável.

No `PATH` tinha bastante coisa já. Usei a substituição a partir de padrões glob. A ideia era fazer algo como:

```bash
echo ${PATH/:aqui o caminho do GoW:/:}
```

onde o caminho do GoW e apenas ele fosse removido. Ele estava entre dois separadores do `PATH` (indicado pelo caracter
`:` dentro da variável `PATH`). Tive problemas usando o `*` do glob e fiquei sem paciência de escapar as barras, então
no lugar de mencionar as barras como `/` coloquei o `?` do glob que aceita um caracter. O resto iria ser muito específico
para que o padrão pegasse apenas o GoW, então não tinha muito problema com isso:

```bash
echo "PATH sem GoW?"
echo "${PATH/:?c?Program Files (x86)?Gow?bin:/:}"
```

E deu certo. Sobrescrevi o `PATH` adequadamente. Confirmei que o `zip` (a ferramenta buscada pelo Sdkman! que me fez ir
atrás do GoW) não estava mais na minha máquina.

Mas ainda preciso me livrar também do Sdkman! no meu `PATH`, não apenas o GoW. Como que eu fiz? Bem, não consegui fazer uma
expansão glob para isso, mas dá para fazer uma expressão regular para lidar com isso. Novamente, não obtive grande sucesso
em uma única chamada do `sed`, mas pude fazer um laço simples:

1. coloca em uma variável o que seria o `$PATH` apagando `(^|:)[^:]*\.sdkman[^:]*:` (devolvendo só o `\1`)
1. se a variável for idêntica textualmente ao `$PATH`, então acabou o processo
1. caso contrário, podemos repetir o primeiro passo , atualizando o `$PATH`

Então, separando os dois passos (`remove-sdkman-from-1path` e `remove-sdkman-from-allpath`), temos:

```bash
remove-sdkman-from-1path() {
	echo "$1" | sed -E 's/(^|:)[^:]*\.sdkman[^:]*:/\1/'
}

remove-sdkman-from-allpath() {
	local le_path="$1"
	local le_step="`remove-sdkman-from-1path "$le_path"`"

	while [ "$le_path" != "$le_step" ]; do
		le_path="$le_step"
		le_step="`remove-sdkman-from-1path "$le_path"`"
	done
	echo "$le_path"
}

export PATH="`remove-sdkman-from-allpath "$PATH"`"
```

Coloquei para influenciar na variável global apenas no caso final, trabalhando com variável intermediária. E
para ficar mais fácil lidar com erros, coloquei numa subshell (ou seja, dentro de um bloco `(` entre parênteses `)`)
de modo que as alterações de variáveis e essas coisas só afetem dentro de um _sandbox_. Para concluir, o último comando
da subshell é um `bash` para iniciar um novo processo interativo com as novas variáveis de ambiente.

Como o comando `sdk` é uma função criada ao ser dado `source` no arquivo de inicialização do Sdkman! `sdkman-init.sh`,
chamar um novo processo "limpa" essa função de nosso alcance. Portanto, com isso, também consegui me livrar do comando. Ufa!

Outra coisa importante também foi fingir que eu tinha uma `HOME` distinta. Para simular alguns casos de complicação,
resolvi que minha `HOME` precisaria ter no caminho um diretório com espaços e acentos. Então, criei o seguinte diretório:

```bash
mkdir -p "/c/repos/sdkman-test/Dir com espaços e acentos"
cd !$                                                     # o !$ expande para o último argumento do comando anterior
export HOME="`pwd`"
```

E confirmei que, de fato, a `HOME` estava alterada de maneira irreversível naquele terminal. Criei um `hello-home.sh` com o seguinte
conteúdo:

```bash
#!/bin/bash

echo "home aqui é $HOME"
```

E executando eu obtive a resposta `home aqui é /c/repos/sdkman-test/Dir com espaços e acentos`. Conforme esperado.

Como um dos pontos de falhas mais comuns é a ausência do executável `zip`, vou criar um `zip` para servir de proxy
(o `gzip` atende à mesma API de CLI). Para funcionar bem, vou precisar criar um executável com ele e colocar no `PATH`.
Então, vou aproveitar o novo `HOME` e fazer `mkdir ~/bin` e adicionar no `PATH` esse diretório.

Como eventualmente eu sei que vou começar esse trabalho em um dia e terminar em outro, criei um script para dar um `source` em outro
terminal outro dia. Apelidei-o de `source-zerante`. Ele precisa lidar com a remoção do GoW do `PATH` e com a questão do `HOME`:

```bash
(
	export HOME="`pwd`"
	export PATH="${PATH/:?c?Program Files (x86)?Gow?bin:/:}"

	remove-sdkman-from-1path() {
		echo "$1" | sed -E 's/(^|:)[^:]*\.sdkman[^:]*:/\1/'
	}

	remove-sdkman-from-allpath() {
		local le_path="$1"
		local le_step="`remove-sdkman-from-1path "$le_path"`"

		while [ "$le_path" != "$le_step" ]; do
			le_path="$le_step"
			le_step="`remove-sdkman-from-1path "$le_path"`"
		done
		echo "$le_path"
	}

	mkdir -p ~/bin
	export PATH="`remove-sdkman-from-allpath "$PATH"`:$HOME/bin"
	bash
)
```

Abri um novo terminal, naveguei até a pasta de testes e fiz o `source source-zerante`, _et voilà_, tudo como esperado.

# Pré-requisitos

Basicamente, precisa ter instalado o `git-bash`.

# Instalando o Sdkman!, happy ending

# Problemas comuns na instalação

Normalmente 
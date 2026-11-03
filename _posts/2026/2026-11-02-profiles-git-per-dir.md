---
layout: post
title: "Profiles de git por diretório? Vem entender comigo!"
author: "Jefferson Quesado"
tags: git engenharia-de-software
base-assets: "/assets/profiles-git-per-dir/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Por um tempo eu fiz o controle de chaves SSH diretamente no clone local do
repositório (leia mais em
[Usando chave ssh "custom" para comandos git]({% post_url 2025/2025-10-16-git-ssh-custom %})).
Porém, depois que eu troquei de computador, acabei fazendo umas bagunças não
intencionais com as chaves SSH e com algumas informações de commit. Então
fiquei pensando, será que não é possível eu poder determinar alguma espécie de
divisão de quais dados do git eu poderia configurar uma vez só e ser feliz.

# Valores padrão vs valores do repositório

Existem configurações que podemos colocar a nível de usuário. Uma delas bem
comum é nome e email:

```bash
git config --global user.name 'Jefferson Quesado'
git config --global user.email 'jeff.quesado@gmail.com'
```

Essas configurações ficam salvas em `~/.gitconfig`:

```conf
[user]
	name = Jefferson Quesado
	email = jeff.quesado@gmail.com
```

Localmente eu consigo sobrepor esses valores simplesmente não informando ao
git que é `--global`:

```bash
git config user.name 'Abóbora'
git config user.email 'abobora@computaria.io'
```

De modo geral, eu queria que tudo que estivesse no diretório `~/computaria`
tivesse alguns padrões. E para o trabalho, onde uso Claude Code, eu tenho uma
trava em que a minha chave SSH exige uma senha, e sem informar mais nada o
Claude não abre a opção de eu digitar a senha e ele fica perdidinho pensando
que a senha era inválida. Então eu preciso:

- um padrão para o sistema
- algo customizado para o computaria
- algo customizado para conseguir digitar a senha da chave SSH em um diretório

# Diretrizes de inclusão

Pesquisando um pouco mais, encontrei a diretriz `includeIf` do gitconfig.
Basicamente, se uma expressão for verdade, ele permite a inclusão de um arquivo
para compor a configuração. Veja mais em
[git-config (_includes)](https://git-scm.com/docs/git-config#_includes).

Basicamente, a minha restrição era por diretório. Então, fui testar isso no
`.gitconfig` global:

```conf
[user]
	name = Jefferson Quesado
	email = jeff.quesado@gmail.com

[includeIf "gitdir:~/computaria/"]
	path = ~/confs/computaria
```

E coloquei essas informações no `~/conf/computaria`:

```conf
[core]
	sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
[user]
	name = Abóbora
	email = abobora@computaria.io
```

Para o caso do Claude, que minha chave SSH por padrão que ele pede usa senha,
eu teria de pedir que ele usasse um programinha (bobinho e inseguro, não façam
isso em casa, usem algo mais bem definido) que subia um popup pedindo a senha
da chave SSH. Para essa configuração eu precisava configurar o
`core.sshCommand`. Coloquei isso em `~/conf/claude-ssh`: 

```conf
[core]
    sshCommand = env SSH_ASKPASS=~/bin/ssh-askpass.tcl SSH_ASKPASS_REQUIRE=force ssh
```

E no caso para a inclusão dessa configuração eu simplesmente confiei em uma
convenção: o trabalho que o Claude Code faria seria em `cc-work`. Logo, alterei
o `~/.gitconfig` global:

```conf
[user]
	name = Jefferson Quesado
	email = jeff.quesado@gmail.com

[includeIf "gitdir:~/computaria/"]
	path = ~/confs/computaria

[includeIf "gitdir:~/source/firma/cc-work/"]
	path = ~/confs/claude-ssh
```

# Resolução de configuração

Se estiver em dúvida de qual o valor de configuração que está valendo naquele
momento, naquele diretório, você sempre pode pedir pro próprio git. Por
exemplo, para pegar o comando SSH:

```bash
git config get core.sshCommand
```

E o git vai resolver a configuração e retornar pra você o valor correto.

Mas se você quiser "pré-computar" o valor dessas variáveis manualmente, também
é possível fazer. Imagine que você vai ter uma tabela com os valores, e cada
linha que você lê das configurações do git você pode alterar o valor. E o
modelo de `conf` que o git usa (pelo menos no que usamos até o momento) é
sempre uma chave de "classe" seguido de um "específico". Por exemplo, o
`core.sshCommand="env SSH_ASKPASS=~/bin/ssh-askpass.tcl SSH_ASKPASS_REQUIRE=force ssh"`
vira:

```conf
[core]
    sshCommand="env SSH_ASKPASS=~/bin/ssh-askpass.tcl SSH_ASKPASS_REQUIRE=force ssh"
```

E a configuração do git não se importa se eu repetir a mesma chave de classe
múltiplas vezes. Portanto, vamos simular aqui para essa configuração:

```conf
[core]
	sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
[user]
	name = Abóbora
	email = abobora@computaria.io
[core]
    sshCommand=cat
```

Vou identificar com um comentário onde estou lendo, e abaixo mostrar como está
a tabela de valores. No começo é assim:

```conf
# leitura
[core]
	sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
[user]
	name = Abóbora
	email = abobora@computaria.io
[core]
    sshCommand=cat
```

E a tabela vazia. Então, lemos o primeiro bloco e fica assim:

```conf
[core]
	sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
# leitura
[user]
	name = Abóbora
	email = abobora@computaria.io
[core]
    sshCommand=cat
```

E os valores:

```
core.sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
```

Então, leio o próximo bloco:

```conf
[core]
	sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
[user]
	name = Abóbora
	email = abobora@computaria.io
# leitura
[core]
    sshCommand=cat
```

E os valores:

```
core.sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
user.name = Abóbora
user.email = abobora@computaria.io
```

E finalmente, o último bloco. Como aqui houve um "choque" com um valor
anterior, ele será sobrescrito:

```conf
[core]
	sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
[user]
	name = Abóbora
	email = abobora@computaria.io
[core]
    sshCommand=cat
# leitura
```

Ficando assim o mapeamento:

```
core.sshCommand=cat
user.name = Abóbora
user.email = abobora@computaria.io
```

No caso do `includeIf`, ele vai ter uma espécie de "branch" de leitura. No
momento em que o caso da inclusão é resolvido como positivo, a leitura do
arquivo vai acontecer como se o conteúdo do arquivo estivesse ali.

Então, bora lá. Para o caso em que eu estou dentro de um subdiretório de
`~/computaria`:

```conf
# leitura
[user]
	name = Jefferson Quesado
	email = jeff.quesado@gmail.com

[includeIf "gitdir:~/computaria/"]
	path = ~/confs/computaria
    # conteúdo do ~/confs/computaria:
    # [core]
	# 	sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
	# [user]
	# 	name = Abóbora
	# 	email = abobora@computaria.io
[includeIf "gitdir:~/source/firma/cc-work/"]
	path = ~/confs/claude-ssh
```

E o mapeamento de valores está vazio no momento. Então, vamos ler o primeiro
bloco:

```conf
[user]
	name = Jefferson Quesado
	email = jeff.quesado@gmail.com

# leitura
[includeIf "gitdir:~/computaria/"]
	path = ~/confs/computaria
    # conteúdo do ~/confs/computaria:
    # [core]
	# 	sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
	# [user]
	# 	name = Abóbora
	# 	email = abobora@computaria.io
[includeIf "gitdir:~/source/firma/cc-work/"]
	path = ~/confs/claude-ssh
```

E fica assim o mapeamento:

```
user.name = Jefferson Quesado
user.email = jeff.quesado@gmail.com
```

Agora, entramos no bloco `includeIf`. Neste caso específico, como o diretório
em que me encontro é um subdiretório dentro de `~/computaria`, a condição dá
`true`. Então é como se ele substituísse o conteúdo daquele bloco (tecnicamente
podemos colocar múltiplos `path` dentro do `includeIf`, mas o racional continua
o mesmo):

```conf
[user]
	name = Jefferson Quesado
	email = jeff.quesado@gmail.com

[includeIf "gitdir:~/computaria/"] # <== avaliou como true
	path = ~/confs/computaria
# leitura
    # conteúdo do ~/confs/computaria:
    # [core]
	# 	sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
	# [user]
	# 	name = Abóbora
	# 	email = abobora@computaria.io
[includeIf "gitdir:~/source/firma/cc-work/"]
	path = ~/confs/claude-ssh
```

Então, aqui, ela vai começar a ler o conteúdo do arquivo incluído:

```conf
[user]
	name = Jefferson Quesado
	email = jeff.quesado@gmail.com

[includeIf "gitdir:~/computaria/"] # <== avaliou como true
	path = ~/confs/computaria
    # conteúdo do ~/confs/computaria:
    # [core]
	# 	sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
# leitura
	# [user]
	# 	name = Abóbora
	# 	email = abobora@computaria.io
[includeIf "gitdir:~/source/firma/cc-work/"]
	path = ~/confs/claude-ssh
```

Alterando agora os valores lidos para:

```
user.name = Jefferson Quesado
user.email = jeff.quesado@gmail.com
sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
```

Ao ler o próximo bloco dentro do arquivo incluído:

```conf
[user]
	name = Jefferson Quesado
	email = jeff.quesado@gmail.com

[includeIf "gitdir:~/computaria/"] # <== avaliou como true
	path = ~/confs/computaria
    # conteúdo do ~/confs/computaria:
    # [core]
	# 	sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
	# [user]
	# 	name = Abóbora
	# 	email = abobora@computaria.io
# leitura
[includeIf "gitdir:~/source/firma/cc-work/"]
	path = ~/confs/claude-ssh
```

Houve choque tanto em `user.name` como em `user.email`, ficando assim no final:

```
user.name = Abóbora
user.email = abobora@computaria.io
sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
```

O próximo canto é o `includeIf` que verifica se é um subdiretório de
`~/source/firma/cc-work`. Como havia em `false`, ele pula a seção do
`includeIf` sem de fato fazer inclusão de nada:

```conf
[user]
	name = Jefferson Quesado
	email = jeff.quesado@gmail.com

[includeIf "gitdir:~/computaria/"] # <== avaliou como true
	path = ~/confs/computaria
    # conteúdo do ~/confs/computaria:
    # [core]
	# 	sshCommand="ssh -i ~/computaria/.ssh/id_ed25519 -o IdentitiesOnly=yes"
	# [user]
	# 	name = Abóbora
	# 	email = abobora@computaria.io
[includeIf "gitdir:~/source/firma/cc-work/"] # <== avaliou como false
	path = ~/confs/claude-ssh
# leitura
```

# Ordem de leitura

Além da questão das inclusões, o git segue alguns níveis de leitura de
configurações:

- sistema
- global (ou usuário)
- local (ou repositório)
- worktree
- linha de comando

Nessa ordem. O da linha de comando você acrescenta usando a flag `-c`. O
funcionamento pode ser imaginado por cima como se colasse os arquivos um após o
outro (no caso do `-c`, bem, imagina como se fosse uma entrada no final, pode
ser?).

# Inclusão não condicional

Além da inclusão condicional, que vimos acima com o `includeIf`, pela doc a
gente também toma conhecimento da inclusão não condicional. Ela tem a função de
abstrair um conjunto de informações. 

Apesar de não servir para criar perfis, como foi feito usando a inclusão
opcional no `.gitconfig` a nível de usuário, pode ser usado com alguns fins:

- isolar para melhor gerenciar um conjunto de informações
- abstrair opções comuns usadas em diversos módulos

Fica a gosto do usuário a melhor alternativa de como fazer o uso.

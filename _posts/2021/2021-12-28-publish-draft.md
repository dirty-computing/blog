---
layout: post
title: "Movendo de draft para post"
author: "Jefferson Quesado"
tags: meta shell-script bash
base-assets: "/assets/publish-draft/"
---

Rapidinho sobre o script de mover de rascunho (pasta `/_drafts/`) para post (pasta `/_posts/`).

O primeiro ponto foi decidir sobre qual pasta colocar o script de modo a tentar não entrar
no meio do caminho do Jekyll. Aparentemente `/bin/` não ofende, então coloquei ali...

Mas, sabe de uma coisa? Na real ofende sim:

![Oops, regerando ao salvar o bin/publish.sh]({{ page.base-assets | append: "regenerating-bin-publish-sh.png" | relative_url }})

Então, como fazer para evitar isso? Bem, adicionar no `_config.yml` para ignorar essa pasta:

```yml
exclude: ["README.md", "bin/"]
```

Aproveitei que já existia no `_config.yml` a diretiva `exclude` como uma lista e adicionei a pasta. A primeiro
momento parecia que ia funcionar. Ao testar, funcionou mesmo. Ok, fico satisfeito de que o Jekyll se comportou
como eu imaginava que ele iria se comportar. Não fui atrás de entender ainda as diretivas do arquivo de
configuração, estou feliz na minha ignorância por hora.

O próximo passo é definir como que eu vou interagir com isso. Já não é a primeira vez que
preciso transferir algo do rascunho para um artigo propriamente dito, portanto isso estava
me custando um tempinho a mais do que o que eu gostaria de fazer. Além disso, é bastante
_error-prone_, visto que o formato do nome da postagem no Jekyll (pelo menos do jeito que está
configurado aqui no Computaria) é bem específico.

Pois bem, o script pode até ser mais bem elaborado, mas precisamos partir de um começo, não é?
Para esse primeiro momento, gostaria apenas de digitar o seguinte:

```bash
$ bin/publish.sh publish-draft
```

Porém, sem ter auto-completar devidamente configurado, preciso me esforçar mentalmente mais do que eu
gostaria. Portanto, também vou considerar igualmente válido colocar as seguintes variantes:

```bash
$ bin/publish.sh publish-draft
$ bin/publish.sh publish-draft.md
$ bin/publish.sh _drafts/publish-draft.md
```

Isso me satisfaz. Eu posso inferir que, não informando o `.md` no final, estou lidando com arquivos `.md`, daí
só preciso do alias do artigo (no caso do artigo atual, `publish-draft`). Também gostaria de lidar _apenas_ com
as coisas em `/_drafts`, nada além. Se não for informado o diretório `_dratfs/`, posso concluir que estou lidando
com algo dentro desse diretório. Se for fornecido algo com `/` no nome, devo me certificar que o nome começa com
`_drafts/` e que só tenha essa única barra.

Ok, partindo desse princípio, como lidar? Primeiro ponto: vou evitar entrada vazia. Esse ponto será eventualmente
alterado para permitir que eu possa fazer algo mais interessante no futuro (como listar os rascunhos disponíveis e permitir
clicar no que se quer publicar), mas por hora é o que temos para hoje:

```bash
if [ $# != 1 ]; then
	echo "Forneça um (e apenas um) draft para publicar" >&2
	exit 1
fi
```

Ok, bacana. Também aproveitei e lidei com o fato de publicar múltiplas coisas de uma vez só. Por hora, melhor evitar isso
do que se sujeitar a causar algum dano.

Ok, hora de manipular a string. Primeiro ponto, verificar se tem `/` no nome. Tem algumas alternativas para isso, mas a minha
favorita é expandir a variável excluindo o que está a esquerda da barra:

```bash
$ v=abc/def
$ echo ${v#*/}
def
$ echo ${v%/*}
abc
```` 

Se a expansão for idêntica a variável, isso significa que a variável não tem `/` no nome. Daí:

```bash
if [ "${DRAFT%/*}" = "$DRAFT" ]; then
	echo "não tem barra"
fi
```

Note que estou sempre protegendo a variável contra uma expansão vazia usado `"$DRAFT"`. Se, na pior das hipóteses, a variável
expandir para nada, ela continuará gerando um token para contar como argumento no Bash e assim pelo menos evitar dores de cabeça
como `[: =: unary operator expected`:

```bash
$ [ $m = "" ]
bash: [: =: unary operator expected
$ [ "$m" = "" ]

```

Isso se sucede pelo jeito como o Bash tenta interpretar os argumentos e a expansão de valores (seja de variáveis, seja de
subtituição textual de subshell, seja como for). Vamos desmontar o caso do unário:

```bash
[ $m = "" ]
```

Aqui, como a variável `m` não está definida (ou está definida como `m=""`, ou como `m="      "`), `$m` será expandido substituindo
o seu valor. No caso de variável indefinida, se não colocar a opção para dar ruim no processamento de variáveis indefinidas
do Bash com `set -u` (vide [https://wizardzines.com/comics/bash-errors/](https://wizardzines.com/comics/bash-errors/) da
[Julias Evans](https://twitter.com/b0rk)), ele irá expandir para string vazia. Isso significa que, para `m` indefinido,
escrever as duas linhas abaixo é a mesma coisa:

```bash
[ $m = "" ]
[  = "" ]
```

Se o valor da variável fosse `m="      "`, as seguintes linhas são iguais:

```bash
[ $m = "" ]
[        = "" ]
```

Bem, aí já viu que você está cometendo alguma besteira, né? `=` é uma operação binária no comando `test` (que tem o alias `[`
em todo sistema Unix que já mexi, com a diferença de que o comando `[` precisa ter como último argumento `]`). Se colocarmos aspas
ao redor da variável, isso significa que o Bash terá um entendimento forçado de que aquilo é uma string. Daí:

```bash
[ "$m" = "" ]
[ "" = "" ]
```

O que claramente não configura problema e ainda retorna verdadeiro. Para o valor `m="      "`:

```bash
[ "$m" = "" ]
[ "      " = "" ]
```

O que claramente não configura problema e ainda retorna falso.

Ok, hora de verificar se o post tem extensão. Se tiver, usemos a fornecida. Se não tiver, adicionemos `.md`. Como
fazer isso? Bem, da mesma forma: fazendo expansão de variável. Agora, no lugar de cortar do final, vou cortar
do começo porque eu espero que `${DRAFT##*.}` seja menor do que `${DRAFT%.*}`, mas até que se prove o contrário isso
é mais uma escolha estética do que prática.

```bash
if [ "${DRAFT%/*}" = "$DRAFT" ]; then
	echo "não tem barra"
	if [ "${DRAFT##*.}" = "$DRAFT" ]; then
		echo "não tem extensão"
	fi
fi
```

Ok, hora de lidar com pequenas questões práticas e começar a resolver o problema. Quando não há extensão, vamos
adicionar a extensão. Quando não há barras, vamos adicionar o diretório:

```bash
if [ "${DRAFT%/*}" = "$DRAFT" ]; then
	DRAFT="_drafts/$DRAFT"
	if [ "${DRAFT##*.}" = "$DRAFT" ]; then
		DRAFT+=.md
	fi
	echo "$DRAFT"
fi
```

Ok, _so far, so good_. Agora precisamos lidar com a situação do existir a barra... algumas validações que precisam
ser feitas são:

1. só pode haver uma única barra
1. o que vier antes da barra precisar ser `_drafts`

Como fazer isso? Bem, dá para fazer isso numa única expansão:

```bash
if [ "${DRAFT%/*}" = "_drafts" ]; then
	echo "ok"
else
	echo "Deu ruim, não começa com '_drafts' ou tem mais de uma barra" >&2
	exit 1
fi
```

Isso acontece porque a expansão `${var%/*}` não é gulosa. Ela vai ignorar a partir da última barra:

```bash
$ m=sin/sala/bim
$ echo $m
sin/sala/bim
$ echo ${m%/*}
sin/sala
$ echo ${m%%/*}
sin
```

Assim, se eu tiver `m=_drafts/bim.md`:

```bash
$ echo ${m%/*}
_drafts
```

E se eu tiver `m=_drafts/sin/sala/bim.md`:

```bash
$ echo ${m%/*}
_drafts/sin/sala
```

Qualquer outra coisa que tenha uma única barra porém não comece com `_drafts/` irá expandir
para algo que não seja `_drafts`, portanto esse teste com essa expansão já satisfaz naturalmente
o segundo requisito listado acima. Juntando com o anterior:

```bash
if [ "${DRAFT%/*}" = "$DRAFT" ]; then
	DRAFT="_drafts/$DRAFT"
	if [ "${DRAFT##*.}" = "$DRAFT" ]; then
		DRAFT+=.md
	fi
	echo "$DRAFT"
elif [ "${DRAFT%/*}" = "_drafts" ]; then
	echo "DRAFT"
else
	echo "Deu ruim, não começa com '_drafts' ou tem mais de uma barra" >&2
	exit 1
fi
```

Mas, isso tá meio tosco, né? Podemos simplificar colocando o `echo "$DRAFT"` para fora:

```bash
if [ "${DRAFT%/*}" = "$DRAFT" ]; then
	DRAFT="_drafts/$DRAFT"
	if [ "${DRAFT##*.}" = "$DRAFT" ]; then
		DRAFT+=.md
	fi
elif [ "${DRAFT%/*}" != "_drafts" ]; then
	echo "Deu ruim, não começa com '_drafts' ou tem mais de uma barra" >&2
	exit 1
fi
echo "$DRAFT"
```

Beleza, já temos agora um modo de nomear o arquivo e, imediatamente, verificar se é válido!
Agora precisamos saber se é possível trabalhar com esse arquivo. Para isso, precisamos verificar
se é um arquivo ordinário. O `test` já nos fornece algo para verificar isso através do `-f`:

```
$ help test
test: test [expr]
    Evaluate conditional expression.

    Exits with a status of 0 (true) or 1 (false) depending on
    the evaluation of EXPR.  Expressions may be unary or binary.  Unary
    expressions are often used to examine the status of a file.  There
    are string operators and numeric comparison operators as well.

    The behavior of test depends on the number of arguments.  Read the
    bash manual page for the complete specification.

    File operators:

      [...]
      -f FILE        True if file exists and is a regular file.
      [...]
```

Então, dado que normalizamos o nome do arquivo de rascunho na variável `DRAFT`, precisamos
apenas perguntar se ele existe e é um arquivo normalzinho:

```bash
[ -f "$DRAFT" ]
```

Note que estou ainda protegendo a string expandida da variável `$DRAFT` porque, se tiver espaços
no nome, as coisas não vão funcionar bem. Para testar a inexistência do arquivo e abortar imediatamente
só negar a condição e ser feliz:

```bash
if [ ! -f "$DRAFT" ]; then
	echo "Não existe '$DRAFT'" >&2
	exit 1
fi
```

Ok, próximo passo agora é mover, certo? Bem, eu normalmente diria que sim, mas estou com onda de má sorte.
No lugar de fazer isso imediatamente, que tal antes elencar o arquivo no git? Só um `git add "$DRAFT"` e pronto.
E o bom é que essa operação é idempotente para o caso que estamos aqui, brincando com a construção do script.

Ok, e agora? Precisamos mover o arquivo de `_drafts/` para `_posts/` e ainda colocar a data na frente. Mover de
`_drafts/` para `_posts/` é fácil:

```bash
$ echo "_posts/${DRAFT#_drafts/}"
```

Mas ainda fica faltando a data de hoje... E se eu simplesmene perguntar pro `date`?

```bash
$ date
ter, 28 de dez de 2021 11:18:22
```

Nada bom, nada bom... ele pega meu locale, dia da semana, hora... e se eu pedir formato ISO? Afinal,
o ISO 8601 prevê que, ao escrever a data completa (sem hora), ela venha sempre no formato `yyyy-MM-dd`. E
é isso que o Jekyll precisa para um post. Será que tem a opção `--iso` para o comando `date`?

```bash
$ date --iso
2021-12-28
```

PERFEITO! Ok, agora precisamos colocar o dia de hoje no nome do arquivo. Para mim, nada mais natural do que
uma expansão de comando:

```bash
$ echo "_posts/`date --iso`-${DRAFT#_drafts/}"
```

Parece perfeitinho, não é? Agora, vamos mover de `DRAFT` para a localização definitiva do arquivo, podemos usar
o `git mv` para esse fim. Vamos adicionar também a flag para ser verboso só para vermos como isso vai ficar no fim
das contas:

```bash
$ bin/publish.sh _drafts/assintota-ou-aquiles-e-a-tartaruga.md
Renaming _drafts/assintota-ou-aquiles-e-a-tartaruga.md to _posts/2021-12-28-assintota-ou-aquiles-e-a-tartaruga.md
```

Puff, magicamente está publicado! E o melhor de tudo: pronto para commitar!

Ok, agora a última coisa: commitar o script. Aparentemente essa é uma tarefa trivial né? Exceto quando você
está no Windows e quer commitar um arquivo executável. Para essas situações, precisamos lembrar de dar um
`update-index`:

```bash
git update-index --add --chmod=+x bin/publish.sh
```

O `update-index` funciona se o arquivo já for de domínio do repositório. Se quiser também, em uma tacada só, já
adicionar o arquivo, só pedir isso usando a flag `--add` como eu fiz acima.

E, pronto. Agora só rodar `bin/publish.sh publish-draft` e estou pronto!
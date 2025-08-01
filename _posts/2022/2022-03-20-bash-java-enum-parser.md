---
layout: post
title: "Um parser em bash que identifica enums de um fonte Java"
author: "Jefferson Quesado"
tags: parser shell-script java
---

Me deparei com uma situação interessante no trabalho: preciso garantir que um
determinado código não entre em deriva com outro. O que eles tem em comum? São
enumerações. O que eles não tem em comum? A linguagem.

Supostamente dava para fazer um processo de rodar uma das linguagens em que o código
está escrita, ler o fonte da outra linguagem e extrair essa enumeração e comparar.
Mas isso significa levantar uma instância Docker no CI para identificar isso, e já
temos um _job_ no GitLab-CI que verificamos alguns traços de sanidade no código. E
esse _job_ tem Bash, basicamente.

Uma das linguagens em que precisamos identificar se a enumeração entrou em deriva é
Java. Vamos ver como extrair enumerações de dentro do Java usando apenas Bash?

# Pressupostos

O arquivo Java é bem formado (ie, ele compila). Não interessa _nested enums_, apenas
enumerações _top level_. Só se tem uma _top level entity_, e essa entidade será uma
enumeração.

# Definindo o teste

Vamos pegar o nosso arquivo. Ele irá soltar como _output_ apenas as enumerações. Por
exemplo, `Day` (exemplo dentro dos [tutoriais da Oracle](https://docs.oracle.com/javase/tutorial/java/javaOO/enum.html)):

```java
public enum Day {
    SUNDAY, MONDAY, TUESDAY, WEDNESDAY,
    THURSDAY, FRIDAY, SATURDAY
}
```

A saída esperada deveria ser:

```txt
SUNDAY
MONDAY
TUESDAY
WEDNESDAY
THURSDAY
FRIDAY
SATURDAY
```


Então, como saber se estou indo para o lado certo? Simples: colocando o resultado
esperado em algum arquivo (`res`, por exemplo) e comparando o resultado do _output_ do
meu script com o resultado esperado. Se o script for `extract-enum.sh`, a comparação seria
assim:

```bash
./extract-enum.sh | diff - res
```

Para uma melhor generalização do problema, podemos redirecionar a entrada padrão do `extract-enum.sh`
para ser o arquivo adequado. No caso da enumeração `Day` acima, sem pacotes:

```bash
./extract-enum.sh < src/main/java/Day.java | diff - res
```

## Funcionamento do `diff`

O comando `diff` normalmente é usado para verificação das diferenças entre dois arquivos distintos,
arquivos esses passados como argumentos do comando `diff`. Porém, tem uma anotação especial, o `-`, que
na verdade indica que vem da entrada padrão. Se você realmente tem um arquivo chamado `-` e pretende
usá-lo, você pode mencioná-lo através do diretório, com `./-`.

O comando `diff` termina com sucesso (código de saída 0) se os arquivos comparados forem iguais. Termina
com erro (código de saída diferente de 0) se não forem iguais. Portanto, dada uma entrada qualquer e sua
saída esperada, podemos sempre verificar com `diff` se o _output_ fornecido por um programa resulta na
saída esperada.

# Formato geral de uma enumeração no Java

Uma enumeração é um caso específico de um arquivo Java. Um arquivo Java é, de modo geral,
um preâmbulo seguido de vários componentes irmãos. Cada componente irmão é um _top level element_. Esses
elementos podem ser:

- classe
- interface
- anotação
- enumeração

O preâmbulo por sua vez é constituído pelo pacote e pelas importações. Comentários são livres para existirem
em qualquer lugar. Uma nota importante é que dentre os diversos elementos irmãos, apenas um pode ser público.

De modo geral, ignorando comentários, um arquivo Java é algo assim:

```
arq-java ==> preâmbulo elemento elementos
preâmbulo ==> pacote? imports
imports ==>
imports ==> import imports
import ==> <<import>> classe
import ==> <<import>> wildcard
import ==> <<import static>> classe
import ==> <<import static>> wildcard
elementos ==>
elementos ==> elemento elementos
elemento ==> modificador-acesso id-interface nome super-interface corpo-interface
elemento ==> modificador-acesso id-anotação nome super-anotação corpo-anotação
elemento ==> modificador-acesso id-classe nome super-classe corpo-classe
elemento ==> modificador-acesso id-enumeração nome super-enumeração corpo-enumeração
modificador-acesso ==> <<public>>
modificador-acesso ==> <<protected>>
modificador-acesso ==> <<private>>
modificador-acesso ==>
id-interface ==> <<interface>>
id-anotação ==> <<@interface>>
id-classe ==> <<class>>
id-enumeração ==> <<enum>>
corpo-interface ==> <<{>> vísceras-interface <<}>>
corpo-anotação ==> <<{>> vísceras-anotação <<}>>
corpo-classe ==> <<{>> vísceras-classe <<}>>
corpo-enumeração ==> <<{>> vísceras-enumeração <<}>>
```

Onde o código mora nas vísceras. Algumas coisas fiz vista grossa proposital, como _generics_
e anotações, voltaremos a anotações mais tarde.

A partir daqui, o que se observa de interessante? Que toda e qualquer víscera começa com `{`.

Então, de modo geral, posso simplesmente começar a me preocupar apenas quando encontrar o primeiro
`{`, ignorando todo o resto (comentário não entra no "modo geral").

Ok, e depois do `{`? Agora temos:

1. a lista enumerada
2. eventuais métodos internos

```
vísceras-enumeração ==> lista-enumerada
vísceras-enumeração ==> lista-enumerada <<;>> vísceras-classe
lista-enumerada ==> elemento-enumeração <<,>> lista-enumerada
lista-enumerada ==> elemento-enumeração
lista-enumerada ==>
elemento-enumeração ==> nome args-construtor? subclasse?
elemento-interno ==> campo
elemento-interno ==> método
elemento-interno ==> construtor
elemento-interno ==> bloco-código
args-construtor ==> <<(>> args <<)>>
subclasse ==> <<{>> vísceras-classe <<}>>
```

Se for encontrado um `;`, a lista enumerada acabou (afinal, não me interessa sobre detalhes internos
da enumeração, apenas quais são os elementos enumerados). O `}` solto, que pareia com o `{` do corpo
da enumeração, também é um sinal de fim da enumeração.

Eventualmente será passado algo para o construtor da enumeração. Essa situação é trivialmente identificada
com o começo do bloco de chamada de construtor (convenientemente o mesmo que o começo de chamada de método, o `(`)
e termina com o `)` correspondente. Eventualmente também um elemento enumerado pode sobrescrever algum
comportamento da classe mãe, portanto fazendo uma subclasse. Assim como o identificador de chamada de
construtor, ele tem o início de bloco `{` e termina com o fim de bloco `}` correspondente.

## Compilador para identificar os elementos da enumeração

De modo geral, tudo será ignorado até o `{` que inicia as vísceras da enumeração. Então, iremos processar até:

- o `}` com o fechamento correspondente
- um `;` que seja produção sintática de `vísceras-enumeração` (ie, nó irmão dos elementos enumerados)

Vamos por hora começar do mais simples e ir complicando aos poucos, ok? Vale lembrar também que é pressuposto
que este seja um arquivo Java válido para uma enumeração, então não iremos nos preocupar se, por acaso, o arquivo
tenha um `;` no final dos elementos da enumeração porém não fechou a enumeração com o fim de bloco `}`.

Como o desejado é detectar nomes e nomes em Java a priori tem letras (maiúsculas e minúsculas), números e `_`,
qualquer caracter fora do padrão `[A-Za-z0-9_]` será levado em consideração como "quebra de palavra". Se o nome tiver
pelo menos um caracter válido e for encontrada uma quebra de palavra, ele deverá ser impresso. Caso contrário, se ele
eu estiver lendo uma palavra e o próximo caracter da leitura for um caracter de nome, então devo apendar esse caracter
ao nome sendo lido.

Nesse momento, eu tenho uma máquina de estados assim (onde `EOE` significa _end of enum_):

```
inicial ==> `{` possíveis-enums
inicial ==> . inicial
possíveis-enums ==> [A-Za-z0-9_] possíveis-enums
possíveis-enums ==> `;` EOE
possíveis-enums ==> `}` EOE
possíveis-enums ==> . possíveis-enums
```

Eu sei que esse não é o estado final, sei que vou precisar eventualmente de uma máquina de pilha, mas para o começo essa já funciona.

Já conseguimos ir para o primeiro caso, vamos nessa?

### Criando cenários de teste

No [_companion_ deste artigo](https://gitlab.com/computaria/blog-companion/-/tree/main/bash-enum-parser) criei duas pastas:

- `extract-enum`, onde guardo os scripts de extração de enumeração Java
- `java-samples`, onde guardo tanto as enumerações Java como seus correspondentes resultados

E o grau de evolução e complexidade são indicados por numerais. No Java, começamos com `Day01.java` que tem como resposta
esperada o `Day01.res`. Um script de teste (`extract-enum-test.sh`) é fornecido na base que recebe dois argumentos:

- o script shell a ser executado
- o arquivo Java (pode ser até sem a extensão) para fazer o diff

É só para facilitar fazer o seguinte:

```bash
extract-enum/extract-enum-01.sh < java-samples/Day01.java | diff - java-samples/Day01.res
```

### Leitura simples: enumerações sem contrutor nem subclasse

O cenário mais simples para enumeração é que ela não tenha construtores nem subclasses nos seus itens.

Para tal, implementemos a máquina de estados acima descrita. Precisamos ler um caracter por vez e fazer a seleção
do estado específico.

Para fazer a leitura de um único caracter, podemos usar o comando `read`, passando o modificador `-n` com argumento `1`:

> ```
> $ help read
> [...]
>       -n nchars return after reading NCHARS characters rather than waiting
>                 for a newline, but honor a delimiter if fewer than
>                 NCHARS characters are read before the delimiter
> ```

Então, lemos o caracter com `read -n1 CARACTER`, armazenando na variável `CARACTER`. O `read` só retorna falso quando
não é mais possível fazer leitura (seja porque acabou a entrada, deu _timeout_, _file descriptor_ inválido, não conseguiu
colocar o valor na variável desejada etc). Portanto, podemos por a leitura num `while read -n1 CARACTER; do ...; done`.

Então, precisamos fazer o processamento para cada estado adequado. No caso, temos os estados:

- `inicial`
- `possíveis-enums`
- `EOE`

Como lidar com isso? Precisamos guardar o estado em alguma variável cujo valor inicial é equivalente a `inicial`.
Podemos usar a estrutura `case ... in` do Bash:

```bash
case "$state" in
	INICIAL)
		;;
	POSSIVEIS_ENUM)
		;;
esac
```

Essa estrutura começa com `case`, termina com `esac`. Após o `case` é especificado o que se deseja fazer _pattern-matching_.
No caso, desejamos fazer o casamento com a expansão simples de `state`. Então, precisamos determinar os casos.

Cada caso consiste de um padrão glob terminado por um `)`. Depois seguem-se comandos Bash até encontrar um `;;` duplo
ponto-e-vírgula (o último duplo ponto-e-vírgula é opcional). Indentações (como espaço e tabulação) não são considerados parte
do padrão, exceto se englobados por aspas/apóstrofos. Aqui, quero simplesmente fazer o _matching_ com o nome de um estaos (ou
de mais estados). Podemos usar `|` para separar os padrões sendo casados.

Então, vamos lá. Do estado `inicial` eu posso sair para `possíveis-enums` se for encontrado um `{`. Em todos os outros casos
se mantém no estado `inicial`. Portanto, o código dentro do estado `inicial` é:

```bash
if [ "$CARACTER" = '{' ]; then
  state=POSSIVEIS_ENUM
fi
```

E no `possíveis-enums`? Bem, pela regra se encontrar algo no padrão `[A-Za-z0-9_]` devo acumular, caso contrário devo imprimir
o acumulado caso esse não seja vazio:

```bash
if [[ "$CARACTER" = [A-Za-z0-9_] ]]; then
	enum_lida+="$CARACTER"
else
	if [ -n "$enum_lida" ]; then
		echo "$enum_lida"
		enum_lida=''
	fi
fi
```

Note que aqui uso a construção de teste `[[` para verificar se a variável `$CARACTER` casa `=` com o glob `[A-Za-z0-9_]`.
O `test` convencional não fornece maneira simples de ter a mesma funcionalidade.

Caso o caracter lido não seja algo para fazer a acumulação, então verificamos num `test` convencional se a string
está não vazia (operador unário `-n`). Estando não vazia, imprimo-a (como eseprado) e reseto meu acumulador.

Bem, e os casos de fim da enumeração? Ainda não foram tratados. Só colocar para realizar o teste, se for o `}` ou o
`;` acabou a conversa:

```bash
if [ "$CARACTER" = '}' ] || [ "$CARACTER" = ';' ]; then
	state=EOE
fi
```

isso fica necessariamente após o teste para saber se se deve imprimir a enumeração lida ou não. Na implementação original eu tive
problemas para colocar o `OU` lógico (operador `-o` do comando `test`) dentro do comando `test`, então usei o `||` que o próprio Bash
fornece para controlar a saída obtida, por isso que ele está entre os dois testes.

Com o `EOE` no lugar e forçando o fim da execução nesse estado, posso continuar a minha enumeração e colocar vísceras dignas de
uma classe que o reconhecimento funciona bem:

```java
public enum Day02 {
	SUNDAY, MONDAY, TUESDAY, WEDNESDAY,
	THURSDAY, FRIDAY, SATURDAY;
	
	private final int weekday;
	Day02() {
		weekday = -1;
	}
	Day02(int weekday) {
		this.weekday = weekday;
	}
}
```

### Leitura ainda simples: enumerações sem contrutor nem subclasse com comentários

Ok, vamos começar a dificultar as coisas? Tudo muito bom aqui, e se tivesse um comentário? Temos dois tipos de comentários, comentário
de linha e comentário de bloco. O comentário de linha começa em qualquer lugar com `//` e vai até o final da linha. Já o comentário de bloco
começa necessariamente com `/*` e termina ao encontrar `*/`. Vamos lidar com eles? A priori, eles parecem inofensivos:

```java
// comentário de linha

/* e o
  de bloco */
public enum Day03 {
	SUNDAY, MONDAY, TUESDAY, WEDNESDAY,
	THURSDAY, FRIDAY, SATURDAY;
	
	private final int weekday;
	Day03() {
		weekday = -1;
	}
	Day03(int weekday) {
		this.weekday = weekday;
	}
}
```

Até que colocamos dentro das enumerações...

```java
// comentário de linha

/* e o
  de bloco */
public enum Day04 {
	SUNDAY /* um bloco no meio */, MONDAY, TUESDAY, WEDNESDAY,
	// quebrando a linha
	THURSDAY, FRIDAY, SATURDAY;
	
	// oops quebrando a linha
	private final int weekday;
	Day04() {
		weekday = -1;
	}
	Day04(int weekday) {
		this.weekday = weekday;
	}
	/* passando aqui
	   com o meu bloco */
}
```

O teste produziu linhas a mais. Eis o retorno do script de testes:

```bash
$ ./extract-enum-test.sh extract-enum/extract-enum-01.sh java-samples/Day04
2,5d1
< um
< bloco
< no
< meio
9,11d4
< quebrando
< a
< linha
```

Ok, só os comentários fazendo bobeira. Preciso levar em consideração que `/` solto no meio de um código pode
ser código válido (o usuário pode estar fazendo uma divisão para o retorno de um método, por exemplo). Então preciso
capturar `//` para identificar comentário de linha e `/*` para identificar comentário de bloco. Como lidar com isso?
Bem, aqui vou fugir um pouco da máquina de estados na implementação, mas a ideia basicamente é:

- pode estar em um estado "comentável", como `INICIAL` e `POSSIVEIS_ENUM`
- ao ler a `/`, fica num estado de observação  
    ```
    INICIAL ==> `/` INICIAL+BARRA
    POSSIVEIS_ENUM ==> `/` POSSIVEIS_ENUM+BARRA
    ```
- ao ler a segunda barra, entro no modo de comentário de linha do estado anterior, caso contrário (exceto `*`, não tratado aqui) o retorno ao estado anterior já  
    ```
    INICIAL+BARRA ==> `/` COMMENT_LINHA+INICIAL
    POSSIVEIS_ENUM+BARRA ==> `/` COMMENT_LINHA+POSSIVEIS_ENUM
    INICIAL+BARRA ==> . INICIAL
    POSSIVEIS_ENUM+BARRA ==> . POSSIVEIS_ENUM
    ```
- ao ler o fim de linha (seja `\r`, seja `\n`) no estado de comentário de linha, decreto o fim do comentário de linha e restauro o estado anterior  
    ```
    COMMENT_LINHA+INICIAL ==> `\r` INICIAL
    COMMENT_LINHA+INICIAL ==> `\n` INICIAL
    COMMENT_LINHA+POSSIVEIS_ENUM ==> `\r` POSSIVEIS_ENUM
    COMMENT_LINHA+POSSIVEIS_ENUM ==> `\n` POSSIVEIS_ENUM
    COMMENT_LINHA+INICIAL ==> . COMMENT_LINHA+INICIAL
    COMMENT_LINHA+POSSIVEIS_ENUM ==> . COMMENT_LINHA+POSSIVEIS_ENUM
    ```
- estando no modo de barra detectada, ao ler o asterisco, entro em comentário de bloco  
    ```
    INICIAL+BARRA ==> `*` COMMENT_BLOCK+INICIAL
    POSSIVEIS_ENUM+BARRA ==> `*` COMMENT_BLOCK+POSSIVEIS_ENUM
    ```
- de modo semelhante à detecção da primeira barra, detecto o asterisco (indicado por `+STAR`) e regresso ao modo anterior se do `+STAR`
  for lida uma barra `/` (estrelas mantém o estado em `+STAR`)  
    ```
    COMMENT_LINHA+INICIAL ==> `*` COMMENT_LINHA+INICIAL+STAR
    COMMENT_LINHA+POSSIVEIS_ENUM ==> `*` COMMENT_LINHA+POSSIVEIS_ENUM+STAR
    COMMENT_LINHA+INICIAL+STAR ==> `/` INICIAL
    COMMENT_LINHA+POSSIVEIS_ENUM+STAR ==> `/` POSSIVEIS_ENUM
    COMMENT_LINHA+INICIAL+STAR ==> `*` COMMENT_LINHA+INICIAL+STAR
    COMMENT_LINHA+POSSIVEIS_ENUM+STAR ==> `*` COMMENT_LINHA+POSSIVEIS_ENUM+STAR
    COMMENT_LINHA+INICIAL+STAR ==> . COMMENT_LINHA+INICIAL
    COMMENT_LINHA+POSSIVEIS_ENUM+STAR ==> . COMMENT_LINHA+POSSIVEIS_ENUM
    ```

Como encaixar isso na máquina de estados existente? Então, o segredo é esse: não encaixar literalmente.
Ao ler a barra `/` estando num estado "natural", ligo uma flag "li uma barra", daí posso detectar a leitura de outra barra
ou de asterisco `*`. Ao confirmar entrar em comentário, entro em processo de ignorar tudo até o fim do comentário, retornando
para o estado anterior.

Depois do fechamento do `case`, coloco essa detecção de barra `/`:

```bash
if [ "$CARACTER" = / ]; then
  if $barra; then
    leitura_comentario_linha
    barra=false
  else
    barra=true
  fi
elif $barra; then
  if [ "$CARACTER" = '*' ]; then
    leitura_comentario_bloco
  fi
  barra=false
fi
```

Eu também preciso iniciar essa variável de detecção de barra `barra=false` no começo do script. E, pronto, passamos no caso de
teste para `Day04.java`...

**Se** estivermos usando final de linha modelo Windows. O que acontece, o `read -n1` lê, conforme prometido, um caracter da entrada.
Porém ele também ignora o conteúdo do `IFS` (_internal field separator_, variável com finalidade diversa). No `read`, o `IFS` é usado
para identificar separador de palavras. Como ele identifica como separador de palavras, ele não atribui o valor lido para lugar algum.

Para fazer uma leitura com sucesso de **todo** e **qualquer** caracter, eu preciso inicialmente nocautear total e completamente o `IFS`,
porém como essa variável é utilizada em outros pontos do sistema não é interessante que esse nocaute valha além do comando `read` desejado.
Felizmente o Bash tem artifício para isso: declarar o valor da variável _antes_ de rodar o comando.

Por exemplo, posso declarar uma variável `MARM` e usar ela dentro de uma função, mas fora dessa função o valor anterior dela é o que vale:

```bash
$ imprime_marm() {
>   echo $MARM
> }
$ MARM=abc imprime_marm
abc
$ MARM=xe
$ echo $MARM
xe
$ imprime_marm
xe
$ MARM=abc echo $MARM
xe
$ MARM=abc imprime_marm
abc
$ imprime_marm
xe
```

Especificamente aqui sobre `MARM=abc echo $MARM` imprimindo o valor `xe`, o que está acontecendo? Bem, nesse caso, temos
que a shell faz a expansão das variáveis _antes_ de tentar interpretar o comando. Logo, o comando que a shell realmente irá
ler é `MARM=abc echo xe`. Aí fica claro que será impresso `xe`, não é mesmo? O valor da variável declarada no começo do comando
vale para o comando a direita, não aos argumentos desse comando.

Podemos testar e ver o como o `read` se comporta de modo controlado. Para tal, podemos simplesmente imprimir strings e
fazer um pipeline para ler no `while read`. O `echo` fornece duas flags interessante para brincar aqui:

- `-e`: permite que o `echo` interprete sequências de escape antes de emitir no stdout; `echo -e 'oi\tcom\ttabs'`
- `-n`: evita que o `echo` insira a quebra de linha como último caracter; `echo -n 'sem quebra de linha ali'`

Então, vamos lá? Ler caracter a caracter sem levar em consideração o `IFS`? Vamos ler
`oi\tcom\ttabs\nquebra de linha antes\nmas no fim desta não`:

```bash
echo -ne 'oi\tcom\ttabs\nquebra de linha antes\nmas no fim desta não' | while IFS='' read -n1 CARACTER; do
  echo "lido >$CARACTER<"
done
```

```txt
lido >o<
lido >i<
lido >	<
lido >c<
lido >o<
lido >m<
lido >	<
lido >t<
lido >a<
lido >b<
lido >s<
lido ><
lido >q<
lido >u<
lido >e<
lido >b<
lido >r<
lido >a<
lido > <
lido >d<
lido >e<
lido > <
lido >l<
lido >i<
lido >n<
lido >h<
lido >a<
lido > <
lido >a<
lido >n<
lido >t<
lido >e<
lido >s<
lido ><
lido >m<
lido >a<
lido >s<
lido > <
lido >n<
lido >o<
lido > <
lido >f<
lido >i<
lido >m<
lido > <
lido >d<
lido >e<
lido >s<
lido >t<
lido >a<
lido > <
lido >n<
lido >ã<
lido >o<
```

Hmmm, intrigante. Ele não lê o _line-feed_. E se eu não sobrescrever o `IFS`?

```bash
echo -ne 'oi\tcom\ttabs\nquebra de linha antes\nmas no fim desta não' | while read -n1 CARACTER; do
  echo "lido >$CARACTER<"
done
```

```txt
lido >o<
lido >i<
lido ><
lido >c<
lido >o<
lido >m<
lido ><
lido >t<
lido >a<
lido >b<
lido >s<
lido ><
lido >q<
lido >u<
lido >e<
lido >b<
lido >r<
lido >a<
lido ><
lido >d<
lido >e<
lido ><
lido >l<
lido >i<
lido >n<
lido >h<
lido >a<
lido ><
lido >a<
lido >n<
lido >t<
lido >e<
lido >s<
lido ><
lido >m<
lido >a<
lido >s<
lido ><
lido >n<
lido >o<
lido ><
lido >f<
lido >i<
lido >m<
lido ><
lido >d<
lido >e<
lido >s<
lido >t<
lido >a<
lido ><
lido >n<
lido >ã<
lido >o<
```

Hmmm, intrigante de novo. Então caracteres do `IFS` quando lidos não são colocados no caracter de leitura, e também
não indicam fim de leitura. Além disso, independente do `IFS`, temos que o _line-feed_ é sempre ignorado e colocado como
leitura vazia... Então preciso lidar com isso, né? Colocar agora na máquina de estados não mais a detecção da quebra de
linha, mas também lidar com a leitura vazia como sendo equivalente à quebra de linha...

Ou ler novamente o `help read` e perceber que tem uma maneira mais simples que não envolve o IFS:

```
> $ help read
> [...]
>       -N nchars return only after reading exactly NCHARS characters, unless
>                 EOF is encountered or read times out, ignoring any
>                 delimiter
```

Pronto, resolvido. A leitura com a flag `-N` maiúsculo define que são lidos **exatamente** `nchars` caracteres, independente
de IFS e outras coisas (do trecho "ignoring any delimiter"). Ok, testar então?

```bash
echo -ne 'oi\tcom\ttabs\nquebra de linha antes\nmas no fim desta não' | while read -N1 CARACTER; do
  echo "lido >$CARACTER<"
done
```

```txt
lido >o<
lido >i<
lido >	<
lido >c<
lido >o<
lido >m<
lido >	<
lido >t<
lido >a<
lido >b<
lido >s<
lido >
<
lido >q<
lido >u<
lido >e<
lido >b<
lido >r<
lido >a<
lido > <
lido >d<
lido >e<
lido > <
lido >l<
lido >i<
lido >n<
lido >h<
lido >a<
lido > <
lido >a<
lido >n<
lido >t<
lido >e<
lido >s<
lido >
<
lido >m<
lido >a<
lido >s<
lido > <
lido >n<
lido >o<
lido > <
lido >f<
lido >i<
lido >m<
lido > <
lido >d<
lido >e<
lido >s<
lido >t<
lido >a<
lido > <
lido >n<
lido >ã<
lido >o<
```

Ok, agora funcionou. E nem precisei mexer no `IFS`, ufa...

Adicionar alguns caracteres que poderiam dar problema no meio dos comentários, como `{` antes de começar a enumeração,
ou `}` e `;` soltos logo após o começo de alguma enumeração:

```java
// comentário de linha{

/* e o
  de bloco{ */
public enum Day05 {
		SUNDAY /* um bloco *no meio */, MONDAY, TUESDAY, WEDNESDAY,
		// quebrando a linha} */;
		THURSDAY, FRIDAY, SATURDAY;

		// oops quebrando a linha
		private final int weekday;
		Day05() {
				weekday = -1;
		}
		Day05(int weekday) {
				this.weekday = weekday;
		}
		/* passando aqui
		   com o meu bloco */
}
```

Apesar da estranheza, nada a declarar. Aceitou.

### Leitura complexa: enumerações subclasseando

Vamos sobrecarregar um simples método para `FRIDAY`: o `toString` dela agora vai soltar a string `"SEXTOOOOU!"`:

```java
// comentário de linha{

/* e o
  de bloco{ */
public enum Day06 {
		SUNDAY /* um bloco *no meio */, MONDAY, TUESDAY, WEDNESDAY,
		// quebrando a linha} */;
		THURSDAY, FRIDAY {

			@Override
			public String toString() {
				return "SEXTOOOOU!";
			}
		}, SATURDAY;

		// oops quebrando a linha
		private final int weekday;
		Day06() {
				weekday = -1;
		}
		Day06(int weekday) {
				this.weekday = weekday;
		}
		/* passando aqui
		   com o meu bloco */
}
```

```bash
$ ./extract-enum-test.sh extract-enum/extract-enum-03.sh java-samples/Day06
7,12c7
< Override
< public
< String
< toString
< return
< SEXTOOOOU
---
> SATURDAY
```

Hmmm, não ótimo. Algo não ocorreu como previsto. Mas como? E por quê?

Vamos examinar primeiro o que deu certo e onde foi feito o diferencial. Em primeiro lugar, todas as
enumerações até `FRIDAY` foram corretamente identificadas, incluindo `FRIDAY`. Então, e só então, as coisas
começaram a andar errado. Foi detectado erroneamente que `Override` seria um dos itens da enumeração. E seguiu
para todas as palavras (`public`, `String`, `toString`, `SEXTOOOOU`) que antecederam `SATURDAY`. E não identificou
`SATURDAY`.

Será que o motivo de ter parado _antes_ de `SATURDAY` foi o `;` para fechar a _statement_ de retorno? Hmmm,
vamos ver nossa máquina de estados... (simplificando a questão dos comentários)

```
inicial ==> `{` possíveis-enums
inicial ==> . inicial
possíveis-enums ==> [A-Za-z0-9_] possíveis-enums
possíveis-enums ==> `;` EOE
possíveis-enums ==> `}` EOE
possíveis-enums ==> . possíveis-enums
```


É. Depois do estado `inicial` ela só evolui para `possíveis-enums` e `EOE`. Sendo que entonrar um `;` significa chegar
em `EOE`. E de `possíveis-enums` não entramos em um estado do tipo "hey, ignora isso", a não ser que seja um comentário.
Logo? Falta algo na nossa máquina de estados.

O que fizemos foi declarar uma subclasse. Lembrando da gramática do Java, o subclasseamento é indicado pelo início com `{`,
um código Java válido das vísceras da classe, então um `}` correspondente para fechar. Logo, podemos adicionar a seguinte
transição para a nossa máquina de estado:

```
possíveis-enums ==> `{` stack-automata<`{`,`}`>
```

Onde agora delegamos a um autômato de pilha. O foco desse autômato de pilha vai ser contar aberturas `{` e fechamentos `}`. Quando
for encontrado o fechamento do `{` que iniciou essa brincadeira, então voltamos ao estado de `possíveis-enums`. Como fazer isso em Bash?

Bem, na real, como é o caso de autômato finito mais trivial possível (contar um único elemento e o seu fechamento), vou usar uma pilha
de `1`s. Um pilha de `1`s é um número escrito no sistema unário. Logo, eu posso encodar essa pilha em um número, em que adicionar elementos
nela significa incrementar em uma unidade o tamanho do número, e consumir elementos da lista é justamente decrementar em uma unidade. Logo vou só
usar `num++` e `num--` tradicionais do C e do Java.

Exceto que... eu não tenho diretamente o operador `++`. Mas posso fazer `x+=1`. Se eu declarar que `x` é um inteiro:

```bash
declare -i x
x=0
x+=1
echo $x  # imprime '1'
a=1
a+=1
echo $a # imprime '11'
```

E o decremento? Bem, posso usar `x-=1`?

```
bash: x-=1: command not found
```

Hmm, e se eu "somar" `-1`? Na prática seria a mesma operação de subtrair 1... `x+=-1`...

```bash
declare -i x
x=0
x+=-1
x+=-1
echo $x # imprime '-2'
```

Então, é isso. O autômato de pilha fica mais ou menos assim (para `$` o fim da pilha, consumido pelo `}` terminador)...

Mas, esepra. Vamos precisar de uma notação mínima pro autômato de pilha, não é? Então vamos fazer assim:

do LHS, temos o estado, o caracter lido e o último elemento da pilha. No RHS teremos o novo estado e o que será escrito
na pilha. Caso o elemento da pilha seja ignorado da leitura, será representado por nada no LHS e no RHS. Caso ele seja consumido,
ele será colocado no LHS e nada no RHS. Caso seja apenas produzido, será representado por nada no LHS e o elemento produzido
no RHS.

```
basal, `{`,  ==> basal, `1`
basal, `}`, `1` ==> basal,
basal, `}`, `$` ==> estado-anterior,
basal, .,  ==> basal, 
```

Pronto? Quase... precisamos levar em consideração consideração comentários. Para evitar surpresas, né? Só para ficar claro,
o `$` é representado pelo contador de abre chaves quando esse contador for 0. Então, partiu?

Em `POSSIVEIS_ENUM`, devo entrar no modo `simple_pushdown_automata` com `{` como início de bloco e `}` como fim de bloco ao ler
um `{`, delegando a leitura então para o autômato de pilha:

```bash
if [[ "$CARACTER" = [A-Za-z0-9_] ]]; then
	enum_lida+="$CARACTER"
else
	if [ -n "$enum_lida" ]; then
		echo "$enum_lida"
		enum_lida=''
	fi
	if [ "$CARACTER" = { ]; then
		simple_pushdown_automata { }
	elif [ "$CARACTER" = '}' ] || [ "$CARACTER" = ';' ]; then
		state=EOE
	fi
fi
```

E a implementação do `simple_pushdown_automata` foi feita para receber um caracter de "abre", um caracter de "fecha":

```bash
simple_pushdown_automata() {
	local -r OPEN="$1" CLOSE="$2"

	# resto do corpo ainda a implementar
}
```

Note que estou forçando que as variáveis `OPEN` e `CLOSE` sejam apenas leitura declarando-as com `local -r`.

Como basicamente não mudamos de estado (exceto pelo flag do "li barra" para eventualmente ser usado para ler comentários de bloco/linha),
vou fazer o `case ... in` apenas no caracter de leitura. Começo com uma variável local inteira de contador, começando em 0, para representar
a pilha, com as operações de empilhar e desempilhar já descritas (`cnt+=1` e `cnt+=-1`). Só preciso declarar a variável localmente
com essa propriedade `local -i cnt`. Então, leitura infinita até encontrar a condição de saída (ler o fechamento de bloco `}` com pilha vazia
`[ $cnt = 0 ]`):

```bash
simple_pushdown_automata() {
	local -r OPEN="$1" CLOSE="$2"
	local -i cnt=0
	local CARACTER
	local barra=false

	while read -N1 CARACTER; do
		case "$CARACTER" in
			"$OPEN")
				cnt+=1
				barra=false
				;;
			"$CLOSE")
				if [ $cnt = 0 ]; then
					return
				fi
				cnt+=-1
				barra=false
				;;
			/)
				if $barra; then
					leitura_comentario_linha
					barra=false
				else
					barra=true;
				fi
				;;
			'*')
				if $barra; then
					leitura_comentario_bloco
					barra=false
				fi
				;;
			*)
				barra=false
				;;
		esac
	done
}
```

Note que por via das dúvidas protegi a expansão `"$OPEN"` e `"$CLOSE"`. Também note que para evitar interpretar `*`
como qualquer coisa (que seria a expansão natural do _glob_), protegi usando apóstrofos `'*'`. Logo em seguida quero
capturar qualquer leitura para justamente remover a flag de "achei uma barra".

Uma tentativa maior de quebrar o estilo do arquivo Java, para identificar se estamos lidando corretamente com comentários de bloco/linha:

```java
// comentário de linha{

/* e o
  de bloco{ */
public enum Day07 {
	SUNDAY /* um bloco *no meio */, MONDAY, TUESDAY, WEDNESDAY,
	// quebrando a linha} */;
	THURSDAY, FRIDAY {
		/* coment bloco */
		// comment linha
		@Override
		public String toString() {return "SEXTOOOOU!" + 1/1/1;}
	}, SATURDAY;

	// oops quebrando a linha
	private final int weekday;
	Day07() {weekday = -1/1;}
	Day07(int weekday) {
		this.weekday = weekday;
	}
	/* passando aqui
	   com o meu bloco */
}
```

E passou. Sem maiores modificações. Ufa!

> Na real eu já tinha feito os testes antes e corrigidos alguns dos detalhes do `case` default, haha!

### Leitura complexa: enumerações com construtores

Notou que o `simple_pushdown_automata` não define de modo duro quem são seus caracteres de abertura e fechamento?

Então, com isso conseguimos fazer mudanças para permitir invocar construtores. Basta identificar o `(` dada a leitura da
máquina de estados:

```bash
if [[ "$CARACTER" = [A-Za-z0-9_] ]]; then
	enum_lida+="$CARACTER"
else
	if [ -n "$enum_lida" ]; then
		echo "$enum_lida"
		enum_lida=''
	fi
	if [ "$CARACTER" = { ]; then
		simple_pushdown_automata { }
	elif [ "$CARACTER" = '(' ]; then
		simple_pushdown_automata '(' ')'
	elif [ "$CARACTER" = '}' ] || [ "$CARACTER" = ';' ]; then
		state=EOE
	fi
fi
```

Pronto, funcionou. Mas... ainda não acabamos. Temos mais marmotas a tratar.

### Leitura complexa: strings

Dentro de vísceras de classe e dentro dos argumentos passados pro construtor podemos ter strings. E você já imagina
qual o problema com strings, não é? Exatamente... Com strings vem alguém colocando um `}` no meio da string. Ou mesmo
`//`, mas se estiver no meio da string isso deve ser ignorado e está tudo bem.

E como lidamos com strings? Bem, pegamos uma aspa `"` e esperamos outra aspa `"` fechando. Só que existe o escape indicado pela
contrabarra `\`, ele vai escapar o caracter seguinte. Pode ser outro contrabarra `\\`, a própria aspa `\"`, ou qualquer outra coisa.
Basicamente, a string seria aceita pela regex `"([^"]|\\.)*"`, em que zero repetições do agrupamento `([^"\\]|\\.)` significa a string vazia
`""`.

De modo geral, podemos encontrar strings dentro dos blocos de construção e de subclasse. Logo, precisamos inserir a detecção de string
dentro do autômato de pilha; agora podemos chamar de `pushdown_automata_with_strings`. Basicamente, ao encontrar uma aspa, vamos entrar
na máquina de estados que lê string! Como é a máquina de estado da string? Basicamente, aspas, tudo menos aspas ou contrabarra **ou** contrabarra
e qualquer coisa, repete o elemento anterior, aspas.

```
início ==> `"` corpo
corpo ==> [^"\\] corpo
corpo ==> `\` escape
escape ==> . corpo
corpo ==> `"`
```

Então, nada mais justo do que detectar a string e mandar pro `leitura_string`, justo?

```bash

leitura_string() {
	local CARACTER
	local ASPAS="$1"

	while read -N1 CARACTER; do
		if [ "$CARACTER" = '\' ]; then
			read -N1 CARACTER
		elif [ "$CARACTER" = "$ASPAS" ]; then
			return
		fi
	done
}
```

E para o `case` dentro do `simple_pushdown_automata` precisei usar o seguinte padrão para fazer o _matching_:

```bash
case "$CARACTER" in
	# ...
	'"'|"'")
		leitura_string "$CARACTER"
		;;
	# ...
esac
```

Tudo bem, confere? O seguinte caso passa:

```java
// comentário de linha{

/* e o
  de bloco{ */
public enum Day08 {
	SUNDAY /* um bloco *no meio */, MONDAY, TUESDAY, WEDNESDAY,
	// quebrando a linha} */;
	THURSDAY, FRIDAY {
		/* coment bloco */
		// comment linha
		@Override
		public String toString() {return "SEXTOOOOU}!" + 1/1/1;}
	}, SATURDAY;

	// oops quebrando a linha
	private final int weekday;
	Day08() {weekday = -1/1;}
	Day08(int weekday) {
		this.weekday = weekday;
	}
	/* passando aqui
	   com o meu bloco */
}
```

Mas... não, não tá tudo bem... o seguinte caso de teste falhou:

```java
// comentário de linha{

/* e o
  de bloco{ */
public enum Day09 {
	SUNDAY /* um bloco *no meio */, MONDAY, TUESDAY, WEDNESDAY,
	// quebrando a linha} */;
	THURSDAY, FRIDAY {
		/* coment bloco */
		// comment linha
		@Override
		public String toString() {return "SEXTOOOO\"U}!" + 1/1/1;}
	}, SATURDAY;

	// oops quebrando a linha
	private final int weekday;
	Day09() {weekday = -1/1;}
	Day09(int weekday) {
		this.weekday = weekday;
	}
	/* passando aqui
	   com o meu bloco */
}
```

Mas, por que será que ele falhou? Vamos tentar buscar a leitura caracter a caracter de modo clássico. Aconteceu algo
dentro da string `SEXTOOOO\"U}!`. Vamos jogar isso no `while read -N1 CARACTER` e imprimir cada caracter lido:

```
$ echo 'SEXTOOOO\"U}!' | while read -N1 CARACTER; do echo "char lido >>>$CARACTER<<<"; done
char lido >>>S<<<
char lido >>>E<<<
char lido >>>X<<<
char lido >>>T<<<
char lido >>>O<<<
char lido >>>O<<<
char lido >>>O<<<
char lido >>>O<<<
char lido >>>"<<<
char lido >>>U<<<
char lido >>>}<<<
char lido >>>!<<<
char lido >>>
<<<
```

Hmmm, ele não leu o escape como esperado... Será que o `help read` tem algo a nos oferecer?

> ```
> $ help read
> [...]
>      -r        do not allow backslashes to escape any characters
> ```

Hmmm, um `-r` simples pode resolver... será que vai?

```
$ echo 'SEXTOOOO\"U}!' | while read -rN1 CARACTER; do echo "char lido >>>$CARACTER<<<"; done
char lido >>>S<<<
char lido >>>E<<<
char lido >>>X<<<
char lido >>>T<<<
char lido >>>O<<<
char lido >>>O<<<
char lido >>>O<<<
char lido >>>O<<<
char lido >>>\<<<
char lido >>>"<<<
char lido >>>U<<<
char lido >>>}<<<
char lido >>>!<<<
char lido >>>
<<<
```

É, foi. Ficamos assim no final:

```bash
leitura_string() {
	local CARACTER
	local ASPAS="$1"

	while read -rN1 CARACTER; do
		if [ "$CARACTER" = '\' ]; then
			read -N1 CARACTER
		elif [ "$CARACTER" = "$ASPAS" ]; then
			return
		fi
	done
}
```

Mas, aparentemente fiz uma complicação a mais, né? Se é só para detectar strings, o que o apóstrofo está fazendo no padrão
de casamento? E ainda mais passando o fechamento como parâmetro? Basicamente para poder detectar o caso em que mandamos um apóstrofo
de identificação de um `char`, como no caso abaixo:

```java
// comentário de linha{

/* e o
  de bloco{ */
public enum Day10 {
	SUNDAY /* um bloco *no meio */, MONDAY, TUESDAY, WEDNESDAY,
	// quebrando a linha} */;
	THURSDAY, FRIDAY {
		/* coment bloco */
		// comment linha
		@Override
		public String toString() {return "SEXTOOOO\"U}!" + 1/1/1 + '\'' + '}';}
	}, SATURDAY;

	// oops quebrando a linha
	private final int weekday;
	Day10() {weekday = -1/1;}
	Day10(int weekday) {
		this.weekday = weekday;
	}
	/* passando aqui
	   com o meu bloco */
}
```

## Ainda tem mais?

Sim, ainda tem mais. Mesmo dentro desse limite, do pressuposto de que o código analisado é Java válido e que
será o único _top-level element_ dentro do arquivo, ainda precisamos lidar com anotações. Anotações de métodos,
anotações da própria enumeração, enumeração de tipo caso implemente uma interface tipada. Mas isso fica
para outra conversa, outro momento.

Já conseguimos fazer a leitura de quase tudo.
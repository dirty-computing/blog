---
layout: post
title: "Escrevendo as funções booleanas do cálculo lambda, em Java"
author: "Jefferson Quesado"
tags: fp java
base-assets: "/assets/lambda-calc/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Vamos falar um pouquinho de cálculo lambda? Nada complicado, só o básico. E
depois vamos implementar um pouquinho em Java sobre as operações booleanas?

# Conceitos básicos

Basicamente, cálculo lambda trata de funções. Aqui, o foco vai ser tratar
funções para lidar com booleanos. Na verdade, as funções serão usadas para
codificar os booleanos!

Então, como definimos uma função? Basicamente, em torno de suas entradas. Por
uma questão de simplicidade, todas as funções vão estar curryadas: todas elas
passaram por currying.

## Tá, mas o que é currying?

Bora lá. Vamos pegar a função de soma, normalmente a gente representa ela como
sendo uma função binária:

```java
int soma(int a, int b) {
    return a + b;
}
```

E para chamar, eu faço isso:

```java
final var result = soma(19, 23);
```

Mas eu posso fazer o que se chama de "avaliação parcial" da função. Como assim?
Bem, eu posso resolver que vou somar com 19, e depois passar o valor. Algo
nesta linha:

```java
final var parcial = soma.betaReduction(19);
final var result = parcial.betaReduction(23);
```

E o resultado final em `result` precisa ser o mesmo: 42. Como eu consigo chegar
nisso? Usando funções que recebem um argumento apenas! Tá, o exemplo acima meio
que não funciona do jeito que está.

Para exemplificar isso, vou criar aqui uma função unária que pode retornar uma
função unária ou um resultado inteiro. E isso vai ser via `sealed interface`,
claro! Tenho um `Element` que pode ser um `Lambda` ou um `Result`, e aqui o 
`Lambda` pode ter uma `betaReduction` passando um inteiro como argumento que
transforma em outro `Element`. Quando se encontra o resultado, chegamos no fim
e nada mais pode ser feito. Pode ser assim? Bora então.

Como é uma função, bem aberto, primeiro vou definir a função "dobrar", e então
depois vou pra soma.

```java
public sealed interface Element {
    
    record Result(int r) implements Element {}

    non-sealed interface Lambda extends Element {
        Element betaReduction(int x);
    }
}

final Element.Lambda dobrar = a -> new Element.Result(2*a);
System.out.println(dobrar.betaReduction(13)); // Result[r=26]
```

Explicando aqui rapidinho:

- `Element` é uma interface selada, portanto todas as suas implementações são
  conhecidas por ela mesma
- `Result` e `Lambda` são as "implementações" conhecidas dela
- `Lambda` está anotada como `non-sealed` porque ela permite a existência de
  subimplementações dela

Nesse caso, eu posso fazer um pattern matching contra `Result` e `Lambda`, mas
não em cima das coisas de lambda. Por exemplo:

```java
static Element currying(Lambda func, int ...params) {
    Element el = func;
    for (int i: params) {
        switch (el) {
            case Lambda l -> el = l.betaReduction(i);
            case Result r -> {
                return r;
            }
        }
    }
    return el;
}
```

Muito bem! Vamos agora fazer o `soma`:

```java
public sealed interface Element {
    
    record Result(int r) implements Element {}

    non-sealed interface Lambda extends Element {
        Element betaReduction(int x);
    }
}

final Element.Lambda soma = a -> b -> new Element.Result(a + b);
System.out.println(soma.betaReduction(19));
```

Hmmm, não compila... Por quê?

> Lambda cannot implement a sealed interface

Mas que coisa! E se eu disser que a saída vai ser um lambda também?

```java
public sealed interface Element {
    
    record Result(int r) implements Element {}

    non-sealed interface Lambda extends Element {
        Element betaReduction(int x);
    }
}

final Element.Lambda soma = a -> (Element.Lambda) b -> new Element.Result(a + b);
System.out.println(soma.betaReduction(19)); // jeffque.Sample$$Lambda/0x00000008000d4840@954b04f
```

Ok, não dá pra ver a aplicação parcial, mas vamos continuar? Jogar o resultado
no `partial`:

```java
public sealed interface Element {
    
    record Result(int r) implements Element {}

    non-sealed interface Lambda extends Element {
        Element betaReduction(int x);
    }
}

final Element.Lambda soma = a -> (Element.Lambda) b -> new Element.Result(a + b);
final var partial = soma.betaReduction(19);
System.out.println(partial.betaReduction(23)); // não compila
```

Não deu certo! Puts, obtive uma função mas a priori devolvo um `Element`, não
um `Element.Lambda`. Vou precisar fazer um casting explícito:

```java
public sealed interface Element {
    
    record Result(int r) implements Element {}

    non-sealed interface Lambda extends Element {
        Element betaReduction(int x);
    }
}

final Element.Lambda soma = a -> (Element.Lambda) b -> new Element.Result(a + b);
final var partial = (Element.Lambda) soma.betaReduction(19);
System.out.println(partial.betaReduction(23)); // Result[r=42]
```

Ok, tem como a gente deixar isso mais palatável? Tem sim! Primeiro, podemos
dizer que um resultado pode até ser uma função, mas uma função que retorna ela
mesma de novo para qualquer novo parâmetro:

```java
public sealed interface Element {

    Element betaReduction(int x);

    record Result(int r) implements Element {

        @Override
        public Result betaReduction(int ignored) {
            return this;
        }
    }

    non-sealed interface Lambda extends Element {
        Element betaReduction(int x);
    }
}

final Element.Lambda soma = a -> (Element.Lambda) b -> new Element.Result(a + b);
final var partial = soma.betaReduction(19);
System.out.println(partial.betaReduction(23)); // Result[r=42]
```

Ok, isso já melhorou um cadinho. Mas ainda tem o `Element.Lambda` como cast
para o retorno da função... como resolver isso?

Bem, na real, dá. Mas para isso preciso me livrar da limitação do `sealed`.

```java
public interface Lambda {
    Lambda betaReduction(int x);
    
    record Result(int r) implements Lambda {

        @Override
        public Result betaReduction(int ignored) {
            return this;
        }
    }
}

final Lambda soma = a -> b -> new Lambda.Result(a + b);
final Lambda somaTripla = a -> b -> c -> new Lambda.Result(a + b + c);
```

E sabe o `currying` que foi dado como exemplo para o pattern matching da
interface selada? Pois bem, agora ele fica assim:

```java
static Lambda currying(Lambda func, int ...params) {
    Lambda el = func;
    for (int i: params) {
        el = el.betaReduction(i);
    }
    return el;
}
```

E graças a isso eu consigo deixar bem mais fácil a escrita de lambdas com
vários níveis.

E currying é, bem dizer, isso: transformar uma função N-ária em uma cadeia de
funções unárias. Como na `somaTripla: a -> b -> c -> resultado(a+b+c)`.

## Notação das funções

{% katexmm %}
Existem algumas maneiras de se anotar as funções do cálculo lambda. Sem entrar
em ambiente matemático, tem a notação de Haskell, que usa o `\` para
representar o que normalmente estaria em $\lambda$.

E como funciona a notação do lambda? Bem, vamos pegar a função soma e escrever
de modo MUITO aberto:

$$
\lambda x.\lambda y. x + y
$$

Isso está dizendo o seguinte:

- tenho uma função com um ponto aberto x $\lambda x.$
- o retorno ao se informar x é $\lambda y. x + y$
- esse retorno é uma função com um ponto aberto $\lambda y.$
- ao ser fornecido o y, o valor obtido é $x + y$

Uma função indica qual o seu ponto aberto através do $\lambda ID.$, onde aqui o
$\lambda$ são só marcações, o identificador é o nome do argumento, e o ponto é
um marcador de que depois dele vem o retorno.

## Números de Church

Existe todo um esquema de fazer números só com funções, que portanto não
seguiriam esse modelo de $\lambda x.\lambda y. x + y$ com esse operator de soma
explícito, mas de um jeito próprio. Assim como temos os números de Peano (que
já foram abordados em [outros]({% post_url 2024-09-02-peano-haskell %})
[posts]({% post_url 2025-03-10-peano-java-moderno %})), existem também os
números na notação de Church para numerais, ou números (numerais?) de Church.

Como funciona o pensamento atrás de um numeral de Church? Quantas vezes uma
função é aplicada sobre se mesma para um argumento. Assim, a função para o
número 0 não aplica a função sobre o argumento, logo:
$\lambda f. \lambda x. x$. Isso significa que a função que representa o número
zero não aplica uma função arbitrária sobre o argumento. Assim, temos que a
função que representa o 1 aplica a função uma vez sobre o argumento:
$\lambda f. \lambda x. f x$. A função para o 2? Aplica a função duas vezes,
portanto a função sobre o resultado da aplicação da função:
$\lambda f. \lambda x. f (f x)$.

Assim, será que conseguimos definir uma função de sucessor? Para que a partir
de um determinado número N eu obtenha o N+1? Vamos lá.

A função sucessor recebe um número como função. Portanto, o argumento é uma
função binária. E o resultado será uma função binária. Portanto, vamos pegar
que, para manter o desconhecimento sobre o mecanismo interno, o nosso argumento
seja $\lambda f. \lambda x. F$. Vamos ver como ficaria aplicar uma vez a mais a
função sobre o resultado?

$$
suc(\lambda f. \lambda x. F) = \lambda f. \lambda x. f F
$$

Ok, teste de sanidade: vamos ver a função de sucessão sobre 0, 1 e 2:

$$
suc(\lambda f. \lambda x. x) = \lambda f. \lambda x. f x\\
suc(\lambda f. \lambda x. f x) = \lambda f. \lambda x. f (f x)\\
suc(\lambda f. \lambda x. f (f x)) = \lambda f. \lambda x. f (f (f x))\\
$$

# Booleanos

Ok, vamos representar booleanos. Se padronizou (através do Church encoding de
booleanos) dizer que a função verdade é a função que retorna o primeiro
argumento, e a função falso é a que retorna o segundo argumento:

$$
TRUE = \lambda x. \lambda y. x\\
FALSE = \lambda x. \lambda y. y
$$

Assim sendo como seria o `AND`? E o `OR`? E o `NOT`? Vamos derivar todas as
operações booleanas básicas abaixo.


## AND

Basicamente, o `AND` é: se o primeiro argumento for verdade, retorna o segundo
argumento, caso contrário retorna falso. Ou a si mesmo (já que é falso), assim
não depende de definição externa:

$$
AND = \lambda x. \lambda y. x\ y\ x
$$

Vamos testar? Bem, X pode ser verdade, então nesse momento ele retorna o valor
da segunda variável. Ok, isso é razoável, já que o valor da expressão, dado que
X é verdadeiro, depende do valor da segunda variável. Então, se eu passar
`AND(TRUE, FALSE)` eu obtenho `FALSE`, e se eu passar `AND(TRUE, TRUE)` eu
obtenho `TRUE`. Em resumo, `AND(TRUE, y) = y`. Agora, para o caso de que X é
falso, não depende do valor de Y, será falso: `AND(FALSE, y) = FALSE`.

A única opção de retornar X é se X for FALSE. Eu convido o leitor a fazer os
testes de mesa passando os valores e fazendo as substituições, pode ajudar na
intuição.

## OR

Aqui, se o X for verdade, já garanto isso e não preciso nem olhar o segundo
argumento. Basicamente, o AND porém trocando a ordem dos parâmetros:

$$
OR = \lambda x. \lambda y. x\ x\ y
$$

## NOT

A função NOT vai inverter quem for verdade e quem for falso, tipo se receber
TRUE precisa retornar FALSE, e se receber FALSE precisa retornar TRUE. Isso
fornece a primeira implementação:

$$
NOT = \lambda x. x\ FALSE\ TRUE
$$

Se X for verdade, vai retornar o primeiro argumento, que é FALSE. Agota, se
for FALSE, vai retornar o segundo elemento que é TRUE. Mas, tem outra
implementação pra isso, bem divertida e que não necessita terceirizar para as
definições prévias.

Basicamente, a gente inverte o que recebe, né? Então, se eu receber um
`(A, B)`, eu posso dizer que o inverso é `(B, A)`. Logo, se eu tiver um TRUE e
eu reverter os argumentos dele, terei a negação:
`NOT(TRUE)(A, B) = TRUE(B, A) = B`. Porque aqui eu estou retornando o segundo
elemnto passado como parâmetro, e retornar o segundo elemento é o equivalente
ao FALSE. De modo semelhante: `NOT(FALSE)(A, B) = FALSE(B, A) = A`.

$$
NOT = \lambda p.\lambda x.\lambda y. p\ y\ x
$$

## NAND

No NAND, se a operação AND for TRUE, ele retorna FALSE. Caso contrário, retorna
TRUE. Isso implica que eu posso ter dois TRUE e retornar um FALSE: o retorno
está além da entrada. Vai ser _quase_ impossível desviar das definições,
precisarei citar tanto o TRUE quanto o FALSE literalmente. Ou isso ou fazer uma
função de 4 argumentos, tal qual a passagem do NOT para 3 argumentos para não
precisar citar diretamente TRUE e FALSE.

Agora e em diante, vou escolher praticidade.

Se o primeiro argumento for FALSE, eu sei que precisarei retornar verdade.
Logo, é algo assim:

$$
\lambda x. \lambda y. x\ ?\ TRUE
$$

Para saber qual seria o valor em `?`, vamos precisar do valor de Y. Se for
TRUE, então preciso avaliar tudo como FALSE. Caso contrário, avalio como TRUE.
Para não mencionar outra vez a constante, como já é sabido nesse caso que X é
TRUE, podemos retornar X. Logo, a expressão completa é:

$$
\lambda x. \lambda y. x\ (y\ FALSE\ x)\ TRUE
$$

## NOR

Linha de raciocínio semelhante ao NAND. Comecemos com o caso em que X é TRUE,
já devemos retornar FALSE:

$$
NOR = \lambda x. \lambda y. x\ FALSE\ ?
$$

Na `?`: se Y for TRUE, precisamos retornar FALSE. Logo, como para chegar na `?`
precisamos que X seja FALSE, podemos retornar X. Caso Y seja FALSE, retornemos
TRUE:

$$
NOR = \lambda x. \lambda y. x\ FALSE\ (y\ x\ TRUE)
$$

## XOR

Aqui o resultado é TRUE se e somente se eu tiver valores distintos. Se for o
mesmo valor, retorno FALSE. Então em ambos os casos para o valor de X terei
funções de Y, mas aqui são funções distintas.

Prendendo aqui para X como TRUE: Caso os dois sejam verdades, preciso retornar
FALSE, caso contrário (aqui o Y sendo FALSE), retorno TRUE. Logo, a primera
parte é $y\ FALSE\ TRUE$. Como o valor de X é sabido ser TRUE, podemos trocar
para $y\ FALSE\ x$.

Agora, para o caso em que X é FALSE. Aqui quem vai definir é apenas Y, pois se
repetir o valor, ambos FALSE o retorno é FALSE. E se trocar, vai ser TRUE.
Logo, a segunda função é $y$.

Juntando tudo:

$$
XOR = \lambda x. \lambda y. x\ (y\ FALSE\ x)\ y
$$

## XNOR (ou EQUIV)

Agora preciso retornar TRUE se ambos forem o mesmo valor, ou FALSE caso tenham
valores trocados. Esse é a operação de equivalência, que é igual a negação do
XOR. A negação do XOR normalemnte denominam como XNOR.

Dado X fixado como TRUE, o retorno vai ser o valor de Y. Mesmo raciocínio da
segunda perna do XOR.

Dado X fixado como FALSE, o retorno vai depende de Y ser FALSE também. Logo, se
Y for TRUE, precisa retornar FALSE. Como sabemos que X é FALSE, podemos
escrever como $y\ x\ TRUE$.

Juntando tudo:

$$
XNOR = \lambda x. \lambda y. x\ y\ (y\ x\ TRUE)
$$


## IMPLY

Finalmente, a operação de implicar. $A \Rightarrow B$. Basicamente a única
situação em que eu retorno FALSE é se X for TRUE e Y for FALSE.

$$
IMPLY = \lambda x. \lambda y. x\ y\ TRUE
$$

Convido aqui o leitor a substituir os valores de X e de Y para realizar teste
de mesa para validar o que foi obtido aqui.

{% endkatexmm %}

# Vamos fazer em Java?

Vamos começar definindo nossa interface. Temos um elemento, podendo estar
aplicado parcialmente ou não, seus valores são `TRUE` e `FALSE`, e todos tem
uma coisa em comum: se aplicados em si mesmos, retorna um de seu próprio tipo
também.

Algo como:

```java
public interface BoolFunc {
    default boolean hasValue() {
        return false;
    }

    BoolFunc apply(BoolFunc a);

    final class TrueFunc implements BoolFunc {

        @Override
        public boolean hasValue() {
            return true;
        }

        @Override
        public BoolFunc apply(BoolFunc a) {
            return b -> a;
        }

        @Override
        public String toString() {
            return "TRUE";
        }

        @Override
        public boolean equals(Object obj) {
            return obj instanceof TrueFunc;
        }

        @Override
        public int hashCode() {
            return 1;
        }
    }

    final class FalseFunc implements BoolFunc {

        @Override
        public boolean hasValue() {
            return true;
        }

        @Override
        public BoolFunc apply(BoolFunc a) {
            return b -> b;
        }

        @Override
        public String toString() {
            return "FALSE";
        }

        @Override
        public boolean equals(Object obj) {
            return obj instanceof FalseFunc;
        }

        @Override
        public int hashCode() {
            return 0;
        }
    }

    BoolFunc TRUE = new TrueFunc();
    BoolFunc FALSE = new FalseFunc();
}

```

Aqui, o que nós temos?

- o tipo `BoolFunc`, que se aplica para um `BoolFunc` e retorna um `BoolFunc`
- uma indicação de que aquilo é parcial/tem um valor definido
- os tipos `TRUE` e `FALSE`, prontamente aplicáveis como sendo um `BoolFunc`
- para os tipos `TRUE` e `FALSE` já definidos, eles indicam isso, tem uma
  representação usual como string e, também, tem resolvido a questão de
  igualdade de objeto Java (tanto `equals` quanto `hashCode`)

Vamos testar? Primeiro, vamos ver se `TRUE` e `FALSE` são facilmente
identificáveis. Podemos fazer isso via `sout`:

```java
System.out.println(TRUE);
System.out.println(FALSE);
```

E a saída é como esperado:

```txt
TRUE
FALSE
```

Ok, não fizemos nenhuma besteira aqui. Agora, será que `TRUE` e `FALSE` estão
mesmo seguindo a descrição? Bem, para isso criei dois objetos só com esse fim:
`testOk` e `testFail`. E para criar eles usei um truque:

```java
static BoolFunc namedPartial(String name, BoolFunc partial) {
    return new BoolFunc() {
        @Override
        public BoolFunc apply(BoolFunc a) {
            return partial.apply(a);
        }

        @Override
        public String toString() {
            return name;
        }
    };
}

final var testOk = namedPartial("deu certo", a -> a);
final var testFail = namedPartial("falhou", a -> a);
```

O valor em si do que eles carregam não me importam, mas os seus nomes importam
e importam bastante. Para verificar se deu certo o teste é bem fácil: chamar
`TRUE` e `FALSE` com os argumentos montados de tal forma que, se implementado
corretamente, retorna "deu certo" e, se montou errado, retorna "deu falha". E
eis a montagem do teste:

```java
System.out.println(TRUE.apply(testOk).apply(testFail));
System.out.println(FALSE.apply(testFail).apply(testOk));
```

E o resultado deu conforme esperado:

```txt
deu certo
deu certo
```

Ok, agora que temos isso, vamos implementar o `NOT`? Foram fornecidas duas
implementações, então vou testar ambas.

A primeira implementação é, dado um elemento, ele aplica `FALSE` e depois
`TRUE`. Se o elemento inicial for `TRUE` ele retorna o primeiro argumento, e se
for `FALSE` ele retorna o segundo argumento. Eu poderia testar apenas
diretamente o valor, mas como isso não se aplica à segunda implementação,
resolvi fazer algo diferente... usar o `testOk` e `testFail` anteriormente já
usados:

```java
// poderia nesse caso ser apenas
// System.out.println(NOT1.apply(FALSE));
// mas quis usar algo que pudesse aplicar pra NOT2 também
BoolFunc NOT1 = x -> x.apply(FALSE).apply(TRUE);

System.out.println(NOT1.apply(FALSE).apply(testOk).apply(testFail));
System.out.println(NOT1.apply(TRUE).apply(testFail).apply(testOk));
```

E para a segunda implementação? Bem, essa pega uma função ternária e retorna um
valor:

```java
BoolFunc NOT2 = x -> a -> b -> x.apply(b).apply(a);

System.out.println(NOT2.apply(FALSE).apply(testOk).apply(testFail));
System.out.println(NOT2.apply(TRUE).apply(testFail).apply(testOk));
```

Tá, e se eu tivesse feito o teste só com `NOT2.apply(TRUE)`? Bem, nesse caso
teríamos obtido algo nesse rumo no `sout`:

```txt
BoolFunc$$Lambda/0x00000008000c4000@68be2bc2
BoolFunc$$Lambda/0x00000008000c4000@28feb3fa
```

## Lidando com funções binárias

Avançamos bastante com o `NOT`. E agora vamos para as funções binárias. Como
podemos fazer isso? Bem, vamos buscar elas de modo exaustivo, pode ser?

Então, para todas as funções, irei testar para todas as combinações. Por
exemplo:

```java
final var VALUES = List.of(TRUE, FALSE);
for (final var v1: VALUES) {
    for (final var v2: VALUES) {
        System.out.printf("v1: [%s], v2: [%s]; AND: [%s]\n", v1, v2, AND.apply(v1).apply(v2));
        
    }
}
System.out.println();
```

Isso passa pelas coisas de modo exaustivo e funciona bem para uma função.
Mas... se for passar para todas, não fica legal.

Então que tal usar o `namedPartial` definido anteriormente? Assim, posso
simplesmente passar pelas funções e imprimir o nome delas! Por exemplo:

```java
final var f = namedPartial("AND", a -> a);
final var VALUES = List.of(TRUE, FALSE);
for (final var v1: VALUES) {
    for (final var v2: VALUES) {
        System.out.printf("v1: [%s], v2: [%s]; %s: [%s]\n", v1, v2, f, f.apply(v1).apply(v2));
        
    }
}
System.out.println();
```

Pois bem, isso nos permite testar a função e ver o que estamos testando.

Agora, vamos ver as funções? Vamos ver para `AND` e `OR`:

```java
BoolFunc AND = namedPartial("AND", b -> a.apply(b).apply(a));
BoolFunc OR = namedPartial("OR", a -> b -> a.apply(a).apply(b));

final var binaryFunctions = List.of(AND, OR);

final var VALUES = List.of(TRUE, FALSE);
for (final var f: binaryFunctions) {
    for (final var v1 : VALUES) {
        for (final var v2 : VALUES) {
            System.out.printf("v1: [%s], v2: [%s]; %s: [%s]\n", v1, v2, f, f.apply(v1).apply(v2));

        }
    }
    System.out.println();
}
```

Foi impresso:

```txt
v1: [TRUE], v2: [TRUE]; AND: [TRUE]
v1: [TRUE], v2: [FALSE]; AND: [FALSE]
v1: [FALSE], v2: [TRUE]; AND: [FALSE]
v1: [FALSE], v2: [FALSE]; AND: [FALSE]

v1: [TRUE], v2: [TRUE]; OR: [TRUE]
v1: [TRUE], v2: [FALSE]; OR: [TRUE]
v1: [FALSE], v2: [TRUE]; OR: [TRUE]
v1: [FALSE], v2: [FALSE]; OR: [FALSE]
```

Tudo indo conforme esperado.

Agora, vamos ver as outras implementações faltosas? Para cada uma das funções,
irei descrevê-las abaixo e irei colocá-las no `binaryFunctions` acima para os
testes.

```java
BoolFunc NAND = namedPartial("NAND", a -> b -> a.apply(b.apply(FALSE).apply(a)).apply(TRUE));
BoolFunc NOR = namedPartial("NOR", a -> b -> a.apply(FALSE).apply(b.apply(a).apply(TRUE)));
BoolFunc XOR = namedPartial("XOR", a -> b -> a.apply(b.apply(FALSE).apply(a)).apply(b))
BoolFunc XNOR = namedPartial("XNOR", a -> b -> a.apply(b).apply(b.apply(a).apply(TRUE)));
BoolFunc IMPLY = namedPartial("IMPLY", a -> b -> a.apply(b).apply(TRUE));
```

Note que, ao aplicar a função binária, fazemos algo como:

```java
a.apply(b).apply(c);
```

Se queremos aplicar como segundo parâmetro algo como no XNOR `y x TRUE`,
precisamos colocar isso como a segunda computação. Isso seria, para os
parâmetros `a` e `b`:

```java
b.apply(a).apply(TRUE);
```

Portanto, a computação completa do XNOR é:

```java
a.apply(b).apply(  b.apply(a).apply(TRUE)  );
```

# Considerações finais

Note que isso não é o cálculo lambda irrestrito. As funções aqui descritas não
são capazes de pegar qualquer elemento e operar neles de modo opaco, só
funcionam corretamente para tipos "booleanish".

As operações também não funcionam do modo mais intuitivo possível. No cálculo
lambda, basta colocar os argumentos e colocar os parênteses ao redor. Aqui
precisa fazer o `.apply` para cada argumento, e controlar para não errar
algumas coisas, como no XNOR eu errei:

```java
// errado
BoolFunc XNORERR = namedPartial("XNORERR", a -> b -> a.apply(b).apply(b.apply(a)).apply(TRUE));
// certo
BoolFunc XNOR = namedPartial("XNOR", a -> b -> a.apply(b).apply(b.apply(a).apply(TRUE)));
```

Note que a versão errado não imprimia a coisa correta, mas sim uma referência
lambda:

```txt
v1: [TRUE], v2: [TRUE]; XNORERR: [BoolFunc$TrueFunc$$Lambda/0x00000008000c2400@1e88b3c]
v1: [TRUE], v2: [FALSE]; XNORERR: [BoolFunc$FalseFunc$$Lambda/0x00000008000c4000@42d80b78]
v1: [FALSE], v2: [TRUE]; XNORERR: [FALSE]
v1: [FALSE], v2: [FALSE]; XNORERR: [TRUE]
```

E ele seria o equivalente ao seguinte no cálculo lambda:

{% katexmm %}
$$
\lambda x. \lambda y. x\ y\ (y\ x)\ TRUE
$$

Enquanto que o correto seria

$$
\lambda x. \lambda y. x\ y\ (y\ x\ TRUE)
$$
{% endkatexmm %}
---
layout: post
title: "O conjunto que contém todos os conjuntos que se contém contém a si? Ou como side effects são infernais"
author: "Jefferson Quesado"
tags: c java language-design
base-assets: "/assets/side-effect-hell/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Se eu tiver um conjunto, que contém a todos os conjuntos que contém a si
mesmos, ele deveria conter a si mesmo?

Bem, podemos tentar explorar isso de algumas formas, como por exemplo tentar
encontrar alguma contradição ao tentar construir esse conjunto. Vamos dizer que
ele não poderia estar dentro de si, então vamos supor que ele está dentro de si
mesmo e torcer para encontrar uma contradição...

{% katexmm %}

Então, bora lá...

$$
C \in C
$$

Dado isso, obtemos alguma contradição? Hmmm, não. O conjunto tá dentro dele,
então tudo se comporta de modo esperado. Portanto, o correto seria que o
conjunto não se contivesse, não é mesmo?

$$
C \not\in C
$$

Bem, se ele não se contém, não tenho nenhuma contradição também...

{% endkatexmm %}

Ou seja, eu não consigo encontrar uma contradição e de toda sorte eu
conseguiria construir esse conjunto, tanto contendo a si mesmo como não
contendo a si mesmo.

Estranho, né?

# Familiar?

Note que aqui não estou lidando com o paradoxo clássico de Russell, mas o
complemento dele. O paradoxo de Russell é descrito de outra maneira:

O conjunto com todos os conjuntos que não contém a si mesmos, deveria se estar
dentro dele mesmo?

{% katexmm %}
$$
C = \left\{ x | x \not\in x \right\}
$$

Já esse que eu introduzi é determinado sem essa negação:

$$
C = \left\{ x | x \in x \right\}
$$
{% endkatexmm %}

Enquanto o paradoxo de Russell é por definição uma contradição, o que foi
descrito acima na real é uma indefinição.

# E o que isso tem a ver com programação?

Bem, vamos lá. Imagina o seguinte pseudo-código:

```js
let a = 0;

function b() {
    global a;
    a += 100;
    return 0;
}

a += b();
console.log(a);
```

Qual o valor que `a` vai assumir? Pois aqui temos o problema, os efeitos
colaterais de `a` fazem parte da `a` sendo somado?

## Stack machines

Vamos pegar um exemplo em Java:

```java
int a = 0;

int b() {
    a += 100000;
    return 0;
}

void main(String[] args) {
    a += b();
    IO.println(a);
}
```

Isso imprime `0`. "Mas por quê?" você pode estar se perguntando. Bem, vamos ver
como que o Java resolveu os bytecodes:

```jvm
  void main(java.lang.String[]);
         0: aload_0
         1: dup
         2: getfield      #7                  // Field a:I
         5: aload_0
         6: invokevirtual #14                 // Method b:()I
         9: iadd
        10: putfield      #7                  // Field a:I
        13: aload_0
        14: getfield      #7                  // Field a:I
        17: invokestatic  #18                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        20: invokestatic  #24                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        23: return
```

A operação `a += ...` é realizada da seguinte maneira:

- `aload_0` carrega o objeto `this`
- `dup` agora tem esse objeto duas vezes na pilha
- `getfield` carrega o campo `a` (remove uma das cópias do `this` da pilha)
- alguma coisa pra calcular o lado direito (RHS, right hand side)
- `iadd`, somando os dois elementos da pilha (o `a` carregado anteriormente e o
  resultado do RHS)
- `putfield` que vai inserir o elemento da pilha no lugar de `a` (consumindo o
  `this` que foi duplicado na segunda operação)

Tá, talvez aqui tenhamos alguma quirk porque estou usando classe anônima e
`instance main`. E se fosse tudo `static`?

```java
class Example {
    static int a = 0;

    static int b() {
        a += 100000;
        return 0;
    }

    public static void main(String[] args) {
        a += b();
        IO.println(a);
    }
}
```

O bytecode gerado foi esse:

```jvm
 public static void main(java.lang.String[]);
         0: getstatic     #7                  // Field a:I
         3: invokestatic  #14                 // Method b:()I
         6: iadd
         7: putstatic     #7                  // Field a:I
        10: getstatic     #7                  // Field a:I
        13: invokestatic  #18                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        16: invokestatic  #24                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        19: return
```

A parte do `a += ...` é basicamente a mesma coisa, mas usando
`getstatic`/`putstatic` no lugar de referência ao objeto `this`:

- `getstatic` pega o valor de `a`
- resolve o RHS
- `iadd` soma os valores da pilha (o valor antigo de `a` e o RHS)
- `putstatic` insere o valor calculado no `iadd` de volta na variável `a`

Então, aqui, o valor de `a` que vai ser somado, inclui os efeitos colaterais?
Não. Mas isso aqui tem um comportamento diferente:

```java
int a = 0;

int b() {
    a += 100000;
    return 0;
}

void main(String[] args) {
    a = b() + a;
    IO.println(a);
}
```

Que gera o bytecode

```jvm
         0: aload_0
         1: aload_0
         2: invokevirtual #14                 // Method b:()I
         5: aload_0
         6: getfield      #7                  // Field a:I
         9: iadd
        10: putfield      #7                  // Field a:I
        13: aload_0
        14: getfield      #7                  // Field a:I
        17: invokestatic  #18                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        20: invokestatic  #24                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        23: return
```

Note que agora primeiro se calcula `b()` e só depois se carrega o valor de `a`.
Além disso, a ordem dos operandos foi alterada, porque agora o `a` tá do lado
direito da soma, não do lado esquerdo. Isso não deveria gerar nenhum problema
com nenhum tipo de número, mas vale a pena ficar atento, né?

Outra coisa que tem valor distinto:

```java
int a = 0;

int b() {
    a += 100000;
    return 0;
}

void main(String[] args) {
    final var r = b();
    a += r;
    IO.println(a);
}
```

Com o bytecode

```jvm
         0: aload_0
         1: invokevirtual #14                 // Method b:()I
         4: istore_2
         5: aload_0
         6: dup
         7: getfield      #7                  // Field a:I
        10: iload_2
        11: iadd
        12: putfield      #7                  // Field a:I
```

Aqui o valor de `b()` é armazenado na stack (`istore_2`) e depois é resgatado
para ser computado (`iload_2`). Isso garante que o que foi computado em `b()`
tenha ocorrido antes de carregar o valor de `a` para fazer a soma.

Aqui, na interpretação do Java (e não só do Java, mas de diversas linguagens),
o conjunto que contém as mudanças realizadas na variável não contém os efeitos
colaterais após a descrição do operador `+=`. Alguns ambientes em que isso foi
reproduzido:

- CommonJS (Spider Monkey)
- Node.JS (v8)

```js
let a = 0
 
function b() {
 a += 100
 return 0
}
 
a += b() // vale 0
```

- Python 3

```py
a = 0
def b():
    global a
    a += 100
    return 0

a += b() # vale 0
```

- Ruby

```ruby
$a = 0
def b()
  $a += 100
  0
end
$a += b() # vale 0
```

## Register machines

Vamos tentar reescrever a essência do código problemático em... C?

```c
// só para poder imprimir o valor mesmo
#include<stdio.h>

static int a = 0;

static int b() {
    a += 100;
    return 0;
}

int main(int argc, char **argv) {
    a += b();
    printf("%d\n", a);
    return 0;
}
```

Vamos gerar o ASM disso em ARM (similar a o que foi feito em
[Otimização de função de cauda em uma toy function]({% post_url 2025/2025-08-07-c-tail-call-opt %}))
para ter uma pequena base de comparação:

```asm
b:
        push    {r11, lr}
        mov     r11, sp
        ldr     r1, .LCPI0_0
.LPC0_0:
        add     r1, pc, r1
        ldr     r0, .LCPI0_1
.LPC0_1:
        ldr     r0, [pc, r0]
        add     r0, r0, #100
        str     r0, [r1]
        mov     r0, #0
        pop     {r11, lr}
        bx      lr
.LCPI0_0:
        .long   a-(.LPC0_0+8)
.LCPI0_1:
        .long   a-(.LPC0_1+8)

main:
        push    {r11, lr}
        mov     r11, sp
        sub     sp, sp, #16
        mov     r2, #0
        str     r2, [sp]
        str     r2, [r11, #-4]
        str     r0, [sp, #8]
        str     r1, [sp, #4]
        bl      b
        mov     r2, r0
        ldr     r1, .LCPI1_0
.LPC1_0:
        add     r1, pc, r1
        ldr     r0, .LCPI1_1
.LPC1_1:
        ldr     r0, [pc, r0]
        add     r0, r0, r2
        str     r0, [r1]
        ldr     r1, .LCPI1_2
.LPC1_2:
        ldr     r1, [pc, r1]
        ldr     r0, .LCPI1_3
.LPC1_3:
        add     r0, pc, r0
        bl      printf
        ldr     r0, [sp]
        mov     sp, r11
        pop     {r11, lr}
        bx      lr
.LCPI1_0:
        .long   a-(.LPC1_0+8)
.LCPI1_1:
        .long   a-(.LPC1_1+8)
.LCPI1_2:
        .long   a-(.LPC1_2+8)
.LCPI1_3:
        .long   .L.str-(.LPC1_3+8)

.L.str:
        .asciz  "%d\n"
```

E aqui o valor impresso é 100, não 0! Mas, por quê?

Primeiramente, gostaria de dizer que estou usando CLang 22.1.0 com target para
armv7-a 32bits  pelo Compiler Explorer! Recomendo testar a ferramenta, é
fantástica: [https://godbolt.org/](https://godbolt.org/).

> Ah, o nome do cara é Godbolt mesmo, vide
> [GitHub @mattgodbolt](https://github.com/mattgodbolt).

Bem, vejamos aqui o que acontece na parte exata `a += b()`:

```asm
        bl      b
        mov     r2, r0
        ldr     r1, .LCPI1_0
.LPC1_0:
        add     r1, pc, r1
        ldr     r0, .LCPI1_1
.LPC1_1:
        ldr     r0, [pc, r0]
        add     r0, r0, r2
        str     r0, [r1]
```

Aqui:

- chama a função `b`
- guarda em `r2` o que está em `r0`
- resgata em `r0` o valor de `a`
- soma `r0` com `r2` e guarda o resultado em `r0`
- guarda `r0` na memória no exato lugar de `a`

> O `r1` ali em cima guarda o endereço da variável `a`, por isso que guardar o
> valor é `str r0, [r1]`, envolvendo o `r1`.

Tá, mas onde tá o retorno da chamada a `b()`? Bem, por convenção, está em `r0`.
E é exatamente por isso que o compilador colocou `mov r2, r0`, assim guardando
o valor do retorno para posterior análise.

## Voltando para a indefinição

Ao fazer uma computação do sentido `a += RHS`, precisamos somar com `a` o que
está no lado direito. Agora, em relação a essa linha, quem é `a` de modo exato?
Podemos dizer aqui que o valor de `a` é tudo aquilo que aconteceu que afetou o
valor de `a`?

Se isso for verdade, o que acontece quando há uma auto-referência? Nesse caso a
auto-referência é o RHS sendo uma função que tem efeitos colaterais em `a`.
Aqui nesse caso temos exatamente o complemento da indefinição de Russell: ambas
as respostas são satisfatórias!

No caso da linguagem Java, devido a questões de filosofia de reprodutibilidade
e outras coisas mais, foi dito que o valor de `a` a ser carregado não iria
levar em consideração o que viria no RHS. Portanto, o conjunto com todas as
operações em `a` que antecedem a soma não inclui o RHS da função.

Para Java em específico, no Java 25, temos aqui a especificação da linguagem na
[seção 15.26.2](https://docs.oracle.com/javase/specs/jls/se25/html/jls-15.html#jls-15.26.2),
sobre operação de atribuição composta. Em primeiro lugar, se resolve o lado
esquerdo, mantendo na pilha, para depois se analisar o lado direito. Após obter
os dois valores, se aplica a soma e só depois que se pode guardar o valor.

Isso permite fazer isso na pilha:

```jvm
0: getstatic     #7                  // Field a:I
3: invokestatic  #14                 // Method b:()I
6: iadd
7: putstatic     #7                  // Field a:I
```

Agora, como seria a manipulação da pilha se isso não fosse verdade? Bem, aqui a
situação seria bem... não convencional... Porque, se eu quiser avaliar a função
primeiro, onde que eu a guardo? Se eu fizer isso:

```jvm
invokestatic  #14                 // Method b:()I
getstatic     #7                  // Field a:I
iadd
putstatic     #7                  // Field a:I
```

Aqui eu faço com que o retorno de `b()` esteja no lado esquerdo da soma, o que
não queremos. E se eu fizesse um `swap`?

```jvm
invokestatic  #14                 // Method b:()I
getstatic     #7                  // Field a:I
swap
iadd
putstatic     #7                  // Field a:I
```

Bem, aqui eu mantive a ordem dos elementos na hora da soma. Outras soluções
para esse problema existem, mas envolvem escrita na memória, não só a questão
de manipulação de coisas de um lado pro outro.

# O que é o operador de atribuição composto?

Bem, vamos pensar aqui, como questão de design de linguagem: o que é essa
atribuição composta do `+=`? Eu posso dizer que ela é sempre igual a
`a = a + b`?

Bem, vamos lá. A operação `+=` quer dizer "somar ao valor da esquerda o que é
computado do lado direito". Para saber o "valor da esquerda", precisamos traçar
tudo aquilo que aconteceu até aquele momento. Aqui vem a questão: vamos
resolver isso de modo _eager_ (buscar primeiro o valor) ou de modo _lazy_
(deixar para buscar no derradeiro momento)?

Bem, isso acaba por ser uma _decisão_ de design. No caso de implementações em
C, pelo que me lembro ou é _unspecified behaviour_ ou é _undefined behaviour_,
(o clássico UB). Inclusive, devido a essa questão, a ordem de resolução de
valores pode gerar como efeito que essas duas expressões, que deveriam
significar a mesma coisa, tenham comportamentos distintos:

- `a += b()`
- `a = a + b()`

Isso porque: com `a + b()`, se eu primeiro resolver o lado esquerdo, o valor de
`a` ainda não terá tido o efeito colateral da chamada `b()`. Se o compilador
resolver que é melhor em uma situação resolver primeiro o lado esquerdo e
depois o direito, e em outra situação fazer o contrário, ainda está tudo bem de
acordo com os padrões da linguagem.

Outro ponto interessante para se levar em consideração é esse excerto, retirado
da Wikipedia em inglês no artigo sobre
[_unspecified behaviour_](https://en.wikipedia.org/wiki/Unspecified_behavior):

```c
a = f(b) + g(b);
```

O valor de `a` vai depender de como `b` vai ser resolvido. Por exemplo, se por
um acaso o compilador vai pegar uma cópia de `b`, enviar para a função `f` e
mandar computar `g` com outra cópia de `b` já resgatada, ele vai obter um
comportamento. Agora, se por acaso ele pegar `b`, enviar para `f`, e só depois
que `f` retornar ele pegar uma cópia de `b` para mandar para `g`, aqui podemos
ter um problema: qual o valor de `b`? Porque agora podemos ter que `f` gere um
efeito colateral em `b`. E a mesma coisa para resolver primeiro `g(b)` e depois
resolver `f(b)`: se `g` gerar efeito colateral em `b`, então o valor da chamada
de `f` será distinto.

E tudo isso só acontece por conta de uma coisa que essas linguagens permitem:
mutação dos dados. Agora, não estou falando em simplesmente _shallow mutation_,
mas sim de _deep mutation_. Situações semelhantes poderiam acontecer se o valor
de `b` não fosse alterado diretamente, mas qualquer valor que eu chegue por
intermédio de `b`. Por exemplo, se eu tiver um objeto em Java que chamar a
função cause alterações em seus campos mais internos, encadear essas chamadas
tem um potencial caso de confusão. Em C, eu posso pegar exemplos semelhantes
onde `b` é um ponteiro para um valor complexo, então alterações no que é
apontado por `b` também gerar problemas semelhantes.

No fundo, para saber o valor de uma variável em determinado momento, você
precisa fazer uma operação de conjunto, de pegar todas as operações que mexem
naquele valor. Então, se eu preciso pegar todas as operações que alteram o
valor da variável, em operações que dependem do valor da variável e que ao
mesmo tempo alteram seu valor, essas operações estão dentro ou fora do
conjunto?

# Como resolver isso?

Uma alternativa para resolver isso é ser caxias tal qual o Java fez, e que
acredito que a maioria das linguagens segue: canonizar um tipo de resposta.
Agora, sabe uma solução ainda mais elegante do que isso? E é bem simples:
evitar efeitos colaterais.

Toda essa discussão só se deu por conta de que o valor referenciado é alterado
no meio da execução. Se não tivesse efeito colateral, essa discussão toda não
estaria ocorrendo.

Esse é o preço que um sistema computacional que permite _side effects_ oferece.
Você vai precisar escolher se o conjunto que contém a todos os conjuntos contém
a si mesmo ou não.

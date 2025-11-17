---
layout: post
title: "O incrível caso do uso de objeto parcialmente carregado"
author: "Jefferson Quesado"
tags: java language-design
base-assets: "/assets/java-final-unstable/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Eu ganho minha vida usando Java, mas isso não significa que essa linguagem e a
cultura criada ao redor dela é livre de qualquer crítica. Inclusive sou muito
crítico ao Javismo cultural, mas aqui é um ponto sobre algo que eu considero
uma... falha... da linguagem. E o pior: eu não vejo situação em que isso possa
ser corrigido no caso do Java!

# O problema do final

Qual a expectativa quando se usa `final`? Basicamente que ele tenha apenas uma
única leitura daquela variável! Sempre! Mas existe sempre aquela situação em
que alcançamos paradoxos. E obviamente aqui estamos lidando com paradoxos de
auto-referenciamento.

Mas não é simples que você caia nos problemas de auto-referenciamento!

Por exemplo, o seguinte código é inválido:

```java
class X {
	private static final int a = b;
	private static final int b = 0;

	static {
		IO.println(a);
		IO.println(b);
	}

	public static void main(String... args) {
	}
}
```

Aqui podemos garantir que os valores que deveriam ser impressos são 0 e 0. Não
há paradoxo, não há ambiguidade. `b` é definido por si, `a` é definido em
termos de `b`. Mas o Java não permite isso:

```bash
$ java a.java  
a.java:2: error: illegal forward reference
	private static final int a = b;
	                             ^
1 error
error: compilation failed
```

Isso porque o Java não permite que você mencione um campo à frente na
inicialização in-line de um campo. Para usar o campo `b`, eu só posso usar após
a declaração dele. Mas isso não vale para métodos! Eu simplesmente posso
referenciar um método qualquer!

E sabe o que eu posso fazer dentro de métodos? Referenciar qualquer campo!

Então isso aqui é um código válido:

```java
class X {
	private static final int a = b();
	private static final int b = 0;

	static {
		IO.println(a);
		IO.println(b);
	}

	public static int b() {
		return b;
	}

	public static void main(String... args) {
	}
}
```

E o resultado é que ele imprime os valores 0 e 0 sem nenhum segredo. Vamos
deixar as coisas mais interessantes? Vamos iniciar `b` com 3 e o valor de `a`
será `b + 1`:

```java
class X {
	private static final int a = b() + 1;
	private static final int b = 3;

	static {
		IO.println(a);
		IO.println(b);
	}

	public static int b() {
		return b;
	}

	public static void main(String... args) {
	}
}
```

E ele imprime, como esperado:

```none
4
3
```

Isso significa que os valores de `a` e de `b` são conhecidos e estáveis, não é?
NÃO É!!?!?!?!

Bem, podemos testar isso... vamos botar para imprimir os valores de `a` e de
`b` no método `b()`, e també, na `main`:

```java
class X {
	private static final int a = b() + 1;
	private static final int b = 3;

	static {
		IO.println(a);
		IO.println(b);
	}

	public static int b() {
		IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted("b", a, b));
		return b;
	}

	public static void main(String... args) {
		IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted("main", a, b));
	}
}
```

E isso é impresso:

```none
valor de (a,b) aqui na função `b`: (0,3)
4
3
valor de (a,b) aqui na função `main`: (4,3)
```

Hmmm, o valor de `a` não está pré-computado ao chamar a função `b`. Isso
significa que, ao ler a variável `a`, obtivemos um valor em um canto e outro
valor em outros cantos!

Lembra do começa da seção, qual a expectativa do `final`? Basicamente que toda
leitura dele retornaria o mesmo valor! Mas aqui temos 2 leituras distintas com
2 valores distintos! E é esse o problema do `final`!

## Como o Java se comportou de fato?

Vamos fazer outro experimento? Vamos mudar o valor de `b`, adicionando `0`
nele. Mas não qualquer 0, um zero determinado dinamicamente, com valores que
dependem de `a` e de `b`. "Ah, mas se depende de `a` e de `b` como que pode ser
zero?" Basicamente enganando o compilador fazendo uma conta complicada para
fazer `x-x`, que para qualquer inteiro é 0:

```java
class X {
	private static final int a = b() + 1;
	private static final int b = c() + 3;

	static {
		IO.println(a);
		IO.println(b);
	}

	public static int c() {
		IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted("c", a, b));
		if (b > 0) {
			return b - b;
		}
		return a - a;
	}

	public static int b() {
		IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted("b", a, b));
		return b;
	}

	public static void main(String... args) {
		IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted("main", a, b));
	}
}
```

O valor de `c()` sempre será 0. Nos dois branches de processamento, ele sempre
retornará 0. Vamos ver como que executa o processamento?

```none
valor de (a,b) aqui na função `b`: (0,0)
valor de (a,b) aqui na função `c`: (1,0)
1
3
valor de (a,b) aqui na função `main`: (1,3)
```

Mas olha que interessante! Simplesmente fazer com que a variável `b` dependesse
da função `c()` fez com que o valor de `b` não fosse carregado na função `b()`!

Mas... vamos fazer um tweak na função `c()`? Vamos fazer com que ela não
dependa nem de `a` nem de `b`? Podemos pegar o nosso template, o tamanho dele,
e então subtrair o valor de si mesmo:

```java
class X {
	private static final int a = b() + 1;
	private static final int b = c() + 3;

	static {
		IO.println(a);
		IO.println(b);
	}

	public static int c() {
		final var template = "valor de (a,b) aqui na função `%s`: (%d,%d)";
		return template.length() - template.length();
	}

	public static int b() {
		IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted("b", a, b));
		return b;
	}

	public static void main(String... args) {
		IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted("main", a, b));
	}
}
```

E o valor que imprime:

```none
valor de (a,b) aqui na função `b`: (0,0)
1
3
valor de (a,b) aqui na função `main`: (1,3)
```

> Note que não coloquei para imprimir os valores na função `c()` porque, se
> assim eu o fizesse, por mais que o valor do retorno de `c()` não dependesse
> de `a` ou de `b`, a computação iria depender em algum ponto e eu queria
> isolar totalmente isso.

Então, o que foi que mudou? Algo na função `b()` foi alterado, já que o valor
de `a` mudou. Vamos... olhar bytecode?

Para fazer isso, podemos chamar `javap -v` e passar o nome da classe em
questão. No caso, eu salvei no arquivo `a.java` por ser algo temporário, então
eu rodo essa linha de comando para construir o `.class`, pegar os bytecodes e
executar a classe `main`:

```bash
javac a.java && javap -v X && java X
```

Vamos ver como fica para o case em que `b = c() + 3`?

```java
class X {
	private static final int a = b() + 1;
	private static final int b = c() + 3;

	static {
		IO.println(a);
		IO.println(b);
	}

	private static int c() {
		return 0;
	}

	public static int b() {
		IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted("b", a, b));
		return b;
	}

	public static void main(String... args) {
		IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted("main", a, b));
	}
}
```

Os bytecodes são assim:

```bytecode
Classfile ~/computaria/blog/etc/java/X.class
  Last modified Nov 3, 2025; size 858 bytes
  SHA-256 checksum 1256192f860b6063ab7518b5ffddba303e7fc2eee99454f2b3fb2a6bc2f93949
  Compiled from "a.java"
class X
  minor version: 0
  major version: 69
  flags: (0x0020) ACC_SUPER
  this_class: #12                         // X
  super_class: #2                         // java/lang/Object
  interfaces: 0, fields: 2, methods: 5, attributes: 1
Constant pool:
   #1 = Methodref          #2.#3          // java/lang/Object."<init>":()V
   #2 = Class              #4             // java/lang/Object
   #3 = NameAndType        #5:#6          // "<init>":()V
   #4 = Utf8               java/lang/Object
   #5 = Utf8               <init>
   #6 = Utf8               ()V
   #7 = String             #8             // valor de (a,b) aqui na função `%s`: (%d,%d)
   #8 = Utf8               valor de (a,b) aqui na função `%s`: (%d,%d)
   #9 = String             #10            // b
  #10 = Utf8               b
  #11 = Fieldref           #12.#13        // X.a:I
  #12 = Class              #14            // X
  #13 = NameAndType        #15:#16        // a:I
  #14 = Utf8               X
  #15 = Utf8               a
  #16 = Utf8               I
  #17 = Methodref          #18.#19        // java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
  #18 = Class              #20            // java/lang/Integer
  #19 = NameAndType        #21:#22        // valueOf:(I)Ljava/lang/Integer;
  #20 = Utf8               java/lang/Integer
  #21 = Utf8               valueOf
  #22 = Utf8               (I)Ljava/lang/Integer;
  #23 = Fieldref           #12.#24        // X.b:I
  #24 = NameAndType        #10:#16        // b:I
  #25 = Methodref          #26.#27        // java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
  #26 = Class              #28            // java/lang/String
  #27 = NameAndType        #29:#30        // formatted:([Ljava/lang/Object;)Ljava/lang/String;
  #28 = Utf8               java/lang/String
  #29 = Utf8               formatted
  #30 = Utf8               ([Ljava/lang/Object;)Ljava/lang/String;
  #31 = Methodref          #32.#33        // java/lang/IO.println:(Ljava/lang/Object;)V
  #32 = Class              #34            // java/lang/IO
  #33 = NameAndType        #35:#36        // println:(Ljava/lang/Object;)V
  #34 = Utf8               java/lang/IO
  #35 = Utf8               println
  #36 = Utf8               (Ljava/lang/Object;)V
  #37 = String             #38            // main
  #38 = Utf8               main
  #39 = Methodref          #12.#40        // X.b:()I
  #40 = NameAndType        #10:#41        // b:()I
  #41 = Utf8               ()I
  #42 = Methodref          #12.#43        // X.c:()I
  #43 = NameAndType        #44:#41        // c:()I
  #44 = Utf8               c
  #45 = Utf8               Code
  #46 = Utf8               LineNumberTable
  #47 = Utf8               ([Ljava/lang/String;)V
  #48 = Utf8               <clinit>
  #49 = Utf8               SourceFile
  #50 = Utf8               a.java
{
  X();
    descriptor: ()V
    flags: (0x0000)
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 1: 0

  public static int b();
    descriptor: ()I
    flags: (0x0009) ACC_PUBLIC, ACC_STATIC
    Code:
      stack=5, locals=0, args_size=0
         0: ldc           #7                  // String valor de (a,b) aqui na função `%s`: (%d,%d)
         2: iconst_3
         3: anewarray     #2                  // class java/lang/Object
         6: dup
         7: iconst_0
         8: ldc           #9                  // String b
        10: aastore
        11: dup
        12: iconst_1
        13: getstatic     #11                 // Field a:I
        16: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        19: aastore
        20: dup
        21: iconst_2
        22: getstatic     #23                 // Field b:I
        25: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        28: aastore
        29: invokevirtual #25                 // Method java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
        32: invokestatic  #31                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        35: getstatic     #23                 // Field b:I
        38: ireturn
      LineNumberTable:
        line 15: 0
        line 16: 35

  public static void main(java.lang.String...);
    descriptor: ([Ljava/lang/String;)V
    flags: (0x0089) ACC_PUBLIC, ACC_STATIC, ACC_VARARGS
    Code:
      stack=5, locals=1, args_size=1
         0: ldc           #7                  // String valor de (a,b) aqui na função `%s`: (%d,%d)
         2: iconst_3
         3: anewarray     #2                  // class java/lang/Object
         6: dup
         7: iconst_0
         8: ldc           #37                 // String main
        10: aastore
        11: dup
        12: iconst_1
        13: getstatic     #11                 // Field a:I
        16: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        19: aastore
        20: dup
        21: iconst_2
        22: getstatic     #23                 // Field b:I
        25: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        28: aastore
        29: invokevirtual #25                 // Method java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
        32: invokestatic  #31                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        35: return
      LineNumberTable:
        line 20: 0
        line 21: 35

  static {};
    descriptor: ()V
    flags: (0x0008) ACC_STATIC
    Code:
      stack=2, locals=0, args_size=0
         0: invokestatic  #39                 // Method b:()I
         3: iconst_1
         4: iadd
         5: putstatic     #11                 // Field a:I
         8: invokestatic  #42                 // Method c:()I
        11: iconst_3
        12: iadd
        13: putstatic     #23                 // Field b:I
        16: getstatic     #11                 // Field a:I
        19: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        22: invokestatic  #31                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        25: getstatic     #23                 // Field b:I
        28: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        31: invokestatic  #31                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        34: return
      LineNumberTable:
        line 2: 0
        line 3: 8
        line 6: 16
        line 7: 25
        line 8: 34
}
SourceFile: "a.java"
```

Hmmm, muita coisa. Vamos focar aqui na função `<clinit>` (identificada por
`static{}`), que é o trecho de código chamado ao inicializar a classe:

```bytecode
  static {};
    descriptor: ()V
    flags: (0x0008) ACC_STATIC
    Code:
      stack=2, locals=0, args_size=0
         0: invokestatic  #39                 // Method b:()I
         3: iconst_1
         4: iadd
         5: putstatic     #11                 // Field a:I
         8: invokestatic  #42                 // Method c:()I
        11: iconst_3
        12: iadd
        13: putstatic     #23                 // Field b:I
        16: getstatic     #11                 // Field a:I
        19: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        22: invokestatic  #31                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        25: getstatic     #23                 // Field b:I
        28: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        31: invokestatic  #31                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        34: return
      LineNumberTable:
        line 2: 0
        line 3: 8
        line 6: 16
        line 7: 25
        line 8: 34
```

Primeira coisa a se ver: `descriptor: ()V`. Isso quer dizer que é uma função
sem argumentos que não tem retorno. O `V` significa a ausência do retorno, como
se fosse um `void`.

Perceba que o construtor também é indicado como se não retornasse nada:

```bytecode
  X();
    descriptor: ()V
    flags: (0x0000)
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 1: 0
```

O descritor continua sendo `()V`. Como que isso é possível se para criar
objetos fazemos algo como `final var x = new X();`? Vamos testar. Mudar aqui
para ter uma função `void printValues(String place)` que chama o template para
imprimir os valores naquele local específico:

```java
class X {
	private static final int a = b() + 1;
	private static final int b = c() + 3;

	static {
		IO.println(a);
		IO.println(b);
	}

	private static int c() {
		return 0;
	}

	public static int b() {
		new X().printValues("b");
		return b;
	}

	public static void main(String... args) {
		new X().printValues("main");
	}

	public void printValues(String place) {
		IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted(place, a, b));
	}
}
```

```bytecode
Classfile ~/computaria/blog/etc/java/X.class
  Last modified Nov 3, 2025; size 942 bytes
  SHA-256 checksum 2b846bf7193d17d8111a25a647772fa45e13073cc409aa8eed473613bcc1a37d
  Compiled from "a.java"
class X
  minor version: 0
  major version: 69
  flags: (0x0020) ACC_SUPER
  this_class: #7                          // X
  super_class: #2                         // java/lang/Object
  interfaces: 0, fields: 2, methods: 6, attributes: 1
Constant pool:
   #1 = Methodref          #2.#3          // java/lang/Object."<init>":()V
   #2 = Class              #4             // java/lang/Object
   #3 = NameAndType        #5:#6          // "<init>":()V
   #4 = Utf8               java/lang/Object
   #5 = Utf8               <init>
   #6 = Utf8               ()V
   #7 = Class              #8             // X
   #8 = Utf8               X
   #9 = Methodref          #7.#3          // X."<init>":()V
  #10 = String             #11            // b
  #11 = Utf8               b
  #12 = Methodref          #7.#13         // X.printValues:(Ljava/lang/String;)V
  #13 = NameAndType        #14:#15        // printValues:(Ljava/lang/String;)V
  #14 = Utf8               printValues
  #15 = Utf8               (Ljava/lang/String;)V
  #16 = Fieldref           #7.#17         // X.b:I
  #17 = NameAndType        #11:#18        // b:I
  #18 = Utf8               I
  #19 = String             #20            // main
  #20 = Utf8               main
  #21 = String             #22            // valor de (a,b) aqui na função `%s`: (%d,%d)
  #22 = Utf8               valor de (a,b) aqui na função `%s`: (%d,%d)
  #23 = Fieldref           #7.#24         // X.a:I
  #24 = NameAndType        #25:#18        // a:I
  #25 = Utf8               a
  #26 = Methodref          #27.#28        // java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
  #27 = Class              #29            // java/lang/Integer
  #28 = NameAndType        #30:#31        // valueOf:(I)Ljava/lang/Integer;
  #29 = Utf8               java/lang/Integer
  #30 = Utf8               valueOf
  #31 = Utf8               (I)Ljava/lang/Integer;
  #32 = Methodref          #33.#34        // java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
  #33 = Class              #35            // java/lang/String
  #34 = NameAndType        #36:#37        // formatted:([Ljava/lang/Object;)Ljava/lang/String;
  #35 = Utf8               java/lang/String
  #36 = Utf8               formatted
  #37 = Utf8               ([Ljava/lang/Object;)Ljava/lang/String;
  #38 = Methodref          #39.#40        // java/lang/IO.println:(Ljava/lang/Object;)V
  #39 = Class              #41            // java/lang/IO
  #40 = NameAndType        #42:#43        // println:(Ljava/lang/Object;)V
  #41 = Utf8               java/lang/IO
  #42 = Utf8               println
  #43 = Utf8               (Ljava/lang/Object;)V
  #44 = Methodref          #7.#45         // X.b:()I
  #45 = NameAndType        #11:#46        // b:()I
  #46 = Utf8               ()I
  #47 = Methodref          #7.#48         // X.c:()I
  #48 = NameAndType        #49:#46        // c:()I
  #49 = Utf8               c
  #50 = Utf8               Code
  #51 = Utf8               LineNumberTable
  #52 = Utf8               ([Ljava/lang/String;)V
  #53 = Utf8               <clinit>
  #54 = Utf8               SourceFile
  #55 = Utf8               a.java
{
  X();
    descriptor: ()V
    flags: (0x0000)
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 1: 0

  public static int b();
    descriptor: ()I
    flags: (0x0009) ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=0, args_size=0
         0: new           #7                  // class X
         3: dup
         4: invokespecial #9                  // Method "<init>":()V
         7: ldc           #10                 // String b
         9: invokevirtual #12                 // Method printValues:(Ljava/lang/String;)V
        12: getstatic     #16                 // Field b:I
        15: ireturn
      LineNumberTable:
        line 15: 0
        line 17: 12

  public static void main(java.lang.String...);
    descriptor: ([Ljava/lang/String;)V
    flags: (0x0089) ACC_PUBLIC, ACC_STATIC, ACC_VARARGS
    Code:
      stack=2, locals=1, args_size=1
         0: new           #7                  // class X
         3: dup
         4: invokespecial #9                  // Method "<init>":()V
         7: ldc           #19                 // String main
         9: invokevirtual #12                 // Method printValues:(Ljava/lang/String;)V
        12: return
      LineNumberTable:
        line 21: 0
        line 22: 12

  public void printValues(java.lang.String);
    descriptor: (Ljava/lang/String;)V
    flags: (0x0001) ACC_PUBLIC
    Code:
      stack=5, locals=2, args_size=2
         0: ldc           #21                 // String valor de (a,b) aqui na função `%s`: (%d,%d)
         2: iconst_3
         3: anewarray     #2                  // class java/lang/Object
         6: dup
         7: iconst_0
         8: aload_1
         9: aastore
        10: dup
        11: iconst_1
        12: getstatic     #23                 // Field a:I
        15: invokestatic  #26                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        18: aastore
        19: dup
        20: iconst_2
        21: getstatic     #16                 // Field b:I
        24: invokestatic  #26                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        27: aastore
        28: invokevirtual #32                 // Method java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
        31: invokestatic  #38                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        34: return
      LineNumberTable:
        line 25: 0
        line 26: 34

  static {};
    descriptor: ()V
    flags: (0x0008) ACC_STATIC
    Code:
      stack=2, locals=0, args_size=0
         0: invokestatic  #44                 // Method b:()I
         3: iconst_1
         4: iadd
         5: putstatic     #23                 // Field a:I
         8: invokestatic  #47                 // Method c:()I
        11: iconst_3
        12: iadd
        13: putstatic     #16                 // Field b:I
        16: getstatic     #23                 // Field a:I
        19: invokestatic  #26                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        22: invokestatic  #38                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        25: getstatic     #16                 // Field b:I
        28: invokestatic  #26                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        31: invokestatic  #38                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        34: return
      LineNumberTable:
        line 2: 0
        line 3: 8
        line 6: 16
        line 7: 25
        line 8: 34
}
SourceFile: "a.java"
```

Vamos focar aqui na função `main`:

```bytecode
  public static void main(java.lang.String...);
    descriptor: ([Ljava/lang/String;)V
    flags: (0x0089) ACC_PUBLIC, ACC_STATIC, ACC_VARARGS
    Code:
      stack=2, locals=1, args_size=1
         0: new           #7                  // class X
         3: dup
         4: invokespecial #9                  // Method "<init>":()V
         7: ldc           #19                 // String main
         9: invokevirtual #12                 // Method printValues:(Ljava/lang/String;)V
        12: return
      LineNumberTable:
        line 21: 0
        line 22: 12
```

No primeiro instante, é chamado o bytecode `new` passando como parâmetro o
7º elemento da _constant pool_. Mas que elemento é esse?

```bytecode
#7 = Class              #8             // X
#8 = Utf8               X
```

O 7º elemento indica que é uma classe, que por sua vez tem o nome representado
pelo 8º elemento. O 8º elemento diz que é uma string Utf8 com o conteúdo `"X"`.
Mas e se por acaso a classe fosse mais complexa? Bem, temos um exemplo disso:

```bytecode
#2 = Class              #4             // java/lang/Object
#4 = Utf8               java/lang/Object
```

A classe é indicada como tendo como nome a string Utf8 `"java/lang/Object"`.

Ok, voltando ao ponto, indicamos que chamamos `new` para a classe `X`. Isso
garante que o espaço de memória para o objeto é reservado, não que o objeto
seja inicializado. Logo depois temos `dup`. Então é chamado `invokespecial #9`,
que é o construtor `<init>:()V` ca classe `X`. Logo depois chama `ldc #19`
(carrega a string `"main"` como próxima referência na memória)  e então
`invokevirtual #12`. O `invokevirtual` é o método de chamada de método
tradicional, no caso o método #12 é o método
`printValues:(Ljava/lang/String;)V` da classe `X`. Como o `ldc` já carregou uma
referência em memória, a JVM sabe que o método virtual vai ser do objeto
anterior a isso na stack. Como que temos um objeto da classe `X` na stack?

Bem, vamos seguir a trilha do que foi chamado. No começo, o `new X`, que
reserva o espaço de memória. Então, chama-se `dup`. Logo depois, uma chamada
para `invokespecial` de uma função que retorna `V` (ie, não retorna nada). Logo
depois uma carga de `ldc`, e então a chamada para o método `printValues` que
vai consumir uma referência de `X` e a referência de string na stack, e como é
`V` não vai colocar nada no lugar. O `invokespecial` não coloca nada no lugar,
então ele só consome a referência.

Portanto, algo entre o `new` e o `invokespecial` deixou uma referência a mais.
E advinha o que temos no caminho? O `dup`! O bytecode `dup` duplica a
referência que está na stack. E a última referência foi a retornada pelo
bytecode `new`. Logo, ao fazer `new X().printValues("main")` ele vai fazer o
seguinte:

- criar um novo objeto do tipo `X`
- duplicar a referência do novo objeto criado
- consumir a primeira referência chamando o construtor, para inicializar o
  objeto
- colocar a constante do _constant pool_ na stack
- chamar um método virtual que do objeto `X`, consumindo a segunda referência
  duplicada

Ok, vamos sair dessa tangente e voltar pra análise do bytecode. O próximo ponto
é `flags`, que nesse caso só tem o `ACC_STATIC` ligado (note que `b()` tem as
flags `ACC_PUBLIC, ACC_STATIC` ligadas). Após isso, começa de verdade o código
de execução. Ele tem alguns metadados (`stack=2, locals=0, args_size=0`) sobre
as variáveis dele e então começa algumas coisas legais:

```bytecode
0: invokestatic  #39                 // Method b:()I
3: iconst_1
4: iadd
5: putstatic     #11                 // Field a:I
```

Aqui, ele está chamando o método estático `b:()I`, que não tem argumentos e
retorna um inteiro, logo depois ele coloca a constante `1` na pilha. Então ele
soma esses valores (`iadd`) e coloca isso em uma variável estática com
`putstatic`. Nesse caso está colocando no campo estática `a`.

Logo depois temos algo semelhante que coloca o valor no campo estático `b`:

```bytecode
8: invokestatic  #42                 // Method c:()I
11: iconst_3
12: iadd
13: putstatic     #23                 // Field b:I
```

Na função `b()` temos isso:

```bytecode
  public static int b();
    descriptor: ()I
    flags: (0x0009) ACC_PUBLIC, ACC_STATIC
    Code:
      stack=5, locals=0, args_size=0
         0: ldc           #7                  // String valor de (a,b) aqui na função `%s`: (%d,%d)
         2: iconst_3
         3: anewarray     #2                  // class java/lang/Object
         6: dup
         7: iconst_0
         8: ldc           #9                  // String b
        10: aastore
        11: dup
        12: iconst_1
        13: getstatic     #11                 // Field a:I
        16: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        19: aastore
        20: dup
        21: iconst_2
        22: getstatic     #23                 // Field b:I
        25: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        28: aastore
        29: invokevirtual #25                 // Method java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
        32: invokestatic  #31                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        35: getstatic     #23                 // Field b:I
        38: ireturn
      LineNumberTable:
        line 15: 0
        line 16: 35
```

Mas o que realmente interessa é apenas isso (vou cortar toda a burocracia do
imprimir os valores):

```bytecode
  public static int b();
    descriptor: ()I
    flags: (0x0009) ACC_PUBLIC, ACC_STATIC
    Code:
      stack=5, locals=0, args_size=0
        // ...
        35: getstatic     #23                 // Field b:I
        38: ireturn
      LineNumberTable:
        line 15: 0
        line 16: 35
```

Basicamente ele pega o valor do campo estático `b` e retorna.

Certo, agora vamos ver se muda muita coisa ao inicializar o valor de `b` apenas
com a constante `3`:

```java
class X {
	private static final int a = b() + 1;
	private static final int b = 3;

	static {
		IO.println(a);
		IO.println(b);
	}

	public static int b() {
		IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted("b", a, b));
		return b;
	}

	public static void main(String... args) {
		IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted("main", a, b));
	}
}
```

```bytecode
Classfile ~/computaria/blog/etc/java/X.class
  Last modified Nov 3, 2025; size 803 bytes
  SHA-256 checksum 1daee38dfbaf52b8404b825ad86ac7948e04da4ad15c7e27afd22063ed0a8314
  Compiled from "a.java"
class X
  minor version: 0
  major version: 69
  flags: (0x0020) ACC_SUPER
  this_class: #12                         // X
  super_class: #2                         // java/lang/Object
  interfaces: 0, fields: 2, methods: 4, attributes: 1
Constant pool:
   #1 = Methodref          #2.#3          // java/lang/Object."<init>":()V
   #2 = Class              #4             // java/lang/Object
   #3 = NameAndType        #5:#6          // "<init>":()V
   #4 = Utf8               java/lang/Object
   #5 = Utf8               <init>
   #6 = Utf8               ()V
   #7 = String             #8             // valor de (a,b) aqui na função `%s`: (%d,%d)
   #8 = Utf8               valor de (a,b) aqui na função `%s`: (%d,%d)
   #9 = String             #10            // b
  #10 = Utf8               b
  #11 = Fieldref           #12.#13        // X.a:I
  #12 = Class              #14            // X
  #13 = NameAndType        #15:#16        // a:I
  #14 = Utf8               X
  #15 = Utf8               a
  #16 = Utf8               I
  #17 = Methodref          #18.#19        // java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
  #18 = Class              #20            // java/lang/Integer
  #19 = NameAndType        #21:#22        // valueOf:(I)Ljava/lang/Integer;
  #20 = Utf8               java/lang/Integer
  #21 = Utf8               valueOf
  #22 = Utf8               (I)Ljava/lang/Integer;
  #23 = Methodref          #24.#25        // java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
  #24 = Class              #26            // java/lang/String
  #25 = NameAndType        #27:#28        // formatted:([Ljava/lang/Object;)Ljava/lang/String;
  #26 = Utf8               java/lang/String
  #27 = Utf8               formatted
  #28 = Utf8               ([Ljava/lang/Object;)Ljava/lang/String;
  #29 = Methodref          #30.#31        // java/lang/IO.println:(Ljava/lang/Object;)V
  #30 = Class              #32            // java/lang/IO
  #31 = NameAndType        #33:#34        // println:(Ljava/lang/Object;)V
  #32 = Utf8               java/lang/IO
  #33 = Utf8               println
  #34 = Utf8               (Ljava/lang/Object;)V
  #35 = String             #36            // main
  #36 = Utf8               main
  #37 = Methodref          #12.#38        // X.b:()I
  #38 = NameAndType        #10:#39        // b:()I
  #39 = Utf8               ()I
  #40 = Utf8               ConstantValue
  #41 = Integer            3
  #42 = Utf8               Code
  #43 = Utf8               LineNumberTable
  #44 = Utf8               ([Ljava/lang/String;)V
  #45 = Utf8               <clinit>
  #46 = Utf8               SourceFile
  #47 = Utf8               a.java
{
  X();
    descriptor: ()V
    flags: (0x0000)
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 1: 0

  public static int b();
    descriptor: ()I
    flags: (0x0009) ACC_PUBLIC, ACC_STATIC
    Code:
      stack=5, locals=0, args_size=0
         0: ldc           #7                  // String valor de (a,b) aqui na função `%s`: (%d,%d)
         2: iconst_3
         3: anewarray     #2                  // class java/lang/Object
         6: dup
         7: iconst_0
         8: ldc           #9                  // String b
        10: aastore
        11: dup
        12: iconst_1
        13: getstatic     #11                 // Field a:I
        16: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        19: aastore
        20: dup
        21: iconst_2
        22: iconst_3
        23: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        26: aastore
        27: invokevirtual #23                 // Method java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
        30: invokestatic  #29                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        33: iconst_3
        34: ireturn
      LineNumberTable:
        line 11: 0
        line 12: 33

  public static void main(java.lang.String...);
    descriptor: ([Ljava/lang/String;)V
    flags: (0x0089) ACC_PUBLIC, ACC_STATIC, ACC_VARARGS
    Code:
      stack=5, locals=1, args_size=1
         0: ldc           #7                  // String valor de (a,b) aqui na função `%s`: (%d,%d)
         2: iconst_3
         3: anewarray     #2                  // class java/lang/Object
         6: dup
         7: iconst_0
         8: ldc           #35                 // String main
        10: aastore
        11: dup
        12: iconst_1
        13: getstatic     #11                 // Field a:I
        16: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        19: aastore
        20: dup
        21: iconst_2
        22: iconst_3
        23: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        26: aastore
        27: invokevirtual #23                 // Method java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
        30: invokestatic  #29                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        33: return
      LineNumberTable:
        line 16: 0
        line 17: 33

  static {};
    descriptor: ()V
    flags: (0x0008) ACC_STATIC
    Code:
      stack=2, locals=0, args_size=0
         0: invokestatic  #37                 // Method b:()I
         3: iconst_1
         4: iadd
         5: putstatic     #11                 // Field a:I
         8: getstatic     #11                 // Field a:I
        11: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        14: invokestatic  #29                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        17: iconst_3
        18: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        21: invokestatic  #29                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        24: return
      LineNumberTable:
        line 2: 0
        line 6: 8
        line 7: 17
        line 8: 24
}
SourceFile: "a.java"
```

Focando na inicialização estática inicialmente:

```bytecode
  static {};
    descriptor: ()V
    flags: (0x0008) ACC_STATIC
    Code:
      stack=2, locals=0, args_size=0
         0: invokestatic  #37                 // Method b:()I
         3: iconst_1
         4: iadd
         5: putstatic     #11                 // Field a:I
         8: getstatic     #11                 // Field a:I
        11: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        14: invokestatic  #29                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        17: iconst_3
        18: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        21: invokestatic  #29                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        24: return
      LineNumberTable:
        line 2: 0
        line 6: 8
        line 7: 17
        line 8: 24
```

Ele começa povoando a variável estática `a`:

```bytecode
0: invokestatic  #37                 // Method b:()I
3: iconst_1
4: iadd
5: putstatic     #11                 // Field a:I
```

Igual ao que tinha antes (dado uma pequena mudança nos offsets do
_constant pool_). E depois disso ele chama para preencher os `IO.println(...)`.

Hmmm, não povoou a variável `b` aqui. Inclusive, em `Fieldref` só há menção
para o campo `a` da classe `X`, não tem mais para o campo `b` da classe `X`.
Hmmm, intrigante. E a função `b()`?

```bytecode
  public static int b();
    descriptor: ()I
    flags: (0x0009) ACC_PUBLIC, ACC_STATIC
    Code:
      stack=5, locals=0, args_size=0
        // ...
        33: iconst_3
        34: ireturn
      LineNumberTable:
        line 11: 0
        line 12: 33
```

Tem muita bucrocia e no final tem:

- carrega o inteiro `3` na pilha
- retorna um inteiro

E só? O valor estático `b` sumiu? Pelo visto...

Ok, vamos fazer um pequeno experimento, deixar esses valores como parte visível
da API dessa classe, vamos remover o `private` tanto do campo `a` como do campo
`b`:

```java
class X {
	static final int a = b() + 1;
	static final int b = 3;

	static {
		IO.println(a);
		IO.println(b);
	}

	public static int b() {
		IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted("b", a, b));
		return b;
	}

	public static void main(String... args) {
		IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted("main", a, b));
	}
}
```

```bytecode
Classfile ~/computaria/blog/etc/java/X.class
  Last modified Nov 4, 2025; size 803 bytes
  SHA-256 checksum 7e138053b9ce2ad0ed79bee707080c89cacbb12b3bd71f4110865444a6399918
  Compiled from "a.java"
class X
  minor version: 0
  major version: 69
  flags: (0x0020) ACC_SUPER
  this_class: #12                         // X
  super_class: #2                         // java/lang/Object
  interfaces: 0, fields: 2, methods: 4, attributes: 1
Constant pool:
   #1 = Methodref          #2.#3          // java/lang/Object."<init>":()V
   #2 = Class              #4             // java/lang/Object
   #3 = NameAndType        #5:#6          // "<init>":()V
   #4 = Utf8               java/lang/Object
   #5 = Utf8               <init>
   #6 = Utf8               ()V
   #7 = String             #8             // valor de (a,b) aqui na função `%s`: (%d,%d)
   #8 = Utf8               valor de (a,b) aqui na função `%s`: (%d,%d)
   #9 = String             #10            // b
  #10 = Utf8               b
  #11 = Fieldref           #12.#13        // X.a:I
  #12 = Class              #14            // X
  #13 = NameAndType        #15:#16        // a:I
  #14 = Utf8               X
  #15 = Utf8               a
  #16 = Utf8               I
  #17 = Methodref          #18.#19        // java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
  #18 = Class              #20            // java/lang/Integer
  #19 = NameAndType        #21:#22        // valueOf:(I)Ljava/lang/Integer;
  #20 = Utf8               java/lang/Integer
  #21 = Utf8               valueOf
  #22 = Utf8               (I)Ljava/lang/Integer;
  #23 = Methodref          #24.#25        // java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
  #24 = Class              #26            // java/lang/String
  #25 = NameAndType        #27:#28        // formatted:([Ljava/lang/Object;)Ljava/lang/String;
  #26 = Utf8               java/lang/String
  #27 = Utf8               formatted
  #28 = Utf8               ([Ljava/lang/Object;)Ljava/lang/String;
  #29 = Methodref          #30.#31        // java/lang/IO.println:(Ljava/lang/Object;)V
  #30 = Class              #32            // java/lang/IO
  #31 = NameAndType        #33:#34        // println:(Ljava/lang/Object;)V
  #32 = Utf8               java/lang/IO
  #33 = Utf8               println
  #34 = Utf8               (Ljava/lang/Object;)V
  #35 = String             #36            // main
  #36 = Utf8               main
  #37 = Methodref          #12.#38        // X.b:()I
  #38 = NameAndType        #10:#39        // b:()I
  #39 = Utf8               ()I
  #40 = Utf8               ConstantValue
  #41 = Integer            3
  #42 = Utf8               Code
  #43 = Utf8               LineNumberTable
  #44 = Utf8               ([Ljava/lang/String;)V
  #45 = Utf8               <clinit>
  #46 = Utf8               SourceFile
  #47 = Utf8               a.java
{
  static final int a;
    descriptor: I
    flags: (0x0018) ACC_STATIC, ACC_FINAL

  static final int b;
    descriptor: I
    flags: (0x0018) ACC_STATIC, ACC_FINAL
    ConstantValue: int 3

  X();
    descriptor: ()V
    flags: (0x0000)
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 1: 0

  public static int b();
    descriptor: ()I
    flags: (0x0009) ACC_PUBLIC, ACC_STATIC
    Code:
      stack=5, locals=0, args_size=0
         0: ldc           #7                  // String valor de (a,b) aqui na função `%s`: (%d,%d)
         2: iconst_3
         3: anewarray     #2                  // class java/lang/Object
         6: dup
         7: iconst_0
         8: ldc           #9                  // String b
        10: aastore
        11: dup
        12: iconst_1
        13: getstatic     #11                 // Field a:I
        16: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        19: aastore
        20: dup
        21: iconst_2
        22: iconst_3
        23: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        26: aastore
        27: invokevirtual #23                 // Method java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
        30: invokestatic  #29                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        33: iconst_3
        34: ireturn
      LineNumberTable:
        line 11: 0
        line 12: 33

  public static void main(java.lang.String...);
    descriptor: ([Ljava/lang/String;)V
    flags: (0x0089) ACC_PUBLIC, ACC_STATIC, ACC_VARARGS
    Code:
      stack=5, locals=1, args_size=1
         0: ldc           #7                  // String valor de (a,b) aqui na função `%s`: (%d,%d)
         2: iconst_3
         3: anewarray     #2                  // class java/lang/Object
         6: dup
         7: iconst_0
         8: ldc           #35                 // String main
        10: aastore
        11: dup
        12: iconst_1
        13: getstatic     #11                 // Field a:I
        16: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        19: aastore
        20: dup
        21: iconst_2
        22: iconst_3
        23: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        26: aastore
        27: invokevirtual #23                 // Method java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
        30: invokestatic  #29                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        33: return
      LineNumberTable:
        line 16: 0
        line 17: 33

  static {};
    descriptor: ()V
    flags: (0x0008) ACC_STATIC
    Code:
      stack=2, locals=0, args_size=0
         0: invokestatic  #37                 // Method b:()I
         3: iconst_1
         4: iadd
         5: putstatic     #11                 // Field a:I
         8: getstatic     #11                 // Field a:I
        11: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        14: invokestatic  #29                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        17: iconst_3
        18: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        21: invokestatic  #29                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        24: return
      LineNumberTable:
        line 2: 0
        line 6: 8
        line 7: 17
        line 8: 24
}
SourceFile: "a.java"
```

O único `Fieldref` que tem é a menção ao `X.a`. Mas após o _constant pool_ ele
menciona uma coisa interessante:

```bytecode
  static final int a;
    descriptor: I
    flags: (0x0018) ACC_STATIC, ACC_FINAL

  static final int b;
    descriptor: I
    flags: (0x0018) ACC_STATIC, ACC_FINAL
    ConstantValue: int 3
```

As variáveis `a` e `b` como parte da API da classe! Note que `b` já tem valor
determinístico definido, 3. Por isso que não é inicializada tal qual `a`.

Agora... e se eu mudar a inicialização de `b`? No lugar de ser inicialização na
declaração do campo, por no campo estático?

```java
class X {
	static final int a = b() + 1;
	static final int b;

	static {
		b = 3;
		IO.println(a);
		IO.println(b);
	}
	// ...
}
```

O bytecode gerado muda um pouquinho:

```bytecode
Classfile ~/computaria/blog/etc/java/X.class
  Last modified Nov 4, 2025; size 800 bytes
  SHA-256 checksum 31c6b9274e883db117b635693265c4bcc20cf2f3e51ecd877cfe0b3fbd1fe097
  Compiled from "a.java"
class X
  minor version: 0
  major version: 69
  flags: (0x0020) ACC_SUPER
  this_class: #12                         // X
  super_class: #2                         // java/lang/Object
  interfaces: 0, fields: 2, methods: 4, attributes: 1
Constant pool:
   #1 = Methodref          #2.#3          // java/lang/Object."<init>":()V
   #2 = Class              #4             // java/lang/Object
   #3 = NameAndType        #5:#6          // "<init>":()V
   #4 = Utf8               java/lang/Object
   #5 = Utf8               <init>
   #6 = Utf8               ()V
   #7 = String             #8             // valor de (a,b) aqui na função `%s`: (%d,%d)
   #8 = Utf8               valor de (a,b) aqui na função `%s`: (%d,%d)
   #9 = String             #10            // b
  #10 = Utf8               b
  #11 = Fieldref           #12.#13        // X.a:I
  #12 = Class              #14            // X
  #13 = NameAndType        #15:#16        // a:I
  #14 = Utf8               X
  #15 = Utf8               a
  #16 = Utf8               I
  #17 = Methodref          #18.#19        // java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
  #18 = Class              #20            // java/lang/Integer
  #19 = NameAndType        #21:#22        // valueOf:(I)Ljava/lang/Integer;
  #20 = Utf8               java/lang/Integer
  #21 = Utf8               valueOf
  #22 = Utf8               (I)Ljava/lang/Integer;
  #23 = Fieldref           #12.#24        // X.b:I
  #24 = NameAndType        #10:#16        // b:I
  #25 = Methodref          #26.#27        // java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
  #26 = Class              #28            // java/lang/String
  #27 = NameAndType        #29:#30        // formatted:([Ljava/lang/Object;)Ljava/lang/String;
  #28 = Utf8               java/lang/String
  #29 = Utf8               formatted
  #30 = Utf8               ([Ljava/lang/Object;)Ljava/lang/String;
  #31 = Methodref          #32.#33        // java/lang/IO.println:(Ljava/lang/Object;)V
  #32 = Class              #34            // java/lang/IO
  #33 = NameAndType        #35:#36        // println:(Ljava/lang/Object;)V
  #34 = Utf8               java/lang/IO
  #35 = Utf8               println
  #36 = Utf8               (Ljava/lang/Object;)V
  #37 = String             #38            // main
  #38 = Utf8               main
  #39 = Methodref          #12.#40        // X.b:()I
  #40 = NameAndType        #10:#41        // b:()I
  #41 = Utf8               ()I
  #42 = Utf8               Code
  #43 = Utf8               LineNumberTable
  #44 = Utf8               ([Ljava/lang/String;)V
  #45 = Utf8               <clinit>
  #46 = Utf8               SourceFile
  #47 = Utf8               a.java
{
  static final int a;
    descriptor: I
    flags: (0x0018) ACC_STATIC, ACC_FINAL

  static final int b;
    descriptor: I
    flags: (0x0018) ACC_STATIC, ACC_FINAL

  X();
    descriptor: ()V
    flags: (0x0000)
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 1: 0

  public static int b();
    descriptor: ()I
    flags: (0x0009) ACC_PUBLIC, ACC_STATIC
    Code:
      stack=5, locals=0, args_size=0
         0: ldc           #7                  // String valor de (a,b) aqui na função `%s`: (%d,%d)
         2: iconst_3
         3: anewarray     #2                  // class java/lang/Object
         6: dup
         7: iconst_0
         8: ldc           #9                  // String b
        10: aastore
        11: dup
        12: iconst_1
        13: getstatic     #11                 // Field a:I
        16: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        19: aastore
        20: dup
        21: iconst_2
        22: getstatic     #23                 // Field b:I
        25: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        28: aastore
        29: invokevirtual #25                 // Method java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
        32: invokestatic  #31                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        35: getstatic     #23                 // Field b:I
        38: ireturn
      LineNumberTable:
        line 12: 0
        line 13: 35

  public static void main(java.lang.String...);
    descriptor: ([Ljava/lang/String;)V
    flags: (0x0089) ACC_PUBLIC, ACC_STATIC, ACC_VARARGS
    Code:
      stack=5, locals=1, args_size=1
         0: ldc           #7                  // String valor de (a,b) aqui na função `%s`: (%d,%d)
         2: iconst_3
         3: anewarray     #2                  // class java/lang/Object
         6: dup
         7: iconst_0
         8: ldc           #37                 // String main
        10: aastore
        11: dup
        12: iconst_1
        13: getstatic     #11                 // Field a:I
        16: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        19: aastore
        20: dup
        21: iconst_2
        22: getstatic     #23                 // Field b:I
        25: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        28: aastore
        29: invokevirtual #25                 // Method java/lang/String.formatted:([Ljava/lang/Object;)Ljava/lang/String;
        32: invokestatic  #31                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        35: return
      LineNumberTable:
        line 17: 0
        line 18: 35

  static {};
    descriptor: ()V
    flags: (0x0008) ACC_STATIC
    Code:
      stack=2, locals=0, args_size=0
         0: invokestatic  #39                 // Method b:()I
         3: iconst_1
         4: iadd
         5: putstatic     #11                 // Field a:I
         8: iconst_3
         9: putstatic     #23                 // Field b:I
        12: getstatic     #11                 // Field a:I
        15: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        18: invokestatic  #31                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        21: getstatic     #23                 // Field b:I
        24: invokestatic  #17                 // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        27: invokestatic  #31                 // Method java/lang/IO.println:(Ljava/lang/Object;)V
        30: return
      LineNumberTable:
        line 2: 0
        line 6: 8
        line 7: 12
        line 8: 21
        line 9: 30
}
SourceFile: "a.java"
```

Note que agora:

- tem o `Fieldref` para `b` (campo 23 do _constant pool_)
- a variável `b` não aparece com valor na declaração dela
- a função `b()` usa `getstatic #23` no lugar de `iconst_3`
- existe inicialização do campo `b`: `iconst_3; putstatic #23`

E isso obviamente alterou a saída também:

```none
valor de (a,b) aqui na função `b`: (0,0)
1
3
valor de (a,b) aqui na função `main`: (1,3)
```

# E como resolve esse problema?

Na hipótese "closed world", podemos simplesmente fazer um grafo de dependência.
Não posso usar uma variável antes de ela estar inicializada, e assim eu posso
determinar que vai quebrar a compilação. Nessa situação de "closed world",
podemos dizer que a função `b()` depende da variável `b`, e que a variável `a`
depende da função `b()`. Assim sendo, como `a` depende de `b()`, isso significa
que eu teria de remover essa linha:

```java
IO.println("valor de (a,b) aqui na função `%s`: (%d,%d)".formatted("b", a, b));
```

Então, assim, para toda função teríamos e para toda variável teríamos um grafo
de dependência. Nesse sentido, poderíamos fazer até inverter a ordem das
declarações, visto que já há garantia de inicialização dos valores:


```java
class X {
	private final static int a = b + 1;
	private final static int b = 3;

	// ...
}
```

Isso seria possível pois saberíamos que `a` depende de `b`, mas que `b` não tem
nenhuma dependência para existir. Inclusive Rust trabalha assim:

```rust
static A: i32 = valor();
static B: i32 = value();

const fn value() -> i32 {
  A + 1
}

const fn valor() -> i32 {
  B + 1
}

fn main() {
  println!("{A} / {B}");
}
```

Isso gera o seguinte erro:

![Erro de referência circular]({{ page.base-assets | append: "rust-circular-ref.png" | relative_url }})

> Imagem cortesia do [Shinobu](https://bsky.app/profile/shinobu-dev.bsky.social),
> [post original](https://bsky.app/profile/shinobu-dev.bsky.social/post/3lhyucpvruc2q).

# Tá, mas só em carga de classes?

Não, isso também ocorre com criação de objetos. Você pode enviar um objeto
parcialmente carregado em qualquer momento, dentro do construtor. Qualquer
método que você chamar no construtor passando `this` pode incorrer nesse
problema.

O exemplo com a classe e campos estáticos é apenas mais pungente, pois se
espera que a classe esteja devidamente carregada para se poder usar.

# Mas por quê Java está condenado a esse problema?

Porque Java NÃO É _closed world_. A qualquer momento é esperado que um `.class`
seja alterado no classpath.

Se fosse closed world, eu poderia fazer isso sem problemas, com 2 classes:

```java
// com/jeffque/A.java
package com.jeffque;

import com.jeffque.etc.Consts;

public class A {
	public static int field1() {
		return FIELD_1;
	}

	public static int field2() {
		return FIELD_2;
	}

	public static final int FIELD_1;
	public static final int FIELD_2;

	static {
		FIELD_1 = Consts.firstPrime() * Consts.secondPrime();
		FIELD_2 = Consts.arbitraryHash();
	}
}

// com/jeffque/etc/Confs.java
package com.jeffque.etc;

public final class Confs {
	public static int firstPrime() {
		return 7;
	}

	public static int secondPrime() {
		return 29;
	}

	public static int arbitraryHash() {
		return 0xDEADBEEF;
	}
}
```

Aqui as dependências são:

- `A.field1()` => `A.FIELD_1`
- `A.field2()` => `A.FIELD_2`
- `A.FIELD_1` => `Consts.firstPrime()`, `Consts.secondPrime()`
- `A.FIELD_2` => `Consts.arbitraryHash()`

Agora, vamos alterar o hash arbitrário...

```java
// com/jeffque/etc/Confs.java
package com.jeffque.etc;

import external.source.Values;

public final class Confs {
	public static int firstPrime() {
		return 7;
	}

	public static int secondPrime() {
		return 29;
	}

	public static int arbitraryHash() {
		return Values.basic ^ 0xDEADBEEF;
	}
}
```

E aí, o que isso aqui imprimiria?

```java
// com/jeffque/app/App1.java

import com.jeffque.A;

public class App1 {
	public static void main(String... args) {
		System.out.println(A.field2());
	}
}
```

Isso depende agora do valor de `Values.basic`. Como Java assume que é "open
world", isso significa que ele não consegue (sempre) precomputar o valor de
`Confs.arbitraryHash`, já que o valor depende de um código externo que não
temos garantia de como é povoado.

Portanto, em um dado momento, o retorno pode ser `0xDEADBEEF`, mas se a
qualquer momento o _classloader_ carregar `external.source.Values` de outro
lugar, ou de repente o arquivo dessa classe ser sobrescrito (considerando que
ou a JVM não tem essa classe carregada), o valor pode se tornar `0xDEADBE00`.

# Considerações finais

Isso é uma falha da linguagem, IMHO. Mas, também, é um problema que foi aceito
desde o momento em que a linguagem foi concebida, já que ela foi feita
assumindo como premissa "open world", já que normalmente prender esse valor de
maneira que ele sempre seja um único valor basicamente implica em assumir
"closed world".

Então, no lugar de fechar o mundo, a escolha foi feita como um _compromise_ e
permitir esse _corner case_. Uma escolha que eu entendo e, para manter a
premissa que precisa funcionar como "open world", foi a melhor possível.
---
layout: post
title: "Anotações sobre JUnit/Mockito e testes automatizados em Java"
author: "Jefferson Quesado"
tags: teste java junit mockito
base-assets: "/assets/junit-mockito-anotacoes/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Deixei espalhado em alguns lugares anotações sobre o uso do JUnit e outras
coisas de teste automatizado em Java. Resolvi concentrar aqui no Computaria.

Eu tenho trabalhado basicamente com JUnit 5, então basicamente onde estiver
escrito "JUnit" aqui nesse post saiba que é sobre JUnit 5.

# JUnit 101

No JUnit, você anota um método com `@Test` e isso é o suficiente para pedir
para ele ser executado. Por exemplo:

```java
@Test
void marmota() {
    // tá vazio mesmo
}
```

No IntelliJ, no VSCode e em qualquer IDE Java que tenha respeito, fazer isso é
o suficiente para aparecer uma opção de executar esse trecho do código. Como em
Java tudo precisa ficar em um componente que determina namespace (como `class`,
`interface`, `record` ou outro definidor de tipo), também aparece nesse
componente que engloba os testes.

Ao mandar executar os testes, vai aparecer na IDE quais os testes que foram
executados. Existe a possibilidade de manipular o que irá aparecer como o "nome
do teste". A priori é o nome da função, mas podemos botar outra coisa:

```java
@Test
@DisplayName("outra coisa")
void marmota() {
    // tá vazio mesmo
}
```

Podemos por um gherkin:

```java
@Test
@DisplayName("""
    GIVEN 2 and 2
    WHEN adding those numbers together
    THEN I should get 4 as the result
    """)
void twoPlusTwo() {
    assertEquals(4, 2 + 2);
}
```

> Por favor, façam testes substanciais, isso aqui foi só um exemplo simples
> e bobinho!!!

É uma convenção no JUnit por o valor esperado do lado esquerdo e o valor obtido
do lado direito. Também podemos colocar uma mensagem de erro para ajudar a
guiar a pessoa caso o teste falhe. Por exemplo, pegue que eu quero testar esse
código aqui, onde o objeto gerado é imutável:

```java
public class GuardaValores {

    private final int x;
    private final int y;

    public GuardaValores(int x, int y) {
        this.x = x;
        this.y = y;
    }

    public int x() {
        return x;
    }

    public int y() {
        return y;
    }

    public GuardaValores alteraX(int novoX) {
        return new GuardaValores(novoX, y);
    }

    public GuardaValores alteraY(int novoY) {
        return new GuardaValores(x, novoY);
    }

    @Override
    public boolean equals(Object another) {
        if (another instanceof GuardaValores otherValidValue) {
            return this.x == otherValidValue.x && this.y == otherValidValue.y;
        }
        return false;
    }
}
```

E eu quero garantir que quem está escrevendo isso mantenha a coisa como
imutável:

```java
class GuardaValoresTest {
    @Test
    void realmenteImutavel() {
        final var primeiroValor = new GuardaValores(0, 0);
        final var segundoValor = primeiroValor.alteraX(2);
        final var terceiroValor = primeiroValor.alteraY(2);

        assertEquals(0, primeiroValor.x() + primeiroValor.y(), "Verificou que `GuardaValores` é de fato imutável?");
    }
}
```

A priori esse código passa. Mas imagina que alguém faça a seguinte alteração no
código de produção:

```java
public class GuardaValores {

    private int x;
    private int y;

    public GuardaValores(int x, int y) {
        this.x = x;
        this.y = y;
    }

    public int x() {
        return x;
    }

    public int y() {
        return y;
    }

    public GuardaValores alteraX(int novoX) {
        x = novoX;
        return new GuardaValores(x, y);
    }

    public GuardaValores alteraY(int novoY) {
        y = novoY;
        return new GuardaValores(x, y);
    }

    @Override
    public boolean equals(Object another) {
        if (another instanceof GuardaValores otherValidValue) {
            return this.x == otherValidValue.x && this.y == otherValidValue.y;
        }
        return false;
    }
}
```

Aqui nós obtemos a seguinte mensagem de erro agora:

```
org.opentest4j.AssertionFailedError: Verificou que `GuardaValores` é de fato imutável? ==> expected: <0> but was: <4>
```

Esse foi um exemplo bobinho de código que não precisaria nem de testes para
existir, já que o Java tem uma ferramenta própria para lidar com tipos com
valores imutáveis:

```java
public record GuardaValores(int x, int y) {

    public GuardaValores alteraX(int novoX) {
        return new GuardaValores(novoX, y);
    }

    public GuardaValores alteraY(int novoY) {
        return new GuardaValores(x, novoY);
    }
}
```

> Inclusive o teste continuar compilando e resultando em "deu bom" depois dessa
> alteração, como esperado.

O `assertEquals` está acessível como um método estático da classe
`org.junit.jupiter.api.Assertions`. Inclusive é comum encontrar códigos que
colocam logo a importação de todas as asserções padrões do JUnit:

```java
import static org.junit.jupiter.api.Assertions.*;
```

Isso facilita pois assim você tem acesso a toda a gama de asserções no
auto-complete da IDE facilmente. Dentre essas asserções, algumas que eu
considero bastante úteis:

- `assertTrue`: verifica se um valor é verdadeiro, como a saída de um método;
  por exemplo:  
  ```java
  assertTrue(isBigger(5, 3));
  ```
- `assertFalse`: mesma coisa que o `assertTrue`, mas que agora deu false;
  mesmos casos de uso
- `assertEquals`: dois objetos são iguais na visão do Java (ie,
  `Objects.equals(a, b)` retornaria true); por exemplo:  
  ```java
  final var pares = IntStream.range(1, 8)
        .filter(i -> i % 2 == 0)
        .boxed()
        .toList();
  assertEquals(List.of(2, 4, 6), pares);
  ```
- `assertNotEquals`: basicamente o `Objects.equals(a, b)` dá falso
- `assertSame`: aqui a garantia é que os ambos os objetos compartilham a mesma
  identidade; ou seja, `a == b`
- `assertNotSame`: o inverso, que não são a mesma identidade; posso usar no
  exemplo do objeto imutável, que após chamar o `alteraX` foi criado um novo
  objeto:  
  ```java
  final var primeiroValor = new GuardaValores(0, 0);
  final var segundoValor = primeiroValor.alteraX(2);

  assertNotSame(primeiroValor, segundoValor, "instâncias deveriam ser distintas");
  ```
- `assertDoesNotThrow`: garante que o código executado rodou sem nenhuma
  exceção sendo lançada para fora:  
  ```java
  assertDoesNotThrow(() -> {
      Integer x = null;
      Integer y = x + 2; // teste vai falhar
  });
  ```
- `assertThrows`: lançou a exceção indicada como esperada:  
  ```java
  assertThrows(NullPointerException.class, () -> {
      Integer x = null;
      Integer y = x + 2;
  });
  ```
- `assertNull`/`assertNotNull`: auto explicativos, verificam se o objeto
  passado é nulo

A convenção, quando precisa comparar dois valoes, é colocar o valor de
comparação base do lado esquerdo, o obtido do lado direito, e se tiver uma
mensagem ainda colocar depois de tudo. A mensagem pode ser uma string literal
ou então algo que produza a string sob demanda:

```java
final var primeiroValor = new GuardaValores(0, 0);
final var segundoValor = primeiroValor.alteraX(2);
assertNotSame(primeiroValor, segundoValor, () -> "instâncias %s/%s deveriam ser distintas".formatted(primeiroValor, segundoValor));
```

Uma outra convenção de testes é que você anota métodos que estão no escopo de
`package-protected`. A anotação `@Test` falha em métodos privados. Além do
escopo de testes, também é convenção colocar esses métodos em uma classe, e que
essa classe também seja `package-protected`. Se você precisar acessar métodos
de uma classe de teste em outro lugar, primeiro você pensa nas escolhas que fez
na sua vida porque não deveria fazer isso. Mas se não restou outra alternativa,
coloque o escopo adequado, seja `protected` ou `public`.

Mas normalmente nesse tipo de situação é melhor colocar essas funções em
classes auxiliares de teste.

# Guia geral para design de testes

No geral, um padrão muito útil para testes é o chamada AAA:

- arrange
- act
- assert

Esse padrão vai garantir que você primeiro define os seus dados (seção
"arrange"). Então, com os dados em mãos, você vai fazer um conjunto de ações
(seção "act"). E por fim, vai verificar se os efeitos colaterais seguiram como
planejados e os resultados obtidos eram os esperados (seção "assert").

No caso, efeitos colaterais normalmente são determinados através de quais
chamadas foram feitas para outros componentes. Muito usado com mocks, dá uma
olhada ali no
[Quando o mock mocka o mockador]({% post_url 2024/2024-03-08-mock-mocks-mocker %})
que lá eu explico um pouquinho sobre o que é um mock e forneço referências.

Normalmente um código de teste tem uma carga cognitiva menor do que o código de
produção. Por que isso? Para manter ele fácil de ler, assim a manutenção feita
nele e a carga cognitiva para os testes são mínimos.

Vamos pegar aqui o exemplo do `GuardaValores`. A primeira coisa que fiz foi
determinar o meu valor. A seção de _arrange_  do teste foi essa:

```java
final var primeiroValor = new GuardaValores(0, 0);
```

As ações que eu tomei foi chamar o `alteraX` e o `alteraY`:

```java
final var segundoValor = primeiroValor.alteraX(2);
final var terceiroValor = primeiroValor.alteraY(2);
```

E a aferição? Bem, aqui é simples: o valor da soma de `x` e `y` do meu objeto
inicial é 0 e também que `segundoValor` e `terceiroValor` são objetos distintos
entre si e também distintos do `primeiroValor`:

```java
assertEquals(0, primeiroValor.x() + primeiroValor.y(), "Verificou que `GuardaValores` é de fato imutável?");
assertNotSame(primeiroValor, segundoValor, () -> "instâncias %s/%s deveriam ser distintas".formatted(primeiroValor, segundoValor));
assertNotSame(segundoValor, terceiroValor);
```

De modo geral, um código de teste bem montado é só isso. As ações são um
conjunto fixo de coisas a se fazer, então normalmente não tem necessidade de
elas estarem em um `if` ou em um looping (exceto se for necessário fazer uma
repetição de ação mesmo).

Muitas vezes é bem trabalhoso gerar os valores da fase _arrange_, e normalmente
dependências entre diversos objetos e seu emaranhado único atrapalha ainda
mais. Para resolver isso, você pode isolar essa fase em uma caixa preta, o que
muitos chamam de um padrão de projeto
[Object Mother](https://martinfowler.com/bliki/ObjectMother.html). Você monta
o objeto e a teia de objetos nessa "mãe", e com isso consegue trabalhar melhor,
isolando a complexidade de instanciação do teste em si.

## Setup e teardown

É comum precisar tomar algumas ações antes de começar um teste. Por exemplo,
você pode querer usar um SQLite para rodar seus testes. Para isso, precisaria
rodar o `flyway` para criar o banco bem bonitinho. Por que não, né?

Nesse tipo de situação, você faz o setup do ambiente. Existe um setup feito
antes de todo e qualuqer teste ser feito, e outro que pode ser feito teste a
teste de modo individual.

Para fazer isso, basta anotar com `@BeforeEach` um método (seguindo as
convenções, um método `package-protected`) que garante a execução antes de
qualquer teste individual; ou o `@BeforeAll` em um método estático, que será
executado apenas uma única vez para todos os testes.

As vezes, o setup significa deixar uma sujeira na máquina. O SQLite pode rodar
em memória, então o teardown dele seria só desconectar ele de um path
específico (que normalmente é dedicada ao nome do arquivo, exceto se nesse path
tiver `:memory:`). Mas nem sempre é assim.

As vezes você precisa levantar um container (dá uma olhada em
[`Testcontainers`](https://testcontainers.com/)). O que seria o teardown disso?
Exatamente: matar o container que eu levantei para fazer um teste. A parte de
se desfazer dos efeitos colaterais você pode anotar com `@AfterEach` e
`@AfterAll`, de acordo com a sua necessidade.

# Testes parametrizados

Se você tem métodos muito semelhantes, idênticos exceto por parâmetros, você
pode anotar com `@ParameterizedTest`. Para passar os parâmetros, você deve
fornecer um modo dele resgatar os valores. Particularmente eu gostei muito do
`@MethodSource("nomeMetodo")` quando vi:

```java
@ParameterizedTest
@MethodSource("fonteDosArgs")
void umTeste(String primeiro, Optional<String> segundo, boolean terceiro) {
}

private static Stream<Arguments> fonteDosArgs() {
  return Stream.of(
        Arguments.of("um valor", Optional.empty(), true),
        Arguments.of(null, Optional.of("123"), true)
    );
}
```

E se eu receber apenas um único argumento para o teste? Meu `method source`
pode ser uma `Stream` do caso adequado, não precisaria ser um `Arguments` que
contém a exata quantidade de coisas que os parâmetros de um teste
parametrizado. Por exemplo:

```java
@ParameterizedTest
@MethodSource("fonteDosArgs")
void umNovoTeste(String forma) {
}

private static Stream<String> fonteDosArgs() {
  return Stream.of(
        "bola",
        "quadrado",
        "retangulo"
    );
}
```

O `@MethodSource` precisa se ligar a um método estático, necessariamente. É
interessante que ele retorne `Stream`, mas podem ser outras coisas.

Testes parametrizáveis tem o nome genérico do teste dado por `DisplayName` e
também uma descrição distinta para cada rodada do teste. Se quiser dar um nome
específico a como o teste é apresentado no console, só preencher o atributo
`ParameterizedTest#name`:

```java
@ParameterizedTest(name = """
          primeiro valor [{0}]
          segundo valor [{1}]
          terceiro valor [{2}]
            """)
@MethodSource("fonteDosArgs")
void umTeste(String primeiro, Optional<String> segundo, boolean terceiro) {
}

private static Stream<Arguments> fonteDosArgs() {
  return Stream.of(
        Arguments.of("um valor", Optional.empty(), true),
        Arguments.of(null, Optional.of("123"), true)
    );
}
```

Para situações de testes com tipos mais simples de variáveis, você pode anotar
diretamente o argumento e seus valores, sem precisar incorrer em indireção tão
grande. Por exemplo, se você precisa fornecer inteiros:

```java
@ValueSource(ints = {0, 1, 2, 3, 5, 8, 13})
@ParameterizedTest
void testeComNumeros(int valor) {
}
```

Outros argumentos possíveis para a anotação `@ValueSource` são:

- booleans
- longs
- strings

Por motivos, não pode passar nulo na lista, nem para string.

# Mockando métodos estáticos

Se você está pensando em fazer mock de métodos estáticos: PARE E PENSE NAS
ESCOLHAS DA SUA VIDA.

Dito isso, as vezes você precisa da gambiarra...

Eu precisei das seguintes dependências:

- org.junit.jupiter:junit-jupiter-api:5.9.0
- org.mockito:mockito-core:5.2.0
- org.mockito:mockito-inline:5.2.0

Vamos trabalhar em cima da classe `Marmota`:

```java
class Marmota {
    static String hello(String world) {
        return "hello " + world;
    }

    static void nada() {
        System.out.println("nada aqui");
        consta();
        throw new RuntimeException();
    }

    static void consta() {
        System.out.println("certidão negativa");
    }
}
```

Você precisa invocar o método `Mockito.mockStatic` e passar para ele uma
classe. Por exemplo, para mockar os métodos estáticos da classe Marmota:

```java
MockedStatic<Marmota> mock = mockStatic(Marmota.class);
```

Para liberar o que foi interceptado e alterado para o mock estático, você
precisa garantidamente liberar os recursos do mock criado. Você deve fazer
isso usando `try-with-resources`:

```java
try (MockedStatic<Marmota> mock = mockStatic(Marmota.class);) {
  // seu teste aqui
}
```

A priori, mockar os métodos estáticos vai fazer TODOS os métodos fazerem nada.

Diferente do mockito tradicional que tem o verify estático, para inspecionar os
métodos chamados do mock estático você precisa chamar o verify do objeto
retornado pelo mockStatic. E por algum motivo precisa passar um lambda
Verification (não recebe parêmtros). Por exemplo:

```java
try (MockedStatic<Marmota> mock = mockStatic(Marmota.class);) {
  Marmota.hello("world");
  mock.verify(() -> Marmota.hello("world"), times(1));
}
```

Para fazer algo, você pode chamar o `mock.when`:

```java
try (MockedStatic<Marmota> mock = mockStatic(Marmota.class);) {
  String x = Marmota.hello("world");
  assertNull(x);

  mock.when(() -> Marmota.hello(anyString())).thenReturn("mama mia");

  String y = Marmota.hello("world");
  assertEquals("mama mia", y);
}
```

Você pode pedir para ele chamar o método real também com `mock.thenCallRealMethod()`

```java
try (MockedStatic<Marmota> mock = mockStatic(Marmota.class);) {
  mock.when(() -> Marmota.nada()).thenCallRealMethod();
  assertThrows(RuntimeException.class, () -> Marmota.nada());
}
```

Aqui o método `real` nada foi chamado, mas não o `consta`, já que só foi pedido
para chamar o método real apenas de nada. Se for olhar a saída padrão dessa
chamada, teremos apenas o seguinte:

```txt
nada aqui
```

O mock pode ser feito para acessar transitivamente um método, basta pedir para
que ele funcione (seja indicando o retorno com o `.then`, seja com chamar o
método real com `thenCallRealMethod`:

```java
try (MockedStatic<Marmota> mock = mockStatic(Marmota.class);) {
  mock.when(() -> Marmota.nada()).thenCallRealMethod();
  mock.when(() -> Marmota.consta()).thenCallRealMethod();
  assertThrows(RuntimeException.class, () -> Marmota.nada());
}
```

O produzido foi:

```
nada aqui
certidão negativa
```

# Extensões do JUnit

Sabe o mockito? Para adicionar o mockito no JUnit, pra ele pegar tudo que
anotei como `@Mock` na classe de testes e injetar as informações, uma das
alternativas é chamar a extensão do mockito para JUnit. O código fica assim:

```java
@ExtendWith(MockitoExtension.class)
class MockitoAnnotationUnitTest {

    @Mock
    List<String> mockedValues;

    // ...
}
```

> Exemplos de código pegues
> [desse aritgo do Baeldung](https://www.baeldung.com/mockito-annotations).

Sabe como funciona o `@ExtendWith`? Basicamente chamando as extensões anotadas.
O `@Testcontainer` é uma anotação própria que faz basicamente a mesma coisa que
o `@ExtendEith(TestcontainersExtension.class)`, pode olhar
[no fonte](https://github.com/testcontainers/testcontainers-java/blob/main/modules/junit-jupiter/src/main/java/org/testcontainers/junit/jupiter/Testcontainers.java).

E, bem, sobre extensões... basicamente você cria sua própria extensão
implementando a interface adequada. Por exemplo, eu criei uma extensão simples:
para quando houver um disparo de exceção inesperado, se for uma má configuráção
do Jigsaw, eu imprimo uma mensagem indicando ao usuário como corrigir essa
questão.

Como fiz? Bem, primeiro foi definir qual o tipo de extensão. No meu caso foi
`AfterTestExecutionCallback`. Você pode ler mais a respeito das extensões na
[documentação oficial](https://junit.org/junit5/docs/current/api/org.junit.jupiter.api/org/junit/jupiter/api/extension/Extension.html).
A partir disso, peguei o `ExtensionContext` e analisei o que foi lançado,
procurando por sinais de que a exceção lançada foi relacionada a problema do
Jigsaw.

A extensão segue abaixo:

```java
class WarnAboutAddOpen implements AfterTestExecutionCallback {

    @Override
    public void afterTestExecution(ExtensionContext context) {
        context.getExecutionException()
            .filter(e -> e instanceof IllegalAccessError || e instanceof NoClassDefFoundError && e.getCause() instanceof ExceptionInInitializerError)
            .map(e -> e instanceof IllegalAccessError? e.getMessage(): e.getCause().getMessage())
            .filter(msg -> msg.contains("in unnamed module"))
            .ifPresent(e -> System.err.println("Have you added the correct exports as VM options? --add-exports <module>/<pkg>=ALL-UNNAMED"));
    }
}
```

E na classe que era executado o teste adicionei a extensão correspondente:

```java
@ExtendsWith(WarnAboutAddOpen.class)
class SomethingUsefulTest {
    // ...
}
```

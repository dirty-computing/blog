---
layout: post
title: "Mock static inserido via `@Mock` vaza?"
author: "Jefferson Quesado"
tags: java mock mockito junit
base-assets: "/assets/static-mock-leak-mock-field/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Sim, eu sei, toda vida que você faz mock de método estático
[uma fadinha morre]({% post_url 2024/2024-03-08-mock-mocks-mocker %})...

Mas eu tive uma situação bem particular no trabalho. Eu refatorei um pacote
para isolar uma dependência externa indesejada... e com isso em uma vez ao
rodar os testes no CI a pipeline carregou o classpath de teste em uma ordem
diferente (aleatoriamente, claro, não determinístico) carregou uma classe de
teste que fazia o mock de um método estático e então carregou uma outra classe
de teste que claramente esperava que o método estático retornasse dados
reais... e aí claramente que um 0 ou um `null` era um valor inválido no
contexto e quebrou com uma exceção maluca.

# Recriando a falha

Bem, eu não posso depender da ordem de carregamento de classes no classpath se
eu quiser reproduzir de modo garantido a falha, né? Então, vamos criar testes
aninhados?

Primeiro, vamos ter nossa classe para mockar o valor:

```java
public class Util {

    static boolean alt = false;
    public static String marm() {
        return alt? "hmmmm": "mota";
    }
}
```

Ok, agora vamos matar uma fadinha inocente e mockar o método estático?
Primeiro, usando a técnica clássica de mock com `try-with-resources` (tal qual
feito
[neste post]({% post_url 2025/2025-04-24-junit-mockito-notas-pessoais %})):

```java
public class MockTest {

    @Test
    void t() {
        try (MockedStatic<Util> mock = mockStatic(Util.class);) {
            mock.when(() -> Util.marm()).thenReturn("MARMOTAAAAA");
            assertEquals("MARMOTAAAAA", Util.marm());
        }
    }
}
```

Show! Agora temos aqui uma situação em que o mock estático está funcionando.
Próximo passo: ficar independente do classloader!

No JUnit, eu posso adicionar testes "aninhados" com `@Nested`. Então, posso
adicionar uma quantidade arbitrária de testes em um único arquivo! Então, vamos
adicionar um teste para o retorno mockado e outro para o retorno esperado?
Primeiro vamos fazer direito, e depois vamos fazer vazando:

```java
public class MockTest {

    @Nested
    class C1 {

        @Test
        void t() {
            try (MockedStatic<Util> mock = mockStatic(Util.class);) {
                mock.when(() -> Util.marm()).thenReturn("MARMOTAAAAA");
                assertEquals("MARMOTAAAAA", Util.marm());
            }
        }
    }

    @Nested
    class C2 {

        @Test
        void t() {
            assertEquals("mota", Util.marm());
        }
    }
}
```

Ok, os dois testes funcionaram sem problemas. Agora... vamos adicionar o
problema? Simplesmente remover o `try-with-resources` vai causar o vazamento!

```java
public class MockTest {

    @Nested
    class C1 {

        @Test
        void t() {
            MockedStatic<Util> mock = mockStatic(Util.class);
            mock.when(() -> Util.marm()).thenReturn("MARMOTAAAAA");
            assertEquals("MARMOTAAAAA", Util.marm());
        }
    }

    @Nested
    class C2 {

        @Test
        void t() {
            assertEquals("mota", Util.marm());
        }
    }
}
```

Hmmm, não vazou. Mas, o que ocorreu de errado? Bem, executei pelo IntelliJ e
ele me deu esse relatório:

![MockTest: C2 OK, C1 OK]({{ page.base-assets | append: "mock-c2-c1-ok.png" | relative_url }})

Ele carregou de baixo pra cima...? E se eu adicionar um `C0`  antes do `C1`?

```java
public class MockTest {

    @Nested
    class C0 {

        @Test
        void t() {
            assertEquals("mota", Util.marm());
        }
    }

    @Nested
    class C1 {

        @Test
        void t() {
            MockedStatic<Util> mock = mockStatic(Util.class);
            mock.when(() -> Util.marm()).thenReturn("MARMOTAAAAA");
            assertEquals("MARMOTAAAAA", Util.marm());
        }
    }

    @Nested
    class C2 {

        @Test
        void t() {
            assertEquals("mota", Util.marm());
        }
    }
}
```

Ok, agora a única chance de não detectar um vazamento é se o IntelliJ resolver
carregar com o JUnit o `C1` apenas no final. Vamos ver se isso vai ocorrer?

![MockTest: C2 OK, C1 OK, C0 X]({{ page.base-assets | append: "mock-c2-c1-c0-fail.png" | relative_url }})

Show! Falhou! Falhou como a gente queria?

```
org.opentest4j.AssertionFailedError: 
Expected :mota
Actual   :MARMOTAAAAA
```

FALHOU COMO QUERIA!!! Agora eu tenho uma detecção do vazamento!

Foram feitos mais testes que ficariam muito sacais recolocar aqui no post,
então como um resumo: o meu IntelliJ carregava os testes das classes `@Nested`
sempre de baixo para cima, ignorando o nome das classes em si.

Sobre a recriação da falha: eu recriei especificamente o vazamento do mock
estático, não exatamente que ele iria retornar nulo. Recriar o retorno nulo
seria simplesmente não colocar o `mock.when(() -> ...).thenReturn(...)`. Mas
o jeito que foi escrito é suficiente para detectar vazamentos, o que é minha
intenção.

# Injeção de `@Mock`

Uma estratégia clássica para evitar o trabalho de criar mocks na mão é usar a
anotação `@Mock` nos testes, em classes que estão anotadas com a extensão do
JUnit `@ExtendWith(MockitoExtension.class)`. Basicamente ele facilita a criação
do objeto mockado. Por exemplo:


```java
@ExtendWith(MockitoExtension.class)
public class SampleMockTest {
    
    @Mock
    Supplier<String> aaah;
    
    @Test
    void t() {
        assertNull(aaah.get());
    }
}
```

Viu como não foi inicializado nada no `aaah`? E eu simplesmente pude chamar
ele, indicando claramente que o objeto existe ali. Isso se dá porque a extensão
do Mockito injetou o mock corretamente.

Uma das coisas que o Mockito fornece com testes mais rígidos (o padrão) é bater
na cabeça de quem mocka as coisas mas o mock não é usado:

```java
@ExtendWith(MockitoExtension.class)
public class SampleMockTest {
    
    @Mock
    Supplier<String> aaah;
    
    @Test
    void t() {
        when(aaah.get()).thenReturn("123");
        // assertNull(aaah.get());
    }
}
```

Isso dá o erro:

```
org.mockito.exceptions.misusing.UnnecessaryStubbingException: 
Unnecessary stubbings detected.
Clean & maintainable test code requires zero unnecessary code.
Following stubbings are unnecessary (click to navigate to relevant line of code):
  1. -> at com.jeffque.SampleMockTest.t(SampleMockTest.java:23)
Please remove unnecessary stubbings or use 'lenient' strictness. More info: javadoc for UnnecessaryStubbingException class.
```

# Injeção de `@Mock` vaza mock estático?

Bem, sobre o vazamento do mock estático, chegou um ponto no trabalho que foi
levantado o questionamento: se o `MockedStatic<Util>` for gerado pelo `@Mock`,
isso vai causar o vazamento não intencional?

O cenário do teste que gerou o vazamento do `MockedStatic` específico realmente
foi um `MockedStatic` gerado no corpo de uma função marcada com `@BeforeAll`
(ou seja, executado no começo do começo do teste específico). Esse cenário a
intenção aparente de quem escreveu o teste era que o método estático ficasse
mockado daquele ponto em diante para aquele teste INTEIRO, e que fosse
carregado de modo a impactar na carga de outras classes no classloader.
Portanto... talvez usar `try-with-resources` não fosse adequado para o cenário
de teste que o autor original estava prevendo.

Além disso, no teste específico que vazou o mock estático, existem cerca de
1500 linhas de código, o que é além da minha intenção de ter domínio para fazer
uma correção profunda. E nesse teste específico já existiam 11 mocks estáticos
injetados com `@Mock`. E claro que o ponto que era usado em outro teste era a
décima segunda classe mockada...

Meus colegas propuseram transformar tudo em `try-with-resources`, o que
causaria mudanças extensas nesse arquivo de teste e sem falar na alteração de
ordem de carregamento, o que talvez implicasse em comportamentos anômalos para
os mocks (afinal, mockar estático é matar fadinhas, e muitos sacrifícios de
fadas foram feitos nessas 1500 linhas). Já o meu instinto de "play-safe" era
fazer o mínimo de alterações necessárias para o funcionamento.

## As alterações mínimas

Para funcionar com as alterações mínimas, preciso que o mock estático criado no
`@BeforeAll` fique armazenado em uma variável estática para que possa ser
liberado em um `@AfterAll`. O valor continuaria sendo criado no lugar correto,
mas ele não seria armazenado apenas na stack da função, mas sim no campo
estático.

Porém isso tem um pressuposto: NÃO HÁ VAZAMENTO de mock estático.

## Montando o cenário de teste

Vamos resgatar o `MockTest`:

```java
public class MockTest {

    @Nested
    class C0 {

        @Test
        void t() {
            assertEquals("mota", Util.marm());
        }
    }

    @Nested
    class C1 {

        @Test
        void t() {
            try (MockedStatic<Util> mock = mockStatic(Util.class);) {
                mock.when(() -> Util.marm()).thenReturn("MARMOTAAAAA");
                assertEquals("MARMOTAAAAA", Util.marm());
            }
        }
    }

    @Nested
    class C2 {

        @Test
        void t() {
            assertEquals("mota", Util.marm());
        }
    }
}
```

Vamos transformar agora a carga do `MockedStatic` em uma injeção com `@Mock`?
Para isso, a preparação do mock vai ser colocada em um `@BeforeEach` só para
isolar o setup do teste propriamente dito:


```java
@ExtendWith(MockitoExtension.class)
public class MockTest {

    @Nested
    class C0 {

        @Test
        void t() {
            assertEquals("mota", Util.marm());
        }
    }

    @Nested
    class C1 {

        @Mock
        private MockedStatic<Util> mock;

        @BeforeEach
        void b() {
            mock.when(() -> Util.marm()).thenReturn("MARMOTAAAAA");
        }

        @Test
        void t() {
            assertEquals("MARMOTAAAAA", Util.marm());
        }
    }

    @Nested
    class C2 {

        @Test
        void t() {
            assertEquals("mota", Util.marm());
        }
    }
}
```

Com resultados:

![MockTest: C2 OK, C1 OK, C0 OK]({{ page.base-assets | append: "mock-c2-c1-c0-ok.png" | relative_url }})

Isso significa que não houve vazamentos, confere? A gente pode adicionar uns
testes a mais para refinar que não tem problemas, né?

```java
@ExtendWith(MockitoExtension.class)
public class MockTest {

    @Nested
    class C0 {

        @Test
        void t() {
            assertEquals("mota", Util.marm());
        }
    }

    @Nested
    class C1 {

        @Mock
        private MockedStatic<Util> mock;

        @BeforeEach
        void b() {
            mock.when(() -> Util.marm()).thenReturn("MARMOTAAAAA");
        }

        @Test
        void t() {
            assertEquals("MARMOTAAAAA", Util.marm());
        }
    }

    @Nested
    class C2 {

        @Mock
        private MockedStatic<Util> mock;

        @BeforeEach
        void b() {
            mock.when(() -> Util.marm()).thenReturn("teste teste");
        }

        @Test
        void t() {
            assertEquals("teste teste", Util.marm());
        }
    }
}
```

Ok, deu certo. Os dois mocks deram certo. E se... eu vazar os mocks no modo
clássico? Crio o `MockedStatic` na stack da função e deixo ela vazar?

```java
@ExtendWith(MockitoExtension.class)
public class MockTest {

    @Nested
    class C0 {

        @Test
        void t() {
            assertEquals("mota", Util.marm());
        }
    }

    @Nested
    class C1 {

        @BeforeEach
        void b() {
            MockedStatic<Util> mock = mockStatic(Util.class);
            mock.when(() -> Util.marm()).thenReturn("MARMOTAAAAA");
        }

        @Test
        void t() {
            assertEquals("MARMOTAAAAA", Util.marm());
        }
    }

    @Nested
    class C2 {

        @BeforeEach
        void b() {
            MockedStatic<Util> mock = mockStatic(Util.class);
            mock.when(() -> Util.marm()).thenReturn("teste teste");
        }

        @Test
        void t() {
            assertEquals("teste teste", Util.marm());
        }
    }
}
```

![MockTest: C2 OK, C1 ERROR, C0 FALHA]({{ page.base-assets | append: "mock-c2-c1-err-c0-fail.png" | relative_url }})

Ok, falhou de mais modos do que eu imaginava... vamos ver os erros?

Erro em `C1`:

```
org.mockito.exceptions.base.MockitoException: 
For com.jeffque.Util, static mocking is already registered in the current thread

To create a new mock, the existing static mock registration must be deregistered

	at com.jeffque.MockTest$C1.b(MockTest.java:34)
	at java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(DirectMethodHandleAccessor.java:103)
	at java.base/java.lang.reflect.Method.invoke(Method.java:580)
	at org.junit.platform.commons.util.ReflectionUtils.invokeMethod(ReflectionUtils.java:727)
	at org.junit.jupiter.engine.execution.MethodInvocation.proceed(MethodInvocation.java:60)
	at org.junit.jupiter.engine.execution.InvocationInterceptorChain$ValidatingInvocation.proceed(InvocationInterceptorChain.java:131)
	at org.junit.jupiter.engine.extension.TimeoutExtension.intercept(TimeoutExtension.java:156)
	at org.junit.jupiter.engine.extension.TimeoutExtension.interceptLifecycleMethod(TimeoutExtension.java:128)
```

Erro em `C0`:

```
org.opentest4j.AssertionFailedError: 
Expected :mota
Actual   :teste teste
```

No caso do erro de `C0`, é apenas o vazamento comum. O mock estático preparado
em `C2` não é o resultado esperado. Em `C1`, o setup falhou miseravelmente
ainda no nível de rodar _antes_ do teste: _To create a new mock, the existing
static mock registration must be deregistered_.

## Conclusão

Não é simples vazar o `@Mock`. Quando criado, o próprio Mockito dá um jeito de
desmontar ele. E no caso de `@Mock MockedStatic<T>`, o Mockito sabe que
desmontar esse objeto é dar um `.close()` para liberar as mudanças realizadas
no classloader.

Então, respondendo a questão: não, não é possível vazar um `MockedStatic<T>` ao
se usar o `@Mock`.

# O código em questão

O código que tinha erro continha _diversos_ `@Mock` com `MockedStatic<T>`. Mas
como vimos nos cenários de teste: esses mocks estáticos não vazam. Mas o teste
em questão tinha um ponto (claro, para a codebase em questão):

```java
@BeforeAll
static void setup() {
    MockedStatic<Util> mock = mockStatic(Util.class);
    mock.when(() -> Util.marm()).thenReturn("teste teste");
}
```

E isso era de uma classe que seria utilizada em uma inicialização estática de
uma classe. E para deixar tudo mais intrigante: o método que gerava a derradeira
falha _não era_ o que estava sendo mockado, mas sim um outro nada a ver que
retornava um inteiro, cujo valor de uso deveria ser _sempre_ maior do que 1. E
o valor padrão para ausência de valores para inteiro primitivo? Zero. Todos os
bits zerados. De modo semelhante ao valor padrão para um tipo referência ser
sempre `null`.

E como as coisas são sempre bem emboladas: a classe que geraria o erro não é
carregada, nem direta nem indiretamente, no teste que está preparando o mock
estático.

## Solução preguiçosa?

O primeiro pensamento é colocar como `@Mock MockedStatic<T>`. Porém... bem...
essa variável estava sendo preparada em um `@BeforeAll`, que é carregado junto
da classe, antes de se ter instância dela.

Como não se tinha ideia do caso de uso para o mock sendo realizado, e já se era
sabido que as alterações nessa classe sendo mockada tinha como efeito possível
mudar comportamento de classe sendo carregada, injetar ela como um `@Mock` de
instância poderia não ter o possível efeito adequado.

Por sinal, existe a possibilidade de se fazer `static @Mock MockedStatic<T>`, e
isso se comporta da maneira esperada: ele cria um mock diferente para cada
teste sendo executado:

```java
 @Nested
class C2 {
    
    static @Mock MockedStatic<Util> mock;

    @BeforeEach
    void b() {
        System.out.println("before " + System.identityHashCode(mock));
        mock.when(() -> Util.marm()).thenReturn("teste teste");
    }

    @Test
    void t1() {
        System.out.println("test " + System.identityHashCode(mock));
        assertEquals("teste teste", Util.marm());
    }

    @Test
    void t2() {
        System.out.println("test " + System.identityHashCode(mock));
        assertEquals("teste teste", Util.marm());
    }
}
```

Output:

```none
before 238467882
test 238467882
before 1904273153
test 1904273153
```

E mais legal ainda: ao tentar usar com `@BeforeAll`:

```java
@BeforeAll
static void b() {
    mock.when(() -> Util.marm()).thenReturn("teste teste");
}
```

Tenho um clássico null pointer exception!

```txt
java.lang.NullPointerException: Cannot invoke "org.mockito.MockedStatic.when(org.mockito.MockedStatic$Verification)" because "com.jeffque.MockTest$C2.mock" is null
```

Ou seja: essa solução vai interferir o como que o carregamento dessa classe
sendo mockada influencia em como outras classes sendo carregas pelo class
loader.

Eu resolvo a questão de vazar o mock, mas não garanto que os efeitos colaterais
desejados de mockar esse valor está realmente ocorrendo como deveria.

## Solução com mínimo de mudanças

Para manter o mínimo de mudanças, o mock estático deveria sim acontecer no
mesmo momento. Porém, para lidar com o "fechamento" correto do teste, preciso
dar um `close()` no mock. Para fazer isso, preciso da referência ao
`MockedStatic`, para então no `@AfterAll` poder chamar o método correto. Logo:

```java
// variável criada
private static MockedStatic<Util> utilMocked;

@BeforeAll
static void setup() {
    // MockedStatic<Util> utilMocked = mockStatic(Util.class); <-- só resquícios do código original
    utilMocked = mockStatic(Util.class);
    utilMocked.when(() -> Util.marm()).thenReturn("teste teste");
}

// adicionando o fechamento
@AfterAll
static void teardown() {
    utilMocked.close();
}
```

Pronto, agora o ciclo de vida da classe mockada continua sendo exatamente o
mesmo que se tinha para o teste. Porém, com uma diferença: ela não vaza mais!
Porque estou fechando ela no `teardown`.

Mas... vou ser sincero. A coisa... era mais feia... Porque não era só uma
classe sendo mockada estática assim. Eram duas!! E as duas vazavam da mesma
maneira! Logo, a solução seria isso, certo?

```java
// variáveis criada
private static MockedStatic<Util> utilMocked;
private static MockedStatic<Util2> util2Mocked;

@BeforeAll
static void setup() {
    // MockedStatic<Util> utilMocked = mockStatic(Util.class); <-- só resquícios do código original
    utilMocked = mockStatic(Util.class);
    utilMocked.when(() -> Util.marm()).thenReturn("teste teste");


    // MockedStatic<Util2> util2Mocked = mockStatic(Util2.class); <-- só resquícios do código original
    util2Mocked = mockStatic(Util2.class);
    util2Mocked.when(() -> Util2.marm()).thenReturn("teste teste");
}

// adicionando o fechamento
@AfterAll
static void teardown() {
    util2Mocked.close();
    utilMocked.close();
}
```

Hmmm, na real? Não. Porque podem ter situações... absurdas... que podem ocorrer
em um `.close()`. Como por exemplo estourar exceção.

Eu espero que aconteçam? Não. Até porque a exceção documentada para isto
ocorrer é de tentar dar um `.close()` após um outro `.close()`. Mas aqui
estamos em um código que já deu problema por mal uso! Um problema bem chatinho
de detectar, mas já deu. Inserir um código com possível problema de detecção de
falha não estava nos meus planos.

Então, como podemos resolver isso? Que tal... criar um mecanismo para
fechamento de todas as classes abertas?

Pois bem, vamos lá! Uma solução seria simplesmente assumir que só existem esses
2 `MockedStatic<T>` que precisam ser criados assim e lidar com isso com
diversos `try-catch`:

```java
@AfterAll
static void teardown() {
    try {
        util2Mocked.close();
    } catch (Exception e) {
    }

    utilMocked.close();
}
```

Mas isso engole potencialmente o erro no primeiro `.close()`, e não queremos
isso. Portanto, precisamos dar um jeito de manter o erro e disparar ele no
final!

```java
@AfterAll
static void teardown() throws Exception {
    Exception thrownErr = null;
    try {
        util2Mocked.close();
    } catch (Exception e) {
        thrownErr = e;
    }

    try {
        utilMocked.close();
    } catch (Exception e) {
        thrownErr = e;
    }

    if (thrownErr != null) {
        throw thrownErr;
    }
}
```

Ainda podemos perder exceções? Sim, pois ambos os `.close()` podem lançar no
mesmo cenário! Então, qual o mecanismo que o Java fornece pra isso? Usar o
`.addSuppressed(e)`:

```java
@AfterAll
static void teardown() throws Exception {
    Exception thrownErr = null;
    try {
        util2Mocked.close();
    } catch (Exception e) {
        thrownErr = e;
    }

    try {
        utilMocked.close();
    } catch (Exception e) {
        if (thrownErr != null) {
            thrownErr.addSuppressed(e);
        } else {
            thrownErr = e;
        }
    }

    if (thrownErr != null) {
        throw thrownErr;
    }
}
```

Tá, isso ficou assimétrico... posso colocar umas coisinhas no primeiro `catch`
só pra ficar simétrico:

```java
@AfterAll
static void teardown() throws Exception {
    Exception thrownErr = null;
    try {
        util2Mocked.close();
    } catch (Exception e) {
        if (thrownErr != null) {
            thrownErr.addSuppressed(e);
        } else {
            thrownErr = e;
        }
    }

    try {
        utilMocked.close();
    } catch (Exception e) {
        if (thrownErr != null) {
            thrownErr.addSuppressed(e);
        } else {
            thrownErr = e;
        }
    }

    if (thrownErr != null) {
        throw thrownErr;
    }
}
```

Mesmo sendo óbvio (tenho até o warning "Condition `thrownErr != null` is always
`false`"), isso fica mais simétrico e repetido. E isso me leva a outro ponto!
Podemos expandir isso! Posso colocar em uma lista e iterar em cima disso:

```java
@AfterAll
static void teardown() throws Exception {
    Exception thrownErr = null;
    List<MockedStatic<?>> mocks = List.of(util2Mocked, utilMocked);

    for (final var mock: mocks) {
        try {
            mock.close();
        } catch (Exception e) {
            if (thrownErr != null) {
                thrownErr.addSuppressed(e);
            } else {
                thrownErr = e;
            }
        }
    }

    if (thrownErr != null) {
        throw thrownErr;
    }
}
```

Muito bom, agora isso seria um pedaço de código potencialmente reutilizável,
né? Se na base de códigos tivesse potencialmente mais vazamentos assim? Que
tal... fazer uma classe para isso? E também eu posso transformar isso em uma
função que retorna a exceção lançada e com isso fazer um `.reduce`, que tal?

Eu não sou fã de exceções, por isso me encanto tanto no jeito que Go lida com
os erros como valores. Então, vamos primeiro lidar com essa questão das
exceções como valores e depois isolar em um componente reutilizável?

Eu tenho aqui a transformação de um `() -> void` em `Exception | null`.
Isso significa: pegar um `Runnable -> Exception | null`? Hmm, não no Java, pois
as exceções checadas precisam necessariamente passar na assinatura da função e
o `Runnable` não possui isso na assinatura. Então posso criar minha própria
interface funcional para ignorar o que está rodando por baixo:

```java
interface MayThrow {
    void action() throws Exception;
}
```

E com isso eu consigo fazer um mapeamento de `MayThrow -> Exception | null`:

```java
static Exception exceptionAsValue(MayThrow mt) {
    try {
        mt.action();
        return null; // foi tudo bem
    } catch (Exception e) {
        return e;
    }
}
```

E para fazer o reduce de exceções? Vamos supor que `exceptionAsValue` é um
método de `MayThrow`:

```java
List<MayThrow> l = List.of(mt1, mt2, mt3, ...);

final var e = l.stream()                // MayThrow
    .map(MayThrow::exceptionAsValue)    // Exception
    .reduce(null, (acc, el) -> {
        if (acc == null) {
            return el;
        }
        if (el == null) {
            return acc;
        }
        acc.addSuppressed(el);
        return acc;
    });
if (e != null) {
    throw e;
}
```

Ok, parece razoável. Agora, para tornar isso reutilizável... vamos criar uma
função que recebe muito `AutoCloseable`s? `closeAll`? Dentro de `MayThrow`, só
para deixar claro que talvez lance algo, mesmo fechando tudo...

E, bem. Que tal deixar resiliente contra nulos acidentais?

```java
static void closeAll(AutoCloseable ...closeables) throws Exception {
    final var e = Stream.of(closeables)
        .filter(Objects::nonNull)
        .map(ac -> (MayThrow) ac::close)
        .map(MayThrow::exceptionAsValue)
        .reduce(null, (acc, el) -> {
            if (acc == null) {
                return el;
            }
            if (el == null) {
                return acc;
            }
            acc.addSuppressed(el);
            return acc;
        });
    if (e != null) {
        throw e;
    }
}
```

Ok, e na hora de usar?

```java
// variáveis criada
private static MockedStatic<Util> utilMocked;
private static MockedStatic<Util2> util2Mocked;

@BeforeAll
static void setup() {
    // MockedStatic<Util> utilMocked = mockStatic(Util.class); <-- só resquícios do código original
    utilMocked = mockStatic(Util.class);
    utilMocked.when(() -> Util.marm()).thenReturn("teste teste");


    // MockedStatic<Util2> util2Mocked = mockStatic(Util2.class); <-- só resquícios do código original
    util2Mocked = mockStatic(Util2.class);
    util2Mocked.when(() -> Util2.marm()).thenReturn("teste teste");
}

// adicionando o fechamento
@AfterAll
static void teardown() throws Exception {
    MayThrow.closeAll(util2Mocked, utilMocked);
}
```

E foi essa a minha primeira proposta de correção! Antes do primeiro code review
em que propuseram trocar todos os campos `@Mock` por `try-with-resources`.
Afinal, código que não era meu, "play-safe".

## Anticlímax

Sabe o `utilMocked.when(() -> Util.marm()).thenReturn("teste teste");`? E o
`util2Mocked.when(() -> Util2.marm()).thenReturn("teste teste");`? Pois bem...

O teste funcionava do mesmo jeito, com ou sem o mock! Mesmo eventualmente se eu
prepara o mock estático e não utilizar ele, o mockito não reclama por ausência
de uso (diferente de um mock tradicional que, se eu mockar e não estiver em
modo leniente, reclama de "Unnecessary stubbings detected"). Então o mock não
estava sendo usado de modo algum no final das contas... a correção portanto foi
simplesmente apagar o método `@BeforeAll`.

O code review que recebi veio com uma reclamação sobre a complexidade do
`MayThrow`. Após inspecionar a codebase, esse vazamento de mock estático não
ocorria em nenhum outro lugar, todos os mocks estáticos estavam adequadamente
em um `try-with-resources` ou com o ciclo de vida controlado pelo `@Mock`.

Essa discussão sobre manter ou não o `MayThrow` acabou gerando a pergunta sobre
a necessidade de ter aquele método mockado ou não, mesmo o "play-safe" sendo
respeitado.

# Considerações sobre o code review

Na revisão, os meus colegas sugeriram usar o `try-with-resources` junto de cada
mock estático. E, sinceramente? Eles estavam certos, e isso seria realmente o
mais adequado a se fazer pela saúde do código.

Porém... aquele código não era de meu domínio. E eu queria tocar o mínimo
possível nele. Eu precisava apenas que ele não atrapalhasse os PRs das demais
equipes, como ele atrapalhou o meu PR uma vez. Mas pelo "play-safe" é melhor
deixar essa refatoração com quem deveria entender, com a equipe que realmente é
a dona do código.

Mas, por que agora estou dizendo que o `try-with-resources` é a alternativa
certa? Justamente por conta do estrago feito em classloader!

Quando você usa o `@Mock mockedStatic`, aquilo toma efeito a cada teste sendo
executado. Se, sem querer, você acaba sobrescrevendo uma classe que
eventualmente vai ser chamada no carregamento de outra classe, já era, a classe
que está sendo carregada vai ficar maculada com resquícios do mock. E usar o
`@Mock` é um alcance bem grande para esse problema acontecer.

Quando você usa o `try-with-resources`, o efeito já vai estar localizado dentro
do método de teste específico. Isso quer dizer que vai impedir todo e qualquer
problema relacionado a carga de classes? Não, não quer dizer isso. Mas a classe
que vai ser maculada já fica maculada logo naquele instante, você tem menos
oportunidades de macular as coisas de modo não intencional.

O `MayThrow.closeAll()` que eu fiz inclusive foi baseado em como eu creio que
funcione o `try-with-resources`, com lembranças de bytecode decompilado para
ver as entranhas de como o Java lidava com as muitas exceções possíveis, porém
de um jeito mais funcional.

Ah! Quase esqueci de mencionar, mas isso eu carrego sempre no meu coração, e
quero que você sempre se lembre disso: toda vida que você faz mock de método
estático uma fadinha morre. Só faça o mock estático se realmente ele for mais
necessário do que a vida de uma criatura mágica da natureza.

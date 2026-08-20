---
layout: post
title: "Como fazer callbacks em Java? Uma análise nas interfaces funcionais padrões"
author: "Jefferson Quesado"
tags: java fp
base-assets: "/assets/java-interfaces-funcionais-101/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Recebi uma chamada do Camilo
[@lixeletto.bsky.social](https://bsky.app/profile/lixeletto.bsky.social)
[clamando por socorro no BlueSky](https://bsky.app/profile/lixeletto.bsky.social/post/3ln4izmyi4k2bi):

> Javeires desse site, to tentando fazer um tipo pra um parâmetro de uma função
> Java que é um callback, se fosse Javascript eu faria uma interface ou type
> assim, no Java isso se faz com @FunctionalInterface?

Bem, isso significa que nosso amigo Camilo está perdido em callbacks no Java.
Bora ajudar ele?

# O callback simples

Vou fazer uma ação longa e depois preciso alertar o usuário que ela terminou.
Como que fazemos isso? Imagina que estamos no browser e que queremos lançar um
popup na melhor estética de alertas de site do começo dos anos 2000.

```js
async function doSomething(params) {
    //... código longo e complicado
}
```

O que precisamos nesse caso é algo que lance o alerta para o usuário no final
do processo. Poderia fazer isso aqui:

```js
await doSomething(myArgs);
alert('oie, a ação acabou e eu queria te avisar isso');
```

Tá, mas e sem `async`/`await` ou promises, como se faria isso? Basicamente
passando a ação para a função. Ficaria mais ou menos assim:

```js
// declaração
async function doSomething(params, callback) {
    //... código longo e complicado
    callback();
}

// uso
doSomething(myArgs, () => alert('oie, a ação acabou e eu queria te avisar isso'));
```

No mundo Java, como seria? Bem, a parte de uso seria bem semelhante:

```java
doSomething(myArgs, () -> Popup.alert("oie, a ação acabou e eu queria te avisar isso"));
```

considerando aqui um `Popup.alert(String)` como sendo a maneira correta de se
criar um alerta qualquer. Certo, mas tem algum outro exemplo? Na real, tem sim.
Inclusive muito semelhante a este.

Tome aqui o exemplo de _hello, world_ do [Express.js](https://expressjs.com/):

```js
const express = require('express')
const app = express()
const port = 3000

app.get('/', (req, res) => {
  res.send('Hello World!')
})

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
```

No exemplo ele simplesmente imprime no terminal que está levantado, mas isso
poderia ser feito para avisar ao sistema que o sistema está no ar, e então
começar a fazer o _tear-down_ da versão anterior na _fleet_. Ou então avisar
ao loadbalancer que tem mais um nó disponível e pronto para receber tráfego.

No Java, damos o nome de `Runnable` para a ação que simplesmente é executada.
Todo o contexto de um `Runnable` está dentro dele, ele não pode ser executado
de modo parametrizado. Voltando ao caso da função `doSomething`, ela ficaria
mais ou menos assim:

```java
void doSomething(Params params, Runnable callback) {
    //... código longo e complicado

    callback.run();
}
```

# Parâmetros

Ok, resolvida a questão de rodar um comando arbitrário. Agora, e se eu precisar
lidar com um evento? Que tal adicionar algo que seja disparado por um ecento de
clique?

O clique em si vai criar um evento de clique que é um objeto a ser consumido, e
em cima dessa informação eu posso tomar alguma ação. Podemos dizer que eu
vou... consumir... essa informação. Para isso, podemos usar o `Consumer<T>`:

```java
onClick(c -> System.out.prinln("clicou " + c));
```

Normalmente `Consumer`s vão reagir a algo que vai ser fornecido para ele. Um
exemplo clássico é o `forEach`, que permite tomar uma ação para cada elemento
de uma lista. Por exemplo:

```java
List.of("one", "two", "three").forEach(s -> System.out.println(s))
```

Se você precisa chamar um `Consumer<T>`, só usar o `accept`:

```java
private Consumer<String> changeState = s -> {}; // noop

public void addChangeStateListener(Consumer<String> changeState) {
    final var oldChangeState = this.changeState;
    this.changeState = newState -> {
        oldChangeState.accept(newState);
        changeState.accept(newState);
    };
}

public void doLongProcess() {
    this.changeState.accept("iniciando");
    // ...
    this.changeState.accept("fim");
}
```

Existe também a variação `BiConsumer`, que recebe 2 argumentos.

# Criação de dados

Existe também uma opção bem curiosa: no lugar de _consumir_ dados, a de
_produzir_ dados. Sim, como se estivesse tirando eles do nada, materializando
do ar. Por exemplo, quando queremos fazer uma computação postergada.

Para pegar exemplo de _computação postergada_, vamos recorrer rapidinho aqui ao
`Optional` do Java, que implementamos algo disso com `orElseGet` lá em
[Reinventando a roda: como escrever streams sem usar stream como base]({% post_url 2026/2026-05-06-reinventando-roda-java-streams %}).
A ideia do `orElseGet` é basicamente pegar um valor padrão caso o `Optional`
esteja vazio. Mas, veja... e se esse valor for computado? E se essa computação
for cara?

Para esse tipo de computação, quando queremos postergar ao máximo computar o
valor, de modo que só o computemos caso estritamente necessário. Não queremos
disperdiçar uma ida ao banco de dados só pra pegar um valor que talvez nem
iremos usar, né?

```java
Optional.of(pedido)
    .map(p -> p.getFrete())
    .orElseGet(() -> consultaValorFrete(pedido));
```

Outro caso de uso para computação postergada foi com trampolim, tanto em
[Trampolim, exemplo em Java]({% post_url 2023/2023-10-02-trampoline %}) quanto
no
[Trampolim para funções além do primitivo recursivo? Implementação para a função de Ackermann Peter]({% post_url 2024/2024-01-23-trampoline-ackermann-peter %}).
Nesses casos, o trampolim é justamente algo que se divide em "já computei" e
"ainda não computei, mas sei computar", e o laço principal do trampolim é
justamente lidando com isso:

```java
public static <IN, R> R trampoline(IN input,
                                   Function<IN, TrampolineStep<R>> trampolinebootStrap) {
  TrampolineStep<R> nextStep = trampolinebootStrap.apply(input);
  while (!nextStep.gotValue()) {
    nextStep = nextStep.runNextStep();
  }
  return nextStep.value();
}
```

Onde o `runNextValue` é simplesmente a resolução de um valor que pode computar
ou gerar outro valor a ser computado ainda:

```java
TrampolineStep<Integer> fib_trampoline(int a, int b, int i, int n) {
    if (i == n) {
        return TrampolineStep.valueFound(a);
    }
    return TrampolineStep.goonStep(() -> fib_trampoline(b, a+b, i+1, n));
}
```

Existem também outros motivos além de computação postergada para se usar essa
criação de dados a partir do nada: podemos ter uma fábrica de valores!

De novo, usamos isso lá no
[reinventando a roda]({% post_url 2026/2026-05-06-reinventando-roda-java-streams %}),
mas dessa vez aqui o foco ao coletar em uma lista: precisamos informar algo que
crie nosso container, como `() -> new ArrayList<>()`.

E também podemos ter uma espécie de abstração para uma espécie de iteração:
conforme for aparecendo valores, ele vai produzindo. Por exemplo, eu posso
querer pegar os primeiro 6 pedidos e produzo a média do seus fretes:

```java
Supplier<Pedido> s = ...;

double acc = 0;
for (int i = 0; i < 6; i++) {
    final var p = s.get();
    final var frete = Optional.of(p)
            .map(p -> p.getFrete())
            .orElseGet(() -> consultaValorFrete(p));
    acc += frete;
}
return acc/6;
```

Esse tipo de coisa a gente resolve com um `Supplier`: não recebe nenhum
argumento, produz algo útil.

# Transformação

Além de poder sumir com valores (`Consumer`) e fazer eles aparecerem do nada,
também posso manipular esses valores: pego algo e transformo em outro algo.
Isso é papel do `Function`! E ele tem apenas esse papel: transformar dados.

Inclusive, já usamos isso mais cedo: `p -> p.getfrete()`. Aqui estamos
simplesmente transformando um pedido em um valor de frete: `Pedido -> valor`.
Essa lógica de mapeamento de tipos foi analizada no post
[Somando valores sem laços]({% post_url 2022/2022-09-09-soma-valores-sem-loops %}),
em que se pegava as compras e mapeava para produtos, que por sua vez eram
mapeados em valores, algo assim:

```java
pedidos.stream()
    .flatMap(c -> c.produtos().stream()) // mapeio pedidos para uma stream de produtos
    .map(p -> p.qtd() * p.valorUnitario())
    .reduce(0, (acc, el) -> acc + el);
```

Aqui também podemos pegar dois valores e transformar em apena um usando um
`BiFunction`.

## Quando o tipo não muda

No Java, algumas `Function`s tem uma característica importante: elas são do
tipo `T` para o tipo `T`. Ou seja, elas mantém o tipo do dado: o mesmo tipo que
entra é o tipo que sai.

Para esse tipo de `Function`, damos o nome de `Operator`.

E no caso de pegar dois elementos do tipo T e retornar um terceiro e novo
elemento do tipo T? Aqui o Java abriu mão da consistência e no lugar de usar
`BiFunction` como em todo canto, passou a usar `BinaryOperator`.

# Decisões

As vezes precisamos definir se vamos para frente ou não. É simples: dado esse
objeto, preciso tomar uma decisão. Para isso usamos o `Predicate`. Por exemplo,
para saber se um pedido é muito caro:

```java
Predicate<Pedido> ehCaro = p -> p.getValor() > 100;
```

Muito comum ver predicados em situações que exigem filtros. Podemos pegar uma
variante da soma sem laços e colocar um filtro:

```java
pedidos.stream()
    .flatMap(c -> c.produtos().stream()) // mapeio pedidos para uma stream de produtos
    .filter(p -> p.vendidoPromocao())
    .map(p -> p.qtd() * p.valorUnitario())
    .reduce(0, (acc, el) -> acc + el);
```

# Variações primitivas

Além das opções que trabalham com objetos, existem também variações para
trabalhar apenas com primitivos, especificamente `int`, `long` e `double`. Se
você precisar usar algo para fazer um `ShortSupplier`, por exemplo, você não
vai encontrar apoio na biblioteca padrão da linguagem Java. O máximo que vai
encontrar é um `IntSupplier`, aí você abre a mão do controle dos 16 bits e
passa a ter fé que nos 32 bits vai funcionar.

Para o caso de funções, existem tanto o caso de `objeto -> primitivo` como
`primitivo -> objeto`. Por exemplo, `IntFunction` vai pegar um inteiro e
produzir um objeto. Já um `ToIntFunction` vai pegar um objeto e extrair um
inteiro de dentro dele. E também a variante `primitivo -> primitivo`, como o
`DooubleToIntFunction`.

A lista mais completa pode ser procurada na
[documentação oficial](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/package-summary.html).

# Notação

Em Java, lambdas são criadas usando a setinha fina, `->`. Porém, em algumas
situações podemos inferir um comportamento a partir da referência do método.
Por exemplo, para pegar o valor do frete do pedido, foi usado
`p -> p.getFrete()`. Porém, podemos simplesmente dizer que isso é uma funçào do
`Pedido`: `Pedido::getFrete`.

Aqui, `::getFrete` é a referência do método `getFrete` de um objeto do tipo
`Pedido`. É como se isso fosse um `Function<Pedido, Double>`.

Para usar referência de método, o correto é usar o `::`. No exemplo do frete
não estava preso que seria a um pedido específico, por isso que aquilo era uma
referência à classe pedido. Agora, se por acaso eu quisesse buscar de modo
_lazy_ o frete daquele pedido em específico, eu poderia fazer `p::getFrete`.

Tanto no caso de referência de método como no caso de lambda mais explícita com
setinha, o Java necessita saber explicitamente qual o tipo que está sendo
trabalhado. Por exemplo, eu não posso fazer

```java
final var calculaFrete = Pedido::getFrete;
// Cannot infer type: method reference requires an explicit target type
```

mas eu posso fazer

```java
final Function<Pedido, Double> calculaFrete = Pedido::getFrete;
```

# E o `@FunctionalInterface`?

Bem, isso é uma anotação. E aqui essa anotação serve para quebrar compilação.
Especificamente, o Java determina que uma interface é uma "interface funcional"
quando ela tem um único "método aberto". Isso é importante identificar porque
"método aberto" é aquele que não tem implementação concreta, então o lambda
dessa interface vai cuidar apenas da parte aberta.

Por exemplo, a interface `Predicate`. Ela tem um único método aberto,
`test(T)`. Mas ela tem alguns métodos que vem com implementações default, como
por exemplo `and(Predicate<T>)`, cuja implementação pode ser algo assim:

```java
default Predicate<T> and(Predicate<T> other) {
    return t -> test(t) && other.test(t);
}
```

No caso, essa anotação força o compilador a dar erro caso alguém, ao dar
manutenção em uma interface dessas, resolva colocar mais um método:

```java
@FunctionalInterface
interface X {
    void p();
    void n();
}
//Multiple non-overriding abstract methods found in interface X
```

# Resumão

{: class="marked-table w90"}
| Interface | FQDN | Descrição | Lambda |
| ----      | ---- | ----      | ----   |
| `Runnable` | `java.lang.Runnable` | Executa uma ação | `() -> System.out.println("execução acabou")` |
| `Consumer` | `java.util.function.Consumer` | Executa uma ação para um argumento recebido | `obj -> System.out.println(obj + ": execução chegou ao fim")` |
| `BiConsumer` | `java.util.function.BiConsumer` | Executa uma ação para dois argumentos recebidos | `(first, second) -> System.out.printf("recebi %s, %s\n", first, second)` |
| `Supplier` | `java.util.function.Supplier` | Retorna um novo valor do nada | `() -> 42` |
| `Function` | `java.util.function.Function` | Processa um dado em outro dado | `prod -> prod.qtd() * prod.valor()` |
| `Predicate` | `java.util.function.Predicate` | Preciso de uma decião com base em um dado | `p -> p.getValor() > 100` |

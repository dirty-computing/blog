---
layout: post
title: "Usando annotations em Java para fazer um strategy"
author: "Jefferson Quesado"
tags: java annotation design-pattern
base-assets: "/assets/java-strategy-annotations/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Passei por uma situação bem interessante no trabalho e queria compartilhar
a solução aqui.

Imagina que você precisa processar um conjunto de dados. E para lidar com esse
conjunto de dados você tem diversas estratégias distintas para isso. Por exemplo,
precisei criar estratégias para como buscar uma coleção de dados do S3, ou de exemplos
dentro do repositório local, ou passados como input.

E quem vai ditar essa estratégia é quem está fazendo a requisição:

> Eu quero pegar os dados no S3. Pegue os dados gerados no dia X entre as horas
> H1 e H2, que sejam do cliente Abóbora. Pegue os últimos 3000 dados que atendam
> isso daí.

Ou então:

> Pegue o dado que você tem de exemplo aí, copie ele 10000 vezes para fazer o teste
> de estresse.

Ou mesmo:

> Tenho esse diretório, você também tem acesso a ele. Pegue tudo nesse diretório
> e recursivamente para os sub-diretórios.

E também finalmente:

> Pega essa unidade de dado que está no input e use ela.

# Como implementar?

Meu primeiro pensamento foi: "como posso definir o shape do meu input em Java?"

E cheguei na primeira conclusão, super importante pro projeto: "quer saber? Não
vou definir shape. Mete um `Map<String, Object>` que aguenta."

Em cima disso, como não coloquei nenhum shape no DTO, tive liberdade total de
experimentar com a entrada.

Então após estabelecer uma prova de conceito, chegamos na situação: precisamos
sair da POC de estresse e partir para algo próximo do uso real.

O serviço que eu estava fazendo era para validar regras. Basicamente, ao se alterar
uma regra, eu precisava pegar essa regra e bater contra os eventos que ocorreram na
aplicação em produção. Ou então, se a aplicação foi alterada e não teve nenhum bug,
o esperado é que a decisão para a mesma regra se mantenha para o mesmo dado; já se
a decisão para a mesma regra usando o mesmo conjunto de dados for alterada...
bem, aí temos encrenca potencial.

Então, eu precisava dessa aplicação para rodar o backtesting das regras. Preciso
bater na aplicação real mandando os dados para avaliação e a regra em questão.
O uso disso é bem diverso:

- validar potenciais desvios ao atualizar a aplicação
- validar se as regras alteradas mantém o mesmo comportamento
  - por exemplo, otimizando o tempo de execução da regra
- verificar se a alteração nas regras gerou a alteração esperada nas decisões
- validar que a alteração na aplicação tornou ela de fato mais eficiente
  - por exemplo, usar a versão nova do GraalVM com JVMCI ligado está aumentando
    a quantidade de requisições que posso fazer?

Então, pra isso, preciso de algumas estratégias para a origem dos eventos:

- pegar os dados reais do S3
- pegar o dado que está como sample dentro do repositório e copiar ele múltiplas vezes
- pegar os dados de um local específico na minha máquina local

E também preciso de estratégias distintas das minhas regras:

- passei via input
- usa o stub de rápida execução
- usa um sample baseado em regra de produção
- usa esse caminho aqui na minha máquina

Como lidar com isso? Bem, deixa o usuário fornecer o dado!

## A API para estratégia

Sabe uma coisa que sempre me chamou atenção no json-schema? Isso aqui:

```json
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://json-schema.org/draft/2020-12/schema",
    "$vocabulary": {
        //...
    }
}
```

Esses campos começados com `$`. Ao meu ver ali eles estão servindo para
indicar metadados. Então, por que não usar isso no input de dados para
indicar o metadado de qual estratégia está sendo usada?

```json
{
    "dados": {
        "$strategy": "sample",
        "copias": 15000
    },
    //...
}
```

Por exemplo, posso pedir 15000 cópias do dado que eu tenho de sample.
Ou então pedir algumas coisas do S3, fazendo query no Athena:

```json
{
    "dados": {
        "$strategy": "athena-query",
        "limit": 15000,
        "inicio": "2024-11-25",
        "fim": "2024-11-26",
        "cliente": "Abóbora"
    },
    //...
}
```

Ou então no localpath?

```json
{
    "dados": {
        "$strategy": "localpath",
        "cwd": "/home/jeffque/random-project-file",
        "dir": "../payloads/esses-daqui/top10-hard/"
    },
    //...
}
```

E assim eu posso delegar para a seleção da estratégia adiante.

## Code review e a fachada

Minha primeira abordagem para lidar com estratégias foi essa:

```java
public DataLoader getDataLoader(Map<String, Object> inputDados) {
    final var strategy = (String) inputDados.get("$strategy");
    return switch (strategy) {
        case "localpath" -> new LocalpathDataLoader();
        case "sample" -> new SampleDataLoader(resourcePatternResolver_spring);
        case "athena-query" -> new AthenaQueryDataLoader(athenaClient, s3Client);
        default -> new AthenaQueryDataLoader(athenaClient, s3Client);
    }
}
```

Então meu arquiteto soltou duas perguntas durante o code-review:

- "por que você instancia tudo e não deixa o Spring trabalhar por você?"
- ele criou um `DataLoaderFacade` no código e abandonou ele _half baked_

O que entendi com isso? Que usar a fachada seria uma boa ideia para delegar
o processamento para o canto correto e... para abrir mão do controle manual?

Bem, muita magia acontece por conta do Spring. Já que estamos em uma casa
Java com expertise java, por que não usar o Java/Spring idiomático, né?
Só porque _eu_ como indivíduo acho complicado de entender algumas coisas
não quer dizer que necessariamente elas sejam complicadas. Então, vamos lá
abraçar o mundo da magia de injeção de dependência do Java.

## Criando o objeto de _façade_

O que antes era:

```java
final var dataLoader = getDataLoader(inputDados)
dataLoader.loadData(inputDados, workingPath);
```

Passou a ser:

```java
dataLoaderFacade.loadData(inputDados, workingPath);
```

Assim minha camada de _controller_ não precisa gerenciar isso.
Deixa com a fachada.

Então, como vamos fazer a fachada? Bem, pra começar, preciso injetar
todos os objetos nela:

```java
@Service // para o Spring gerenciar esse componente como um serviço
public class DataLoaderFacade implements DataLoader {

    public DataLoaderFacade(DataLoader primaryDataLoader,
                            List<DataLoader> dataLoaderWithStrategies) {
        // armazena de algum modo
    }

    @Override
    public CompletableFuture<Void> loadData(Map<String, Object> input, Path workingPath) {
        return getDataLoader(input).loadData(input, workingPath);
    }

    private DataLoader getDataLoader(Map<String, Object> input) {
        final var strategy = input.get("$strategy");
        // magia...
    }
}
```

Ok, para o `DataLoader` principal eu anoto ele como `@Primary` além de
`@Service`. Os demais eu anoto só com `@Service`.

Testar isso aqui, pondo para `getDataLoader` retornar nulo só para experimentar
o como o Spring está chamando o construtor e... deu certo. Agora eu preciso
**anotar** com **metadados** cada serviço que estratégia eles usam...

Como fazer isso...

Bem, olha só! Em java temos _anotações_! Posso criar uma anotação de _runtime_
que tenha dentro de si quais as estragédias usadas por aquele compoenente!

Então eu posso ter algo assim no `AthenaQueryDataLoader`:


```java
@Service
@Primary
@Estrategia("athena-query")
public class AthenaQueryDataLoader implements DataLoader {
    // ...
}
```

E eu posso ter aliases também, por que não?

```java
@Service
@Estrategia({"local", "path", "localpath"})
public class LocalpathDataLoader implements DataLoader {
    // ...
}
```

E show!

Mas como criar essa anotação? Bem, preciso que ela tenha um atributo
que seja um vetor de strings (o compilador Java já lida em fornecer uma
string solitária e transformar isos em um vetor com 1 posição).
O valor padrão é `value`. Fica assim:

```java
@Retention(RetentionPolicy.RUNTIME) // posso usar isso em runtime, não só em análise de bytecode
@Target(ElementType.TYPE)           // é intenção que eu só possa anotar tipos com essa anotação
public @interface Estrategia {
    String[] value();
}
```

Se o campo da anotação não fosse `value` eu precisaria explicitar ele,
e isso ficaria feio, como na anotação `EstrategiaFeia`:

```java
@Service
@EstrategiaFeia(estrategia = {"local", "path", "localpath"})
public class LocalpathDataLoader implements DataLoader {
    // ...
}
```

Não soa tão natural ao meu ver.

Ok, dado isso, precisamos ainda:

{% katexmm %}
- extrair a anotação das classes dos objetos passados
- montar um mapa string $\rightarrow$ data loader (ou string $\rightarrow$ T)
{% endkatexmm %}

## Extraindo a anotação e montando o mapa

Para extrair a anotação, preciso ter acesso a classe o objeto:

```java
o.getClass();
```

Em cima disso, posso pedir se essa classe foi anotada com uma anotação
do tipo `Estrategia`:

```java
o.getClass().getDeclaredAnnotation(Estrategia.class)
```

Lembra que ela tem o campo `values`? Pois bem, esse campo retorna um
vetor de strings:

```java
String[] estrategias = o.getClass().getDeclaredAnnotation(Estrategia.class).values();
```

Show! Mas tenho um desafio, porque antes eu tinha um objeto do tipo `T` e agora
quero mapear esse mesmo objeto em, bem dizer, `(T, String)[]`. Em streams, a
operação clássica que faz isso é `flatMap`. E Java também não permite eu retornar
uma tupla assim do nada, mas posso criar um `record` com isso.

Ficaria algo assim:

```java
record DataLoaderComEstrategia(DataLoader dataLoader, String estrategia) {}

List<DataLoaders> dataLoaders = ...;

dataLoaders.stream()
    .flatMap(o ->
        Stream.of(o.getClass().getDeclaredAnnotation(Estrategia.class).values())
            .map(s -> new DataLoaderComEstrategia(o, s)
        )
    )  //...
```

E se tiver um objeto que não foi anotado com estratégia? Vai dar NPE?
Melhor não, vamos filtrar ele fora antes do NPE:

```java
record DataLoaderComEstrategia(DataLoader dataLoader, String estrategia) {}

List<DataLoaders> dataLoaders = ...;

dataLoaders.stream()
    .filter(o -> o.getClass().getDeclaredAnnotation(Estrategia.class) != null)
    .flatMap(o ->
        Stream.of(o.getClass().getDeclaredAnnotation(Estrategia.class).values())
            .map(s -> new DataLoaderComEstrategia(o, s)
        )
    )  //...
```

Dado isso, ainda preciso montar um mapa. E, bem, veja só: o Java já fornece um coletor
pra isso!
[`Collector.toMap(keyMapper, valueMapper)`](https://docs.oracle.com/en/java/javase/22/docs/api/java.base/java/util/stream/Collectors.html#toMap(java.util.function.Function,java.util.function.Function))

```java
record DataLoaderComEstrategia(DataLoader dataLoader, String estrategia) {}

List<DataLoaders> dataLoaders = ...;

dataLoaders.stream()
    .filter(o -> o.getClass().getDeclaredAnnotation(Estrategia.class) != null)
    .flatMap(o ->
        Stream.of(o.getClass().getDeclaredAnnotation(Estrategia.class).values())
            .map(s -> new DataLoaderComEstrategia(o, s)
        )
    ).collect(Collectors.toMap(DataLoaderComEstrategia::estratgia, DataLoaderComEstrategia::dataLoader));
```

Até aqui, ok. Mas o `flatMap` particularmente me incomodou. Existe uma nova API do Java
chamada de `mapMulti`, que tem esse potencial de multiplicar:

```java
record DataLoaderComEstrategia(DataLoader dataLoader, String estrategia) {}

List<DataLoaders> dataLoaders = ...;

dataLoaders.stream()
    .filter(o -> o.getClass().getDeclaredAnnotation(Estrategia.class) != null)
    .<DataLoaderComEstrategia<T>>mapMulti((o, c) -> {
        for (final var estrategia: o.getClass().getDeclaredAnnotation(Strategized.class).value()) {
            c.accept(new DataLoaderComEstrategia<>(o, estrategia));
        }
    })
    .collect(Collectors.toMap(DataLoaderComEstrategia::estratgia, DataLoaderComEstrategia::dataLoader));
```

Beleza. Consegui para `DataLoader`, mas também preciso fazer a mesma coisa para `RuleLoader`.
Ou será que não? Se perceber não tem nada nesse código que seja específico de `DataLoader`.
Podemos abstrair esse código!!

```java
record ObjetoComEstrategia<T>(T objeto, String estrategia) {}

List<T> objetos = ...;

objetos.stream()
    .filter(o -> o.getClass().getDeclaredAnnotation(Estrategia.class) != null)
    .<ObjetoComEstrategia<T>>mapMulti((o, c) -> {
        for (final var estrategia: o.getClass().getDeclaredAnnotation(Strategized.class).value()) {
            c.accept(new ObjetoComEstrategia<>(o, estrategia));
        }
    })
    .collect(Collectors.toMap(ObjetoComEstrategia::estratgia, ObjetoComEstrategia::objeto));
```

## Debaixo da fachada

Por uma questão puramente utilitária, coloquei esse algoritmo dentro da anotação:

```java
@Retention(RetentionPolicy.RUNTIME) // posso usar isso em runtime, não só em análise de bytecode
@Target(ElementType.TYPE)           // é intenção que eu só possa anotar tipos com essa anotação
public @interface Estrategia {
    String[] value();

    public static class Util {

        // nenhum motivo especial o record estar aqui, apenas para facilidade de uso
        private record ObjetoComEstrategia<T>(T objeto, String estrategia) {}

        public static <T> Map<String, T> mapaEstrategia(List<T> objetosComEstrategia) {
            return objetosComEstrategia.stream()
                    .filter(o -> o.getClass().getDeclaredAnnotation(Estrategia.class) != null)
                    .<ObjetoComEstrategia<T>>mapMulti((o, c) -> {
                        for (final var estrategia: o.getClass().getDeclaredAnnotation(Strategized.class).value()) {
                            c.accept(new ObjetoComEstrategia<>(o, estrategia));
                        }
                    })
                    .collect(Collectors.toMap(ObjetoComEstrategia::estratgia, ObjetoComEstrategia::objeto));
        }
    }
}
```

E para a fachada? Bem, o trabalho é bem dizer o mesmo. Resolvi abstrair isso:

```java
class FachadaSelector<T> {
    final T primario;
    final Map<String, T> estrategia;

    FachadaSelector(T primario, List<T> outros) {
        this.primario = primario;
        this.estrategia = Estrategia.Util.mapaEstrategia(outros);
    }

    T objetoUsado(Map<String, Object> input) {
        if (input == null) return primario;
        final var estrategiaInput = input.get("$strategy"); // aqui o tipo vai ser Object
        if (estrategiaInput == null) return primario;

        // mas tudo bem ser object porque a chave do mapa é Object e ele casa no final com .equals
        return estrategia.getOrDefault(estrategiaInput, primario);
    }
}
```

E a fachada fica assim:

```java
@Service // para o Spring gerenciar esse componente como um serviço
public class DataLoaderFacade implements DataLoader {

    private final FachadaSelector<DataLoader> selector;

    public DataLoaderFacade(DataLoader primaryDataLoader,
                            List<DataLoader> dataLoaderWithStrategies) {
        this.selector = new FachadaSelector<>(primaryDataLoader, dataLoaderWithStrategies);
    }

    @Override
    public CompletableFuture<Void> loadData(Map<String, Object> input, Path workingPath) {
        return getDataLoader(input).loadData(input, workingPath);
    }

    private DataLoader getDataLoader(Map<String, Object> input) {
        return selector.objetoUsado(input);
    }
}
```
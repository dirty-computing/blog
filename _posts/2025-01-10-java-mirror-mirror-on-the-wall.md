---
layout: post
title: "Conheça-te a ti mesmo! Reflexão e meta-programação em Java"
author: "Jefferson Quesado"
tags: java python reflection meta-programming ipc typescript totalcross
base-assets: "/assets/java-mirror-mirror-on-the-wall/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Primeiramente gostaria de agradecer aos patrocinadores desta postagem,
David Fornazier e Rodolfo de Nadai. Esse post sobre reflexão e meta-programação
em java é dedicado a vocês, que investem na expansão do javismo cultural.

# Um pequeno conto sobre engenharia de software

Durante minha atuação como líder de engenharia (formalmente denominado de
Mestre dos Magos), uma das coisas que eu estava lutando era para espalhar
o conhecimento da equipe sobre o escopo das coisas da firma.

Não era uma firma grande, mas a firma em si tinha pedaço de código documentado
da época que eu tinha começado o ensino médio. Então passar pelo código de lá
era, também, passar por código que tinha sobrevivido a mais de 15 anos.
Antigamente havia uma Wiki em um Mac Mini da firma, acessível na LAN e na VPN,
mas quando eu quis resgatar informações de lá o acaso e a falta de ativa
manutenção nesses subsistemas esquecidos cobrou o preço e os arquivos
mencionados pela Wiki, apesar de existirem, o usuário `www` (ou equivalente)
não tinha permissão de leitura. Então, por mais que eu desejasse resgatar
as coisas de lá, havia menção a coisas descritas em imagens e anexos que,
na prática, estavam inacessíveis.

Muita coisa havia mudado na firma, e eu fui catalisador de mudanças extremas
do lado de engenharia. As mudanças de engenharia foram feitas de modo que,
ao menos na minha visão da época, fossem o mais suave e menos impactante para
a equipe de negócios.

O software em si era um força de vendas. Ela se caracterizava por ter um portal
web multi-tenant e, também, uma versão mobile com as mesmas funcionalidades do
portal com um _catch_ a mais: ele era disponibilizado também offline, portanto
vendedores deveriam ser capazes de lidar com as diversas e mais complexas regras
de negócio mesmo estando desplugados.

Entre as diversas atividades de tiragem de pedido, haviam diversas validações
que eram disparadas em condições distintas. Em 2021 haviam mais de 90
validações distintas disparadas e condições distintas. Isso era um problema
pois havia condições de disparo disso que muitos colegas não haviam vivenciado.

Um outro problema era em relação a um dos cadastros mais complexos do sistema:
o de precificação de frete. Esse cadastro tinha dentro dele diversas validações
para garantir que o objeto salvo seria um objeto válido (inclusive usando o
mesmo framework funcional que o de validação de pedido), além de que o impacto
desses dados no valor final do pedido era grande.

Existia também um submódulo do sistema de emissão de relatórios usando jasper
reports, em que foi feito um trabalho para deixar online o máximo possível
o servidor que emitia o relatório só atualizando o `.jrxml` sob demanda de
novas atualizações. Devido a questões de _constraints_ e gestão estratégica
e de risco da equipe, o foco para a criação e manutenção de relatório
acabou recaindo sobre uma única pessoa, já que essa pessoa era a pessoa
programadora com maior capacidade e agilidade de mexer com jasper reports
e entregar o relatório da maneira certa dentro dos parâmetros da empresa.

O início da tiragem do pedido também passava por um carregamento inicial
específico pesado, cheio de particularidades, e obviamente foram poucas
as pessoas que mexeram nessa parte do sistema.

Também existia um módulo novo da definição de preços através de fórmulas
e cadastros de variáveis (em contraponto do modelo anterior que era apenas
o valor que constava no ERP da faixa de preço). Esse era um trabalho muito
específico e ficou restrito a poucas pessoas...

E o sistema estava em migração de tecnologia mobile. Antigamente o sistema
mobile era totalmente escrito em TotalCross (portanto a codebase era
totalmente java; um java com restrições mas não obstante java). Infelizmente
a plataforma TotalCross não estava avançando rapidamente para as necessidades
que eram enfrentadas na firma, e a atualização para TotalCross 5 (ou seria
TotalCross 6?, não lembro exatamente) estava custosa.

Uma das coisas que se deseja nessa migração de plataforma era a capacidade
de se utilizar Flyway para controlar versionamento do banco de dados do
aplicativo móvel. Entre os diversos pressupostos da migração de tecnologia
era uma mudança significativa no modelo de negócio: o mesmo aparelho poderia
ser usado por pessoas distintas, em contas distintas; e a mesma pessoa poderia
ser capaz de se logar em dispositivos distintos. Antes por uma questão de
negócio cada usuário só poderia fazer login em um único dispositivo, e se
o usuário fizesse login em diversos dispositivos poderia incorrer em
corrupção de dados (obviamente que ocorreu, por mais raro que fosse).

E, bem, durante a análise para ver a possibilidade de se atualizar a versão
do TotalCross para não mudar de tecnologia, esbarramos em diversos problemas
únicos que particularmente foram muito custosos. O porte do Flyway para
funcionar no JRE limitado do TotalCross foi muito desgastante. Escrever
a GUI em TotalCross não era uma experiência boa para o desenvolvedor, e
nem a experiência de usuário ficava boa mesmo com nossos melhores esforços.

> Só um disclaimer aqui: sempre foi possível fazer uma boa experiência de
> usuário usando TotalCross. Da época que eu trabalhei para a TotalCross,
> um dos clientes tinha uma interface tão amigável e fluida usando TotalCross
> que era algo sensacional. Mas isso não quer dizer que fosse algo fácil
> ou intuitivo de alcançar, eu mesmo nunca fui capaz de chegar perto do
> trabalho desse pessoal.

Então, dito isso, foi feito um esforço para migrar a aplicação mobile para
Flutter. Como 90% da base de usuários dos clientes eram Android, e boa
parte do _core_ da aplicação era código Java já, decidi (estrategicamente,
junto ao diretor de operações da época), que isso iria se manter em Java.
O Flutter seria a camada de interface com usuário que falaria com código
Java nativo.

E com isso passamos a desenvolver o sistema em 4 frentes:

1. o _core_ do sistema, em Java, com restrição de ser compatível com
   TotalCross, Android, Java Web e em algumas situações GWT
2. a aplicação web em GWT, em Java
3. a aplicação móvel em TotalCross, em Java
4. a nova versão em Flutter, com parte do código em Dart e parte em Java

E, bem, preciso dizer aqui novamente que as pessoas programadoras da equipe,
que somavam menos de 15 pessoas, algumas nunca tinham tocado em diversas
partes do sistema mobile, preciso?

## Espalhando conhecimento

Algumas coisas críticas estavam acontecendo. E alguns projetos estavam sendo
carregados por pessoas basicamente sozinhas, levando nos ombros o peso que
Síssifo carregava. E as falhas se acumulavam por cansaço e saturação do tema.

E as pessoas ficavam doentes ou precisam sair de férias. E uma pessoa ausente
no projeto fazia uma grande diferença, impactando significativamente a entrega.

Quando ascendi à liderança técnica/gestão de engenharia por vacância, o
conhecimento em ilhas isoladas foi uma das principais fraquezas e fragilidades
que eu quis atacar. E para resolver isso, experimentei com _pair programming_
promíscuo, onde haveria tanto promiscuidade de par como também de atividade
delegada para cada par trabalhar. Fizemos uma leitura de
[Arlo Belshee 2005, Promiscuous Pairing and Beginner’s Mind: Embrace
Inexperience](http://jtigger-learning.wdfiles.com/local--files/agile/XR4PromiscuousPairingandBeginnersMind.pdf),
e fizemos um esquema de rotação de atividades e pares.

Como funcionava isso? Bem, existia uma sala no Discord chamada de Donhan, em
homenagem ao Pokemon elefante cujo _signature move_ é girar:

![Donphan](https://www.pokemon.com/static-assets/content-assets/cms2/img/pokedex/full/232.png)

Criamos um ritual chamado de "rotação" (por isso o Donphan), no qual as pessoas
e as atividades eram atribuídas a números e botávamos no
[https://random.org](https://random.org) para obter uma permutação
verdadeiramente aleatória de pessoas e atividades.

Diversas encarnações e regras distintas foram tentadas, uma delas mais clara
na minha cabeça é que a rotação era feita 2 vezes por dia, existiam mais
atividades do que duplas disponíveis para atacar as atividades, e o tempo
de passagem de conhecimento era de no máximo 5 minutos síncronos, após
esse tempo os pares deveriam já estabelecer no que cada um iria atacar da
atividade em si (ou se iriam de _pair programming_ clássico, de acordo
com a necessidade que a dupla sentisse para a atividade).

Devo dizer que o pessoal que trabalha comigo fala bastante que eles cresceram
em conhecimento técnico e no conhecimento de negócio da empresa. Também
é justo mencionar que essas minhas ideias e frequência de rotação foram
motivo de estresse da minha equipe. Oops...

Mas enfim, com tão pouco tempo para lidar com o trabalho da dupla anterior,
como que as pessoas programadoras conseguiam seguir em frente? Basicamente,
a interface de contato de 5 minutos que se tinha com a pessoa que estava saindo
da atividade era o suficiente para se situar no código para continuar a
atividade. A partir dali, sabendo a direção para o alvo que se desejava
alcançar, inspecionando a região de código ao redor de onde o outro tinha
deixado a atividade, era só dar o próximo pasos.

E se programava assim. A pessoa precisava se situar, olhar a programação,
extrair daquilo informação para o próximo passo, e decidir qual o passo
necessário para codificar.

E o que esse prefácio todo tem a ver com reflexão no java? Porque, ao
trabalhar com reflexão, estamos em uma situação semelhante (menos o
estresse das rotações). Entramos em um ambiente estranho e precisamos
tatear o que tem ao redor para dar o próximo passo. Mas com humanos
existia a vantagem de que é possível avançar com informação
pouca/imprecisa e só um rumo geral. No caso de questões técnicas temos
mais coisas a se fazer e determinar...

# Reflexão fofa: instanceof

Primeira questão aqui para que o código saiba do que se trata. Perguntar
qual o tipo do objeto. Em java, podemos perguntar para um objeto se ele
é uma instância de determinado tipo:

```java
public static <T> ArrayList<T> getMutableList(List<T> base) {
    if (base instanceof ArrayList<T> array) {
        return array;
    }
    return new ArrayList<>(base);
}
```

Ok, podemos usar isso para fazer coisinhas bobas e fofinhas, como evitar
recriar uma lista como lista mutável se ela já for uma lista mutável.
Isso permite com que a gente se preocupe com tipos previamente conhecidos
inputados pelo programador. Mas isso é o de menos, podemos ir para coisas
mais profundas... em breve retornaremos sobre verificar instância, mas
de modo mais dinâmico!

Note que isso não define o formato do objeto em Java. Java segue a chamada
"tipagem nominal", onde o tipo é determinado pelo nome. Existem outros tipos
de tipagem, como tipagem estrutural. E TypeScript lida justamente com tipagem
estrutural.

Um objeto em TypeScript não carrega em si (em tempo de runtime) o nome de seu
tipo. Mas podemos usar reflexão para saber se ele tem determinado formato.
Em TypeScript usamos "type guardians", como uma função com o operador `is`.

Por exemplo, ao fazer postagens no BlueSky, eu tive de lidar com objetos
de referência de blobs (`JsonBlobRef`). Inclusive tinha um tipo especial
que tinha o campo `ref` com a referência (um objeto do tipo
[`CID`](https://github.com/multiformats/js-multiformats?tab=readme-ov-file)).
Isso era o que para mim era mais significativo em relação ao `TypedJsonBlobRef`,
mas o jeito mais simples de verificar se ele era `TypedJsonBlobRef` era
de o campo `$type` existia.

Então, para verificar se um objeto `JsonBlobRef` era um `TypedJsonBlobRef`,
escrevi a seguinte função:

```ts
function isTypedJsonBlobRef(blob: JsonBlobRef): blob is TypedJsonBlobRef {
    return (blob as any)["$type"] != null
}
```

Como estou usando o operador `is` estou indicando para o compilador TS (e
também ao LSP) que dentro de um escopo aquele objeto pode, de fato, ser
tratado como um `TypedJsonBlobRef`:

```ts
const blob = ...;

// neste escopo eu não tenho garantia que `blob.original` tenha o campo `ref`,
// portanto `blob.original.ref` gera falha de compilação
if (isTypedJsonBlobRef(blob.original)) {
    // aqui neste escopo eu sei que blob.original é do tipo TypedJsonBlobRef,
    // portanto o código abaixo não gera erro de compilação
    return {
        ...blob.original,
        ref: `CID(${blob.original.ref.toString()})`
    }
}

// aqui novamente não possuo garantias sobre o tipo de `blob.original`,
// então `blob.original.ref` gera falha de compilação
```

Bem, com isso só dá para codar fofo? Será que não dá para fazer nada tipo...
pesadão?

## Implementando um protocolo de DeSer

Eu passei por essa necessidade recentemente em um projeto em GWT.
Pense que eu tinha acesso a boa parte da JRE, mas não teria acesso
a anotações, resgate de métodos/campos nem a muitas bibliotecas do
Java.

Então sobrou para mim fazer algumas coisas na mão.

GWT mantém no objeto informações o suficiente do tipo do objeto
em questão. Então eu consigo fazer perguntas como
`obj instanceof BigDecimal` que ele consegue me responder com
tranquilidade. Internamente ele tem um campo no objeto javascript
para fazer o mapeamento para o tipo java e o operador `instanceof`
é transpilado em uma operação que usa esse dito campo.

Dito isso, caí em um caso extremamente peculiar. O sistema fazia
o logoff automaticamente do usuário se ele passasse 30 minutos sem
interagir. E ao ser deslogado o usuário perdia automaticamente o
trabalho dele. Também tinha o caso de que o sistema poderia ter
sido feito um deploy novo e com isso forçado o usuário a se logar
novamente (eu sei, skill issue de minha parte, não precisava matar
a sessão a cada deploy). Ou então as vezes o usuário simplesmente
tinha um azar de pegar uma atualização automática do Windows e
o SO fechava o browser contra a vontade dele para se reiniciar.

Preciso dizer que isso era em uma tela crítica do sistema
que mantinha a principal operação do usuário? E que não era uma
operação simples, mas sim parte de uma negociação entre o usuário
e o cliente dele envolvendo diversas questões de venda e muitas
coisas mais? E que o usuário não ficava feliz quando ele precisava
refazer aquela operação toda de novo? Alguns casos o usuário havia
cadastrado já quase 50 itens no processo da venda...

Com isso, surgiu a necessidade de fazer com que a pessoa que operasse
o sistema conseguisse retomar o que ela havia parado. Eu poderia salvar
o estado intermediário no servidor? Poderia, mas não queria dispender
tempo no servidor resgatando questões de valores intermediários que
naturalmente eram descartados. Queria algo que dependesse apenas do
browser. Para resolver essa questão? LocalStorage.

Mas para usar o LocalStorage eu precisava ser capaz de transformar
o objeto de trabalho em uma string de bytes. E como se faz isso?
Bem, com serialização. E para tornar o objeto útil novamente seria
necessário o processo de desserialização.

No LocalStorage, foi escolhida uma chave arbitrária para guardar
o valor. Em cima dessa chave colocamos um JSON que carregaria consigo
as informações todas de objetos de trabalho parcial das operações
que foram abandonadas pelos usuários do sistema daquele browser. Não
custa nada, nesse caso, de guardar nesse JSON uma chave de multiplexação
com o usuário e o tenant que aquele usuário estava vinculado. Então,
dada essa multiplexação, chegávamos no objeto serializado propriamente dito.

Esse objeto era um objeto simples. Ele carregava em si algumas poucas
informações:

1. o identificador da serialização `id`
2. data de criação `dtCriacao`
3. data de validade `dtValidade`
4. local onde foi gerado esse objeto `local`
5. versão do DeSer utilizado `versao`
6. a serialização do valor `valor`

O `id` era utilizado para guardar trabalho temporário sendo realizado.
Jogar o dado no LocalStorage é feito nesse caso sem o consentimento do
usuário, os dados são simplesmente armazenados de acordo com algum fator
de trigger disso (utilizava aqui "observers" para verificar se o objeto
havia sido atualizado). Quando o usuário fazia alguma alteração relevante,
salvava-se o valor serializado e entrava em modo de "descanso" por alguns
segundos. Após esse tempo de descanso, se houvesse outra alteração repetia
esse processo.

Na primeira vez que se salvava um objeto de trabalho temporário, se obtinha
a chave única desse objeto. Nas vezes subsequentes, no lugar de gerar
uma linha nova no JSON com esse valor, se atualizava aquela linha específica.

`dtCriacao` devo admitir que não me lembro o motivo. `dtValidade` era o
TTL daquele registro. Não adianta manter o registro de um pedido de venda
mais de 370 dias só porque naquela segunda-feira a bateria do notebook
arriou, né?

`local` aqui tinha serventia dupla. A primeira serventia é justamente essa,
de apontar qual a tela deveria ser restaurada para continuar o serviço. Além
disso, como a tela trabalhava com um objeto específico, isso também indicava
qual o desserializador utilizar para povoar o objeto (o desserializador fica
no backend porque existem informações que não são preenchidas apenas com dados
que estavam no front, pois eles podem ter sido atualizadas por alguma importação
de dados naquele intervalo de tempo).

A `versao` foi utilizado porque, bem... o sistema evolui, né? E com a evolução...
o shape do objeto eventualmente vai mudar. Com a mudança do shape, posso
resolver usar estratégias de serialização distinta, mais inteligentes...
e preciso saber como eu serializei aquilo para poder desserializar corretamente.

E finalmente o valor serializado propriamente dito em `valor`. Pronto.

Mas o ponto desse artigo é reflection, né? E aqui estamos lidando com
reflexão fofa, `instanceof`. Então vamos entrar no mundo de como foi usada
a reflexão fofa para contornar a ausência de uma lib de serialização que
eu pudesse controlar. O texto acima foi só para contextualizar a necessidade
de usar a reflexão fofa para fazer um trabalho... mais pesadinho.

Para definir a serialização, comecei definindo aqui um `SerializationContext`.
Nesse contexto eu vou adicionar o serializador. Mas o serializador não vem
sozinho. Ele vem com condição de ativação. Algo assim:

```java
SerializationContext context = new SerializationContext();
context.addSerializer(x -> x == null, new NullSerializer());
context.addSerializer(x -> x instanceof String, new StringSerializer());
```

Ok. Define também que eu queria trabalhar com alguns tipos básicos de serialização:

1. nulo
2. string
3. inteiro (enquadre aqui `Integer` e `Long`)
4. dicionário com chaves string
5. listas
6. arrays java (que posso tratar como lista depois de enfeitar um pouco)

E a serialização, bem... a serialização é algo recursivo. Pegue o exemplo de um
dicionário: preciso serializar os objetos apontados dentro dele, e esses objetos
podem ter outros objetos dentro dele. Igual com listas. Por exemplo:

```java
List.of(List.of(List.of(), "marmota"), List.of());
// serialização: [ [[], "marmota"] , [] ]
```

Então isso significa que, para um `Serializer<T>`, eu tenho que ter uma função
`(T, SerializationContext) -> String`, pois recursivamente vou pedir para serializar
as coisas. Então, vamos serializar algumas coisas? E não ficar delegado para uma
abstração não exibida?

```java
SerializationContext context = new SerializationContext();
context.addSerializer(x -> x == null, (value, ctxt) -> "null");
context.addSerializer(x -> x instanceof String, (s, ctxt) -> "\"" + s + "\"");
context.addSerializer(x -> x instanceof Number, (s, ctxt) -> s.toString());
```

Ok, até aí tudo bem, tudo tranquilo. O contexto estava sendo sempre ignorado.
Pois vamos começar a brincadeira? Para listas:

```java
conext.addSerializer(x -> x instanceof List, (l, ctxt) ->
    l.stream()
        .map(ctxt::serialize)
        .collect(Collectors.joining(",", "[", "]"))
);
```

E, bem, temos serialização recursiva de tipos! Yaaaaay! Mas isso não é tudo.
Serialização de mapa também não é lá essas coisas de complicada:

```java
conext.addSerializer(x -> x instanceof Map, (m, ctxt) ->
    m.entrySet().stream()
        .map(es -> ctxt.serialize(es.getKey()) + ":" + ctxt.serialize(es.getValue()))
        .collect(Collectors.joining(",", "{", "}"))
);
```

E, bem... agora falta o cadastro para tipos complexos que não são dicionários...

Como esses tipos são definidos, de maneira geral? Normalmente eles são definidos
como sendo um nome (denominado chave) e dentro dessa chave eu tenho um valor. Então...
se eu cadastrar todas as chaves desse tipo, e junto a essas chaves, funções para
extrair os valores, então eu posso aplicar uma lógica de serialização semelhante
a que usei para serializar o mapa! Vamos lá!

O `SerializerFromFields<T>` para funcionar precisar ter uma série de mapeamentos
de nome de campos para extrator de valor `String -> T -> any`. Posso obter isso
modelando como sendo `Map<String, Function<T, ?>>`. Então posso criar uma classe
chamada `SerializerFromFields<T>` que recebe no construtor um um mapa de nome de
campo para extrator de campo! Chamando esse campo de `fieldExtractor`, a função
de serialização seria isto daqui:

```java
@Override
public String serialize(T obj, SerializationContext ctxt) {
    return fieldExtractor.entrySet()
        .map(fe -> ctxt.serialize(fe.getKey()) + ":" + ctxt.serialize(fe.getValue().apply(obj)))
        .collect(Collectors.joining(",", "{", "}"));
}
```

Ok. Se eu tivesse uma classe chamada `Banana`, com os campos `cor: String` e
`gramagem: int`, eu poderia criar um serializador de `Banana` dessa maneira:


```java
new SerializerFromFields<Banana>(
    Map.of(
        "cor", Banana::getCor,
        "gramagem": Banana::getGramagem
    )
);
```

Se eu não utilizasse getters para essa classe:

```java
new SerializerFromFields<Banana>(
    Map.of(
        "cor", b -> b.cor,
        "gramagem": b -> b.gramagem
    )
);
```

E para cadastrar no contexto de serialização? Bem, seria assim:

```java
SerializationContext context = new SerializationContext();
context.addSerializer(x -> x == null, (value, ctxt) -> "null");
context.addSerializer(x -> x instanceof String, (s, ctxt) -> "\"" + s + "\"");
context.addSerializer(x -> x instanceof Number, (s, ctxt) -> s.toString());

context.addSerializer(x -> x instanceof Banana, (s, ctxt) -> new SerializerFromFields<Banana>(
                                                                Map.of(
                                                                    "cor", b -> b.cor,
                                                                    "gramagem": b -> b.gramagem
                                                                )
                                                             )
);
```

Tudo resolvido, né? Bem, na real não... Precisa ainda lidar com questões
de que a string pode ter caracteres que causam confusão, como contra-barras,
aspas, quebras de linhas... Bem, aí nesses casos vamos precisar reajustar
o serializador de string!

```java
(s, ctxt) ->
        "\"" +
        s.replaceAll("\\", "\\\\")
            .replaceAll("\r", "\\r")
            .replaceAll("\n", "\\n")
            .replaceAll("\t", "\\t")
            .replaceAll("\"", "\\\"") +
        "\""
```

E, bem... não vai ser aqui me preocupar tanto assim em casos de caracteres
multi-bytes. Isso é discussão mais longa. O importante é que, agora, só com
essas pequenas serializações já consigamos lidar com a figura geral.

Bem, faltou só o `SerializationContext`, né? Esse não tem muito segredo.
A API geral dele já está definida, `<T>addSerializer(Predicate<T>, BiFunction<T, SerializationContext, String>)`
e `serialize(Object)`. Podemos trocar o `addSerializer` por um builder
e passar uma lista no construtor, mas isso não muda a ideia geral:

```java
public class SerializationContext {
    public record Serializer<T>(Predicate<Object> when, BiFunction<T, SerializationContext, String> then) {
        public boolean test(Object o) {
            return when.test(o);
        }

        public String serialize(Object o, SerializationContext ctxt) {
            return then.apply((T) o, ctxt);
        }
    }

    private final ArrayList<Serializer> knownSerializers = new ArrayList<>();

    public <T> void addSerializer(Predicate<Object> when, BiFunction<T, SerializationContext, String> then) {
        knownSerializers.add(new Serializer<>(when, then));
    }

    public Serializer<Object> defaultSerializer() {
        return new Serializer<>(__ -> true, (o, ctxt) -> Objects.toString(o));
    }

    public <T> String serialize(T obj) {
        return knownSerializers.stream()
            .filter(s -> s.test(obj))
            .findFirst()
            .orElseGet(this::defaultSerializer)
            .serialize(obj, this);
    }
}
```

E graças a reflexão fofa temos aqui um serializador recursivo de dados arbitrários.

# Listando métodos

Uma das vantagens de se fazer reflexão é poder olhar tudo o que um objeto
oferece em tempo de runtime. Entre isso podemos ver quais os métodos que
ele tem.

Podemos fazer isso perguntando quais os métodos da classe. De que classe?
Da classe do objeto, claro! A teoria é bem simples: você chega pro
objeto, pergunta qual a classe dele (inclusive pode retornar uma classe
anônima, viu?). Em cima dessa classe, pedimos seus métodos:

```java
List<Method> listarMetodosBonitos(Object o, Predicate<Method> ehBonito) {
    return Stream.of(o.getClass().getDeclaredMethods()) // Method
        .filter(ehBonito)
        .toList();
}
```

Veja o Javadoc para [`Class`](https://docs.oracle.com/en/java/javase/22/docs/api/java.base/java/lang/Class.html)
e para [`Method`](https://docs.oracle.com/en/java/javase/22/docs/api/java.base/java/lang/reflect/Method.html).

Uma das coisas que podemos fazer com isso é selectionar os métodos cujos
nomes começam com `get` (lembre-se que estamos aqui lidando com OOP séria,
usar getter e setter é INTENCIONAL, não [javismo cultural puro e
simples]({% post_url 2024-08-21-mentiras-oop %})):

```java
List<Method> getters = listarMetodosBonitos(config, m -> m.getName().startsWith("get"));
```

Mas, sinceramente? Isso é potencialmente perigoso. Se eu quero um getter, para mim
só interessa o getter que não tem parâmetros. Como resolver isso? Adicionando uma
condição ao filtro, o de quantos argumentos tem o método:

```java
List<Method> getters = listarMetodosBonitos(config,
                                            m -> m.getName().startsWith("get") &&
                                                 m.getParameterCount() == 0
                                           );
```

Mas o `Class.getDeclaredMethods()` me retorna todos os métodos disponíveis. Isso
significa que até mesmo métodos `private` e `static` são retornados. Mas
aqui nos interessa retornar métodos de instância que sejam públicos (porque
faz parte do exemplo, que é arbitrário)! Como podemos fazer isso? Perguntando
para o método, claro!

O método possui um `getModifiers() -> int`, que retorna um inteiro de 32 bits
com as diversas flags de acesso setadas. Como podemos validar essas flags de
acesso? Uma alternativa é decorando, lembrando de cabeça delas. Por exemplo:

```java
Method m = ...;
System.out.println(m.getModifiers() & 0x1);
```

Se o resultado impresso for diferente de 0, isso significa que a flag `0x1`
estava ligada nos modificadores do método, e essa flag indica que o método
é público. Então uma alternativa é decorar essas coisas.

Outra alternativa é consultar as enumerações 
[`AccessFlags`](https://docs.oracle.com/en/java/javase/22/docs/api/java.base/java/lang/reflect/AccessFlag.html),
ou decorar [`Modifiers`](https://docs.oracle.com/en/java/javase/22/docs/api/java.base/java/lang/reflect/Modifier.html).
Particularmente o `AccessFlags` me parece mais fácil, para mim ao menos. Como
podemos estender aquela solução para verificar pelas flags de acesso? De modo
a selecionar apenas métodos públicos e que são de instância (portanto não podem
ser estáticos). Vamos criar aqui uma pergunta que verifica se uma flag de acesso
está ativada, bora?

Para isso, vou usar `AccessFlags`, que tem dentro de si o método `.mask()` que
retorna o valor da máscara da flag de acesso.

```java
boolean metodoPossuiFlag(Method m, AccesFlag f) {
    return (m.getModifiers() & f.mask()) != 0;
}
```

Se eu quero saber se o método é público:

```java
Method m = ...;
System.out.println(metodoPossuiFlag(m, AccessFlag.PUBLIC));
```

E também posso verificar se **não** possui a flag:

```java
Method m = ...;
System.out.println(!metodoPossuiFlag(m, AccessFlag.STATIC));
```

Com isso, conseguimos desenvolver melhor o filtro dos getters:

```java
List<Method> getters = listarMetodosBonitos(config,
                                            m -> m.getName().startsWith("get") &&
                                                 m.getParameterCount() == 0 &&
                                                 metodoPossuiFlag(m, AccessFlag.PUBLIC) &&
                                                 !metodoPossuiFlag(m, AccessFlag.STATIC)
                                           );
```

E, bem. Isso vai dar simplesmente os getters para o objeto `config`.
Que tal transformar isso em valores? No final das contas, não vai me interessar
ter acesso cego a esses métodos, gostaria do valor dentro deles.

Para invocar o método, precisamos simplesmente chamar `m.invoke(self)`,
onde `self` seria a instância que iríamos chamar do método específico.
No caso, suponha que eu tenha `config.getMarmota()`, e `getMarmota()`
é um método público. Isso significa que `getMarmota` estará ne lista
de métodos. Vamos supor, para questão deste exercício, que `getMarmota`
seja o único método na lista de getters... como eu faria para invocar
o equivalente a `config.getMarmota()`? Usando o `invoke`, claro!

```java
List<Method> getters = listarMetodosBonitos(config,
                                            m -> m.getName().startsWith("get") &&
                                                 m.getParameterCount() == 0 &&
                                                 metodoPossuiFlag(m, AccessFlag.PUBLIC) &&
                                                 !metodoPossuiFlag(m, AccessFlag.STATIC)
                                           );
final var resultado = getters.get(0).invoke(config);
```

Pronto, chamei o método `getMarmota` para o objeto `config`. E ainda posso
guardar o resultado da chamada. E se por acaso o método que eu quisesse chamar
tivesse, por exemplo, uma string como primeiro argumento, como eu poderia
fazer?

Bem, felizmente o `Method.invoke` pode receber argumentos. Nesse caso
específico, a chamada seria algo assim:

```java
Object config = ...;
Method m = ...;
m.invoke(config, "uma string como argumento");
```

E se meu método fosse estático? Bem, aí a documentação do Java já me indica
que o primeiro argumento desse método é ignorado. Se é ignorado e eu
sei com toda a certeza que é estático, eu posso passar `null` para o
indicar de "self". Essa convenção ajuda a quem for ler o código depois,
indica que o método chamado é estático:

```java
Object config = ...;
Method m = ...;
m.invoke(null, "uma string como argumento"); // ahha! método estático primeiro param null, por convenção
```

Eu omiti de propósito uma coisa. É tão comum essa necessidade de obter os
métodos públicos de instância que o Java fornece uma outra API que não
a `Class.getDeclaredMethods()`! O Java oferece `Class.getMethods()`,
que retorna apenas métodos públicos e que não são estáticos. Eu omiti
isso propositadamente para falar sobre `modifiers` e aplicações das
máscaras, mas já que lidamos com isso já podemos ser mais eficientes
agora em relação a obter os métodos de instância, né?

```java
List<Method> listarMetodosInstanciaBonitos(Object o, Predicate<Method> ehBonito) {
    return Stream.of(o.getClass().getMethods()) // Method
        .filter(ehBonito)
        .toList();
}
```

Agora, imagine que eu quero saber, nem que seja um por cima, o tipo do objeto
que seria retornado caso eu invocasse o método. Como eu faria isso? Uma alternativa
seria _de fato_ chamar. Mas isso não é necessário, eu posso perguntar ao objeto
qual o seu retorno: `Method.getReturnType()`.

Tem um detalhe chato em relação a isso, que é que o método `invoke` lança exceções
checadas. E isso impede que eu chame diretamente o `invoke` em métodos funcionais.
Mas claro que existe uma gambiarra para isso! Eu posso envelopar a exceção!

```java
record InvokeResult(Exception err, Object value) {
    static InvokeResult value(Object value) {
        return new InvokeResult(null, value);
    }
    static InvokeResult err(Exception err) {
        return new InvokeResult(err, null);
    }

    boolean isError() {
        return err != null;
    }
}

InvokeResult wrapInvoke(Method m, Object self, Object... args) {
    try {
        return InvokeResult.value(m.invoke(self, args));
    } catch (Exception e) {
        return InvokeResult.err(e);
    }
}

List<Method> getters = listarMetodosInstanciaBonitos(config,
                                                     m -> m.getName().startsWith("get") &&
                                                     m.getParameterCount() == 0
                                                    );
List<Object> resultado = getters.stream()           // Method
    .map(m -> wrapInvoke(m, config))                // InvokeResult
    .filter(Predicate.not(InvokeResult::isError))   // InvokeResult
    .map(InvokeResult::value)                       // Object
    .toList();
```

E se quiséssemos que fossem executados apenas os métodos que retornam string?
Vou usar em cima da mesma abstração anterior, portanto já começo com a lista
`getters` preenchida:

```java
List<String> resultado = getters.stream()           // Method
    .filter(m -> m.getReturnType() == String.class) // Method
    .map(m -> wrapInvoke(m, config))                // InvokeResult
    .filter(Predicate.not(InvokeResult::isError))   // InvokeResult
    .map(InvokeResult::value)                       // Object
    .map(o -> (String) o)                           // String
    .toList();
```

Isso daqui é só um começo de reflexão, onde conseguimos investigar o
método em si. Existem coisas extremamente semelhantes a nível de construtores,
onde podemos pedir os construtores de uma classe para ela. Aqui foi minha
intenção não lidar com questões de construtores, apenas métodos, mas a
ideia por cima é muito semelhante.

Bem, conseguimos aqui já inspecionar algumas coisinhas. Entre elas
o tipo do retorno. Mas e se eu quisesse olhar para o tipo dos argumentos?
Bem, podemos procurar por `Method.getParameterTypes()`! Ele vai retornar
um array de classes com os tipos dos argumentos. Por exemplo, para verificar
se um método recebe uma string e um mapa como argumentos, nesta ordem
específica e apenas esses 2 elementos:

```java
Method m = ...;
if (m.getParameterCount() != 2) {
    return false; // early-return para exemplificar
}
Class[] paramTypes = m.getParameterTypes(); // sim, vai gerar warning porque Class pode ser paramétrica, mas não quero agora
return paramTypes[0] == String.class && paramTypes[1] == Map.class;
```

# Obtendo todos os tipos declarados de um objeto

Em java, um objeto sempre pertence a um tipo (indicado por uma instância da classe
`Class`). Mas não apenas isso. Uma classe pode derivar de outra classe, sendo a classe
base a classe `Object`. Devido a design da linguagem, uma classe só pode estender uma
classe mãe. Isso evita alguns _pitfalls_ comuns em linguagens que oferecem herança
múltipla (como o problema do diamante).

A classe `Object`, por sua vez, não tem classe mãe (a resolução do trilema de Münchausen
escolhida foi o axioma). Então basta iterar na classe puxando sua superclasse até chegar
no fim, confere? Bem, sim. Confere. Mas essa iteração não é trivialesca. `Class` não
implementa a interface `Iterator` ou `Iterable`, então isso aqui não é trivial:

```java
for (Class hipoteticamente: obj.getClass()) {
    // passando pelas classes mães
}
```

Para fazer isso, temos de recorrer a implementação clássica de iteração: com iteradores
ad-hoc em um `for` de 3 cláusulas, tipo os `for` de C/C++:

```java
for (Class c = obj.getClass(); c != null; c = c.getSuperClass()) {
    // passando pelas classes mães
}
```

Mas, será mesmo que esse é o único jeito? Na real não. Temos alternativas para isso.
Podemos implementar nosso próprio iterador. Como? Bem, simples. Um `Iterator<T>` em Java
é um objeto _stateful_ com dois métodos de interesse:

- `next()`
- `hasNext()`

De modo geral, se `hasNext()` retornar falso, isso significa que a chamada de `next()` é
insegura e irá disparar exceção. Isso fala sobre `hasNext()`. E `next()` por sua vez
faz duas coisas: retorna o objeto atual e move o estado interno para indicar que aquele
elemento já foi consumido.

"Como assim?", talvez você esteja se perguntando. Bem, vamos pra um exemplo simples.
Peguemos essa lista de 3 inteiros:

```none
    1   2   3
```

Ao começar a iterar nela, o primeiro elemento a ser resgatado seria o `1`. Então posso
indicar que o `next()` meio que aponta para o `1`:

```none
    1   2   3
    ^
    next
```

Ao chamar o método `next()`, o objeto `1` é retornado ao chamador e o `next()` agora
aponta para o `2`:

```none
    1   2   3
        ^
        next
```

Ao chamar o método `next()` novamente, o objeto `2` é retornado ao chamador e
o `next()` agora aponta para o `3`:

```none
    1   2   3
            ^
            next
```

Ao chamar o método `next()` novamente, o objeto `3` é retornado ao chamador e
o `next()` agora aponta para uma posição inválida:

```none
    1   2   3
                ^
                next
```

Uma próxima chamada para `next()` iria lançar uma exceção. Além disso, nesse
momento a chamada de `hasNext()` retorna `false`, enquanto nos momentos
anteriores retornava `true`.

A nível de implementação, você precisa garantir que se `hasNext()` retornar
`true`, isso significa que a chamada de `next()` não irá lançar exceção de
`java.util.NoSuchElementException`. Você não precisa (apesar de que seja
recomendado) que `next()` lance uma exceção ao chegar no final da iteração.

Pegando essa abordagem mais relaxada (de que não precisa lançar a exceção),
precisamos agora apenas garantir que consigamos carregar todas as classes e
classes mães da classe atual e de quem acima dela. Ou seja, enquanto ainda
houver classes a se retornar, pode pegar mais classes. Sabe aquele exemplo
com 3 números? Pois peguemos aqui um exemplo com 3 níveis de herança de
classes:

```none
BigDecimal    Number    Object
```

`BigDecimal` estende de `Number`, que por sua vez chega na raiz `Object` e
por lá fica. Ou seja, se fosse iterar, seria na mesma lógica que a lista
`[1, 2, 3]` apresentada antes:

```none
BigDecimal    Number    Object
^
next

BigDecimal    Number    Object
              ^
              next

BigDecimal    Number    Object
                        ^
                        next

BigDecimal    Number    Object
                                ^
                                next
```

Como fazer isso? Pois bem, mais simples do que se imagina. Vamos guardar
como estado a classe que será devolvida ao chamar `next()`. Ao chamar
`next()`, guardamos temporariamente o valor para ser retornado e, no estado
interno, sobrescrevemos com o valor da superclasse do elemento atual.
Algo assim:

```java
public Class<?> next() {
    Class<?> r = this.current;
    this.current = this.current.getSuperclass();
    return r;
}
```

A condição de continuar iterando se torna simples: verificar se o meu
elemento é não nulo. Se for nulo, retorna `false` e impede de prosseguir:

```java
public boolean hasNext() {
    return this.current != null;
}
```

Antes de mostrar toda a implementação, só mencionar rapidamente sobre
`Iterable`. Para poder utilizar em um `for-each` no Java, como em

```java
for (Class c: classes) {
    // faz algo
}
```

o objeto que está sendo feito o laço (no caso acima `classes`) precisa
implementar a classe `Iterable`. Mais especificamente, um objeto do
tipo `Iterable<T>` vai permitir que eu faça laços assim:

```java
for (T t: iterable) {
    // faz algo
}
```

E sabe o que essa classe faz? Ela simplesmente retorna um `Iterator<T>`.
Só isso. Como ela só tem um método, eu esqueço até mesmo qual é esse
método, pois afinal isso torna a interface uma interface funcional e,
como interface funcional, você pode escrever um simples lambda.

Portanto, para ter em um `for-each` clássico do Java a minha classe
e toda a sua ancestralidade, podemos fazer isso:

```java
public Iterable<Class<?>> classHierarchy(Object o) {
    return () -> new Iterator<Class<?>>() {
        Class<?> current = o.getClass();

        @Override
        public boolean hasNext() {
            return current != null;
        }

        @Override
        public Class<?> next() {
            final var r = current;
            current = current.getSuperclass();
            return r;
        }
    };
}
```

E pronto, agora eu posso chamar o iterador para pegar toda a hierarquia
da minha classe:

```java
for (Class<?> c: classHierarchy(obj)) {
    // faz algo
}
```

E, bem, eu posso expandir isso para usar em `Streams`, e de modo bem interessante
na real. Ao usar streams, existem algumas operações intermediárias que você pode usar,
sendo as mais famosas:

- `filter`: diminui a quantidade de elementos, mantendo o tipo
- `map`: muda o tipo do objeto atual em outro
- `flatMap`: transforma o objeto atual eu uma coleção de (potencialmente) outro tipo,
  permitindo trabalhar em cima desse outro tipo

Aqui queremos transformar uma classe em uma coleção de classes. Esse é o típico caso
de se usar `flatMap` para obter esse efeito. Mas existe uma opção que faz algo muito
parecido com o `flatMap` e me parece mais adequado para se usar agora: o `mapMulti`.

Como o `mapMulti` funciona? Bem, você recebe o elemento atual e algo que vai receber
elementos do tipo seguinte. E você literalmente invoca esse cara passando os novos
elementos. Por exemplo, um `mapMulti` que me retorna os divisores de um número:

```java
Stream.of(144)
    .mapMulti((atual, next) -> {
        next.accept(1);
        for (int i = 2; i < atual; i++) {
            if (atual % i == 0) {
                next.accept(i);
            }
        }
        next.accept(atual);
    }).toList();
```

Assim como `flatMap`, essa é uma operação intermediária. Basicamente toda e
qualquer chamada que for feita ao `next` ele passará adiante na `Stream`. É
praticamente um modo de construir streams sem precisar acumular nem listar todos
os elementos individualmente.

Nesse caso, me parece uma ótima alternativa para se buscar toda a hierarquia de
classes do objeto. Comecemos do objeto e, a partir dele, tenhamos a hierarquia de
classes:

```java
Stream.of(BigDecimal.ZERO)
    .map(Object::getClass)
    .mapMulti((atual, next) -> {
        do {
            next.accept(atual);
            atual = atual.getSuperclass();
        } while (atual != null);
    }).toList();
```

## Passando por interfaces

Passear pelas classes foi moleza. Agora, para pegar todos os tipos, precisamos
também passar por todas as interfaces. O que difere de buscar por classes
e buscar por interfaces? Bem, uma interface pode herdar de múltiplas outras
interfaces ao mesmo tempo.

Então agora a visita profunda para pegar todos os tipos se torna mais desafiante...
Sem mais delongas, bora lá?

Vou modelar aqui em um sistema de tipos que eu considero mais expressivo e rico.
Temos aqui um tipo, que pode ser uma classe ou uma interface. A classe, por sua
vez, pode ter uma superclasse e também tem uma coleção de interfaces. Uma interface
tem uma coleção de interfaces. Posso representar assim:

```ts
type objType = clazz | iface
type clazz = {
    superClass: clazz?,
    implementsIface: iface[]
}

type iface = {
    implementsIface: iface[]
}
```

Pela definição de Java, temos que interfaces não podem ser circulares. E
nesse nível de preocupação _generics_ não vai ser uma preocupação. As garantias
que a linguagem me fornece me dizem que eu vou precisar navegar por um DAG
(grafo direcionado acíclico, em inglês _directed acyclic graph_).

Bem dizer, eu quero visitar todos os tipos e supertipos. De interfaces. Mas
para visitar todos os tipos e supertipos eu preciso visitar toda a hierarquia
de classes de toda sorte. Bem, pois vamos lá. Vamos nos aproveitar do
`mapMulti` agora, pra valer.

Lembra que o `mapMulti` fornece um argumento que eu chamei de `next`?
Em uma `Stream<T>` o tipo de `next` é `Consumer<U>`. No caso atual,
vou de um `Stream<Class<?>>` e irei consumir outro `Class<?>`, mas
apenas por coincidência.

Para fazer a navegação por todos os tipos, usando um `Consumer`,
posso ter pensamentos recursivos agora (lembra que agora a questão não
é mais trivial linear). Vamos analisar primeiro o tipo `iface` (que
é uma metáforo para uma `Class` de interface no Java):

```ts
type iface = {
    implementsIface: iface[]
}
```

Eu posso pegar o meu `Consumer` e trabalhar nele assim (vamos chamar de
`visitor` já que para o que compete esse procedimento ele está só visitando):

```ts
function <T> void visitarIface(atual: iface, visitor: Consumer<objType>) {
    visitor.accept(atual);
    for (const superIface: atual.implementsIface) {
        visitarIface(superIface, visitor);
    }
}
```

Pareceu simples, né? E para as classes (tipo `clazz`)? Vou-me usar também da
questão da recursividade da definição:

```ts
function <T> void visitarClazz(atual: clazz, visitor: Consumer<objType>) {
    visitor.accept(atual);
    if (atual.superClazz) {
        visitarClazz(atual.superClazz, visitor);
    }
    for (const superIface: atual.implementsIface) {
        visitarIface(superIface, visitor);
    }
}
```

Pronto, fim de jogo. Vamos transpor para Java? E usar com  `mapMulti` no final?

```java
public void visitarIface(Class<?> atual, Consumer<Class<?>> visitor) {
    visitor.accept(atual);
    for (Class<?> iface: atual.getInterfaces()) {
        visitarIface(iface, visitor);
    }
}

public void visitarClazz(Class<?> atual, Consumer<Class<?>> visitor) {
    visitor.accept(atual);
    if (atual.getSuperclass() != null) {
        visitarClazz(atual.getSuperclass(), visitor);
    }
    for (Class<?> iface: atual.getInterfaces()) {
        visitarIface(iface, visitor);
    }
}

List<Class<?>> tipos = Stream.of(obj)
    .map(Object::getClass)
    .multiMap(this::visitarClazz)
    .toList();
```

Eventualmente isso pode passar pelas interfaces mais de uma vez, mas para resolver
isso só usar a operação intermediária `distinct()`, resolver em um `Set<Class<?>>`
ou até mesmo nem se importar com isso. Por exemplo, aqui a saída para os
tipos de `ArrayList`:

```java
jshell> Stream.of(new ArrayList<>()).map(Object::getClass).mapMulti((Class<?> a, Consumer<Class<?>> c) -> visitarClazz(a, c)).toList()
$44 ==> [class java.util.ArrayList, class java.util.AbstractList, class java.util.AbstractCollection, class java.lang.Object,
         interface java.util.Collection, interface java.lang.Iterable, interface java.util.List, interface java.util.SequencedCollection,
         interface java.util.Collection, interface java.lang.Iterable, interface java.util.List, interface java.util.SequencedCollection,
         interface java.util.Collection, interface java.lang.Iterable, interface java.util.RandomAccess, interface java.lang.Cloneable,
         interface java.io.Serializable]
```

Eu precisei tipar o `mapMulti`, não fui atrás de saber como que funciona por debaixo
dos panos a criação de funções não estáticas no jshell, nem sabia como que era
referenciado o momento atual (descobri posteriormente que não existia o `this` no
jshell). Então por via das dúvidas no lugar de usar um nome de classe arbitrário
preferi usar uma lambda explícita com seta `->` no lugar de referência de método
`::`.

Mais tarde, escrevendo outra porção deste post, descobri que posso escolher tipar
a invocação do método no lugar de tipar os argumentos do lambda:

```java
jshell> Stream.of(new ArrayList<>()).map(Object::getClass).<Class<?>>mapMulti((a, c) -> visitarClazz(a, c)).toList()
```

# Injeção de dependência orientada a tipos... em TotalCross

> Eu passei por essa necessidade, [veja](https://gitlab.com/totalcross/TotalCross/-/issues/590).

Bem, muito tempo atrás, o Jeff que aqui vos fala precisava lidar com inicialização de classes
em TotalCross. As classes da camada de negócio eram as mesmas que as utilizadas por um serviço
Spring, e eu precisava injetar nelas objetos de acesso ao banco de dados. Fazia um tempo já
que TotalCross aceitava **não quebrar** ao ter anotações no código, porém na versão utilizada
as anotações eram removidas do classfile ao ser transpilado em TCZ. O que significava que eu não
poderia usar diretamente anotações no TotalCross.

> Usar anotações para gerar código, entretanto, seria válido para TotalCross, inclusive
> havia suporte para [Dagger](https://dagger.dev/). Mas na época isso não foi investigado
> para resolver as questões de onde eu trabalhava.

A priori a quantidade de elementos para lidar com essa questão de injetar era pequena. Cerca
de 40, 50 elementos que deveriam ser injetados, era tudo feito na mão. Mas esse número estava
crescendo cada vez mais, e estava ficando insustentável tentar manter essa estrutura. Além disso,
muita coisa que estava na camada de negócio era, na realidade, especificidades do app mobile
em TotalCross, e esses métodos estavam sendo calmamente removidos da interface comum, e o começo do
desenvolvimento do app mobile em Flutter acabou pesando fortemente para que essa separação
ocorresse de maneira mais intensa. Então essas 40 injeções iriam aumentar consideravelmente
nas próximas iterações.

Para evitar cair na insanidade, automatizar isso se tornou uma necessidade. Mas, como fazer isso?
Bem, inspirado (de maneira muito superficial e porca) no Spring, a ideia era ter um conjunto de
objetos gerenciados pelo motor de injeção de dependência e, ao detectar algum ponto aberto que
teria uma dependência a se suprir, verificar se tinha algum objeto de tipo compatível e inserir
esse objeto na dependência. Por uma questão de limitação de conhecimento técnico, não iria
ser feito geração de código. Como a aplicação ainda estaria em "startup time", eu poderia criar
sem medo os objetos em estado inválido e ajeitar o estado antes do término da inicialização
do aplicativo. Portanto seria feito injeção de dependência via setters.

E a obtenção dos elementos a serem gerenciados? Bem, esses tinham classes de "configuração"
com métodos para resgatar esses elementos, construídos de modo muito básico. Como eram muitos
elementos, foi convencionado que eles seriam indicados por getters. Para essas classes de
configuração, todo método público de instância que começasse com `get` e tivesse zero parâmetros
seria um objeto para ser gerenciado.

Listar esses objetos era tranquilo então. O `get*` trazia o resultado e eu era feliz. Como
o getter em si não me era interessante, eu percorria para achar os getters e depois resolvia
eles. Algo mais ou menos assim:

```java
record InvokeResult(Exception err, Object value) {
    static InvokeResult value(Object value) {
        return new InvokeResult(null, value);
    }
    static InvokeResult err(Exception err) {
        return new InvokeResult(err, null);
    }

    boolean isError() {
        return err != null;
    }
}

InvokeResult wrapInvoke(Method m, Object self, Object... args) {
    try {
        return InvokeResult.value(m.invoke(self, args));
    } catch (Exception e) {
        return InvokeResult.err(e);
    }
}

Object configObject = ...;
List<InvokeResult> managedObjectsResult = Stream.of(configObject.getClass().getMethods())
    .filter(m -> m.getName().startsWith("get") && m.getParameterCount() == 0)
    .map(m -> wrapInvoke(m, configObject))
    .toList();

Optional<Excxeption> initFailures = managedObjectsResult.stream()
    .filter(InvokeResult::isError)
    .map(InvokeResult::err)
    .reduce((e1, e2) -> {
        e1.addSuppressed(e2);
        return e1;
    });

if (initFailures.isPresent()) {
    throw initFailures.get();
}

List<Object> managedObjects = managedObjectsResult.stream()
    .map(InvokeResult::value)
    .toList();
```

Com isso obtenho a lista de objetos gerenciados por mim. Mas isso não
me é o suficiente. Eu quero injetar baseado no seu tipo. Então, vamos
abrir para todos os tipos do objeto em questão? Incluindo interfaces
e tudo o mais?

Pois bem:

```java
record ManagedObjectWithType(Object obj, Class<?> type) {}

List<ManagedObjectWithType> managedObjectsWithType =
    managedObjects.stream()
        .<managedObjects>mapMulti((atual, next) ->
            visitarClazz(atual.getClass(), t -> next.accept(new ManagedObjectWithType(atual, t))))
        .toList();
```

Quando eu precisar encontrar algo com a classe `Xyz`, agora só fazer isso:

```java
<Xyz> Xyz getSingleObjectForInjectionByClazz(Class<Xyz> xyz) {
    List<Xyz> candidatos = managedObjectsWithType.stream()
        .filter(mo -> mo.type() == xyz)
        .map(ManagedObjectWithType::obj)
        .toList();
    if (candidatos.size() != 1) {
        throw new RunTimeException("Esperava encontrar apenas um candidato, mas encontrou uma quantidade diferente: " + candidatos.size());
    }
    return candidatos.get(0);
}
```

Devido a uma característica peculiar, também se faz necessário inserir uma lista
de objetos que implementam a mesmo interface:

```java
<Xyz> List<Xyz> getListObjectsForInjectionByClazz(Class<Xyz> xyz) {
    return managedObjectsWithType.stream()
        .filter(mo -> mo.type() == xyz)
        .map(ManagedObjectWithType::obj)
        .toList();
}
```

Vamos falar dessa peculiaridade logo? Pois bem, alguns desses objetos gerenciados
eram chamados de `BufferedDAO`s. O que é isso? São objetos de acesso à persistência
que tinham dois métodos a mais:

- `clearBuffer()`
- `loadBuffer()`

Basicamente deixavam algumas informações muito importantes pré-carregadas já.
Não eram todos os objetos que precisavam disso, então nem todo objeto implementava
essa interface, mas de toda sorte existiam momentos críticos no ciclo de vida
da aplicação que esse reset de dados precisava ser feito:

```java
List<BufferedDAO> bufferedDAOs = getListObjectsForInjectionByClazz(BufferedDAO.class);
```

E assim eu mantenho a variável `bufferedDAOs` em algum lugar que o ciclo
de vida da aplicação consiga chamar ele para fazer a nova cargar de
dados.

Perfeito, agora eu tenho a lista de objetos parcialmente preenchidos. Para
terminar de preencher eles, preciso injetar nesses objetos suas dependências.
Note que aqui o meu modelo aceita com tranquilidade dependências circulares
de objetos. E dependência circular de objetos normalmente é uma coisa ruim,
coisa que devemos evitar. Mas aqui foi uma escolha consciente ter dependências
circulares.

Para cada um dos objetos gerenciados, eu quero pegar o método de instância
público que seja um setter (começa com `set` e tenha um único argumento).
Para cada setter desses, caso não seja possível determinar quem deveria
ser o parâmetro de chamada, devemos abortar o processo de inicialização
da maneira mais catastrófica possível.

```java
record ObjectAndSetter(Object o, Method setter) {
    Class<?> toBeSettedType() {
        return m.getParameterTypes()[0];
    }
    InvokeResult inject(Object arg) {
        return wrapInvoke(o, setter, seg);
    }
}

final var injectedIntoManagedResult = managedObjects.stream()
    .flatMap(mo -> {
        
        return Stream.of(mo.getClass().getMethods())
            .filter(m -> m.getName().startsWith("set") && m.getParameterCount() == 1)
            .map(m -> new ObjectAndSetter(mo, m));
    })
    .map(os -> {
        Class<?> classToInject = os.toBeSettedType();
        Object toBeInjected = Objects.requiresNonNull(getSingleObjectForInjectionByClazz(classToInject));
        return os.inject(toBeInjected);
    })
    .toList();

Optional<Excxeption> setterFailures = injectedIntoManagedResult.stream()
    .filter(InvokeResult::isError)
    .map(InvokeResult::err)
    .reduce((e1, e2) -> {
        e1.addSuppressed(e2);
        return e1;
    });

if (setterFailures.isPresent()) {
    throw setterFailures.get();
}
```

## Treta de TotalCross: identificar classe

Ok, no TotalCross eu não tenho acesso a `record`s, não tenho acesso a funções lambda,
nem tampouco tenho acesso à API de streams do Java 8. Mas essas coisas não foram
grandes impeditivos:

- para `record`, usar classe mesmo
- para funções lambda, usar retrolambda
- para a API de Stream do Java 8, usar a lib que provê uma API muito similar (futuramente
  um post no Computaria sobre essa lib)

E tudo isso consegui contornar. Mas tem algo que não conseguia contornar facilmente:
carregar o `BufferedDAO` a partir de referência estática. Isso acontecia porque, devido
a alguma característica da plataforma, `BufferedDAO.class` era diferente da classe obtida
a partir da declaração do método/obtido a partir do objeto em runtime.

Para contornar isso? Basicamente... pegar de um objeto de runtime...

```java
List<BufferedDAO> bufferedDAOs = getListObjectsForInjectionByClazz((Class<BufferedDAO>) new BufferedDAO() {

    //... implementação tosca dos métodos

}.getClass().getInterfaces()[0]);
```

# Proxy

Antes de falar de proxy dinâmico, vamos falar de proxy? Do objeto de proxy?

Um objeto de proxy é um objeto que simplesmente vai delegar a responsabilidade
para outro objeto processar. As vezes ele pode ser utilizado para decorar a chamada
(em breve retornarei a isto, decorar chamadas de funções). Vamos criar um proxy
simples para depurar com uma mensagem: "Oi, eu sou o Goku". Essa mensagem deve
ser impressa quando for chamado um `Consumer<String>`. O meu objeto real é:

```java
void doAsyncProcessing(Consumer<String> consumer) {
    // ... alguma coisa demorada
    consumer.accept(value);
}

// ...
ComponenteTexto componente = ...;

doAsyncProcessing(componente::setText);
```

Agora, vamos adicionar a capacidade de depuração. O código `doAsyncProcessing`
é totalmente agnóstico a o que ocorre com a chamada de `consumer.accept(value)`,
então não iremos mais nos preocupar com esse trecho do código.

Uma alternativa para adicionar essa capacidade de depuração seria simplesmente
fazer de modo totalmente ad-hoc:

```java
doAsyncProcessing(v -> {
    System.out.println("Oi, eu sou o Goku");
    componente.setText(v);
});
```

Esse novo objeto que está sendo criado está servindo de proxy para a chamada
`componente.setText`. Mas está ainda de modo bem não estruturado. Se eu
quisesse usar essa decoração específica em outros proxies eu não conseguiria
replicar. Mas eu posso criar a decoração passando o objeto que eu quero
delegar a computação:

```java
<T> Consumer<T> oiEuSouGokuProxy(Consumer<T> objReal) {
    return t -> {
        System.out.println("Oi, eu sou o Goku");
        objReal.accept(t);
    };
}

doAsyncProcessing(oiEuSouGokuProxy(componente::setText));
```

Esse uso para fazer o proxy pode não ser muito útil... mas podemos fazer
umas coisinhas bem legais, não é? Imagina que eu queira deixar o componente
indisponível até o fim do processamento assíncrono. Como faríamos? Bem,
poderíamos aproveitar que vamos proxyar para liberar o componente,
adicionando funcionalidades no objeto de proxy:

```java
<T> Consumer<T> runAfterProxy(Consumer<T> objReal, Runnable actionAfterProxy) {
    return t -> {
        objReal.accept(t);
        actionAfterProxy.run();
    };
}

componente.setLock(true);
doAsyncProcessing(runAfterProxy(componente::setText, () -> componente.setLock(false)));
```

Um exemplo de proxy muito conhecido no mundo Java (que muitas vezes não
é tratado como proxy) é a obtenção de uma conexão JDBC ao se pedir ao data
source do Hikari CP. Muitas palavras para pouco sentido? Bem, vamos aos poucos.

Em Java, temos um padrão de comunicação com bancos de dados: o JDBC (Java Data Base
Connectivity). Um dos conceitos centrais do JDBC é o conceito de `Connection`.
A partir da conexão que iremos fazer novas queries, e das queries obter resultados
ou atualizar de fato coisas no banco. Para abrir uma conexão eu preciso saber
com qual banco estou me conectando, muitas vezes usuário e senha, endereço de
rede de onde está o banco (ou endereço físico do disco no caso de SQLite).

Só que obter conexões é um processo caro, e isso pode estressar o banco. Porque
uma conexão é uma sessão longa conectada no banco, com possível isolamento de
transação e outras coisas. A nível de programador, sua obrigação ao requisitar
uma conexão JDBC é sempre liberar o objeto de conexão. Algo assim pode ocorrer:

```java
try (Connection conn = getDatabaseConnection()) {
    // ...
}
```

Colocando a conexão obtida dentro de um `try-with-resources`, portanto
garantindo que o método `conn.close()` seja sempre chamado. Essa função
`getDatabaseConnection` precisa conhecer os detalhes de conexão com o banco
ou então chamar quem conhece esses detalhes. Pois bem, o JDBC também fornece
o conceito de `DataSource`. O `DataSource` por sua vez é um objeto que
permite pegar uma conexão (em dois sabores: o primeiro só pegar a conexão
e o segundo é tipo o primeiro mas com usuário e senha explícitos).
É comum nesse caso que o `getDatabaseConnection()` internamente tenha uma
chamada ao `DataSource` ou que ele simplesmente seja chamado diretamente:

```java
try (Connection conn = dataSource.getConnection()) {
    // ...
}
```

Só que, bem, obter conexões é caro, como estabeleci antes. Então podemos
trabalhar melhor em cima disso. Sobre os `DataSource`s, o pessoal passou
a escrever pools de conexões com o banco de dados. Assim, ao criar uma
conexão, ela é adicionada ao pool de recursos, e o `close` não literalmente
terminaria a conexão com o banco de dados, mas permitiria que essa conexão
fosse reutilizada.

Para lidar com o pool de conexões, o Hikari CP cria diversas conexões com
o banco de dados (normalmente já cria o máximo de conexão) e, bem dizer,
exceto em situações muito excepcionais, mantém essas conexões até ser
liberado. O `close` do objeto do tipo `Connection` obtido do `DataSource`
do Hikari não irá fechar a conexão com o banco de dados, mas sim devolver
aquela conexão específica para o pool de conexões.

A conexão obtido pelo Hikari é independente da conexão real por debaixo.
Então todas as chamadas praticamente (com exceção do `.close()`) vai delegar
para o `Connection` verdadeiro. No caso de chamar funções que geram novos
elementos JDBC, que cria um recurso temporário que precisa ser liberado
(como `PreparedStatement`), esse novo objeto gerado carregará dentro dele
uma versão do objeto adequado de acesso ao banco, porém com um diferencial
para tratar de questões de `close` desses recursos internos dele.

Então o Hikari CP irá servir de proxy para os objetos que lidam diretamente
com o banco de dados, colocando algumas abstrações acima (como por exemplo
abrir todas as conexões ao iniciar a aplicação e ficar constantemente
reciclando-as), mas de modo geral ele cria proxies para gerencias detalhes
que impactam significativamente a performance da aplicação.

Aqui explorei algumas possibilidades de se fazer proxy contra interfaces,
mas o pessoal do Java permitiu ir muito além disso. Por exemplo, o próprio
Spring gera proxy de objetos em cima de classes. Mas meu foco aqui é
tocar em aspectos de reflexão do Java, e essas coisas são de outros aspectos.
Vamos agora explorar algo com reflexão de verdade?

## Proxy dinâmico

O proxy dinâmico é uma maneira simples de se interceptar todos os métodos
de interfaces. Para criar um proxy, você precisa determinar como você
vai lidar ao receber argumentos para um processamento de um método.
Além de informar isso, precisa registrar no `ClassLoader`.

Uma coisa que o proxy dinâmico permite fazer é colocar decorações em cima
de qualquer chamada. Vamos ver como se comporta isso?

Peguemos aqui o caso de fazer o proxy de um `Consumer<T>`:

```java
Consumer<String> componenteSetText = componente::setText;
Consumer<T> decorated = (Consumer<T>) Proxy.newProxyInstance(this.getClass().getClassLoader(),
    new Class[] { Consumer.class },
    (proxy, m, args) -> {
        System.out.println("Fool of a Tuck");
        return m.invoke(componenteSetText, args);
    }
);
return decorated;
```

Agora literalmente toda chamada para o objeto de proxy irá escrever
"Fool of a Tuck" e logo em seguida fazer a chamada convencional do
objeto proxyado.

Agora, isso não precisa ser a única função do proxy reverso. Eu posso
literalmente usar ele para gerar saídas convincentes. Por exemplo,
no projeto de transportar para o Flutter, mencionado na introdução
deste post, uma das coisas que foi feita foi tratar implementações
padrão no Android.

Imagina que se tem um DAO. Sei lá, `JeffDAO`. Esse DAO tem vários
métodos, alguns retornam números, outros retornam objetos java,
outros ainda retornam coleções. E no Android temos a classe
`JeffDAO_Android`. Essa classe não implementa `JeffDao` por uma
questão de escrita de código automatizada.

Suponha que consigamos identificar que um método de uma interface
tem a mesma assinatura de um método de uma classe fora da
hieraraquia de implementações. Nesse caso, façamos a chamada
padrão. Mas vai ter situações que `JeffDAO_Android` ainda não
implementou algum método de `JeffDAO` (já que ele nem tem
obrigação, porque não implementa a interface). Bem, nesse caso
quero fazer duas coisas:

1. registrar qual foi o método faltoso (basta o nome do método)
2. retornar um valor padrão, que depende do retorno do método

Os valores default são:

- para alguma coleção simples, como `Collection`/`List`/`Set`,
  a coleção vazia
- para vetores (`array` clássico, como `int[] v`), um vetor
  vazio
- `0`, para números (e suas variações como o 0L, o zero do long)
  - não se esquecer do zero para `BigDecimal`
- `false`, para `boolean` (não para `Boolean`)
- nulo para todo o resto (incluindo para `Map`)
- para `void`, bem, qualquer coisa funciona, vou retornar `null`
  por via das dúvidas

Então, vamos criar o proxy dinâmico que segue esses características?

```java
JeffDAO getProxyObject(JeffDAO_Android original) {
    return (JeffDAO) Proxy.newProxyInstance(this.getClass().getClassLoader(),
        new Class[] { JeffDAO.class },
        (proxy, m, args) -> {
            if (validProxyCall(m, args, original)) {
                return doCall(m, args, original);
            }
            System.out.println("chamada ainda não implementada, método " + m.getName());

            final var returnTypeProxy = m.getReturnType();
            if (List.class.isAssignableFrom(returnTypeProxy)) {
                reutrn List.of();
            }
            if (Set.class.isAssignableFrom(returnTypeProxy)) {
                reutrn Set.of();
            }
            if (Collection.class.isAssignableFrom(returnTypeProxy)) {
                reutrn List.of();
            }
            if (BigDecimal.class.isAssignableFrom(returnTypeProxy)) {
                reutrn BigDecimal.ZERO;
            }
            if (returnTypeProxy == void.class) {
                return null;
            }
            if (returnTypeProxy.isPrimitive()) {
                return appropriateZeroValue(returnTypeProxy);
            }
            if (returnTypeProxy.isArray()) {
                return appropriateEmptyArray(returnTypeProxy);
            }

            return null;
        }
    );
}
```

Ok, vamos descobrir os tipos apropriados de zero? Para isso, preciso saber
os primitivos. Seguindo a [especificação da
linguagem](https://docs.oracle.com/javase/specs/jls/se23/html/jls-4.html),
os tipos possíveis são:

- `boolean`
- `byte`
- `short`
- `char`
- `int`
- `long`
- `float`
- `double`

Ele não fala do tipo `void` nessa seção, mas `void.class.isPrimitive()`
retorna `true`.

Ok, pois vamos lá com `Object appropriateZeroValue(Class<?> type)`,
estratégia exaustiva mesmo:

```java
Object appropriateZeroValue(Class<?> type) {
    if (type == boolean.type) {
        return false;
    }
    if (type == float.class) {
        return 0.0f;
    }
    if (type == double.class) {
        return 0.0;
    }
    if (type == long.class) {
        return 0L;
    }
    if (type == char.class) {
        return '\0';
    }
    return 0;
}
```

Para os outros tipos primitivos (`int`, `short`, `byte`) não
tem como eu escrever literalmente. A [especificação
Java](https://docs.oracle.com/javase/specs/jls/se23/html/jls-3.html#jls-3.10.1)
só dá o sufixo para long.

Para array clássico, preciso retornar um array vazio. A API de reflection
do java fornece algo para criar um array clássico,
[`Array.newInstance`](https://docs.oracle.com/en/java/javase/22/docs/api/java.base/java/lang/reflect/Array.html#newInstance(java.lang.Class,int)).
Isso permite instanciar a coisa adequada. Mas ainda preciso pegar o tipo do
componente que irá para o array. Tipo, se eu fizer simplesmente
`Array.newInstance(returnTypeProxy, 0)` e o tipo de `returnTypeProxy`
é `String[]`, o retorno será um `String[0][]`. Então, como pegar
o tipo dos componentes do array? Bem, se meu objeto de `Class<?>`
retornar verdadeiro para `isArray()`, então ele irá retornar o
tipo em `getComponentType()`. A implementação pode ser simplesmente:

```java
Object appropriateEmptyArray(Class<?> type) {
    return Array.newInstance(tClazz.getComponentType(), 0);
}
```

Eu tentei tipar corretamente o método mas não funcionou quando
tentei instanciar primitivos (até porque tipos primitivos em java
não estão disponíveis para generics):

```java
<T> T[] appropriateEmptyArray(Class<? extends T[]> tClazz) {
    return (T[]) Array.newInstance(tClazz.getComponentType(), 0);
}
```

A opção acima funciona (apesar do warning) quando o componente do array
é um tipo de referência, como `String[]`.

Inclusive, o array retornado por `Array.newInstance` vem todo zerado.
Isso fornece uma outra abordagem para retornar o valor zerado de primitivos:

```java
Object appropriateZeroValue(Class<?> type) {
    Object zeroedArray = Array.newInstance(type, 1);
    if (type == boolean.type) {
        return Array.getBoolean(zeroedArray, 0);
    }
    if (type == float.class) {
        return Array.getFloat(zeroedArray, 0);
    }
    if (type == double.class) {
        return Array.getDouble(zeroedArray, 0);
    }
    if (type == long.class) {
        return Array.getLong(zeroedArray, 0);
    }
    if (type == char.class) {
        return Array.getChar(zeroedArray, 0);
    }
    if (type == byte.class) {
        return Array.getByte(zeroedArray, 0);
    }
    if (type == short.class) {
        return Array.getShort(zeroedArray, 0);
    }
    if (type == int.class) {
        return Array.getInt(zeroedArray, 0);
    }
    return 0; // por via das dúvidas
}
```

Isso me fornece uma habilidade extra para retornar o valor zerado
adequado. Para quem quiser por esse lado overpower, tá aí.

Mas vamos lá. Ainda preciso saber responder isso: `validProxyCall`?
Como validar?

Bem, podemos pedir para a instância de `JeffDAO_Android` se ele tem aquele
método em questão. Em Java, identificar o método é verificar sua assinatura,
que consiste no nome do método e nos tipos dos argumentos. Em cima dessas
informações, vai ser iniciada uma busca na vtable do objeto em questão.
Se o objeto em questão for declarado como sendo uma interface (o tipo
que o compilador conhece), o output será o bytecode `invokeInterface` e
a busca na vtable é uma das mais ineficientes possível. Caso seja feito
a partir de um objeto (o compilador já sabe o tipo do objeto), o output
será o `invokeVirtual` e isso ajuda a percorrer a vtable de modo muito
mais eficiente.

A classe `Class` tem métodos para fazer isso:

- `getMethod(String name, Class<?> ...args)`
- `getDeclaredMethod(String name, Class<?> ...args)`

A diferença é que o `getDeclaredMethod` retornará o método público.
Mesmo se não tivesse isso, seria possível fazer uma busca exaustiva
usando uma estratégia similar a que foi usada em
`listarMetodosInstanciaBonitos`, algumas seções atrás.
Então, sabendo disso, como podemos implementar `validProxyCall`?
Bem, investigando os métodos em `original`!

Vamos pegar de `original` o método que tem o mesmo nome e os mesmos
argumentos que o método declarado que foi invocado:

```java
boolean validProxyCall(Method m, Object[] args, Object original) {
    Class<?> clazz = original.getClass();
    try {
        clazz.getDeclaredMethod(m.getName(), m.getParameterTypes());
        return true;
    } catch (NoSuchMethodException e) {
        return false;
    }
}
```

Hmmm, notei que esse `args` está desnecessário, e que depois de fazer
essa reflexão toda ainda preciso me preocupar em fazer ela novamente
para `doCall`. Hmmmm. E se eu já gerasse uma chamda com isso tudo?

```java
@FunctionalInterface
interface ReflectionCall {
    Object invoke(Object... args) throws IllegalAccessException, InvocationTargetException;
}

ReflectionCall getProxyCall(Method m, Object original) {
    Class<?> clazz = original.getClass();
    try {
        Method mOriginal = clazz.getDeclaredMethod(m.getName(), m.getParameterTypes());
        return (args) -> mOriginal.invoke(original, args);
    } catch (NoSuchMethodException e) {
        return null;
    }
}

JeffDAO getProxyObject(JeffDAO_Android original) {
    return (JeffDAO) Proxy.newProxyInstance(this.getClass().getClassLoader(),
        new Class[] { JeffDAO.class },
        (proxy, m, args) -> {
            final var proxyCall = getProxyCall(m, original);
            if (proxyCall != null) {
                return proxyCall.invoke(args);
            }
            System.out.println("chamada ainda não implementada, método " + m.getName());

            //...
        }
    );
}
```

# Anotando código

Até então, fizemos reflexão com poder de modificação. Mas toda informação extra que eu
poderia retirar era apenas do shape dos objetos e métodos. Mas existe algo ainda mais
potente que não foi explorado. Capacidade de dar informações extra para modificar
comportamentos específicos.

Por exemplo, antigamente para rodar algo no jeito clássico do Java com J2EE, se
usava o famigerado `web.xml`. Colocar aqui um trecho desse arquivo de um
[repositório aberto](https://github.com/spring-projects/spring-integration-samples/blob/main/applications/loanshark/src/main/webapp/WEB-INF/web.xml):

```xml
    <filter>
        <filter-name>Spring OpenEntityManagerInViewFilter</filter-name>
        <filter-class>org.springframework.orm.jpa.support.OpenEntityManagerInViewFilter</filter-class>
    </filter>

    <!-- omitido -->

    <filter-mapping>
        <filter-name>Spring OpenEntityManagerInViewFilter</filter-name>
        <url-pattern>/*</url-pattern>
    </filter-mapping>

    <!-- omitido -->

    <servlet>
        <servlet-name>loanshark</servlet-name>
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
        <init-param>
            <param-name>contextConfigLocation</param-name>
            <param-value>/WEB-INF/spring/webmvc-config.xml</param-value>
        </init-param>
        <load-on-startup>1</load-on-startup>
    </servlet>

    <!-- omitido -->
    
    <servlet-mapping>
        <servlet-name>loanshark</servlet-name>
        <url-pattern>/</url-pattern>
    </servlet-mapping>
```

Tá, mas o que esses caras são? Bem, vamos começar com o `filter-mapping`
e `servlet-mapping`. Cada nó desse tem 2 filhos:

- `...-name`, indicando qual a referência do objeto a ser colocado no mapping
- `url-pattern`, indicando quais são os paths que vai ter essa entidade acima
  referenciada acima

Bem, advinha o que aconteceu com isso em específico? Eu posso gerar essa
informação colocando esse tipo de informação na classe que eu quero que
tenha esse efeito! Aqui no caso do Spring Boot que irei citar abaixo
ele não injeta todo um servlet para fim de mapeamento, mas ele injeta
o servlet no contexto adequado e, dentro desse servlet, ele invoca um
ou outro método explícito de acordo com anotações na classe.

Abaixo um exmeplo tirado do próprio [site do
Spring](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller/ann-requestmapping.html):

```java
@RestController
@RequestMapping("/persons") // <=== atenção aqui!!!
class PersonController {

	@GetMapping("/{id}") // <=== atenção aqui!!!
	public Person getPerson(@PathVariable Long id) {
		// ...
	}

	@PostMapping // <=== atenção aqui!!!
	@ResponseStatus(HttpStatus.CREATED)
	public void add(@RequestBody Person person) {
		// ...
	}
}
```

Através da anotação `@RequestMapping` no tipo, o autor indica que ele receberá
chamadas na URL `/persons`. Então ele anota o método `getPerson` com `@GetMapping`,
e nesse caso específico `@GetMapping` tem mais uma parte de path. Essa anotação
indica que `/persons/42` irá invocar o método `getPerson` passando `42` como
argumento. E por último temos o método `add`, que dentro dele tem um `@PostMapping`.
Dessa vez o `@PostMapping` não tem nenhum trecho de URL associado, o que indica
que ele responde a chamadas em `/persons`. Devido a anotação ele só irá responder
chamadas de POST recebidas pelo Java. Os detalhes de como conseguir alcançar esses
comportamentos via reflection será visto mais tarde.

Com as anotações, o autor do código consegue fornecer mais informações que o
código pode usar em si mesmo. Inclusive isso pode ser feito para substituir XMLs
malucos de configuração! Basta que quem escreveu o processamento do XML tenha
feito uma alternativa processando anotações.

## Os usos de anotação

De modo geral, em Java, anotações vão servir alguns propósitos:

- gerar código
- quebrar compilação/mudar warning
- permitir processamento de bytecode
- permitir criação de proxy dinâmico/decorator (ou equivalente)

Um uso de geração de código via anotações é o [Lombok](https://projectlombok.org/).
Com o Lombok, você pode anotar na sua classe com `@EqualsAndHashCode` e
o processador de anotações do Lombok irá gerar os bytecodes tanto do método `equals`
como também do método `hashCode`.

> Eu, pessoalmente, tenho uma visão crítica do Lombok, eu não recomendo usar e
> eu evito usar, mas que o pessoal por trás dele fez um negócio muito massa
> de se estudar eu preciso admitir!

Para quebrar compilação, eu conheço duas anotações do próprio Java que fazem
isso. `@Override` quando adicionado em um método vai comparar se tem algum
método compatível na classe mãe ou nas interfaces que a classe implementa;
se não encontrar, vai quebrar a compilação. Por exemplo:

```java
class Batata {

    @Override
    BatataFrita fritar() {
        return new BatataFrita(this);
    }
}
```

Como `Batata` não tem superclasse explícita nem tampouco implementa nenhuma
interface, ela só tem `Object` para olhar pelo método `fritar` que não recebe
argumentos e que devolve algo que `BatataFrita` seja compatível. Como não
tem um método assim em `Object`, a compilação vai quebrar.

Aqui quebrar a compilação é algo _útil_. Imagina que você tem a interface
`JeffDAO`, e tem a implementação em Spring `JeffDAOSpring`. Se por algum
motivo a API de `JeffDAO` alterar (por exemplo, o método `void marmota()`
foi removido), com essa anotação vai ser fácil verificar que na implementação
ela está tentando sobrescrever uma coisa que não existe mais.

Outra coisa interessante com função de quebrar compilação é a anotação
`@FunctionalInterface`. Essa anotação pode ser colocada em interfaces
e serve para garantir que a interface seja mantida sempre em um estado
que o Java denomina de "interface funcional". Isso permite que seja
usada a sintaxe de funções lambda do Java para essas interfaces.

Por exemplo, a interface a seguir não é uma interface funcional
para a representação de [aritmética de
Peano]({% post_url 2024-09-02-peano-haskell %}):

```java
interface Peano {
    Peano previous();
    Peano succ();
}
```

Mas poderíamos transformar ela em uma interface funcional:

```java
interface Peano {
    Peano previous();
    default Peano succ() {
        return () -> this;
    }
}
```

Agora imagina que eu posso querer aumentar essa interface, por exemplo
com o método `Peano add(Peano)`. Hipoteticamente se tivesse alguma
implementação que dependia que `Peano` fosse uma interface funcional,
adicionar o método iria fazer com que isso parecesse uma coisa inofensiva:

```java
interface Peano {
    Peano previous();
    Peano add(Peano o);
    default Peano succ() {
        return () -> this;
    }
}
```

Porém fazendo isso eu quebrei todos que usavam lambda para implementação
dessa interface. Para garantir que essa interface seja válida sempre,
podemos facilmente fazer essa mudança:

```java
@FunctionalInterface
interface Peano {
    Peano previous();
    Peano add(Peano o);

    default Peano succ() {
        return () -> this;
    }
}
```

E pronto, agora a compilação quebra logo na cara! Não preciso esperar um
cliente hipotético vir reclamar porque importava a lib e na versão anterior
funcionava e agora não funciona mais! Mas, como resolver para esse caso
da aritmética de Peano, né?

Bem, vamos lá. Vou convencionar que o zero retorna a si mesmo. Então se
um objeto retorna algo diferente, esse objeto é um sucessor de zero,
direta ou indiretamente. Vamos pegar o estado válido anterior, adicionar
a anotação para garantir que não saiamos da validade e adicionar a
geração do zero:

```java
@FunctionalInterface
interface Peano {
    Peano previous();

    default Peano succ() {
        return () -> this;
    }

    static Peano zero() {
        return new Peano() {

            @Override
            Peano previous() {
                return this;
            }
        };
    }
}
```

Muito bem. Preciso fazer a detecção do zero de um número. Posso fazer
isso no método de `add` ou então extrair isso. Vou optar por extrair o
`isZero()`:

```java
@FunctionalInterface
interface Peano {
    Peano previous();

    default boolean isZero() {
        return this == previous();
    }

    default Peano succ() {
        return () -> this;
    }

    static Peano zero() {
        return new Peano() {

            @Override
            Peano previous() {
                return this;
            }
        };
    }
}
```

Ok, lembrando aqui da `addNat`, ela é definida assim:

```haskell
addNat :: Nat -> Nat -> Nat
addNat x Zero = x
addNat x (Suc y) = addNat (Suc x) y
```

Então a adição, em Java, vai ser determinar se o RHS é zero. Se for,
retorna `this`. Caso contrário, só retornar a soma do sucessor de `this`
com o predecessor do outro arugmento:

```java
@FunctionalInterface
interface Peano {
    Peano previous();

    default boolean isZero() {
        return this == previous();
    }

    default Peano succ() {
        return () -> this;
    }

    default Peano add(Peano outro) {
        if (outro.isZero()) {
            return this;
        }
        return succ().add(outro.previous());
    }

    static Peano zero() {
        return new Peano() {

            @Override
            Peano previous() {
                return this;
            }
        };
    }
}
```

E assim usamos a anotação para controlar a evolução do código, quebrando a compilação
quando ele deriva para algo desnecessário.

Uma das maneiras que se pode usar anotações para manipular warnings do compilador
é usando a `@SuppressWarnings`. Ao utilizar essa anotação, você suprime os avisos
que você especificou. Inclusive aqui você pode anotar para remover warnings do Sonar
Qube.

Outro uso é quando há mistura de varargs com generics. Para se aprofundar mais,
só conferir [este artigo do Baeldung](https://www.baeldung.com/java-safevarargs).
Basicamente, ao anotar o método como `@SafeVarArgs`, estou dando algumas certezas
para o compilador que algumas das tretas não estarão disponíveis.

Podemos também ter anotações para fazer processamento de bytecode. Um exemplo de possível
uso para isso é gerar um grafo de injeção de dependência estilo [Dagger](https://dagger.dev/).
Apenas lendo o bytecode da aplicação (e eventualmente das libs) é possível determinar qual
a classe que implementa qual interface e determinar como construir os diversos elementos.

Note que o processamento de bytecode ocorre antes da aplicação estar no ar, portanto
não é feito em runtime.

Um outro caso bem bacana de processamento de bytecode é no relatório de cobertura do JaCoCo.
O JaCoCo consegue ignorar alguns métodos automaticamente, mas para isso eles precisam estar
anotados com `@*Generated*`, onde `*` aqui significa qualquer string. O JaCoCo vai inspecionar
o bytecode atrás dessas anotações e, ao encontrar uma anotação assim, ele irá remover do
relatório de cobertura a existência das linhas relativas a essa anotação.

E, finalmente, temos o caso de criação de proxy ou decorator ou equivalente. E aqui que
realmente os olhos brilham ao se falar de anotações. Porque com isso você pode fazer
uma coisa a mais: aplicar programação orientada a aspeto (AOP, do inglês _aspect
oriented programming_).

## Retenção da anotação e outras coisas a mais

Para se criar uma anotação em Java, você precisa definir até onde essa anotação vai
ficar. Existem 3 níveis:

- SOURCE
- CLASS
- RUNTIME

Para fazer reflexão você só pode usar anotações de runtime. Mas as vezes você não
precisa disso, né? Em diversas casos, você só precisa processar o bytecode para
gerar um novo código bacana para atender uma necessidade sua. Você pode simplesmente
processar o código compilado e, em cima de anotações de lá, gerar o código. O Dagger
na minha lembrança faz isso, e se não o faz ele tem a capacidade de fazer.

Para esse tipo de processamento, escolher retenção de CLASS é o suficiente. Anotações
de RUNTIME também podem ser usada para processamenot de bytecode. A diferença principal
entre esses dois tipos de retenção é que na retenção CLASS, ao carregar a classe,
o classloader remove as anotações antes de disponibilizar o `Class<?>`. Já
a anotação que marcou a retenção como RUNTIME o classloader deixa disponível.

Anotações de nível de SOURCE só existem a nível de código fonte mesmo. Compilou,
perdeu. Exemplo disso são as anotações do Lombok, que só existem a nível de código fonte
e depois disso elas são descartadas. O Lombok intercepta isso e gera o bytecode adeqaudo
para criação de métodos.

E, bem, a gente precisa de algum modo indicar os metadados da anotação, como qual
o nível de retenção dela. Pra isso que existem anotações!

Isso mesmo, para adicioar dados de anotação usamos anotações. Esse tipo de anotação
que anota anotação é chamado de meta-anotação. Por exemplo, a anotação `@Getter` do
Lombok está anotada assim:

```java
@Target({ElementType.FIELD, ElementType.TYPE})
@Retention(RetentionPolicy.SOURCE)
public @interface Getter {
        // ...
}
```

Além da meta-anotação `@Retention`, existe outra muito importante, chamada de `@Target`.
Enquanto que em `@Retention` era definido até onde segurar aquela anotação, o `@Target`
vai determinar quais elementos de código posso segurar com isso. Por exemplo, o `@Getter`
do Lombok pode ser usado tanto em um campo quando na definição do tipo.

## Parâmetros de anotações

Além da anotação carrear dados por si mesma (como em `@SafeVarArgs` ou em `@Override`),
ainda assim podemos precisar anotar de modo paramétrico. Por exemplo, o `@Retention`,
você precisa determinar qual vai ser o nível em que a anotação irá viver.

Ao declarar uma anotação, você pode dizer quais são os parâmetros dela. E isso permite
adicionar muito mais metadados do que a anotação pura e simples. Isso permite que nos
livremos dos xml's de configuração, de uma vez por todas.

Pegando o exemplo de `@Retention`. Podemos dizer que o código é mais ou menos:

```java
@interface Retention {
    RetentionPolicy value();
}
```

Existe uma miríade de informações que podem ser adicionadas a uma anotação.
Como já vimos antes, temos enumerações. Além disso, podemos colocar booleanos,
inteiros e strings. E tudo isso tanto em escalar como em uma forma de vetores
também.

## Um exemplo de anotação com retenção em runtime

Pegar um exemplo próximo do real. Utilizei algo disso no trabalho.

Eu tenho um objeto que é onde vou colocar os dados utilizados em uma operação.
Após processada a operação, eu guardo esse registro para posteriormente poder
desserializar e fazer o replay dessa operação. Alguns desses dados tem resgate
de uso direto, outros precisam ser ignorados e deixados para o runtime
preencher, e ainda tem outros que são resgatados de uma maneira porém para serem
utilizados precisam passar por uma transformação. Então preciso que cada atributo
tenha duas informações a mais sobre eles:

- se deve ser ignorado ou não
- qual a tratativa que ele deve receber antes de ser repassado para o objeto de
  trabalho do replay

Com isso, temos o objeto que guarda esses valores:

```java
class OperationalData {

    private String someValue;
    private Map<String, String> keyValue;
    private SomeDeepObject deepObjet;
    private ThisIsCurriedFunction curriedFunction;

    // getters e setters
}
```

A partir disso, conseguimos ter os objetos desejados em runtime, serializar
e desserializar. Por uma questão de regras de negócio, ao fazer o replay,
preenchemos parcialmente um objeto novo de `OperationalData` e, então, fazemos
o merge do `OperationalData` da rodada anterior. Um dos motivos dessa escolha
é o `curriedFunction`.

O `curriedFunction` é uma função do tipo `String -> String -> Object`,
onde `Object` é resgatado de um banco de dados com base nas strings passadas
como parâmetros. Para serializar os dados de `curriedFunction` usados,
a estratégia foi armazenar em níveis em um JSON. Por exemplo, se em algum
momento for utilizada a seguinte consulta:

```java
operationalData.getCurriedFunction()
    .find("catKey")
    .find("innerKey");
```

Se a saída for um objeto assim:

```json
{
    "cod": "c",
    "qtd": 3,
    "valor_unitario": "98.14"
}
```

A serialização do objeto `curriedFuntion` será assim:

```json
{
    "curriedFunction": {
        "catKey": {
            "innerKey": {
                "cod": "c",
                "qtd": 3,
                "valor_unitario": "98.14"
            }
        }
    },
    // ...
}
```

De modo semelhante, se a chamada contiver duas chamadas dentro da mesma
"categoria":

```json
{
    "curriedFunction": {
        "catKey": {
            "innerKey": {
                "cod": "c",
                "qtd": 3,
                "valor_unitario": "98.14"
            },
            "anotherInnerKey": ...
        }
    },
    // ...
}
```

Colocando outra categoria:

```json
{
    "curriedFunction": {
        "catKey": {
            "innerKey": {
                "cod": "c",
                "qtd": 3,
                "valor_unitario": "98.14"
            },
            "anotherInnerKey": ...
        },
        "alternativeCat": {
            "alternativeInnerKey": ...,
            "anotherAlternativeInnerKey": ...
        }
    },
    // ...
}
```

Muito bem, temos o nosso objeto serializado explicado. Por um motivo
de regras de negócio, os valores em `keyValue` precisam ser preenchidos
durante o tempo de execução e isso faz parte da execução da operação,
não pode ser usado o valor anterior, então esse atributo precisa ser
ignorado. O resto, é usado normalmente, e preciso de uma lida especial
com o `curriedFunction`.

Então, com isso em mente, vamos escrever a anotação de `@ReplayAttribute`?

```java
@interface ReplayAttribute {
    boolean ignored() default false;
    MergeStrategy strategy() default STANDARD;
}
```

Com isso precisamos definir o `MergeStrategy` também:

```java
enum MergeStrategy {
    STANDARD,
    CURRIED_FUNCTION,
    ...;

    void merge(OperationalData oldData, OperationalData newData, Field fi) {
        try {
            final var fieldName = fi.getName();
            final var getterPreffix = fi.getType() == boolean.class? "is": "get";
            final var getterName = getterPreffix +
                    fieldName.substring(0, 1).toUpperCase() +
                    fieldName.substring(1);
            final var setterName = "set" +
                    fieldName.substring(0, 1).toUpperCase() +
                    fieldName.substring(1);

            final var declaringClass = fi.getDeclaringClass();
            final var getter = declaringClass.getDeclaredMethod(getterName);
            final var setter = declaringClass.getDeclaredMethod(setterName, fi.getType());
            final Object fieldValue = getter.invoke(oldData);

            setter.invoke(newData, switch (this) {
                case STANDARD -> fieldValue,
                case CURRIED_FUNCTION -> {
                    ...
                }
            });
        } catch (IllegalAccessException | NoSuchMethodException e) {
            throw new RuntimeException(e); // problema para o futuro
        }
    }
}
```

Vamos destrinchar um pouquinho? O método `merge` permite inserir as coisas
de `oldData` em `newData`, passando um `Field` de cada vez.

Para acessar o setter específico, primeiro eu transformo o nome do `Field`
(guardado em `fieldName`) no padrão setter: o prefixo `set` + o nome do campo,
porém com a primeira letra maiúscula:

```java
final var setterName = "set" +
        fieldName.substring(0, 1).toUpperCase() +
        fieldName.substring(1);
```

Com o nome do setter em mãos, para resgatar o setter adequado preciso perguntar
a classe que declara o campo `Field.getDeclaringClass()` qual o método que tem
comom nome o `setterName` e que tem como parâmetro um único valor do tipo do
campo `Field.getType()`:

```java
final var declaringClass = fi.getDeclaringClass();
final var setter = declaringClass.getDeclaredMethod(setterName, fi.getType());
```

Para o nome do getter, primeiro precisa se atentar a um detalhe de convenção:
se o campo for um `boolean` (isso não vale para `Boolean`, só para o primitivo
`boolean`), o prefixo é `is`, caso contrário o prefixo é `get`. Com esse
detalhe em mente, de resto é igual ao padrão para setter: o prefixo (que
pode ser `get` ou `is`)  + o nome do campo, porém com a primeira letra
maiúscula:

```java
final var getterPreffix = fi.getType() == boolean.class? "is": "get";
final var getterName = getterPreffix +
        fieldName.substring(0, 1).toUpperCase() +
        fieldName.substring(1);
```

No caso para pegar o método é simplesmente o método com o nome do
getter e sem parâmetros:

```java
final var declaringClass = fi.getDeclaringClass();
final var getter = declaringClass.getDeclaredMethod(getterName);
```

Ok, muito bem, mas como vamos resolver a questão do `curriedFunction`?

Temos aqui uma implementação muito vaga sobre como é sua interface:

```java
interface ThisIsCurriedFunction {
    default Findable<String, Object> find(String category) {
        return specifics -> find(category, specifics);
    }

    interface Findable<K, V> {
        V find(K key);
    }

    Object find(String category, String specifics);
}
```

Uma implementação da versão dela, pura:

```java
class CurriedFunctionProxy implements ThisIsCurriedFunction {

    final BiFunction<String, String, Object> dbQuery;

    CurriedFunctionProxy(BiFunction<String, String, Object> dbQuery) {
        this.dbQuery = dbQuery;
    }

    @Override
    public Object find(String category, String specifics) {
        return dbQuery.apply(category, specifics);
    }
}
```

Só que essa classe não favorece em nada a serialização. Para respeitar a
serialização escolhida, vamos usar uma alternativa com memoização:

```java
class MemoizedCurriedFunctionProxy implements ThisIsCurriedFunction {

    @JsonIgnore
    final BiFunction<String, String, Object> dbQuery;
    @JsonIgnore
    final HashMap<String, Map<String, Object>> data = new HashMap<>();

    MemoizedCurriedFunctionProxy(BiFunction<String, String, Object> dbQuery) {
        this.dbQuery = dbQuery;
    }

    @Override
    public Object find(String category, String specifics) {
        if (data.containsKey(category)) {
            final var catMap = data.get(category);
            if (catMap.containsKey(specifics)) {
                return catMap.containsKey(specifics);
            }
        }
        final var result = dbQuery.apply(category, specifics);
        final var catMap = data.computeIfAbsent(category, k -> new HashMap<>());
        catMap.put(specifics, result);
        return result;
    }

    @JsonAnyGetter
    public Map<String, Map<String, Object>> getData() {
        return data;
    }
}
```

Aqui o `@JsonAnyGetter` serve para colocar no nível do objeto sendo serializado
as chaves do mapa como sendo os campos do objeto. Se eu não tivesse colocado
o `@JsonAnyGetter`, mantendo os `@JsonIgnore`, teríamos como serialização
apenas:

```json
{}
```

Porém, desse jeito, podemos ter o esquema desejado:

```java
{
    "catKey": {
        "innerKey": {
            "cod": "c",
            "qtd": 3,
            "valor_unitario": "98.14"
        },
        "anotherInnerKey": ...
    },
    "alternativeCat": {
        "alternativeInnerKey": ...,
        "anotherAlternativeInnerKey": ...
    }
}
```

Ok, muito bem. Agora, para desserializar isso? Vamos assumir que a versão
desserializada não leve em consideração nada de banco de dados, apenas em cima
dos valores desserializados. Aqui vou usar o `@JsonAnySetter` para fazer o
trabalho simétrico ao que o `@JsonAnyGetter` proporcionou:

```java
class FromSerializedCurriedFunctionProxy implements ThisIsCurriedFunction {

    @JsonIgnore
    final HashMap<String, Map<String, Object>> data = new HashMap<>();

    @Override
    public Finable<String, Object> find(String category) {
        if (data.containsKey(category)) {
            return specifics -> null;
        }
        final var catMap = data.get(category);
        return catMap::get;
    }

    @Override
    public Object find(String category, String specifics) {
        return this.find(category)
                .find(specifics);
    }

    @JsonAnySetter
    public void setData(String category, Map<String, Object> values) {
        data.computeIfAbsent(category, h -> new HashMap<>())
                .put(categpry, values);
    }

    // isso aqui vou usar depois
    public boolean hasValue(String category, String specifics) {
        if (!data.containsKey(category)) {
            return false;
        }
        final var catMap = data.get(category);
        return catMap.containsKey(specifics);
    }
}
```

Note que o `@JsonAnySetter` permite que o Jackson insira valores com chaves
arbitrárias. O `@JsonAnySetter` precisa ser anotado em um método que receba uma
string e um objeto, ou então em um campo `Map<String, ?>`.

Para pedir para a interface que o Jackson serializou desserializar em uma
instância especíica da classe `FromSerializedCurriedFunctionProxy`, precisamos
alteraruma coisinha na interface:

```java
@JsonDeserialize(as = FromSerializedCurriedFunctionProxy.class)
interface ThisIsCurriedFunction {
    default Function<String, Object> find(String category) {
        return specifics -> find(category, specifics);
    }

    Object find(String category, String specifics);
}
```

Tendo isso em mãos, como seria a estratégia `CURRIED_FUNCTION`? Bem, primeiro
vamos começar pegando o valor atual. Ele tem acesso para além do que foi usado
na operação inicial. Basicamente, se não tiver na rodada anterior, pego da nova
função.

Então, o valor antigo é sabidamente nulo, então não tem o que entfeitar, só
retornar o valor atual. Caso contrário, primeiro consultamos no valor que foi
guardado anteriormente (`FromSerializedCurriedFunctionProxy#hasValue` que foi
criado nessa classe específica). Caso tenha, retorne esse valor; caso
contrário, retorne o valor da consulta atual. Envelope isso em um
`MemoizedCurriedFunctionProxy` para podermos saber o que foi consultado nessa
rodada e pronto.

```java
final ThisIsCurriedFunction newCurriedFunction = (ThisIsCurriedFunction) getter.invoke(newData);
if (fieldValue == null) {
    yield newCurriedFunction;
}
final FromSerializedCurriedFunctionProxy fromSerializedCurriedFunction = (FromSerializedCurriedFunctionProxy) fieldValue;
yield new MemoizedCurriedFunctionProxy((cat, specifics) -> {
    if (fromSerializedCurriedFunction.hasValue(cat, specifics)) {
        return fromSerializedCurriedFunction.find(cat, specifics)
    }
    return newCurriedFunction.find(cat, specifics);
});
```

Ainda precisamos saber como usar a anotação para poder chamar esse código.
Então, vamos lá, a função `mergeInto`:

```java
class OperationalData {

    private String someValue;
    private Map<String, String> keyValue;
    private SomeDeepObject deepObjet;
    private ThisIsCurriedFunction curriedFunction;

    // getters e setters

    void mergeInto(OperationalData newData) {
        Field[] oldFields = this.getClass().getDeclaredFields();

        record AnnotatedField(Field fi, ReplayAttribute replayAttr) {
            AnnotatedField(Field fi) {
                this(fi, fi.getAnnotation(ReplayAttribute.class));
            }
            void merge(OperationalData oldData, OperationalData newData) {
                replayAttr.strategy().merge(oldDate, newData, fi);
            }
        }

        Stream.of(oldFields)
                .map(AnnotatedField::new)                   // mapeia para o campo com a anotação
                .filter(af -> af.replayAttr() != null)      // possuem de fato a anotação
                .filter(af -> !af.replayAttr().ignored())   // não pode ser ignorado
                .forEach(af -> af.merge(oldData, newData)); // pronto, o que não foi filtrado fora faz o merge
    }
}
```

## AOP

AOP é um subparadigma de programação que indica que uma parte do código irá ser
processada dentro de um "aspecto". Por exemplo, podemos por o aspecto de
"cronometrar a execução".

Outros aspectos que já vi incluem:

- garantir nível de acesso do usuário
- loggar
- selecionar o tenant de um app multi-tenant

Sobre essa questão específica do multo-tenant, eu cheguei a trabalhar com isso.
Lá era necessário escolher o tenant adequadamente (isso implica na escolha da
conexão JDBC correta etc). Também tinha situações em algumas apps que eram de
instância única que algumas operações no tenant específica eram extremamente
críticas, necessitando assim que fossem executadas em modo de total isolamento.

> Note que esse artigo não é um tutorial para usar AOP com alguma ferramenta,
> vou focar mais na parte de reflexão/metaprogramação do que em realmente
> programação orientada a aspecto.

Para lidar com essas coisas, criei 3 anotações:

- `@RequiresTenant`, para indicar que aquela função ou classe necessitava de
  seleção de tenant
- `@Tenant`, no próprio parâmetro para indicar quem era o tenant
- `@TenantMutex`, para indicar que o tenant precisa ser acessado de modo
   único dentro desse

Aqui um exemplo de como seria a implementação dessas anotações (assumindo
pacote `jeffque.aspect`):

```java
package jeffque.aspect;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.TYPE, ElementType.METHOD})
public @interface RequiresTenant {
}
```

```java
package jeffque.aspect;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.PARAMETER)
public @interface Tenant {
}
```

```java
package jeffque.aspect;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface TenantMutex {
}
```

Um exemplo (artificial) de código que usaria essas anotações:

```java
@RestController
@RequestMapping("/import/{tenant}")
@RequiresTenant
class ImportacaoDadosController {

    @GetMapping("/{table}/count")
    public int countLinesOfTable(@Tenant @PathVariable String tenant,
                                 @PathVariable String table) {
        return count(table);
    }

    @PostMapping
    @TenantMutex
    public void importData(@Tenant @PathVariable String tenant,
                           @RequestBody InputStream data) {
        handleData(data);
    }
}
```

Aqui o método `countLinesOfTable` tem duas variáveis de URL: a primeira é
`{tenant}` e está anotada devidamente com `@PathVariable` e também `@Tenant`, e
a segunda que está anotada como `@PathVariable`.

Já o método `importData` tem também uma variável de `@PathVariable` que é o
próprio `{tenant}`, do mesmo modo que `countLinesOfTable`. Tem também o
parâmetro anotado com `@RequestBody`, que devido a como foi pedido o
Spring-Boot vai fazer o mínimo de tratativa possível em cima e me entregar o
mais _raw data_ possível, se não me engano vai lidar com possível compressão
apenas. Note que esse método, entretanto, também está anotado com
`@TenantMutex`.

A inserção do aspecto vai garantir que o tenant vai ser colocado corretamente
para a seleção da conexão JDBC ou que o acesso a um tenant seja único naquela
aplicação.

Vamos usar aqui algo do AspectJ para usar AOP. Detalhes variam, mas a ideia num
modo geral é essa. Para usar os aspectos no AspectJ, precisamos definir duas
coisas:

- o ponto de corte
- como lidar com o ponto de corte através de um _advice_

Por exemplo, para pegar o ponto de corte "métodos executados dentro de classes
anotadas com `@RequiresTenant`":

```aspectj
within(@RequiresTenant *) && execution(* *(..))
```

Esse é o ponto de corte. Tem duas condições que precisam ser satisfeitas.
A primeira é que esteja dentro de um tipo. O tipo precisa estar anotado com
`@RequiresTenant`. Poderia ser feita alguma limitação na identificação do
tipo, mas escolhi pegar todo com `*`.

A segunda condição é que seja em relação a qualquer execução. Aqui ele
indica que é uma execução de qualquer tipo de retorno (primeiro `*`), qualquer nome
de método (segundo `*`) com qualquer tipo/quantidade de parâmetro `(..)`. Por
aqui como contraponto outro pointcut:
`execution(int mcprol.aspectj.dummy.DummyCounter.add(int))`.
Aqui a execução retorna um int, o método é o método `add` da classe
`mcprol.aspectj.dummy.DummyCounter`, e recebe um argumento do tipo
`int`. Esse exemplo foi pegue do repositório
[https://github.com/mcprol/aspectj-sample-aspects](https://github.com/mcprol/aspectj-sample-aspects).
Fiz um fork meu
[https://github.com/jeffque/aspectj-sample-aspects](https://github.com/jeffque/aspectj-sample-aspects)
para fazer alguns experimentos.

> Não coloquei para aquele pointcut o método ser anotado com `@RequiresTenant`,
> isso fica para um artigo mais longo sobre AOP.

Para lidar com isso, precisamos criar um aspecto:

```java
@Aspect
public class TenantAspect {

    @Pointcut("within(@RequiresTenant *) && execution(* *(..))")
    public void requiresTenant() {
    }

    @Around("requiresTenant()") // advice around
    public Object around(ProceedingJoinPoint pjp) throws Throwable {
        // ainda vazio, só para testar
        System.out.println("passou pelo TenantAspect");
        return pjp.proceed(pjp.getArgs());
    }
}
```

Ok, lidando com `requiresTenant`. Colocamos o _advice_ `@Around`. Esse tipo de
_advice_ é pra você indicar processamentos que vão ocorrer ao redor do método
sendo executado, do método que o aspecto irá interromper. O `@Around` permite
ter todo o poder de um decorador nas mãos.

Mas também tem a possibilidade de fornecer outros _advices_, como por exemplo
`@Before` que vai executar antes do método ser chamado, `@AfterReturn` que será
chamado após um retorno tranquilo do método.

No caso de invocação de método, o `ProceedingJoinPoint` vai ter uma asinatura
do tipo `MethodSignature`. É seguro usar isso, por exemplo, dentro do _advice_
`@Around`:

```java
@Around("requiresTenant()")
public Object around(ProceedingJoinPoint pjp) throws Throwable {
    if (pjp.getSignature() instanceof MethodSignature sig) {
        System.out.println("aqui a assinatura:" + sig);
    }
    return pjp.proceed(pjp.getArgs());
}
```

Ok, agora eu preciso examinar qual o parâmetro que esteja anotado
com `@Tenant`. Para isso, eu posso pegar o método a partir do
`MethodSignature#getMethod()`. E com isso termina a questão
específica de aspecto e voltamos a 100% meta programação!

```java
if (pjp.getSignature() instanceof MethodSignature sig) {
    final var method = sig.getMethod();
    // agora explorar o método
}
```

A classe de reflexão de método fornece para a gente um jeito
de pegar todas as anotações de todos os parâmetros,
`Method#getParameterAnnotations()`. O retorno desse método é
engraçado. Ele retorna um vetor com o tamanho igual à
quantidade de parâmetros. Então, no exemplo:

```java
@GetMapping("/{table}/count")
public int countLinesOfTable(@Tenant @PathVariable String tenant,
                                @PathVariable String table) {
    return count(table);
}
```

Ele retornaria um array de 2 posições. Cada posição desse array
consiste de quais anotações estão em cada parâmetro. Por exemplo,
`Method#getParameterAnnotations()[0]` retornaria um array com
duas posições, uma com a anotação `@Tenant` e outro com a anotação
`@PathVariable`. Já `Method#getParameterAnnotations()[1]`
retornaria apenas um vetor com uma única posição que é
`@PathVariable`.

Se eu tivesse o seguinte método sendo interceptado por aspectos:

```java
public int random(int a, @DummyAnnotation int b, int c) {
    return a + b + c;
}
```

Onde `@DummyAnnotation` é uma anotação com de retenção de runtime.
O retorno de `Method#getParameterAnnotations()` seria um vetor
de 3 posições, onde `Method#getParameterAnnotations()[0]` e
`Method#getParameterAnnotations()[2]` são vetores vazios e
`Method#getParameterAnnotations()[1]` é um vetor de uma posição
contendo `@DummyAnnotation`.

Dito isso, como retornar qual o parâmetro que usa o `@Tenant`?
Bem, podemos devolver o índice com o parâmetro que é o `@Tenant`,
usando números negativos para falhas: `-1` caso não ache nenhum e
`-2` caso tenha mais de um `@Tenant` no mesmo método:

```java
public final int NOT_FOUND = -1;
public final int CONFLICTING = -2;
public int findParameterIndexWithAnnotation(Method m, Class<?> annotationClass) {
    final var paramsAnnotations = m.getParameterAnnotations();
    int idx = NOT_FOUND;

    for (int i = 0; i < paramsAnnotations.length; i++) {
        final var singleParamAnnotations = paramsAnnotations[i];
        for (var annotation: singleParamAnnotations) {
            if (annotationClass.isInstance(annotation)) {
                // deu match
                if (idx != NOT_FOUND) {
                    // deu choque, pode retornar conflito
                    return CONFLICTING;
                }
                idx = i;
            }
        }
    }
    return idx;
}
```

Para usar e pegar o tenant adequado, vamos capturar esse valor. Caso
seja valor de falha (menor que zero), abortar. Caso contrário, pegar
o valor e verificar se é string (precisa ser string). Se não for,
abortar. Se for, configurar o tenant.

```java
@Around("requiresTenant()")
public Object around(ProceedingJoinPoint pjp) throws Throwable {
    if (pjp.getSignature() instanceof MethodSignature sig) {
        System.out.println(sig);
        final var method = sig.getMethod();
        final var idxTenant = findParameterIndexWithAnnotation(method, Tenant.class);

        if (idxTenant < 0) {
            // não achou, abortando
            throw new RuntimeException("problemas com o método que assinala o tenant");
        }
        final Object tenantObj = pjp.getArgs()[idxTenant];

        if (tenantObj instanceof String tenant) {
            configurarTenant(tenant);
        } else {
            // achou, mas não é string
            throw new RuntimeException("tenant não é string?");
        }
    }
    try {
        // se chegou aqui, o tenant está configurado corretamente
        return pjp.proceed(pjp.getArgs());
    } finally {
        // precisa liberar para evitar efeitos colaterais nocivos
        // por exemplo, no caso de `configurarTenant` alterar valores
        // dentro de ThreadLocal
        liberarTenant(tenant);
    }
}
```

### Decoradores?

Muita coisa que se faz em Java com anotações para alterar a execução de código
é na prática por um decorador na função/classe. Mas anotações Java não se resumem
a isso, como visto acima.

Em Python, temos uma coisa que se escreve de modo *muito semelhante* a uma
anotação Java. Abaixo um exemplo do uso de um decorador que remove um campo
específico de um dicionário que se tem no retorno de uma função:

```python
@remove_property_etc_from_dict
def createDict(input_obj):
    if isinstance(input_obj, dict):
        return input_obj
    if isinstance(input_obj, str):
        return json.loads(input_obj)
    return None
```

A implementação de `remove_property_etc_from_dict` é na forma de uma função
que retorna a função decorada. Decoradores em Python também podem ser para
classes, mas aqui vou focar em funções. Aqui a implementação do decorador,
que remove o campo `etc` no dicionário retornado:

```python
def remove_property_etc_from_dict(func):
    def decorated_func(*args, **kwargs):
        returned_dict = func(*args, **kwargs)
        if returned_dict is None:
            return None
        returned_dict.pop('etc', None)
        return returned_dict
    return decorated_func
```

O decorador do Python tem uso imediato e já afeta o resultado da computação,
pode até testar no IDLE agora. Nesse sentido, o decorador no Python é
distinto do que se tem em anotações no Java. Escopo menor, poder menor, mas
mais direto para utilizar.

Note que, como não é uma anotação, não posso deixar a cargo de reflexão apenas
um esquema para identificar o `@Tenant`, como foi feito no exemplo de AOP.
Para fazer algo semelhante, vou precisar passar para o decorador mais dicas
para que ele consiga determinar o tenant.

## Outros usos de anotação

Mostrei acima alguns usos, mas está longe de ser uma lista exaustiva. Os
usos que eu mais fiz foram os acima, mas note que nunca escrevi em nenhum
momento um processador de anotação, para linkar com o `javac`.

Também não fiz algo para fazer geração, por exemplo, para gerar código
JSON, por exemplo para exportar um exemplo de classe Java em um schema
que o TypeScript entenda.

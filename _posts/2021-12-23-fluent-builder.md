---
layout: post
title: "Fluent Builder com região crítica"
author: "Jefferson Quesado"
tags: java design-patterns
---

Durante o trabalho, me deparei com uma situação bem interssante: precisava de um `builder` fluente para
preparar uma classe específica. Mais notoriamente, um esquema para construir o `AsyncCallback` do GWT.
Os pontos principais são:

1. o dito callback será usado como argumento de uma chamada assíncrona GWT-RPC
2. posso definir o que fazer no sucesso da chamada (`onSuccess`)
3. posso definir o que fazer na falha da chamada (`onFailure`)
4. posso definir o que fazer após a resposta do servidor e de tratar a resposta (`onFinally`)
5. posso definir o que fazer antes de realizar a chamada (`onBefore`)
6. os passos 2...5 são opcionais
7. posso definir diversas tratativas de antes, sucesso, falha e pós-resposta

Os detalhes dessa implementação não precisam ser tratados a fundo aqui, dá para abstrair
completamente isso por hora. O padrão que gostaria de enfatizar independe dos detalhes
internos, então vamos focar apenas na API, ok? Em tese, isso poderia ser feito de maneira engessada,
não fluente, mais ou menos assim:

```java
// seja T o tipo da resposta da chamada GWT-RPC service.fazChamada
AsyncCallbackBuilder<T> builder = new AsyncCallbackBuilder<>();
builder.onSuccess(this::fun1);
builder.onSuccess(this::fun2);
builder.onBefore(Loader::startLoading);
builder.onFinally(Loader::endLoading);
builder.onFailure(logger::consoleFailure);
builder.onFailure(e -> showToastFailure(e.getMessage()));

AsyncCallback<T> callback = builder.build();

service.fazChamada(arg0, arg1, callback);
```

Mas, isso é meio bruto, não é? Que tal se, no lugar de fazer assim, pudéssemos fazer de modo
mais fluente? APIs fluente normalmente retornam o próprio tipo para que você posso continuar
trabalhando em cima dele, então algumas coisas ficam menos engessadas de escrever:

```java
// seja T o tipo da resposta da chamada GWT-RPC service.fazChamada
AsyncCallback<T> callback = new AsyncCallbackBuilder<T>()
		.onSuccess(this::fun1)
		.onSuccess(this::fun2)
		.onBefore(Loader::startLoading)
		.onFinally(Loader::endLoading)
		.onFailure(logger::consoleFailure)
		.onFailure(e -> showToastFailure(e.getMessage()))
		.build();

service.fazChamada(arg0, arg1, callback);
```

Ao menos soa um pouco mais natural, não é? Agora, normalmente essas chamadas, essas preparações tem
uma grande coesão entre _callback_ e chamada assíncrona. Então, eu poderia colocar nessa chamada assíncrona,
de certo modo, a chamada assíncrona e, no lugar de falar que fiz a construção, mandar rodar. Fica mais ou
menos assim:

```java
// seja T o tipo da resposta da chamada GWT-RPC service.fazChamada
new AsyncCallbackBuilder<T>()
		.onSuccess(this::fun1)
		.onSuccess(this::fun2)
		.onBefore(Loader::startLoading)
		.setAsyncCall(cb -> service.fazChamada(arg0, arg1, cb))
		.onFinally(Loader::endLoading)
		.onFailure(logger::consoleFailure)
		.onFailure(e -> showToastFailure(e.getMessage()))
		.run();
```

Com isso, tenho tudo que preciso para fazer a chamada assíncrona, consigo programar feliz e já trato o consumo
do `AsyncCallback` dentro do meu _fluent builder_, já que a intenção aqui é englobar de modo mais natural
o ciclo de vida da chamada assíncrona. Não faz sentido armazenar um `AsyncCallback` em uma variável longeva,
normalmente esse _callback_ tem uma vida muito curta.

Agora, isso tem um lado negativo. Se alguém esquecer de colocar um `setAsyncCall` e chamar o `run`, o erro só será
detectado quando o construtor criar o `AsyncCallback` ou, pior ainda, quando for tentar chamar o GWT-RPC e dar ruim
porque o `Consumer<AsyncCallback<T>>` passado como `setAsyncCall` ser nulo, gerando o equivalente JavaScript do
famigerado `NullPointerException`.

Uma coisa que me chamou bastante atenção em alguns papos no Twitter com pessoal que gosta mais de programação funcional
é que eles sempre falam para deixar o compilador fazer o trabalho de verificação por você. Então, como fazer isso em Java?
Que tal... manipulando os tipos?

Pois bem, eu preciso de um construtor fluente. Não preciso instanciar ele, mas posso pegar algo que o representa. Isso também
abstrai alguns passos que são comuns no projeto, como o `startLoading`, `endLoading`, `consoleFailure` que são coisas que eu
normalmente gosto de usar. Então, digamos que tenho uma chamada estática que resgata esse _builder_ pré-montado.
Ficaria assim o código cliente:

```java
// seja T o tipo da resposta da chamada GWT-RPC service.fazChamada
AsyncCallbackBuilder.<T>getDefaultBuilder()
		.onSuccess(this::fun1)
		.onSuccess(this::fun2)
		.setAsyncCall(cb -> service.fazChamada(arg0, arg1, cb))
		.onFailure(e -> showToastFailure(e.getMessage()))
		.run();
```

Divertido? Bem, sim. Eu curto isso. Ainda posso determinar outras questões de `onBefore`, `onFinally`, `onFailure`
de modo privado. Também posso tentar pegar de modo "cru" o _builder_, caso não queira o _loading_ na tela:

```java
AsyncCallbackBuilder.<T>getRawBuilder()
		.onSuccess(this::fun1)
		.onSuccess(this::fun2)
		.setAsyncCall(cb -> service.fazChamada(arg0, arg1, cb))
		.onFailure(logger::consoleFailure)
		.run();
```

Mas ainda tenho o problema de como fazer chamar o `run` única e exclusivamente após garantir que o meu _builder_ fluente
tenha passado por `setAsyncCall`. Note que nesse caso específico eu não quero garantir apenas a chamada do `setAsyncCall`, mas
quero também que ela seja única. O que o compilador poderia garantir para mim?

Bem, a maior coisa que o compilador me permite é brincar com tipos. Aqui não adianta ser um tipo de parâmetro do _generics_,
então preciso mexer nos tipos do _builder_ mesmo. De grosso modo, posso definir que tenho 2 APIs distintas para lidar com isso:

```
BeforeAsyncBuilder<T>:
	onSuccess: Consumer<T> => BeforeAsyncBuilder<T>
	onFailure: Consumer<Throwable> => BeforeAsyncBuilder<T>
	onBefore: Runnable => BeforeAsyncBuilder<T>
	onFinally: Runnable => BeforeAsyncBuilder<T>
	setAsyncCall: Consumer<AsyncCallback<T>> => AsyncSettedBuilder<T>

AsyncSettedBuilder<T>:
	onSuccess: Consumer<T> => AsyncSettedBuilder<T>
	onFailure: Consumer<Throwable> => AsyncSettedBuilder<T>
	onBefore: Runnable => AsyncSettedBuilder<T>
	onFinally: Runnable => AsyncSettedBuilder<T>
	run: () => void
```

> O retorno de `run` não é relevante para a discussão agora, poderia ser qualquer coisa.
> Estou colocando `void` mas sem perder generalidade.

Notou que os 4 primeiros métodos são quase iguais em ambas as APIs? Hmmm, interessante. Não vamos fazer nada com isso _agora_,
mas mantenhamos isso na cabeça.

Bem, uma coisa que gostaria de salientar é que não preciso ter dois objetos distintos para lidar com isso, seria melhor que
tudo isso fossem apenas interfaces. Então, se são interfaces, poderia fazer algo como:

```java
public class AsyncCallbackBuilder<T> implements BeforeAsyncBuilder<T>, AsyncSettedBuilder<T> {

	public static <T> BeforeAsyncBuilder<T> getDefaultBuilder<T>() {
		AsyncCallbackBuilder<T> builder = new AsyncCallbackBuilder<>();
		// ... prepara com valores padrão o builder...
		return builder;
	}

	public static <T> BeforeAsyncBuilder<T> getRawBuilder<T>() {
		return new AsyncCallbackBuilder<>();
	}

	// só para garantir que apenas os métodos estáticos possam instanciar o AsyncCallbackBuilder
	private AsyncCallbackBuilder() {
	}

	// ... diversas chamadas...

	// apenas como exemplo de chamada fluente
	public AsyncCallbackBuilder<T> onSuccess(Consumer<T> successFunction) {
		// faz algo significativo com successFunction
		return this;
	}
}
```

Pois bem, as chamadas estáticas de fato obedecem nosso desejo de impedir chamar o `run` antes de ter garantido o
`setAsyncCall`. Agora... precisamos lidar com os tipos. Note que o compilador vai chiar porque vou precisar implementar
o método `onBefore`, recebendo os mesmos argumentos, porém com retornos conflitantes vindos de dois pais distintos...

E se... no lugar de ter 2 tipos, eu tivesse só 1?

Pois bem, isso é possível se eu tiver um tipo comum, que tanto `BeforeAsyncBuilder<T>` quanto `AsyncSettedBuilder<T>`
derivem. Também posso colocar nesse tipo os 4 métodos comuns entre `BeforeAsyncBuilder` e `AsyncSettedBuilder`. Posso
me utilizar de que o Java permite que uma subclasse (ou subinterface) pode retornar um tipo mais específico do que o método
do supertipo.

Isto é, se eu tenho `HasReturn` que tem o método `Object getReturn()`, eu posso implementar um `ChildHasReturn` com o método
`String getReturn()`, já que `String` è um subtipo de `Object`. Com isso, as APIs que mencionei acima se mantém, porém agora
adiciono um tipo base (`FluentAsyncCallbackBuilder<T>`) cujas interfaces herdam dele:

```
FluentAsyncCallbackBuilder<T>:
	onSuccess: Consumer<T> => FluentAsyncCallbackBuilder<T>
	onFailure: Consumer<Throwable> => FluentAsyncCallbackBuilder<T>
	onBefore: Runnable => FluentAsyncCallbackBuilder<T>
	onFinally: Runnable => FluentAsyncCallbackBuilder<T>

BeforeAsyncBuilder<T>: FluentAsyncCallbackBuilder<T>
	onSuccess: Consumer<T> => BeforeAsyncBuilder<T>
	onFailure: Consumer<Throwable> => BeforeAsyncBuilder<T>
	onBefore: Runnable => BeforeAsyncBuilder<T>
	onFinally: Runnable => BeforeAsyncBuilder<T>
	setAsyncCall: Consumer<AsyncCallback<T>> => AsyncSettedBuilder<T>

AsyncSettedBuilder<T>: FluentAsyncCallbackBuilder<T>
	onSuccess: Consumer<T> => AsyncSettedBuilder<T>
	onFailure: Consumer<Throwable> => AsyncSettedBuilder<T>
	onBefore: Runnable => AsyncSettedBuilder<T>
	onFinally: Runnable => AsyncSettedBuilder<T>
	run: () => void
```

Note que, caso o programador se depare usando no código cliente `FluentAsyncCallbackBuilder<T>` ele estará em um
beco sem saída. Não é interessante exibir essa interface para ele. Note que, ao implementar `AsyncCallbackBuilder.onSuccess`,
como `AsyncCallbackBuilder` implementa tanto `BeforeAsyncBuilder` quanto `AsyncSettedBuilder`, continuar retornando `this`
é positivo pois ele atende as interfaces que o requerem sem erro.

O código fica com a seguinte estrutura:

```java
// não queremos expor esta interface
interface FluentAsyncCallbackBuilder<T> {
	FluentAsyncCallbackBuilder<T> onSuccess(Consumer<T> successFunction);
	// ... demais métodos declarados
}

public interface BeforeAsyncBuilder<T> extends FluentAsyncCallbackBuilder<T> {
	BeforeAsyncBuilder<T> onSuccess(Consumer<T> successFunction);
	// ... demais métodos advindos de FluentAsyncCallbackBuilder

	// note que eu **preciso** colocar esses métodos com o retorno correto,
	// caso contrário jogo o programador no beco sem saída do FluentAsyncCallbackBuilder
	AsyncSettedBuilder<T> setAsyncCall(Consumer<AsyncCallback<T>> asyncCall);
}

public interface AsyncSettedBuilder<T> extends FluentAsyncCallbackBuilder<T> {
	AsyncSettedBuilder<T> onSuccess(Consumer<T> successFunction);
	// ... demais métodos advindos de FluentAsyncCallbackBuilder

	// note que eu **preciso** colocar esses métodos com o retorno correto,
	// caso contrário jogo o programador no beco sem saída do FluentAsyncCallbackBuilder
	void run();
}

public class AsyncCallbackBuilder<T> implements BeforeAsyncBuilder<T>, AsyncSettedBuilder<T> {
	// métodos estáticos, construtor privado e todo esse auê

	public AsyncCallbackBuilder<T> onSuccess(Consumer<T> successFunction) {
		// faz algo significativo com successFunction
		return this;
	}
	// ... demais métodos advindos de FluentAsyncCallbackBuilder, BeforeAsyncBuilder e AsyncSettedBuilder
```

Parece algo bobo, não é? Exemplo clássico de _overengineering_?

Pois bem... algo aconteceu recentemente que mostrou motivos para garantir esse tipo de coisa...

No trabalho, está sendo refeita uma tratativa, ainda bem modesta, do ciclo de vida das requisições ao
[Prometheus](https://gitlab.com/geosales-open-source/prometheus). Como estamos no GWT, de toda sorte
vou ter uma chamada assíncrona para lidar com a requisição ao ciclo de validação do Prometheus, então
preciso lidar com alguns tipos de respostas:

1. quando tudo ocorre bem e o dado é (supostamente) persistido
1. quando ocorrem explosões
1. quando ocorrem dúvidas
1. quando preciso exibir informações emitidas por um dos processamentos do ciclo de validação

Na lida das dúvidas, preciso fazer uma segunda chamada assíncrona falando "ciclo de validação, eu perguntei pro
usuário e ele disse que tá tudo bem, ele come a bronca, vai fundo". Nem sempre é necessário lidar com as dúvidas,
mas sempre é necessário fazer a chamada. No caso, quem lida com isso tudo é a classe `PrometheusMgr`, com o _builder_
fluente `PrometheusMgrBuilder`.

Então, em cima dessa informação, foi colocada a seguinte linha no construtor de `PrometheusMgr`:

```java
PrometheusMgr(Consumer<List<Inform>> actionInform, Consumer<List<Doubt>> actionDoubts, Consumer<List<Explode>> actionExplode,
		 Consumer<PrometheusDTO<T>> endAction, BiFunction<T, AsyncCallback<PrometheusDTO<T>>, Request> asyncCall) {
	// ... demais inicializações ...
	this.asyncCall = Objects.requireNonNull(asyncCall);
}
```

E... aconteceu exatamente de, em um único uso de `PrometheusMgrBuilder`, não ter sido alterado para fornecer o `asyncCall`. Esse
caso específico estava em uma classe que está marcada para morrer com `@Deprecated` e servindo de _proxy_ para `PrometheusMgr`.
Eis o código que gerou o problema:

```java
// bannerContainer é variável de classe
// prometheusDTO é argumento do método que tem esse código aqui
PrometheusMgr<T> prometheusMgr = new PrometheusMgrBuilder<T>()
		.setActionInform((listaInform) -> bannerContainer.add(new BasserInform(listaInform)))
		.setActionExplode((listaExplode) -> bannerContainer.add(new BannerExplode(listaExplode)))
		.setActionDoubts((listaDoubts) -> tratamentoDoubts.accept(prometheusDTO))
		.build();
```

Bem fácil perder esse ponto crítico, hein? Note que, no caso do `PrometheusMgr`, faz sentido construir o objeto
e manter ele ao longo da vida da parte do app que faz chamadas ao Prometheus.

# Resumindo o padrão _fluent builder_

Você precisa de um conjunto de métodos de preparação. Você também precisa de um método crítico que vai determinar "esse objeto
está pronto para ser construído". Esse método precisa ser chamado pelo menos uma única vez, mas talvez mais.

> Talvez você precise ter vários desses métodos críticos, porém a complexidade de manter tudo através de tipos sobe exponencialmente.

Aqui, temos os seguintes participantes:

- interface fluente base (`FluentBase`)
- interface fluente antes do método crítico (`BeforeCritic`)
- interface fluente após o método crítico (`ReadyToBuild`)
- objeto que implementa as interfaces sempre retornado `this` (`FluentBuilder`)
- o objeto de construção complicada (`Target`)

```
FluentBase:
	método preparação: ... => FluentBase
	// demais métodos

BeforeCritic: FluentBase
	método preparação: ... => BeforeCritic
	// demais métodos de preparação, sempre retornando BeforeCritic
	método crítico: ... => ReadyToBuild

ReadyToBuild: FluentBase
	método preparação: ... => ReadyToBuild
	// demais métodos de preparação, sempre retornando ReadyToBuild
	build: () => Target
	// se puder chamar diversos métodos críticos, só colocar "método crítico: ... => ReadyToBuild" aqui

FluentBuilder: BeforeCritic & ReadyToBuild
	[static] get builder: ... => BeforeCritic
	método preparação: ... => FluentBuilder
	// demais métodos de preparação, sempre retornando FluentBuilder
	método crítico: ... => FluentBuilder
	build: () => Target
```

Note que `Target` pode ter construtor público sem nenhum problema, mas o `FluentBuilder` vai facilitar sua chamada no código cliente.

Note também que, no caso do `AsyncCallbackBuilder`, não precisei de fato usar o `build: () => Target`, já que o objeto a ser construído
não necessitava em nenhum momento ser mantido já que se cadastrava também o próprio consumo dele.

Como todo padrão de projeto, isso foi algo percebido como útil em alguns cenários e deve ser usado com carinho e cautela. Não tente
forçar um uso para esse padrão de projeto, ele tem escopo extremamente limitado para linguagens com tipagem estática estilo Java onde
se deseja garantir determinados valores antes de chamar o construtor de algum objeto. Isso não exime jamais do construtor desse objeto
ter suas próprias regras para evitar uma instanciação danosa. O uso desse padrão de projeto é apenas fazer o compilador impedir a
construção do objeto em estado inválido.

---
layout: post
title: "GWT-SAX - parte 1: criando uma biblioteca GWT"
author: "Jefferson Quesado"
---

Estamos abrindo um esquema de usar o `AsyncCallback` do GWT para um
jeito mais natural de se construir. Ainda mais que a gente usa coisas que
precisam ser disparadas antes de iniciar a chamada assíncrona e outras
logo depois que finaliza (com sucesso ou falha). Para isso, temos um builder
para definir como tratar diversos momentos, como abrir a tela de loading antes de
iniciar a chamada assíncrona e fechar o loading independente se recebeu o `onSuccess`
ou o `onFailure`.

Exatamente nesse artigo estou focando na parte de permitir cadastrar as interceptações de
eventos e momentos, não focado no outro aspecto que achei importante ao descrever essa classe
que foi deixar o consumo de sua API bem fluente.

Além de estar fazendo essa migração, uma coisa importante a se fazer é: tornar o mais
testável possível. Uma das metas de testabilidade é tentar contornar o problema de se
precisar estar numa chamada XHR do JavaScript para simular e garantir isso. O ideal é algo
puramente JVM. Então, partiu fazer as coisas no JUnit?

## Como simular algo assíncrono no Java?

Esse foi o primeiro ponto que eu precisei ponderar. Fazer de modo síncrono o callback
não era algo que seria desejável para mim. Então, partiu assincronia?

Uma das coisas que eu vi no Java porém nunca usei foi o
[`Future<T>`](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/Future.html). Vi isso num contexto
quando estava estudando `promises` do JavaScript, e acabei parando nessa questão do Java por
algum motivo aleatório (talvez eu estivesse procurando o equivalente Java para as `promises`?).

Quando estudando Dart para implementar o aplicativo em Flutter para a GeoSales, também vi que
lá existia a classe [`Completer`](https://api.flutter.dev/flutter/dart-async/Completer-class.html),
uma maneira de delegar um preenchimento de valor para o futuro.

Então, por que não brincar com `Future`s no Java? Vi que `Future` era uma interface. Quando brinquei
no Dart, usava `Completer.complete(param)`. Como fazer isso no Java?

Bem, uma das implementações que em tese deveria ser bem fácil de trabalhar é o
[`CompletableFuture<T>`](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/CompletableFuture.html).
Como eu indico que se completou algo? Usando
[`CompletableFuture.complete(T)`](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/CompletableFuture.html#complete-T-)!

Bem, então vamos começar a brincar com isso? Primeiro, colocar algo para a execução. Preciso garantir que eu só faça
validações após a conclusão do futuro. Com `Thread`s (ou `fork` em C) eu usava `Thread.join`, então provavelmente teria
será que tem algo equivalente no `CompletableFuture`? Que tal
[`CompletableFuture.join()`](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/CompletableFuture.html#join--)?

Então, basicamente isso daqui precisa funcionar:

```java
CompletableFuture<Integer> futuro = new CompletableFuture<>();
futuro.complete(1);
futuro.join();
```

Ok, mas como saber se aconteceu de fato uma chamada assíncrona? Podemos pendurar um callback usando
[`CompletableFuture.whenComplete(BiConsumer<? super T, ? super Throwable>)`](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/CompletableFuture.html#whenComplete-java.util.function.BiConsumer-).
Uma das coisas interessantes é que isso deveria funcionar colocando o `whenComplete` tanto _antes_ de completar
o futuro como _depois_:

```java
BiConsumer<Integer, Throwable> simplesPrint = (v, __) -> {
  System.out.println("valor passado " + v);
};
CompletableFuture<Integer> futuro1 = new CompletableFuture<>();
futuro1.whenComplete(simplesPrint);
futuro1.complete(1);

CompletableFuture<Integer> futuro2 = new CompletableFuture<>();
futuro2.complete(2);
futuro2.whenComplete(simplesPrint);

futuro1.join();
futuro2.join();
```

A saída foi:

```
valor passado 1
valor passado 2
```

Ok, mas isso ainda dá feedback visual para um humano que esteja supervisionando.
Como fazer para alterar uma variável e validar que tudo está acontecendo como esperado?

Bem, uma alternativa é "extrair" o estado do lambda e colocar no método. Algo **mais ou menos**
nessa linha:

```java
boolean executou = false;
CompletableFuture<Integer> futuro = new CompletableFuture<>();
futuro.whenComplete((v, e) -> executou = true);
futuro.complete(1);
futuro.join();

assertTrue(executou);
```

Porém, não posso fazer isso. No Java 7 se permite passar para classes anônimas variáveis
finais como _closure_. No Java 8 isso meio que continua sendo verdade, porém agora foi feito
um relaxamento para permitir variáveis _efetivamente_ `final`s. Uma variável é efetivamente final
se ela é atribuída um único valor durante seu _lifetime_ e nunca é alterado. Veja mais nessa [resposta
do Jon Skeet](https://stackoverflow.com/a/4732617/4438007).

Inclusive, o código acima dá o seguinte erro de compilação no IntelliJ:

> Variable used in lambda expression should be final or effectively final

Então, se eu posso passar pro lambda, é como se ela estivesse com o modificador `final`, portanto
não posso alterar o que está atribuído à variável. Mas... posso alterar algo dentro dela. Então, para
ter um efeito na prática com o que eu desejo, posso simplesmente delegar a um objeto que carregue
dentro de si um `boolean`, como o
[`BooleanIndirection`](https://gitlab.com/geosales-open-source/totalcross-functional-toolbox/-/blob/master/functional-toolbox/src/main/java/br/com/softsite/toolbox/indirection/BooleanIndirection.java).
Como a ideia é ter o mínimo de dependências possível além do mínimo necessário para funcionar, eu faço
a minha própria implementação descartável:

```java
static class HasBool {
  boolean value;
  HasBool(boolean initialValue) {
    this.value = initialValue;
  }
}

HasBool executou = new HasBool(false);
CompletableFuture<Integer> futuro = new CompletableFuture<>();
futuro.whenComplete((v, e) -> executou.value = true);
futuro.complete(1);
futuro.join();

assertTrue(executou.value);
```

## No sucesso e na falha

O primeiro ponto aqui é:

- posso cadastrar os eventos (`onBefore`, `onSuccess`, `onFailure`, `onFinally`)
- preciso setar algo para consumir o `AsyncCallback` a ser gerado
- mandar rodar tudo

O segundo desses pontos é o mais fácil de se tratar. Como escolha de design, transformo um
`AsyncCallback<T>` em um
[`Request`](http://www.gwtproject.org/javadoc/latest/com/google/gwt/http/client/Request.html).
Então, vou precisar de uma `Function<AsyncCallback<T>, Request>` para dar certo isso.

Para testar o funcionamento básico, posso colocar um `onSuccess` para interceptar o resultado
de interesse e povoar um `HasBool` como no caso do `CompletableFuture` anterior.

Então, meu teste seria algo nesses termos:

```java
HasBool executou = new HasBool(false);
new AsyncCallbackBuilder<Integer>()
  .onSuccess(i -> executou.value = i == 1)
  .setAsyncCall(...)
  .run();

assertTrue(executou.value);
```

Ok, mas ainda não é assíncrona essa chamada. Preciso plugar esse `AsyncCallback<Integer>`
em um `whenComplete` de um `CompletableFuture<Integer>`. Como fazer? Bem, basicamente me aproveitar
da interface do `AsyncCallback`: ele tem uma função que apenas come um sucesso `T` e outra que come
falhas `Throwable`:

```java
<T> BiConsumer<T, Throwable> asyncCallBack2biConsumer(AsyncCallback<T> cb) {
  return (t, e) -> {
    if (e != null) {
      cb.onFailure(e);
    } else {
      cb.onSuccess(t);
    }
  };
}
```

Note que um retorno com sucesso hipoteticamente pode ser nulo, mas uma exceção lançada
sempre precisa estar preenchida. Logo, se eu tenho uma exceção qualquer, devo jogar para
o `onFailure`; caso contrário, com a exceção nula, eu preciso assumir sucesso. Então, a chamada
assíncrona vai conter, dentro dela, setar o `whenComplete` para o `callback` recebido, falta o
retorno... que basicamente podemos fazer vista graça e retornar `null`:

```java
CompletableFuture<Integer> futuro = new CompletableFuture<>();
HasBool executou = new HasBool(false);
new AsyncCallbackBuilder<Integer>()
  .onSuccess(i -> executou.value = i == 1)
  .setAsyncCall(cb -> {
    futuro.whenComplete(asyncCallBack2biConsumer(cb));
    return null;
  })
  .run();
futuro.complete(1);
futuro.join();

assertTrue(executou.value);
```

Como estou fazendo o mínimo para rolar tentando seguir TDD, isso significa que
eu espero que falhe. Agora, como falhou?

Bem, falhou inicialmente porque o método `run` não faz nada. Então coloquei ele
para recuperar um `AsyncCallback<T>` de dentro do builder. De cara, esse
`getAsyncCallback()` também estava destinado a simplesmente falhar, pois o mínimo
de trabalho é retornar `null`.

Ok, chegou a hora dele ter impacto real. A priori, não faço nada com o que chega,
então tenho que o `onSuccess` padrão deve ser um `noop`. No momento que eu cadastro
mais `onSuccess` diversos, devo encadear os chamados. O próprio `Consumer<T>` já
fornece o método
[`Consumer.andThen(Consumer<? super T>)`](https://docs.oracle.com/javase/8/docs/api/java/util/function/Consumer.html#andThen-java.util.function.Consumer-)
que faz exatamente o que desejamos.

Então, para rodar o teste, tenho que a classe `AsyncCallbackBuilder<T>`
tenha o campo `private Consumer<T> success = t -> {};` já iniciado no `noop`,
o método `onSuccess` atualize o estado interno com `success = success.andThen(arg)`.
Então, coloco para o `onSuccess` do `AsyncCallback` delegar ao `success` construído
pelo builder:

```java
new AsyncCallback<T>() {
  @Override
  public void onFailure(Throwable caught) {
    // TODO
  }

  @Override
  public void onSuccess(T result) {
    success.accept(result);
  }
}
```

Após esses preparativos.

Agora, vamos complicar um pouco? Quero garantir que múltiplas
chamadas ao método `onSuccess` realmente causem que o `callback` no final
execute tudo registrado. Que tal fazer um `onSuccess` que armazena o número passado
e outro que armazena o dobreo desse número? Se eu armazenar em um `HashSet`, posso
inclusive garantir que aconteceram as chamadas verificando se contém os números passados
e também que só se armazenou 2 números:

```java
CompletableFuture<Integer> futuro = new CompletableFuture<>();
HashSet<Integer> armazem = new HashSet<>();
new AsyncCallbackBuilder<Integer>()
  .onSuccess(armazem::add)
  .onSuccess(i -> armazem.add(2*i))
  .setAsyncCall(cb -> {
    futuro.whenComplete(asyncCallBack2biConsumer(cb));
    return null;
  })
  .run();
futuro.complete(1);
futuro.join();

assertEquals(2, armazem.size());
assertTrue(armazem.contains(1));
assertTrue(armazem.contains(2));
```

E tudo funcionou. Próximo passo é fazer o análogo para a falha.

A diferença é que, no lugar de dizer que o futuro completou com o número, eu indico que o
futuro teve uma compleição excepcional
[`CompletableFuture.completeExceptionally(Throwable)`](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/CompletableFuture.html#completeExceptionally-java.lang.Throwable-).

Bem, eu ainda gostaria de fazer um teste antes... quero garantir que não houve nenhuma espécie
de chamada ao `onSuccess`. Então, vamos pegar o primeiro exemplo, fornecer um fim excepcional
e verificar que o `onSuccess` não foi chamado?

```java
CompletableFuture<Integer> futuro = new CompletableFuture<>();
HasBool executouSuccess = new HasBool(false);
new AsyncCallbackBuilder<Integer>()
  .onSuccess(i -> executouSuccess.value = true)
  .setAsyncCall(cb -> {
    futuro.whenComplete(asyncCallBack2biConsumer(cb));
    return null;
  })
  .run();
futuro.completeExceptionally(new RuntimeException());
futuro.join();

assertFalse(executouSuccess.value);
```

Só que... agora não chegou no fim e terminou com uma exceção... por quê?

Na própria documentação do `CompletableFuture.join()` tem a explicação:

- lança `CancellationException` se o cálculo foi interrompido
- lança `CompletionException` se terminou com uma exceção

Logo, preciso engolir a exceção ao redor do `CompletableFuture.join`, já que
essa exceção é perfeitamente esperada e ignorável:

```java
CompletableFuture<Integer> futuro = new CompletableFuture<>();
HasBool executouSuccess = new HasBool(false);
new AsyncCallbackBuilder<Integer>()
  .onSuccess(i -> executouSuccess.value = true)
  .setAsyncCall(cb -> {
    futuro.whenComplete(asyncCallBack2biConsumer(cb));
    return null;
  })
  .run();
futuro.completeExceptionally(new RuntimeException());
try {
  futuro.join();
} catch (CompletionException e) {
  // ignorando feliz
}

assertFalse(executouSuccess.value);
```

Bem, hora de verificar se o `onFailure` está sendo devidamente chamado, correto?
Vamos já extrapolar para duas chamadas distintas:

```java
CompletableFuture<String> futuro = new CompletableFuture<>();
HasBool executouFailure1 = new HasBool(false);
HasBool executouFailure2 = new HasBool(false);
new AsyncCallbackBuilder<Integer>()
  .onFailure(__ -> executouFailure1.value = true)
  .onFailure(__ -> executouFailure2.value = true))
  .setAsyncCall(cb -> {
    futuro.whenComplete(asyncCallBack2biConsumer(cb));
    return null;
  })
  .run();
futuro.completeExceptionally(new RuntimeException());
try {
  futuro.join();
} catch (CompletionException e) {
  // ignorando feliz
}

assertTrue(executouFailure1);
assertTrue(executouFailure2);
```

Bem, não implementei o `onFailure`, né? Vamos implementar de modo
semelhante ao `onSuccess`, mas consumindo `Throwable`s...

> Fazer a implementação do `onFailure` aqui!!!!

Ok, e agora, `onFinally`. Eles devem ser executados sempre. Então, não
basta apenas mandar rodar um `onFinally` e então mandar rodar outro: é preciso
garantir que **todos** disparem.

Como fazer isso? Bem, se houver uma exceção, precisamos capturar ela. As demais
vão ser suprimidas na primeira. Se tiver pelo menos uma exceção, precisamos lançar
ela no final do processamento.

Que tal... transforma o `Runnable` em um `Supplier<Throwable>`?

```java
Supplier<Throwable> toSupplier(Runnable r) {
  try {
    r.run();
    return null;
  } catch (Throwable t) {
    return t;
  }
}
```

Se algo der errado, transforma numa exceção. Porém, não é apenas isso
que queremos, confere? Quando tivermos mais disso, precisamos fazer o
adequado tratamento das demais exceções lançadas e, no frigir do processamento,
disparar a primeira exceção capturada.

No começo, vamos ignorar a possibilidade de múltiplos `onFinally` e focar apenas
em um. Como fazer isso? Bem, ele precisa necessariamente ser executado tanto no final
do `onSuccess` como no do `onFailure`. Se tivermos que `Supplier<Throwable> onFinally` é
a modelagem correta, a implementação seria simplesmente:

```java
  @Override
  public void onSuccess(T result) {
    try {
      success.accept(result);
    } finally {
      Throwable t = onFinally.get();
      if (t != null) {
        throw t;
      }
    }
  }
```

Só que `Throwable` é _checked_, então não posso fazer isso. O que temos
_unchecked_ são `RuntimeException` e classes filhas, e `Error` e classes filhas.

Java 16 permite _instanceof pattern matching_, então podemos relançar facilmente
quando é _unchecked_, ou então envelopar numa `RuntimeException` caso seja
uma _checked_:

```java
Throwable t = s.get();
if (t != null) {
  if (t instanceof RuntimeException rte) {
    throw rte;
  } else if (t instanceof Error e) {
    throw e;
  } else {
    throw new RuntimeException(t);
  }
}
```

Mas... isso estava disponibilizado como _preview feature_ no Java 14, que foi lançado
na mesma época que o GWT 2.9.0 (nosso target atual). Então, vamos à moda antiga, né?

```java
Throwable t = s.get();
if (t != null) {
  if (t instanceof RuntimeException) {
    RuntimeException rte = (RuntimeException) t;
    throw rte;
  } else if (t instanceof Error) {
    Error e = (Error) t;
    throw e;
  } else {
    throw new RuntimeException(t);
  }
}
```

Ok, e como seria o comportamento disso? E se tiver acontecido uma exceção anterior que
precisamos lidar com ela? Ou será que o próprio Java já dá um jeito de lidar com isso
suprimindo uma excção lançada no `finally`? Vamos testar?

```java
boolean ok = false;
try {
	Supplier<Throwable> s = () -> new RuntimeException("lalala");
	try {
		ok = true;
		throw new RuntimeException("Oops");
	} finally {
		Throwable t = s.get();
		if (t != null) {
			if (t instanceof RuntimeException) {
				RuntimeException rte = (RuntimeException) t;
				throw rte;
			} else if (t instanceof Error) {
				Error e = (Error) t;
				throw e;
			} else {
				throw new RuntimeException(t);
			}
		}
	}
} catch (RuntimeException e) {
	e.printStackTrace();
	System.out.println("suprimidas " + e.getSuppressed().length);
}
assertTrue(ok);
```

O resultado aqui foi que capturei a exceção com a mensagem "lalala" e sem nada suprimido.

Bem, resultado não ótimo, mas é possível contornar. Se eu capturar a exceção, o `catch` deve
acontecer _antes_ do `finally`, afinal o `finally` deve acontecer apenas no final. Vamos testar?
Colocar uma variável externa ao `try` interno representando a exceção lançada, capturar qualquer
`throwable` sendo lançado, guardar a sua referência e relançá-lo. Então, no `finally`, se eu tiver
a referência dessa primeira exceção eu coloco a gerada no `finally`, eu suprimo essa exceção na
primeira capturada.

Mas, vou ter um problema de repetição de código aqui. Se eu fizer isso, vou precisar botar tanto
no `catch` como no `finally` esse trecho que transformar o `throwable` em _unchecked_, seja por
conversão de tipo, seja envelopando em uma `RuntimeException`. Então, vamos normalizar isso?

```java
private void silentThrow(Throwable t) {
	if (t instanceof RuntimeException) {
		RuntimeException rte = (RuntimeException) t;
		throw rte;
	} else if (t instanceof Error) {
		Error e = (Error) t;
		throw e;
	} else {
		throw new RuntimeException(t);
	}
}
```

Normalizado isso, voltando à intenção anterior:

1. lançar exceção
2. guardar sua referência no `catch`
3. se tiver referência guardada, suprimir eventual nova exceção gerada no `finally`

```java
boolean ok = false;
try {
	Supplier<Throwable> s = () -> new RuntimeException("lalala");
	Throwable tt = null;
	try {
		ok = true;
		throw new RuntimeException("Oops");
	} catch (Throwable te) {
		tt = te;
		silentThrow(tt);
	} finally {
		Throwable t = s.get();
		if (t != null) {
			if (tt != null) {
				tt.addSuppressed(t);
			} else {
				silentThrow(t);
			}
		}
	}
} catch (RuntimeException e) {
	e.printStackTrace();
	System.out.println("suprimidas " + e.getSuppressed().length);
}
assertTrue(ok);
```

Agora, obtive que quem foi lançado foi a exceção de mensagem "Oops", como
esperado. Vi também que a exceção com a mensagem "lalala" foi devidamente supressa,
e que só tinha essa exceção suprimida.

Ou seja, daqui, temos que, para o modelagem `Supplier<Throwable> onFinally`, o
código dentro do `AsyncCallback.onSuccess` seria o seguinte:

```java
  @Override
  public void onSuccess(T result) {
    Throwable tt = null;
    try {
      success.accept(result);
    } catch (Throwable t) {
      tt = t;
      silentThrow(t);
    } finally {
      Throwable t = onFinally.get();
      if (t != null) {
        if (tt == null) {
          silentThrow(t);
        } else {
          tt.addSuppressed(t);
        }
      }
    }
  }
```

Beleza, ótimo. E no `onFailure`, como fica essa belezura?

Bem, se é `onFailure` já há a chamada em cima de um `Throwable`. Logo, não
preciso armazenar a eventual exceção lançada, apenas suprimi-la no `Throwable`
conhecido:

```java
  @Override
  public void onFailure(Throwable t) {
    try {
      failure.accept(t);
    } catch (Throwable tt) {
      t.addSuppressed(tt);
      silentThrow(t);
    } finally {
      Throwable tt = onFinally.get();
      if (tt != null) {
        t.addSuppressed(tt);
      }
    }
  }
```

Mas, será que é essa mesma a semântica desejada? A priori, o `onFailure`
não lança exceção, ele [_trata_ a exceção recebida do
servidor](http://www.gwtproject.org/doc/latest/tutorial/RPC.html#exceptions). Logo, podemos
esquecer da ideia de colocar tudo para ser supresso no `Throwable` recebido. O código
fica bem semelhante ao do `onSuccess`:

```java
  @Override
  public void onFailure(Throwable t) {
    Throwable tt = null;
    try {
      failure.accept(t);
    } catch (Throwable ti) {
      tt = ti;
      silentThrow(ti);
    } finally {
      Throwable te = onFinally.get();
      if (te != null) {
        if (tt == null) {
          silentThrow(te);
        } else {
          tt.addSuppressed(te);
        }
      }
    }
  }
```

Não há nada para diferir ali, então que tal unificar o que está ao redor daquilo que
está sendo rodado? Eu passo um processamento como parâmetro e envelopo ele dentro dessa
tratativa de erro:

```java
  static void wrapExecution(Runnable r) {
    Throwable tt = null;
    try {
      r.run();
    } catch (Throwable ti) {
      tt = ti;
      silentThrow(ti);
    } finally {
      Throwable t = onFinally.get();
      if (t != null) {
        if (tt == null) {
          silentThrow(t);
        } else {
          tt.addSuppressed(t);
        }
      }
    }
  }

  // ...

  @Override
  public void onSuccess(T result) {
    wrapExecution(() -> success.accept(result));
  }

  @Override
  public void onFailure(Throwable t) {
    wrapExecution(() -> failure.accept(t));
  }
```

> Como o `wrapExecution` independe da instância do objeto, deixei estático mesmo. Não precisaria
nem necessariamente ser um  método da classe específica, poderia ser um método utilitário em outro lugar.

## E nos finalmentes também

Bem, na seção anterior modelamos o `onFinally` como sendo um `Supplier<Throwable>`.
A transformação do `Runnable` em `Supplier<Throwable>` foi bem direto ao ponto. Recordando:

```java
Supplier<Throwable> finallyToSupplierThrowable(Runnable onFinally) {
  try {
    onFinally.run();
    return null;
  } catch (Throwable t) {
    return t;
  }
}
```

Agora, como podemos fazer para encadear essas chamadas? No começo, temos que `onFinally`
é um `() -> null` trivial. Então, para concatenar essas coisas, como prosseguir? Podemos chamar
o objeto anterior e, então, se ele retornar diferente de nulo, usar seu retorno:

```java
onFinally(Runnable onFinally) {
  Supplier<Throwable> oldOnFinally = this.onFinally;
  Supplier<Throwable> otherOnFinally = finallyToSupplierThrowable(onFinally);
  this.onFinally = () -> {
    Throwable tOld = oldOnFinally.get();
    Throwable tNeo = otherOnFinally.get();
    if (tOld != null) {
      if (tNeo != null) {
        tOld.addSuppressed(tNeo);
      }
      return tOld;
    }
    return tNeo;
  };
}
```

## Nâo nos esqueçamos do antes
---
layout: post
title: "ManyCodec: um codec de Redisson para todos dominar"
author: "Jefferson Quesado"
tags: redisson java serialização jackson
base-assets: "/assets/redisson-many-codec/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

O [Redis](https://redis.io/) é um banco de dados de chave valor muito
utilizado, inclusive é uma das principais soluções usadas para cache
distribuído. Ele tem um cliente muito usado em Java, o
[Redisson](https://redisson.pro/).

Pro Redisson, normalmente não basta apenas você conseguir se conectar no Redis,
ele normalmente provê mais coisas para você como programador, para que você
tenha uma melhor DX: ele fornece mecanismos de DeSer para que você já trabalhe
com o objeto adequado no lugar de ficar lidando explicitamente com I/O e bytes!
Para isso, ele usa codecs.

Mas... o que aconteceria se eu salvasse algo via Redisson usando um codec que
ficou... `@Deprecated` com o tempo? Como por exemplo
[`MarshallingCodec`](https://javadoc.io/doc/org.redisson/redisson/3.50.0/org/redisson/codec/MarshallingCodec.html)?

Bem, e que tal tentarmos fazer um codec com múltiplos codecs internos?

# Um codec para todos conquistar?

A ideia do `ManyCodec` é ter um modelo de serialização e diversos modelos de
desserialização. Então seria algo como:

```java
public ManyCodec(Codec writerCodec, Codec... readCodecs) {
    ...
}
```

Assim, podemos tranquilamente manter a compatibilidade com um esquema de
serialização anterior e preparar para uma nova serialização. Como? Por exemplo:

```java
final Codec myCodec = new ManyCodec(
    new MarshallingCodec(),

    new MarshallingCodec(),
    new TypedJsonJacksonCodec(JsonNode.class));
```

Aqui, estamos usando o `MarshallingCodec` como serialização e desserialização
primária, e em segunda opção para desserializar o `TypedJsonJacksonCodec` com
uma opção marota: uma árvore genérica de objeto que pode ser usado para gerar
o que se quiser!

Vamos primeiro supor que a transformação em `JsonNode` esteja funcionando bem.
Com o `JsonNode` em mãos, vou querer transformar ele em um objeto meu para
manipular ele corretamente.

> Isso meio que faz o trabalho do codec novamente? Até faz, mas é o jeito mais
> habitual para mim quando estou trabalhando com Jackson, eu informo o tipo de
> dado que estou desserializando para desserializar corretamente, no lugar de
> depende de anotações mágicas de classe.
> 
> E quando não tenho esse dado, eu leio como `JsonNode` que eu posso bem dizer
> fazer uma navegação em árvore desse tipo de dado.

Para transformar um `JsonNode` em um objeto qualquer, como por exemplo um
record que só envelopa uma string qualquer, eu posso fazer isso:

```java
record Wrapper(String valor) {}

final var original = new Wrapper("abc");

// ... transforma o `original` em `data` usando o codec ...

final var node = (JsonNode) manyCodec.getValueDecoder().decode(data, null);
final var w = objectMapper.treeAsValue(node, Wrapper.class);
IO.println(w); // Wrap[valor=abc]
```

## Implementando a interface `Codec`

Essa interface vem das definições do
[Redisson](https://javadoc.io/static/org.redisson/redisson/3.52.0/org/redisson/client/codec/Codec.html):

- decoders para 3 tipos de coisas
- encoders para 3 tipos de coisas
- resgate de classloader

Por hora vou completamente ignorar a questão do classloader. Agora, quais são
esses tipos e coisas?

- valores (não mapas)
- chaves de mapas
- valores de mapas

Como só se tem um único codec usado para fazer fazer a serialização, posso
simplesmente fazer o encadeamento para o `writerCodec` passando o método
adequado:

```java
public class ManyCodec implements Codec {

    private final Codec writeCodec;
    private final Codec[] readCodecs;
    // ...

    public ManyCodec(Codec writeCodec, Codec... readCodecs) {
        // ...
    }

    // métodos de decod/etc

    @Override
    public Encoder getMapValueEncoder() {
        return writeCodec.getValueEncoder();

    }

    @Override
    public Encoder getValueEncoder() {
        return writeCodec.getValueEncoder();
    }

    @Override
    public Encoder getMapKeyEncoder() {
        return writeCodec.getMapKeyEncoder();
    }
}
```

Ok, e o processo de decoding? Vamos simplificar isso e focar por hora só nos
casos de `getValueDecoder()`. Para isso, precisamos definir qual dos codecs
será usado. Agora, como fazer isso?

Que tal... fazer isso na "sorte"? O `Decoder` tenta fazer a desserialização, e
o mecanismo de falha é lançar uma exceção `IOException`. Então... que tal
tentar com uma e, se capturar a exceção, tenta a próxima?

Vamos começar com o passo simples: itera e retorna.

```java
public class ManyCodec implements Codec {

    private final Codec writeCodec;
    private final Codec[] readCodecs;
    // ...

    public ManyCodec(Codec writeCodec, Codec... readCodecs) {
        // ...
    }

    // métodos de encod/etc
    
    @Override
    public Decoder<Object> getValueDecoder() {
        return (buf, state) -> {
            for (final var codec: readCodecs) {
                return codec.getValueDecoder().decode(buf, state);
            }
        };
    }
}
```

Hmmm, mas aqui tem caso que o compilador identifica como vazamento... pois
vamos soltar uma exceção caso nada aconteça? Agora o foco apenas no método
específico:

```java
@Override
public Decoder<Object> getValueDecoder() {
    return (buf, state) -> {
        for (final var codec: readCodecs) {
            return codec.getValueDecoder().decode(buf, state);
        }
        throw new IOException("Could not decode data with known codecs!");
    };
}
```

Tá, se fizer decoding é só do primeiro codec de leitura. Tá valendo? Tá
valendo! Vamos testar? Modelo mais simples, uma string, no lugar de objeto
complexo.

Um modelo de teste é tentar usar o `MarshallingCodec` para fazer o DeSer. Algo
como:

```java
final var original = "abc";

final var manyCodec = new ManyCodec(new MarshallingCodec(), new MarshallingCodec());
final var buff = manyCodec.getValueEncoder().encode(original);
final var w = manyCodec.getValueDecoder().decode(buff, ...);
IO.println(w);
```

Hmmm, como que usam o segundo argumento de `decode`? O tal de `state`? Bem, em
`org.redisson.RedissonLocalCachedMap` tem um uso desse jeito:

```java
@Override
protected CacheValue updateCache(ByteBuf keyBuf, ByteBuf valueBuf) throws IOException {
    CacheKey cacheKey = localCacheView.toCacheKey(keyBuf);
    Object key = codec.getMapKeyDecoder().decode(keyBuf, null);
    Object value = codec.getMapValueDecoder().decode(valueBuf, null);
    cachePut(cacheKey, key, value);
    return new CacheValue(key, value);
}
```

Eles usam `null` para o estado inicial. Quem sou eu para questionar isso? Vamos
de nulo para a serialização inicial!

```java
final var original = "abc";

final var manyCodec = new ManyCodec(new MarshallingCodec(), new MarshallingCodec());
final var buff = manyCodec.getValueEncoder().encode(original);
final var w = manyCodec.getValueDecoder().decode(buff, null);
IO.println(w);
```

E... _voi là_! Funcionou! Agora... mudar um pouco o jogo, vamos fazer o encode
com o `JsonJacksonCodec` e tentar ler com ele mesmo...

```java
final var original = "abc";

final var manyCodec = new ManyCodec(new JsonJacksonCodec(), new JsonJacksonCodec());
final var buff = manyCodec.getValueEncoder().encode(original);
final var w = manyCodec.getValueDecoder().decode(buff, null);
IO.println(w);
```

E tudo funcionou. Mas... será que eu de fato eu fiz a serialização correta?
Vamos ver como que ficou o `buff`, imprimir o seu conteúdo...

Meu primeiro pensamento foi usar o método `array(): byte[]`, mas isso gerou uma
exceção:

```none
Exception in thread "main" java.lang.UnsupportedOperationException: direct buffer
	at io.netty.buffer.PooledUnsafeDirectByteBuf.array(PooledUnsafeDirectByteBuf.java:226)
    ...
```

Então não posso usar isso. Mas... eu posso alocar um array de bytes e ler os
bytes nesse array, e depois transformar em string:

```java
int n = buff.readableBytes();
final var arr = new byte[n];
buff.getBytes(0, arr, 0, n);
IO.println(new String(arr));
```

Ok, eu consigo com isso ver que ele está serializando a string como eu
esperava: `"abc"`, com as aspas, no modelo JSON de ser.

Agora com isso fora da cabeça, vamos iterar de verdade nos codec de leitura.
Já temos um `for-each` bem estabelecido, basta apenas agora nos garantir contra
as exceções:

```java
@Override
public Decoder<Object> getValueDecoder() {
    return (buf, state) -> {
        for (final var codec: readCodecs) {
            try {
                return codec.getValueDecoder().decode(buf, state);
            } catch (IOException e) {
                e.printStackTrace(); // placeholder só pra ver o erro ocorrendo
            }
        }
        throw new IOException("Could not decode data with known codecs!");
    };
}
```

E o código para teste:

```java
final var original = "abc";

final var manyCodec = new ManyCodec(new JsonJacksonCodec(), new MarshallingCodec(), new JsonJacksonCodec());
final var buff = manyCodec.getValueEncoder().encode(original);
final var w = manyCodec.getValueDecoder().decode(buff, null);
IO.println(w);
```

Aqui a escrita vai ser usando o codec para JSON e a primeira leitura vai ser
usando o `MarshallingCodec`, para então a segunda leitura ser o codec correto
para JSON. E o resultado?

```none
java.io.IOException: Unsupported protocol version 34
	at org.jboss.marshalling.river.RiverUnmarshaller.start(RiverUnmarshaller.java:1375)
	at org.redisson.codec.MarshallingCodec.lambda$new$0(MarshallingCodec.java:150)
	at ManyCodec.lambda$new$0(ManyCodec.java:31)
	at Main.main(Main.java:25)
com.fasterxml.jackson.databind.exc.MismatchedInputException: No content to map due to end-of-input
 at [Source: (io.netty.buffer.ByteBufInputStream); line: 1, column: 0]
	at com.fasterxml.jackson.databind.exc.MismatchedInputException.from(MismatchedInputException.java:59)
	at com.fasterxml.jackson.databind.ObjectMapper._initForReading(ObjectMapper.java:4688)
	at com.fasterxml.jackson.databind.ObjectMapper._readMapAndClose(ObjectMapper.java:4586)
	at com.fasterxml.jackson.databind.ObjectMapper.readValue(ObjectMapper.java:3585)
	at org.redisson.codec.JsonJacksonCodec$2.decode(JsonJacksonCodec.java:99)
	at ManyCodec.lambda$new$0(ManyCodec.java:31)
	at Main.main(Main.java:25)
Exception in thread "main" java.io.IOException: Could not decode data with known codecs!
	at ManyCodec.lambda$new$0(ManyCodec.java:40)
	at Main.main(Main.java:25)
```

Ué... mas... por quê? Bem, vamos olhar o estado do `buffer` que é passado! Na
primeira iteração ele está assim:

```none
PooledUnsafeDirectByteBuf(ridx: 0, widx: 5, cap: 256)
```

E logo em seguida ele dá uma exceção e fica assim:

```none
PooledUnsafeDirectByteBuf(ridx: 5, widx: 5, cap: 256)
```

Ou seja... a segunda leitura não é feita no mesmo estado da primeira leitura...
e agora?

Bem, a classe `io.netty.buffer.ByteBuf` tem o método chamado `copy()`! Então...
que tal no lugar de tentar fazer a desserialização com o `buf` fazer com a sua
cópia?

```java
@Override
public Decoder<Object> getValueDecoder() {
    return (buf, state) -> {
        for (final var codec: readCodecs) {
            try {
                final var bufCpy = buf.copy();
                return codec.getValueDecoder().decode(buf, state);
            } catch (IOException e) {
                e.printStackTrace(); // placeholder só pra ver o erro ocorrendo
            }
        }
        throw new IOException("Could not decode data with known codecs!");
    };
}
```

Bem, aqui dá tudo certo, exibe o `abc` direitinho e mostra o stacktrace ali de
placeholder.

## Lidando com exceções

Hmmm, não queremos simplesmente imprimir os erros a esmo, não é? Uma estratégia
seria que um erro suprimisse o outro, até que chegaria um momento em que de
fato não fosse possível transcrever com nenhum codec, aí lançaria a exceção
adequada. Que tal fazer isso?

Vamos manter no histórico a última exceção lançada. As demais exceções lançadas
pelo caminho serão mantidas como exceções suprimidas dentro da última:

```java
@Override
public Decoder<Object> getValueDecoder() {
    return (buf, state) -> {
        IOException lastThrownException = null;
        for (final var codec: readCodecs) {
            try {
                final var bufCpy = buf.copy();
                return codec.getValueDecoder().decode(buf, state);
            } catch (IOException e) {
                if (lastThrownException != null) {
                    e.addSppressedException(lastThrownException);
                }
                lastThrownException = e;
            }
        }
        throw new IOException("Could not decode data with known codecs!", lastThrownException);
    };
}
```

Vamos fazer um teste?

```java
final var manyCodec = new ManyCodec(
    new JsonJacksonCodec(),
    
    new MarshallingCodec(), new MarshallingCodec(), new MarshallingCodec(), new MarshallingCodec()
);
final var buff = manyCodec.getValueEncoder().encode(original);
final var w = manyCodec.getValueDecoder().decode(buff, null);
IO.println(w);
```

E o resultado foi:

```none
Exception in thread "main" java.io.IOException: Could not decode data with known codecs!
	at ManyCodec.lambda$new$0(ManyCodec.java:39)
	at Main.main(Main.java:25)
Caused by: java.io.IOException: Unsupported protocol version 34
	at org.jboss.marshalling.river.RiverUnmarshaller.start(RiverUnmarshaller.java:1375)
	at org.redisson.codec.MarshallingCodec.lambda$new$0(MarshallingCodec.java:150)
	at ManyCodec.lambda$new$0(ManyCodec.java:30)
	... 1 more
	Suppressed: java.io.IOException: Unsupported protocol version 34
		... 4 more
		Suppressed: java.io.IOException: Unsupported protocol version 34
			... 4 more
			Suppressed: java.io.IOException: Unsupported protocol version 34
				... 4 more
```

## Os demais métodos de desserialização

Até o momento, a implementação foi focada apenas em um único m;etodo de
desserialização. E quanto aos outros?

Bem, se pensarmos em termos de funções, precisamos acessar uma função dentro
da definição dos objetos. Para o `getValueDecoder` é a função
`getValueDecoder`, e a mesma coisa para `getMapKeyDecoder` (que precisa acessar
`getMapKeyDecoder`) e para `getMapValueDecoder`. Então, isso significa que eu
tenho um acesso homogêneo: dada a minha função, eu preciso acessar aquele
algoritmo descrito acima que lida com as exceções e tudo o mais, acessando uma
função do objeto através da função.

Em termos de Java, seria como se eu tivesse algo que recebesse
`Function<Codec, Decoder<Object>>` e devolvesse um `Decoder<Object>`. Ou
seja... `Function<Function<Codec, Decoder<Object>>, Decoder<Object>>`.

Mas como adaptaríamos o algoritmo? Bem, simples. Ele em si é um
`Decoder<Object>`, dado que ele recebe a entrada correta (`ByteBuf,State`) e
tem o retorno correto (`Object`). Então, preciso de um argumento do tipo de
função de mapeamento que retorne essa função:

```java
map -> (buf, state) -> {
    //...
}
```

Basicamente fazemos um 
[`adapter`]({% post_url 2025/2025-05-24-functions-as-design-patterns %})
que permite essa HoF. Internamente seria só usar o mapeamento no lugar de fazer
a chamada de função direto:

```java
(final var map) -> (final var buf, final var state) -> {
    IOException lastThrownException = null;
    for (final var codec: this.readCodecs) {
        try {
            final var bufCopy = buf.copy();
            final var decoder = map.apply(codec);
            return decoder.decode(bufCopy, state);
        } catch (IOException e) {
            // e.printStackTrace();
            if (lastThrownException != null) {
                e.addSuppressed(lastThrownException);
            }
            lastThrownException = e;
        }
    }
    throw new IOException("Could not decode data with known codecs!", lastThrownException);
};
```

E isso eu armazeno como um
`Function<Function<Codec, Decoder<Object>>, Decoder<Object>>`.

Finalmente, as chamadas ficam assim:

```java
@Override
public Decoder<Object> getMapValueDecoder() {
    return decoder.apply(Codec::getMapValueDecoder);
}
```

## Estado final

Aqui o codec implementado:

```java
import org.redisson.client.codec.Codec;
import org.redisson.client.protocol.Decoder;
import org.redisson.client.protocol.Encoder;

import java.io.IOException;
import java.util.function.Function;

public class ManyCodec implements Codec {

    private final Codec writeCodec;
    private final Codec[] readCodecs;
    private final Function<Function<Codec, Decoder<Object>>, Decoder<Object>> decoder;

    public ManyCodec(Codec writeCodec, Codec... readCodecs) {
        this.writeCodec = writeCodec;
        if (readCodecs.length != 0) {
            this.readCodecs = readCodecs;
        } else {
            this.readCodecs = new Codec[] { writeCodec };
        }
        
        this.decoder = (final var map) -> (final var buf, final var state) -> {
            IOException lastThrownException = null;
            for (final var codec: this.readCodecs) {
                try {
                    final var bufCopy = buf.copy();
                    final var decoder = map.apply(codec);
                    return decoder.decode(bufCopy, state);
                } catch (IOException e) {
                    if (lastThrownException != null) {
                        e.addSuppressed(lastThrownException);
                    }
                    lastThrownException = e;
                }
            }
            throw new IOException("Could not decode data with known codecs!", lastThrownException);
        };
    }

    @Override
    public Decoder<Object> getMapValueDecoder() {
        return decoder.apply(Codec::getMapValueDecoder);
    }

    @Override
    public Encoder getMapValueEncoder() {
        return writeCodec.getValueEncoder();
    }

    @Override
    public Decoder<Object> getMapKeyDecoder() {
        return decoder.apply(Codec::getMapKeyDecoder);
    }

    @Override
    public Encoder getMapKeyEncoder() {
        return writeCodec.getMapKeyEncoder();
    }

    @Override
    public Decoder<Object> getValueDecoder() {
        return decoder.apply(Codec::getValueDecoder);
    }

    @Override
    public Encoder getValueEncoder() {
        return writeCodec.getValueEncoder();
    }

    @Override
    public ClassLoader getClassLoader() {
        return writeCodec.getClassLoader();
    }
}
```
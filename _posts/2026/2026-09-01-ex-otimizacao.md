---
layout: post
title: "Pequeno exemplo de otimização"
author: "Jefferson Quesado"
tags: otimização java performance
base-assets: "/assets/ex-otimizacao/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Estava eu assistindo um vídeo do {{ site.data.podcasts.people["vepo"] }} sobre
performance
([Devemos pensar na performance o tempo todo ao programar?](https://youtu.be/QDCqFdcKxOo?si=vVIwlEEbUcEsKnBn))
que ele citou a célebre frase do Donald Knuth

> Otimização prematura é a raiz de todo o mal.

[Donald Knuth, Structured Programming with Go To Statements, 1974](https://dl.acm.org/doi/epdf/10.1145/356635.356640)

A frase completa é legal! Ainda mais como exposta no
[Laws of Software Engineering](https://lawsofsoftwareengineering.com/laws/premature-optimization/)

> We should forget about small efficiencies, say about 97% of the time:
> premature optimization is the root of all evil. Yet we should not pass up our
> opportunities in that critical 3%.

Em tradução livre:

> Nós devemos nos esquecer quanto a pequenas [melhorias de] eficiências, cerca
> de 97% do tempo: otimização prematura é a raiz de todo o mal. Ainda assim,
> não devemos deixar passar as oportunidades nesses 3% críticos.

Nesse momento imaginei o Gandalf impedindo o Balrog Durin's Bane de perseguir a
Sociedade do Anel, mas agora estou divagando...

A citação original continua com uma parte importante:

> [...]. It is often a mistake to make a priori judgments about what parts of a
> program are really critical, since the universal experience of programmers
> who have been using measurement tools has been that their intuitive guesses
> fail.

O espírito dessa frase é algo no sentido de que a intuição do programador leva
a otimizar cantos que, ao se medir de fato a performance, são lugares cuja
mudança levou a lugar nenhum. Segundo a heurística do próprio Knuth, 97% tem
impacto quase 0 no programa, enquanto que os 3% críticos tem impacto
significativo.

Enfim, tudo isso me fez recordar de um caso bem curioso, em uma vida passada.
O software estava rodando em produção, finalmente estava estabilizado. Mas algo
me incomodava com os testes, eu sentia que ele estava demorando mais do que o
que devia. Então, liguei o Visual VM e rodei contra a suíte de testes completa!
E finalmente ficou claro que tinha um trecho que estava consumindo um tempo
considerável, uns 3% a 6% do tempo total. E era uma operação trivial e básica,
que era realizada o tempo todo: comparação de dois números!

# Observações sobre o conteúdo

Aqui estou lidando com coisas que aconteceram há mais de 10 anos, então tome as
coisas com um saudável _grain of salt_, não tanto literalmente. Então, ao falar
que as coisas estavam demorando de 3% a 6%, esses números são metafóricos. Pode
ter sido mais inclusive, mas difícil que tenha sido menos do que o limite
inferior porque esse fato me chamou a atenção, e menos de 3% não seria
considerável.

Eu tenho em lembrança mais ou menos a _big picture_ da coisa, então até mesmo
algumas coisas podem estar um pouco fora da realidade. Mais abaixo eu trago
o código da comparação, eu coloquei uma versão mais caricata do que seria ele,
talvez não usasse tantas instâncias de `BigDecimal` para realizar a comparação.
O exemplo foi devidamente caricaturado para efeito dramático.

# Comparando dois números

Quando estamos lidando com números não inteiros, precisamos saber que besta
estamos lidando. Elas tem jeitos distintos para serem lidadas.

No caso específico, eu estava lidando com números de precisão arbitrária em
Java, os famosos
[`BigDecimal`](https://docs.oracle.com/en/java/javase/25/docs/api//java.base/java/math/BigDecimal.html)s.
O bom é que sempre que possível eles dão resultados exatos. Porém... sempre que
possível não é sempre. Existem situações em que não há resultado exato para
esse tipo de representação, situações que carregam erros. E uma das principais
delas: a divisão. E sim, em algumas ocasiões eu precisava fazer divisões.

{% katexmm %}

Nesse tipo de situação, se define uma margem de aceitabilidade. Apesar de
fazer contas com uma quantidade grande de casas decimais, foi decidido que o
limite do aceitável de erro era a partir da 7 casa decimal. Ou seja, se dois
números tivessem uma diferença de cerca de $10^{-7}$, eles eram considerados
iguais para todos os propósitos.

Nesse tipo de cenário, a comparação é feita mais ou menos assim:

$$
approx\_equals\left(a, b\right) = |a - b| \le \epsilon
$$

Para a operação de comparação em si:

$$
compare\left(a, b\right) =
\begin{cases}
    approx\_equals(a, b) & EQ \\
    a \gt b & GT \\
    a \lt b & LT
\end{cases}
$$

{% endkatexmm %}

# Limitações tecnológicas: wrappers de wrappers

Dessa época eu me lembro de uma limitação muito forte que eu sofria: eu
precisava de um código que fosse compatível com TotalCross, GWT (depois de
transpilado para JavaScript) e servidor Tomcat tradicional. E por incrível que
pareça um dos impedimentos era o tipo: TotalCross oferecia o próprio
`totalcross.util.BigDecimal`, enquanto que o Java (e sua contraparte do GWT)
ofereciam o `java.math.BigDecimal`.

Uma das versões utilizadas para gerar o aplicativo TotalCross para
Android/Win32 não tinha a opção de _translate_ automático de
`java.math.BigDecimal` para o `totalcross.util.BigDecimal` (ainda bem, diga-se)
e, portanto, eu não podia usar o `BigDecimal` padrão do Java no TotalCross. Em
compensação, eu não podia usar o código do `BigDecimal` do TotalCross no GWT.

Então, qual foi minha solução? Bem, se lembra que eu mencionei que o TotalCross
fazia o _translate_ automático de algumas classes? Pois bem, existia um caso
bem conhecido disso: `*4D`. O que seria uma coisa `4D`? Seria algo como
`for device`, para o dispositivo. Então, ao encontrar `path.to.SomeClass` e
existia no classpath a classe `path.to.SomeClass4D`, o TotalCross
automaticamente fazia a tradução do `path.to.SomeClass4D` para
`path.to.SomeClass`, permitindo assim que `SomeClass` fosse sobrescrita com
a versão `*4D`.

Na teoria isso permitiria que eu fizesse códigos absurdos como a classe que
iria para o dispositivo ser totalmente incompatível com a classe para a qual eu
compilei o resto do mundo, tendo métodos a mais, métodos a menos, construtores
arbitrariamente diferentes e outras coisas.

Então, como que sanei isso? Com um pouco de engenho!

- criei a interface `my.own.IBigDecimal`
- implementei a classe de referência
  `my.own.BigDecimal implements my.own.IBigDecimal`
- em uma outra dependência, implementei
  `my.own.BigDecimal4D implements my.own.IBigDecimal`

Para a classe, mesmo que eu quisesse eu não conseguia desviar muito do que a
implementação base precisava ter. E como eu tinha que a versão do TotalCross
também implementava aquilo, eu botei o compilador para trabalhar por mim quando
começava algum desvio de assinaturas.

E por dentro dessas classes, como que funcionava? Bem, do jeito mais tosco que
se pode imaginar... apenas wrappers:

```java
public interface IBigDecimal<N extends IBigDecimal<N>> {

    // ...
    N add(N other);
    N abs();
    int signum();

    // ...

    // método específico para obter o valor da plataforma
    Object unwrap();
}
```

```java
public class BigDecimal implements IBigDecimal<BigDecimal> {

    // olha aqui fazendo o wrapping do BigDecimal do Java!!!
    private final java.math.BigDecimal value;

    private BigDecimal(java.math.BigDecimal value) {
        this.value = value;
    }

    public BigDecimal(String value) {
        this(new java.math.BigDecimal(value));
    }

    // ...

    @Override
    public BigDecimal add(BigDecimal other) {
        return new BigDecimal(this.value.add(other.value));
    }

    @Override
    public BigDecimal abs() {
        return new BigDecimal(this.value.abs());
    }

    @Override
    public int signum() {
        return this.value.signum();
    }

    // ...

    @Override
    public Object unwrap() {
        return this.value;
    }
}
```

```java
public class BigDecimal4D implements IBigDecimal<BigDecimal4D> {

    // olha aqui fazendo o wrapping do BigDecimal do TotalCross!!!
    private final totalcross.util.BigDecimal value;

    private BigDecimal4D(totalcross.util.BigDecimal value) {
        this.value = value;
    }

    public BigDecimal4D(String value) {
        this(new totalcross.util.BigDecimal(value));
    }

    // ...

    @Override
    public BigDecimal4D add(BigDecimal4D other) {
        return new BigDecimal4D(this.value.add(other.value));
    }

    @Override
    public BigDecimal4D abs() {
        return new BigDecimal4D(this.value.abs());
    }

    @Override
    public int signum() {
        return this.value.signum();
    }

    // ...

    @Override
    public Object unwrap() {
        return this.value;
    }
}
```

Toda operação, bem dizer, envolvia desmontar o número em mãos, o número RHS
sendo passado, operar como `BigDecimal` do tipo original, e então envelopar
novamente na classe wrapper. Uma operação de soma se tornava dois acessos de
campo, invocação de método virtual, alocação de objeto devido a essa chamada e
finalmente alocação do objeto wrapper e depositar o novo objeto de valor recém
calculado. De modo geral, agora se duplica as alocações. Mas consigo mandar
para todas as minhas plataformas alvo! Hehe!

A API que foi exposta na interface (e que, portanto, era a API pública do que
se podia fazer com `BigDecimal`) era uma interseção conveniente entre o que o
`BigDecimal` do Java fornecia e o que o `BigDecimal` do TotalCross suportava.
Essa superfície de exposição acabou sendo mais larga que o esperado, assim como
a assinatura do genérico ficou mais complexa do que o desejado, mas pelo menos
funcionava.

Para o caso de precisar acessar os objetos finais da plataforma em questão
(de modo geral apenas para serialização e persistência), eu tenho a opção do
`unwrap` que retorna um `Object`. No caso Java tradicional eu já tinha o objeto
de trabalho, no caso do TotalCross tinha um inconveniente: eu precisava
transformar aquele objeto opaco em `totalcross.util.BigDecimal` para poder
trabalhar. A solução passou por outra classe com `4D`:

```java
public class ExtractPlatformValue {

    public static totalcross.util.BigDecimal extractPlatformNativeValue(BigDecimal myBigDecimal) {
        return new totalcross.util.BigDecimal(myBigDecimal.toPlainString());
    }
}

// no arquivo ao lado

public class ExtractPlatformValue4D {

    public static totalcross.util.BigDecimal extractPlatformNativeValue(BigDecimal4D myBigDecimal) {
        return (totalcross.util.BigDecimal) myBigDecimal.unwrap();
    }
}
```

## Sobre o "ainda bem que não fazia o translate automático"

Existia uma operação que o `BigDecimal` do TotalCross executava diferentemente
do `BigDecimal` do Java. E era a operação de `mod`, quando o operando era
negativo.

O comportamento era sutilmente distinto, algo como o resultado continuava
negativo e o esperado era que fosse positivo. A solução também era trivial,
algo nesse sentido aqui:

```java
// BigDecimal referência
public BigDecimal mod(BigDecimal other) {
    return new BigDecimal(this.value.mod(other.value));
}

// implementação TotalCross
public BigDecimal4D mod(BigDecimal4D other) {
    totalcross.util.BigDecimal d = other.value;
    totalcross.util.BigDecimal v = this.value.mod(d);
    if (v.signum() < 0) {
        v = v.add(d.abs());
    }
    return new BigDecimal4D(v);
}
```

# A operação crítica

Dado esse contexto, vamos examinar como que era a operação de comparação com
precisão:

```java
public static final BigDecimal DEFAULT_PRECISION = BigDecimal.ONE.movePointLeft(7);

public static int compareWithPrecision(BigDecimal a, BigDecimal b) {
    return compareWithPrecision(a, b, DEFAULT_PRECISION);
}

public static int compareWithPrecision(BigDecimal a, BigDecimal b, BigDecimal epsilon) {
    final BigDecimal diff = a.subtract(b).abs();
    if (diff.subtract(epsilon).signum() <= 0) {
        return 0;
    }
    return a.compareTo(b);
}
```

{% katexmm %}

Aqui eu defini um epsilon padrão de $10^{-7}$, portanto tudo cuja diferença é
menor do que ou igual a esse threshold é considerado ruído. Agora, como pode um
trecho de 7 linhas estar tão crítico assim, nos testes automatizados?

{% endkatexmm %}

Bem, esse trecho, mesmo curto do jeito que é, é chamado muitas e muitas vezes
no path crítico de execução. Como é algo que é chamado de modo demasiado, então
qualquer vacilo é propagado muitas e muitas vezes.

Ok, vamos ver o que essa função faz? Subtrai 2 valores, pega o valor absoluto.
Então subtrai de novo e verifica o sinal desse novo número. Finalmente, se não
cair no caso de "igual aproximado", faz a comparação e retorna. Onde pode estar
o gargalo nisso?

Comecei a me questionar "e se estivermos criando muitos números à toa?"...

Resgatando a fórmula:

{% katexmm %}
$$
compare\left(a, b\right) =
\begin{cases}
    approx\_equals(a, b) & EQ \\
    a \gt b & GT \\
    a \lt b & LT
\end{cases}
$$

Aqui não diz nada _diretamente_ sobre quando $a = b$... mas sabemos que, se
isso de fato ocorrer, então esse é um caso especial de $approx\_equals$. Vamos
supor aqui que a comparação seja barata, e que é comum obter números de fato
iguais sem precisar da aproximação, então se eu simplesmente comparar eu não
vou gastar espaço criando mais dois objetos (o `BigDecimal` wrapper e o
`BigDecimal` real)! E, olha só! Eu já vou ter o resultado da comparação sem
precisar me preocupar em fazer isso no fim!

Então, vamos adaptar um pouco a fórmula para o que queremos:

$$
compare\left(a, b\right) =
\begin{cases}
    a = b & EQ \\
    approx\_equals(a, b) & EQ \\
    a \gt b & GT \\
    a \lt b & LT
\end{cases}
$$
{% endkatexmm %}

E isso em Java ficaria assim:

```java
public static int compareWithPrecision(BigDecimal a, BigDecimal b, BigDecimal epsilon) {
    final int comparison = a.compareTo(b);
    if (comparison == 0) {
        return 0;
    }
    final BigDecimal diff = a.subtract(b).abs();
    if (diff.subtract(epsilon).signum() <= 0) {
        return 0;
    }
    return comparison;
}
```

Ok, muito bem. Agora, eu realmente vou precisar gerar um número novo, que é a
diferença entre `a` e `b`. Mas... eu preciso gerar o valor absoluto disso? Na
verdade, não, eu não preciso. Eu já sei quem é maior e quem é o menor.
Portanto, eu posso fazer a conta de modo que eu obtenho um número
garantidamente positivo!

{% katexmm %}
Considerando que $a\not=b$, e que $max(a, b)$ retorna o maior entre os dois e
que $min(a, b)$ retorna o menor entre os dois, então
$max(a, b) - min(a, b) \gt 0$.
{% endkatexmm %}

Logo, apesar de ainda ter a subtração, agora eu posso garantir que só será
gerado um novo número, não dois novos números. Já sabendo que a comparação não
é 0, precisamos agora só filtrar para os casos de positivo e negativo:

```java
public static int compareWithPrecision(BigDecimal a, BigDecimal b, BigDecimal epsilon) {
    final int comparison = a.compareTo(b);
    if (comparison == 0) {
        return 0;
    }
    final BigDecimal M, m;
    if (comparison > 0) {
        M = a;
        m = b;
    } else {
        m = a;
        M = b;
    }
    final BigDecimal diff = M.subtract(m);
    // ...
    return comparison;
}
```

Ok, isso adicionou uma penca de complexidade, mas estou evitando novas
alocações em memória! O que nesse caso pela métrica que tiramos aparentava
estar fazendo diferença.

Agora que temos um `diff` garantidamente positivo, vamos comparar com o
`epsilon` para ver se está dentro da margem de erro. Aqui, não precisamos de
nova subtração, apenas uma comparação direta: se for zero ou negativo, então tá
dentro da margem!

```java
public static int compareWithPrecision(BigDecimal a, BigDecimal b, BigDecimal epsilon) {
    final int comparison = a.compareTo(b);
    if (comparison == 0) {
        return 0;
    }
    final BigDecimal M, m;
    if (comparison > 0) {
        M = a;
        m = b;
    } else {
        m = a;
        M = b;
    }
    final BigDecimal diff = M.subtract(m);
    if (diff.compareTo(epsilon) <= 0) {
        return 0;
    }
    return comparison;
}
```

Após essas alterações, a medida (que antes constantemente apontava problemas
nessa parte) agora mostra que esse não é mais um ponto de atenção importante. O
tempo decorrido nesse trecho não era mais significante.

# A comparação final

Peguemos a função original:

```java
public static int compareWithPrecision(BigDecimal a, BigDecimal b, BigDecimal epsilon) {
    final BigDecimal diff = a.subtract(b).abs();
    if (diff.subtract(epsilon).signum() <= 0) {
        return 0;
    }
    return a.compareTo(b);
}
```

Simples, direta, entrega o que promete. Porém, aqui, fazemos alocação de 3
elementos toda vez que ela é chamada:

- `a.subtract(b)` cria um novo objeto
- `.abs()` cria um novo objeto
- `diff.subtract(epsilon)` cria um novo objeto

Agora, a versão modificada:

```java
public static int compareWithPrecision(BigDecimal a, BigDecimal b, BigDecimal epsilon) {
    final int comparison = a.compareTo(b);
    if (comparison == 0) {
        return 0;
    }
    final BigDecimal M, m;
    if (comparison > 0) {
        M = a;
        m = b;
    } else {
        m = a;
        M = b;
    }
    final BigDecimal diff = M.subtract(m);
    if (diff.compareTo(epsilon) <= 0) {
        return 0;
    }
    return comparison;
}
```

Aqui, em _muitos_ casos (como a comparação com o zero) não gera um novo
elemento. Existem diversos casos em produção cuja ideia era comparar com zero,
assim como em testes também. Assim, para esses casos a comparação será
trivialmente resolvida sem precisar alocar novos elementos.

Mas, para o caso em que a comparação não é trivialmente igual, como ela se
comporta? Nesse caso, acontece uma única criação de elemento, `M.subtract(m)`.
Não há necessidade de obter o valor absoluto (economizando uma criação de
objeto) porque sabemos que o maior objeto estará necessariamente em `M`, logo a
subtração sempre retornará um valor positivo.

Além disso, a comparação com a precisão, o epsilon, foi feita para não gerar
nenhum novo elemento, economizando aqui uma outra criação de objetos.

## Poderia otimizar o wrapper?

Bem, uma pergunta óbvia a ser realizada: eu poderia otimizar o wrapper? E a
resposta é: claro que poderia!

Por exemplo, no método `abs()`, a implementação padrão do Java (ao menos
no Temurin) é algo assim:

```java
public BigDecimal abs() {
    return (signum() < 0? negate(): this);
}
```

Aqui, a classe `BigDecimal` já se otimiza, evitando a criação de objetos de
modo desnecessário. Nesse tipo de cenário, mesmo assim a quantidade de novos
objetos criados seria _potencialmente_ reduzido, não seria algo garantido. Já a
manipulação algébrica garante que `M > m`, logo será ótimo sempre. Ser esperto
em como fazemos a comparação aqui parece que vale mais a pena do que otimizar o
wrapper por baixo, né?

Mas de toda sorte eu poderia ainda assim otimizar o wrapper, né? Será que vale
a pena? Bem, vamos lá pensar a respeito...

Apesar de ser algo que perpassa todo o sistema (com todos os cálculos sendo
feitos usando `BigDecimal` para tudo), ter um código otimizado e esperto se
justifica se ele estiver causando impacto. Mas de toda sorte, qual seria o
custo de ter um código esperto?

Bem, talvez não seja tanto. Mas há. Um código wrapper puro é mais simples de
manter. Imagina uma implementação no `BigDecimal4D` que não é utilizado de
maneira comum durante o tempo de desenvolvimento? Se ela estiver equivocada?
Qual o custo desse equívoco?

Por exemplo, o código de `mod` (mencionado
[acima](#sobre-o-ainda-bem-que-não-fazia-o-translate-automático)) continha um
problema que estava fora do contexto de teste tradicional, que só foi detectado
após um caso específico de um corner-case. Esse é um tipo de operação que
naturalmente não iríamos escrever um teste para ela, pois não faria sentido
testar isso. Até o momento em que um valor específico fez a necessidade
aparecer.

Para esse ponto específico conseguimos escrever um teste _depois do fato_. Mas
e se tentássemos ser espertos com as mais diversas operações? De modo que o
reuso do wrapper desse certo? Bem, sinceramente? Os casos de problema para a
quantidade de mão de obra disponível para detectar e reverter o problema não
valia a pena.

Apesar de alocar múltiplos objetos quando não havia necessidade, não tinha
métrica para justificar uma atuação naquele ponto. Tentar otimizar isso sem
ganho palpável com um código mais esperto seria perigoso, pois poderíamos sim
introduzir bugs.

> Otimização prematura é a raiz de todo o mal.

# Uma nota sobre a raiz da raiz de todo o mal

Entre eu começar a escrever este post e eu terminar o rascunho e _quase_
publicar, aconteceu algo importante: a palestra [_The root of the root of all
evil_](https://www.computerenhance.com/p/theroot) do
[Casey Muratori](https://caseymuratori.com/) ficou
[disponível no YouTube](https://www.youtube.com/watch?v=hpj6r6CjJf8).
Especificamente o vídeo do {{ site.data.podcasts.people["vepo"] }} foi lançado
no dia anterior ao do Casey Muratori, e eu comecei a escrever este post na
noite em que o cafezinho ficou disponível para mim.

No "a raiz da raiz de todo o mal" o Casey investiga o que Knuth queria dizer com
"medir". E, bem, no parágrafo em que Knuth fala sobre otimização prematura ele
ainda chega a dizer que "todos os compiladores deveriam por design indicar os
pontos mais críticos". Aqui isso é um indicativo forte de que a medida ainda
assim era uma medida estática, não uma medida de cronômetro. Casey inclusive
fala que não encontrou relatos de Knuth fazendo medida de performance com um
"stopwatch" como fazemos hoje em dia, e que "medida de performance" que o Knuth
mencionou era algo bem diferente do que entendemos hoje em dia.

Knuth coloca no artigo que o tempo gasto de um determinado algoritmo de exemplo
era de `14n + 5` e que no apêndice ele detalhava mais como que era a regra
desse cálculo que ele fazia. Se não fosse pelo Casey, eu juro que não teria
percebido isso e assumiria (erroneamente) que Knuth tinha medido com o clock da
CPU ou coisa equivalente o tempo de execução do algoritmo, mas não. Ele estava
medindo quantas vezes a memória era acessada em um processador com múltiplos
registradores porém sem cache. "[...] cada instrução custa uma unidade, mais
outra unidade se acessar memória".

Uma das hipóteses que o Casey levantou sobre isso era que, como os computadores
eram coisas que normalmente você mandava os cartões perfurados e então uma
pessoa da faculdade ficava lá alimentando o computador para processar as coisas
no seu time slice do computador compartilhado, medir o tempo que demorava para
executar não era algo prático.

De toda sorte, mensurar na prática o programa, que agora são peças separadas em
diversos pedaços cujos componentes podem executar de modo distinto dependendo
do payload recebido e que não precisam necessariamente chegar a um fim
determinado ou mesmo sequer desejado (web servers, por exemplo, são desenhados
para funcionarem eternamente em loop infinito), com um cronômetro ou algo
equivalente, é uma forma de mensuração. E na minha opinião uma ótima heurística
para ser levada em consideração.

Portanto, venho aqui defender novamente, conforme a citação:

> Otimização prematura é a raiz de todo o mal.

Por mais que o que se considere como prematuro e o que se considere como uma
forma válida de se medir o desempenho tenha se alterado com o passar das
gerações de programadores.

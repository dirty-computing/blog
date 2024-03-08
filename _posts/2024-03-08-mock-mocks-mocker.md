---
layout: post
title: "Quando o mock mocka o mockador"
author: "Jefferson Quesado"
tags: java testes-unitários mock mockito engenharia-de-software
base-assets: "/assets/mock-mocks-mocker/"
draft: "true"
---

Quem me segue no Twitter deve ter percebido que eu estou em uma cruzada.
O [Gomex](https://twitter.com/gomex) viu minha indignação contra
mocks e pediu para eu comentar mais sobre, para sair da bolha dev do Twitter.
Para deixar claro, eu não gosto de mocks.
Não gosto de mocks  *mesmo*. E você também não deveria gostar. 

> Ah, mas eu faço os mocks dos objetos com valores padrão

Provavelmente não é um mock, meu jovem. Temos esse vício de linguagem.
O [Camus](https://twitter.com/cybermangueboy) do Twitter uma vez compartilhou
esse artigo do Fowler
[Mocks Aren't Stubs](https://martinfowler.com/articles/mocksArentStubs.html)
e o [Mockito Made Clear](https://pragprog.com/titles/mockito/mockito-made-clear/)
quando estava estudando sobre testes. E nessas fontes tem uma parte que o Camus 
achou importante o suficiente para dar um destaque, que é a diferença
entre stubs e mocks?

- **Stub**: informações enlatadas
- **Mock**: guarda que houve chamada para objetos que foram pré-configurados
  com ações e as vezes dados enlatados

Então, quando você simplesmente fala "vou mockar esse dado no objeto"
você provavelmente quer fazer é um simples stub.

Essa tecnicalidade é um ponto importante para o debate que eu carrego contra
mocks: use stubs.

Um ponto também que o Camus cita é sobre spy:

- **Spy**: guarda que houve chamada, mas delega para o objeto real

Particularmente eu acho o spy muito mais interessante. Entrarei em detalhes depois,
mas o teste com código de produção e de modo mais NATURAL possível é o melhor.
Se você artificializa demais, tem certeza que estará testando algo de produção?

A propósito, apesar de eu estar na cruzada contra o conceito do mock,
esse artigo aqui será feito focado em Java. Mas a minha pegada do "não abuse"
é real e transcende limitações sintático-semânticas e paradigmas de linguagens
de programação.

# Mocks te levam a lugares estranhos

As vezes queremos garantir um comportamento. Só que o trecho sob
teste depende daquela funçãozinha maldita estática ali no meio
que vai discar o telefone vermelho da Casa Branca por conta do
acontecimento de um ataque nuclear e precisa que o Presidente
dos Estados Unidos da América cumpra o seu contrato de
Exterminação Mútua Garantida™.

E, bem, você precisa testar aquilo ali. É extremamente importante
que nessa situação a sua função `Doomsday.armagedon()` chame a
função `POTUS.assuredMutualDestruction(Country theEnemyObliterateThem)`.
Se pudesse mockar um método estático e só verificar que aquela
chamada ocorreu ia ser tão bom, né?

E advinha? É possível fazer isso. É possível meter a mão no meio do
bytecode java no meio do teste e redirecionar chamadas de métodos estáticos
para bater em outro ponto do código que não o natural dele. E sabe
o que é o pior? Eu te ensino, tá no meu
[jardim de anotações](https://github.com/jeffque/digital-garden/blob/main/mockito-junit5-static.md).

Em resumo: você precisa fazer um _lifting_ com algumas dependências,
no caso do JUnit o _lifting_ em si é feito rodando a "extensão mockito",
então você pode bem dizer para para mockar a _classe_ em si, e então
controla cada trecho `static` do seu código de modo bem semelhante a
o que seria o controle de um mock de objeto comum.

> Particularmente eu suspeito que isso seja magia feita
> com interceptação de chamadas do _classloader_ e a alma
> de um coelho inocente sacrificado para deuses dos mundos
> exteriores.

_Et voilà_, você tem um mock em cima do método estático.
Parabéns, uma fadinha morreu por essa heresia.

Outros pontos estranhos que o mock leva é: e quando eu mocko
um objeto em cima de uma função e preciso que um método `protected`
dele seja chamado como se fosse método real?

Passei por situação semelhante no trabalho, ao criar um
componente do _tree walking_ e a um colega meu criar outro
componente do _tree walking_. Inclusive, o esquema de
testes automatizados que bolamos era extremamente semelhante:

- desenhava o trecho da lang
- mandava o compilador rodar
- controlava os efeitos colaterais gerados

Só que o meu teste funcionava e o dele soltava `NullPointerException`.
O ponto do código dele que dava problema era algo mais
ou menos nesse sentido:

```java
public class MyColleagueVisitor extends Visitor {
    // ...
    public Decision visitNodeAndDecide(Node node) {
        //...

        // linha 104
        Decision decision = createDecision();
        decision.setValue("something"); // linha 106
        return decision; // linha 107
    }
}
```

E o teste dele dava sempre `NullPointerException at MyColleagueVisitor.visitNodeAndDecide line 106`.
Conclusão? Que o `createDecision` estava retornando nulo. _Easy peasy lemon squeeze_, erro de código
do colega. Até que se investiga `MyColleagueVisitor`. Ela não implementa explicitamente
em nenhum lugar `createDecicion()`. Então essa função deve pertencer a classe mãe, correto?
Bem, correto. Erro da classe mãe?

```java
public abstract class Visitor {
    protected abstract Something something();
    protected abstract Value value();
    protected abstract String message();

    // ...
    protected Decicion createDecision() {
        return new Decision(something(), value(), message());
    }
}
```

Hmmm, isso retorna nulo? Por código Java, não. Jamais.
O resultado disso é necessariamente um objeto alocado do tipo
`Decision` criado ou o lançamento de alguma `RuntimeException`
ou de algum `Error`. Não tem outra alternativa segundo a linguagem
e sabendo que esse método não foi sobrescrito no objeto em
questão. Portanto, não havia erro no código do meu colega.
Ele está seguro. Mas o teste quebrava de toda sorte.

Um dos experimentos que pedi para ele fazer foi tirar
o exato componente dele do mock e chamar diretamente passando
"o `Node` porém como objeto". Foi chato mudar da linguagem
para descrever o `Node` diretamente, então fizemos uma chamada bem
imperativa ao código, e funcionou. Mistério resolvido? Não, porque
fazer esse tipo de mudança deixou o teste de certa forma mais
feia e menos confiável.

Colocamos o mock novamente no objeto, mas já na estrutura
mais nova do teste. E voltou a apresentar aquele erro
do `NullPointerException at MyColleagueVisitor.visitNodeAndDecide line 106`.
O próprio mock que estava fazendo com que a chamada à classe
mãe causasse um erro nesse método `protected`.

No teste que eu escrevi, nada relativo ao _tree walker_ tinha mock.
Criei o componente do _tree walker_ como manda o figurino, injetei
mocks (hipocrisia que chama?) de partes do sistema que eram opacas
para o meu teste e não sofri com coisa similar. O `JeffVisitor` usado
era real, natural, não um mock _fake natty_. E ele por si só não
falhava porque o mock estava fazendo comportamentos estranhos.

Mocks levam pessoas a cantos estranhos...

# Pseudotestes

Meu caso mais recente de coisas de mock foi uma leitura
que fui levado ao engano. Precisei mudar um trecho do sistema
que executava diversos `Command`s. Cada command em si era
uma espécie de `interface Command { void doSomething(); }`.
Algo bem GoF mesmo
([Refactoring Guru sobre Command](https://refactoring.guru/design-patterns/command)).

E existiam dois desses `Command`s que eram bem cruciais:

- `TheZicadoOne`
- `ComplicatedStuff`

Os comandos eram executados por um executor que garantia que eles
seriam feitos de modo paralelo ao processamento que estava
acontecendo, então tinha um quêzinho de lógica nesse
executor. E também precisava garantir que um `Command` não
conseguisse parar o processamento de outro `Command` (exceto
em casos que o programa não tem controle, como `Error`).

Meu papel foi mudar um detalhe desse executor, então
fui ver como era o teste do executor para ver se já
tinha alguma garantia para o requisio "um `Command` não
conseguir parar o processamento de outro `Command`":

```java
@Test
void commandsSimplyRunEvenWhenException() {
     // ...
     try {
        executor.runCommands(theZicadoOne, complicatedStuff)
            .join();
     } catch (Exception e) {
        verify(complicatedStuff).doSomething();
     }
}
```

Hmmm, ok. Além de estar testando o componente de execução está
testando o trabalho do `TheZicadoOne` e o do `ComplicatedStuff`?
Mas... cadê as 1500 dependências que o complicado precisava? E o
acesso a banco do zicado, estes testes não sobem banco local
para testar, será que deixaram atrás de algum repositório
fake ou coisa assim?

Bem, nada disso.

```java
@Mock TheZicadoOne theZicadoOne;
@Mock ComplicatedStuff complicatedStuff;
```

Era tudo mock. E o começo da função que foi omitida, só configuração de mocks:

```java
@Test
void commandsSimplyRunEvenWhenException() {
     doThrow(new RuntimeException()).when(theZicadoOne).doSomething();
     doNothing().when(complicatedStuff).doSomething();
     try {
        executor.runCommands(theZicadoOne, complicatedStuff)
            .join();
     } catch (Exception e) {
        verify(complicatedStuff).doSomething();
     }
}
```

Ou seja, um teste que foi feito desenhando intereação entre 3 compoentes
distintos só seria para testar no máximo 1 componente. Os outros dois
componentes ali estão servindo de nada. Apenas mocks de `Command`s
no lugar do `TheZicadoOne` e `ComplicatedStuff` seriam o suficiente.
A menção a essas duas criaturas apocalípticas não servia de nada
além de confundir o leitor e dar falsa sensação de segurança.

## Teste que não quebra

Como um caso específico do pseudoteste, eu peguei um caso em que a mudança
do código não fez quebrar o teste. Então, para que existia o teste mesmo?

Pois bem, basicamente vinha um `Event` dos céus. Ele tinha um `Type` e também
poderia opcionalmente ter um `intensity`. Em uma primeira ideia, foi levantado
a possibilidade do _corner case_ `TypeX, intensity != null`. Mas apenas para `TypeX`
e quando `intensity != null`.

Foi desenhado um componente para lidar com isso. Para os tipos de evento `TypeA`
e `TypeB`, era supostamente garantido ter a propriedade `lalala`. Para os tipos de
eventos `TypeZ`, `TypeW`, a propriedade `lalala` seria nula. Quando tinha um evento `TypeX`, a
presença ou ausência de `intensity` iria determinar se `lalala` estaria ou não presente,
com `intensity != null` significando que teria a propriedade `lalala`. Então o
compoente era bem dizer a função `function hasLalalaProperty(event: Event): bool`.

Muito bem, tempo passou e o _corner case_ foi considerado indesejado. Ou seja,
`TypeX` se comporta igual ao `TypeZ` e ao `TypeW`, nunca tendo a propriedade `lalala`.
Vamos criar um teste para isso e... bem, tá funcionando aqui. Mesmo mudando completamente
o comportamento de dentor do componente, ele sempre se comporta redondinho eu similar...

Até que foi descoberto que nos locais de teste da propriedade `lalala`, o componente
de decisão estava sendo guiado por um mock. Remoção do mock, limpeza do recinto,
e agora os testes refletem o cenário desenhado no teste. Não preciso mais
configurar o stub do meu evento para dizer que ele é do tipo `TypeA` e que
o componente retornará verdade, basta dizer que o evento é do tipo `TypeA`.

# E como prosseguir?

Bem, relembremos aqui o caso de Exterminação Mútua Garantida™,
um contrato multilateral assinado pelas nações que produzem
esse tipo de armamento.

`Doomsday.armagedon()` chamava em circuntâncias especiais o
`POTUS.assuredMutualDestruction(Country theEnemyObliterateThem)`, mas nem sempre.
Como fazer isso nese caso?

Ben, minha sugestão foi: deixe seu código testável. `POTUS.assuredMutualDestruction`
é borda do sistema. Vamos garantir que a borda do sistema foi alcançada.
Para evitar criar mais abstrações, usemos algo que vai receber um `Country` e pronto.
Um `Consumer<Country>`. Isso basta para representar. Como esse trecho de código
a se testar é antigo, melhor não mexer na API pública já presente, que é
`Doomsday.armagedon()`. Mas nada impede que `Doomsday.armagedon()` seja um
proxy bem configurado para chamar `Doomsday.armagedon(Consumer<Country>)`,
e colocar a lógica pesada na função `Doomsday.armagedon(Consumer<Country>)`. Sai de algo assim:



```diff
 public class Doomsday {
     // ...
     public Apocalypse armagedon() {
+        return armagedon(POTUS::assuredMutualDestruction); // Exterminação Mútua Garantida™
+    }
+
+    public Apocalypse armagedon(Consumer<Country> doomsdayHandler) {
        // ...
-       POTUS.assuredMutualDestruction(theEnemy);
+       doomsdayHandler.accept(theEnemy);
+
        // ...
        return apocalypseNow;
    }
     // ...
 }
```

Com essas 7 linhas eu tornei um código que não era testável em um código
testável, e não precisei mudar em nada os muitos blocos de código que
dependiam desse componente. A API pública de `Doomsday` agora permite
explicitar para qual fronteira do sistema irá ser disparada, o que nesse
caso não seria o ideal, mas sacrificar para expor uma fronteira do sistema
foi considerado um belo trade-off.

De resto, os outros casos poderia trabalhar mais para evitar criar o mock
(eu sei que para o caso específico do _tree walker_ é um esforço não trivial,
literalmente _being there done that_), usar spy no lugar de mock (afinal,
viva o natural, e sempre que possível se prefira o natural) e deixar
para usar mocks/spies em situações de _fronteira_ do sistema. Tem um vídeo
do Code Aesthetics que fala justamente sobre as fronteiras do sistema,
inclusive tem um conteúdo bem rico sobre isso: [Dependency Injection,
The Best Pattern](https://www.youtube.com/watch?v=J1f5b4vcxCQ).

# Devo fugir do mock como o cão foge da carrocinha?

Não. Tenho opiniões fortes sobre mock, mas mesmo assim, não precisa tanto.
Sabe o exemplo do trabalho a toa que se pensava estar 2 outros comandos
complicados? Poderia ser um mock diretamente da interface que resolveria o problema:

```diff
-@Mock TheZicadoOne theZicadoOne;
-@Mock ComplicatedStuff complicatedStuff;
+@Mock Command cmd1;
+@Mock Command cmd2;
 @Test
 void commandsSimplyRunEvenWhenException() {
-     doThrow(new RuntimeException()).when(theZicadoOne).doSomething();
-     doNothing().when(complicatedStuff).doSomething();
+     doThrow(new RuntimeException()).when(cmd1).doSomething();
+     doNothing().when(cmd2).doSomething();
     try {
-        executor.runCommands(theZicadoOne, complicatedStuff)
+        executor.runCommands(cmd1, cmd2)
            .join();
     } catch (Exception e) {
-        verify(complicatedStuff).doSomething();
+        verify(cmd2).doSomething();
     }
 }
```

Olha como que de fato fica:

```java
@Mock Command cmd1;
@Mock Command cmd2;
@Test
void commandsSimplyRunEvenWhenException() {
    doThrow(new RuntimeException()).when(cmd1).doSomething();
    doNothing().when(cmd2).doSomething();
    try {
        executor.runCommands(cmd1, cmd2)
           .join();
    } catch (Exception e) {
        verify(cmd2).doSomething();
    }
}
```

Pronto, pelo menos agora não tem nem como dar a entender que
os testes para os comandos mais zicados e complicados
estão sendo executados. Aqui agora é só o teste do componente
`Executor` com duas implementações arbitrárias dos balões.

Nesse caso, perceba que o domínio de dentro do comando
é completamente alheio ao executor do comando em si? Como
se o pattern `Command` fosse a fronteira que o `Executor`
precisa passar a bola? Então, mocks nas fronteiras do
"sistema", ou da fração do sistema que está sendo levada
em consideração.

# Por que evitar _fake natty_ afinal?

Bem, temos um sistema. Ele é feito de partes. Os teste olham as partes do sistema.
Mas não apenas isso, testes bons vão poder ver as partes do sistema em movimento e
interagindo. E no sistema, o que importa _mais_ é a propriedade emergente
de suas partes e comunicações. Um bom teste precisa ser feito nas fronteiras do
sistema.

Agora, o que considerar as fronteiras do sistema? Bem, as partes internas
dela podemos (muitas vezes) considerara que são... partes, não fronteiras.
Podemos considerar também que o banco é uma parte do sistema.

Por sinal, um anti-padrão de testes é fazer um mock/stub na camada de
comunicação com o banco. Declarar que aquilo é uma fronteira intransponível.
Mas isso traz seus problemas:

- e se estiver consultando alguma tabela/view inválida?
- e se o banco encrencar com os tipos de colunas diferentes na hora do join?
- como posso ver se realmente estou fazendo a consulta correta na shopee?

Existem várias pequenas partes de comunicação com o banco ali que
simplesmente por atrás de um mock irão _esconder_ do teste. Eu mesmo
já testemunhei lugares em que os erros se concentravam principalmente
nesta camada.

E advinha? Tinha testes nessa camada da comunicação da aplicação com o banco?
Não, não tinha. Mas nesse caso foi uma limitação técnica que não foi possível
ser superada, que era subir o banco durante a execução do teste automatizado.
Foi feita uma escolha _deliberada_ de considerar o banco como uma fronteira,
para pelo menos garantir automaticamente a parte até chegar do banco e
trabalhando com hipotéticos dados recuperados.

Além disso, chamar um componente de um modo não natural ao sistema
pode fazer com que propriedade emergentes estranhas surjam. Bugs
podem aparecer, mas bugs que só existem porque o componente do
sistema que garantia um requisito foi ignorado. E que provavelmente
o erro em si seja chamar um procedimento sem a garantia dos requisitos.

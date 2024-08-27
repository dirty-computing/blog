---
layout: post
title: "As mentiras que te contaram sobre OOP"
author: "Jefferson Quesado"
tags: programação-orientada-a-objetos programação paradigmas engenharia-de-software haskell java
base-assets: "/assets/mentiras-oop/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Você sabe o pq você usa OOP?

Então, existem motivos e motivos para se usar OOP. Alguns mais nobres, outros nem tanto.
Mas finalmente tem aqueles motivos que são simplesmente errados. Mentiras.

Venho aqui expor algumas dessas mentiras.

> Inspirado nessa [thread do Twitter](https://x.com/JeffQuesado/status/1825947635834118389)

# Mentira #1: Você define seus tipos

Ao fazer a propaganda de OOP, pessoal vende que a orientação a objetos é o
único caminho verdadeiro para se ter tipagem bem feito. Mas... não é bem assim.

Linguagens FP com tipagem permitem tipos bem ricos, inclusive melhor
reuso entre tipos de for tipada estruturalmente.

Inclusive, Haskell tem um sistema de tipos bem rico. Vale a pena experimentar.
Por exemplo, só pra ilustrar, peguei aqui
[mapeamento de tipos no StackOverflow](https://stackoverflow.com/q/22337214/4438007).
Ele começa pedido o tipo da função `map`, e obtém como resposta isso:

```haskell
> :t map
map :: (a -> b) -> [a] -> [b]
```

Isso significa que, dada uma função que mapeia coisas do tipo `a` para o tipo `b`,
e também uma lista de elementos do tipo `a`, você obtém uma nova lista de elementos
do tipo `b`. Como aplicar na prática? Bem, podemos duplicar os elementos da lista,
que tal?

```haskell
duasVezes :: Int -> Int
duasVezes x = 2*x

map duasVezes [1, 2, 3]
-- retorna [2, 4, 6]
```

Consigo também brincando aqui no lugar de prender a usar sempre o dobro a retornar
a multiplicação que eu quiser. Basta que minha função retorne uma função:

```haskell
nVezes :: Int -> Int -> Int
nVezes n x = n*x

map (nVezes 5) [1, 2, 3]
-- retorna [5, 10, 15]
```

Tudo isso só para mostrar que programação funcional acolhe e permite tipos.
Um outro exemplo em que uso apenas a análise de tipos para guiar o jeito
que eu codei, usando um estilo de programação mais funcional do que
imperativo ou orientado a objetos, foi no artigo [Somando valores sem laços]({% post_url 2022-09-09-soma-valores-sem-loops %}).

Além disso, a OOP em si não se preocupa com tipos. Se você pegar por exemplo Python,
JavaScript, Ruby, todas essas linguagens que se dizem orientadas a objetos, você
só pasosu a ter tipos recentemente. Antes era tudo duck-typing. Python passou a ter
_type hints_ a partir da versão 3.5 (2015). Ruby passou a oficialmente ter suporte
a tipos oficialmente através do RBS, lançado junto ao Ruby 3 em 2020.
E JavaScript? Bem, JavaScript contnua sem tipos, desenvolveram até outras lingaugens
em cima de JS para suportar tipos (como TypeScript, Dart).

# Mentira #2: Reuso de software através de métodos

Isso aí é desculpa pra herança. Você reusa funções. Alguns casos a função precisa de dados juntos.
Como você reusa funções, você pode promover funções a serem cidadãs de primeira classe.

# Mentira #3: Você escreve menos

Comparando com...?

Clausuras permitem que o compilador trabalhe mais pra você do que apenas OOP clássica imperativa.
Então você pode usar clausuras e escrever menos.

Um exemplo clássico aqui: somar os elementos de um array:

Haskell:
```haskell
foldl (\ x y -> x + y) 0 [1, 2, 3, 4]
```

Java com streams:
```java
int[] array = {1, 2, 3, 4};
IntStream.of(array).reduce(0, (a, b) -> a + b);
```

Java com iteração `for-each`:
```java
int[] array = {1, 2, 3, 4};
int acc = 0;
for (int n: array) {
    acc += n;
}
```

Java com iteração via índice do array (o mais imperativo possível), de trás pra frente:
```java
int[] array = {1, 2, 3, 4};
int acc = 0;
for (int i = array.length - 1; i >= 0; i--) {
    acc += array[i];
}
```

Java com iteração via índice do array, agora crescente:
```java
int[] array = {1, 2, 3, 4};
int acc = 0;
for (int i = 0; i < array.length; i++) {
    acc += array[i];
}
```

Então, onde escreveu menos? No estilo funcional, independente de Java ou Haskell.

# Mentira #4: OOP é construtor padrão e getter e setter

Amigo, isso é javismo cultural. Você entende de onde vem isso?
Normalmente OOP prega que você não precise expor suas entranhas,
que você tenha um canal de troca de mensagens padronizado
(por exemplo, push/pop em pilha/fila).

Então OOP sem javismo cultural existe no contexto de ir na direção
oposta a expor informação. Getters e setters são um idioma para permitir
que a JVM consiga mexer em atributos de dados sem precisar acoplar a
interface de fronteira (banco ou UI no caso de AWT) com o objeto.

Isso permite que a JVM inspecione o objeto a ser preenchido e enxertar
o valor adequado. Essa mágica era possível através da introspecção,
que é uma maneira de se praticar meta-programação. Construtor padrão
vem para facilitar criar o objeto base vazio pra preencher os dados.

Além disso, essas práticas de meta-programação permitiram fazer
serializadores e desserializadores de runtime independentes do dado
sendo serializado. Se você seguir um idioma padronizado já em outros
ferramentais, você poderia exploitar isso para serializar.

Também entra aqui questão de enxertar valores de configurações definidos
em arquivos que não são código/compilados para código, como os temíveis XMLs
de configuração do Java que era muito comum na década de 2000.

# Mentira #5: o jeito certo de evoluir o dado é mudando o dado

Bem, sinto dizer mas definitivamente ✨DEPENDE✨. Se você permite que os dados
sejam mudados em runtime, você remove do compilador opções de deixar seu código
🔥BLAZINGLY FAST🔥, já que ele não vai poder brincar com a ordem das operações.

Tem situações em que dados mutáveis são bons, como por exemplo quando o
compilador não é evoluído o suficiente para perceber isso, ou na antiguidade
quando você precisava lidar com a memória como recurso precioso e não poderia
se dar o luxo de desperdiçar alguns kb de memória.

# Pra fechar o assunto

Independente de qqr coisa, o que vai realmente dominar no que um
paradigma/uma prática/uma maneira de codar é bom ou não é a sua capacidade
de tirar o melhor dela, e sua disciplina.

Tal qual OOP tem seus problemas, você também vai encontrar muita masturbação
intelectual em FP. Se você não sabe extrair o melhor da situação, só trocar
cegamente de OOP para FP ou o contrário ou mesmo indo pro lógico você estará
apenas atirando no próprio pé.

Dito isso, não se esqueça de um pequeno detalhe que é o mais crucial: você
vai encontrar muito mais por aí pessoas que codam de modo imperativo, mais OOP,
do que gente que gosta de Haskell. Isso implica que a força de reserva do mercado
voltado a OOP é maior, portanto é _menos arriscado_ para as empresas apostar
em langs com essa pegada, já que elas vão conseguir repor eventuais devs que
saiam do trabalho com mais facilidade.

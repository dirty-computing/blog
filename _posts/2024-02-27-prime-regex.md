---
layout: post
title: "Expressões regulares podem detectar números primos?"
author: "Jefferson Quesado"
tags: regex expressão-regular primo primalidade matemática autômatos
base-assets: "/assets/prime-regex/"
---

# tl;dr

Não. Mas se tiver uma simples extensão, sim.

A regex abaixo com extensões compatíveis com PCRE detecta números que não
são primos:

```
^1?$|^(11+?)\1+$
```

> Baseado na minha resposta sobre a pergunta [Uma máquina de estados finitos é capaz de detectar primalidade de um número?](https://pt.stackoverflow.com/q/436448/64969)

# Sobre conjuntos gerados por processos markovianos

Expressões regulares são uma maneira expressiva de se representar
um tipo específico de conjuntos. Toda expressão regular visa
representar um conjunto de palavras que podem ser obtidas
através de um alfabeto finito e uma conjunto finito de regras.

Especificamente, imagine um grafo qualquer, no qual você tem um começo.
Você precisa partir daquele ponto específico. A cada passo que você dá
no grafo, imagina que você escreva uma letra. Agora imagine que existam
alguns vértices especiais, que você pode simplesmente chegar e falar
"pronto, terminei". A palavra produzida por esse grafo nesse procedimento
é uma palavra válida para aquele grafo. Todo o conjunto de palavras
produzidas dessa maneira formam um conjunto regular. Por exemplo:

![Um autômato finito determinístico][dfa]

Esse processo de geração de palavras é nomeado de "processo markoviano".

Vamos ver aqui se ele reconhece a palavra `001010`. Vou listar apenas o estado atual
e o que falta consumir da palavra. Como começamos em `S1` sempre,
a primeira entrada vai ser `S1 - 001010`, então cada letra consumida vou
alterando o estado no sentido adequado. Se chegar no final da palavra no
estado `S1`, o único estado de "aceitação" presente, então essa é uma
palavra aceita pelo grafo.

- `S1 - 001010`
- `S2 - 01010`
- `S1 - 1010`
- `S1 - 010`
- `S2 - 10`
- `S2 - 0`
- `S1 - `

Pronto, aceitou.

Perceba que, para o caso desse grafo de reconhecimento, reconhecer um "trecho"
de palavra depende apenas do próprio trecho de palavra e do estado em que se
encontra. Não há necessidade, aqui, de saber como que se saiu do estado inicial
para o estado atual. Esse é um dos motivos pelos quais se fala que para
reconhecer palavras de linguagens que são representadas por esses grafos
_não se precisa de memória_.

> A propósito, se estiver estudando a partir de Chomsky, por exemplo
> [On Certain Formal Properties of Grammars*](https://pdf.sciencedirectassets.com/273276/1-s2.0-S0019995800X0157X/1-s2.0-S0019995859903626/main.pdf?X-Amz-Security-Token=IQoJb3JpZ2luX2VjEJr%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLWVhc3QtMSJHMEUCIQCNoPEjR56DSMgxwBmyyn9EyCOqIDYYSqBSg%2BELonOrMwIgZSNBzQDKScx4E%2FdXQ%2FOkDaflYJcQr0YF6GrgJ7fiT5gquwUIgv%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARAFGgwwNTkwMDM1NDY4NjUiDMYvC5OTA9QE3EpjCiqPBWj86JkODY4oj%2BtXlPf9tKrKcI6C1B80syWLwk1b2ZQXsbjZtGv51ZmPOPqlCDeBeXcrnnatpgLVrG6PGFF6eObEHLt0A2dZHH0V9QajoEmisqZ6FLllR%2BqMsNfht2ujG1JfmncHrqZzrHWhHPfhiGzOU%2BucIsBrg3CRl0TEMAcysiaNrYz0yCpaJuogFzgFrymsuQluRbReAQ%2Bztz8U6vbeMr7nxLEFdZ89EoGm97soix7gHuKnw0CdK8GfTWsszpL8RCIjOoJx64ETKoXpYUJFjgifRZtOj5veTrkzHI9bfC1Na86o4Wi8foU%2BZGTIDt2NLHvHWAD%2BInXM%2F%2B5tUN0RPgCRNA2cp92XwCovXN6ojlwF3URyhPv%2FhoCR0uBYAVS8vsKpGO0hF0qGzCxRZi%2Bi2EoveZQQBHo%2BVdTaSfSUWPUKDWdpfLI5OOBAGxj1rkEy8WTQzlmWuA%2BPb%2FlfAV1ToTNr4B8fQgotTAaPYN0UH11Ii6SzS1flPmyEPEIXNIKTKMrWrTCQsW3JgC9s6poOM4DXEezlA5UbjmiGydhKpvku7mGDhssm4dK9gxrhXKf3DCBgcpcKbkqLGndTJAnaPHJ7u3BeSznb3zIygfbhlVtvcKxlBmcHlFAbMk7ryFtMiUFDlLcf6gZQyFOb%2FJ6W0ZwU9Q4GIt6vx1rjvwkkm10AlgyJFiAQdep8OuGpE7hiFPAZFbTkfbpyM7G1agu4A1JizHYcTxnlBdTpapxtwEeFBm7MIR51chMkm07ABNdd17S%2F0lRiu8aEk2TeBL7GCSgtnmyJe69Jn93%2Bd9sp5U1iWbGoaid1ipbCdgX4XCUdlPVaCs9NJAFTs6c8OBP3KytcDaPd7vNWw5CI7uIw6YLlrgY6sQFVQzRr7V3m3doRiVAK7aBSzchzFGTpVHU21X9isEBXLOGMmUTgZ%2BUDuU%2F%2FHMAFoIKQw4xPhw%2FAFCt8urJICz%2FbsLF%2Bg5qrpyiv8M3f5GaU0WWLiiBKOBEcABVF7cPL3VpOT48fJoQ1V77BpmM9rTADUMs32ey51KZDqjzEj86%2FSJRsY0wKD0xk9dY2hSBIFYl9WOWmJAKlJuiH5hlogZ%2B19CYkP%2BxCGR8B%2B6qzhzvWeoQ%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20240224T030444Z&X-Amz-SignedHeaders=host&X-Amz-Expires=300&X-Amz-Credential=ASIAQ3PHCVTY7WW6UEFF%2F20240224%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Signature=25cbb843a06f7ecc5c3d018d87862143384821068d3bc7f281b31dfa9be50df8&hash=b24ed7096d4d339c8322e1c39a1a4285ea451b97862e5d4b017556ad24db916b&host=68042c943591013ac2b2430a89b270f6af2c76d8dfd086a07176afe7c76c2c61&pii=S0019995859903626&tid=spdf-98a1ab27-1321-4e11-9970-79758b108884&sid=a3b5e70c9ea0c34002289aa9b26d1ecba9dbgxrqa&type=client&tsoh=d3d3LnNjaWVuY2VkaXJlY3QuY29t&ua=18175f540f53520c025756&rr=85a47ba00bfa2559&cc=br),
> vai perceber que a palavra "regular" usada por ele se refere a uma gramática
> livre de contexto (que ele chama de auto-aninhada) no que atualmente chamamos
> de "forma normal de Chomsky".

# Autômatos finitos e gramáticas regulares

Ben, vamos pegar o grafo de exemplo:

![Um autômato finito determinístico][dfa]

Note que esse grafo determina as leis de formação das palavras.

{% katexmm %}
$$
\begin{array}{lcl}
	S1&\mapsto&0, S2\\
    S1&\mapsto&1, S1\\
    S2&\mapsto&1, S2\\
    S2&\mapsto&0, S1\\
    S2&\mapsto&\epsilon
\end{array}
$$

A partir do autômato, conseguimos criar transformações gramaticais. E fica
mais fácil ainda quando se é uma gramática regular a direita.

Uma transição na gramática nesse caso consiste em sair de um
símbolo não terminal, produzir um terminal e um novo símbolo não
terminal a direita. Então, aqui, $S1 \mapsto 0,S2$ quer dizer que
é possível substituir S1 pelo terminal 0 e colocar o novo não terminal
S2 no final. Aqui podemos criar a palavra exemplo `001010`, que antes
foi reconhecida pelo "grafo":

- `S1`
- `0S2`
- `00S1`
- `001S1`
- `0010S2`
- `00101S2`
- `001010S1`
- `001010`

> Note que usei a transição $\epsilon$ no final.

{% endkatexmm %}

# Expressões regulares

Finalmente, expressão regular é um jeito conciso de se expressar um conjunto
gerado por um processo markoviano; ou seja, por um autômato finito; ou seja
a linguagem definida para uma gramática regular.

Em cima da gramática, temos basicamente escolhas (ir por um caminho
ou pelo outro?) e repetição de uma parte da expressão.

No autômato de exemplo, começamos com `1*`, pois é sempre possível colocar
quantos `1`s quisermos no começo da palavra.

![Um autômato finito determinístico][dfa]

Além disso, podemos sair de S1, ir pra S2, e voltar pra S1. Quantas vezes quisermos.
Para sair de S1 e chegar em S2 precisamos consumir um 0, e esse 0 pode ser
precedido por diversos 1s; então só esse pequeno trecho de S1 para S2 é `1*0`.
Em S2, podemos consumir 1 e continuar em S2, até que finalmente consumimo um 0
e retornamos a S1. E como volta a S1, podemos repetir 1 várias vezes. Então,
uma única ida e volta de S1 para S2 fica `1*01*01*`. Como isso pode ser
repetidamente aplicado, então eu preciso aplicar a repetição em cima dessa
expressão: `(1*01*01*)*`. Juntando com o começo fica: `1*(1*01*01*)*`.

Com cuidado é possível reduzir essa regex para `1*(01*01*)*` sem perder
a capacidade de reconhecer palavras, nem de reconhecer palavras novas.

# Propriedades de linguagens regulares

{% katexmm %}

Como toda linguagem fomal, a linguagem gerada pela gramática é sempre um
subconjunto (não necessariamente próprio) de $\Sigma^{*}$.

Tomemos o autômato finito que estamos usando de exemplo principal:

![Um autômato finito determinístico][dfa]

Ele reconhece palavras no alfabeto $\{0, 1\}$, portanto é um subconjunto
de $\{0, 1\}^{*}$. No caso específico, todas as palavras que contenham
um número par de zeros. Ele é um processo completo pois para todo vértice
você tem uma aresta para cada letra do alfabeto.

Mas nem sempre representa-se assim, de modo completo, o grafo. Com
apenas uma pequena alteração eu posso transformar esse grafo em
um grafo incompleto. Considere que o alfabeto é $\Sigma = \{0, 1, 2\}$,
as palavras reconhecidas tem uma quantidade par de zeros porém não
pode ter nenhum 2.

O grafo é exatamente o mesmo, as produções da gramática são exatamente as
mesmas, a expressão regular é a mesma. Mas agora o grafo está incompleto,
pois os vértices S1 e S2 não tem arestas para a letra 2 do alfabeto.

Como corrigir isso? Bem, adicionando um vértice chamado de "poço". Ou, se
quiser, "perdição". Ou em inglês "damnation". Basicamente esse vértice é
não final, e ele tem arestas de todas as letras voltando pra ele mesmo.
As outras arestas que incidem nele vem de vértices incompletos, que falta
alguma letra do alfabeto que geraria uma palavra inválida para a linguagem
(como produzir um 2 na linguagem que não aceita palavras com 2).

Esse artifício transforma qualquer grafo incompleto em completo.

E sabe uma coisa interessante que podemos observar com a adição desse vértice
poço? Que você pode inverter os vértices finais e não finais que continuará
representando um processo de Markov válido para geração de palavras, mas ele
irá gerar o complemento perante $\Sigma^*$. Isso significa que linguagens
regulares são fechadas sob o complemento.

Outra coisa interessante é que ao permitir transações $\epsilon$, podemos
ligar todos os vértices finais através de transações $\epsilon$ com o vértice
inicial. Isso permite demonstrar que se uma linguagem $A$ era uma linguagem
regular, então $A^{*}$ também será. Então linguagens regulares são
fechadas perante a estrela de Kleene.

Concatenação de palavras é semelhante, mas no lugar de fazer a transação $\epsilon$
voltar para o vértice inicial do grafo atual, se pluga no vértice inicial
da outra linguagem regular. Isso significa que linguagens regulares são fechadas
perante a concatenação.

E sobre união de linguagens regulares? Bem, pegue os grafos $A, B$ que tem vérticies
iniciais $S_A, S_B$, permita transações $\epsilon$, e crie um novo estado inicial $S$.
$S$ então tem uma transação $\epsilon$ para $S_A$ e outra para $S_B$. Com isso,
demonstramos que linguagens regular são fechadas perante a união.

Com essas características poderemos demonstrar que é impossível um processo de Markov,
conforme descrito neste post para gerar linguagens, detectar se um número é composto
ou primo.

{% endkatexmm %}

# Números em unário

Para detectar a primalidade do número, vamos assumir que ele é unário. Um número
representado de modo unário é distinto do modelo posicional, como temos o
indo-arábico. O sistema unário de representação é simplesmente contar quantas
vezes um determinado símbolo (por convenção, "1") aparece. Então, em Ruby,
para transformar um número `n` qualquer, basta fazer:

```ruby
# que n seja um inteiro...
unary_representation = "1" * n
```

E assim temos nosso número em unário. Essa notação é muito útil para (em teoria
da computação) representar números estritamente positivo.

## Um número composto em unário

Imaginemos que temos um número composto qualquer, `c`. Como esse número
é composto, então temos que ele é da forma `f * m`, para um fator `f`
multiplicado por `m`, com `f, m != 1; f, m > 0`.

Como unário é apenas um sistema que concatena o mesmo símbolo repetidamente
até a quantidade adequada, somar dois números é simplesmente concatenar ambos.

Para demonstrar isso, veja esse código em Elixir:

```elixir
def soma(a, []), do: a

def soma(a, [1 | t]), do: soma(a ++ [1], t)

# exemplo de chamada
IO.inspect(soma([1, 1, 1], [1, 1]))
```

Isso é uma base de soma até esgotar a entrada. Sabemos que, qualquer que seja
o número, somado com 0, é ele mesmo. Agora, dos outros números, como podemos fazer?
Bem, removo de um canto e coloco no outro. Até que o RHS esteja vazio (ie, 0).

E indo pela indução, podemos fazer a soma de modo direto:

```elixir
def soma_concat(a, b), do: a ++ b

# exemplo de chamada
IO.inspect(soma_concat([1, 1, 1], [1, 1]))
```

E para fazer multiplicação, então, podemos seguir o mesmo raciocínio...
A multiplicação de `f*m = f + (f*(m-1))`, até chegar em `m == 1: f`:

```elixir
def mult(f, [1]), do: f

def mult(f, [1 | m]), do: f ++ mult(f, m)
```

Ou seja, se eu tenho um número (em notação unária) diferente de 1 e
concatenar ele com ele mesmo diversas vezes, eu tenho um número composto,
pois é um múltiplo daquele número.

# Retrovisores

Sabe uma coisa que existe em alguns motores de expressões regulares?
Retrovisores. Um retrovisor permite pegar um valor anterior e repetir
ele.

{% katexmm %}

Por exemplo: a linguagem que reconheça palavras da forma $W \cdot c \cdot W$,
onde $W \in \{a, b\}^*$, uma palavra dentro do alfabeto $\Sigma_W = \{a, b\}$,
seguido da letra $c$, seguido da exata palavra anterior. Poderíamos fazer isso
caputando em um grupo a palavra $W$ e então fazer um retrovisor apontando para
ela:

```
([ab]*)c\1
```

Um grupo é definido por "aquilo que deu match dentro do parêntese", é numerado
a partir do 1 e o que conta é o parêntese da esquerda. Ou seja, isso daqui iria
pegar apenas um caracter $a$ ou $b$, o que aparecer primeira:

```
(a|b)*c\1
```

e essa segunda expressão não reconheceria $W \cdot c \cdot W$. Para capturar isso
precisaria fazer

```
((a|b)*)c\1
```

e se por acaso quisesse o comportamento de apenas a primeira letra mesmo usando
os dois parênteses:

```
((a|b)*)c\2
```

E, digo mais, podemos colocar quantificadores em cima dos retrovisores. Sabe
o que isso significa? Que isso aqui é válido:

```
([ab]*)c\1+
```

Essa expressão regular reconhece a linguagem $W \cdot c \cdot W+$,
onde $W \in \{a, b\}^*$. Uma palavra em $\{a, b\}$ seguido de $c$
seguido pela palavra inicial repetida pelo menos uma vez.

Bem, vamos relembrar aqui como fazer uma multiplicação em unário?

> se eu tenho um número (em notação unária) diferente de 1 e
> concatenar ele com ele mesmo diversas vezes, eu tenho um [...] um múltiplo
> daquele número

Ou seja, precoso primeiro de um número em unário... `1+`. Preciso garantir que
ele seja maior do que um... então `11+`, o menor valor possível é 2. Daí, se eu
concatenar ele com ele mesmo, tenho o número $\times 2$: `(11+)\1`. Para
pegar todos os múltiplos? `(11+)\1+`. Um pequeno toque para fazer um mínimo
de backtracking e usar uma estrela de Kleene não gulosa? `(11+?)\1+`.

{% endkatexmm %}

Agora, vamos também adicionar nesse balaio o 1 e o 0 que também
não são primos? `1?|(11+?)\1+`. Agora, bora colocar umas âncoras para
evitar matching parcial? `^1?$|^(11+?)\1+$`.

E para usar isso em Ruby:

```ruby
def is_prime(n)
    ("1" * n) !~ /^1?$|^(11+?)\1+$/
end
```

Destrinchando a função:

- dado um número `n` qualquer
- transforma-o e, unário `("1" * n)`
- se não der match com a expressão `!~ /^1?$|^(11+?)\1+$/` diz que é primo
- se der match, diz que não é primo

# Mas será que é regular?

Vamos recobrar aqui um trecho mencionado no começo do post sobre linguagens
regulares:

> reconhecer palavras de linguagens que são representadas por [processos morkovianos]
> _não se precisa de memória_

Hmmm, mas o retrovisor é _justamente_ uma forma de memória. Algo não está bom aqui.

A linha de raciocínio aqui vai ser mostrar que não é possível reconhecer números
primos com linguagem e, portanto, a "expressão regular" que reconhece números compostos
também não é uma linguagem regular. Isso porque expressões regulares são fechadas
no complemento.

O conjunto das linguagens regulares é um subconjunto próprio das linguagens livres
de contexto. Então, se eu provar que não existe uma linguagem livre de contexto para
reconhecer números primos, necessariamente não há linguagem regular para reconhecer
números primos e portanto não tem linguagem regular para reconhecer números compostos.

Uma propriedade interessante de uma linguagem livre de contexto é que ela sempre
obedece ao lema do bombeamento. Apesar de esse lema do bombeamento acabar deixando
passar mais linguagens do que apenas as linguagens livres de contexto, ele é um
bom, prático e eficiente corte. Se a linguagem `L` não segue o lema do bombeamento
para linguagens livres de contexto, então `L` não é uma linguagem livre de contexto.

Para essa demonstração, precisamos recordar do lema do bombeamento para linguagens livres de contexto:

- existe uma palavra `u v w x y` pertencente à `L`
- tal que `|v x| >= 1`
- tal que `|v w x| <= p`
- então `u v^n w x^n y` também pertence a `L`, para todo inteiro `n >= 0`

Se não for possível encontrar essa palavra, então `L` não é livre de contexto.

Tomemos o primo `u + v + w + x + y` como sendo a palavra `u v w x y`.
A palavra bombeada seria da forma `u v^n w x^n y`
Reordenemos o comprimento da palavra bombeada: `n*v + n*x + u + w + y`, e
ainda podemos por `n` em evidência: `n*(v+x) + u + w + y`.

Aqui, temos duas opções:

- o comprimento de `u w y` é nulo, portanto qualquer bombeamento de `n != 1` produz
  um número não primo, seja 0 ou um número múltiplo de `v+x`
- o comprimento de `u w y` é não nulo

Se formos pela primeira hipótese, usando `n = 2`, iremos gerar uma palavra
de comprimento `2*(v+x)`, que é claramente um número composto se `v` e `x` foram
ambos não vazios (ie, `v+x >= 2`). Na hipótese de `v+x = 1`, então temos que
o bombeamento produz todos os números naturais, o que não é a linguagem "todos
os números primos".

Então sobrou a segunda hipótese, que `u + w + y` é não nulo. Vamos supor inicialmente
que `u + w + y = 1`. Ao tomar `n = 0`, `n*(v+x)+ u + w + y = 0*(v+x) + 1 = 1`. E
`1` por definição não é um número primo.

Agora, e para os demais valores? Bem, tomemos `n = u + w + y`. Com isso, temos
que o bombeamento ficaria `n*(v+x)+ u+w+y = (u+w+y)*(v+x) + (u+w+y)*1 = (u+w+y) * (v+x+1)`.
Esse número é um múltiplo de `u+w+y`. Como `v+x >= 1`, temos que esse número é
um múltiplo não trivial de `u+w+y`, provando que esse número gerado é
composto e, portanto, não deveria estar na linguagem de todos os números primos
em unário.

Com isso, demonstramos que não há linguagem livre de contexto para detectar
números primos. Por conta disso, não há linguagem regular para detectar números
primos. Por conta disso, não há linguagem regular para detectar números compostos.
Por conta disso, `^(11+?)\1+$` não é regular.


[dfa]: {{ page.base-assets | append: "dfa.svg" | relative_url }}
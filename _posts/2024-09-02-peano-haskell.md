---
layout: post
title: "Aritmética de Peano em Haskell"
author: "Jefferson Quesado"
tags: haskell matemática peano tail-call recursão
base-assets: "/assets/peano-haskell/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---
Vamos mergulhar um pouquinho em Haskell? A ideia é fazer
um pouco de aritmética de Peano. Estou usando o site
[https://www.jdoodle.com/execute-haskell-online](https://www.jdoodle.com/execute-haskell-online)
para testar o código Haskell.

# Aritmética de Peano

Peano criou um conjunto de axiomas para construir os números naturais. Entre diversos
formalismos, duas coisas se destacam para a construção do sistema de números:

1. existe um elemento que pertence aos naturais
2. o sucessor desse elemento é um número natural

O conjunto de axiomas de Peano vai garantir questões como igualdade, que não seja possível
possível entrar em laço e propriedade da função de sucessão. Você pode encontrar mais
sobre isso [nessa página da Wikipedia](https://en.wikipedia.org/wiki/Peano_axioms).

# Definindo tipo base

Por uma questão de convenção, comecemos com o elemento 0. Os números naturais são
zero ou algo que venha depois de um número natural. Então, podemos definir nosso
tipo de dados:

```haskell
data Nat = Zero | Suc Nat
```

Ok, já temos um começo. Se eu quiser representar o número 1, eu só preciso
`Suc Zero`. Se eu quiser o número 2, só fazer `Suc Suc Zero`, certo? Bem, não
tão rápido. Nesse caso vou precisar englobar o natural anterior entra parênteses,
já que o `Suc` é definido para um natural, e o próximo token que ele recebe é
`Suc` que não é um natural por si só. Então eu preciso colocar entre parênteses:
`Suc (Suc Zero)`. Agora eu atendo a questão, já que `Zero` é natural e `Suc Nat`
também é. Aos pouquinhos, é como se fosse algo assim (muito _freestyle_, apenas
o jeito como eu reconheci a questão, não leve como sendo formalidade):

```haskell
Suc (Suc Zero) -- `Zero` é `Nat`
Suc (Suc Nat) -- `Suc Nat` é `Nat`
Suc Nat -- `Suc Nat` é `Nat`
Nat
```

# Depurando

Perfeito. Entendimento concluído. Agora, para imprimir naturais? Para eu
conseguir visualmente olhar se estou fazendo a coisa certa? Bem,
temos a função `print`. Vamos testar:

```haskell
print (Suc (Suc Zero))
```

```none
jdoodle.hs:62:1: error:
    • No instance for (Show Nat) arising from a use of ‘print’
    • In a stmt of a 'do' block: print (Suc (Suc Zero))
      In the expression: do print (Suc (Suc Zero))
      In an equation for ‘main’: main = do print (Suc (Suc Zero))
   |
62 | print (Suc (Suc Zero))
   | ^^^^^^^^^^^^^^^^^^^^^^
```

Hmmm, não deu certo. está falando aqui que não tem instância para `Show Nat`.
Pesquisei um pouco e no StackOverflow achei uma resposta que indicava o caminho:
preciso indicar quem é `Show Nat`, mais ou menos assim:

```haskell
instance Show Nat where
    show = someFancyFunction
````

O padrão é nomear a função que ele chamará com `show<Type>`, então
no caso aqui seria chamar de `showNat`. Bem, vamos precisar que a função
seja `Nat -> String`. Vamos primeiro ensinar como lidar com o `Zero`?

```haskell
showNat :: Nat -> String
showNat Zero = "Zero"

instance Show Nat where
    show = showNat

print Zero
```

```none
[1 of 1] Compiling Main             ( jdoodle.hs, jdoodle.o )
Linking jdoodle ...
Zero
```

Perfeito, funcionou! Vamos expandir pro sucessor do zero:

```haskell
showNat :: Nat -> String
showNat Zero = "Zero"

instance Show Nat where
    show = showNat

print (Suc Zero)
```

```none
[1 of 1] Compiling Main             ( jdoodle.hs, jdoodle.o )
Linking jdoodle ...

jdoodle: jdoodle.hs:6:1-21: Non-exhaustive patterns in function showNat
```

Ok, justo. Ele não conseguiu achar algo digno. Então, vamos ensinar ele como lidar
com o sucessor de um número. Usemos aqui o operador `++`, que faz concatenação entre
strings:

```haskell
showNat :: Nat -> String
showNat Zero = "Zero"
showNat Suc v = "Suc " ++ (showNat v)

instance Show Nat where
    show = showNat

print (Suc Zero)
```

```none
[1 of 1] Compiling Main             ( jdoodle.hs, jdoodle.o )
Linking jdoodle ...
Suc Zero
```

Perfeitinho. Vamos imprimir agora o sucessor dele:

```haskell
showNat :: Nat -> String
showNat Zero = "Zero"
showNat Suc v = "Suc " ++ (showNat v)

instance Show Nat where
    show = showNat

print (Suc (Suc Zero))
```

```none
[1 of 1] Compiling Main             ( jdoodle.hs, jdoodle.o )
Linking jdoodle ...
Suc Suc Zero
```

Foi o suficiente na minha opinião. Mas... a função `show` deveria permitir
que eu simplesmente colasse a string de volta no código Haskell, seria muito
conveniente isso para mim. Mas ela não permite do jeito que está. Vamos por
uns parênteses ao redor da representação interna?

```haskell
showNat :: Nat -> String
showNat Zero = "Zero"
showNat Suc v = "Suc (" ++ (showNat v) ++ ")"

instance Show Nat where
    show = showNat

print (Suc (Suc Zero))
```

```none
[1 of 1] Compiling Main             ( jdoodle.hs, jdoodle.o )
Linking jdoodle ...
Suc (Suc (Zero))
```

Hmmmm, funciona. Mas eu não achei adequado envelopar o `Zero` em
`(Zero)`. Vamos criar um caso especial para o sucessor do zero:

```haskell
showNat :: Nat -> String
showNat Zero = "Zero"
showNat Suc Zero = "Suc " ++ (showNat Zero)
showNat Suc v = "Suc (" ++ (showNat v) ++ ")"

instance Show Nat where
    show = showNat

print (Suc (Suc Zero))
```

```none
[1 of 1] Compiling Main             ( jdoodle.hs, jdoodle.o )
Linking jdoodle ...
Suc (Suc Zero)
```

Minha primeira implementação eu fiz em cima de `show` na verdade, e funcionava:

```haskell
showNat :: Nat -> String
showNat Zero = "Zero"
showNat Suc v = "Suc " ++ (show v)

instance Show Nat where
    show = showNat
```

Mas particularmente achei mais elegante depender apenas de `showNat` em recursão
direta, do que delegar para `show` que depois eu iria fazer o bind de volta para
`showNat`, ocasionando uma recursão indireta.

# Função de soma

Bem, pra somar a moda aritmética de Peano, primeiro eu pensei nos casos de soma
com zero:

```haskell
addNat :: Nat -> Nat -> Nat

addNat Zero X = X
addNat X Zero = X
```

Ok, e além disso? Bem, posso tirar de um lado e passar pro outro, até esgotar um lado:

```haskell
addNat x (Suc y) = addNat (Suc x) y
```

Com o tempo, o lado direito vai sendo secado até não sobrar nada. A cada passo, se incrementa
algo no lado esquerdo. Como o lado direito vai sempre diminuindo, e ele é composto de
algum sucessor de zero, ele eventualmente chegará no valor zero. Portanto, essa recursão
vai chegar ao fim, e o valor irá ficar no operador esquerdo (caso `addNat X Zero = X`).

## Função de cauda

A recursão aqui consiste em chamar constantemente a função `addNat`, com valores distintos,
até chegar num valor final. Note que outra possível maneira de fazer isso seria diminuindo
o problema e chamando o `Suc` de uma soma menor:

```haskell
addNat x (Suc y) = Suc (addNat x y)
```

Esse é o tipo caso de recursão estrutural, em que o problema fica menor a cada passo.
Porém, nesse caso aqui, eu preciso manter uma espécie de estado anterior, pois eu só
posso aplicar o `Suc` na saída de `addNat`. Em
[Trampolim, exemplo em Java]({% post_url 2023-10-02-trampoline %}) foi feito um exemplo
de chamada de cauda para Fibonacci. Também foi feita uma versão dessa chamada de cauda
para a função `sum` para possibilitar o trampolim.

Podemos descrever as duas versões de `sum` descritas no artigo sobre trampolim:

```haskell
sum_classico :: Int -> Int
sum_classico 0 = 0
sum_classico n = n + (sum_classico (n-1))


sum_tailcall :: Int -> Int -> Int
sum_tailcall 0 acc = acc
sum_tailcall n acc = sum_tailcall (n-1) (acc+n)

sum_tailcall_bootstrap :: Int -> Int
sum_tailcall_bootstrap n = sum_tailcall n 0
```

Qual a diferença entre elas? Bem, que no caso de `sum_classico` precisa manter
implicitamente o valor até a resolução da função, enquanto que em `sum_tailcall`
o valor é passado adiante. Em linguagens que permitem otimização de chamada de
cauda, a chamada de cauda do jeito que foi feito em `sum_tailcall` (ie, que não
precisa manter implicitamente o estado) é potencialmente muito mais eficiente.

Veja esse post do Leandro Proença que ele fala mais sobre chamada de cauda
e otimização de chamada de cauda (tail call optimization, TCO):
[Entendendo fundamentos de recursão](https://dev.to/leandronsp/entendendo-fundamentos-de-recursao-2ap4).

## Aliases de tipo

Conforme eu ia avançando no código comecei a ficar bem chateado de ficar
repetindo sempre a declaração do tipo da função: `Nat -> Nat -> Nat`. Então
decidi que deveria ter menos trabalho. Criei então um tipo com a intenção
pura e simples de diminuir meu trabalho:

```haskell
type BinNat = Nat -> Nat -> Nat

addNat :: BinNat

addNat Zero X = X
addNat X Zero = X
```

# Multiplicação

Para a multiplicação, resolvi adotar uma estratégia menos elaborada.
Como `x*(n + 1) = x + x*n`, implementei isso literalmente. Aqui eu
não deixei a chamada de cauda adequada para qualquer eventual otimização:

```haskell
multNat :: BinNat

multNat _ Zero = Zero
multNat Zero _ = Zero
multNat _ Zero = Zero
multNat (Suc x) y = addNat y (multNat x y)
```

Ah, nota algo aqui bem legal: o argumento com `_` significa algo que
será prontamente ignorado. Não importa com o que estou multiplicando,
ao multiplicar com zero o valor é zero.

Se eu quisesse ir para um lado voltado para otimização da chamada de cauda:

```haskell
multNat :: BinNat

multNat x y = bootstrap_multNat x y Zero

bootstrap_multNat :: Nat -> Nat -> Nat -> Nat
bootstrap_multNat Zero _ acc = acc
bootstrap_multNat _ Zero acc = acc
bootstrap_multNat (Suc x) y acc = bootstrap_multNat x y (addNat y acc)
```

# Módulo e divisão

Vamos calcular o módulo de um número natural pelo outro?
O jeito mais fácil de fazer `n % d` é quando `n < d`, porque
isso quer dizer que o módulo é `n`. Então, vamos tentar reconhecer
se um número é maior do que o outro?

## Menor que

Temos aqui uma função que vai pegar dois naturais e retornar um
booleano:

```haskell
ltNat :: Nat -> Nat -> Bool
```

Começando com o caso base, dos dois argumentos como zero. Temos que
a avaliação vai ser falsa, pois zero não é menor do que zero:

```haskell
ltNat Zero Zero = False
```

Joia. E se eu encontrar zero do lado esquerdo e algo maior do que
zero do lado direito? Aí vai ser verdade!

```haskell
ltNat Zero (Suc _) = True
```

Mas o contrário é falso:

```haskell
ltNat (Suc _) Zero = False
```

Mas se os dois forem maiores do que zero? Bem, podemos tirar um de cada
e verificar de novo, recursivamente:

```haskell
ltNat (Suc x) (Suc y) = ltNat x y
```

## Condições

Agora que temos a condicional, como poderíamos calcular o módulo?

Por hora vamos ignorar a saída no caso que `n >= d`, vamos fixar aqui
para questão de teste que esse caso vai retornar um placeholder, zero.
Para essas situações, podemos usar um `if`:

```haskell
modNat :: BinNat
modNat n d = if (ltNat n d) then n else Zero
```

Ótimo. Mas agora precisamos resolver de fato o caso do `else`. Como estamos
lidando com o módulo, temos que `n % d == (n-d) % d`, portanto vamos diminuir
o problema e calcular recursivamente:

```haskell
modNat :: BinNat
modNat n d = if (ltNat n d) then n else modNat (diffNat n d) d
```

Para uma questão de evitar problemas de cálculos, vou usar como convenção
que o resto da divisão por zero é zero, só para não precisar mexer no tipo de
`modNat`:

```haskell
modNat :: BinNat
modNat _ Zero = Zero
modNat n d = if (ltNat n d) then n else modNat (diffNat n d) d
```

Agora precisamos calcular `diffNat`. Como naturais não tem números negativos,
vou simplesmente usar a liberdade de definir que, caso eu tente remover mais
elementos do que eu tenho, eu fico com zero:

```haskell
diffNat :: BinNat
diffNat Zero _ = Zero
```

Como a ideia é sair removendo até chegar no final, ao esgotar o quanto
de coisa se tem pra remover, também cheguei ao fim:

```haskell
diffNat x Zero = x
```

E nos outros casos? Bem, tal qual fizemos com o "menor que", vamos retirar
um ponto de cada um e continuar recursivamente. Afinal, `x - y == (x-1) - (y-1)`:

```haskell
diffNat (Suc x) (Suc y) = diffNat x y
```

A função como um todo:

```haskell
diffNat :: BinNat
diffNat Zero _ = Zero
diffNat x Zero = x
diffNat (Suc x) (Suc y) = diffNat x y

modNat :: BinNat
modNat n d = if (ltNat n d) then n else modNat (diffNat n d) d
```

Para achar o resultado da divisão, podemos seguir um pensamento semelhante. Ao chegar
na situação que `n < d`, temos que o resultado da divisão é 0. Caso `n >= d`, temos
que o resultado da divisão inteira vai ser um além do que `(n-d) // d`, ou seja,
`n//d == 1 + (n-d)//d`:

```haskell
divNat :: BinNat
divNat n d = if (ltNat n d) then Zero else Suc(divNat (diffNat n d) d)
```

De modo semelhante a o que foi com `modNat`, vou usar como convenção o retorno
zero para divisão por zero:

```haskell
divNat :: BinNat
divNat _ Zero = Zero
divNat n d = if (ltNat n d) then Zero else Suc(divNat (diffNat n d) d)
```

## Records

Se por acaso eu precisar do resultado do módulo e da divisão inteira entre
dois números, como proceder? Bem, já temos o suficiente para isso com as
coisas acima, mas isso não é eficiente. Não deveria ser necessário fazer essa
conta duas vezes.

Temos aqui que sempre damos um passo para baixo, e no caso da divisão pegamos
o resultado desse passo e somamos um. Seria interessante se a linguagem desse
um tipo que permitisse extrair essas informações... E adivinha? Tem sim.

Podemos pegar um `record`, uma espécie de tupla nomeada. Você declara o formato
como quer o seu tipo e isso já vai te dar funções especiais que trazem as
informações de cada campo. Por exemplo, queremos o resultado da divisão e do
módulo, vou chamar esse tipo de dado de `DivMod`:

```haskell
data DivMod = DivMod{ divN :: Nat, modN :: Nat}

let teste = DivMod{ divN = Zero, modN = (Suc Zero)}
print (divN teste) -- imprime Zero
print (modN teste) -- imprime Suc Zero
```

Para calcular o `divModNat`, eu preciso pegar o `step` e retornar o seguinte:

```haskell
-- assuma `step :: DivMod`
DivMod{ divN=(Suc (divN step)), modN=(modN step) }
```

Isso é verdade onde o valor de `step` é definido como `step = divModNat (diffNat n d) d`.
E o Haskell fornece `where` para isso:

```haskell
divModNat :: Nat -> Nat -> DivMod
divModNat n d = if (ltNat n d) then DivMod{ divN=Zero, modN=n} else DivMod{ divN=(Suc (divN step)), modN=(modN step) }
                where step = divModNat (diffNat n d) d
```

Adicionando a salva guarda para a divisão por zero:

```haskell
divModNat :: Nat -> Nat -> DivMod
divModNat _ Zero = DivModNat{ divN=Zero, modN=Zero }
divModNat n d = if (ltNat n d) then DivMod{ divN=Zero, modN=n } else DivMod{ divN=(Suc (divN step)), modN=(modN step) }
                where step = divModNat (diffNat n d) d
```

# Ackermann Peter

Vamos fazer alguma computação pesada? Vamos computar o valor
da função de Ackermann Peter?

Essa função tem dois casos base: uma quando o `m` é zero e outra
quando o `n` é zero.

```haskell
ackPeter :: BinNat
ackPeter Zero n = Suc n
ackPeter (Suc m) Zero = ackPeter m (Suc Zero)
ackPeter (Suc m) (Suc n) = ackPeter m (ackPeter (Suc m) n)
```

# Fontes

Alguns links que serviram de base para o estudo deste post:

- [https://haskell.pesquisa.ufabc.edu.br/](https://haskell.pesquisa.ufabc.edu.br/)
- [https://wiki.haskell.org/](https://wiki.haskell.org/)
- [https://pt.m.wikibooks.org/wiki/Haskell/](https://pt.m.wikibooks.org/wiki/Haskell/)
- [https://ghc.gitlab.haskell.org/ghc/doc/users_guide/](https://ghc.gitlab.haskell.org/ghc/doc/users_guide/)
- [https://mmhaskell.com/haskell-data/basics](https://mmhaskell.com/haskell-data/basics)

Muitas outras fontes foram usadas, mas esqueci de catalogá-las antes
de escrever este post, então as perdi.

Você vai encontrar mais também em alguns gists que eu fix sobre Haskell:

- [https://gist.github.com/jeffque/04fcd2d19030d8461edd10f0c3a35543](https://gist.github.com/jeffque/04fcd2d19030d8461edd10f0c3a35543)
- [https://gist.github.com/jeffque/8091d1b0cac4ca85f64e87eecf805ee5](https://gist.github.com/jeffque/8091d1b0cac4ca85f64e87eecf805ee5)

Note que esses gists foram feitos antes de eu escrever este post,
então diversas coisas que descobri depois estão de fora.

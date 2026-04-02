---
layout: post
title: "Contando pares no intervalo [a,b]"
author: "Jefferson Quesado"
tags: c tco matemática recursão
base-assets: "/assets/conta-pares/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

> Baseado [nesta minha publicação](https://pt.stackoverflow.com/a/286793/64969)
> no Stack Overflow em Português

Preciso contar quantos números pares existem em um intervalo fechado de
números. Missão parece bem tranquila, não é?

```c
int conta_pares(int a, int b) {
    int i;
    int acc = 0;
    for (i = a; i <= b; i++) {
        if (i % 2 == 0) {
            acc++;
        }
    }

    return acc;
}
```

Mas isso pode ser melhorado, não é? Para que se sujeitar a iterar na coleção
inteira? Bem, podemos contar quantos pares tem no intervalo aberto `(0, a)`,
quanto tem no intervalo fechado `(0, b]` e então remover os pares do intervalo
`(0, a)`. A diferença de conjuntos vai ser `[a, b]`, conforme o esperado.

No caso, para contar a quantidade de números pares entre `(0, x]`, basicamente
é a metade de `x`, arredondado para baixo. Por exemplo, até 10? Temos 5 pares:
2, 4, 6, 8, 10. Até 9? Só quatro pares: 2, 4, 6, 8. Então, para computar a
quantidade de pares no intervalo `(0, b]`, já temos a fórmula.

Mas e para `(0, a)`? Agora o intervalo é aberto... Bem, como é aberto nos
números inteiro, podemos trocar por um fechado no inteiro logo menor:
`(0, a-1]`. Isso só vale porque estamos trabalhando com números inteiros, se
fosse nos reais ou mesmo nos racionais isso já não valeria. Então, para achar
os números entre `[a, b]`:

```c
int conta_pares(int a, int b) {
    return b/2 - (a-1)/2;
}
```

Por via das dúvidas, podemos nos resguardar porque a entrada vai ser de um
usuário:

```c
int conta_pares(int a, int b) {
    if (a > b) {
        return 0;
    }
    return b/2 - (a-1)/2;
}
```

Muito bem, agora vamos ver a questão de novo...

só aceita recursivo...

# Construção recursiva básica

Bem, voltamos aqui ao clássico problema de como expressar de modo recursivo uma
solução. Então, que tal fazer assim:

- começamos no intervalo `[a, b]`
- resolvo para `[a+1, b]`
- se `a` for par, adiciono `1` ao resultado do problema menor

Mas... qual seria o caso base? Bem, com um intervalo inválido! Quando `a > b`.
E nesse caso, qual seria a solução? Seria 0 mesmo, não tem número algum nesse
intervalo, muito menos pares:

```c
int conta_pares(int a, int b) {
    if (a > b) {
        return 0;
    }
    int problema_menor = conta_pares(a + 1, b);
    return problema_menor + (a % 2 == 0? 1: 0);
}
```

De modo mais conciso?

```c
int conta_pares(int a, int b) {
    if (a > b) {
        return 0;
    }

    return conta_pares(a + 1, b) + (a % 2 == 0? 1: 0);
}
```

Isso resolve o problema da recursão. Mas, vamos botar o chapéu da otimização da
função de cauda? Tal qual em
[Otimização de função de cauda em uma toy function]({% post_url 2025/2025-08-07-c-tail-call-opt %}).

A estratégia que vou passar é passar adiante a solução acumulada até o momento.
Como estamos em C, eu também não quero expor minhas funções para o mundo
externo, quero que elas fiquem retidas na unidade de compilação: que façamos
elas serem `static`! O `static` na função garante que ela não será usada para
fazer linking com outros arquivos. É como se a função só existisse dentro do
arquivo e fosse invisível acessar de fora:

```c
static int _conta_pares(int a, int b, int acc) {
    // placeholder
    return 0;
}

int conta_pares(int a, int b) {
    return _conta_pares(a, b, 0);
}
```

Ok, vamos pensar aqui. O passo recursivo vai continuar sendo chamar apra o
número seguinte da parte inferior do intervalo: `[a,b]` tem como subproblema o
intervalo `[a+1, b]`. O caso base também seria o mesmo, retorno o que foi
computado até o momento:

```c
static int _conta_pares(int a, int b, int acc) {
    if (a > b) {
        return acc;
    }
    return _conta_pares(a+1, b, 0 /* placeholder esse 0 aqui! */);
}

int conta_pares(int a, int b) {
    return _conta_pares(a, b, 0);
}
```

Muito bem... agora, o que eu venho acumulando? A quantidade de pares! E essa
grandeza nunca diminui. Portanto, vai ser `acc` com alguma coisa. E que coisa
seria essa? Se `a` for par:

```c
static int _conta_pares(int a, int b, int acc) {
    if (a > b) {
        return acc;
    }
    return _conta_pares(a+1, b, acc + (a % 2 == 0? 1: 0));
}

int conta_pares(int a, int b) {
    return _conta_pares(a, b, 0);
}
```

# Funções de alta ordem!

Hmmm, ainda tem algo me incomodando. Eu posso transformar isso não em um
conjunto de ifs, deve ter um jeito de contar automaticamente na estrutura! E,
bem, temos sim! Basicamente vamos contar quantas vezes passamos pelo estado
"`a` é par" até esgotar o limite inferior do intervalo. E esse grafo só tem
dois estados: o anterior descrito e o estado "`a` é ímpar", que não serve de
nada.

Modelando cada estado como se fosse uma função, temos um problema: temos duas
funções mutuamente recursivas. E como que podemos permitir isso em C? Usando
cálculo &lambda; e passando as funções como argumentos? Bem, até que é uma
solução um tanto quanto... rebuscada... mas não precisamos disso. Mas não
precisar não quer dizer não ter!

Então vamos lá! Vamos resolver do jeito difícil, depois vamos resolver do jeito
mais adequado!

Nesse caso, é bom definir um tipo de função. Normalmente, para definir um tipo
novo com nome simples usamos `typedef`. Para definir um ponto, por exemplo,
podemos escrever assim:

```c
typedef struct { int x; int y; } Ponto;
```

Aqui eu estou criando uma `struct` anônima que tem os campos `x` e `y`, e ambos
esses campos são do tipo `int`. Então, após criar esse `struct` anônima eu
atribuo a ela o nome `Ponto`. Para iniciar um valor, podemos fazer a
inicialização inline:

```c
Ponto p = {
    .x = 2,
    .y = 1
};
```

Que também podemos escrever de modo mais conciso:

```c
Ponto p = { .x = 1, .y = 2 };
```

Podemos fazer reatribuição completa do valor também, mas para isso precisamos
apresentar à `struct` que estamos criando o tipo dela (o compilador não infere
o tipo):

```c
Ponto p = { .x = 1, .y = 2 };
p = (Ponto) { .x = 5, .y = 0 };
```

E tem uma coisa bem legal também: podemos declarar campos dessa `struct` como
`const`! E isso impede algumas operações ilegais:

```c
typedef struct { const int x; const int y; } Ponto;

Ponto p = { .x = 1, .y = 2 };

p.x = 5;
// error: cannot assign to non-static data member 'x' with const-qualified type 'const int'

p = (Ponto) { .x = 5, .y = 4};
// error: cannot assign to variable 'p' with const-qualified data member 'x'
```

> Ah, sim, tal qual Java assumimos que um campo `final` não pode ter seu valor
> alterado em tempo de execução, aqui podemos ter esse pressuposto mas com um
> cuidado a mais: é mais fácil em C fazer acesso ilegal a esses campos do que
> em Java fazer deep-reflection e mudar o campo para não ser mais `final`. Isso
> é um salva-guarda entre você e o compilador, não quer dizer que quem receba
> esses dados vai respeitar o acesso de memória.
>
> Faz parte da API saudável essa declaração de tipos.

Mas para o caso de tipos de função, a coisa é um pouco mais diferente. Ao
declarar o tipo de função, o nome do tipo vai entre parênteses, assim:

```c
typedef int (*Pega_dois_int)(int a, int b);

int add(int a, int b) {
    return a + b;
}

int mult(int a, int b) {
    return a * b;
}

Pega_dois_int op = (choice == '+'? add: mult);

int v = op(first, second);
printf("%d\n", v);
```

O tipo `Pega_dois_int` foi declarado como sendo um ponteiro de função que
retorna um inteir `int (*)(       )`. E também coloquei que ele recebe dois
argumentos inteiros: `int (*)(int, int)`. O nome do tipo da função fica ali,
dentro do parênteses que segura o indicador de ponteiro `*`.

E, bem, aqui eu não consigo me dar ao luxo de passar um tipo parcialmente
conhecido como seria comum fazer com listas ligadas:

```c
typedef struct lista {
    int value;
    struct lista *next;
} Lista;
```

Aqui estou construindo primeiro a `struct` nomeada `struct lista`. Essa
estrutura ainda não está completamente definida, então não posso listar ela
diretamente dentro de si mesma. Mas tenho indicações suficientes para saber que
estou lidando com essa struct! Se eu pudesse mencionar ela sem precisar saber
de mais detalhes dela... como se fosse só um ponteiro... daria certo.

E é assim que podemos fazer o `struct lista *next` dentro de `struct lista`.
Note que aqui a estrutura é nomeada, não mais anônima como foi no caso do
ponto. E também que aqui sabemos que existe o tipo `struct lista`, mas ainda
não fomos apresentados a `Lista`, portanto tentar fazer o seguinte é ilegal:

```c
typedef struct lista {
    int value;
    Lista *next;
    // error: unknown type name 'Lista'
} Lista;
```

Como eu não posso mencionar ao elemento em si, não posso colocar o tipo de
função que declarei como argumento de si mesmo. "Ah, mas é só um ponteiro!"
Então, vai convencer o compilador! Melhor deixar quieto... porque existe um
contorno para isso!

Apesar de não poder dizer qual o tipo perfeito, podemos dizer que o argumento é
um ponteiro de função que retorna um inteiro: `int (*)()`. Os argumentos? Não
decidido, então eu posso brincar.

> Note que, em C, se eu quiser explicitar que a função não recebe argumento de
> jeito nenhum, preciso declarar ela com `(void)`. No caso acima, algo como
> `int (*)(void)`.

Então eu consigo fazer isso aqui:

```c
typedef int (*Rec_int)(int (*r)(), int a, int b, int acc);

int _soma_rec(Rec_int r, int a, int b, int acc) {
    if (a > b) {
        return acc;
    }
    return r(r, a + 1, b, acc + (a % 2 == 0? 1: 0));
}
```

Muito bem, agora eu posso fazer a troca de estados! Vamos precisar de um tipo
de função que recebe a função do estado par, a do estado ímpar, o começo do
intervalo, o final do intervalo e o acumulado até então, e que retorne um
inteiro:

```c
typedef int (*Sum_f)(int (*parstate)(), int (*imparstate)(), int a, int b, int acc);
```

Ok, agora a função de entrada: se `a` for par, chamo logo a função do estado
par; caso contrário, a função do estado ímpar:

```c
int conta_pares(int a, int b) {
    Sum_f parst = _conta_pares_parstate;
    Sum_f imparst = _conta_pares_imparstate;

    Sum_f f_ini = a % 2 == 0? parst: imparst;
    return f_ini(parst, imparst, a, b, 0);
}
```

A função do estado ímpar só passa pra frente as coisas para o estado par,
mudando apenas o `a` (como se ele tivesse feito o `+1` mentalmente):

```c
static int _conta_pares_imparstate(Sum_f parstate, Sum_f imparstate, int a, int b, int acc) {
    if (a > b) {
        return acc;
    }
    return parstate(parstate, imparstate, a+1, b, acc);
}
```

E, bem, sobre o estado par, basicamente chama o próximo estado com o `acc`
alterado:

```c
static int _conta_pares_parstate(Sum_f parstate, Sum_f imparstate, int a, int b, int acc) {
    if (a > b) {
        return acc;
    }
    return imparstate(parstate, imparstate, a+1, b, acc+1);
}
```

# Recursão indireta

Ok, eu achei que ficou legal. Eu estou satisfeito com o meu serviço. Mas,
falando sério, quem que vai codificar pensando em cálculo &lambda;? Além de,
bem, eu mesmo?

Vamos agora cogitar que teremos a chamada recursivamente, precisamos na função
de entrada definir se vamos entrar em comportamento de que começamos a subir
par ou ímpar:

```c
int conta_pares(int a, int b) {
    int (*f_ini)(int a, int b, int acc) = a % 2 == 0? _conta_pares_parstate: _conta_pares_imparstate;
    return f_ini(a, b, 0);
}
```

O mais comum seria usar uma estratégia que já usamos anteriormente aqui nesse
post: o poder de C que nos permite mencionar nominalmente coisas parcialmente
conhecidas, por mais que não se sabe todos os detalhes.

Para isso, diferente do `struct lista`, precisamos fazer um "forward
declaration". O que quer dizer meio que "spoiler" do que vem a frente, sem de
fato destrinchar o que vem na frente.

```c
static int _conta_pares_imparstate(int a, int b, int acc);
```

Aqui eu posso mencionar chamar essa função, por mais que o compilador ainda não
saiba quem é ela. Então eu posso definir `_conta_pares_parstate`:

```c
static int _conta_pares_imparstate(int a, int b, int acc);

static int _conta_pares_parstate(int a, int b, int acc) {
    if (a > b) {
        return acc;
    }
    return _conta_pares_imparstate(a + 1, b, acc + 1);
}
```

Para a contagem de ímpares... bem, o `_conta_pares_parstate` já foi definido,
não preciso fazer forward declaration:

```c
static int _conta_pares_imparstate(int a, int b, int acc);

static int _conta_pares_parstate(int a, int b, int acc) {
    if (a > b) {
        return acc;
    }
    return _conta_pares_imparstate(a + 1, b, acc + 1);
}

static int _conta_pares_imparstate(int a, int b, int acc) {
    if (a > b) {
        return acc;
    }
    return _conta_pares_parstate(a + 1, b, acc);
}
```

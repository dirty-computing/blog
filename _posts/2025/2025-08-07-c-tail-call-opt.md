---
layout: post
title: "Otimização de função de cauda em uma toy function"
author: "Jefferson Quesado"
tags: tco c
base-assets: "/assets/c-tail-call-opt/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Vi um post na APDA (Associaçãp de Programadores Depressivos Anônimos,
comunidade do Facebook) sobre um rapaz que estava escrevendo uma função de
multiplicação em C sem usar primitivos de multiplicação. A resposta dele foi
algo assim:

```c
int mult(int a, int b) {
	if (b == 0) return 0;
	return a + mult(a, b - 1);
}
```

Até aí tudo tranquilo. Mas as coisas começaram a dar pane para ele com entradas
tipo 1000 (mil) e 300000000 (300 milhões). Começou a disparar segmentation
fault.

Assim sendo, resolvi deixar com que o programa dele funcionasse sem quebrar
mesmo com grandes números.

# E esse segmento?

Como se pode ver, não está acontecendo nenhum acesso explícito a região de
memória. O caso clássico de falha de segmentação é quando você acessa uma
posição de ponteiro inválida. Por exemplo, pegue esse `segfault.c`:

```c
#include <stdio.h>

int main() {
        int nums[100];

        printf("numero no alem: %d\n", nums[100000]);
        return 0;
}
```

Pedi pra compilar, compilador (CLang) obviamente identificou algo estranho:

```none
$ make segfault                   
cc     segfault.c   -o segfault
segfault.c:6:33: warning: array index 100000 is past the end of the array (that has type 'int[100]') [-Warray-bounds]
    6 |         printf("numero no alem: %d\n", nums[100000]);
      |                                        ^    ~~~~~~
segfault.c:4:2: note: array 'nums' declared here
    4 |         int nums[100];
      |         ^
1 warning generated.
```

MAS é um código C válido, me alertou porque é amigo mas me deixou passar. Ao
executar:

```none
$ ./segfault 
[1]    61857 segmentation fault  ./segfault
```

Mas o que é uma falha de segmentação? Pra falar disso, preciso falar de modelo
de memória, de alocação e várias coisas. Vou dar uma pincelada por cima com
muita simplificação, até porque eu preciso admitir não ser alguém com
especialidade nessa área. Vou usar apenas o meu conhecimento superficial.

Na memória, a unidade mais baixa que se usa não é byte. É página. Quando você
pede para a unidade gerenciadora de memória
([MMU](https://en.wikipedia.org/wiki/Memory_management_unit)) uma região da
memória ela retorna uma página. Mas páginas não são segmentos, o que uma coisa
tem a ver com a outra?

Porque historicamente a memória de um programa era dividida em segmentos. Os
mais tradicionais são (não limitados a apenas esses):

- segmento de dados. 
  onde havia apenas dados, sem código executável
- segmento de código  
  onde mora o código executável da aplicação
- segmento de stack  
  onde ocorre o trabalho que não envolve memória dinâmica, onde normalmente
  moram as variáveis da função

E esses segmentos são divididos em páginas. Então um segmento é um conjunto de
páginas. O que aconteceu no exemplo do `segfault.c`?

Eu criei uma variável de stack chamada `nums`. Ela tinha um tamanho limitado,
de 400 bytes na minha máquina local. Como sei desse valor exato? Bem, perguntei
pro meu compilador usando o operador `sizeof`:

```c
int nums[100];
printf("sizeof nums %lu\n", sizeof(nums)); // sizeof nums 400
```

Isso pode mudar de acordo com o compilador, arquitetura etc. No meu caso, ele
tá usando `int` como tendo 4 bytes (ou 32 bits), o que dá um range de
aproximadamente -2 bilhões até +2 bilhões (se fosse `unsigned int` seria de 0 a
+4 bilhões, aproximadamente).

E sim, eu disse "**operador** `sizeof`". Isso porque `sizeof` não é uma função,
apesar de ser chamado com parênteses pós fixo. Ele é um operador que calcula o
tamanho da variável, do tipo ou do valor passado. Ele é um operador que é
resolvido a nível de compilação, inclusive. Eu pedi para o Compiler Explorer
(aka godbolt) [godbolt.org](https://godbolt.org/) gerar o código para mim dessa
variação do `segfault.c`:

```c
#include <stdio.h>

int main() {
        int nums[100];
        printf("sizeof nums %lu\n", sizeof(nums));

        //printf("numero no alem: %d\n", nums[100000]);
        return 0;
}
```

E ele absolutamente já coloca o 400 para ser impresso:

```asm
main:
        push    {r11, lr}
        mov     r11, sp
        sub     sp, sp, #408
        mov     r0, #0
        str     r0, [sp]
        str     r0, [r11, #-4]
        ldr     r0, .LCPI0_0
.LPC0_0:
        add     r0, pc, r0
        mov     r1, #400
        bl      printf
        ldr     r0, [sp]
        mov     sp, r11
        pop     {r11, lr}
        bx      lr
.LCPI0_0:
        .long   .L.str-(.LPC0_0+8)

.L.str:
        .asciz  "sizeof nums %lu\n"
```

Ele primeiro carrega isso aqui: `ldr r0, .LCPI0_0`. E `.LCPI0_0` aponta para
`.long .L.str-(.LPC0_0+8)`, que por sua vez aponta para
`.asciz "sizeof nums %lu\n"`. Ou seja, o `ldr` carrega no registrador o
endereço de memória correto para a string `sizeof nums %lu\n\0` (o terminador
`\0` é inserido pelo compilador para indicar fim de string, detalhe). Depois
ele coloca o 400 com `mov r1, #400`. Não tem referência, é o número direto.
Então ele chama a função `bl printf`.

E assim o compilador C resolve o operador `sizeof` ainda em tempo de
compilação, já que em tempo de execução esses tipos são perdidos e só temos
região de memória que tratamos como quiser.

Tá, mas o por quê de lançar falha de segmentação ao executar o `segfault.c`?
Lê no parágrafo passado "tipos são perdidos [...] tratamos como quiser"? Então.
Quando pedimos `nums[100000]`, ele está acessando a posição de número 100000 de
um vetor de inteiros. Isso pode ser entendido como aritmética de ponteiro: pego
a base do meu array, `&num` (que C permite tratar tanto `&num` como `num` como
ponteiro, o compilador entende que é o indicador de região de memória),
adiciona cem mil posições de inteiro (que no caso são 4 bytes cada posição) e
depois resolve esse valor. Como se fosse:
`int __interm = ((int)&num) + sizeof(*num) * 100000`. Isso vai nos retornar o
endereço de onde está armazenado o elemento na centésima milésima casa. Então
ele pega o conteúdo desse endereço `*((int*) __interm)`.

> Estou usando com bastante liberdade poética essa operação. Aritmética de
> ponteiros em C tem algumas nuances que estou evitando intencionalmente porque
> não é o foco aqui, por isso essas conversões absurdas para inteiro, e depois
> de volta para ponteiro. É só pra ilustrar o ponto e entender mais ou menos
> por cima qual a região de memória procurada.

Com isso, ele procura essa região no segmento de stack, e ela não está alocada.
Como não está alocada, o que acontece? Falha de segmentação!!!

# A falha de segmentação

No meu caso do `segfault.c` eu estou fazendo um acesso explícito de memória,
mas não na multiplicação. Não tem memória extra na função `mult`! Ou... será
que tem?

{% katexmm %}
Você se lembra de análise assintótica de complexidade? Quando se falava que a
memória extra _média_ do [quicksort](https://en.wikipedia.org/wiki/Quicksort)
era de $O(log n)$? Então, o quicksort não explicitamente alocava memória, mas
ele usava a estrutura de pilha da recursão para saber onde tinha parado para
poder continuar executando.
{% endkatexmm %}

Então, ao invocar uma função, normalmente você coloca a região de trabalho na
pilha, guarda os registradores que vai precisar depois, então coloca os
parâmetros para invocar a nova função e invoca a função que você deseja a
partir de um deslocamento da pilha. E é aí que tem a "memória adicional" na
análise de complexidade do quicksort! O programa coloca mais memória no
segmento de stack para poder voltar a trabalhar na função anterior!

Como a função é recursiva, ela está usando memória extra de maneira escondida.
Vamos rever ela:

```c
int mult(int a, int b) {
	if (b == 0) return 0;
	return a + mult(a, b - 1);
}
```

{% katexmm %}
Ela precisa encadear `b` chamadas recursivas em `mult`. Ou seja, $O(n)$ de
memória extra!
{% endkatexmm %}

Então o estouro se deu porque foram criadas 300 milhões de janelas de stack em
um único segmento da memória. Aí o segmento não aguentou e em uma dessas
chamadas ele estourou o segmento, causando uma falha na segmentação da memória.

# Aqui entra a função de cauda

Existem algumas técnicas para evitar isso. Entre elas, temos o
[Trampolim]({% post_url 2023/2023-10-02-trampoline %}), em que se usa memória
dinâmica para armazenar o estado de execução no lugar de usar a stack. E em
memória dinâmica podemos continuamente pedir novas páginas.

Mas não vim falar disso. Vim falar de outra estratégia, que também está
mencionada no artigo acima: recursão de função de cauda!

Resgatando aqui a função de cauda do exemplo, que foi Fibonacci:

```c
int fib_tc_entrada(int n) {
    return fib_tc(0, 1, 0, n);
}

int fib_tc(int a, int b, int i, int n) {
    if (i == n) {
        return a;
    }
    return fib_tc(b, a+b, i+1, n);
}
```

Note que, ao fazer a chamada recursiva, não precisa fazer nada depois que o
resultado for obtido, apenas passar pra cima. A computação foi feita antes da
invocação recursiva. Compare isso ao Fibonacci clássico:

```c
int fib(int n) {
    if (n == 0) return 0;
    if (n == 1) return 1;
    return fib(n - 1) + fib(n - 2);
}
```

Após a chamada a `fib(n-1)`, o programa precisa combinar com o retorno de outra
chamada de função. Então, aqui, eu preciso manter um contexto no final da
função.

E sabe o que tem legal em o contexto ser dispensável? Que você pode jogar ele
fora! Quando você tem uma chamada de função de cauda, basta manter os
parâmetros passados para baixo, não necessita criar uma nova região na stack
para manter a chamada para recuperar o contexto, fazer alguma computação e
retornar pra cima o valor.

E aqui vem o pulo do gato, o mesmo que o Leandro usou neste artigo
[Entendendo fundamentos de recursão](https://dev.to/leandronsp/entendendo-fundamentos-de-recursao-2ap4)!
Inclusive vou copiar a descrição dele:

> [...] algumas linguagens empregam uma técnica de otimização que consiste em
> utilizar a chamada TC com apenas um stack frame, garantindo assim que cada
> chamada recursiva seja tratada como se fosse uma iteração num loop primitivo.
> 
> Com isto, é feita a manipulação dos argumentos e dados da função em uma única
> stack frame [...].
> 
> A esta técnica chamamos de Tail call optimization, ou TCO.

## Transformando em função de cauda

O objetivo é transformar a função recursiva em função de cauda. A função
originalmente faz um processo computacional logo depois que obtém o resultado.
Isso significa que se eu conseguir "empilhar" esses processos, eu posso aplicar
eles em ordem e obter o resultado.

No caso, a operação é "somar com `a`": `return a + mult(a, b - 1);`. Vou tomar
uma liberdade aqui e escrever "lambdas" pra isso, mesmo não sendo código C,
depois ajeito a bagunça. No caso, a primeira chamada é simplesmente a operação
identidade. Eu retorno o que obtenho quando entra na chamada e mantenho o
`int mult(int a, int b)` como interface. tipo, teremos a função de entrada e a
função que de fato executa as coisas:

```c
int mult_tc(int a, int b, lambda computacoes) {
    if (b == 0) return computacoes(0);
    // ...
}

int mult(int a, int b) {
    return mult_tc(a, b, n => n);
}
```

Muito bem, agora precisamos avançar na recursão. Basicamente é a mesma coisa de
antes, subtrair de `b`. E na computação, que antes era `a + mult(...)`, vou
colocar a parte do `a + ...` no lambda:

```c
int mult_tc(int a, int b, lambda computacoes) {
    if (b == 0) return computacoes(0);
    return mult_tc(a, b - 1, n => computacoes(n) + a);
}

int mult(int a, int b) {
    return mult_tc(a, b, n => n);
}
```

E pronto, é isso. Agora, precisamos eliminar esse lambda, porque ele não
pertence ao C. Como fazer isso? Se reparar bem, a operação de soma ela é tanto
comutativa quanto associativa, tal qual o
[XOR]({% post_url 2025/2025-07-17-xor-search-missing-array %}). Então não
importa a ordem com que são feitas as operações, vai dar o mesmo resultado.

E se não importa a ordem, e toda a computação que eu faço é somar, então eu
posso simplesmente passar a "soma" para baixo, pasos o valor acumulado. E chega
no final e eu simplesmente somo com esse acumulado. E olha só! Eu sempre
retorno 0 para sofrer a computação lambda, então basta aqui retornar o valor
acumulado!

```c
int mult_tc(int a, int b, int acc) {
    if (b == 0) return acc;
    return mult_tc(a, b - 1, acc + a);
}

int mult(int a, int b) {
    return mult_tc(a, b, 0);
}
```

Agora a função não faz nenhuma computação a mais no retorno, é apenas uma
chamada de função de cauda. Ela pode ser otimizada com TCO!

# Nem tudon são flores

Não foi porque eu transformei o código em algo que PODE sofrer otimização de
cauda que ele VAI sofrer otimização de cauda. Para isso, você precisa passar a
flag de otimização. No meu compilador **Apple clang version 17.0.0**, e
compatível com GCC e muitos outros compiladores, usei a flag de otimização
"nível 3": `-O3`.

Pedindo ao Compiler Explorer pra ele gerar a função com otimização vs sem
otimização, podemos ver que na versão sem as otimizações ele mantém o aspecto
recursivo da função:

```asm
mult_tc:
        push    {r11, lr}
        mov     r11, sp
        sub     sp, sp, #16
[...]
        sub     r1, r1, #1
        ldr     r2, [sp]
        add     r2, r2, r0
        bl      mult_tc         ; bl - branch with link: faz chamada de função
[...]
        bx      lr              ; bx - branch and exchange: volta pra stack anterior
```

Agora com a otimização:

```asm
mult_tc:
        mla     r3, r1, r0, r2
        mov     r0, r3
        bx      lr

mult:
        mul     r2, r1, r0
        mov     r0, r2
        bx      lr
```

E sabe uma coisa mais legal? Quando falamos que a função específica não vai ter
uso fora da unidade de compilação (ie, bota o modificador `static` nela), o
compilador faz uma magia que some com a função!

```c
static int mult_tc(int a, int b, int acc) {
    if (b == 0) return acc;
    return mult_tc(a, b - 1, acc + a);
}

int mult(int a, int b) {
    return mult_tc(a, b, 0);
}
```

Vira isso:

```asm
mult:
        mul     r2, r1, r0
        mov     r0, r2
        bx      lr
```

E pronto.

Hmmmm. Ele... ele tá fazendo uma multiplicação direta? Bem, e se eu mandar ele
compilar com otimização a função com recursão clássica?

```c
int mult_class(int a, int b) {
    if (b == 0) return 0;
    return a + mult_class(a, b - 1);
}
```

```asm
mult_class:
        mul     r2, r1, r0
        mov     r0, r2
        bx      lr
```

Ok, ok, o compilador está prevendo nossos passos! Vou reduzir a otimização para
`-O1`:

```asm
mult:
        mov     r2, #0
        b       mult_tc

mult_tc:
.LBB5_1:
        cmp     r1, #0
        moveq   r0, r2
        bxeq    lr
        add     r2, r2, r0
        sub     r1, r1, #1
        b       .LBB5_1

mult_class:
        mov     r2, r0
        mov     r0, #0
.LBB6_1:
        cmp     r1, #0
        bxeq    lr
        add     r0, r0, r2
        sub     r1, r1, #1
        b       .LBB6_1
```

Vamos examinar aqui. Em `mult_class`, temos no final uma chamada para a label
dele mesmo através do `b .LBB6_1`. O `b` é como se fosse uma "chamada" menor de
função, em que não se cria um novo contexto de stack. O `bxeq` ali representa
uma situação de "branch and exchange", mas apenas se a condição for de
igualdade. Ele está comparando o elemento com 0 na instrução anterior, então
somente invoca essa finalização de função e término do branch caso seja
verdade.

Note que em `mult_tc` claramente ele faz um loop de si mesmo na última
instrução. A chamada de `mult` faz um `b mult_tc`. Em conversa com o
[Castilho](https://www.linkedin.com/in/pcstl/), ele me disse que esse processo
de não criar uma nova stack (o `bl`, branch with link) mas de reaproveitar a
stack com outra chamada de função é chamado de "proper tail call", PTC, não de
TCO.

Mas isso está de toda sorte muito bonitinho. Eu quero que ele demore mais
tempo, então vou colocar algo pra dificultar um pouco a vida: vou fazer a soma
do mesmo jeito. A vantagem da soma é que ela já vem como tail call diretamente:

```c
int sum_tco(int a, int b) {
    if (b == 0) return a;
    return sum_tco(a + 1, b - 1);
}
```

Então, usei isso para aumentar a dificuldade das funções:

```c
static int mult_tc(int a, int b, int acc) {
    if (b == 0) return acc;
    return mult_tc(a, b - 1, sum_tco(acc, a));
}

int mult(int a, int b) {
    return mult_tc(a, b, 0);
}

int mult_class(int a, int b) {
    if (b == 0) return 0;
    return sum_tco(a, mult_class(a, b - 1));
}
```

Gerando o ASM abaixo:

```asm
sum_tco:
.LBB1_1:
        cmp     r1, #1
        bxlt    lr
        sub     r1, r1, #1
        add     r0, r0, #1
        b       .LBB1_1

mult:
        mov     r2, #0
        b       mult_tc

mult_tc:
        push    {r4, r5, r11, lr}
        mov     r4, r1
        mov     r5, r0
.LBB5_1:
        mov     r0, r2
        cmp     r4, #0
        popeq   {r4, r5, r11, lr}
        bxeq    lr
        mov     r1, r5
        bl      sum_tco
        mov     r2, r0
        sub     r4, r4, #1
        b       .LBB5_1

mult_class:
        cmp     r1, #0
        moveq   r0, #0
        bxeq    lr
        push    {r4, lr}
        mov     r4, r0
        sub     r1, r1, #1
        bl      mult_class
        mov     r1, r0
        mov     r0, r4
        pop     {r4, lr}
        b       sum_tco
```

A multiplicação clássica tem o "branch and link" (`bl`) chamando a si mesma, e
logo no finalzinho ela chama a função `sum_tco` com PTC.

Já na função `mult_tc`, ele faz uma chamada para si mesma (`b .label`) no
final. Não exatamente para si do começo, mas de uma porção significativa.

## Vamos aos testes

Bem, para os testes vamos precisar de números grandes. Aqui o `int` é limitado
a 4 bytes, então vou praticamente reescrever tudo com `long long int`, com
tamanho de 8 bytes.

Agora, para comparar, não quero ficar fazendo múltiplos arquivos. Se estamos
usando C, vamos usar também o pré-processador que vem junto! Queria ter a
capacidade de determinar 2 coisas via compilação:

- se vai usar a versão clássica da recursão, ou a versão TCO
- se vai somar simplesmente ou se vai usar o `sum-tco`

Então eu fiz isso. Eu poderia ter usado uma função de macro para lidar com a
questão do `sum-tco`, mas fiz de jeito bem mais clássico mesmo:

```c
#ifdef SUM
    return sum_tco(a, mult(a, b-1));
#else
    return a + mult(a, b-1);
#endif
```

E para determinar a estratégia de multiplicação:

```c
long long int mult_iface(long long int a, long long int b) {
#ifdef TCO
    return mult_tco(a, b);
#else
    return mult(a, b);
#endif
}
```

Eis o programa completo:

```c
#include<stdio.h>
#include<stdlib.h>

long long int sum_tco(long long int a, long long int b) {
	if (b <= 0) {
		return a;
	}
	return sum_tco(a + 1, b - 1);
}

static long long int inner_mult_tco(long long int a, long long int b, long long int acc) {
	if (b <= 0) {
		return acc;
	}
#ifdef SUM
	return inner_mult_tco(a, b - 1, sum_tco(a, acc));
#else
	return inner_mult_tco(a, b - 1, a + acc);
#endif
}

long long int mult_tco(long long int a, long long int b) {
	return inner_mult_tco(a, b, 0);
}

long long int mult(long long int a, long long int b) {
	if (b == 0) return 0;
#ifdef SUM
	return sum_tco(a, mult(a, b - 1));
#else
	return a + mult(a, b - 1);
#endif
}

long long int mult_iface(long long int a, long long int b) {
#ifdef TCO
	printf("usando a função mult_tco\n");
	return mult_tco(a, b);
#else
	printf("usando a função mult\n");
	return mult(a, b);
#endif
}

int main(int argc, char **argv) {
	if (argc != 3) {
		fprintf(stderr, "Passe no mínimo 3 argumentos!\n");
		return 1;
	}

	long long int m = atoll(argv[1]);
	long long int n = atoll(argv[2]);

	long long int r = mult_iface(m, n);

	printf("mult(%lld, %lld): %lld\n", m, n, r);
	return 0;
}
```

Para compilar e para rodar, criei dois scripts para lidar com as seguintes
combinações:

- com/sem TCO
- com/sem a soma
- com/sem a otimização

A compilação é assim:

```bash
#!/bin/bash

set -x

SRC=mult.c
DEST_BASE=mult

# plain
cc "${SRC}" -o "${DEST_BASE}"

# -O1
cc "${SRC}" -O1 -o "${DEST_BASE}-O1"

# TCO
cc "${SRC}" -DTCO -o "${DEST_BASE}-defTCO"

# -O1 TCO
cc "${SRC}" -O1 -DTCO -o "${DEST_BASE}-defTCO-O1"

# SUM
cc "${SRC}" -DSUM -o "${DEST_BASE}-defSUM"

# -O1 SUM
cc "${SRC}" -O1 -DSUM -o "${DEST_BASE}-defSUM-O1"

# TCO SUM
cc "${SRC}" -DTCO -DSUM -o "${DEST_BASE}-defTCO-SUM"

# -O1 TCO SUM
cc "${SRC}" -O1 -DTCO -DSUM -o "${DEST_BASE}-defTCO-SUM-O1"
```

E para rodar:

```bash
#!/bin/bash

set -x

a="${1:-1000}"
b="${2:-30000000000}"

run-tests() {
    time "./mult${1}" "$a" "$b"
}

run-tests
run-tests -O1
run-tests -defTCO
run-tests -defTCO-O1

run-tests -defSUM
run-tests -defSUM-O1
run-tests -defTCO-SUM
run-tests -defTCO-SUM-O1
```

Quando fiz o experimento com otimização de nível 3, todos as execuções
retornaram em tempo razoável. A maioria por falha de segmentação.

O compilador mesmo com um grau de otimização já é esperto o suficiente para
entender que naquele canto devemos ter uma otimização de cauda. Inclusive com
otimização no grau 3 ele conseguiu desenrolar e ver a multiplicação por baixo
dos panos.

As seguintes execuções resultaram em falha de segmentação para a entrada 1000
30000000000 (mil e 30 bilhões):

- `mult`
- `mult-defTCO`
- `mult-defSUM`
- `mult-defSUM-O1`
- `mult-defTCO-SUM`

As seguintesa execuções (com o tempo de execução) concluíram com sucesso
- `mult-O1` 9.6s
- `mult-defTCO-O1` 9.7s
- `mult-defTCO-SUM-O1` (rodou sem conclusão, parei antes do tempo e eu creio
  nessa conclusão)

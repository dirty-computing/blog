---
layout: post
title: "Cacofonia em código?"
author: "Jefferson Quesado"
tags: js c++ language-design bash
base-assets: "/assets/cacofonia/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Existem alguns conjuntos de caracteres que são bem caóticos. E eles são pedaços
de código válidos! Vamos explorar alguns dos meus favoritos? E entender o
porquê de as linguagens delas permitirem?

Usem os códigos abaixo por conta e risco.

# Clássico de bash

```bash
:(){ :|:& };:
```

Vamos começar a análise. O `:` é um caracter válido para nome de função. Por
exemplo, eu posso criar uma função assim:

```bash
:f() {
    echo f
}

:f
# imprime "f"
```

Se `:f` é válido, também posso brincar com `:`. Inclusive, o `:` é um built-in
do shell:

```bash
$ help :
:: :
    No effect; the command does nothing.  A zero exit code is returned.
```

E eu posso sobrescrever o built-in com uma função declarada.

Para criar uma função em bash existem duas alternativas:

- usar a palavra reservada `function` antes do nome da função
- usar o par de abre/fecha parênteses após o nome da função
- e misturar ambos também funciona

Diferente de outras linguagens, o que está dentro do parêntese não tem relação
alguma com os parâmetros que a função vai receber: esses parênteses precisam
estar vazios. Ok, aceita espaços dentro dos parênteses, mas por convenção é
mais comum encontar vazio.

Portanto, se eu quiser criar uma função chamada `hello`, eu tenho as seguintes
alternativas:

```bash
function hello {
    echo "olá, mundo"
}

hello() {
    echo "olá, mundo"
}

function hello() {
    echo "olá, mundo"
}
```

Portanto, como `:` é um caracter válido para nome de função, `:()` indica que
eu estou criando uma função.

Após a declaração de função com o nome `:`, vem o corpo da função. Aqui, estou
usando o corpo como sendo um bloco de código, com o `{` para iniciar e o `}`
para terminar.

Mas... isso não é necessário com o bash! Você pode usar não um bloco de código,
mas sim uma subshell!! Colocando `(` para começar e `)` para terminar. Analise
as duas funções abaixo:

```bash
XISPA=123

xispa(){
    echo $XISPA
    XISPA=xxx
    echo $XISPA
}

SAI=123
sai()(
    echo $SAI
    SAI=xxx
    echo $SAI
)

xispa
# imprime "123", imprime "xxx"

sai
# imprime "123", imprime "xxx"
```

Aparentemente, tudo igual, né? Bem, mas a função de baixo não usa um bloco de
código, mas uma subshell. Isso significa que a memória usada na subshell é no
estilo COW, copy-on-write: ele vem como uma espécie de "cópia" da shell mãe.
Mas essa cópia ela não se materializa até de fato houver uma escrita, então
nesse momento se passa a ter a variável apontando para um outro canto. Até
lá, a memória da shell mãe e a da filha compartilham esse pedaço de memória,
evitando disperdício de memória.

Isso significa que na função `sai`, que é uma subshell, vai ativar o mecanismo
COW ao fazer `SAI=xxx`. Portanto, após invocar `sai`, o valor da variável vai
continuar sendo `123`!

Você pode usar subshells em outros contextos também. Inclusive com o intuito de
controlar efeitos colaterais. Já cheguei a citar isso nos posts
[Instalando Sdkman! no Windows]({% post_url 2022/2022-09-22-sdkman-windows %})
e
[Usando chave ssh "custom" para comandos git]({% post_url 2025/2025-10-16-git-ssh-custom %}).
Elas não precisam necessariamente estarem atribuídas a um bloco sintático de
texto, como o corpo de uma função. Elas podem simplesmente existirem por conta
própria no meio de um código.

No caso de um bloco de código, o bash necessita que você separe com espaços o
`{`. Por isso você não pode fazer `{echo 123;}`. Isso gera um erro sintático,
desses que não são intuitivos:

```bash
$ {echo 123;}
bash: syntax error near unexpected token `}'
```

Notou que está reclamando do caracter `}`? É porque ele está fechando algo que
não foi aberto. "Ué, como assim?" você pode estar se perguntando... Bem, porque
no caso ele reconheceu `{echo` como o comando, mas nem chegou a perceber que o
comando não existia porque a sintaxe do comando estava errado! Removendo o `}`
que não fecha nada temos isso:

```bash
$ {echo 123;
bash: {echo: command not found
```

Já com subshell não precisamos disso:

```bash
$ (echo 123)
123
```

Por sinal... notou que com bloco de código tinha um `;` ali no final do `echo`?
Isso porque no bloco de código você precisa indicar que o comando acabou, para
impedir que o `}` seja interpretado como parte dos argvs do comando. Se o `}`
não vier no começo do comando, ele é interpretado como apenas mais um dos
argumentos:

```bash
$ echo 123 }
123 }
$ echo 123; }
bash: syntax error near unexpected token `}'
```

Mas... sabia que existe uma maneira alternativa para indicar que o comando 
acabou? Tá, são duas... A mais comum e trivial é dividir em várias linhas, que
aí sem indicativo nenhum a bash interpreta como separação de comando. MAS tem
uma maneira mais divertida: indicar que o comando terminou de ser digitado, mas
que você quer que ele seja executado em segundo plano: `&`. Note que ele é meio
que equivalente sintaticamente ao `;`:

```bash
$ { echo 123&}
[1] 4086
123
bash-3.2$ { echo 123;}
123
```

Mas notou também que ele mostrou um número entre `[`colchetes`]`? Aqui ele
mostra uma espécie de ID de processo de background. O PID dele mesmo foi 4086,
mas ele é o processo de número 1 em atividades em background naquela shell. E
como fazemos para mapear quantos processos em background temos? Existe o
comando `bg`. Por exemplo:

```bash
$ sleep 20 &
[1] 12573
$ bg
bash: bg: job 1 already in background
$ bg
bash: bg: job has terminated
[1]+  Done                    sleep 20
```

`bg` vem literalmente de
<span style="color: red;" markdown=1>b</span>ack<span style="color: red;" markdown=1>g</span>round.
Para trazer o que está em plano de fundo para plano de frente, temos o `fg`,
<span style="color: red;" markdown=1>f</span>ore<span style="color: red;" markdown=1>g</span>round.

Até agora, já foi explicado o praticamente tudo que se tinha para explicar
sobre esse pedaço de código bash, só falta explicar a barra vertical. Bem, isso
é um pipe. Mas... o que seria um pipe?

O símbolo da barra vertical `|` em bash (e em diversas outras shells) é usado
para ligar um processo a outro. Mas não liga de qualquer jeito: liga a saída
padrão do processo da esquerda com a entrada padrão do processo da direita. Com
essa ligação, podemos fazer pipelines bem complexos, com o fluxo de dados
sempre indo da esquerda pra direita.

E sabe uma coisa bem bacana das pipelines do bash? Elas são o que em Java
seriam chamadas de
[`gatherer`]({% post_url 2025/2025-03-21-java-24-gatherers %}), porque é uma
operação intermediária sem limitação do que pode fazer: pode aumentar a
quantidade de elementos produzidos, diminuir, transformar, acumular e de vez em
quando dar algum output. Inclusive isso pode ser usado em lexers e parsers,
como de fato fiz aqui em
[Um parser em bash que identifica enums de um fonte Java]({% post_url 2022/2022-03-20-bash-java-enum-parser %}).

> E se isso é possível fazer em Java? CLARO QUE SIM! Com `gatherer`. Mais cedo
> ou mais tarde vem o post com um lexer Java usando `gatherer`.

Em bash temos diversas maneiras de manipular para onde vão os dados, desde de
onde eles serão lidos até para onde serão escritos. Além do pipe, também
podemos fazer redirecionamentos de input/output através dos operadores `<` e
`>`. De modo geral, eles permitem a escrita e a leitura em lugares nomeados. E
esses lugares podem ser, por exemplo, arquivos ou pipes nomeadas (que, por
sinal, não tem _aparente_ tanta diferença para arquivos convencionais no que
tange o uso). Mas também permite principalmente a leitura através de operações
inline, seja com entrada de string ou com heredoc. Mas existem outras
alternativas para redirecionamentos anônimos. Mas não vem ao caso explorar
todas essas possibilidades nesse artigo.

Além do redirecionamento da entrada e da saída padrão, também podemos fazer
redirecionamento da saída de erro através do `2>`. Tirando esse número, ele se
comporta igual aos redirecionamentos da saída padrão.

Agora, se tem esse `2` para a saída de erro... isso significa que existe algum
"número" para a saída padrão? Na real, sim! E para a entrada padrão também!

De modo geral, é comum na programação que as coleções comecem com o número 0.
Então, o `0` nesse sentido seria a entrada padrão. O `<` serve como uma espécie
de atalho para `0<`. A saída padrão ocupa o número `1`, e de modo semelhantes o
`>` é um atalho para `1>`. Logo, o redirecionamento da saída e de saída de erro
usam o mesmo operador, apenas que como é uma operação extremamente comum fazer
o redirecionamento da saída padrão é fornecido um "atalho" para ela.

E... esses números, são arbitrários? Na real, meio que sim. Eles são os "file
descriptors". E todo processo tem 3 file descriptors padrões:

- 0 : entrada padrão
- 1 : saída padrão
- 2 : saída de erro

Os file descriptors podem ser fechados/nem abertos? Podem. Mas... isso não vem
ao caso aqui neste post. E também podemos fazer a operação de abrir outros file
descriptors para um processo. Por exemplo, nada impede que se faça `3<`, para
indicar que o processo novo sendo aberto irá usar o file descriptor de número 3
para fazer leitura. Ou então fazer `3>` para dizer que vai usar o file
descriptor de número 3 para escrever.

E o bash tem uma coisa importante em relação a isso: ele só inicia o processo
que está sendo chamado se todos os file descriptors para a inicialização dele
estiverem prontos. Em pipelines isso significa que, enquanto se está levantando
o programa do "lado esquerdo", uma pipeline anônima já foi preparada para que,
quando algo for escrito nela, seja direcionado para o programa "logo a direita"
(e assim recursivamente).

Ou seja, ao fazer `:|:`, estamos aqui prendendo a execução de um processo na
existência do outro.

> Ah, mas o seu processo nem escreve no saída padrão! Muito menos lê nada de
> lá!

De fato, mas a bash não sabe nada sobre isso no momento da invocação, ele
simplesmente faz o que é requisitado da melhor maneira possível como se o
processo fosse uma caixa preta.

Então, o que o `:|:` faz? Basicamente cria um pipeline, coloca o primeiro `:`
do "lado esquerdo" escrevendo nela, então coloca o segundo `:` do "lado
direito" lendo dela. E saca só? Ele faz essa pipeline em segundo plano porque o
comando é `:|:&`, com o `&` indicando que é execução em plano de fundo.

E... advinha o que `:` faz? Cria uma pipe anônima que coloca um processo para
escrever nessa pipe e outro processo para ler dessa pipe, com execução em plano
de fundo! E esse processo que ele chama é exatamente o `:`. Isso implica que
ele vai criar e criar o processo várias e várias vezes, enchendo o computador
com esses processos. E sabe qual o nome que se dá para a criação de um novo
processo? Fork! E como isso tem um comportamento explosivo, essa função é
chamada de fork bomb!

Mas... isso só acontece se você chamar a função bash `:`, confere? Pois bem...
Lembra como foi a escrita cacofônica do começo? Vamos repor ela aqui com as
partes que chamam a atenção:

```bash
:() { ... };:
```

Pois bem.... criamos a função e logo em seguida... tem o `;` que indica o final
de um comando! E a criação de função é um comando completo! E logo em seguia
temos... `:`. Ou seja: ao digitar a cacofonia inteira e dar `enter`, invocamos
a própria função. Basta colocar essa linha de código que criamos e invocamos a
fork bomb!

# IIFE do JS

No JS, temos a alternativa de criar funções anônimas através das arrow
functions! E como vimos em
[A vida sem if, um desafio para escrever código sem estruturas de controle]({% post_url 2025/2025-10-09-controlless %}),
podemos fazer um IIFE.

Então, o que seria

```js
(() => {})()
```

Bem, isso é uma operação imediatamente invocada que... não faz nada.

Aqui o `{}` indica que é uma arrow function de corpo vazio. Mas se eu fizer

```js
(() => 42)()
```

eu obtenho como resposta 42. E se eu botar um array vazio? Pois bem, eu vou ter
um array vazio

```js
(() => [])()
```

Mas se eu quiser muito obter um objeto vazio? Bem, o comportamento padrão de
arrow function é começar um bloco de código, logo começar com `{` vai indicar
para o interpretador que você está querendo um bloco de código. Mas... como
contornar isso?

Ora, ora... existe um operador que permite indicar precedência! O `(` parêntese
`)`. Por exemplo, `4 + 2 * 3`, sem parêntese, significa 10: `2*3` dá 6, e
depois `4 + 6` resultado em `10`. E isso é diferente de `(4 + 2) * 3`, que dá
`18`: `4+2` gera `6`, e `6*3` gera `18`. Com isso, podemos fazer `(42)` também.
Apesar de não ter nada aqui para lutar pela precedência... sabemos que a
expressão dentro do parêntese deve ser resolvido antes do resto. E isso se
aplica também a `({})`: aqui indica que o objeto vazio precisa ser resolvido
antes de outra coisa.

E podemos usar isso na nossa IIFE:

```js
(() => ({}))()
```

Ok, temos a arrow function, temos a chamada dela, e também temos um `(`
parêntese `)` ao redor da arrow function antes da IIFE. Agora, por que
precisamos dele? Do operador de resolução de precedência?

Basicamente porque ele remove qualquer ambiguidade. Eu posso criar uma arrow
function que chama uma função, por exemplo:

```js
const sum = (i) => i <= 0? 0: i + sum(i-1)
```

Notou como eu tenho uma chamada de função dentro da arrow function? Isso
poderia ser também uma chamada de uma função sem argumentos, por exemplo:

```js
const x = () => console.log()
```

Ou seja: não tem motivo nenhum para que esse parêntese seja interpretado como
a invocação da arrow function que estamos criando. Se quiser, esse trecho é um
código "válido" sintaticamente:

```js
() => ({})()
```

Aqui, criamos uma arrow function que faz uma "call" para um objeto vazio. Claro
que nesse exemplo dá errado porque o objeto vazio `{}` não é "callable", ele
não é uma função. MAS PODERIA SER!

```js
() => (() =>{})()
```

Aqui eu tenho uma função anônima que cria e invoca uma função anônima que não
faz nada, e aqui

```js
() => (() =>({}))()
```

eu tenho uma função anônima que retorna o valor de uma função anônima
imediatamente declarada e invocada que retorna um objeto vazio.

E é por conta disso que eu preciso indicar que a criação do objeto terminou, e
que eu vou invocar a função:

```js
(() => (() =>({}))())()
```

Para indicar que eu terminei de criar a função, para assim poder invocar ela
imediatamente, e assim resolver sintaticamente toda e qualquer ambiguidade que
possa restar a respeito de qual função realmente deveria ser chamada.

# Empilhando parênteses com C++

Olha isso:

```c++
[](){}()
```

Parece até um exercício para saber se está fechando o parêntese com o par
correto, né? Querendo saber se você sabe implementar uma pilha?

Ok, mas em C++ eu não posso colocar tudo em qualquer lugar, como será um caso
de uso que eu posso inserir esse pedaço de código?

```c++
#include <iostream>

int main() {
        [](){}();
        std::cout << "hello" << std::endl;
        return 0;
}
```

Exemplo esclarecedor? Nem tanto, né? Mas isso em C++ é uma lambda! E digo mais!
Tal qual em JS, o C++ permite que você faça um IIFE: _immediately invoked
function expression_. Mas, se tem essa expressão, o que ela faz?

Bem, ela não tem nada, né? Então... essa função não faz nada. Mas podemos ver
muita coisa legal do C++11! Vamos lá!

O primeiro par de parênteses se chama de "capture group". Ele está vazio, tá
vendo? Isso significa que essa lambda é um combinador (vide
[O combinador Y]({% post_url 2025/2025-09-15-y-combinator %} para definição de
combinador), lá explico isso bem direitinho). Diferente do Java e do JS, que
pega por contexto o como você lida com as funções da clausura, o C++ quer que
**você** como programador indique o que está capturando.

Em Java, inclusive, eles diferenciam "capturing lambda" de "non-capturing
lambda". O lambda que faz captura exige que seja criado um novo objeto a cada
criação da lambda, pois ele precisa de informações ao redor para ser colocado
dentro do escopo de coisas que a lambda conhece; em outras palavras, é
transparente adicionar novas variáveis dentro da clausura de uma função.
Classes anônimas em Java também tem essa questão de fazerem clausura
automática.

Aliás, clausura em Java é transparente? Bem... nem tanto. Para Java, o elemento
que é adicionado na clausura precisa ser efetivamente `final`. Isto é: essa
variável precisa ser preenchida com um único valor antes da declaração da
lambda, e também esse valor não pode ser alterado depois; é como se a
declaração dessa variável pudesse ser feita com o modificador `final` (por mais
que ela não tenha o `final`), por isso que é como "se essa variável fosse
efetivamente `final`".

Tá, e além da clausura explícita, o que temos? A lista de argumentos. Como uma
lambda, é uma HoF. Isso significa que não é apenas uma "execução lazy", mas sim
que vai executar como uma função para o argumento que será passdo. Então sim,
eventualmente posso passar adiante uma lambda.

Finalmente temos o `{}`, que é o corpo da lambda. E o último `()` é a chamada
da função. Como é um IIFE, ela aparece logo após o bloco. Como não tem
argumentos, ela está vazia.

Agora, como saber se está de fato acontecendo uma chamada? Vamos imprimir tanto
na main como na lambda:

```c++
#include <iostream>

int main() {
        [](){
                std::cout << "lambda" << std::endl;
        }();
        std::cout << "main" << std::endl;
        return 0;
}
```

Ao compilar e executar:

```bash
> g++ a.cpp -o a && ./a
lambda
main
```

Isso demonstra que está acontecendo chamada de lambda, massa! Agora, será que
podemos usar o grupo de captura? Vamos declarar a string `lambda` como sendo
uma variável no escopo da função `main`:

```c++
#include <iostream>

int main() {
        auto x = "lambda";
        [x](){
                std::cout << x << std::endl;
        }();
        std::cout << "main" << std::endl;
        return 0;
}
```

Ok, ok. E para passar argumentos? Vamos testar?

```c++
#include <iostream>

int main() {
        auto x = "lambda";
        [x](int i){
                std::cout << x << std::endl;
                std::cout << i << std::endl;
        }(10);
        std::cout << "main" << std::endl;
        return 0;
}
```

Ok, isso imprime o `10` entre `lambda` e `main`. Como esperado. Mas, e para
reusar a função? Eu posso simplesmente atribuir ela a uma variável!

```c++
#include <iostream>

int main() {
        auto x = "lambda";
        const auto f = [x](int i){
                std::cout << x << std::endl;
                std::cout << i << std::endl;
        };
        f(10);
        f(15);
        std::cout << "main" << std::endl;
        return 0;
}
```

Conforme esperado, imprime:

```text
lambda
10
lambda
15
main
```

Note também que eu não fui atráves de saber com detalhes qual seria o tipo de
`f`, pedi para o compilador resolver.

Agora, como será que o compilador lida com a captura em si? Bem, vamos fazer
alguns testes...

O primeiro: tentar escrever na variável dentro do lambda!

```c++
#include <iostream>

int main() {
        auto x = "lambda";
        const auto f = [x](int i){
                std::cout << x << std::endl;
                std::cout << i << std::endl;
                x = "teste";
        };
        f(10);
        f(15);
        std::cout << "main" << std::endl;
        return 0;
}
```

```none
a.cpp:8:5: error: cannot assign to a variable captured by copy in a non-mutable lambda
    8 |                 x = "123";
      |                 ~ ^
1 error generated.
```

Ok, isso não funcionou. E escrita na variável fora da lambda, entre duas
chamadas?

```c++
#include <iostream>

int main() {
        auto x = "lambda";
        const auto f = [x](int i){
                std::cout << x << std::endl;
                std::cout << i << std::endl;
        };
        f(10);
        x = "teste";
        f(15);
        std::cout << "main" << std::endl;
        return 0;
}
```

E a saída:

```c++
#include <iostream>

int main() {
        auto x = "lambda";
        const auto f = [x](int i){
                std::cout << x << std::endl;
                std::cout << i << std::endl;
        };
        f(10);
        x = "teste";
        f(15);
        std::cout << "main" << std::endl;
        return 0;
}
```

Tá, mas por que isso aconteceu assim? Lembra da mensagem de erro? "cannot
assign to a variable captured by copy"? Isso significa que o valor de `x` ali
é capturado como valor! Lembra daquele conversa de "passar variável como valor
ou como referência" no começo da faculdade? Então...

Se eu quiser passar como referência, só usar a notação tradicional do C++ para
isso. Vamos testar?

```c++
#include <iostream>

int main() {
        auto x = "lambda";
        const auto f = [&x](int i){
                std::cout << x << std::endl;
                std::cout << i << std::endl;
        };
        f(10);
        x = "teste";
        f(15);
        std::cout << "main" << std::endl;
        return 0;
}
```

E o resultado vem como se espera:

```none
lambda
10
teste
15
main
```

E, bem, já que estamos lidando com referência, será que conseguimos
sobrescrever o valor dentro do lambda? E a resposta é: SIM! Vai dar o mesmo
output:

```c++
#include <iostream>

int main() {
        auto x = "lambda";
        const auto f = [&x](int i){
                std::cout << x << std::endl;
                std::cout << i << std::endl;
                x = "teste";
        };
        f(10);
        f(15);
        std::cout << "main" << std::endl;
        return 0;
}
```

E... e se eu quisesse ter tipos dinâmicos como parâmetros da minha lambda? Bem,
podemos usar o `auto`?

```c++
#include <iostream>

int main() {
        const auto f = [](auto i){
                std::cout << i << std::endl;
        };
        f(10);
        f("teste");

        return 0;
}
```

O que vai imprimir:

```none
10
teste
```

E se eu quiser passar dois parâmetros? Bem, por que não, né?

```c++
#include <iostream>

int main() {
        const auto f = [](auto i, auto j){
                std::cout << i << std::endl;
                std::cout << j << std::endl;
        };
        f(10, 15);
        f("teste", "outro teste");

        return 0;
}
```

Isso vai imprimir:

```none
10
15
teste
outro teste
```

Tudo bonitinho, né? Mas se eu quiser que ambos seja do mesmo tipo? Tipo...
chamar `f(0, "falha")` quebrando? Bem, essa estratégia não funciona, porque o
compilador aceita misturar os tipos nessa situação (um tipo não causa
limitações no outro):

```c++
#include <iostream>

int main() {
        const auto f = [](auto i, auto j){
        //const auto f = []<typename v>(v i, v j){
                std::cout << i << std::endl;
                std::cout << j << std::endl;
        };
        f(10, 15);
        f("teste", "outro teste");

        f(0, "falha");
        return 0;
}
```

Isso compila com sucesso e imprime:

```none
10
15
teste
outro teste
0
falha
```

Mas eu posso aplicar o generics do C++! Porque, claro, tudo fica mais divertido
com generics! Mas aqui tem um detalhe para quem usa `g++` (e possivalmente
outros compiladores): precisa passar a flag de padrão c++23:

```bash
g++ -std=c++23 a.cpp -o a
```

Com isso em mão, como se aplica o generics? Bem, vamos usar mais um par de
parênteses na expressão, o `<>`. Infelizmente eles não podem vir vazios... mas
vamos lá! Fica assim:

```c++
#include <iostream>

int main() {
        const auto f = []<typename v>(v i, v j){
                std::cout << i << std::endl;
                std::cout << j << std::endl;
        };
        f(10, 15);
        f("teste", "outro teste");

        f(0, "falha");
        return 0;
}
```

Aqui nesta situação eu vou quebrar a compilação:

```none
a.cpp:12:2: error: no matching function for call to object of type 'const (lambda at a.cpp:5:17)'
   12 |         f(0, "falha");
      |         ^
a.cpp:5:17: note: candidate template ignored: deduced conflicting types for parameter 'v' ('int' vs. 'const char *')
    5 |         const auto f = []<typename v>(v i, v j){
      |                        ^
```

Removemndo a chamada de função ruim, executa normalmente:



```c++
#include <iostream>

int main() {
        const auto f = []<typename v>(v i, v j){
                std::cout << i << std::endl;
                std::cout << j << std::endl;
        };
        f(10, 15);
        f("teste", "outro teste");

        return 0;
}
```

Com output:

```none
10
15
teste
outro teste
```

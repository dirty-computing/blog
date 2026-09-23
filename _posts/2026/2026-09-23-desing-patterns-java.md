---
layout: post
title: "Não cometa esse erro com design patterns! Em Java!"
author: "Jefferson Quesado"
tags: java design-pattern engenharia-de-software
base-assets: "/assets/desing-patterns-java/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

> Baseado [nesta thread no Bluesky](https://bsky.app/profile/jeffquesado.ulivre.dev/post/3mthkpb52nk2j)

Quando lidamos com padrões de projetos, muitas pessoas veem naquilo como algo
bem dogmático. Digamos que eu tenha uma
[visão diferente do assunto]({% post_url 2025/2025-05-24-functions-as-design-patterns %}).

Então, vamos lá explorar algumas coisas que são **erros** que tem gente que
ainda propaga por aí? Você se junta a mim na minha eterna cruzada contra o
javismo cultural?

# Template method como classe abstrata

Peguei isso aqui como um dogma. Em um código. Em que a pessoa literalmente
deixou o código comentado assim tentando justificar a escolha. Mas, bem, de
onde vem essa ideia?

Se formos visitar 
[template method no meu artigo]({% post_url 2025/2025-05-24-functions-as-design-patterns %}#template-method)
vemos que não tem nada de obrigação quanto à estrutura de ser uma classe
necessariamente.

Historicamente, GoF escreveu quando o que se tinha era um C++ antigo. Nessa
versão existiam templates, e o que se entendia por interface em C++ era uma
classe virtual pura sem nenhum campo. Algo como:

```c++
class Somavel {
public:
    virtual Somavel soma(Somaval rhs) = 0;
}
```

Assim, o entendimento do que era uma "interface" era algo livre de qualquer
implementação. Como evidênca (fraca, ok, mas evidência do _Zeitgeist_ sobre
isso), temos [esta resposta](https://stackoverflow.com/a/1307282/4438007) no
Stack Overflow sobre o assunto, em que no final o autor escreveu isto lá em
2009:

> Pure Virtual Functions are mostly used to define:
>
> 1. Abstract Classes
>    - These are base classes where you have to derive from them and then
>      implement the pure virtual functions.
> 2. Interfaces
>    - These are 'empty' classes where all functions are pure virtual and hence
>      you have to derive and then implement all of the functions.

Em tradução livre

> Funções puramente virtuais são usadas em grande parte ara definir:
>
> 1. Classes abstratas
>    - Essas são classes bases onde você precisará derivar delas e entào
>      implementar as funções puramente virtuais
> 2. Interfaces
>    - Essas são classes "vazias" onde todas as funções são puramente virautis
>      e portanto você precisa derivar e implementar todas as suas funções.

Mas note que isso é um conceito "além" das definições de C++. Quando se vai ver
nas definições da linguagem, não se tem menção à interface. Vide o índice de
referência da linguagem:

- [overview](https://en.cppreference.com/cpp)
- [linguagem/sintaxe](https://en.cppreference.com/cpp/language)

> A propósito, quem está por trás desse site? Administração e hospedagem via
> [Standard C++ Foundation](https://en.cppreference.com/Cppreference:FAQ#Who_is_behind_this_site?)

Ao consultar esses índices, não vai se encontrar nada a respeito do que seja
uma "interface". Esta resposta de 2012 no
[Software engineering exchange](https://softwareengineering.stackexchange.com/a/134772)
deixa claro que as pessoas usam interface no contexto de C++ de maneiras
distintas:

> In C++, the term "interface" has not just one widely accepted definition - so
> whenever you are going to use it, you should say what you mean exactly

Em tradução livre:

> Em C++, o termo "interface" não tem uma única definição amplamente aceita,
> portanto toda vida que você mencionar "interface", você precisa dizer
> exatamente o que quer dizer com isso

Logo depois, o autor da resposta enumera alguns usos:

- classes abstratas
- classes abstratas com implementações default
- os membros públicos de uma classe arbitrária

e deixa claro que existem outras interpretações para o que quer dizer
"interface", e que cabe ao escritor definir o que ele quer dizer quando
menciona essa palavra.

Na referência da linguagem C++, existem coisas que eles chamam de "requisitos
nomeados", como por exemplo
[`Compare`](https://en.cppreference.com/cpp/named_req/Compare). Aqui, o
`Compare` recebe dois elementos de um tipo `T` e retorna um booleano indicando
se os elementos passados estão em ordem; ie, para a chamada `comp(a, b)`, eu
retorno `true` se e somente se `a < b`.

> Isso implica que se `a == b`, então tenho que
> `comp(a, b) == comp(b, a) == false`.

Um canto em que esse requisito nomeado é mencionado explicitamente é na
implementação de
[`is_sorted`](https://en.cppreference.com/cpp/algorithm/is_sorted), na variante
que passa estes 3 argumentos:

```c++
template< class ForwardIt, class Compare >
bool is_sorted( ForwardIt first, ForwardIt last, Compare comp );
```

Note que através do template não há como saber como que deveria ser o contrato
de `Compare` nem de `ForwardIt`, mas aqui `comp` precisa ser tal que ele
aceite ser chamado com dois elementos "guardados" pelo iterador de `ForwardIt`.
Onde o `ForwardIt` explicitamente requer que fazer um desreferenciamento
retorne a instância do tipo que o iterador navega e que a operação `it++`
avance uma casa.

Aqui um exemplo de como usar isso no `is_sorted`, sem que haja conhecimento por
parte da função `is_sorted` do que está sendo usado:

```c++
#include <iostream>
#include <algorithm>

class MeuIt {
	int *data;
	int pos;

public:
	MeuIt(int data[], int pos): data(data), pos(pos) {}

	MeuIt& operator=(MeuIt& base);
	bool operator==(const MeuIt& other) const;
	MeuIt& operator++();
	int& operator*();
};

class Edges {
	int *data;
	int size;

public:
	Edges(int data[], int size): data(data), size(size) {}
	MeuIt init() {
		return MeuIt(data, 0);
	}

	MeuIt end() {
		return MeuIt(data, size);
	}
};

MeuIt& MeuIt::operator++() {
	pos += 1;
	return *this;
}

MeuIt& operator++(MeuIt& self, int _) {
	return ++self;
}

bool operator!=(const MeuIt& self, const MeuIt& other) {
	return ! (self == other);
}

bool MeuIt::operator==(const MeuIt& other) const {
	return this->data == other.data && this->pos == other.pos;
}

int& MeuIt::operator*() {
	return data[pos];
}

MeuIt& MeuIt::operator=(MeuIt& base) {
	this->data = base.data;
	this->pos = base.pos;
	return *this;
}

std::string boolprint(bool b) {
	return b? "true": "false";
}

int main() {
	int d[] = { 1, 1, 2, 3, 5, 8};
	
	std::cout << sizeof(d)/sizeof(*d) << std::endl;
	
	Edges e = Edges(d, sizeof(d)/sizeof(*d));
	std::cout << "main" << std::endl;

	std::cout << boolprint(true) << std::endl;

	std::cout << "vamos lá?" << std::endl;
	std::cout
        << boolprint(std::is_sorted(e.init(), e.end(), [](auto a, auto b) { return a < b; }))
        << std::endl;

	return 0;
}
```

> A maior parte do tempo que eu passei escrevendo esse arquivo de teste foi
> tentando passar uma referência de array para dentro da classe. No final eu
> desisti disso e simplesmente passei o clássico ponteiro mesmo.
> 
> Também sofri um pouco com as definições do iterador, pois precisava definir
> o operador `++` prefixado e eu fiquei confuso quanto aos operadores `==` e
> `!=`, qual que precisava definir, então acabei por definir ambos.

Aqui eu implementei:

- `Edges`: simplesmente para poder pegar o início e o fim
- `MeuIt`: o iterador em si

Para o comparador usei lambda mesmo.

O iterador tem:

- operador para definir quando cheguei no destino final
- algo para andar
- algo para pegar o elemento que ele está apontando

E, bem... basicamente... precisei seguir... uma interface? O contrato de
implementação era uma interface afinal! Mas note que era uma interface do tipo
"requisito nomeado", que por um tempo foi definido informalmente!

> Em C++ mais moderno (C++20) existem
> [`concepts`](https://en.cppreference.com/cpp/language/constraints) e
> [`requires`](https://en.cppreference.com/cpp/language/requires), que formam
> um tipo mais formalizado sobre o tipo de coisa que precisa ser passado. Mas
> mesmo assim nem todo "requisito nomeado" é fácil descrever em cima disso.
>
> O texto aqui ignora completamente essas novas funcionalidade da linguagem,
> lidando com o C++ um pouco mais antigo + extensão para lambdas.

E sobre o `Compare`... bem, a única coisa requerida era que ele fosse de certo
modo _callable_ passando dois argumentos retornando um booleano. E fizemos isso
em um lambda! Yay!

Tá, isso tudo foi explorando o que C++ tem sobre interfaces e classes
abstratas, e conseguimos provar que podemos usar "interfaces" em lugares mesmo
que a linguagem em si não tenha o construto determinado com subtipos e toda a
alegria esperada. O uso de templates do C++ (e aqui entram os operadores
relacionados ao tipo de dado passado) permite que façamos uso de sua API sem
precisar prender estruturalmente a um tipo (vulgo, há a possibilidade de se
usar tipagem estrutural nesses cenários).

A checagem do tipo de dados, para o templating do C++, é fornecido em tempo de
compilação. A linguagem gera, para cada novo tipo passado para o template, uma
função nova, tornando algo que era "genérico" e portanto "não instanciável"
como algo concreto. Então, ao usar o `is_sorted` no exemplo, o compilador irá
criar dinamicamente a função `is_sorted<MeuIt, "callable(int, int) -> bool">`
e, nesse momento vai tentar compilar o tipo para ver se deu certo. Devido a
essa natureza, o compilador não sabe a priori que tipo de dado será aceito
dentro do template, portanto só podendo validar no último momento.

> Ah, mas como que em C++ o genérico não é instanciável?

Porque C++ lida com espaços reservados de memória, e só usa
ponteiros/referência se o programador explicitamente pedir isso. Se não houver
um pedido por usar uma referência para um dado objeto, o objeto será passado
inteiro "por cópia". Por exemplo, se for uma struct assim

```c++
struct {
	int a, b, c;
	double x, y, z;
}
```

ela vai ocupa 40 bytes na memória. Então simplesmente o ato de colocar essa
`struct` na stack vai precisar de 40 bytes para botar o objeto. Passar ele para
uma função mais para baixo vai necessitar de 40 bytes lá. Enfim, e ele ocupa o
mesmo lugar em um template que, por exemplo, um `char`, que ocupa um byte
apenas.

Para instanciar a função, o compilador precisa saber exatamente o tamanho de
cada objeto para separar para ele o lugar adequado. Esse tipo de problema não
ocorre na JVM porque lá só se trabalha com referências (com poucas exceções aos
tipos primitivos, que não podem ser utilizados quando o método/classe menciona
o uso de generics).

Para Java, você pode usar sim de interfaces para determinar o que você
necessita, e colocar o método esqueleto na interface.

## Estado compartilhado

E se por acaso eu tiver um estado que é compartilhado entre os métodos chamados
pelo esqueleto? Esse é um caso de se advogar em favor da classe abstrata,
confere? Bem, não tão rápido, para falar a verdade.

Nesse tipo de situação _provavelmente_ usar uma variável com um estado
compartilhado seja o certo. Mas... (porque sempre tem um "mas"...) isso pode
gerar algumas complicações. Por exemplo, o estado precisa ser preservado entre
diversas chamadas? Ou é só uma conveniência enquanto está ali naquele template
method?

Se for só uma conveniência, isso indica que _provavelmente_ vai ser um
problema. Afinal, por que compartilhamos o estado? Para otimizar que índice?
Será que não é uma
[otimização prematura]({% post_url 2026/2026-09-01-ex-otimizacao %})?

O compartilhamento incorre no real risco sim de condições de corrida,
ainda mais se o objeto em questão for mutável. Se ele precisa estar limpo a
cada execução, talvez seja melhor gerar esse estado no esqueleto e passar ele
para as funções desejadas. Como se fosse um "estado" que vimos nas operações de
gathering e de collecting. Vide:

- [Criando um Collector novo para o Java]({% post_url 2026/2026-09-08-java-collector-criando-necessario %}),
- [Reinventando a roda: como escrever streams sem usar stream como base]({% post_url 2026/2026-05-06-reinventando-roda-java-streams %})
- [Java 24 chegou! Vamos reescrever streams com gatherers!]({% post_url 2025/2025-03-21-java-24-gatherers %})

De modo geral, ficaria assim:

```java
interface FactoryMethod {
	default Valor skeleton(Entrada1 in1, Entrada2 in2) {
		final var estadoCompartilhado = constroiEstadoInicial(/* potencialmente passando as entradas */);

		while (continua(estadoCompartilhado)) {
			final var saidaIntermediaria = processamento1(in1, in2, estadoCompartilhado);
			if (condicao(saidaIntermediaria)) {
				algoDiferente(in1, estadoCompartilhado);
			}
			processamento2(in2, estadoCompartilhado);
		}

		return computaSaida(estadoCompartilhado)
	}

	boolean condicao(Intermediario i);
	boolean continua(EstadoCompartilhado estado);

	Intermediario processamento1(Entrada1 in1, Entrada2 in2, EstadoCompartilhado estado);
	void processamento2(Entrada2 in2, EstadoCompartilhado estado);

	default EstadoCompartilhado constroiEstadoInicial() {
		// ...
		// outra alternativa seria construir diretamente o estado compartilhado, `new`
	}

	Valor computaSaida(EstadoCompartilhado estado);

	public record Intermediario(...) {
		// ...
	}

	public static class EstadoCompartilhado {
		// ...
	}
}
```

Aqui o estado compartilhado é compartilhado apenas durante a execuçào do
algoritmo, inexistindo fora dele. Ao usarmos a classe para guardar o estado
intermediário, esse estado eventualmente fica sujo entre duas rodadas. E se o
objeto em si for compartilhado entre threads a situação fica mais difícil
ainda!

O exemplo vou deveras complicado e abstrato de modo proposital, só para mostrar
a possibilidade do uso de estado compartilhado entre as diversas funções de um
template method baseado em interfaces com métodos default.

Deixei explícito também que os tipos `Intermediario` e `EstadoCompartilhado`
precisam ser conhecidos para quem for implementar essa interface. Afinal, se
vai manipular de modo _não opaco_ o objeto, esse objeto precisa ter um tipo
conhecido em Java.

# Interface para fazer strategy de enum

Você ter uma interface para usar uma espécie de strategy tá tudo bem. Agora,
usar isso como mecanismo a forçar a implementação de métodos em cada elemento
enumerável? Aí tem algo de errado.

O que eu vi foi algo assim:

```java
interface Strategy {
	Cat inTheHat();
}

enum AvailableStrategy implements Strategy {
	
	GREEN_EGGS {

		@Override
		public Cat inTheHat() {
			return new Cat(...);
		}
	},
	HAM {

		@Override
		public Cat inTheHat() {
			return new Cat(...);
		}
	}
}
```

E mais nenhuma estratégia distinta além das da enumeração. Ou seja, o
`Strategy` ali só está servindo para forçar cada item da enumeração a
implementar o método em aberto. Agora... isso não é necessário! Podemos indicar
na própria enumeração que ela tem um método em aberto para ser escrito pelos
itens enumerados! Inclusive foi visto algo parecido em
[Um parser em bash que identifica enums de um fonte Java]({% post_url 2022/2022-03-20-bash-java-enum-parser %}).
O que se pode fazer é declarar, no corpo principal da enumeração, que tem um
método abstrato/em aberto:

```java
enum AvailableStrategy {
	
	GREEN_EGGS {

		@Override
		public Cat inTheHat() {
			return new Cat(...);
		}
	},
	HAM {

		@Override
		public Cat inTheHat() {
			return new Cat(...);
		}
	};

	public abstract Cat inTheHat();
}
```

## Existe quando usar?

Tem uma situação em que faz sentido usar a interface: quando você quer tornar
aquele trecho testável com algo mais "controlado". Nesse tipo de situação, em
que hipoteticamente a estratégia da enumeração é mais complexa do que o
desejado em simples testes.

Nesse tipo de situação, sim, vale a pena usar a interface para pedir que a
enumeração implemente.

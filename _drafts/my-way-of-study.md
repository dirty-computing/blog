---
layout: post
title: "Como aprendo programação"
author: "Jefferson Quesado"
tags: programação
base-assets: "/assets/my-way-of-study/"
---

> Baseado na thread de Twitter [https://twitter.com/JeffQuesado/status/1502789758627590145](https://twitter.com/JeffQuesado/status/1502789758627590145)

{% katexmm %}
Todo dev deveria aprender a escrever testes. Talvez não necessariamente submeter seus testes para o controle de versão,
mas ao menos escrever os testes. Afinal, um feedback rápido vai indicar se você está indo para o canto certo ou não.
E as vezes fazer a setup todo "bonitinho" fim-a-fim daquele detalhe vai custar um tempo $X$, que será repetido $n$ vezes
até que o detalhe seja sanado. Portanto, num mundo perfeito, o dev gastaria _apenas_ $X\times n$ tempo para ajeitar o seu
detalhe. E se... pudêssemos reduzir $X$?

# Começando com programação competitiva

No começo, aprendi Pascal, no final do ensino fundamental e começo do ensino médio (não lembro mais de muita coisa, entretanto).
E aprendi dentro de um contexto de programação competitiva. Nesse contexto, somos apresentados a uma questão, um ou mais
exemplos de entrada, e as respectivas saídas.

A entrada vinha sempre da entrada padrão, normalmente o teclado. Então, se por acaso a questão exigisse uma quantidade $N$ de números,
eu deveria digitar todos os $N$ números que eu precisasse rodar um código. E, sinceramente? Esse é um processo muito lento e propenso
a erro. Ao menos uma vez esse processo precisaria ser feito. De resto, hipoteticamente seria bom se eu pudesse pegar aquela entrada
que foi digitada e passar adiante, né?

Como eu poderia otimizar esse tempo? Bem, vamos pegar um exemplo digno de programação competitiva?

## Círculos que se interceptam

São fornecidos dois círculos. Deseja-se saber se eles se interceptam ou não. Os cículos são forneceidos cada um em uma linha,
com 3 números inteiros `x`, `y`, `r`:

- `x,y` é a coordenada do centro do círculo
- `r` é o raio do círculo

Seu programa deverá dizer se os círculos descritos se interceptam em 2 pontos, em 1 único ponto ou se não se interceptam. A saída
deve ser a quantidade de vezes que os círculos se interceptam. Sempre serão forneceidos círculos distintos.

Seu programa deverá sair quando for fornecida a entrada `0 0 0 0 0 0`, a única hipótese de ter dois círculos coincidentes.

{% endkatexmm %}

### Exemplo de entrada e suas respectivas saídas

<style>
.problem-io tbody {
	font-family: monospace;
}
.problem-io table {
	width: 100%;
}
.problem-io thead {
	text-align: left;
}
.problem-io tbody td {
	vertical-align: top;
	outline: inset thin lightgrey;
}
</style>

<div class="problem-io">
<table>
	<thead>
		<tr>
			<th>Entrada</th>
			<th>Saída</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td>
			0 0 1<br/>
			1 1 1
			</td>
			<td>
			2
			</td>
		</tr>
		<tr>
			<td>
			0 0 1<br/>
			2 0 1
			</td>
			<td>
			1
			</td>
		</tr>
		<tr>
			<td>
			0 0 1<br/>
			3 2 1
			</td>
			<td>
			0
			</td>
		</tr>
		<tr>
			<td>
				0 0 0<br/>
				0 0 0
			</td>
			<td/>
		</tr>
	</tbody>
</table>
</div>

## Resolvendo o problema de perder tempo para resolver o problema

Bem, seja lá qual for o código a ser resolvido, as linguagens de programação competitiva normalmente envolvem
um passo de compilação e um passo de execução, como C (`gcc lalala.c -o lalala; ./lalala`), C++
(`g++ lalala.cpp -o lalala; ./lalala`) e Java (`javac lalala.java; java lalala`). Então, como automatizar isso?

Vou focar no C, por preferência e viés mesmo. Mas nesse sentido Java e C++ e Pascal não tem nada de demérito, nem
C de especial, apenas mais fácil para eu explicar aqui.

Eu vou ter um código fonte. Vou precisar compilá-lo a cada novidade. E vou precisar rodar (a priori) contra uma entrada
fornecida (de preferência armazenando o tempo). Então, comparar a saída obtida com o resultado esperado. Como posso
automatizar isso?

Bem, eu posso automatizar a detecção da diferença usando `diff`. No post sobre [identifcando enums Java com
bash]({% post_url 2022-03-20-bash-java-enum-parser %}) falei um pouco sobre isso. Preciso alimentar um arquivo com a
saída obtida do programa. Chamemos essa saída de `circulos.out` e o resultado esperado de `circulos.res`.

Então, como gerar essas coisas? Vamos precisar de um `circulos.res` que é informado pelo humano uma única vez.
Caso ele seja informado erroneamente, seria bom fazer o teste de novo. Além disso, vou precisar do `circulos.out`,
que será gerado pelo executável `circulos` usando como entrada `circulos.in`. E finalmente o `circulos` depende de
seu arquivo fonte `circulos.c`. Como encaixar tudo isso?

![Grafo de dependência de cada ponto. O fonte é compilado no executável, que por sua vez recebe a entrada
e gera a saída, que então é comparada com o diff com o resultado esperado]({{ page.base-assets | append: "dependency.png" | relative_url }})

Ok, bacana, mas e agora? E se a gente tivesse algo para descrever esse grafo de dependência e como gerar um recurso a partir
de seus requisitos? Isso automatizaria o processo inteiro de teste, ficaria apenas com o programador a necessidade de escrever
o código-fonte e fornecer a entrada com a saída esperada.

E se eu disser que isso já existe? É o chamado `Makefile`, e ele trabalho com grafos direcionado acíclicos. Além disso, ele permite
inferência para gerar a informação. Sem entrar muito no mérito do `Makefile`, ficaria assim o caso específico do problema `circulos`:

```makefile
diff_circulos: circulos.out circulos.res
	diff circulos.out circulos.res

circulos.out: circulos circulos.in
	./circulos < circulos.in > circulos.out

circulos: circulos.c
	gcc circulos.c -Wall -o circulos
```

E se eu disser que, em cima dessas mesmas 3 regras, posso abstrair para todos as questões?

```makefile
diff_%: %.out %.res
	diff $$.out $$.res

%.out: % %.in
	./$$ < $$.in > $$.out

%: %.c
	gcc $< -Wall -o $@
```

E que só precisaria acrescentar um pouquinho para funcionar para C++, por exemplo?

```makefile
%: %.cpp
	g++ $< -Wall -o $@
```

Assim eu evito ficar pensando muito no mérito das coisas ao redor de resolver a questão:

- compilar o fonte?, perda de tempo, deveria minimizar a quantidade de vezes que faço isso
- digitar a entrada?, perda de tempo, propenso a erro, deveria minimizar a quantidade de vezes que faço isso
- verificar a saída?, perda de tempo, propenso a erro, deveria minimizar a quantidade de vezes que faço isso

Simplemente digito meu código. Então faço `make diff_circulos`, e a saída me diz se eu fiz certo ou não. Posso focar
no que interessa, que é resolver a questão, automatizando de maneira confiável o trabalho repetido _no brainer_ que
é fazer os passos repetitivos necessários para se testar o programa.

E ainda tem um detalhe que me intriga. Eu deveria ser capaz de ver o tempo que passou exxecutando o programa
para ter alguma noção se por acaso, ao submeter a solução, ele não iria dar o famigerado _Time Limit Exceeded_, TLE.
Então, como manipular para ver o tempo? Bem, o Unix nos dá a ferramenta adequada, `time`. E só preciso alterar
a regra que contém a execução do programa, todo o resto se mantém idêntico:

```makefile
%.out: % %.in
	time 	./$$ < $$.in > $$.out
```
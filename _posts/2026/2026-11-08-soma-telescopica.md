---
layout: post
title: "Somando logs: uma questão de vestibular"
author: "Jefferson Quesado"
tags: matemática indução
base-assets: "/assets/soma-telescopica/"
---

Recentemente vi uma postagem no Instagram que falava de uma soma de logaritmos:

{% katexmm %}

$$
\log_2\left(1 + \frac{1}{1}\right) + \log_2\left(1 + \frac{1}{2}\right) + \cdots + \log_2\left(1 + \frac{1}{127}\right) = ?
$$

Então, como resolver?

O primeiro passo que imaginei foi: como eu consigo representar isso em forma de
um somatório? Bem, vamos lá. Cada termo é fornecido na forma

$$
\log_2\left(1 + \frac{1}{n}\right)
$$

então essa soma seria variar esses termos de 1 até 127:

$$
\sum_{n = 1}^{127}\log_2\left(1 + \frac{1}{n}\right)
$$

E, bem, uma outra maneira de escrever $1 + \frac{1}{n}$ para $n \not= 0$ é
$\frac{n+1}{n}$. Então eu posso reescrever o somatório como:

$$
\sum_{n = 1}^{127}\log_2\left(\frac{n+1}{n}\right)
$$

Agora, vamos pegar a propriedade que usamos no artigo
[Somando logs: alternativa para agregar multiplicação em SQL]({% post_url 2026/2026-01-04-soma-logs %}):
o log da multiplicação de dois números é a soma do log desses números. E
tomemos dois números consecutivos: $a$ e $a+1$.

$$
\log_2\left(\frac{a+1}{a}\right) + \log_2\left(\frac{a+2}{a+1}\right)
$$

Dentro da condição de existência desse problema, o número $a$ arbitrário é um
inteiro estritamente positivo (afinal, ele vai ser algo entre 1 e 127). Assim,
podemos tranquilamente transformar essa soma em uma multiplicação:

$$
\log_2\left(\frac{a+1}{a} \times \frac{a+2}{a+1}\right)
$$

E, bem como $a$ é estritamente positivo, eu tenho que $a+1$ também será. Logo,
eu posso simplificar essa conta ao remover o fator $a+1$ do numerador do número
do lado esquerdo e do denominador do lado direito, ficando só com isso aqui:

$$
\log_2\left(\frac{a+2}{a}\right)
$$

E, bem, em forma de somatório fizemos isso:

$$
\sum_{n=a}^{a+1} \log_2\left(\frac{n+1}{n}\right) = \log_2\left(\frac{a+2}{a}\right)
$$

Podemos usar aqui uma indução matemática? Vejamos... vamos supor que a soma de
$a$ até $a+q$ de $\log_2\left(\frac{n+1}{n}\right)$ seja
$\log_2\left(\frac{a+q+1}{a}\right)$. Será que isso vale para $a+q+1$?

Supondo que o passo anterior até $a+q$ seja válido, então podemos desmembrar o
somatório em dois pedaços:

$$
\sum_{n=a}^{a+q+1} \log_2\left(\frac{n+1}{n}\right) = \sum_{n=a}^{a+q} \log_2\left(\frac{n+1}{n}\right) + \log_2\left(\frac{a+q+2}{a+q+1}\right) =
\\
\log_2\left(\frac{a+q+1}{a}\right) + \log_2\left(\frac{a+q+2}{a+q+1}\right) \therefore \\
\sum_{n=a}^{a+q+1} \log_2\left(\frac{n+1}{n}\right) = \log_2\left(\frac{a+q+2}{a}\right) \square
$$

Com isso, temos a hipótese indutiva (que o somatório de $a$ até $b$ vai ser
igual a $\log_2\left(\frac{b+1}{a}\right)$) o passo indutivo em que
partimos desse ponto e somamos até $b+1$ obtendo
$\log_2\left(\frac{b+2}{a}\right)$ tal qual a hipótese indutiva e temos o
caso base da soma de $a$ com $a+1$ resultando na fórmula da hipótese indutiva
$\log_2\left(\frac{a+2}{a}\right)$.

Logo, o somatório original:

$$
\sum_{n = 1}^{127}\log_2\left(1 + \frac{1}{n}\right)
$$

Que pode ser reescito como

$$
\sum_{n = 1}^{127}\log_2\left(\frac{n+1}{n}\right)
$$

Ao aplicar a fórmula que descobrimos fica:

$$
\log_2\left(\frac{127+1}{1}\right) = \log_2 128 = 7
$$

E tudo isso derivado simplesmente do fato de que a soma de logs é o log da
multiplicação.

# Uma variante do problema

Eu também me deparei com uma variante dessa questão, em que ela se apresentava
assim:

$$
\log_2\left(1 - \frac{1}{2}\right) + \log_2\left(1 - \frac{1}{3}\right) + \cdots + \log_2\left(1 - \frac{1}{128}\right) = ?
$$

Vamos fazer os mesmos processos? Aqui a soma vai de 2 até 128 do seguinte termo:

$$
\log_2\left(1 - \frac{1}{n}\right)
$$

Ou seja, a expressão do começo começo pode ser descrita como o seguinte somatório:

$$
\sum_{n=2}^{128}\log_2\left(1 - \frac{1}{n}\right)
$$

Ao fazer essa subtração, temos que o termo fica assim:

$$
\frac{n-1}{n}
$$

Ou seja:

$$
\sum_{n=2}^{128}\log_2\left(1 - \frac{1}{n}\right) = \sum_{n=2}^{128}\log_2\left(\frac{n-1}{n}\right)
$$

Pegando os valores para somar $a$ e $a+1$ (para $a \ge 2$):

$$
\log_2\left(\frac{a-1}{a}\right) + \log_2\left(\frac{a}{a+1}\right) = \log_2\left(\frac{a-1}{a+1}\right)
$$

Vou colocar minha hipótese indutiva que o somatório de $a$ até $a+q$ seja:

$$
\sum_{n=a}^{a+q}\log_2\left(\frac{n-1}{n}\right) = \log_2\left(\frac{a-1}{a+q}\right)
$$

Então, o passo indutivo seria sair disso para até $a+q+1$:

$$
\sum_{n=a}^{a+q+1}\log_2\left(\frac{n-1}{n}\right) =
\sum_{n=a}^{a+q}\log_2\left(\frac{n-1}{n}\right) + \log_2\left(\frac{a+q}{a+q+1}\right) =
\log_2\left(\frac{a-1}{a+q}\right) + \log_2\left(\frac{a+q}{a+q+1}\right) = 
\log_2\left(\frac{a-1}{a+q+1}\right)
$$

Como isso vale para $a = 2$:

$$
\sum_{n=2}^{2}\log_2\left(\frac{n-1}{n}\right) = \log_2\left(\frac{2-1}{2}\right)
$$

Temos que nossa indução está demonstrada. Logo, aquele somatório é:

$$
\sum_{n=2}^{128}\log_2\left(\frac{n-1}{n}\right) =
\log_2\left(\frac{2-1}{128}\right) = 
\log_2 2^{-7} = -7
$$

{% endkatexmm %}

# Soma telescópica?

Buscando mais informações sobre essa questão, acabei por encontrar o termo
"série telescópica". Eu queria colocar uma URL bacana para este artigo, e na
minha cabeça só vinha "soma-logs", porém seria o mesmo exato slug que usei no
artigo de Janeiro: ["soma-logs"]({% post_url 2026/2026-01-04-soma-logs %}).

Mas por que o nome "telescópico"?

Bem, visualize um telescópio. Pode ser desses que fazem a representação de
piratas na era da pirataria:

![Telescópio pirata]({{ page.base-assets | append: "250px-Spyglass.png" | relative_url }})

> [Hydrargyrum](https://commons.wikimedia.org/wiki/File:Spyglass.png),
> [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0), via Wikimedia
> Commons. Rotacionado e invertido horizontalmente para efeitos de encaixe na
> página, sem outras edições.

Note que ele está expandido, porém seus componentes se encaixam um no outro. E,
devido a esse encaixe, podemos retrair ele completamente, até que fique
minúsculo, do tamanho de apenas um segmento. Essa capacidade de "remover" os
elementos intermediários e fazer esse colapso é o que dá a origem à alcunha
"telescópica" de uma série: os elementos intermediários dela se cancelam e se
"unem". E no caso usei especificamente "soma telescópica" porque esta série em
específica era uma soma.

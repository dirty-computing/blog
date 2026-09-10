---
layout: post
title: "Função contínua e validação de cadastro"
author: "Jefferson Quesado"
tags: matemática java engenharia-de-software cálculo limite
base-assets: "/assets/funcao-continua-validacao/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Sabe aqueles contextos que as vezes você pensa "por que diabos eu aprendi
isso?" Então, tipo [logaritmos]({% post_url 2026/2026-01-04-soma-logs %})?

Pois é. Aqui venho falar de um caso em que foi necessário recuperar outros
conceitos matemáticos que as pessoas acham tedioso saber. Limites e funções
contínuas. E tudo isso por conta daquilo que dizem que é a função do engenheiro
de software médio: mexer com cadastros!

Mas esse era um cadastro bem particular que sim, envolvia limites... mas
principalmente envolvia funções contínuas.

# O que era o cadastro em si?

Dizem por aí que a vida de um engenheiro de software médio é só escrever CRUD.
E, bem, esse era um caso que realmente se precisava escrever um simples CRUD. E
esse CRUD era algo já não tão absurdamente simples, mas também não era algo
fora do conhecimento da equipe: cadastrar várias faixas de valor, e o valor
iria eventualmente depender de algum fator externo.

Se isso soa ligeiramente familiar com o que descrevi nas faixas de preço que
escalonam de acordo com a quantidade em
[RPN como um sistema de plugins, ou minha primeira proto-linguagem de programação]({% post_url 2026/2026-08-03-rpn-plugin %}),
é porque realmente tem uma pegada semelhante. E isso deixou toda a equipe muito
confortável.

O cadastro específico era sobre precificação de frete. Especificamente frete
como função do peso. E para isso, de acordo com o peso total do pedido, o valor
do frete seria diferente e ele seguiria faixas distintas.

O cliente que requisitou isso disse que dependendo do que eles iriam resolver
de como alocar o frete (saltar de uma faixa para outra pela quantidade de peso)
poderia ter um custo fixo diferente para aquela faixa.

Então basicamente a gente já tinha um arcabouço para pensar em como os dados
seriam trabalhados:

{% katexmm %}
$$
faixa:peso \mapsto \left\{ fixo, fator\right\}\\
preço\left(peso\right) = fixo + peso\times fator |
\left\{ fixo, fator\right\} \Leftarrow faixa\left(peso\right)
$$


Lidar com faixas era algo bem conhecido da equipe: no lugar de modelar o
problemático "a faixa precisa definir $\left[ min, max \right)$ para valer" e
ter de lidar com todas as consequências de alterações de dados que tornariam
isso uma função parcial, conseguimos explicar ao setor de negócios que cada
elemento da faixa precisaria apenas definir o seu valor mínimo, e com isso
implicitamente já temos o valor máximo da faixa bem definido (potencialmente o
$\infty$, mas tudo bem, não há limite superior de peso)!

> Precisa de um _reminder_ sobre funções parciais e completas? Vê esse artigo
> aqui
> [Criando mapas "apenas" com funções em java]({% post_url 2023/2023-08-21-java-map-stateless %})
> que eu recapitulo isso pra você!

Dado isso, banco para o resgate modelado, aplicação bem modelada, piloto já
funcionando, vamos para a parte mais chata... cadastro.

O usuário insere o peso mínimo, o valor fixo, o fator $\frac{\texttt{R\$}}{kg}$
e ainda vê perante as outras faixas onde que vai encaixar. E agora começam as
inconsistências... cada faixa deveria ser única, o que fazer quando há duas
faixas com o mesmo "peso mínimo"?

E outra, o que fazer se o gráfico da função de frete for algo assim?

![Função definida por diversas partes lineares com diversas descontinuadades]({{ page.base-assets | append: "descontinuo.png" | relative_url }})

O que devemos fazer com esse "salto" no valor do frete?

{% endkatexmm %}

## Por que começar pela aplicação do dado?

Perdão pela tangente e fugir da parte matemática, mas acho que isso aqui é uma
parte inportante na vida de um desenvolvedor.

Aqui é uma filosofia minha do desenvolvimento de software: normalmente o dado
não existe em um vácuo. O dado do cadastro existe para causar algum efeito
colateral no sistema (normalmente). Por exemplo, em um sistema de vendas, o
dado cadastrado da venda vai gerar:

- uma nota fiscal
- um envio de mercadoria
- um título em aberto
- outras coisas

E tudo isso é importante para o como eu vou guardar e manipular o dado. Não é
simplesmente uma informação fria sem contexto, em que a informação é o ponto
final do sistema.

Por exemplo, nesse mesmo sistema de vendas existia um módulo de "contagem".
Essa contagem era feita pelo vendedor, que precisava olhar o estoque que o
cliente tinha de um produto. E para que fazer essa contagem? Para que, durante
a venda, o sistema informe o vendedor o quanto seria necessário vender para que
o estoque do cliente retorne ao "estado anterior".

Por sinal, essa funcionalidade em si foi requisitada por uma panificadora que
tinha como cliente mercadinhos, e ela também tinha uma coisa que era a troca de
mercadoria vencidas: o vendedor recolhia os pães e bolos vencidos e trocava por
novos (tempo de validade de prateleira dos produtos da panificadora era bem
volátil mesmo, poucos dias). E essa troca precisa ser feita em um pedido
separado por questões fiscais.

Então originalmente o vendedor precisava fazer 3 operações distintas:

- criar um pedido de troca informando quais itens foram trocados, e o quanto de
  cada item
- fazer uma contagem de quanto o cliente possuía de cada tipo de produto
  distinto
- em cima dessa informação de quantos produtos o cliente detinha na prateleira,
  vender para o cliente de modo que ele mantivesse o mesmo estoque que tinha na
  contagem anterior

E, bem, o sistema era bem sacal para iniciar ou editar um pedido. No caso do
aplicativo para dispositivo móvel, só se podia trabalhar em um pedido por vez,
e não era barato sair da tela de pedidos para fazer outra coisa, como por
exemplo contar os produtos no cliente! Só era possível sair do pedido
salvando-o ou descartando as últimas alterações. E fazer a contagem era outra
tela, e fazer um pedido de venda era necessário começar um outro pedido com
outro tipo de pedido.

Então o fluxo que o aplicativo fornecia ao vendedor seria:

- primeiro uma tour pelo estoque para fazer o pedido de troca
- então uma nova tour para fazer a contagem dos produto
- finalmente validar com o cliente o que o vendedor deveria vender o suficiente
  para retornar à quantia da última contagem

Bem, isso significa que o vendedor vai precisar passar pelo mesmo setor ao
menos duas vezes, uma para identificar os produtos vencidos para trocar e outra
para fazer a contagem do quanto o cliente tem no estoque. Ou isso ou o vendedor
faria com uma prancheta a contagem e a identificação de produtos vencidos, o
que particularmente derrota a ideia de ter um software para facilitar a vida.

Então para esse caso eu fiz uma proposta: e se, na parte de vendas, fosse
oferecida uma UI alternativa que daria ao vendedor a opção de, ao selecionar um
produto específico, fazer a contagem daquela produto, a marcação de quantos ele
precisa trocar e também mostrar a sugestão de venda junto da text box para
inserir o quanto vai vender de fato!

E assim o pedido de troca (com o tipo fiscal adequado para troca) era criado
por baixo dos panos, o dado da contagem era coletado e também utilizado para
gerar a nova venda! E tudo isso sem precisar ficar acessando módulos distintos
do mesmo sistema, apenas manipulando o dado de maneira fluida!

Só foi possível propor isso porque o intuito do dado coletado no ato da
"contagem" passou a ter significado. E com o significado, e sua ação no
sistema, foi possível modelar um fluxo de uso que simplificava a vida do
usuário.

Ah, e como efeito colateral a tela de "contagem" que não era uma funcionalidade
tão comum de ser usada e portanto testada/expandida ganhou a funcionalidade de
pesquisa por família de produto/nome, coisa que não existia na tela tradicional
do módulo de contagem (que antecede a minha chegada na empresa, diga-se de
passagem) mas que era necessária existir na tela de "venda".

Saber o como o dado de um CRUD vai impactar no uso do sistema (ou no de
sistemas conectados ao sistema em que se está trabalhando) permite que se faça
o desenvolvimento do sistema já pensando no uso, para então ter isso
devidamente modelado para poder ter noção do que importa para o cadastro (como,
no caso das faixas, deixar visualmente ordenado por "peso mínimo"). Além disso,
quando o alvo do dado não é a coleta pela coleta, é sempre possível trabalhar
com dados inseridos no banco via outras alternativas que não o cadastro do
usuário final diretamente. Em diversos casos eu já vi que foi feita a inserção
do dado no banco pela intenção do cliente para só então permitir que o usuário
final pudesse fazer a inserção direta e autônoma.

## As regras de validação do cadastro

Cadastrar com faixas já era rotina da vida. As faixas seriam um campo a mais no
frete como um todo, então posso focar em validar aqui apenas detalhes das
faixas. Como visto anteriormente, tinha duas validações importantes que
deveriam ser feitas:

- duas faixas com o mesmo mínimo (estado inconsistente)
- descontinuidade na função (pedir confirmação do usuário)

Existia ainda uma outra regra importante: a primeira faixa precisa começar do
zero, caso contrário não tenho uma função completa.

Tem a questão de eventualmente o frete resultar em um valor negativo, mas isso
importa? Bem, para alguns clientes não, eles esperavam esse tipo de
comportamento ao alterar o tipo do frete de CIF para FOB, então fretes
negativos são algo que podem ser esperados, não uma validação forte a ser feita
independente de contexto.

Ah, o uso de faixas era tão tradicional que já existia um componente que se
auto-ajustava em cima das quantidades, se mantendo sempre ordenado com o menor
em cima, então quem fosse desenvolver essa parte do CRUD nem precisaria se
preocupar com implementar isso, apenas em usar.

Dito isso, passei a tarefa para a desenvolvedora júnior da equipe. E batemos na
matemática...

# Função contínua

O que é uma função contínua? Bem, uma função é contínua se eu "posso desenhá-la
sem tirar o lápis do papel". Isso significa que o domínio precisa ser um
intervalo real e que, também, uma propriedade muito interessante seja
satisfeita:

{% katexmm %}
$$
\forall d \in \left(a,b\right), \lim_{x \rightarrow d}F(x) = F(d)
$$

Implicitamente isso quer dizer algumas coisas:

- o valor da função é bem definido para todo ponto do domínio
- a função tem limite para todo elemento do domínio
- o limite da função para um elemento do domínio é o valor do limite
- o domínio da função é um intervalo só

Agora, em cima dessas 4 imposições, será que tem algo interessante? Alguma
propriedade que possamos usar para facilitar a vida? Na verdade, tem sim!

Funções polinomiais são resolvidas para todo argumento real! Ou seja, o domínio
de um polinômio é a reta real! E retas são uma espécie de polinômio, polinômio
do primeiro grau na forma $a\times x + b$. Ou seja, sabemos que o domínio vai
ser sim um intervalo.

Agora, outra propriedade interessante é que polinômios são bem comportados:
o valor do polinômio para um ponto `d` qualquer é igual ao valor do seu limite:
$P(d) = \lim_{x \rightarrow d} P(d)$. Então isso significa que, dentro de cada
componente, tudo está bem feito! Só falta garantir que o limite da função vai
sempre existir. E, bem, como que posso fazer isso?

Estamos lidando aqui com função de um único parâmetro. Então, para o limite
existir em um ponto `p`, eu preciso satisfazer a seguinte condição:

$$
\lim_{x\rightarrow p^-}f(x) = \lim_{x\rightarrow p^+}f(x)
$$

O limite da função quando o parâmetro tende a `p` vindo pela esquerda precisa
ser igual ao limite da função quando o parâmetro tende a `p` vindo pela
direita. O que significa que só vai ser necessário verificar as bordas dos
componentes!

Para uma entrada com `n` faixas e indexada com 0 como primeiro elemento, onde
`p_i` indica o peso mínimo da `i`-ésima faixa e $F_i(p)$ o valor que a
`i`-ésima faixa vale para um peso `p` qualquer, isso aqui precisa ser verdade:

$$
\forall i \in \left(0, n\right), F_{i-1}(p_i) = F_i(p_i)
$$
{% endkatexmm %}

Note que o intervalo de verificação é aberto em `0` porque não preciso
verificar a primeira faixa (afinal, indexada por 0) com o que vem antes, pois
como é a primeira faixa não tem nada que venha antes. E é aberto em `n` porque,
apesar de ter `n` elementos, como é indexada em `0`, o elemento de índice `n`
está fora dos intervalos fornecidos.

## Validando em Java

Temos uma lista de faixas. Já se é sabido que essa lista tem duas
características importantes:

1. ela não tem duas faixas com o mesmo `pesoMinimo`
2. ela está em ordem de `pesoMinimo`

Vamos rapidamente modelar aqui como que seria essa faixa de frete em Java?

```java
public class FaixaFrete {

    private final double pesoMinimo;
    private final double fixo;
    private final double fator;

    public FaixaFrete(double pesoMinimo, double fixo, double fator) {
        this.pesoMinimo = pesoMinimo;
        this.fixo = fixo;
        this.fator = fator;
    }

    public double pesoMinimo() {
        return this.pesoMinimo;
    }

    public double fixo() {
        return this.fixo;
    }

    public double fator() {
        return this.fator;
    }
}
```

{% katexmm %}

> Tá, tá, eu sei, eu disse em outra postagem que eu era obcecado em usar
> `BigDecimal` para tudo
> ([Pequeno exemplo de otimização]({% post_url 2026/2026-09-01-ex-otimizacao %})),
> mas isso continua sendo verdade e a implementação real usava `BigDecimal`
> para esse fim, mas para efeitos de leitura usar `double` como fatores de uma
> função $f:\mathbb{R}\mapsto\mathbb{R}$ não tem conotação negativa, deixe
> estar.

{% endkatexmm %}

Como fazemos para calcular o valor do frete? Que tal definir uma função aí?

```java
public class FaixaFrete {
    // ,,,

    public double valorFrete(double peso) {
        return fixo + peso*fator;
    }
}
```

Até aqui, tudo bem. Agora precisamos pegar todos os elementos de `n-1` até 0
(aberto). Para iterar assim, posso fazer o seguinte loop:

```java
// List<FaixaFrete> faixas = ...;
List<Discontinuidade> discontinuidades = new ArrayList<>();
for (int i = faixas.size() - 1; i > 0; i++) {
    final FaixaFrete faixaAtual = faixas.get(i);
    final FaixaFrete faixaAnterior = faixas.get(i-1);

    final double pesoMinimoFaixaAtual = faixaAtual.pesoMinimo();

    final double valorFreteEsq = faixaAnterior.valorFrete(pesoMinimoFaixaAtual);
    final double valorFreteDir = faixaAtual.valorFrete(pesoMinimoFaixaAtual);

    if (valorFreteEsq != valorFreteDir) {
        // indicar ponto de descontinuidade
        discontinuidades.add(
            Discontinuidade.x(pesoMinimoFaixaAtual)
                           .limEsq(valorFreteEsq)
                           .limDir(valorFreteEsq));
    }
}

return discontinuidades;
```

Assim, temos todos os pontos de discontinuidade disponíveis. Com as informações
em mãos, fica com o usuário se ele deseja continuar com o cadastro ou não.

# Recapitulando

O cliente tinha um requisito, que precisava calcular o frete a partir do peso
do pedido. Porém, para esse cliente o peso do pedido faria com que a faixa de
precificação do frete fosse alterada.

{% katexmm %}

As faixas de frete como um todo eram uma maneira de encodar uma função total
em $f:\mathbb{R}^+\mapsto\mathbb{R}$ através de várias funções parciais,
$I\subseteq\mathbb{R}^+, f_i:I\mapsto\mathbb{R}$.

As funções parciais $f_i$ são todas lineares. Sem o devido cuidado, a função
total $f$ pode apresentar pontos de descontinuidade, em que a função "quebra",
como no gráfico abaixo:

![Função definida por diversas partes lineares com diversas descontinuadades]({{ page.base-assets | append: "descontinuo.png" | relative_url }})

Uma função descontínua não é desejada de maneira geral, então _devemos_
perguntar ao usuário se aquilo está certo mesmo, se o usuário deseja mesmo esse
resultado.

Como as funções parciais são todas polinômios, não preciso me preocupar com o
miolo delas, apenas em como elas se encaixam uma na outra.

{% endkatexmm %}
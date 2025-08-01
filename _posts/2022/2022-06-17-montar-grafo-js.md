---
layout: post
title: "Montando uma árvore em JavaScript, desafio do Nicoloso"
author: "Jefferson Quesado"
tags: javascript grafos árvore
base-assets: "/assets/montar-grafo-js/"
---

O Nicoloso ([@nicolaslopess__](https://twitter.com/nicolaslopess__)) surgiu com o seguinte código e perguntou se
estou bacana:

```js
const buildTree = (arr, id = null) =>
  arr
    .filter((item) => item.parent_id === id)
    .map((item) => ({ ...item, children: buildTree(arr, item.id) }));
```

Não percebi nenhum contexto prévio nisso.

# Funcionamento atual

Pelo que deu para perceber, a ideia é adicionar, em um determinado item, os filhos dele. Um item tem identificador `.id` e
o seu pai tem identificador `.parent_id`. Portanto, necessita-se criar o elo na ordem inversa, do `parent` anexar nele
seus filhos `.children`.

A ideia aqui é: a primeira consulta é com o `id` nulo, portanto passa pelo `filter` apenas aqueles nós que são raízes. Então,
mapeamos a raiz atual em um _shallow-clone_, porém agora com a propriedade `.children`, que por sua vez é determinada pela montagem
recursiva, passando o `.id` do item atual.

# Complexidade calculada atual

{% katexmm %}

Para cada chamada dessa função, será feito um novo _fullsearch_, já que o `array` é passado sem modificções para baixo. Portanto,
a cada nível são executados $O(n)$ operações (pelo menos um filtro e talvez um mapeamento).

Então, a questão que sobra é: quantas chamadas dessa função serão feitas? Vamos supor que, no caso médio, todos os nós pertencem a uma
única árvore. Nessa situação, a primeira busca passará por todo o vetor e enontrará um único nó. Então, para esse nó, será executada
outra _fullsearch_. Se o nó pertence à árvore, então eventualmente ele terá um `parent_id` que coincidirá com o `id` do item que está
sendo analisado. Assim sendo, serão executadas $n$ _fullsearches_, portanto $O(n^2)$.

Caso seja fornecido uma floresta, e todos os itens pertençam à floresta, o mesmo raciocínio se aplica. Os itens que não desencadearão novas
chamadas _fullsearch_ são aqueles que apontam para pais que estão fora do alcance de todas das raízes dispostas no vetor.

# _Shortcomings_ da solução atual

A solução consegue montar toda e qualquer árvore, em toda e qualquer floresta. Porém, e se for tentado algo não árvore? Ou cujos
componentes menores não sejam árvores?

Pela definição de árvore, temos que:

1. toda árvore possui uma raiz única
2. a raiz não tem nó pai
2. todo nó que não é a raiz tem um e exatamente um único nó pai
3. a árvore é uma estrutura conexa

Uma floresta, por sua vez, se difere de árvore por ser uma coleção de árvores. Como podemos lidar com florestas, a limitação de ser conexa pode ser ignorada
do algoritmo pois ele está montando uma coleção de árvores. E pela definição da estrutura de dados, o nó tem no máximo um único pai (ou pode não ter pai).

E o que garante a restrição de que a árvore possui uma raiz? Na real, a única coisa que garante isso é o valor padrão passado como argumento de `id`, a
ser executado unicamente na primeira vez que vai trazer em si o que se necessita. Se for muito desejável evitar que o programador coloque como ponto de partida
outr identificador, podemos deixar exposta uma API pública com apenas um único parâmetro e, internamente, ter a descrição recursiva:

```js
const buildTree = (arr) => {
  const __buildTree = (__arr, id) =>
    arr
      .filter((item) => item.parent_id === id)
      .map((item) => ({ ...item, children: __buildTree(__arr, item.id) }));
  return __buildTree(arr, null);
}
```

Mas, mantendo a API original, o que acontece se for passado um `id` de um nó existente? Por exemplo, se for o nó da raiz?

Tome o seguinte grafo:

![Nó com id 13 é pai dos nós de ids 15 e 16, por sua vez o nó de id 15 é pai do nó de id 17 e o nó de id 16 é pai do nó de id 18]({{ page.base-assets | append: "tree.svg" | relative_url }})

E se a busca fosse feita buscando o identificador 13? Seriam retornados os nós de ids 15 e 16, junto de seus respectivos filhos. Como a busca parte desse ponto, ele não
consegue reconhecer eventual pai do nó 13.

Mas e se... a estrutura fosse outra? Como abaixo?

![Nó com id 13 é pai dos nós de ids 15 e 16, por sua vez o nó de id 15 é pai do nó de id 17 e o nó de id 16 é pai do nó de id 18, e o nó 18 é pai do nó 13]({{ page.base-assets | append: "ring.svg" | relative_url }})

Bem, aqui, neste caso específico, teríamos problemas... Vamos procurar aqueles cujo nó pai é o 13. Quem encontramos? O 15 e o 16.

Repetindo a busca pelo 15, achamos o 17. Repetindo pelo 17, chegamos ao fim desse ramo.

Mas do 16, encontramos o 18. E advinha quem é o nó que tem como pai o nó 18? Isso mesmo, o nó 13. Nesse momento será reiniciada a busca pelo nó
13 como pai. E eventualmente chegará nele de novo e tudo se repete.

# Complexidade teórica

A atividade basicamente consiste de:

- pegar um nó (chamemos esse nó de $N$)
- achar o nó pai de $N$, portanto $P \in nodes, P.id = N.parent\_id$
- adicionar a aresta $P\rightarrow{}N$ à coleção $P.children$
- repetir isso $\forall N \in nodes$

A adição da aresta à coleção vou assumir ser de complexidade constante, $O(1)$. A busca de um elemento dentro de um conjunto,
baseado em uma característica sua... bem, esse problema pode ser tratado de maneira linear (esgotar todas as possibiidades buscando
todos os elementos em busca daquele da característica desejada), logarítmica (se a característica for organizável lexicograficamente,
podemos sempre compara dois objetos dessa categoria e determinar quem é maior/menor ou se são iguais, pondo numa árvore de busca)
ou de modo "armotizado" constante (colocando numa tabela de _hash_ cuja chave é essa característica desejada, por exemplo).

Então, como tem a possibilidade da busca pela tabela de espalhamento, podemos considerar que buscar o nó $P \in nodes, P.id = N.parent\_id$
é uma operação oracular, portanto $O(1)$.

Como isso precisa ser feito para todos os elementos, temos então $\Theta(|nodes|)$ advindo do laço. Dado que são necessárias para cada
iteração buscar e fazer o _append_, operações de tempo constante. Daí, $\Theta(|nodes|)$ operações de $O(1)$, portanto o tempo de execução
teórico para isso é $O(|nodes|)$.

Então, para isso funcionar, primeiro é necessário ter essa estrutura de busca montada, mas não há nada além de um array. Então, isso fica
por nossa conta. Assim, precisamos passar os $|nodes|$ elementos para dentro da estrutura. Se fosse uma árvore, o tempo necessário
para se inserir um elemento seria $O(log(|nodes|))$, mas em um mapa esse tempo é aproximadamente $O(1)$ (em _hashtables_ essa é uma boa aproximação,
dada amortização, mas existem situações em que inserir um novo elemento dispara em toda uma reestruturação da estrutura de dados). Daí, o tempo
necessário para se montar a estrutura é de $O(|nodes|)$.

Portanto, o algoritmo para a execução menor possível precisa ter um momento de pré-computação (que gasta $O(|nodes|)$) e, então, fazer mais $O(|nodes|)$ operações
para a montagem do grafo.

# Código na menor complexidade usando mapa

De modo geral, o código teria a seguinte forma:

```js
def monta_arvore(arr) {
	// mantendo os dados externos intactos
	const nodes_arvore = arr.map((node_ori) -> { ...node_ori, children: [] })
	
	// criando o mapa com base no id do nó
	const mapa = cria_mapa(nodes_arvore, (node) -> node.id)
	
	
	// povoa os filhos
	nodes_arvore.forEach((nodo) -> mapa[nodo.parent_id].children.push(nodo))
	return nodes_arvore.filter((nodo) -> nodo.parent_id == null)
}
```

Aqui está se supondo que o nó pai sempre irá existir. Essa suposição é violável, então seria adequado validar que o nó resgatado de fato existe.
Como lidar com isso? Uma alternativa é colocar um clássico `if` para validar a existêcia do `parent`, mas podemos fazer de outro jeito:

- transforma `node` na dupla `[node, parent]`, buscando do mapa quem seria o `parent`
- filtra `parent`s vazios (isto é, aqueles que são mencionados porém não estão de fato no mapa)
- foreach, `parent.children.push(node)`

Ficaria uma vasculhada pelos nós mais ou menos assim:

```js
nodes_arvore.
	map((node) -> [node, mapa[node.parent_id]]).
	filter(([node, parent]) -> parent != null).
	forEach(([node, parent]) -> parent.children.push(node));
```

Então, como ficaria o `build_tree` final? Fica mais ou menos
assim:

```js
const build_tree = (arr) => {
  // mantenho os objetos externos intactos
  const nodes_arvore = arr.map((node) => ({...node, children: []}))

  // povoando o mapa id para node
  const mapa_id2node = new Map()
  nodes_arvore.forEach((n) => mapa_id2node[n.id] = n)

  // vasculhando todos os nós e colocando os filhos em seus respectivos pais
  nodes_arvore.
    map((node) => [node, mapa_id2node[node.parent_id]]).
    filter(([node, parent]) => parent != null).
    forEach(([node, parent]) => parent.children.push(node));
  return nodes_arvore.filter((n) => n.parent_id == null);
}
```

# Outras estruturas de busca

Podemos usar, no lugar de um mapa, uma lista ordenada por `id` e fazer
busca binária nela para encontrar o nó que corresponde ao `id` adequado.
A busca disso seria $O(log n)$ para cada busca. Serão realizadas $n$ buscas,
então a complexidade seria $O(n log n)$.

Muito por cima, o código ficaria mais ou menos assim:

```js
const build_tree = (arr) => {
  // mantenho os objetos externos intactos
  const nodes_arvore = arr.map((node) => ({...node, children: []})).sort((a, b) => a.id - b.id)

  // povoando o mapa id para node, agora com binary search
  const mapa_id2node = (id, init = 0, fim = nodes_arvore.len - 1) => {
    if (init == fim) return nodes_arvore[init].id == id? nodes_arvore[init]: null;
    if (init > fim) return null;

    const meio = (init + fim)/2; // divisão inteira
    const ids_diff = id - nodes_arvore[meio].id;

    if (ids_diff == 0) return nodes_arvore[meio];
    else if (ids_diff < 0) return mapa_id2node(id, init, meio - 1);
    else return mapa_id2node(id, init + 1, fim);
  }

  // vasculhando todos os nós e colocando os filhos em seus respectivos pais
  nodes_arvore.
    map((node) => [node, mapa_id2node(node.parent_id)]).
    filter(([node, parent]) => parent != null).
    forEach(([node, parent]) => parent.children.push(node));
  return nodes_arvore.filter((n) => n.parent_id == null);
}
```

Notou como a estrutura ficou semelhante? A ideia do algoritmo é a mesma,
só mudando o detalhe do algoritmo de busca.

{% endkatexmm %}
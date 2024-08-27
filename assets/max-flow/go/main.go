package main

import (
	"computaria/graphs/maxflow"
	"fmt"
)

func main() {
	g := maxflow.CriaGrafo(5)
	g.AdicionaArestaBi(0, 1, 2.0)
	g.AdicionaArestaBi(0, 2, 4.0)
	g.AdicionaArestaBi(0, 3, 7.0)
	g.AdicionaArestaBi(1, 2, 1.0)
	g.AdicionaArestaBi(1, 3, 7.0)

	g.AdicionaArestaBi(2, 3, 2.0)
	g.AdicionaArestaBi(2, 4, 10.0)
	g.AdicionaArestaBi(3, 4, 2.0)

	fmt.Println(maxflow.Busca(1, 2, func(id int) []maxflow.Aresta { return g.Vizinhos(id) }))

	arestas := [4]maxflow.Aresta{{Destino: 0, Peso: 1}, {Destino: 1, Peso: 2}, {Destino: 0, Peso: 3}, {Destino: 1, Peso: 4}}
	for i, a := range arestas[1:] {
		fmt.Printf("%d (%d, %f)\n", i, a.Destino, a.Peso)
	}
}

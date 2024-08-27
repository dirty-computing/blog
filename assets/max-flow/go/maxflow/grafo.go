package maxflow

type Aresta struct {
	Destino int
	Peso    float64
}

type Grafo struct {
	pesos [][]Aresta
}

func (g *Grafo) AdicionaAresta(origem int, destino int, peso float64) {
	g.pesos[origem] = append(g.pesos[origem], Aresta{destino, peso})
}

func (g *Grafo) AdicionaArestaBi(a int, b int, peso float64) {
	g.AdicionaAresta(a, b, peso)
	g.AdicionaAresta(b, a, peso)
}

func (g *Grafo) Vizinhos(a int) []Aresta {
	v := g.pesos[a]
	copia := make([]Aresta, len(v))
	copy(copia, v)
	return copia
}

func CriaGrafo(vertices int) *Grafo {
	g := Grafo{make([][]Aresta, vertices)}

	for i := range vertices {
		g.pesos[i] = make([]Aresta, 0)
	}
	return &g
}

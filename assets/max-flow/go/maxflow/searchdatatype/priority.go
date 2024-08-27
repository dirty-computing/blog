package searchdatatype

type PriorityMax struct {
	interno []NodoArmazenado
	topo    int
}

func CriaPriority() SearchDataType {
	return &PriorityMax{make([]NodoArmazenado, 0), 0}
}

func (p *PriorityMax) Vazia() bool {
	return p.topo == 0
}

func (p *PriorityMax) Push(v NodoArmazenado) {
	ogTopo := p.topo
	p.topo += 1

	if ogTopo == len(p.interno) {
		p.interno = append(p.interno, v)
		return
	}
	p.interno[ogTopo] = v
}

func (p *PriorityMax) Pop() NodoArmazenado {
	if p.topo == 0 {
		return NodoArmazenado{Id: -1, Peso: -1}
	}

	maxPriority, maxPriorityIndex := p.interno[p.topo-1], p.topo-1

	last := maxPriority
	p.topo -= 1
	for i, node := range p.interno[:p.topo] {
		if node.Peso > maxPriority.Peso {
			maxPriority = node
			maxPriorityIndex = i
		}
	}
	if maxPriorityIndex < p.topo {
		p.interno[maxPriorityIndex] = last
	}

	return maxPriority
}

func (p PriorityMax) Len() int {
	return p.topo
}

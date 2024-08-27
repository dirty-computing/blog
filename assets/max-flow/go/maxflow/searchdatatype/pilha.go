package searchdatatype

type Pilha struct {
	interno []NodoArmazenado
	topo    int
}

func CriaPilha() SearchDataType {
	return &Pilha{make([]NodoArmazenado, 0), 0}
}

func (p *Pilha) Vazia() bool {
	return p.topo == 0
}

func (p *Pilha) Push(v NodoArmazenado) {
	ogTopo := p.topo
	p.topo += 1

	if ogTopo == len(p.interno) {
		p.interno = append(p.interno, v)
		return
	}
	p.interno[ogTopo] = v
}

func (p *Pilha) Pop() NodoArmazenado {
	if p.topo == 0 {
		return NodoArmazenado{Id: -1, Peso: -1}
	}
	p.topo -= 1
	r := p.interno[p.topo]
	return r
}

func (p Pilha) Len() int {
	return p.topo
}

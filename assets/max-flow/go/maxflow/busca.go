package maxflow

import (
	"computaria/graphs/maxflow/searchdatatype"
)

func garanteTamanho(jahVisitados []bool, idDesejadoMinimo int) []bool {
	tamanhoDesejadoMinimo := idDesejadoMinimo + 1
	if jahVisitados == nil {
		r := make([]bool, tamanhoDesejadoMinimo)
		for i := range tamanhoDesejadoMinimo {
			r[i] = false
		}
		return r
	}
	tamanhoAtual := len(jahVisitados)
	if tamanhoAtual >= tamanhoDesejadoMinimo {
		return jahVisitados
	}
	delta := tamanhoDesejadoMinimo - tamanhoAtual
	r := make([]bool, delta)
	for i := range delta {
		r[i] = false
	}
	return append(jahVisitados, r...)
}

func Busca(origem int, destino int, vizinho func(int) []Aresta) float64 {
	estruturaDados := searchdatatype.CriaPriority()
	// estruturaDados := searchdatatype.CriaPilha()
	jahVisitados := make([]bool, max(origem, destino)+1)

	vizinhosLocais := vizinho(origem)
	maxLocal := vizinhosLocais[0].Peso
	for _, a := range vizinhosLocais {
		if a.Peso > maxLocal {
			maxLocal = a.Peso
		}
	}

	estruturaDados.Push(searchdatatype.NodoArmazenado{Id: origem, Peso: maxLocal})
	for !estruturaDados.Vazia() {
		sendoVisitado := estruturaDados.Pop()
		if sendoVisitado.Id == destino {
			return sendoVisitado.Peso
		}
		jahVisitados = garanteTamanho(jahVisitados, sendoVisitado.Id)
		if jahVisitados[sendoVisitado.Id] {
			continue
		}
		jahVisitados[sendoVisitado.Id] = true

		for _, aresta := range vizinho(sendoVisitado.Id) {
			d := aresta.Destino
			p := aresta.Peso
			estruturaDados.Push(searchdatatype.NodoArmazenado{Id: d, Peso: min(p, sendoVisitado.Peso)})
		}
	}
	return -1
}

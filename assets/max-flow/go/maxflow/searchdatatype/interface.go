package searchdatatype

type NodoArmazenado struct {
	Id   int
	Peso float64
}

type SearchDataType interface {
	Push(NodoArmazenado)
	Pop() NodoArmazenado
	Vazia() bool
}

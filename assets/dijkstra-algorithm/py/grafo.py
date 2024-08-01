from dijkstra import busca_dijkstra

class Grafo:
    def __init__(self, n):
        self.arestas = [[] for _ in range(n)]

    def adiciona_aresta_bi(self, a, b, w):
        self.adiciona_aresta(a, b, w)
        self.adiciona_aresta(b, a, w)
    
    def adiciona_aresta(self, v_out, v_in, w):
        self.arestas[v_out].append((v_in, w))

    def vizinhos(self, idx):
        return self.arestas[idx]

grafo = Grafo(5)
print(grafo.arestas)

grafo.adiciona_aresta_bi(0, 1, 2)
grafo.adiciona_aresta_bi(0, 2, 4)
grafo.adiciona_aresta_bi(1, 2, 1)
grafo.adiciona_aresta_bi(1, 3, 7)
grafo.adiciona_aresta_bi(2, 3, 2)
grafo.adiciona_aresta_bi(2, 4, 10)
grafo.adiciona_aresta_bi(3, 4, 2)

print(f"a menor distâncie entre 0 e 4 é de {busca_dijkstra(grafo, 0, 4)}")

for vizinhanca in grafo.arestas:
    print(vizinhanca)
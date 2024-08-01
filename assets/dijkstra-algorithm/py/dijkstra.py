from heap import HeapLike

# g é o grafo em si, origem é o índice de origem e destino é o índice de destino
def busca_dijkstra(g, origem, destino):
    estrutura_dados = HeapLike(lambda a,b: a[1] <= b[1])
    print("before push")
    estrutura_dados.push((origem, 0))
    print("after push")
    jah_visitados = set()

    while not estrutura_dados.empty():
        sendo_visitado, distancia = estrutura_dados.pop()
        if sendo_visitado == destino:
            return distancia
        if sendo_visitado not in jah_visitados:
            jah_visitados.add(sendo_visitado)

            for v,d in g.vizinhos(sendo_visitado):
                if v not in jah_visitados:
                    estrutura_dados.push((v, distancia + d))
    return None
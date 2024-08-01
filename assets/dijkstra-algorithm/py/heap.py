class HeapLike:
    def __init__(self, comparator):
        self.internal = []
        self.comparator = comparator
    
    def push(self, n):
        i = len(self.internal)
        self.internal.append(n)

        if i == 0:
            return
        nodo_pai = HeapLike.nodo_pai(i)
        while self.comparator(n, self.internal[HeapLike.nodo_pai(i)]):
            self.internal[i] = self.internal[nodo_pai]
            self.internal[nodo_pai] = n
            i = nodo_pai
            if i == 0:
                break
            nodo_pai = HeapLike.nodo_pai(i)

    @staticmethod
    def nodo_pai(n):
        return (n-1)//2
    
    @staticmethod
    def filho_esq(n):
        return (n+1)*2 -1
    
    @staticmethod
    def filho_dir(n):
        return (n+1)*2

    def pop(self):
        r = self.internal[0]
        tamanho = len(self.internal) - 1
        elemento_rebaixado = self.internal[tamanho]
        self.internal[0] = elemento_rebaixado
        self.internal.pop()

        i = 0
        while True:
            e = HeapLike.filho_esq(i)
            d = HeapLike.filho_dir(i)

            #print(f"tamanho {tamanho}, índices envolvidos {i} {e} {d}")
            if e >= tamanho:
                # chegou ao fim da heap
                break
            if d >= tamanho:
                # o nodo a esquerda ainda tá na heap, mas o da direita não
                # se precisar rebaixar, é apenas comparando com o da esquerda
                if not self.comparator(elemento_rebaixado, self.internal[e]):
                    # precisa trocar esquerda e índice atual
                    #print(f"trocando {self.internal[i]} idx {i} com {self.internal[e]} idx {e}")
                    self.internal[i], self.internal[e] = self.internal[e], self.internal[i]
                break
            if self.comparator(elemento_rebaixado, self.internal[e]) and self.comparator(elemento_rebaixado, self.internal[d]):
                # já está ordenado, não precisa de trocas
                break
            # agora, precisa detectar qual o índice alvo da troca
            target = e if self.comparator(self.internal[e], self.internal[d]) else d
            #print(f"envolvidos: {self.internal[i]} {self.internal[e]} {self.internal[d]}, índices {i} {e} {d}, trocando {self.internal[i]} idx {i} com {self.internal[target]} idx {target}")
            self.internal[i], self.internal[target] = self.internal[target], self.internal[i]
            i = target
        return r

    def empty(self):
        return len(self.internal) == 0
    
#    def print_all(self):
#        print(f"{self.internal}")

n = HeapLike(lambda x,y: x < y)
n.push(123)
n.push(456)
n.push(13)
n.push(457)
n.push(458)
n.push(256)
n.push(2)
n.push(20)
n.push(200)
n.push(2000)
n.push(20000)


#n.print_all()
while not n.empty():
    print(n.pop())
    #n.print_all()
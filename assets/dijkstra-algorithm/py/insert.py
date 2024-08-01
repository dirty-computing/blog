class InsertLista:
    def __init__(self, comparator):
        self.internal = []
        self.comparator = comparator
    
    def push(self, n):
        i = len(self.internal)
        self.internal.append(n)
        while i > 0 and self.comparator(n, self.internal[i-1]):
            self.internal[i], self.internal[i-1] = self.internal[i-1], self.internal[i]
            i -= 1
    
    def pop(self):
        if len(self.internal) == 0:
            return None
        return self.internal.pop(0)

    def empty(self):
        return len(self.internal) == 0

n = InsertLista(lambda x,y: x < y)
n.push(123)
n.push(456)
n.push(13)
while not n.empty():
    print(n.pop())
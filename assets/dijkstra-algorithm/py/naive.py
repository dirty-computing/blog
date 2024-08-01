class NaiveLista:
    def __init__(self, comparator):
        self.internal = []
        self.comparator = comparator
    
    def push(self, n):
        self.internal.append(n)
    
    def pop(self):
        if len(self.internal) == 0:
            return None
        m = 0
        minimum_value = self.internal[0]
        for i, v in enumerate(self.internal):
            if self.comparator(v, minimum_value):
                minimum_value = v
                m = i
        self.internal.pop(m)
        return minimum_value

    def empty(self):
        return len(self.internal) == 0

n = NaiveLista(lambda x,y: x < y)
n.push(123)
n.push(456)
n.push(13)
while not n.empty():
    print(n.pop())
---
layout: post
title: "Aprendendo ponto flutuante, parte1: notação científica"
author: "Jefferson Quesado"
tags: matemática float
---

Peguem o console da web e façam o teste:

```js
0.2 + 0.1
```

Qual foi o resultado obtido?

<button id="calc" onclick="zero_dois_mais_zero_um()">Resultado</button>
<script>
function zero_dois_mais_zero_um() {
	let x = 0.2+0.1;
	alert(`o resultado da conta maldita é: ${x}`);
}
</script>
---
layout: post
title: "Pipes nomeados e redirecionamento"
author: "Jefferson Quesado"
tags: shell bash io linux file-descriptor
---

O pipeline quase todo mundo que já lidou com alguma
shell unix já conhece. Ele é um processo de encadear
a escrita de um processo com a leitura de outro
processo, algo mais ou menos assim:

```bash
head -n 5 <some-file | sed 's/Oie/Tchau/g'
```

Isso vai executar primeiro o comando `head`, passando
como parâmetros `['-n', '5']` nessa ordem, e fazendo
a entrada padrão ser a leitura do arquivo
`some-file`.

O pipe nomeado vai fazer algo bem próximo disso, só
que eu nomeio o meio do caminho.

> Por sinal, o pipelining tradicional é referenciado
> em alguns lugares como "annonymous pipe", "pipe
> anônimo".

Para executar o mesmo pipeline acima com pipes
nomeados, eu precisaria direcionar a saída do `head`
para o pipe nomeado e direcionar a entrada do `sed`
para o pipe nomeado. Algo assim, em duas shells
distintas (ou qualquer outra estratégia para rodar
em paralelo):

```bash
# na primeira shell
head -n 5 <some-file >my-named-pipe

# na segunda shell
sed 's/Oie/Tchau/g' <my-named-pipe
```

Mas, temos uma carcterística importante aqui...
o pipe nomeado _não é_ é arquivo convencional. Ele
jamais armazenará informações, ele apenas fará 
conexão das leituras que ele está fazedo (o seu
input) e escreverá numa saída assim que tiver alguém
lendo.

Para criar um pipe nomeado, execute o comando
`mkfifo nome-do-pipe`. O pipeline, por si,
é uniplex, onde a informação sai sempre de um
canto e chega em outro. Isso vale para pipes
nomeados e anônimos. Se você necessita de uma
abordagem com comunicação duplex, um único pipe
nomeado não será o suficiente. Você precisará de
dois (um será a entrada do primeiro comando e saída
da segundo comando; enquanto que o segundo será a
saída do primeiro comando e a entrada do primeiro).

# Notas sobre redirecionamento

# Criando uma comunicação full-duplex usando named pipes
---
layout: post
title: "Qual é a diferença entre socket e porta?"
author: "Jefferson Quesado"
tags: conceito redes ipc
base-assets: /assets/porta-socket/
---

> Baseado na minha resposta sobre
> [Qual é a diferença entre socket e porta?](https://pt.stackoverflow.com/a/277763/64969)

Antes de mais nada, vamos analisar as palavras?

- _socket_

  Em Português, soquete. A palavra originou do inglês _socket_ mesmo, que por
  sua vez veio do do francês antigo _soc_... no final, a origem significa
  "nariz de porco". Em questões de conexões elétricas, é a parte fêmea da
  conexão. [[1]](https://pt.wiktionary.org/wiki/soquete),
  [[2]](https://en.wiktionary.org/wiki/socket), [[3]](https://en.wiktionary.org/wiki/soc)

  ![Soquete em formato de soc/nariz de porco][plugue-porco]

- _porta_

  Ou _porto_ em Português de Portugal. A palavra nesse uso veio da especificação em
  inglês, onde estava escrito _port_. Pelo que está descrito na origem da palavra
  no Wiktionary, vem do francês antigo _porte_/latim _porta_, no sentido de portão,
  passagem por onde coisas podem entrar. Também usado em alguns lugares como a parte
  fêmea de uma conexão (porta serial/ethernet, por exemplo).
  [[1] (etimologia 2)](https://en.wiktionary.org/wiki/port#Etymology_2),
  [[2]][wiki-computerport]

  ![portas de computador](https://upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Computer-connector-sockets.jpg/800px-Computer-connector-sockets.jpg)

Bem, ambos significam a parte fêmea de uma conexão, então isso acaba que não
ajudou 100% a diferenciá-los.

Bem, então vamos para uma metáfora com tomadas?

Imagine que você tem a seguinte tomada suíça:

![tomada de 3 entradas, superior, esquerda inferior e direita inferior, padrão suíço](https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/SEV_1011_Typ_13_Steckdose.jpg/596px-SEV_1011_Typ_13_Steckdose.jpg)

Você tem 3 portas de entrada:

1. a superior
1. a esquerda inferior
1. a direita inferior

Se você tentar estabelecer uma conexão com uma dessas portas, você precisa de um cabo
de plugue adequado para entrar na porta. Se o soquete estiver ligado na rede elétrica,
então haverá uma corrente elétrica (haverá comunicação) entre o servidor de energia
(sua casa, que é na Suíça para ter uma tomada dessas) e quem está consumindo a energia,
o aparelho cliente.

Mas e se não tiver ligação no soquete? Então a porta é vacuosa. Você pode ligar o que
for nela que não haverá comunicação.

A porta, então, é o identificador de onde quero me encaixar. O plugue é o meu padrão
de conexão, definida no nível 4 (transporte) no modelo TCP/IP de redes. O _socket_
seria a ligação dessa porta com a aplicação, que pode ser um servidor web, FTP, SSH
ou qualquer outra aplicação (a aplicação aqui seria a rede elétrica).

## _Berkley sockets_

Uma coisa que vale a pena mencionar é sobre socket Unix, e é de bom tom para tal
falar dos [sockets Berkley][berk-soc].

Esses tais sockets Berkley, na verdade, é uma API para se ter acesso a um ponto de
comunicação. Ela prevê dois tipos de sockets comumente usados:

- socket de rede
- socket Unix

Ambos são pontos de conexão para se realizar [IPC](https://pt.stackoverflow.com/q/211430/64969) e são usados da mesma maneira: lê-se e escreve-se dados. A diferença entre os dois sockets é com quem a comunicação será feita. Sockets Unix são para conexões dentro do mesmo computador (como _pipes_), já sockets de rede são para computadores em rede.

[plugue-porco]: {{ page.base-assets | append: "porco.jpg" | relative_url }}
[wiki-computerport]: https://en.wikipedia.org/wiki/Computer_port_(hardware)
[a-jsbueno]: https://pt.stackoverflow.com/a/277762/64969
[berk-soc]: https://en.wikipedia.org/wiki/Berkeley_sockets
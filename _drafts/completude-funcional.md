---
layout: post
title: "Caranguejos como computadores completos?"
author: "Jefferson Quesado"
tags: matemática lógica circuitos-lógicos
---

> Baseado na _thread_ do Twitter [https://twitter.com/JeffQuesado/status/1477843585919770626](https://twitter.com/JeffQuesado/status/1477843585919770626)

O usuário do Twitter [@edo9k](https://twitter.com/edo9k) respondeu uma brincadeira sobre modelos
de computação com o seguinte tuíte:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Water based computing considered harmful.<br>Move your system to crab. <a href="https://t.co/c5MF0aBny6">https://t.co/c5MF0aBny6</a></p>&mdash; Eduardo França (@edo9k) <a href="https://twitter.com/edo9k/status/1475994283303972865?ref_src=twsrc%5Etfw">December 29, 2021</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script> 

Em cima do comportamento desses caranguejos, foram feitos 2 portas lógicas.

# Porta `OR`

Na porta `OR`, chegam dois sinais de caranguejos e tem um único output. Ela é desenhada
de tal forma que, caso tenha pelo menos um sinal chegando, ele saia pelo output; e caso
tenha dois sinais chegando, eles se misturam e saem no output. A tabela verdade é a mesma
da porta `OR` tradicional (tome com `A` e `B` os dois sinais de input):

|   A   |   B   |  output  |
| :---: | :---: |  :---:   |
|   0   |   0   |    0     |
|   1   |   0   |    1     |
|   0   |   1   |    1     |
|   1   |   1   |    1     |
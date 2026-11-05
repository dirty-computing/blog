---
layout: post
title: "Regex em ação: contando posts do computaria por ano"
author: "Jefferson Quesado"
tags: regex bash meta
base-assets: "/assets/regex-action-contando-posts/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Hoje eu fui brincar com as novidades que eu coloquei no
[Gerencial](/blog/managerial) (coloquei uma seção dedicada a variáveis de
local storage voltadas pra customização, sem ser toggle, tá bem legal!), e
então acabei por abrir o índice do Computaria... e num é que tem muito artigo
publicado?

Então lembrei do meu antigo plano de fazer um paginador por ano, que ainda
pretendo implementar. Mas além disso, bateu a curiosidade: quantos artigos será
que tem no Computaria? E por ano? Vamos coletar esses dados?

# Estrutura de pastas

Talvez o jeito mais fácil fosse simplesmente contar quantos `*.md` tem dentro
de `_posts/*/*.md`. Porém essa estratégia é um pouco falha... visto que ela
fica acoplada à estrutura atual de como organizo as pastas dentro do próprio
Computaria e... bem, isso já teve mudanças para que eu pudesse me organizar
melhor.

Desde pelo menos janeiro de 2025 que já tenho o intuito de fazer a [paginação
do Computaria por ano](https://gitlab.com/computaria/blog/-/work_items/20).
Justamente porque fica com muita coisa carregada no índice. Mas, enquanto não
chega esse momento, o índice continua com todas as publicações.

Mas o problema de manutenção dos arquivos continuava. Então, que tal resolver
esse problema? Foi isso que eu fiz no
[commit aa8ecc8ce]({{ site.repository.base }}/-/commit/aa8ecc8ce4fff71d1a59e56bb252d93cdf87459a)
(uma mudança tão interna e tão pouco esperta que nem achei que era digna de
virar artigo na época). Para não ficar tudo em um único canto, os mais de 100
artigos listados no mesmo diretório, resolvi separar por ano. E desde então o
artigo fica publicado na pasta com o seguinte formato:

- `_posts/YYYY/YYYY-MM-DD-titulo.md`

Além disso, tem também o caso de rascunhos que são publicados a fim de revisão.
Atualmente não tem nenhum artigo de rascunho digno, mas mantive uma publicação
dessas "escondida":
[Post de rascunho público de exemplo]({% post_url 2022/2022-10-26-eu-sou-rascunho %}).

Então, devido a isso, simplesmente procurar na estrutura de pastas não é algo
que eu gostaria de confiar cegamente.

# Procurando na página central

Já que vai ser um one-off, bora extrair do índice central? Para fazer isso, é
só fazer um `curl` mesmo:

```bash
curl https://computaria.gitlab.io
```

Mas... hmmm... bem, para a raiz eu coloquei um redirecionamento (vide
[Pequenas melhorias no Computaria]({% post_url 2024/2024-04-09-little-improves %})).
Então vamos pedir pro `curl` seguir redirects!

```bash
curl https://computaria.gitlab.io -L
```

Ok, seguiu redirect. Agora, vamos pegar links? Todo link de post que eu
coloquei no índice tem a classe `post-link`. Pois, vamos seguir essa classe?

```bash
curl https://computaria.gitlab.io -L | grep post-link
```

Um exemplo do que isso filtrou:

```html
    <a class="post-link beta-link" href="/blog/2021/12/23/fluent-builder">Fluent Builder com região crítica</a>
    <a class="post-link beta-link" href="/blog/2021/10/07/hello-world-gwt-archetype-1">"Hello, World!" em GWT usando arquétipo do TBroyer</a>
    <a class="post-link beta-link" href="/blog/2021/09/17/desenhos-python-turtle">Desenhando com Python e tartarugas</a>
    <a class="post-link beta-link" href="/blog/2021/09/12/base-assets">Manipulando Liquid para permitir uma base dos assets</a>
    <a class="post-link beta-link" href="/blog/2021/08/30/criando-blog-jekyll">Criando o blog com Jekyll no GitLab</a>
```

Agora eu posso simplesmente contar:

```bash
curl https://computaria.gitlab.io -L | grep post-link | wc -l
```

I isso me dá 113 artigos ao todo.

> Por curiosidade, localmente tem 154.

Ok, mas eu quero pegar por ano. Vamos pegar essa string e manipular de modo que
fique apenas o ano? Para isso, quero pegar no link os quatro números tem depois
de `/blog/`. Como o blog foi lançado em 2021 e ainda não viramos o ano, vou
casar com `202[0-9]`. Em tese poderia botar pra casar com outras décadas, não
seria difícil. Bem, dado isso, eu preciso casar com `/blog/202[0-9]` e depois
selecionar apenas os números. Meio que um
`replace("^.*/blog/(202[0-9]).*$", "\1")`.

Usando `sed`, para fazer esse "replace", eu uso o comando `s`. Tradicionalmente
se usa `/` junto do `s`, ficando `s/pattern/replace/`, mas no meu caso, como
tem barras no pattern, fica bem chatinho de escrever a substituição. Mas sabia
que o `sed` não precisa usar barras? Na real, qualquer caracter serve, contanto
que você mantenha consisência. Então usei `_`:
`'s_^.*/blog/\(202[0-9]\).*$_\1_'`.

Até agora, ficou assim o comando:

```bash
curl https://computaria.gitlab.io -L | grep post-link | sed 's_^.*/blog/\(202[0-9]\)/.*$_\1_'
```

Ok, agora como que faço pra contar? Bem, eu conheço o comando Unix `uniq`. Esse
comando pega várias linhas do input e pega as aparições únicas de cada linha?
Bem, quase... na verdade se a linha `N+1` for idêntica à linha `N`, o `uniq`
ignora essa linha. Agora, caso `N+1` for diferente da `N`, então ele imprime.
Por exemplo:

```bash
curl https://computaria.gitlab.io -L | grep post-link | sed 's_^.*/blog/\(202[0-9]\)/.*$_\1_' | uniq
```

Imprime:

```txt
2026
2025
2024
2023
2022
2021
```

Agora, se eu colocar um `2026` no final

```bash
(curl -s https://computaria.gitlab.io -L | grep post-link | sed 's_^.*/blog/\(202[0-9]\)/.*$_\1_'; echo 2026 ) | uniq
```

ele imprime isso:

```txt
2026
2025
2024
2023
2022
2021
2026
```

Será que tem alguma opção no `uniq` que faz a acumulação? Vamos olhar no
`man uniq`...


```man
     The following options are available:

     -c, --count
             Precede each output line with the count of the number of times the line occurred in the input,
             followed by a single space.
```

A primeira opção é o `-c` e é exatamente o que eu quero!

```bash
curl https://computaria.gitlab.io -L | grep post-link | sed 's_^.*/blog/\(202[0-9]\)/.*$_\1_' | uniq -c
```

Imprimindo

```txt
  27 2026
  37 2025
  20 2024
   8 2023
  12 2022
   9 2021
```

E com isso botamos as regexes pra trabalhar e obter o dado que se buscava
conhecer! Pra terminar de deixar bonito só falta pedir pro `curl` não mostrar
o progresso do download, e se consegue isso pedindo para que ele seja
"silencioso", com o `-s`. A linha completa fica:

```bash
curl -s https://computaria.gitlab.io -L | grep post-link | sed 's_^.*/blog/\(202[0-9]\)/.*$_\1_' | uniq -c
```

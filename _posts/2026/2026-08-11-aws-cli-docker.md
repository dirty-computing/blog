---
layout: post
title: "Simples workaround para trabalhar com AWS CLI sem instalar nada"
author: "Jefferson Quesado"
tags: aws docker docker-compose
base-assets: "/assets/aws-cli-docker/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Tenho uma necessidade específica: usar a AWS-CLI. Porém, o meu desafio é fazer
isso sem instalar nada. E ainda por cima para essa atividade específica eu
precisava disponibilizar na mesma máquina tanto o AWS-CLI quanto também acesso
ao Terraform.

Na primeira instância que realizei isso foi através do
[Cloud Shell](https://console.aws.amazon.com/cloudshell) da própria AWS. Mas
posso dizer com tranquilidade que isso não se comparava em nada com o conforto
de poder fazer isso da minha própria máquina, né?

Então, veio o desafio: como poder interagir com o AWS-CLI, porém sem instalar
nada, e também tentando evitar todo e qualquer contaminação com outro ambiente
que eventualmente eu pudesse ter na minha máquina?

Foi então que eu me lembrei de que eu poderia tentar usar uma imagem docker
para tentar burlar essa limitação! E claro que a Amazon subiu uma imagem
oficial de seu Amazon Linux com a AWS-CLI no Docker Hub:
[`amazon/aws-cli`](https://hub.docker.com/r/amazon/aws-cli/).

# Container/Imagem 101

Vamos lá. Ao usar Docker, estamos usando uma **imagem** em um **container**. De
modo bem grosseiro para quem usa programação orientada a objetos estilo
Java/C++: é como se a **imagem** fosse a _classe_ e o _objeto_ que é a
_instância_ da classe fosse o **container**.

Nesse sentido, a classe é imutável. A imagem é única também. E a partir dela
podemos instanciar uma classe e assim teremos um objeto, que pode evoluir.
Eventualmente esse objeto deixará de existir. Podemos dizer que ele vai ser
"destruído" ou "coletado" no final do seu ciclo de vida.

Mas eu também posso querer trabalhar com uma mesma customização em todas as
imagens por debaixo. Para isso, damos a ela o caminho adequado para a
construção de novos containers em cima de uma nova imagem. Para isso criamos o
Dockerfile.

Muitas imagens são criadas com base em algo já existente. Por exmeplo, no post
[Rodando o gitlab runner em um docker-in-docker]({% post_url 2026/2026-02-10-gitlab-runner-dind %}),
para rodar a imagem já com as dependências pré-instaladas e assim economizar
uma boa parte do tempo de build do Computaria, usei a imagem `ruby`.

Agora, apenas a imagem não é o suficiente. Esse caso da imagem que se chama
apenas `ruby`, sem a barra, indica mais ou menos de que ela vem da
"distribuição padrão". No caso de um Docker sem nenhuma alteração (como, por
exemplo, endereço do repositório de imagens customizado), isso significa
[Imagens Dokcer Oficiais](https://docs.docker.com/docker-hub/repos/manage/trusted-content/official-images/).
E a específica que usei para o Ruby foi a
[imagem docker oficial de Ruby](https://hub.docker.com/_/ruby).

Mas só usar a imagem não é lá essas coisas de confiável. A imagem eventualmente
é atualizada. Precisamos atrelar nela uma versão! E pra isso o `:3.2-alpine`.
Aqui estou dizendo que "não basta pegar uma imagem qualquer do Ruby, eu quero
pegar especificamente a versão `3.2-alpine`".

Se você quiser prender com mais força a imagem em si, tavez nem seja o adequado
usar uma tag genérica de versão. As vezes faz mais sentido prender a um ponto
específico no histórico da imagem, como se fosse "naquele commit específico" e
não "naquela tag específica". Para isso, usamos o `@`. Usamos o `@` seguido da
"assinatura" daquele ponto no histórico. E para isso podemos mencionar o
"manifest" (que pega num nível mais alto, independente de arquitetura) ou
direto o índice já com a arquitetura.

No meu caso, pegando a versão [`3.2-alpine`](https://hub.docker.com/layers/library/ruby/3.2-alpine3.23/images/) para um arm64-v7:

manifest digest `sha256:f2eacfbe046e6842d45984663c8868422762dbd62b54cda603cba11a80c6d484`:

```bash
docker run --rm -it ruby@sha256:f2eacfbe046e6842d45984663c8868422762dbd62b54cda603cba11a80c6d484
```

manifest digest `sha256:d206c25708a44df6a7ce22213ee5da9fc0a9f7b31ce884429ba758db48abdc62`:  

```bash
docker run --rm -it ruby@sha256:d206c25708a44df6a7ce22213ee5da9fc0a9f7b31ce884429ba758db48abdc62
```

Qual você vai usar, e porquê vai usar essa em específico vai depender de como o
projeto evolui e decisões técnicas e contratuais. Para o meu caso específico,
que é ter uma imagem pra fazer um build de um SSG e para rodar uma CLI, vou
preferir me ater a o que é mais fácil.

## Alterando como o container roda

A primeira coisa a saber sobre um container é: ele nasce quando você o inicia,
e ele morre quando o seu processo principal chega ao fim.

Portanto, `docker run ruby:3.2-alpine` vai iniciar um processo e rapidamente
vai terminá-lo:

```bash
> docker run ruby:3.2-alpine    
Switch to inspect mode.

> 
```

Mas por que nesse caso específico acabou tão rápido? Porque não vinculei nada
de que estou interagindo com o terminal desse container. Para isso, usamos as
flags `-it`:

```bash
> docker run -it ruby:3.2-alpine
irb(main):001:0> puts 'oi'
oi
=> nil                                           
irb(main):002:0> 
```

Aqui estou falando pro Docker que quero interagir `-i` com o programa sendo
invocado, e também digo ao Docker para que ele aloque uma TTY `-t` para uma
interação melhor.

Nesse caso, o container especificamente chamou o `irb` e caiu fora. Não tem
nada depois do `irb`. E o `irb`, se não tiver alocado em uma interface
interativa, ele simplesmente se termina.

Agora, para não ficar sujando com vários containeres não mais utilizados,
podemos usar a opção para remover assim que terminar, o `--rm`. Isso indica pro
daemon que, ao terminar a execução do programa, remova o container.

Note que nem sempre usar o `--rm` é a solução! Se você tiver um processo web
que precisa ficar sempre ligado, você provavelmente vai querer usar que ele se
[reinicie](https://docs.docker.com/reference/cli/docker/container/run/#restart).
Para isso, você não passa o `--rm` (que remove o container após parar) e coloca
uma flag com a política de restart, como `--restart unless-stopped`. Note que
para aplicativos efêmeros de linha de comando (como o AWS-CLI) é desejável que
o container evapore no final da execução, enquanto que para serviços eu peça
para que ee se reinicie.

Eu particularmente prefiro ter a opção explícita de poder derrubar o serviço,
por isso prefiro por `--restart unless-stopped`: isso vai dizer que, quando
ocorre uma parada no serviço por algum fluxo que levou o servidor a parar de
rodar, esse container irá se reiniciar sozinho. Porém caso eu explicite que ele
deva parar com `docker stop`, esse container vai obedecer o comando e vai se
desaparecer. Sempre bom ter a opção de poder simplesmente parar o container
para atualizar com uma versão mais nova.

Outra coisa sobre a localização de containeres! Eu posso indicar que o meu
container está sendo disponibilizado por alguém, como no caso do
`amazon/aws-cli` (imagem `aws-cli` do usuário `amazon`), ou então `alpine/curl`
(imagem `curl` do usuário `alpine`).

Agora, tem umas paradas interessantes em relação a alguns containeres. Eles já
vem prontinhos para serem chamados na linha de comando! Por exemplo:

```bash
> docker run --rm alpine/curl:8.21.0 https://www.pudim.com.br -s
<html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>Pudim</title>
    <link rel="stylesheet" href="estilo.css">
</head>
<body>
<div>
    <div class="container">
        <div class="image">
            <img src="pudim.jpg" alt="">
        </div>
        <div class="email">
            <a href="mailto:pudim@pudim.com.br">pudim@pudim.com.br</a>
        </div>
    </div>
</div>
<script>
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
                (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
            m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

    ga('create', 'UA-28861757-1', 'auto');
    ga('send', 'pageview');

</script>
</body>
</html>
```

Aqui estou chamando a imagem `curl` do usuário `alpine` na versão `8.21.0` e
passando para ele o comando de baixar o
[`https://www.pudim.com.br`](https://www.pudim.com.br) de modo silencioso `-s`.
Notou que depois do nome da imagem todo o resto foram opções do comando `curl`?

Pois bem, mas nem toda imagem é assim. Por exemplo, posso pedir para carregar
uma shell arbitrária no Ruby:

```bash
docker run --rm -it ruby:3.2-alpine sh                            
/ # 
```

Aqui o `sh` é o comando que vai ser executado na imagem `ruby:3.2-alpine` para
rodar o container.

A diferença entre essas duas imagens é que no caso do `alpine/curl` foi
definido um `entrypoint`, e no `ruby` não. Ao definir um
[`entrypoint`](https://docs.docker.com/reference/dockerfile/#entrypoint) para
a imagem, o que vier depois na linha de comando se torna simplesmente
argumentos. Caso não tenha nenhum entrypoint registrado, os argumentos são
simplesmente delegados para o container executar e o container fica ativo
apenas até que esse comando termine a execução.

No caso, mesmo tendo um entrypoint tradicional, eu posso alterar o meu
entrypoint desejado na hora de subir o container:

```bash
> docker run --rm --entrypoint sh -it alpine/curl:8.21.0 
/ # 
```

Agora, mesmo o `alpine/curl` definindo que tem um entrypoint, eu estou mandando
usar comom entrypoint o `sh`.

Além do comando `run` que vai iniciar um novo container, eu posso executar algo
dentro de um container pré-existente. Para isso temos o comando `docker exec`,
aí você identifica qual o container deseja executar e qual o comando a ser
executado.

Além do que já foi dito, tem mais uma coisa importante, principalmente para
quem deseja algo com efeitos colaterais duradouros (como, por exemplo,
conseguir se logar com sucesos na AWS): usar volumes para montar um diretório
do host no container! Isso permite, por exemplo, que a aplicação CLI possa
fazer login, ser efêmera, e na próxima vez que for invocada que ela esteja já
pronta com a parte de autenticação resolvida.

## Uma fórmula para montar container

O docker compose existe para montar um ecossistema adeqaudo de imagens para
poder subir um pequeno sistema. Um exemplo simples para isso:

```yaml
services:
  web:
    build: .
    ports:
      - "${APP_PORT}:5000"
    environment:
      - REDIS_HOST=${REDIS_HOST}
      - REDIS_PORT=${REDIS_PORT}

  redis:
    image: redis:alpine
```

Aqui os diversos serviçoes são listados, cada um com as descrições do que
precisa pra subir o serviço específico. Aqui, no exemplo tirado diretamente da
página do [Dokcer Compose](https://docs.docker.com/compose/gettingstarted/),
temos a descrição de dois serviços:

- web
- redis

O `redis` simplesmente sobe em cima da imagem padrão. O `web`, por sua vez,
indica que é feito o build a partir do diretório local, abre uma porta para a
5000 e também pega duas variáveis de ambinete.

Como eu posso configurar arbitrariamente o container, vou usar isso para poder
manipular o como eu quero que o meu AWS-CLI suba.

Em um primeiro instante:

```yaml
services:
  aws:
    image: amazon/aws-cli:latest
```

Isso simplesmente sobe o container. Ok, agora consigo experimentar se eu
consigo fazer login na AWS com sucesso através do `aws login`? Bem, não, não
livremente pelo menos. O `entrypoint` não é uma shell, é o próprio comando
`aws`. Eu poderia declarar no próprio `services`, mas não... quero ser
explícito chamar o shell. Então, vou colocar essa informação na hora de subir o
container. Ficando assim por enquanto:

```bash
docker compose run -it --rm --entrypoint sh aws
```

Por hora não parece estar sendo vantajoso usar o docker compose, né? Ok, as
coisas melhoram, eu prometo. Estamos prontos para fazer o login! E, após o
login, chamar o comando `aws sts get-caller-identity`. Massa demais! Mas...
Como conseguimos tornar esse login perene? Ainda está volátil, basta fechar o
container que preciso fazer tudo de novo, o exato oposto do que eu gostaria.

Bem, as coisas da AWS ficam salvas em `~/.aws`. Como o usuário é `root`, o
destino é `/root/.aws`. Então, nada mais justo que eu mapeie também para o
`.aws` da pasta local, né?

```yaml
services:
  aws:
    image: amazon/aws-cli:latest
    volumes:
      - .aws:/root/.aws
```

Ok, ao executar o `aws login` ele preenche as opções do jeito que eu espero.
Inclusive, rodar `docker compose run -i --rm  aws sts get-caller-identity`
retorna o valor esperado.

> Viu por que eu não queria mexer no entrypoint direto no `docker-compose.yml`?
> Se pagou, né?

Ok, com AWS logado e com sessões persistentes, qual o próximo passo?

# AWS + Terraform

Voltamos ao começo da minha questão. Preciso ter um container que tenha ao
mesmo tempo acesso da AWS-CLI e também ao Terraform, no mesmo ambiente!

Ok, AWS está resolvido. Vamos resolver o como subir as descrições do Terraform?
Do mesmo jeito que foi feito com a AWS que foi montado um volume para
compartilhar uma pasta, vamos botar aqui também:

```yaml
services:
  aws:
    image: amazon/aws-cli:latest
    volumes:
      - .aws:/root/.aws
      - ./terraform:/terraform
```

Isso permite que eu edite no VSCode rodando na minha máquina local os arquivos
do Terraform, e eles são percebidos pelo container ao serem salvos. Como
Terraform depende do estado, obter o estado em que a infra se encontra é um
"must have", e aqui eu obtenho porque o diretório permite a comunicação
full-duplex.

Agora, seria bom que toda interação já ocorresse na pasta do `/terraform`, de
modo que essa atividade (que é a principal) ficasse toda lá. Para isso, preciso
alterar o `workdir` do container. E eu poderia fazer isso a nível de
`docker run`? Sim, mas inconveniente. A nível de `docker-compose` (usando
atributo `working_dir` do service)? Poderia também, mas acho que é mais
explícito deixar isso a nível de imagem.

Então vamos começar a customoizar a imagem `aws-cli`?

```dockerfile
FROM amazon/aws-cli:latest

WORKDIR /terraform
```

Ok, imagem declarada. Agora, como utilizar ela? Bora lá, não posso mais dizer
que o meu service `aws` vai vir direto de uma imagem, mas que vou fazer o build
dela. E nesse build, o diretório com o contexto é o local. Posso também
especificar o dockerfile específico, e nesse caso eu preferi por via das
dúvidas:

```yaml
services:
  aws:
    #image: amazon/aws-cli:latest
    build:
      context: .
      dockerfile: Dockerfile.aws
    volumes:
      - .aws:/root/.aws
      - ./terraform:/terraform
```

Tenho o Terraform instalado? Ainda não, mas já começou a tomar forma. Falta-me
isso agora. Seguindo o guia de instalação do Terraform em Amazon Linux, temos
que o `Dockerfile.aws` ficou assim:

```dockerfile
FROM amazon/aws-cli:latest

RUN yum install -y yum-utils shadow-utils
RUN yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
RUN yum install -y terraform

WORKDIR /terraform
```

Para demonstrar que funciona, nada como um `terraform init && terraform plan`.
Mas... falhou. Por quê? Não encontrou o comando?

Aqui é um caso em que a imagem derivou da descrição da imagem, e não percebemos
isso. Basicamente no passado recente foi feito o build dessa imagem e aconteceu
o seu reaproveitamento. Com isso, gerando essa espécie de comportamento não
esperado.

A resolução é simples:

```bash
docker compose build aws
```

Ou então tem um atalho pra isso:

```bash
docker compose --build run --rm -it --entrupoint sh aws
```

Aqui o próprio `docker compose` se encarrega de fazer o build sozinho.

E mais uma coisinha antes que eu me esqueça, se for necessário injetar alguma
coisa de variável de ambiente no container, podemos definir isso no
`docker-compose.yaml`. Mas aqui não falo em estar lá em texto puro, mas em
menção:

```yaml
services:
  aws:
    #image: amazon/aws-cli:latest
    build:
      context: .
      dockerfile: Dockerfile.aws
    env_file: .env
    volumes:
      - .aws:/root/.aws
      - ./terraform:/terraform
```

Aqui o próprio Docker ao subir o container vai injetar as variáveis definidas
no `.env`. Usei o `.env`, por exemplo, para injetar minhas credenciais da AWS.

# Um `.gitignore` de referência

Bem, alguns arquivos não devemos commitar. Alguns porque são secrets mesmo.
Outros porque são assets secundários, como o binário depois do build.

Aqui está o que eu pude discernir:

```gitignore
*.sw[po]
.*.sw[po]
/.aws/
.env
.DS_Store
```

Esse eu mantive na raiz do repositório. Mas também achei prudente colocar um
`.gitignore` só no diretório do Terraform:

```gitignore
.terraform
.terraform.tfstate.lock.info

# terraform.tfstate não deve estar commitado
terraform.tfstate
terraform.tfstate.backup
```

Aqui, o `.terraform` é um diretório. Ele foi criado após o `terraform init`.
O `terraform.tfstate` representar o estado do sistema.

E aí temos o arquivo de lock `.terraform.tfstate.lock.info`! Bem, o que são
eles, né? Basicamente, eles permitem que apenas uma única instância do elemento
que estou trabalho, se surgir uma segunda instância ela vai tentar adquirir o
lock e não vai conseguir, pois o SO deve travar esse recurso com acesso único.
E isso que protege duas execuções em paralelo de alterar o estado em paralelo.

Inclusive, é o mesmo mecanismo que o Git utiliza para não ferrar o banco de
dados interno dele: ele tem um arquivo próprio, o `.git/index.lock`. Esse
`index.lock` que garante que um processo secundário não altere os dados,
soltando a célebre mensagem

```none
Erro: Unable to create '/path/to/repo/.git/index.lock': File exists.

If no other git process is currently running, this probably means a
git process crashed in this repository earlier. Make sure no other git
process is running and remove the file manually to continue.
```

Na primeira versão deste artigo, eu mencionei que era para colocar o arquivo
`.terraform.lock.hcl`. Isso foi um equívoco de minha parte, evidenciado em um
primeiro momento em uma revisão do Claude.

A lógica por trás desse arquivo `.lock` é distinta do
`.terraform.tfstate.lock.info`. Enquanto um se preocupa em realizar uma espécie
de IPC através do sistema de arquivos, o `.terraform.lock.hcl` tem mais
semelhança com os `.lock` de gerenciamento de dependências, como o
`Gemfile.lock` de Ruby Gems ou o `package-json.lock` do NPM. Como no caso de
gerenciamento de dependências, há motivos para você commitar sim o `.lock` no
controle de versão. Leia mais sobre esse lock na
[documentação oficial](https://developer.hashicorp.com/terraform/language/files/dependency-lock)

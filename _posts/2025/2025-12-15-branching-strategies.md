---
layout: post
title: "Escolhendo uma estratégia de branching (e porque TBD é a escolha correta)"
author: "Jefferson Quesado"
tags: software-engineering git
base-assets: "/assets/branching-strategies/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Existem algumas estratégias de modelo de contribuição quando estamos em equipe.
Quando a equipe é pequena, provavelmente nem se preocupa muito em como isso é
cimentado, todo mundo dá um jeito de enviar as alterações para o repositório.

Mas eventualmente o projeto pode crescer. E com isso surge a necessidade de
prover uma organização, uma estrutura de colaboração. E na era de git e GitHub,
isso normalmente vem através de um esquema de como o seu código vai entrar no
`main` do repositório.

# A não estrutura

No começo, você não precisa de muita estrutura para colaboração no projeto.
Você faz parte de uma _euquipe_. Apenas você e seus pensamentos. Nesse momento,
o código é seu e ninguém mais toca.

Hoje em dia é costumeiro fazer tudo via git/repositório. Mas... nem sempre é
assim. As vezes você só tem arquivos soltos no servidor e é isso. Mas... bem,
você já precisou dar manutenção em um projeto assim sem controle de versão? É
bem caótico... e também não é confiável.

Então, a completa ausência de não estrutura é só arquivo solto. Talvez um
artefato que você compilou na mão e subiu no servidor? Ou um executável que
você enviou por pen-drive para ser instalado? Enfim, esse é a maior ausência de
estrutura possível.

E também tem o mínimo atualmente. O mínimo comum é "ter um repositório". Isso
bem dizer significa que você tem uma cópia do seu código que você pode fazer
testes e experimentações mais a vontade. E quando estiver satisfeito, você
commita esse código, tornando ele mais "oficial".

Quando você não tem uma equipe, isso basta. E o git permite trabalhar assim, já
que você não precisa de um servidor para guardar o seu código. O bom de
trabalhar assim perante a ausência completa de repositório é que você pode
controlar sim o que entra. Quando sobe a aplicação no servidor (para o caso de
webapp), você pode pegar de um repositório limpinho, sem alterações locais, no
lugar de confiar unicamente na disciplina de saber fazer o build direitinho
localmente ignorando as mudanças locais experimentais.

Essa simples estrutura permite que você tenha um ambiente de dev e um ambiente
de produção.

# Quando a equipe cresce

É natural que em um trabalho corporativo você não seja o único desenvolvedor no
projeto. Que você eventualmente passe a trabalhar com outros desenvolvedores ou
que você entre em uma equipe para manter/expandir um software.

O uso do git permite que cada ambiente de dev seja efetivamente isolado. Em
tese o SVN e outros sistemas de controle de versão de segunda geração permitem
isso, mas o histórico normalmente é compartilhado (enquanto que no git o
histórico é local, só sendo compartilhado quando desejado) e único.

Num começo de equipe, talvez não haja necessidade de grandes estruturas de
colaboração. Então é bem capaz que a "não estrutura" satisfaça. Todo mundo
trabalha na branch `main` e empurra para o repositório.

Mas aí, o que garante que o que você fez e o coleguinha fez não entre em
conflito? Na real, apenas todo mundo commitando a bel prazer? Nada. Torça para
que conflitos sejam conflitos a nível de arquivo, porque se for uma mudança de
API que foi usada em um código novo seu porém que o coleguinha removeu porque
ela é danosa para a abstração? Aí já era. O conflito não é detectado pela
ferramenta de controle de versão. Você só vai conseguir detectar algum problema
se tiver algum processo que faça uma validação mínima do código.

Quais são essas verificações?

Bem, a primeiro momento, rodar o projeto. Em langs que precisam de compilação
de todos os componente, você vai ser avisado sobre isso. Agora... e se por
acaso você estiver em uma lang interpretada e não passou por aquele caminho?
Então aqui você não detecta. Fica sujeito à sorte de usar aquele trecho do
sistema ou não.

Muito provavelmente uma equipe maior tem um processo de garantia de qualidade
que indica que o c;odigo precisa ser testado. Isso funciona até certo modo com
"código quente". Código frio... bem, nem tanto. Aqui o código é "quente" tipo
um pãozinho carioca que acabou de sair a fornada, fumaçando e cheiroso e que
atrai as atenções. Mas nem toda mudança de conflito desse tipo vai ser código
quente com código quente. As vezes uma alteração torna um código frio inválido.
Por exemplo, alterar os parâmetros de uma query SQL. Se você assumir que no seu
caminho o valor de um dos parâmetros vai ser sempre não nulo e colocar na query
que a coluna precisa ser igual a esse valor... e no código frio esse valor não
for preenchido... bem, aí já viu, né? A query antiga vai trazer um result set
vazio como resultado.

Então o processo de validação de código quente não é suficiente. Devemos testar
então todos os códigos sempre?

Bem... se eu disser que... sim? Você fica surpreso?

Mas aqui não precisamos que seja uma pessoa de fato testando. Lembra no começo
do conflito quando há quebra de compilação? Então... e se adicionarmos testes
automatizados?

Com a adição de testes automatizados podemos invocar o teste para verificar se
inserimos alguma coisa que deixa o código inválido. Ele passa a ser um nível a
mais de validação que não apenas "o código escrito pertence à gramática da
linguagem". Ele serve para dar um aval mínimo que para algumas situações o
código funciona, um pequeno proxy para qualidade.

Aqui conseguimos aferir a qualidade do código a qualquer momento. Basta baixar
do repositório e testar. Mas... isso vai dar uma garantia: de que o código que
estamos rodando localmente não esteja absurdamente quebrado. Mas isso não
impede que código entre no repositório quebrado.

Para ter uma garantia maior em relação a isso, para evitar que código entre
quebrado, precisamos validar que o código que foi empurrado vai passar nos
testes. Isso é alguma coisa mais concreta.

A partir desse momento o repositório vai começar a apitar que as coisas começam
a dar errado. Mas mesmo assim esse aviso acontece após o fato. E se quisermos
mesmo evitar que código entre quebrado? Nessa situação precisamos ter uma
barreira que impeça a entrada de código não validada.

E uma das alternativas para isso é o _pull request_ (na terminologia do GitHub,
ou _merge request_ na terminologia do GitLab; são essencialmente a mesma
coisa). No _pull request_, ou simplesmente PR, podemos colocar uma trava nele
que impede o código de entrar até que ele passe no teste. No GitLab eu costumo
colocar algumas travas para essa garantia, entra elas a de que o código não
pode entrar se o teste falhar, portanto a opção de mergear o código vai estar
desabilitada até o fim do teste.

> Uma coisa interessante do GitLab é que eu posso clicar no botão "mergear se
> o teste passar", o que significa que eu não preciso ficar guardando caixão
> até o teste terminar.

Mas sabe outra coisa que o PR possibilita também? Ele vai estar com o
diferencial do código disponível para leitura... então por que não revisar?
Por exemplo, eu tentei fazer uma contribuição para o Jekyll esse ano, lá por
Fevereiro:
[https://github.com/jekyll/jekyll/pull/9776](https://github.com/jekyll/jekyll/pull/9776).
Porém [@ashmaroli](https://github.com/ashmaroli) detectou alguns pontos que eu
não fazia ideia do comportamento e isso impediu uma regressão importante de
entrar.

Bem, já que agora estamos falando em PR, isso significa que uma alteração passa
a ter um ciclo de vida. A pessoa desenvolvedora trabalha em uma modificação,
então ela precisa ter um branch. Esse branch precisa ter uma origem, e para uma
equipe que está crescendo essa origem precisa ser bem definida. Depois disso,
essa alteração precisa ser empurrada para uma outra branch. Para esse empurrão
funcionar, precisamos validar, e validação humana normalmente não é suficiente,
porque normalmente somos enviesados para validar rumo ao "código quente" e
precisamos garantir o "código frio" também, então para isso precisamos ter
testes que rodem automaticamente no repositório. Nesse momento, pode ser uma
estratégia da equipe permitir que o código só seja integrado completamento após
a validação desses testes. Aqui entra também o processo de revisão de código,
em que outra pessoa vai analisar o código para entender a mudança e aprovar ou
não o código. Se reprovar normalmente se espera que venha com pontos de crítica
indicando pontos para melhorar o código, ou alguma falha incipiente e inata
à alteração específica que indique o porquê aquilo precisa ser imediatamente
fechado.

# Fluxos de trabalhos variados no mundom selvagem

Vou entrar em detalhes de fluxos de trabalhos depois, mas vale a pena dar uma
destacada em alguns para explorar depois. O site da Atlassian comenta sobre uns
4 worflows em
[https://www.atlassian.com/git/tutorials/comparing-workflows](https://www.atlassian.com/git/tutorials/comparing-workflows):

- centralizado
- feature branching
- gitflow
- forking

Bem dizer o "centralizado" que ele menciona é semelhante à ausência de
estrutura mencionada no começo desse post. Feature branching é um mecanismo em
que o desenvolvimento de algo vai em um mundo apartado, permitindo um
desenvolvimento em um cenário ideal sem atrito nem resistência do ar...

[![Como seria colocar um físico em um ambiente sem atrito nem resistência do ar?](https://imgs.xkcd.com/comics/experiment.png)](https://xkcd.com/669/)

O gitflow você trabalha em uma versão instável, e corrige na versão estável se
necessário. Esse workflow será bem explorado depois.

E finalmente existe o forking... bem, ele não quer dizer muita coisa além de
que o repositório "sagrado", que vai ser usado como base para gerar o sistema
será estruturado, apenas que cada pessoa desenvolvedora vai ter o seu próprio
fork do repositório na sua própria conta.

O GitHub sugere o
[GitHub Flow](https://docs.github.com/en/get-started/using-github/github-flow).
Até que se prove o contrário é muito similar ao feature branching que a
Atlassian descreve.

GitLab faz um
[apanhado de algumas estratégias](https://docs.gitlab.com/user/project/repository/branches/strategies/).
Acho legal que ele descreve, sem citar nominalmente, o que em outros cantos se
chama de feature branching: você trabalha em uma feature branch, então empurra
pra main.

Em seguida o GitLab faz uma série de perguntas sobre o seu produto, como você
colabora, como as coisas se encaixam etc. Para web services ele menciona o
gitflow, porém "você não precisa pegar tudo do gitflow".

Depois sugere o que chama de "long lived release branches", e indica situações
em que esse fluxo pode ser adequado e normalmente isso se dá com múltiplas
versões vivas, como SDKs que você precisa manter funcionando com coisas do
passado.

E por fim, também menciona "branch por ambiente".

A AWS
[menciona 3 estratégias](https://docs.aws.amazon.com/prescriptive-guidance/latest/choosing-git-branch-approach/git-branching-strategies.html):
TBD, GitHub Flow, e gitflow. Aqui o TBD é o desenvolvimento em que o
repostiório está sempre pronto para ser deployado, GitHub Flow é o feature
branching já mencionado e o gitflow é o já conhecido gitflow.

## Martin Fowler

Finalmente, temos aqui uma menção quase que obrigatória ao Martin Fowler. Em
seu [artigo sobre padrões de branching][mf-branching], Fowler fala sobre
diversos padrões e como eles se encaixam em diversos workflows.

Ele cita nominalmente 3 workflows: gitflow, GitHub Flow e TBD. Ele diferencia o
GitHub Flow do TBD no que tange à completude da feature: no GitHub Flow o
branch só é mergeado quando a feature está completa, já no TBD há a questão de
mergear coisas logo no main (mas sem jamais quebrar o main).

Entre os padrões de uso de branching, Fowler lista várias coisas bem legais de
se conhecer, aqui um apanhado de coisas que eu achei relevante:

- feature braching: "sem atrito nem resistência do ar"
- integração contínua: commit saudável? Manda pra frente!
- release branches: quando você prepara a release
- maturity branches: branches de coisas já lançadas
- mainline saudável: é a prática de que o main está sempre feliz, passando no
  teste
- review pré-integração: revisão de código, code review, PR review etc
- branch de ambiente: um anti-pattern para separar ambiente com pedaços de
  código
- hotfix branch: branch de correção de emergência; ele apresenta algumas
  soluções para reintegrar de volta ao main
- release train: cadência de lançamento, normalmente em schedule fixo e
  antecipado
- release-ready main: o branch principal pronto para ser lançado
- future branch: coisa disruptiva que não quero na versão atual, mas na
  seguinte ou mesmo em outro futuro mais distante

# Gitflow

Gitflow é o modelo de workflow que eu acho que é o mais conhecido/praticado no
mundo de desenvolvimento de software corporativo. Ele foi descrito por nvie
no post
[A successful Git branching model](https://nvie.com/posts/a-successful-git-branching-model/).

Basicamente, temos uma versão lançada, e ela é a main (na época da escrita do
post o padrão de chamar o branch principal do repositório era chamar de
`master`, a mudança para o padrão `main` é bem mais recente que o post). Esse
branch só muda por 2 motivos:

- correções quentes
- lançamento de novas versões

As correções nunca dizem quando vão surgir, então a qualquer momento pode ser
necessário alterar a versão de produção. E a versão de produção "é" _sempre_ a
ponta do main. "É" entre aspas porque pode diferir de algum hotfix feito e
ainda não lançado, ou mas isso deveria ser uma completa exceção visto que
hotfixes deveriam ser lançados tão logo estejam prontos.

O trabalho bem dizer acontece no branch de desenvolvimento, o `dev`. Esse
branch tem mais motivos para ser alterado:

- adições de features
- correções de integrações/coisas da dev
- propagação de correções da main
- propagação de correções da release

As "correções de integrações" podem surgir devido aos eventuais conflitos
mencionados na seção [Quando a equipe cresce](#quando-a-equipe-cresce), quando
por algum acaso não havia cobertura e a integração de funcionalidades levou a
algum erro, seja com funcionalidades novas ou com "código frio". E isso é algo
que simplesmente pode acontecer, inevitavelmente.

Adição de feature é a evolução tradicional do software. Toda nova feature
envolve um certo risco, afinal é uma mudança, né?

Propagações é... bem, só isso. Código que foi corrigido na main precisa
retornar à dev, e o mesmo pra correções na release.

Finalmente, temos a release branch. Se a dev estiver saudável, a release vai
estar pronta para entrar na main. Mas esse branch está ali para eventual
necessidade de estabilidade/correção de coisas que não foram feitas na branch
dev. Vai que passou algo, né? Seu fluxo de vida é: nasce da dev, sofre
alterações, vai pra main e morre.

A cada lançamento de nova versão (não hotfix, claro), precisa de uma nova
release. E assim o fluxo de vida segue.

A necessidade para a branch de release é porque naturalmente a branch de dev é
instável. Ie, não há garantias de que ela esteja _production ready_. A main,
entretanto, é sempre _production ready_.

# Feature branching

Aqui a ideia é que o desenvolvedor parta da main e retorne para a main com o
trabalho concluído. Diferentemente do gitflow, não há duas fontes de branches,
só uma.

Pipelines de CI podem fazer com que a main esteja mais confiantemente
deployável, mas no feature branching clássico isso não é garantido.

O [GitHub Flow](https://githubflow.github.io/) propriamente dito fala que ele
não tem branch de release pois está sempre deployável, mas nem toda estratégia
de feature branching fala que isso precisa ser garantido. Eu particularmente
vejo o GitHub Flow como uma variação do feature branching.

Muito tempo atrás (se não me falha a memória) no post da Atlassian sobre
workflows com repositórios mencionava "GitHub Flow" como a estratégia de
colaboração através de forks, mas particularmente toda fonte que eu vejo sobre
GitHub Flow não menciona essa necessidade de fazer forks, nem tampouco isso
IMHO é algo em essência, mas sim mais um detalhe de implementação.

# Trunk Based Development

Aqui, toda mudança auto-contida que não quebre deve voltar ao `trunk`, à main.
Basicamente, isso, e manter sempre a main pronta para produção!

Uma vantagem desse método de desenvolvimento é que ele é bem automatizável. O
TBD é uma maneira de alcançar entrega contínua (o que não quer dizer deploy
contínuo). Com o código pronto para entrar em produção, o que evita que você o
suba?

Código que não vê a cara de produção envelhece como leite, ele não está exposto
às intempéries para saber se ele vai sobreviver ou se na release da próxima
versão ela será xoxa, capenga, manca, anêmica, fraca e inconsistente. Com o TBD
há incentivos para que o código constantemente respire o ar produtivo, se não a
cara atualização, a cada dia por exemplo.

Com o código sempre sendo exposto aos inconvenientes produtivos, necessidades
de alteração são percebidos e remediados. Um bom loop de feedback entre
operações e desenvolvimento torna isso mais fácil de lidar.

Diferentemente do feature branching, em que a alteração só é mergeada quando a
feature está completa, o TBD favorece que você quebre a "entrega" grandiosa em
partes menores. Inclusive, na
[referência sobre TBD](https://trunkbaseddevelopment.com/) existe uma seção
sobre
[branch by abstraction](https://trunkbaseddevelopment.com/branch-by-abstraction/)
que vai versar justamente sobre alternativas para manter o código novo sendo
adicionado mesmo que o destino final ainda não tenha sido alcançado.

# Branch por ambiente

Um completo absurdo em que um branch é colocado para indicar onde aquele código
está. Útil para saber qual a versão do ambiente específico mencionado em um
eventual chamado? Talvez, se o chamado for muito fresco.

Mas, por que você iria querer fazer branching de ambiente? Vai ter alguma
mudança de código que seja específica de ambiente? Se for, isso ofende
diretamente os 12 fatores, principalmente o primeiro 1) base de código: uma
única base de código, múltiplos deploys; mas também ofende o terceiro
princípio 3) configuração: armazene a configuração no ambiente (não no código).

Martin Fowler reitera que isso é um anti-padrão no seu [artigo sobre sobre
padrões de branching][mf-branching]: parece algo promissor e tentador, como
todo anti-padrão, mas rapidamente leva a um mundo de sofrimento. Aqui, no lugar
de dar suporte a uma base de código, você vai passar a dar suporte a várias
versões, cada uma manca de uma maneira, e vai precisar fazer uma magia para
reaproveitar uma resposta em um branch de ambiente para o branch principal, ou
para outro ambiente. E talvez a mudança de branch de ambiente torne algo
incompatível com o branch principal, e você precisa viver com a divergência de
versões já que o código do branch de ambiente não pode ser integrado no branch
principal, e o código do branch principal não pode ser integrado no branch do
ambiente.

# Mas por que você defende o TBD?

Bem, vamos primeiro comparar o TBD com o feature branching. Primariamente, com
a variante "GitHub Flow".

No GitHub Flow, o branch principal sempre precisa estar pronto para lançar. No
TBD, também. Mas... qual a diferença então? Bem, no GitHub Flow em tese você
lança o PR quando a feature está completa o suficiente. O que isso pode
significar que há incentivo para reter o desenvolvimento e entregar uma coisa
maior. Por quê? Porque há uma maior fricção de entrega.

Quando você entrega algo maior, o risco se torna maior. Com o risco maior, há
incentivos para que a pessoa que integre o código segure mais e coloque mais
barreiras. Então, como podemos minimizar essa fricção, deixar menor o impacto
da entrada de código?

Bem, se a integração do código não quebrar nada, fica mais fácil aceitar, né?
Para isso temos testes, eles são um proxy para qualidade da entrega. Além
disso, podemos entregar coisas menores para permitir a entrega. Então, no caso
de entregar uma feature inteira, um tíquete inteiro, podemos integrar, por
exemplo, aquela refatoração que seria necessária para poder começar o
desenvolvimento.

E... isso traria alguma vantagem? Sim, claro que traz! O código que você
escreveu, que acha que não vai ter impacto, você já pode colocar para começar a
botar pra valer. Afinal, se não tem impacto, por que não por pra frente, né?
Você tem métricas (proxy? Proxy, mas alguma forma de métrica) que corrobora com
essa intuição de que não houve mudança. E se trouxer algum impacto? Bem, se
trouxer algum impacto, tem duas alternativas para isso: a primeira é detectar
cedo, onde apenas aquilo foi entregue e que é fácil desfazer. A outra é
entregar essa pequena mudança aparentemente inócua junto com outras coisas e
ver o pactoe como um todo quebrando ao mesmo tempo. Então fica difícil
discernir exatamente o que deu ruim.

Assim, pequenas entregas, mesmo que não sejam a completude total do que motivou
a mudança, tornam a fricção de entrada menor. Para times que fazem revisão,
fica melhor revisar aquele contexto específico. De toda sorte, o risco é
minimizado e antecipado: menor entrega, menor risco.

Mas... e se o pequeno pedaço não pudesse ser acessível? Bem, nesse caso você
tem diversas estratégias, como shadow release, feature flag, teste A/B, alguma
coisa assim. De modo que o código novo está integrado, por mais que
inacessível, e portanto em algum contato com o mundo real. Isso é mais uma
métrica proxy de que a mudança no código não foi ruim.

Então, qual a diferença maior entre GitHub Flow e TBD? Branches de vida curta.
Feature branch com vida longa causa alguns problemas, entre eles um é que
código que não está em produção envelhece como leite. O código de um long lived
branch é feito em cima de um conjunto de premissas que foi congelado no tempo.
Porém, quanto maior o intervalo de tempo entre "estou assumindo essa premissa"
e a entrada do código na base de código, maior a chance de que essas premissas
não sejam mais verdadeiras. E muitas vezes essas premissas não são nem tomadas
de maneira consciente, eles são assumidas como verdade de modo totalmente
intuitivo, ou pelo simples hábito de que aquilo sempre foi verdade que em
nenhum momento se cogitou que talvez aquilo pudesse vir a ser alterado.

Tá, e em comparação a feature branching geral? Bem, no feature branching tem um
ponto que falta em relação ao GitHub Flow, e que eu considero de extremo valor:
ele não tem o "ready to deploy". Como não tem o ready to deploy, ao decidir
lançar uma versão no ar, você precisa passar por um tempo de estabilização,
fazer um release branching. Mas, sabe qual o tempo ideal para se ter um release
branch? O ideal seria que o tempo fosse mínimo! 0 minutos, só validar que está
saudável e mandar pra frente. Afinal, trabalho feito em release branch é um
trabalho que adia lançamento de valor. E adiar lançar valor não é bom, é?

> Claro, estou considerando aqui lançar _valor_, não lançar algo que vá afetar
> negativamente o produto/empresa.

Como o software não está pronto, ele precisa ser segurado por mais um tempo, e
isso poderia ser evitado se o software estivesse sempre pronto para lançar. A
decisão estratégica da empresa que quis fazer assim é que não vale o custo
manter sempre o sistema a ponto de lançamento. Eu entendo que a empresa
enxergue desse jeito, o que não quer dizer que eu concorde que o tradeoff aqui
valha. Branch de release, branch de estabilização antes do deploy, é sempre um
custo imposto antes de lançar o sistema e uma possível perda de oportunidade. O
ideal é não ter esse custo. Mas entre ter esse custo e um retorno negativo de
um lançamento ruim, obviamente que é melhor pagar pela estabilização.

Agora... o que acontece quando se segura um lançamento? Features ficam
atrasadas, o moral do time de desenvolvimento que se importa com o produto fica
abalado porque as mudanças que foram feitas não enxergaram a luz do dia.
Segurar lançamentos também significa que correções ficam embarreiradas.
Eventuais atualizações de segurança ou entram via alguma gambiarra no processo
ou vai ficar atravancada esperando a estabilização.

E então, quando você segura demais, tem muita coisa a ser lançada ao mesmo
tempo. E o pior disso, de quando você segura por muito tempo, é quando dá
errado o lançamento. Aqui não é o trabalho de dois dias, de uma semana, mas as
vezes trabalho de meses. Nessa situação, tem muitos clientes que se
beneficiaram com a nova versão, e teve também aqueles clientes que aquela nova
versão simplesmente não só não atende, como é um valor negativo em comparação à
versão anterior. O que fazer nesse caso?

Existem algumas estratégias, como no caso de web fazer uma multiplexação para
que, naquele intervalo de tempo para aquele conjunto de clientes, uma versão
anterior seja utilizada. Isso gera um custo de ferramental e de infraestrutura
que nem sempre é viável manter. E fazer um rollback vai causar impactos
negativos nos outros clientes que precisavam de novas features lançadas, ou que
estavam esperando uma correção, ou que por acaso uma melhoria feita deixa o uso
do sistema mais fluido.

Eu já passei por essa situação, o lançamento da versão era essencial para
corrigir alguns pontos do sistema que desafogariam o banco de dados. Mas
infelizmente um efeito colateral não previsto de uma customização afetou o
negativamente uma outra funcionalidade core para alguns clientes, e isso não
foi detectado durante o tempo de estabilização, durante a release branch. E
para piorar a situação foi preciso aplicar migrações no banco de dados que
deixava o sistema não compatível com a versão anterior, necessitando rollback
não trivial de banco.

Mas, sabe o que não tem atrito em caso de lançamento que dá errado? Quando o
lançamento é feito em cima do trabalho da tarde anterior. Também passei por
isso, a nova versão que se assumia que se estava saudável para sair não estava.
Em menos de 2 minutos eu havia feito o rollback, não ofereci resistência. E
direcionei a equipe para a correção e para trabalhos preventivos para detecção
dessa regressão no futuro.

Agora, vamos imaginar um outro cenário... imagine que eu estou trabalhando em
uma nova versão, cheia de features. E foi detectado um problema 0-day de
segurança em produção. E se eu tivesse registrado o ponto da versão de
produção? De modo que eu trabalhasse em um mundo do futuro a ser lançado, mas a
versão de produção estava lá, ao meu alcance?

Bem, com isso podemos a qualquer momento evitar a questão de lançar uma nova
versão com correções. Pode ser correção de segurança, algum bug que atrapalhava
a vida do usuário, alguma melhoria de performance urgente porque o banco está
topando. Eu posso corrigir a versão presente, e mandar para o futuro novas
mudanças mais críticas. Parece uma boa, né?

Isso descrito acima é em essência o gitflow. No papel parece uma boa ideia e eu
defendi por bastante tempo o gitflow. A versão de produção é o `main` branch, e
a versão em que o grosso do trabalho é feito é a `dev` branch. E com isso temos
um distanciamento entre a versão futura e a versão de produção.

Um dos efeitos desse distanciamento é que, as vezes, o desenvolvedor faz uma
correção que ele acha que só existe em dev, pois foi evidenciado em uma
atividade que ele estava trabalhando. Ele vai lá e corrige. E então ao mergear
essa correção, as outras pessoas desenvolvedoras não passam mais a ver aquilo
no "código de trabalho". E quando o usuário reclama de que aquele problema está
acontecendo, vai demorar um tempo entre perceber que aquilo não acontece com o
código de trabalho e em como corrigir. E o pior, de algo que já foi resolvido!

Isso me levou a criar um mecanismo interno na época: "ao corrigir algo,
verifique a origem desse algo; se vier de algo da `main`, faça a correção como
se fosse um hotfix". E, bem... isso chegou a existir mais vezes do que eu
gostaria de admitir. Muitas correções sendo feitos porque foi identificado um
mal comportamento em `dev`, então foi investigada a origem e ela era de algo
que estava na `main`, então era feita a correção na `main` e depois propagada
para a `dev`. O trabalho da pessoa desenvolvedora era maior com mais overhead.

Eventualmente, chegava o fatídico dia em que se começava o release branch. A
branch de `release-candidate` era criada e o investimento de estabilização era
iniciado. Toda tentativa de release era marcada no sistema de versionamento,
se colocava no ar no ambiente interno, passava pelo processo de validação.
Novos problemas eram encontrados e corrigidos, e novas correções vinham, até
que as partes envolvidas estavam satisfeitas. E nesse momento o lançamento era
feito.

Mas esse processo não era tão bonitinho assim... as vezes uma versão de release
demorava bastante tempo sendo validada e revalidada. E o que acontecia com a
versão de `dev`? Bem, ela seguia. E a distância entre `dev` e a release só
aumentava. E com isso a versão entre release e `main` aumentava. Até que
eventualmente chegava o momento em que o release era tido como satisfatório. E
com isso aquelas mudanças viam a cor do dia.

Mas... sabe algo que poderia acontecer também nesse intervalo? A versão de
`dev` acumulou tanta coisa positiva para entregar que entregar aquela release
em que se estava trabalhando não fazia mais sentido. Nessa situação, a release
falhou. As mudanças de estabilização obviamente já foram aproveitadas para a
versão de `dev`, e então uma nova release era trabalhada. E isso era
frustrante. E isso deixava a entrega lenta, e a entrega final pesada, com
muitas mudanças e muita fricção para entrar.

Mas sabe o que seria ótimo de ter no gitflow? Uma branch de `dev` que estivesse
sempre ready to deploy. Estando ready do deploy, sabe o tempo que seria gasto
com estabilização de release branching? Isso mesmo, 0, zero, nada, nadica. A
release estaria pronta imediatamente. E sabe como mitigar ao máximo a fricção e
a diferença entre a versão de trabalho e a versão de produção? Para cada merge
feito na branch `dev`, uma release ser puxada e, como a está sempre pronto para
encarar o mundo selvagem, colocado em produção.

Assim sendo, a diferença entre `dev` e `main` seria zero. Toda correção feita
na `main` já é prontamente propagada para `dev`. E aqui toda mudança feita na
`dev` entra em um intervalo de tempo curtíssimo, quase zero, na `main`. `dev`
está sempre em sincronia com as mudanças da `main`, e a `main` fica no máximo
um commit atrás da branch `dev`, sendo essa mudança rapidamente convertida em
release e, portanto, zerando essa alteração.

Então... `dev` não fica a frente da `main`, e a `main` não fica a frente de
`dev`... por que diferenciar as duas então? Com essa frequência de lançamento,
a `dev` e a `main` efetivamente se tornam branches que apontam para o mesmo
estado do repositório, efetivamente são sinônimos. Se são sinônimos, por que
não adotar um único nome para isso? E ela se chamaria... `trunk`!

E é por isso que eu defendo que o TBD é a estratégia correta, você está sempre
pronto para lançar versão, todo mundo trabalha com uma mesma verdade no código,
não precisa ficar dando manutenção em 3 versões diferentes com estabilidades
questionáveis. Menos distanciamento entre o que a pessoa desenvolvedora
enxerga, mais fácil fica navegar no código, mais fácil corrigir, mais fácil
lançar novas versões.

# O correto é sempre TBD?

Bem, eu sou do mundo SaaS. Eu creio que basicamente o leitor aqui do Computaria
trabalha mais com SaaS do que com outros tipos de software.

Mas nem sempre é possível trabalhar assim, sempre na ponta, até mesmo em SaaS.
Eu recomendo fortemente que o trabalho seja desenvolvido em uma única ponta.
Para um bom TBD eu creio que fazer lançamentos com frequência seja crucial para
garantia de estabilidade do software. Mas e quando você não tem agência sobre
isso?

Já peguei situações (bem caóticas, que se diga) em que o desenvolvimento do
mesmo sistema foi feito por 3 equipes diferentes, cada equipe cuidando de uns
5 ou 6 clientes diferentes (normalmente correlatos). E nesse esquema, o que
aconteceu foi que cada equipe desejou ter agência sobre o seu código e sobre o
seu deploy. Justo? Justo. Mas com isso se tinha 12 versões de código (a versão
basal + as 3 equipes totalizando 4 bases de código, juntando a isso uma `main`,
uma `dev` e sempre uma `release` de estabilização, 4 bolos de código vezes 3
branches por bolo).

E sabe o que foi pior disso? Que algumas equipes começaram a ter necessidades
específicas de atender clientes específicos. Então se antes a equipe tinha lá
3 versões próprias + 3 gerais para ficar de olho, agora passavam a ter 6
versões prórias, as vezes 9 ou 12! E junta a isso o trabalho com as outras
equipes.

Esse modelo obviamente faliu e a separação dessas equipes foi dissolvida. Essa
foi uma estratégia ruim de modo geral.

Mas mesmo assim, teve um cliente em especial que se manteve especial. Esse
cliente tinha um ciclo de vida diferente, porque ele não contratava o software
como um SaaS, mas sim contratou para ter ele dentro da própria infraestrutura.

E nessa situação sabe o que fazia sentido? Manter um histórico (que podia ser
uma anotação em um documento) de qual a versão atual do cliente. E sim, as
vezes tinha necessidade de mudança específica. E não existia outra solução alén
de corrigir. Nem sempre o cliente estava disposto a aceitar uma nova versão que
diferenciou por meses da versão estável o suficiente que ele usa. Então nessas
situações se faziam correções com aquilo que ele precisava, as vezes se
percebia que aquela reclamação era uma reclamação que outro cliente passou e
que já havia sido corrigido no passado e as vezes se conseguia convencer a
homologar a nova versão.

Para o caso em que a infraestrutura e o deploy não ficam no controle da firma,
faz sentido puxar correções em pontos do passado. Vai aumentar a carga
cognitiva de quem está fazendo a manutenção? Provavelmente, mas vai ser
necessário. O melhor nessas situações é ter o mínimo de versões divergentes o
possível, mas nem sempre isso será possível.

Usar feature flags, dark launches e outras estratégias para mitigar possíveis
danos derivados de alterações também é algo bem interessante. Mesmo que o seu
software tenha uma cadência mais lenta do que "contínua"/"diária", trabalhar
assim permite que ele esteja sempre "ready to deploy", o que é um benefício
muito grande na hora de por no ar.



[mf-branching]: https://martinfowler.com/articles/branching-patterns.html
---
layout: post
title: "O dia em que precisei estudar HTTP, para otimizar a aplicação"
author: "Jefferson Quesado"
tags: http totalcross java redes otimização
base-assets: "/assets/o-dia-que-estudei-http/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

> Otimização precoce é a raiz de todo o mal.

-- Donald Knuth

Eu trabalhei para uma empresa cujo um dos principais produtos era um aplicativo
mobile para força de vendas. E uma das features mais visualmente atratativas
era o catálogo de produtos: um conjunto de fotos relevantes dos produtos sendo
vendidos.

Mas tinha uma particularidade muito interessante desse força de vendas: ele era
capaz de operar 100% offline para a realização das vendas, fazendo a
transmissão dos pedidos quando o vendedor entrava em um local com rede
novamente. Portanto, para usar o catálogo, ele precisava baixar as fotos a
priori.

Muito tempo se passou depois da entrega dessa funcionalidade, e de modo geral
as pessoas estavam usando para fazer um catálogo com meia dúzia de produtos
mais visados. Naquela época, os produtos de força de vendas aparentemente não
precisam ter muito apelo visual.

Mas chegou o fatídico dia: o dia em que a empresa que usava o sistema precisou
de mais de 300 fotos para exibir o catálogo.

# O problema do catálogo, visão do usuário

O app dizia que precisa baixar fotos. Essa etapa era opcional, e o app tratava
de baixar todas automaticamente, sem intervenção humana. Para tal fim, o
usuário tinha um botão para baixar as fotos e outro para apagar o que foi
baixado previamente, fornecendo assim a capacidade de resetar os dados caso
veja algum problema.

Mas, após começar o download, o usuário precisava esperar que o programa
terminasse a execução. Não havia o que fazer enquanto a thread principal fazia
o download das fotos. E isso para aquele cliente específico durava _horas_. E
depois de tudo isso? Falhava.

E o app não fornecia uma alternativa para recuperar-se e continuar o download
de onde parou.

Ou seja: era um jogo de tudo ou nada em que ele precisava sempre iniciar uma
nova partida e que era quase garantido ele perder. O usuário estava bem
insatisfeito, e a sua única alternativa era realizar as vendas sem o catálogo.

E o cliente, que pagou para o seu vendedor tivesse o catálogo na mão, estava
insatisfeito pois escolheu o fornecedor e pagou um valor premium por conta do
catálogo.

# As tecnologias envolvidas

O catálogo de fotos era feito em cima de URLs. Mas a priori, não há pecados em
URLs, não é? Só que cadastrar manualmente múltiplas URLs para uma centena de
produtos era um processo oneroso. Existia um método de bulk-upload do catálogo,
que fazia a ligação do produto com a foto através de uma convenção com o nome
do arquivo.

Isso implicava que as fotos quase todas estavam na AWS, em um bucket S3.

Antes de enviar para o S3, as fotos passavam por um processo de minificação,
pois afinal não precisava ter qualidade de impressão em um outdoor (muitos
uploads eram feitos com fotos em altíssima resolução). Então essas fotos, cujo
upload era gerenciado pela firma, já passavam por uma grande camada de
otimização de tamanho. Sim, era uma espécie de _lossy compression_, mas ainda
gerava uma imagem aceitável nos smartphones alvo. Até mesmo no tablet a imagem
não era ruim.

Além disso, o produto era feito em cima do TotalCross. E foi justamente erro
nosso, ao usar o TotalCross, que ocasionou nos problemas de performance.

## Uma visão por cima do TotalCross

TotalCross é uma plataforma para desenvolvimento de aplicativos móveis. A
promessa é: você desenvolve uma vez e entrega em todos os lugares. E um
executável TotalCross é bem rápido.

Para fazer um programa em TotalCross você escreve código em Java, compila esse
código e passa para um comando chamado `tc.Deploy`. Esse comando vai pegar os
bytecodes das suas classes e transformar em bytecodes para TCVM, no final das
contas gerando um arquivo `.tcz`. Falo com mais detalhes sobre isso no post
[TC Compiler Help - um apoio a fazer o build de bibliotecas]({% post_url 2021-12-31-tc-compiler-help %}).

Mas, afinal, o que é a TCVM? É uma máquina de registradores, em contraponto à
JVM que é uma máquina de pilha. O processo de compilação dos bytecodes 
para bytecodes TCZ envolve uma transformação que não é 1:1. A TCVM é o único
pedaço que precisa ter target específico de plataforma, pois ela pega os TCZs
gerados e os interpreta.

Na época do Java 1.5, o TotalCross já oferecia um aporte muito grande aos
bytecodes gerados ao passar as classes pelo `javac`. Então nesse sentido a TCVM
suportava bem código Java compilado. Mas... bem, Java não é só o conjunto de
bytecodes sendo executados, também depende de outra parte muito importante: o
que o mundo Java chama de JRE: Java runtime environment. No caso, posso chamar
de TCRE?

O conjunto de libs padrão fornecidas pela TCRE eram amplamente compatíveis com
Java, mas não totalmente compatíveis. Um exemplo? A API de arquivos no
TotalCross é completamente distinta da API de arquivos no Java. Apesar de que
existe um mapeamento aproximado do que é `java.io.*` ir para `totalcross.io.*`
e que muita coisa já era feito um mapeamento automático, trocando as classes
compiladas para usar como alvo `java.io.*`, `java.lang.*`, por
`totalcross.io.*`, `totalcross.lang.*` etc. E mesmo com esse mapeamento, o uso
da API de arquivos é completamente distinta, com parâmetros distintos,
filosofias distintas.

Felizmente _quase tudo_ em java.util.* tem na TCRE. Mas, afinal, qual o
problema? Que praticamente tudo feito para ter como alvo Java tradicional
acabava sendo incompatível com TotalCross. Existiam métodos em
`java.lang.String` que não estavam presente em `totalcross.lang.String`.

E, sim, TotalCross também fornecia por conveniência um cliente de HTTP, o
`HttpStream`. Ele era bem _bare bones_. Por exemplo, da [documentação do
TotalCross](https://learn.totalcross.com/documentation/apis/api-rest):

```java
HttpStream.Options options = new HttpStream.Options();
options.httpType = httpType;

HttpStream httpStream = new HttpStream(new URI(url), options);
ByteArrayStream bas = new ByteArrayStream(4096);
bas.readFully(httpStream, 10, 2048);
String data = new String(bas.getBuffer(), 0, bas.available());

Response<ResponseData> response = new Response<>();
response.responseCode = httpStream.responseCode;

if (httpStream.responseCode == 200){
        response.data = (JSONFactory.parse(data, ResponseData.class));
        
        //Accessing the answer and picking up the information.
        msg += "Url: " + response.data.getUrl() + "\n";
        msg += "Origin: " + response.data.getOrigin();
}
```

E um exemplo de como era chamada essa função:

```java
String binUrl = "http://httpbin.org";

Button btnGet = new Button("GET");
btnGet.addPressListener(getPressListener(binUrl + "/get", HttpStream.GET));
```

Por baixo dos panos se usava mesmo o `HttpStream`, mas isso estava oculto por
uma camada mais focada em DX que permitia preparar os headers, o body a ser
enviado, todos esses detalhes com bastante mais calma.

Para ambiente de desnvolvimento, TotalCross fornecia o TCSDK, uma biblioteca
Java, puramente Java, que permitia experimentar como ficaria a aplicação de
modo geral. No geral, para coisas específicas ainda seria necessário de fato
compilar a aplicação para TCVM, mas de modo geral o TCSDK permitia um amplo
leque de análise do que aconteceria ao executar o app.

As versões distribuídas incluiam a versão Android distribuída de modo ad-hoc,
uma versão iOS distribuída de modo _também_ ad-hoc, com um certificado de
geração do app para instalar no celular fora da loja, e também versões Windows
desktop cujo download dependia da vontade do usuário/pressão do gerente.
Mantenha os tipos de transmissão na cabeça, ele será útil na discussão...

# Identificando o problema

Emulamos o teste com uma massa de dados comparável à massa de produção.
Conseguimos um resultado de 40min, não as 3h citadas, mas de toda sorte um
tempo inaceitável de uso. Depois de muito teimar, finalmente fizemos o trabalho
correto de usar a topologia e distribuição de dados no banco de modo a espelhar
produção.

Tá, mas e aí? O que fazer com isso? Dizer para o usuário usar uma internet de
melhor qualidade e um aparelho _high end_? Não, não mesmo. Agora que
conseguimos obter um resultado de tempo, precisamos medir como esses 40min
estavam distribuídos nas atividades do aplicativo, para saber o que exatamente
atacar.

E, bem, sabe a conversa de que o ambiente de desenvolvimento, com o TCSDK
totalmente Java, dava uma visão geral próxima do que aconteceria com o
aplicativo? Bem, Java é bem instrumentado para medir performance e essas
coisas, usamos o [VisualVM](https://visualvm.github.io/) para medir como o
tempo estava sendo gasto.

E o resultado desse proxy de performance foi que uns 80% do tempo era gasto com
as seguintes operações:

- totalcross.io.File#open
- totalcross.io.File#close
- algo dentro de `totalcross.net.Socket#socketCreate`, que após análise da
  época chegou-se a conclusão de que era resolução de nome DNS

E, se a medida do proxy estivesse correta, solucionar essas 3 coisas iria
resolver os problemas. Das 3h que se esperava, iria baixar para 36min só com
essas alterações.

## Uma cisão de soluções

Uma das sugestões dadas para resolver isso foi: não abramos mais sockets, não
abramos mais arquivos. Abramos apenas um único arquivo e um único socket: vai
ser feito o upload de um zip, e iremos baixar exatamente esse zip para o
aplicativo.

Mas essa sugestão indicava que teríamos diversas mudanças. Para começar, as
imagens não iriam passar pela compressão _lossy_, que permitia diminuir o
tamanho delas bastante (já que imagens por natureza não são muito susceptíveis
a mais compressões, provavelmente tendo pouquíssima compressão dentro do zip),
e isso significaria mais tempo de download porque agora o payload é maior. Mas
além disso, isso significava que seria necessário fazer um novo modelo de
vínculo de imagem com o produto, que antes era feito através de uma URL no
banco de dados do dispositivo móvel que apontava para um arquivo local.

E isso significava também que os aplicativos antigos, que estavam funcionando
porque a massa de dados é menor, deixassem de ter um catálogo funcional, pois
isso iria provavelmente quebrar a compatibilidade com o que já existia.

Mas também tinha uma outra alternativa, que eu propus. E que eu concordei com a
visão "um arquivo, um socket", mas discordava dos detalhes. Eu vinha com essa
discussão com duas doses de conhecimento:

- existe um modo de escrever arquivos em ZIP que não aplica compactação nenhuma
- browseres passaram por diversos problemas de performance, e com certeza eles
  tem truques na manga para resolver páginas com referências a múltiplas
  imagens, códigos JS e folhas de estilo

E eu coloquei uma restrição para a solução: precisaria ser retrocompatível,
nenhuma atualização para _manter_ funcionando deveria ser feita.

# A solução final

Para a solução do arquivo, minha sugestão foi: vai ser salvo em um ZIP. Mas a
fonte do arquivo? Tanto faz. Se a pessoa estivesse com uma versão antiga e
atualizasse a aplicação, as referências locais iriam continuar sendo válidas,
portanto não seria necessário nenhuma ação do usuário após atualizar.

E as entradas no arquivo zip (as `ZipEntry`s) seriam armazenadas no modo
`STORE`, não no modo `DEFLATE`. Isso porque o algoritmo de salvar/ler do modo
`STORE` é simplesmente... lidar com cada byte individual. Ele não aplica nenhum
método de transformação de bytes, é a operação identidade.

Isso resolve a treta com os arquivos? Não! Porque agora eu preciso encodar na
URL algo para indicar qual entrada do arquivo zip o arquivo específico se
encontra os meus bytes algo. E eu tirei a solução baseado na leitura que fiz
uma vez de algo dentro de um jar no classpath: usar `!`. Por exemplo:
`file://arquivo.zip!entrada.jpg`. E, agora sim, foi possível resolver todas as
tretas com arquivo.

Ok, agora preciso alterar a outra parte da história: a consulta de DNS. E a
minha busca pela solução não foi uma tentativa de atacar diretamente o
problema, não não não. Eu invoquei minha segunda dose de conhecimento: os
browsers já passaram por isso, e essa história está embebida nas alterações do
protocolo.

HTTP 1.0 funcionava bem para o que se propunha: abrir um socket, enviar uma
requisição, receber uma resposta e fechar a conexão. Só que isso impunha
desafios de performance. E aí entram as extensões do protocolo.

A primeira extensão que eu vi foi `HTTP 1.0+chunked`. Essa dica verio para
otimizar o lado serer: ele não precisa saber o tamanho do que está sendo
enviado, pois o server, ao detectou que chegou ao fim, manda uma última
mensagem para indicar "fim de leitura".

Então eu descobri uma extensão motivada exatamente pela questões de muitos
sokcet abertos: a extensão `HTTP 1.0+keepalive`. O que ela faz? Em resumo,
usa um header (`keep-alive`) extra pedindo para manter a conexão ativa, e
reutilizar o socket futuramente para enviar outra requisição http recebendo uma
nova resposta http.

Basicamente altera o HTTP 1.0 clássico:

- abrir socket
- enviar requisição
- receber resposta
- fechar conexão

Para 3 momentos:

- Primeiro momento: conexão
  - tenho conexão para o mesmo host livre?
  - se sim, uso ela
  - se não, crio conexão
- Segundo momento: mensagens
  - envia requisição
  - recebe resposta
- Terceiro momento: fechamento
  - o server pediu pra fechar?
  - se não, mantém ligado
  - se pediu para fechar, melhor fechar porque do lado dele ele já fechou

Bem, pelo visto isso é algo que resolveria o problema, não é? Essa extensão?

Então... aqui nos esbarramos com um problema do TotalCross, que deveria ter
sido óbvio caso eu tivesse ido mais a fundo nele. A classe `HttpStream` dava
suporte apenas para a extensão `chunked`, não dava para a extensão
`keepalive`.

O que me resta? Fazer o meu próprio cliente de HTTP. Ok, como funciona o keep
alive? Esse esquema dos headers. Enquanto o server não dizer que fechou, tá
valendo, posso continuar mandando mais requisições para o mesmo socket.

E sabe o que o TotalCross me fornece de http request/response para trabalhar?
Nada! Mas isso tem motivos históricos, em PalmOS memória era um recurso muito
escasso e qqr abstração de novas classes/navegar por referências era demasiado
custoso.

> O Fabio da TotalCross só não botou pra rodar TotalCross em uma batata porque,
> apesar de ter encontrado o compilador de C para BatataOS, o jemalloc usava
> algumas primitivas de OS que não estavam contempladas pelo BatataOS, mas o
> hardware era compatível

Mas eu não queria rodar em uma batata qualquer, o target era um poderoso Android
Gingerbread que já não recebia mais atualizações (tá, isso foi exagero de minha
parte para efeitos de storytelling)! Então eu tinha bastante memória e
processamento pra trabalhar.

Ok, lá vamos nós. Abstrações pra esse fim? HttpRequest, que tem método, URL,
body (output stream), headers. HttpResponse, com o código http, headers, body
(input stream). Agora eu preciso enviar, antes mesmo de resolver a questão dos
sockets.

Muito sofrimento depois, descobri que se eu quiser como client posso enviar
chunked o body da requisição, download tem chunked e tem multipart, em cima
dessas coisas pode ter compactação. E múltiplas compactações uma em cima da
outra.

Então, como sanar isso? Primeiro o input stream raw: ele pode ser comum, multi
part, ou chunked. Podem ter outros modos? Pode, mas não me afetou nos meus
testes. Ok, resolvido o raw input, aplicam-se as múltiplas descompactações. As
que eu me lembro: brotli, deflate, gzip.

TotalCross já fornece tanto deflate stream como gzip stream. E se me mandarem
brotli? Eu lanço exceção, fim. Eu aprendi que isso fazia parte do content
negotiation do http, então eu nem digo que tenho suporte a brotli para não
receber brotli.

Sanado essa questão de enviar/receber dados, vamos para o outro lado: sockets.
Olhei a ideia mais ou menos de como o okhttp fazia com socket. Basicamente ele
mantinha uma espécie de pool de "server:port" para socket.

Então, o que eu faço? O mesmo. Tenho um HttpClient e dentro dele mantenho um
SocketPool. Toda vida que o server fecha uma conexão ou eu tento escrever e
recebo "socket closed", eu removo o socket do meu pool.

E com isso resolvi o problema do usuário. O download que era de horas foi
melhorado para poucos minutos, não quebrou compatibilidade com ninguém, não
precisou fazer backfill nem nada.

O resultado final dessa brincadeira tá aqui:
[https://gitlab.com/geosales-open-source/tc-http-conn](https://gitlab.com/geosales-open-source/tc-http-conn).

# Fim (?)

Após essas otimizações, o usuário já não sofria mais com a questão dos
downloads. E outra coisa também bastante importante: os usuários antigos não
foram de nenhuma maneira afetados. E quem fazia o upload das imagens pode
continuar trabalhando em cima das mesmas convenções.

A ideia inicial era trabalhar com tarfiles (os chamados tarballs), não com zip
no modo `STORE`. Tarfile forneceria a escrita em fita dos dados,
sequencialmente. Mas TotalCross não dava suporte para isso, e também não havia
interesse da parte deles dar suporte para isso. A solução foi usar o zip, pois
teria o mesmo efeito.

Conhecer um pouco de como outros programas operam, quais problemas eles já
resolveram, ajuda a lidar com questões que você eventualmente irá se deparar no
dia-a-dia como dev. E as vezes a melhor solução vai ser algo totalmente fora do
esperado: usuário está com problema no download? Pois vamos implementar o que
está especificado para o protocolo HTTP 1.1, salvando as coisas em um zip.
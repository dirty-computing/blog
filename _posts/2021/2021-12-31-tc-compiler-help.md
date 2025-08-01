---
layout: post
title: "TC Compiler Help - um apoio a fazer o build de bibliotecas"
author: "Jefferson Quesado"
tags: java totalcross ci
---

Esse posicionamento se refere a antes do início do `totalcross-maven-plugin` que facilitou muitas coisas.
Muito do que o `tc-compiler-help` se propõe a resolver já foi suplantado pelo `totalcross-maven-plugin`,
mas muito não é tudo, né?

# Como funciona o `totalcross-maven-plugin`

Esse plugin é o que há de mais esperto e o que eu gostaria de ter feito antes. Porém, não fiz, e também
continuo não sabendo como se faz um plugin para o Maven.

Para gerar uma aplicação, o MOJO chamado desse plugin vai varrer todas as dependências. Mas não irá varrer
em vão, vai varrer procurando sinais de um `tcz` dentro delas. Na arquitetura atual do `totalcross-maven-plugin`,
para funcionar, em cima de uma dependência chamada `abacate` se espera encontrar, na raiz do zip `abacate.jar`,
o arquivo `abacateLib.tcz`.

Se o `tcz` existir, essa dependência é considerada uma dependência TotalCross, o `tcz` é extraído de dento dela
e ainda é nomeado no `all.pkg`. Tudo lindo e maravilhoso...

... **SE** a biblioteca em questão foi empacotada usando o `totalcross-maven-plugin`. Em situações de bibliotecas
selvagens, normalmente elas não são empacotadas com esse plugin, portanto falta existir nelas o `tcz`.

Isso normalmente não é um problema, pois o ecossistema TotalCross, apesar de ser baseado sobre o Java,
tem algumas idiossincrasias que o torna incompatíveis (ou, no mínimo, hostil) com diversas bibliotecas estrangeiras.
Mas, e em casos legados, em que a biblioteca foi gerada sem o `.tcz` associado? Ou se simplesmente não for
auspicioso embarcar esse arquivo no `.jar` gerado?

# Como funciona o modelo "clássico" de dependências no TotalCross

Para gerar um `.tcz` do jeito clássico, é necessário invocar a classe `tc.Deploy` com algumas opções de linha de
comando para fazer essa geração. A priori, essa mesma classe gera também o executável, desde que seja fornecido
para ela uma das opções de plataforma; na inexistência de plataforma fornecida, só será criado um `.tcz` de
biblioteca.

Assim, é possível especificar qual o `.jar` que será compilado. Quando se está gerando aplicativos, é possível passar
o caminho para a classe principal ou mesmo para onde ficam os arquivos compilados Java, mas estamos aqui lidando com
bibliotecas, voltando à trilha principal.

Após gerar o `.tcz`, se faz necessário colocar uma referência a esse arquivo no `all.pkg`. Essa referência precisa seguir
o formato `[L] abacateLib.tcz`, onde `abacateLib` é a dependência a ser inserida. Antigamente, quando a instalação da TCVM
era separada da instalação do aplicativo, fazia sentido diferenciar dependências do tipo local da aplicação (`[L]`) daquelas
que deveriam morar juntas à TCVM globalmente (`[G]`), porém isso só é relevante atualmente para WinCE e WinMobile.

Mas, isso não é tudo. A TCVM tem uma limitação que, a partir de um `.tcz`, só consegue carregar 4096 métodos distintos, 4096
atributos distintos e 4096 classes distintas. O que acontecia quando o alvo sendo tratado tinha mais do que a TCVM era capaz
de carregar? Bem, nos primórdios o build falhava miseravelmente mesmo e ficava a cargo do programador separar as preocupações
e dar seus pulos para ter bibliotecas com no máximo 4096 classes/métodos/atributos. Mas com o tempo foi adicionada a
capacidade do `.tcz` sofrer um _split_ automaticamente. Ainda no exemplo do `abacateLib.tcz`, o primeiro _split_ geraria
o arquivo `abacateLib_1lib.tcz`. Sim, isso mesmo, com `l` minúsculo.

De modo geral, a transformação é:

{% katexmm %}

- `%.tcz` $\mapsto$ `%_<n>lib.tcz`

{% endkatexmm %}

onde aqui `<n>` é o número de vezes que foi disparado o _split_. Se for já voltado a uma biblioteca, temos o radical pós-fixo
o `%Lib`.

Independente do _split_, ao adicionar a dependência no `all.pkg`, o próprio `tc.Deploy` vai atrás de pegar sozinho os _splits_.
Por exemplo, se o `all.pkg` tivesse o seguinte conteúdo:

```
[L] abacateLib.tcz
[L] /path/to/marmotaLib.tcz
```

O `tc.Deploy` irá procurar por `abacateLib.tcz` no diretório atual e, também, por qualquer outro arquivo dentro do mesmo
diretório que satisfaça a regex `abacateLib_[1-9][0-9]*lib\.tcz`. E irá procurar pelo `marmotaLib.tcz` no diretório absoluto
`/path/to/` de modo semelhante, portanto resgatando os arquivos `/path/to/marmotaLib.tcz` e os que satisfaçam a regex
`/path/to/marmotaLib_[1-9][0-9]*lib\.tcz`.

## Diferenças entre o jeito clássico e o `totalcross-maven-plugin`

O plugin, na hora de criar os `.tcz`, delega ao `tc.Deploy` o trabalho duro. Porém, ele ignora a existência do _split_ de `.tcz`s.
Tanto ao empacotar como ao extrair. Então, temos um problema a ser tratado. Quem estiver se sentindo aventureiro, o repositório é
[https://github.com/TotalCross/totalcross-maven-plugin/](https://github.com/TotalCross/totalcross-maven-plugin/).

Porém, ele tem uma vantagem indiscutível em relação ao clássico: gerência do `all.pkg`. O plugin cria automaticamente o `all.pkg`
na inexistência dele, e também aparentemente mantém uma boa relação com o `all.pkg` pré-existente.

# O `tc-compiler-help` como alternativa

Na criação desse auxiliar da compilação de Java para formato TotalCross, tive de lidar com problemas distintos do que aqueles
que o plugin veio resolver. Em primeiro lugar, o `.jar` já estava formado. Eu não poderia mexer nele. E também (originalmente)
muitas das bibliotecas sofriam _split_.

Então, eu precisava de uma maneira alternativa para conseguir gerar os `.tcz`s. Inicialmente, quando existiam poucas dependências,
era feito na mão o processo, via um script configurado no build do Jenkins chamando o `tc.Deploy` de um lugar pré-instalado. Só
que isso implicava uma boa quantidade de "duplicação" de código, da chamada dessa classe em um script. E também a manutenção do
`all.pkg` dentro do repositório. Quando saímos de 3 dependências para 4, já foi começado a tomar outro rumo.

No lugar de definir externamente o que compilar, trouxemos para dentro de uma classe Java o que compilar. Dado um predicado arbitrário,
passando por todos os `.jar` do _classpath_, julgar se precisa compilar baseado apenas no nome do arquivo. Algo que tem em comum é
que eles tem no `groupId` (e, portanto, no esquema de diretórios) o nome `softsite`, e posso excluir o `tc-compiler-help` como parte
do predicado. Pronto, isso me permite trabalhar com o legado dos antigos `.jar` sem maiores estresses.

Assim sendo, o `tc-compiler-help` ficava encarregado de fazer algumas coisas:

1. percorrer o _classpath_ perguntando se o usuário gostaria de usar aquele `.jar`
2. caso sim, verificar se tinha algum `.tcz` associado
3. caso não, ou caso o `.tcz` seja mais antigo do que o `.jar`, gerar um novo `.tcz`
4. adicionar na lista do `all.pkg` o caminho para o `.tcz`
5. chamar o `tc.Deploy` para gerar a aplicação
6. restaurar o estado anterior do `all.pkg`

Pronto, só isso. Note que, na época, o maior suporte que o TotalCross fornecia era para o Java 8, então peguei o _classloader_ padrão
do Java (que por sinal era instância de `URLClassLoader`) e isso funcionava bem. Porém, com o advento do _jigsaw_ e módulos do Java 9,
isso não é mais uma simples verdade e, portanto, o `tc-compiler-help` não funciona adequadamente.

O `.tcz` foi convencionado para ser gerado na mesma pasta do `.jar` (que, por sua vez, está dentro do `MAVEN_HOME`).

## _Caveats_

Antes de lidar aqui com o exemplo, mostrar algumas das limitações do `tc-compiler-help`.

A primeira é a já citada necessidade de rodar com Java 8. Não apenas limitado a ser compilado com _target_ para Java 8,
preciso estar rodando em cima de Java 8.

Outra é que ele escreve no diretório onde fica a dependência Maven. Como está lá, isso pressupõe que o usuário que estiver rodando
o comando tenha permissão para adicionar coisas dentro do `MAVEN_HOME` (o que talvez não seja verdade).

Tem uma mais sutil. No caso, ela é relativa ao modo como o predicado é fornecido. O que o predicado vai receber é uma string com o caminho
absoluto do nome do arquivo. Se o predicado fizer apenas uma verificação de substring (por exemplo, `abacate`), e o usuário que estiver
rodando o comando tiver essa substring no nome, e o comando estiver sendo executado dentro da `HOME` do usuário, então todo `.jar` será
considerado como válido. Isso pode ser relativo não só ao `abacate` dependência com o `abacate` usuário, mas talvez o nome do projeto
seja assim e na criação do CI o predicado dar falso positivo para todo mundo.

Para poder pegar todo o _classpath_ das dependências, se faz aconselhável rodar pelo Maven (mojo `exec:java`). Precisa ser executado
após a geração do `.jar`.

Por fim, quando detecta que precisa gerar um novo `.tcz`, ele não irá imediatamente remover os demais `.tcz`s gerados pelo _split_
anterior. Então, se por acaso a versão anterior de `abacate` gerasse dois _splits_ e a nova gerasse apenas um único _split_, o arquivo
`abacateLib_2lib.tcz` iria vazar e ser instalado junto da aplicação, com resultados imprevisiveís.

## Usando na prática

Vamos pegar um projeto de exemplo aqui, o [`stream-support-totalcross-sample`](https://gitlab.com/geosales-open-source/stream-support-totalcross-sample).
Esse exemplo foi criado só para demonstrar a possibilidade de usar algo
extremamente semelhante ao `java.util.stream.Stream` do Java 8 dentro do TotalCross,
através do projeto [`totalcross-functional-toolbox`](https://gitlab.com/geosales-open-source/totalcross-functional-toolbox).

O projeto em si é bem simples, contém 3 classes apenas:

- a classe `App` que estende a `MainWindow`
- a classe `SampleApp` que apenas chama `TotalCrossApplication.run` para a classe principal
- a classe `CompileApp` que configura o `CompilationBuilder` e lida com parâmetros CLI

Vamos focar na configuração principal do `CompilationBuilder`. As primeiras coisas que se podem
ver são que estamos configurando variáveis relativas ao TotalCross:

- a chave usada do TotalCross
- onde está TotalCross

Em seguida, começamos a ver coisas relativas à construção propriamente dita, quando
se informa que se deseja compilar para WIN32. O próximo passo é informando o _predicado_
de compilação da dependência. Esse projeto em específico foi feito para mostrar usando
`Stream` no TotalCross, então foi necessário colocar lá algo que conseguisse colocar identificar
corretamente a dependência do `totalcross-functional-toolbox`.

Depois, finalmente, temos a classe da `MainWindow`, informação de que se trata de um
"_single package_" e o comando para se fazer o `.build()`.

Chamando pela linha de comando pelo Maven, seria algo assim:

```bash
./mvnw clean package exec:java -Dexec.mainClass="br.com.softsite.streamsupport.CompileApp" \
    -Dexec.args="-n \
    -P retrolambda
```

Note que, nesse caso específico, eu só quero fazer o _dry-run_ para verificar se tudo está compilando adequadamente.
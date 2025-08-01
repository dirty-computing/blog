---
layout: post
title: "\"Hello, World!\" em GWT usando arquétipo do TBroyer"
author: "Jefferson Quesado"
tags: java gwt maven
---

Como tudo bom na programação, vamos começar com um "hello, world!"?

No caso, quero codar um componente em GWT, e para não precisar codar com o
app do trabalho, melhor resumir ao extritamente necessário. Como no mundo Maven
existem os "arquétipos" (`archetypes`, no inglês), eles já trazem meio caminho montado
para ser feliz. Então, que tal usar um desses `archetypes`?

Eu já conhecia o [`net.ltgt.gwt.archetypes`](https://github.com/tbroyer/gwt-maven-archetypes)
do @tbroyer, mas ao pesquisar no Google a primeira opção que apareceu foi o
[`branflake2267/Archetypes`](https://github.com/branflake2267/Archetypes). Aqui vou testar
focando no arquétipo do TBroyer, deixando o branflake2267 para um outro momento.

> Cavando mais apareceram outros arquétipos, mas aparentemente não tão significativos.

# tbroyer ltgt archetype, base para começar

Existem 3 arquétipos distintos:

- `modular-webapp`
- `modular-requestfactory`
- `dagger-guice-rf-activities`

Eu quero a coisa mais simples para começar. Não necessito de `requestfactory` nem nada _fancy_
assim. Isso entra em conflito com os dois últimos arquétipos, só restando o primeiro. De todo jeito,
o primeiro ainda fornece um esquema modular no Maven, não exatamente o que eu queria mas funciona bem...

```bash
./mvnw archetype:generate \
    -DarchetypeGroupId=net.ltgt.gwt.archetypes \
    -DarchetypeVersion=LATEST \
    -DarchetypeArtifactId=modular-webapp
```

> Estou usando o Maven Wrapper por conveniência, Maven 3.6.3 e Wrapper 0.5.6

E voilà, sou apresentado com o prompt me fazendo algumas perguntas:

- qual o `groupId`/`artifactId`/`version`?
- qual o valor para `package`?
  - deixar essa propriedade em branco fez ele assumir o `groupId`
- simplesmente me informou que estava usando `module=App`
- qual o `module-short-name`?

E então pediu para confirmar os dados.

Mandei fazer um `package` a partir da raiz. Deu incompatibilidade de versão do plugin de war
com o Java 16. A versão era 2.2, e eu sei que a versão mais atual (no caso de hoje seria a 3.3.2)
funciona para versões mais novas e está listado como compatível com o Java 7. Simplesmente declaro que
desejo usar o `maven-war-plugin` na versão adequado dentro do `pluginManagement` e fica tudo bem: build
sucesso.

```xml
<project>
  ...
  <build>
    ...
    <pluginManagement>
      <plugins>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-war-plugin</artifactId>
          <version>3.2.2</version>
        </plugin>
        ...
```

Bem, não estava acostumado mais com isso mas o `war` gerado não era auto-executável (spring-boot me viciou).
Então, vamos lá, instalar um Tomcat novo. Peço para o `sdkman` cuidar disso para mim:

```bash
$ sdk list tomcat # para verificar as versões disponíveis
$ sdk install tomcat 9.0.40 # escolhi essa versão porque ela está "fechada"
```

> Encontrei esse blog post que pode trazer mais informações úteis https://franciscochaves.com.br/blog/instale-o-apache-tomcat-com-sdkman,
> mas não segui as dicas dele para isso.

Peguei o `war` gerado e joguei na pasta do Tomcat (no meu caso, `~/.sdkman/candidates/tomcat/current`), na subpasta onde deveriam morar
as aplicações `webapp/`. Daí `startup.sh` no Tomcat!

No primeiro momento não carregou corretamente o script do GWT. Ao inspecionar o `index.html` gerado, a tag
que deveria carregar o `.nocache.js` estava assim:

```html
<script src="${module.toLowerCase()}/${module.toLowerCase()}.nocache.js"></script>
```

alterei para apontar para o JS correto:

```html
<script src="br.com.softsite.gsos.hw.App/br.com.softsite.gsos.hw.App.nocache.js"></script>
```

Eu creio que foi algum `<ENTER>` que apertei com a opção de usar a opção padrão durante o uso do arquétipo.

Após alterar para pegar do lugar certo (eu coloquei o valor dentro do `war` expandido pelo próprio Tomcat),
a página carregou corretamente. Porém... chamadas GWT-RPC não foram bem sucedidas como eu queria, deu 404.

Vou atrás de alguns suspeitos, nada para mim é muito claro quanto a esse erro... então, após procurar
um tanto, encontro o seguinte mapeamento no `web.xml`:

```xml
  <servlet-mapping>
    <servlet-name>greetServlet</servlet-name>
    <url-pattern>/${module.toLowerCase()}/greet</url-pattern>
  </servlet-mapping>
```

Outra _red-flag_ de que eu fiz alguma bobeira na construção do arquétipo! Corrigindo:

```xml
  <servlet-mapping>
    <servlet-name>greetServlet</servlet-name>
    <url-pattern>/br.com.softsite.gsos.hw.App/greet</url-pattern>
  </servlet-mapping>
```

Tudo funcionou como uma maravilha!!

## Estrutura do projeto

O projeto consiste de um reator-pai com as quebras de linha um tanto quanto bagunçadas:

```xml
  
  
  <modelVersion>4.0.0</modelVersion>
        
  
  
  <groupId>br.com.softsite.gsos.hw</groupId>
        
  
  
  <artifactId>ltgt</artifactId>
        
  
  
  <version>1.0-SNAPSHOT</version>
        
  
  
  <packaging>pom</packaging>
        
  
  
  <properties>
                
    
    
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
              
  
  
  </properties>
```

Mas, tirando isso, não tem nada demais. Precisei fazer o ajuste do plugin do war para funcionar e só.

Existem 3 módulos:

- `ltgt-client`
- `ltgt-shared`
- `ltgt-server`

O `shared` é dependência comum do `client` e do `server`. A única dependência que possui
é `com.google.gwt:gwt-servlet` como `provided` para lidar com GWT-RPC. Tem o plugin
`maven-source-plugin` habilitado justamente para que, quando seja publicado, seus fontes
também sejam publicados e seja possível o GWT serializar corretamente as suas classes.

Mandar instalar esse módulo instala os seguintes artefatos:

- `ltgt-shared-1.0-SNAPSHOT.jar`
- `ltgt-shared-1.0-SNAPSHOT-sources.jar`

Esse comportamento é exibido porque o `maven-source-plugin` foi configurado na raiz
para gerar esse artefato de fonte, com o _goal_ `jar-no-fork` atrelado à fase `package`.

Não foi gerado nenhum `gwt.xml` para esse artefato. Para um futuro, não devo confiar na coincidência
de que tudo do `shared` esteja exatamente no mesmo pacote das coisas do `client`>

O `client` por sua vez tem como dependência o `shared` normal **E** também com
`<classifier>sources</classifier>`:

```xml
    <dependency>
      <groupId>${project.groupId}</groupId>
      <artifactId>ltgt-shared</artifactId>
      <version>${project.version}</version>
    </dependency>
    <dependency>
      <groupId>${project.groupId}</groupId>
      <artifactId>ltgt-shared</artifactId>
      <version>${project.version}</version>
      <classifier>sources</classifier>
    </dependency>
```

Ele é empacotado como `gwt-app`. Nada mais esquisito que eu dê conta
exatamente agora, apenas uma menção a como ele configura o plugin
`net.ltgt.gwt.maven.gwt-maven-plugin`.

O `gwt.xml` (situado em `br.com.softsite.gsos.hw.App.gwt.xml`) gerado é bem simples,
apenas com menção ao `entry-point` e ao `source` além de um punhado trivial de `inherits`
e uma definição arbitrária:

```xml
  <source path=""/>
  <entry-point class="br.com.softsite.gsos.hw.App"/>
```

Note que como todos os fontes estão exatamente no mesmo pacote, não há necessidade
de importar do `shared` nem de especificar um diretório de onde estarão os fontes.

Jà o `server` é mais interessante. Por padrão ele depende do `shared` e pronto,
sem puxar diretamente o `sources`. Porém ele tem dependência ativa por perfil Maven.
Se ele estiver com o perfil `env-prod` ligado (ligado por padrão, para caso eu esquela
algo na linha de comando ele já ativa esse perfil), ele tem a dependência de `runtime`
do `client`, como `war`:

```xml
        <dependency>
          <groupId>${project.groupId}</groupId>
          <artifactId>ltgt-client</artifactId>
          <version>${project.version}</version>
          <type>war</type>
          <scope>runtime</scope>
        </dependency>
```

A dependência é colocada como `war` justamente para deixar o próprio Maven lidar com a
sobreposição de seus elementos. O `gwt-app` do `client` vai produzir um `war` consistindo
apenas da parte _client-side_ do aplicativo. Isso inclui eventual CSS e JS que o programador
suba no projeto, _assets_ diversos como imagens como _também_ o resultado do próprio compilador
GWT, o código transformado de Java para JS. Dizer que é uma dependência `war` vai fazer a magia
da sobreposição correta no aplicativo gerado.

Agora, caso seja especificado que se deve rodar com o perfil `env-dev` (e, portanto, não
ativar o perfil `env-prod`), temos que não há dependência extra. Em compensação, temos os seguintes
plugins configurados:

```xml
         <plugins>
            <plugin>
              <groupId>org.eclipse.jetty</groupId>
              <artifactId>jetty-maven-plugin</artifactId>
              <configuration>
                <webApp>
                  <resourceBases>
                    <resourceBase>${basedir}/src/main/webapp</resourceBase>
                    <resourceBase>${basedir}/../target/gwt/launcherDir/</resourceBase>
                  </resourceBases>
                </webApp>
              </configuration>
            </plugin>
            <plugin>
              <groupId>org.apache.tomcat.maven</groupId>
              <artifactId>tomcat7-maven-plugin</artifactId>
              <configuration>
                <contextFile>${basedir}/src/main/tomcatconf/context.xml</contextFile>
              </configuration>
            </plugin>
          </plugins>
```

Notou o `jetty` ali? Ele está pegando de `../target/gwt/lancherDir/` como um `resourceBase`. Ou seja,
um `target` na posição do reator!

Onde mais vi isso? Na configuração do plugin `net.ltgt.gwt.maven.gwt-maven-plugin` dentro do
`pom` do reator (_prettified_):

```xml
      <plugin>
        <groupId>net.ltgt.gwt.maven</groupId>
        <artifactId>gwt-maven-plugin</artifactId>
        <inherited>false</inherited>
        <configuration>
          <launcherDir>${project.build.directory}/gwt/launcherDir</launcherDir>
        </configuration>
      </plugin>
```

Outra coisa bacana a se perceber é a configuração padrão do plugin do `jetty`, que a priori
estará simplesmente ligada (e será usada pelo `gwt-maven-plugin`):

```xml
        <plugin>
          <groupId>org.eclipse.jetty</groupId>
          <artifactId>jetty-maven-plugin</artifactId>
          <configuration>
            <scanIntervalSeconds>1</scanIntervalSeconds>
            <webApp>
              <extraClasspath>${basedir}/../ltgt-shared/target/classes/</extraClasspath>
            </webApp>
            <contextXml>${basedir}/src/main/jettyconf/context.xml</contextXml>
          </configuration>
        </plugin>
```

aqui foi definido que o `shared` é parte do _classpath_  extra, algo que precisa ser cuidado
pelo Jetty.
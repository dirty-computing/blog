---
layout: post
title: "Criando projeto Maven com profiles distintos de dependências"
author: "Jefferson Quesado"
tags: maven java
base-assets: "/assets/maven-profiles/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

No trabalho tivemos um problema com a GraalVM, e devido a isso
[essa issue foi criada](https://github.com/oracle/graaljs/issues/886).

Eu falei com o autor e pensei "será que não seria melhor criar um projeto maven
com isso bonitinho? Subir um repo, MCVE, que você controla através de profiles
as dependências?"

E cá está o repo! [github.com/jeffque/graalvm-regression](https://github.com/jeffque/graalvm-regression)

Pois bem, aproveitar que vou fazer isso e compartilhar um pouco o processo.

# Iniciando um projeto maven

Para começar, eu gosto de iniciar o projeto maven colocar o `mvnw` (maven
wrapper). Eu normalmente começo copiando o `mvnw` de um outro repositório meu
conhecido, mas posso fazer isso de modo mais canônico. Como por exemplo,
seguindo [esse tutorial do Baeldung](https://www.baeldung.com/maven-wrapper):

```bash
$ mvn -N wrapper:wrapper
```

Ficou assim o diretório:

```none
.
├── .mvn
│   └── wrapper
│       └── maven-wrapper.properties
├── mvnw
└── mvnw.cmd
```

Qual a versão do maven que ele usa? Podemos perguntar diretamente ao `mvwn` ou
então consultar em `.mvn/wrapper/maven-wrapper.properties`. No caso, o conteúdo
do arquivo é:

```properties
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
distributionType=only-script
distributionUrl=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.9/apache-maven-3.9.9-bin.zip
```

Muito bem, maven na versão 3.9.9, uma delícia.

# Criando o projeto base

Existem diversas maneiras de iniciar um projeto maven. Inclusive a de você
o `pom.xml` totalmente do zero. Mas... um modo mais canônico seria pedir um
arquétipo, que nem eu fiz em ["Hello, World!" em GWT usando arquétipo do TBroyer]({% post_url 2021-10-07-hello-world-gwt-archetype-1 %}).

Então, vamos pedir o arquétipo vazio? Normalmente eu peço o
[`maven-archetype-quickstart`](https://maven.apache.org/archetypes/maven-archetype-quickstart/).
Tem uma lista não exaustiva de arquétipos
[aqui](https://maven.apache.org/archetypes/index.html).

```bash
./mvnw archetype:generate -DarchetypeGroupId=org.apache.maven.archetypes -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.5
```

Após baixar as dependências necessárias para rodar o arquétipo ele me pergunta:

- Define value for property 'groupId'
  - com.jeffque
- Define value for property 'artifactId'
  - graalvm-24-1-2-regression
- Define value for property 'version' 1.0-SNPASHOT
  - &lt;enter&gt; (o que é equivalente a usar o default, que no caso é `1.0-SNAPSHOT`)
- Define value for property 'package' com.jeffque:
  - &lt;enter&gt; (o que é equivalente a usar o default, que no caso é `com.jeffque`)

Após responder, ele pede para confirmar:

```none
Define value for property 'package' com.jeffque: 
Confirm properties configuration:
javaCompilerVersion: 17
junitVersion: 5.11.0
groupId: com.jeffque
artifactId: graalvm-24-1-2-regression
version: 1.0-SNAPSHOT
package: com.jeffque
 Y:
```

Confimei e... puff!

```none
.
├── .mvn
│   └── wrapper
│       └── maven-wrapper.properties
├── graalvm-24-1-2-regression
│   ├── .mvn
│   │   ├── jvm.config
│   │   └── maven.config
│   ├── pom.xml
│   └── src
│       ├── main
│       │   └── java
│       │       └── com
│       │           └── jeffque
│       │               └── App.java
│       └── test
│           └── java
│               └── com
│                   └── jeffque
│                       └── AppTest.java
├── mvnw
└── mvnw.cmd
```

Gerei no canto errado? Ok, só mover uma pasta pra lá
{% katexmm %}$\leftarrow${% endkatexmm %}.

```bash
cd graalvm-24-1-2-regression
mv pom.xml src ../
mv .mvn/* ../.mvn
rmdir .mvn
cd ..
rmdir graalvm-24-1-2-regression
```

Ok, ajeitado:

```none
.
├── .mvn
│   ├── jvm.config
│   ├── maven.config
│   └── wrapper
│       └── maven-wrapper.properties
├── mvnw
├── mvnw.cmd
├── pom.xml
└── src
    ├── main
    │   └── java
    │       └── com
    │           └── jeffque
    │               └── App.java
    └── test
        └── java
            └── com
                └── jeffque
                    └── AppTest.java
```

# Adicionando comando de execução

Eu quero facilitar a vida de quem vai testar usando Maven. Para tal, vou
configurar o plugin `exec`. O plugin é esse:
[`exec-maven-plugin`](https://www.mojohaus.org/exec-maven-plugin/usage.html).

Na linha de comando:

```bash
> ./mvnw exec:java -Dexec.mainClass="com.jeffque.App"
[INFO] Scanning for projects...
[INFO] 
[INFO] ---------------< com.jeffque:graalvm-24-1-2-regression >----------------
[INFO] Building graalvm-24-1-2-regression 1.0-SNAPSHOT
[INFO]   from pom.xml
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- exec:3.5.0:java (default-cli) @ graalvm-24-1-2-regression ---
Hello World!
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  0.383 s
[INFO] Finished at: 2025-01-31T08:02:13-03:00
[INFO] ------------------------------------------------------------------------
```

Beleza, vamos por no pom? Em `pluginManagement` a gente indica commo o plugin
vai ser executado ao ser chamado, não necessariamente ele será chamado. Então,
se eu adicionar o `exec-maven-plugin` lá, o maven não tentará fazer o fetch
desse plugin a priori. Já em `build.plugins`... aí a gente está indicando que o
plugin será de fato executado.

Aí vem a questão: quando usar algo em `build.plugins`? Quando precisamos que o
plugin seja executado e não tem implícito em algum lugar isso. Como por
exemplo, chamar o `retrolambda` para permitir usar a sintaxe de lambdas e
conseguir dar um target para java 7.

Ok, vamos adicionar as configurações do plugin em `pluginManagement`?
Primeiramente, vamos colocar o plugin lá:

```xml
<plugin>
    <groupId>org.codehaus.mojo</groupId>
    <artifactId>exec-maven-plugin</artifactId>
    <version>3.5.0</version>
</plugin>
```

Ok, prendemos a versão. Agora, vamos para o como vai ser chamado. No caso,
quando for chamado o mojo `exec:java`: `exec` identifica esse plugin e `java` o
_goal_ específico:

```xml
<plugin>
    <groupId>org.codehaus.mojo</groupId>
    <artifactId>exec-maven-plugin</artifactId>
    <version>3.5.0</version>
    <executions>
        <execution>
            <goals>
                <goal>java</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

Ok, agora, vamos por a configuração da classe principal:

```xml
<plugin>
    <groupId>org.codehaus.mojo</groupId>
    <artifactId>exec-maven-plugin</artifactId>
    <version>3.5.0</version>
    <executions>...</executions>
    <configuration>
        <mainClass>com.jeffque.App</mainClass>
    </configuration>
</plugin>
```

Plugin configurado! Será?

```bash
> ./mvnw exec:java
[INFO] Scanning for projects...
[INFO] 
[INFO] ---------------< com.jeffque:graalvm-24-1-2-regression >----------------
[INFO] Building graalvm-24-1-2-regression 1.0-SNAPSHOT
[INFO]   from pom.xml
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- exec:3.5.0:java (default-cli) @ graalvm-24-1-2-regression ---
Hello World!
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  0.341 s
[INFO] Finished at: 2025-01-31T08:28:48-03:00
[INFO] ------------------------------------------------------------------------
```

# Adaptando ao problema da issue

Vamos colocar as coisas da issue do GitHub. Primeiramente, para a versão
problemática do GraalVM. Vamos alterar a `main` para refletir como está na
issue.

Adicionar as dependências e alterar a `main` foi uma non-issue, bem direto ao
ponto. Para testar, coloquei as dependências para a versão do GraalVM com
problema e mandei executar:


```bash
> ./mvnw compile exec:java
...
org.graalvm.polyglot.PolyglotException: TypeError: k.equals is not a function
    at <js>.:=> (Unnamed:6)
    at com.oracle.truffle.polyglot.PolyglotFunctionProxyHandler.invoke (PolyglotFunctionProxyHandler.java:151)
...
```

Perfeito! Tal qual aparece na issue!

## Profiles

Vou criar perfis distintos. E neles vou colocar as dependências. Você pode ler
mais na
[documentação oficial](https://maven.apache.org/guides/introduction/introduction-to-profiles.html).

Vou criar dois perfis:

- graalvm-24, apresenta o problema
- graalvm-20, não apresenta o problema

```xml
<profiles>
    <profile>
        <id>graalvm-24</id>
    </profile>
    <profile>
        <id>graalvm-24</id>
    </profile>
</profiles>
```

Ok. Agora, vou deixar o perfil `graalvm-24` ativo por default. Se ninguém
falar nada, ele que será invocado:

```xml
<profile>
    <id>graalvm-24</id>
    <activation>
        <activeByDefault>true</activeByDefault>
    </activation>
</profile>
```

Como invocar esse perfil? Passando a opção `-P` na linha de comando!

Por exemplo:

```bash
./mvnw exec:java -Pgraalvm-24
```

Estou explicitando que quero o perfil `graalvm-24`. De modo semelhante:

```bash
./mvnw exec:java -Pgraalvm-20
```

Para o perfil `graalvm-20`. Eu poderia passar múltiplos perfis também:

```bash
./mvnw exec:java -Pgraalvm-20,jeff,marmota
```

Isso ativa os perfis `graalvm-20`, `jeff` e `marmota`. E no caso o
`activateByDefault`, funciona como? Bem, se você não falar nada...

```bash
./mvnw exec:java
# note que não tem -P
```

Aí só ativa o que tá cadastrado pra rodar por padrão.

Muito bem, agora eu coloco as dependências:

```xml
<profiles>
    <profile>
        <id>graalvm-24</id>
        <activation>
            <activeByDefault>true</activeByDefault>
        </activation>
        <dependencies>
            <dependency>
                <groupId>org.graalvm.polyglot</groupId>
                <artifactId>polyglot</artifactId>
                <version>24.1.2</version>
            </dependency>
            <dependency>
                <groupId>org.graalvm.polyglot</groupId>
                <artifactId>js-community</artifactId>
                <version>24.1.2</version>
                <type>pom</type>
                <scope>runtime</scope>
            </dependency>
        </dependencies>
    </profile>
    <profile>
        <id>graalvm-20</id>
        <dependencies>
            <dependency>
                <groupId>org.graalvm.sdk</groupId>
                <artifactId>graal-sdk</artifactId>
                <version>20.1.0</version>
            </dependency>
            <dependency>
                <groupId>org.graalvm.js</groupId>
                <artifactId>js</artifactId>
                <version>20.1.0</version>
            </dependency>
        </dependencies>
    </profile>
</profiles>
```

E pronto, agora tenho dois perfis distintos! Note que o `graalvm` foi removido
do `project.dependencies`, pois essas dependências sem perfil afetam a todos.

Para testar:

```bash
> ./mvnw exec:java
...
org.graalvm.polyglot.PolyglotException: TypeError: k.equals is not a function
    at <js>.:=> (Unnamed:6)
...

> ./mvnw exec:java -P graalvm-20
...
[INFO] --- exec:3.5.0:java (default-cli) @ graalvm-24-1-2-regression ---
Optional[true]
[INFO] ------------------------------------------------------------------------
...
```

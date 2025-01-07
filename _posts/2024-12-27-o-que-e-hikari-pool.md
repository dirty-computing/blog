---
layout: post
title: "O que é o hikari pool?"
author: "Jefferson Quesado"
tags: java resource-pool pool design-pattern
base-assets: "/assets/o-que-e-hikari-pool/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

> O que é o hikari pool?

Essa simples pergunta em
[uma publicação no BlueSky](https://bsky.app/profile/milila.bsky.social/post/3lclm74m6q225)
me levou a uma explicação que achei bem legal. Vim aqui terminar ela.

No contexto específico estava sendo falado sobre o
[Hikari Connection Pool](https://github.com/brettwooldridge/HikariCP). Mas, se
o Hikari é um Connection Pool, o que seria um "Pool"?

# First things first, conceito de pool

Antes de explicar o que é HikariCP precisamos explicar o que é um _connection
pool_. E pra explicar _connection pool_, precisamos explicar _pool_.

Vamos usar uma analogia econômica para isso? Uma analogia econômica histórica
cheia de falhas e inacurácias com o mundo real, mas vai, suspende a descrença
rapidinho só pela explicação! É auto-contido.

Imagina que você é um lorde/lady na era medieval. Você detém as ferramentas
para a realização do trabalho dos camponeses. E você quer que eles trabalhem.
Então, como que você garante isso? Se as ferramentas são suas? Você vai
precisar entregar as ferramentas para os camponeses, simples.

Então imagine a situação: seu camponês precisa de uma enxada para capinar o
terreno, então ele vai lá e pede pra você uma enxada. Você vai dar a enxada pra
ele e vida que segue. Mas e se ele não devolver, como que fica o seu estoque de
enxadas? Uma hora vai acabar...

Uma alternativa a entregar a enxada é mandar fazer uma enxada. Você é o
senhor/a senhora daquelas terras, então você tem acesso ao ferreiro pra fundir
o metal no formato de enxada e encaixar num cabo. Mas isso não é algo que você
consegue produzir na hora sem que o camponês fique sentado numa sala de espera.
Para fazer esse recurso novo, você demanda de tempo e energia descomunais.

Agora, se o camponês devolver a enxada no final do dia, ela fica disponível
para outro camponês usar no dia seguinte.

Aqui você está controlando o _pool_ de enxadas. O _pool_ é um padrão de projeto
que indica algo que você pode fazer as seguintes ações:

- pedir um elemento para ele
- devolver elemento para ele

Outras coisas também comuns de se ter em _pools_ de objetos:

- capacidade de criar mais objetos, sob demanda, registrando-os no _pool_
- capacidade de destruir objetos do _pool_ (ou desassociar ele daquele _pool_)

# Conexão com o banco de dados JDBC

Bem, vamos nos aproximar ao HikariCP. Vamos falar aqui de conexões com banco
de dados em Java.

No java, pedimos para estabelecer uma conexão com o banco de dados. Existe a
opção de conexão direta, que você precisa entender diretamente sobre quais
classes chamar e alguns detalhes, ou então simplesmente se deleitar com a
opção de descoberta de serviço.

A priori, para usar descoberta de serviço, o provedor do serviço faz um jeito
de cadastrar o que ele está provendo e então o "service discovery" vai atrás
de ver quem poderia servir aquela requisição.

## Um caso de service discovery: pstmt-null-safe

Eu peguei um caso em que precisava fazer conexões JDBC para falar com o banco
de dados. Porém o meu driver de JDBC não aceitava usar nulos como valor, apenas
nulos direto nas queries. Então, o que fiz? Um driver em cima do driver!

A ideia geral era o seguinte. Imagina que eu tenha essa consulta que eu quero
inserir valores:

```sql
INSERT INTO some_table (id, content, parent)
VALUES (?, ?, ?)
```

Agora imagine que estou lidando com a primeira inserção desse valor no banco.
Para isso, preciso deixar com `ID=1`, `CONTENT=first` e `PARENT=null` porque,
afinal, não tem nenhum registro pai desse (é o primeiro, afinal).

O que naturalmente seria feito:

```java
try (final var pstmt = conn.prepareStatement(
                """
                INSERT INTO some_table (id, content, parent)
                VALUES (?, ?, ?)
                """)) {

    pstmt.setInt(1, 1);
    pstmt.setString(2, "first");
    pstmt.setNull(3, Types.INTGEGER); // java.sql.Types
    pstmt.executeUpdate(); // de fato altere o valor
}
```

Quero continuar usando desse jeito, afinal é o jeito idiomático de se usar.
E de acordo com [CUPID](https://dannorth.net/cupid-for-joyful-coding/), o I
vem de "idiomático". A ideia de ter um código idiomático é justamente de
"diminuir a carga mental desnecessária".

Para resolver isso, minha escolha foi: deixar o `prepareStatement` para
o último momento antes do `executeUpdate`. Então eu armazeno todos os nulos
a serem aplicados e, ao perceber que preciso de fato por um nulo, eu rodo
uma substituição de string e gero uma nova query, e essa nova query que será
de fato executada.

Nesse caso, eu começo com:

```sql
INSERT INTO some_table (id, content, parent)
VALUES (?, ?, ?)
```

Então, tenho de botar esses valores:

```sql
INSERT INTO some_table (id, content, parent)
VALUES (?, ?, ?)

-- 1, 'first', NULL
```

Só que eu não posso de fato usar o nulo, então eu crio uma chave
para identificar que a terceira casa é um nulo:

```sql
-- (value, value, NULL)
INSERT INTO some_table (id, content, parent)
VALUES (?, ?, NULL)
-- 1, 'first'
```

E nesse caso preparo essa nova string e coloco os argumentos conforme
o que foi requisitado.

Ok, dito isso, como eu conseguia indicar para a minha aplicação que eu
precisava usar o meu driver de JDBC? Como eu fazia esse cadastro?

O projeto em questão é [Pstmt Null Safe](https://gitlab.com/geosales-open-source/pstmt-null-safe).
Basicamente, existe uma magia no classloader do Java que, ao carregar
um jar, ele procura por uma pasta de metadados chamada de `META-INF`.
E no caso de driver JDBC, `META-INF/services/java.sql.Driver`, e eu anotei
com a classe que implementa
[`java.sql.Driver`](https://docs.oracle.com/javase/8/docs/api/java/sql/Driver.html):
[`br.com.softsite.pstmtnullsafe.jdbc.PstmtNullSafeDriver`](https://gitlab.com/geosales-open-source/pstmt-null-safe/-/blob/master/src/main/java/br/com/softsite/pstmtnullsafe/jdbc/PstmtNullSafeDriver.java?ref_type=heads).

Segundo a documentação do `java.sql.Driver`, todo driver deveria criar uma instância
de si mesmo e se registrar no `DriverManager`. Implementei assim:

```java
public static final PstmtNullSafeDriver instance;

static {
    instance = new PstmtNullSafeDriver();
    try {
        DriverManager.registerDriver(instance);
    } catch (SQLException e) {
        e.printStackTrace();
    }
}
```

Bloco estático se carrega sozinho. E como que sabemos qual a conexão que deveria
ser gerenciada pelo meu driver? A chamada se dá através de
[`DriverManager#getConnection(String url)`](https://docs.oracle.com/javase/8/docs/api/java/sql/DriverManager.html#getConnection-java.lang.String-).
Temos a URL para perguntar para o driver se ele aceita a conexão.
A convenção (aqui de novo, o modo idiomático de se usar) é colocar
no prefixo do esquema da URL. Como eu quero que o meu driver se conecte em cima
de outro driver, fiz nesse equema:

```txt
jdbc:pstmt-nullsafe:<url de conexão sem jdbc:>
\__/ \____________/
 |    |
 |    Nome do meu driver
 Padrão para indicar JDBC
```

Então, para realizar os
[testes](https://gitlab.com/geosales-open-source/pstmt-null-safe/-/blob/master/src/test/java/br/com/softsite/pstmtnullsafe/DriverTest.java?ref_type=heads),
conectei com o SQLite, e usei o indicar do Xerial para pedir
uma conexão em memória através da URI de conexão:

```txt
jdbc:sqlite::memory:
```

Para "envelopar" a conexão, minha convenção indica que eu não repito o `jdbc:`,
então:

```txt
jdbc:pstmt-nullsafe:sqlite::memory:
```

Dissecando a URI acima:

```txt
jdbc:pstmt-nullsafe:sqlite::memory:
\__/ \____________/ \____/ \_____/
 |     |             |       |
 JDBC  meu driver    |       em memória, não use arquivo
                    driver do Xerial SQLite
```

Tá, e como indicar isso? O `Driver#acceptsURL` deve retornar verdade
se eu posso abrir a conexão. Eu poderia só fazer isso:

```java
public static final String PREFIX_URL = "jdbc:pstmt-nullsafe:";

@Override
public boolean acceptsURL(String url) {
    return url.startsWith(PREFIX_URL);
}
```

Mas o que isso indicaria se eu tentasse carregare um driver inexistente?
Nada, iria dar um problema em outro momento. E isso não é bom, o ideal
seria dar pane logo no começo. Então pra isso, vou tentar carregar o
driver por baixo, e se não conseguir, eu retorno falso:

```java
public static final String PREFIX_URL = "jdbc:pstmt-nullsafe:";

@Override
public boolean acceptsURL(String url) throws SQLException {
    if (url.startsWith(PREFIX_URL)) {
        return getUnderlyingDriver(url) != null;
    }
    return false;
}

private String toUnderlyingUrl(String url) {
    return "jdbc:" + url.substring(PREFIX_URL.length());
}

private Driver getUnderlyingDriver(String url) throws SQLException {
    return DriverManager.getDriver(toUnderlyingUrl(url));
}
```

> O código real do driver tem alguns pontos a mais que não são relevantes
> a discussão aqui sobre HikariCP, nem sobre DataSource, nem JDBC ou tópicos
> abordados neste post.

Então, ao requisitar uma conexão "null safe" para o `DriverManager`,
primeiro ele acha o meu driver e o meu driver recursivamente tenta
verificar se existe a possibilidade de conexão por debaixo dos panos.
Confirmado que existe algum driver capaz de lidar com isso, retorno
que sim, é possível.

## O padrão de uso de conexões JDBC no Java

A interface [`Connection`](https://docs.oracle.com/javase/8/docs/api/java/sql/Connection.html)
implementa a interface [`AutoCloseable`](https://docs.oracle.com/javase/8/docs/api/java/lang/AutoCloseable.html).
Isso significa que você pega a conexão, usa a conexão como deseja, e então
você fecha a conexão. É bem padrão você usar alguma indireção com isso ou,
se usar a conexão diretamente, usar dentro de um bloco `try-with-resources`:

```java
try (final var conn = getJdbcConnection();
     final var pstmt = conn.prepareStatement( """
                INSERT INTO some_table (id, content, parent)
                VALUES (?, ?, ?)
                """)) {
    // something with the code
}
```

Agora, o processo de criar conexões é um processo caro. E também o processo de
_service discovery_ não é exatamente gratuito. Então o ideal seria guardar o
_driver_ para então gerar as conexões. Vamos desenvolver isso aos poucos.

Primeiro, vamos precisar ter um objeto que podemos iniciar com o driver. Pode
tranquilamente ser um objeto global, um componente injetado do Spring, ou
qualquer coias assim. Chamemos ele de `JdbcConnector`:

```java
public class JdbcConnector {
    private final String url;
    private final Driver driver;
    private final Properties defaultProperties;

    public static JdbcConnector createJdbcConnector(String url) throws SQLException {
        return createJdbcConnector(url, new Properties());
    }

    public static JdbcConnector createJdbcConnector(String url, Properties defaultProperties) throws SQLException {
        final var driver = DriverManager.getDriver(url);
        if (driver == null) {
            return null;
        }
        return new JdbcConnector(url, driver, defaultProperties);
    }

    private JdbcConnector(Stirng url, Driver driver, Properties defaultProperties) {
        this.url = url;
        this.driver = driver;
        this.defaultProperties = defaultProperties;
    }

    public Connection getConnection() {
        return driver.connect(url, this.defaultProperties);
    }
}
```

Uma implementação possível para `getJdbcConnection()` é confiar em um
estado englobado por essa função:

```java
private JdbcConnector jdbcConnector = /* inicializa de algum jeito */;

private Connection getJdbcConnection() {
    return jdbcConnector.getConnection();
}
```

Tudo muito bem até aqui. Mas... lembra do exemplo inicial de que o camponês
pede uma enxada no _pool_ de ferramentas? Então... Vamos levar isso em
consideração? No lugar de realmente fechar a conexão, podemos devolver
a conexão para o _pool_. Por uma questão de corretude vou proteger contra
múltiplos acessos simultâneos, mas não vou me preocupar aqui em eficiência.

Vamos aqui assumir que eu tenho uma classe chamada de `ConnectionDelegator`.
Ela implementa todos os métodos de `Connection`, porém não faz nada por conta
própria, só delega para um `connection` que é passado pra ela como construtor.
Por exemplo, para o método `isClosed()`:

```java
public abstract class ConnectionDelegator implements Connection {

    protected final Connection connection;

    public ConnectionDelegator(Connection connection) {
        this.connection = connection;
    }

    @Overrride
    public boolean isClosed() throws SQLException {
        return connection.isClosed();
    }

    // ... todos os outros métodos
}
```

E assim para os demais métodos. Ela é abstrata pelo simples fato de que
eu quero me forçar a quando for usar fazer algo que não seja uma simples
delegação.

Pois bem, vamos lá. A ideia é que vai ser pedida uma conexão, que pode
ou não existir. Se ela existir, eu envelopo nessa nova classe para poder
depois devolver ao _pool_ quando fechar a conexão. Hmmm, então vou fazer
algo no método `close()`... Tá, vamos envelopar antes. Vamos deixar o
`getConnection()` como `synchronized` para evitar problemas de concorrência:

```java
private final ArrayList<Connection> pool = new ArrayList<>();

private Connection getConnectionFromDriver() {
    if (pool.isEmpty()) {
        return driver.connect(url, this.defaultProperties);
    }
    return pool.removeLast();
}

public synchronized Connection getConnection() {
    final var availableConnection = getConnectionFromDriver();
    return new ConnectionDelegator(availableConnection) {

        @Override
        public void close() {
            // ...
        }
    };
}
```

Ok, se eu tiver elementos no _pool_ de conexões eu os uso
até ele ficar vazio. Mas ele nunca é preenchido! Pois vamos
resolver essa questão? Quando fechar, podemos devolver ao
_pool_!

```java
private synchronized void addToPool(Connection connection) {
    pool.addLast(connection);
}

public synchronized Connection getConnection() {
    final var availableConnection = getConnectionFromDriver();
    return new ConnectionDelegator(availableConnection) {

        @Override
        public void close() {
            addToPool(this.connection);
        }
    };
}
```

Ok, agora ao terminar de usar a conexão, ela é enviada de volta para
o _pool_. Isso não satisfaz a documentação do método
[`Connetion#close()`](https://docs.oracle.com/en/java/javase/21/docs/api/java.sql/java/sql/Connection.html#close()),
porque na documentação mencional que libera todos os recursos JDBC
relacionados a esta conexão. Isso significa que eu precisaria manter
um registro de todos `Statement`s, `ResultSet`s, `PreparedStatement`s
etc. Podemos lidar com isso criando um método `protected` em
`ConnectionDelegator` chamado `closeAllInnerResources()`. E chamar
ele no `close()`:

```java
public synchronized Connection getConnection() {
    final var availableConnection = getConnectionFromDriver();
    return new ConnectionDelegator(availableConnection) {

        @Override
        public void close() {
            this.closeAllInnerResources();
            addToPool(this.connection);
        }
    };
}
```

E com isso temos algo que me devolve conexões sob demanda
e que tem a capacidade de formar um _pool_ de recursos.

Sabe qual o nome que o Java dá para um objeto que fornece
conexões?
[`DataSource`](https://docs.oracle.com/en/java/javase/21/docs/api/java.sql/javax/sql/DataSource.html).
E sabe o que mais o Java tem a dizer sobre `DataSource`s?
Que existem alguns tipos, conceitualmente falando. E que desses
tipos os 2 mais relevante são:

- básico: não faz pooling, pediu conexão só cria e devolve
- _pooled_: em que há um pooling de conexões com o banco

E aqui passamos pelo processo justamente de criar conexões
sempre (tipo básico) como também evoluímos para um `DataSource`
_pooled_.

# O que é o HikariCP?

HikariCP é um `DataSource`. Especificamente, um _pooled_
`DataSource`. Só que ele tem uma característica:
ele é o mais rápido de todos. Para garantir essa velocidade,
no _pool_ de conexões dele para uso durante o ciclo de vida da
aplicação, o HikariCP faz um segredo: já cria todas as conexões
disponíves. Assim, ao chegar um `getConnection`, o HikariCP
só vai precisar verificar o _pool_ de conexões.

Se quiser se aprofundar no assunto, pode consultar [este artigo
no Baeldung](https://www.baeldung.com/hikaricp) sobre o assunto,
e também consultar [o repositório no
github](https://github.com/brettwooldridge/HikariCP/).
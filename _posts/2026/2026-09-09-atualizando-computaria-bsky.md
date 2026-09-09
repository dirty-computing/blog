---
layout: post
title: "Atualizando o sistema de postar no Bluesky"
author: "Jefferson Quesado"
tags: bluesky atprotocol node typescript meta
base-assets: "/assets/atualizando-computaria-bsky/"
pixmecoffe: jeffquesado
twitter: jeffquesado
---

Fazia um tempo que eu não usava o sistema de publicação no Bluesky que fiz no
[Publicando coisas da Computaria no Bluesky]({% post_url 2025/2025-01-14-publicar-bsky %}).
Então resolvi testar para publicar meu último artigo.

E aí... nada mais funciona direito 🤷‍♂️

# Atualizando as dependências

O primeiro erro que me apresentou foi uma coisa de login da Vercel. E isso me
levou a uma decisão que talvez não tenha sido a mais bem acertada: tentar
atualizar as libs. Ficou assim o diff:

```diff
   "dependencies": {
-    "@atproto/api": "^0.15.26",
-    "@vercel/node": "^5.3.6",
-    "dotenv": "^17.2.0",
-    "vercel": "^44.4.3"
+    "@atproto/api": "^0.20.42",
+    "@vercel/node": "^12.0.1",
+    "dotenv": "^17.4.2",
+    "vercel": "^59.11.7"
   },
+  "devDependencies": {
+    "@types/node": "^26.5.0"
   },
   ...
```

Bem, as coisas não saíram de graça, né? Tive alguns incovenientes pelo caminho,
e ainda não tinha conseguido me livrar do login da Vercel... até que vi que uma
das opções de rodar script já no `package.json` era `setup`. Pensei "por que
não?" e rodei esse comando, que finalmente me trouxe para a tela correta para
fazer o fluxo de login. Particularmente eu não tenho certeza se atualizar a
dependência da Vercel era necessário para fazer o fluxo novo, mas tudo bem,
foi.

# A falha do Yarn

A priori eu tinha feito para que funcionasse via `yarn`. Na época eu gostava do
`yarn` e achava mais simples e rápido do que o `npm`. Porém, algo começou a
incomodar: ao rodar `yarn` para baixar as dependências atualizadas, algo que eu
não lembrava de ter configurado para o projeto começava a pipocar:

```text
[2/4] 🚚  Fetching packages...
error @renovatebot/pep440@4.2.1: The engine "node" is incompatible with this module. Expected version "^20.9.0 || ^22.11.0 || ^24". Got "26.7.0"
warning @renovatebot/pep440@4.2.1: The engine "pnpm" appears to be invalid.
error Found incompatible module.
info Visit https://yarnpkg.com/en/docs/cli/install for documentation about this command.
```

E isso após uns 4 minutos! Eu não fazia questão de usar `yarn`, era mais uma
conveniência do passado. Então disso tchau a ele e abracei migrar para o
tradicional `npm` mesmo, que no lugar de falhar apenas reclama:

```text
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@renovatebot/pep440@4.2.1',
npm warn EBADENGINE   required: { node: '^20.9.0 || ^22.11.0 || ^24', pnpm: '^10.0.0' },
npm warn EBADENGINE   current: { node: 'v26.7.0', npm: '11.19.0' }
npm warn EBADENGINE }
```

O primeiro passo da migração foi tirar dos scripts coisas remanescentes do
`yarn`:

```diff
   "scripts": {
-    "setup": "yarn vercel login && yarn vercel link",
-    "start": "yarn vercel dev",
-    "dev": "yarn start",
+    "setup": "vercel login && vercel link",
+    "start": "vercel dev",
+    "dev": "npm start",
     "build": "echo oi"
   },
```

# Outras mudanças de configuração

Teve uma mudança que advém de alguma atualização do TypeScript: ele reclamou
que colocar no `tsconfig.json` o campo `compilerOptions.moduleResolution` com o
valor `node` era considerado deprecado. Portanto, precisei escolher uma versão
seguinte, gravitei para o lado `node16` sem muito pensamento crítico. A
mensagem fornecida era essa:


> Option 'moduleResolution=node10' is deprecated and will stop functioning in
> TypeScript 7.0. Specify compilerOption '"ignoreDeprecations": "6.0"' to
> silence this error.
>   Visit https://aka.ms/ts6 for migration information.
> 
> Specify the module resolution strategy:
> 
> - '`node16`' or '`nodenext`' for modern versions of Node.js. Node.js v12 and
>   later supports both ECMAScript imports and CommonJS require, which resolve
>   using different algorithms. These moduleResolution values, when combined
>   with the corresponding module values, picks the right algorithm for each
>   resolution based on whether Node.js will see an import or require in the
>   output JavaScript code.
> - '`node10`' (previously called '`node`') for Node.js versions older than
>   v10, which only support CommonJS require. You probably won't need to use
>   node10 in modern code.
> - '`bundler`' for use with bundlers. Like node16 and nodenext, this mode
>   supports package.json "imports" and "exports", but unlike the Node.js
>   resolution modes, bundler never requires file extensions on relative paths
>   in imports.
> - '`classic`' was used in TypeScript before the release of 1.6. classic
>   should not be used.
> 
> There are reference pages explaining the theory behind TypeScript's module
> resolution and the details of each option.
> 
> node: Deprecated, use "node10" in TypeScript 5.0+ instead

Coloquei como opção `node16`, afinal era mais novo e achei melhor fixar uma
versão do que colocar genericamente "next". Mas isso me gerou um novo problema:

> Option 'module' must be set to 'Node16' when option 'moduleResolution' is set
> to 'Node16'.

Ok, então vamos adicionar também `compilerOptions.module` com o valor adequado
então para poder aprciar o diff:

```diff
 {
   "compilerOptions": {
     "target": "es2017",
-    "moduleResolution": "node",
+    "moduleResolution": "node16",
     "esModuleInterop": true,
+    "module": "node16",
     "strict": true,
   },
   "include": [ "api/*.ts" ],
   "exclude": ["node_modules"],
   "strictPropertyInitialization": false
 }
```

Mas... bem, o `npm` também é mais chatinho de aceitar as coisas do que o
`yarn`, e o `npm` só queria liberar as coisas mediante umas reclamações
bizarras. Por exemplo, a seguinte importação começou a falhar:

```ts
import { CID } from 'multiformats/cid';
```

com a mensagem de erro:

> Package subpath './cid' is not defined by "exports"

Futricando o código chegou a cogitar botar os diretórios intermediários, como:

```ts
import { CID } from 'multiformats/dist/src/cid';
```

Mas ele continuava dando um jeito de reclamar. Foi então que finalmente
adicionei isto no `package.json`:

```json
"type": "module",
```

Oficialmente transformando agora o projeto em um projeto de TypeScript modular.
E isso resolveu o problema de localizar o `cid`, deixando o import válido sem
precisar de mudança alguma:

```ts
import { CID } from 'multiformats/cid';
```

Mas isso não foi tudo. Os imports de dentro do projeto começaram a falhar! Isso
aqui agora é inválido!

```ts
import { message , interpolateMessage, msg2html } from './message';
```

> Relative import paths need explicit file extensions in ECMAScript imports
> when '--moduleResolution' is 'node16' or 'nodenext'. Did you mean
> './message.js'?

Ok, fazer o quê, né? Vamos adicionar o `.js` em tudinho!

```diff
-import { message , interpolateMessage, msg2html } from './message';
+import { message , interpolateMessage, msg2html } from './message.js';
```

# Falhas/deprecados no Bluesky

Bem, atualizar dependência pode incorrer em tornar código inviável, não é?
Pequenas mudanças de comportamento aqui, algumas coisas que eram mais relaxadas
lá, uns deprecated não esperados e tal...

No meu caso, peguei 2 problemas. O primeiro que vou descrever aqui foi bem
tranquilo de resolver e explicar, mas na verdade ele não impedia nada de
funcionar, mas como é mais fácil de explicar, vou tratar logo ele.

Eu tinha um import específico em `thumbcache.ts`:

```ts
import { ipldToJson } from '@atproto/common-web';
```

Com o uso dessa função nesse contexto aqui:

```ts
function retrieveCache(currentBlobInfo: { digest: string; size: number; }): BlobRef | null {
    // ...
    return {
        ...jsonCidNormalized,
        ipld() {
            return {
                $type: 'blob',
                ref: this.ref,
                mimeType: this.mimeType,
                size: this.size,
            }
        },
        toJSON() {
            return ipldToJson(this.ipld()) as {
                $type: 'blob'
                ref: { $link: string }
                mimeType: string
                size: number
            }
        }
    }
}
```

A mensagem que veio junto do deprecado indicava a solução: utilize `lexToJson`
do pacote `@atproto/lexicon`. Então a solução foi bem prática, só substituir a
função:

```ts
import { lexToJson } from '@atproto/lexicon';

// ...

function retrieveCache(currentBlobInfo: { digest: string; size: number; }): BlobRef | null {
    // ...
    return {
        ...jsonCidNormalized,
        ipld() {
            return {
                $type: 'blob',
                ref: this.ref,
                mimeType: this.mimeType,
                size: this.size,
            }
        },
        toJSON() {
            return lexToJson(this.ipld()) as {
                $type: 'blob'
                ref: { $link: string }
                mimeType: string
                size: number
            }
        }
    }
}
```

Agora o outro erro foi mais interessante de caçar...

Ele simplesmente reclamava em uma validação interna do `@atproto`:

```text
.../node_modules/@atproto/lex-json/src/lex-json.ts:269
      throw new TypeError(`Invalid Lex value: ${typeof value}`)
            ^

TypeError: Invalid Lex value: function
```

Hmmm, ok? O stack trace infelizmente não trazia nenhum detalhe de onde veio
esse problema, apenas chamadas e mais chamadas dentro de `@atproto/lex-json`,
sem ponto de entrada visível do mundo externo.

Como era algo com a publicação (provavelmente, diga-se), resolvi interceptar
justamente onde fazia a publicação. Coloquei algumas guardas só para garantir
que realmente tinha algo a ver:

```diff
+console.log("antes de postar")
 const postado = await agent.post(step3);
+console.log("após postar")
```

E, como esperado, apareceu a mensagem "antes de postar" porém sem aparecer
"após postar". Ok, então o problema ocorria justamnte na função `agent.post`!
Logo, vamos inspecionar o que tem no `step3`? Mandei imprimir o objeto e obtive
isso como resposta:

```diff
+console.log("antes de postar")
+console.log(step3)
 const postado = await agent.post(step3);
+console.log("após postar")
```

```js
{
  '$type': 'app.bsky.feed.post',
  text: 'olha o que eu fiz: Publicando coisas da Computaria no Bluesky!',
  langs: [ 'pt-BR' ],
  facets: [ { index: [Object], features: [Array] } ],
  embed: {
    '$type': 'app.bsky.embed.external',
    external: {
      uri: 'https://computaria.gitlab.io/blog/2025/01/14/publicar-bsky',
      title: 'Publicando coisas da Computaria no Bluesky',
      description: 'bluesky atprotocol typescript vercel node html htmx',
      thumb: [Object]
    }
  }
}
```

Ok, ok, ok... aparentemente, ou é algo em `embed.external.thumb`, ou é algo em
`facets[].index`/`facets[].features`. Para investigar melhor dentro do
`facets`, devido ao tipo de `step3`, precisei fazer uma gambiarra para permitir
que eu possa investigar dentro:

```ts
const debugante: Record<string, any> = step3
console.log("debugante")
console.log(debugante.facets[0])
```

Essa transformação basicamente é um "widening": coloco um objeto em um tipo
mais amplo ainda, menos restritivo do que o objeto original. Saindo de um
objeto convencional com estrutura determinada para um `Record<string, any>` é
válido, pois um objeto convencional é um conjunto de chaves para valores
completamente arbitrários. Portanto, eu posso colocar na variável `debugante` o
objeto contido em `step3`: `debugante` é de um tipo mais amplo do que `step3`.

Com a nova sessão de depuração obtive isso:

```js
{
  index: { byteStart: 19, byteEnd: 61 },
  features: [
    {
      '$type': 'app.bsky.richtext.facet#link',
      uri: 'https://computaria.gitlab.io/blog/2025/01/14/publicar-bsky'
    }
  ]
}
```

Portanto, até segunda ordem, o `facets[]` será considerado inocente até segunda
ordem. Logo, me resta a `thumb`... que felizmente não preciso de gambiarra para
inspecionar pois o tipo de `step3` já prever como navego para dentro e obtenho
o thumb:

```ts
console.log("thumb?")
console.log(step3.embed.external.thumb)
```

E com isso obtive:

```js
{
  ref: CID(bafkreieg6lyhynujrhegdnvvh45pumpr24psnuhfk7gg2b4lm2x2aolf4q),
  mimeType: 'image/jpeg',
  size: 26533,
  original: {
    '$type': 'blob',
    ref: CID(bafkreieg6lyhynujrhegdnvvh45pumpr24psnuhfk7gg2b4lm2x2aolf4q),
    mimeType: 'image/jpeg',
    size: 26533
  },
  ipld: [Function: ipld],
  toJSON: [Function: toJSON]
}
```

Hmmm, começou a aparecer aqui uns `function`s... conforme a mensagem de erro.
Vamos então nos livrar dessas funções? E, olha só! Uma dessas funções é
justamente aquela que será alterada no futuro por conta da função deprecada do
`@atproto/common-web`! Agora é só interceptar onde que isso é gerado e remover
essas funções, certo?

Bem, errado. Olha as mensagens de erro que aparecem quando se remove uma dessas
funções:

```text
Property 'ipld' is missing in type '...' but required in type 'BlobRef'.

Property 'toJSON' is missing in type '...' but required in type 'BlobRef'.
```

Isso claramente indica que as funções aqui nesse passo são obrigatórias pela
tipagem. Portanto, se eu desejo alterar alguém, seria após esse retorno. A
montagem do `thumb` final ocorre na função `addBlobAtProtPost`, que é assim:

```ts
async function addBlobAtProtPost(post: object,
    blobMetaData: { uri: string; title: string; description: string; },
    uploadBlob: (blob: Blob, contentType: string) => Promise<ComAtprotoRepoUploadBlob.Response>
) {

    const blob = await getBabyBlob(uploadBlob)
    
    return {
        ...post,
        embed: {
            $type: "app.bsky.embed.external",
            external: {
                uri: blobMetaData.uri,
                title: blobMetaData.title,
                description: blobMetaData.description,
                thumb: blob
            }
        }
    }
}
```

Vamos adicionar mais umas linhas de depuração?

```ts
async function addBlobAtProtPost(post: object,
    blobMetaData: { uri: string; title: string; description: string; },
    uploadBlob: (blob: Blob, contentType: string) => Promise<ComAtprotoRepoUploadBlob.Response>
) {

    const blob = await getBabyBlob(uploadBlob)
    console.log("blob original")
    console.log(blob)
    
    return {
        ...post,
        embed: {
            $type: "app.bsky.embed.external",
            external: {
                uri: blobMetaData.uri,
                title: blobMetaData.title,
                description: blobMetaData.description,
                thumb: blob
            }
        }
    }
}
```

E eis que obtenho

```js
{
  ref: CID(bafkreieg6lyhynujrhegdnvvh45pumpr24psnuhfk7gg2b4lm2x2aolf4q),
  mimeType: 'image/jpeg',
  size: 26533,
  original: {
    '$type': 'blob',
    ref: CID(bafkreieg6lyhynujrhegdnvvh45pumpr24psnuhfk7gg2b4lm2x2aolf4q),
    mimeType: 'image/jpeg',
    size: 26533
  },
  ipld: [Function: ipld],
  toJSON: [Function: toJSON]
}
```

Massa! Vamos limpar isso para obter um `blob` limpo! E vamos chamar ele de
`reblob`! Como a ideia por hora é simplesmente tirar 2 campos, não vejo porque
fazer nada _fancy_ para esse fim, só listar os outros atributos do jeito que
vieram:

```ts
async function addBlobAtProtPost(post: object,
    blobMetaData: { uri: string; title: string; description: string; },
    uploadBlob: (blob: Blob, contentType: string) => Promise<ComAtprotoRepoUploadBlob.Response>
) {

    const blob = await getBabyBlob(uploadBlob)
    console.log("blob original")
    const reblob = {
        ref: blob.ref,
        mimeType: blob.mimeType,
        size: blob.size,
        original: blob.original
    }
    console.log(blob)
    console.log("reblob")
    console.log(reblob)
    
    return {
        ...post,
        embed: {
            $type: "app.bsky.embed.external",
            external: {
                uri: blobMetaData.uri,
                title: blobMetaData.title,
                description: blobMetaData.description,
                thumb: reblob

            }
        }
    }
}
```

O valor do `reblob` agora é

```js
{
  ref: CID(bafkreieg6lyhynujrhegdnvvh45pumpr24psnuhfk7gg2b4lm2x2aolf4q),
  mimeType: 'image/jpeg',
  size: 26533,
  original: {
    '$type': 'blob',
    ref: CID(bafkreieg6lyhynujrhegdnvvh45pumpr24psnuhfk7gg2b4lm2x2aolf4q),
    mimeType: 'image/jpeg',
    size: 26533
  }
}
```

E com isso...

```text
XRPCError: Invalid app.bsky.feed.post record: Expected blob value type (got {"ref": ..., "mimeType": ..., ...}) at $.record.embed.external.thumb
```

Ué. Só o `reblob` desse jeito não deu certo. Ele reclama algo como "Expected
blob value type"... bem, o `blob.original` tem um atributo justamente chamado
`'$type'` com o valor `blob` associado, seria isso? Pois vamos testar...

```ts
async function addBlobAtProtPost(post: object,
    blobMetaData: { uri: string; title: string; description: string; },
    uploadBlob: (blob: Blob, contentType: string) => Promise<ComAtprotoRepoUploadBlob.Response>
) {

    const blob = await getBabyBlob(uploadBlob)
    console.log("blob original")
    const reblob = blob.original
    console.log(blob)
    console.log("reblob")
    console.log(reblob)
    
    return {
        ...post,
        embed: {
            $type: "app.bsky.embed.external",
            external: {
                uri: blobMetaData.uri,
                title: blobMetaData.title,
                description: blobMetaData.description,
                thumb: reblob
            }
        }
    }
}
```

Agora o valor do `reblob` ficou

```js
{
  '$type': 'blob',
  ref: CID(bafkreieg6lyhynujrhegdnvvh45pumpr24psnuhfk7gg2b4lm2x2aolf4q),
  mimeType: 'image/jpeg',
  size: 26533
}
```

E postou! Yay!

Mas... será que isso é o certo mesmo? Pois bem, estava escrevendo o artigo e
resolvi futricar numa coisa... "e se eu usasse o `.toJSON()` para gerar o
`reblob`, o que será que acontece?"

```ts
async function addBlobAtProtPost(post: object,
    blobMetaData: { uri: string; title: string; description: string; },
    uploadBlob: (blob: Blob, contentType: string) => Promise<ComAtprotoRepoUploadBlob.Response>
) {

    const blob = await getBabyBlob(uploadBlob)
    console.log("blob original")
    const reblob = blob.toJSON()
    console.log(blob)
    console.log("reblob")
    console.log(reblob)
    
    return {
        ...post,
        embed: {
            $type: "app.bsky.embed.external",
            external: {
                uri: blobMetaData.uri,
                title: blobMetaData.title,
                description: blobMetaData.description,
                thumb: reblob
            }
        }
    }
}
```

A primeira coisa é que eu tenho o seguinte `reblob`:

```js
{
  '$type': 'blob',
  ref: {
    '$link': 'bafkreieg6lyhynujrhegdnvvh45pumpr24psnuhfk7gg2b4lm2x2aolf4q'
  },
  mimeType: 'image/jpeg',
  size: 26533
}
```

E tudo funciona! Yay de novo!! Isso me parece a melhor situação, pedir para
gerar o JSON.

# Trabalhos futuros para esse mini-app

Nada contra a Vercel, até tenho amigos que usam (desculpa, não pude resistir!).
Vercel ajuda sim com muita coisa. Mas eu particularmente não preciso dela para
subir as coisas que estou fazendo aqui.

Basicamente aqui estou utilizando do roteamento automático da Vercel para
servir um arquivo estático (`index.html`) e para fazer chamada de API HTTP em
cima da convenção deles:

- o nome do arquivo é o nome da rota
- o arquivo tem uma função exportada default
  `async handle(req: VercelRequest, res: VercelResponse)`

Isso pode e deve ser tranquilamente um app Express. Em breve será e eu venho
aqui com mais um post sobre isso. Falando em Express, tem um post
_in the making_ justamente sobre a escrita de um app em Express que eu fiz para
a pós. Tem bastante coisa interessante lá. Quando publicar eventualmente eu
coloco o link dele aqui, não tem porque ficar dando "spoilers" a mais do que
apenas "tô fazendo".

Também tem algumas melhorias que eu gostaria de fazer... ficar com a mensagem
aleatória é legal, mas eu gostaria de, também, me permitir selecionar qual a
mensagem que eu gostaria de postar. E inclusive isso pode simplesmente
renderizar a mensagem HTML por alto, só pra ter uma noção de como ficaria,
antes de submeter. Claro que a ideia da aleatoriedade é boa, teria sim uma
opção de mandar mensagem aleatória tal qual existe de publicar um post
aleatório.

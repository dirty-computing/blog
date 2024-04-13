[![Build Status](https://gitlab.com/computaria/blog/badges/master/pipeline.svg)](https://gitlab.com/computaria/blog/-/pipelines?ref=master)
![Jekyll Version](https://img.shields.io/gem/v/jekyll.svg)

---

Bem vindo ao Computaria! Aqui tem o meu blog.

Se quiser contribuir, só [abrir uma issue](../../issues) indicando como eu posso melhorar,
ou com uma ideia; ou mesmo pode mandar um [merge request](../../merge_request) com um artigo
seu ou com mudanças estruturais no blog. Colaborações são bem vindas! Por exemplo:

- !1+s

# Estrutura do blog

O blog é feito em [Jekyll](http://jekyllrb.com/). Você sempre pode consultar
a [documentação do Jekyll](https://jekyllrb.com/docs/home/), ela é uma ótima amiga por sinal.

Cada artigo tem sua própria seção de `assets`. Isso me ajudou a organizar os artigos e
evitar que o asset de um se misture com o asset do outro. Isso se aplica tanto a
rascunhos quanto a posts publicados propriamente ditos. Considerando que um artigo
é da forma `/_posts/{date-part}-{slug}.md` e um rascunho `/_drafts/{slug}.md`,
os assets desse artigo ficam em `/assets/{slug}/`.

Além dos assets, tem o [blog companion](https://gitlab.com/computaria/blog-companion) também.
A ligação é através da raiz do repositório, então seria `/{slug}/` o companion relacionado
ao artigo `{slug}`.

## Requisitos para colaborar no blog

Você precisa ter instalado Ruby 3.0 ou superior.

O Computaria foi testado com sucesso no Linux, no Mac e no Windows.

Algumas dependências do blog precisam (ou podem depender) de extensões nativas, é recomendável
ter ao alcance `gcc`, `g++` e `make`.

Para mais informações:

- [Criando o blog com Jekyll no GitLab](https://computaria.gitlab.io/blog/2021/08/30/criando-blog-jekyll)

## Colaborando criando um artigo

Temos um Rakefile que lida com boa parte da burocracia. Também, como autor externo,
tem um `.env` para que você possa preencher com suas informações e colaborar o
quanto desejar com artigos, sem precisar perder muito tempo.

Para começar, rode `rake .env`. Você será apresentado a uma TUI que irá fazer
algumas perguntas para você e irá preencher o arquivo `.env` com os
valores informados. Você pode sempre olhar o [`.env.example`](.env.example)
para ver quais são os valores.

Fazer esse setup vai poupar tempo no futuro e ele fica salvo no repositório.

Para criar um novo post, recomendo iniciar pelo rascunho dele.
Simplesmente peça ao Rakefile que ele crie por você, e você será guiado
pelo processo de criação:

![Criando um post com rake](/assets/little-improves/rake-blah.md.png)

Para citar posts, use `{% post_url 2021-09-17-desenhos-python-turtle %}` com
o nome do arquivo do post.

Assets ficam em uma pasta separada dentro dos assets, então coloque o que
precisa dos assets na pasta adequada. Por exemplo, os assets da página
da citação acima ficam em
[`/assets/desenhos-python-turtle/`](/assets/desenhos-python-turtle/).

A citação de imagens pode ser um tanto quanto sofrida, mas foi criado
um modo para tentar facilitar isso. Existe tanto o comando `rake`
quando o comando bash para fazer essa citação:

```bash
› bin/mention-image.sh assets/edita-svc-manualmente/1-iframe-cru.png
{{ page.base-assets | append: "1-iframe-cru.png" | relative_url }}

› rake assets/edita-svc-manualmente/1-iframe-cru.png:mention        
{{ page.base-assets | append: "1-iframe-cru.png" | relative_url }}
```

O `bin/mention-image.sh` funciona melhor com o auto complete do ZSH.

Para publicar, use o comando `rake publish`, ele irá te guiar no processo.

Para mais informações:

- [Pequenas melhorias no Computaria][little-improves]
- [Rakefile, parte 1 - publicar rascunho](https://computaria.gitlab.io/blog/2023/01/06/rakefile-publish-draft)
- [Rakefile, parte 2 - criando rascunho](https://computaria.gitlab.io/blog/2023/12/30/rakefile-create-draft)
- [Automatizando menção de imagem](https://computaria.gitlab.io/blog/2022/10/19/automatizando-mencao-imagem)

## Frontmatter

O Rakefile gera automaticamente boa parte do frontmatter para você. Tem os mesmos
campos padrões usados pelo Jekyll, e também os seguintes:

- `pixmecoffe`: o seu nome de usuário na [Pix me a Coffee](https://www.pixme.bio)
- `draft`: um booleano que indica se deve aparecer na listagem de arquivos,
  ou se deve ser considerado um rascunho publicado para apreciação de terceiros
- `base-assets`: uma variável no frontmatter para facilitar mencioanr imagens

Para mais informações:

- [Rascunhos publicados em Jekyll](https://computaria.gitlab.io/blog/2022/10/26/public-draft)
- [Pequenas melhorias no Computaria][little-improves]
- [Manipulando Liquid para permitir uma base dos assets](https://computaria.gitlab.io/blog/2021/09/12/base-assets)

[little-improves]: https://computaria.gitlab.io/blog/2024/04/09/little-improves
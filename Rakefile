task :default => :run

desc "Inicia o blog em modo de desenvolvimento na porta 4000, depois é só abrir http://localhost:4000/blog/"
task :run do |t|
    require "jekyll"
    conf = Jekyll.configuration({
        'show_drafts' => true,
        'watch' => true,
        'serving' => true
    })
    Jekyll::Commands::Build.process conf
    Jekyll::Commands::Serve.process conf
end

desc "Abre o browser com o blog"
task :browser do |t|
    require 'dotenv/load'
    sh "open #{"-a #{ENV["BROWSER_NAME"]}" unless ENV["BROWSER_NAME"].nil?} http://localhost:4000/blog/"
end

desc "Publica um rascunho, perguntando ao usuário qual rascunho publicar"
task :publish do |t|
    require "cli/ui"

    draft2publish = CLI::UI::Prompt.ask('Vamos publicar quem?', options:  Dir["_drafts/*.md"].map {|s| s.sub(/^_drafts\/(.*)\.md$/, '\1') })
    sh "#{"bash " if Gem.win_platform?}bin/publish.sh #{draft2publish}" # melhorar, só chamar bash se souber estar no win
end

desc "Ajuda na citação de uma imagem"
rule(/^assets\/.*\.(png|jpe?g|gif|svg):mention$/) do |t|
    referenceFromBaseAssets = t.name.split(":")[0..-2].join(":").split("/")[2..].join("/")
    puts "{{ page.base-assets | append: \"#{referenceFromBaseAssets}\" | relative_url }}"
end

desc "Guia o usuário na criação do arquivo com as variáveis de ambiente para ter opções padrões ao criar novos artigos"
file '.env' => '.env.example' do |t|
    linhasEnv = File.readlines '.env.example'
    require "cli/ui"
    
    File.open '.env', mode = 'w' do |file|
        linhasEnv.each do |linha|
            envvar = linha[...-2]
            envvalue = title = CLI::UI::Prompt.ask( "Qual o valor para [#{envvar}]?", default: ENV[envvar])
            file.write "#{envvar}=\"#{envvalue}\"\n" unless envvalue.empty?
        end
    end
end

desc "Cria um rascunho"
rule(/^_drafts\/.*\.md$/) do |t|
    require 'dotenv/load'

    author = ENV["COMPUTARIA_AUTHOR"]
    author = "Jefferson Quesado" if author.nil?
    pixme = ENV["COMPUTARIA_PIXME"]
    twitter = ENV["TWITTER_HANDLER"]

    fileName = t.name

    radix = fileName.sub /_drafts\/(.*)\.md/, '\1'
    require "cli/ui"
    title = CLI::UI::Prompt.ask('Qual o título?')
    tags = CLI::UI::Prompt.ask('Quais as tags (separadas por espaço)?')

    template =  "layout: post
title: \"#{title}\"
author: \"#{author}\"
tags: #{tags}
base-assets: \"/assets/#{radix}/\"
"
    File.open fileName, mode = 'w' do |file|
        file.write "---\n"
        file.write template
        file.write "pixmecoffe: #{pixme}\n" unless pixme.nil?
        file.write "twitter: #{twitter}\n" unless twitter.nil?
        file.write "---\n"
    end
    puts "escreveu em #{fileName}, abrindo..."
    spawn("code #{fileName}", :out => :out, :err => :err)
    Process.wait
end
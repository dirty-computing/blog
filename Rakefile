task :default => :run

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

task :publish do |t|
    require "cli/ui"

    draft2publish = CLI::UI::Prompt.ask('Vamos publicar quem?', options:  Dir["_drafts/*.md"].map {|s| s.sub(/^_drafts\/(.*)\.md$/, '\1') })
    sh "#{"bash " if Gem.win_platform?}bin/publish.sh #{draft2publish}" # melhorar, só chamar bash se souber estar no win
end

rule(/^assets\/.*\.(png|jpe?g|gif|svg):mention$/) do |t|
    referenceFromBaseAssets = t.name.split(":")[0..-2].join(":").split("/")[2..].join("/")
    puts "{{ page.base-assets | append: \"#{referenceFromBaseAssets}\" | relative_url }}"
end

rule(/^_drafts\/.*\.md$/) do |t|
    fileName = t.name

    radix = fileName.sub /_drafts\/(.*)\.md/, '\1'
    require "cli/ui"
    title = CLI::UI::Prompt.ask('Qual o título?')
    tags = CLI::UI::Prompt.ask('Quais as tags (separadas por espaço)?')

    template =  "---
layout: post
title: \"#{title}\"
author: \"Jefferson Quesado\"
tags: #{tags}
base-assets: \"/assets/#{radix}/\"
---
"
    File.open fileName, mode = 'w' do |file|
        file.write template
    end
    puts "escreveu em #{fileName}, abrindo..."
    spawn("code #{fileName}", :out => :out, :err => :err)
    Process.wait
end
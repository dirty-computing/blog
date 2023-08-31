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

rule( /^_drafts\/.*\.md$/) do |t|
    p "cc -c -o #{t.name}"
end

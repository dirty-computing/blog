require "jekyll"

module Computaria
    class TagPageGenerator < Jekyll::Generator
        def generate(site)
            site.categories["tags"] = []
            reverse_alias = Computaria::reverse_alias_tag_pure_data site.data["tag_alias"]

            normalized_tags_posts = { }
            site.tags.each do |tag, posts|
                posts_local = posts.select do |p|
                    p.data["draft"] != 'true'
                end
                next if posts_local.empty?
                unaliased_tag = unless reverse_alias.nil? or reverse_alias[tag].nil?
                    reverse_alias[tag]["tag"]
                else
                    tag
                end
                if normalized_tags_posts[unaliased_tag].nil?
                    normalized_tags_posts[unaliased_tag] = posts_local
                else
                    normalized_tags_posts[unaliased_tag] += posts_local
                end
            end
            normalized_tags_posts.each do |tag, posts_local|
                tagPage = TagPage.new(site, tag, posts_local.sort_by do |post| post.date end.uniq.reverse)
                site.categories["tags"] << tagPage
                site.pages << tagPage
            end
            central = CentralTag.new(site, site.categories["tags"])
            site.categories["tags"] << central
            site.pages << central
        end
    end

    class TagPage < Jekyll::Page
        attr_reader :tag, :posts, :data
        def initialize(site, tag, posts)
            @site = site                     # the current site instance.
            @base = "#{site.source}/#{tag}"  # path to the source directory.
            @dir  = "tags/#{tag}"            # the directory the page will reside in.
            @tag = tag
            @posts = posts

            # All pages have the same filename, so define attributes straight away.
            @basename = 'index'      # filename without the extension.
            @ext      = '.html'      # the extension.
            @name     = 'index.html' # basically @basename + @ext.

            # Initialize data hash with a key pointing to all posts under current category.
            # This allows accessing the list in a template via `page.linked_docs`.
            @data = {
                "layout" => "tag-list",
                "tag" => tag,
                "posts" => @posts,
                "title" => tag
            }
        end
    end

    class CentralTag < Jekyll::Page
        def initialize(site, tags)
            @site = site           # the current site instance.
            @base = site.source    # path to the source directory.
            @dir  = "tags"         # the directory the page will reside in.

            # All pages have the same filename, so define attributes straight away.
            @basename = 'index'      # filename without the extension.
            @ext      = '.html'      # the extension.
            @name     = 'index.html' # basically @basename + @ext.

            # Initialize data hash with a key pointing to all posts under current category.
            # This allows accessing the list in a template via `page.linked_docs`.
            @data = {
                "layout" => "tags",
                "sitetags" => tags.sort_by do |element| element.tag.downcase.gsub("á", "a") end,
                "show" => true,
                "title" => "Tags"
            }
        end
    end

    module TagNormalizer
        def normalize_tags(input)
            reverse_alias = Computaria::reverse_alias_tag @context
            return input if reverse_alias.nil?
            input.map do |element|
                unless reverse_alias[element].nil?
                    reverse_alias[element]["tag"]
                else
                    element
                end
            end
        end
    end

    private

    def self.reverse_alias_tag(context)
        reverse_alias = context.registers[:reverse_alias]
        return reverse_alias unless reverse_alias.nil?

        tag_alias = context.registers[:site].data["tag_alias"]
        return nil if tag_alias.nil?

        reverse_alias = reverse_alias_tag_pure_data tag_alias

        context.registers[:reverse_alias] = reverse_alias
        return reverse_alias
    end

    def self.reverse_alias_tag_pure_data(tag_alias)
        return nil if tag_alias.nil?

        reverse_alias = { }
        for tag in tag_alias do
            for single_alias in tag["alias"] do
                reverse_alias[single_alias] = tag
            end
        end
        return reverse_alias
    end
end

Liquid::Template.register_filter(Computaria::TagNormalizer)
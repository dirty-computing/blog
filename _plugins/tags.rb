require "jekyll"

module Computaria
    class TagPageGenerator < Jekyll::Generator
        def generate(site)
            site.categories["tags"] = []
            site.tags.each do |tag, posts|
                posts_local = posts.select do |p|
                    p.data["draft"] != 'true'
                end
                next if posts_local.empty?
                tagPage = TagPage.new(site, tag, posts_local)
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
                "layout" => "default",
                "sitetags" => tags.sort_by do |element| element.tag.downcase.gsub("á", "a") end,
                "show" => true,
                "title" => "Tags"
            }

            @content = "
<div class='home'>

<h1 class='page-heading'>Posts por tag</h1>

<ul class='post-list'>
    {% for tag in page.sitetags %}
        <li>
            <span class='post-meta'>{{ tag.posts.size }} posts</span>
            <h2>
                <a class='post-link' href='{{ tag.url | prepend: site.baseurl }}'>{{ tag.tag }}</a>
            </h2>
        </li>
    {% endfor %}
</ul>
</div>
          
            "
        end
    end
end

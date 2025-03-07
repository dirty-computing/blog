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



          class PostComparer
            MATCHER = %r!^(.+/)*(\d+-\d+-\d+)-(.*)$!.freeze
      
            attr_reader :path, :date, :slug, :name
      
            def initialize(name)
              @name = name
      
              all, @path, @date, @slug = *name.sub(%r!^/!, "").match(MATCHER)
              unless all
                raise Jekyll::Errors::InvalidPostNameError,
                      "'#{name}' does not contain valid date and/or title."
              end
      
              basename_pattern = "#{date}-#{Regexp.escape(slug)}\\.[^.]+"
              @name_regex = %r!^_posts/#{path}#{basename_pattern}|^#{path}_posts/?#{basename_pattern}!
            end
      
            def post_date
              @post_date ||= Jekyll::Utils.parse_date(
                date,
                "'#{date}' does not contain valid date and/or title."
              )
            end
      
            def ==(other)
              other.relative_path.match(@name_regex)
            end
      
            def deprecated_equality(other)
              slug == post_slug(other) &&
                post_date.year  == other.date.year &&
                post_date.month == other.date.month &&
                post_date.day   == other.date.day
            end
      
            private
      
            # Construct the directory-aware post slug for a Jekyll::Post
            #
            # other - the Jekyll::Post
            #
            # Returns the post slug with the subdirectory (relative to _posts)
            def post_slug(other)
              path = other.basename.split("/")[0...-1].join("/")
              if path.nil? || path == ""
                other.data["slug"]
              else
                "#{path}/#{other.data["slug"]}"
              end
            end
          end
      
          class PostUrlWA < Liquid::Tag
            include Jekyll::Filters::URLFilters
      
            def initialize(tag_name, post, tokens)
              super
              @orig_post = post.strip
              #begin
              #  @post = PostComparer.new(@orig_post)
              #rescue StandardError => e
              #  raise Jekyll::Errors::PostURLError, <<~MSG
              #    Could not parse name of post "#{@orig_post}" in tag 'post_url'.
              #     Make sure the post exists and the name is correct.
              #     #{e.class}: #{e.message}
              #  MSG
              #end
            end
      
            def render(context)
              @context = context
              liquid_solved_orig_post = Liquid::Template.parse(@orig_post).render(context)

              if liquid_solved_orig_post == @orig_post
                post_from_input_string = "\"#{liquid_solved_orig_post}\""
              else
                post_from_input_string = "\"#{liquid_solved_orig_post}\" (from input \"#{@orig_post}\")"
              end
              begin
                post = PostComparer.new(liquid_solved_orig_post)
              rescue StandardError => e
                raise Jekyll::Errors::PostURLError, <<~MSG
                  Could not parse name of post #{post_from_input_string} in tag 'post_url'.
                   Make sure the post exists and the name is correct.
                   #{e.class}: #{e.message}
                MSG
              end

              #print "post_path #{post_path}\n"
              #print "post #{post}\n"
              #print "---------\n"

              site = context.registers[:site]
      
              site.posts.docs.each do |document|
                return relative_url(document) if post == document
              end
      
              # New matching method did not match, fall back to old method
              # with deprecation warning if this matches
      
              site.posts.docs.each do |document|
                next unless post.deprecated_equality document
      
                Jekyll::Deprecator.deprecation_message(
                  "A call to '{% post_url #{post.name} %}' did not match a post using the new " \
                  "matching method of checking name (path-date-slug) equality. Please make sure " \
                  "that you change this tag to match the post's name exactly."
                )
                return relative_url(document)
              end
      
              raise Jekyll::Errors::PostURLError, <<~MSG
                Could not find post #{post_from_input_string} in tag 'post_url'.
                Make sure the post exists and the name is correct.
              MSG
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
Liquid::Template.register_tag("post_urlwa", Computaria::PostUrlWA)
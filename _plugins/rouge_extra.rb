require "rouge" unless defined?(Rouge)

module RougeGMPL
    class GMPL < Rouge::RegexLexer
        # baseado em https://github.com/rouge-ruby/rouge/blob/v4.7.0/lib/rouge/lexers/c.rb

        tag 'gmpl'
        desc 'GNU MathProg Lang'

        ws = %r((?:\s|//.*?\n|/[*].*?[*]/)+)
        id = /[a-zA-Z_][a-zA-Z0-9_]*/

        def self.keywords
            @keywords ||= Set.new %w(
                "subject to"
                "subj to"
                "s.t."
                var
                min
                minimize
                max
                maximize
                end
                integer
                solve
                display
                printf
            )
        end

        start do
            push :root
        end

        state :inline_whitespace do
            rule %r/[ \t\r]+/, Text
        end

        state :whitespace do
            rule %r/\n+/m, Text
            mixin :comment_line
            mixin :inline_whitespace
        end

        state :comment_line do
            rule %r(#(.*)?\n?), Comment::Single
        end

        state :root do
            mixin :whitespace
            mixin :comment_line
            rule %r((\d+[.]\d*|[.]?\d+)e[+-]?\d+[lu]*)i, Num::Float
            rule %r/\d+[lu]*/i, Num::Integer
            rule %r([+-/*<>=]), Operator
            rule %r([:;]), Punctuation
            rule %r/subject#{ws}to/, Keyword
            rule %r/subj#{ws}to/, Keyword
            rule %r/s\.t\./, Keyword
            rule id do |m|
                name = m[0]
                if self.class.keywords.include? name
                    token Keyword
                else
                    token Name
                end
            end
        end
    end

    class Abobora < Rouge::RegexLexer
        tag 'abobora'

        start do
            push :root
        end

        state :inline_whitespace do
            rule %r/[ \t\r]+/, Text
            rule %r/\\\n/, Text # line continuation
        end

        state :whitespace do
            rule %r/\n+/m, Text
            mixin :inline_whitespace
        end

        state :root do
            mixin :whitespace
            rule %r/abobora/, Keyword
        end
    end
end

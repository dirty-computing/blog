require "rouge"

module Rouge
   module Lexers
        class GMPL < RegexLexer
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

            start { push :bol }

            state :expr_bol do
                mixin :inline_whitespace

                rule %r/#if\s0/, Comment, :if_0
                rule %r/#/, Comment::Preproc, :macro

                rule(//) { pop! }
            end
            state :bol do
                rule %r/#{id}:(?!:)/, Name::Label
                mixin :expr_bol
            end


            state :inline_whitespace do
                rule %r/[ \t\r]+/, Text
                rule %r/\\\n/, Text # line continuation
                rule %r(/(\\\n)?[*].*?[*](\\\n)?/)m, Comment::Multiline
            end

            state :whitespace do
                rule %r/\n+/m, Text, :bol
                rule %r(//(\\.|.)*?$), Comment::Single, :bol
                mixin :inline_whitespace
            end

            state :root do
                mixin :whitespace
                rule %r((\d+[.]\d*|[.]?\d+)e[+-]?\d+[lu]*)i, Num::Float
                rule %r/\d+[lu]*/i, Num::Integer
                rule %r([+-/*<>=]), Operator
                rule %r([:;]), Punctuation
                rule %r/subject to/, Keyword
                rule %r/subj to/, Keyword
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
   end
end

.PHONY: run

run:
	bundle exec jekyll s --drafts -w

_drafts/%.md:
	bin/new-post.sh "$@"

.PHONY: deploy

deploy:
	ghp-import build -b gh-pages
	git push origin gh-pages:gh-pages

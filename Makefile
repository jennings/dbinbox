.PHONY: all format install-prettier

all: format

format:
	prettier --write --no-semi public/js/app.js

install-prettier:
	yarn global add prettier || npm install -g prettier

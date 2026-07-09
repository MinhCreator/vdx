DOTFILES := $(HOME)/.dotfiles
TARGET  := $(HOME)/.config

.PHONY: link clean install

link: link-home link-apps link-system

link-home:
	stow --no-folding --dir=$(DOTFILES)/home --target=$(HOME) .

link-apps:
	stow --no-folding --dir=$(DOTFILES)/apps --target=$(TARGET) .

link-system:
	stow --no-folding --dir=$(DOTFILES)/system --target=$(TARGET) .

clean:
	stow -D --no-folding --dir=$(DOTFILES)/home --target=$(HOME) .
	stow -D --no-folding --dir=$(DOTFILES)/apps --target=$(TARGET) .
	stow -D --no-folding --dir=$(DOTFILES)/system --target=$(TARGET) .
	-find "$(TARGET)" -mindepth 1 -type d -empty -delete

install: link
	git config core.hooksPath hooks
	@echo "hooksPath set to hooks/"

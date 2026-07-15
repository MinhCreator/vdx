DOTFILES := $(HOME)/.dotfiles
TARGET   := $(HOME)/.config

.PHONY: link clean force install check-deps verify setup link-home link-apps link-system

link: link-home link-apps link-system

link-home:
	stow --no-folding --dir=$(DOTFILES)/home --target=$(HOME) .

link-apps:
	stow --no-folding --dir=$(DOTFILES)/apps --target=$(TARGET) .

link-system:
	stow --no-folding --dir=$(DOTFILES)/system --target=$(TARGET) .

link-%:
	@target="$(HOME)"; \
	for dir in home apps system; do \
		if [ -d "$(DOTFILES)/$$dir/$*" ]; then \
			[ "$$dir" = "home" ] || target="$(TARGET)"; \
			stow --no-folding --dir=$(DOTFILES)/$$dir --target="$$target" $* && exit 0; \
		fi; \
	done; \
	echo "Package '$*' not found"

clean:
	stow -D --no-folding --dir=$(DOTFILES)/home --target=$(HOME) .
	stow -D --no-folding --dir=$(DOTFILES)/apps --target=$(TARGET) .
	stow -D --no-folding --dir=$(DOTFILES)/system --target=$(TARGET) .
	-find "$(TARGET)" -mindepth 1 -type d -empty -delete

force:
	@stow -D --no-folding --dir=$(DOTFILES)/home --target=$(HOME) . 2>/dev/null || true
	@stow -D --no-folding --dir=$(DOTFILES)/apps --target=$(TARGET) . 2>/dev/null || true
	@stow -D --no-folding --dir=$(DOTFILES)/system --target=$(TARGET) . 2>/dev/null || true
	@echo "Removed old links, restowing..."
	$(MAKE) link

check-deps:
	@command -v stow >/dev/null 2>&1 || { echo "Error: stow not found. Install with: sudo pacman -S stow"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "Error: git not found"; exit 1; }

verify:
	@echo "Checking symlinks..."
	@broken=0; \
	for f in $$(find $(HOME) $(TARGET) -maxdepth 2 -type l 2>/dev/null); do \
		if [ ! -e "$$f" ]; then \
			echo "BROKEN: $$f"; \
			broken=1; \
		fi; \
	done; \
	[ $$broken -eq 0 ] && echo "All symlinks OK"

install: check-deps link
	chmod +x hooks/*
	git submodule update --init --recursive
	git config core.hooksPath hooks
	@echo "Done. Hooks: post-checkout, post-merge, post-rebase"

setup: check-deps
	sudo pacman -S --needed stow git
	@echo "Installing oh-my-zsh..."
	@sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
	@echo "Installing starship..."
	@curl -sS https://starship.rs/install.sh | sh
	$(MAKE) install

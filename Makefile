# GNU Makefile that documents and automates common development operations
#              using the GNU make tool (version >= 3.81)
# Development is typically conducted on Linux or Max OS X (with the Xcode
#              command-line tools installed), so this Makefile is designed
#              to work in that environment (and not on Windows).
# USAGE: Package-Builder$ make [TARGET]

.PHONY=help
help:
	@echo "USAGE: make [TARGET]"
	@echo "TARGETS:"
	@echo "help       : show help message"
	@echo "clean      : remove .pyc files and local package"
	@echo "package    : build and install local package"
	@echo "pytest     : generate report for and cleanup after pytest"
	@echo "cstest     : generate coding-style errors using the"
	@echo "             pycodestyle (nee pep8) and pylint tools"
	@echo "coverage   : generate test coverage report"
	@echo "git-sync   : synchronize local, origin, and upstream Git repos"
	@echo "git-pr N=n : create local pr-n branch containing upstream PR"

.PHONY=clean
clean:
	@find . -name *pyc -exec rm {} \;
	@find . -name *cache -maxdepth 1 -exec rm -r {} \;
	@./conda.recipe/remove_local_package.sh

.PHONY=package
package:
	@cd conda.recipe ; ./install_local_package.sh

define pytest-cleanup
find . -name *cache -maxdepth 1 -exec rm -r {} \;
endef

.PHONY=pytest
pytest:
	@cd pkgbld ; pytest -n4
	@$(pytest-cleanup)

PYLINT_FILES := $(shell grep -rl --include="*py" disable=locally-disabled .)
PYLINT_OPTIONS = --disable=locally-disabled --score=no --jobs=4

.PHONY=cstest
cstest:
	-pycodestyle pkgbld
	@-pylint $(PYLINT_OPTIONS) $(PYLINT_FILES)

define coverage-cleanup
rm -f .coverage htmlcov/*
endef

OS := $(shell uname -s)

.PHONY=coverage
coverage:
	@$(coverage-cleanup)
	@coverage run -m pytest -v > /dev/null
	@coverage html --ignore-errors
ifeq ($(OS), Darwin) # on Mac OS X
	@open htmlcov/index.html
else
	@echo "Open htmlcov/index.html in browser to view report"
endif
	@$(pytest-cleanup)

.PHONY=git-sync
git-sync:
	@./gitsync

.PHONY=git-pr
git-pr:
	@./gitpr $(N)
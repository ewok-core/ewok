SHELL := /usr/bin/env bash
EXEC = python=3.10
PACKAGE = ewok
SRC = scripts
INSTALL = python -m pip install
ACTIVATE = source activate $(PACKAGE)
.DEFAULT_GOAL := help

## help      : print available build commands.
.PHONY : help
help : Makefile
	@sed -n 's/^##//p' $<

## update    : update repo with latest version from GitHub.
.PHONY : update
update :
	@git pull origin main

## env       : setup environment and install dependencies.
.PHONY : env
env : $(PACKAGE).egg-info/
$(PACKAGE).egg-info/ : setup.py requirements.txt
ifeq (0, $(shell conda env list | grep -wc $(PACKAGE)))
	@conda create -yn $(PACKAGE) $(EXEC)
endif
	@$(ACTIVATE); python -m pip install -e "."
	@touch $(PACKAGE).egg-info/

## setup     : decompress templates and finalize setup.
.PHONY : setup
setup : env config.zip
	@$(ACTIVATE); conda install conda-forge::zip
	@$(ACTIVATE); unzip -o config.zip -d ./
	@echo "Setup complete."

## format    : format code with black.
.PHONY : format
format : env
	@$(ACTIVATE); black .

## test      : run testing pipeline.
.PHONY : test
test: style static integration
style : black
static : pylint 
docs: pdoc
integration : test_pipeline
pdoc: env docs/index.html
pylint : env html/pylint/index.html
black : env
	@$(ACTIVATE); black --check .
test_pipeline : env $(SRC)/test.sh $(PACKAGE)/*.py $(PACKAGE)/*/*.py
	@$(ACTIVATE); cd $(SRC)/ && bash test.sh
docs/index.html : $(PACKAGE)/*.py $(PACKAGE)/*/*.py
	@$(ACTIVATE); pdoc \
	$(PACKAGE) \
	-o $(@D)
html/pylint/index.html : html/pylint/index.json
	@$(ACTIVATE); pylint-json2html -o $@ -e utf-8 $<
html/pylint/index.json : $(PACKAGE)/*.py $(PACKAGE)/*/*.py
	@mkdir -p $(@D)
	@$(ACTIVATE); pylint $(PACKAGE) \
	--disable C0112,C0113,C0114,C0115,C0116,C0103,C0301 \
	--generated-members=torch.* \
	--output-format=colorized,json:$@ \
	|| pylint-exit $$?

## ewok-core   : build ewok-core dataset.
.PHONY : ewok-core
ewok-core : $(SRC)/ewok-core.sh $(PACKAGE)/compile/*.py config/*/*.*
	@$(ACTIVATE); cd $(SRC) && bash ewok-core.sh

## clean     : remove all generated files.
.PHONY : clean
clean : 
	@rm -rf output/

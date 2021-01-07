#
# Makefile: Commands to simplify development and releases
#
# Usage:
#
#    make clean
#    make checks
#    make patch build upload

# You can set these variable on the command line.
PYTHON = python3.8

# Where everything lives
site_python := /usr/bin/env $(PYTHON)

root_dir = $(realpath .)
app_dir = $(root_dir)/src/crispy_forms_gds
frontend_dir = $(root_dir)/demo/frontend

python := $(root_dir)/venv/bin/python3
pip := $(root_dir)/venv/bin/pip3
pip-compile := $(root_dir)/venv/bin/pip-compile
pip-sync := $(root_dir)/venv/bin/pip-sync
django := $(python) $(root_dir)/demo/manage.py
checker := $(root_dir)/venv/bin/flake8
black := $(root_dir)/venv/bin/black
isort := $(root_dir)/venv/bin/isort
pytest := $(root_dir)/venv/bin/pytest
coverage := $(root_dir)/venv/bin/coverage
bumpversion := $(root_dir)/venv/bin/bump2version
twine := $(root_dir)/venv/bin/twine
nvm := sh ~/.nvm/nvm.sh


commit_opts := --gpg-sign
upload_opts := --skip-existing --sign
pytest_opts := --flake8 --black --isort

.PHONY: help
help:
	@echo "Please use 'make <target>' where <target> is one of:"
	@echo ""
	@echo "  help                 to show this list"
	@echo "  clean-build          to clean the files and directories generated by previous builds"
	@echo "  clean-docs           to clean the generated HTML documentation"
	@echo "  clean-frontend       to clean the frontend assets and node packages"
	@echo "  clean-tests          to clean the directories created during testing"
	@echo "  clean-coverage       to clean the test coverage data and reports"
	@echo "  clean-venv           to clean the virtualenv"
	@echo "  clean                to clean everything EXCEPT the virtualenv"
	@echo
	@echo "  build                to build the package"
	@echo "  checks               to run quality code checks"
	@echo "  coverage             to measure the test coverage"
	@echo "  docs                 to build the HTML documentation"
	@echo "  frontend             to install and build the Design System assets for the demo site"
	@echo "  install              to install the dependencies"
	@echo "  major                to update the version number for a major release, e.g. 2.1 to 3.0"
	@echo "  messages             to run the makemessages and compilemessages management commands"
	@echo "  migrate              to run migrate management command"
	@echo "  migrations           to run makemigrations management command"
	@echo "  minor                to update the version number for a minor release, e.g. 2.1 to 2.2"
	@echo "  patch                to update the version number for a patch release, e.g. 2.1.1 to 2.1.2"
	@echo "  runserver            to run the Django demo site"
	@echo "  test                 to run the tests during development"
	@echo "  test-all             to run the tests for all the supported environments"
	@echo "  upload               to upload a release to PyPI repository"
	@echo "  venv                 to create the virtualenv"
	@echo

.PHONY: clean-build
clean-build:
	rm -rf build
	rm -rf src/*.egg-info

.PHONY: clean-docs
clean-docs:
	cd docs && make clean

.PHONY: clean-frontend
clean-frontend:
	rm -rf $(frontend_dir)/dist
	rm -rf $(frontend_dir)/node_modules
	rm -f $(frontend_dir)/package-lock.json
.PHONY: clean-tests
clean-tests:
	rm -rf .tox
	rm -rf .pytest_cache

.PHONY: clean-coverage
clean-coverage:
	rm -rf .coverage
	rm -rf reports/coverage

.PHONY: clean-venv
clean-venv:
	rm -rf venv

.PHONY: clean
clean: clean-build clean-tests clean-coverage clean-docs

.PHONY: build
build: clean-build
	$(python) setup.py sdist bdist_wheel

.PHOMY: checks
checks:
	flake8 $(app_dir)
	black --check $(app_dir)
	isort --check $(app_dir)

.PHONY: coverage
coverage:
	pytest --cov=crispy_forms_gds --cov-config=setup.cfg --cov-report html

.PHONY: docs
docs:
	cd docs && make html

$(frontend_dir)/node_modules:
	cd $(frontend_dir) && $(nvm) use && npm install

$(frontend_dir)/dist: $(frontend_dir)/node_modules
	cd $(frontend_dir) && $(nvm) use && npm run dev

.PHONY: frontend
frontend: $(frontend_dir)/dist

.PHONY: install
install: venv frontend
	$(pip) install --upgrade pip setuptools wheel
	$(pip) install pip-tools
	$(pip-sync) requirements/dev.txt

.PHONY: major
major:
	$(bumpversion) major

.PHONY: messages
messages:
	cd $(app_dir) && $(django) makemessages --no-obsolete --all && $(django) compilemessages

.PHONY: migrate
migrate:
	$(django) migrate

.PHONY: migrations
migrations:
	$(django) makemigrations

.PHONY: minor
minor:
	$(bumpversion) minor

.PHONY: patch
patch:
	$(bumpversion) patch

.PHONY: runserver
runserver:
	$(django) migrate
	$(django) runserver

.PHONY: test
test:
	pytest $(pytest_opts)

.PHONY: test-all
test-all: test
	tox
	tox -e docs

.PHONY: upload
upload:
	$(twine) upload $(upload_opts) dist/*

venv:
	$(site_python) -m venv venv

# include any local makefiles
-include *.mk

# Project Layout
The project is layout as follows:

*data*: default Hiera parameters
*files*: files used for `source` in `file` resources
*lib*: helper Ruby methods and Facter facts
*manifests*: core Puppet logic
*scripts*: non-Puppet scripts to help with Puppet bootstrapping
*spec*: something Puppet requires that we don't use
*templates*: epp template files

# Validating Puppet Code
Run `pdk validate` in the module root directory. This runs a `puppet-lint` and provides a very basic static analysis of your Puppet module.

# Generating Documentation
Run `puppet strings generate --format markdown --out REFERENCES.md` in the module root directory.

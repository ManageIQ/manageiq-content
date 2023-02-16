# ManageIQ::Content

[![CI](https://github.com/ManageIQ/manageiq-content/actions/workflows/ci.yaml/badge.svg?branch=petrosian)](https://github.com/ManageIQ/manageiq-content/actions/workflows/ci.yaml)
[![Maintainability](https://api.codeclimate.com/v1/badges/bc6773f3e24fd6323a5c/maintainability)](https://codeclimate.com/github/ManageIQ/manageiq-content/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/bc6773f3e24fd6323a5c/test_coverage)](https://codeclimate.com/github/ManageIQ/manageiq-content/test_coverage)

[![Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ManageIQ/manageiq/automate?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Build history for petrosian branch](https://buildstats.info/github/chart/ManageIQ/manageiq-content?branch=petrosian&buildCount=50&includeBuildsFromPullRequest=false&showstats=false)](https://github.com/ManageIQ/manageiq-content/actions?query=branch%3Amaster)

Content plugin for ManageIQ.

## Notes on content

At present, this repo contains only the ManageIQ automate domain.  In the future,
more content will be extracted from the ManageIQ/manageiq repo such as dialogs,
reports, and policies.

## Development

See the section on plugins in the [ManageIQ Developer Setup](http://manageiq.org/docs/guides/developer_setup/plugins)

For quick local setup run `bin/setup`, which will clone the core ManageIQ repository under the *spec* directory and setup necessary config files. If you have already cloned it, you can run `bin/update` to bring the core ManageIQ code up to date.

## License

The gem is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

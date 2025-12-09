# ManageIQ::Content

[![CI](https://github.com/ManageIQ/manageiq-content/actions/workflows/ci.yaml/badge.svg?branch=master)](https://github.com/ManageIQ/manageiq-content/actions/workflows/ci.yaml)

[![Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ManageIQ/manageiq/automate?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

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

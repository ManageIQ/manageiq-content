# ManageIQ Content

[![Gem Version](https://badge.fury.io/rb/manageiq-content.svg)](http://badge.fury.io/rb/manageiq-content)
[![Build Status](https://travis-ci.org/ManageIQ/manageiq-content.svg)](https://travis-ci.org/ManageIQ/manageiq-content)
[![Code Climate](https://codeclimate.com/github/ManageIQ/manageiq-content.svg)](https://codeclimate.com/github/ManageIQ/manageiq-content)
[![Test Coverage](https://codeclimate.com/github/ManageIQ/manageiq-content/badges/coverage.svg)](https://codeclimate.com/github/ManageIQ/manageiq-content/coverage)
[![Dependency Status](https://gemnasium.com/ManageIQ/manageiq-content.svg)](https://gemnasium.com/ManageIQ/manageiq-content)

[![Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ManageIQ/manageiq/automate?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Default ManageIQ content.

At present, this repo contains only the ManageIQ automate domain.  In the future,
more content will be extracted from the ManageIQ/manageiq repo such as dialogs,
reports, and policies.

## Contributing

First, you will need to set up your repo for development.

1. Clone the repo.
2. Set up the ManageIQ application in the spec/manageiq directory.  This can be
   done in one of two ways.
   - Run `bin/setup`.  This command will do a shallow clone of ManageIQ into spec/manageiq,
     and also prepare any files for setup.
   - Create a symlink from spec/manageiq to a local source checkout of ManageIQ.
     This is especially useful if you will be modifying ManageIQ itself at the
     same time.
3. `bundle`
4. `bundle exec rake spec:setup`

Now you are ready to begin development.  You can run the specs with
`bundle exec rake`.

Please be sure to add specs for any new automate methods you create, and follow
the [ManageIQ development guidelines](https://github.com/ManageIQ/guides/blob/master/coding_style_and_standards.md).
Thanks for your contribution!

## Testing your own Automate Domain

It is possible to test your own ManageIQ Automate Domain methods leveraging this framework.

Individual Automate methods need to be converted to the [Class Style](https://github.com/ManageIQ/manageiq-content/issues/8), and
tests written.

1. In `content/automate/` symlink in the top of your exported Automate domain
2. In `spec/content/automate` symlink in to the top of your _spec.rb tree (which matches above)

### Embedded Method Testing & Mocking

For Automate "Methods" intended to be Embedded Methods, the ruby code, to be both available for use in
Automate, and testable here, requires additional decorations, as does the calling Automate code.

1. The Embedded Method methods are Module methods (other languages would call them "static"), that not
attached to a (ruby) Class
2. The calling Automate Method, in the `class` definition can `include` the full name of the Embedded "method"
3. The Embedded Method developer should provide required mock/stub/double factories
4. The Embedded Method developer should also provide reasonable test coverage of their Methods

   The Embedded Method _spec will need to create a concrete, if dummy, Class to test Module methods.
5. By convention, the mock/stub/double factories live in `spec/factories`, so symlink in to the top directory of
all "factories" or other helpers you have.


## License

The gem is available as open source under the terms of the [Apache License 2.0](LICENSE.txt).

# Vaporware

A thin Ruby wrapper around the AWS CloudFormation SDK.

## Installation

```bash
gem install vaporware
```

Or with Bundler:
```ruby
# Gemfile
gem "vaporware", "~> 0.0"
```

## Usage

#### In a Rake task

```ruby
require 'vaporware'

task :make_stack do
  Vaporware.new({
    stack_name: "some-stack",
    template_filename: "cf.template",
    timeout: 40, # minutes
    parameters: {
      S3Bucket: "somebucket",
      Blah: "yes"
    }
  }).apply
end
```

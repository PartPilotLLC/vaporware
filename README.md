# Vaporware

[![Build Status](https://travis-ci.org/audreyschwarz/vaporware.svg?branch=master)](https://travis-ci.org/audreyschwarz/vaporware)

A thin Ruby wrapper around the AWS CloudFormation SDK.

## Installation

```bash
gem install vaporware
```

Or with Bundler:
```ruby
# Gemfile
gem "vaporware", "~> 0.0.8"
```

## Usage

### Methods

- `#create_stack` - Creates the stack
- `#delete_stack` - Deletes the stack
- `#update_stack` - Updates the stack
- `#apply` -  Updates or creates the stack, depending on status
- `#outputs` - Gets the stack outputs

### Parameters

```ruby
Vaporware.new({
  stack_name: "the-stack-name", # default: change-me
  template_filename: "cf.template", # required
  timeout: 10, # minutes, default: 40
  on_failure: "DO_NOTHING", # default: ROLLBACK
  parameters: { # optional
    SomeKey: "some_value",
    AnotherKey: "another_value"
  },
  tags: { # optional
    tag_1: "yay",
    other_tag: "whee"
  },
  capabilities: ["SOME_CAPABILITY"], # default: CAPABILITY_IAM
  status_max_attempts: 5, # default: 720
  status_delay: 5 # default: 5
})
```

#### Using in a Rake task

```ruby
require 'vaporware'

task :make_stack do
  v = Vaporware.new({
    ...params
  })
  v.apply
  puts v.outputs
end
```

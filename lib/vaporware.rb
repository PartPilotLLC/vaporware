require 'aws-sdk'

class Vaporware
  attr_reader :client

  def initialize opts = {}
    options = {
      stack_name: "change-me",
      parameters: {},
      timeout: 40 # minutes
    }.merge opts
    fail "You must specify the template filename!" unless options[:template_filename]

    @client = Aws::CloudFormation::Client.new
    @stack_name = options[:stack_name]
    @template_body = File.read(options[:template_filename])
    @parameters = build_parameters options[:parameters]
    @timeout = options[:timeout]
  end

  def create_stack
    @client.create_stack(stack_params)
    @client.wait_until(:stack_create_complete, stack_name: @stack_name)
  end

  def update_stack
    @client.update_stack(stack_params)
    @client.wait_until(:stack_update_complete, stack_name: @stack_name)
  end

  def delete_stack
    @client.delete_stack({ stack_name: @stack_name })
    @client.wait_until(:stack_delete_complete, stack_name: @stack_name)
  end

  private

  def build_parameters parameters
    parameters.keys.reduce([]) do |acc, key|
      acc << {
        parameter_key: key,
        parameter_value: parameters[key]
      }
    end
  end

  def stack_params
    {
      stack_name: @stack_name,
      template_body: @template_body,
      parameters: @parameters,
      timeout_in_minutes: @timeout,
      capabilities: ["CAPABILITY_IAM"],
      on_failure: "ROLLBACK"
    }
  end
end

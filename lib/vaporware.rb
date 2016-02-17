require 'aws-sdk'

class Vaporware
  attr_reader :client

  def initialize opts = {}
    options = {
      stack_name: "my-wonderful-stack",
      parameters: {},
      timeout: 40, # minutes
      tags: {},
      capabilities: ["CAPABILITY_IAM"],
      on_failure: "ROLLBACK", # or: DO_NOTHING, DELETE
      status_max_attempts: 720,
      status_delay: 5
    }.merge opts
    fail "You must specify a template filename!" unless options[:template_filename]

    @client = Aws::CloudFormation::Client.new
    @stack_name = options[:stack_name]
    @template_body = File.read(options[:template_filename])
    @parameters = build_parameters options[:parameters]
    @timeout = options[:timeout]
    @tags = build_tags options[:tags]
    @capabilities = options[:capabilities]
    @on_failure = options[:on_failure]
    @status_max_attempts = options[:status_max_attempts]
    @status_delay = options[:status_delay]
  end

  def apply
    stack_exists? ? update_stack : create_stack
  end

  def create_stack
    wait_for "creation", :stack_create_complete do
      @client.create_stack(stack_create_params)
    end
  end

  def update_stack
    wait_for "update", :stack_update_complete do
      @client.update_stack(stack_update_params)
    end
  end

  def delete_stack
    wait_for "deletion", :stack_delete_complete do
      @client.delete_stack(stack_name: @stack_name)
    end
  end

  def outputs
    get_outputs.inject({}) do |acc, output|
      acc[output.output_key.to_sym] = output.output_value
      acc
    end
  end

  def printable_outputs
    output = get_outputs.reduce("") do |acc, output|
      acc << "#{output.description} (#{output.output_key}): #{output.output_value}\n"
    end
    return "Stack '#{@stack_name}' has no outputs." if output == ""
    output
  end

  def validate!
    @client.validate_template template_body: @template_body
  end

  private

  # private
  def get_outputs
    @client.describe_stacks(stack_name: @stack_name).stacks.first.outputs
  end

  # private
  def build_parameters parameters
    parameters.keys.reduce([]) do |acc, key|
      acc << {
        parameter_key: key.to_s,
        parameter_value: parameters[key]
      }
    end
  end

  # private
  def build_tags tags
    tags.keys.reduce([]) do |acc, key|
      acc << {
        key: key.to_s,
        value: tags[key]
      }
    end
  end

  # private
  def stack_create_params
    {
      stack_name: @stack_name,
      template_body: @template_body,
      parameters: @parameters,
      timeout_in_minutes: @timeout,
      capabilities: @capabilities,
      on_failure: @on_failure,
      tags: @tags
    }
  end

  # private
  def stack_update_params
    {
      stack_name: @stack_name,
      template_body: @template_body,
      parameters: @parameters,
      capabilities: @capabilities
    }
  end

  # private
  def stack_exists?
    begin
      @client.describe_stacks(stack_name: @stack_name)
    rescue Aws::CloudFormation::Errors::ValidationError => e
      return false
    end
    true
  end

  # private
  def stack_events
    events = []
    begin
      events = @client.describe_stack_events(stack_name: @stack_name).stack_events
    rescue Aws::CloudFormation::Errors::ValidationError
    end
    events
  end

  # private
  def new_stack_events
    new_events = stack_events[0..@old_events]
    return [] if new_events.size == 0
    @old_events = @old_events - new_events.size
    new_events.reverse
  end

  # private
  def format_events events
    return nil if events.size == 0
    events.reduce("") do |acc, event|
      acc << "[#{event.timestamp}] #{event.logical_resource_id} (#{event.resource_type}): #{event.resource_status}\n"
    end
  end

  # private
  def wait_for goal, event_type
    @old_events = -1
    new_stack_events
    puts "Waiting for stack #{goal}..."
    yield
    @client.wait_until(event_type, stack_name: @stack_name) do |w|
      w.max_attempts = @status_max_attempts
      w.delay = @status_delay
      w.before_wait do
        events = format_events new_stack_events
        puts events if events
      end
    end
    puts format_events new_stack_events
    puts "Stack #{goal} complete!"
  end
end

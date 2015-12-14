require 'aws-sdk'

class Vaporware
  attr_reader :client

  def initialize opts = {}
    options = {
      stack_name: "change-me",
      parameters: {},
      timeout: 40 # minutes
    }.merge opts
    fail "You must specify a template filename!" unless options[:template_filename]

    @client = Aws::CloudFormation::Client.new
    @stack_name = options[:stack_name]
    @template_body = File.read(options[:template_filename])
    @parameters = build_parameters options[:parameters]
    @timeout = options[:timeout]
  end

  def apply
    stack_exists? ? update_stack : create_stack
  end

  def create_stack
    with_progress "creation" do
      @client.create_stack(stack_params)
      @client.wait_until(:stack_create_complete, stack_name: @stack_name)
    end
  end

  def update_stack
    with_progress "update" do
      @client.update_stack(stack_params)
      @client.wait_until(:stack_update_complete, stack_name: @stack_name)
    end
  end

  def delete_stack
    with_progress "deletion" do
      @client.delete_stack({ stack_name: @stack_name })
      @client.wait_until(:stack_delete_complete, stack_name: @stack_name)
    end
  end

  private

  def build_parameters parameters
    parameters.keys.reduce([]) do |acc, key|
      acc << {
        parameter_key: key.to_s,
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

  def stack_exists?
    begin
      @client.describe_stacks(stack_name: @stack_name)
    rescue Aws::CloudFormation::Errors::ValidationError => e
      return false
    end
    true
  end

  def stack_events
    events = []
    begin
      events = @client.describe_stack_events(stack_name: @stack_name).stack_events
    rescue Aws::CloudFormation::Errors::ValidationError
    end
    events
  end

  def new_stack_events
    new_events = stack_events[0..@old_events]
    return [] if new_events.size == 0
    @old_events = @old_events - new_events.size
    new_events.reverse
  end

  def with_progress goal
    @old_events = -1
    new_stack_events
    progress_thread = Thread.new do
      loop do
        puts "Waiting for stack #{goal}..."
        sleep 5
        new_events = new_stack_events
        new_events.each do |event|
          puts "[#{event.timestamp}] #{event.logical_resource_id} (#{event.resource_type}): #{event.resource_status}"
        end
      end
    end
    yield
    progress_thread.exit
    puts "Stack #{goal} complete!"
  end
end

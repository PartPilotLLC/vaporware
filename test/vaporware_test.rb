require 'minitest/autorun'
require 'minitest/around/spec'
require './lib/vaporware'

def stack_create_params
  {
    stack_name: "some-stack",
    template_body: "blah",
    parameters: [
      {
        parameter_key: "a",
        parameter_value: "b"
      },
      {
        parameter_key: "c",
        parameter_value: "d"
      }
    ],
    timeout_in_minutes: 10,
    capabilities: ["CAPABILITY_IAM"],
    on_failure: "DO_NOTHING",
    tags: [
      {
        key: "e",
        value: "f"
      }
    ]
  }
end

def stack_update_params
  {
    stack_name: "some-stack",
    template_body: "blah",
    parameters: [
      {
        parameter_key: "a",
        parameter_value: "b"
      },
      {
        parameter_key: "c",
        parameter_value: "d"
      }
    ],
    capabilities: ["CAPABILITY_IAM"]
  }
end

describe Vaporware do
  around do |test|
    File.stub :read, ->(f) { 'blah' } do
      test.call
    end
  end

  it "raises an exception when no template_filename is provided" do
    raised = false
    begin
      Vaporware.new
    rescue RuntimeError => e
      raised = true
    end

    raised.must_equal true
  end

  describe "#create_stack" do
    it "calls the client with an acceptable set of options" do
      mock = MiniTest::Mock.new
      mock.expect :create_stack, nil, [stack_create_params]
      mock.expect :wait_until, nil, [:stack_create_complete, { stack_name: "some-stack" }]
      2.times { mock.expect :stack_events, [] }
      2.times { mock.expect :describe_stack_events, mock, [{ stack_name: "some-stack" }] }

      Aws::CloudFormation::Client.stub(:new, ->() { mock }) do
        Vaporware.new({
          stack_name: "some-stack",
          template_filename: "doesn'tmatter",
          timeout: 10,
          parameters: {
            a: "b",
            c: "d"
          },
          tags: {
            e: "f"
          },
          on_failure: "DO_NOTHING"
        }).create_stack
      end
      mock.verify
    end
  end

  describe "#update_stack" do
    it "calls the client with an acceptable set of options" do
      mock = MiniTest::Mock.new
      mock.expect :update_stack, nil, [stack_update_params]
      mock.expect :wait_until, nil, [:stack_update_complete, { stack_name: "some-stack" }]
      2.times { mock.expect :stack_events, [] }
      2.times { mock.expect :describe_stack_events, mock, [{ stack_name: "some-stack" }] }

      Aws::CloudFormation::Client.stub(:new, ->() { mock }) do
        Vaporware.new({
          stack_name: "some-stack",
          template_filename: "doesn'tmatter",
          timeout: 10,
          parameters: {
            "a" => "b",
            "c" => "d"
          },
          tags: {
            e: "f"
          },
          on_failure: "DO_NOTHING"
        }).update_stack
      end
      mock.verify
    end
  end

  describe "#delete_stack" do
    it "calls the client with the stack name" do
      mock = MiniTest::Mock.new
      mock.expect :delete_stack, nil, [{ stack_name: "some-stack" }]
      mock.expect :wait_until, nil, [:stack_delete_complete, { stack_name: "some-stack" }]
      2.times { mock.expect :stack_events, [] }
      2.times { mock.expect :describe_stack_events, mock, [{ stack_name: "some-stack" }] }

      Aws::CloudFormation::Client.stub(:new, ->() { mock }) do
        Vaporware.new({
          stack_name: "some-stack",
          template_filename: "doesn'tmatter"
        }).delete_stack
      end
      mock.verify
    end
  end

  describe "#apply" do
    it "checks stack existence by calling client#describe_stacks" do
      mock = MiniTest::Mock.new
      mock.expect :describe_stacks, nil, [{ stack_name: "my-wonderful-stack"}]

      Aws::CloudFormation::Client.stub(:new, ->() { mock }) do
        v = Vaporware.new template_filename: "doesn'tmatter"
        v.stub(:update_stack, nil) do
          v.apply
        end
      end
      mock.verify
    end

    it "updates the stack if the stack exists" do
      v= Vaporware.new template_filename: "doesn'tmatter"
      v.stub(:stack_exists?, true) do
        v.stub(:update_stack, nil) do
          v.apply
        end
      end
    end

    it "creates the stack if the stack doesn't exist" do
      v= Vaporware.new template_filename: "doesn'tmatter"
      v.stub(:stack_exists?, false) do
        v.stub(:create_stack, nil) do
          v.apply
        end
      end
    end
  end

  describe "#printable_outputs" do
    it "returns a message if stack has no outputs" do
      v= Vaporware.new template_filename: "doesn'tmatter"
      v.stub :get_outputs, [] do
        v.printable_outputs.must_equal "Stack 'my-wonderful-stack' has no outputs."
      end
    end

    it "returns formatted outputs if stack has outputs" do
      mock = MiniTest::Mock.new
      mock.expect :description, "blah"
      mock.expect :output_key, "key"
      mock.expect :output_value, "value"
      v= Vaporware.new template_filename: "doesn'tmatter"
      v.stub :get_outputs, [mock] do
        v.printable_outputs.must_equal "blah (key): value\n"
      end
    end
  end

  describe "#outputs" do
    it "returns the raw outputs, with keys symbolized" do
      fake_output = Struct.new("FakeOutput", :output_key, :output_value).new
      fake_output.output_key = "something"
      fake_output.output_value = "outputs here"
      v= Vaporware.new template_filename: "doesn'tmatter"
      v.stub :get_outputs, [fake_output] do
        v.outputs.must_equal something: "outputs here"
      end
    end
  end

  describe "#validate!" do
    it "validates the template" do
      v= Vaporware.new template_filename: "doesn'tmatter"
      v.client.stub :validate_template, ->(_) { true } do
        v.validate!.must_equal true
      end
    end
  end
end

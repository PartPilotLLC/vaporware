require 'minitest/autorun'
require './lib/vaporware'

def stack_params
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
    on_failure: "ROLLBACK"
  }
end

describe Vaporware do
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
      mock.expect :create_stack, nil, [stack_params]
      mock.expect :wait_until, nil, [:stack_create_complete, { stack_name: "some-stack" }]

      File.stub :read, ->(f) { 'blah' } do
        Aws::CloudFormation::Client.stub(:new, ->() { mock }) do
          Vaporware.new({
            stack_name: "some-stack",
            template_filename: "doesn'tmatter",
            timeout: 10,
            parameters: {
              "a" => "b",
              "c" => "d"
            }
          }).create_stack
        end
      end
      mock.verify
    end
  end

  describe "#update_stack" do
    it "calls the client with an acceptable set of options" do
      mock = MiniTest::Mock.new
      mock.expect :update_stack, nil, [stack_params]
      mock.expect :wait_until, nil, [:stack_update_complete, { stack_name: "some-stack" }]

      File.stub :read, ->(f) { 'blah' } do
        Aws::CloudFormation::Client.stub(:new, ->() { mock }) do
          Vaporware.new({
            stack_name: "some-stack",
            template_filename: "doesn'tmatter",
            timeout: 10,
            parameters: {
              "a" => "b",
              "c" => "d"
            }
          }).update_stack
        end
      end
      mock.verify
    end
  end

  describe "#delete_stack" do
    it "calls the client with the stack name" do
      mock = MiniTest::Mock.new
      mock.expect :delete_stack, nil, [{ stack_name: "some-stack" }]
      mock.expect :wait_until, nil, [:stack_delete_complete, { stack_name: "some-stack" }]

      File.stub :read, ->(f) { nil } do
        Aws::CloudFormation::Client.stub(:new, ->() { mock }) do
          Vaporware.new({
            stack_name: "some-stack",
            template_filename: "doesn'tmatter"
          }).delete_stack
        end
      end
      mock.verify
    end
  end
end

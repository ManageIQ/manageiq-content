require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/System/CommonMethods/Utils.class/__methods__/log_object.rb')

describe ManageIQ::Automate::System::Request::Inspectme do
  let(:root) do
    Spec::Support::MiqAeMockObject.new(
      'current' => current_object
    )
  end
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:current_object) { Spec::Support::MiqAeMockObject.new('a' => 1, 'b' => 2) }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root).tap do |service|
      current_object.parent = root
      service.current_object = current_object
    end
  end

  it '.root' do
    allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:root).with(@handle).and_return("blah")
    allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_ar_objects).with("Inspectme", @handle).and_return("blah")
  end
end

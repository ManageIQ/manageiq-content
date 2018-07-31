require_domain_file
describe ManageIQ::Automate::System::CommonMethods::Utils::LogObject do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:ems) { FactoryGirl.create(:ext_management_system) }

  let(:root) do
    Spec::Support::MiqAeMockObject.new(
      'dialog_provider' => ems.id.to_s,
      'user'            => svc_model_user,
      'current'         => current_object
    )
  end

  let(:current_object) { Spec::Support::MiqAeMockObject.new('a' => 1, 'b' => 2) }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root).tap do |service|
      current_object.parent = root
      service.current_object = current_object
    end
  end

  let(:log_header_footer_count) { 2 }
  let(:root_attr_count) { 3 }
  let(:current_attr_count) { 2 }

  it '.root' do
    expect(ae_service).to receive(:log).with('info', /Listing root Attributes/).exactly(log_header_footer_count).times
    expect(ae_service).to receive(:log).with('info', /   Attribute/).exactly(root_attr_count).times

    # described_class.root(ae_service)
    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.root(ae_service)
  end

  it '.current' do
    expect(ae_service).to receive(:log).with('info', /Listing current Attributes/).exactly(log_header_footer_count).times
    expect(ae_service).to receive(:log).with('info', /   Attribute/).exactly(current_attr_count).times

    # described_class.current(ae_service)
    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.current(ae_service)
  end

  it '.log' do
    expect(ae_service).to receive(:log).with('info', /Listing My Object Attributes/).exactly(log_header_footer_count).times
    expect(ae_service).to receive(:log).with('info', /   Attribute/).exactly(root_attr_count).times

    # described_class.log(ae_service, root)
    ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log(root, 'My Object', ae_service)
  end
end

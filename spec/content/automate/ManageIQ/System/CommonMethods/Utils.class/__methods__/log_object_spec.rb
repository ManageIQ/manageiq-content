require_domain_file
describe ManageIQ::Automate::System::CommonMethods::Utils::LogObject do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:ems) { FactoryGirl.create(:ext_management_system) }
  let(:ar_object) { svc_model_user }

  let(:root) do
    Spec::Support::MiqAeMockObject.new(
      'dialog_provider' => ems.id.to_s,
      'ar_object'       => ar_object,
      'current'         => current_object
    )
  end

  let(:small_environment_zone) { FactoryGirl.create(:small_environment) }
  let(:parent_classification) { FactoryGirl.create(:classification, :description => "Environment", :name => "environment", :read_only => false) }
  let(:classification)        { FactoryGirl.create(:classification, :name => "prod", :description => "Production", :parent => parent_classification, :read_only => true) }
  let(:vm1) do
    small_environment_zone

    Vm.first
  end

  let(:svc_model_vm1) { MiqAeMethodService::MiqAeServiceVm.find(vm1.id) }

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

  context 'log ar_objects' do
    let(:ar_object) { svc_model_vm1 }

    it 'with default VMDB Object string' do
      classification.assign_entry_to(vm1)
      expect(ae_service).to receive(:log).with('info', /log_ar_objects/).exactly(1).times
      expect(ae_service).to receive(:log).with('info', /key:/).exactly(1).times

      expect(ae_service).to receive(:log).with('info', / VMDB Object Begin Attributes/).exactly(1).times
      expect(ae_service).to receive(:log).with('info', /  Attribute:/).exactly(vm1.attributes.count).times
      expect(ae_service).to receive(:log).with('info', / VMDB Object End Attributes/).exactly(1).times

      expect(ae_service).to receive(:log).with('info', / VMDB Object Begin Associations/).exactly(1).times
      expect(ae_service).to receive(:log).with('info', /   Associations -/).exactly(MiqAeMethodService::MiqAeServiceVm.associations.count).times
      expect(ae_service).to receive(:log).with('info', / VMDB Object End Associations/).exactly(1).times

      expect(ae_service).to receive(:log).with('info', / VMDB Object Begin Tags /).exactly(1).times
      expect(ae_service).to receive(:log).with('info', /    Category:/).exactly(vm1.tags.count).times
      expect(ae_service).to receive(:log).with('info', / VMDB Object End Tags/).exactly(1).times
      # described_class.log_ar_objects('VMDB Object', ae_service)
      ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_ar_objects('VMDB Object', ae_service)
    end
  end

  context 'log ar_objects' do
    let(:ar_object) { svc_model_vm1 }

    it ' with My Database Object string' do
      classification.assign_entry_to(vm1)
      expect(ae_service).to receive(:log).with('info', /log_ar_objects/).exactly(1).times
      expect(ae_service).to receive(:log).with('info', /key:/).exactly(1).times

      expect(ae_service).to receive(:log).with('info', / My Database Object Begin Attributes/).exactly(1).times
      expect(ae_service).to receive(:log).with('info', /  Attribute:/).exactly(vm1.attributes.count).times
      expect(ae_service).to receive(:log).with('info', / My Database Object End Attributes/).exactly(1).times

      expect(ae_service).to receive(:log).with('info', / My Database Object Begin Associations/).exactly(1).times
      expect(ae_service).to receive(:log).with('info', /   Associations -/).exactly(MiqAeMethodService::MiqAeServiceVm.associations.count).times
      expect(ae_service).to receive(:log).with('info', / My Database Object End Associations/).exactly(1).times

      expect(ae_service).to receive(:log).with('info', / My Database Object Begin Tags /).exactly(1).times
      expect(ae_service).to receive(:log).with('info', /    Category:/).exactly(vm1.tags.count).times
      expect(ae_service).to receive(:log).with('info', / My Database Object End Tags/).exactly(1).times
      # described_class.log_ar_objects('My Database Object', ae_service)
      ManageIQ::Automate::System::CommonMethods::Utils::LogObject.log_ar_objects('My Database Object', ae_service)
    end
  end
end

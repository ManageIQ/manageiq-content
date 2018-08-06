require_domain_file

describe ManageIQ::Automate::System::Notification::Email::MiqProvisionCustomizeBody do
  let(:vm_url) { "https://www.manageiq.org/show/vm/1" }
  let(:svc_miq_provision) { MiqAeMethodService::MiqAeServiceMiqProvision.find(miq_provision.id) }
  let(:root_hash) do
    {
      'miq_provision' => svc_miq_provision,
      'user'          => MiqAeMethodService::MiqAeServiceUser.find(user.id),
      'miq_server'    => MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id)
    }
  end

  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new('to' => 'touser@example.com', 'from' => 'fromuser@example.com',
        'signature' => 'Virtualization Infrastructure Team',
        'customize' => 'miq_provision_complete',
        'subject' => 'Request ID ')
      current_object.parent = root_object
      service.object = current_object
    end
  end

  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:svc_model_miq_server) { MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id) }
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:svc_vm) { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }
  let(:vm) do
    FactoryGirl.create(:vm_vmware,
                       :evm_owner       => user,
                       :retires_on      => Time.zone.now + 30.days,
                       :retirement_warn => Time.zone.now + 7.days,
                       :ems_id          => ems.id)
  end

  let(:ems) { FactoryGirl.create(:ems_vmware_with_authentication) }
  let(:vm_template) { FactoryGirl.create(:template_vmware, :ext_management_system => ems) }
  let(:options) { {:src_vm_id => [vm_template.id, vm_template.name], :pass => 1} }
  let(:miq_provision_request) do
    FactoryGirl.create(:miq_provision_request,
                       :provision_type => 'template',
                       :state => 'pending', :status => 'Ok',
                       :src_vm_id => vm_template.id,
                       :requester => user)
  end
  let(:miq_provision) do
    FactoryGirl.create(:miq_provision_vmware, :provision_type => 'template',
                       :state => 'pending', :status => 'Ok',
                       :miq_request => miq_provision_request,
                       :vm => vm,
                       :options => options, :userid => user.userid)
  end

  it "Check object values" do
    allow(svc_miq_provision).to receive(:vm).and_return(svc_vm)
    allow(svc_vm).to receive(:show_url).and_return(vm_url)
    described_class.new(ae_service).main

    expect(ae_service.object.attributes).to include(
      'to'        => 'touser@example.com',
      'signature' => 'Virtualization Infrastructure Team',
      'from'      => 'fromuser@example.com',
      'customize' => 'miq_provision_complete',
      'subject'   => 'Request ID '
    )
  end

  it "Check body values" do
    allow(svc_miq_provision).to receive(:vm).and_return(svc_vm)
    allow(svc_vm).to receive(:show_url).and_return(vm_url)
    described_class.new(ae_service).main

    expect(ae_service.object['body']).to include(vm_url)

    # these two are conditional, retirement information must be specified
    expect(ae_service.object['body']).to include('This VM will automatically be retired on')
    expect(ae_service.object['body']).to include('You will receive a warning')
  end

  it "No Retirement will be retired in Body" do
    vm.update_attributes!(:retires_on => nil)
    allow(svc_miq_provision).to receive(:vm).and_return(svc_vm)
    allow(svc_vm).to receive(:show_url).and_return(vm_url)

    described_class.new(ae_service).main
    expect(ae_service.object['body']).not_to include('This VM will automatically be retired on')
  end

  it "No Retirement warning in Body" do
    vm.update_attributes!(:retirement_warn => nil)
    allow(svc_miq_provision).to receive(:vm).and_return(svc_vm)
    allow(svc_vm).to receive(:show_url).and_return(vm_url)

    described_class.new(ae_service).main
    expect(ae_service.object['body']).not_to include('You will receive a warning')
  end

  context "with no vm" do
    let(:vm) { nil }

    it "raises the ERROR - VM not found exception" do
      expect { described_class.new(ae_service).main }.to raise_error(
        'ERROR - VM not found'
      )
    end
  end

  context "with no objects" do
    let(:root_hash) { {} }

    it "raises the ERROR - miq_provision object not passed in exception" do
      expect { described_class.new(ae_service).main }.to raise_error(
        'ERROR - miq_provision object not passed in'
      )
    end
  end
end

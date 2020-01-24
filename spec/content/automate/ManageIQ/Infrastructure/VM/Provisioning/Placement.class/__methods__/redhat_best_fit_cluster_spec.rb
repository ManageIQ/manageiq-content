require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Provisioning::Placement::RedhatBestFitCluster do
  let(:datacenter)  { FactoryBot.create(:datacenter, :ext_management_system => ems) }
  let(:ems)         { FactoryBot.create(:ems_redhat_with_authentication) }
  let(:ems_cluster) { FactoryBot.create(:ems_cluster, :ext_management_system => ems) }
  let(:miq_provision) do
    FactoryBot.create(:miq_provision_redhat,
                      :options      => {:src_vm_id => vm_template.id, :placement_auto => [true, 1]},
                      :userid       => user.userid,
                      :source       => vm_template,
                      :request_type => 'clone_to_vm',
                      :state        => 'active',
                      :status       => 'Ok')
  end
  let(:user)        { FactoryBot.create(:user_with_group, :settings => {:display => {:timezone => 'UTC'}}) }
  let(:vm_template) { FactoryBot.create(:template_redhat, :ext_management_system => ems) }

  let(:svc_miq_provision) { MiqAeMethodService::MiqAeServiceMiqProvision.find(miq_provision.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new(:miq_provision => svc_miq_provision) }
  let(:ae_service)  { Spec::Support::MiqAeMockService.new(root_object) }

  it 'Check log messages with No errors' do
    expect(ae_service).to receive(:log).with('info', "vm=[#{vm_template.name}]")
    expect(ae_service).to receive(:log).with('info', "Selected Cluster: [nil]")
    expect(ae_service).to receive(:log).with('info', "vm=[#{vm_template.name}] cluster=[]")
    described_class.new(ae_service).main
  end

  it 'Raise error when source vm is not specified' do
    miq_provision.update(:source => nil)
    expect { described_class.new(ae_service).main }.to raise_error('VM not specified')
  end

  context "Raise error" do
    let(:svc_miq_provision) { nil }
    it 'when miq_provision is not specified' do
      expect { described_class.new(ae_service).main }.to raise_error('miq_provision not specified')
    end
  end
end

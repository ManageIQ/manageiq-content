require_domain_file

describe ManageIQ::Automate::Cloud::VM::Provisioning::StateMachines::ProvisionRequestApproval::ValidateRequest do
  let(:ems)              { FactoryGirl.create(:ems_cloud) }
  let(:vm_template)      { FactoryGirl.create(:template, :ext_management_system => ems) }
  let(:root_hash)        { { 'miq_request' => MiqAeMethodService::MiqAeServiceMiqProvisionRequest.find(prov_request.id) } }
  let(:root_object)      { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:flavor)           { FactoryGirl.create(:flavor, :ext_management_system => ems, :cpus => 2, :memory => 4.gigabytes) }
  let(:options)          { { :instance_type => flavor.id, :number_of_vms => 2, :retirement => 3.days.seconds } }
  let(:error_msg_memory) { 'Request was not auto-approved for the following reasons: (Requested Memory 8 GB limit is 2147483648) ' }
  let(:error_msg_time)   { 'Request was not auto-approved for the following reasons: (Requested Retirement Days 3 limit is 1) ' }
  let(:error_msg_cpus)   { 'Request was not auto-approved for the following reasons: (Requested CPUs 4 limit is 1) ' }
  let(:error_msg_vms)    { 'Request was not auto-approved for the following reasons: (Requested VMs 2 limit is 1) ' }

  let(:prov_request) do
    FactoryGirl.create(:miq_provision_request,
                       :provision_type => 'template',
                       :state => 'pending', :status => 'Ok',
                       :src_vm_id => vm_template.id,
                       :options   => options)
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      current_object['max_cpus'] = 4
      current_object['max_memory'] = 8.gigabytes
      service.object = current_object
    end
  end

  def check_error_msg(msg)
    expect(ae_service.root["ae_result"]).to eq("error")
    expect(ae_service.object["reason"]).to eq(msg)
  end

  context 'limits validation from tags' do
    it "exceeds cpus" do
      vm_template.tags << FactoryGirl.create(:tag, :name => '/managed/prov_max_cpu/1')
      described_class.new(ae_service).main
      check_error_msg(error_msg_cpus)
    end

    it "exceeds memory" do
      vm_template.tags << FactoryGirl.create(:tag, :name => "/managed/prov_max_memory/#{2.gigabytes}")
      described_class.new(ae_service).main
      check_error_msg(error_msg_memory)
    end

    it "exceed vms" do
      vm_template.tags << FactoryGirl.create(:tag, :name => '/managed/prov_max_vm/1')
      described_class.new(ae_service).main
      check_error_msg(error_msg_vms)
    end

    it "exceeds retirement" do
      vm_template.tags << FactoryGirl.create(:tag, :name => '/managed/prov_max_retirement_days/1')
      described_class.new(ae_service).main
      check_error_msg(error_msg_time)
    end
  end

  context 'limits validation from model' do
    it "exceeds cpu limit" do
      ae_service.object['max_cpus'] = 1
      described_class.new(ae_service).main
      check_error_msg(error_msg_cpus)
    end

    it "exceeds memory limit" do
      ae_service.object['max_memory'] = 2.gigabytes
      described_class.new(ae_service).main
      check_error_msg(error_msg_memory)
    end

    it "exceed vms" do
      ae_service.object['max_vms'] = 1
      described_class.new(ae_service).main
      check_error_msg(error_msg_vms)
    end

    it "exceeds retirement" do
      ae_service.object['max_retirement_days'] = 1
      described_class.new(ae_service).main
      check_error_msg(error_msg_time)
    end
  end

  it "aprroves request" do
    described_class.new(ae_service).main
    expect(ae_service.root["ae_result"]).to be_nil
  end
end

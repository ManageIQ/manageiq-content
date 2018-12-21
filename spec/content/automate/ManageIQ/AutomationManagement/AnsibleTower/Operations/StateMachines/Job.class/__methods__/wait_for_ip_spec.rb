require_domain_file

describe ManageIQ::Automate::AutomationManagement::AnsibleTower::Operations::StateMachines::Job::WaitForIP do
  let(:user) { FactoryBot.create(:user_with_group) }
  let(:vm) { FactoryBot.create(:vm) }
  let(:klass) { MiqAeMethodService::MiqAeServiceVm }
  let(:svc_vm) { klass.find(vm.id) }
  let(:ip_addr) { ['1.1.1.1'] }
  let(:svc_job) { job_class.find(job.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new }
  let(:service) { Spec::Support::MiqAeMockService.new(root_object) }

  it "#main - ok" do
    root_object['vm'] = svc_vm
    allow_any_instance_of(klass).to receive(:ipaddresses).with(no_args).and_return(ip_addr)
    allow_any_instance_of(klass).to receive(:refresh).with(no_args).and_return(nil)

    described_class.new(service).main

    expect(root_object['ae_result']).to eq('ok')
  end

  it "#main - retry" do
    root_object['vm'] = svc_vm
    allow_any_instance_of(klass).to receive(:ipaddresses).with(no_args).and_return([])
    allow_any_instance_of(klass).to receive(:refresh).with(no_args).and_return(nil)

    described_class.new(service).main

    expect(root_object['ae_result']).to eq('retry')
  end
end

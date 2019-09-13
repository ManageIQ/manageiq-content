require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/System/CommonMethods/Utils.class/__methods__/log_object.rb')

describe ManageIQ::Automate::System::Request::VmRetireExtend do
  let(:user) { FactoryBot.create(:user_with_email_and_group) }
  let(:zone) { FactoryBot.create(:zone) }
  let(:ems) { FactoryBot.create(:ems_microsoft, :zone => zone, :tenant => Tenant.root_tenant) }
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:vm) do
    FactoryBot.create(:vm_microsoft,
                       :raw_power_state => "PowerOff",
                       :retires_on      => Time.zone.now,
                       :evm_owner       => user,
                       :ems_id          => ems.id)
  end

  let(:root_hash) do
    { 'vm' => vm }
  end

  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(root_hash)
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  before do
    allow(ae_service).to receive(:execute)
  end

  context "when vm_retire_extend_days is 14" do
    it "returns a new retirement date " do
      future_retires_on = Time.zone.now + 14.days
      described_class.new(ae_service).main
      expect(vm.retires_on.day).to eq(future_retires_on.day)
    end
  end

  context "Log_and_raise" do
    let(:vm) { nil }
    it "ERROR - vm object not passed in" do
      allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/ERROR - vm object not passed in/, ae_service).and_raise(RuntimeError)
      expect { described_class.new(ae_service).main }.to raise_error(RuntimeError)
    end
  end

  context "Log_and_raise" do
    it "ERROR - VM has no retirement date" do
      vm.update(:retires_on => nil)
      allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/ERROR - VM #{vm.name} has no retirement date - extension bypassed. No Action taken/, ae_service).and_raise(RuntimeError)
      expect { described_class.new(ae_service).main }.to raise_error(RuntimeError)
    end
  end

  context "Log_and_raise" do
    it "ERROR - VM has no retirement date" do
      vm.update(:retired => true)
      allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/ERROR - VM #{vm.name} is already retired - extension bypassed. No Action taken/, ae_service).and_raise(RuntimeError)
      expect { described_class.new(ae_service).main }.to raise_error(RuntimeError)
    end
  end
end

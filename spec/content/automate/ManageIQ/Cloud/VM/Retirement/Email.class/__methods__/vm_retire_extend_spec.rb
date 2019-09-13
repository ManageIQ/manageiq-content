require_domain_file

describe ManageIQ::Automate::Cloud::VM::Retirement::Email::VmRetireExtend do
  let(:user) { FactoryBot.create(:user_with_email_and_group) }
  let(:zone) { FactoryBot.create(:zone) }
  let(:ems) { FactoryBot.create(:ems_amazon, :zone => zone, :tenant => Tenant.root_tenant) }
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:vm) do
    FactoryBot.create(:vm_amazon,
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

  context "when vm_retire_extend_days is 7" do
    it "Calls execute to send_email" do
      ae_service.object[:vm_retire_extend_days] = 7
      ae_service.object[:from_email_address] = "evmadmin@example.com"
      expect(ae_service).to receive(:execute).once
      described_class.new(ae_service).main
    end

    it "returns a new retirement date " do
      ae_service.object[:vm_retire_extend_days] = 7
      future_retires_on = Time.zone.now + 7.days
      described_class.new(ae_service).main
      expect(vm.retires_on.day).to eq(future_retires_on.day)
    end
  end

  context "when vm_retire_extend_days is nil" do
    it "raises error message" do
      ae_service.object[:vm_retire_extend_days] = nil
      errormsg = 'ERROR - vm_retire_extend_days not found!'
      expect { described_class.new(ae_service).main }.to raise_error(errormsg)
    end
  end

  context "when vm retires_on is nil" do
    it "does not update retires_on date" do
      ae_service.object[:vm_retire_extend_days] = 7
      vm.update(:retires_on => nil)
      expect(ae_service).not_to receive(:execute)
      described_class.new(ae_service).main
      expect(ae_service.root['ae_result']).to eq(nil)
    end
  end

  context "when vm retired is true " do
    it "does not update retires_on date" do
      ae_service.object[:vm_retire_extend_days] = 7
      vm.update(:retired => true)
      expect(ae_service).not_to receive(:execute)
      described_class.new(ae_service).main
      expect(ae_service.root['ae_result']).to eq(nil)
    end
  end

  context "when there is no vm" do
    let(:root_hash) { {} }
    let(:svc_model_service) { nil }
    let(:vm) { nil }
    it "raises error message" do
      errormsg = 'ERROR - vm object not passed in'
      expect { described_class.new(ae_service).main }.to raise_error(errormsg)
    end
  end
end

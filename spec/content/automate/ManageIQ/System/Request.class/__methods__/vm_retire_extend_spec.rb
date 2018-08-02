require_domain_file

describe ManageIQ::Automate::System::Request::VmRetireExtend do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:zone) { FactoryGirl.create(:zone) }
  let(:ems) { FactoryGirl.create(:ems_microsoft, :zone => zone, :tenant => Tenant.root_tenant) }
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:vm) do
    FactoryGirl.create(:vm_microsoft,
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

  context "when vm retires_on is nil" do
    it "does not update retires_on date" do
      vm.update_attributes(:retires_on => nil)
      errormsg = "ERROR - VM #{vm} has no retirement date - extension bypassed. No Action taken"
      expect { described_class.new(ae_service).main }.to raise_error(errormsg)
    end
  end

  context "when vm retired is true " do
    it "does not update retires_on date" do
      vm.update_attributes(:retired => true)
      errormsg = "ERROR - VM #{vm} is already retired - extension bypassed. No Action taken"
      expect { described_class.new(ae_service).main }.to raise_error(errormsg)
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

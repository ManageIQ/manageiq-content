describe "Auto Approval Request Validation" do
  include Spec::Support::QuotaHelper
  let(:ws) { MiqAeEngine.instantiate("/System/Request/Call_Method?#{method}&#{args}&#{@value}", @user) }
  let(:method) do
    "namespace=/ManageIQ/Cloud/VM/Provisioning/StateMachines&class=ProvisionRequestApproval&method=validate_request"
  end
  let(:args) { "status=fred&MiqProvisionRequest::miq_request=#{@miq_provision_request.id}" }

  let(:large_flavor) do
    FactoryGirl.create(:flavor_google, :ems_id => @ems.id, :cloud_subnet_required => false,
                                             :cpus => 4, :cpu_cores => 1, :memory => 2_048_000)
  end
  before do
    setup_model("google")
    add_call_method
  end

  it "exceed cpus" do
    @value = "max_cpus=3"
    msg = "Request was not auto-approved for the following reasons: (Requested CPUs 4 limit is 3) "
    expect(ws.root["ae_result"]).to eq("error")
    expect(ws.root["reason"]).to eq(msg)
  end

  it "not exceed cpus" do
    @value = "max_cpus=4"
    expect(ws.root["ae_result"]).to be_nil
  end

  it "exceed memory" do
    @miq_provision_request.update_attributes(:options => @miq_provision_request.options.merge(:instance_type => [large_flavor.id, large_flavor.name]))
    @value = "max_memory=1"
    msg = "Request was not auto-approved for the following reasons: (Requested Memory 1.95 MB limit is 1 MB) "
    expect(ws.root["reason"]).to eq(msg)
    expect(ws.root["ae_result"]).to eq("error")
  end

  it "not exceed memory" do
    @miq_provision_request.update_attributes(:options => @miq_provision_request.options.merge(:instance_type => [large_flavor.id, large_flavor.name]))
    @value = "max_memory=2"
    expect(ws.root["ae_result"]).to be_nil
  end

  it "exceed retirement" do
    @miq_provision_request.options[:retirement] = 3.days.seconds
    @miq_provision_request.save
    @value = "max_retirement_days=1"
    msg = "Request was not auto-approved for the following reasons: (Requested Retirement Days 3 limit is 1) "
    expect(ws.root["reason"]).to eq(msg)
    expect(ws.root["ae_result"]).to eq("error")
  end

  it "not exceed retirement" do
    @miq_provision_request.options[:retirement] = 1
    @miq_provision_request.save
    @value = "max_retirement_days=1"
    expect(ws.root["ae_result"]).to be_nil
  end

  it "exceed vms" do
    @miq_provision_request.options[:number_of_vms] = 2
    @miq_provision_request.save
    @value = "max_vms=1"
    msg = "Request was not auto-approved for the following reasons: (Requested VMs 2 limit is 1) "
    expect(ws.root["reason"]).to eq(msg)
    expect(ws.root["ae_result"]).to eq("error")
  end

  it "not exceed vms" do
    @miq_provision_request.options[:number_of_vms] = 1
    @miq_provision_request.save
    @value = "max_vms=1"
    expect(ws.root["ae_result"]).to be_nil
  end
end

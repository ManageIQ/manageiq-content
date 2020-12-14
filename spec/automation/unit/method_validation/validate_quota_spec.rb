describe "Quota Validation" do
  include Spec::Support::QuotaHelper

  def run_automate_method(used, requested)
    attrs = []
    attrs << "MiqRequest::miq_request=#{@miq_provision_request.id}&" \
             "quota_limit_max_yaml=#{@quota_limit_max}&" \
             "quota_limit_warn_yaml=#{@quota_limit_warn}&" \
             "quota_used_yaml=#{used}&" \
             "Tenant::quota_source=#{@tenant.id}&" \
             "quota_requested_yaml=#{requested}"
    attrs << extra_attrs if extra_attrs
    MiqAeEngine.instantiate("/ManageIQ/system/request/Call_Instance?namespace=System/CommonMethods&" \
                            "class=QuotaMethods&instance=validate_quota&#{attrs.join('&')}", @user)
  end

  let(:used) { YAML.dump(:storage => 32_768, :vms => 2, :cpu => 2, :memory => 4096) }
  let(:requested) { YAML.dump(:storage => 10_240, :vms => 1, :cpu => 1, :memory => 1024) }

  before do
    setup_model
  end

  context "Provisioning" do
    let(:msg) { err_msg }
    let(:quota_type) { :quota_max_exceeded }
    let(:quota_result) { 'error' }
    let(:extra_attrs) { nil }
    let(:quota_warn) { YAML.dump(:storage => 0, :vms => 0, :cpu => 0, :memory => 0) }
    let(:quota_max) { YAML.dump(:storage => 0, :vms => 0, :cpu => 0, :memory => 0) }

    shared_examples_for "check_quota for Provisioning" do
      it "check" do
        @quota_limit_warn = quota_warn
        @quota_limit_max = quota_max
        ws = run_automate_method(used, requested)
        expect(ws.root['ae_result']).to eq(quota_result)
        @miq_request.reload
        expect(@miq_request.options[quota_type]).to eql(err_msg)
        expect(@miq_request.message).to eql(msg)
      end
    end

    context "no quota set" do
      let(:quota_result) { 'ok' }
      let(:msg) { "VM Provisioning - Request Created" }
      let(:err_msg) { nil }

      it_behaves_like "check_quota for Provisioning"
    end

    context "failure max memory" do
      let(:quota_max) { YAML.dump(:storage => 0, :vms => 0, :cpu => 0, :memory => 4096) }
      let(:err_msg) do
        "Request exceeds maximum allowed for the following:" \
                  " (memory - Used: 4 KB plus requested: 1 KB exceeds quota: 4 KB) "
      end

      it_behaves_like "check_quota for Provisioning"
    end

    context "failure max storage" do
      let(:quota_max) { YAML.dump(:storage => 20_480, :vms => 0, :cpu => 0, :memory => 0) }
      let(:err_msg) do
        "Request exceeds maximum allowed for the following:" \
                  " (storage - Used: 32 KB plus requested: 10 KB exceeds quota: 20 KB) "
      end

      it_behaves_like "check_quota for Provisioning"
    end

    context "failure max vms" do
      let(:quota_max) { YAML.dump(:storage => 0, :vms => 2, :cpu => 0, :memory => 0) }
      let(:err_msg) do
        "Request exceeds maximum allowed for the following:" \
                  " (vms - Used: 2 plus requested: 1 exceeds quota: 2) "
      end

      it_behaves_like "check_quota for Provisioning"
    end

    context "failure max cpu" do
      let(:quota_max) { YAML.dump(:storage => 0, :vms => 0, :cpu => 2, :memory => 0) }
      let(:err_msg) do
        "Request exceeds maximum allowed for the following:" \
                  " (cpu - Used: 2 plus requested: 1 exceeds quota: 2) "
      end

      it_behaves_like "check_quota for Provisioning"
    end

    context "failure warn memory" do
      let(:quota_type) { :quota_warn_exceeded }
      let(:quota_result) { 'ok' }
      let(:quota_warn) { YAML.dump(:storage => 0, :vms => 0, :cpu => 0, :memory => 4096) }
      let(:err_msg) do
        "Request exceeds warning limits for the following:" \
                  " (memory - Used: 4 KB plus requested: 1 KB exceeds quota: 4 KB) "
      end

      it_behaves_like "check_quota for Provisioning"
    end

    context "failure warn vms" do
      let(:quota_type) { :quota_warn_exceeded }
      let(:quota_result) { 'ok' }
      let(:quota_warn) { YAML.dump(:storage => 0, :vms => 2, :cpu => 0, :memory => 0) }
      let(:err_msg) do
        "Request exceeds warning limits for the following:" \
                  " (vms - Used: 2 plus requested: 1 exceeds quota: 2) "
      end

      it_behaves_like "check_quota for Provisioning"
    end

    context "failure warn cpu" do
      let(:quota_type) { :quota_warn_exceeded }
      let(:quota_result) { 'ok' }
      let(:quota_warn) { YAML.dump(:storage => 0, :vms => 0, :cpu => 1, :memory => 0) }
      let(:err_msg) do
        "Request exceeds warning limits for the following:" \
                  " (cpu - Used: 2 plus requested: 1 exceeds quota: 1) "
      end

      it_behaves_like "check_quota for Provisioning"
    end

    context "failure warn storage" do
      let(:quota_type) { :quota_warn_exceeded }
      let(:quota_result) { 'ok' }
      let(:quota_warn) { YAML.dump(:storage => 10_240, :vms => 0, :cpu => 0, :memory => 0) }
      let(:err_msg) do
        "Request exceeds warning limits for the following:" \
                  " (storage - Used: 32 KB plus requested: 10 KB exceeds quota: 10 KB) "
      end

      it_behaves_like "check_quota for Provisioning"
    end
  end

  context "Reconfigure " do
    let(:used) { YAML.dump(:storage => 10_240, :vms => 2, :cpu => 2, :memory => 1024) }
    let(:requested) { YAML.dump(:storage => 20_480, :vms => 0, :cpu => 0, :memory => 4096) }
    let(:err_msg) { nil }
    let(:msg) { "VM Provisioning - Request Created" }
    let(:extra_attrs) { nil }
    let(:quota_result) { 'ok' }
    let(:quota_check) { nil }
    let(:quota_max) { nil }

    shared_examples_for "check_quota for Reconfigure" do
      it "check" do
        setup_model("vmware_reconfigure")
        @quota_limit_warn = YAML.dump(:storage => 0, :vms => 0, :cpu => 0, :memory => 0)
        @quota_limit_max = quota_max
        ws = run_automate_method(used, requested)
        expect(ws.root['ae_result']).to eq(quota_result)
        expect(ws.root['check_quota']).to eq(quota_check)
        @miq_request.reload
        expect(@miq_request.options[:quota_max_exceeded]).to eql(err_msg)
        expect(@miq_request.message).to eql(msg)
      end
    end

    context "false " do
      it_behaves_like "check_quota for Reconfigure"
    end

    context "true " do
      let(:quota_check) { 'true' }
      let(:extra_attrs) { "check_quota=true" }

      it_behaves_like "check_quota for Reconfigure"
    end

    context "success when requesting storage even when cpu and vm is exceeded" do
      let(:quota_result) { nil }
      let(:quota_max) { YAML.dump(:storage => 40_960, :vms => 1, :cpu => 1, :memory => 0) }

      it_behaves_like "check_quota for Reconfigure"
    end

    context "success when requesting memory even when cpu and vm is exceeded" do
      let(:quota_result) { nil }
      let(:quota_max) { YAML.dump(:storage => 0, :vms => 1, :cpu => 1, :memory => 8192) }

      it_behaves_like "check_quota for Reconfigure"
    end

    context "failure max memory" do
      let(:quota_result) { 'error' }
      let(:quota_max) { YAML.dump(:storage => 0, :vms => 1, :cpu => 1, :memory => 4096) }
      let(:err_msg) do
        "Request exceeds maximum allowed for the following:" \
                  " (memory - Used: 1 KB plus requested: 4 KB exceeds quota: 4 KB) "
      end
      let(:msg) { err_msg }

      it_behaves_like "check_quota for Reconfigure"
    end

    context "failure max storage" do
      let(:quota_result) { 'error' }
      let(:quota_max) { YAML.dump(:storage => 20_480, :vms => 1, :cpu => 1, :memory => 0) }
      let(:err_msg) do
        "Request exceeds maximum allowed for the following:" \
                " (storage - Used: 10 KB plus requested: 20 KB exceeds quota: 20 KB) "
      end
      let(:msg) { err_msg }

      it_behaves_like "check_quota for Reconfigure"
    end
  end
end

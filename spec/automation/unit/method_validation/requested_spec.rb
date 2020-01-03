describe "Quota Validation" do
  include Spec::Support::QuotaHelper
  include Spec::Support::ServiceTemplateHelper

  def run_automate_method(attrs)
    MiqAeEngine.instantiate("/ManageIQ/system/request/Call_Instance?namespace=System/CommonMethods&" \
                            "class=QuotaMethods&instance=requested&#{attrs.join('&')}", @user)
  end

  def vm_attrs
    ["MiqRequest::miq_request=#{@miq_provision_request.id}"]
  end

  def service_attrs
    ["MiqRequest::miq_request=#{@service_request.id}&"\
     "vmdb_object_type=service_template_provision_request"]
  end

  def reconfigure_attrs
    ["MiqRequest::miq_request=#{@reconfigure_request.id}&"\
    "vmdb_object_type=VmReconfigureRequest"]
  end

  def check_results(requested_hash, storage, cpu, vms, memory)
    expect(requested_hash[:storage]).to eq(storage)
    expect(requested_hash[:cpu]).to eq(cpu)
    expect(requested_hash[:vms]).to eq(vms)
    expect(requested_hash[:memory]).to eq(memory)
  end

  context "Service provisioning quota" do
    it "generic requested" do
      setup_model("generic")
      build_generic_service_item
      expect { run_automate_method(service_attrs) }.not_to raise_exception
    end

    it "generic ansible tower requested" do
      setup_model("generic")
      build_generic_ansible_tower_service_item
      expect { run_automate_method(service_attrs) }.not_to raise_exception
    end

    it "vmware service item requested" do
      setup_model("vmware")
      build_small_environment
      build_vmware_service_item
      ws = run_automate_method(service_attrs)
      check_results(ws.root['quota_requested'], 512.megabytes, 4, 1, 1.gigabytes)
    end
  end

  shared_examples_for "requested" do
    it "check" do
      setup_model("vmware")
      build_small_environment
      build_vmware_service_item
      @service_request.options[:dialog] = result_dialog
      @service_request.save
      expect(@service_request.options[:dialog]).to include(result_dialog)
      ws = run_automate_method(service_attrs)
      expect(ws.root['quota_requested']).to include(result_counts_hash)
    end
  end

  context "vmware service item with dialog override number_of_sockets = 3" do
    let(:result_counts_hash) do
      {:storage => 512.megabytes, :cpu => 6, :vms => 1, :memory => 1.gigabytes}
    end
    let(:result_dialog) do
      {"dialog_option_0_number_of_sockets" => "3"}
    end
    it_behaves_like "requested"
  end

  context "vmware service item with dialog override cores_per_socket = 4" do
    let(:result_counts_hash) do
      {:storage => 512.megabytes, :cpu => 8, :vms => 1, :memory => 1.gigabytes}
    end
    let(:result_dialog) do
      {"dialog_option_0_cores_per_socket" => "4"}
    end
    it_behaves_like "requested"
  end

  context "vmware service item with dialog override sockets = 3 and cores = 4 = 12" do
    let(:result_counts_hash) do
      {:storage => 512.megabytes, :cpu => 12, :vms => 1, :memory => 1.gigabytes}
    end
    let(:result_dialog) do
      {"dialog_option_0_number_of_sockets" => "3", "dialog_option_0_cores_per_socket" => "4"}
    end
    it_behaves_like "requested"
  end

  context "vmware service item with dialog override number_of_cpus = 5" do
    let(:result_counts_hash) do
      {:storage => 512.megabytes, :cpu => 5, :vms => 1, :memory => 1.gigabytes}
    end
    let(:result_dialog) do
      {"dialog_option_0_number_of_cpus" => "5"}
    end
    it_behaves_like "requested"
  end

  context "vmware service item with dialog override vm_memory = 2048" do
    let(:result_counts_hash) do
      {:storage => 512.megabytes, :cpu => 4, :vms => 1, :memory => 2.gigabytes}
    end
    let(:result_dialog) do
      {"dialog_option_0_vm_memory" => "2048"}
    end
    it_behaves_like "requested"
  end

  context "vmware service item with dialog override number_of_vms = 5" do
    let(:result_counts_hash) do
      {:storage => 2560.megabytes, :cpu => 20, :vms => 5, :memory => 5.gigabytes}
    end
    let(:result_dialog) do
      {"dialog_option_0_number_of_vms" => "5"}
    end
    it_behaves_like "requested"
  end

  context "vmware service item with dialog override storage = 2147483648" do
    let(:result_counts_hash) do
      {:storage => 2.gigabytes, :cpu => 4, :vms => 1, :memory => 1.gigabytes}
    end
    let(:result_dialog) do
      {"dialog_option_0_storage" => "2147483648"}
    end
    it_behaves_like "requested"
  end

  context "vmware service item with dialog override number_of_vms = 5, sockets = 3 and cores = 4 = 12" do
    let(:result_counts_hash) do
      {:storage => 2560.megabytes, :cpu => 60, :vms => 5, :memory => 5.gigabytes}
    end
    let(:result_dialog) do
      {"dialog_option_0_number_of_vms" => "5", "dialog_option_0_number_of_sockets" => "3", "dialog_option_0_cores_per_socket" => "4"}
    end
    it_behaves_like "requested"
  end

  context "Service Bundle provisioning quota" do
    it "Bundle of 2, google and vmware" do
      create_service_bundle([google_template, vmware_template])
      expect { run_automate_method(service_attrs) }.not_to raise_exception
    end

    it "Bundle of 2, google and generic" do
      create_service_bundle([google_template, generic_template])
      expect { run_automate_method(service_attrs) }.not_to raise_exception
    end
  end

  context "google service item flavor override" do
    let(:large_flavor) do
      FactoryBot.create(:flavor_google, :ems_id => @ems.id, :cloud_subnet_required => false,
                         :cpus => 6, :cpu_cores => 2, :memory => 4026)
    end

    let(:result_dialog) do
      {"dialog_option_0_instance_type" => large_flavor.id}
    end

    it "requested" do
      setup_model("google")
      build_google_service_item

      @service_request.options[:dialog] = result_dialog
      @service_request.save
      expect(@service_request.options[:dialog]).to include(result_dialog)
      ws = run_automate_method(service_attrs)
      check_results(ws.root['quota_requested'], 10.gigabytes, 6, 1, 4026)
    end
  end

  context "google service item" do
    it "requested" do
      setup_model("google")
      build_google_service_item
      ws = run_automate_method(service_attrs)
      check_results(ws.root['quota_requested'], 10.gigabytes, 1, 1, 1024)
    end
  end

  context "VM Cloud provisioning with cloud volumes" do
    it "google requested number of vms 3, cloud volumes 3 gig " do
      setup_model("google")
      @miq_provision_request.options[:volumes] = [{:name => "Fred", :size => '1'}, {:name => "Wilma", :size => '2'}]
      @miq_provision_request.options[:number_of_vms] = 3
      @miq_provision_request.save
      ws = run_automate_method(vm_attrs)
      check_results(ws.root['quota_requested'], 39.gigabytes, 12, 3, 3.kilobytes)
    end
  end

  context "VM provisioning quota" do
    it "vmware requested" do
      setup_model("vmware")
      ws = run_automate_method(vm_attrs)
      check_results(ws.root['quota_requested'], 512.megabytes, 4, 1, 1.gigabytes)
    end

    it "google requested" do
      setup_model("google")
      ws = run_automate_method(vm_attrs)
      check_results(ws.root['quota_requested'], 10.gigabytes, 4, 1, 1024)
    end
  end

  context "VM provisioning multiple vms quota" do
    it "vmware requested number of vms 3" do
      setup_model("vmware")
      @miq_provision_request.options[:number_of_vms] = 3
      @miq_provision_request.save
      ws = run_automate_method(vm_attrs)
      check_results(ws.root['quota_requested'], 1536.megabytes, 12, 3, 3.gigabytes)
    end

    it "google requested number of vms 3" do
      setup_model("google")
      @miq_provision_request.options[:number_of_vms] = 3
      @miq_provision_request.save
      ws = run_automate_method(vm_attrs)
      check_results(ws.root['quota_requested'], 30.gigabytes, 12, 3, 3.kilobytes)
    end
  end

  context "VmReconfig quota request" do
    let(:disk) { FactoryBot.create(:disk, :size_on_disk => 1024, :size => 10_485_760, :filename => "freds disk") }
    it "add 2 cpus and add 4096 memory " do
      setup_model("vmware_reconfigure")
      @reconfigure_request.update(:options => {:src_ids => [@vm_vmware.id], :cores_per_socket => 2,\
      :number_of_sockets => 2, :number_of_cpus => 4, :vm_memory => 8192, :request_type => :vm_reconfigure,\
      :disk_add => [{"disk_size_in_mb" => "10", "persistent" => true, "thin_provisioned" => true,\
      "dependent" => true, "bootable" => false}]})
      ws = run_automate_method(reconfigure_attrs)
      check_results(ws.root['quota_requested'], 10.megabytes, 2, 1, 4096.megabytes)
    end

    it "resize 10 to 20 megabyte disk, difference is 10" do
      # Disk_resize only supports increasing the size.
      setup_model("vmware_reconfigure")
      @reconfigure_request.update(:options => {:src_ids => [@vm_vmware.id], :request_type => :vm_reconfigure,\
      :disk_resize => [{"disk_name" => disk.filename, "disk_size_in_mb" => 20}]})
      ws = run_automate_method(reconfigure_attrs)
      check_results(ws.root['quota_requested'], 10.megabytes, 0, 1, 0)
    end

    it "resize a disk thats not found" do
      setup_model("vmware_reconfigure")
      @reconfigure_request.update(:options => {:src_ids => [@vm_vmware.id], :request_type => :vm_reconfigure,\
      :disk_resize => [{"disk_name" => "not found", "disk_size_in_mb" => 20}]})
      expect { run_automate_method(reconfigure_attrs) }.to raise_error(MiqAeException::UnknownMethodRc)
    end

    it "removes a disk " do
      setup_model("vmware_reconfigure")
      @reconfigure_request.update(:options => {:src_ids => [@vm_vmware.id], :request_type => :vm_reconfigure,\
      :disk_remove => [{:disk_name => disk.filename, :persistent => true, :thin_provisioned => false,\
      "dependent" => true, "bootable" => false}]})
      ws = run_automate_method(reconfigure_attrs)
      check_results(ws.root['quota_requested'], -10.megabytes, 0, 1, 0.megabytes)
    end

    it "remove a disk thats not found" do
      setup_model("vmware_reconfigure")
      @reconfigure_request.update(:options => {:src_ids => [@vm_vmware.id], :request_type => :vm_reconfigure,\
      :disk_remove => [{:disk_name => "not found", :persistent => true, :thin_provisioned => false,\
      "dependent" => true, "bootable" => false}]})
      expect { run_automate_method(reconfigure_attrs) }.to raise_error(MiqAeException::UnknownMethodRc)
    end

    it "minus 1 cpu and minus 2048 memory" do
      setup_model("vmware_reconfigure")
      @reconfigure_request.update(:options => {:src_ids => [@vm_vmware.id], :cores_per_socket => 1,\
      :number_of_sockets => 1, :number_of_cpus => 1, :vm_memory => 2048, :request_type => :vm_reconfigure})
      ws = run_automate_method(reconfigure_attrs)
      check_results(ws.root['quota_requested'], 0, -1, 1, -2048.megabytes)
    end

    it "no change" do
      setup_model("vmware_reconfigure")
      @reconfigure_request.update(:options => {:src_ids => [@vm_vmware.id], :cores_per_socket => 2,\
      :number_of_sockets => 1, :number_of_cpus => 2, :vm_memory => 4096, :request_type => :vm_reconfigure})
      ws = run_automate_method(reconfigure_attrs)
      check_results(ws.root['quota_requested'], 0, 0, 1, 0.megabytes)
    end
  end
end

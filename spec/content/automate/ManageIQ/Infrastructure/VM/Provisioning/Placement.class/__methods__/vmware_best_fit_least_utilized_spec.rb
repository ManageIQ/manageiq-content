require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/System/CommonMethods/Utils.class/__methods__/log_object.rb')

describe ManageIQ::Automate::Infrastructure::VM::Provisioning::Placement::VmwareBestFitLeastUtilized do
  let(:datacenter)  { FactoryBot.create(:datacenter, :ext_management_system => ems) }
  let(:ems)         { FactoryBot.create(:ems_vmware_with_authentication) }
  let(:ems_cluster) { FactoryBot.create(:ems_cluster, :ext_management_system => ems) }
  let(:miq_provision) do
    FactoryBot.create(:miq_provision_vmware,
                       :options      => {:src_vm_id => vm_template.id, :placement_auto => [true, 1]},
                       :userid       => user.userid,
                       :source       => vm_template,
                       :request_type => 'clone_to_vm',
                       :state        => 'active',
                       :status       => 'Ok')
  end
  let(:user)        { FactoryBot.create(:user_with_group) }
  let(:vm_template) { FactoryBot.create(:template_vmware, :ext_management_system => ems) }

  let(:svc_miq_provision) { MiqAeMethodService::MiqAeServiceMiqProvision.find(miq_provision.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new(:miq_provision => svc_miq_provision) }
  let(:ae_service)  { Spec::Support::MiqAeMockService.new(root_object) }

  it 'requires miq_provision attribute in root object' do
    new_service = Spec::Support::MiqAeMockService.new(Spec::Support::MiqAeMockObject.new)
    allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/miq_provision not specified/, new_service).and_raise(RuntimeError)
    expect { described_class.new(new_service).main }.to raise_error(RuntimeError)
  end

  it 'requires source vm in miq_provision' do
    miq_provision.update(:source => nil)
    allow(ManageIQ::Automate::System::CommonMethods::Utils::LogObject).to receive(:log_and_raise).with(/VM not specified/, ae_service).and_raise(RuntimeError)
    expect { described_class.new(ae_service).main }.to raise_error(RuntimeError)
  end

  context "Auto placement" do
    let(:storages) { Array.new(4) { |r| FactoryBot.create(:storage, :free_space => 1000 * (r + 1)) } }
    let(:ro_storage) { FactoryBot.create(:storage, :free_space => 10_000) }
    let(:storage_profile) { FactoryBot.create(:storage_profile) }

    let(:vms) { Array.new(5) { FactoryBot.create(:vm_vmware) } }

    # host1 has two small  storages and 2 vms
    # host2 has two larger storages and 3 vms
    # host3 has one larger read-only datastore and one smaller writable datastore
    let(:host1) { FactoryBot.create(:host_vmware, :storages => storages[0..1], :vms => vms[2..3], :ext_management_system => ems) }
    let(:host2) { FactoryBot.create(:host_vmware, :storages => storages[0..1], :vms => vms[2..4], :ext_management_system => ems) }
    let(:host3) { FactoryBot.create(:host_vmware, :storages => [ro_storage, storages[2]], :vms => vms[2..4], :ext_management_system => ems) }
    let(:host4) { FactoryBot.create(:host_vmware, :storages => storages[0..2], :vms => vms[2..4], :ext_management_system => ems) }
    let(:host5) { FactoryBot.create(:host_vmware, :storages => [ro_storage, storages[2]], :vms => vms[2..4], :ext_management_system => ems) }

    let(:host_struct) do
      [MiqHashStruct.new(:id => host1.id, :evm_object_class => host1.class.base_class.name.to_sym),
       MiqHashStruct.new(:id => host2.id, :evm_object_class => host2.class.base_class.name.to_sym)]
    end

    let(:svc_host1) { MiqAeMethodService::MiqAeServiceHost.find(host1.id) }
    let(:svc_host2) { MiqAeMethodService::MiqAeServiceHost.find(host2.id) }
    let(:svc_host3) { MiqAeMethodService::MiqAeServiceHost.find(host3.id) }
    let(:svc_host4) { MiqAeMethodService::MiqAeServiceHost.find(host4.id) }
    let(:svc_host5) { MiqAeMethodService::MiqAeServiceHost.find(host5.id) }

    let(:svc_storages) { storages.collect { |s| MiqAeMethodService::MiqAeServiceStorage.find(s.id) } }
    let(:svc_host_struct) { [svc_host1, svc_host2, svc_host4] }

    context "hosts with a cluster" do
      before do
        host1.ems_cluster = ems_cluster
        host2.ems_cluster = ems_cluster
        host4.ems_cluster = ems_cluster
        datacenter.with_relationship_type("ems_metadata") { datacenter.add_child(ems_cluster) }
        HostStorage.where(:host_id => host3.id, :storage_id => ro_storage.id).update(:read_only => true)
      end

      it "selects a host with fewer vms and a storage with more free space" do
        allow(svc_miq_provision).to receive(:eligible_hosts).and_return(svc_host_struct)
        allow(svc_miq_provision).to receive(:eligible_storages).and_return(svc_storages)

        expect(svc_miq_provision).to receive(:set_host).with(svc_host1)
        allow(svc_miq_provision).to receive(:set_storage) do |s|
          expect(s.id).to eq(svc_host1.storages[1].id)
          expect(s.name).to eq(svc_host1.storages[1].name)
        end

        described_class.new(ae_service).main
      end

      context "with all storages accessible" do
        it "selects largest storage that is writable" do
          allow(svc_miq_provision).to receive(:eligible_hosts).and_return([svc_host3])
          allow(svc_miq_provision).to receive(:eligible_storages).and_return(svc_host3.storages)

          expect(svc_miq_provision).to receive(:set_host).with(svc_host3)
          allow(svc_miq_provision).to receive(:set_storage) do |s|
            # ro_storage is larger but read-only, so it should select storages[2]
            expect(s.id).to eq(storages[2].id)
            expect(s.name).to eq(storages[2].name)
          end

          described_class.new(ae_service).main
        end
      end

      context "with no storages accessible" do
        before do
          HostStorage.where(:host_id => host5.id, :storage_id => ro_storage.id).update(:accessible => false)
          HostStorage.where(:host_id => host5.id, :storage_id => storages[2].id).update(:accessible => false)
        end
        it "selects nothing" do
          allow(svc_miq_provision).to receive(:eligible_hosts).and_return([svc_host5])
          allow(svc_miq_provision).to receive(:eligible_storages).and_return(svc_host5.storages)

          expect(svc_miq_provision).not_to receive(:set_host)
          allow(svc_miq_provision).to receive(:set_storage) do |s|
            # both ro_storage and storages[2] are inaccessible
            expect(s.id).to eq(nil)
            expect(s.name).to eq(nil)
          end

          described_class.new(ae_service).main
        end
      end

      context "with the writable storage inaccessible" do
        before do
          HostStorage.where(:host_id => host5.id, :storage_id => storages[2].id).update(:accessible => false)
        end
        it "selects ro storage" do
          allow(svc_miq_provision).to receive(:eligible_hosts).and_return([svc_host5])
          allow(svc_miq_provision).to receive(:eligible_storages).and_return(svc_host5.storages)

          expect(svc_miq_provision).to receive(:set_host).with(svc_host5)
          allow(svc_miq_provision).to receive(:set_storage) do |s|
            # storages[2] is inaccessible so it should select the ro
            expect(s.id).to eq(ro_storage.id)
            expect(s.name).to eq(ro_storage.name)
          end

          described_class.new(ae_service).main
        end
      end

      it "selects the storage in the storage profile" do
        options = miq_provision.options.merge(:placement_storage_profile => storage_profile.id)
        miq_provision.update(:options => options)
        storages[2].storage_profiles = [storage_profile]

        allow(svc_miq_provision).to receive(:eligible_hosts).and_return(svc_host_struct)
        allow(svc_miq_provision).to receive(:eligible_storages).and_return(svc_storages)

        expect(svc_miq_provision).to receive(:set_host).with(svc_host4)
        allow(svc_miq_provision).to receive(:set_storage) do |s|
          expect(s.id).to eq(svc_host4.storages[2].id)
          expect(s.name).to eq(svc_host4.storages[2].name)
        end

        described_class.new(ae_service).main
      end
    end

    context "hosts without a cluster" do
      before do
        datacenter.with_relationship_type("ems_metadata") do
          datacenter.add_child(host1)
          datacenter.add_child(host2)
        end
      end

      it "selects a host with fewer vms and a storage with more free space" do
        allow(svc_miq_provision).to receive(:eligible_hosts).and_return(svc_host_struct)
        allow(svc_miq_provision).to receive(:eligible_storages).and_return(svc_storages)

        expect(svc_miq_provision).to receive(:set_host).with(svc_host1)
        allow(svc_miq_provision).to receive(:set_storage) do |s|
          expect(s.id).to eq(svc_host1.storages[1].id)
          expect(s.name).to eq(svc_host1.storages[1].name)
        end

        described_class.new(ae_service).main
      end

      it "selects a host not in maintenance" do
        host1.update(:maintenance => true)

        allow(svc_miq_provision).to receive(:eligible_hosts).and_return(svc_host_struct)
        allow(svc_miq_provision).to receive(:eligible_storages).and_return(svc_storages)

        expect(svc_miq_provision).to receive(:set_host).with(svc_host2)
        allow(svc_miq_provision).to receive(:set_storage) do |s|
          expect(s.id).to eq(svc_host2.storages[1].id)
          expect(s.name).to eq(svc_host2.storages[1].name)
        end

        described_class.new(ae_service).main
      end
    end
  end
end

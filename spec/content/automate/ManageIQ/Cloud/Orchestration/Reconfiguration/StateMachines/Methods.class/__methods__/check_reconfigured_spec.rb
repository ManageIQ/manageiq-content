require_domain_file

describe ManageIQ::Automate::Cloud::Orchestration::Reconfiguration::StateMachines::Methods::CheckReconfigured do
  let(:user)          { FactoryBot.create(:user_with_group) }
  let(:ems_amazon)    { FactoryBot.create(:ems_amazon, :last_refresh_date => Time.now.getlocal - 100) }
  let(:request)       { FactoryBot.create(:service_reconfigure_request, :requester => user) }
  let(:orch_template) { FactoryBot.create(:orchestration_template) }
  let(:serv_template) { FactoryBot.create(:service_template_orchestration, :orchestration_template => orch_template) }

  let(:service_orchestration) do
    FactoryBot.create(:service_orchestration,
                       :orchestration_manager => ems_amazon,
                       :service_template      => serv_template)
  end

  let(:miq_reconfigure_task) { FactoryBot.create(:service_reconfigure_task, :request_type => 'service_reconfigure') }
  let(:svc_model_service)    { MiqAeMethodService::MiqAeServiceService.find(service_orchestration.id) }

  let(:svc_model_service_reconfigure_task) do
    MiqAeMethodService::MiqAeServiceServiceReconfigureTask.find(miq_reconfigure_task.id)
  end

  let(:svc_model_orchestration_manager) do
    MiqAeMethodService::MiqAeServiceExtManagementSystem.find(ems_amazon.id)
  end

  let(:root_hash) do
    { 'service_template' => MiqAeMethodService::MiqAeServiceService.find(service_orchestration.id) }
  end

  let(:root_object) do
    obj = Spec::Support::MiqAeMockObject.new(root_hash)
    obj["service_reconfigure_task"] = svc_model_service_reconfigure_task
    obj
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  context "with a service" do
    let(:update_result) { 'ae_result' }
    let(:update_reason) { 'ae_reason' }

    before do
      allow(svc_model_service_reconfigure_task).to receive(:source).and_return(svc_model_service)
      allow(svc_model_service_reconfigure_task).to receive(:miq_request).and_return(svc_model_service_reconfigure_task)
    end

    context "check_refreshed" do
      it "refresh_may_have_completed? is true" do
        ae_service.set_state_var('provider_last_refresh', (Time.now.getlocal - 200).to_i)
        ae_service.set_state_var('update_result', update_result)
        ae_service.set_state_var('update_reason', update_reason)

        expect(svc_model_service_reconfigure_task).to receive(:user_message=).with(update_reason)
        described_class.new(ae_service).main
        expect(ae_service.root['ae_result']).to eq(update_result)
        expect(ae_service.root['ae_reason']).to eq(update_reason)
      end

      it "refresh_may_have_completed? is false" do
        ae_service.set_state_var('provider_last_refresh', Time.now.getlocal.to_i)
        described_class.new(ae_service).main
        expect(ae_service.root['ae_result']).to eq('retry')
        expect(ae_service.root['ae_retry_interval']).to eq('30.seconds')
      end
    end

    context "check_updated" do
      before do
        allow(svc_model_service).to receive(:orchestration_manager).and_return(svc_model_orchestration_manager)
        allow(svc_model_orchestration_manager).to receive(:refresh)
      end

      after do
        expect(ae_service.root['ae_result']).to eq('retry')
        expect(ae_service.root['ae_retry_interval']).to eq('30.seconds')
      end

      it "orchestration_stack_status is 'update_complete'" do
        allow(svc_model_service).to receive(:orchestration_stack_status)
          .and_return(['update_complete', nil])
        described_class.new(ae_service).main

        expect(ae_service.get_state_var('update_result')).to eq('ok')
        expect(ae_service.get_state_var('update_reason')).to eq(nil)
      end

      it "orchestration_stack_status is 'rollback_complete'" do
        allow(svc_model_service).to receive(:orchestration_stack_status)
          .and_return(['rollback_complete', update_reason])

        expect(svc_model_service_reconfigure_task).to receive(:user_message=).with(update_reason)
        described_class.new(ae_service).main
        expect(ae_service.get_state_var('update_result')).to eq('error')
        expect(ae_service.get_state_var('update_reason')).to eq(update_reason)
      end

      it "update in provider hasn't been done yet" do
        allow(svc_model_service).to receive(:orchestration_stack_status)
          .and_return(['', nil])
        described_class.new(ae_service).main

        expect(ae_service.get_state_var('update_result')).to eq('retry')
        expect(ae_service.get_state_var('update_reason')).to eq(nil)
      end
    end
  end

  context "without a service" do
    let(:root_hash) { {} }
    let(:svc_model_service) { nil }

    it "raises the 'service is nil' exception" do
      expect { described_class.new(ae_service).main }.to raise_error('Service is nil')
    end
  end
end

require_domain_file

describe ManageIQ::Automate::Cloud::Orchestration::Lifecycle::OrchestrationMixin do
  let(:root)        { {} }
  let(:object)      { {} }
  let(:stack_by_id) { nil }
  let(:handle) do
    handle = double('handle', :root => root, :object => object)
    allow(handle).to receive(:log)
    allow(handle).to receive(:vmdb).and_return(stack_by_id)
    handle
  end

  # Annonymous class where we include the module in order to test module functions.
  subject { Class.new { include ManageIQ::Automate::Cloud::Orchestration::Lifecycle::OrchestrationMixin }.new }

  describe '#get_stack' do
    it('stack not found') { assert_not_stack }

    describe 'from $evm.object' do
      context '$evm.object["orchestration_stack"]' do
        let(:object) { { 'orchestration_stack' => 'STACK' } }
        it { assert_stack }
      end

      describe '$evm.object["orchestration_stack_id"]' do
        let(:object) { { 'orchestration_stack_id' => 123 } }
        it 'when stack by id not found' do
          assert_not_stack
        end

        context 'when stack by id is found' do
          let(:stack_by_id) { 'STACK' }
          before            { FactoryGirl.create(:orchestration_stack_cloud, :id => 123) }
          it { assert_stack }
        end
      end
    end

    describe 'from $evm.root' do
      context '$evm.root["orchestration_stack"]' do
        let(:root) { { 'orchestration_stack' => 'STACK' } }
        it         { assert_stack }
      end

      describe '$evm.root["orchestration_stack_id"]' do
        let(:root) { { 'orchestration_stack_id' => 123 } }
        it('when stack by id not found') { assert_not_stack }

        context 'when stack by id is found' do
          let(:stack_by_id) { 'STACK' }
          before            { FactoryGirl.create(:orchestration_stack_cloud, :id => 123) }
          it                { assert_stack }
        end
      end

      context 'stack from $evm.root["service"].orchestration_stack' do
        let(:service) { double('service', :orchestration_stack => 'STACK') }
        let(:root)    { { 'service' => service } }
        it            { assert_stack }
      end
    end

    def assert_stack
      expect(subject.get_stack(handle)).to eq('STACK')
    end

    def assert_not_stack
      expect(subject.get_stack(handle)).to be_nil
    end
  end

  describe '#get_service' do
    it('service not found') { assert_not_service }

    context('from $evm.object') do
      let(:object) { { 'service' => 'SERVICE' } }
      it { assert_service }
    end

    context('from $evm.root') do
      let(:root) { { 'service' => 'SERVICE' } }
      it { assert_service }
    end

    def assert_service
      expect(subject.get_service(handle)).to eq('SERVICE')
    end

    def assert_not_service
      expect(subject.get_service(handle)).to be_nil
    end
  end
end

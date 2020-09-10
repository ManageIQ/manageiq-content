module AutomateClassDefinitionHook
  mattr_accessor :hooking

  def self.hooked
    @hooked ||= []
  end

  def inherited(other)
    AutomateClassDefinitionHook.hook(other)
    super
  end

  def self.require_with_hook(file_name)
    self.hooking = true
    require(file_name).tap { unhook }
  end

  class TestLoadStub
    def main
    end
  end

  def self.hook(klass)
    return unless hooking
    if klass.name&.start_with?("ManageIQ::Automate::")
      hooked << klass
      klass.define_singleton_method(:new) { |*_args| AutomateClassDefinitionHook::TestLoadStub.new }
    end
  end

  def self.unhook
    hooked.delete_if { |klass| klass.singleton_class.send(:remove_method, :new) }
    self.hooking = false
  end
end

Object.singleton_class.prepend(AutomateClassDefinitionHook)

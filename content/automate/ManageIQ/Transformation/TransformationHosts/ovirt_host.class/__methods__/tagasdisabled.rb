#
#
#
module ManageIQ
  module Automate
    module Transformation
      module TransformationHost
        module OVirtHost
          class TagAsDisabled
            def initialize(handle = $evm)
              @handle = handle
            end

            def main
              host = @handle.root['host']
              raise "No host found. Aborting." if host.nil?
              host.tag_assign('v2v_transformation_host/false')
              host.tag_unassign('v2v_transformation_method/vddk')
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Transformation::TransformationHost::OVirtHost::TagAsDisabled.new.main

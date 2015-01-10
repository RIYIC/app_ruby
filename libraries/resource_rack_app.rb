class Chef
  class Resource
    class RackApp < Chef::Resource::RiyicApp

      def initialize(name, run_context = nil)
        super(name, run_context)
        @resource_name = :rack_app
        @provider = Chef::Provider::RackApp
        @exclude_bundler_groups = []
        @extra_gems = []
      end

      def exclude_bundler_groups(arg=nil)
          set_or_return(
              :exclude_bundler_groups,
              arg,
              :kind_of => [Array],
              :default => []
          )
      end


      def extra_gems(arg=nil)
          set_or_return(
              :extra_gems,
              arg,
              :kind_of => Array
          )
      end

    end
  end
end

# Xata database compatibility
# Xata doesn't support CREATE EXTENSION statements but has plpgsql enabled by default
# This must run before schema loading, hence the 00_ prefix for early loading

if ENV["DATABASE_URL"]&.include?("xata.sh")
  # Use ActiveSupport.on_load to ensure the adapter is loaded before patching
  ActiveSupport.on_load(:active_record) do
    module XataExtensionPrevention
      def enable_extension(name, **)
        Rails.logger&.info "Skipping extension '#{name}' - Xata has it enabled by default"
        return
      end
    end

    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(XataExtensionPrevention)
  end
end

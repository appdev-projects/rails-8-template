# Xata database compatibility
# Xata doesn't support CREATE EXTENSION statements but has plpgsql enabled by default

# Prevent extension enabling when using Xata
if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  module XataExtensionPrevention
    def enable_extension(name, **)
      # Skip enabling extensions on Xata (they're already enabled)
      if ENV["DATABASE_URL"]&.include?("xata.sh")
        Rails.logger&.info "Skipping extension '#{name}' - Xata has it enabled by default"
        return
      end
      super
    end
  end

  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(XataExtensionPrevention)
end

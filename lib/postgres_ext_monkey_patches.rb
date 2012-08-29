# These patches are from this commit:
# https://github.com/dockyard/postgres_ext/commit/78d1139fca048935ba09132f5c0d5acb685bd6c3
# They are required in order to properly update inet/cidr postgres columns
module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      def quote_with_extended_types(value, column = nil)
        if [Array, IPAddr].include? value.class
          "'#{type_cast(value, column)}'"
        else
          quote_without_extended_types(value, column)
        end
      end
      alias_method_chain :quote, :extended_types
    end
  end
end

module Arel
  module Visitors
    class ToSql
      private
      def visit_IPAddr value
        "'#{value.to_s}/#{value.instance_variable_get(:@mask_addr).to_s(2).count('1')}'"
      end
    end
  end
end

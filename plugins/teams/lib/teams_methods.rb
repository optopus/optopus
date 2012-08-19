module TeamsMethods
  module Role
    module ClassMethods
      def teams
        where("properties -> 'team_enable' = 'true'")
      end
    end

    module InstanceMethods
      def team
        properties['team_enable'] == true.to_s
      end

      def team=(value)
        properties['team_enable'] = value
      end

      def teams
        where("properties -> 'team_enable' = 'true'")
      end
    end

    def self.included(base)
      base.class_eval do
        extend TeamsMethods::Role::ClassMethods
      end
      base.instance_eval do
        include TeamsMethods::Role::InstanceMethods
      end
    end
  end
end

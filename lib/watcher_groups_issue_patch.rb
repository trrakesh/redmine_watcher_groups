
module WatcherGroupsIssuePatch

  def self.included(base) # :nodoc:
    base.send(:prepend, InstanceMethods)
    
    base.class_eval do
      alias_method :send_notification_with_out_watcher, :send_notification
      alias_method :send_notification, :send_notification_with_watcher
    end 

  end

	Issue.class_eval do
    include WatcherGroupsHelper

    scope :watched_by, lambda { |user|
      user = User.find(user) unless user.is_a?(User)
      g = user.groups
      joins(:watchers).where("#{Watcher.table_name}.user_id IN (#{user.id} #{g.empty? ? "" : ","} #{g.map(&:id).join(',')})")
    }

    def send_notification_with_watcher
    
    end

    def watcher_groups_send_notification
      send_notification_with_out_watcher
    end

    def watcher_groups
      if self.id
        groups = Watcher.where("watchable_type='#{self.class}' and watchable_id = #{self.id}")
        Group.where(id: groups.map(&:user_id))
      end
    end

    def watcher_groups_ids
      self.watcher_groups.collect {|group| group.id}
    end

    def watcher_groups_ids=(group_ids)
      groups = group_ids.collect {|group_id| Group.find(group_id) if Group.find(group_id).is_a?(Group)  }
			user_ids = groups.map(&:users).flatten.compact.uniq.map(&:id)
      Watcher.where("watchable_type = '#{self.class}' AND watchable_id = #{self.id} AND user_id IN (#{user_ids.join(',')})").delete_all unless user_ids.empty?
      groups.each do |group|
        self.add_watcher_group(group)
      end
    end

    # Returns an array of users that are proposed as watchers
    def addable_watcher_groups
      groups = self.project.principals.select{|p| p if p.type=='Group'}
      groups = groups.sort - self.watcher_groups
      if respond_to?(:visible?)
        groups.reject! {|group| !visible?(group)}
      end
      groups
    end

    # Adds group as a watcher
    def add_watcher_group(group)
      if Watcher.where("watchable_type='#{self.class}' and watchable_id = #{self.id} and user_id = '#{group.id}'").limit(1).all.blank?
        # insert directly into table to avoid user type checking
        Watcher.connection.execute("INSERT INTO #{Watcher.table_name} (user_id, watchable_id, watchable_type) VALUES (#{group.id}, #{self.id}, '#{self.class.name}')")
      end
    end

    # Removes user from the watchers list
    def remove_watcher_group(group)
      return nil unless group && group.is_a?(Group)
      Watcher.where("watchable_type = '#{self.class}' AND watchable_id = #{self.id} AND user_id = #{group.id}").delete_all
    end

    # Adds/removes watcher
    def set_watcher_group(group, watching=true)
      watching ? add_watcher_group(group) : remove_watcher_group(group)
    end

    # Returns true if object is watched by +user+
    def watched_by_group?(group)
      !!(group && self.watcher_groups.detect {|gr| gr.id == group.id } unless self.watcher_groups.nil?)
    end

  end

  module InstanceMethods
    def notified_watchers
      notified = []

			w = Watcher.where("watchable_type='#{self.class}' and watchable_id = #{self.id}").all
      groups = Group.where(:id => w.map(&:user_id)).all

      groups.each do |p|
          group_users = p.users.to_a
          group_users.reject! {|user| user.mail.blank? || user.mail_notification == 'none'}
          if respond_to?(:visible?)
            group_users.reject! {|user| !visible?(user)}
          end
          notified += group_users
      end
      notified += watcher_users
      notified.reject! {|user| user.mail.blank? || user.mail_notification == 'none'}
      if respond_to?(:visible?)
        notified.reject! {|user| !visible?(user)}
      end
      notified.uniq
    end

    def watched_by?(user)
      watcher_groups.each do |group|
        return true if user.is_or_belongs_to?(group)
      end if self.id?
      super(user)
    end

    def implicit_watcher_users
			users = []
			if self.id?
	      watcher_groups.each do |g|
	        users += g.users
				end
				users -= watcher_users
			end
      users.uniq
    end
  end
end


require 'redmine' 

require_relative 'lib/watcher_groups/views_issues_hook'
require_relative 'lib/watcher_groups_helper' 
require_relative 'lib/watcher_groups_issue_hook'
require_relative 'lib/watchers_list_override'
Rails.logger.info 'Starting Watcher Groups plugin for Redmine'
 

Rails.configuration.after_initialize do

  unless WatchersHelper.included_modules.include?(WatchersListOverride)
    WatchersHelper.send(:prepend, WatchersListOverride)
	end
	
  unless WatcherGroupsHelper.included_modules.include?(WatchersHelper)
    WatcherGroupsHelper.send(:include, WatchersHelper)
	end
	
  unless Issue.included_modules.include?(WatcherGroupsIssuePatch)
    Issue.send(:include, WatcherGroupsIssuePatch)
	end

  unless IssuesController.included_modules.include?(WatcherGroupsIssuesControllerPatch)
    IssuesController.send(:include, WatcherGroupsIssuesControllerPatch)
  end

end

Redmine::Plugin.register :redmine_watcher_groups do
  name 'Redmine Watcher Groups plugin'
  author 'Kamen Ferdinandov, Massimo Rossello'
  description 'This is a plugin for Redmine to add watcher groups functionality'
  version '1.0.0'
  url 'http://github.com/maxrossello/redmine_watcher_groups'
  author_url 'http://github.com/maxrossello'
end

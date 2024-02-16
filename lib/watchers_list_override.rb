module WatchersListOverride	
	def watchers_list(object)
		remove_allowed = User.current.allowed_to?("delete_#{object.class.name.underscore}_watchers".to_sym, object.project)
		content = ''.html_safe
		user_in_groups = []
		return unless object.respond_to?(:watcher_groups)
		object.watcher_groups.collect {|group| user_in_groups += group.users }
		lis = object.implicit_watcher_users.collect do |user|
			s = ''.html_safe
			s << avatar(user, :size => "16").to_s
			s << link_to_user(user, :class => 'user')
			if remove_allowed and !user.in? user_in_groups
				url = {:controller => 'watchers',
							 :action => 'destroy',
							 :object_type => object.class.to_s.underscore,
							 :object_id => object.id,
							 :user_id => user}
				s << ' '
				s << link_to(image_tag('delete.png'), url,
										 :remote => true, :method => 'delete', :class => "delete")
			end
			content << content_tag('li', s, :class => "user-#{user.id}")
		end
		super(object) + (content.present? ? content_tag('ul', content, :class => 'watchers') : content) + '<script type="text/javascript">(function (h3) { h3.text(h3.text().replace(/\(\d+\)/, function (m) { return "(" + $("#watchers li").length + ")" })) }) ($("#watchers h3"))</script>'.html_safe
	end
end
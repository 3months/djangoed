# include require record extentions - included later on request
require File.dirname(__FILE__) + '/active_record/extensions/managed_content'
require File.dirname(__FILE__) + '/active_record/extensions/enumerable'
require File.dirname(__FILE__) + '/active_record/extensions/sluggable'
require File.dirname(__FILE__) + '/active_record/extensions/base'

# now require action controller extensions - included later on request
require File.dirname(__FILE__) + '/action_controller/extensions/actions'
require File.dirname(__FILE__) + '/action_controller/extensions/record_select'
require File.dirname(__FILE__) + '/action_controller/extensions/base'

# now require action view extensions - included later on request
require File.dirname(__FILE__) + '/action_view/extensions/filters'
require File.dirname(__FILE__) + '/action_view/extensions/record_select'
require File.dirname(__FILE__) + '/action_view/extensions/base'

# require routing and include it immediately
require File.dirname(__FILE__) + '/routing/extensions/base'
ActionController::Routing::RouteSet::Mapper.send :include, Routing::Extensions::Base
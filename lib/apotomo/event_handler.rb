module Apotomo
  class EventHandler
    attr_accessor :widget_id, :state, :content, :event
    
    
    def process_for(tree, page)
      target = tree.find_by_path(widget_id) ### DISCUSS: widget_id or widget_selector?
      raise "widget '#{widget_id}' could not be found." unless target
      
      puts "EventHandler: invoking #{target.name}##{state}"
      @content = target.invoke(state)
      
      target.trigger(:afterInvoke)
      
      self
    end
  end
end
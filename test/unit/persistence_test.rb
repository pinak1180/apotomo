require File.join(File.dirname(__FILE__), *%w[.. test_helper])

class PersistenceTest < Test::Unit::TestCase
  
  context "After #hibernate_widget (request) the widget" do
    should "still have the same ivars" do
      class PersistentMouse < Apotomo::StatefulWidget # we need a named class for marshalling.
        attr_reader :who, :what
          
        def educate
          @who  = "the cat"
          @what = "run away"
          render :nothing => true
        end
          
        def recap;  render :nothing => true; end
      end
      @mum = PersistentMouse.new('mum', :educate)
      @mum.controller = @controller ### FIXME: remove that dependency
      
      @mum.invoke(:educate)
      
      assert_equal @mum.last_state, :educate
      assert_equal @mum.who,  "the cat"
      assert_equal @mum.what, "run away"
      
      @mum = hibernate_widget(@mum)
      @mum.controller = @controller ### FIXME: remove that dependency
      
      @mum.invoke(:recap)
      
      assert_equal @mum.last_state, :recap
      assert_equal @mum.who,  "the cat"
      assert_equal @mum.what, "run away"
    end
  end
  
  context "freezing and thawing a widget family" do
    setup do
      mum_and_kid!
      @storage = {}
    end
    
    should "push @mum's freezable ivars to the storage when calling #freeze_ivars_to" do
      @mum.freeze_ivars_to(@storage)
      
      assert_equal 1, @storage.size
      assert_equal 6, @storage['mum'].size
    end
    
    should "push family's freezable ivars to the storage when calling #freeze_data_to" do
      @kid << mouse_mock('pet')
      @mum.freeze_data_to(@storage)
      
      assert_equal 3, @storage.size
      assert_equal 6, @storage['mum'].size
      assert_equal 6, @storage['mum/kid'].size
      assert_equal 5, @storage['mum/kid/pet'].size
    end
    
    should "push ivars and structure to the storage when calling #freeze_to" do
      @mum.freeze_to(@storage)
      assert_equal 2, @storage[:apotomo_widget_ivars].size
      assert_kind_of Apotomo::StatefulWidget, @storage[:apotomo_root]
    end
    
    should "update @mum's ivars when calling #thaw_ivars_from" do
      @mum.instance_variable_set(:@name, "zombie mum")
      assert_equal 'zombie mum', @mum.name
      
      @mum.thaw_ivars_from({'zombie mum' => {'@name' => 'mum'}})
      assert_equal 'mum', @mum.name
    end
    
    should "update family's ivars when calling #thaw_data_from" do
      @kid << @pet = mouse_mock('pet')
      @kid.instance_variable_set(:@name, "paranoid kid")
      @pet.instance_variable_set(:@name, "mad dog")
      assert_equal "paranoid kid", @kid.name
      
      @mum.thaw_data_from({ "mum/paranoid kid"  => {'@name' => 'kid'},
                            "mum/kid/mad dog"   => {'@name' => 'pet'}})
      assert_equal 'kid', @kid.name
      assert_equal 'pet', @pet.name
    end
    
    should "recreate it when calling #thaw_from" do
      @kid << @pet = mouse_mock('pet', :bark)
      @mum.freeze_to(@storage)
      
      mum = Apotomo::StatefulWidget.thaw_from(@storage)
      assert_equal 3, mum.size
      assert_equal :answer_squeak,  mum.instance_variable_get(:@start_state)
      assert_equal :peek,           mum.children.first.instance_variable_get(:@start_state)
      assert_equal :bark,           mum.children.first.children.first.instance_variable_get(:@start_state)
    end
  end
end
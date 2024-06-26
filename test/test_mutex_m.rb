# frozen_string_literal: false
require 'test/unit'
require 'mutex_m'

class TestMutexM < Test::Unit::TestCase
  def test_cv_wait
    o = Object.new
    o.instance_variable_set(:@foo, nil)
    o.extend(Mutex_m)
    c = Thread::ConditionVariable.new
    t = Thread.start {
      o.synchronize do
        until foo = o.instance_variable_get(:@foo)
          c.wait(o)
        end
        foo
      end
    }
    sleep(0.0001)
    o.synchronize do
      o.instance_variable_set(:@foo, "abc")
    end
    c.signal
    assert_equal "abc", t.value
  end

  class KeywordInitializeParent
    def initialize(x:)
    end
  end

  class KeywordInitializeChild < KeywordInitializeParent
    include Mutex_m
    def initialize
      super(x: 1)
    end
  end

  def test_initialize_with_keyword_arg
    assert KeywordInitializeChild.new
  end

  class NoArgInitializeParent
    def initialize
    end
  end

  class NoArgInitializeChild < NoArgInitializeParent
    include Mutex_m
    def initialize
      super()
    end
  end

  def test_initialize_no_args
    assert NoArgInitializeChild.new
  end

  class PositionalArgInitializeParent
    attr_reader :x

    def initialize(x)
      @x = x
    end
  end

  def test_include
    c = PositionalArgInitializeParent.dup
    c.class_eval do
      alias initialize initialize
      def initialize(x)
        @x = x
        super()
      end
      include Mutex_m
    end
    o = c.new(1)
    assert_equal(1, o.synchronize{o.x})
  end

  def test_prepend
    c = PositionalArgInitializeParent.dup
    c.prepend Mutex_m
    o = c.new(1)
    assert_equal(1, o.synchronize{o.x})
  end

  def test_include_sub
    c = Class.new(PositionalArgInitializeParent)
    c.include Mutex_m
    o = c.new(1)
    assert_equal(1, o.synchronize{o.x})
  end

  def test_prepend_sub
    c = Class.new(PositionalArgInitializeParent)
    c.prepend Mutex_m
    o = c.new(1)
    assert_equal(1, o.synchronize{o.x})
  end

  def test_alias_extended_object
    object = Object.new
    object.extend(Mutex_m)

    assert object.respond_to?(:locked?)
    assert object.respond_to?(:lock)
    assert object.respond_to?(:unlock)
    assert object.respond_to?(:try_lock)
    assert object.respond_to?(:synchronize)
  end

  def test_alias_included_class
    object = NoArgInitializeChild.new

    assert object.respond_to?(:locked?)
    assert object.respond_to?(:lock)
    assert object.respond_to?(:unlock)
    assert object.respond_to?(:try_lock)
    assert object.respond_to?(:synchronize)
  end
end

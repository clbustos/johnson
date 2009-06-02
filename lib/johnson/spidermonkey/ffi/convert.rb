module Johnson
  module SpiderMonkey

    module Convert

      class << self

        def convert_to_ruby(runtime, js_value)
          
          context = runtime.context
          
          js_value.root
          value = js_value.value

          if value == JSVAL_NULL
            js_value.unroot
            return nil
          end

          case SpiderMonkey.JS_TypeOfValue(context, value)
            
          when SpiderMonkey::JSTYPE_VOID
            js_value.unroot
            return nil

          when SpiderMonkey::JSTYPE_BOOLEAN
            js_value.unroot
            return value == SpiderMonkey::JSVAL_TRUE ? true : false

          when SpiderMonkey::JSTYPE_STRING
            js_value.unroot
            return to_ruby_string(runtime, value)
            
          when SpiderMonkey::JSTYPE_NUMBER
            if SpiderMonkey.JSVAL_IS_INT(value)
              js_value.unroot
              return to_ruby_fixnum_or_bignum(runtime, value)
            else
              js_value.unroot
              return to_ruby_float(runtime, value)
            end

          when SpiderMonkey::JSTYPE_OBJECT, SpiderMonkey::JSTYPE_FUNCTION

            if SpiderMonkey.OBJECT_TO_JSVAL(runtime.native_global) == value
              js_value.unroot
              return SpiderMonkey::RubyLandProxy.make(runtime, value, 'GlobalProxy')
            end  

            if JSLandProxy.js_value_is_proxy?(js_value)
              js_value.unroot
              return JSLandProxy.unwrap_js_land_proxy(runtime, js_value)
            end
            
            js_value.unroot
            return SpiderMonkey::RubyLandProxy.make(runtime, value, 'RubyLandProxy')

          end      

        end

        alias_method :to_ruby, :convert_to_ruby

        def convert_to_js(runtime, value)
          
          case value

          when NilClass
            SpiderMonkey::JSValue.new(runtime, JSVAL_NULL)

          when TrueClass
            SpiderMonkey::JSValue.new(runtime, JSVAL_TRUE)

          when FalseClass
            SpiderMonkey::JSValue.new(runtime, JSVAL_FALSE)

          when String
            SpiderMonkey::JSValue.new(runtime, convert_ruby_string_to_js(runtime, value))

          when Fixnum
            SpiderMonkey::JSValue.new(runtime, SpiderMonkey.INT_TO_JSVAL(value))

          when Float, Bignum
            SpiderMonkey::JSValue.new(runtime, convert_float_or_bignum_to_js(runtime, value))

          when Class, Hash, Module, File, Struct, Object, Array
            if value.kind_of?(SpiderMonkey::RubyLandProxy)
              value.proxy_js_value
            else
              SpiderMonkey::JSLandProxy.make(runtime, value)
            end
          else
            raise 'Unknown ruby type in switch'
          end

        end

        alias_method :to_js, :convert_to_js

        private

        def convert_ruby_string_to_js(runtime, value)
          js_string = SpiderMonkey.JS_NewStringCopyN(runtime.context, value, value.size)
          SpiderMonkey.STRING_TO_JSVAL(js_string)
        end

        def convert_float_or_bignum_to_js(runtime, value)
          retval = FFI::MemoryPointer.new(:long)
          SpiderMonkey.JS_NewNumberValue(runtime.context, value.to_f, retval)
          retval
        end

        def to_ruby_fixnum_or_bignum(runtime, value)
          SpiderMonkey.JSVAL_TO_INT(value)
        end

        def to_ruby_float(runtime, value)
          rvalue = FFI::MemoryPointer.new(:double)
          SpiderMonkey.JS_ValueToNumber(runtime.context, value, rvalue)
          rvalue.get_double(0)
        end

        def to_ruby_string(runtime, value)
          js_string = JSGCThing.new(runtime, SpiderMonkey.JSVAL_TO_STRING(value))
          js_string.root(binding)
          result = SpiderMonkey.JS_GetStringBytes(js_string)
          js_string.unroot
          result
        end

      end
    end
  end
end
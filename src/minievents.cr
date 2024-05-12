require "uuid"

module MiniEvents
  macro install(base_event_name = ::MiniEvents::Event)
    # Base class for events. NOT TO BE INHERITED BY ANYTHING UNLESS YOU REALLY NEED TO, use the `event` macro instead. HERE BE DRAGONS!
    abstract class {{base_event_name}}
      def initialize
        raise "Event should never be initialized!"
      end
    end

    {% for i in [0, 1] %}
      {% attach_name = (i == 0) ? "".id : "attach_".id %}
      # Creates a new event
      macro {{attach_name}}event(event_name, *args)
        \{% raise "event_name should be a Path" unless event_name.is_a? Path %}
        # Create our event class
        class \{{event_name}} < {{base_event_name}}

          # Callbacks tied to this event, all of them will be called when triggered
          @@callbacks = [] of \{{event_name}}::Callback

          # Types of the arguments for the event
          ARG_TYPES = {
            \{% for arg in args %}
              \{{arg.var.stringify}} => \{{(arg.type.is_a? Self) ? @type : arg.type}},
            \{% end %}
          } of String => Object.class

          # Adds the block to the callbacks
          def self.add_callback(&block : \{{event_name}}::CallbackProc)
            @@callbacks << \{{event_name}}::Callback.new(&block)
          end

          # Adds the block to the callbacks
          def self.add_callback(name : String, &block : \{{event_name}}::CallbackProc)
            @@callbacks << \{{event_name}}::Callback.new(name, &block)
          end

          def self.remove_callback(name : String)
            @@callbacks.reject!(&.name.==(name))
          end

          # Triggers all the callbacks
          def self.trigger(\{{args.map {|a| a.var}.splat}}) : Nil
            @@callbacks.each(&.call(\{{args.map {|a| a.var}.splat}}))
          end

          def self.clear_callbacks
            @@callbacks.clear
          end
        end

        # Alias for the callback.
        alias \{{event_name}}::CallbackProc = Proc(\{{(args.map {|arg| (arg.type.is_a? Self) ? @type : arg.type }).splat}}\{% if args.size > 0 %}, \{% end %}Nil)
        struct \{{event_name}}::Callback
          getter name : String = ""
          getter proc : CallbackProc
          getter? once = false

          def initialize(name : String? = nil, @once = false, &block : CallbackProc)
            if n = name
              @name = n 
            else
              @name = UUID.random.to_s
            end
            
            @proc = CallbackProc.new &block
          end

          def call(\{{args.map {|a| a.var}.splat}})
            proc.call(\{{args.map {|a| a.var}.splat}})
          end
        end
        {% if i == 1 %}
          _attach_self(\{{event_name}})
        {% end %}
      end
    {% end %}

    # Defines a global event callback
    macro on(event_name, &block)
      \{% raise "event_name should be a Path" unless event_name.is_a? Path %}

      \{% if args = parse_type("#{event_name}::ARG_TYPES").resolve? %}
        \{% raise "Incorrect arguments for block" unless block.args.size == args.size %}
      \{% end %}
      \{{event_name}}.add_callback do \{% if block.args.size > 0 %}|\{{block.args.splat}}|\{% end %}
        \{{ block.body }}
        nil
      end
    end

    # Defines a global event named callback
    macro on(name, event_name, &block)
      \{% raise "event_name should be a Path" unless event_name.is_a? Path %}

      \{% if args = parse_type("#{event_name}::ARG_TYPES").resolve? %}
        \{% raise "Incorrect arguments for block" unless block.args.size == args.size %}
      \{% end %}
      \{% raise "name cannot be empty" if name.empty? %}
      \{{event_name}}.add_callback(\{{name}}) do \{% if block.args.size > 0 %}|\{{block.args.splat}}|\{% end %}
        \{{ block.body }}
        nil
      end
    end

    # Emits a global event callback
    macro emit(event_name, *args)
      \{{event_name}}.trigger(\{{args.splat}})
    end

    macro _attach_self(event_name)
      \{% if args = parse_type("#{event_name}::ARG_TYPES").resolve? %}
        class \{{event_name}} < {{base_event_name}}
          # Triggers all the callbacks
          def self.trigger(\{{args.keys.map(&.id).splat}}) : Nil
            \{{args.keys[0].id}}.emit_\{{event_name.names.last.underscore}}(\{{args.keys[1..].map(&.id).splat}})

            @@callbacks.each(&.call(\{{args.keys.map(&.id).splat}}))
          end
        end


        alias \{{event_name}}::SelfCallbackProc = Proc(\{% if args.size > 1 %}\{{args.values[1..].splat}}, \{% end %}Nil)

        struct \{{event_name}}::Callback
          def initialize(&block : SelfCallbackProc)
            wrapped_block = \{{event_name}}::CallbackProc.new do |_\{% if args.size > 1 %},\{% end %} \{{args.keys[1..].map(&.id).splat}}|
              block.call(\{{args.keys[1..].map(&.id).splat}})
            end
            @proc = wrapped_block
          end
        end

        @%callbacks_\{{event_name.id.underscore}} = [] of \{{event_name}}::Callback

        def on_\{{event_name.names.last.underscore}}(&block : \{{event_name}}::SelfCallbackProc)
          @%callbacks_\{{event_name.id.underscore}} << \{{event_name}}::Callback.new(&block)
        end

        def on_\{{event_name.names.last.underscore}}(name : String, &block : \{{event_name}}::SelfCallbackProc)
          @%callbacks_\{{event_name.id.underscore}} << \{{event_name}}::Callback.new(name, &block)
        end

        def delete_\{{event_name.names.last.underscore}}(name : String)
          @%callbacks_\{{event_name.id.underscore}}.reject!(&.name.==(name))
        end

        def clear_\{{event_name.names.last.underscore}}()
          @%callbacks_\{{event_name.id.underscore}}.clear
        end

        \{% arg_types = [] of MacroId%}
        \{% args.each { |k,v| arg_types << "#{k.id} : #{v}".id }%}

        def emit_\{{event_name.names.last.underscore}}(\{{arg_types[1..].splat}})
          @%callbacks_\{{event_name.id.underscore}}.each(&.call(self\{% if args.size > 1 %},\{% end %}\{{args.keys[1..].map {|a| a.id }.splat}}))
        end
      \{% end %}
    end
  end
end
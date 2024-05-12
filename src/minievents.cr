module MiniEvents
  macro install(base_event_name = ::MiniEvents::Event)
    # Base class for events. NOT TO BE INHERITED BY ANYTHING UNLESS YOU REALLY NEED TO, use the `event` macro instead. HERE BE DRAGONS!
    abstract class {{base_event_name}}
      def initialize
        raise "Event should never be initialized!"
      end
    end

    # Creates a new event
    macro event(event_name, *args)

      \{% raise "event_name should be a Path" unless event_name.is_a? Path %}

      # Create our event class
      class \{{event_name}} < {{base_event_name}}

        # Callbacks tied to this event, all of them will be called when triggered
        @@callbacks = [] of \{{event_name}}::CallbackProc
        @@named_callbacks = {} of String => \{{event_name}}::CallbackProc

        # Types of the arguments for the event
        ARG_TYPES = {
          \{% for arg in args %}
            \{{arg.var.stringify}} => \{{(arg.type.is_a? Self) ? @type : arg.type}},
          \{% end %}
        } of String => Object.class

        # Adds the block to the callbacks
        def self.add_callback(&block : \{{event_name}}::CallbackProc)
          @@callbacks << block
        end

        # Adds the block to the callbacks
        def self.add_callback(name : String, &block : \{{event_name}}::CallbackProc)
          @@named_callbacks[name] = block
        end

        def self.remove_callback(name : String)
          @@named_callbacks.delete(name)
        end

        # Triggers all the callbacks
        def self.trigger(\{{args.map {|a| a.var}.splat}}) : Nil
          @@callbacks.each(&.call(\{{args.map {|a| a.var}.splat}}))
          @@named_callbacks.values.each(&.call(\{{args.map {|a| a.var}.splat}}))
        end

        def self.clear_callbacks
          @@callbacks.clear
          @@named_callbacks.clear
        end
      end

      # Alias for the callback.
      alias \{{event_name}}::CallbackProc = Proc(\{{(args.map {|arg| (arg.type.is_a? Self) ? @type : arg.type }).splat}}\{% if args.size > 0 %}, \{% end %}Nil)
      struct \{{event_name}}::Callback
        getter proc : CallbackProc
        getter? after_global = false

        def initialize(@after_global = false, &block : CallbackProc)
          @proc = CallbackProc.new &block
        end

        def call(\{{args.map {|a| a.var}.splat}})
          proc.call(\{{args.map {|a| a.var}.splat}})
        end
      end
    end

    # Includes an event to the classes instances
    macro attach(event_name)   
      \{% if args = parse_type("#{event_name}::ARG_TYPES").resolve? %}
        @%callbacks_\{{event_name.id.underscore}} = [] of \{{event_name}}::Callback
        @%named_callbacks_\{{event_name.id.underscore}} = {} of String => \{{event_name}}::Callback

        def on_\{{event_name.names.last.underscore}}(after_global = false, &block : \{{event_name}}::CallbackProc)
          @%callbacks_\{{event_name.id.underscore}} << \{{event_name}}::Callback.new(after_global, &block)
        end

        def on_\{{event_name.names.last.underscore}}(name : String, after_global = false, &block : \{{event_name}}::CallbackProc)
          @%named_callbacks_\{{event_name.id.underscore}}[name] = \{{event_name}}::Callback.new(after_global, &block)
        end

        def delete_\{{event_name.names.last.underscore}}(name : String)
          @%named_callbacks_\{{event_name.id.underscore}}.delete(name)
        end

        def clear_\{{event_name.names.last.underscore}}()
          @%callbacks_\{{event_name.id.underscore}}.clear
          @%named_callbacks_\{{event_name.id.underscore}}.clear
        end

        \{% arg_types = [] of MacroId%}
        \{% args.each { |k,v| arg_types << "#{k.id} : #{v}".id }%}

        def emit_\{{event_name.names.last.underscore}}(\\{{arg_types.splat}})
          # Call object specific callbacks before global
          @%callbacks_\{{event_name.id.underscore}}.select(&.after_global?.!).each(&.call(\{{args.keys.map {|a| a.id }.splat}}))
          @%named_callbacks_\{{event_name.id.underscore}}.values.select(&.after_global?.!).each(&.call(\{{args.keys.map {|a| a.id }.splat}}))

          # Call event callbacks 
          \{{event_name}}.trigger(\{{args.keys.map {|a| a.id }.splat}})

          # Call object specific callbacks after global
          @%callbacks_\{{event_name.id.underscore}}.select(&.after_global?).each(&.call(\{{args.keys.map {|a| a.id }.splat}}))
          @%named_callbacks_\{{event_name.id.underscore}}.values.select(&.after_global?).each(&.call(\{{args.keys.map {|a| a.id }.splat}}))
        end
      \{% else %}
        \{% raise "Path was unable to be resolved!" %}
      \{% end %}
    end

    # Includes an event to the classes instances but replaces the first argument with self
    macro attach_self(event_name)  
      \{% if args = parse_type("#{event_name}::ARG_TYPES").resolve? %}
        \{% raise "Cannot attach to self with zero arguments!" if args.size == 0 %}
        \{% raise "Self must be the first argument!" unless args.values[0].id == @type.id %}
        alias \{{event_name}}::SelfCallbackProc = Proc(\{{(args.size > 1) ? (args.values[1..].map {|arg| (arg.type.is_a? Self) ? @type : arg.type }).splat : "".id}}\{% if args.size > 1 %}, \{% end %}Nil)

        struct \{{event_name}}::Callback
          def initialize(@after_global = false, &block : SelfCallbackProc)
            wrapped_block = \{{event_name}}::CallbackProc.new do |_\{% if args.size > 1 %},\{% end %} \{{args.keys[1..].splat}}|
              block.call(\{{args.keys[1..].splat}})
            end
            @proc = wrapped_block
          end
        end

        @%callbacks_\{{event_name.id.underscore}} = [] of \{{event_name}}::Callback
        @%named_callbacks_\{{event_name.id.underscore}} = {} of String => \{{event_name}}::Callback

        def on_\{{event_name.names.last.underscore}}(after_global = false, &block : \{{event_name}}::SelfCallbackProc)
          @%callbacks_\{{event_name.id.underscore}} << \{{event_name}}::Callback.new(after_global, &block)
        end

        def on_\{{event_name.names.last.underscore}}(name : String, after_global = false, &block : \{{event_name}}::SelfCallbackProc)
          @%named_callbacks_\{{event_name.id.underscore}}[name] = \{{event_name}}::Callback.new(after_global, &block)
        end

        def delete_\{{event_name.names.last.underscore}}(name : String)
          @%named_callbacks_\{{event_name.id.underscore}}.delete(name)
        end

        def clear_\{{event_name.names.last.underscore}}()
          @%callbacks_\{{event_name.id.underscore}}.clear
          @%named_callbacks_\{{event_name.id.underscore}}.clear
        end

        \{% arg_types = [] of MacroId%}
        \{% args.each { |k,v| arg_types << "#{k.id} : #{v}".id }%}

        def emit_\{{event_name.names.last.underscore}}(\{{arg_types[1..].splat}})
          # Call object specific callbacks
          @%callbacks_\{{event_name.id.underscore}}.select(&.after_global?.!).each(&.call(self \{% if args.size > 1 %},\{% end %} \{{args.keys[1..].map {|a| a.id }.splat}}))
          @%named_callbacks_\{{event_name.id.underscore}}.values.select(&.after_global?.!).each(&.call(self \{% if args.size > 1 %},\{% end %} \{{args.keys[1..].map {|a| a.id }.splat}}))
          
          # Call event callbacks 
          \{{event_name}}.trigger(self, \\{{args.keys[1..].map {|a| a.id }.splat}})

          @%callbacks_\{{event_name.id.underscore}}.select(&.after_global?).each(&.call(self \{% if args.size > 1 %},\{% end %} \{{args.keys[1..].map {|a| a.id }.splat}}))
          @%named_callbacks_\{{event_name.id.underscore}}.values.select(&.after_global?).each(&.call(self \{% if args.size > 1 %},\{% end %} \{{args.keys[1..].map {|a| a.id }.splat}}))
        end
      \{% else %}
        \{% raise "Path was unable to be resolved!" %}
      \{% end %}
    end

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
  end
end
require "uuid"

module MiniEvents
  macro install(base_event_name = ::MiniEvents::Event)
    # Base class for events. NOT TO BE INHERITED BY ANYTHING UNLESS YOU REALLY NEED TO, use the `event` macro instead. HERE BE DRAGONS!
    abstract class {{base_event_name}}
      def initialize
        raise "Event should never be initialized!"
      end
    end

    # Creates a new event, attempts to bind itself to instances of a class if it's first argument is a self
    macro event(event_name, *args)
      _event(\{{event_name}}, \{{args.splat}})

      \{% if args.size > 0 && args[0].type.is_a?(Self) %}
        _attach_self(\{{event_name}})
      \{% end %}
    end

    # Creates a new event
    macro _event(event_name, *args)
      \{% raise "event_name should be a Path" unless event_name.is_a? Path %}

      # Create our event class
      class \{{event_name}} < {{base_event_name}}
        # Alias for the callback.
        alias CallbackProc = Proc(\{{(args.map {|arg| (arg.type.is_a? Self) ? @type : arg.type }).splat}}\{% if args.size > 0 %}, \{% end %}Nil)
        
        # Holds the callback information
        struct Callback
          # name of the proc
          getter name : String = ""
          # THe proc itself
          getter proc : CallbackProc
          # TODO: Use this
          # Should we only run this once?
          getter? once = false

          def initialize(name : String, @once = false, &block : CallbackProc)            
            @proc = CallbackProc.new &block
          end

          # Calls our proc with the arguments
          def call(\{{args.map {|a| a.var}.splat}})
            @proc.call(\{{args.map {|a| a.var}.splat}})
          end
        end

        # Callbacks tied to this event, all of them will be called when triggered
        @@callbacks = [] of Callback

        # Types of the arguments for the callback event
        ARG_TYPES = {
          \{% for arg in args %}
            \{{arg.var.stringify}} => \{{(arg.type.is_a? Self) ? @type : arg.type}},
          \{% end %}
        } of String => Object.class

        # Adds the block to the callbacks
        def self.add_callback(once = false, &block : CallbackProc)
          name = UUID.random.to_s
          @@callbacks << Callback.new(name, once) do \{% if args.size > 0 %}|\{{args.map { |a| a.var }.splat}}|\{% end %}
            block.call(\{{args.map { |a| a.var }.splat}})

            if once
              remove_callback name
            end
          end
        end

        # Adds the named block to the callbacks
        def self.add_callback(name : String, once = false, &block : CallbackProc)
          @@callbacks << \{{event_name}}::Callback.new(name, once) do \{% if args.size > 0 %}|\{{args.map { |a| a.var }.splat}}|\{% end %}
            block.call(\{{args.map { |a| a.var }.splat}})

            if once
              remove_callback name
            end
          end
        end

        # Removes a named block
        def self.remove_callback(name : String)
          @@callbacks.reject!(&.name.==(name))
        end

        # Triggers all the callbacks
        def self.trigger(\{{args.map {|a| a.var}.splat}}) : Nil
          @@callbacks.each(&.call(\{{args.map {|a| a.var}.splat}}))
        end

        # Clears all the callbacks
        def self.clear_callbacks
          @@callbacks.clear
        end
      end
    end

    # Defines a global event callback
    macro on(event_name, once = false, &block)
      \{% raise "event_name should be a Path" unless event_name.is_a? Path %}

      \{% if args = parse_type("#{event_name}::ARG_TYPES").resolve? %}
        \{% raise "Incorrect arguments for block" unless block.args.size == args.size %}
      \{% end %}
      \{{event_name}}.add_callback(once: \{{once}}) do \{% if block.args.size > 0 %}|\{{block.args.splat}}|\{% end %}
        \{{ block.body }}
        nil
      end
    end

    # Defines a global event named callback
    macro on(event_name, name, once = false, &block)
      \{% raise "event_name should be a Path" unless event_name.is_a? Path %}

      \{% if args = parse_type("#{event_name}::ARG_TYPES").resolve? %}
        \{% raise "Incorrect arguments for block" unless block.args.size == args.size %}
      \{% end %}
      \{% raise "name cannot be empty" if name.empty? %}
      \{{event_name}}.add_callback(\{{name}}, once: \{{once}}) do \{% if block.args.size > 0 %}|\{{block.args.splat}}|\{% end %}
        \{{ block.body }}
        nil
      end
    end

    # Emits a global event callback
    macro emit(event_name, *args)
      \{{event_name}}.trigger(\{{args.splat}})
    end

    # Attaches this event to the class its run under
    macro _attach_self(event_name)
      #TODO: Do check to make sure @type isnt a struct
      \{% if args = parse_type("#{event_name}::ARG_TYPES").resolve? %}
        class \{{event_name}} < {{base_event_name}}
          alias SelfCallbackProc = Proc(\{% if args.size > 1 %}\{{args.values[1..].splat}}, \{% end %}Nil)

          struct SelfCallback
            # name of the proc
            getter name : String
            # THe proc itself
            getter proc : SelfCallbackProc
            # TODO: Use this
            # Should we only run this once?
            getter? once = false

            def initialize(@name : String, @once = false, &block : SelfCallbackProc)
              @proc = block
            end
            

            # Calls our proc with the arguments
            def call(\{{args.keys[1..].map {|a| a.id}.splat}})
              @proc.call(\{{args.keys[1..].map {|a| a.id}.splat}})
            end
          end

          # Triggers all the callbacks
          def self.trigger(\{{args.keys.map(&.id).splat}}) : Nil
            \{{args.keys[0].id}}.run_\{{event_name.names.last.underscore}}(\{{args.keys[1..].map(&.id).splat}})

            @@callbacks.each(&.call(\{{args.keys.map(&.id).splat}}))
          end
        end

        @%callbacks_\{{event_name.id.underscore}} = [] of \{{event_name}}::SelfCallback

        def on_\{{event_name.names.last.underscore}}(once = false, &block : \{{event_name}}::SelfCallbackProc)
          name = UUID.random.to_s
          @%callbacks_\{{event_name.id.underscore}} << \{{event_name}}::SelfCallback.new(name, once: once) do \{% if args.size > 1 %}|\{{args.keys[1..].map { |a| a.id }.splat}}|\{% end %}
            block.call(\{{args.keys[1..].map { |a| a.id }.splat}})

            if once
              remove_\{{event_name.names.last.underscore}} name
            end
          end
        end

        def on_\{{event_name.names.last.underscore}}(name : String, once = false, &block : \{{event_name}}::SelfCallbackProc)
          @%callbacks_\{{event_name.id.underscore}} << \{{event_name}}::SelfCallback.new(name, once: once) do \{% if args.size > 1 %}|\{{args.keys[1..].map { |a| a.id }.splat}}|\{% end %}
            block.call(\{{args.keys[1..].map { |a| a.id }.splat}})

            if once
              remove_\{{event_name.names.last.underscore}} name
            end
          end
        end

        def remove_\{{event_name.names.last.underscore}}(name : String)
          @%callbacks_\{{event_name.id.underscore}}.reject! {|cb| cb.name == name}
        end

        def clear_\{{event_name.names.last.underscore}}()
          @%callbacks_\{{event_name.id.underscore}}.clear
        end

        \{% arg_types = [] of MacroId%}
        \{% args.each { |k,v| arg_types << "#{k.id} : #{v}".id }%}

        def run_\{{event_name.names.last.underscore}}(\{{arg_types[1..].splat}})
          @%callbacks_\{{event_name.id.underscore}}.each(&.call(\{{args.keys[1..].map {|a| a.id }.splat}}))
        end
      \{% end %}
    end
  end
end
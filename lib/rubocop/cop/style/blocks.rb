# encoding: utf-8

module RuboCop
  module Cop
    module Style
      # Check for uses of braces or do/end around blocks.
      class Blocks < Cop
        include AutocorrectUnlessChangingAST
        include ConfigurableEnforcedStyle

        MULTI_LINE_MSG = 'Avoid using {...} for multi-line blocks.'
        SINGLE_LINE_MSG = 'Prefer {...} over do...end for single-line blocks.'
        RETURN_VALUE_MSG = 'Prefer {...} over do...end for return value blocks.'
        SIDE_EFFECTS_MSG = 'Prefer do...end over {...} for side effects blocks.'

        def on_send(node)
          _receiver, method_name, *args = *node
          return unless args.any?

          block = get_block(args.last)
          return unless block && !parentheses?(node) && !operator?(method_name)

          # If there are no parentheses around the arguments, then braces and
          # do-end have different meaning due to how they bind, so we allow
          # either.
          ignore_node(block)
        end

        def on_block(node)
          return if ignored_node?(node)

          block_begin = node.loc.begin.source

          case style
          when :single_braces_multi_do_end
            block_length = Util.block_length(node)

            if block_length > 0 && block_begin == '{'
              add_offense(node, :begin, MULTI_LINE_MSG)
            elsif block_length == 0 && block_begin != '{'
              add_offense(node, :begin, SINGLE_LINE_MSG)
            end
          when :weirich_semantic
            return_value_block = return_value_block?(node)

            if return_value_block && block_begin != '{'
              add_offense(node, :begin, RETURN_VALUE_MSG)
            elsif !return_value_block && block_begin == '{'
              add_offense(node, :begin, SIDE_EFFECTS_MSG)
            end
          end
        end

        private

        def correction(node)
          case style
          when :single_braces_multi_do_end
            lambda do |corrector|
              b, e = node.loc.begin, node.loc.end
              if b.is?('{')
                # If the left brace is immediately preceded by a word character,
                # then we need a space before `do` to get valid Ruby code.
                if b.source_buffer.source[b.begin_pos - 1, 1] =~ /\w/
                  corrector.insert_before(b, ' ')
                end
                corrector.replace(b, 'do')
                corrector.replace(e, 'end')
              else
                corrector.replace(b, '{')
                corrector.replace(e, '}')
              end
            end
          end
        end

        def get_block(node)
          case node.type
          when :block
            node
          when :send
            receiver, _method_name, *_args = *node
            get_block(receiver) if receiver
          end
        end

        def parentheses?(send_node)
          send_node.loc.begin
        end

        def operator?(method_name)
          method_name =~ /^\W/
        end

        def return_value_block?(node)
          chained = node.parent && node.parent.type == :send
          enum_return_value_methods = [
            :sort,
            :sort_by,
            :grep,
            :count,
            :find,
            :detect,
            :find_index,
            :find_all,
            :select,
            :reject,
            :collect,
            :map,
            :flat_map,
            :collect_concat,
            :inject,
            :reduce,
            :partition,
            :group_by,
            :all?,
            :any?,
            :one?,
            :none?,
            :min,
            :max,
            :minmax,
            :min_by,
            :max_by,
            :minmax_by,
            :zip,
            :take_while,
            :drop_while,
            :chunk,
            :slice_before,
            :slice_after,
            :slice_when,
            :drop_last
          ]
          enum_return_value_block = enum_return_value_methods.include?(node.children.first.children.last)
          chained || enum_return_value_block
        end
      end
    end
  end
end

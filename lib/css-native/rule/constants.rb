class CSSNative
  class Rule
    private

    COMBINATORS = {
      descendant: " ",
      child: " > ",
      sibling: " + ",
      adjacent: " + ",
      column: " || "
    }
    
    # pseudo-classes
    # name of value is pseudo-class, array values are acceptad options
    #   Equality is compared by <option> === <value>, allowing 
    #   classes to test for instances or regex matching
    # If array is empty, there's no limitations (in the code, foraml CSS may differ)
    # If array is nil, it takes no options
    PSEUDO_CLASSES = {
      # Linguistic
      dir: ["ltr", "rtl"],
      lang: [],
      # Location
      "any_link": nil,
      link: nil,
      visited: nil,
      "local_link": nil,
      target: nil,
      "target_within": nil,
      scope: nil,
      # User action
      hover: nil,
      active: nil,
      focus: nil,
      "focus_visible": nil,
      "focus_within": nil,
      # Time_dimensional _ ill_defined
      current: nil,
      past: nil,
      future: nil,
      # Resource state
      playing: nil,
      paused: nil,
      # Input
      enabled: nil,
      disabled: nil,
      "read_only": nil,
      "read_write": nil,
      "placeholder_shown": nil,
      default: nil,
      checked: nil,
      indeterminate: nil,
      blank: nil,
      valid: nil,
      invalid: nil,
      "in_range": nil,
      "out_of_range": nil,
      required: nil,
      optional: nil,
      "user_invalid": nil,
      root: nil,
      empty: nil,
      "nth_child": ["odd", "even", /^\d+(n(\s*\+\s*\d+)?)?$/],
      "nth_last_child": ["odd", "even", /^\d+(n(\s*\+\s*\d+)?)?$/],
      "first_child": nil,
      "last_child": nil,
      "only_child": nil,
      "nth_of_type": ["odd", "even", /^\d+(n(\s*\+\s*\d+)?)?$/],
      "nth_last_of_type": ["odd", "even", /^\d+(n(\s*\+\s*\d+)?)?$/],
      "first_of_type": nil,
      "last_of_type": nil,
      "only_of_type": nil,
    }

    # pseudo-elements
    # definition semantics same as pseudo-classes
    PSEUDO_ELEMENTS = {
      after: nil,
      before: nil,
      backdrop: nil,
      cue: nil,
      "cue_region": nil,
      "first_letter": nil,
      "first_line": nil,
      "file_selector_button": nil,
      "grammar_error": nil,
      marker: nil,
      part: [/[-a-zA-Z]+( [-a-zA-Z]+)?/],
      placeholder: nil,
      selection: nil,
      slotted: [],
      "spelling_error": nil,
      "target_text": nil,
    }
  end
end

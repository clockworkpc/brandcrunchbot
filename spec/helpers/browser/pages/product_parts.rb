module Browser
  module Pages
    class ProductParts
      DOOR_TOP_RAIL_SALVADOR_FORMULA = <<~HEREDOC
        ,1, 1, 0, 0,{{this_part.Length}}, {{this_part.Qty}},,1,,,{{this_part.Length}}_{{this_part.Width}}_{{stile_rail.name}}_R_{{order_num}}_{{group_id}}{{line_num}}//{{order_num}}{{group_id}}{{line_num}}3,{{this_part.Width}},{{group_id}}{{line_num}},R
      HEREDOC

      DOOR_BOTTOM_RAIL_SALVADOR_FORMULA = <<~HEREDOC
        ,1, 1, 0, 0,{{this_part.Length}}, {{this_part.Qty}},,1,,,{{this_part.Length}}_{{this_part.Width}}_{{stile_rail.name}}_R_{{order_num}}_{{group_id}}{{line_num}}//{{order_num}}{{group_id}}{{line_num}}4,{{this_part.Width}},{{group_id}}{{line_num}},R
      HEREDOC

      DOOR_LEFT_STILE_SALVADOR_FORMULA = <<~HEREDOC
        ,1, 1, 0, 0,{{this_part.Length}}, {{this_part.Qty}},,2,,,{{this_part.Length}}_{{this_part.Width}}_{{stile_rail.name}}_S_{{order_num}}_{{group_id}}{{line_num}}//{{order_num}}{{group_id}}{{line_num}}1,{{this_part.Width}},{{group_id}}{{line_num}},S
      HEREDOC

      DOOR_RIGHT_STILE_SALVADOR_FORMULA = <<~HEREDOC
        ,1, 1, 0, 0,{{this_part.Length}}, {{this_part.Qty}},,2,,,{{this_part.Length}}_{{this_part.Width}}_{{stile_rail.name}}_S_{{order_num}}_{{group_id}}{{line_num}}//{{order_num}}{{group_id}}{{line_num}}2,{{this_part.Width}},{{group_id}}{{line_num}},S
      HEREDOC

      DOOR_HORIZONTAL_MID_RAIL_SALVADOR_FORMULA = <<~HEREDOC
        ,1, 1, 0, 0,{{this_part.Length}}, {{this_part.Qty}},,3,,,{{this_part.Length}}_{{this_part.Width}}_{{stile_rail.name}}_MR_{{order_num}}_{{group_id}}{{line_num}}//{{order_num}}{{group_id}}{{line_num}}6,{{this_part.Width}},{{group_id}}{{line_num}},MR
      HEREDOC

      DOOR_VERTICAL_MID_RAIL_SALVADOR_FORMULA = <<~HEREDOC
        ,1, 1, 0, 0,{{this_part.Length}}, {{this_part.Qty}},,3,,,{{this_part.Length}}_{{this_part.Width}}_{{stile_rail.name}}_MS_{{order_num}}_{{group_id}}{{line_num}}//{{order_num}}{{group_id}}{{line_num}}5,{{this_part.Width}},{{group_id}}{{line_num}},MS
      HEREDOC
    end
  end
end

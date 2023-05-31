class ProjectReportService
  DOOR_ATTRIBUTES = %w[
    1_4_wood_veneer
    applied_moulding
    batton_and_applied_door_turn_around_time
    bottom_rail_width
    cabinet_door_hinge_drilling
    comments
    door_finish
    door_style
    double_width
    drawer_front_sizing
    edges
    finger_pull
    finish_color
    finish_sheen
    foam
    hidden_1
    hidden_2_
    hidden_3
    hidden_4
    hidden_5
    hidden_6
    hidden_7
    hidden_8
    hidden_9
    hinge_drilling_edge_distance_
    left_stile_width
    miter_stile_and_rail_profiles
    mullion_pattern_type
    panel_face_style
    panel_profiles
    right_stile_width
    route_for_retainer
    side_by_side_width
    solid_panel_wood_type
    stile_rail
    top_rail_width
    valance_rise
    valance_shoulder
    wood_type
  ].freeze

  DRAWER_ATTRIBUTES = %w[
    blum_clips
    bottom_material
    bottom_placement
    comments
    comments_box
    drawer_box_logo
    drawer_dividers
    drawer_front_boring
    drawer_front_material
    drawer_options
    drawer_scooped_front
    drawer_tabs
    drawers_swooped_sides
    finish
    side_material
    specialty
    top_edge_detail
    undermount_notching
  ].freeze

  SLAB_ATTRIBUTES = %w[
    cabinet_door_hinge_drilling
    comments
    door_finish
    drawer_front_sizing
    edges
    finger_pull
    finish_color
    finish_sheen
    grain_match
    hidden_1
    hidden_10
    hidden_11
    hidden_2_
    hidden_3
    hidden_4
    hidden_5
    hidden_6
    hidden_7
    hidden_8
    hidden_9
    hinge_drilling_edge_distance_
    panel_face_style
    specialty
    wood_type
    wood_type_thick_doors
  ].freeze

  # PRODUCT_NAMES = %w[

  # ]

  SPECIALTY_ATTRIBUTES = %w[
    cabinet_door_hinge_drilling
    comments
    door_finish
    edge_banding_thickness
    edges
    endpanel_material
    finish_color
    finish_sheen
    grain_match
    hidden_1
    hidden_10
    hidden_11
    hidden_2_
    hidden_3
    hidden_4
    hidden_5
    hidden_6
    hidden_7
    hidden_8
    hidden_9
    hinge_drilling_edge_distance_
    material_butcherblock
    panel_face_material
    panel_face_width
    plywood
    specialty
    thickness_butcher
    toekick_height
    width_filler_strip
    wood_type
    wood_type_toekick
  ].freeze

  def door_headers
    DOOR_ATTRIBUTES.map(&:upcase).join("\t")
  end

  def drawer_headers
    DRAWER_ATTRIBUTES.map(&:upcase).join("\t")
  end

  def slab_headers
    SLAB_ATTRIBUTES.map(&:upcase).join("\t")
  end

  def specialty_headers
    SPECIALTY_ATTRIBUTES.map(&:upcase).join("\t")
  end
end

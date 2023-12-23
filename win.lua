.win. = .module. ".win."
.win...float. = .module. ".win...float."
.win...id. = .module. ".win...id."
.win...id...float. = .module. ".win...id...float."

.function. .win...vimsize.()
  .local. .scratch. = .vim...api...nvim_create_buf.(.false., .true.)

  .vim...api...nvim_buf_call.(.scratch., .function.()
    .vim...cmd. ".tabnew."
    .local. .tabpage. = .vim...fn...tabpagenr.()
    .width. = .vim...fn...winwidth.(.0.)
    .height. = .vim...fn...winheight.(.0.)
    .vim...cmd.(".tabclose. " .. .tabpage.)
  .end.)

  .vim...cmd.(":.bwipeout.! " .. .scratch.)

  .return. { .width., .height. }
.end.

.local. .function. .default_winnr.()
  .return. .vim...fn...bufwinnr.(.vim...fn...bufnr.())
.end.

.function. .win...exists.(.winnr.)
  .local. .ok. =
    .vim...api...nvim_win_is_valid.(.win...nr2id.(.winnr.) .or. -.1.)
  .if. .not. .ok. .then.
    .return.
  .end.
  .return. .winnr.
.end.

.function. .win...nr2id.(.winnr.)
  .local. .id. = .vim...fn...win_getid.(.winnr. .or. .default_winnr.())

  .if. .id. == .0. .then.
    .return.
  .end.

  .return. .id.
.end.

.function. .win...id2nr.(.id.)
  .local. .winnr. = .vim...fn...win_id2win.(.id. .or. .win...nr2id.())

  .if. .winnr. == .0. .then.
    .return.
  .end.

  .return. .winnr.
.end.

.function. .win...winnr.(.expr.)
  .if. .expr. == .nil. .then.
    .return. .vim...fn...winnr.()
  .end.
  .return. .vim...fn...winnr.(.expr.)
.end.

.function. .win...current.()
  .return. .default_winnr.()
.end.

.function. .win...current_id.()
  .return. .win...nr2id.(.win...current.())
.end.

.function. .win...height.(.winnr.)
  .winnr. = .winnr. .or. .win...current.()
  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .end.
  .return. .vim...fn...winheight.(.winnr.)
.end.

.function. .win...width.(.winnr.)
  .winnr. = .winnr. .or. .win...current.()
  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .end.
  .return. .vim...fn...winwidth.(.winnr.)
.end.

.function. .win...size.(.winnr.)
  .local. .width., .height. = .win...width.(.winnr.), .win...height.(.winnr.)

  .if. .not. .width. .or. .not. .height. .then.
    .return.
  .end.

  .return. { .width., .height. }
.end.

.function. .win...var.(.winnr., .var.)
  .winnr. = .winnr. .or. .win...winnr.()

  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .end.

  .local. .ok., .msg. =
    .pcall.(.vim...api...nvim_win_get_var., .win...nr2id.(.winnr.), .var.)

  .if. .not. .ok. .then.
    .return. .false., .msg.
  .end.

  .return. .ok.
.end.

.function. .win...option.(.winnr., .opt.)
  .winnr. = .winnr. .or. .win...winnr.()

  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .end.

  .local. .ok., .msg. = .pcall.(
    .vim...api...nvim_win_get_option.,
    .win...nr2id.(.winnr.),
    .opt.
  )

  .if. .not. .ok. .then.
    .return. .false., .msg.
  .end.

  .return. .ok., .msg.
.end.

.function. .win...del_var.(.winnr., .var.)
  .winnr. = .winnr. .or. .win...current.()

  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .end.

  .local. .ok., .msg. =
    .pcall.(.vim...api...nvim_win_del_var., .winnr., .var.)

  .if. .not. .ok. .then.
    .return. .false., .msg.
  .end.

  .return. .true.
.end.

.function. .win...tabnr.(.winnr.)
  .winnr. = .winnr. .or. .win...current.()
  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .end.

  .return. .vim...api...nvim_win_get_tabpage.(.winnr.)
.end.

.function. .win...call.(.winnr., .f.)
  .winnr. = .winnr. .or. .win...current.()

  .if. .not. .winnr. .then.
    .return.
  .end.
  .return. .vim...api...nvim_win_call.(.win...nr2id.(.winnr.), .f.)
.end.

.function. .win...pos.(.winnr., .expr.)
  .winnr. = .winnr. .or. .win...current.()

  .return. .win...call.(.winnr., .function.()
    .local. .pos. = .vim...fn...getpos.(.expr. .or. ".")
    .return. {
      .bufnr. = .vim...fn...bufnr.(),
      .winnr. = .winnr.,
      .winid. = .win...nr2id.(.winnr.),
      .row. = .pos.[.2.],
      .col. = .pos.[.3.],
      .offset. = .pos.[.4.],
    }
  .end.)
.end.

.function. .win...restore_cmd.(.winnr.)
  .return. .win...call.(.winnr., .function.()
    .return. .vim...fn...winrestcmd.()
  .end.)
.end.

.function. .win...restore_view.(.winnr., .view.)
  .return. .win...call.(.winnr., .function.()
    .if. .is_a...string.(.view.) .then.
      .vim...cmd.(.view.)
    .else.
      .vim...fn...winrestview.(.view.)
    .end.

    .return. .true.
  .end.)
.end.

.function. .win...save_view.(.winnr.)
  .return. .win...call.(.winnr., .function.()
    .return. .vim...fn...winsaveview.()
  .end.)
.end.

.function. .win...current_line.(.winnr.)
  .return. .win...call.(.winnr., .function.()
    .return. .vim...fn...winline.()
  .end.)
.end.

.function. .win...layouts.(.tab.)
  .local. .out.
  .if. .tab. == .nil. .then.
    .out. = .vim...fn...winlayout.()
  .else.
    .out. = .vim...fn...winlayout.(.tab.)
  .end.

  .if. #.out. == .0. .then.
    .return.
  .end.
  .return. .out.
.end.

.function. .win...virtualcol.(.winnr.)
  .return. .win...call.(.winnr., .function.()
    .return. .vim...fn...wincol.()
  .end.)
.end.

.function. .win...bufnr.(.winnr.)
  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .end.
  .return. .vim...fn...winbufnr.(.winnr.)
.end.

.function. .win...move.(.from_winnr., .to_winnr., .opts.)
  .from_winnr. = .from_winnr. .or. .win...current.()

  .if. .not. .win...exists.(.from_winnr.) .then.
    .return.
  .end.
  .if. .not. .win...exists.(.to_winnr.) .then.
    .return.
  .end.

  .vim...fn...win_splitmove.(
    .from_winnr.,
    .to_winnr.,
    .opts. .or. { .right. = .true. }
  )

  .return. .true.
.end.

.function. .win...screen_pos.(.winnr.)
  .winnr. = .winnr. .or. .win...current.()

  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .end.

  .return. .vim...fn...win_screen_pos.(.winnr.)
.end.

.function. .win...move_statusline.(.winnr., .offset.)
  .return. .vim...fn...win_move_statusline.(.winnr., .offset.) ~= .0.
.end.

.function. .win...move_separator.(.winnr., .offset.)
  .return. .vim...fn...win_move_separator.(.winnr., .offset.) ~= .0.
.end.

.function. .win...tabwin.(.winnr.)
  .local. .out. = .vim...fn...win_id2tabwin.(.win...nr2id.(.winnr.))
  .if. .out.[.1.] == .0. .and. .out.[.2.] == .0. .then.
    .return.
  .end.

  .return. .out.
.end.

.function. .win...id...goto.(.id.)
  .return. .vim...fn...win_gotoid.(.id.) ~= .0.
.end.

.function. .win...split.(.winnr., .direction.)
  .winnr. = .winnr. .or. .win...current.()
  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .end.

  .local. .bufnr. = .win...bufnr.(.winnr.)
  .direction. = .direction. .or. ".s."

  .local. .function. .cmd.(.s.)
    .s. = .s. .. " | .b. " .. .bufnr.
    .vim...cmd.(.s.)
  .end.

  .if. .direction.:.match_any.("^.v.$", "^.vsplit.$") .then.
    .cmd. ":.vsplit."
  .elseif. .string...match_any.(.direction., "^.s.$", "^.split.$") .then.
    .cmd. ":.split."
  .elseif. .direction.:.match. ".botright." .then.
    .cmd.(.direction.)
  .elseif. .direction.:.match. ".topleft." .then.
    .cmd.(.direction.)
  .elseif. .direction.:.match_any.(".aboveleft.", ".leftabove.") .then.
    .cmd.(.direction.)
  .elseif.
    .direction.:.match_any.(".belowright.", ".rightbelow.")
  .then.
    .cmd.(.direction.)
  .elseif.
    .direction. == ".tabnew."
    .or. .direction. == ".t."
    .or. .direction. == ".tab."
  .then.
    .cmd. ":.tabnew."
  .end.

  .return. .true.
.end.

.function. .win...botright_vsplit.(.winnr.)
  .return. .win...split_vsplit.(.winnr., ".botright. .vsplit.")
.end.

.function. .win...topleft_vsplit.(.winnr.)
  .return. .win...split_vsplit.(.winnr., ".topleft. .vsplit.")
.end.

.function. .win...rightbelow_vsplit.(.winnr.)
  .return. .win...split_vsplit.(.winnr., ".belowright. .vsplit.")
.end.

.function. .win...leftabove_vsplit.(.winnr.)
  .return. .win...split_vsplit.(.winnr., ".aboveleft. .vsplit.")
.end.

.function. .win...belowright_vsplit.(.winnr.)
  .return. .win...split_vsplit.(.winnr., ".belowright. .vsplit.")
.end.

.function. .win...aboveleft_vsplit.(.winnr.)
  .return. .win...split_vsplit.(.winnr., ".aboveleft. .vsplit.")
.end.

.function. .win...botright.(.winnr.)
  .return. .win...split.(.winnr., ".botright. .split.")
.end.

.function. .win...topleft.(.winnr.)
  .return. .win...split.(.winnr., ".topleft. .split.")
.end.

.function. .win...rightbelow.(.winnr.)
  .return. .win...split.(.winnr., ".belowright. .split.")
.end.

.function. .win...leftabove.(.winnr.)
  .return. .win...split.(.winnr., ".aboveleft. .split.")
.end.

.function. .win...belowright.(.winnr.)
  .return. .win...split.(.winnr., ".belowright. .split.")
.end.

.function. .win...aboveleft.(.winnr.)
  .return. .win...split.(.winnr., ".aboveleft. .split.")
.end.

.function. .win...tabnew.(.winnr.)
  .return. .win...split.(.winnr., ".t.")
.end.

.function. .win...vsplit.(.winnr.)
  .return. .win...split.(.winnr., ".v.")
.end.

.function. .win...type.(.winnr.)
  .winnr. = .winnr. .or. .win...current.()
  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .end.

  .return. .vim...fn...win_gettype.(.winnr.)
.end.

.function. .win...col.(.winnr., .expr.)
  .return. .win...call.(.winnr., .function.()
    .expr. = .expr. .or. "."
    .return. .vim...fn...col.(.expr.)
  .end.)
.end.

.function. .win...row.(.winnr., .expr.)
  .return. .win...call.(.winnr., .function.()
    .expr. = .expr. .or. "."
    .return. .vim...fn...line.(.expr.)
  .end.)
.end.

.function. .win...cursor_pos.(.winnr.)
  .local. .row. = .win...row.(.winnr.)
  .local. .col. = .win...col.(.winnr.)
  .if. .not. .row. .or. .not. .col. .then.
    .return.
  .end.

  .return. { .row., .col. }
.end.

.function. .win...range.(.winnr.)
  .return. .win...call.(.winnr. .or. .win...current.(), .function.()
    .if. .vim...fn...mode.() == ".v." .then.
      .vim...cmd. ".normal.! "
    .end.

    .local. ._., .csrow., .cscol., ._. = .unpack.(.vim...fn...getpos. "'<")
    .local. ._., .cerow., .cecol., ._. = .unpack.(.vim...fn...getpos. "'>")

    .if. .csrow. > .cerow. .or. .cscol. > .cecol. .then.
      .return.
    .end.

    .return. { .row. = { .csrow., .cerow. }, .col. = { .cscol., .cecol. } }
  .end.)
.end.

.local. .function. .range_text.(.buf., ...)
  .local. .args. = { ... }
  .args. = .map.(.args., .function.(.x.)
    .return. .x. - .1.
  .end.)
  .args.[#.args. + .1.] = {}

  .return. .vim...api...nvim_buf_get_text.(.buf., .unpack.(.args.))
.end.

.function. .win...range_text.(.winnr.)
  .winnr. = .winnr. .or. .win...current.()
  .local. .range. = .win...range.(.winnr.)
  .if. .not. .range. .then.
    .return.
  .end.

  .local. .csrow., .cerow. = .unpack.(.range...row.)
  .local. .cscol., .cecol. = .unpack.(.range...col.)
  .local. .buf. = .win...bufnr.(.winnr.)

  .return. .range_text.(.buf., .csrow., .cscol., .cerow., .cecol.)
.end.

.function. .win...is_visible.(.winnr.)
  .return. .win...nr2id.(.winnr.)
.end.

.function. .win...id...is_visible.(.winid.)
  .return. .win...is_visible.(.win...id2nr.(.winid.))
.end.

.function. .win...id...hide.(.winid.)
  .if. .not. .win...id...is_visible.(.winid.) .then.
    .return.
  .end.

  .vim...api...nvim_win_hide.(.winid.)
  .return. .true.
.end.

.function. .win...id...close.(.winid., .force.)
  .if. .not. .win...id...is_visible.(.winid.) .then.
    .return.
  .end.

  .if. .not. .force. .then.
    .vim...api...nvim_win_close.(.winid., .false.)
  .else.
    .vim...api...nvim_win_close.(.winid., .true.)
  .end.

  .return. .true.
.end.

.function. .win...set_height.(.winnr., .height.)
  .winnr. = .winnr. .or. .win...current.()
  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .end.

  .vim...api...nvim_win_set_height.(.win...nr2id.(.winnr.), .height.)
  .return. .true.
.end.

.function. .win...set_width.(.winnr., .width.)
  .winnr. = .winnr. .or. .win...current.()
  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .end.

  .vim...api...nvim_win_set_width.(.win...nr2id.(.winnr.), .width.)
  .return. .true.
.end.

.function. .win...info.(.winnr.)
  .if. .not. .win...exists.(.bufnr.) .then.
    .return.
  .end.
  .return. .vim...fn...getwininfo.(.win...nr2id.(.winnr.))
.end.

.function. .win...set_var.(.winnr., .k., .v.)
  .validate. {
    .key. = { .union.(".string.", ".dict."), .k. },
  }

  .winnr. = .winnr. .or. .win...winnr.()
  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .end.

  .if. .is_a...string.(.k.) .then.
    .vim...api...nvim_win_set_var.(.winnr., .k., .v.)
  .else.
    .each.(.k., .function.(.key., .value.)
      .win...set_var.(.winnr., .key., .value.)
    .end.)
  .end.

  .return. .true.
.end.

.function. .win...set_option.(.winnr., .k., .v.)
  .validate. {
    .key. = { .union.(".string.", ".dict."), .k. },
  }

  .winnr. = .winnr. .or. .win...winnr.()
  .if. .not. .win...is_visible.(.winnr.) .then.
    .return.
  .end.

  .if. .is_a...string.(.k.) .then.
    .vim...api...nvim_win_set_option.(.win...nr2id.(.winnr.), .k., .v.)
  .else.
    .each.(.k., .function.(.key., .value.)
      .win...set_option.(.winnr., .key., .value.)
    .end.)
  .end.

  .return. .true.
.end.

.function. .win...scroll.(.winnr., .direction., .lines.)
  .winnr. = .winnr. .or. .win...current.()
  .if. .not. .win...exists.(.winnr.) .then.
    .return. .false.
  .end.

  .if. .direction. == "+" .then.
    .keys. = .lines. .. "\\<.C.-.e.>"
  .else.
    .keys. = .lines. .. "\\<.C.-.y.>"
  .end.

  .winnr...call.(.winnr., .function.()
    .vim...cmd.(.sprintf.(':.call. .feedkeys.("%.s.")', .keys.))
  .end.)

  .return. .true.
.end.

--------------------------------------------------
.local. .function. .from_percent.(.current., .width., .min.)
  .current. = .current. .or. .vim...fn...winwidth.(.0.)
  .width. = .width. .or. .0...5.

  .assert.(.width. ~= .0., ".width. .cannot. .be. .0.")
  .assert.(.width. > .0., ".width. .cannot. .be. < .0.")

  .if. .width. < .1. .then.
    .required. = .math...floor.(.current. * .width.)
  .else.
    .return. .width.
  .end.

  .if. .min. < .1. .then.
    .min. = .math...floor.(.current. * .min.)
  .else.
    .min. = .math...floor.(.min.)
  .end.

  .if. .required. < .min. .then.
    .required. = .min.
  .end.

  .return. .required.
.end.

.local. .float. = .win...float.
.function. .float.:.__call.(.winnr., .opts.)
  .winnr. = .winnr. .or. .win...current.()
  .local. .bufnr.

  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .else.
    .bufnr. = .win...bufnr.(.winnr.)
  .end.

  .validate. {
    .win_options. = {
      {
        .__nonexistent. = .true.,
        ["?.center."] = ".list.",
        ["?.panel."] = ".number.",
        ["?.dock."] = ".number.",
      },
      .opts. .or. {},
    },
  }

  .opts. = .opts. .or. {}
  .local. .dock. = .opts...dock.
  .local. .panel. = .opts...panel.
  .local. .center. = .opts...center.
  .local. .focus. = .opts...focus.
  .opts...dock. = .nil.
  .opts...panel. = .nil.
  .opts...center. = .nil.
  .opts...style. = .opts...style. .or. ".minimal."
  .opts...border. = .opts...border. .or. ".single."
  .local. .editor_size. = .win...vimsize.()
  .local. .current_width. = .win...width.()
  .local. .current_height. = .win...height.()
  .opts...width. = .opts...width. .or. .current_width.
  .opts...height. = .opts...height. .or. .current_height.
  .opts...relative. = .opts...relative. .or. ".editor."
  .focus. = .focus. == .nil. .and. .true. .or. .focus.
  .local. .reverse. = .opts...reverse.
  .opts...reverse. = .nil.

  .if. .center. .then.
    .if. .opts...relative. == ".editor." .then.
      .current_width. = .editor_size.[.1.]
      .current_height. = .editor_size.[.2.]
    .end.

    .local. .width., .height. = .unpack.(.center.)
    .width. =
      .math...floor.(.from_percent.(.current_width., .width., .10.))
    .height. =
      .math...floor.(.from_percent.(.current_height., .height., .5.))
    .local. .col. = (.current_width. - .width.) / .2.
    .local. .row. = (.current_height. - .height.) / .2.
    .opts...width. = .width.
    .opts...height. = .height.
    .opts...col. = .math...floor.(.col.)
    .opts...row. = .math...floor.(.row.)
  .elseif. .panel. .then.
    .if. .opts...relative. == ".editor." .then.
      .current_width. = .editor_size.[.1.]
      .current_height. = .editor_size.[.2.]
    .end.

    .opts...row. = .0.
    .opts...col. = .1.
    .opts...width. = .from_percent.(.current_width., .panel., .5.)
    .opts...height. = .current_height.

    .if. .reverse. .then.
      .opts...col. = .current_width. - .opts...width.
    .end.
  .elseif. .dock. .then.
    .if. .opts...relative. == ".editor." .then.
      .current_width. = .editor_size.[.1.]
      .current_height. = .editor_size.[.2.]
    .end.

    .opts...col. = .0.
    .opts...row. = .opts...height. - .dock.
    .opts...height. = .from_percent.(.current_height., .dock., .5.)
    .opts...width. = .current_width. > .5. .and. .current_width. - .2.
      .or. .current_width.

    .if. .reverse. .then.
      .opts...row. = .opts...height.
    .end.
  .end.

  .local. .winid. = .vim...api...nvim_open_win.(.bufnr., .focus., .opts.)

  .if. .winid. == .0. .then.
    .return. .false.
  .end.

  .win...id...goto.(.winid.)

  .return. .winid.
.end.

.function. .float...panel.(.winnr., .size., .opts.)
  .if. .not. .size. .then.
    .size. = .30.
  .end.

  .local. .o. = .merge.({ .panel. = .size. }, .opts. .or. {})
  .return. .float.(.winnr., .o.)
.end.

.function. .float...center.(.winnr., .size., .opts.)
  .if. .not. .size. .then.
    .size. = { .80., .80. }
  .elseif. .is_number.(.size.) .then.
    .local. .n. = .size.
    .size. = { .n., .n. }
  .elseif. #.size. == .1. .then.
    .local. .n. = .size.[.1.]
    .size. = { .n., .n. }
  .end.

  .return. .float.(.winnr., .merge.({ .center. = .size. }, .opts.))
.end.

.function. .float...dock.(.winnr., .size., .opts.)
  .size. = .size. .or. .10.
  .return. .float.(.winnr., .merge.({ .dock. = .size. }, .opts. .or. {}))
.end.

.function. .float...set_config.(.winnr., .config.)
  .config. = .config. .or. {}
  .local. .ok., .msg. = .pcall.(
    .vim...api...nvim_win_set_config.,
    .win...nr2id.(.winnr.),
    .config.
  )

  .if. .not. .ok. .then.
    .return. .false., .msg.
  .end.

  .return. .true.
.end.

.function. .float...get_config.(.winnr.)
  .if. .not. .win...exists.(.winnr.) .then.
    .return.
  .end.

  .local. .ok., .msg. =
    .pcall.(.vim...api...nvim_win_get_config., .win...nr2id.(.winnr.))
  .if. .not. .ok. .then.
    .return. .false., .msg.
  .end.

  .return. .ok.
.end.

.function. .win...close.(.winnr.)
  .return. .win...id...close.(.win...nr2id.(.winnr.))
.end.

.function. .win...hide.(.winnr.)
  .return. .win...id...hide.(.win...nr2id.(.winnr.))
.end.

.function. .win...goto.(.winnr.)
  .return. .win...id...goto.(.win...nr2id.(.winnr.))
.end.

.function. .win...id...float.:.__call.(.winid., .opts.)
  .return. .win...float.(.win...id2nr.(.winid.), .opts.)
.end.

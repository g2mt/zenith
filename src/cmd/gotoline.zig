//
// Copyright (c) 2024 T. M. <pm2mtr@gmail.com>.
//
// This work is licensed under the BSD 3-Clause License.
//
const Cmd = @This();

const std = @import("std");
const builtin = @import("builtin");

const kbd = @import("../kbd.zig");
const text = @import("../text.zig");
const editor = @import("../editor.zig");


pub fn onInputted(self: *editor.Editor) !void {
  self.needs_update_cursor = true;
  var text_handler: *text.TextHandler = &self.text_handler;
  var cmd_data: *editor.CommandData = self.getCmdData();
  const line: u32 = std.fmt.parseInt(u32, cmd_data.cmdinp.items, 10) catch {
    cmd_data.replacePromptOverlay(self, .{ .static = PROMPT_INVALID_INTEGER, });
    return;
  };
  if (line == 0) {
    cmd_data.replacePromptOverlay(self, .{ .static = PROMPT_LINE_STARTS_AT_ONE });
    return;
  }
  text_handler.gotoLine(self, line - 1) catch {
    cmd_data.replacePromptOverlay(self, .{ .static = PROMPT_OUT_OF_BOUNDS });
    return;
  };
  self.setState(.text);
}

pub fn onKey(self: *editor.Editor, keysym: kbd.Keysym) !bool {
  if (keysym.getPrint()) |key| {
    if (key == 'g') {
      try self.text_handler.gotoLine(self, 0);
      self.setState(.text);
      return true;
    } else if (key == 'G') {
      try self.text_handler.gotoLine(
        self,
        @intCast(self.text_handler.lineinfo.getLen() - 1)
      );
      self.setState(.text);
      return true;
    }
  }
  return false;
}

pub const PROMPT = "Go to line (first = g, last = G):";
pub const PROMPT_INVALID_INTEGER = "Invalid integer!";
pub const PROMPT_LINE_STARTS_AT_ONE = "Lines start at 1!";
pub const PROMPT_OUT_OF_BOUNDS = "Out of bounds!";

pub const Fns: editor.CommandData.FnTable = .{
  .onInputted = Cmd.onInputted,
  .onKey = Cmd.onKey,
};
//
// Copyright (c) 2024 T. M. <pm2mtr@gmail.com>.
//
// This work is licensed under the BSD 3-Clause License.
//
const Impl = @This();

const std = @import("std");

const kbd = @import("../kbd.zig");
const text = @import("../text.zig");
const editor = @import("../editor.zig");

pub fn onSet(self: *editor.Editor) void {
  self.text_handler.markStart(self);
}

pub fn resetState(self: *editor.Editor) void {
  self.text_handler.markers = null;
  self.setState(.text);
}

pub fn handleInput(self: *editor.Editor, keysym: kbd.Keysym) !void {
  if (keysym.raw == kbd.Keysym.ESC) {
    Impl.resetState(self);
    return;
  }
  if (keysym.key == kbd.Keysym.Key.up) {
    self.text_handler.goUp(self);
  }
  else if (keysym.key == kbd.Keysym.Key.down) {
    self.text_handler.goDown(self);
  }
  else if (keysym.key == kbd.Keysym.Key.left) {
    self.text_handler.goLeft(self);
  }
  else if (keysym.key == kbd.Keysym.Key.right) {
    self.text_handler.goRight(self);
  }
  else if (keysym.key == kbd.Keysym.Key.home) {
    self.text_handler.goHead(self);
  }
  else if (keysym.key == kbd.Keysym.Key.end) {
    try self.text_handler.goTail(self);
  }
  else if (keysym.raw == kbd.Keysym.NEWLINE) {
    if (self.text_handler.markers == null) {
      self.text_handler.markStart(self);
    } else {
      self.text_handler.markEnd(self);
    }
  }
  
  else if (keysym.key == kbd.Keysym.Key.del) {
    try self.text_handler.deleteMarked(self);
  }
  else if (keysym.raw == kbd.Keysym.BACKSPACE) {
    try self.text_handler.deleteMarked(self);
    Impl.resetState(self);
  }
  
  else if (keysym.ctrl_key and keysym.isChar('c')) {
    try self.text_handler.copy(self);
    Impl.resetState(self);
  }
  else if (keysym.ctrl_key and keysym.isChar('x')) {
    try self.text_handler.copy(self);
    try self.text_handler.deleteMarked(self);
    Impl.resetState(self);
  }
}

pub fn handleOutput(self: *editor.Editor) !void {
  if (self.needs_redraw) {
    try self.refreshScreen();
    try self.renderText();
    self.needs_redraw = false;
  }
  if (self.needs_update_cursor) {
    try Impl.renderStatus(self);
    try self.updateCursorPos();
    self.needs_update_cursor = false;
  }
}

pub fn renderStatus(self: *editor.Editor) !void {
  try self.moveCursor(self.getTextHeight(), 0);
  try self.writeAll(editor.Editor.CLEAR_LINE);
  try self.writeAll("Enter: mark end, Del: delete");
  var status: [32]u8 = undefined;
  const status_slice = try std.fmt.bufPrint(
    &status,
    "{d}:{d}",
    .{self.text_handler.cursor.row,self.text_handler.cursor.col}, 
  );
  try self.moveCursor(
    self.getTextHeight() + 1,
    @intCast(self.w_width - status_slice.len),
  );
  try self.writeAll(status_slice);
}
#ifndef RUNNER_MINI_WINDOW_H_
#define RUNNER_MINI_WINDOW_H_

#include <flutter/encodable_value.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// The desktop mini calendar: a small borderless window beside the app's, with a Flutter engine of its
// own running miniCalendarMain (lib/features/mini_calendar). It stays above the other windows, among
// them, or on the desktop below them, and remembers where it was and whether it was open.
class MiniWindow {
 public:
  // |on_action| gets the taps that open the app ("open|2026-10-09|d", "create|2026-10-09|d");
  // |on_open_changed| hears it opened or closed by the user (not the app quitting).
  MiniWindow(std::function<void(const std::string&)> on_action, std::function<void(bool)> on_open_changed);
  ~MiniWindow();

  MiniWindow(const MiniWindow&) = delete;
  MiniWindow& operator=(const MiniWindow&) = delete;

  // Shows the window (creating it the first time) and brings it forward.
  void Open();

  // Closed by the user: it stays closed on the next start.
  void Close();

  // The app is quitting: the window goes, and comes back on the next start if it was open.
  void Destroy();

  bool IsOpen() const { return hwnd_ != nullptr; }

  // Whether it was open when the app last quit.
  static bool WasOpen();

 private:
  // Above the other windows, among them, or on the desktop below them (as MiniLayer in Dart).
  enum class Layer { kTop = 0, kNormal = 1, kDesktop = 2 };

  static LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);
  LRESULT HandleMessage(UINT message, WPARAM wparam, LPARAM lparam);
  void HandleCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void SetLayer(Layer layer);
  // On the desktop: whether the desktop is showing (Win + D, or a click on it) decides whether the
  // window rises above everything or stays below the other windows.
  void FollowDesktop();
  void SavePlacement();

  std::function<void(const std::string&)> on_action_;
  std::function<void(bool)> on_open_changed_;
  HWND hwnd_ = nullptr;
  std::unique_ptr<flutter::FlutterViewController> controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  Layer layer_ = Layer::kTop;
  bool above_desktop_ = false;
};

#endif  // RUNNER_MINI_WINDOW_H_

#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>
#include <string>

#include "mini_window.h"
#include "win32_window.h"

// Registered message a second instance broadcasts so the running one comes to the front.
constexpr wchar_t kShowMessageName[] = L"dev.lucasfelipe.Tarefas.Show";

// Registered message the uninstaller broadcasts so the app quits (even from the tray) before its
// files are removed.
constexpr wchar_t kQuitMessageName[] = L"dev.lucasfelipe.Tarefas.Quit";

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|. With |start_hidden| (Windows
  // starting the app, "--minimized") it stays in the tray until opened.
  FlutterWindow(const flutter::DartProject& project, bool start_hidden);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void HandleWindowCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // The tray icon (beside the clock): a click opens the window, the right click shows Abrir / Sair.
  void AddTrayIcon();
  void RemoveTrayIcon();
  void ShowTrayMenu();
  void ShowFromTray();
  void Quit();

  // A tap on the mini calendar that opens the app on a day: the window comes forward and Dart goes there.
  void OnMiniAction(const std::string& action);

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // "tarefas/window": the window title (the running focus timer), the tray, the alarm sound, showing
  // the window, starting with Windows and the mini calendar.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> window_channel_;

  // The desktop mini calendar, opened from the tray or the settings.
  std::unique_ptr<MiniWindow> mini_;

  bool start_hidden_;
  bool maximized_ = false;
  bool shown_once_ = false;

  // Closing hides the window in the tray while the app keeps running (reminders, focus); "Sair" quits.
  bool tray_enabled_;
  bool tray_added_ = false;
  bool quitting_ = false;

  // Texts come from Dart (the ARB file); these stand in until it configures the tray.
  std::wstring tray_tooltip_ = L"Ordo";
  std::wstring tray_open_ = L"Abrir";
  std::wstring tray_mini_ = L"Mini calendário";
  std::wstring tray_quit_ = L"Sair";

  UINT show_message_ = 0;
  UINT quit_message_ = 0;
  UINT taskbar_created_ = 0;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_

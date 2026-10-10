#include "flutter_window.h"

#include <flutter/standard_method_codec.h>
#include <mmsystem.h>
#include <shellapi.h>

#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"

namespace {

// Where the window's size, position and maximized state are kept between runs.
#ifdef NDEBUG
constexpr wchar_t kSettingsKey[] = L"Software\\dev.lucasfelipe\\Tarefas";
#else
// Debug builds keep their own, beside an installed app's.
constexpr wchar_t kSettingsKey[] = L"Software\\dev.lucasfelipe\\Tarefas\\Debug";
#endif
constexpr wchar_t kPlacementValue[] = L"WindowPlacement";

// Puts the still hidden window where the last run left it, if that spot is still on a monitor.
// Returns whether it was maximized, so the first show can maximize it again.
bool RestorePlacement(HWND hwnd) {
  WINDOWPLACEMENT placement{};
  DWORD size = sizeof(placement);
  if (::RegGetValueW(HKEY_CURRENT_USER, kSettingsKey, kPlacementValue, RRF_RT_REG_BINARY, nullptr, &placement,
                     &size) != ERROR_SUCCESS ||
      size != sizeof(placement) || placement.length != sizeof(placement)) {
    return false;
  }
  if (::MonitorFromRect(&placement.rcNormalPosition, MONITOR_DEFAULTTONULL) == nullptr) {
    return false;
  }
  // Closed while minimized from a maximized window: it comes back maximized.
  const bool maximized = placement.showCmd == SW_SHOWMAXIMIZED ||
                         (placement.showCmd == SW_SHOWMINIMIZED && (placement.flags & WPF_RESTORETOMAXIMIZED) != 0);
  placement.showCmd = SW_HIDE;
  placement.flags = 0;
  ::SetWindowPlacement(hwnd, &placement);
  // Moving onto a monitor with another scale makes Windows resize the window for its DPI
  // (WM_DPICHANGED); placing it again, now on that monitor, gives back the saved size.
  ::SetWindowPlacement(hwnd, &placement);
  return maximized;
}

constexpr UINT kTrayMessage = WM_APP + 1;
constexpr UINT kTrayIconId = 1;
constexpr UINT kMenuOpen = 1;
constexpr UINT kMenuQuit = 2;
constexpr UINT kMenuMini = 3;

// "Iniciar com o Windows": the app in the user's Run key, started hidden in the tray.
constexpr wchar_t kRunKey[] = L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";
constexpr wchar_t kRunValue[] = L"Tarefas";

std::wstring Widen(const std::string& text) {
  const int length = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, nullptr, 0);
  std::wstring wide(length > 0 ? length : 1, L'\0');
  if (length > 0) {
    MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, wide.data(), length);
  }
  wide.resize(wcslen(wide.c_str()));
  return wide;
}

std::wstring ExePath() {
  wchar_t path[MAX_PATH];
  const DWORD length = ::GetModuleFileNameW(nullptr, path, MAX_PATH);
  return std::wstring(path, length);
}

// The "Despertador" sound, shipped as a Flutter asset next to the executable.
std::wstring AlarmSoundPath() {
  std::wstring exe = ExePath();
  return exe.substr(0, exe.find_last_of(L'\\')) + L"\\data\\flutter_assets\\assets\\sounds\\despertador.wav";
}

void SetAutostart(bool enabled) {
#ifdef NDEBUG
  if (!enabled) {
    ::RegDeleteKeyValueW(HKEY_CURRENT_USER, kRunKey, kRunValue);
    return;
  }
  const std::wstring command = L"\"" + ExePath() + L"\" --minimized";
  ::RegSetKeyValueW(HKEY_CURRENT_USER, kRunKey, kRunValue, REG_SZ, command.c_str(),
                    static_cast<DWORD>((command.size() + 1) * sizeof(wchar_t)));
#else
  // A debug build leaves the installed app's start with Windows alone.
  (void)enabled;
#endif
}

const flutter::EncodableValue* Field(const flutter::EncodableMap& map, const char* key) {
  const auto it = map.find(flutter::EncodableValue(std::string(key)));
  return it == map.end() ? nullptr : &it->second;
}

void SavePlacement(HWND hwnd) {
  WINDOWPLACEMENT placement{};
  placement.length = sizeof(placement);
  if (!::GetWindowPlacement(hwnd, &placement)) {
    return;
  }
  ::RegSetKeyValueW(HKEY_CURRENT_USER, kSettingsKey, kPlacementValue, REG_BINARY, &placement, sizeof(placement));
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project, bool start_hidden)
    : project_(project), start_hidden_(start_hidden), tray_enabled_(start_hidden) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }
  maximized_ = RestorePlacement(GetHandle());
  show_message_ = ::RegisterWindowMessageW(kShowMessageName);
  quit_message_ = ::RegisterWindowMessageW(kQuitMessageName);
  taskbar_created_ = ::RegisterWindowMessageW(L"TaskbarCreated");
  if (tray_enabled_) {
    AddTrayIcon();
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  window_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "tarefas/window",
      &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        HandleWindowCall(call, std::move(result));
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([this]() {
    // Started with Windows: it stays in the tray until opened.
    if (!start_hidden_) {
      ShowFromTray();
    }
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  // The mini calendar comes back if it was open when the app quit.
  mini_ = std::make_unique<MiniWindow>([this](const std::string& action) { OnMiniAction(action); });
  if (MiniWindow::WasOpen()) {
    mini_->Open();
  }

  return true;
}

void FlutterWindow::OnDestroy() {
  ::PlaySoundW(nullptr, nullptr, 0);
  RemoveTrayIcon();
  if (mini_) {
    mini_->Destroy();
    mini_ = nullptr;
  }
  window_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  if (message == show_message_ && show_message_ != 0) {
    ShowFromTray();
    return 0;
  }
  if (message == quit_message_ && quit_message_ != 0) {
    Quit();
    return 0;
  }
  // Explorer restarted: the tray is new and empty.
  if (message == taskbar_created_ && taskbar_created_ != 0 && tray_added_) {
    tray_added_ = false;
    AddTrayIcon();
    return 0;
  }

  switch (message) {
    case kTrayMessage:
      switch (LOWORD(lparam)) {
        case WM_LBUTTONUP:
        case WM_LBUTTONDBLCLK:
          ShowFromTray();
          break;
        case WM_RBUTTONUP:
        case WM_CONTEXTMENU:
          ShowTrayMenu();
          break;
      }
      return 0;
    // Windows signing out or the installer updating the app (Restart Manager): quit for real, even
    // with the tray.
    case WM_QUERYENDSESSION:
      quitting_ = true;
      return TRUE;
    case WM_ENDSESSION:
      if (wparam) {
        quitting_ = true;
        SavePlacement(hwnd);
        ::PlaySoundW(nullptr, nullptr, 0);
        RemoveTrayIcon();
        ::DestroyWindow(hwnd);
      }
      return 0;
    case WM_CLOSE:
      SavePlacement(hwnd);
      // With the tray, closing hides: reminders and the focus timer keep running.
      if (tray_enabled_ && !quitting_) {
        ::ShowWindow(hwnd, SW_HIDE);
        return 0;
      }
      break;
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::HandleWindowCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                                     std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();
  const auto* arguments = call.arguments();
  if (method == "setTitle") {
    const auto* title = std::get_if<std::string>(arguments);
    if (title == nullptr) {
      result->Error("bad_args", "setTitle takes a string");
      return;
    }
    ::SetWindowTextW(GetHandle(), Widen(*title).c_str());
    result->Success();
  } else if (method == "configureTray") {
    const auto* map = std::get_if<flutter::EncodableMap>(arguments);
    if (map == nullptr) {
      result->Error("bad_args", "configureTray takes a map");
      return;
    }
    if (const auto* v = Field(*map, "tooltip"); v != nullptr && std::holds_alternative<std::string>(*v)) {
      tray_tooltip_ = Widen(std::get<std::string>(*v));
    }
    if (const auto* v = Field(*map, "open"); v != nullptr && std::holds_alternative<std::string>(*v)) {
      tray_open_ = Widen(std::get<std::string>(*v));
    }
    if (const auto* v = Field(*map, "mini"); v != nullptr && std::holds_alternative<std::string>(*v)) {
      tray_mini_ = Widen(std::get<std::string>(*v));
    }
    if (const auto* v = Field(*map, "quit"); v != nullptr && std::holds_alternative<std::string>(*v)) {
      tray_quit_ = Widen(std::get<std::string>(*v));
    }
    const auto* enabled = Field(*map, "enabled");
    tray_enabled_ = enabled != nullptr && std::holds_alternative<bool>(*enabled) && std::get<bool>(*enabled);
    if (tray_enabled_) {
      RemoveTrayIcon();
      AddTrayIcon();
    } else {
      RemoveTrayIcon();
      // Without the tray a hidden window could not be reached again.
      if (!::IsWindowVisible(GetHandle())) {
        ShowFromTray();
      }
    }
    result->Success();
  } else if (method == "playAlarm") {
    const auto* loop = std::get_if<bool>(arguments);
    const std::wstring path = AlarmSoundPath();
    ::PlaySoundW(path.c_str(), nullptr, SND_FILENAME | SND_ASYNC | SND_NODEFAULT | (loop != nullptr && *loop ? SND_LOOP : 0));
    result->Success();
  } else if (method == "stopAlarm") {
    ::PlaySoundW(nullptr, nullptr, 0);
    result->Success();
  } else if (method == "show") {
    ShowFromTray();
    result->Success();
  } else if (method == "setAutostart") {
    const auto* enabled = std::get_if<bool>(arguments);
    SetAutostart(enabled != nullptr && *enabled);
    result->Success();
  } else if (method == "openMini") {
    if (mini_) {
      mini_->Open();
    }
    result->Success();
  } else {
    result->NotImplemented();
  }
}

void FlutterWindow::AddTrayIcon() {
  if (tray_added_) {
    return;
  }
  NOTIFYICONDATAW data{};
  data.cbSize = sizeof(data);
  data.hWnd = GetHandle();
  data.uID = kTrayIconId;
  data.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  data.uCallbackMessage = kTrayMessage;
  data.hIcon = static_cast<HICON>(::LoadImageW(::GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON,
                                               ::GetSystemMetrics(SM_CXSMICON), ::GetSystemMetrics(SM_CYSMICON), LR_DEFAULTCOLOR));
  wcsncpy_s(data.szTip, tray_tooltip_.c_str(), _TRUNCATE);
  tray_added_ = ::Shell_NotifyIconW(NIM_ADD, &data) != FALSE;
}

void FlutterWindow::RemoveTrayIcon() {
  if (!tray_added_) {
    return;
  }
  NOTIFYICONDATAW data{};
  data.cbSize = sizeof(data);
  data.hWnd = GetHandle();
  data.uID = kTrayIconId;
  ::Shell_NotifyIconW(NIM_DELETE, &data);
  tray_added_ = false;
}

void FlutterWindow::ShowTrayMenu() {
  HWND hwnd = GetHandle();
  POINT point;
  ::GetCursorPos(&point);
  HMENU menu = ::CreatePopupMenu();
  ::AppendMenuW(menu, MF_STRING, kMenuOpen, tray_open_.c_str());
  ::AppendMenuW(menu, MF_STRING | (mini_ && mini_->IsOpen() ? MF_CHECKED : MF_UNCHECKED), kMenuMini, tray_mini_.c_str());
  ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  ::AppendMenuW(menu, MF_STRING, kMenuQuit, tray_quit_.c_str());
  ::SetMenuDefaultItem(menu, kMenuOpen, FALSE);
  // The menu closes when clicking elsewhere only if the window is in the foreground.
  ::SetForegroundWindow(hwnd);
  const UINT command = ::TrackPopupMenu(menu, TPM_RETURNCMD | TPM_NONOTIFY | TPM_RIGHTBUTTON, point.x, point.y, 0, hwnd, nullptr);
  ::PostMessageW(hwnd, WM_NULL, 0, 0);
  ::DestroyMenu(menu);
  if (command == kMenuOpen) {
    ShowFromTray();
  } else if (command == kMenuMini && mini_) {
    if (mini_->IsOpen()) {
      mini_->Close();
    } else {
      mini_->Open();
    }
  } else if (command == kMenuQuit) {
    Quit();
  }
}

void FlutterWindow::ShowFromTray() {
  HWND hwnd = GetHandle();
  if (!shown_once_) {
    shown_once_ = true;
    ::ShowWindow(hwnd, maximized_ ? SW_SHOWMAXIMIZED : SW_SHOWNORMAL);
  } else if (::IsIconic(hwnd)) {
    ::ShowWindow(hwnd, SW_RESTORE);
  } else {
    ::ShowWindow(hwnd, SW_SHOW);
  }
  ::SetForegroundWindow(hwnd);
}

void FlutterWindow::OnMiniAction(const std::string& action) {
  ShowFromTray();
  if (window_channel_) {
    window_channel_->InvokeMethod("widgetAction", std::make_unique<flutter::EncodableValue>(action));
  }
}

void FlutterWindow::Quit() {
  quitting_ = true;
  ::PlaySoundW(nullptr, nullptr, 0);
  RemoveTrayIcon();
  ::PostMessageW(GetHandle(), WM_CLOSE, 0, 0);
}

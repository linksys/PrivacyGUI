import 'dart:html';

void assignWebLocation(String url) => window.location.assign(url);
void updateWebHost(String host) => window.location.host = host;
void reload() {
  window.location.reload();
}

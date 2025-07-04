import json
import os

# Translations for each language
translations ={
  "ar": {
    "factoryResetChildTitle": "إعادة ضبط العقدة وجميع العقد التابعة لها إلى إعدادات المصنع الافتراضية",
    "menuRestartNetworkChildMessage": "إعادة تشغيل العقدة وجميع العقد الفرعية. ستؤدي إعادة تشغيل نظام شبكة الواي فاي المتداخلة إلى قطع الاتصال بالإنترنت مؤقتًا. إذا كان لديك عدة عقد، فستتم إعادة تشغيلها جميعًا. ستواجه الأجهزة المتصلة أيضًا انقطاعًا مؤقتًا ولكن ستتصل تلقائيًا بمجرد عودة النظام للاتصال.",
    "rebootChildTitle": "إعادة تشغيل العقدة وجميع العقد التابعة لها"
  },
  "da": {
    "factoryResetChildTitle": "Nulstil noden og alle dens underordnede til fabriksindstillinger",
    "menuRestartNetworkChildMessage": "Genstart node og alle underordnede noder. Genstart af mesh Wi-Fi-systemet vil midlertidigt afbryde det fra internettet. Hvis du har flere noder, vil alle genstarte. Tilsluttede enheder vil også opleve en midlertidig afbrydelse, men vil automatisk genoprette forbindelse, når systemet er online igen.",
    "rebootChildTitle": "Genstart noden og alle dens underordnede"
  },
  "de": {
    "factoryResetChildTitle": "Knoten und alle untergeordneten Knoten auf Werkseinstellungen zurücksetzen",
    "menuRestartNetworkChildMessage": "Knoten und alle untergeordneten Knoten neu starten. Das Neustarten des Mesh-WLAN-Systems trennt es vorübergehend vom Internet. Wenn Sie mehrere Knoten haben, werden alle neu gestartet. Verbundene Geräte werden ebenfalls eine temporäre Trennung erfahren, verbinden sich jedoch automatisch wieder, sobald das System wieder online ist.",
    "rebootChildTitle": "Knoten und alle untergeordneten Knoten neu starten"
  },
  "el": {
    "factoryResetChildTitle": "Επαναφορά του κόμβου και όλων των θυγατρικών του στην εργοστασιακή προεπιλογή",
    "menuRestartNetworkChildMessage": "Επανεκκίνηση κόμβου και όλων των θυγατρικών κόμβων. Η επανεκκίνηση του συστήματος mesh Wi-Fi θα το αποσυνδέσει προσωρινά από το Διαδίκτυο. Εάν έχετε πολλούς κόμβους, όλοι θα επανεκκινήσουν. Οι συνδεδεμένες συσκευές θα αντιμετωπίσουν επίσης μια προσωρινή αποσύνδεση, αλλά θα επανασυνδεθούν αυτόματα μόλις το σύστημα είναι ξανά συνδεδεμένο.",
    "rebootChildTitle": "Επανεκκίνηση του κόμβου και όλων των θυγατρικών του"
  },
  "en": {
    "factoryResetChildTitle": "Reset the node and all its child/s to Factory Default",
    "menuRestartNetworkChildMessage": "Reboot Node and All Child Nodes Restarting the mesh WiFi system will temporarily disconnect it from the Internet. If you have multiple nodes, all will restart. Connected devices will also experience a temporary disconnection but will automatically reconnect once the system is back online.",
    "rebootChildTitle": "Reboot the node and all its child/s"
  },
  "es": {
    "factoryResetChildTitle": "Restablecer el nodo y todos sus nodos secundarios a la configuración de fábrica",
    "menuRestartNetworkChildMessage": "Reiniciar el nodo y todos los nodos secundarios. Reiniciar el sistema Wi-Fi en malla lo desconectará temporalmente de Internet. Si tiene varios nodos, todos se reiniciarán. Los dispositivos conectados también experimentarán una desconexión temporal, pero se volverán a conectar automáticamente una vez que el sistema esté en línea nuevamente.",
    "rebootChildTitle": "Reiniciar el nodo y todos sus nodos secundarios"
  },
  "es_AR": {
    "factoryResetChildTitle": "Restablecer el nodo y todos sus nodos hijos a la configuración predeterminada de fábrica",
    "menuRestartNetworkChildMessage": "Reiniciar el nodo y todos los nodos hijos. Reiniciar el sistema de Wi-Fi en malla lo desconectará temporalmente de Internet. Si tiene varios nodos, todos se reiniciarán. Los dispositivos conectados también experimentarán una desconexión temporal, pero se volverán a conectar automáticamente una vez que el sistema esté en línea nuevamente.",
    "rebootChildTitle": "Reiniciar el nodo y todos sus nodos hijos"
  },
  "fi": {
    "factoryResetChildTitle": "Nollaa solmu ja kaikki sen alisolmut tehdasasetuksiin",
    "menuRestartNetworkChildMessage": "Käynnistä solmu ja kaikki alisolmut uudelleen. Mesh-Wi-Fi-järjestelmän uudelleenkäynnistys katkaisee sen väliaikaisesti Internet-yhteydestä. Jos sinulla on useita solmuja, kaikki käynnistyvät uudelleen. Liitetyt laitteet kokevat myös väliaikaisen yhteyden katkeamisen, mutta muodostavat automaattisesti yhteyden uudelleen, kun järjestelmä on taas online.",
    "rebootChildTitle": "Käynnistä solmu ja kaikki sen alisolmut uudelleen"
  },
  "fr": {
    "factoryResetChildTitle": "Réinitialiser le nœud et tous ses nœuds enfants aux paramètres d'usine",
    "menuRestartNetworkChildMessage": "Redémarrer le nœud et tous les nœuds enfants. Le redémarrage du système Wi-Fi maillé le déconnectera temporairement d'Internet. Si vous avez plusieurs nœuds, tous redémarreront. Les appareils connectés subiront également une déconnexion temporaire, mais se reconnecteront automatiquement une fois le système en ligne.",
    "rebootChildTitle": "Redémarrer le nœud et tous ses nœuds enfants"
  },
  "fr_CA": {
    "factoryResetChildTitle": "Réinitialiser le nœud et tous ses nœuds enfants aux paramètres d'usine par défaut",
    "menuRestartNetworkChildMessage": "Redémarrer le nœud et tous les nœuds enfants. Le redémarrage du système Wi-Fi maillé le déconnectera temporairement d'Internet. Si vous avez plusieurs nœuds, tous redémarreront. Les appareils connectés subiront également une déconnexion temporaire, mais se reconnecteront automatiquement une fois le système en ligne.",
    "rebootChildTitle": "Redémarrer le nœud et tous ses nœuds enfants"
  },
  "id": {
    "factoryResetChildTitle": "Reset node dan semua child/nya ke Pengaturan Pabrik Default",
    "menuRestartNetworkChildMessage": "Nyalakan Ulang Node dan Semua Node Child. Menyalakan ulang sistem WiFi mesh akan memutuskan koneksi internet sementara. Jika Anda memiliki beberapa node, semua akan menyala ulang. Perangkat yang terhubung juga akan mengalami pemutusan sementara tetapi akan secara otomatis terhubung kembali setelah sistem online kembali.",
    "rebootChildTitle": "Nyalakan ulang node dan semua child/nya"
  },
  "it": {
    "factoryResetChildTitle": "Ripristina il nodo e tutti i suoi nodi figli alle impostazioni predefinite di fabbrica",
    "menuRestartNetworkChildMessage": "Riavvia il nodo e tutti i nodi figli. Il riavvio del sistema Wi-Fi mesh lo disconnetterà temporaneamente da Internet. Se hai più nodi, tutti si riavvieranno. Anche i dispositivi connessi subiranno una disconnessione temporanea ma si ricollegheranno automaticamente una volta che il sistema sarà di nuovo online.",
    "rebootChildTitle": "Riavvia il nodo e tutti i suoi nodi figli"
  },
  "ja": {
    "factoryResetChildTitle": "ノードとそのすべての子ノードを工場出荷時の設定にリセット",
    "menuRestartNetworkChildMessage": "ノードとすべての子ノードを再起動します。メッシュWi-Fiシステムの再起動により、一時的にインターネットから切断されます。複数のノードがある場合、すべてが再起動します。接続されているデバイスも一時的に切断されますが、システムがオンラインに戻ると自動的に再接続されます。",
    "rebootChildTitle": "ノードとそのすべての子ノードを再起動"
  },
  "ko": {
    "factoryResetChildTitle": "노드 및 모든 하위 노드를 공장 기본값으로 재설정",
    "menuRestartNetworkChildMessage": "노드 및 모든 하위 노드 재부팅. 메시 Wi-Fi 시스템을 다시 시작하면 일시적으로 인터넷 연결이 끊어집니다. 여러 개의 노드가 있는 경우 모두 다시 시작됩니다. 연결된 장치도 일시적으로 연결이 끊어지지만 시스템이 다시 온라인 상태가 되면 자동으로 다시 연결됩니다.",
    "rebootChildTitle": "노드 및 모든 하위 노드 재부팅"
  },
  "nb": {
    "factoryResetChildTitle": "Tilbakestill noden og alle dens underordnede til fabrikkinnstillinger",
    "menuRestartNetworkChildMessage": "Start node og alle underordnede noder på nytt. Omstart av mesh Wi-Fi-systemet vil midlertidig koble det fra Internett. Hvis du har flere noder, vil alle starte på nytt. Tilkoblede enheter vil også oppleve en midlertidig frakobling, men vil automatisk koble til igjen når systemet er tilbake på nett.",
    "rebootChildTitle": "Start noden og alle dens underordnede på nytt"
  },
  "nl": {
    "factoryResetChildTitle": "Reset de node en al zijn kind-/kinderen naar fabrieksinstellingen",
    "menuRestartNetworkChildMessage": "Herstart node en alle kindnodes. Het herstarten van het mesh Wi-Fi-systeem zal de internetverbinding tijdelijk verbreken. Als u meerdere nodes heeft, worden ze allemaal herstart. Verbonden apparaten zullen ook een tijdelijke onderbreking ervaren, maar zullen automatisch opnieuw verbinding maken zodra het systeem weer online is.",
    "rebootChildTitle": "Herstart de node en al zijn kind-/kinderen"
  },
  "pl": {
    "factoryResetChildTitle": "Przywróć ustawienia fabryczne węzła i wszystkich jego węzłów podrzędnych",
    "menuRestartNetworkChildMessage": "Uruchom ponownie węzeł i wszystkie węzły podrzędne. Ponowne uruchomienie systemu mesh WiFi tymczasowo rozłączy go z Internetem. Jeśli masz wiele węzłów, wszystkie zostaną ponownie uruchomione. Podłączone urządzenia również doświadczą tymczasowego rozłączenia, ale automatycznie ponownie połączą się, gdy system będzie ponownie online.",
    "rebootChildTitle": "Uruchom ponownie węzeł i wszystkie jego węzły podrzędne"
  },
  "pt": {
    "factoryResetChildTitle": "Redefinir o nó e todos os seus nós filhos para o padrão de fábrica",
    "menuRestartNetworkChildMessage": "Reiniciar Nó e Todos os Nós Filhos. A reinicialização do sistema Wi-Fi em malha o desconectará temporariamente da Internet. Se você tiver vários nós, todos serão reiniciados. Os dispositivos conectados também experimentarão uma desconexão temporária, mas se reconectarão automaticamente assim que o sistema estiver online novamente.",
    "rebootChildTitle": "Reiniciar o nó e todos os seus nós filhos"
  },
  "pt_PT": {
    "factoryResetChildTitle": "Repor o nó e todos os seus nós filhos para as predefinições de fábrica",
    "menuRestartNetworkChildMessage": "Reiniciar o Nó e Todos os Nós Filhos. Reiniciar o sistema Wi-Fi em malha irá desconectá-lo temporariamente da Internet. Se tiver vários nós, todos irão reiniciar. Os dispositivos ligados também irão experimentar uma desconexão temporária, mas irão reconectar-se automaticamente assim que o sistema estiver online novamente.",
    "rebootChildTitle": "Reiniciar o nó e todos os seus nós filhos"
  },
  "ru": {
    "factoryResetChildTitle": "Сбросить узел и все его дочерние узлы до заводских настроек",
    "menuRestartNetworkChildMessage": "Перезагрузить узел и все дочерние узлы. Перезапуск mesh Wi-Fi системы временно отключит ее от Интернета. Если у вас несколько узлов, все они перезагрузятся. Подключенные устройства также испытают временное отключение, но автоматически переподключатся, как только система снова будет в сети.",
    "rebootChildTitle": "Перезагрузить узел и все его дочерние узлы"
  },
  "sv": {
    "factoryResetChildTitle": "Återställ noden och alla dess undernoder till fabriksinställningarna",
    "menuRestartNetworkChildMessage": "Starta om noden och alla underordnade noder. Omstart av mesh Wi-Fi-systemet kommer tillfälligt att koppla bort det från Internet. Om du har flera noder kommer alla att starta om. Anslutna enheter kommer också att uppleva en tillfällig frånkoppling men kommer automatiskt att återansluta när systemet är online igen.",
    "rebootChildTitle": "Starta om noden och alla dess undernoder"
  },
  "th": {
    "factoryResetChildTitle": "รีเซ็ตโหนดและโหนดลูกทั้งหมดเป็นค่าเริ่มต้นจากโรงงาน",
    "menuRestartNetworkChildMessage": "รีบูตโหนดและโหนดลูกทั้งหมด การรีบูตระบบ Mesh WiFi จะตัดการเชื่อมต่อจากอินเทอร์เน็ตชั่วคราว หากคุณมีหลายโหนด ทุกโหนดจะรีบูต อุปกรณ์ที่เชื่อมต่อจะถูกตัดการเชื่อมต่อชั่วคราวด้วย แต่จะเชื่อมต่อใหม่โดยอัตโนมัติเมื่อระบบกลับมาออนไลน์",
    "rebootChildTitle": "รีบูตโหนดและโหนดลูกทั้งหมด"
  },
  "tr": {
    "factoryResetChildTitle": "Düğümü ve tüm alt düğümlerini Fabrika Varsayılanlarına sıfırla",
    "menuRestartNetworkChildMessage": "Düğümü ve Tüm Alt Düğümleri Yeniden Başlat. Mesh WiFi sistemini yeniden başlatmak, internet bağlantısını geçici olarak keser. Birden fazla düğümünüz varsa, hepsi yeniden başlar. Bağlı cihazlar da geçici bir bağlantı kesintisi yaşar ancak sistem tekrar çevrimiçi olduğunda otomatik olarak yeniden bağlanır.",
    "rebootChildTitle": "Düğümü ve tüm alt düğümlerini yeniden başlat"
  },
  "vi": {
    "factoryResetChildTitle": "Đặt lại nút và tất cả các nút con về cài đặt gốc",
    "menuRestartNetworkChildMessage": "Khởi động lại nút và tất cả các nút con. Khởi động lại hệ thống WiFi mesh sẽ tạm thời ngắt kết nối Internet. Nếu bạn có nhiều nút, tất cả sẽ khởi động lại. Các thiết bị đã kết nối cũng sẽ bị ngắt kết nối tạm thời nhưng sẽ tự động kết nối lại sau khi hệ thống hoạt động trở lại.",
    "rebootChildTitle": "Khởi động lại nút và tất cả các nút con"
  },
  "zh": {
    "factoryResetChildTitle": "将节点及其所有子节点恢复出厂设置",
    "menuRestartNetworkChildMessage": "重启节点和所有子节点。重启 Mesh WiFi 系统将暂时断开互联网连接。如果您有多个节点，所有节点都将重启。连接的设备也将暂时断开连接，但系统上线后会自动重新连接。",
    "rebootChildTitle": "重启节点及其所有子节点"
  },
  "zh_TW": {
    "factoryResetChildTitle": "將節點及其所有子節點重設為原廠預設值",
    "menuRestartNetworkChildMessage": "重新啟動節點和所有子節點。重新啟動網狀 Wi-Fi 系統將會暫時中斷網際網路連線。如果您有多個節點，所有節點都將重新啟動。已連線的裝置也將會暫時中斷連線，但系統重新上線後將會自動重新連線。",
    "rebootChildTitle": "重新啟動節點及其所有子節點"
  }
}

def update_translations():
    # Construct the path to the 'lib/l10n' directory relative to the script's location
    # The script is in the 'tools' directory, so we need to go up one level to find 'lib/l10n'
    l10n_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'lib', 'l10n')

    # Ensure the l10n_dir exists
    if not os.path.isdir(l10n_dir):
        print(f"Error: Directory '{l10n_dir}' not found. Please ensure the script is in the correct location relative to your 'lib/l10n' folder.")
        return

    for filename in os.listdir(l10n_dir):
        # Process only app_*.arb files, excluding app_en.arb
        if not filename.startswith('app_') or not filename.endswith('.arb') or filename == 'app_en.arb':
            continue

        # Extract language code and normalize (convert to lowercase and replace - with _)
        # Example: 'app_es-AR.arb' becomes 'es_ar'
        lang_code = filename[4:-4].lower().replace('-', '_')

        # Adjust for 'es_ar' and 'fr_ca' if they are distinct in your translations dictionary
        if lang_code == 'es-ar': # handle potential direct match before _ conversion
            lang_code = 'es_AR'
        elif lang_code == 'fr-ca':
            lang_code = 'fr_CA'

        # Check if the exact language code exists in the translations dictionary
        if lang_code not in translations:
            # If not, try to fall back to the base language code (e.g., 'es' for 'es_AR')
            base_lang_code = lang_code.split('_')[0]
            if base_lang_code in translations:
                lang_code = base_lang_code
            else:
                print(f"No translations found for {lang_code}, skipping {filename}...")
                continue

        filepath = os.path.join(l10n_dir, filename)

        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # Iterate through the keys in the translations dictionary for the current language
            for key, value in translations[lang_code].items():
                data[key] = value
                # Remove '@' prefixed keys associated with the updated key if they exist
                # These are typically metadata keys for the English file and shouldn't be in others.
                if f'@{key}' in data:
                    del data[f'@{key}']

            # Write back to file with proper indentation
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
                f.write('\n')  # Add newline at end of file

            print(f"Updated {filename}")

        except Exception as e:
            print(f"Error updating {filename}: {str(e)}")

if __name__ == '__main__':
    update_translations()
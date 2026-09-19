package id.gemi.gemi

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FragmentActivity wajib untuk local_auth (BiometricPrompt).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Blokir screenshot + pratinjau app switcher (FLAG_SECURE); diatur dari Pengaturan › Tampilan.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "id.gemi/layar")
            .setMethodCallHandler { call, result ->
                if (call.method == "aman") {
                    if (call.arguments == true) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    else window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                } else result.notImplemented()
            }
    }
}

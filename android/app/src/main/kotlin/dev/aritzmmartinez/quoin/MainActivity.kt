package dev.aritzmmartinez.quoin

import android.os.Bundle
import android.view.View
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity

// Immersive mode for the system navigation bar only; the status bar stays.
// Done here because none of Flutter's SystemUiMode values fits: `manual`
// brings the hidden bar back on any touch on Android, and `immersiveSticky`
// hides the status bar as well. A swipe from the edge shows the navigation
// bar as a transient overlay.
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Edge to edge: Flutter draws under both system bars.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        keepNavigationBarInset(findViewById(FLUTTER_VIEW_ID))
        hideNavigationBar()
    }

    // Android shows the bar again after another app, a dialog or the
    // keyboard, so hide it whenever the window regains focus.
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideNavigationBar()
    }

    private fun hideNavigationBar() {
        WindowCompat.getInsetsController(window, window.decorView).apply {
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            hide(WindowInsetsCompat.Type.navigationBars())
        }
    }

    // A hidden bar reports a zero inset, so Flutter's padding and viewPadding
    // would let the floating bar sit where the transient bar appears (3-button
    // navigation) or on the gesture handle. Hand Flutter the inset the bar has
    // when shown, so the UI keeps clear of it either way.
    private fun keepNavigationBarInset(flutterView: View) {
        ViewCompat.setOnApplyWindowInsetsListener(flutterView) { view, insets ->
            val navigationBars = WindowInsetsCompat.Type.navigationBars()
            val adjusted = WindowInsetsCompat.Builder(insets)
                .setInsets(navigationBars, insets.getInsetsIgnoringVisibility(navigationBars))
                .build()
            ViewCompat.onApplyWindowInsets(view, adjusted)
        }
    }
}

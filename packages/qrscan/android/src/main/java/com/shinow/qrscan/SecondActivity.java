package com.shinow.qrscan;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.graphics.Color;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.hardware.Sensor;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.Display;
import android.view.Surface;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.Camera;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;

import com.google.common.util.concurrent.ListenableFuture;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class SecondActivity extends AppCompatActivity {

    public static final String EXTRA_RESULT = "qrscan_result";
    public static final String EXTRA_PATH = "path";
    public static final String EXTRA_ERROR = "ERROR_CODE";
    public static final String EXTRA_ERROR_MESSAGE = "ERROR_MESSAGE";
    public static final String EXTRA_COLOR = "qrscan_color";
    public static final String EXTRA_HINT = "qrscan_hint";
    public static final String EXTRA_TITLE = "qrscan_title";
    public static final String EXTRA_LABELS = "qrscan_labels";
    public static final String EXTRA_FONTS = "qrscan_fonts";
    public static boolean isLightOpen = false;

    private static final String TAG = "Qrscan";
    private static final int REQUEST_CAMERA = 202;

    private PreviewView previewView;
    private ScanOverlayView overlay;
    private ImageView lightButton;
    private LinearLayout column;
    private View hole;
    private Map<String, String> labels = new HashMap<>();
    private Camera camera;
    private Preview preview;
    private ImageAnalysis analysis;
    private ExecutorService cameraExecutor;
    private volatile boolean handled = false;
    private SensorManager sensorManager;
    private Sensor lightSensor;
    private SensorEventListener sensorEventListener;
    private boolean cameraBound = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        isLightOpen = false;
        setContentView(R.layout.activity_second);
        previewView = findViewById(R.id.preview_view);
        overlay = findViewById(R.id.scan_overlay);
        if (overlay != null) {
            Integer color = getIntent().hasExtra(EXTRA_COLOR)
                    ? getIntent().getIntExtra(EXTRA_COLOR, 0xFF12C4FF)
                    : null;
            overlay.setStyle(color);
        }
        lightButton = findViewById(R.id.scan_light);
        column = findViewById(R.id.scan_column);
        hole = findViewById(R.id.scan_hole);
        edgeToEdge();
        applyLabels();
        applyFonts();
        column.addOnLayoutChangeListener((v, l, t, r, b, ol, ot, or, ob) -> fitHole());
        cameraExecutor = Executors.newSingleThreadExecutor();

        previewView.setImplementationMode(PreviewView.ImplementationMode.COMPATIBLE);
        previewView.setScaleType(PreviewView.ScaleType.FILL_CENTER);

        sensorManager = (SensorManager) getSystemService(Context.SENSOR_SERVICE);
        if (sensorManager != null) {
            lightSensor = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT);
            sensorEventListener = new LightSensorEventListener(findViewById(R.id.scan_light_box));
        }

        findViewById(R.id.scan_back).setOnClickListener(v -> cancel());
        lightButton.setOnClickListener(v -> toggleTorch());

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,
                    new String[]{Manifest.permission.CAMERA}, REQUEST_CAMERA);
        } else {
            startCamera();
        }
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        // Android shows the bar again after a dialog, as in the app.
        if (hasFocus) {
            hideNavigationBar();
        }
    }

    // Under the system bars like the app, the navigation bar hidden; the
    // column keeps clear of where both bars appear.
    private void edgeToEdge() {
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        getWindow().setStatusBarColor(Color.TRANSPARENT);
        WindowCompat.getInsetsController(getWindow(), getWindow().getDecorView())
                .setAppearanceLightStatusBars(false);
        hideNavigationBar();
        ViewCompat.setOnApplyWindowInsetsListener(column, (view, insets) -> {
            Insets status = insets.getInsets(WindowInsetsCompat.Type.statusBars()
                    | WindowInsetsCompat.Type.displayCutout());
            Insets navigation = insets.getInsetsIgnoringVisibility(
                    WindowInsetsCompat.Type.navigationBars());
            view.setPadding(navigation.left, status.top, navigation.right, navigation.bottom);
            return insets;
        });
    }

    private void hideNavigationBar() {
        WindowInsetsControllerCompat controller =
                WindowCompat.getInsetsController(getWindow(), getWindow().getDecorView());
        controller.setSystemBarsBehavior(
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
        controller.hide(WindowInsetsCompat.Type.navigationBars());
    }

    // Every word comes from the caller, in its language. Without labels the
    // old title and hint fill the two lines they now live in.
    @SuppressWarnings("unchecked")
    private void applyLabels() {
        Object extra = getIntent().getSerializableExtra(EXTRA_LABELS);
        if (extra instanceof Map) {
            labels = (Map<String, String>) extra;
        } else {
            putIfPresent("title", getIntent().getStringExtra(EXTRA_TITLE));
            putIfPresent("subtitle", getIntent().getStringExtra(EXTRA_HINT));
        }
        setText(R.id.scan_step, "step");
        setText(R.id.scan_title, "title");
        setText(R.id.scan_subtitle, "subtitle");
        setText(R.id.scan_searching, "searching");
        setText(R.id.scan_light_label, "torch");
        ViewCompat.setAccessibilityHeading(findViewById(R.id.scan_title), true);
        if (labels.containsKey("close")) {
            findViewById(R.id.scan_back).setContentDescription(labels.get("close"));
        }
        showTorch(false);
    }

    private void putIfPresent(String key, String value) {
        if (value != null && !value.trim().isEmpty()) {
            labels.put(key, value.trim());
        }
    }

    private void setText(int id, String key) {
        TextView view = findViewById(id);
        String text = labels.get(key);
        view.setText(text == null ? "" : text);
        view.setVisibility(text == null || text.isEmpty() ? View.GONE : View.VISIBLE);
    }

    @SuppressWarnings("unchecked")
    private void applyFonts() {
        Object extra = getIntent().getSerializableExtra(EXTRA_FONTS);
        if (!(extra instanceof Map)) {
            return;
        }
        Map<String, String> fonts = (Map<String, String>) extra;
        Typeface regular = font(fonts.get("regular"));
        Typeface medium = font(fonts.get("medium"));
        Typeface semiBold = font(fonts.get("semiBold"));
        setFont(R.id.scan_step, medium);
        setFont(R.id.scan_title, semiBold);
        setFont(R.id.scan_subtitle, regular);
        setFont(R.id.scan_searching, regular);
        setFont(R.id.scan_light_label, regular);
    }

    private Typeface font(String assetKey) {
        if (assetKey == null) {
            return null;
        }
        try {
            return Typeface.createFromAsset(getAssets(), assetKey);
        } catch (RuntimeException e) {
            Log.w(TAG, "font not found " + assetKey);
            return null;
        }
    }

    private void setFont(int id, Typeface typeface) {
        if (typeface != null) {
            ((TextView) findViewById(id)).setTypeface(typeface);
        }
    }

    // The viewfinder is as large as the design asks while everything fits,
    // and gives way to large text down to a floor; the overlay cuts it where
    // the layout put it.
    private void fitHole() {
        int max = getResources().getDimensionPixelSize(R.dimen.scan_hole);
        int min = getResources().getDimensionPixelSize(R.dimen.scan_hole_min);
        ViewGroup.MarginLayoutParams params =
                (ViewGroup.MarginLayoutParams) hole.getLayoutParams();
        View last = column.getChildAt(column.getChildCount() - 1);
        int overflow = last.getBottom()
                + ((ViewGroup.MarginLayoutParams) last.getLayoutParams()).bottomMargin
                + column.getPaddingBottom() - column.getHeight();
        int spare = findViewById(R.id.scan_space_top).getHeight()
                + findViewById(R.id.scan_space_bottom).getHeight();
        int current = hole.getHeight();
        int widest = column.getWidth() - column.getPaddingLeft() - column.getPaddingRight()
                - 2 * getResources().getDimensionPixelSize(R.dimen.scan_side);
        int target = overflow > 0 ? current - overflow : current + spare;
        target = Math.max(min, Math.min(Math.min(max, widest), target));
        if (target != current && current > 0) {
            params.width = target;
            params.height = target;
            hole.post(() -> hole.setLayoutParams(params));
            return;
        }
        overlay.setHole(new RectF(
                column.getLeft() + hole.getLeft(),
                column.getTop() + hole.getTop(),
                column.getLeft() + hole.getRight(),
                column.getTop() + hole.getBottom()));
    }

    private void showTorch(boolean on) {
        lightButton.setBackgroundResource(on ? R.drawable.scan_torch_on : R.drawable.scan_glass_circle);
        lightButton.setColorFilter(on
                ? ContextCompat.getColor(this, R.color.scan_torch_on_icon)
                : ContextCompat.getColor(this, R.color.scan_text));
        String description = labels.get(on ? "torchOff" : "torchOn");
        if (description != null) {
            lightButton.setContentDescription(description);
        }
    }

    @Override
    public void onConfigurationChanged(@NonNull Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        applyTargetRotation();
        if (overlay != null) {
            overlay.invalidate();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_CAMERA) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                startCamera();
            } else {
                failAndFinish("PERMISSION_NOT_GRANTED", "Camera permission denied");
            }
        }
    }

    private void startCamera() {
        if (cameraBound) {
            applyTargetRotation();
            return;
        }
        ListenableFuture<ProcessCameraProvider> future = ProcessCameraProvider.getInstance(this);
        future.addListener(() -> {
            try {
                ProcessCameraProvider provider = future.get();
                if (!provider.hasCamera(CameraSelector.DEFAULT_BACK_CAMERA)) {
                    failAndFinish("CAMERA_START_FAILED", "No back camera");
                    return;
                }
                preview = new Preview.Builder()
                        .setTargetRotation(currentRotation())
                        .build();
                preview.setSurfaceProvider(previewView.getSurfaceProvider());

                analysis = new ImageAnalysis.Builder()
                        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                        .setTargetRotation(currentRotation())
                        .build();
                analysis.setAnalyzer(cameraExecutor, image -> {
                    if (handled) {
                        image.close();
                        return;
                    }
                    String code = QrDecoder.decodeImageProxy(image);
                    image.close();
                    if (code != null && !handled) {
                        handled = true;
                        Log.i(TAG, "decoded length=" + code.length());
                        runOnUiThread(() -> finishWith(code));
                    }
                });

                CameraSelector selector = CameraSelector.DEFAULT_BACK_CAMERA;
                provider.unbindAll();
                camera = provider.bindToLifecycle(this, selector, preview, analysis);
                cameraBound = true;
                Log.i(TAG, "camera bound rotation=" + currentRotation()
                        + " preview=" + previewView.getWidth() + "x" + previewView.getHeight());
            } catch (Exception e) {
                Log.e(TAG, "camera start failed", e);
                failAndFinish(classifyCameraFailure(e), e.getMessage());
            }
        }, ContextCompat.getMainExecutor(this));
    }

    private static String classifyCameraFailure(Exception e) {
        String name = e.getClass().getSimpleName();
        String msg = e.getMessage() == null ? "" : e.getMessage().toLowerCase();
        if (name.contains("Unavailable") || msg.contains("in use")
                || msg.contains("camera_in_use") || msg.contains("higher-priority")) {
            return "CAMERA_IN_USE";
        }
        return "CAMERA_START_FAILED";
    }

    private void applyTargetRotation() {
        int rotation = currentRotation();
        if (preview != null) {
            preview.setTargetRotation(rotation);
        }
        if (analysis != null) {
            analysis.setTargetRotation(rotation);
        }
    }

    private int currentRotation() {
        Display display = previewView != null ? previewView.getDisplay() : null;
        if (display == null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display = getDisplay();
        }
        if (display == null) {
            display = getWindowManager().getDefaultDisplay();
        }
        return display != null ? display.getRotation() : Surface.ROTATION_0;
    }

    private void toggleTorch() {
        if (camera == null || !camera.getCameraInfo().hasFlashUnit()) {
            torchUnavailable();
            return;
        }
        try {
            isLightOpen = !isLightOpen;
            camera.getCameraControl().enableTorch(isLightOpen);
            showTorch(isLightOpen);
        } catch (Exception e) {
            isLightOpen = false;
            showTorch(false);
            torchUnavailable();
        }
    }

    private void torchUnavailable() {
        String text = labels.get("torchUnavailable");
        if (text != null) {
            Toast.makeText(this, text, Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (sensorManager != null && lightSensor != null && sensorEventListener != null) {
            sensorManager.registerListener(sensorEventListener, lightSensor,
                    SensorManager.SENSOR_DELAY_NORMAL);
        }
        applyTargetRotation();
    }

    @Override
    protected void onPause() {
        if (sensorManager != null && sensorEventListener != null) {
            sensorManager.unregisterListener(sensorEventListener);
        }
        super.onPause();
    }

    @Override
    public void onBackPressed() {
        cancel();
    }

    private void cancel() {
        setResult(Activity.RESULT_CANCELED);
        finish();
    }

    private void failAndFinish(String errorCode, String message) {
        Log.e(TAG, "fail " + errorCode + " " + message);
        Intent data = new Intent();
        data.putExtra(EXTRA_ERROR, errorCode);
        if (message != null) {
            data.putExtra(EXTRA_ERROR_MESSAGE, message);
        }
        setResult(Activity.RESULT_CANCELED, data);
        finish();
    }

    private void finishWith(String code) {
        Intent result = new Intent();
        result.putExtra(EXTRA_RESULT, code);
        setResult(Activity.RESULT_OK, result);
        finish();
    }

    @Override
    protected void onDestroy() {
        if (cameraExecutor != null) {
            cameraExecutor.shutdown();
        }
        super.onDestroy();
    }
}

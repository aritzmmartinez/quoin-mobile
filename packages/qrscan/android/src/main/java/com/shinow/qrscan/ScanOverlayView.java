package com.shinow.qrscan;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.util.AttributeSet;
import android.view.View;

import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

/**
 * The veil over the camera with the viewfinder cut out of it, rounded, and
 * its four corners marked. Still: nothing here moves.
 */
public class ScanOverlayView extends View {

    private static final int DEFAULT_ACCENT = 0xFF12C4FF;

    private final Paint veilPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint cornerPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path veil = new Path();
    private final Path corners = new Path();
    private final RectF hole = new RectF();
    private final RectF arc = new RectF();
    private boolean hasHole = false;

    public ScanOverlayView(Context context) {
        super(context);
        init();
    }

    public ScanOverlayView(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public ScanOverlayView(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        veilPaint.setColor(ContextCompat.getColor(getContext(), R.color.scan_veil));
        veilPaint.setStyle(Paint.Style.FILL);
        cornerPaint.setStyle(Paint.Style.STROKE);
        cornerPaint.setStrokeCap(Paint.Cap.ROUND);
        cornerPaint.setStrokeJoin(Paint.Join.ROUND);
        cornerPaint.setStrokeWidth(getResources().getDimension(R.dimen.scan_corner_stroke));
        cornerPaint.setColor(DEFAULT_ACCENT);
    }

    void setStyle(@Nullable Integer color) {
        cornerPaint.setColor((color == null ? DEFAULT_ACCENT : color) | 0xFF000000);
        invalidate();
    }

    /** The viewfinder, in this view's coordinates. */
    void setHole(RectF rect) {
        if (hasHole && hole.equals(rect)) {
            return;
        }
        hole.set(rect);
        hasHole = true;
        invalidate();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        int w = getWidth();
        int h = getHeight();
        if (w <= 0 || h <= 0) {
            return;
        }
        if (!hasHole) {
            canvas.drawRect(0, 0, w, h, veilPaint);
            return;
        }
        float r = Math.min(getResources().getDimension(R.dimen.scan_hole_radius),
                hole.width() / 4f);
        veil.reset();
        veil.setFillType(Path.FillType.EVEN_ODD);
        veil.addRect(0, 0, w, h, Path.Direction.CW);
        veil.addRoundRect(hole, r, r, Path.Direction.CW);
        canvas.drawPath(veil, veilPaint);

        // Each corner: a straight arm, the quarter circle, the other arm, on
        // the edge of the hole, as in the design.
        float arm = getResources().getDimension(R.dimen.scan_corner_arm);
        float l = hole.left;
        float t = hole.top;
        float rt = hole.right;
        float b = hole.bottom;
        float d = 2 * r;
        corners.reset();
        corners.moveTo(l, t + r + arm);
        corners.lineTo(l, t + r);
        arc.set(l, t, l + d, t + d);
        corners.arcTo(arc, 180, 90, false);
        corners.lineTo(l + r + arm, t);
        corners.moveTo(rt - r - arm, t);
        corners.lineTo(rt - r, t);
        arc.set(rt - d, t, rt, t + d);
        corners.arcTo(arc, 270, 90, false);
        corners.lineTo(rt, t + r + arm);
        corners.moveTo(rt, b - r - arm);
        corners.lineTo(rt, b - r);
        arc.set(rt - d, b - d, rt, b);
        corners.arcTo(arc, 0, 90, false);
        corners.lineTo(rt - r - arm, b);
        corners.moveTo(l + r + arm, b);
        corners.lineTo(l + r, b);
        arc.set(l, b - d, l + d, b);
        corners.arcTo(arc, 90, 90, false);
        corners.lineTo(l, b - r - arm);
        canvas.drawPath(corners, cornerPaint);
    }
}

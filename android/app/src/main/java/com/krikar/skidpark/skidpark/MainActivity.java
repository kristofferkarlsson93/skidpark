package com.krikar.skidpark.skidpark;

import io.flutter.embedding.android.FlutterActivity;
import android.view.KeyEvent;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.skidpark.app/volume_key";
    private MethodChannel channel;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);

        channel.setMethodCallHandler((call, result) -> { /* Ignore incoming calls */ });
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (channel == null) {
            return super.onKeyDown(keyCode, event);
        }
        // Sending call to volume_control.dart with the text args.
        switch (keyCode) {
            case KeyEvent.KEYCODE_VOLUME_DOWN:
                channel.invokeMethod("onVolumePress", "down");
                return true;
            case KeyEvent.KEYCODE_VOLUME_UP:
                channel.invokeMethod("onVolumePress", "up");
                return true;
            default:
                return super.onKeyDown(keyCode, event);
        }
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        if (channel == null) {
            return super.onKeyUp(keyCode, event);
        }
        // Sending call to volume_control.dart with the text args.
        switch (keyCode) {
            case KeyEvent.KEYCODE_VOLUME_DOWN:
                channel.invokeMethod("onVolumeRelease", "down");
                return true;
            case KeyEvent.KEYCODE_VOLUME_UP:
                channel.invokeMethod("onVolumeRelease", "up");
                return true;
            default:
                return super.onKeyUp(keyCode, event);
        }
    }
}

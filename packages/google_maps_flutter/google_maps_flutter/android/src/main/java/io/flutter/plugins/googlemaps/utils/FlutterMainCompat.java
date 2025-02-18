package io.flutter.plugins.googlemaps.utils;

import androidx.annotation.NonNull;

import io.flutter.FlutterInjector;

public class FlutterMainCompat {

    /**
     * Returns the file name for the given asset. The returned file name can be used to access the
     * asset in the APK through the {@link android.content.res.AssetManager} API.
     *
     * @param asset the name of the asset. The name can be hierarchical
     * @return the filename to be used with {@link android.content.res.AssetManager}
     */
    @NonNull
    public static String getLookupKeyForAsset(@NonNull String asset) {
        return FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset);
    }
}

package com.npkompleet.beatz;

import android.Manifest;
import android.content.ContentUris;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.media.AudioAttributes;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore.Audio.Albums;
import android.provider.MediaStore.Audio.Media;
import android.util.Log;
import android.util.Size;

import androidx.annotation.NonNull;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "Beatz";
    private static final String CHANNEL_NAME = "com.npkompleet.beatz";
    private static final String FETCH_ALBUMS_METHOD = "fetchAlbums";
    private static final String FETCH_SONGS_FROM_ALBUM_METHOD = "fetchSongsFromAlbum";
    private static final String SEEK_METHOD = "seek";
    private static final String PAUSE_METHOD = "pause";
    private static final String RESUME_METHOD = "resume";
    private static final String PLAY_SONG_METHOD = "play";
    private static final String POSITION_METHOD = "position";
    private static final String SONG_COMPLETE_METHOD = "complete";
    private static final String ERROR_METHOD = "error";
    private static final int REQUEST_AUDIO_PERMISSION = 200;
    private static final long POSITION_INTERVAL_MS = 300L;

    private final ExecutorService ioExecutor = Executors.newSingleThreadExecutor();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    /** Calls waiting for the audio permission dialog to be answered. */
    private final List<Runnable> pendingPermissionCalls = new ArrayList<>();

    private MethodChannel channel;
    private MediaPlayer player;

    private final Runnable positionTicker = new Runnable() {
        @Override
        public void run() {
            if (player != null && player.isPlaying()) {
                channel.invokeMethod(POSITION_METHOD, player.getCurrentPosition());
            }
            mainHandler.postDelayed(this, POSITION_INTERVAL_MS);
        }
    };

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler(this::handleMethodCall);
    }

    private void handleMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case FETCH_ALBUMS_METHOD:
                withAudioPermission(() -> runQuery(result, this::queryAlbums), result);
                break;
            case FETCH_SONGS_FROM_ALBUM_METHOD: {
                Number albumId = call.argument("albumId");
                if (albumId == null) {
                    result.error("bad_args", "albumId is required", null);
                    return;
                }
                withAudioPermission(
                        () -> runQuery(result, () -> querySongsFromAlbum(albumId.longValue())),
                        result);
                break;
            }
            case PLAY_SONG_METHOD:
                playSong(call.argument("songUrl"), result);
                break;
            case SEEK_METHOD: {
                Number position = call.argument("position");
                if (player != null && position != null) player.seekTo(position.intValue());
                result.success(null);
                break;
            }
            case PAUSE_METHOD:
                if (player != null && player.isPlaying()) player.pause();
                result.success(null);
                break;
            case RESUME_METHOD:
                if (player != null) player.start();
                result.success(null);
                break;
            default:
                result.notImplemented();
        }
    }

    // ---------------------------------------------------------------- permissions

    private String audioPermission() {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
                ? Manifest.permission.READ_MEDIA_AUDIO
                : Manifest.permission.READ_EXTERNAL_STORAGE;
    }

    private boolean hasAudioPermission() {
        return checkSelfPermission(audioPermission()) == PackageManager.PERMISSION_GRANTED;
    }

    /** Runs {@code action} once the audio permission is granted, or fails {@code result}. */
    private void withAudioPermission(Runnable action, Result result) {
        if (hasAudioPermission()) {
            action.run();
            return;
        }
        pendingPermissionCalls.add(() -> {
            if (hasAudioPermission()) {
                action.run();
            } else {
                result.error("permission_denied", "Audio library permission was denied", null);
            }
        });
        if (pendingPermissionCalls.size() == 1) {
            requestPermissions(new String[]{audioPermission()}, REQUEST_AUDIO_PERMISSION);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode != REQUEST_AUDIO_PERMISSION) return;
        List<Runnable> calls = new ArrayList<>(pendingPermissionCalls);
        pendingPermissionCalls.clear();
        for (Runnable call : calls) call.run();
    }

    // ---------------------------------------------------------------- media queries

    private interface Query {
        String run() throws JSONException;
    }

    /** Runs a MediaStore query off the main thread and replies on the main thread. */
    private void runQuery(Result result, Query query) {
        ioExecutor.execute(() -> {
            try {
                String json = query.run();
                mainHandler.post(() -> result.success(json));
            } catch (Exception e) {
                Log.e(TAG, "Media query failed", e);
                mainHandler.post(() -> result.error("query_failed", e.getMessage(), null));
            }
        });
    }

    private String queryAlbums() throws JSONException {
        String[] projection = {
                Albums._ID, Albums.ALBUM, Albums.ARTIST, Albums.ALBUM_ART, Albums.NUMBER_OF_SONGS};
        JSONArray albums = new JSONArray();
        try (Cursor cursor = getContentResolver().query(
                Albums.EXTERNAL_CONTENT_URI, projection, null, null, Albums.ALBUM + " ASC")) {
            if (cursor == null) return albums.toString();
            while (cursor.moveToNext()) {
                long id = cursor.getLong(0);
                JSONObject album = new JSONObject();
                album.put("id", id);
                album.put("album", cursor.getString(1));
                album.put("artist", cursor.getString(2));
                album.put("albumArt", albumArtPath(id, cursor.getString(3)));
                album.put("numOfSongs", cursor.getInt(4));
                albums.put(album);
            }
        }
        return albums.toString();
    }

    /**
     * Returns a file path to the album cover. Since Android 10 ALBUM_ART is no longer
     * populated, so the thumbnail is rendered once into the app cache.
     */
    private Object albumArtPath(long albumId, String legacyPath) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return legacyPath == null ? JSONObject.NULL : legacyPath;
        }
        File dir = new File(getCacheDir(), "album_art");
        File file = new File(dir, albumId + ".jpg");
        if (file.exists()) return file.getAbsolutePath();
        Uri albumUri = ContentUris.withAppendedId(Albums.EXTERNAL_CONTENT_URI, albumId);
        try {
            Bitmap bitmap = getContentResolver().loadThumbnail(albumUri, new Size(512, 512), null);
            if (!dir.exists() && !dir.mkdirs()) return JSONObject.NULL;
            try (FileOutputStream out = new FileOutputStream(file)) {
                bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out);
            }
            return file.getAbsolutePath();
        } catch (IOException e) {
            return JSONObject.NULL; // Album has no cover art.
        }
    }

    private String querySongsFromAlbum(long albumId) throws JSONException {
        String[] projection = {
                Media._ID, Media.TITLE, Media.DISPLAY_NAME, Media.ARTIST,
                Media.DURATION, Media.TRACK, Media.MIME_TYPE};
        JSONArray songs = new JSONArray();
        try (Cursor cursor = getContentResolver().query(Media.EXTERNAL_CONTENT_URI, projection,
                Media.ALBUM_ID + "=?", new String[]{String.valueOf(albumId)}, Media.TRACK + " ASC")) {
            if (cursor == null) return songs.toString();
            while (cursor.moveToNext()) {
                long id = cursor.getLong(0);
                JSONObject song = new JSONObject();
                song.put("id", id);
                song.put("title", cursor.getString(1));
                song.put("displayName", cursor.getString(2));
                song.put("artist", cursor.getString(3));
                song.put("duration", cursor.getLong(4));
                song.put("track", cursor.getInt(5));
                song.put("uri", ContentUris.withAppendedId(Media.EXTERNAL_CONTENT_URI, id).toString());
                song.put("type", cursor.getString(6));
                songs.put(song);
            }
        }
        return songs.toString();
    }

    // ---------------------------------------------------------------- playback

    private void playSong(String uri, Result result) {
        if (uri == null) {
            result.error("bad_args", "songUrl is required", null);
            return;
        }
        releasePlayer();
        MediaPlayer mp = new MediaPlayer();
        player = mp;
        mp.setAudioAttributes(new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build());
        mp.setOnPreparedListener(prepared -> {
            prepared.start();
            mainHandler.post(positionTicker);
            result.success("success");
        });
        mp.setOnCompletionListener(done -> {
            mainHandler.removeCallbacks(positionTicker);
            channel.invokeMethod(SONG_COMPLETE_METHOD, null);
        });
        mp.setOnErrorListener((failed, what, extra) -> {
            Log.e(TAG, "MediaPlayer error what=" + what + " extra=" + extra);
            mainHandler.removeCallbacks(positionTicker);
            channel.invokeMethod(ERROR_METHOD, null);
            return true;
        });
        try {
            mp.setDataSource(this, Uri.parse(uri));
            mp.prepareAsync();
        } catch (IOException | IllegalArgumentException e) {
            releasePlayer();
            result.error("play_failed", e.getMessage(), null);
        }
    }

    private void releasePlayer() {
        mainHandler.removeCallbacks(positionTicker);
        if (player != null) {
            player.release();
            player = null;
        }
    }

    @Override
    protected void onDestroy() {
        releasePlayer();
        ioExecutor.shutdown();
        super.onDestroy();
    }
}

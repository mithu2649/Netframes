package com.example.netframes

import android.content.Context
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.hls.HlsMediaSource
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class VideoPlayerView(context: Context, messenger: BinaryMessenger, id: Int, creationParams: Map<String?, Any?>?) : PlatformView {
    private val exoPlayer: ExoPlayer
    private val playerView: PlayerView

    init {
        playerView = PlayerView(context)
        exoPlayer = ExoPlayer.Builder(context).build()
        playerView.player = exoPlayer

        val url = creationParams?.get("url") as? String
        val headers = creationParams?.get("headers") as? Map<String, String>
        if (url != null) {
            initializePlayer(url, headers)
        }
    }

    private fun initializePlayer(url: String, headers: Map<String, String>?) {
        val httpDataSourceFactory = DefaultHttpDataSource.Factory()
        if (headers != null) {
            httpDataSourceFactory.setDefaultRequestProperties(headers)
        }

        val mediaSource = HlsMediaSource.Factory(httpDataSourceFactory)
            .createMediaSource(MediaItem.fromUri(url))

        exoPlayer.setMediaSource(mediaSource)
        exoPlayer.prepare()
        exoPlayer.playWhenReady = true
    }

    override fun getView(): PlayerView {
        return playerView
    }

    override fun dispose() {
        exoPlayer.release()
    }
}

class VideoPlayerFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String?, Any?>?
        return VideoPlayerView(context, messenger, viewId, creationParams)
    }
}
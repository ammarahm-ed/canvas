import { VideoBase, controlsProperty, autoplayProperty, loopProperty, srcProperty, currentTimeProperty, durationProperty } from './common';
import { Screen, Application, ControlStateChangeListener, Utils, knownFolders, path } from '@nativescript/core';
import { Source } from '..';
import { isString } from '@nativescript/core/utils/types';

const STATE_IDLE: number = 1;
const STATE_BUFFERING: number = 2;
const STATE_READY: number = 3;
const STATE_ENDED: number = 4;

// @NativeClass()
// class NativeOhax extends java.lang.Object {
// 	finalize(){
// 		// clean shit up
// 		super.finalize();
// 	}
// }

export class Video extends VideoBase {
	#container: android.widget.LinearLayout;
	#sourceView: Source[] = [];
	#playerView: com.google.android.exoplayer2.ui.PlayerView;
	#player: com.google.android.exoplayer2.SimpleExoPlayer;
	#playerListener: com.google.android.exoplayer2.Player.EventListener;
	#videoListener: com.google.android.exoplayer2.video.VideoListener;
	#src: string;
	#autoplay: boolean;
	#loop: boolean;
	#textureView: android.view.TextureView;
	_isCustom: boolean = false;
	_playing: boolean = false;
	_timer: any;
	_st: android.graphics.SurfaceTexture;
	_surface: android.view.Surface;
	_render: any;
	_frameListener: any;
	_canvas: any;
	_frameTimer: any;
	_readyState: number = 0;
	_videoWidth = 0;
	_videoHeight = 0;
	constructor() {
		super();
		java.lang.System.loadLibrary('canvasnative');
		//@ts-ignore
		const builder = new com.google.android.exoplayer2.SimpleExoPlayer.Builder(Utils.ad.getApplicationContext());
		this.#player = builder.build();
		const ref = new WeakRef(this);
		this.#playerListener = new com.google.android.exoplayer2.Player.EventListener({
			onIsPlayingChanged: function (isPlaying) {
				const owner = ref.get();
				if (owner) {
					const duration = owner.#player.getDuration();
					if (owner.duration != duration) {
						durationProperty.nativeValueChange(owner, duration);
						owner._notifyListener(Video.durationchangeEvent);
					}
					owner._playing = isPlaying;
					if (isPlaying) {
						owner._notifyListener(Video.playingEvent);
						owner._notifyVideoFrameCallbacks();
						if (owner._timer) {
							clearInterval(owner._timer);
						}
						if (owner._frameTimer) {
							clearInterval(owner._frameTimer);
						}

						owner._timer = setInterval(function () {
							const current = owner.#player.getCurrentPosition();
							if (current != owner.currentTime) {
								currentTimeProperty.nativeValueChange(owner, current);
								owner._notifyListener(Video.timeupdateEvent);
								owner._notifyVideoFrameCallbacks();
							}
						}, 1000);
					} else {
						clearInterval(owner._timer);
						clearInterval(owner._frameTimer);
						currentTimeProperty.nativeValueChange(owner, owner.#player.getCurrentPosition());
					}
				}
			},
			onLoadingChanged: function (isLoading) {
				console.log('onLoadingChanged', isLoading);
			},
			onPlaybackParametersChanged: function (playbackParameters) {},
			onPlaybackSuppressionReasonChanged: function (playbackSuppressionReason) {},
			onPlayerError: function (error) {
				console.log('PlayerError', error);
			},
			onPlayerStateChanged: function (playWhenReady, playbackState) {
				console.log('onPlayerStateChanged', Date.now());
				// if (playbackState === STATE_READY) {
				// 	playerReady = true;
				// } else if (playbackState === STATE_ENDED) {
				// 	playerEnded = true;
				// }
			},
			onPositionDiscontinuity: function (reason) {},
			onRepeatModeChanged: function (repeatMode) {},
			onSeekProcessed: function () {},
			onShuffleModeEnabledChanged: function (shuffleModeEnabled) {},
			//@ts-ignore
			onTimelineChanged(timeline: com.google.android.exoplayer2.Timeline, manifest: any, reason: number) {},
			onTracksChanged: function (trackGroups, trackSelections) {},
		});
		this.#videoListener = new com.google.android.exoplayer2.video.VideoListener({
			onRenderedFirstFrame() {},
			onVideoSizeChanged(width: number, height: number, unappliedRotationDegrees: number, pixelWidthHeightRatio: number) {
				const owner = ref.get();
				if (owner) {
					owner._videoWidth = width;
					owner._videoHeight = height;
				}
			},
			onSurfaceSizeChanged(width: number, height: number) {},
		});
		const activity: androidx.appcompat.app.AppCompatActivity = Application.android.foregroundActivity || Application.android.startActivity;
		const inflator = activity.getLayoutInflater();
		const layout = Video.getResourceId(Application.android.foregroundActivity || Application.android.startActivity, 'player');
		this.#player.addListener(this.#playerListener);
		this.#playerView = inflator.inflate(layout, null, false) as any; //new com.google.android.exoplayer2.ui.PlayerView(Application.android.foregroundActivity || Application.android.startActivity);
		this.#container = new android.widget.LinearLayout(Application.android.foregroundActivity || Application.android.startActivity);
		const params = new android.widget.LinearLayout.LayoutParams(android.widget.LinearLayout.LayoutParams.MATCH_PARENT, android.widget.LinearLayout.LayoutParams.MATCH_PARENT);
		this.#textureView = new android.view.TextureView(Application.android.foregroundActivity || Application.android.startActivity);
		this.#container.addView(this.#textureView as any, params);
		this.setNativeView(this.#container);
		this.#player.addVideoListener(this.#videoListener);
	}

	get readyState() {
		return this._readyState;
	}

	_setSurface(surface) {
		this.#player.setVideoSurface(surface);
	}

	private static getResourceId(context: any, res: string = '') {
		if (!context) return 0;
		if (isString(res)) {
			const packageName = context.getPackageName();
			try {
				const className = java.lang.Class.forName(`${packageName}.R$layout`);
				return parseInt(String(className.getDeclaredField(res).get(null)));
			} catch (e) {
				return 0;
			}
		}
		return 0;
	}
	static st_count = 0;
	static createCustomView() {
		const video = new Video();
		video._isCustom = true;
		video.width = 300;
		video.height = 150;
		return video;
	}

	private _setSrc(value: string) {
		try {
			if (typeof value === 'string' && value.startsWith('~/')) {
				value = path.join(knownFolders.currentApp().path, value.replace('~', ''));
			}
			this.#player.addMediaItem(com.google.android.exoplayer2.MediaItem.fromUri(android.net.Uri.parse(value)));
			this.#player.prepare();
			if (this.#autoplay) {
				this.#player.setPlayWhenReady(true);
			}
		} catch (e) {
			console.log(e);
		}
	}

	_hasFrame = false;
	getCurrentFrame(context?: WebGLRenderingContext) {
		if (this.isLoaded) {
			const surfaceView = this.#playerView.getVideoSurfaceView();
			if (surfaceView instanceof android.view.TextureView) {
				const st = surfaceView.getSurfaceTexture();
				if (st) {
					// @ts-ignore
					this._render = com.github.triniwiz.canvas.Utils.createRenderAndAttachToGLContext(context, st);
					this._st = st;
				}
			}
		}

		if (!this._st) {
			// @ts-ignore
			const result = com.github.triniwiz.canvas.Utils.createSurfaceTexture(context);
			this._st = result[0];
			const ref = new WeakRef(this);
			this._frameListener = new android.graphics.SurfaceTexture.OnFrameAvailableListener({
				onFrameAvailable(param0: android.graphics.SurfaceTexture) {
					const owner = ref.get();
					if (owner) {
						owner._hasFrame = true;
						owner._notifyVideoFrameCallbacks();
					}
				},
			});

			this._st.setOnFrameAvailableListener(this._frameListener);

			this._surface = new android.view.Surface(this._st);
			this.#player.setVideoSurface(this._surface);
			this._render = result[1];
		}

		if (this._st) {
			if (!this._hasFrame) {
				return;
			}
			// @ts-ignore
			com.github.triniwiz.canvas.Utils.updateTexImage(context, this._st, this._render, this._videoWidth, this._videoHeight, arguments[4], arguments[5]);

			this._hasFrame = false;
		}
	}

	play() {
		this.#player.setPlayWhenReady(true);
	}

	pause() {
		this.#player.setPlayWhenReady(false);
	}

	get muted() {
		return this.#player.isDeviceMuted();
	}

	set muted(value: boolean) {
		this.#player.setDeviceMuted(value);
	}

	get duration() {
		return this.#player.getDuration();
	}

	get currentTime() {
		return this.#player.getCurrentPosition() / 1000;
	}

	set currentTime(value: number) {
		this.#player.seekTo(value * 1000);
	}

	get src() {
		return this.#src;
	}

	set src(value: string) {
		this.#src = value;
		this._setSrc(value);
	}

	//@ts-ignore
	get autoplay() {
		return this.#autoplay;
	}

	set autoplay(value: boolean) {
		this.#player.setPlayWhenReady(value);
	}

	get controls() {
		return this.#playerView.getUseController();
	}

	set controls(enabled: boolean) {
		this.#playerView.setUseController(enabled);
	}

	// @ts-ignore
	get loop() {
		return this.#loop;
	}

	set loop(value: boolean) {
		this.#loop = value;

		if (value) {
			this.#player.setRepeatMode(com.google.android.exoplayer2.Player.REPEAT_MODE_ALL);
		} else {
			this.#player.setRepeatMode(com.google.android.exoplayer2.Player.REPEAT_MODE_OFF);
		}
	}

	createNativeView(): Object {
		if (!this.#playerView) {
			this.#playerView = new com.google.android.exoplayer2.ui.PlayerView(this._context);
		}
		this.#playerView.setPlayer(this.#player);
		return this.#playerView;
	}

	initNativeView() {
		super.initNativeView();
	}

	_addChildFromBuilder(name: string, value: any) {
		if (value instanceof Source) {
			this.#sourceView.push(value);
		}
	}

	onLoaded() {
		super.onLoaded();
		if (this.#sourceView.length > 0) {
			this._setSrc(this.#sourceView[0].src);
		}
	}

	// @ts-ignore
	get width() {
		if (this.getMeasuredWidth() > 0) {
			return this.getMeasuredWidth();
		}
		//@ts-ignore
		const width = this.#container.getWidth();
		if (width === 0) {
			//@ts-ignore
			let rootParams = this.#container.getLayoutParams();
			if (rootParams) {
				return rootParams.width;
			}
		}
		return width;
	}

	set width(value) {
		this.style.width = value;
		if (this._isCustom) {
			this._layoutNative();
		}
	}

	// @ts-ignore
	get height() {
		if (this.getMeasuredHeight() > 0) {
			return this.getMeasuredHeight();
		}
		//@ts-ignore
		const height = this.#container.getHeight();
		if (height === 0) {
			//@ts-ignore
			let rootParams = this.#container.getLayoutParams();
			if (rootParams) {
				return rootParams.height;
			}
		}
		return height;
	}

	set height(value) {
		this.style.height = value;
		if (this._isCustom) {
			this._layoutNative();
		}
	}

	_layoutNative() {
		if (!this.parent) {
			//@ts-ignore
			if ((typeof this.width === 'string' && this.width.indexOf('%')) || (typeof this.height === 'string' && this.height.indexOf('%'))) {
				return;
			}
			if (!this._isCustom) {
				return;
			}

			const size = this._realSize;
			size.width = size.width * Screen.mainScreen.scale;
			size.height = size.height * Screen.mainScreen.scale;
			//@ts-ignore
			let rootParams = this.#container.getLayoutParams();

			if (rootParams && (size.width || 0) === rootParams.width && (size.height || 0) === rootParams.height) {
				return;
			}

			if ((size.width || 0) !== 0 && (size.height || 0) !== 0) {
				if (!rootParams) {
					rootParams = new android.widget.FrameLayout.LayoutParams(0, 0);
				}
				rootParams.width = size.width;
				rootParams.height = size.height;
				let surfaceParams; // = this._canvas.getSurface().getLayoutParams();
				if (!surfaceParams) {
					surfaceParams = new android.widget.FrameLayout.LayoutParams(0, 0);
				}
				//	surfaceParams.width = size.width;
				//	surfaceParams.height = size.height;

				//@ts-ignore
				this.#container.setLayoutParams(rootParams);

				const w = android.view.View.MeasureSpec.makeMeasureSpec(size.width, android.view.View.MeasureSpec.EXACTLY);
				const h = android.view.View.MeasureSpec.makeMeasureSpec(size.height, android.view.View.MeasureSpec.EXACTLY);
				//@ts-ignore
				this.#container.measure(w, h);
				//@ts-ignore
				this.#container.layout(0, 0, size.width || 0, size.height || 0);

				if (this._st) {
					this._st.setDefaultBufferSize(size.width || 0, size.height || 0);
				}
			}
		}
	}
}

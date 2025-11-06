import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

import '../../../config.dart';
import '../../../controllers/app_pages_controllers/video_call_controller.dart';

class VideoCallClass {
  Widget buildNormalVideoUI() {
    return GetBuilder<VideoCallController>(builder: (videoCtrl) {
      log('buildNormalVideoUI: remoteUId=${videoCtrl.remoteUId}, users=${videoCtrl.users}, localUserJoined=${videoCtrl.localUserJoined}');
      return SizedBox(
        height: Get.height,
        width: Get.width,
        child: videoCtrl.localUserJoined
            ? buildJoinUserUI(videoCtrl)
            : Container(color: appCtrl.appTheme.primary), // Fallback UI
      );
    });
  }

  Widget buildJoinUserUI(VideoCallController? videoCtrl) {
    final views = _getRenderViews(videoCtrl);
    log('Views count: ${views.length}');
    switch (views.length) {
      case 1: // Only local user
        return Column(
          children: [_videoView(views[0])],
        );
      case 2: // Local + one remote user
        return Stack(
          children: [
            // Remote user (full screen)
            _expandedVideoRow([views[1]]),
            // Local user (small overlay)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(width: Sizes.s8, color: Colors.white38),
                  borderRadius: BorderRadius.circular(Insets.i10),
                ),
                margin: const EdgeInsets.fromLTRB(
                    Insets.i15, Insets.i40, Insets.i10, Insets.i15),
                width: Sizes.s110,
                height: Sizes.s140,
                child: _expandedVideoRow([views[0]]),
              ),
            ),
          ],
        );
      case 3: // Local + two remote users
        return Column(
          children: [
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 3)),
          ],
        );
      case 4: // Local + three remote users
        return Column(
          children: [
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 4)),
          ],
        );
      default:
        return Container(color: appCtrl.appTheme.primary);
    }
  }

  List<Widget> _getRenderViews(VideoCallController? videoCtrl) {
    final List<Widget> list = [];
    // Add local user view if joined
    if (videoCtrl!.localUserJoined) {
      list.add(
        AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: videoCtrl.engine!,
            canvas: const VideoCanvas(uid: 0),
          ),
        ),
      );
    }
    // Add remote user views
    for (var uid in videoCtrl.users) {
      list.add(
        AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: videoCtrl.engine,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: videoCtrl.channelName!),
          ),
        ),
      );
    }
    log('Render views: ${list.length}');
    return list;
  }

  Widget _videoView(Widget view) {
    return GetBuilder<VideoCallController>(builder: (videoCtrl) {
      return Expanded(
        child: Container(
          child: videoCtrl.isCameraShow || view != _getRenderViews(videoCtrl)[0]
              ? view
              : Container(
              color: appCtrl
                  .appTheme.primary), // Hide local video if camera off
        ),
      );
    });
  }

  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map(_videoView).toList();
    return Row(children: wrappedViews);
  }
}

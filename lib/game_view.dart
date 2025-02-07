import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:game_2048/utils/url_launcher_utils.dart';

import 'views/button_widget.dart';
import 'views/empy_board_widget.dart';
import 'views/score_board.dart';
import 'views/tile_board_widget.dart';
import 'const/colors.dart';
import 'managers/board_manager.dart';
import 'package:panara_dialogs/panara_dialogs.dart';

class GameView extends ConsumerStatefulWidget {
  const GameView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GameState();
}

class _GameState extends ConsumerState<GameView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  //The contoller used to move the the tiles
  late final AnimationController _moveController = AnimationController(
    duration: const Duration(milliseconds: 100),
    vsync: this,
  )..addStatusListener((status) {
      //When the movement finishes merge the tiles and start the scale animation which gives the pop effect.
      if (status == AnimationStatus.completed) {
        ref.read(boardManager.notifier).merge();
        _scaleController.forward(from: 0.0);
      }
    });

  //The curve animation for the move animation controller.
  late final CurvedAnimation _moveAnimation = CurvedAnimation(
    parent: _moveController,
    curve: Curves.easeInOut,
  );

  //The contoller used to show a popup effect when the tiles get merged
  late final AnimationController _scaleController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  )..addStatusListener((status) {
      //When the scale animation finishes end the round and if there is a queued movement start the move controller again for the next direction.
      if (status == AnimationStatus.completed) {
        if (ref.read(boardManager.notifier).endRound()) {
          _moveController.forward(from: 0.0);
        }
      }
    });

  //The curve animation for the scale animation controller.
  late final CurvedAnimation _scaleAnimation = CurvedAnimation(
    parent: _scaleController,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    //Add an Observer for the Lifecycles of the App
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKey: (RawKeyEvent event) {
        //Move the tile with the arrows on the keyboard on Desktop
        if (ref.read(boardManager.notifier).onKey(event)) {
          _moveController.forward(from: 0.0);
        }
      },
      child: SwipeDetector(
        onSwipe: (direction, offset) {
          if (ref.read(boardManager.notifier).move(direction)) {
            _moveController.forward(from: 0.0);
          }
        },
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '2048',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 52.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const ScoreBoard(),
                    const SizedBox(height: 32.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ButtonWidget(
                          icon: Icons.undo,
                          text: "Undo\n",
                          onPressed: () {
                            //Undo the round.
                            ref.read(boardManager.notifier).undo();
                          },
                        ),
                        const SizedBox(width: 16.0),
                        ButtonWidget(
                          icon: Icons.refresh,
                          text: "New\ngame",
                          onPressed: () {
                            //Restart the game
                            PanaraConfirmDialog.showAnimatedGrow(
                              context,
                              title: "2048",
                              message:
                                  "Are you sure you want to start a new game?",
                              confirmButtonText: "Yes",
                              cancelButtonText: "No",
                              onTapCancel: () {
                                Navigator.pop(context);
                              },
                              onTapConfirm: () {
                                Navigator.pop(context);
                                ref.read(boardManager.notifier).newGame();
                              },
                              panaraDialogType: PanaraDialogType.custom,
                              barrierDismissible: true,
                              imagePath: "assets/images/q.png",
                              color: textColor,
                              textColor: buttonColor,
                              buttonTextColor: textColorWhite,
                            );
                          },
                        ),
                        const SizedBox(width: 16.0),
                        ButtonWidget(
                          icon: Icons.star,
                          text: "Rate\napp",
                          onPressed: () {
                            UrlLauncherUtils.rateApp(null, null);
                          },
                        ),
                        const SizedBox(width: 16.0),
                        ButtonWidget(
                          icon: Icons.favorite,
                          text: "More\napp",
                          onPressed: () {
                            UrlLauncherUtils.moreApp();
                          },
                        ),
                        const SizedBox(width: 16.0),
                        ButtonWidget(
                          icon: Icons.policy,
                          text: "Privacy\npolicy",
                          onPressed: () {
                            UrlLauncherUtils.launchPolicy();
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32.0),
              Stack(
                children: [
                  const EmptyBoardWidget(),
                  TileBoardWidget(
                    moveAnimation: _moveAnimation,
                    scaleAnimation: _scaleAnimation,
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //Save current state when the app becomes inactive
    if (state == AppLifecycleState.inactive) {
      ref.read(boardManager.notifier).save();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    //Remove the Observer for the Lifecycles of the App
    WidgetsBinding.instance.removeObserver(this);

    //Dispose the animations.
    _moveAnimation.dispose();
    _scaleAnimation.dispose();
    _moveController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}

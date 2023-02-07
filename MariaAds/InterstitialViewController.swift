//
//  InterstitialViewController.swift
//  MariaAds
//
//  Created by Maria Yelfimova on 07/02/2023.
//

import GoogleMobileAds
import UIKit

class InterstitialViewController: UIViewController, GADFullScreenContentDelegate {

    enum GameState: NSInteger {
        case notStarted
        case playing
        case paused
        case ended
      }

      /// The game length.
      static let gameLength = 5

      /// The interstitial ad.
      var interstitial: GADInterstitialAd?

      /// The countdown timer.
      var timer: Timer?

      /// The amount of time left in the game.
      var timeLeft = gameLength

      /// The state of the game.
      var gameState = GameState.notStarted

      /// The date that the timer was paused.
      var pauseDate: Date?

      /// The last fire date before a pause.
      var previousFireDate: Date?

      /// The countdown timer label.
      @IBOutlet weak var gameText: UILabel!

      /// The play again button.
      @IBOutlet weak var playAgainButton: UIButton!

      override func viewDidLoad() {
        super.viewDidLoad()

        // Pause game when application enters background.
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(InterstitialViewController.pauseGame),
          name: UIApplication.didEnterBackgroundNotification, object: nil)

        // Resume game when application becomes active.
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(InterstitialViewController.resumeGame),
          name: UIApplication.didBecomeActiveNotification, object: nil)

        startNewGame()
      }

      // MARK: - Game Logic
      fileprivate func startNewGame() {
        loadInterstitial()

        gameState = .playing
        timeLeft = InterstitialViewController.gameLength
        playAgainButton.isHidden = true
        updateTimeLeft()
        timer = Timer.scheduledTimer(
          timeInterval: 1.0,
          target: self,
          selector: #selector(InterstitialViewController.decrementTimeLeft(_:)),
          userInfo: nil,
          repeats: true)
      }

      fileprivate func loadInterstitial() {
        let request = GADRequest()
        GADInterstitialAd.load(
          withAdUnitID: "ca-app-pub-3940256099942544/4411468910", request: request
        ) { (ad, error) in
          if let error = error {
            print("Failed to load interstitial ad with error: \(error.localizedDescription)")
            return
          }
          self.interstitial = ad
          self.interstitial?.fullScreenContentDelegate = self
        }
      }

      fileprivate func updateTimeLeft() {
        gameText.text = "\(timeLeft) seconds left!"
      }

      @objc func decrementTimeLeft(_ timer: Timer) {
        timeLeft -= 1
        updateTimeLeft()
        if timeLeft == 0 {
          endGame()
        }
      }

      @objc func pauseGame() {
        if gameState != .playing {
          return
        }
        gameState = .paused

        // Record the relevant pause times.
        pauseDate = Date()
        previousFireDate = timer?.fireDate

        // Prevent the timer from firing while app is in background.
        timer?.fireDate = Date.distantFuture
      }

      @objc func resumeGame() {
        if gameState != .paused {
          return
        }
        gameState = .playing

        // Calculate amount of time the app was paused.
        let pauseTime = (pauseDate?.timeIntervalSinceNow)! * -1

        // Set the timer to start firing again.
        timer?.fireDate = (previousFireDate?.addingTimeInterval(pauseTime))!
      }

      fileprivate func endGame() {
        gameState = .ended
        timer?.invalidate()
        timer = nil

        let alert = UIAlertController(
          title: "Game Over",
          message: "You lasted \(InterstitialViewController.gameLength) seconds",
          preferredStyle: .alert)
        let alertAction = UIAlertAction(
          title: "OK",
          style: .cancel,
          handler: { [weak self] action in
            if let ad = self?.interstitial {
              ad.present(fromRootViewController: self!)
            } else {
              print("Ad wasn't ready")
            }
            self?.playAgainButton.isHidden = false
          })
        alert.addAction(alertAction)
        self.present(alert, animated: true, completion: nil)
      }

      // MARK: - Interstitial Button Actions
      @IBAction func playAgain(_ sender: AnyObject) {
        startNewGame()
      }

      // MARK: - GADFullScreenContentDelegate
      func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad will present full screen content.")
      }

      func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error)
      {
        print("Ad failed to present full screen content with error \(error.localizedDescription).")
      }

      func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
      }

      // MARK: - deinit
      deinit {
        NotificationCenter.default.removeObserver(
          self,
          name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(
          self,
          name: UIApplication.didBecomeActiveNotification, object: nil)
      }

}


//
//  PlayVideoViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/5.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class PlayVideoViewController: AVPlayerViewController {

    var quest: question?
    var videoPlayer: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let quest = self.quest {
            let videoURL = quest.file.URL
            self.player = AVPlayer(URL: videoURL)
            self.player = self.videoPlayer
            
            self.player?.play()
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
